# 软硬件统一命名约定

> **用途**: 确保固件 (C) 和 APP (Dart) 对同一概念使用相同的名字。
>             消除"固件叫 strip，APP 叫 channel"这类混乱。

---

## 一、核心硬件概念命名

| 概念 | 中文 | 固件 (C) | APP (Dart) | 说明 |
|------|------|----------|------------|------|
| 风扇 | 风扇 | `fan`, `FAN` | `fan`, `fanSpeed` | PWM 控制的风扇 |
| 速度 | 速度 | `speed`, `SPEED` | `speed` | 风速/跑步机速度 |
| 加湿器 | 加湿器/雾化器 | `wuhuaqi`, `WUHUA` | `wuhuaqi`, `humidifier` | 超声波雾化片 |
| 油门模式 | 油门模式 | `throttle`, `THROTTLE` | `throttle` | 长按加速松手减速 |
| 灯带 | 灯带 | `strip`, `LED_STRIP` | `strip` | WS2812B LED 灯带 |
| 预设 | 预设 | `preset`, `PRESET` | `preset` | 14种 LED 预设颜色 |
| 亮度 | 亮度 | `brightness`, `BRIGHT` | `brightness` | LED 全局亮度 |
| 流光 | 流水灯/流光 | `streamlight`, `STREAMLIGHT` | `streamlight` | LED 自动渐变动画 |
| 呼吸 | 呼吸效果 | `breath`, `BREATH` | `breathing` | LED 亮度正弦呼吸 |
| 编码器 | 编码器/旋钮 | `encoder`, `ENC` | `encoder` | EC11 旋转编码器 |
| 音量 | 音量 | `volume`, `VOL` | `volume` | 音频音量 |
| Logo | 标志 | `logo`, `LOGO` | `logo` | 240×240 圆形 Logo |
| 槽位 | 槽位 | `slot` | `slot` | Logo 存储槽位 (0-2) |

---

## 二、灯带命名

```
固件:  strip 0-1 (Main/Tail)
APP:   strip 0-1 (Main/Tail)

物理布局:
  strip 0 = Main (中间, 6颗 LED, IO41)
  strip 1 = Tail (尾部, 3颗 LED, IO16)

已移除: strip 1-2 (Left/Right) — 2026-05-09 硬件改版省成本
```

**注意:** BLE 协议中 `LED:s:r:g:b` 的 s 是 1-2 而非 0-1（固件自动转换）。

---

## 三、速度概念

| 概念 | 固件 (C) | APP (Dart) | 说明 |
|------|----------|------------|------|
| 内部值 | `current_speed_kmh` (0-100) | `internalSpeed` (0-100) | 0-100 内部表示 |
| 显示值(km/h) | `last_reported_speed` (0-340) | `displaySpeed` (0-340) | APP 显示的速度 |
| 显示值(mph) | 0-211 | 0-211 | APP 显示的速度 |
| 换算公式 | `display = internal × 3.4` | `display = internal × 3.4` | 必须一致 |
| 跑步机速度 | `treadmill_speed` (0-999) | `treadmillSpeed` (0-999) | 独立的速度值 |

---

## 四、UI 界面编号

| 编号 | 固件 (C) | APP (Dart) | 中文名 |
|------|----------|------------|--------|
| 1 | `UI1` / `ui_speed` | Speed | 速度控制 |
| 2 | `UI2` / `ui_preset` | Color | 颜色预设 |
| 3 | `UI3` / `ui_rgb` | RGB | RGB 调色 |
| 4 | `UI4` / `ui_bright` | Brightness | 亮度 |
| 5 | `UI5` / `ui_menu` | Menu | 菜单 |
| 6 | `UI6` / `ui_logo` | Logo | Logo 管理 |
| 8 | `UI8` / `ui_treadmill` | Treadmill | 跑步机 |

**注意:** 固件的 `UI:x` 命令，x 就是上面这个编号。不要跳到 7（音量界面已禁用）。

---

## 五、Git 分支命名

```
firmware/<功能名>     — 固件改动
app/<功能名>          — APP 改动
protocol/<功能名>     — 协议变更
steering/<功能名>     — 文档变更
```

**功能名风格:** 小写 + 连字符
- ✅ `firmware/fix-encoder-bounce`
- ✅ `app/ui-onboarding`
- ❌ `firmware/FixEncoderBounce`

---

*创建日期: 2026-05-08*
