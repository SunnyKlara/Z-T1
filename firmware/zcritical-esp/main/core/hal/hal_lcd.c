/* ═══════════════════════════════════════════════════════════════
 * STEER: 反臃肿 | max_lines=280 | scope=firmware | 修改前读 anti-bloat.md
 *
 * 职责: GC9A01 圆形 LCD SPI 驱动 — 初始化 SPI + GC9A01 初始化序列 + 画图基元
 * 不做什么: 不处理 UI 渲染逻辑（由 modules/display/ 负责）、不管理字库
 *
 * 硬件 (唯一真值源: steering/specs/hardware-config.md):
 *   CS=IO4, DC=IO5, SDA(MOSI)=IO6, SCL=IO7
 *   SPI2_HOST, 40MHz, 240×240 分辨率
 * ═══════════════════════════════════════════════════════════════ */

#include "hal_lcd.h"
#include "driver/spi_master.h"
#include "driver/gpio.h"
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "esp_log.h"
#include <string.h>
#include <stdio.h>

static const char *TAG = "hal_lcd";

#define PIN_LCD_CS     GPIO_NUM_4
#define PIN_LCD_DC     GPIO_NUM_5
#define PIN_LCD_SDA    GPIO_NUM_6
#define PIN_LCD_SCL    GPIO_NUM_7
#define PIN_LCD_BL     GPIO_NUM_9
#define LCD_SPI_HOST   SPI2_HOST
#define LCD_SPI_FREQ   (40 * 1000 * 1000)

#define LINE_BUF_SIZE  (HAL_LCD_WIDTH * 2)

static spi_device_handle_t s_spi_dev;

/* ── Low-level SPI helpers ── */

static void lcd_cmd(uint8_t cmd)
{
    spi_transaction_t t = {
        .length    = 8,
        .tx_buffer = &cmd,
    };
    gpio_set_level(PIN_LCD_DC, 0);
    spi_device_polling_transmit(s_spi_dev, &t);
}

static void lcd_data(uint8_t d)
{
    spi_transaction_t t = {
        .length    = 8,
        .tx_buffer = &d,
    };
    gpio_set_level(PIN_LCD_DC, 1);
    spi_device_polling_transmit(s_spi_dev, &t);
}

static void lcd_data_buf(const uint8_t *buf, int len)
{
    if (len <= 0) return;
    spi_transaction_t t = {
        .length    = len * 8,
        .tx_buffer = buf,
    };
    gpio_set_level(PIN_LCD_DC, 1);
    spi_device_polling_transmit(s_spi_dev, &t);
}

/* ── GC9A01 初始化序列 (已验证过的参数) ── */

