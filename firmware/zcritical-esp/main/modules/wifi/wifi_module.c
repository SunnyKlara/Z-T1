/* ═══════════════════════════════════════════════════════════════
 * STEER: 反臃肿 | scope=firmware | modules/wifi/
 *
 * 职责: WiFi 模块骨架
 * ═══════════════════════════════════════════════════════════════ */

#include "wifi_module.h"
#include "esp_log.h"

static const char *TAG = "WIFI";

void wifi_module_init(void) {
    ESP_LOGI(TAG, "WiFi module initialized (skeleton)");
}

void wifi_module_connect(int32_t ssid_hash, const char *password) {
    (void)ssid_hash; (void)password;
    ESP_LOGI(TAG, "WiFi connect (skeleton)");
}
