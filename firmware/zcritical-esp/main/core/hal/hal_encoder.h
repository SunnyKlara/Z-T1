#pragma once

/* ═══════════════════════════════════════════════════════════════
 * STEER: 反臃肿 | max_lines=50 | scope=firmware | 修改前读 anti-bloat.md
 *
 * 职责: EC11 编码器驱动 — PCNT 旋转解码 + GPIO 按键检测
 * 不做什么: 不含事件分发逻辑、不含 UI 交互、不含菜单导航
 * 硬件: S1(IO17), S2(IO18), KEY(IO8, 拉低触发) — 唯一真值源 hardware-config.md
 * ═══════════════════════════════════════════════════════════════ */

#include <stdint.h>
#include <stdbool.h>
#include "esp_err.h"

typedef enum {
    HAL_ENC_EVT_NONE = 0,
    HAL_ENC_EVT_ROTATE,
    HAL_ENC_EVT_CLICK,
    HAL_ENC_EVT_DOUBLE_CLICK,
    HAL_ENC_EVT_TRIPLE_CLICK,
    HAL_ENC_EVT_LONG_PRESS,
    HAL_ENC_EVT_PRESS,
    HAL_ENC_EVT_RELEASE,
} hal_encoder_event_type_t;

typedef struct {
    hal_encoder_event_type_t type;
    int16_t delta;
} hal_encoder_event_t;

esp_err_t hal_encoder_init(void);
bool hal_encoder_poll(hal_encoder_event_t *evt);
bool hal_encoder_button_pressed(void);
