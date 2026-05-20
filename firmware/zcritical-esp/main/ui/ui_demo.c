/* ═══════════════════════════════════════════════════════════════
 * STEER: ui demo branch | scope=firmware/ui
 *
 * 职责: LVGL demo — 3 屏展示视觉能力，用于判断是否采用 LVGL
 *
 * Screen 1 Gauge:  圆弧仪表 + 大数字 + 旋转改值平滑动画
 * Screen 2 Menu:   7 项菜单 + 滑动切换 + 焦点放大
 * Screen 3 Color:  RGB 三色条 + 渐变背景
 * ═══════════════════════════════════════════════════════════════ */

#include "ui_demo.h"
#include "lvgl.h"
#include "esp_log.h"
#include <stdio.h>

static const char *TAG = "UI_DEMO";

/* ── 颜色主题 ─────────────────────────────────────────────────── */
#define COLOR_BG       lv_color_hex(0x0A0E1A)   /* 深蓝黑 */
#define COLOR_ACCENT   lv_color_hex(0x00D68F)   /* 主色绿 */
#define COLOR_TEXT     lv_color_hex(0xFFFFFF)
#define COLOR_DIM      lv_color_hex(0x6B7280)
#define COLOR_SURFACE  lv_color_hex(0x1F2937)

/* ── 三个屏幕指针 ─────────────────────────────────────────────── */
static lv_obj_t *s_scr_gauge;
static lv_obj_t *s_scr_menu;
static lv_obj_t *s_scr_color;
static uint8_t   s_cur = 0;  /* 0=gauge, 1=menu, 2=color */

/* Gauge 屏的控件引用 */
static lv_obj_t *s_arc;
static lv_obj_t *s_label_value;
static int32_t   s_speed_val = 0;

/* ═══════════════════════════════════════════════════════════════
 *  Screen 1 — Speed Gauge
 * ═══════════════════════════════════════════════════════════════ */
static void arc_anim_cb(void *var, int32_t v)
{
    lv_arc_set_value((lv_obj_t *)var, v);
    char buf[8];
    snprintf(buf, sizeof(buf), "%d", (int)v);
    lv_label_set_text(s_label_value, buf);
}

static void gauge_event_cb(lv_event_t *e)
{
    if (lv_event_get_code(e) != LV_EVENT_KEY) return;
    uint32_t key = lv_indev_get_key(lv_indev_active());
    int32_t target = s_speed_val;
    if (key == LV_KEY_RIGHT)      target += 5;
    else if (key == LV_KEY_LEFT)  target -= 5;
    else return;

    if (target < 0)   target = 0;
    if (target > 100) target = 100;
    s_speed_val = target;

    /* 平滑动画到目标值，250ms ease_out */
    lv_anim_t a;
    lv_anim_init(&a);
    lv_anim_set_var(&a, s_arc);
    lv_anim_set_exec_cb(&a, arc_anim_cb);
    lv_anim_set_values(&a, lv_arc_get_value(s_arc), target);
    lv_anim_set_time(&a, 250);
    lv_anim_set_path_cb(&a, lv_anim_path_ease_out);
    lv_anim_start(&a);
}

static void build_scr_gauge(void)
{
    s_scr_gauge = lv_obj_create(NULL);
    lv_obj_set_style_bg_color(s_scr_gauge, COLOR_BG, 0);
    lv_obj_set_style_bg_opa(s_scr_gauge, LV_OPA_COVER, 0);
    lv_obj_remove_style(s_scr_gauge, NULL, LV_PART_SCROLLBAR);

    /* 主圆弧仪表 220×220 */
    s_arc = lv_arc_create(s_scr_gauge);
    lv_obj_set_size(s_arc, 220, 220);
    lv_obj_center(s_arc);
    lv_arc_set_rotation(s_arc, 135);
    lv_arc_set_bg_angles(s_arc, 0, 270);
    lv_arc_set_range(s_arc, 0, 100);
    lv_arc_set_value(s_arc, 0);
    lv_obj_remove_style(s_arc, NULL, LV_PART_KNOB);
    lv_obj_set_style_arc_width(s_arc, 14, LV_PART_MAIN);
    lv_obj_set_style_arc_width(s_arc, 14, LV_PART_INDICATOR);
    lv_obj_set_style_arc_color(s_arc, COLOR_SURFACE, LV_PART_MAIN);
    lv_obj_set_style_arc_color(s_arc, COLOR_ACCENT, LV_PART_INDICATOR);

    /* 中心大数字 48px */
    s_label_value = lv_label_create(s_scr_gauge);
    lv_label_set_text(s_label_value, "0");
    lv_obj_set_style_text_color(s_label_value, COLOR_TEXT, 0);
    lv_obj_set_style_text_font(s_label_value, &lv_font_montserrat_48, 0);
    lv_obj_align(s_label_value, LV_ALIGN_CENTER, 0, -10);

    /* 单位 */
    lv_obj_t *unit = lv_label_create(s_scr_gauge);
    lv_label_set_text(unit, "% SPEED");
    lv_obj_set_style_text_color(unit, COLOR_DIM, 0);
    lv_obj_set_style_text_font(unit, &lv_font_montserrat_14, 0);
    lv_obj_align(unit, LV_ALIGN_CENTER, 0, 30);

    /* 顶部标题 */
    lv_obj_t *title = lv_label_create(s_scr_gauge);
    lv_label_set_text(title, "ZCRITICAL  T1");
    lv_obj_set_style_text_color(title, COLOR_ACCENT, 0);
    lv_obj_set_style_text_font(title, &lv_font_montserrat_14, 0);
    lv_obj_align(title, LV_ALIGN_TOP_MID, 0, 16);

    /* 底部提示 */
    lv_obj_t *hint = lv_label_create(s_scr_gauge);
    lv_label_set_text(hint, "rotate to change");
    lv_obj_set_style_text_color(hint, COLOR_DIM, 0);
    lv_obj_set_style_text_font(hint, &lv_font_montserrat_14, 0);
    lv_obj_align(hint, LV_ALIGN_BOTTOM_MID, 0, -16);

    /* 焦点 → arc 接收编码器旋转 */
    lv_group_add_obj(lv_group_get_default(), s_arc);
    lv_obj_add_event_cb(s_arc, gauge_event_cb, LV_EVENT_KEY, NULL);
}

