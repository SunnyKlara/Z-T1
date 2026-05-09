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
#include "esp_err.h"
#include "nvs_flash.h"

#include "hal_gpio.h"
#include "hal_pwm.h"
#include "hal_led.h"
#include "hal_lcd.h"
#include "hal_encoder.h"
#include "hal_audio.h"

static const char *TAG = "ZCRITICAL";

void app_main(void)
{
    /* NVS 初始化 */
    esp_err_t ret = nvs_flash_init();
    if (ret == ESP_ERR_NVS_NO_FREE_PAGES ||
        ret == ESP_ERR_NVS_NEW_VERSION_FOUND) {
        nvs_flash_erase();
        nvs_flash_init();
    }

    ESP_LOGI(TAG, "ZCritical ESP32-S3 started");

    /* ── B1: HAL 层初始化 ── */

    ret = hal_gpio_init();
    if (ret != ESP_OK) ESP_LOGE(TAG, "hal_gpio_init failed!");

    ret = hal_pwm_init();
    if (ret != ESP_OK) ESP_LOGE(TAG, "hal_pwm_init failed!");

    ret = hal_led_init();
    if (ret != ESP_OK) ESP_LOGE(TAG, "hal_led_init failed!");

    ret = hal_lcd_init();
    if (ret != ESP_OK) ESP_LOGE(TAG, "hal_lcd_init failed!");

    ret = hal_encoder_init();
    if (ret != ESP_OK) ESP_LOGE(TAG, "hal_encoder_init failed!");

    ret = hal_audio_init();
    if (ret != ESP_OK) ESP_LOGE(TAG, "hal_audio_init failed!");

    ESP_LOGI(TAG, "HAL init complete");

    /* ── B1 验证: LCD 清黑屏 + LED 红灯测试 ── */
    hal_lcd_clear(0x0000);

    hal_led_set_strip(HAL_LED_STRIP_MAIN, 255, 0, 0);
    hal_led_set_strip(HAL_LED_STRIP_TAIL, 255, 0, 0);
    hal_led_refresh();

    ESP_LOGI(TAG, "Ready. All HAL drivers initialized.");

    // TODO B2: 初始化状态 + 协议 + BLE

    /* 主循环 */
    while (1) {
        vTaskDelay(pdMS_TO_TICKS(1000));
    }
}
