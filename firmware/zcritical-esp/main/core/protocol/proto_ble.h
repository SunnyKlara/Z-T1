/* ═══════════════════════════════════════════════════════════════
 * STEER: 反臃肿 | max_lines=30 | scope=firmware
 *
 * 职责: BLE GATTS 服务 — 广播 + GATT 属性表 + 连接管理 + 通知发送
 * 不做什么: 不解析命令、不管理命令队列、不处理 Logo 上传（Phase 2 B2）
 *
 * BLE参数 (唯一真值源: steering/specs/protocol-contract.md):
 *   Device Name: "T1"
 *   Service UUID:  0xFFE0
 *   Char UUID:     0xFFE1 (write-without-response + notify)
 * ═══════════════════════════════════════════════════════════════ */

#pragma once

#include <stdint.h>
#include <stdbool.h>

/* Public API */
void proto_ble_init(void);
void proto_ble_start_advertising(void);
void proto_ble_stop_advertising(void);
void proto_ble_notify(const char *data, uint16_t len);
void proto_ble_notify_str(const char *str);
bool proto_ble_is_connected(void);
void proto_ble_set_data_callback(void (*cb)(const uint8_t *data, uint16_t len));
