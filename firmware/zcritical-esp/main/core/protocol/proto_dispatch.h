/* ═══════════════════════════════════════════════════════════════
 * STEER: 反臃肿 | scope=firmware | core/protocol/
 *
 * 职责: 命令分发 — 接收 cmd_msg_t，更新状态，回复 BLE
 * 不做什么: 不解析协议文本（属于 proto_parser.c）、不实现硬件操作（属于 modules/）
 * ═══════════════════════════════════════════════════════════════ */

#pragma once
#include "proto_parser.h"

/* 分发一条命令：修改状态 + 回复 BLE */
void proto_dispatch(const cmd_msg_t *cmd);
