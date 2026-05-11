/* ═══════════════════════════════════════════════════════════════
 * STEER: 反臃肿 | max_lines=45 | scope=firmware | 修改前读 anti-bloat.md
 *
 * 职责: GC9A01 圆形 LCD SPI 驱动 — 初始化 SPI + GC9A01 初始化序列 + 画图基元
 * 不做什么: 不处理 UI 渲染逻辑（由 modules/display/ 负责）、不管理字库
 *
 * 硬件 (唯一真值源: steering/specs/hardware-config.md):
 *   CS=IO4, DC=IO5, SDA(MOSI)=IO6, SCL=IO7
 *   SPI2_HOST, 40MHz, 240×240 分辨率
 * ═══════════════════════════════════════════════════════════════ */

#pragma once

#include <stdint.h>
#include <stdbool.h>

#define HAL_LCD_WIDTH   240
#define HAL_LCD_HEIGHT  240

void hal_lcd_init(void);

/* 窗口设置 + 发送像素数据 */
void hal_lcd_set_window(uint16_t x0, uint16_t y0, uint16_t x1, uint16_t y1);
void hal_lcd_write_data(const uint8_t *data, uint32_t len);

/* 绘图基元 */
void hal_lcd_clear(uint16_t color);
void hal_lcd_draw_pixel(uint16_t x, uint16_t y, uint16_t color);
void hal_lcd_fill_rect(uint16_t x, uint16_t y, uint16_t w, uint16_t h, uint16_t color);
void hal_lcd_draw_circle(uint16_t cx, uint16_t cy, uint16_t r, uint16_t color, bool filled);
void hal_lcd_draw_line(uint16_t x0, uint16_t y0, uint16_t x1, uint16_t y1, uint16_t color);
void hal_lcd_draw_string(uint16_t x, uint16_t y, const char *str,
                         uint16_t fg, uint16_t bg, uint8_t size);

/* 图像块传输 */
void hal_lcd_blit_rgb565(uint16_t x, uint16_t y, uint16_t w, uint16_t h,
                         const uint16_t *data);

/* 背光控制 */
void hal_lcd_set_backlight(bool on);
