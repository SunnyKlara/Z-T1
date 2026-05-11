/* ═══════════════════════════════════════════════════════════════
 * STEER: 反臃肿 | scope=firmware | modules/encoder/
 *
 * 职责: 编码器事件处理 — 旋转→调速/切换预设，按键→菜单
 * 不做什么: 不直接读硬件（通过 core/hal/hal_encoder）
 * ═══════════════════════════════════════════════════════════════ */

#pragma once

void encoder_module_init(void);
void encoder_module_poll(void);        /* 每周期轮询编码器事件 */
