/* ═══════════════════════════════════════════════════════════════
 * STEER: ui demo branch | scope=firmware/ui
 *
 * 职责: LVGL 适配层 — display flush + tick + indev
 * ═══════════════════════════════════════════════════════════════ */

#pragma once

#ifdef __cplusplus
extern "C" {
#endif

/* 初始化 LVGL + 注册 display + 编码器 indev + 启动 LVGL 任务 */
void ui_port_init(void);

#ifdef __cplusplus
}
#endif
