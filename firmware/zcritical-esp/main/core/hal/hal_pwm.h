#pragma once

/* ═══════════════════════════════════════════════════════════════
 * STEER: 反臃肿 | ref_lines=30 | scope=firmware | 修改前读 anti-bloat.md
 *
 * 职责: LEDC PWM 驱动 — 风扇 MOS 管调速 (IO40, CH2)
 * 不做什么: 不含油门逻辑、不含速度映射、不含风扇状态机
 * 引脚: IO40 — 唯一真值源 hardware-config.md
 * ═══════════════════════════════════════════════════════════════ */

#include <stdint.h>
#include "esp_err.h"

esp_err_t hal_pwm_init(void);
void hal_pwm_set_duty(uint8_t percent);
uint8_t hal_pwm_get_duty(void);
