/* ═══════════════════════════════════════════════════════════════
 * STEER: 反臃肿 | scope=firmware | core/protocol/
 *
 * 职责: 命令分发 — 解析结果 → 调用 modules/ + 修改 state + BLE 回复
 * 不做什么: 不解析文本（proto_parser）、不直接操作 HAL（通过 modules/）
 * ═══════════════════════════════════════════════════════════════ */

#include "proto_dispatch.h"
#include "proto_ble.h"
#include "../state/app_state.h"
#include "../../modules/fan/fan_module.h"
#include "../../modules/led/led_module.h"
#include "../../modules/display/display_module.h"
#include "../../modules/audio/audio_module.h"
#include "../../modules/logo/logo_module.h"
#include "../../modules/wifi/wifi_module.h"
#include <stdio.h>

void proto_dispatch(const cmd_msg_t *cmd)
{
    char resp[128];
    resp[0] = '\0';

    switch (cmd->type) {

    /* ── 风扇/速度 ── */
    case CMD_FAN:
        fan_module_set((uint8_t)cmd->params[0]);
        snprintf(resp, sizeof(resp), "OK:FAN");
        break;

    case CMD_SPEED:
        fan_module_set_speed((uint16_t)cmd->params[0]);
        return; /* 高频命令无响应 */

    case CMD_WUHUA:
        APP_STATE_LOCK();
        g_app_state.fan.wuhuaqi = (uint8_t)cmd->params[0];
        APP_STATE_UNLOCK();
        snprintf(resp, sizeof(resp), "OK:WUHUA");
        break;

    /* ── LED ── */
    case CMD_LED:
        led_module_set_strip(
            (uint8_t)(cmd->params[0] - 1),
            (uint8_t)cmd->params[1],
            (uint8_t)cmd->params[2],
            (uint8_t)cmd->params[3]);
        snprintf(resp, sizeof(resp), "OK:LED");
        break;

    case CMD_PRESET:
        led_module_preset((uint8_t)cmd->params[0]);
        snprintf(resp, sizeof(resp), "OK:PRESET");
        break;

    case CMD_BRIGHT:
        led_module_brightness((uint8_t)cmd->params[0]);
        snprintf(resp, sizeof(resp), "OK:BRIGHT");
        break;

    case CMD_STREAMLIGHT:
        led_module_streamlight((uint8_t)cmd->params[0]);
        snprintf(resp, sizeof(resp), "OK:STREAMLIGHT:%d", (int)cmd->params[0]);
        break;

    case CMD_LED_GRADIENT:
        led_module_gradient(
            (uint8_t)cmd->params[0], (uint8_t)cmd->params[1],
            (uint8_t)cmd->params[2], (uint8_t)cmd->params[3],
            (uint8_t)cmd->params[4]);
        snprintf(resp, sizeof(resp), "OK:LED_GRADIENT");
        break;

    /* ── LCD/UI ── */
    case CMD_LCD:
        display_module_lcd_on((uint8_t)cmd->params[0]);
        snprintf(resp, sizeof(resp), "OK:LCD");
        break;

    case CMD_UI:
        display_module_switch((uint8_t)cmd->params[0]);
        snprintf(resp, sizeof(resp), "OK:UI");
        break;

    /* ── 音量 ── */
    case CMD_VOL:
        audio_module_set_volume((uint8_t)cmd->params[0]);
        snprintf(resp, sizeof(resp), "OK:VOL");
        break;

    /* ── 油门 ── */
    case CMD_THROTTLE:
        fan_module_set_throttle((uint8_t)cmd->params[0]);
        snprintf(resp, sizeof(resp), "OK:THROTTLE");
        break;

    case CMD_UNIT:
        APP_STATE_LOCK();
        g_app_state.fan.unit = (uint8_t)cmd->params[0];
        APP_STATE_UNLOCK();
        snprintf(resp, sizeof(resp), "OK:UNIT");
        break;

    case CMD_TREAD:
        APP_STATE_LOCK();
        g_app_state.fan.wuhuaqi = (uint8_t)(cmd->params[0] ? 2 : 0);
        APP_STATE_UNLOCK();
        snprintf(resp, sizeof(resp), "OK:TREAD:%d", (int)cmd->params[0]);
        break;

    /* ── GET 查询 ── */
    case CMD_GET_ALL:
        APP_STATE_LOCK();
        snprintf(resp, sizeof(resp), "STATUS:FAN:%d:WUHUA:%d:BRIGHT:%d",
            g_app_state.fan.speed,
            g_app_state.fan.wuhuaqi,
            g_app_state.led.brightness);
        APP_STATE_UNLOCK();
        break;

    case CMD_GET_FAN:
        APP_STATE_LOCK();
        snprintf(resp, sizeof(resp), "FAN:%d", g_app_state.fan.speed);
        APP_STATE_UNLOCK();
        break;

    case CMD_GET_WUHUA:
        APP_STATE_LOCK();
        snprintf(resp, sizeof(resp), "WUHUA:%d", g_app_state.fan.wuhuaqi);
        APP_STATE_UNLOCK();
        break;

    case CMD_GET_BRIGHT:
        APP_STATE_LOCK();
        snprintf(resp, sizeof(resp), "BRIGHT:%d", g_app_state.led.brightness);
        APP_STATE_UNLOCK();
        break;

    case CMD_GET_PRESET:
        APP_STATE_LOCK();
        snprintf(resp, sizeof(resp), "PRESET_REPORT:%d", g_app_state.led.preset);
        APP_STATE_UNLOCK();
        break;

    case CMD_GET_UI:
        APP_STATE_LOCK();
        snprintf(resp, sizeof(resp), "UI:%d", g_app_state.ui.page);
        APP_STATE_UNLOCK();
        break;

    case CMD_GET_LOGO:
        APP_STATE_LOCK();
        snprintf(resp, sizeof(resp), "LOGO_SLOTS:%d:%d:%d:%d",
            g_app_state.logo.slots[0], g_app_state.logo.slots[1],
            g_app_state.logo.slots[2], g_app_state.logo.active_slot);
        APP_STATE_UNLOCK();
        break;

    case CMD_GET_VOL:
        APP_STATE_LOCK();
        snprintf(resp, sizeof(resp), "VOL:%d", g_app_state.audio.volume);
        APP_STATE_UNLOCK();
        break;

    case CMD_GET_TREAD:
        snprintf(resp, sizeof(resp), "TREAD_REPORT:0");
        break;

    case CMD_GET_STREAMLIGHT:
        APP_STATE_LOCK();
        snprintf(resp, sizeof(resp), "STREAMLIGHT:%d", g_app_state.led.streamlight);
        APP_STATE_UNLOCK();
        break;

    /* ── WiFi ── */
    case CMD_WIFI:
        wifi_module_connect((int32_t)cmd->params[0], NULL);
        snprintf(resp, sizeof(resp), "OK:WIFI");
        break;

    case CMD_WIFI_SCAN:
        snprintf(resp, sizeof(resp), "WIFI_SCAN:USE_PHONE");
        break;

    /* ── Logo ── */
    case CMD_LOGO_START:
    case CMD_LOGO_START_BIN:
        logo_module_init();
        snprintf(resp, sizeof(resp), "LOGO_READY:%d", (int)cmd->params[0]);
        break;

    case CMD_LOGO_DATA:
        snprintf(resp, sizeof(resp), "LOGO_ACK:%d", (int)cmd->params[0]);
        break;

    case CMD_LOGO_END:
        snprintf(resp, sizeof(resp), "LOGO_OK:0");
        break;

    case CMD_LOGO_DELETE:
        snprintf(resp, sizeof(resp), "OK:LOGO_DELETE");
        break;

    default:
        return;
    }

    if (resp[0]) {
        proto_ble_notify_str(resp);
    }
}
