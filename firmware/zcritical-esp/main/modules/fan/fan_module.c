/* ═══════════════════════════════════════════════════════════════
 * STEER: 反臃肿 | scope=firmware | modules/fan/
 *
 * 职责: 风扇+油门 — 接收上层指令 → 调用 hal_pwm / hal_gpio → 更新 state
 * ═══════════════════════════════════════════════════════════════ */

#include "fan_module.h"
#include "core/hal/hal_pwm.h"
#include "core/hal/hal_gpio.h"
#include "core/state/app_state.h"
#include "esp_log.h"

static const char *TAG = "FAN";

void fan_module_init(void)
{
    ESP_LOGI(TAG, "Fan module initialized");
}

void fan_module_set(uint8_t speed_pct)
{
    if (speed_pct > 100) speed_pct = 100;
    hal_pwm_set_duty(speed_pct);
    APP_STATE_LOCK();
    g_app_state.fan.speed = speed_pct;
    APP_STATE_UNLOCK();
}

void fan_module_set_speed(uint16_t display)
{
    /* 显示值 km/h → 内部值: /3.4 */
    uint16_t internal = (uint16_t)((float)display / 3.4f);
    if (internal > 100) internal = 100;
    fan_module_set((uint8_t)internal);
}

void fan_module_set_throttle(uint8_t on)
{
    if (on) {
        hal_gpio_set(true); /* 油门模式强制开加湿器 */
        APP_STATE_LOCK();
        g_app_state.fan.wuhuaqi = 2;
        APP_STATE_UNLOCK();
    } else {
        APP_STATE_LOCK();
        g_app_state.fan.wuhuaqi = 0;
        APP_STATE_UNLOCK();
    }
}
