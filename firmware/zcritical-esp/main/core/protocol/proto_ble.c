/* ═══════════════════════════════════════════════════════════════
 * STEER: 反臃肿 | max_lines=250 | scope=firmware
 *
 * 职责: BLE GATTS 服务 — 广播 + GATT 属性表 + 连接管理 + 通知发送
 * 不做什么: 不解析命令、不管理命令队列、不处理 Logo 上传（B2）
 *
 * BLE参数 (唯一真值源: steering/specs/protocol-contract.md):
 *   Device Name: "T1"
 *   Service UUID:  0xFFE0
 *   Char UUID:     0xFFE1 (write-without-response + notify)
 *
 * ESP-IDF v5.3.5: esp_bt_controller.h 不存在，controller API 在 esp_bt.h
 * ═══════════════════════════════════════════════════════════════ */

#include "proto_ble.h"

#include <string.h>
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"

#include "esp_bt.h"
#include "esp_bt_main.h"
#include "esp_gap_ble_api.h"
#include "esp_gatts_api.h"
#include "esp_gatt_common_api.h"
#include "esp_log.h"

/* ── Constants ── */
#define TAG              "BLE"
#define DEVICE_NAME      "T1"
#define SVC_UUID         0xFFE0
#define CHAR_UUID        0xFFE1
#define GATTS_APP_ID     0
#define CHAR_VAL_LEN     512

/* ── GATT database (Service + Char Declaration + Char Value + CCC) ── */
#define GATT_DB_NUM  4

enum {
    HANDLE_SVC_DECL = 0,   /* Service declaration */
    HANDLE_CHAR_DECL,       /* Characteristic declaration */
    HANDLE_CHAR_VALUE,      /* Characteristic value (read/write) */
    HANDLE_CHAR_CCC,       /* Client Characteristic Configuration */
};

/* ── Internal state ── */
static const uint16_t s_primary_svc_uuid = ESP_GATT_UUID_PRI_SERVICE;
static const uint16_t s_char_decl_uuid   = ESP_GATT_UUID_CHAR_DECLARE;
static const uint16_t s_char_ccc_uuid    = ESP_GATT_UUID_CHAR_CLIENT_CONFIG;

static const uint16_t s_svc_uuid_val  = SVC_UUID;
static const uint16_t s_char_uuid_val = CHAR_UUID;

static const uint8_t  s_char_prop =
    ESP_GATT_CHAR_PROP_BIT_WRITE_NR |
    ESP_GATT_CHAR_PROP_BIT_NOTIFY;

static uint8_t  s_char_ccc_val[2]     = {0x00, 0x00};
static uint8_t  s_char_value[CHAR_VAL_LEN] = {0};

/* GATT attribute table */
static const esp_gatts_attr_db_t s_gatt_db[GATT_DB_NUM] = {
    /* [HANDLE_SVC_DECL] Service Declaration */
    { {ESP_GATT_AUTO_RSP}, {
        ESP_UUID_LEN_16, (uint8_t *)&s_primary_svc_uuid,
        ESP_GATT_PERM_READ,
        sizeof(uint16_t), sizeof(s_svc_uuid_val), (uint8_t *)&s_svc_uuid_val
    }},
    /* [HANDLE_CHAR_DECL] Characteristic Declaration */
    { {ESP_GATT_AUTO_RSP}, {
        ESP_UUID_LEN_16, (uint8_t *)&s_char_decl_uuid,
        ESP_GATT_PERM_READ,
        sizeof(uint8_t), sizeof(s_char_prop), (uint8_t *)&s_char_prop
    }},
    /* [HANDLE_CHAR_VALUE] Characteristic Value — RSP_BY_APP for write response */
    { {ESP_GATT_RSP_BY_APP}, {
        ESP_UUID_LEN_16, (uint8_t *)&s_char_uuid_val,
        ESP_GATT_PERM_READ | ESP_GATT_PERM_WRITE,
        CHAR_VAL_LEN, 0, s_char_value
    }},
    /* [HANDLE_CHAR_CCC] Client Characteristic Configuration */
    { {ESP_GATT_AUTO_RSP}, {
        ESP_UUID_LEN_16, (uint8_t *)&s_char_ccc_uuid,
        ESP_GATT_PERM_READ | ESP_GATT_PERM_WRITE,
        sizeof(s_char_ccc_val), sizeof(s_char_ccc_val), s_char_ccc_val
    }},
};

