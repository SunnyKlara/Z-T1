/* ═══════════════════════════════════════════════════════════════
 * STEER: 反臃肿 | scope=firmware | core/state/
 *
 * 职责: UI 页面状态的子结构体定义
 * 不做什么: 不包含 LCD 渲染逻辑（属于 modules/display/）
 * ═══════════════════════════════════════════════════════════════ */

#pragma once
#include <stdint.h>

typedef struct {
    uint8_t page;            /* 当前页面 1=Speed/2=Color/3=RGB/4=Bright/5=Menu/6=Logo/8=Treadmill */
    uint8_t menu_selected;   /* 菜单选中项 */
    uint8_t lcd_on;          /* 0=熄屏, 1=开屏 */
} ui_state_t;
