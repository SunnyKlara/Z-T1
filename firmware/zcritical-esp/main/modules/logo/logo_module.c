/* ═══════════════════════════════════════════════════════════════
 * STEER: 反臃肿 | scope=firmware | modules/logo/
 *
 * 职责: Logo模块骨架 — B3 阶段预留
 * ═══════════════════════════════════════════════════════════════ */

#include "logo_module.h"
#include "esp_log.h"

static const char *TAG = "LOGO";

void logo_module_init(void) {
    ESP_LOGI(TAG, "Logo module initialized (skeleton)");
    /* TODO: LittleFS 挂载 + 槽位扫描 + PSRAM 缓冲 */
}
