> ⚠️ 本文件已归档（2026-05-09）。核心内容已涵盖在 `steering/global-development-roadmap.md` 中（路线图、阶段规划、验收标准）。
> 本文件保留作为历史参考，不再作为权威源。具体任务参数请见各端 `session-handoff.md`。

# 🏗️ Z-T1 开发施工图 📦已归档

> **用途**: 所有开发对话的唯一参照系。定义每个阶段的精确任务、产出物、依赖关系、验收标准。
> **原则**: 一旦定下，不返工。每个阶段有明确的"完成"定义和质量关卡。
> **创建**: 2026-05-08

---

## 一、全局开发路线图

```
Phase 0: 基础设施          ✅ 已完成
    │
    ├─ 全局 steering (11文件)
    ├─ APP steering (18文件)
    ├─ 固件 steering (5文件)
    ├─ 协议契约
    └─ 4个 Panel 提前完成
    │
    ▼
Phase 1: APP 骨架           📍 当前阶段
    │
    ├─ A1: 应用入口 (Splash + Onboarding + HomeShell + Drawer)
    ├─ A2: 用户中心 (UserCenter + LogoManagement)
    └─ A3: BLE 连接层 (BLE Provider + 连接状态管理)
    │
    ▼
Phase 2: 固件骨架
    │
    ├─ B1: HAL 驱动 (6个: LCD / LED / Encoder / Fan / Humidifier / Audio)
    ├─ B2: BLE 协议层 (GATT + 命令解析 + 状态机)
    └─ B3: 功能模块 (7个: fan / led / display / audio / encoder / logo / wifi)
    │
    ▼
Phase 3: APP 核心功能
    │
    ├─ C1: BLE 协议实现 (命令发送 + 响应解析 + 状态同步)
    ├─ C2: 面板数据绑定 (4个 Panel 连接真实数据)
    └─ C3: 状态管理 (Provider 层 + 离线缓存)
    │
    ▼
Phase 4: 固件核心功能
    │
    ├─ D1: 协议完整实现 (所有命令 + 响应 + 上报)
    ├─ D2: Logo 上传 (PSRAM 缓冲 + CRC32 + LittleFS)
    └─ D3: WiFi 模块 (OTA 基础 + 网络状态)
    │
    ▼
Phase 5: 联调测试
    │
    ├─ E1: APP-固件 BLE 联调 (所有命令 + 响应)
    ├─ E2: 真机测试 (所有硬件功能)
    └─ E3: 问题修复 + 性能优化
    │
    ▼
Phase 6: 生产准备
    │
    ├─ F1: APP 上架 (隐私政策 + 应用截图 + 多语言)
    ├─ F2: 工厂测试模式 (GPIO 触发 + 全功能自检)
    ├─ F3: 工装烧录方案 (多路 USB + 自动化)
    └─ F4: OTA 固件更新 (ESP-IDF 原生 + WiFi)
    │
    ▼
Phase 7: 发布
    │
    ├─ G1: APP 上架 (App Store + Google Play)
    ├─ G2: 固件量产版本 (v1.0.0)
    └─ G3: 用户文档 (说明书 + FAQ)
```

---

## 二、当前阶段详细规划 — Phase 1: APP 骨架

### A1: 应用入口 (当前任务)

| 项目 | 详情 |
|------|------|
| **目标** | 完成 APP 启动流程：Splash → Onboarding → HomeShell |
| **预计对话** | 3-4 个 |
| **依赖** | Phase 0 (已完成) |
| **产出物** | 4 个新文件 + 2 个修改文件 |
| **验收标准** | `flutter analyze` 零错误 + 真机可运行 + 路由正确 |

#### 任务清单