/* ── BLE 数据接收回调（main.c 注册）── */
static void (*s_data_cb)(const uint8_t *data, uint16_t len) = NULL;

void proto_ble_set_data_callback(void (*cb)(const uint8_t *, uint16_t))
{
    s_data_cb = cb;
}

/* ── Runtime state ── */
static uint16_t s_gatts_if    = ESP_GATT_IF_NONE;
static uint16_t s_conn_id    = 0;
static bool     s_connected  = false;
static uint16_t s_svc_handle = 0;
static uint16_t s_char_handle = 0;

/* ── Advertising parameters ── */
static esp_ble_adv_params_t s_adv_params = {
    .adv_int_min       = 0x20,  /* 32 * 0.625ms = 20ms */
    .adv_int_max       = 0x40,  /* 64 * 0.625ms = 40ms */
    .adv_type          = ADV_TYPE_IND,
    .own_addr_type     = BLE_ADDR_TYPE_PUBLIC,
    .channel_map       = ADV_CHNL_ALL,
    .adv_filter_policy = ADV_FILTER_ALLOW_SCAN_ANY_CON_ANY,
};

/* ═══════════════════════════════════════════════════════════════
 *  GAP callbacks — advertising control
 * ═══════════════════════════════════════════════════════════════ */
static void gap_cb(esp_gap_ble_cb_event_t event, esp_ble_gap_cb_param_t *param)
{
    switch (event) {
    case ESP_GAP_BLE_ADV_DATA_SET_COMPLETE_EVT:
        if (param->adv_data_cmpl.status != ESP_BT_STATUS_SUCCESS) {
            ESP_LOGE(TAG, "Adv data set failed: 0x%02x", param->adv_data_cmpl.status);
            return;
        }
        esp_ble_gap_start_advertising(&s_adv_params);
        break;

    case ESP_GAP_BLE_ADV_START_COMPLETE_EVT:
        if (param->adv_start_cmpl.status == ESP_BT_STATUS_SUCCESS) {
            ESP_LOGI(TAG, "Advertising started (name: %s)", DEVICE_NAME);
        } else {
            ESP_LOGE(TAG, "Advertising start failed: 0x%02x", param->adv_start_cmpl.status);
        }
        break;

    case ESP_GAP_BLE_ADV_STOP_COMPLETE_EVT:
        ESP_LOGI(TAG, "Advertising stopped");
        break;

    default:
        break;
    }
}

/* ═══════════════════════════════════════════════════════════════
 *  GATTS callbacks — GATT server events
 * ═══════════════════════════════════════════════════════════════ */
static void gatts_cb(esp_gatts_cb_event_t event, esp_gatt_if_t gatts_if,
                     esp_ble_gatts_cb_param_t *param)
{
    switch (event) {

    case ESP_GATTS_REG_EVT:
        if (param->reg.status != ESP_GATT_OK) {
            ESP_LOGE(TAG, "GATTS reg failed: 0x%02x", param->reg.status);
            return;
        }
        s_gatts_if = gatts_if;

        /* Set device name */
        esp_ble_gap_set_device_name(DEVICE_NAME);

        /* Configure advertising data — device name + flags.
         * APP scans by device name "T1", so name MUST be in adv data (not just scan rsp). */
        esp_ble_adv_data_t adv_data = {
            .set_scan_rsp        = false,
            .include_name        = true,
            .include_txpower     = false,
            .min_interval        = 0x0006,
            .max_interval        = 0x0010,
            .appearance          = 0x00,
            .manufacturer_len    = 0,
            .p_manufacturer_data = NULL,
            .service_data_len    = 0,
            .p_service_data      = NULL,
            .service_uuid_len    = 0,
            .p_service_uuid      = NULL,
            .flag                = (ESP_BLE_ADV_FLAG_GEN_DISC | ESP_BLE_ADV_FLAG_BREDR_NOT_SPT),
        };
        esp_ble_gap_config_adv_data(&adv_data);

        /* Create GATT attribute table */
        esp_ble_gatts_create_attr_tab(s_gatt_db, gatts_if, GATT_DB_NUM, 0);
        break;

    case ESP_GATTS_CREAT_ATTR_TAB_EVT:
        if (param->add_attr_tab.status != ESP_GATT_OK) {
            ESP_LOGE(TAG, "Create attr tab failed: 0x%02x", param->add_attr_tab.status);
            return;
        }
        if (param->add_attr_tab.num_handle != GATT_DB_NUM) {
            ESP_LOGE(TAG, "Unexpected handle count: %d", param->add_attr_tab.num_handle);
            return;
        }
        s_svc_handle  = param->add_attr_tab.handles[HANDLE_SVC_DECL];
        s_char_handle = param->add_attr_tab.handles[HANDLE_CHAR_VALUE];
        esp_ble_gatts_start_service(s_svc_handle);
        ESP_LOGI(TAG, "GATT service started (svc=%d, char=%d)", s_svc_handle, s_char_handle);
        break;

    case ESP_GATTS_CONNECT_EVT:
        s_conn_id   = param->connect.conn_id;
        s_connected = true;
        ESP_LOGI(TAG, "Client connected (conn_id=%d)", s_conn_id);
        /* Request maximum MTU */
        esp_ble_gatt_set_local_mtu(247);
        break;

    case ESP_GATTS_DISCONNECT_EVT:
        s_connected = false;
        ESP_LOGI(TAG, "Client disconnected, restarting advertising");
        esp_ble_gap_start_advertising(&s_adv_params);
        break;

    case ESP_GATTS_WRITE_EVT:
        if (param->write.handle == s_char_handle && param->write.len > 0) {
            /* B2: 转发给数据回调 */
            if (s_data_cb) {
                s_data_cb(param->write.value, param->write.len);
            }
        }
        /* Send write response (RSP_BY_APP mode) */
        if (param->write.need_rsp) {
            esp_ble_gatts_send_response(gatts_if, param->write.conn_id,
                param->write.trans_id, ESP_GATT_OK, NULL);
        }
        break;

    case ESP_GATTS_MTU_EVT:
        ESP_LOGI(TAG, "MTU updated to %d", param->mtu.mtu);
        break;

    case ESP_GATTS_START_EVT:
    case ESP_GATTS_STOP_EVT:
    default:
        break;
    }
}

