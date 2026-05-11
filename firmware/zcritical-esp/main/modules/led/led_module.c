/* ═══════════════════════════════════════════════════════════════
 * STEER: 反臃肿 | scope=firmware | modules/led/
 *
 * 职责: LED 控制 — 1-14种预设、单色设置、亮度、特效
 *
 * 14种预设RGB值 (唯一真值源: steering/specs/protocol-contract.md §四/八)
 * ═══════════════════════════════════════════════════════════════ */

#include "led_module.h"
#include "core/hal/hal_led.h"
#include "core/state/app_state.h"
#include "esp_log.h"

static const char *TAG = "LED";

/* 14种预设: [strip 0=Main, 1=Tail][R, G, B] */
static const uint8_t s_presets[14][2][3] = {
    {{255,0,0},     {255,0,0}},      /* 1  Flame Red */
    {{0,255,0},     {0,255,0}},      /* 2  Neon Green */
    {{0,0,255},     {0,0,255}},      /* 3  Deep Blue */
    {{255,105,180}, {255,20,147}},   /* 4  Sakura Pink */
    {{255,215,0},   {255,140,0}},    /* 5  Golden Hour */
    {{0,255,128},   {0,206,209}},    /* 6  Mint Fresh */
    {{138,43,226},  {147,112,219}},  /* 7  Lavender */
    {{220,20,60},   {178,34,34}},    /* 8  Crimson */
    {{0,64,255},    {0,191,255}},    /* 9  Ocean Blue */
    {{128,255,0},   {50,205,50}},    /* 10 Lime */
    {{255,0,0},     {0,0,255}},      /* 11 Police Flash */
    {{255,69,0},    {255,140,0}},    /* 12 Sunset Glow */
    {{128,0,128},   {186,85,211}},   /* 13 Purple Haze */
    {{255,0,0},     {0,255,0}},      /* 14 Rainbow (简化为红绿交替) */
};

void led_module_init(void) {
    ESP_LOGI(TAG, "LED module initialized (14 presets)");
}

void led_module_set_strip(uint8_t strip, uint8_t r, uint8_t g, uint8_t b) {
    if (strip > 1) return;
    hal_led_set_strip(strip, r, g, b);
    APP_STATE_LOCK();
    g_app_state.led.colors[strip][0] = r;
    g_app_state.led.colors[strip][1] = g;
    g_app_state.led.colors[strip][2] = b;
    APP_STATE_UNLOCK();
}

void led_module_preset(uint8_t preset) {
    if (preset < 1 || preset > 14) return;
    uint8_t idx = preset - 1;
    led_module_set_strip(0, s_presets[idx][0][0], s_presets[idx][0][1], s_presets[idx][0][2]);
    led_module_set_strip(1, s_presets[idx][1][0], s_presets[idx][1][1], s_presets[idx][1][2]);
    APP_STATE_LOCK();
    g_app_state.led.preset = preset;
    APP_STATE_UNLOCK();
    ESP_LOGI(TAG, "Preset %d applied", preset);
}

void led_module_brightness(uint8_t pct) {
    if (pct > 100) pct = 100;
    hal_led_set_brightness(pct);
    APP_STATE_LOCK();
    g_app_state.led.brightness = pct;
    APP_STATE_UNLOCK();
}

void led_module_streamlight(uint8_t on) {
    APP_STATE_LOCK();
    g_app_state.led.streamlight = on;
    APP_STATE_UNLOCK();
    /* TODO: 流水灯特效 — 在 led_module_task 中实现 */
}

void led_module_gradient(uint8_t strip, uint8_t r, uint8_t g, uint8_t b, uint8_t speed) {
    if (strip > 1) return;
    led_module_set_strip(strip, r, g, b);
    APP_STATE_LOCK();
    g_app_state.led.gradient_speed = speed;
    APP_STATE_UNLOCK();
    /* TODO: 渐变过渡 — 在 led_module_task 中实现平滑过渡 */
}

void led_module_task(void) {
    /* TODO: 后台更新流水灯/渐变/彩虹特效 */
}
