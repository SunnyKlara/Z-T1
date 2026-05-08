/**
 * @file engine_synth.h
 * @brief Multi-layer wavetable engine sound synthesizer.
 *
 * Uses real engine recordings (5 layers: idle/low/mid/high/rev)
 * with equal-power crossfade blending and variable-rate playback.
 *
 * Designed for ESP32-S3 @ 240MHz, output 44100Hz 16-bit stereo to I2S.
 */

#pragma once
#include <stdint.h>
#include <stdbool.h>

/* ── Public API (same interface as audio_player for drop-in swap) ── */

/** Initialize synth */
void engine_synth_init(void);

/** Start the engine synth task */
void engine_synth_start(void);

/** Stop engine synth (with fade-out) */
void engine_synth_stop(void);

/** Check if engine sound is playing */
bool engine_synth_is_playing(void);

/**
 * Set target RPM from speed percentage (0-100).
 * RPM = 800 + pct * 72  (maps 0-100% → 800-8000 RPM)
 */
void engine_synth_set_rpm(uint8_t speed_percent);

/** Set master volume (0-100) */
void engine_synth_set_volume(uint8_t volume);

/** Get current target RPM percentage (0-100). Used for RPM preservation on reload. */
uint16_t engine_synth_get_rpm(void);

/* ── Synthesis parameters (tunable) ── */

/** RPM range */
#define SYNTH_RPM_MIN           800
#define SYNTH_RPM_MAX           8000

/** I2S buffer chunk size (same as current audio_player) */
#define SYNTH_BUF_FRAMES        512

/** Fade parameters */
#define SYNTH_FADE_IN_BUFS      50
#define SYNTH_FADE_OUT_BUFS     20
