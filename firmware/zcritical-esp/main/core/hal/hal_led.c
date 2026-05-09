/* ═══════════════════════════════════════════════════════════════
 * STEER: 反臃肿 | max_lines=300 | scope=firmware | 修改前读 anti-bloat.md
 *
 * 职责: WS2812B LED RMT 驱动 — 2 条灯带, 9 颗灯珠
 *        LED1(IO41, 6颗主灯) + LED2(IO16, 3颗尾灯)
 * 不做什么: 不含预设颜色表、不含 LED 特效、不含 UI 逻辑
 *
 * ⚠️ 白板重建 — 不从 reference/ridewind-esp 搬运代码
 * ═══════════════════════════════════════════════════════════════ */

#include "hal_led.h"
#include "led_strip.h"
#include "esp_log.h"

static const char *TAG = "HAL_LED";

#define PIN_LED1            GPIO_NUM_41
#define PIN_LED2            GPIO_NUM_16
#define LED1_COUNT          6
#define LED2_COUNT          3
#define RMT_RES_HZ          (10 * 1000 * 1000)

static led_strip_handle_t s_strip1 = NULL;
static led_strip_handle_t s_strip2 = NULL;
static uint8_t s_buf1[6][3];
static uint8_t s_buf2[3][3];
static uint8_t s_brightness = 100;

esp_err_t hal_led_init(void)
{
    led_strip_config_t cfg1 = {
        .strip_gpio_num   = PIN_LED1,
        .max_leds         = LED1_COUNT,
        .led_pixel_format = LED_PIXEL_FORMAT_GRB,
        .led_model        = LED_MODEL_WS2812,
    };
    led_strip_rmt_config_t rmt1 = {
        .clk_src          = RMT_CLK_SRC_DEFAULT,
        .resolution_hz    = RMT_RES_HZ,
        .mem_block_symbols = 64,
        .flags.with_dma   = false,
    };
    esp_err_t err = led_strip_new_rmt_device(&cfg1, &rmt1, &s_strip1);
    if (err != ESP_OK) {
        ESP_LOGE(TAG, "LED1 RMT init failed: %s", esp_err_to_name(err));
        return err;
    }

    led_strip_config_t cfg2 = {
        .strip_gpio_num   = PIN_LED2,
        .max_leds         = LED2_COUNT,
        .led_pixel_format = LED_PIXEL_FORMAT_GRB,
        .led_model        = LED_MODEL_WS2812,
    };
    led_strip_rmt_config_t rmt2 = {
        .clk_src          = RMT_CLK_SRC_DEFAULT,
        .resolution_hz    = RMT_RES_HZ,
        .mem_block_symbols = 64,
        .flags.with_dma   = false,
    };
    err = led_strip_new_rmt_device(&cfg2, &rmt2, &s_strip2);
    if (err != ESP_OK) {
        ESP_LOGE(TAG, "LED2 RMT init failed: %s", esp_err_to_name(err));
        return err;
    }

    hal_led_clear();
    hal_led_refresh();

    ESP_LOGI(TAG, "LED init OK: strip1=%d LEDs (IO%d), strip2=%d LEDs (IO%d)",
             LED1_COUNT, PIN_LED1, LED2_COUNT, PIN_LED2);
    return ESP_OK;
}

void hal_led_set_pixel(uint8_t phys_strip, uint16_t index, uint8_t r, uint8_t g, uint8_t b)
{
    if (phys_strip == 0 && index < LED1_COUNT) {
        s_buf1[index][0] = r;
        s_buf1[index][1] = g;
        s_buf1[index][2] = b;
    } else if (phys_strip == 1 && index < LED2_COUNT) {
        s_buf2[index][0] = r;
        s_buf2[index][1] = g;
        s_buf2[index][2] = b;
    }
}

void hal_led_set_strip(hal_led_strip_t strip, uint8_t r, uint8_t g, uint8_t b)
{
    uint8_t (*buf)[3];
    uint16_t count;

    if (strip == HAL_LED_STRIP_MAIN) {
        buf   = s_buf1;
        count = LED1_COUNT;
    } else {
        buf   = s_buf2;
        count = LED2_COUNT;
    }

    for (uint16_t i = 0; i < count; i++) {
        buf[i][0] = r;
        buf[i][1] = g;
        buf[i][2] = b;
    }
}

void hal_led_set_brightness(uint8_t brightness)
{
    if (brightness > 100) brightness = 100;
    s_brightness = brightness;
}

void hal_led_refresh(void)
{
    for (uint16_t i = 0; i < LED1_COUNT; i++) {
        uint8_t r = (uint8_t)((uint16_t)s_buf1[i][0] * s_brightness / 100);
        uint8_t g = (uint8_t)((uint16_t)s_buf1[i][1] * s_brightness / 100);
        uint8_t b = (uint8_t)((uint16_t)s_buf1[i][2] * s_brightness / 100);
        led_strip_set_pixel(s_strip1, i, r, g, b);
    }
    led_strip_refresh(s_strip1);

    for (uint16_t i = 0; i < LED2_COUNT; i++) {
        uint8_t r = (uint8_t)((uint16_t)s_buf2[i][0] * s_brightness / 100);
        uint8_t g = (uint8_t)((uint16_t)s_buf2[i][1] * s_brightness / 100);
        uint8_t b = (uint8_t)((uint16_t)s_buf2[i][2] * s_brightness / 100);
        led_strip_set_pixel(s_strip2, i, r, g, b);
    }
    led_strip_refresh(s_strip2);
}

void hal_led_clear(void)
{
    for (uint16_t i = 0; i < LED1_COUNT; i++) {
        s_buf1[i][0] = s_buf1[i][1] = s_buf1[i][2] = 0;
    }
    for (uint16_t i = 0; i < LED2_COUNT; i++) {
        s_buf2[i][0] = s_buf2[i][1] = s_buf2[i][2] = 0;
    }
}
