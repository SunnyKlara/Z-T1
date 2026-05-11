# ═══════════════════════════════════════════════════════════════
# STEER: 反臃肿 | scope=firmware
# 职责: 主组件构建配置 — 注册源文件
# ═══════════════════════════════════════════════════════════════
idf_component_register(
    SRCS
        "main.c"
        "core/state/app_state.c"
        "core/hal/hal_gpio.c"
        "core/hal/hal_pwm.c"
        "core/hal/hal_led.c"
        "core/hal/hal_lcd.c"
        "core/hal/hal_encoder.c"
        "core/hal/hal_audio.c"
        "core/protocol/proto_ble.c"
        "core/protocol/proto_parser.c"
        "core/protocol/proto_dispatch.c"
        "modules/fan/fan_module.c"
        "modules/led/led_module.c"
        "modules/display/display_module.c"
        "modules/encoder/encoder_module.c"
        "modules/audio/audio_module.c"
        "modules/logo/logo_module.c"
        "modules/wifi/wifi_module.c"
    INCLUDE_DIRS "."
    REQUIRES
        nvs_flash
        bt
        esp_driver_gpio
        esp_driver_ledc
        esp_driver_spi
        esp_driver_i2s
        esp_driver_pcnt
        esp_driver_rmt
)
