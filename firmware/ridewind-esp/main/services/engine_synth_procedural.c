/**
 * @file engine_synth_procedural.c
 * @brief 纯程序化引擎声音合成器 - 零素材依赖！
 *
 * ═══════════════════════════════════════════════════════════════
 *  声音合成原理
 * ═══════════════════════════════════════════════════════════════
 *
 * 1. 引擎主体：多谐波锯齿波
 *    - 基础频率 = RPM / 60 * 气缸数 / 2 (四冲程)
 *    - 锯齿波 = 基频 + 2次 + 3次 + ... 谐波
 *    - 低通滤波模拟排气系统共振
 *
 * 2. 涡轮增压：滤波白噪声
 *    - 白噪声通过带通滤波器
 *    - 中心频率随增压值变化
 *    - 泄压阀 = 短暂高频噪声爆发
 *
 * 3. 换挡提示：正弦波短音
 *    - 升档：800Hz → 1200Hz 上滑音
 *    - 降档：600Hz → 400Hz 下滑音
 *
 * 4. 爆震/回火：随机脉冲
 *    - 低概率触发短促脉冲
 *    - 模拟排气管爆震
 */

#include "engine_synth_procedural.h"
#include "drv_audio.h"
#include "esp_log.h"
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include <string.h>
#include <math.h>

static const char *TAG = "ENGINE_SYNTH_PROC";

/* ═══════════════════════════════════════════════════════════════
 *  引擎类型配置
 * ═══════════════════════════════════════════════════════════════ */

typedef struct {
    int cylinders;           /* 气缸数 */
    float base_harmonics;    /* 基础谐波数 */
    float distortion;        /* 失真度 0-1 */
    float exhaust_resonance; /* 排气共振频率 (Hz) */
    float idle_freq_mult;    /* 怠速频率倍率 */
} engine_config_t;

static const engine_config_t s_engine_configs[] = {
    [ENGINE_TYPE_I4]  = { 4,  8.0f, 0.3f, 200.0f, 0.8f },
    [ENGINE_TYPE_V6]  = { 6,  12.0f, 0.2f, 150.0f, 0.7f },
    [ENGINE_TYPE_V8]  = { 8,  16.0f, 0.4f, 100.0f, 0.6f },
    [ENGINE_TYPE_W12] = { 12, 20.0f, 0.15f, 120.0f, 0.5f },
};

/* ═══════════════════════════════════════════════════════════════
 *  全局状态
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

static engine_type_t s_engine_type = ENGINE_TYPE_V6;

/* ── 涡轮增压状态 ── */
static volatile uint8_t s_turbo_boost = 0;
static volatile bool    s_turbo_wastegate = false;
static float s_turbo_noise_phase = 0;
static float s_wastegate_decay = 0;

/* ── 换挡提示状态 ── */
static bool     s_shift_active = false;
static float    s_shift_phase = 0;
static float    s_shift_freq_start = 0;
static float    s_shift_freq_end = 0;
static uint32_t s_shift_duration = 0;
static uint32_t s_shift_elapsed = 0;

/* ── 爆震状态 ── */
static float s_backfire_decay = 0;
static uint32_t s_backfire_timer = 0;

/* ── 滤波器状态 ── */
static float s_exhaust_z1 = 0;
static float s_exhaust_z2 = 0;
static float s_turbo_bp_z1 = 0;
static float s_turbo_bp_z2 = 0;

/* ═══════════════════════════════════════════════════════════════
 *  数学工具函数
 * ═══════════════════════════════════════════════════════════════ */

/* 快速锯齿波：使用相位累加器 */
static inline float sawtooth(float phase) {
    return 2.0f * (phase - floorf(phase + 0.5f));
}

/* 快速正弦波：使用泰勒级数近似 */
static inline float fast_sin(float x) {
    /* 归一化到 [-π, π] */
    while (x > 3.14159265f) x -= 6.2831853f;
    while (x < -3.14159265f) x += 6.2831853f;
    
    /* 5 项泰勒展开 */
    float x2 = x * x;
    return x * (1.0f - x2 / 6.0f * (1.0f - x2 / 20.0f * (1.0f - x2 / 42.0f)));
}

/* 白噪声生成 */
static inline float white_noise(void) {
    /* 简单 LCG 随机数 */
    static uint32_t seed = 12345;
    seed = seed * 1103515245 + 12345;
    return ((float)(seed >> 16) / 32768.0f) - 1.0f;
}

/* ═══════════════════════════════════════════════════════════════
 *  滤波器
 * ═══════════════════════════════════════════════════════════════ */

/* 二阶低通滤波器 (biquad) */
static inline float lp_filter(float input, float cutoff_hz, float sample_rate) {
    float rc = 1.0f / (2.0f * 3.14159265f * cutoff_hz);
    float dt = 1.0f / sample_rate;
    float alpha = dt / (rc + dt);
    
    s_exhaust_z1 = s_exhaust_z1 + alpha * (input - s_exhaust_z1);
    return s_exhaust_z1;
}

