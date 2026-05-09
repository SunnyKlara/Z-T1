# ═══════════════════════════════════════════════════════════════
# STEER: 反臃肿 | max_lines=30 | scope=firmware | 修改前读 anti-bloat.md
#
# 职责: 主组件构建配置 — 注册源文件 + HAL 驱动 + led_strip 依赖
# ═══════════════════════════════════════════════════════════════
idf_component_register(
    SRCS "main.c"
         "core/hal/hal_gpio.c"
         "core/hal/hal_pwm.c"
         "core/hal/hal_led.c"
         "core/hal/hal_lcd.c"
         "core/hal/hal_encoder.c"
         "core/hal/hal_audio.c"
    INCLUDE_DIRS "." "core/hal"
    REQUIRES nvs_flash driver esp_timer led_strip
)
