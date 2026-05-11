/* ═══════════════════════════════════════════════════════════════
 * STEER: 反臃肿 | max_lines=120 | scope=firmware | 修改前读 anti-bloat.md
 *
 * 职责: WS2812B LED 驱动 — 初始化 RMT 2条灯带 + 单像素/全灯带颜色 + 亮度 + 刷新
 * 不做什么: 不处理预设选择（由 modules/ 负责）、不处理特效/渐变
 *
 * 硬件 (唯一真值源: steering/specs/hardware-config.md):
 *   LED1 (strip 0): IO41, 6颗主灯
 *   LED2 (strip 1): IO16, 3颗尾灯
 *   LED_PIXEL_FORMAT_GRB, 10MHz RMT
 * ═══════════════════════════════════════════════════════════════ */

#include "hal_led.h"
#include "led_strip.h"
#include "esp_log.h"
#include <string.h>

static const char *TAG = "hal_led";

#define PIN_LED_MAIN  GPIO_NUM_41
#define PIN_LED_TAIL  GPIO_NUM_16

static led_strip_handle_t s_strip_main;
static led_strip_handle_t s_strip_tail;

static uint8_t s_buf_main[HAL_LED_MAIN_COUNT][3];
static uint8_t s_buf_tail[HAL_LED_TAIL_COUNT][3];

static uint8_t s_brightness = 100;

void hal_led_init(void)
{
    /* Main strip: IO41, 6 LEDs */
    led_strip_config_t cfg_main = {
        .strip_gpio_num   = PIN_LED_MAIN,
        .max_leds         = HAL_LED_MAIN_COUNT,
        .led_pixel_format = LED_PIXEL_FORMAT_GRB,
        .led_model        = LED_MODEL_WS2812,
    };
    led_strip_rmt_config_t rmt_main = {
        .resolution_hz   = 10 * 1000 * 1000,
        .flags.with_dma  = false,
    };
    ESP_ERROR_CHECK(led_strip_new_rmt_device(&cfg_main, &rmt_main, &s_strip_main));

    /* Tail strip: IO16, 3 LEDs */
    led_strip_config_t cfg_tail = {
        .strip_gpio_num   = PIN_LED_TAIL,
        .max_leds         = HAL_LED_TAIL_COUNT,
        .led_pixel_format = LED_PIXEL_FORMAT_GRB,
        .led_model        = LED_MODEL_WS2812,
    };
    led_strip_rmt_config_t rmt_tail = {
        .resolution_hz   = 10 * 1000 * 1000,
        .flags.with_dma  = false,
    };
    ESP_ERROR_CHECK(led_strip_new_rmt_device(&cfg_tail, &rmt_tail, &s_strip_tail));

    hal_led_clear();
    hal_led_refresh();

    ESP_LOGI(TAG, "LED init: Main=%d LEDs (IO%d), Tail=%d LEDs (IO%d)",
             HAL_LED_MAIN_COUNT, PIN_LED_MAIN,
             HAL_LED_TAIL_COUNT, PIN_LED_TAIL);
}

void hal_led_set_pixel(uint8_t strip, uint16_t index, uint8_t r, uint8_t g, uint8_t b)
{
    if (strip == HAL_LED_STRIP_MAIN && index < HAL_LED_MAIN_COUNT) {
        s_buf_main[index][0] = r;
        s_buf_main[index][1] = g;
        s_buf_main[index][2] = b;
    } else if (strip == HAL_LED_STRIP_TAIL && index < HAL_LED_TAIL_COUNT) {
        s_buf_tail[index][0] = r;
        s_buf_tail[index][1] = g;
        s_buf_tail[index][2] = b;
    }
}

void hal_led_set_strip(uint8_t strip, uint8_t r, uint8_t g, uint8_t b)
{
    if (strip == HAL_LED_STRIP_MAIN) {
        for (int i = 0; i < HAL_LED_MAIN_COUNT; i++) {
            s_buf_main[i][0] = r;
            s_buf_main[i][1] = g;
            s_buf_main[i][2] = b;
        }
    } else if (strip == HAL_LED_STRIP_TAIL) {
        for (int i = 0; i < HAL_LED_TAIL_COUNT; i++) {
            s_buf_tail[i][0] = r;
            s_buf_tail[i][1] = g;
            s_buf_tail[i][2] = b;
        }
    }
}

void hal_led_set_brightness(uint8_t brightness)
{
    if (brightness > 100) brightness = 100;
    s_brightness = brightness;
}

void hal_led_refresh(void)
{
    for (int i = 0; i < HAL_LED_MAIN_COUNT; i++) {
        uint8_t r = (uint8_t)((uint16_t)s_buf_main[i][0] * s_brightness / 100);
        uint8_t g = (uint8_t)((uint16_t)s_buf_main[i][1] * s_brightness / 100);
        uint8_t b = (uint8_t)((uint16_t)s_buf_main[i][2] * s_brightness / 100);
        led_strip_set_pixel(s_strip_main, i, r, g, b);
    }
    led_strip_refresh(s_strip_main);

    for (int i = 0; i < HAL_LED_TAIL_COUNT; i++) {
        uint8_t r = (uint8_t)((uint16_t)s_buf_tail[i][0] * s_brightness / 100);
        uint8_t g = (uint8_t)((uint16_t)s_buf_tail[i][1] * s_brightness / 100);
        uint8_t b = (uint8_t)((uint16_t)s_buf_tail[i][2] * s_brightness / 100);
        led_strip_set_pixel(s_strip_tail, i, r, g, b);
    }
    led_strip_refresh(s_strip_tail);
}

void hal_led_clear(void)
{
    memset(s_buf_main, 0, sizeof(s_buf_main));
    memset(s_buf_tail, 0, sizeof(s_buf_tail));
}
