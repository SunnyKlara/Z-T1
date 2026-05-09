#pragma once

/* ═══════════════════════════════════════════════════════════════
 * STEER: 反臃肿 | ref_lines=30 | scope=firmware | 修改前读 anti-bloat.md
 *
 * 职责: I2S MAX98357 音频驱动 — 初始化、PCM 写入、音量控制
 * 不做什么: 不含音频合成、不含 MP3 解码、不含音频流管理
 * 硬件: DIN(IO13), BCLK(IO12), LRC(IO11), 44100Hz, 16-bit stereo
 *        — 唯一真值源 hardware-config.md
 * ═══════════════════════════════════════════════════════════════ */

#include <stdint.h>
#include "esp_err.h"

esp_err_t hal_audio_init(void);
esp_err_t hal_audio_write(const int16_t *samples, uint32_t sample_count);
void hal_audio_set_volume(uint8_t volume);
esp_err_t hal_audio_stop(void);
esp_err_t hal_audio_restart(void);
