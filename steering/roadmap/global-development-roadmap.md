# ⚠️ Z-T1 全局开发路线图

> **优先级**: CRITICAL — 所有对话的出发点和参照系
> **用途**: 定义软硬件两端的完整开发节奏、架构方案、协作流程、规范标准。
>             新对话启动 → 读此文件 → 知悉全局 → 对号入座。
> **创建**: 2026-05-08 | **会议**: 架构深入讨论第 34 轮对话
> **施工图**: `steering/development-blueprint.md` — 每个阶段的精确任务、产出物、依赖、验收标准

---

## 一、产品与项目总览

| 维度 | 说明 |
|------|------|
| **产品** | 桌面级智能风洞 |
| **品牌** | ZCritical / T1 |
| **硬件** | ESP32-S3 + GC9A01 LCD + WS2812B LED + EC11 编码器 + 风扇 + 加湿器 |
| **软件** | Flutter APP (Dart) + ESP32 固件 (C/ESP-IDF) |
| **策略** | 软硬件两端白板重建，不复用旧代码 |

---

## 二、项目结构

```
Z-T1/
├── firmware/zcritical-esp/    ← 新固件 (白板重建)
│   ├── main/
│   │   ├── core/              — 核心基础设施
│   │   │   ├── hal/           — 6个硬件驱动
│   │   │   ├── protocol/      — BLE + 协议解析 + 命令分发
│   │   │   └── state/         — 全局状态 (子结构体)
│   │   ├── modules/           — 7个功能模块
│   │   │   ├── fan/  led/  display/  audio/
│   │   │   ├── encoder/  logo/  wifi/
│   │   ├── assets/            — 静态资源
│   │   └── vendor/            — 第三方库
│   └── .kiro/steering/       — 固件专属 steering
│
├── zcritical/                ← 新 APP (白板重建, Clean Architecture)
│   ├── lib/
│   │   ├── core/             — Result<T>, DI, Router, Theme
│   │   ├── domain/           — Models, Repository接口, UseCases
│   │   ├── data/             — Repository实现, 数据源
│   │   └── presentation/     — Providers, Screens, Widgets
│   └── .kiro/steering/       — APP 专属 steering
│
├── reference/                ← 参考项目 (不复用代码)
│   ├── RideWind/              — 旧 APP
│   └── ridewind-esp/          — 旧固件
│
├── steering/                 ← 全局 steering (软硬件共享)
│   ├── project-overview.md           — 项目总览
│   ├── protocol-contract.md          — 软硬件接口契约
│   ├── global-development-roadmap.md — 本文件
│   ├── firmware-reconstruction-blueprint.md — 固件端重建蓝图
│   ├── multi-session-collaboration.md — 多会话协作协议
│   ├── naming-conventions.md         — 统一命名约定
│   └── git-workflow.md               — Git 工作流
│
└── README.md
```

---

## 三、全局开发阶段

