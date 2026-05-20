/* ═══════════════════════════════════════════════════════════════
 * STEER: ui demo branch | scope=firmware/ui
 *
 * 职责: LVGL 适配层 — display flush + tick + 编码器 indev + LVGL 任务
 * 不做什么: 不画 UI（由 ui_demo.c 负责）
 *
 * 依赖: hal_lcd（SPI 推送）+ hal_encoder（编码器输入）
 * ═══════════════════════════════════════════════════════════════ */

#include "ui_port.h"
#include "ui_demo.h"
#include "core/hal/hal_lcd.h"
#include "core/hal/hal_encoder.h"
#include "lvgl.h"
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "esp_timer.h"
#include "esp_log.h"
#include "esp_heap_caps.h"
#include <string.h>

static const char *TAG = "UI_PORT";

#define LCD_W 240
#define LCD_H 240

/* 双缓冲，每块 1/10 屏幕高 = 24 行 = 11.5KB，留在内部 SRAM 保证 SPI 速度 */
#define DRAW_BUF_LINES   24
#define DRAW_BUF_PIXELS  (LCD_W * DRAW_BUF_LINES)
#define DRAW_BUF_BYTES   (DRAW_BUF_PIXELS * sizeof(lv_color_t))

static lv_display_t *s_disp;
static lv_indev_t   *s_indev;

/* ── LVGL tick — 由 esp_timer 周期回调 ─────────────────────────── */
static void lv_tick_timer_cb(void *arg)
{
    lv_tick_inc(2);
}

/* ── Display flush callback ───────────────────────────────────── */
static void disp_flush_cb(lv_display_t *disp, const lv_area_t *area, uint8_t *px_map)
{
    int32_t w = area->x2 - area->x1 + 1;
    int32_t h = area->y2 - area->y1 + 1;

    /* px_map 已是 RGB565 大端（CONFIG_LV_COLOR_16_SWAP=y） */
    hal_lcd_blit_rgb565(area->x1, area->y1, w, h, (const uint16_t *)px_map);

    lv_display_flush_ready(disp);
}

/* ── 编码器 indev read callback ──────────────────────────────── */
static void encoder_read_cb(lv_indev_t *indev, lv_indev_data_t *data)
{
    static int32_t accumulated_diff = 0;

    hal_encoder_event_t evt;
    while (hal_encoder_poll(&evt)) {
        if (evt.type == HAL_ENC_EVT_ROTATE) {
            accumulated_diff += evt.delta;
        } else if (evt.type == HAL_ENC_EVT_CLICK ||
                   evt.type == HAL_ENC_EVT_PRESS) {
            data->state = LV_INDEV_STATE_PRESSED;
        } else if (evt.type == HAL_ENC_EVT_RELEASE) {
            data->state = LV_INDEV_STATE_RELEASED;
        }
    }

    data->enc_diff = (int16_t)accumulated_diff;
    accumulated_diff = 0;

    /* 通知 demo 有按键事件（用于切换页面） */
    if (data->state == LV_INDEV_STATE_PRESSED) {
        ui_demo_on_click();
    }
}

/* ── LVGL 任务 ────────────────────────────────────────────────── */
static void lvgl_task(void *arg)
{
    while (1) {
        uint32_t delay_ms = lv_timer_handler();
        if (delay_ms > 33) delay_ms = 33;
        if (delay_ms < 5)  delay_ms = 5;
        vTaskDelay(pdMS_TO_TICKS(delay_ms));
    }
}

/* ── 初始化 ──────────────────────────────────────────────────── */
void ui_port_init(void)
{
    ESP_LOGI(TAG, "Init LVGL");

    lv_init();

    /* 1ms tick from esp_timer */
    const esp_timer_create_args_t tick_args = {
        .callback = lv_tick_timer_cb,
        .name = "lv_tick",
    };
    esp_timer_handle_t tick_timer;
    esp_timer_create(&tick_args, &tick_timer);
    esp_timer_start_periodic(tick_timer, 2000);  /* 2ms */

    /* Display */
    s_disp = lv_display_create(LCD_W, LCD_H);
    lv_display_set_flush_cb(s_disp, disp_flush_cb);

    /* Draw buffers — 内部 SRAM 保证速度 */
    static uint8_t buf1[DRAW_BUF_BYTES] __attribute__((aligned(4)));
    static uint8_t buf2[DRAW_BUF_BYTES] __attribute__((aligned(4)));
    lv_display_set_buffers(s_disp, buf1, buf2, sizeof(buf1),
                           LV_DISPLAY_RENDER_MODE_PARTIAL);

    /* Encoder indev */
    s_indev = lv_indev_create();
    lv_indev_set_type(s_indev, LV_INDEV_TYPE_ENCODER);
    lv_indev_set_read_cb(s_indev, encoder_read_cb);

    /* 创建一个 group，让 demo 把控件加入（编码器才能驱动焦点） */
    lv_group_t *group = lv_group_create();
    lv_indev_set_group(s_indev, group);
    lv_group_set_default(group);

    ESP_LOGI(TAG, "LVGL ready, mem free=%d KB",
             (int)(heap_caps_get_free_size(MALLOC_CAP_SPIRAM) / 1024));

    /* 构建 UI */
    ui_demo_create();

    /* 启动 LVGL 调度任务（栈 8KB，优先级中） */
    xTaskCreatePinnedToCore(lvgl_task, "lvgl", 8192, NULL, 4, NULL, 1);
}
