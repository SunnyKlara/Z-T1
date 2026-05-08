/**
 * @file engine_synth.c
 * @brief Multi-layer wavetable engine sound synth using real recorded samples.
 *
 * ═══════════════════════════════════════════════════════════════
 *  SOUND DESIGN: Equal-Power Crossfade + Variable Rate + Knock
 * ═══════════════════════════════════════════════════════════════
 *
 * Uses real engine recordings (idle/low/mid/high + knock) from
 * engine_idle.h / engine_low.h / engine_mid.h / engine_high.h /
 * engine_rev.h / engine_knock.h.
 *
 * Algorithm:
 *   1. Based on target RPM, select 1 or 2 adjacent layers and
 *      crossfade using equal-power (cos²/sin²) curves.
 *   2. Play each layer at variable rate: pitch tracks RPM.
 *      idle plays at 800RPM native pitch, high at 6200RPM.
 *      In between, pitch is interpolated.
 *   3. Linear interpolation on sample reads for smooth resampling.
 *   4. Mix in knock samples occasionally for texture.
 *   5. Apply gentle lowpass at low RPM, open up at high RPM.
 *
 * Crossfade tuning (XFD_HALF = half-width of each transition zone):
 *   Narrower → cleaner but may "jump" between layers
 *   Wider    → smoother but two layers fight each other
 *   Current: XFD_HALF = 300 RPM (was 450 RPM)
 *
 * Output: 44100 Hz, 16-bit stereo via drv_audio_write.
 */

#include "engine_synth.h"
#include "drv_audio.h"
#include "esp_log.h"
#include "esp_timer.h"
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include <string.h>

/* ── Real engine samples ── */
#include "../resources/engine_idle.h"
#include "../resources/engine_low.h"
#include "../resources/engine_mid.h"
#include "../resources/engine_high.h"
#include "../resources/engine_rev.h"
#include "../resources/engine_knock.h"

static const char *TAG = "ENGINE_SYNTH";

/* ═══════════════════════════════════════════════════════════════
 *  Wavetable definitions
 * ═══════════════════════════════════════════════════════════════ */

#define WAVETABLE_COUNT     5   /* idle, low, mid, high, rev */
#define WAVETABLE_KNOCK     5   /* index for knock */

typedef struct {
    const int8_t *data;
    uint32_t      length;
    uint16_t      native_rpm;  /* RPM this sample was recorded at */
} wavetable_t;

static const wavetable_t s_tables[WAVETABLE_COUNT] = {
    { engine_idle_samples, ENGINE_IDLE_SAMPLE_COUNT, 800  },
    { engine_low_samples,  ENGINE_LOW_SAMPLE_COUNT,  2600 },
    { engine_mid_samples,  ENGINE_MID_SAMPLE_COUNT,  4400 },
    { engine_high_samples, ENGINE_HIGH_SAMPLE_COUNT, 6200 },
    { engine_rev_samples,  ENGINE_REV_SAMPLE_COUNT,  8000 },
};

/* ── Per-layer playback state ── */
typedef struct {
    uint32_t phase_Q24;    /* read position, Q24 fixed-point */
    uint32_t step_Q24;     /* phase increment per output sample */
    int32_t  amp_Q12;      /* current amplitude (smoothed) */
} layer_state_t;

/* ═══════════════════════════════════════════════════════════════
 *  Global state
 * ═══════════════════════════════════════════════════════════════ */
static volatile bool     s_playing      = false;
static volatile bool     s_stop_request = false;
static volatile uint16_t s_target_rpm   = SYNTH_RPM_MIN;
static volatile uint8_t  s_master_vol   = 80;
static TaskHandle_t      s_task         = NULL;

static uint16_t s_current_rpm;
static int32_t  s_fade;
static bool     s_fading_out;
static int16_t  s_buf[SYNTH_BUF_FRAMES * 2];

/* ── Layer state (we run all 5 layers in parallel) ── */
static layer_state_t s_layer[WAVETABLE_COUNT + 1];  /* +1 for knock */

/* ── Knock state ── */
static uint32_t s_knock_phase_Q24;
static uint32_t s_knock_timer;    /* countdown to next knock trigger */
static int32_t  s_knock_amp;      /* current knock amplitude (decaying) */

/* ── LP filter ── */
static int32_t s_lp_z1;

/* ═══════════════════════════════════════════════════════════════
 *  RPM smoothing (flywheel inertia) — unchanged
 * ═══════════════════════════════════════════════════════════════ */