```
═══════════════════════════════════════════════════════════════
  第一阶段：基础设施 (当前已完成 ✅)
═══════════════════════════════════════════════════════════════

  ✅ 全局 steering 体系 (11个文件)
  ✅ APP 端 steering (18个文件)
  ✅ 固件端 steering (5个文件)
  ✅ 多会话协作协议
  ✅ 代码内嵌约束 (STEER 块)
  ✅ APP 4个 Panel (Pace/Running/Colorize/RGB)
  ✅ 固件项目骨架 (core+modules 目录)
  ✅ 参考项目归档 (reference/RideWind + reference/ridewind-esp)


═══════════════════════════════════════════════════════════════
  第二阶段：骨架填充 (详细规划见 steering/development-blueprint.md)
═══════════════════════════════════════════════════════════════

  Phase 1: APP 骨架 (✅ A1 已完成)
    A1: 应用入口 (Splash + Onboarding + HomeShell + Drawer) ✅ 2026-05-10
        产出: 6文件 (app_router.dart, app.dart, splash_screen.dart, onboarding_screen.dart, home_shell.dart, drawer_widget.dart)
        验收: flutter analyze 零错误 + 路由正确 + Navigator→GoRouter迁移完成
    A2: 用户中心 (UserCenter + LogoManagement) 📍 下一阶段
        产出: 2新文件 | 验收: 可从 Drawer 导航进入 + 界面完整
    A3: BLE 连接层 (BLE Provider + 连接状态管理)
        产出: 3新文件 + 1修改文件 | 验收: 可扫描 + 可连接 + 状态同步

  Phase 2: 固件骨架
    B1: HAL 驱动 (6个: LCD / LED / Encoder / Fan / Humidifier / Audio)
        产出: 6驱动文件 + 头文件 | 验收: idf.py build 通过 + 烧录可工作
    B2: BLE 协议层 (GATT + 命令解析 + 状态机)
        产出: 3文件 | 验收: idf.py build 通过 + 可解析 BLE 命令
    B3: 功能模块 (7个: fan / led / display / audio / encoder / logo / wifi)
        产出: 7模块文件 | 验收: idf.py build 通过 + 各模块可独立工作


═══════════════════════════════════════════════════════════════
  第三阶段：核心功能 (详细规划见 steering/development-blueprint.md)
═══════════════════════════════════════════════════════════════

  Phase 3: APP 核心功能
    C1: BLE 协议实现 (命令发送 + 响应解析 + 状态同步)
    C2: 面板数据绑定 (4个 Panel 连接真实数据)
    C3: 状态管理 (Provider 层 + 离线缓存)

  Phase 4: 固件核心功能
    D1: 协议完整实现 (所有命令 + 响应 + 上报)
    D2: Logo 上传 (PSRAM 缓冲 + CRC32 + LittleFS)
    D3: WiFi 模块 (OTA 基础 + 网络状态)

  Phase 5: 联调测试
    E1: 软硬件联调 (端到端测试)
    E2: 性能优化 + 稳定性

```

---

## 四、架构决策记录（本次对话确认的）

| 决策 | 内容 | 确认日期 |
|------|------|---------|
| **APP 整体架构** | HomeShell (GoRouter Shell) + PageView面板 + 抽屉 + 用户中心 | 2026-05-08 |
| **APP 入口流** | Splash → Onboarding(3页) → HomeShell | 2026-05-08 |
| **APP 页面布局** | 顶部风洞视图 + 下半部PageView(4面板) + 右上☰抽屉 | 2026-05-08 |
| **APP 抽屉内容** | 极简: 用户中心 + Logo管理。其他塞用户中心 | 2026-05-08 |
| **APP 用户中心** | 分区标题 + icon tile 列表 (参考 RideWind settings_screen) | 2026-05-08 |
| **APP 无设备状态** | 顶部 BLE连接Banner, 不做独立NoDeviceScreen | 2026-05-08 |
| **固件架构方案** | core + modules 双区架构 (方案D) | 2026-05-08 |
| **固件策略** | 白板重建，零行搬运 | 2026-05-08 |
| **固件 state** | AppState 拆为子结构体 (fan_state, led_state, ui_state, audio_state) | 2026-05-08 |
| **多会话协作** | 工作范围声明 + STEER硬约束 + session-handoff + 合规检查报告 | 2026-05-08 |
| **协议管理** | protocol-contract.md 是唯一真值源 | 2026-05-08 |
| **开发节奏** | 先硬后软基底，两端并行填充 | 2026-05-08 |

---

## 五、两端规范对标

| 规范项 | APP 端 (Dart) | 固件端 (C) |
|--------|--------------|-----------|
| **文件行数上限** | 350行(业务) / 500行(配置) | 300行(HAL) / 400行(modules) / 150行(main.c) |
| **架构模式** | Clean Architecture (core/domain/data/presentation) | core + modules 双区 |
| **状态管理** | Riverpod Provider | app_state_t (子结构体) |
| **路由** | GoRouter | ui_manager (UI 状态机) |
| **依赖方向** | presentation→domain→core | modules→core/state→core/hal |
| **禁止依赖** | presentation 不 import data | hal 不 depend modules |
| **编码风格** | Dart: snake_case文件, CamelCase类 | C: 模块_动作(), s_静态, g_全局 |
| **文件头约束** | `// STEER: 反臃肿 \| max_lines=350` | `/* STEER: 反臃肿 \| max_lines=N */` |
| **编译验证** | `flutter analyze` 零错误 | `idf.py build` 通过 |
| **提交格式** | `feat(app): xxx` | `feat(fw): xxx` |
| **日志** | logger.i/w/e | ESP_LOGI/W/E(TAG, ...) |

