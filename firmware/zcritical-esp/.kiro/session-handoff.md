# 固件端 — 会话交接 (可直接执行)

> **给下一个 AI**: 读完这页你就知道该做什么。这里是全部参数，不需要去别的文件找。
> **施工图**: `firmware/zcritical-esp/.kiro/steering/specs/architecture.md`

---

## 当前阶段: B1 HAL 驱动 ✅ 完成 (2026-05-09)

> 6 个 HAL 驱动全部编译通过。下一步: B2 BLE 协议层。

### 完成状态

| # | 文件 | 状态 | 行数 |
|---|------|------|------|
| 1 | `hal_gpio.c` / `.h` | ✅ 编译通过 | 48/23 |
| 2 | `hal_pwm.c` / `.h` | ✅ 编译通过 | 61/20 |
| 3 | `hal_led.c` / `.h` | ✅ 编译通过 | 137/38 |
| 4 | `hal_lcd.c` / `.h` | ✅ 编译通过 | 165/30 |
| 5 | `hal_encoder.c` / `.h` | ✅ 编译通过 | 173/36 |
| 6 | `hal_audio.c` / `.h` | ✅ 编译通过 | 128/22 |

### 构建配置

| 文件 | 说明 |
|------|------|
| `CMakeLists.txt` | 顶层: project(zcritical-esp) |
| `main/CMakeLists.txt` | 注册 main.c + 6个HAL .c, REQUIRES: nvs_flash driver esp_timer led_strip |
| `main/idf_component.yml` | 依赖 espressif/led_strip (v2.5.5) |
| `sdkconfig.defaults` | ESP32-S3 + BLE + WiFi + PSRAM; 已移除无效的 LCD_IO_SPI_MODE |

### main.c 当前状态

调用了所有 6 个 HAL init 函数，初始化完成后 LCD 清黑屏 + LED 红灯测试。

### 编译环境

```
ESP-IDF v5.3.5 (C:\Espressif\frameworks\esp-idf-v5.3.5)
Python: C:\Espressif\python_env\idf5.3_py3.11_env\Scripts\python.exe
Toolchain: xtensa-esp-elf\esp-13.2.0_20250707
编译命令: idf.py build (需设置 IDF_PATH, cmake/ninja/xtensa 在 PATH 中)
等效快捷方式: build_fw.bat build
```

### 已验证

- [x] `idf.py set-target esp32s3`
- [x] `idf.py build` ✅ 通过
- [ ] 烧录实机验证 (用户自行验证)

### 下一步: B2 BLE 协议层

```
目标: BLE GATT 服务 + 协议解析 + 命令分发
参考: steering/specs/protocol-contract.md
架构: firmware/zcritical-esp/.kiro/steering/specs/architecture.md 第五节
```

---

## 硬件参数（唯一真值源: `steering/specs/hardware-config.md`）

| 外设 | 引脚 | 驱动文件 |
|------|------|----------|
| 加湿器 GPIO | IO10 (CH1 MOS) | hal_gpio.c |
| 风扇 PWM | IO40 (CH2 MOS, LEDC) | hal_pwm.c |
| LED1 WS2812B | IO41 (6颗主灯, RMT) | hal_led.c |
| LED2 WS2812B | IO16 (3颗尾灯, RMT) | hal_led.c |
| LCD GC9A01 | CS=IO4, DC=IO5, SDA=IO6, SCL=IO7 (SPI2 40MHz) | hal_lcd.c |
| 编码器 EC11 | S1=IO17, S2=IO18, KEY=IO8 (PCNT) | hal_encoder.c |
| 音频 MAX98357 | DIN=IO13, BCLK=IO12, LRC=IO11 (I2S 44100Hz) | hal_audio.c |

## sdkconfig.defaults 当前配置

```
CONFIG_IDF_TARGET_ESP32S3=y
CONFIG_BT_ENABLED=y
CONFIG_BT_BLUEDROID_ENABLED=y
CONFIG_BT_CLASSIC_ENABLED=n
CONFIG_ESP_WIFI_ENABLED=y
CONFIG_SPIRAM=y
CONFIG_SPIRAM_USE_CAPS_ALLOC=y
```

---

*最后更新: 2026-05-09 | B1 HAL 驱动全部编译通过 | 待实机烧录验证*
