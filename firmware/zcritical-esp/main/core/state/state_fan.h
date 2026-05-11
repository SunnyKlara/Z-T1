/* ═══════════════════════════════════════════════════════════════
 * STEER: 反臃肿 | scope=firmware | core/state/
 *
 * 职责: 风扇+加湿器状态的子结构体定义
 * 不做什么: 不包含业务逻辑（属于 modules/fan/）
 * ═══════════════════════════════════════════════════════════════ */

#pragma once
#include <stdint.h>

typedef struct {
    uint8_t speed;          /* 0-100 PWM 占空比 */
    uint8_t wuhuaqi;        /* 0=关, 1=开, 2=油门(强制开) */
    uint8_t unit;           /* 0=km/h, 1=mph */
} fan_state_t;