| # | 文件 | 职责 | 行数上限 | 状态 |
|---|------|------|---------|------|
| 1 | `lib/presentation/screens/splash/splash_screen.dart` | 品牌展示 + 用户协议勾选 + "开始使用"按钮 | ≤180 | 待开始 |
| 2 | `lib/presentation/screens/onboarding/onboarding_screen.dart` | 3页引导 (通知权限 + 设备权限 + 完成) | ≤150 | 待开始 |
| 3 | `lib/presentation/screens/home/home_shell.dart` | GoRouter ShellRoute + Stack + ☰按钮 | ≤80 | 待开始 |
| 4 | `lib/presentation/widgets/drawer/drawer_widget.dart` | 品牌区 + 用户中心 + Logo管理 | ≤80 | 待开始 |
| 5 | `lib/core/router/app_router.dart` | 扩展路由: /splash, /onboarding, Shell route | 修改 | 待开始 |
| 6 | `lib/app.dart` | 入口流: isFirstLaunch → Splash 或 HomeShell | 修改 | 待开始 |

#### 具体参数

**SplashScreen:**
- 背景: `Color(0xFF000000)` 纯黑
- 品牌Logo: 代码绘制 "ZCritical" 文字 + 风洞线框图形
- 协议勾选: 圆框 + 红色内圆点 + "我已阅读并同意" + 蓝色链接
- 按钮: 白底黑字, 圆角29, 宽320高58
- 用户协议和隐私政策: 硬编码文本, 弹窗展示

**OnboardingScreen (3页):**
- PageView 可滑动
- 标题: 48号字, w800
- 描述: 20号字, 白色70%透明度
- 底部: 3个指示器横条 + 下一步按钮
- 第1页: "允许通知权限"
- 第2页: "允许附近设备权限"
- 第3页: "全部就绪！" → 按钮文案"开始探索"
- 完成后: `markOnboardingComplete()` → `pushAndRemoveUntil` → HomeShell

**HomeShell:**
- GoRouter ShellRoute 管理 body
- Stack: 主内容 + Positioned(top-right) ☰按钮 (56x56, 白色半透明圆形)
- ☰按钮 → `openEndDrawer`
- BLE Banner: 顶部细条, 未连接时显示 "未连接设备 — 点击连接" (A3 实现)

**Drawer:**
- 从右滑出, 黑色背景, 宽 ~280px
- 品牌区: "ZCritical" 文字 + 版本号 (连点5次解锁开发者选项)
- 👤 用户中心 → `/user-center`
- 🖼️ Logo 管理 → `/logo`
- 分隔线 + 预留扩展位

#### 关键常量

```dart
颜色:
  背景:   Color(0xFF000000) 纯黑
  主色:   Color(0xFF00BCD4) 青色
  高亮:   Color(0xFF00E5FF) 亮青
  文字:   Colors.white / Colors.white70
  按钮:   Colors.white 背景 + Colors.black 前景

字体:
  大标题: 48px, w800, letterSpacing -0.5
  描述:   20px, w400, height 1.5
  按钮:   17px, w600

路由:
  /splash       → SplashScreen
  /onboarding   → OnboardingScreen
  /             → HomeScreen (Shell body)
  /user-center  → UserCenterScreen
  /logo         → LogoManagementScreen
```

---

### A2: 用户中心 + Logo 管理

| 项目 | 详情 |
|------|------|
| **目标** | 完成用户中心界面和 Logo 管理界面 |
| **预计对话** | 2 个 |
| **依赖** | A1 (HomeShell + Drawer + 路由) |
| **产出物** | 2 个新文件 |
| **验收标准** | 可从 Drawer 导航进入 + 界面完整 + `flutter analyze` 零错误 |

#### 任务清单

| # | 文件 | 职责 | 行数上限 | 状态 |
|---|------|------|---------|------|
| 1 | `lib/presentation/screens/user_center/user_center_screen.dart` | 分区标题 + icon tile 列表 (参考 RideWind `_sectionTitle` + `_tile`) | ≤200 | 待开始 |
| 2 | `lib/presentation/screens/logo/logo_management_screen.dart` | Logo 上传界面 + 预览 + 进度条 | ≤250 | 待开始 |

---

### A3: BLE 连接层

| 项目 | 详情 |
|------|------|
| **目标** | 完成 BLE 连接状态管理和连接界面 |
| **预计对话** | 2-3 个 |
| **依赖** | A1 (HomeShell) + 协议契约 |
| **产出物** | 3 个新文件 + 1 个修改文件 |
| **验收标准** | 可扫描设备 + 可连接 + 状态正确同步 + `flutter analyze` 零错误 |

