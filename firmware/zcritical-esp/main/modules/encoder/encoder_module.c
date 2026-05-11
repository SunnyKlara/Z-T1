/* ═══════════════════════════════════════════════════════════════
 * STEER: 反臃肿 | scope=firmware | modules/encoder/
 *
 * 职责: 编码器 → 菜单导航/子界面操作
 * 参照: ridewind-esp encoder_handler + drv_encoder
 *
 * 操作: 旋转=翻页/调值  单击=进入/确认  双击=返回菜单
 * ═══════════════════════════════════════════════════════════════ */

#include "encoder_module.h"
#include "core/hal/hal_encoder.h"
#include "core/state/app_state.h"
#include "core/protocol/proto_ble.h"
#include "modules/display/display_module.h"
#include "modules/fan/fan_module.h"
#include "modules/led/led_module.h"
#include "esp_log.h"
#include "esp_timer.h"
#include <stdio.h>

static const char *TAG = "ENC";

#define CLICK_TIMEOUT_MS  400
static uint32_t s_last_click_tick = 0;
static uint8_t  s_click_count = 0;

static uint32_t now_ms(void) {
    return (uint32_t)(esp_timer_get_time()/1000);
}

void encoder_module_init(void) {
    s_click_count = 0;
    s_last_click_tick = 0;
    ESP_LOGI(TAG,"Encoder ready");
}

void encoder_module_poll(void)
{
    hal_encoder_event_t evt;
    if (!hal_encoder_poll(&evt)) return;

    uint8_t page;
    APP_STATE_LOCK(); page = g_app_state.ui.page; APP_STATE_UNLOCK();

    uint32_t t = now_ms();

    /* ── 双击超时重置 ── */
    if (s_click_count > 0 && t - s_last_click_tick > CLICK_TIMEOUT_MS) {
        s_click_count = 0;
    }

    /* ── 单击处理 ── */
    if (evt.type == HAL_ENC_EVT_CLICK) {
        s_click_count++;
        s_last_click_tick = t;

        /* ── 双击: 任何页面 → 回菜单 ── */
        if (s_click_count >= 2) {
            ESP_LOGI(TAG,"Double-click → Menu");
            s_click_count = 0;
            display_module_switch(PAGE_MENU);
            return;
        }

        /* ── 菜单页: 单击进入子界面 ── */
        if (page == PAGE_MENU) {
            display_menu_select();
            s_click_count = 0;
            return;
        }

        /* ── Speed: 单击切换单位 ── */
        if (page == PAGE_SPEED) {
            APP_STATE_LOCK();
            g_app_state.fan.unit = (g_app_state.fan.unit==0)?1:0;
            APP_STATE_UNLOCK();
            return;
        }
        return;
    }

    /* ── 长按: 总回到菜单 ── */
    if (evt.type == HAL_ENC_EVT_LONG_PRESS) {
        ESP_LOGI(TAG,"Long-press → Menu");
        display_module_switch(PAGE_MENU);
        return;
    }

    /* ── 旋转处理 ── */
    if (evt.type == HAL_ENC_EVT_ROTATE) {
        int d = evt.delta;

        switch (page) {

        case PAGE_MENU:
            display_menu_navigate(d);
            break;

        case PAGE_SPEED: {
            APP_STATE_LOCK();
            int16_t ns = (int16_t)g_app_state.fan.speed + d;
            APP_STATE_UNLOCK();
            if (ns<0) ns=0;
            if (ns>100) ns=100;
            fan_module_set((uint8_t)ns);
            /* BLE 上报 */
            char r[32];
            snprintf(r,sizeof(r),"SPEED_REPORT:%d:%d",
                (int)(ns*3.4f), g_app_state.fan.unit);
            proto_ble_notify_str(r);
            break;
        }

        case PAGE_COLOR: {
            APP_STATE_LOCK();
            int8_t np = (int8_t)g_app_state.led.preset + d;
            APP_STATE_UNLOCK();
            if (np<1) np=14;
            if (np>14) np=1;
            led_module_preset((uint8_t)np);
            char r[32];
            snprintf(r,sizeof(r),"PRESET_REPORT:%d",np);
            proto_ble_notify_str(r);
            break;
        }

        case PAGE_RGB:
            display_rgb_rotate(d);
            break;

        case PAGE_BRIGHT: {
            APP_STATE_LOCK();
            int16_t nb = (int16_t)g_app_state.led.brightness + d*5;
            APP_STATE_UNLOCK();
            if (nb<0) nb=0;
            if (nb>100) nb=100;
            led_module_brightness((uint8_t)nb);
            break;
        }

        case PAGE_VOLUME: {
            APP_STATE_LOCK();
            int16_t nv = (int16_t)g_app_state.audio.volume + d*5;
            APP_STATE_UNLOCK();
            if (nv<0) nv=0;
            if (nv>100) nv=100;
            APP_STATE_LOCK(); g_app_state.audio.volume=(uint8_t)nv; APP_STATE_UNLOCK();
            break;
        }

        default: break;
        }
    }
}
