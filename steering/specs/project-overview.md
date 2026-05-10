# ⚠️ 桌面级智能风洞 — 项目总览

> **优先级**: CRITICAL — 新对话第一份必读文件
> **作用域**: 全局 — 固件和 APP 端对话都从这里开始

> **用途**: 新 AI 会话或协作者加入时，一次性了解全貌。
> **更新**: 重大架构变更后更新。

---

## 一、产品定位

| 维度 | 说明 |
|------|------|
| **产品** | 桌面风洞模型（汽车风洞的 1:64 微缩版）|
| **品牌** | ZCritical / T1 |
| **目标用户** | 车模收藏爱好者、桌面摆件/潮玩玩家、STEM 科教 |
| **核心体验** | 把玩、展示、个性化——不是"工具"，是"玩具" |
| **App 角色** | 让用户驾驭风洞模型的精致控制终端 |
| **产品名** | **桌面级智能风洞** |

---

## 二、项目结构

```
Z-T1/
├── firmware/zcritical-esp/    ← ESP32-S3 固件 (C, ESP-IDF) — 白板重建
│   ├── main/
│   │   ├── core/              → 核心基础设施
│   │   │   ├── hal/           → 硬件抽象层 (LCD, LED, PWM, GPIO, 编码器, 音频)
│   │   │   ├── protocol/      → 通信协议 (BLE, 文本解析, 命令分发)
│   │   │   └── state/         → 全局状态 (拆为子结构体)
│   │   ├── modules/           → 功能模块 (可插拔)
│   │   │   ├── fan/           → 风扇 + 油门
│   │   │   ├── led/           → LED 预设 + 特效
│   │   │   ├── display/       → LCD UI 渲染
│   │   │   ├── audio/         → 引擎合成 + 播放
│   │   │   ├── encoder/       → 编码器事件
│   │   │   ├── logo/          → Logo 上传 + 存储
│   │   │   └── wifi/          → WiFi 音频流
│   │   ├── assets/            → 静态资源 (图片/字体/音频)
│   │   └── vendor/            → 第三方库 (minimp3)
│   ├── .kiro/steering/       → 固件专属 steering
│   └── tools/                → 构建/调试工具
│
├── zcritical/                ← Flutter APP (Dart, Clean Architecture) — 白板重建
│   ├── lib/
│   │   ├── core/             → Result<T>, DI, Router, Theme, Logger
│   │   ├── domain/           → Models, Repository 接口, UseCases
│   │   ├── data/             → Repository 实现, 数据源
│   │   └── presentation/     → Providers, Screens, Widgets
│   └── .kiro/steering/       → APP 专属 steering
│
├── reference/                ← 参考项目 (仅参考，不复用代码)
│   ├── RideWind/              → 旧 APP 项目
│   └── ridewind-esp/          → 旧固件项目
│
├── steering/                 ← 全局 steering (软硬件共享)
│   ├── project-overview.md
│   ├── protocol-contract.md
│   ├── git-workflow.md
│   └── naming-conventions.md
│
├── images/                   ← 产品图片
├── README.md
└── .gitignore
```

---

## 三、软硬件架构图

