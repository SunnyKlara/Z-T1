/* ═══════════════════════════════════════════════════════════════
 * STEER: 反臃肿 | max_lines=50 | scope=firmware | 修改前读 anti-bloat.md
 *
 * 职责: 加湿器 GPIO 开关驱动 — 初始化 IO10 为输出 + 开/关/读取
 * 不做什么: 不处理业务逻辑（油门模式由 modules/ 负责）
 *
 * 硬件 (唯一真值源: steering/specs/hardware-config.md):
 *   GPIO IO10 → MOS管 CH1 → 超声波雾化片
 * ═══════════════════════════════════════════════════════════════ */

#include "hal_gpio.h"
#include "driver/gpio.h"
#include "esp_log.h"

static const char *TAG = "hal_gpio";

#define PIN_HUMIDIFIER  GPIO_NUM_10

static bool s_state = false;

void hal_gpio_init(void)
{
    gpio_config_t cfg = {
        .pin_bit_mask = (1ULL << PIN_HUMIDIFIER),
        .mode         = GPIO_MODE_OUTPUT,
        .pull_up_en   = GPIO_PULLUP_DISABLE,
        .pull_down_en = GPIO_PULLDOWN_DISABLE,
        .intr_type    = GPIO_INTR_DISABLE,
    };
    gpio_config(&cfg);
    gpio_set_level(PIN_HUMIDIFIER, 0);
    s_state = false;
    ESP_LOGI(TAG, "Humidifier GPIO init: IO%d", PIN_HUMIDIFIER);
}

void hal_gpio_set(bool on)
{
    s_state = on;
    gpio_set_level(PIN_HUMIDIFIER, on ? 1 : 0);
}

bool hal_gpio_get(void)
{
    return s_state;
}
