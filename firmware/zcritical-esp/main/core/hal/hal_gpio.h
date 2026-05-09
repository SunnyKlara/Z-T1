#pragma once

/* ═══════════════════════════════════════════════════════════════
 * STEER: 反臃肿 | ref_lines=30 | scope=firmware | 修改前读 anti-bloat.md
 *
 * 职责: GPIO 驱动 — 加湿器 MOS 管开关控制
 * 不做什么: 不含状态管理、不含加湿器业务逻辑（modules/humidifier/）
 * 引脚: IO10 (CH1, MOS 管开关) — 唯一真值源 hardware-config.md
 * ═══════════════════════════════════════════════════════════════ */

#include <stdint.h>
#include <stdbool.h>
#include "esp_err.h"

esp_err_t hal_gpio_init(void);
void hal_gpio_set_humidifier(bool on);
bool hal_gpio_get_humidifier(void);
