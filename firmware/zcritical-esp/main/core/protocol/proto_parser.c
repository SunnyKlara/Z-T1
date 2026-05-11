/* ═══════════════════════════════════════════════════════════════
 * STEER: 反臃肿 | scope=firmware | core/protocol/
 *
 * 职责: 文本协议解析 — "KEY:VALUE\n" 行 → cmd_msg_t
 * 不做什么: 不执行命令、不处理 BLE 收发
 *
 * 协议源: steering/specs/protocol-contract.md
 * ═══════════════════════════════════════════════════════════════ */

#include "proto_parser.h"
#include <string.h>
#include <stdlib.h>

/* ── 按命令名匹配 cmd_type ── */
static cmd_type_t match_cmd(const char *key)
{
    if (strcmp(key, "FAN") == 0)            return CMD_FAN;
    if (strcmp(key, "SPEED") == 0)          return CMD_SPEED;
    if (strcmp(key, "WUHUA") == 0)          return CMD_WUHUA;
    if (strcmp(key, "LED") == 0)            return CMD_LED;
    if (strcmp(key, "PRESET") == 0)         return CMD_PRESET;
    if (strcmp(key, "BRIGHT") == 0)         return CMD_BRIGHT;
    if (strcmp(key, "STREAMLIGHT") == 0)    return CMD_STREAMLIGHT;
    if (strcmp(key, "LED_GRADIENT") == 0)   return CMD_LED_GRADIENT;
    if (strcmp(key, "LCD") == 0)            return CMD_LCD;
    if (strcmp(key, "UI") == 0)             return CMD_UI;
    if (strcmp(key, "VOL") == 0)            return CMD_VOL;
    if (strcmp(key, "THROTTLE") == 0)       return CMD_THROTTLE;
    if (strcmp(key, "UNIT") == 0)           return CMD_UNIT;
    if (strcmp(key, "TREAD") == 0)          return CMD_TREAD;
    if (strcmp(key, "WIFI") == 0)           return CMD_WIFI;
    if (strcmp(key, "WIFI_SCAN") == 0)      return CMD_WIFI_SCAN;
    if (strcmp(key, "GET:FAN") == 0)        return CMD_GET_FAN;
    if (strcmp(key, "GET:WUHUA") == 0)      return CMD_GET_WUHUA;
    if (strcmp(key, "GET:BRIGHT") == 0)     return CMD_GET_BRIGHT;
    if (strcmp(key, "GET:STREAMLIGHT") == 0) return CMD_GET_STREAMLIGHT;
    if (strcmp(key, "GET:PRESET") == 0)     return CMD_GET_PRESET;
    if (strcmp(key, "GET:ALL") == 0)        return CMD_GET_ALL;
    if (strcmp(key, "GET:UI") == 0)         return CMD_GET_UI;
    if (strcmp(key, "GET:LOGO") == 0)       return CMD_GET_LOGO;
    if (strcmp(key, "GET:VOL") == 0)        return CMD_GET_VOL;
    if (strcmp(key, "GET:TREAD") == 0)      return CMD_GET_TREAD;
    if (strcmp(key, "LOGO_START") == 0)     return CMD_LOGO_START;
    if (strcmp(key, "LOGO_START_BIN") == 0) return CMD_LOGO_START_BIN;
    if (strcmp(key, "LOGO_DATA") == 0)      return CMD_LOGO_DATA;
    if (strcmp(key, "LOGO_END") == 0)       return CMD_LOGO_END;
    if (strcmp(key, "LOGO_DELETE") == 0)    return CMD_LOGO_DELETE;
    return CMD_UNKNOWN;
}

/* ── 解析参数（:分隔） ── */
static int parse_params(const char *val, int32_t *params, int max_params)
{
    int count = 0;
    char buf[32];
    const char *p = val;
    while (count < max_params && *p) {
        const char *end = strchr(p, ':');
        if (!end) end = p + strlen(p);
        size_t len = (size_t)(end - p);
        if (len > sizeof(buf) - 1) len = sizeof(buf) - 1;
        memcpy(buf, p, len);
        buf[len] = '\0';
        params[count++] = (int32_t)atoi(buf);
        p = (*end == ':') ? end + 1 : end;
    }
    return count;
}

/* ── 公开接口 ── */
cmd_msg_t proto_parse(const char *line)
{
    cmd_msg_t msg = {.type = CMD_UNKNOWN, .params = {0}, .str_param = {0}};

    /* 跳过空白行 */
    if (!line || !*line) return msg;

    /* 分离 KEY 和 VALUE */
    const char *colon = strchr(line, ':');
    if (!colon) return msg;

    /* 提取 KEY */
    char key[32];
    size_t key_len = (size_t)(colon - line);
    if (key_len > sizeof(key) - 1) key_len = sizeof(key) - 1;
    memcpy(key, line, key_len);
    key[key_len] = '\0';

    const char *val = colon + 1;

    msg.type = match_cmd(key);
    if (msg.type == CMD_UNKNOWN) return msg;

    /* 解析参数 */
    switch (msg.type) {
    case CMD_LED:
        /* LED:strip:r:g:b — 4参数 */
        parse_params(val, msg.params, 4);
        break;
    case CMD_LED_GRADIENT:
        /* LED_GRADIENT:strip:r:g:b:speed — 5参数 */
        parse_params(val, msg.params, 5);
        break;
    case CMD_WIFI:
        /* WIFI:ssid:password — 复制原始值 */
        strncpy(msg.str_param, val, sizeof(msg.str_param) - 1);
        break;
    case CMD_LOGO_START:
    case CMD_LOGO_START_BIN:
        /* LOGO_START:s:size:crc — 3参数 */
        parse_params(val, msg.params, 3);
        break;
    case CMD_LOGO_DATA:
        /* LOGO_DATA:seq:hex — 2参数 */
        parse_params(val, msg.params, 2);
        break;
    default:
        /* 一般命令: 1个参数 */
        parse_params(val, msg.params, 1);
        break;
    }
    return msg;
}
