/* ═══════════════════════════════════════════════════════════════
 * STEER: 反臃肿 | max_lines=60 | scope=firmware | 修改前读 anti-bloat.md
 *
 * 职责: 风扇 LEDC PWM 驱动 — 初始化 IO40 PWM + 设置占空比(0-100%) + 读取
 * 不做什么: 不处理速度映射（kmh↔% 由 modules/ 负责）
 *
 * 硬件 (唯一真值源: steering/specs/hardware-config.md):
 *   GPIO IO40 → MOS管 CH2 → 风扇 PWM 调速
 *   频率 1000Hz, 分辨率 10-bit (0-1023)
 * ═══════════════════════════════════════════════════════════════ */

#include "hal_pwm.h"
#include "driver/ledc.h"
#include "esp_log.h"

static const char *TAG = "hal_pwm";

#define PIN_FAN              GPIO_NUM_40
#define FAN_PWM_FREQ_HZ      1000
#define FAN_LEDC_TIMER       LEDC_TIMER_0
#define FAN_LEDC_CHANNEL     LEDC_CHANNEL_0
#define FAN_LEDC_RESOLUTION  LEDC_TIMER_10_BIT

static uint8_t s_duty = 0;

void hal_pwm_init(void)
{
    ledc_timer_config_t timer = {
        .speed_mode      = LEDC_LOW_SPEED_MODE,
        .timer_num       = FAN_LEDC_TIMER,
        .duty_resolution = FAN_LEDC_RESOLUTION,
        .freq_hz         = FAN_PWM_FREQ_HZ,
        .clk_cfg         = LEDC_AUTO_CLK,
    };
    ESP_ERROR_CHECK(ledc_timer_config(&timer));

    ledc_channel_config_t ch = {
        .speed_mode = LEDC_LOW_SPEED_MODE,
        .channel    = FAN_LEDC_CHANNEL,
        .timer_sel  = FAN_LEDC_TIMER,
        .gpio_num   = PIN_FAN,
        .duty       = 0,
        .hpoint     = 0,
    };
    ESP_ERROR_CHECK(ledc_channel_config(&ch));
    s_duty = 0;
    ESP_LOGI(TAG, "Fan PWM init: IO%d, %dHz, 10-bit", PIN_FAN, FAN_PWM_FREQ_HZ);
}

void hal_pwm_set_duty(uint8_t percent)
{
    if (percent > 100) percent = 100;
    s_duty = percent;
    uint32_t max_duty = (1 << FAN_LEDC_RESOLUTION) - 1;
    uint32_t duty_val = (uint32_t)percent * max_duty / 100;
    ledc_set_duty(LEDC_LOW_SPEED_MODE, FAN_LEDC_CHANNEL, duty_val);
    ledc_update_duty(LEDC_LOW_SPEED_MODE, FAN_LEDC_CHANNEL);
}

uint8_t hal_pwm_get_duty(void)
{
    return s_duty;
}