---

## 六、AI 协作标准流程

### 每段对话必做的事

```
1. 启动 — AI 自动读取：
   ├── steering/global-development-roadmap.md (本文件)
   ├── 对应端的 session-handoff.md
   ├── 对应端的 steering 文件
   └── steering/protocol-contract.md

2. 执行 — 遵守约束：
   ├── 修改文件前检查 STEER 约束声明
   ├── 每文件写完后检查行数 ≤ 上限
   ├── 每步编译验证
   └── 协议变更先改 protocol-contract.md

3. 收尾 — 强制输出：
   ├── 合规检查报告 (行数表 + 架构边界 + 协议一致性)
   ├── 更新 session-handoff.md (完成什么 + 待做什么 + 下次从哪开始)
   └── 提交代码
```

### 合规检查报告模板

```
═══════════════════════════════════════════════════════════════
📋 合规检查报告

文件行数:
  [文件名]  [行数]/[上限]  [✅/❌]

架构边界:
  [x] hal/ 未 depend modules/
  [x] modules/ 之间未互相 depend
  [ ] ❌ 问题: [描述]

协议一致性:
  [x] BLE 命令格式与 protocol-contract.md 一致
  [x] LED 预设数量: 14

决策: [放行 / 需要修复后重新提交]
═══════════════════════════════════════════════════════════════
```

---

## 七、启动新对话的标准方式

### 固件端对话

```
详细查看 firmware/zcritical-esp 项目文件，为后续协助我开发做准备。
从阶段 [B0/B1/B2/B3/B4] 开始。
```

### APP 端对话

```
详细查看 zcritical 项目文件，为后续协助我开发做准备。
从阶段 [A1/A2/A3/A4/A5] 开始。
```

### 架构/协议讨论

```
详细查看 steering 目录下的文档。
讨论 [协议变更 / 架构决策 / xxx]。
```

---

## 八、硬约束清单（不可协商）

| # | 规则 | 适用范围 |
|---|------|---------|
| 1 | 协议变更必须先改 protocol-contract.md | 全局 |
| 2 | 文件行数 ≤ 上限 (350/300/400) | 全局 |
| 3 | 不从 reference 搬运代码 | 全局 |
| 4 | 跨域不 depend (hal不depend modules, 等) | 全局 |
| 5 | 每步编译验证 (flutter analyze / idf.py build) | 全局 |
| 6 | 对话结束更新 session-handoff | 全局 |
| 7 | 提交前输出合规检查报告 | 全局 |
| 8 | 一次提交只做一件事 | 全局 |
| 9 | 文件头必须有 STEER 约束块 | 全局 |
| 10 | 全局变量只能在 state/ 中定义 | 固件 |
| 11 | BLE 回调不能直接写 AppState | 固件 |
| 12 | Screen 不能 import BLE Service | APP |

---

## 九、快速参考

| 我想知道... | 读这个 |
|------------|--------|
| 项目全貌 | `steering/project-overview.md` |
| 开发节奏 | `steering/global-development-roadmap.md` (本文件) |
| 协议格式 | `steering/protocol-contract.md` |
| 多段对话怎么协作 | `steering/multi-session-collaboration.md` |
| 命名规则 | `steering/naming-conventions.md` |
| Git 怎么用 | `steering/git-workflow.md` |
| APP 架构 | `zcritical/.kiro/steering/reconstruction-blueprint.md` |
| APP 防臃肿 | `zcritical/.kiro/steering/anti-bloat.md` |
| APP 上次做到哪 | `zcritical/.kiro/session-handoff.md` |
| 固件架构 | `firmware/zcritical-esp/.kiro/steering/architecture.md` |
| 固件防臃肿 | `firmware/zcritical-esp/.kiro/steering/anti-bloat.md` |
| 固件上次做到哪 | `firmware/zcritical-esp/.kiro/session-handoff.md` |

---

*创建日期: 2026-05-08 | 这是本次 34 轮架构讨论的结晶*
