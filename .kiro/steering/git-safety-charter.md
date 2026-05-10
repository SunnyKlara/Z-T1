---
inclusion: auto
---

# Git 安全宪章

> 优先级: CRITICAL — Kiro 每次对话自动注入
> 用途: 确保主干圣洁、分支开发、文档同步
> 类型: 操作规范 | 维护者: 用户 | 废弃条件: Git 工作流根本变化

---

## 一、核心原则

**主干是圣杯，分支是工地。**

```
main ────────────────────────────────────→ 永远是稳定可用状态
  │
  ├── feature/xxx    ← 新功能开发
  ├── fix/xxx        ← Bug修复
  └── experiment/xxx ← 实验（功能验证后删不合并）
```

| 原则 | 说明 |
|------|------|
| 主干不可污染 | main 永远可编译、可运行。未经测试通过的代码不进 main |
| 新功能=新分支 | 任何代码变更从分支开始，在分支验证，通过后合并 |
| 功能完成后删分支 | 合并后立即删除功能分支，保持分支列表干净 |
| 文档跟着代码 | steering 文档变更与代码变更同步提交 |

## 二、分支命名与用途

| 前缀 | 用途 | 示例 |
|------|------|------|
| `app/` | APP 端开发 | `app/splash-onboarding` |
| `firmware/` | 固件端开发 | `firmware/hal-lcd-driver` |
| `steering/` | 文档/配置变更 | `steering/hooks-config` |
| `protocol/` | 协议变更（两端都涉及） | `protocol/new-led-command` |
| `fix/` | Bug 修复 | `fix/encoder-bounce` |
| `experiment/` | 实验代码 | `experiment/audio-stream-test` |

## 三、提交规范

### 格式
```
<type>(<scope>): <简短描述>
```

| type | 含义 |
|------|------|
| `feat` | 新功能 |
| `fix` | Bug 修复 |
| `refactor` | 重构（不改功能） |
| `docs` | 文档变更 |
| `style` | 格式修改 |
| `test` | 测试相关 |
| `chore` | 配置/构建 |

| scope | 含义 |
|-------|------|
| `fw` | 固件 |
| `app` | APP |
| `steer` | steering 文档 |
| `proto` | 协议 |

### 铁律
- 一次提交只做一件事
- 逐文件 git add，不用 `git add .`
- commit 前 `diff --cached --name-only` 确认只是当前域的文件

## 四、功能开发流程

```
1. 从 main 切分支
   git checkout main && git pull && git checkout -b app/my-feature

2. 在分支上开发
   写代码 → 验证 → 写文档 → 验证 → 多次小提交

3. 开发完成
   跑全量测试 → 手动验证 → 更新 steering 文档

4. 合并主干
   git checkout main && git pull && git merge app/my-feature

5. 清理
   git branch -d app/my-feature
```

**禁止**：
- 在 main 上直接写代码
- 跳过验证合并
- 把实验分支合并到 main
- 代码改了文档没改就提交

## 五、Stash 清理

- Stash 不是长期草稿箱
- 每次对话结束时 stash 应为空
- 如果 ≥2 个 stash → 提醒用户清理
- 长期保存的内容 → 开分支提交，不存 stash

## 六、冲突处理

| 场景 | 处理 |
|------|------|
| 协议文件冲突 | 以固件端为准（固件=硬件真值源），手动合并 |
| 代码冲突 | firmware/ 和 zcritical/ 物理隔离，不会冲突 |
| steering 冲突 | 保留两端内容，手动审查合并 |

## 七、文档同步要求

代码变更 → 同步检查：
- 新模块/文件 → 更新 architecture-map.md 或 architecture.md
- 新协议命令 → 更新 protocol-contract.md
- 阶段完成 → 更新 session-handoff.md
- 新决策 → 写 DR 文档到 steering/decisions/
- 新问题 → 更新 known-pitfalls.md 或 troubleshooting.md

---

*创建: 2026-05-10 | 提炼自: git-workflow.md, conversation-lessons #7 #8 #9*