/* 二阶带通滤波器 */
static inline float bp_filter(float input, float center_hz, float q, float sample_rate) {
    float w0 = 2.0f * 3.14159265f * center_hz / sample_rate;
    float b1 = 1.0f - fast_sin(w0);  /* 简化系数 */
    
    float output = b1 * (input - s_turbo_bp_z2) + 2.0f * cosf(w0) * s_turbo_bp_z1 - s_turbo_bp_z2;
    s_turbo_bp_z2 = s_turbo_bp_z1;
    s_turbo_bp_z1 = output;
    
    return output * 0.5f;  /* 增益补偿 */
}

/* ═══════════════════════════════════════════════════════════════
 *  RPM 平滑 (飞轮惯性)
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
 *  合成任务
 * ═══════════════════════════════════════════════════════════════ */

static void synth_task(void *arg) {
    ESP_LOGI(TAG, "Procedural synth started — zero samples needed!");
    
    const engine_config_t *cfg = &s_engine_configs[s_engine_type];
    
    s_current_rpm = SYNTH_RPM_MIN;
    s_fade = 0;
    s_fading_out = false;
    s_exhaust_z1 = 0;
    s_exhaust_z2 = 0;
    
    float engine_phase = 0;
    float turbo_phase = 0;
    
    const int32_t fade_in_step  = (256 + SYNTH_FADE_IN_BUFS  - 1) / SYNTH_FADE_IN_BUFS;
    const int32_t fade_out_step = (256 + SYNTH_FADE_OUT_BUFS - 1) / SYNTH_FADE_OUT_BUFS;
    
    while (1) {
        /* ── RPM 更新 ── */
        s_current_rpm = smooth_rpm(s_current_rpm, s_target_rpm);
        
        /* ── 淡入淡出 ── */
        if (s_stop_request && !s_fading_out) s_fading_out = true;
        if (s_fading_out) {
            s_fade -= fade_out_step;
            if (s_fade <= 0) { s_fade = 0; break; }
        } else if (s_fade < 256) {
            s_fade += fade_in_step;
            if (s_fade > 256) s_fade = 256;
        }
        
        /* ── 计算引擎参数 ── */
        float rpm_ratio = (float)(s_current_rpm - SYNTH_RPM_MIN) / (SYNTH_RPM_MAX - SYNTH_RPM_MIN);
        
        /* 基础频率：四冲程引擎 = RPM/60 * 气缸数/2 */
        float base_freq = (float)s_current_rpm / 60.0f * (float)cfg->cylinders / 2.0f;
        base_freq *= cfg->idle_freq_mult + (1.0f - cfg->idle_freq_mult) * rpm_ratio;
        
        /* 相位增量 */
        float phase_inc = base_freq / 44100.0f;
        
        /* 谐波数随 RPM 增加 */
        float num_harmonics = cfg->base_harmonics * (1.0f + rpm_ratio * 2.0f);
        if (num_harmonics > 32) num_harmonics = 32;  /* 限制计算量 */
        
        /* 低通截止频率 */
        float exhaust_cutoff = cfg->exhaust_resonance * (1.0f + rpm_ratio * 8.0f);
        
        /* ── 生成音频缓冲区 ── */
        for (int i = 0; i < SYNTH_BUF_FRAMES; i++) {
            float engine_sample = 0;
            
            /* ── 引擎主体：多谐波锯齿波 ── */
            for (int h = 1; h <= (int)num_harmonics; h++) {
                float harm_phase = engine_phase * h;
                float harm_amp = 1.0f / (float)h;  /* 谐波衰减 */
                
                /* 偶次谐波稍微增强（模拟排气共振） */
                if (h % 2 == 0) harm_amp *= 1.2f;
                
                engine_sample += sawtooth(harm_phase) * harm_amp;
            }
            
            /* 归一化 */
            engine_sample /= (num_harmonics * 0.5f);
            
            /* 添加轻微失真 */
            float dist = cfg->distortion * rpm_ratio;
            if (dist > 0) {
                engine_sample = engine_sample * (1.0f + dist) / (1.0f + dist * fabsf(engine_sample));
            }
            
            /* 排气低通滤波 */
            engine_sample = lp_filter(engine_sample, exhaust_cutoff, 44100.0f);
            
            /* ── 涡轮增压：滤波白噪声 ── */
            if (s_turbo_boost > 0) {
                float turbo_vol = (float)s_turbo_boost / 100.0f;
                float noise = white_noise();
                
                /* 带通中心频率随增压变化 */
                float turbo_center = 800.0f + rpm_ratio * 2000.0f;
                float turbo_q = 2.0f + turbo_vol * 3.0f;
                
                float turbo_sample = bp_filter(noise, turbo_center, turbo_q, 44100.0f);
                turbo_sample *= turbo_vol * 0.3f;
                
                /* 泄压阀效果 */
                if (s_turbo_wastegate && s_wastegate_decay > 0) {
                    float wg_sample = white_noise() * s_wastegate_decay * 0.5f;
                    turbo_sample += wg_sample;
                    s_wastegate_decay *= 0.95f;
                    if (s_wastegate_decay < 0.01f) s_wastegate_decay = 0;
                }
                
                engine_sample += turbo_sample;
            }
            
            /* ── 爆震/回火 ── */
            if (s_backfire_decay > 0) {
                engine_sample += white_noise() * s_backfire_decay * 0.4f;
                s_backfire_decay *= 0.9f;
                if (s_backfire_decay < 0.01f) s_backfire_decay = 0;
            }
            
            /* 随机触发爆震（低 RPM 时更频繁） */
            if (s_backfire_timer == 0 && rpm_ratio < 0.7f) {
                if (white_noise() > 0.98f) {
                    s_backfire_decay = 0.8f;
                }
                s_backfire_timer = 100 + (uint32_t)(white_noise() * 500);
            }
            if (s_backfire_timer > 0) s_backfire_timer--;
            
            /* ── 换挡提示音 ── */
            if (s_shift_active) {
                s_shift_elapsed++;
                float shift_progress = (float)s_shift_elapsed / (float)s_shift_duration;
                
                if (shift_progress >= 1.0f) {
                    s_shift_active = false;
                } else {
                    /* 频率滑音 */
                    float shift_freq = s_shift_freq_start + 
                        (s_shift_freq_end - s_shift_freq_start) * shift_progress;
                    float shift_phase_inc = shift_freq / 44100.0f;
                    s_shift_phase += shift_phase_inc;
                    
                    /* 包络：快速起音 + 指数衰减 */
                    float env;
                    if (shift_progress < 0.1f) {
                        env = shift_progress / 0.1f;
                    } else {
                        env = expf(-(shift_progress - 0.1f) * 8.0f);
                    }
                    
                    float shift_sample = fast_sin(s_shift_phase * 6.2831853f) * env * 0.25f;
                    engine_sample += shift_sample;
                }
            }
            
            /* ── 应用音量和淡入淡出 ── */
            float volume = (float)s_master_vol / 100.0f;
            float fade = (float)s_fade / 256.0f;
            engine_sample *= volume * fade;
            
            /* 软限幅 */
            if (engine_sample > 1.0f) engine_sample = 1.0f;
            if (engine_sample < -1.0f) engine_sample = -1.0f;
            
            int16_t sample = (int16_t)(engine_sample * 32767.0f);
            s_buf[i * 2] = sample;
            s_buf[i * 2 + 1] = sample;
            
            engine_phase += phase_inc;
            if (engine_phase > 1000.0f) engine_phase -= 1000.0f;  /* 防止溢出 */
        }
        
        drv_audio_write(s_buf, SYNTH_BUF_FRAMES);
        
        /* Yield to prevent watchdog timeout */
        vTaskDelay(1);
    }
    
    /* ── 清理关闭 ── */
    memset(s_buf, 0, sizeof(s_buf));
    for (int i = 0; i < 4; i++) drv_audio_write(s_buf, SYNTH_BUF_FRAMES);
    drv_audio_stop();
    
    s_playing = false;
    s_task = NULL;
    ESP_LOGI(TAG, "Synth stopped");
    vTaskDelete(NULL);
}