/* ═══════════════════════════════════════════════════════════════
 *  Screen 2 — Menu (7 项垂直滚动)
 * ═══════════════════════════════════════════════════════════════ */
static const char *MENU_ITEMS[] = {
    "SPEED", "COLOR", "RGB", "BRIGHT", "LOGO", "VOLUME", "ABOUT"
};
#define MENU_COUNT 7

static void build_scr_menu(void)
{
    s_scr_menu = lv_obj_create(NULL);
    lv_obj_set_style_bg_color(s_scr_menu, COLOR_BG, 0);
    lv_obj_set_style_bg_opa(s_scr_menu, LV_OPA_COVER, 0);
    lv_obj_remove_style(s_scr_menu, NULL, LV_PART_SCROLLBAR);

    /* 标题 */
    lv_obj_t *title = lv_label_create(s_scr_menu);
    lv_label_set_text(title, "MENU");
    lv_obj_set_style_text_color(title, COLOR_ACCENT, 0);
    lv_obj_set_style_text_font(title, &lv_font_montserrat_20, 0);
    lv_obj_align(title, LV_ALIGN_TOP_MID, 0, 18);

    /* 列表容器 */
    lv_obj_t *list = lv_obj_create(s_scr_menu);
    lv_obj_set_size(list, 220, 160);
    lv_obj_align(list, LV_ALIGN_CENTER, 0, 15);
    lv_obj_set_flex_flow(list, LV_FLEX_FLOW_COLUMN);
    lv_obj_set_flex_align(list, LV_FLEX_ALIGN_CENTER, LV_FLEX_ALIGN_CENTER, LV_FLEX_ALIGN_CENTER);
    lv_obj_set_style_bg_opa(list, LV_OPA_TRANSP, 0);
    lv_obj_set_style_border_width(list, 0, 0);
    lv_obj_set_style_pad_all(list, 4, 0);
    lv_obj_set_style_pad_row(list, 6, 0);
    lv_obj_set_scroll_snap_y(list, LV_SCROLL_SNAP_CENTER);
    lv_obj_remove_style(list, NULL, LV_PART_SCROLLBAR);

    /* 创建 7 个按钮 */
    for (int i = 0; i < MENU_COUNT; i++) {
        lv_obj_t *btn = lv_btn_create(list);
        lv_obj_set_size(btn, 180, 40);
        lv_obj_set_style_bg_color(btn, COLOR_SURFACE, LV_STATE_DEFAULT);
        lv_obj_set_style_bg_color(btn, COLOR_ACCENT, LV_STATE_FOCUSED);
        lv_obj_set_style_radius(btn, 20, 0);
        lv_obj_set_style_shadow_width(btn, 0, 0);
        lv_obj_set_style_border_width(btn, 0, 0);

        lv_obj_t *lab = lv_label_create(btn);
        lv_label_set_text(lab, MENU_ITEMS[i]);
        lv_obj_set_style_text_color(lab, COLOR_TEXT, 0);
        lv_obj_set_style_text_font(lab, &lv_font_montserrat_20, 0);
        lv_obj_center(lab);

        lv_group_add_obj(lv_group_get_default(), btn);
    }
}

/* ═══════════════════════════════════════════════════════════════
 *  Screen 3 — Color (渐变 + RGB 滑块)
 * ═══════════════════════════════════════════════════════════════ */