```
┌──────────────────────────────────────────────────────────┐
│                    ZCritical APP (Flutter)                 │
│  ┌────────┐  ┌──────────┐  ┌────────┐  ┌──────────┐    │
│  │  Pace  │  │ Running  │  │Colorize│  │   RGB    │    │
│  │ Panel  │  │  Panel   │  │ Panel  │  │  Panel   │    │
│  └───┬────┘  └────┬─────┘  └───┬────┘  └────┬─────┘    │
│      │            │            │            │            │
│      └────────────┴────────────┴────────────┘            │
│                         │                                 │
│                  ┌──────┴───────┐                         │
│                  │  BLE Service │                         │
│                  └──────┬───────┘                         │
├─────────────────────────┼────────────────────────────────┤
│                    BLE │                                  │
│           Service 0xFFE0│Char 0xFFE1                     │
├─────────────────────────┼────────────────────────────────┤
│                  ┌──────┴───────┐                         │
│                  │  BLE Service │  (ESP32-S3 固件)        │
│                  └──────┬───────┘                         │
│                         │                                 │
│      ┌──────────────────┼──────────────────┐             │
│      │                  │                  │             │
│  ┌───┴───┐        ┌─────┴─────┐      ┌───┴────┐        │
│  │ 风扇  │        │ LED灯带   │      │ 加湿器 │        │
│  │  PWM  │        │ WS2812B  │      │  GPIO  │        │
│  └───────┘        └───────────┘      └────────┘        │
│                                                         │
│  ┌───────┐  ┌───────┐  ┌───────┐  ┌────────────┐      │
│  │  LCD  │  │ 音频  │  │编码器 │  │   WiFi/TCP  │      │
│  │GC9A01 │  │I2S AMP│  │ EC11  │  │ 音频投射   │      │
│  └───────┘  └───────┘  └───────┘  └────────────┘      │
└──────────────────────────────────────────────────────────┘
```

---

## 四、核心约束

### 不可变

| 项 | 说明 |
|----|------|
| BLE UUID | Service 0xFFE0, Char 0xFFE1, 设备名 "T1" |
| Logo 格式 | 240×240 RGB565, 115200 字节 |
| CRC32 | 多项式 0xEDB88320 |
| LED 预设 | 14 种，两端对齐 |
| 协议格式 | 文本协议 `\n` 结尾 |

### 设计约束

