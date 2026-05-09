# ⚠️ ZCritical APP — 开发入口

> **你是新的 AI 会话。动手写代码前，先理解项目和找到正确的文档。**

---

## 第一步：理解产品（不是技术）

ZCritical 是一个**桌面风洞模型**的配套 App。

- 产品是一个 1:64 比例的汽车风洞微缩模型，放在桌上的
- 用户是车模收藏爱好者、桌面潮玩玩家
- 用户**坐在桌前悠闲操作**，不是在开车
- App 通过 BLE 控制风洞的风速、LED 灯光、Logo 屏幕、音效
- **这不是一个"工具型 App"，而是一个"体验型 App"**

---

## 第二步：APP 端文档索引

> 本索引是 APP 端所有 steering 文档的唯一目录。新文档必须先在此注册。

### 活跃文档

| # | 文件 | 类型 | 维护者 | 主要内容 |
|---|------|------|--------|---------|
| 1 | `START-HERE.md` | 操作指南 | 你 | **本文件** — APP 端文档索引入口 |
| 2 | `anti-bloat.md` | 操作指南 | 你 | 七道防线、行数约束、原型退出机制、臃肿预警 |
| 3 | `reconstruction-blueprint.md` | 路线图 | 你 | APP 白板重建蓝图、不可变核心、已知技术债务、实施阶段 |
| 4 | `architecture-map.md` | 规范 | 你 | 架构全景图、每层职责、Import 方向规则、文件统计 |
| 5 | `contract-driven-collaboration.md` | 操作指南 | 你 | 三层契约模式（功能契约→设计契约→实现） |
| 6 | `conventions.md` | 操作指南 | 你 | APP 开发约定 |
| 7 | `development-workflow.md` | 操作指南 | 你 | Git 分支策略、开发流程 |
| 8 | `engineering-process.md` | 操作指南 | 你 | 从需求到上线的 6 阶段完整流程 |
| 9 | `engineering-standards.md` | 操作指南 | 你 | 工程标准 |
| 10 | `migration-map.md` | 路线图 | 你 | 迁移地图 |
| 11 | `senior-dev-role.md` | 操作指南 | 你 | AI 作为资深开发者的角色定义 |
| 12 | `technical-risks.md` | 参考知识 | 你+AI | 技术风险登记 |
| 13 | `technical-strategy.md` | 路线图 | 你 | 技术策略 |
| 14 | `ux-principles.md` | 操作指南 | 你 | UX 原则、用户场景、设计哲学 |
| 15 | `ai-collaboration.md` | 操作指南 | 你 | AI 协作规范 |
| 16 | `ai-efficiency-log.md` | 参考知识 | AI | AI 效率日志（累积型） |
| 17 | `communication-template.md` | 操作指南 | 你 | 沟通模板 |

### 已归档（`archived/`）

| # | 文件 | 归档原因 | 权威源 |
|---|------|---------|--------|
| 1 | `archived/protocol-contract.md` | 与全局 `steering/protocol-contract.md` 内容重叠，全局版本是唯一真值源 | `steering/protocol-contract.md` |

### 全局文档（引用，不复制）

| 你需要什么 | 在哪 |
|-----------|------|
| 硬件引脚参数 | `steering/hardware-config.md` |
| BLE 协议命令表 | `steering/protocol-contract.md` |
| 全局开发阶段 | `steering/global-development-roadmap.md` |
| 当前任务 + 进度 | `zcritical/.kiro/session-handoff.md` |
| AI 行为规范 | `steering/ai-proactive-guidance.md` |
| 软硬件命名约定 | `steering/naming-conventions.md` |
| 文档治理中心 | `steering/project-overview.md` |

---

## 第三步：知道架构规则

完整的目录树和每文件职责 → `architecture-map.md`

```
presentation/ → 只能 import domain/ 和 core/
data/         → 只能 import domain/ 和 core/
domain/       → 只能 import core/
core/          → 不 import 任何业务代码

每文件 ≤ 350 行（核心业务）、≤ 500 行（配置）
详见 `conventions.md` + `anti-bloat.md`
```

---

## 第四步：知道你要做什么

| 场景 | 先读 |
|------|------|
| 新功能或修改 | `contract-driven-collaboration.md` — 先契约后代码 |
| 改 UI | `contract-driven-collaboration.md` + `ux-principles.md` |
| 修 bug | `technical-risks.md` — 确认不是已知债务 |
| 新增/修改文件 | `architecture-map.md` — 确认文件放哪层 |
| 不确定流程 | `engineering-standards.md` |
| 新对话开始 | 本文件 + `session-handoff.md` |
| 协议问题 | `steering/protocol-contract.md`（全局唯一源） |
| 硬件参数 | `steering/hardware-config.md`（全局唯一源） |

---

## ⚠️ 最重要的一条

**不写没有契约的代码。**

收到任何需求时，AI 必须先输出设计契约（模型 + 接口 + 文件拆分），确认后再写实现。
详细说明 → `contract-driven-collaboration.md`

---

## 🔑 你的角色

你不是代码打字员。你是**技术合伙人**。详见 `senior-dev-role.md` + `steering/ai-proactive-guidance.md`。

---

*修订: 2026-05-09（增加文档索引、归档 protocol-contract）*
