# ZCritical 快速上下文（5秒速查）

> **用途**: 继续开发/修 bug 场景下快速恢复上下文，无需读完整文档
> **完整上下文**: 读 `session-handoff.md`
> **架构详情**: 读 `steering/specs/architecture-map.md`
> **约束规范**: 读 `steering/guides/anti-bloat.md`

---

## 当前阶段

| 端 | 阶段 | 状态 |
|----|------|------|
| APP | A2: 基础 UI 框架 | ✅ 完成 |
| 固件 | B2: BLE 协议层 | ✅ 完成 |
| 下一步 | APP A3: BLE 通信层 / 固件 B3: 功能模块 | 📋 待开始 |

## 分支

| 端 | 分支 | 说明 |
|----|------|------|
| APP | `app/` | Flutter Clean Architecture |
| 固件 | `firmware/` | ESP-IDF (ESP32-S3) |

## 硬件参数（唯一真值源: `steering/specs/hardware-config.md`）

| 参数 | 值 |
|------|-----|
| MCU | ESP32-S3 |
| BLE 设备名 | "T1" |
| BLE Service UUID | 0xFFE0 |
| BLE Char UUID | 0xFFE1 |
| LCD | GC9A01, 240×240, SPI |
| 编码器 | EC11, IO17/IO18/IO8 |
| LED1 | WS2812B ×6, IO41 |
| LED2 | WS2812B ×3, IO16 |
| 风扇 PWM | IO40 |
| 加湿器 | IO10 |
| 音频 I2S | MAX98357, IO13/IO12/IO11 |

## 设计令牌（唯一真值源: `steering/specs/ui-design-tokens.md`）

| 令牌 | 值 |
|------|-----|
| 背景色 | `Color(0xFF000000)` 纯黑 |
| 主色 | `Color(0xFF00BCD4)` 青 |
| 高亮色 | `Color(0xFF00E5FF)` 亮青 |
| 大标题 | 48px / w800 |
| 描述文字 | 20px / w400 |
| 按钮文字 | 17px / w600 |
| 按钮圆角 | 29 |
| 卡片圆角 | 12 |
| 页面边距 | ≥16px |

## BLE 协议（30 个命令）

| 类别 | 命令数 | 说明 |
|------|--------|------|
| 系统控制 | 5 | 心跳、重置、版本等 |
| LED 控制 | 6 | 颜色、模式、亮度 |
| LCD 控制 | 4 | Logo 上传、亮度 |
| 风扇控制 | 3 | 开关、档位 |
| 加湿器控制 | 3 | 开关、档位 |
| 编码器事件 | 3 | 旋转、按下 |
| 音频控制 | 3 | 播放、音量 |
| 状态查询 | 3 | 设备状态、电量 |

## 架构分层（APP 端）

```
presentation/  → UI + State (Provider)
domain/        → Entities + UseCases + Repositories(接口)
data/          → Repositories(实现) + BLE Service
core/          → Utils + Constants + Errors
```

## 关键约束

- 一个文件只做一件事（职责单一）
- import 方向不能反向（presentation ← domain ← data）
- 禁止从 reference/ 搬运代码（白板重建）
- 新功能先有契约再写代码