static void gc9a01_init_seq(void)
{
    lcd_cmd(0xEF);
    lcd_cmd(0xEB); lcd_data(0x14);
    lcd_cmd(0xFE);
    lcd_cmd(0xEF);
    lcd_cmd(0xEB); lcd_data(0x14);
    lcd_cmd(0x84); lcd_data(0x40);
    lcd_cmd(0x85); lcd_data(0xFF);
    lcd_cmd(0x86); lcd_data(0xFF);
    lcd_cmd(0x87); lcd_data(0xFF);
    lcd_cmd(0x88); lcd_data(0x0A);
    lcd_cmd(0x89); lcd_data(0x21);
    lcd_cmd(0x8A); lcd_data(0x00);
    lcd_cmd(0x8B); lcd_data(0x80);
    lcd_cmd(0x8C); lcd_data(0x01);
    lcd_cmd(0x8D); lcd_data(0x01);
    lcd_cmd(0x8E); lcd_data(0xFF);
    lcd_cmd(0x8F); lcd_data(0xFF);

    lcd_cmd(0xB6); lcd_data(0x00); lcd_data(0x00);

    /* Memory Access Control: 0x28 = 90° rotation */
    lcd_cmd(0x36); lcd_data(0x28);

    /* Pixel format: 16-bit RGB565 */
    lcd_cmd(0x3A); lcd_data(0x05);

    lcd_cmd(0x90); lcd_data(0x08); lcd_data(0x08); lcd_data(0x08); lcd_data(0x08);
    lcd_cmd(0xBD); lcd_data(0x06);
    lcd_cmd(0xBC); lcd_data(0x00);
    lcd_cmd(0xFF); lcd_data(0x60); lcd_data(0x01); lcd_data(0x04);
    lcd_cmd(0xC3); lcd_data(0x13);
    lcd_cmd(0xC4); lcd_data(0x13);
    lcd_cmd(0xC9); lcd_data(0x22);
    lcd_cmd(0xBE); lcd_data(0x11);
    lcd_cmd(0xE1); lcd_data(0x10); lcd_data(0x0E);
    lcd_cmd(0xDF); lcd_data(0x21); lcd_data(0x0C); lcd_data(0x02);

    /* Gamma */
    lcd_cmd(0xF0); lcd_data(0x45); lcd_data(0x09); lcd_data(0x08);
                   lcd_data(0x08); lcd_data(0x26); lcd_data(0x2A);
    lcd_cmd(0xF1); lcd_data(0x43); lcd_data(0x70); lcd_data(0x72);
                   lcd_data(0x36); lcd_data(0x37); lcd_data(0x6F);
    lcd_cmd(0xF2); lcd_data(0x45); lcd_data(0x09); lcd_data(0x08);
                   lcd_data(0x08); lcd_data(0x26); lcd_data(0x2A);
    lcd_cmd(0xF3); lcd_data(0x43); lcd_data(0x70); lcd_data(0x72);
                   lcd_data(0x36); lcd_data(0x37); lcd_data(0x6F);

    lcd_cmd(0xED); lcd_data(0x1B); lcd_data(0x0B);
    lcd_cmd(0xAE); lcd_data(0x77);
    lcd_cmd(0xCD); lcd_data(0x63);

    lcd_cmd(0x70); lcd_data(0x07); lcd_data(0x07); lcd_data(0x04); lcd_data(0x0E);
                   lcd_data(0x0F); lcd_data(0x09); lcd_data(0x07); lcd_data(0x08);
                   lcd_data(0x03);

    lcd_cmd(0xE8); lcd_data(0x34);

    lcd_cmd(0x62); lcd_data(0x18); lcd_data(0x0D); lcd_data(0x71); lcd_data(0xED);
                   lcd_data(0x70); lcd_data(0x70); lcd_data(0x18); lcd_data(0x0F);
                   lcd_data(0x71); lcd_data(0xEF); lcd_data(0x70); lcd_data(0x70);

    lcd_cmd(0x63); lcd_data(0x18); lcd_data(0x11); lcd_data(0x71); lcd_data(0xF1);
                   lcd_data(0x70); lcd_data(0x70); lcd_data(0x18); lcd_data(0x13);
                   lcd_data(0x71); lcd_data(0xF3); lcd_data(0x70); lcd_data(0x70);

    lcd_cmd(0x64); lcd_data(0x28); lcd_data(0x29); lcd_data(0xF1); lcd_data(0x01);
                   lcd_data(0xF1); lcd_data(0x00); lcd_data(0x07);

    lcd_cmd(0x66); lcd_data(0x3C); lcd_data(0x00); lcd_data(0xCD); lcd_data(0x67);
                   lcd_data(0x45); lcd_data(0x45); lcd_data(0x10); lcd_data(0x00);
                   lcd_data(0x00); lcd_data(0x00);

    lcd_cmd(0x67); lcd_data(0x00); lcd_data(0x3C); lcd_data(0x00); lcd_data(0x00);
                   lcd_data(0x00); lcd_data(0x01); lcd_data(0x54); lcd_data(0x10);
                   lcd_data(0x32); lcd_data(0x98);

    lcd_cmd(0x74); lcd_data(0x10); lcd_data(0x85); lcd_data(0x80); lcd_data(0x00);
                   lcd_data(0x00); lcd_data(0x4E); lcd_data(0x00);

    lcd_cmd(0x98); lcd_data(0x3E); lcd_data(0x07);

    /* Tearing effect OFF — 避免 SPI 直接写入时闪烁 */
    /* 0x35 已移除 */
    lcd_cmd(0x21);  /* Display inversion ON */

    /* Sleep out */
    lcd_cmd(0x11);
    vTaskDelay(pdMS_TO_TICKS(120));

    /* Display ON */
    lcd_cmd(0x29);
    vTaskDelay(pdMS_TO_TICKS(20));
}

/* ── Public API ── */

