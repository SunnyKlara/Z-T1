/* ═══════════════════════════════════════════════════════════════
 * STEER: 反臃肿 | scope=firmware | modules/wifi/
 *
 * 职责: WiFi/TCP 音频流模块骨架
 * 不做什么: 不直接操作音频（通过 modules/audio/）
 * ═══════════════════════════════════════════════════════════════ */

#pragma once
#include <stdint.h>

void wifi_module_init(void);
void wifi_module_connect(int32_t ssid_hash, const char *password);
