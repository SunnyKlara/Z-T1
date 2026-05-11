/* ═══════════════════════════════════════════════════════════════
 * STEER: 反臃肿 | scope=firmware | modules/display/
 *
 * 职责: LCD 显示 — 启动自检 + 7页菜单 + 子界面渲染
 * 参照: ridewind-esp ui_manager + ui_menu 设计
 * 不做什么: 不操作 SPI（hal_lcd）、不处理输入（encoder_module）
 *
 * 页面: 0=Menu, 1=Speed, 2=Color, 3=RGB, 4=Bright, 5=Logo, 6=Volume
 * ═══════════════════════════════════════════════════════════════ */

#pragma once
#include <stdint.h>

/* 页面ID — 与 ridewind-esp 对齐 */
#define PAGE_MENU       0
#define PAGE_SPEED      1
#define PAGE_COLOR      2
#define PAGE_RGB        3
#define PAGE_BRIGHT     4
#define PAGE_LOGO       5
#define PAGE_VOLUME     6
#define PAGE_COUNT      7

void display_module_init(void);
void display_module_switch(uint8_t page);
void display_module_lcd_on(uint8_t on);
void display_module_render(void);

/* ── 菜单导航（由 encoder_module 调用）── */
void display_menu_navigate(int8_t dir);
void display_menu_select(void);

/* ── RGB 编码器操作 ── */
void display_rgb_rotate(int delta);

/* 子界面 enter（首次进入全量渲染）*/
void display_speed_enter(void);
void display_color_enter(void);
void display_rgb_enter(void);
void display_bright_enter(void);
void display_logo_enter(void);
void display_volume_enter(void);

/* 子界面 update（增量渲染） */
void display_speed_update(void);
void display_color_update(void);
void display_rgb_update(void);
void display_bright_update(void);
void display_logo_update(void);
void display_volume_update(void);