void hal_lcd_init(void)
{
    gpio_set_direction(PIN_LCD_DC, GPIO_MODE_OUTPUT);
    gpio_set_level(PIN_LCD_DC, 0);

    gpio_set_direction(PIN_LCD_CS, GPIO_MODE_OUTPUT);
    gpio_set_level(PIN_LCD_CS, 1);

    gpio_set_direction(PIN_LCD_BL, GPIO_MODE_OUTPUT);
    gpio_set_level(PIN_LCD_BL, 0);

    spi_bus_config_t bus_cfg = {
        .mosi_io_num   = PIN_LCD_SDA,
        .miso_io_num   = -1,
        .sclk_io_num   = PIN_LCD_SCL,
        .quadwp_io_num = -1,
        .quadhd_io_num = -1,
        .max_transfer_sz = HAL_LCD_WIDTH * HAL_LCD_HEIGHT * 2,
    };
    spi_device_interface_config_t dev_cfg = {
        .clock_speed_hz = LCD_SPI_FREQ,
        .mode           = 0,
        .spics_io_num   = PIN_LCD_CS,
        .queue_size     = 7,
    };
    ESP_ERROR_CHECK(spi_bus_initialize(LCD_SPI_HOST, &bus_cfg, SPI_DMA_CH_AUTO));
    ESP_ERROR_CHECK(spi_bus_add_device(LCD_SPI_HOST, &dev_cfg, &s_spi_dev));

    gc9a01_init_seq();
    hal_lcd_clear(0x0000);
    hal_lcd_set_backlight(true);

    ESP_LOGI(TAG, "GC9A01 LCD init: %dx%d, %d MHz SPI",
             HAL_LCD_WIDTH, HAL_LCD_HEIGHT, LCD_SPI_FREQ / 1000000);
}

void hal_lcd_set_window(uint16_t x0, uint16_t y0, uint16_t x1, uint16_t y1)
{
    lcd_cmd(0x2A);
    lcd_data(x0 >> 8); lcd_data(x0 & 0xFF);
    lcd_data(x1 >> 8); lcd_data(x1 & 0xFF);

    lcd_cmd(0x2B);
    lcd_data(y0 >> 8); lcd_data(y0 & 0xFF);
    lcd_data(y1 >> 8); lcd_data(y1 & 0xFF);

    lcd_cmd(0x2C);
}

void hal_lcd_write_data(const uint8_t *data, uint32_t len)
{
    if (!data || len == 0) return;
    lcd_data_buf(data, (int)len);
}

void hal_lcd_clear(uint16_t color)
{
    hal_lcd_fill_rect(0, 0, HAL_LCD_WIDTH, HAL_LCD_HEIGHT, color);
}

void hal_lcd_draw_pixel(uint16_t x, uint16_t y, uint16_t color)
{
    if (x >= HAL_LCD_WIDTH || y >= HAL_LCD_HEIGHT) return;
    hal_lcd_set_window(x, y, x, y);
    uint8_t pixel[2] = { color >> 8, color & 0xFF };
    gpio_set_level(PIN_LCD_DC, 1);
    spi_transaction_t t = {
        .length    = 16,
        .tx_buffer = pixel,
    };
    spi_device_transmit(s_spi_dev, &t);
}

void hal_lcd_fill_rect(uint16_t x, uint16_t y, uint16_t w, uint16_t h, uint16_t color)
{
    if (w == 0 || h == 0) return;
    if (x >= HAL_LCD_WIDTH || y >= HAL_LCD_HEIGHT) return;
    if (x + w > HAL_LCD_WIDTH)  w = HAL_LCD_WIDTH  - x;
    if (y + h > HAL_LCD_HEIGHT) h = HAL_LCD_HEIGHT - y;

    hal_lcd_set_window(x, y, x + w - 1, y + h - 1);

    uint8_t hi = color >> 8;
    uint8_t lo = color & 0xFF;
    uint8_t line[LINE_BUF_SIZE];
    for (uint16_t i = 0; i < w; i++) {
        line[i * 2]     = hi;
        line[i * 2 + 1] = lo;
    }
    for (uint16_t r = 0; r < h; r++) {
        lcd_data_buf(line, w * 2);
    }
}

void hal_lcd_draw_line(uint16_t x0, uint16_t y0, uint16_t x1, uint16_t y1, uint16_t color)
{
    int dx = (int)x1 - (int)x0;
    int dy = (int)y1 - (int)y0;
    int sx = (dx >= 0) ? 1 : -1;
    int sy = (dy >= 0) ? 1 : -1;
    dx = (dx >= 0) ? dx : -dx;
    dy = (dy >= 0) ? dy : -dy;

    int err = dx - dy;
    int cx = (int)x0, cy = (int)y0;
    for (;;) {
        if (cx >= 0 && cx < HAL_LCD_WIDTH && cy >= 0 && cy < HAL_LCD_HEIGHT) {
            hal_lcd_draw_pixel((uint16_t)cx, (uint16_t)cy, color);
        }
        if (cx == (int)x1 && cy == (int)y1) break;
        int e2 = 2 * err;
        if (e2 > -dy) { err -= dy; cx += sx; }
        if (e2 <  dx) { err += dx; cy += sy; }
    }
}