static uint16_t smooth_rpm(uint16_t cur, uint16_t tgt) {
    int32_t delta = (int32_t)tgt - (int32_t)cur;
    if (delta > 0) {
        int32_t rate = 30 + (delta / 8);
        if (rate < 10) rate = 10;
        cur += (delta > rate) ? (uint16_t)rate : (uint16_t)delta;
    } else if (delta < 0) {
        delta = -delta;
        int32_t rate = 15 + (delta / 10);
        if (rate < 5) rate = 5;
        cur -= (delta > rate) ? (uint16_t)rate : (uint16_t)delta;
    }
    if (cur < SYNTH_RPM_MIN) cur = SYNTH_RPM_MIN;
    if (cur > SYNTH_RPM_MAX) cur = SYNTH_RPM_MAX;
    return cur;
}

/* ═══════════════════════════════════════════════════════════════
 *  Read sample from wavetable with linear interpolation
 *
 *  phase_Q24: 0..(length << 24) - 1, auto-wraps via mask
 *
 *  Returns int16_t sample (scaled from int8_t).
 * ═══════════════════════════════════════════════════════════════ */

static inline int32_t read_sample(const wavetable_t *wt, layer_state_t *ls) {
    uint32_t phase = ls->phase_Q24;

    /* Wrap using 64-bit to avoid overflow (84893 * 2^24 > 2^32) */
    uint64_t one_cycle_64 = (uint64_t)wt->length << 24;
    uint64_t phase_64 = (uint64_t)phase;
    while (phase_64 >= one_cycle_64) {
        phase_64 -= one_cycle_64;
    }
    phase = (uint32_t)phase_64;
    ls->phase_Q24 = phase;

    uint32_t idx = phase >> 24;
    uint32_t frac = (phase >> 12) & 0xFFF;

    uint32_t next = idx + 1;
    if (next >= wt->length) next = 0;

    int32_t s0 = (int32_t)wt->data[idx];
    int32_t s1 = (int32_t)wt->data[next];
    int32_t interp = s0 + (((s1 - s0) * (int32_t)frac) >> 12);

    return interp << 8;  /* int8 → int16 */
}

/* ═══════════════════════════════════════════════════════════════
 *  Knocked sample reader (non-looping, one-shot decay)
 * ═══════════════════════════════════════════════════════════════ */

static inline int32_t read_knock_sample(void) {
    uint32_t idx = s_knock_phase_Q24 >> 24;
    if (idx >= ENGINE_KNOCK_SAMPLE_COUNT) return 0;

    uint32_t frac = (s_knock_phase_Q24 >> 12) & 0xFFF;
    uint32_t next = idx + 1;
    if (next >= ENGINE_KNOCK_SAMPLE_COUNT) next = idx;

    int32_t s0 = (int32_t)engine_knock_samples[idx];
    int32_t s1 = (int32_t)engine_knock_samples[next];
    int32_t interp = s0 + (((s1 - s0) * (int32_t)frac) >> 12);

    /* Scale int8→int16 and apply current knock amplitude */
    return (interp << 8) * s_knock_amp / 4096;
}

/* Advance knock playhead and decay amplitude.
 * Called once per sample, even when knock is silent. */
static inline void advance_knock(void) {
    if (s_knock_amp <= 0) return;

    s_knock_phase_Q24 += 8388608;  /* play at original 22050 rate */

    /* Slow decay: lose ~1/256 per sample */
    s_knock_amp = s_knock_amp - (s_knock_amp >> 8);
    if (s_knock_amp < 10) s_knock_amp = 0;
}

/* ═══════════════════════════════════════════════════════════════
 *  Equal-power crossfade pre-computed tables
 *
 *  Q12 fixed-point cos²/sin² lookup for 17 entries (0..16 → 0..π/2).
 *  INDEX: 0 = start of transition, XFD_STEPS = mid-point.
 *
 *  Using pre-computed table avoids runtime sqrt/trig.
 * ═══════════════════════════════════════════════════════════════ */

#define XFD_HALF    300   /* half-width of each transition zone in RPM */
#define XFD_STEPS   16    /* resolution of the fade table */

/* cos²(t) for t = 0..π/2, 17 steps, in Q12 (0..4096).
 * Computed as: round(cos²(n * π/2 / 16) * 4096) */
