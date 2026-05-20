/* ═══════════════════════════════════════════════════════════════
 * STEER: ui demo branch
 *
 * 职责: LVGL UI demo — 3 个 screen 演示 LVGL 视觉能力
 *
 * Screen 1: 速度仪表盘（圆弧 + 大数字 + 平滑动画）
 * Screen 2: 主菜单（7 项 + 滑动切换）
 * Screen 3: 渐变色谱（演示渐变色块）
 *
 * 操作: 旋转编码器 → 在当前 screen 内调整 / 翻菜单
 *      单击 → 切换到下一个 screen
 * ═══════════════════════════════════════════════════════════════ */

#pragma once

#ifdef __cplusplus
extern "C" {
#endif

void ui_demo_create(void);
void ui_demo_on_click(void);  /* 由 ui_port 调用 */

#ifdef __cplusplus
}
#endif
