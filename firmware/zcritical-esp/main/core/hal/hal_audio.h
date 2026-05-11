/* ═══════════════════════════════════════════════════════════════
 * STEER: 反臃肿 | max_lines=30 | scope=firmware | 修改前读 anti-bloat.md
 *
 * 职责: I2S MAX98357 音频输出驱动 — 初始化 I2S + 写入 PCM 数据 + 音量控制
 * 不做什么: 不处理音频解码/合成（由 modules/audio/ 负责）
 *
 * 硬件 (唯一真值源: steering/specs/hardware-config.md):
 *   DIN=IO13, BCLK=IO12, LRC=IO11
 *   44100Hz, 16-bit, stereo, Philips I2S standard
 * ═══════════════════════════════════════════════════════════════ */

#pragma once

#include <stdint.h>

void hal_audio_init(void);
void hal_audio_write(const int16_t *samples, uint32_t sample_count);
void hal_audio_set_volume(uint8_t volume);
uint8_t hal_audio_get_volume(void);
void hal_audio_stop(void);
void hal_audio_restart(void);
