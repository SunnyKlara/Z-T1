> ⚠️ 本文件已归档（2026-05-09）。核心内容已涵盖在 `firmware/zcritical-esp/.kiro/steering/architecture.md`（架构）和 `firmware/zcritical-esp/.kiro/steering/anti-bloat.md`（反臃肿）。
> 本文件保留作为历史参考，不再作为权威源。建议后续移入固件专属 steering 目录。

# ⚠️ 固件端重建蓝图 📦已归档

> **优先级**: CRITICAL — 固件端对标 APP 端的全面重建计划
> **对标**: zcritical/.kiro/steering/reconstruction-blueprint.md
> **核心理念**: 和 APP 端完全一致——**白板重建，不从 ridewind-esp 搬运代码。**
>             ridewind-esp 已移到 reference/，仅作参考（协议格式、引脚定义等不可变信息）。
>             所有代码从零写，在写的过程中自然应用新架构。
> **创建**: 2026-05-08 | **修订**: 2026-05-08（切换为白板重建策略）

---

## 一、和 APP 端完全对标

```
APP端:   reference/RideWind/     → 参考项目
          zcritical/              → 白板重写，零行代码搬运

固件端:  reference/ridewind-esp/ → 参考项目
          firmware/zcritical-esp/ → 白板重写，零行代码搬运
```

**ridewind-esp 唯一不可替代的价值：**
- 引脚定义（pin_config.h → 硬件焊接后不可变）
- 板级参数（board_config.h → 风扇转速、LCD尺寸等硬参数）
- BLE UUID（Service 0xFFE0, Char 0xFFE1, 设备名 "T1"）
- 协议格式（protocol-contract.md 已提取，不依赖代码）
- LED 预设颜色（14种，在 preset_colors.h 中定义）
- CRC32 多项式（0xEDB88320）
- Logo 格式（240×240 RGB565, 115200字节）

---

## 二、目标架构（方案 D：core + modules）

```
firmware/zcritical-esp/
├── CMakeLists.txt              ← ESP-IDF 构建配置（从零写）
├── sdkconfig.defaults           ← SDK 默认配置
├── partitions.csv               ← Flash 分区表
│
├── main/
│   ├── CMakeLists.txt           ← 主组件构建配置
│   ├── main.c                   ← 入口（目标 ~100行）
│   │
│   ├── core/                    ← 核心基础设施
│   │   ├── hal/                 ← 硬件抽象层
│   │   │   ├── hal_lcd.h/c      # GC9A01 LCD (SPI+DMA)
│   │   │   ├── hal_led.h/c      # WS2812B LED
│   │   │   ├── hal_encoder.h/c  # EC11 编码器
│   │   │   ├── hal_pwm.h/c      # LEDC PWM (风扇)
│   │   │   ├── hal_gpio.h/c     # GPIO (加湿器)
│   │   │   └── hal_audio.h/c    # I2S 音频
│   │   │
│   │   ├── protocol/            ← 通信协议
│   │   │   ├── proto_types.h    # 命令枚举 + cmd_msg_t
│   │   │   ├── proto_parser.h/c # 文本协议解析
│   │   │   ├── proto_dispatch.h/c # 命令分发
│   │   │   └── proto_ble.h/c    # BLE GATT 服务
│   │   │
│   │   └── state/               ← 全局状态
│   │       ├── state_app.h/c    # AppState 聚合入口
│   │       ├── state_fan.h      # 风扇/速度子状态
│   │       ├── state_led.h      # LED 颜色/特效子状态
│   │       ├── state_ui.h       # UI/编码器子状态
│   │       └── state_audio.h    # 音频/Logo子状态
│   │
│   ├── modules/                 ← 功能模块（可插拔）
│   │   ├── fan/                 ← 风扇模块
│   │   │   ├── fan_control.h/c  # 速度控制 + 油门模式
│   │   │   └── fan_speed_map.h  # kmh/mph 换算
│   │   │
│   │   ├── led/                 ← LED 模块
│   │   │   ├── led_presets.h    # 14种预设颜色
│   │   │   ├── led_color.h/c    # 颜色设置
│   │   │   └── led_effects.h/c  # 渐变/流光/呼吸
│   │   │
│   │   ├── display/             ← LCD 显示模块
│   │   │   ├── disp_ui.h/c      # UI 状态机
│   │   │   ├── disp_common.h/c  # 通用绘制
│   │   │   ├── disp_speed.h/c   # 速度页
│   │   │   ├── disp_color.h/c   # 颜色页
│   │   │   ├── disp_rgb.h/c     # RGB页
│   │   │   ├── disp_bright.h/c  # 亮度页
│   │   │   ├── disp_menu.h/c    # 菜单页
│   │   │   ├── disp_logo.h/c    # Logo页
│   │   │   └── disp_treadmill.h/c # 跑步机页
│   │   │
│   │   ├── audio/               ← 音频模块
│   │   │   ├── audio_engine.h/c # 引擎总控
│   │   │   ├── audio_synth.h/c  # 波表合成
│   │   │   ├── audio_synth_proc.h/c # 程序化合成
│   │   │   └── audio_player.h/c # 播放器
│   │   │
│   │   ├── encoder/             ← 编码器模块
│   │   │   └── enc_handler.h/c  # 事件分发
│   │   │
│   │   ├── logo/                ← Logo 模块
│   │   │   ├── logo_receiver.h/c # BLE 上传接收
│   │   │   └── logo_storage.h/c # 文件存储
│   │   │
│   │   └── wifi/                ← WiFi 模块
│   │       └── wifi_audio.h/c   # TCP 音频流
│   │
│   ├── assets/                  ← 静态资源
│   │   ├── images/              # LCD 位图数据
│   │   ├── fonts/               # 字体
│   │   └── audio/               # 音频素材
│   │
│   └── vendor/                  ← 第三方库
│       └── minimp3/
│
├── .kiro/steering/              ← 固件专属 steering
│   ├── anti-bloat.md
│   ├── architecture.md
│   ├── coding-standards-c.md
│   ├── firmware-workflow.md
│   └── technical-debt.md
│
└── tools/                       ← 构建/调试工具
```