static const int32_t s_cos2_Q12[XFD_STEPS + 1] = {
    4096, 4057, 3940, 3751, 3496, 3186, 2830, 2441,
    2048, 1655, 1266,  910,  600,  345,  156,   39,
       0
};

/* ═══════════════════════════════════════════════════════════════
 *  Layer crossfade — equal-power 2-layer blend with phase lock
 *
 *  At any RPM, at most 2 layers are active:
 *    primary:   the layer whose native RPM is closest below current RPM
 *    secondary: the next layer up (or the "rev" layer at high RPM)
 *
 *  Uses cos²/sin² equal-power fade for constant perceived loudness
 *  through the transition zone.
 *
 *  Output:
 *    primary_idx: index of dominant layer (or -1 if none)
 *    pri_w_Q12:   primary weight (0..4096)
 *    sec_w_Q12:   secondary weight (0..4096)
 *    sec_idx:     secondary layer index (or -1 if none)
 *
 *  Crossfade zones (XFD_HALF = 300 RPM):
 *    idle↔low: 1850-2150-2450  (600 RPM total transition)
 *    low↔mid:  3650-3950-4250  (600 RPM total transition)
 *    mid↔high: 5450-5750-6050  (600 RPM total transition)
 *    high+rev: 6500-8000       (rev fades in on top of high, max 50%)
 *
 *  FIX #1: Per-layer gain = 2048 (50% attenuation) to prevent
 *  overflow when two layers + knock are summed. Max combined before
 *  gain: 32767*2 + 16384 = 81918, after gain: ~40959 < 32767*2
 *  Final hard-clamp before LP filter catches any remaining spikes.
 *
 *  FIX #2: LP filter uses gentler alpha range: 400→3200 Hz cutoff
 *  (instead of 400→6500 Hz) to avoid harsh/sibilant highs at high RPM.
 *
 *  FIX #3: Knock gain reduced to 25% to avoid contributing to overflow.
 * ═══════════════════════════════════════════════════════════════ */

static void compute_blend(uint16_t rpm,
                          int *primary_idx, int32_t *pri_w_Q12,
                          int *sec_idx,    int32_t *sec_w_Q12)
{
    int32_t r = (int32_t)rpm;
    *primary_idx = -1;
    *pri_w_Q12 = 0;
    *sec_idx = -1;
    *sec_w_Q12 = 0;

    /* Layer native RPMs: 0=idle(800), 1=low(2600), 2=mid(4400),
     *                     3=high(6200), 4=rev(8000) */

    /* ── Pure zones & crossfade zones ── */

    if (r < 1850) {
        /* 800–1850: idle pure */
        *primary_idx = 0;
        *pri_w_Q12 = 4096;

    } else if (r < 2450) {
        /* 1850–2450: idle→low equal-power crossfade (mid=2150) */
        *primary_idx = 0;
        *sec_idx = 1;
        /* t: 0..XFD_STEPS within the transition zone */
        int32_t t = (r - 1850) * XFD_STEPS / (XFD_HALF * 2);
        if (t < 0) t = 0;
        if (t > XFD_STEPS) t = XFD_STEPS;
        /* cos² for primary, sin² (1-cos²) for secondary */
        int32_t c2 = s_cos2_Q12[t];
        *pri_w_Q12 = c2;
        *sec_w_Q12 = 4096 - c2;

    } else if (r < 3650) {
        /* 2450–3650: low pure */
        *primary_idx = 1;
        *pri_w_Q12 = 4096;

    } else if (r < 4250) {
        /* 3650–4250: low→mid equal-power crossfade (mid=3950) */
        *primary_idx = 1;
        *sec_idx = 2;
        int32_t t = (r - 3650) * XFD_STEPS / (XFD_HALF * 2);
        if (t < 0) t = 0;
        if (t > XFD_STEPS) t = XFD_STEPS;
        int32_t c2 = s_cos2_Q12[t];
        *pri_w_Q12 = c2;
        *sec_w_Q12 = 4096 - c2;

    } else if (r < 5450) {
        /* 4250–5450: mid pure */
        *primary_idx = 2;
        *pri_w_Q12 = 4096;

    } else if (r < 6050) {
        /* 5450–6050: mid→high equal-power crossfade (mid=5750) */
        *primary_idx = 2;
        *sec_idx = 3;
        int32_t t = (r - 5450) * XFD_STEPS / (XFD_HALF * 2);
        if (t < 0) t = 0;
        if (t > XFD_STEPS) t = XFD_STEPS;
        int32_t c2 = s_cos2_Q12[t];
        *pri_w_Q12 = c2;
        *sec_w_Q12 = 4096 - c2;

    } else {
        /* 6050–8000: high pure + rev overlay */
        *primary_idx = 3;
        *pri_w_Q12 = 4096;
        if (r >= 6500) {
            /* rev fades in on top of high, max 2048 (50%) */
            *sec_idx = 4;
            *sec_w_Q12 = (r - 6500) * 2048 / 1500;
            if (*sec_w_Q12 > 2048) *sec_w_Q12 = 2048;
        }
    }

    /* Clamp */
    if (*pri_w_Q12 < 0) *pri_w_Q12 = 0;
    if (*pri_w_Q12 > 4096) *pri_w_Q12 = 4096;
    if (*sec_w_Q12 < 0) *sec_w_Q12 = 0;
    if (*sec_w_Q12 > 4096) *sec_w_Q12 = 4096;
}