void hal_lcd_draw_circle(uint16_t cx, uint16_t cy, uint16_t r, uint16_t color, bool filled)
{
    if (r == 0) {
        hal_lcd_draw_pixel(cx, cy, color);
        return;
    }
    int x = 0, y = (int)r;
    int d = 1 - (int)r;
    while (x <= y) {
        if (filled) {
            int y0_top = (int)cy - y, y0_bot = (int)cy + y;
            int y1_top = (int)cy - x, y1_bot = (int)cy + x;
            int x_left  = (int)cx - x, x_right = (int)cx + x;
            int x_left2 = (int)cx - y, x_right2 = (int)cy + y;

            if (y0_top >= 0 && y0_top < HAL_LCD_HEIGHT) {
                int xl = x_left < 0 ? 0 : x_left;
                int xr = x_right >= HAL_LCD_WIDTH ? HAL_LCD_WIDTH - 1 : x_right;
                if (xl <= xr) hal_lcd_fill_rect((uint16_t)xl, (uint16_t)y0_top,
                    (uint16_t)(xr - xl + 1), 1, color);
            }
            if (y0_bot >= 0 && y0_bot < HAL_LCD_HEIGHT) {
                int xl = x_left < 0 ? 0 : x_left;
                int xr = x_right >= HAL_LCD_WIDTH ? HAL_LCD_WIDTH - 1 : x_right;
                if (xl <= xr) hal_lcd_fill_rect((uint16_t)xl, (uint16_t)y0_bot,
                    (uint16_t)(xr - xl + 1), 1, color);
            }
            if (y1_top >= 0 && y1_top < HAL_LCD_HEIGHT) {
                int xl = x_left2 < 0 ? 0 : x_left2;
                int xr = x_right2 >= HAL_LCD_WIDTH ? HAL_LCD_WIDTH - 1 : x_right2;
                if (xl <= xr) hal_lcd_fill_rect((uint16_t)xl, (uint16_t)y1_top,
                    (uint16_t)(xr - xl + 1), 1, color);
            }
            if (y1_bot >= 0 && y1_bot < HAL_LCD_HEIGHT) {
                int xl = x_left2 < 0 ? 0 : x_left2;
                int xr = x_right2 >= HAL_LCD_WIDTH ? HAL_LCD_WIDTH - 1 : x_right2;
                if (xl <= xr) hal_lcd_fill_rect((uint16_t)xl, (uint16_t)y1_bot,
                    (uint16_t)(xr - xl + 1), 1, color);
            }
        } else {
            hal_lcd_draw_pixel(cx + x, cy + y, color);
            hal_lcd_draw_pixel(cx - x, cy + y, color);
            hal_lcd_draw_pixel(cx + x, cy - y, color);
            hal_lcd_draw_pixel(cx - x, cy - y, color);
            hal_lcd_draw_pixel(cx + y, cy + x, color);
            hal_lcd_draw_pixel(cx - y, cy + x, color);
            hal_lcd_draw_pixel(cx + y, cy - x, color);
            hal_lcd_draw_pixel(cx - y, cy - x, color);
        }

        if (d < 0) {
            d += 2 * x + 3;
        } else {
            d += 2 * (x - y) + 5;
            y--;
        }
        x++;
    }
}