/* ═══════════════════════════════════════════════════════════════
 *  公共 API
 * ═══════════════════════════════════════════════════════════════ */

void engine_synth_init(void) {
    ESP_LOGI(TAG, "Procedural engine synth initialized (zero samples!)");
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
    if (xTaskCreatePinnedToCore(synth_task, "eng_synth_proc", 4096, NULL, 6, &s_task, 1) != pdPASS) {
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

void engine_synth_set_volume(uint8_t v) {
    if (v > 100) v = 100;
    s_master_vol = v;
}

/* ── 涡轮增压控制 ── */
void engine_synth_set_turbo_boost(uint8_t boost_percent) {
    if (boost_percent > 100) boost_percent = 100;
    s_turbo_boost = boost_percent;
}

void engine_synth_set_turbo_wastegate(bool open) {
    s_turbo_wastegate = open;
    if (open) {
        s_wastegate_decay = 1.0f;  /* 触发泄压阀声音 */
    }
}

/* ── 换挡提示 ── */
void engine_synth_play_shift_up(void) {
    s_shift_active = true;
    s_shift_phase = 0;
    s_shift_freq_start = 800.0f;
    s_shift_freq_end = 1200.0f;
    s_shift_duration = 150;  /* 约 3.4ms @ 44100Hz */
    s_shift_elapsed = 0;
}

void engine_synth_play_shift_down(void) {
    s_shift_active = true;
    s_shift_phase = 0;
    s_shift_freq_start = 600.0f;
    s_shift_freq_end = 400.0f;
    s_shift_duration = 200;
    s_shift_elapsed = 0;
}

/* ── 引擎类型 ── */
void engine_synth_set_type(engine_type_t type) {
    if (type <= ENGINE_TYPE_W12) {
        s_engine_type = type;
    }
}