#### 任务清单

| # | 文件 | 职责 | 行数上限 | 状态 |
|---|------|------|---------|------|
| 1 | `lib/data/services/ble_service.dart` | BLE 扫描 + 连接 + 断开 + 状态管理 | ≤300 | 待开始 |
| 2 | `lib/presentation/providers/ble_provider.dart` | BLE 状态 Provider (Riverpod/Provider) | ≤150 | 待开始 |
| 3 | `lib/presentation/screens/device_scan/device_scan_screen.dart` | 设备扫描界面 + 连接按钮 | ≤200 | 待开始 |
| 4 | `lib/presentation/widgets/ble_banner.dart` | 顶部连接状态 Banner | ≤80 | 待开始 |

---

## 三、Phase 2: 固件骨架

### B1: HAL 驱动

| 项目 | 详情 |
|------|------|
| **目标** | 6个硬件驱动全部实现 |
| **预计对话** | 4-5 个 |
| **依赖** | Phase 0 (项目骨架) + 硬件参数 |
| **产出物** | 6 个驱动文件 + 头文件 |
| **验收标准** | `idf.py build` 通过 + 烧录后各驱动可独立工作 |

#### 任务清单

| # | 文件 | 职责 | 行数上限 | 状态 |
|---|------|------|---------|------|
| 1 | `main/core/hal/lcd_gc9a01.c/h` | GC9A01 LCD 驱动 (SPI, 240×240) | ≤300 | 待开始 |
| 2 | `main/core/hal/led_ws2812b.c/h` | WS2812B LED 驱动 (RMT, 10+3颗) | ≤250 | 待开始 |
| 3 | `main/core/hal/encoder_ec11.c/h` | EC11 编码器驱动 (GPIO 中断) | ≤200 | 待开始 |
| 4 | `main/core/hal/fan_pwm.c/h` | 风扇 PWM 驱动 (LEDC, IO40) | ≤150 | 待开始 |
| 5 | `main/core/hal/humidifier.c/h` | 加湿器驱动 (GPIO, IO10) | ≤100 | 待开始 |
| 6 | `main/core/hal/audio_i2s.c/h` | 音频驱动 (I2S, MAX98357) | ≤250 | 待开始 |

#### 硬件参数

| 参数 | 值 | 来源 |
|------|-----|------|
| MCU | ESP32-S3 | — |
| BLE 设备名 | "T1" | reference/board_config.h |
| BLE Service UUID | 0xFFE0 | reference/ble_service.c |
| BLE Char UUID | 0xFFE1 | reference/ble_service.c |
| LCD 芯片 | GC9A01, 240×240 | reference/board_config.h |
| LCD SPI | SPI2_HOST, 40MHz, IO4-7 | reference/pin_config.h |
| 编码器 | EC11, A=IO17, B=IO18, KEY=IO8 | reference/pin_config.h |
| 风扇 PWM | IO40, LEDC, 1000Hz | reference/board_config.h |
| LED WS2812B | IO41(10颗) + IO16(3颗) | reference/board_config.h |
| 加湿器 GPIO | IO10 | reference/pin_config.h |
| 音频 I2S | IO11/12/13, MAX98357, 44100Hz | reference/pin_config.h |
| 主任务周期 | 20ms | reference/board_config.h |
| 命令队列深度 | 32 | reference/board_config.h |
| Logo 格式 | 240×240 RGB565, 115200字节 | 不可变 |
| CRC32 多项式 | 0xEDB88320 | 不可变 |

---

### B2: BLE 协议层

| 项目 | 详情 |
|------|------|
| **目标** | 完成 BLE GATT + 命令解析 + 状态机 |
| **预计对话** | 3-4 个 |
| **依赖** | B1 (HAL 驱动) |
| **产出物** | 3 个文件 |
| **验收标准** | `idf.py build` 通过 + 可接收/解析 BLE 命令 + 状态机正确 |