/* ═══════════════════════════════════════════════════════════════
 *  Public API
 * ═══════════════════════════════════════════════════════════════ */
void proto_ble_init(void)
{
    ESP_LOGI(TAG, "Initializing BLE GATTS (device: %s, svc: 0x%04X, char: 0x%04X)",
             DEVICE_NAME, SVC_UUID, CHAR_UUID);

    /* Release Classic BT memory (ESP32-S3 BLE-only) */
    ESP_ERROR_CHECK(esp_bt_controller_mem_release(ESP_BT_MODE_CLASSIC_BT));

    esp_bt_controller_config_t bt_cfg = BT_CONTROLLER_INIT_CONFIG_DEFAULT();
    ESP_ERROR_CHECK(esp_bt_controller_init(&bt_cfg));
    ESP_ERROR_CHECK(esp_bt_controller_enable(ESP_BT_MODE_BLE));

    ESP_ERROR_CHECK(esp_bluedroid_init());
    ESP_ERROR_CHECK(esp_bluedroid_enable());

    ESP_ERROR_CHECK(esp_ble_gatts_register_callback(gatts_cb));
    ESP_ERROR_CHECK(esp_ble_gap_register_callback(gap_cb));
    ESP_ERROR_CHECK(esp_ble_gatts_app_register(GATTS_APP_ID));

    ESP_LOGI(TAG, "BLE GATTS initialized");
}

void proto_ble_start_advertising(void)
{
    esp_ble_gap_start_advertising(&s_adv_params);
}

void proto_ble_stop_advertising(void)
{
    esp_ble_gap_stop_advertising();
}

void proto_ble_notify(const char *data, uint16_t len)
{
    if (!s_connected || s_gatts_if == ESP_GATT_IF_NONE || s_char_handle == 0) {
        return;
    }

    /* Retry on congestion */
    for (int retry = 0; retry < 10; retry++) {
        esp_err_t err = esp_ble_gatts_send_indicate(
            s_gatts_if, s_conn_id, s_char_handle, len, (uint8_t *)data, false);
        if (err == ESP_OK) return;

        if (err == ESP_ERR_NO_MEM || err == ESP_GATT_CONGESTED) {
            vTaskDelay(pdMS_TO_TICKS(20));
            continue;
        }
        ESP_LOGW(TAG, "Notify failed: %s", esp_err_to_name(err));
        return;
    }
    ESP_LOGW(TAG, "Notify failed after 10 retries");
}

void proto_ble_notify_str(const char *str)
{
    if (!str) return;
    proto_ble_notify(str, (uint16_t)strlen(str));
}

bool proto_ble_is_connected(void)
{
    return s_connected;
}