/* ── 5x8 位图字体 (ASCII 0x20-0x7E) ── */
static const uint8_t FONT_5X8[][5] = {
    [0] = {0x00,0x00,0x00,0x00,0x00}, /*   */
    {0x00,0x00,0x5F,0x00,0x00}, /* ! */
    {0x00,0x07,0x00,0x07,0x00}, /* " */
    {0x14,0x7F,0x14,0x7F,0x14}, /* # */
    {0x24,0x2A,0x7F,0x2A,0x12}, /* $ */
    {0x23,0x13,0x08,0x64,0x62}, /* % */
    {0x36,0x49,0x55,0x22,0x50}, /* & */
    {0x00,0x05,0x03,0x00,0x00}, /* ' */
    {0x00,0x1C,0x22,0x41,0x00}, /* ( */
    {0x00,0x41,0x22,0x1C,0x00}, /* ) */
    {0x08,0x2A,0x1C,0x2A,0x08}, /* * */
    {0x08,0x08,0x3E,0x08,0x08}, /* + */
    {0x00,0x50,0x30,0x00,0x00}, /* , */
    {0x08,0x08,0x08,0x08,0x08}, /* - */
    {0x00,0x60,0x60,0x00,0x00}, /* . */
    {0x20,0x10,0x08,0x04,0x02}, /* / */
    {0x3E,0x51,0x49,0x45,0x3E}, /* 0 */
    {0x00,0x42,0x7F,0x40,0x00}, /* 1 */
    {0x42,0x61,0x51,0x49,0x46}, /* 2 */
    {0x21,0x41,0x45,0x4B,0x31}, /* 3 */
    {0x18,0x14,0x12,0x7F,0x10}, /* 4 */
    {0x27,0x45,0x45,0x45,0x39}, /* 5 */
    {0x3C,0x4A,0x49,0x49,0x30}, /* 6 */
    {0x01,0x71,0x09,0x05,0x03}, /* 7 */
    {0x36,0x49,0x49,0x49,0x36}, /* 8 */
    {0x06,0x49,0x49,0x29,0x1E}, /* 9 */
    {0x00,0x36,0x36,0x00,0x00}, /* : */
    {0x00,0x56,0x36,0x00,0x00}, /* ; */
    {0x00,0x08,0x14,0x22,0x41}, /* < */
    {0x14,0x14,0x14,0x14,0x14}, /* = */
    {0x41,0x22,0x14,0x08,0x00}, /* > */
    {0x02,0x01,0x51,0x09,0x06}, /* ? */
    {0x32,0x49,0x79,0x41,0x3E}, /* @ */
    {0x7E,0x11,0x11,0x11,0x7E}, /* A */
    {0x7F,0x49,0x49,0x49,0x36}, /* B */
    {0x3E,0x41,0x41,0x41,0x22}, /* C */
    {0x7F,0x41,0x41,0x22,0x1C}, /* D */
    {0x7F,0x49,0x49,0x49,0x41}, /* E */
    {0x7F,0x09,0x09,0x01,0x01}, /* F */
    {0x3E,0x41,0x41,0x51,0x32}, /* G */
    {0x7F,0x08,0x08,0x08,0x7F}, /* H */
    {0x00,0x41,0x7F,0x41,0x00}, /* I */
    {0x20,0x40,0x41,0x3F,0x01}, /* J */
    {0x7F,0x08,0x14,0x22,0x41}, /* K */
    {0x7F,0x40,0x40,0x40,0x40}, /* L */
    {0x7F,0x02,0x04,0x02,0x7F}, /* M */
    {0x7F,0x04,0x08,0x10,0x7F}, /* N */
    {0x3E,0x41,0x41,0x41,0x3E}, /* O */
    {0x7F,0x09,0x09,0x09,0x06}, /* P */
    {0x3E,0x41,0x51,0x21,0x5E}, /* Q */
    {0x7F,0x09,0x19,0x29,0x46}, /* R */
    {0x46,0x49,0x49,0x49,0x31}, /* S */
    {0x01,0x01,0x7F,0x01,0x01}, /* T */
    {0x3F,0x40,0x40,0x40,0x3F}, /* U */
    {0x1F,0x20,0x40,0x20,0x1F}, /* V */
    {0x7F,0x20,0x18,0x20,0x7F}, /* W */
    {0x63,0x14,0x08,0x14,0x63}, /* X */
    {0x03,0x04,0x78,0x04,0x03}, /* Y */
    {0x61,0x51,0x49,0x45,0x43}, /* Z */
    {0x00,0x00,0x7F,0x41,0x41}, /* [ */
    {0x02,0x04,0x08,0x10,0x20}, /* \ */
    {0x41,0x41,0x7F,0x00,0x00}, /* ] */
    {0x04,0x02,0x01,0x02,0x04}, /* ^ */
    {0x40,0x40,0x40,0x40,0x40}, /* _ */
    {0x00,0x01,0x02,0x04,0x00}, /* ` */
    {0x20,0x54,0x54,0x54,0x78}, /* a */
    {0x7F,0x48,0x44,0x44,0x38}, /* b */
    {0x38,0x44,0x44,0x44,0x20}, /* c */
    {0x38,0x44,0x44,0x48,0x7F}, /* d */
    {0x38,0x54,0x54,0x54,0x18}, /* e */
    {0x08,0x7E,0x09,0x01,0x02}, /* f */
    {0x08,0x14,0x54,0x54,0x3C}, /* g */
    {0x7F,0x08,0x04,0x04,0x78}, /* h */
    {0x00,0x44,0x7D,0x40,0x00}, /* i */
    {0x20,0x40,0x44,0x3D,0x00}, /* j */
    {0x00,0x7F,0x10,0x28,0x44}, /* k */
    {0x00,0x41,0x7F,0x40,0x00}, /* l */
    {0x7C,0x04,0x18,0x04,0x78}, /* m */
    {0x7C,0x08,0x04,0x04,0x78}, /* n */
    {0x38,0x44,0x44,0x44,0x38}, /* o */
    {0x7C,0x14,0x14,0x14,0x08}, /* p */
    {0x08,0x14,0x14,0x18,0x7C}, /* q */
    {0x7C,0x08,0x04,0x04,0x08}, /* r */
    {0x48,0x54,0x54,0x54,0x20}, /* s */
    {0x04,0x3F,0x44,0x40,0x20}, /* t */
    {0x3C,0x40,0x40,0x20,0x7C}, /* u */
    {0x1C,0x20,0x40,0x20,0x1C}, /* v */
    {0x3C,0x40,0x30,0x40,0x3C}, /* w */
    {0x44,0x28,0x10,0x28,0x44}, /* x */
    {0x0C,0x50,0x50,0x50,0x3C}, /* y */
    {0x44,0x64,0x54,0x4C,0x44}, /* z */
    {0x00,0x08,0x36,0x41,0x00}, /* { */
    {0x00,0x00,0x7F,0x00,0x00}, /* | */
    {0x00,0x41,0x36,0x08,0x00}, /* } */
    {0x08,0x08,0x2A,0x1C,0x08}, /* ~ */
};