#### 任务清单

| # | 文件 | 职责 | 行数上限 | 状态 |
|---|------|------|---------|------|
| 1 | `main/core/protocol/ble_gatt.c/h` | BLE GATT 服务 + 特征值 | ≤300 | 待开始 |
| 2 | `main/core/protocol/command_parser.c/h` | 命令解析 (文本协议) | ≤250 | 待开始 |
| 3 | `main/core/protocol/state_machine.c/h` | 设备状态机 | ≤200 | 待开始 |

---

### B3: 功能模块

| 项目 | 详情 |
|------|------|
| **目标** | 7个功能模块实现 |
| **预计对话** | 4-5 个 |
| **依赖** | B1 (HAL) + B2 (协议层) |
| **产出物** | 7 个模块文件 |
| **验收标准** | `idf.py build` 通过 + 各模块可独立工作 |

#### 任务清单

| # | 文件 | 职责 | 行数上限 | 状态 |
|---|------|------|---------|------|
| 1 | `main/modules/fan/fan_module.c/h` | 风扇控制 (速度/开关) | ≤200 | 待开始 |
| 2 | `main/modules/led/led_module.c/h` | LED 控制 (颜色/预设/RGB) | ≤250 | 待开始 |
| 3 | `main/modules/display/display_module.c/h` | LCD 显示 (速度/状态) | ≤200 | 待开始 |
| 4 | `main/modules/audio/audio_module.c/h` | 音频播放 | ≤150 | 待开始 |
| 5 | `main/modules/encoder/encoder_module.c/h` | 编码器事件处理 | ≤150 | 待开始 |
| 6 | `main/modules/logo/logo_module.c/h` | Logo 上传/存储/显示 | ≤300 | 待开始 |
| 7 | `main/modules/wifi/wifi_module.c/h` | WiFi 连接/状态 | ≤200 | 待开始 |

---

## 四、Phase 3-7 概要规划

> 以下阶段在当前阶段完成后细化。此处列出目标和依赖关系。

### Phase 3: APP 核心功能

| 子阶段 | 目标 | 依赖 | 预计对话 |
|--------|------|------|---------|
| C1: BLE 协议实现 | 命令发送 + 响应解析 + 状态同步 | A3 (BLE 连接层) + 协议契约 | 3-4 |
| C2: 面板数据绑定 | 4个 Panel 连接真实数据 | C1 + Phase 0 (Panel 已完成) | 2-3 |
| C3: 状态管理 | Provider 层 + 离线缓存 | C1 + C2 | 2 |

### Phase 4: 固件核心功能

| 子阶段 | 目标 | 依赖 | 预计对话 |
|--------|------|------|---------|
| D1: 协议完整实现 | 所有命令 + 响应 + 上报 | B2 + B3 | 3-4 |
| D2: Logo 上传 | PSRAM 缓冲 + CRC32 + LittleFS | B3 (logo_module) | 2-3 |
| D3: WiFi 模块 | OTA 基础 + 网络状态 | B3 (wifi_module) | 2 |

### Phase 5: 联调测试

| 子阶段 | 目标 | 依赖 | 预计对话 |
|--------|------|------|---------|
| E1: BLE 联调 | 所有命令 + 响应验证 | Phase 3 + Phase 4 | 4-5 |
| E2: 真机测试 | 所有硬件功能验证 | E1 | 3-4 |
| E3: 问题修复 | 性能优化 + Bug 修复 | E2 | 3-5 |

### Phase 6: 生产准备

| 子阶段 | 目标 | 依赖 | 预计对话 |
|--------|------|------|---------|
| F1: APP 上架 | 隐私政策 + 应用截图 + 多语言 | Phase 5 | 3-4 |
| F2: 工厂测试模式 | GPIO 触发 + 全功能自检 | Phase 5 | 2-3 |
| F3: 工装烧录方案 | 多路 USB + 自动化 | Phase 5 | 2 |
| F4: OTA 固件更新 | ESP-IDF 原生 + WiFi | Phase 5 | 3-4 |

### Phase 7: 发布