---

## 三、重建阶段

### 阶段 0: 可编译空壳（P0）

```
目标: CMakeLists.txt + main.c + sdkconfig → idf.py build 通过
输出: 一个能编译但什么都不做的固件
```

### 阶段 1: HAL 层（P0 — 必须先做）

```
顺序按依赖关系:
  1. hal_gpio.c    — 最简单，先验证工具链
  2. hal_pwm.c     — 风扇 PWM
  3. hal_led.c     — WS2812B
  4. hal_lcd.c     — GC9A01 SPI
  5. hal_encoder.c — EC11
  6. hal_audio.c   — I2S

每写完一个 → 编译通过 → 烧录验证 → 下一个
```

### 阶段 2: 状态 + 协议（P0）

```
  1. state_app.c/h      — 聚合入口 + 锁
  2. state_fan.h        — 风扇子状态
  3. state_led.h        — LED 子状态
  4. state_ui.h         — UI 子状态
  5. state_audio.h      — 音频子状态
  6. proto_types.h      — 命令枚举
  7. proto_parser.c     — 协议解析
  8. proto_dispatch.c   — 命令分发
  9. proto_ble.c        — BLE 服务
```

### 阶段 3: 功能模块（P1）

```
每模块独立开发，互不阻塞：
  1. modules/fan/       — 风扇 + 油门
  2. modules/led/       — LED 预设 + 特效
  3. modules/encoder/   — 编码器事件
  4. modules/audio/     — 引擎合成 + 播放
  5. modules/display/   — LCD UI 页面
  6. modules/logo/      — Logo 上传 + 存储
  7. modules/wifi/      — WiFi 音频流
```

### 阶段 4: main.c 组装（P2）

```
将所有模块连接到主循环 → 完整功能固件
```

---

## 四、不可变核心（从 reference 提取，不是从代码搬运）

| 项 | 值 | 来源 |
|----|-----|------|
| 引脚分配 | IO4-IO41 各功能 | reference/ridewind-esp 引脚文档 |
| BLE UUID | Service 0xFFE0, Char 0xFFE1 | 硬件不变 |
| 设备名 | "T1" | 硬件不变 |
| Logo 格式 | 240×240 RGB565, 115200字节 | 硬件不变 |
| CRC32 | 多项式 0xEDB88320 | 数学常数 |
| LED 预设 | 14种颜色值 | 参考 preset_colors.h 的值 |
| 协议格式 | 文本协议 `\n` 结尾 | protocol-contract.md |
| LCD | GC9A01, 240×240, SPI 40MHz | 硬件不变 |

---

## 五、重建铁律

1. **零行搬运** — 从 reference 抄的是"值"（引脚号、颜色RGB），不是"代码"
2. **每步编译** — 写完一个文件 → idf.py build → 通过 → 下一个
3. **先 HAL 再模块** — HAL 是所有模块的依赖基底
4. **并行开发** — 阶段 3 的模块可以同时开多段对话并行写
5. **协议不可变** — 所有 BLE 命令格式与 reference 完全一致
6. **每文件 ≤ 300行** — HAL 层硬限制，从第一天就遵守

---

## 六、和 APP 端对应关系

| APP 端 | 固件端 |
|--------|--------|
| `core/` | `core/hal/` — 基础设施 |
| `data/` | `core/protocol/` — 数据通信 |
| `domain/` | `core/state/` — 状态模型 |
| `presentation/screens/` | `modules/display/` — UI渲染 |
| `presentation/providers/` | `modules/fan/`, `modules/led/` — 业务逻辑 |
| `steering/` | `.kiro/steering/` — 约束文档 |

---

*创建日期: 2026-05-08 | 对标 zcritical reconstruction-blueprint.md*
