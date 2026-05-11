/* ═══════════════════════════════════════════════════════════════
 * STEER: 反臃肿 | scope=firmware | core/state/
 *
 * 职责: 音频状态的子结构体定义
 * 不做什么: 不包含音频引擎逻辑（属于 modules/audio/）
 * ═══════════════════════════════════════════════════════════════ */

#pragma once
#include <stdint.h>

typedef struct {
    uint8_t volume;          /* 0-100 */
    uint8_t engine_on;       /* 引擎声 0=关/1=开 */
} audio_state_t;