/* ═══════════════════════════════════════════════════════════════
 *  Synth task
 * ═══════════════════════════════════════════════════════════════ */

static void synth_task(void *arg) {
    ESP_LOGI(TAG, "Wavetable synth started — 5 layers + knock");

    /* Init all state */
    s_current_rpm = SYNTH_RPM_MIN;
    s_fade = 0;
    s_fading_out = false;
    s_lp_z1 = 0;

    for (int i = 0; i <= WAVETABLE_COUNT; i++) {
        s_layer[i].phase_Q24 = 0;
        s_layer[i].step_Q24 = 0;
        s_layer[i].amp_Q12 = 0;
    }
    s_knock_phase_Q24 = 0;
    s_knock_timer = 0;
    s_knock_amp = 0;

    const int32_t fade_in_step  = (256 + SYNTH_FADE_IN_BUFS  - 1) / SYNTH_FADE_IN_BUFS;
    const int32_t fade_out_step = (256 + SYNTH_FADE_OUT_BUFS - 1) / SYNTH_FADE_OUT_BUFS;

    while (1) {
        /* ── RPM update ── */
        s_current_rpm = smooth_rpm(s_current_rpm, s_target_rpm);

        /* ── Fade ── */
        if (s_stop_request && !s_fading_out) s_fading_out = true;
        if (s_fading_out) {
            s_fade -= fade_out_step;
            if (s_fade <= 0) { s_fade = 0; break; }
        } else if (s_fade < 256) {
            s_fade += fade_in_step;
            if (s_fade > 256) s_fade = 256;
        }

        /* ── Compute blend: at most 2 active layers ── */
        int pri_idx, sec_idx;
        int32_t pri_target_Q12, sec_target_Q12;
        compute_blend(s_current_rpm, &pri_idx, &pri_target_Q12,
                      &sec_idx, &sec_target_Q12);

        /* Phase lock: when a secondary layer first becomes active
         * (its weight just crossed from 0 to >0), sync its phase to
         * the primary layer's phase, scaled by sample length ratio.
         * This prevents beat frequencies and comb filtering. */
        static int s_prev_pri_idx = -1;
        static int s_prev_sec_idx = -1;
        static int32_t s_prev_sec_w = 0;

        if (sec_idx >= 0 && sec_target_Q12 > 0 && s_prev_sec_w == 0) {
            /* Secondary just activated — phase-lock to primary */
            if (pri_idx >= 0) {
                uint64_t pri_pos = (uint64_t)s_layer[pri_idx].phase_Q24 *
                                   (uint64_t)s_tables[sec_idx].length /
                                   (uint64_t)s_tables[pri_idx].length;
                s_layer[sec_idx].phase_Q24 = (uint32_t)pri_pos;
            }
        }
        s_prev_pri_idx = pri_idx;
        s_prev_sec_idx = sec_idx;
        s_prev_sec_w = sec_target_Q12;

        /* Also phase-lock on primary change (e.g. idle→low) */
        static int s_prev_pri_idx2 = -1;
        if (pri_idx >= 0 && pri_idx != s_prev_pri_idx2 && s_prev_pri_idx2 >= 0) {
            uint64_t old_pos = (uint64_t)s_layer[s_prev_pri_idx2].phase_Q24 *
                               (uint64_t)s_tables[pri_idx].length /
                               (uint64_t)s_tables[s_prev_pri_idx2].length;
            s_layer[pri_idx].phase_Q24 = (uint32_t)old_pos;
        }
        s_prev_pri_idx2 = pri_idx;

        /* ── Compute per-layer phase steps ── */
        /* Each layer plays at a rate proportional to current RPM,
         * relative to its native RPM.
         *
         * For a layer recorded at native_rpm, to play at current_rpm:
         *   step = (current_rpm / native_rpm) * (native_sample_rate / output_rate) * 2^24
         *
         * Example: idle layer at 2600 RPM:
         *   step = (2600/800) * (22050/44100) * 2^24
         *        = 3.25 * 0.5 * 16777216
         *        = 27288960
         */

        /* FIX #2: LP filter — gentler cutoff range: 400Hz at idle, 3200Hz at max.
         * Previously used 400Hz→6500Hz which was too harsh on highs.
         * Formula: alpha_Q14 = round(cutoff_Hz * 2π / 44100 * 16384)
         *   400Hz → 1009 Q14, 3200Hz → 8072 Q14 */
        int32_t lp_alpha_Q14;
        {
            int32_t frac_Q12 = ((int32_t)s_current_rpm - SYNTH_RPM_MIN) * 4096 /
                               (SYNTH_RPM_MAX - SYNTH_RPM_MIN);
            lp_alpha_Q14 = 1000 + (frac_Q12 * 7000 / 4096);  /* 1000→8000 */
        }

        /* ── Update layer playback rates ── */
        for (int i = 0; i < WAVETABLE_COUNT; i++) {
            /* step = (current_rpm / native_rpm) * (22050/44100) * 2^24
             *      = current_rpm * 22050 * 2^24 / (native_rpm * 44100)
             *      = current_rpm * 8388608 / native_rpm
             */
            uint32_t step = (uint32_t)(((uint64_t)s_current_rpm * 8388608ULL) /
                                        (uint64_t)s_tables[i].native_rpm);
            s_layer[i].step_Q24 = step;
        }

        /* ── Knock trigger ── */
        /* Subtle knock at high RPM for texture — gentler than before */
        if (s_current_rpm > 5000) {
            if (s_knock_timer == 0) {
                s_knock_timer = (s_current_rpm > 6500) ? 4410 : 13230;
                s_knock_amp = (s_current_rpm > 7000) ? 2048 : 1024;
                s_knock_phase_Q24 = 0;
            }
        }
        if (s_knock_timer > 0) s_knock_timer--;

        /* ── Fill buffer ── */
        for (int i = 0; i < SYNTH_BUF_FRAMES; i++) {
            int32_t sample = 0;

            /* ── Mix at most 2 layers ── */
            /* Helper: update one layer — read, scale, advance.
             *
             * Amp ramp: 128 Q12/sample = ~32 samples (~0.73ms) to full.
             * Slower than before to complement equal-power fade smoothness.
             *
             * FIX #1: Per-layer gain = 2048 (50%) to prevent overflow when
             * two layers + knock are summed at transition zones.
             * Before gain: max(32767 + 32767 + ~16000) = ~81500
             * After gain: ~40750 — safely below 16-bit range after final clamp */
            #define MIX_LAYER(l_idx, target_Q12) do { \
                layer_state_t *ls = &s_layer[l_idx]; \
                int32_t ramp_step = 128; \
                if (ls->amp_Q12 < (target_Q12)) { \
                    ls->amp_Q12 += ramp_step; \
                    if (ls->amp_Q12 > (target_Q12)) ls->amp_Q12 = (target_Q12); \
                } else if (ls->amp_Q12 > (target_Q12)) { \
                    ls->amp_Q12 -= ramp_step; \
                    if (ls->amp_Q12 < (target_Q12)) ls->amp_Q12 = (target_Q12); \
                } \
                if (ls->amp_Q12 > 0) { \
                    int32_t s = read_sample(&s_tables[l_idx], ls); \
                    /* FIX #1: scale by 2048 (50%) before summing to prevent clip */ \
                    sample += ((s * ls->amp_Q12) >> 12) >> 1; \
                    ls->phase_Q24 += ls->step_Q24; \
                } \
            } while(0)

            /* Primary layer always plays if active */
            if (pri_idx >= 0) MIX_LAYER(pri_idx, pri_target_Q12);

            /* Secondary layer (crossfade partner or rev overlay) */
            if (sec_idx >= 0 && sec_target_Q12 > 0) MIX_LAYER(sec_idx, sec_target_Q12);

            #undef MIX_LAYER

            /* ── Knock layer (FIX #3: gain 1024 = 25%) ── */
            {
                int32_t ks = read_knock_sample();
                /* Knock already includes amp in its calculation, apply extra 25% */
                sample += ks >> 1;
                advance_knock();
            }

            /* ── LP filter ── */
            {
                int32_t diff = sample - s_lp_z1;
                s_lp_z1 = s_lp_z1 + ((diff * lp_alpha_Q14) >> 14);
                sample = s_lp_z1;
            }

            /* FIX #4: Volume gain calculation — use saturating 32-bit multiply.
             * Old formula: (sample * vol_gain) >> 8 was producing ~2 instead of
             * ~256 at max volume due to truncation in the intermediate calculation.
             * New formula: directly multiply sample by volume percentage (0-100). */
            sample = (sample * (int32_t)s_master_vol) / 100;

            /* ── Clamp ── */
            if (sample >  32767) sample =  32767;
            if (sample < -32768) sample = -32768;

            s_buf[i * 2]     = (int16_t)sample;
            s_buf[i * 2 + 1] = (int16_t)sample;
        }

        drv_audio_write(s_buf, SYNTH_BUF_FRAMES);
    }

    /* ── Clean shutdown ── */
    memset(s_buf, 0, sizeof(s_buf));
    for (int i = 0; i < 4; i++) drv_audio_write(s_buf, SYNTH_BUF_FRAMES);
    drv_audio_stop();

    s_playing = false;
    s_task = NULL;
    ESP_LOGI(TAG, "Synth stopped");
    vTaskDelete(NULL);
}

