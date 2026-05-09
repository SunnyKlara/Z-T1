/* ═══════════════════════════════════════════════════════════════
 * STEER: 反臃肿 | max_lines=150 | scope=firmware | 修改前读 anti-bloat.md
 *
 * 职责: ESP32 固件入口 — 硬件初始化 + 主任务创建
 * 不做什么: 不包含命令分发（proto_dispatch.c）、不包含 Logo 上传（modules/logo/）
 *
 * ⚠️ 白板重建 — 不从 reference/ridewind-esp 搬运代码
 * ═══════════════════════════════════════════════════════════════ */

#include <stdio.h>
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "esp_log.h"
#include "nvs_flash.h"

static const char *TAG = "ZCRITICAL";

void app_main(void)
{
    // NVS 初始化
    esp_err_t ret = nvs_flash_init();
    if (ret == ESP_ERR_NVS_NO_FREE_PAGES ||
        ret == ESP_ERR_NVS_NEW_VERSION_FOUND) {
        nvs_flash_erase();
        nvs_flash_init();
    }

    ESP_LOGI(TAG, "ZCritical ESP32-S3 started");

    // TODO B1: 初始化 HAL 层 (LCD / LED / Encoder / Fan / Humidifier / Audio)
    // TODO B2: 初始化状态 + 协议 + BLE

    // 主循环
    while (1) {
        vTaskDelay(pdMS_TO_TICKS(1000));
    }
}
