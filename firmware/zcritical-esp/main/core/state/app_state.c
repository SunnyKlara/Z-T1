/* ═══════════════════════════════════════════════════════════════
 * STEER: 反臃肿 | scope=firmware | core/state/
 *
 * 职责: 全局状态初始化 + 默认值
 * ═══════════════════════════════════════════════════════════════ */

#include "app_state.h"

app_state_t g_app_state = {0};
SemaphoreHandle_t g_state_mutex = NULL;

void app_state_init(void)
{
    g_state_mutex = xSemaphoreCreateMutex();

    /* 风扇默认值 */
    g_app_state.fan.speed   = 0;
    g_app_state.fan.wuhuaqi = 0;
    g_app_state.fan.unit    = 0; /* km/h */

    /* LED 默认值 */
    g_app_state.led.colors[0][0] = 255; /* Main: red */
    g_app_state.led.colors[0][1] = 0;
    g_app_state.led.colors[0][2] = 0;
    g_app_state.led.colors[1][0] = 255; /* Tail: red */
    g_app_state.led.colors[1][1] = 0;
    g_app_state.led.colors[1][2] = 0;
    g_app_state.led.brightness  = 80;
    g_app_state.led.preset      = 1;   /* Flame Red */
    g_app_state.led.streamlight = 0;
    g_app_state.led.gradient_speed = 0;

    /* UI 默认值 */
    g_app_state.ui.page          = 1; /* Speed */
    g_app_state.ui.menu_selected = 0;
    g_app_state.ui.lcd_on        = 1;

    /* 音频默认值 */
    g_app_state.audio.volume    = 50;
    g_app_state.audio.engine_on = 0;

    /* Logo 默认值 */
    g_app_state.logo.active_slot = 0;
    g_app_state.logo.slots[0]    = 0;
    g_app_state.logo.slots[1]    = 0;
    g_app_state.logo.slots[2]    = 0;
}