void hal_lcd_draw_string(uint16_t x, uint16_t y, const char *str,
                         uint16_t fg, uint16_t bg, uint8_t size)
{
    if (!str) return;
    if (size == 0) size = 1;
    if (size > 3) size = 3;

    uint16_t cx = x;
    while (*str) {
        uint8_t c = (uint8_t)*str;
        if (c >= 0x20 && c <= 0x7E) c -= 0x20;
        else { str++; continue; }

        const uint8_t *glyph = FONT_5X8[c];
        for (int col = 0; col < 5; col++) {
            uint8_t bits = glyph[col];
            for (int row = 0; row < 8; row++) {
                if (bits & (1 << row)) {
                    if (size == 1) {
                        hal_lcd_draw_pixel(cx + col, y + row, fg);
                    } else {
                        hal_lcd_fill_rect(cx + col * size, y + row * size,
                            size, size, fg);
                    }
                } else if (bg != fg && size == 1) {
                    hal_lcd_draw_pixel(cx + col, y + row, bg);
                }
            }
        }
        /* 清除背景列 */
        if (bg != fg && size > 1) {
            for (int row = 0; row < 8; row++) {
                for (int col = 0; col < 5; col++) {
                    uint8_t bits = glyph[col];
                    if (!(bits & (1 << row))) {
                        hal_lcd_fill_rect(cx + col * size, y + row * size,
                            size, size, bg);
                    }
                }
            }
        }
        cx += 6 * size;
        str++;
    }
}

void hal_lcd_blit_rgb565(uint16_t x, uint16_t y, uint16_t w, uint16_t h,
                         const uint16_t *data)
{
    if (!data || w == 0 || h == 0) return;
    if (x >= HAL_LCD_WIDTH || y >= HAL_LCD_HEIGHT) return;
    if (x + w > HAL_LCD_WIDTH)  w = HAL_LCD_WIDTH  - x;
    if (y + h > HAL_LCD_HEIGHT) h = HAL_LCD_HEIGHT - y;

    hal_lcd_set_window(x, y, x + w - 1, y + h - 1);

    uint32_t total_bytes = (uint32_t)w * h * 2;
    const uint8_t *src = (const uint8_t *)data;
    while (total_bytes > 0) {
        int chunk = (total_bytes > LINE_BUF_SIZE) ? LINE_BUF_SIZE : (int)total_bytes;
        lcd_data_buf(src, chunk);
        src += chunk;
        total_bytes -= chunk;
    }
}

void hal_lcd_set_backlight(bool on)
{
    gpio_set_level(PIN_LCD_BL, on ? 1 : 0);
}
