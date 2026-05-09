#pragma once

/* ═══════════════════════════════════════════════════════════════
 * STEER: 反臃肿 | ref_lines=50 | scope=firmware | 修改前读 anti-bloat.md
 *
 * 职责: WS2812B LED 驱动 — 2 条灯带 (RMT 外设)
 * 不做什么: 不含 LED 预设值、不含特效（呼吸/渐变/流水灯）、不含 UI 逻辑
 * 硬件: LED1(IO41, 6颗主灯) + LED2(IO16, 3颗尾灯) — 唯一真值源 hardware-config.md
 * ═══════════════════════════════════════════════════════════════ */

#include <stdint.h>
#include <stdbool.h>
#include "esp_err.h"

/* 灯带标识 */
typedef enum {
    HAL_LED_STRIP_MAIN = 0,
    HAL_LED_STRIP_TAIL = 1,
} hal_led_strip_t;

/* 公开 API */

esp_err_t hal_led_init(void);

void hal_led_set_strip(hal_led_strip_t strip, uint8_t r, uint8_t g, uint8_t b);

void hal_led_set_pixel(uint8_t phys_strip, uint16_t index, uint8_t r, uint8_t g, uint8_t b);

void hal_led_set_brightness(uint8_t brightness);

void hal_led_refresh(void);

void hal_led_clear(void);
