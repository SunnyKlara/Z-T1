/* ═══════════════════════════════════════════════════════════════
 * STEER: 反臃肿 | scope=firmware | core/state/
 *
 * 职责: LED 状态的子结构体定义 — 颜色、亮度、预设、特效
 * 不做什么: 不包含 LED 驱动逻辑（属于 modules/led/）
 * ═══════════════════════════════════════════════════════════════ */

#pragma once
#include <stdint.h>

typedef struct {
    uint8_t colors[2][3];   /* [strip 0=Main/1=Tail][R/G/B] 0-255 */
    uint8_t brightness;      /* 0-100 */
    uint8_t preset;          /* 1-14 LED 预设 */
    uint8_t streamlight;     /* 0=关, 1=开 流水灯 */
    uint8_t gradient_speed;  /* 渐变速度 0=快/1=中/2=慢 */
} led_state_t;
