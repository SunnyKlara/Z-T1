/* ═══════════════════════════════════════════════════════════════
 * STEER: 反臃肿 | scope=firmware | modules/led/
 *
 * 职责: LED 控制模块 — 预设/单色/亮度/流水灯/渐变
 * 不做什么: 不直接驱动 RMT（通过 core/hal/hal_led）
 * ═══════════════════════════════════════════════════════════════ */

#pragma once
#include <stdint.h>

void led_module_init(void);
void led_module_set_strip(uint8_t strip, uint8_t r, uint8_t g, uint8_t b);
void led_module_preset(uint8_t preset);    /* 1-14 */
void led_module_brightness(uint8_t pct);   /* 0-100 */
void led_module_streamlight(uint8_t on);
void led_module_gradient(uint8_t strip, uint8_t r, uint8_t g, uint8_t b, uint8_t speed);
void led_module_task(void);                /* 后台特效更新 */