/* ═══════════════════════════════════════════════════════════════
 *  Public API — UNCHANGED
 * ═══════════════════════════════════════════════════════════════ */

void engine_synth_init(void) {
    ESP_LOGI(TAG, "Wavetable engine synth initialized");
}

void engine_synth_start(void) {
    if (s_playing) return;

    ESP_LOGI(TAG, "Synth start: pausing audio engine...");
    extern void audio_engine_pause(void);
    audio_engine_pause();

    ESP_LOGI(TAG, "Synth start: restarting I2S...");
    drv_audio_restart();

    memset(s_buf, 0, sizeof(s_buf));
    for (int i = 0; i < 4; i++) drv_audio_write(s_buf, SYNTH_BUF_FRAMES);

    s_stop_request = false;
    s_playing = true;
    s_target_rpm = SYNTH_RPM_MIN;

    ESP_LOGI(TAG, "Synth start: creating synth task...");
    if (xTaskCreatePinnedToCore(synth_task, "eng_synth", 4096, NULL, 6, &s_task, 1) != pdPASS) {
        ESP_LOGE(TAG, "Task create failed");
        s_playing = false;
        extern void audio_engine_resume(void);
        audio_engine_resume();
    }
}

void engine_synth_stop(void) {
    if (!s_playing) return;
    s_stop_request = true;
    for (int i = 0; i < 200 && s_task; i++) vTaskDelay(pdMS_TO_TICKS(10));
    if (s_task) {
        vTaskDelete(s_task);
        s_task = NULL;
        s_playing = false;
        drv_audio_stop();
    }
    extern void audio_engine_resume(void);
    audio_engine_resume();
}

