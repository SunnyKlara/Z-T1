/* ═══════════════════════════════════════════════════════════════
 * STEER: 反臃肿 | max_lines=300 | scope=firmware | 修改前读 anti-bloat.md
 *
 * 职责: GC9A01 240×240 圆形 LCD SPI 驱动
 * 不做什么: 不含 UI 渲染逻辑、不含 framebuffer 管理
 *
 * ⚠️ 白板重建 — 不从 reference/ridewind-esp 搬运代码
 * ═══════════════════════════════════════════════════════════════ */

#include "hal_lcd.h"
#include "driver/spi_master.h"
#include "driver/gpio.h"
#include "esp_log.h"
#include "esp_heap_caps.h"
#include <string.h>

static const char *TAG = "HAL_LCD";

#define PIN_LCD_CS          GPIO_NUM_4
#define PIN_LCD_DC          GPIO_NUM_5
#define PIN_LCD_SDA         GPIO_NUM_6
#define PIN_LCD_SCL         GPIO_NUM_7
#define LCD_WIDTH           240
#define LCD_HEIGHT          240
#define LCD_SPI_HOST        SPI2_HOST
#define LCD_SPI_FREQ_HZ     (40 * 1000 * 1000)

static spi_device_handle_t s_spi = NULL;

static void lcd_cmd(uint8_t cmd)
{
    gpio_set_level(PIN_LCD_DC, 0);
    spi_transaction_t t = { .length = 8, .tx_buffer = &cmd };
    spi_device_polling_transmit(s_spi, &t);
}

static void lcd_data8(uint8_t data)
{
    gpio_set_level(PIN_LCD_DC, 1);
    spi_transaction_t t = { .length = 8, .tx_buffer = &data };
    spi_device_polling_transmit(s_spi, &t);
}

static void lcd_data_bytes(const uint8_t *data, uint32_t len)
{
    if (len == 0) return;
    gpio_set_level(PIN_LCD_DC, 1);

    const uint32_t chunk_max = 4092;
    const uint8_t *p = data;
    uint32_t remaining = len;

    while (remaining > 0) {
        uint32_t chunk = (remaining > chunk_max) ? chunk_max : remaining;
        spi_transaction_t t = { .length = chunk * 8, .tx_buffer = p };
        spi_device_polling_transmit(s_spi, &t);
        p         += chunk;
        remaining -= chunk;
    }
}

static void lcd_init_sequence(void)
{
    lcd_cmd(0x01);  /* SW reset */
    vTaskDelay(pdMS_TO_TICKS(120));
    lcd_cmd(0x11);  /* Sleep out */
    vTaskDelay(pdMS_TO_TICKS(120));

    lcd_cmd(0x3A);  /* Pixel format: RGB565 */
    lcd_data8(0x05);

    lcd_cmd(0x36);  /* Memory access: rotate 90° */
    lcd_data8(0x28);

    lcd_cmd(0xC4);  /* Frame rate */
    lcd_data8(0x01);

    lcd_cmd(0xC1);  /* Power control 1 */
    lcd_data8(0x2B);

    lcd_cmd(0xC3);  /* Power control 2 */
    lcd_data8(0x01);

    lcd_cmd(0xC5);  /* VCOM */
    lcd_data8(0x15);
    lcd_data8(0x10);

    lcd_cmd(0xF0); lcd_data8(0x01);  /* Gamma */
    lcd_cmd(0xF2); lcd_data8(0x06);
    lcd_cmd(0xF3); lcd_data8(0x02);
    lcd_cmd(0xF9); lcd_data8(0x00);

    lcd_cmd(0x21);  /* Display inversion off */
    lcd_cmd(0x38);  /* Idle mode off */
    lcd_cmd(0x29);  /* Display on */
    vTaskDelay(pdMS_TO_TICKS(20));
}

