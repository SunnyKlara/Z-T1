/* ═══════════════════════════════════════════════════════════════
 * STEER: ui demo branch | scope=firmware
 *
 * 职责: LVGL UI demo 启动入口
 *   - 只初始化 LCD + 编码器 + LVGL
 *   - 不启动 BLE/风扇/LED 等外设（单纯评估 UI 效果）
 * ═══════════════════════════════════════════════════════════════ */

#include <stdio.h>
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "esp_log.h"
#include "nvs_flash.h"

#include "core/hal/hal_lcd.h"
#include "core/hal/hal_encoder.h"
#include "ui/ui_port.h"

static const char *TAG = "MAIN";

void app_main(void)
{
    esp_err_t ret = nvs_flash_init();
    if (ret == ESP_ERR_NVS_NO_FREE_PAGES || ret == ESP_ERR_NVS_NEW_VERSION_FOUND) {
        ESP_ERROR_CHECK(nvs_flash_erase());
        ret = nvs_flash_init();
    }
    ESP_ERROR_CHECK(ret);

    ESP_LOGI(TAG, "╔══════════════════════════════╗");
    ESP_LOGI(TAG, "║  ZCritical T1 — LVGL Demo    ║");
    ESP_LOGI(TAG, "╚══════════════════════════════╝");

    /* 硬件：仅 LCD + 编码器 */
    hal_lcd_init();
    hal_encoder_init();

    /* 启动 LVGL 与 demo */
    ui_port_init();

    ESP_LOGI(TAG, "LVGL demo running. Rotate encoder to change, click to next screen.");

    while (1) {
        vTaskDelay(pdMS_TO_TICKS(1000));
    }
}
