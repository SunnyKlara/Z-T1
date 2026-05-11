/* ═══════════════════════════════════════════════════════════════
 * STEER: 反臃肿 | scope=firmware | core/state/
 *
 * 职责: Logo 状态的子结构体定义
 * 不做什么: 不包含 Logo 上传/存储逻辑（属于 modules/logo/）
 * ═══════════════════════════════════════════════════════════════ */

#pragma once
#include <stdint.h>

typedef struct {
    uint8_t active_slot;     /* 当前显示槽位 0-2 */
    uint8_t slots[3];        /* 0=空, 1=有 Logo */
} logo_state_t;
