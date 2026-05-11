/* ═══════════════════════════════════════════════════════════════
 * STEER: 反臃肿 | scope=firmware | modules/logo/
 *
 * 职责: Logo 上传+存储模块骨架
 * 不做什么: 不直接操作 Flash（通过 LittleFS）
 * ═══════════════════════════════════════════════════════════════ */

#pragma once
#include <stdint.h>

void logo_module_init(void);
