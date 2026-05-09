/* ═══════════════════════════════════════════════════════════════
 * STEER: 反臃肿 | max_lines=300 | scope=firmware | 修改前读 anti-bloat.md
 *
 * 职责: LEDC PWM 驱动 — 风扇 MOS 管调速 (IO40, CH2)
 * 不做什么: 不含速度映射、不含油门逻辑、不含风扇状态管理
 *
 * ⚠️ 白板重建 — 不从 reference/ridewind-esp 搬运代码
 * ═══════════════════════════════════════════════════════════════ */

#include "hal_pwm.h"
#include "driver/ledc.h"
#include "esp_log.h"

static const char *TAG = "HAL_PWM";

#define PIN_FAN             GPIO_NUM_40
#define PWM_FREQ_HZ         1000
#define PWM_LEDC_TIMER      LEDC_TIMER_0
#define PWM_LEDC_CHANNEL    LEDC_CHANNEL_0
#define PWM_LEDC_RESOLUTION LEDC_TIMER_10_BIT
#define PWM_MAX_DUTY        1023

static uint8_t s_duty = 0;

esp_err_t hal_pwm_init(void)
{
    ledc_timer_config_t timer = {
        .speed_mode      = LEDC_LOW_SPEED_MODE,
        .timer_num       = PWM_LEDC_TIMER,
        .duty_resolution = PWM_LEDC_RESOLUTION,
        .freq_hz         = PWM_FREQ_HZ,
        .clk_cfg         = LEDC_AUTO_CLK,
    };
    esp_err_t err = ledc_timer_config(&timer);
    if (err != ESP_OK) {
        ESP_LOGE(TAG, "LEDC timer config failed: %s", esp_err_to_name(err));
        return err;
    }

    ledc_channel_config_t ch = {
        .speed_mode = LEDC_LOW_SPEED_MODE,
        .channel    = PWM_LEDC_CHANNEL,
        .timer_sel  = PWM_LEDC_TIMER,
        .gpio_num   = PIN_FAN,
        .duty       = 0,
        .hpoint     = 0,
    };
    err = ledc_channel_config(&ch);
    if (err != ESP_OK) {
        ESP_LOGE(TAG, "LEDC channel config failed: %s", esp_err_to_name(err));
        return err;
    }

    s_duty = 0;
    ESP_LOGI(TAG, "Fan PWM init OK: IO%d, %dHz, %d-bit", PIN_FAN, PWM_FREQ_HZ, PWM_LEDC_RESOLUTION);
    return ESP_OK;
}

void hal_pwm_set_duty(uint8_t percent)
{
    if (percent > 100) percent = 100;
    s_duty = percent;

    uint32_t val = (uint32_t)percent * PWM_MAX_DUTY / 100;
    ledc_set_duty(LEDC_LOW_SPEED_MODE, PWM_LEDC_CHANNEL, val);
    ledc_update_duty(LEDC_LOW_SPEED_MODE, PWM_LEDC_CHANNEL);
}

uint8_t hal_pwm_get_duty(void)
{
    return s_duty;
}
