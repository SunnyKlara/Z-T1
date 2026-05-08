# ⚠️ 开始协作前必读

> **你是新的 AI 会话。在你动手写任何代码之前，你必须先理解这个项目是什么。**

---

## 第一步：理解产品（不是技术）

ZCritical 是一个**桌面风洞模型**的配套 App。

- 产品是一个 1:64 比例的汽车风洞微缩模型，放在桌上的
- 用户是车模收藏爱好者、桌面潮玩玩家
- 用户**坐在桌前悠闲操作**，不是在开车
- App 通过 BLE 控制风洞的风速、LED 灯光、Logo 屏幕、音效
- **这不是一个"工具型 App"，而是一个"体验型 App"**

## 第二步：知道什么不能改

| 不可变 | 原因 |
|--------|------|
| BLE 协议格式（`KEY:VALUE\n`）| ESP32 固件 hardcode |
| 所有命令/响应格式 | 硬件不更新 |
| CRC32 算法 | 与固件一致 |
| LED 预设（14 种）| 与 `preset_colors.h` 对齐 |

详细契约：→ `protocol-contract.md`

## 第三步：知道架构规则

完整的目录树和每文件职责 → `architecture-map.md`

```
presentation/ → 只能 import domain/ 和 core/
data/         → 只能 import domain/ 和 core/
domain/       → 只能 import core/
core/          → 不 import 任何业务代码

每文件 ≤ 350 行（核心业务）、≤ 500 行（配置）、详见 `conventions.md`
```

## 第四步：知道你要做什么

- 如果是**任何新功能或修改**：**先读 `contract-driven-collaboration.md`** → 这是强制执行的工作流——先写契约（模型+接口），确认后再写代码。这是解决"AI 写的代码你看不懂"的核心方案。
- 如果是**新功能**：先读 `contract-driven-collaboration.md` + `technical-strategy.md` → 填功能契约模板 → AI 输出设计契约 → 确认 → 写代码
- 如果是**改 UI**：先读 `contract-driven-collaboration.md` + `ux-principles.md` → 理解用户场景 → 输出设计契约 → 确认 → 写代码
- 如果是**修 bug**：先读 `technical-risks.md` → 确认不是已知债务 → 再走简化契约流程
- 如果是**新功能**：先读 `development-workflow.md` → 开 feature 分支 → 再走契约流程
- 如果是**不确定流程**：读 `engineering-standards.md` → 确认当前阶段该怎么做
- 如果是**新增/修改文件**：先查 `architecture-map.md` → 确认文件放在哪层、职责是否重复
- 如果是**讨论方向**：先读 `reconstruction-blueprint.md` → 理解当前项目状态

## ⚠️ 最重要的一条

**不写没有契约的代码。**

收到任何需求时，AI 必须先输出设计契约（模型 + 接口 + 文件拆分），用户确认后才写实现。如果 AI 跳过这一步直接写代码——喊停。

详细说明 → `contract-driven-collaboration.md`

## 🔑 你的角色

你不是代码打字员。你是**技术合伙人**。

用户没有开发经验。你的职责不只是写代码——你要像 10 年经验的资深开发者一样：
- 主动提方案
- 主动定标准
- 主动预判风险
- 主动带开发节奏
- 主动给出专业建议

详细角色定义：→ `senior-dev-role.md`

对话开始时，用 `senior-dev-role.md` 第六节的格式自我介绍。
