# AI 启动时必须读取的文件清单

> 优先级: CRITICAL - 新对话 AI 第一份必读文件
> 作用域: 全局 - 固件端和 APP 端对话都从这里开始

## 规则

新对话 AI 必须在开始任何工作前，按顺序读完以下全部文件。读不完就继续读，不允许跳跃。

## 必读清单（按顺序）

### 第 1 层: 全局文档（steering/）

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

### 第 2 层: 领域文档

**如果是 APP 端对话**:
```
7. zcritical/.kiro/session-handoff.md
   知道当前阶段和任务清单

8. zcritical/.kiro/steering/specs/architecture-map.md
   知道 APP 架构

9. zcritical/.kiro/steering/guides/anti-bloat.md
   知道防臃肿约束
```

**如果是固件端对话**:
```
7. firmware/zcritical-esp/.kiro/session-handoff.md
   知道当前阶段和任务清单

8. firmware/zcritical-esp/.kiro/steering/specs/architecture.md
   知道固件架构

9. firmware/zcritical-esp/.kiro/steering/guides/anti-bloat.md
   知道防臃肿约束
```

### 第 3 层: 技术决策

```
10. steering/decisions/README.md
    知道有哪些已决策的方案

11. 按需读对应 DR 文档 (DR-001~DR-003 等)
    知道每个方案为什么这么选
```

## 读取顺序有讲究

1. 先读节奏 → 知道现在该做什么
2. 再读索引 → 知道文档在哪
3. 再读协议和硬件 → 知道不可变约束
4. 再读领域文档 → 知道具体架构
5. 最后读决策记录 → 知道方案为什么这么选

这个顺序是为了让 AI 先建立全局认知，再深入细节。反过来读（先看 DR 再看架构）会导致碎片化理解。

## 禁止行为

| 禁止 | 原因 |
|------|------|
| 跳过文件 | 每份文件都可能包含新对话必需的信息 |
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
