/* ═══════════════════════════════════════════════════════════════
 * STEER: 反臃肿 | scope=firmware | core/protocol/
 *
 * 职责: 文本协议解析 — "KEY:VALUE\n" → cmd_msg_t
 * 不做什么: 不执行命令（属于 proto_dispatch.c）
 *
 * 协议源: steering/specs/protocol-contract.md
 * ═══════════════════════════════════════════════════════════════ */

#pragma once
#include <stdint.h>

/* 命令类型枚举 */
typedef enum {
    CMD_FAN, CMD_SPEED, CMD_WUHUA,
    CMD_LED, CMD_PRESET, CMD_BRIGHT, CMD_STREAMLIGHT, CMD_LED_GRADIENT,
    CMD_LCD, CMD_UI, CMD_VOL,
    CMD_THROTTLE, CMD_UNIT, CMD_TREAD,
    CMD_WIFI, CMD_WIFI_SCAN,
    CMD_GET_FAN, CMD_GET_WUHUA, CMD_GET_BRIGHT,
    CMD_GET_STREAMLIGHT, CMD_GET_PRESET, CMD_GET_ALL, CMD_GET_UI,
    CMD_GET_LOGO, CMD_GET_VOL, CMD_GET_TREAD,
    CMD_LOGO_START, CMD_LOGO_START_BIN, CMD_LOGO_DATA, CMD_LOGO_END, CMD_LOGO_DELETE,
    CMD_UNKNOWN
} cmd_type_t;

/* 解析后的命令消息 */
typedef struct {
    cmd_type_t type;
    int32_t   params[4];    /* 最多4个整型参数 */
    char      str_param[64]; /* 字符串参数(WiFi SSID/password等) */
} cmd_msg_t;

/* 解析一行协议文本 */
cmd_msg_t proto_parse(const char *line);

/* 获取当前命令队列句柄 */
void *proto_get_cmd_queue(void);
