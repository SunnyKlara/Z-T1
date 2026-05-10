# AI 启动时必须读取的文件清单

> 优先级: CRITICAL - 新对话 AI 第一份必读文件
> 作用域: APP端 - 所有 zcritical/ 相关对话都从这里开始

## 规则

新对话 AI 必须在开始任何工作前，先判断对话类型，再按对应策略读取文件。

## 第一步：判断对话类型

| 对话类型 | 触发词/场景 | 读取策略 | Token 消耗 |
|---------|------------|---------|-----------|
| 继续开发 | "继续"、"下一步"、"接着做" | 只读 context-quickref.md | ~500 |
| 修 bug | "报错"、"不工作"、"崩溃" | quickref + 相关报错文件 | ~1K |
| 新任务 | "实现"、"做"、"新建" | 读 session-handoff.md | ~3K |
| 方案讨论 | "怎么"、"方案"、"讨论" | session-handoff + 相关 DR | ~5K |
| 全新启动 | 无 session-handoff | 完整 1-3 层（见下方） | ~15K |

**判断方法**：
1. 先检查 `.kiro/session-handoff.md` 是否存在
2. 存在 → 根据用户首句判断类型，按上表读取
3. 不存在 → 按"全新启动"策略执行

## 第二步：按类型读取

### 类型 A：继续开发（最轻量）

```
1. zcritical/.kiro/context-quickref.md  ← 5秒速查卡
2. 直接开始工作
```

### 类型 B：修 bug

```
1. zcritical/.kiro/context-quickref.md  ← 5秒速查卡
2. 用户提到的报错文件
3. zcritical/.kiro/steering/guides/anti-bloat.md  ← 防臃肿约束
```

### 类型 C：新任务

```
1. zcritical/.kiro/session-handoff.md  ← 完整上下文
2. zcritical/.kiro/steering/guides/anti-bloat.md  ← 防臃肿约束
3. 相关架构文档（按需）
```

### 类型 D：方案讨论

```
1. zcritical/.kiro/session-handoff.md  ← 完整上下文
2. steering/decisions/README.md  ← 已决策方案
3. 相关 DR 文档（按需）
```

### 类型 E：全新启动（完整加载）

> 仅在首次对话或 session-handoff.md 不存在时执行

#### 第 1 层: 全局文档（steering/）

```
1. steering/roadmap/development-rhythm.md
   知道当前在四圈中哪一圈

2. steering/specs/project-overview.md
   知道整个文档索引在哪里、有什么规范

3. steering/specs/hardware-config.md
   知道硬件参数（不可变）

4. steering/specs/protocol-contract.md
   知道 BLE 协议格式

5. steering/specs/ui-design-tokens.md
   知道设计令牌

6. steering/specs/product-requirements-audit.md
   知道缺失功能和优先级
```

#### 第 2 层: 领域文档

```
7. zcritical/.kiro/session-handoff.md
   知道当前阶段和任务清单

8. zcritical/.kiro/steering/specs/architecture-map.md
   知道 APP 架构

9. zcritical/.kiro/steering/guides/anti-bloat.md
   知道防臃肿约束
```

#### 第 3 层: 技术决策

```
10. steering/decisions/README.md
    知道有哪些已决策的方案

11. 按需读对应 DR 文档 (DR-001~DR-003 等)
    知道每个方案为什么这么选
```

## 读取顺序有讲究

1. 先判断对话类型 → 决定读多少
2. 再读速查卡或 session-handoff → 建立上下文
3. 最后按需读专项文档 → 深入细节

这个策略是为了让 AI 根据场景智能加载，避免每次新对话都读 15K token 的完整文档。

## 禁止行为

| 禁止 | 原因 |
|------|------|
| 跳过对话类型判断 | 会导致不必要的 token 消耗 |
| 全新启动时跳过文件 | 每份文件都可能包含新对话必需的信息 |
| 只看标题不读内容 | 关键决策细节在正文中 |
| 读了一半就开始写代码 | 信息不完整 → 决策可能和已确认方案冲突 |
| 不看 DR 直接提替代方案 | 替代方案可能已经被讨论并否决过 |

## 硬事实（不可重复询问）

**以下事实已经确认，AI 禁止再问。用户没有耐心重复回答。**

| 事实 | 来源 |
|------|------|
| 用户有 ESP32-S3 开发板在手边，随时可以烧录测试 | 用户确认 |
| 实机测试不是瓶颈，代码写好后用户会自行验证 | 用户确认 |
| 不需要每次问"你有没有硬件"或"能不能实机测" | 用户确认 |
| 同一时间只开发一端（APP 或固件），不需要并行 | 用户确认 |
| 开发 APP 时切到 app/ 分支，开发固件时切到 firmware/ 分支 | Git工作流 |
