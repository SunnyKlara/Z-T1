/* ═══════════════════════════════════════════════════════════════
 * STEER: 反臃肿 | max_lines=70 | scope=firmware | 修改前读 anti-bloat.md
 *
 * 职责: I2S MAX98357 音频输出驱动 — 初始化 I2S + 写入 PCM 数据 + 音量控制
 * 不做什么: 不处理音频解码/合成（由 modules/audio/ 负责）
 *
 * 硬件 (唯一真值源: steering/specs/hardware-config.md):
 *   DIN=IO13, BCLK=IO12, LRC=IO11
 *   44100Hz, 16-bit, stereo, Philips I2S standard
 * ═══════════════════════════════════════════════════════════════ */

#include "hal_audio.h"
#include "driver/i2s_std.h"
#include "freertos/FreeRTOS.h"
#include "esp_log.h"

static const char *TAG = "hal_audio";

#define PIN_I2S_DIN   GPIO_NUM_13
#define PIN_I2S_BCLK  GPIO_NUM_12
#define PIN_I2S_LRC   GPIO_NUM_11

static i2s_chan_handle_t s_tx_handle = NULL;
static uint8_t s_volume = 100;

void hal_audio_init(void)
{
    i2s_chan_config_t chan_cfg = I2S_CHANNEL_DEFAULT_CONFIG(I2S_NUM_0, I2S_ROLE_MASTER);
    /* 6 descriptors x 512 frames x 4 bytes = 12KB DMA buffer, ~70ms at 44100Hz */
    chan_cfg.dma_desc_num  = 6;
    chan_cfg.dma_frame_num = 512;

    ESP_ERROR_CHECK(i2s_new_channel(&chan_cfg, &s_tx_handle, NULL));

    i2s_std_config_t std_cfg = {
        .clk_cfg  = I2S_STD_CLK_DEFAULT_CONFIG(44100),
        .slot_cfg = I2S_STD_PHILIPS_SLOT_DEFAULT_CONFIG(I2S_DATA_BIT_WIDTH_16BIT,
                                                         I2S_SLOT_MODE_STEREO),
        .gpio_cfg = {
            .mclk = I2S_GPIO_UNUSED,
            .bclk = PIN_I2S_BCLK,
            .ws   = PIN_I2S_LRC,
            .dout = PIN_I2S_DIN,
            .din  = I2S_GPIO_UNUSED,
            .invert_flags = {
                .mclk_inv = false,
                .bclk_inv = false,
                .ws_inv   = false,
            },
        },
    };

    ESP_ERROR_CHECK(i2s_channel_init_std_mode(s_tx_handle, &std_cfg));
    ESP_ERROR_CHECK(i2s_channel_enable(s_tx_handle));

    ESP_LOGI(TAG, "I2S init: 44100Hz 16-bit stereo, DIN=%d BCLK=%d LRC=%d",
             PIN_I2S_DIN, PIN_I2S_BCLK, PIN_I2S_LRC);
}

void hal_audio_write(const int16_t *samples, uint32_t sample_count)
{
    if (!s_tx_handle || sample_count == 0) return;
    size_t bytes_written = 0;
    i2s_channel_write(s_tx_handle, samples,
        sample_count * sizeof(int16_t) * 2, &bytes_written, portMAX_DELAY);
}

void hal_audio_set_volume(uint8_t volume)
{
    if (volume > 100) volume = 100;
    s_volume = volume;
}

uint8_t hal_audio_get_volume(void)
{
    return s_volume;
}

void hal_audio_stop(void)
{
    if (s_tx_handle) {
        i2s_channel_disable(s_tx_handle);
    }
}

void hal_audio_restart(void)
{
    if (s_tx_handle) {
        i2s_channel_enable(s_tx_handle);
    }
}

