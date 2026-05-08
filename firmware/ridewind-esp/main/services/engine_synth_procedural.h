/**
 * @file engine_synth_procedural.h
 * @brief 纯程序化引擎声音合成器 - 无需任何音频素材！
 *
 * 使用数学波形合成：
 *   - 引擎声：多锯齿波 + 低通滤波 + RPM 调制
 *   - 涡轮增压：白噪声 + 带通滤波
 *   - 换挡提示：正弦波短音
 *
 * 输出：44100Hz 16-bit 立体声 I2S
 */

#pragma once
#include <stdint.h>
#include <stdbool.h>

/* ── 公共 API ── */
void engine_synth_init(void);
void engine_synth_start(void);
void engine_synth_stop(void);
bool engine_synth_is_playing(void);
void engine_synth_set_rpm(uint8_t speed_percent);
void engine_synth_set_volume(uint8_t volume);

/* ── 新增：涡轮增压控制 ── */
void engine_synth_set_turbo_boost(uint8_t boost_percent);  /* 0-100 */
void engine_synth_set_turbo_wastegate(bool open);          /* 泄压阀 */

/* ── 新增：换挡提示 ── */
void engine_synth_play_shift_up(void);
void engine_synth_play_shift_down(void);

/* ── 合成参数 ── */
#define SYNTH_RPM_MIN           800
#define SYNTH_RPM_MAX           8000
#define SYNTH_BUF_FRAMES        512
#define SYNTH_FADE_IN_BUFS      50
#define SYNTH_FADE_OUT_BUFS     20

/* ── 引擎类型配置 ── */
typedef enum {
    ENGINE_TYPE_I4,    /* 直列四缸 - 尖锐高亢 */
    ENGINE_TYPE_V6,    /* V6 - 平滑浑厚 */
    ENGINE_TYPE_V8,    /* V8 - 低沉咆哮 */
    ENGINE_TYPE_W12,   /* W12 - 豪华绵密 */
} engine_type_t;

void engine_synth_set_type(engine_type_t type);
