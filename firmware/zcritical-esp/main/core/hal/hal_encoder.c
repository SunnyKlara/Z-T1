/* ================================================================
 * STEER: anti-bloat | max_lines=160 | scope=firmware | read anti-bloat.md
 *
 * Purpose: EC11 encoder driver ¡ª PCNT hardware decode + GPIO button + event polling
 * Does NOT: handle UI menu navigation (modules/encoder/ does that)
 *
 * Hardware (single source: steering/specs/hardware-config.md):
 *   S1(A)=IO17, S2(B)=IO18, KEY=IO8 (active low, internal pull-up)
 *   Debounce: PCNT hardware 1us glitch filter
 *   Button: 400ms click timeout / 800ms long-press threshold
 * ================================================================ */

#include "hal_encoder.h"
#include "driver/pulse_cnt.h"
#include "driver/gpio.h"
#include "esp_log.h"
#include "esp_timer.h"

static const char *TAG = "hal_enc";

#define PIN_ENC_A    GPIO_NUM_17
#define PIN_ENC_B    GPIO_NUM_18
#define PIN_ENC_KEY  GPIO_NUM_8

#define BUTTON_TIMEOUT_MS  400
#define LONG_PRESS_MS      800

static pcnt_unit_handle_t s_pcnt_unit;
static int s_last_count;

static uint8_t  s_btn_click_count;
static uint32_t s_btn_press_tick;
static uint32_t s_btn_last_click_tick;
static bool     s_btn_prev;
static bool     s_btn_long_fired;

static hal_encoder_event_t s_pending;
static bool s_has_pending;

static uint32_t now_ms(void)
{
    return (uint32_t)(esp_timer_get_time() / 1000);
}

void hal_encoder_init(void)
{
    pcnt_unit_config_t unit_cfg = {
        .low_limit  = -1000,
        .high_limit =  1000,
    };
    ESP_ERROR_CHECK(pcnt_new_unit(&unit_cfg, &s_pcnt_unit));

    pcnt_glitch_filter_config_t filt = { .max_glitch_ns = 1000 };
    ESP_ERROR_CHECK(pcnt_unit_set_glitch_filter(s_pcnt_unit, &filt));

    pcnt_chan_config_t chan_a_cfg = {
        .edge_gpio_num  = PIN_ENC_A,
        .level_gpio_num = PIN_ENC_B,
    };
    pcnt_channel_handle_t chan_a;
    ESP_ERROR_CHECK(pcnt_new_channel(s_pcnt_unit, &chan_a_cfg, &chan_a));
    ESP_ERROR_CHECK(pcnt_channel_set_edge_action(chan_a,
        PCNT_CHANNEL_EDGE_ACTION_DECREASE, PCNT_CHANNEL_EDGE_ACTION_INCREASE));
    ESP_ERROR_CHECK(pcnt_channel_set_level_action(chan_a,
        PCNT_CHANNEL_LEVEL_ACTION_KEEP, PCNT_CHANNEL_LEVEL_ACTION_INVERSE));

    pcnt_chan_config_t chan_b_cfg = {
        .edge_gpio_num  = PIN_ENC_B,
        .level_gpio_num = PIN_ENC_A,
    };
    pcnt_channel_handle_t chan_b;
    ESP_ERROR_CHECK(pcnt_new_channel(s_pcnt_unit, &chan_b_cfg, &chan_b));
    ESP_ERROR_CHECK(pcnt_channel_set_edge_action(chan_b,
        PCNT_CHANNEL_EDGE_ACTION_INCREASE, PCNT_CHANNEL_EDGE_ACTION_DECREASE));
    ESP_ERROR_CHECK(pcnt_channel_set_level_action(chan_b,
        PCNT_CHANNEL_LEVEL_ACTION_KEEP, PCNT_CHANNEL_LEVEL_ACTION_INVERSE));

    ESP_ERROR_CHECK(pcnt_unit_enable(s_pcnt_unit));
    ESP_ERROR_CHECK(pcnt_unit_clear_count(s_pcnt_unit));
    ESP_ERROR_CHECK(pcnt_unit_start(s_pcnt_unit));
    s_last_count = 0;

    gpio_config_t btn_cfg = {
        .pin_bit_mask = (1ULL << PIN_ENC_KEY),
        .mode         = GPIO_MODE_INPUT,
        .pull_up_en   = GPIO_PULLUP_ENABLE,
        .pull_down_en = GPIO_PULLDOWN_DISABLE,
        .intr_type    = GPIO_INTR_DISABLE,
    };
    gpio_config(&btn_cfg);

    s_btn_prev = false;
    s_btn_click_count = 0;
    s_btn_long_fired = false;
    s_has_pending = false;

    ESP_LOGI(TAG, "Encoder init: PCNT(A=%d,B=%d) KEY=%d",
             PIN_ENC_A, PIN_ENC_B, PIN_ENC_KEY);
}

bool hal_encoder_button_pressed(void)
{
    return gpio_get_level(PIN_ENC_KEY) == 0;
}

bool hal_encoder_poll(hal_encoder_event_t *evt)
{
    if (s_has_pending) {
        *evt = s_pending;
        s_has_pending = false;
        return true;
    }

    uint32_t t = now_ms();

    int count;
    pcnt_unit_get_count(s_pcnt_unit, &count);
    int delta = count - s_last_count;

    if (delta != 0) {
        s_last_count = count;
        int16_t steps = (int16_t)(delta / 2);
        if (steps != 0) {
            if (steps > 3) steps = 3;
            if (steps < -3) steps = -3;
            evt->type = HAL_ENC_EVT_ROTATE;
            evt->delta = steps;
            return true;
        }
    }

    bool pressed = hal_encoder_button_pressed();

    if (pressed && !s_btn_prev) {
        s_btn_press_tick = t;
        s_btn_long_fired = false;
        evt->type = HAL_ENC_EVT_PRESS;
        evt->delta = 0;
        s_btn_prev = pressed;
        return true;
    }

    if (!pressed && s_btn_prev) {
        uint32_t duration = t - s_btn_press_tick;
        s_pending.type = HAL_ENC_EVT_RELEASE;
        s_pending.delta = 0;
        s_has_pending = true;

        if (s_btn_long_fired) {
            s_btn_click_count = 0;
            s_btn_long_fired = false;
        } else if (duration < BUTTON_TIMEOUT_MS) {
            s_btn_click_count++;
            s_btn_last_click_tick = t;
        }
        s_btn_prev = pressed;
        evt->type = HAL_ENC_EVT_RELEASE;
        evt->delta = 0;
        return true;
    }

    if (pressed && !s_btn_long_fired && (t - s_btn_press_tick >= LONG_PRESS_MS)) {
        s_btn_long_fired = true;
        s_btn_click_count = 0;
        evt->type = HAL_ENC_EVT_LONG_PRESS;
        evt->delta = 0;
        s_btn_prev = pressed;
        return true;
    }

    if (s_btn_click_count > 0 && (t - s_btn_last_click_tick >= BUTTON_TIMEOUT_MS)) {
        switch (s_btn_click_count) {
        case 1: evt->type = HAL_ENC_EVT_CLICK;        break;
        case 2: evt->type = HAL_ENC_EVT_DOUBLE_CLICK; break;
        default: evt->type = HAL_ENC_EVT_TRIPLE_CLICK; break;
        }
        evt->delta = 0;
        s_btn_click_count = 0;
        s_btn_prev = pressed;
        return true;
    }

    s_btn_prev = pressed;
    evt->type = HAL_ENC_EVT_NONE;
    evt->delta = 0;
    return false;
}
