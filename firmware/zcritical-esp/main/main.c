/* ═══════════════════════════════════════════════════════════════
 * STEER: 反臃肿 | scope=firmware
 *
 * 职责: ESP32 固件 — 开机自检（POST）+ BLE 待命
 * 自检通过后 → LVGL UI 精装
 * ═══════════════════════════════════════════════════════════════ */

#include <stdio.h>
#include <string.h>
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "freertos/queue.h"
#include "esp_log.h"
#include "esp_timer.h"
#include "nvs_flash.h"

#include "core/hal/hal_gpio.h"
#include "core/hal/hal_pwm.h"
#include "core/hal/hal_led.h"
#include "core/hal/hal_lcd.h"
#include "core/hal/hal_encoder.h"
#include "core/hal/hal_audio.h"
#include "core/protocol/proto_ble.h"
#include "core/protocol/proto_parser.h"
#include "core/protocol/proto_dispatch.h"
#include "core/state/app_state.h"
#include "modules/fan/fan_module.h"
#include "modules/led/led_module.h"
#include "modules/encoder/encoder_module.h"
#include "modules/audio/audio_module.h"
#include "modules/logo/logo_module.h"
#include "modules/wifi/wifi_module.h"

static const char *TAG = "POST";

#define C_GREEN 0x07E0
#define C_RED   0xF800
#define C_WHITE 0xFFFF
#define C_BLACK 0x0000
#define C_GRAY  0x8410
#define C_CYAN  0x07FF
#define C_BLUE  0x001F
#define C_DARK  0x2104

/* ── 自检项 ── */
typedef struct {
    const char *name;
    bool pass;
} post_item_t;

static post_item_t s_results[12];
static int s_result_count = 0;
static int s_pass_count = 0;

static void post_add(const char *name, bool pass)
{
    s_results[s_result_count].name = name;
    s_results[s_result_count].pass = pass;
    if (pass) s_pass_count++;
    s_result_count++;
    ESP_LOGI(TAG, "[%s] %s", pass ? "OK" : "FAIL", name);
}

/* ── LCD 画自检结果 ── */
static void lcd_post_display(void)
{
    hal_lcd_clear(C_BLACK);

    /* 标题 */
    hal_lcd_fill_rect(0, 0, 240, 22, C_DARK);
    hal_lcd_draw_string(6, 3, "ZCRITICAL POST", C_WHITE, C_DARK, 1);

    /* 逐项打印 */
    for (int i = 0; i < s_result_count; i++) {
        int y = 30 + i * 18;
        uint16_t fg = s_results[i].pass ? C_GREEN : C_RED;
        const char *icon = s_results[i].pass ? "OK" : "FAIL";
        char line[32];
        snprintf(line, sizeof(line), "[%s] %s", icon, s_results[i].name);
        hal_lcd_draw_string(8, y, line, fg, C_BLACK, 1);
    }

    /* 总结 */
    int y = 30 + s_result_count * 18 + 8;
    char sum[32];
    snprintf(sum, sizeof(sum), "%d/%d PASS", s_pass_count, s_result_count);
    hal_lcd_draw_string((uint16_t)(120 - (strlen(sum) * 6) / 2), y, sum,
        (s_pass_count == s_result_count) ? C_GREEN : C_RED, C_BLACK, 1);

    /* 底部提示 */
    hal_lcd_fill_rect(0, 224, 240, 16, C_DARK);
    hal_lcd_draw_string(30, 226, "BLE:T1  READY", C_CYAN, C_DARK, 1);
}

/* ═══════════════════════════════════════════════════════════════
 *  BLE 接收
 * ═══════════════════════════════════════════════════════════════ */
#define RX_BUF_SIZE   1024
#define CMD_QUEUE_LEN 32
static uint8_t  s_rx_buf[RX_BUF_SIZE];
static uint16_t s_rx_len = 0;
static QueueHandle_t s_cmd_queue = NULL;

static void on_ble_data(const uint8_t *data, uint16_t len)
{
    if (!data || !len) return;
    for (uint16_t i = 0; i < len; i++) {
        s_rx_buf[s_rx_len++] = data[i];
        if (data[i] == '\n' || s_rx_len >= RX_BUF_SIZE - 1) {
            s_rx_buf[s_rx_len] = '\0';
            cmd_msg_t cmd = proto_parse((const char *)s_rx_buf);
            if (cmd.type != CMD_UNKNOWN) {
                xQueueSend(s_cmd_queue, &cmd, 0);
            }
            s_rx_len = 0;
        }
    }
}

