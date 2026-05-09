/* ═══════════════════════════════════════════════════════════════
 * STEER: 反臃肿 | max_lines=300 | scope=firmware | 修改前读 anti-bloat.md
 *
 * 职责: EC11 编码器驱动 — PCNT 旋转解码 + GPIO 按键状态机
 * 不做什么: 不含事件分发、不含 UI 导航、不含菜单逻辑
 *
 * ⚠️ 白板重建 — 不从 reference/ridewind-esp 搬运代码
 * ═══════════════════════════════════════════════════════════════ */

#include "hal_encoder.h"
#include "driver/pulse_cnt.h"
#include "driver/gpio.h"
#include "esp_log.h"
#include "esp_timer.h"

static const char *TAG = "HAL_ENC";

#define PIN_ENC_A           GPIO_NUM_17
#define PIN_ENC_B           GPIO_NUM_18
#define PIN_ENC_KEY         GPIO_NUM_8
#define BTN_LONG_PRESS_MS   800
#define BTN_TIMEOUT_MS      400

static pcnt_unit_handle_t s_pcnt_unit = NULL;
static int s_last_count = 0;

static bool     s_btn_prev         = false;
static uint32_t s_btn_press_tick   = 0;
static uint32_t s_btn_release_tick = 0;
static uint8_t  s_btn_click_cnt    = 0;
static bool     s_btn_long_fired   = false;

static hal_encoder_event_t s_pending;
static bool s_has_pending = false;

static uint32_t now_ms(void)
{
    return (uint32_t)(esp_timer_get_time() / 1000);
}

static void btn_process_edge(bool pressed)
{
    uint32_t now = now_ms();

    if (pressed) {
        s_btn_press_tick = now;
        s_btn_long_fired = false;
        s_btn_prev       = true;

        if (!s_has_pending) {
            s_pending.type  = HAL_ENC_EVT_PRESS;
            s_pending.delta = 0;
            s_has_pending   = true;
        }
    } else {
        s_btn_prev         = false;
        s_btn_release_tick = now;
        s_btn_click_cnt++;

        if (!s_has_pending) {
            s_pending.type  = HAL_ENC_EVT_RELEASE;
            s_pending.delta = 0;
            s_has_pending   = true;
        }
    }
}

static void btn_check_timeout(void)
{
    if (s_btn_click_cnt == 0) return;

    uint32_t now = now_ms();

    if (s_btn_prev && !s_btn_long_fired) {
        if (now - s_btn_press_tick >= BTN_LONG_PRESS_MS) {
            s_btn_long_fired = true;
            s_pending.type   = HAL_ENC_EVT_LONG_PRESS;
            s_pending.delta  = 0;
            s_has_pending    = true;
            s_btn_click_cnt  = 0;
            return;
        }
    }

    if (!s_btn_prev && (now - s_btn_release_tick >= BTN_TIMEOUT_MS)) {
        if (!s_has_pending) {
            switch (s_btn_click_cnt) {
            case 1:  s_pending.type = HAL_ENC_EVT_CLICK; break;
            case 2:  s_pending.type = HAL_ENC_EVT_DOUBLE_CLICK; break;
            default: s_pending.type = HAL_ENC_EVT_TRIPLE_CLICK; break;
            }
            s_pending.delta = 0;
            s_has_pending   = true;
        }
        s_btn_click_cnt = 0;
    }
}

esp_err_t hal_encoder_init(void)
{
    pcnt_unit_config_t unit_cfg = { .low_limit = -1000, .high_limit = 1000 };
    esp_err_t err = pcnt_new_unit(&unit_cfg, &s_pcnt_unit);
    if (err != ESP_OK) {
        ESP_LOGE(TAG, "PCNT unit create failed: %s", esp_err_to_name(err));
        return err;
    }

    pcnt_glitch_filter_config_t filt = { .max_glitch_ns = 1000 };
    pcnt_unit_set_glitch_filter(s_pcnt_unit, &filt);

    pcnt_chan_config_t cha = { .edge_gpio_num = PIN_ENC_A, .level_gpio_num = PIN_ENC_B };
    pcnt_channel_handle_t chan_a;
    pcnt_new_channel(s_pcnt_unit, &cha, &chan_a);
    pcnt_channel_set_edge_action(chan_a,
        PCNT_CHANNEL_EDGE_ACTION_DECREASE, PCNT_CHANNEL_EDGE_ACTION_INCREASE);
    pcnt_channel_set_level_action(chan_a,
        PCNT_CHANNEL_LEVEL_ACTION_KEEP, PCNT_CHANNEL_LEVEL_ACTION_INVERSE);

    pcnt_chan_config_t chb = { .edge_gpio_num = PIN_ENC_B, .level_gpio_num = PIN_ENC_A };
    pcnt_channel_handle_t chan_b;
    pcnt_new_channel(s_pcnt_unit, &chb, &chan_b);
    pcnt_channel_set_edge_action(chan_b,
        PCNT_CHANNEL_EDGE_ACTION_DECREASE, PCNT_CHANNEL_EDGE_ACTION_INCREASE);
    pcnt_channel_set_level_action(chan_b,
        PCNT_CHANNEL_LEVEL_ACTION_KEEP, PCNT_CHANNEL_LEVEL_ACTION_INVERSE);

    gpio_config_t btn_cfg = {
        .pin_bit_mask = (1ULL << PIN_ENC_KEY),
        .mode         = GPIO_MODE_INPUT,
        .pull_up_en   = GPIO_PULLUP_ENABLE,
        .pull_down_en = GPIO_PULLDOWN_DISABLE,
        .intr_type    = GPIO_INTR_DISABLE,
    };
    gpio_config(&btn_cfg);

    pcnt_unit_enable(s_pcnt_unit);
    pcnt_unit_clear_count(s_pcnt_unit);
    pcnt_unit_start(s_pcnt_unit);

    s_last_count     = 0;
    s_btn_prev       = (gpio_get_level(PIN_ENC_KEY) == 0);
    s_btn_click_cnt  = 0;
    s_has_pending    = false;

    ESP_LOGI(TAG, "Encoder init OK: A=IO%d, B=IO%d, KEY=IO%d", PIN_ENC_A, PIN_ENC_B, PIN_ENC_KEY);
    return ESP_OK;
}

bool hal_encoder_poll(hal_encoder_event_t *evt)
{
    if (!evt) return false;

    int cur_count = 0;
    pcnt_unit_get_count(s_pcnt_unit, &cur_count);
    int raw_delta = cur_count - s_last_count;
    s_last_count = cur_count;

    if (raw_delta != 0 && !s_has_pending) {
        int16_t delta = (int16_t)(raw_delta / 2);
        if (delta >  3) delta =  3;
        if (delta < -3) delta = -3;
        s_pending.type  = HAL_ENC_EVT_ROTATE;
        s_pending.delta = delta;
        s_has_pending   = true;
    }

    bool btn_now = (gpio_get_level(PIN_ENC_KEY) == 0);
    if (btn_now != s_btn_prev) {
        btn_process_edge(btn_now);
    }
    btn_check_timeout();

    if (s_has_pending) {
        *evt         = s_pending;
        s_has_pending = false;
        return (evt->type != HAL_ENC_EVT_NONE);
    }

    evt->type  = HAL_ENC_EVT_NONE;
    evt->delta = 0;
    return false;
}

bool hal_encoder_button_pressed(void)
{
    return (gpio_get_level(PIN_ENC_KEY) == 0);
}