bool engine_synth_is_playing(void) {
    return s_playing;
}

void engine_synth_set_rpm(uint8_t pct) {
    if (pct > 100) pct = 100;

    uint16_t rpm = SYNTH_RPM_MIN + (uint32_t)pct * (SYNTH_RPM_MAX - SYNTH_RPM_MIN) / 100;

    if (pct < 5) {
        s_target_rpm = SYNTH_RPM_MIN;
        s_master_vol = (uint8_t)(5 + pct * 5);
    } else if (pct < 12) {
        s_target_rpm = rpm;
        s_master_vol = (uint8_t)(30 + (pct - 5) * 7);
    } else {
        s_target_rpm = rpm;
        s_master_vol = 100;
    }
}

uint16_t engine_synth_get_rpm(void) {
    /* Return RPM percentage (0-100) that was last set */
    if (s_target_rpm <= SYNTH_RPM_MIN) return 0;
    uint32_t pct = ((uint32_t)(s_target_rpm - SYNTH_RPM_MIN) * 100)
                   / (SYNTH_RPM_MAX - SYNTH_RPM_MIN);
    return (uint16_t)(pct > 100 ? 100 : pct);
}

void engine_synth_set_volume(uint8_t v) {
    if (v > 100) v = 100;
    s_master_vol = v;
}
