/* ═══════════════════════════════════════════════════════════════
 * STEER: 反臃肿 | max_lines=300 | scope=firmware | 修改前读 anti-bloat.md
 *
 * 职责: I2S MAX98357 音频驱动 — Philips I2S, 44100Hz, 16-bit stereo
 * 不做什么: 不含音频合成、不含 MP3 解码、不含音频引擎逻辑
 *
 * ⚠️ 白板重建 — 不从 reference/ridewind-esp 搬运代码
 * ═══════════════════════════════════════════════════════════════ */

#include "hal_audio.h"
#include "driver/i2s_std.h"
#include "freertos/FreeRTOS.h"
#include "esp_log.h"

static const char *TAG = "HAL_AUD";

#define PIN_I2S_BCLK        GPIO_NUM_12
#define PIN_I2S_LRC         GPIO_NUM_11
#define PIN_I2S_DIN         GPIO_NUM_13
#define AUDIO_SAMPLE_RATE   44100
#define AUDIO_BIT_WIDTH     I2S_DATA_BIT_WIDTH_16BIT
#define AUDIO_SLOT_MODE     I2S_SLOT_MODE_STEREO
#define AUDIO_I2S_PORT      I2S_NUM_0
#define AUDIO_DMA_DESC      6
#define AUDIO_DMA_FRAMES    512

static i2s_chan_handle_t s_tx_handle = NULL;
static uint8_t           s_volume    = 100;
static bool              s_enabled   = false;

esp_err_t hal_audio_init(void)
{
    i2s_chan_config_t chan_cfg = I2S_CHANNEL_DEFAULT_CONFIG(AUDIO_I2S_PORT, I2S_ROLE_MASTER);
    chan_cfg.dma_desc_num  = AUDIO_DMA_DESC;
    chan_cfg.dma_frame_num = AUDIO_DMA_FRAMES;

    esp_err_t err = i2s_new_channel(&chan_cfg, &s_tx_handle, NULL);
    if (err != ESP_OK) {
        ESP_LOGE(TAG, "I2S new channel failed: %s", esp_err_to_name(err));
        return err;
    }

    i2s_std_config_t std_cfg = {
        .clk_cfg  = I2S_STD_CLK_DEFAULT_CONFIG(AUDIO_SAMPLE_RATE),
        .slot_cfg = I2S_STD_PHILIPS_SLOT_DEFAULT_CONFIG(AUDIO_BIT_WIDTH, AUDIO_SLOT_MODE),
        .gpio_cfg = {
            .mclk = I2S_GPIO_UNUSED,
            .bclk = PIN_I2S_BCLK,
            .ws   = PIN_I2S_LRC,
            .dout = PIN_I2S_DIN,
            .din  = I2S_GPIO_UNUSED,
            .invert_flags = { .mclk_inv = false, .bclk_inv = false, .ws_inv = false },
        },
    };

    err = i2s_channel_init_std_mode(s_tx_handle, &std_cfg);
    if (err != ESP_OK) {
        ESP_LOGE(TAG, "I2S std mode init failed: %s", esp_err_to_name(err));
        return err;
    }

    err = i2s_channel_enable(s_tx_handle);
    if (err != ESP_OK) {
        ESP_LOGE(TAG, "I2S channel enable failed: %s", esp_err_to_name(err));
        return err;
    }

    s_enabled = true;
    ESP_LOGI(TAG, "Audio I2S init OK: %dHz, 16-bit stereo, DMA %dx%d",
             AUDIO_SAMPLE_RATE, AUDIO_DMA_DESC, AUDIO_DMA_FRAMES);
    return ESP_OK;
}

esp_err_t hal_audio_write(const int16_t *samples, uint32_t sample_count)
{
    if (!s_tx_handle || !s_enabled || !samples || sample_count == 0) {
        return ESP_ERR_INVALID_STATE;
    }

    size_t bytes = (size_t)sample_count * 4;
    size_t written = 0;

    esp_err_t err = i2s_channel_write(s_tx_handle, samples, bytes, &written, portMAX_DELAY);
    if (err != ESP_OK) {
        ESP_LOGE(TAG, "I2S write failed: %s", esp_err_to_name(err));
    }

    return err;
}

void hal_audio_set_volume(uint8_t volume)
{
    if (volume > 100) volume = 100;
    s_volume = volume;
}

esp_err_t hal_audio_stop(void)
{
    if (!s_tx_handle) return ESP_ERR_INVALID_STATE;
    esp_err_t err = i2s_channel_disable(s_tx_handle);
    if (err == ESP_OK) { s_enabled = false; }
    return err;
}

esp_err_t hal_audio_restart(void)
{
    if (!s_tx_handle) return ESP_ERR_INVALID_STATE;
    esp_err_t err = i2s_channel_enable(s_tx_handle);
    if (err == ESP_OK) { s_enabled = true; }
    return err;
}
