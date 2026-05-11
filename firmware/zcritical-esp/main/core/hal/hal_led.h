/* ═══════════════════════════════════════════════════════════════
 * STEER: 反臃肿 | max_lines=40 | scope=firmware | 修改前读 anti-bloat.md
 *
 * 职责: WS2812B LED 驱动 — 初始化 RMT 2条灯带 + 单像素/全灯带颜色 + 亮度 + 刷新
 * 不做什么: 不处理预设选择（由 modules/led/ 负责）、不处理特效/渐变
 *
 * 硬件 (唯一真值源: steering/specs/hardware-config.md):
 *   LED1 (strip 0): IO41, 6颗主灯
 *   LED2 (strip 1): IO16, 3颗尾灯
 *   LED_PIXEL_FORMAT_GRB, 10MHz RMT
 * ═══════════════════════════════════════════════════════════════ */

#pragma once

#include <stdint.h>

#define HAL_LED_STRIP_MAIN  0
#define HAL_LED_STRIP_TAIL  1

#define HAL_LED_MAIN_COUNT  6
#define HAL_LED_TAIL_COUNT  3

void hal_led_init(void);

/* 设置单个物理像素 (strip: 0=Main/IO41, 1=Tail/IO16) */
void hal_led_set_pixel(uint8_t strip, uint16_t index, uint8_t r, uint8_t g, uint8_t b);

/* 设置整条灯带颜色 */
void hal_led_set_strip(uint8_t strip, uint8_t r, uint8_t g, uint8_t b);

/* 全局亮度 0-100，刷新时生效 */
void hal_led_set_brightness(uint8_t brightness);

/* 清除所有像素缓冲 */
void hal_led_clear(void);

/* 将缓冲数据推送到 RMT 硬件 */
void hal_led_refresh(void);