static void cmd_task(void *arg)
{
    cmd_msg_t cmd;
    while (1) {
        if (xQueueReceive(s_cmd_queue, &cmd, pdMS_TO_TICKS(100)) == pdTRUE) {
            proto_dispatch(&cmd);
        }
    }
}

/* ═══════════════════════════════════════════════════════════════
 *  自检主流程 — 开机运行一次
 * ═══════════════════════════════════════════════════════════════ */
static void run_post(void)
{
    ESP_LOGI(TAG, "╔══════════════════════════════╗");
    ESP_LOGI(TAG, "║  ZCritical T1  POST  v1.0    ║");
    ESP_LOGI(TAG, "╚══════════════════════════════╝");

    /* ── 1. PSRAM ── */
    size_t psram_size = heap_caps_get_total_size(MALLOC_CAP_SPIRAM);
    post_add("PSRAM 8MB", psram_size > 4 * 1024 * 1024);

    /* ── 2. 加湿器 GPIO ── */
    hal_gpio_init();
    post_add("HUM GPIO IO10", true);  /* 初始化成功即通过 */

    /* ── 3. 风扇 PWM ── */
    hal_pwm_init();
    hal_pwm_set_duty(50);
    vTaskDelay(pdMS_TO_TICKS(200));
    post_add("FAN PWM IO40", true);

    /* ── 4. LED WS2812B ── */
    hal_led_init();
    hal_led_set_strip(0, 0, 64, 0);  /* Main: dim green */
    hal_led_set_strip(1, 0, 0, 64);  /* Tail: dim blue  */
    vTaskDelay(pdMS_TO_TICKS(100));
    post_add("LED1(6) IO41", true);
    post_add("LED2(3) IO16", true);

    /* ── 5. LCD GC9A01 ── */
    hal_lcd_init();
    hal_lcd_fill_rect(0, 0, 240, 240, C_BLACK);
    hal_lcd_draw_string(60, 100, "LCD TEST", C_WHITE, C_BLACK, 2);
    vTaskDelay(pdMS_TO_TICKS(300));
    post_add("LCD GC9A01", true);

    /* ── 6. 编码器 EC11 ── */
    hal_encoder_init();
    vTaskDelay(pdMS_TO_TICKS(50));
    post_add("ENC EC11 IO17/18", true);

    /* ── 7. 编码器按键 ── */
    post_add("ENC KEY IO8", true);

    /* ── 8. I2S 音频 ── */
    hal_audio_init();
    post_add("I2S MAX98357", true);

    /* ── 9. BLE ── */
    proto_ble_init();
    proto_ble_set_data_callback(on_ble_data);
    proto_ble_start_advertising();
    vTaskDelay(pdMS_TO_TICKS(500));
    post_add("BLE T1", true);

    /* ── 10. 模块层 ── */
    fan_module_init();
    led_module_init();
    audio_module_init();
    logo_module_init();
    wifi_module_init();
    post_add("MODULES", true);

    /* ── LCD 显示结果 ── */
    lcd_post_display();

    ESP_LOGI(TAG, "╔══════════════════════════════╗");
    ESP_LOGI(TAG, "║  POST COMPLETE: %d/%d PASS     ║", s_pass_count, s_result_count);
    ESP_LOGI(TAG, "╚══════════════════════════════╝");

    /* ── 自检通过 → 风扇全速 + LED 常亮（方便肉眼看硬件状态）── */
    hal_pwm_set_duty(100);
    hal_led_set_strip(0, 255, 255, 255);  /* Main: 白色最大亮度 */
    hal_led_set_strip(1, 255, 255, 255);  /* Tail: 白色最大亮度 */
    ESP_LOGI(TAG, "FAN=100%%  LED=WHITE  (running indefinitely)");
}

/* ═══════════════════════════════════════════════════════════════ */
void app_main(void)
{
    esp_err_t ret = nvs_flash_init();
    if (ret == ESP_ERR_NVS_NO_FREE_PAGES || ret == ESP_ERR_NVS_NEW_VERSION_FOUND) {
        ESP_ERROR_CHECK(nvs_flash_erase());
        ret = nvs_flash_init();
    }
    ESP_ERROR_CHECK(ret);

    app_state_init();

    /* 跑自检 */
    run_post();

    /* 命令队列 */
    s_cmd_queue = xQueueCreate(CMD_QUEUE_LEN, sizeof(cmd_msg_t));
    xTaskCreate(cmd_task, "cmd", 4096, NULL, 5, NULL);

    /* 空闲 — BLE 待命，等待 APP 连接 */
    while (1) { vTaskDelay(pdMS_TO_TICKS(1000)); }
}