| 子阶段 | 目标 | 依赖 | 预计对话 |
|--------|------|------|---------|
| G1: APP 上架 | App Store + Google Play | Phase 6 | 2-3 |
| G2: 固件量产版本 | v1.0.0 发布 | Phase 6 | 1-2 |
| G3: 用户文档 | 说明书 + FAQ | Phase 6 | 2 |

---

## 五、阶段依赖关系图

```
Phase 0 (基础设施)
    │
    ├─────────────────────────────────────┐
    ▼                                     ▼
Phase 1 (APP 骨架)                    Phase 2 (固件骨架)
    │                                     │
    ├─ A1: 应用入口                       ├─ B1: HAL 驱动
    ├─ A2: 用户中心                       ├─ B2: BLE 协议层
    └─ A3: BLE 连接层                     └─ B3: 功能模块
    │                                     │
    ▼                                     ▼
Phase 3 (APP 核心功能)                Phase 4 (固件核心功能)
    │                                     │
    ├─ C1: BLE 协议实现                   ├─ D1: 协议完整实现
    ├─ C2: 面板数据绑定                   ├─ D2: Logo 上传
    └─ C3: 状态管理                       └─ D3: WiFi 模块
    │                                     │
    └──────────────────┬──────────────────┘
                       ▼
              Phase 5 (联调测试)
                       │
                       ▼
              Phase 6 (生产准备)
                       │
                       ▼
              Phase 7 (发布)
```

**关键依赖说明**:
- Phase 1 和 Phase 2 可并行开发
- Phase 3 依赖 Phase 1 完成
- Phase 4 依赖 Phase 2 完成
- Phase 5 依赖 Phase 3 + Phase 4 都完成
- Phase 6 依赖 Phase 5 完成
- Phase 7 依赖 Phase 6 完成

---

## 六、验收标准

### 通用验收标准 (所有阶段)

| 检查项 | 标准 | 工具 |
|--------|------|------|
| 编译 | 零错误 + 零警告 | `flutter analyze` / `idf.py build` |
| 行数 | 单文件 ≤350 行 | 手动检查 |
| STEER 块 | 每个文件头部有职责声明 | 手动检查 |
| Import 方向 | 不跨层 import | 手动检查 |
| 文档更新 | session-handoff.md 已更新 | 手动检查 |

### Phase 1 验收标准

| 检查项 | 标准 |
|--------|------|
| 路由 | /splash → /onboarding → / 正确跳转 |
| 首次启动 | 显示 Splash → Onboarding → HomeShell |
| 非首次启动 | 直接显示 HomeShell |
| Drawer | 从右侧滑出，包含品牌区 + 用户中心 + Logo管理 |
| 编译 | `flutter analyze` 零错误 |

### Phase 2 验收标准

| 检查项 | 标准 |
|--------|------|
| 编译 | `idf.py build` 通过 |
| LCD | 可显示测试图案 |
| LED | 可控制颜色和亮度 |
| 编码器 | 旋转可上报速度变化 |
| 风扇 | 可控制速度和开关 |
| 加湿器 | 可控制开关 |
| 音频 | 可播放测试音频 |

### Phase 5 验收标准

| 检查项 | 标准 |
|--------|------|
| BLE 连接 | APP 可扫描并连接设备 |
| 命令响应 | 所有命令发送后收到正确响应 |
| 状态同步 | APP 显示状态与设备实际状态一致 |
| Logo 上传 | 240×240 Logo 可完整上传并显示 |
| 异常处理 | 断连/超时/CRC 错误正确处理 |

---

## 七、文档索引

### 新对话启动 → 读这 3 个文件

| 顺序 | 文件 | 用途 | 阅读时间 |
|------|------|------|---------|
| 1 | `steering/global-development-roadmap.md` | 全局阶段、当前进度、下一步 | 5 分钟 |
| 2 | `steering/development-blueprint.md` | 本文件 — 精确任务清单 + 验收标准 | 3 分钟 |
| 3 | `zcritical/.kiro/session-handoff.md` 或 `firmware/zcritical-esp/.kiro/session-handoff.md` | 当前任务清单、已完成项、下一步 | 2 分钟 |