esp_err_t hal_lcd_init(void)
{
    gpio_config_t io_cfg = {
        .pin_bit_mask = (1ULL << PIN_LCD_DC) | (1ULL << PIN_LCD_CS),
        .mode         = GPIO_MODE_OUTPUT,
        .pull_up_en   = GPIO_PULLUP_DISABLE,
        .pull_down_en = GPIO_PULLDOWN_DISABLE,
        .intr_type    = GPIO_INTR_DISABLE,
    };
    gpio_config(&io_cfg);
    gpio_set_level(PIN_LCD_CS, 1);
    gpio_set_level(PIN_LCD_DC, 1);

    spi_bus_config_t bus_cfg = {
        .mosi_io_num     = PIN_LCD_SDA,
        .miso_io_num     = -1,
        .sclk_io_num     = PIN_LCD_SCL,
        .quadwp_io_num   = -1,
        .quadhd_io_num   = -1,
        .max_transfer_sz = LCD_WIDTH * LCD_HEIGHT * 2 + 8,
    };
    esp_err_t err = spi_bus_initialize(LCD_SPI_HOST, &bus_cfg, SPI_DMA_CH_AUTO);
    if (err != ESP_OK) {
        ESP_LOGE(TAG, "SPI bus init failed: %s", esp_err_to_name(err));
        return err;
    }

    spi_device_interface_config_t dev_cfg = {
        .mode           = 0,
        .clock_speed_hz = LCD_SPI_FREQ_HZ,
        .spics_io_num   = PIN_LCD_CS,
        .queue_size     = 7,
    };
    err = spi_bus_add_device(LCD_SPI_HOST, &dev_cfg, &s_spi);
    if (err != ESP_OK) {
        ESP_LOGE(TAG, "SPI device add failed: %s", esp_err_to_name(err));
        return err;
    }

    lcd_init_sequence();
    hal_lcd_clear(0x0000);

    ESP_LOGI(TAG, "LCD init OK: GC9A01 %dx%d, SPI@%dMHz",
             LCD_WIDTH, LCD_HEIGHT, (int)(LCD_SPI_FREQ_HZ / 1000000));
    return ESP_OK;
}

void hal_lcd_draw_pixel(uint16_t x, uint16_t y, uint16_t color)
{
    if (x >= LCD_WIDTH || y >= LCD_HEIGHT) return;

    lcd_cmd(0x2A);
    lcd_data8(x >> 8); lcd_data8(x & 0xFF);
    lcd_data8(x >> 8); lcd_data8(x & 0xFF);

    lcd_cmd(0x2B);
    lcd_data8(y >> 8); lcd_data8(y & 0xFF);
    lcd_data8(y >> 8); lcd_data8(y & 0xFF);

    lcd_cmd(0x2C);
    lcd_data8(color >> 8);
    lcd_data8(color & 0xFF);
}

void hal_lcd_set_window(uint16_t x0, uint16_t y0, uint16_t x1, uint16_t y1)
{
    lcd_cmd(0x2A);
    lcd_data8(x0 >> 8); lcd_data8(x0 & 0xFF);
    lcd_data8(x1 >> 8); lcd_data8(x1 & 0xFF);

    lcd_cmd(0x2B);
    lcd_data8(y0 >> 8); lcd_data8(y0 & 0xFF);
    lcd_data8(y1 >> 8); lcd_data8(y1 & 0xFF);

    lcd_cmd(0x2C);
}

void hal_lcd_write_data(const uint8_t *data, uint32_t len)
{
    lcd_data_bytes(data, len);
}

void hal_lcd_blit_dma(uint16_t x, uint16_t y, uint16_t w, uint16_t h, const uint16_t *data)
{
    if (!data || w == 0 || h == 0) return;

    hal_lcd_set_window(x, y, x + w - 1, y + h - 1);

    spi_transaction_t t = {
        .length    = (size_t)w * h * 16,
        .tx_buffer = data,
    };
    spi_device_transmit(s_spi, &t);
}

void hal_lcd_fill_rect(uint16_t x, uint16_t y, uint16_t w, uint16_t h, uint16_t color)
{
    if (w == 0 || h == 0) return;

    hal_lcd_set_window(x, y, x + w - 1, y + h - 1);

    uint32_t pixel_count = (uint32_t)w * h;
    if (pixel_count <= 16) {
        for (uint32_t i = 0; i < pixel_count; i++) {
            lcd_data8(color >> 8);
            lcd_data8(color & 0xFF);
        }
    } else {
        uint16_t *line_buf = heap_caps_malloc(w * 2, MALLOC_CAP_DMA);
        if (!line_buf) {
            for (uint32_t i = 0; i < pixel_count; i++) {
                lcd_data8(color >> 8);
                lcd_data8(color & 0xFF);
            }
            return;
        }

        for (uint16_t i = 0; i < w; i++) {
            line_buf[i] = color;
        }

        for (uint16_t row = 0; row < h; row++) {
            spi_transaction_t t = { .length = (size_t)w * 16, .tx_buffer = line_buf };
            spi_device_transmit(s_spi, &t);
        }

        heap_caps_free(line_buf);
    }
}

void hal_lcd_clear(uint16_t color)
{
    hal_lcd_fill_rect(0, 0, LCD_WIDTH, LCD_HEIGHT, color);
}
