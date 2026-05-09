/* ═══════════════════════════════════════════════════════════════
 * STEER: 反臃肿 | max_lines=300 | scope=firmware | 修改前读 anti-bloat.md
 *
 * 职责: GPIO 驱动 — 加湿器 MOS 管开关 (IO10)
 * 不做什么: 不含双掷逻辑、不含状态机、不含加湿器业务规则
 *
 * ⚠️ 白板重建 — 不从 reference/ridewind-esp 搬运代码
 * ═══════════════════════════════════════════════════════════════ */

#include "hal_gpio.h"
#include "driver/gpio.h"
#include "esp_log.h"

static const char *TAG = "HAL_GPIO";

#define PIN_HUMIDIFIER  GPIO_NUM_10

static bool s_humidifier = false;

esp_err_t hal_gpio_init(void)
{
    gpio_config_t cfg = {
        .pin_bit_mask = (1ULL << PIN_HUMIDIFIER),
        .mode         = GPIO_MODE_OUTPUT,
        .pull_up_en   = GPIO_PULLUP_DISABLE,
        .pull_down_en = GPIO_PULLDOWN_DISABLE,
        .intr_type    = GPIO_INTR_DISABLE,
    };
    esp_err_t err = gpio_config(&cfg);
    if (err != ESP_OK) {
        ESP_LOGE(TAG, "GPIO config failed: %s", esp_err_to_name(err));
        return err;
    }

    gpio_set_level(PIN_HUMIDIFIER, 0);
    s_humidifier = false;

    ESP_LOGI(TAG, "Humidifier GPIO init OK: IO%d (CH1 MOS)", PIN_HUMIDIFIER);
    return ESP_OK;
}

void hal_gpio_set_humidifier(bool on)
{
    s_humidifier = on;
    gpio_set_level(PIN_HUMIDIFIER, on ? 1 : 0);
}

bool hal_gpio_get_humidifier(void)
{
    return s_humidifier;
}