| 项 | 说明 |
|----|------|
| APP 背景 | 纯黑 (#000000) |
| UI 绘制 | 所有 UI 用代码绘制，不依赖图片 |
| 每文件 | ≤350 行 (APP), ≤400 行 (固件) |
| 契约驱动 | 写代码前先输出设计契约确认 |

---

## 五、当前状态

> **注意**: 精确的当前阶段和任务清单以各端 `session-handoff.md` 为准。
> `reference/ridewind-esp` = 旧固件（功能已完成但历史遗留问题多，仅作参考）。
> `firmware/zcritical-esp` = 新固件（白板重建）。

### APP 端 (ZCritical)
- [x] 项目初始化 (Clean Architecture 骨架)
- [x] Pace Panel
- [x] Running Panel
- [x] Colorize Panel
- [x] RGB Panel
- [x] HomePageView (4 面板滑动)
- [x] A1: 应用入口 (路由+Splash+Onboarding+HomeShell+Drawer) — ✅ 2026-05-10
- [ ] A2: 用户中心 / Logo管理
- [ ] A3: BLE 连接层
- [ ] 协议层

### 固件端 (zcritical-esp, 白板重建)
- [ ] B0: 可编译空壳 — 待开始
- [ ] B1: HAL 驱动 (LCD/LED/Encoder/Fan/Humidifier/Audio) — 待开始
- [ ] B2: BLE 协议层 — 待开始
- [ ] B3: 功能模块 — 待开始

> `reference/ridewind-esp`（旧固件）已有完整功能实现，仅作硬件参数和协议格式参考。

---

## 六、文档索引（唯一入口）

> **说明**: 本章是整个项目文档体系的"目录"。所有文档在此注册。
> **分类文件夹**: `specs/` 规范 | `roadmap/` 路线图 | `guides/` 操作指南 | `knowledge/` 参考知识 | `archived/` 已归档

### 6.1 全局 steering（`steering/`）

```
steering/
├── specs/           ← 规范（不可变事实，唯一真值源）
│   ├── project-overview.md           ← 📋 文档治理中心
│   ├── hardware-config.md            ← 🔧 硬件参数唯一真值源
│   ├── protocol-contract.md          ← 📡 协议唯一真值源
│   └── ui-design-tokens.md           ← 🎨 UI 设计令牌
│
├── roadmap/         ← 路线图（阶段规划）
│   └── global-development-roadmap.md ← 🗺️ 全局开发路线图
│
├── guides/          ← 操作指南（如何做事）
│   ├── ai-proactive-guidance.md      ← 🤖 AI 行为规范
│   ├── multi-session-collaboration.md ← 👥 多会话协作协议
│   ├── naming-conventions.md         ← 🏷️ 软硬件统一命名
│   ├── git-workflow.md               ← 🌿 Git 工作流
│   ├── ux-guidelines.md              ← 📐 UX 指南
│   └── ui-review-checklist.md        ← ✅ UI 评审清单
│
├── knowledge/       ← 参考知识（累积型）
│   ├── known-pitfalls.md             ← ⚠️ 已知陷阱
│   └── troubleshooting.md            ← 🩺 问题排查手册
│
└── archived/        ← 📦 已归档（历史参考）
    ├── product-context.md
    ├── ai-onboarding.md
    ├── engineering-rhythm.md
    ├── development-blueprint.md
    └── firmware-reconstruction-blueprint.md
```

### 6.2 APP 端 steering（`zcritical/.kiro/steering/`）

```
zcritical/.kiro/steering/
├── specs/           ← 规范
│   └── architecture-map.md           ← APP 架构全景图
│
├── roadmap/         ← 路线图
│   ├── reconstruction-blueprint.md   ← APP 白板重建蓝图
│   ├── migration-map.md              ← 迁移地图
│   └── technical-strategy.md         ← 技术策略
│
├── guides/          ← 操作指南
│   ├── START-HERE.md                 ← 📋 APP 端文档索引入口（分层加载策略）
│   ├── anti-bloat.md                 ← 防臃肿纲领
│   ├── contract-driven-collaboration.md ← 契约驱动协作
│   ├── conventions.md                ← 开发约定
│   ├── development-workflow.md       ← 开发流程
│   ├── engineering-process.md        ← 工程管理流程
│   ├── engineering-standards.md      ← 工程标准
│   ├── senior-dev-role.md            ← AI 资深开发者角色
│   ├── ai-collaboration.md           ← AI 协作规范
│   ├── ux-principles.md              ← UX 原则
│   └── communication-template.md     ← 沟通模板
│
├── knowledge/       ← 参考知识
│   ├── technical-risks.md            ← 技术风险
│   └── ai-efficiency-log.md          ← AI 效率日志
│
└── context-quickref.md              ← ⚡ 5秒速查卡（轻量级对话用）
│
└── archived/        ← 📦 已归档
    └── protocol-contract.md          ← 协议（引用全局唯一源）
```

### 6.3 固件端 steering（`firmware/zcritical-esp/.kiro/steering/`）

```
firmware/zcritical-esp/.kiro/steering/
├── specs/           ← 规范
│   ├── architecture.md               ← 固件架构 + 引脚配置
│   └── coding-standards-c.md         ← C 编码规范
│
├── guides/          ← 操作指南
│   ├── anti-bloat.md                 ← 防臃肿纲领
│   └── firmware-workflow.md          ← 固件开发流程
│
└── knowledge/       ← 参考知识
    └── technical-debt.md             ← 技术债务 + 21个修复清单
```

### 6.4 状态快照（Session Handoff）

| # | 文件 | 用途 |
|---|------|------|
| 1 | `zcritical/.kiro/session-handoff.md` | APP 端当前阶段 (A1)、任务清单、验证标准 |
| 2 | `firmware/zcritical-esp/.kiro/session-handoff.md` | 固件端当前阶段 (B1)、硬件参数表、任务清单 |

### 6.5 参考项目文档（`reference/`）

> 📋 矿藏地图: `reference/README.md` — 标注了所有有价值的设计参考及其对标新项目位置

| # | 目录 | 用途 |
|---|------|------|
| 1 | `reference/RideWind/` | 旧 APP — BLE 协议/Logo 上传/UI 设计/音频流 的设计参考 |
| 2 | `reference/ridewind-esp/` | 旧固件 — HAL 驱动/UI 状态机/音频引擎/配置参数 的设计参考 |
| 3 | `reference/README.md` | 📋 矿藏地图 — 按功能索引到具体参考文件 |

### 6.6 Agent Hooks — 自动执法（`.kiro/hooks/`）

> 📌 这些 hooks 将 steering 文档中的软规则变成硬约束。
> 类型: 自动化配置 | 维护者: AI | 废弃条件: Kiro 不再支持 hooks 时

| # | Hook | 触发 | 对应的规则来源 |
|---|------|------|--------------|
| 1 | `session-handoff-enforcer` | agentStop | multi-session §七, conversation-lessons #5 #13 |
| 2 | `protocol-contract-guardian` | fileEdited: protocol-contract.md | multi-session 铁律1, conversation-lessons #1 |
| 3 | `architecture-boundary-guard` | preToolUse(write) | anti-bloat 防线2, global-roadmap §五, contract-driven 铁律0 |
| 4 | `new-session-bootstrap` | promptSubmit | START-HERE, conversation-lessons #5 #13, senior-dev-role |
| 5 | `git-branch-isolation` | preToolUse(write) | conversation-lessons #7 #8 #9, git-workflow |
| 6 | `steering-doc-registration` | fileCreated: steering/*.md | conversation-lessons #14 #6, project-overview §八 |
| 7 | `ui-acceptance-checklist` | preToolUse(write) | ui-review-checklist, ux-guidelines, known-pitfalls #12 #13 |

### 6.6b Kiro Steering 核心宪法（`.kiro/steering/`）

> 📌 `inclusion: auto` — Kiro 每次对话自动注入

| # | 文件 | 用途 | 提炼自 |
|---|------|------|--------|
| 1 | `ai-role-charter.md` | AI 身份+职责+行为边界+对话模板 | ai-proactive, senior-dev-role, multi-session, conv-lessons #15 #16 #18 |
| 2 | `git-safety-charter.md` | 分支开发测试、主干圣洁、文档同步 | git-workflow, conv-lessons #7 #8 #9 |

### 6.6c Kiro Skills — 可复用开发技能（`.kiro/skills/`）

> 📌 Skills 封装高频开发领域的全栈知识和规范，AI 可随时激活

| # | Skill | 用途 | 提炼自 |
|---|-------|------|--------|
| 1 | `flutter-app-dev` | Flutter Clean Architecture 全栈开发：架构边界/命名/编码模板/设计令牌/禁止行为 | anti-bloat, conventions, ui-design-tokens, contract-driven, engineering-standards |
| 2 | `esp32-firmware-dev` | ESP32 固件开发：HAL模板/编码标准/硬件参数/已知陷阱/白板铁律 | architecture(固件), coding-standards-c, known-pitfalls, hardware-config, firmware-workflow |

### 6.7 Kiro SPECs — 结构化任务（`.kiro/specs/`）

> 📌 将 session-handoff.md 中的任务拆为可追踪的 task，Kiro 可逐步引导。
> 类型: 结构化任务 | 维护者: AI

| # | Spec | 任务数 | 内容 |
|---|------|--------|------|
| 1 | `app-phase1-a1-detailed.yml` | 6 tasks (全部done, 6/6) ✅ | APP A1 完整入口: 路由扩展→入口流→Splash→Onboarding→HomeShell→Drawer |
| 2 | `firmware-phase2-b1-detailed.yml` | 10 tasks (4 done + 6 todo, 4/10) | 固件 B1 HAL: GPIO✅→Encoder✅→LCD⏳→LED⏳→Fan⏳→Audio⏳→Humidifier⏳ |
| 3 | `architecture-decisions.yml` | 11 tasks (3 done + 8 todo, 3/11) | 架构决策: DR-001✅→DR-002✅→DR-003✅→DR-004~011⏳ |

---

## 七、文档冲突记录

> **规则**: 当发现两份文档对同一事实有矛盾说法时，记录在此。AI 遇到冲突必须停止执行并询问。

| # | 冲突描述 | 文件A | 内容A | 文件B | 内容B | 已确认权威源 |
|---|---------|-------|-------|-------|-------|------------|
| 1 | 产品名不一致 | `product-context.md` | "RideWind" | `project-overview.md` | "ZCritical / T1" | ✅ ZCritical (2026-05-09) |
| 2 | LED 灯珠数量/引脚 | `product-context.md` + `hardware-config.md` | 6颗 GPIO18 (旧) | `session-handoff.md` (固件) | 10+3颗 (旧) | ✅ LED1(IO41)6颗 + LED2(IO16)3颗 (2026-05-09) |
| 3 | 风扇引脚 | `product-context.md` + `hardware-config.md` | GPIO17/18/19 (旧) | `session-handoff.md` (固件) | IO40 (旧) | ✅ IO40, MOS管 CH2 (2026-05-09) |
| 4 | 编码器引脚 | `product-context.md` + `hardware-config.md` | GPIO4/5 或 GPIO21/22/23 (旧) | `session-handoff.md` (固件) | IO17/18/8 (旧) | ✅ S1(IO17), S2(IO18), KEY(IO8) (2026-05-09) |
| 5 | 固件完成状态 | `project-overview.md` 第五节 | 固件全部✅ (旧) | `global-development-roadmap.md` + `session-handoff.md` | Phase 2 B1 HAL 待开始，白板重建 | ✅ 白板重建，B1待开始 (2026-05-09) |
| 6 | LCD SPI 引脚 | `hardware-config.md` | GPIO11-16 (旧) | `session-handoff.md` (固件) | IO4-7 (旧) | ✅ CS(IO4), DC(IO5), SDA(IO6), SCL(IO7) (2026-05-09) |
| 7 | 音频引脚 | `hardware-config.md` | GPIO25-27 (旧) | `session-handoff.md` (固件) | IO11-13 (旧) | ✅ DIN(IO13), BCLK(IO12), LRC(IO11), MAX98357 (2026-05-09) |

---

## 八、文档创建协议

**任何新 steering 文件必须满足以下所有条件：**

1. **内容不能被现有文件涵盖** → 否则更新现有文件，不新建
2. **必须在本文件的"文档索引"中注册** → 未注册 = 无效文档
3. **必须声明类型** → 规范 / 路线图 / 操作指南 / 状态快照 / 参考知识
4. **必须声明维护者** → 你 or AI
5. **必须声明废弃条件** → 什么情况下这个文件应该被归档或删除
6. **文件名必须反映内容** → 禁止模糊命名

**文件归档流程：**
- 在文件头部添加：`> ⚠️ 本文件已归档（日期）。核心规则已迁移至 [新文件]。本文件保留作为历史参考，不再作为权威源。`
- 在本索引中更新状态为 📦归档
- **原始文件不删除**，保留作为历史参考

---

## 九、文档维护周期

| 类型 | 更新时机 | 更新者 | 验证方式 |
|------|---------|--------|---------|
| 规范 | 你正式决策后 | AI 执行更新 | 你确认 |
| 路线图 | 阶段完成后 | AI 执行更新 | 你确认 |
| 操作指南 | 发现规则不适用时 | 你或 AI 提议 | 你确认 |
| 状态快照 | 每次对话结束 | AI 自动更新 | 你验收 |
| 参考知识 | 发现新坑/新修复时 | AI 追加 | 你确认 |

---

## 十、AI 行为硬约束

> 以下不是建议，AI 必须执行：

| # | 规则 |
|---|------|
| 1 | 发现文档冲突 → 必须停止执行，列出冲突点，问你确认 |
| 2 | 发现文档过时 → 必须提醒你更新，不能忽略 |
| 3 | 发现需求不符合当前阶段 → 必须指出并拉回，不能顺应 |
| 4 | 每次对话结束 → 必须更新 session-handoff.md |
| 5 | 每次修改文件 → 必须检查行数，不能超标 |
| 6 | 协议变更 → 必须先改 protocol-contract.md，再改代码 |
| 7 | 硬件参数变更 → 必须先改 hardware-config.md，再改代码 |

---

*创建日期: 2026-05-08 | 修订: 2026-05-10（文档索引重建、7个冲突全部确认并修正、硬件参数全面校正为实际 PCB 配置、anti-bloat 行数改革、START-HERE 分层加载、context-quickref 速查卡）*
