# ═══════════════════════════════════════════════════════════════
# STEER: ui demo branch | scope=firmware
# 职责: LVGL UI demo 最小构建 — 只保留 LCD/编码器 HAL + LVGL UI
# ═══════════════════════════════════════════════════════════════
idf_component_register(
    SRCS
        "main.c"
        "core/hal/hal_lcd.c"
        "core/hal/hal_encoder.c"
        "ui/ui_port.c"
        "ui/ui_demo.c"
    INCLUDE_DIRS "."
    REQUIRES
        nvs_flash
        esp_driver_gpio
        esp_driver_spi
        esp_driver_pcnt
        esp_timer
        lvgl
)
