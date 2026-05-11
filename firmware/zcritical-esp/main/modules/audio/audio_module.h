/* ═══════════════════════════════════════════════════════════════
 * STEER: 反臃肿 | scope=firmware | modules/audio/
 *
 * 职责: 音频模块 — 音量控制、引擎声开关
 * 不做什么: 不直接操作 I2S（通过 core/hal/hal_audio）
 * ═══════════════════════════════════════════════════════════════ */

#pragma once
#include <stdint.h>

void audio_module_init(void);
void audio_module_set_volume(uint8_t vol);  /* 0-100 */
void audio_module_engine(uint8_t on);       /* 0=关, 1=开 */
