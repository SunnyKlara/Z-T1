/* ═══════════════════════════════════════════════════════════════
 * STEER: 反臃肿 | max_lines=30 | scope=firmware | 修改前读 anti-bloat.md
 *
 * 职责: 风扇 LEDC PWM 驱动 — 初始化 IO40 PWM + 设置占空比(0-100%) + 读取
 * 不做什么: 不处理速度映射（kmh↔% 由 modules/ 负责）
 *
 * 硬件 (唯一真值源: steering/specs/hardware-config.md):
 *   GPIO IO40 → MOS管 CH2 → 风扇 PWM 调速
 *   频率 1000Hz, 分辨率 10-bit (0-1023)
 * ═══════════════════════════════════════════════════════════════ */

#pragma once

#include <stdint.h>

void hal_pwm_init(void);
void hal_pwm_set_duty(uint8_t percent);
uint8_t hal_pwm_get_duty(void);
