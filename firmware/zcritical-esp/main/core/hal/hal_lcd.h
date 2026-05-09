#pragma once

/* ═══════════════════════════════════════════════════════════════
 * STEER: 反臃肿 | max_lines=50 | scope=firmware | 修改前读 anti-bloat.md
 *
 * 职责: GC9A01 圆形 LCD SPI 驱动 — 初始化、像素绘制、区域填充、清屏
 * 不做什么: 不含 UI 逻辑、不含 framebuffer 管理策略、不含显示内容组合
 * 硬件: 240×240 RGB565, SPI @40MHz, CS=IO4, DC=IO5, SDA=IO6, SCL=IO7
 *        — 唯一真值源 hardware-config.md
 * ═══════════════════════════════════════════════════════════════ */

#include <stdint.h>
#include <stdbool.h>
#include "esp_err.h"

esp_err_t hal_lcd_init(void);
void hal_lcd_draw_pixel(uint16_t x, uint16_t y, uint16_t color);
void hal_lcd_fill_rect(uint16_t x, uint16_t y, uint16_t w, uint16_t h, uint16_t color);
void hal_lcd_set_window(uint16_t x0, uint16_t y0, uint16_t x1, uint16_t y1);
void hal_lcd_write_data(const uint8_t *data, uint32_t len);
void hal_lcd_blit_dma(uint16_t x, uint16_t y, uint16_t w, uint16_t h, const uint16_t *data);
void hal_lcd_clear(uint16_t color);