static void build_scr_color(void)
{
    s_scr_color = lv_obj_create(NULL);
    lv_obj_set_style_bg_color(s_scr_color, COLOR_BG, 0);
    lv_obj_set_style_bg_opa(s_scr_color, LV_OPA_COVER, 0);
    lv_obj_remove_style(s_scr_color, NULL, LV_PART_SCROLLBAR);

    lv_obj_t *title = lv_label_create(s_scr_color);
    lv_label_set_text(title, "RGB GRADIENT");
    lv_obj_set_style_text_color(title, COLOR_ACCENT, 0);
    lv_obj_set_style_text_font(title, &lv_font_montserrat_14, 0);
    lv_obj_align(title, LV_ALIGN_TOP_MID, 0, 20);

    /* 中央圆形渐变示例 */
    lv_obj_t *ring = lv_arc_create(s_scr_color);
    lv_obj_set_size(ring, 180, 180);
    lv_obj_center(ring);
    lv_arc_set_bg_angles(ring, 0, 360);
    lv_arc_set_value(ring, 100);
    lv_arc_set_range(ring, 0, 100);
    lv_obj_remove_style(ring, NULL, LV_PART_KNOB);
    lv_obj_set_style_arc_width(ring, 30, LV_PART_INDICATOR);
    lv_obj_set_style_arc_width(ring, 30, LV_PART_MAIN);
    lv_obj_set_style_arc_color(ring, lv_color_hex(0xF59E0B), LV_PART_INDICATOR);
    lv_obj_set_style_arc_color(ring, lv_color_hex(0x1F2937), LV_PART_MAIN);

    /* 中央渐变圆 (R/G/B 三色块叠加示意) */
    static const uint32_t bar_colors[3] = {0xEF4444, 0x10B981, 0x3B82F6};
    static const char *bar_labels[3] = {"R", "G", "B"};
    for (int i = 0; i < 3; i++) {
        lv_obj_t *dot = lv_obj_create(s_scr_color);
        lv_obj_set_size(dot, 24, 24);
        lv_obj_align(dot, LV_ALIGN_CENTER, (i - 1) * 36, 0);
        lv_obj_set_style_radius(dot, LV_RADIUS_CIRCLE, 0);
        lv_obj_set_style_bg_color(dot, lv_color_hex(bar_colors[i]), 0);
        lv_obj_set_style_border_width(dot, 0, 0);
        lv_obj_set_style_shadow_color(dot, lv_color_hex(bar_colors[i]), 0);
        lv_obj_set_style_shadow_width(dot, 24, 0);
        lv_obj_set_style_shadow_opa(dot, LV_OPA_60, 0);

        lv_obj_t *lab = lv_label_create(dot);
        lv_label_set_text(lab, bar_labels[i]);
        lv_obj_set_style_text_color(lab, COLOR_TEXT, 0);
        lv_obj_center(lab);
    }

    lv_obj_t *hint = lv_label_create(s_scr_color);
    lv_label_set_text(hint, "click to next");
    lv_obj_set_style_text_color(hint, COLOR_DIM, 0);
    lv_obj_set_style_text_font(hint, &lv_font_montserrat_14, 0);
    lv_obj_align(hint, LV_ALIGN_BOTTOM_MID, 0, -16);
}

/* ═══════════════════════════════════════════════════════════════
 *  公共 API
 * ═══════════════════════════════════════════════════════════════ */
void ui_demo_create(void)
{
    ESP_LOGI(TAG, "Build UI demo");
    build_scr_gauge();
    build_scr_menu();
    build_scr_color();
    /* 第一屏：仪表盘，淡入 */
    lv_screen_load_anim(s_scr_gauge, LV_SCR_LOAD_ANIM_FADE_IN, 400, 0, false);
    s_cur = 0;
}

void ui_demo_on_click(void)
{
    static uint32_t last_tick = 0;
    uint32_t now = lv_tick_get();
    /* 防抖：200ms 内重复点击忽略 */
    if (now - last_tick < 200) return;
    last_tick = now;

    s_cur = (s_cur + 1) % 3;
    lv_obj_t *target = (s_cur == 0) ? s_scr_gauge
                     : (s_cur == 1) ? s_scr_menu
                     : s_scr_color;
    /* 不同切换效果展示 LVGL 多种动画 */
    lv_scr_load_anim_t a = (s_cur == 1) ? LV_SCR_LOAD_ANIM_OVER_LEFT
                          : (s_cur == 2) ? LV_SCR_LOAD_ANIM_OVER_LEFT
                                         : LV_SCR_LOAD_ANIM_OVER_LEFT;
    lv_screen_load_anim(target, a, 350, 0, false);
    ESP_LOGI(TAG, "→ screen %d", s_cur);
}
