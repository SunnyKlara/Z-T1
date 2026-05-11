/* ═══════════════════════════════════════════════════════════════
 * STEER: 反臃肿 | max_lines=30 | scope=firmware | 修改前读 anti-bloat.md
 *
 * 职责: 加湿器 GPIO 开关驱动 — 初始化 IO10 为输出 + 开/关/读取
 * 不做什么: 不处理业务逻辑（油门模式由 modules/ 负责）
 *
 * 硬件 (唯一真值源: steering/specs/hardware-config.md):
 *   GPIO IO10 → MOS管 CH1 → 超声波雾化片
 * ═══════════════════════════════════════════════════════════════ */

#pragma once

#include <stdbool.h>

void hal_gpio_init(void);
void hal_gpio_set(bool on);
bool hal_gpio_get(void);
