/* ═══════════════════════════════════════════════════════════════
 * STEER: 反臃肿 | max_lines=45 | scope=firmware | 修改前读 anti-bloat.md
 *
 * 职责: EC11 编码器驱动 — 初始化 PCNT 硬件解码 + GPIO按键 + 事件轮询
 * 不做什么: 不处理 UI 菜单导航逻辑（由 modules/encoder/ 负责）
 *
 * 硬件 (唯一真值源: steering/specs/hardware-config.md):
 *   S1(A相)=IO17, S2(B相)=IO18, KEY(按键)=IO8 (active low, 内部上拉)
 *   消抖: PCNT 硬件 1μs glitch filter
 *   按键: 400ms 连击超时 / 800ms 长按判定
 * ═══════════════════════════════════════════════════════════════ */

#pragma once

#include <stdint.h>
#include <stdbool.h>

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

void hal_encoder_init(void);
bool hal_encoder_poll(hal_encoder_event_t *evt);
bool hal_encoder_button_pressed(void);
