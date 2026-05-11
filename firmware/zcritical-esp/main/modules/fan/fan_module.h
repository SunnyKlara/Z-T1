/* ═══════════════════════════════════════════════════════════════
 * STEER: 反臃肿 | scope=firmware | modules/fan/
 *
 * 职责: 风扇+油门模块 — PWM 调速、速度映射、单位切换
 * 不做什么: 不直接驱动硬件（通过 core/hal/）
 * ═══════════════════════════════════════════════════════════════ */

#pragma once
#include <stdint.h>

void fan_module_init(void);
void fan_module_set(uint8_t speed_pct);       /* 0-100 PWM */
void fan_module_set_speed(uint16_t display);  /* 0-340 km/h 显示值 */
void fan_module_set_throttle(uint8_t on);     /* 0=关, 1=开 */
