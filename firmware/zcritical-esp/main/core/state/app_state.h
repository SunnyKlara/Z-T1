/* ═══════════════════════════════════════════════════════════════
 * STEER: 反臃肿 | scope=firmware | core/state/
 *
 * 职责: 全局状态聚合 — 包含所有子结构体 + 互斥锁
 * 不做什么: 不包含业务逻辑、不包含硬件操作
 *
 * 依赖: state_fan.h / state_led.h / state_ui.h / state_audio.h / state_logo.h
 * ═══════════════════════════════════════════════════════════════ */

#pragma once
#include "state_fan.h"
#include "state_led.h"
#include "state_ui.h"
#include "state_audio.h"
#include "state_logo.h"
#include "freertos/FreeRTOS.h"
#include "freertos/semphr.h"

typedef struct {
    fan_state_t   fan;
    led_state_t   led;
    ui_state_t    ui;
    audio_state_t audio;
    logo_state_t  logo;
} app_state_t;

/* 全局单例 */
extern app_state_t g_app_state;
extern SemaphoreHandle_t g_state_mutex;

/* 初始化 */
void app_state_init(void);

/* 锁操作 */
#define APP_STATE_LOCK()   xSemaphoreTake(g_state_mutex, portMAX_DELAY)
#define APP_STATE_UNLOCK() xSemaphoreGive(g_state_mutex)