### 按角色找文件

| 角色 | 必读文件 | 选读文件 |
|------|---------|---------|
| **APP 开发** | `global-development-roadmap.md`<br>`development-blueprint.md`<br>`session-handoff.md` (APP端)<br>`protocol-contract.md` | `naming-conventions.md`<br>`anti-bloat.md`<br>`git-workflow.md` |
| **固件开发** | `global-development-roadmap.md`<br>`development-blueprint.md`<br>`session-handoff.md` (固件端)<br>`protocol-contract.md` | `firmware-reconstruction-blueprint.md`<br>`architecture.md` (固件端)<br>`naming-conventions.md` |
| **架构决策** | `protocol-contract.md`<br>`project-overview.md` | 所有 steering 文件 |
| **问题排查** | `troubleshooting.md` | `protocol-contract.md` |

---

## 八、技术决策记录

> 以下决策已确认，后续开发必须遵守。如需变更，必须更新此文件。

### 8.1 测试策略

| 决策 | 方案 | 理由 |
|------|------|------|
| 测试策略 | 关键逻辑单测 + 真机测试 | 投入产出比高，只测容易出错的地方 |
| 固件开发 | HAL Mock 层 | 不依赖硬件到位，业务逻辑可提前验证 |
| 批量烧录 | 工装烧录 + OTA 兜底 | 适合中等批量生产 |
| Logo 容错 | 超时 + CRC 重试 | 先简后繁，断点续传后续迭代 |
| OTA | ESP-IDF 原生 OTA + WiFi | 官方稳定方案 |
| 离线能力 | 缓存 + 只读模式 | 提升用户体验 |
| Panel 归属 | Phase 0 提前完成 | 不影响主流程 |

### 8.2 架构决策

| 决策 | 方案 | 理由 |
|------|------|------|
| APP 架构 | Clean Architecture + Provider | 分层清晰，易于测试和维护 |
| 固件架构 | core + modules 分层 | 职责分离，便于扩展 |
| 通信协议 | 自定义文本协议 over BLE | 简单、可读、易调试 |
| 状态管理 | 固件端全局状态结构体 | 统一状态源，避免分散 |
| 路由管理 | GoRouter Shell route | 支持复杂路由场景 |

### 8.3 规范决策

| 决策 | 方案 | 理由 |
|------|------|------|
| 单文件行数 | ≤350 行 | 防止文件膨胀，便于维护 |
| 代码注释 | STEER 块 + 职责声明 | 明确文件用途，防止原型变正式 |
| 分支策略 | feature 分支 + PR 合并 | 保证主干稳定 |
| 文档先行 | 设计契约 → 执行 → 验证 | 防止盲目开发 |

---

## 九、开发流程

### 标准开发循环

```
1. 读文档 (5-10分钟)
   ├─ global-development-roadmap.md → 知悉全局
   ├─ development-blueprint.md → 找对文件
   └─ session-handoff.md → 明确任务

2. 出设计契约 (5分钟)
   ├─ 确认当前阶段
   ├─ 列出任务清单
   └─ 等待用户确认

3. 执行 (逐文件)
   ├─ 写一个文件
   ├─ 编译验证
   ├─ 检查行数
   └─ 添加 STEER 块

4. 自检
   ├─ flutter analyze / idf.py build
   ├─ 文件行数检查
   ├─ STEER 块检查
   └─ import 方向检查

5. 交接
   ├─ 更新 session-handoff.md
   ├─ 输出完成报告
   └─ 明确下一步
```

### 禁止行为

| 禁止 | 原因 |
|------|------|
| 一次写多个文件 | 问题堆积，难以定位 |
| 跳过设计直接写代码 | 方向错误，返工成本高 |
| 行数超标不拆分 | 文件膨胀，维护困难 |
| 不更新文档就改代码 | 文档过时，后续对话迷失 |
| 跳阶段开发 | 依赖缺失，问题堆积 |

---

*创建日期: 2026-05-08*
*修订: 2026-05-08 (重新设计，精确到文件和数字)*
