# ⚠️ ZCritical-ESP 固件架构

> **优先级**: CRITICAL — 新固件对话第一份必读文件
> **策略**: 白板重建。reference/ridewind-esp 仅作参考。
> **架构方案**: core + modules 双区架构

---

## 一、项目定位

| 维度 | 说明 |
|------|------|
| **固件名称** | zcritical-esp |
| **MCU** | ESP32-S3 |
| **框架** | ESP-IDF |
| **语言** | C |
| **参考项目** | `reference/ridewind-esp/` — 不复用代码，仅参考值 |
| **对标** | `zcritical/` (APP端) — 白板重建 |

---

## 二、架构概览

```
main/
├── core/          ← 核心基础设施（改了影响全局）
│   ├── hal/       ← 硬件抽象（6个驱动文件）
│   ├── protocol/  ← 通信协议（BLE + 文本协议解析）
│   └── state/     ← 全局状态（拆为子结构体）
│
├── modules/       ← 功能模块（改了只影响自己）
│   ├── fan/       ← 风扇 + 油门
│   ├── led/       ← LED 预设 + 特效
│   ├── display/   ← LCD UI 渲染
│   ├── audio/     ← 引擎合成 + 播放
│   ├── encoder/   ← 编码器事件
│   ├── logo/      ← Logo 上传 + 存储
│   └── wifi/      ← WiFi 音频流
│
├── assets/        ← 静态资源
├── vendor/        ← 第三方库
└── main.c         ← 入口（~100行）
```

### 依赖方向

```
modules/  →  core/state/  →  core/hal/
modules/  →  core/protocol/
core/protocol/  →  core/state/
core/state/  →  core/hal/
core/hal/  →  （仅依赖 ESP-IDF SDK）
```

### 禁止的依赖

- `core/hal/` ⛔ 不能依赖 `core/state/`, `core/protocol/`, `modules/`
- `core/state/` ⛔ 不能依赖 `modules/`
- `modules/` 之间 ⛔ 不能互相依赖
- `modules/fan/` 和 `modules/led/` ⛔ 不能互相 include

---

## 三、HAL 层（6个驱动）

| 文件 | 外设 | 接口 |
|------|------|------|
| `hal_gpio.c` | GPIO (加湿器开关) | `gpio_set(hum, on/off)` |
| `hal_pwm.c` | LEDC PWM (风扇调速) | `pwm_set_duty(0-100)` |
| `hal_led.c` | WS2812B (2条 LED 灯带) | `led_set_strip(0-1, r, g, b)` |
| `hal_lcd.c` | GC9A01 SPI LCD | `lcd_draw_pixel(x,y,color)`, `lcd_fill(rect,color)` |
| `hal_encoder.c` | EC11 编码器 | `encoder_poll()` → delta |
| `hal_audio.c` | I2S MAX98357 | `audio_output(pcm, len)` |

每文件参考 ~300 行，职责单一优先。

---

## 四、状态管理

AppState 拆分为子结构体：

```c
// core/state/state_fan.h
typedef struct {
    uint8_t speed;          // 0-100
    uint8_t wuhuaqi;        // 0=关, 1=开, 2=油门
    uint8_t unit;           // 0=km/h, 1=mph
} fan_state_t;

// core/state/state_led.h
typedef struct {
    uint8_t colors[2][3];   // [strip][rgb] — 2条灯带 (Main/Tail)
    uint8_t brightness;      // 0-100
    uint8_t preset;          // 1-14
} led_state_t;

// core/state/state_app.h
typedef struct {
    fan_state_t  fan;
    led_state_t  led;
    ui_state_t   ui;
    audio_state_t audio;
    // ... 聚合入口 + 锁
} app_state_t;
```

---

## 五、协议层

### BLE 参数

| 参数 | 值 |
|------|-----|
| Service UUID | 0xFFE0 |
| Char UUID | 0xFFE1 |
| 设备名 | "T1" |
| MTU | 247 |

### 数据流

```
BLE 回调 (Core 0)
  → s_rx_buf 缓冲 → \n 分割
    → proto_parser.c 解析 → cmd_msg_t
      → xQueueSend → cmd_queue
        → main_task (Core 1) 接收
          → proto_dispatch.c 分发
            → 调用 modules/ 或 修改 state/
            → proto_ble.c 回复通知
```

---

## 六、核心约束

| 约束 | 说明 |
|------|------|
| 行数参考值 | HAL ~300行 / modules ~400行 / main.c ~150行。**职责单一 > 行数**。逻辑清晰的500行好过强行拆分的3个碎片 |
| 零行搬运 | 不从 reference 复制代码 |
| 协议不可变 | BLE 命令格式与 reference 一致 |
| 编译验证 | 每步 idf.py build 必须通过 |

## 七、编译环境

| 参数 | 值 |
|------|-----|
| ESP-IDF | v5.3.5 (`C:\Espressif\frameworks\esp-idf-v5.3.5`) |
| Python | `C:\Espressif\python_env\idf5.3_py3.11_env\Scripts\python.exe` |
| Toolchain | xtensa-esp-elf 13.2.0 (`C:\Espressif\tools\xtensa-esp-elf\esp-13.2.0_20250707`) |
| CMake | 3.30.2 (`C:\Espressif\tools\cmake\3.30.2\bin`) |
| Ninja | 1.12.1 (`C:\Espressif\tools\ninja\1.12.1`) |
| 快捷构建 | `build_fw.bat build`（需在 ESP-IDF 环境变量已配好的终端中执行） |

### 编译命令（手动指定路径）

```powershell
$env:IDF_PATH="C:\Espressif\frameworks\esp-idf-v5.3.5"
$env:PATH="C:\Espressif\tools\cmake\3.30.2\bin;C:\Espressif\tools\ninja\1.12.1;C:\Espressif\tools\xtensa-esp-elf\esp-13.2.0_20250707\xtensa-esp-elf\bin;C:\Espressif\python_env\idf5.3_py3.11_env\Scripts;$env:PATH"
python C:\Espressif\frameworks\esp-idf-v5.3.5\tools\idf.py build
```

### .h 文件 include 规则

- 必须显式 `#include <stdint.h>` 和 `#include <stdbool.h>`（ESP-IDF gnu17 模式不自动提供）
- 使用 `#include "esp_err.h"` 获取 `esp_err_t`
- 不要包含 `<stdio.h>` 等标准库（IDE linter 可能报错但不影响 ESP-IDF 编译）

---

## 八、硬件引脚配置（唯一真值源: `steering/hardware-config.md`）

| 外设 | 引脚 | 说明 |
|------|------|------|
| LCD CS | IO4 | GC9A01 SPI 片选 |
| LCD DC | IO5 | GC9A01 数据/命令 |
| LCD SDA | IO6 | GC9A01 SPI 数据 |
| LCD SCL | IO7 | GC9A01 SPI 时钟 |
| 编码器 KEY | IO8 | EC11 按键，拉低触发 |
| 加湿器 CH1 | IO10 | MOS管开关 |
| 音频 LRC | IO11 | MAX98357 I2S 左右时钟 |
| 音频 BCLK | IO12 | MAX98357 I2S 位时钟 |
| 音频 DIN | IO13 | MAX98357 I2S 数据 |
| LED2 | IO16 | WS2812B × 3颗（尾灯） |
| 编码器 S1 | IO17 | EC11 A相 |
| 编码器 S2 | IO18 | EC11 B相 |
| 风扇 CH2 | IO40 | MOS管 PWM 调速 |
| LED1 | IO41 | WS2812B × 6颗（主灯） |

---

*创建日期: 2026-05-08*
