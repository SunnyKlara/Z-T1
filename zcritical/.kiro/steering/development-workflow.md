# ZCritical 开发工作流规范

> **用途**: 定义日常开发的完整流程——分支管理、多需求并行、软硬件协作、日常节奏。
> **设计记录**: 2026-05-07。解决 RideWind 开发中"改坏了回不去、多个功能互相打架、软硬件不知道谁等谁"的核心痛点。
> **核心理念**: 不是"写好代码"，而是**让每一次改动都可撤销、可隔离、可追溯**。

---

## 一、核心理念：主干永远可运行

```
main 分支 = 任何时候拿过来都能编译、能运行、能发给用户
```

这是天条。main 上的任何代码出了 bug，唯一工作就是修 bug。永远不在 main 上做实验。

---

## 二、Git 分支策略（Feature Branch）

### 2.1 分支命名

```
feature/<功能名>    # 新功能开发
fix/<问题描述>      # bug 修复
refactor/<模块名>   # 重构（不改变功能）
```

示例：
```
feature/logo-upload
feature/treadmill-ui
fix/ble-reconnect-crash
refactor/transmission-layer
```

### 2.2 每个分支只做一件事

| ✅ 正确 | ❌ 错误 |
|---------|--------|
| `feature/logo-upload` — 只做 Logo 上传 | `feature/misc` — 上传 + UI + bug 修复混在一起 |
| `fix/ble-timeout` — 只修 BLE 超时 | `fix/various` — 三个无关 bug 一起改 |

### 2.3 分支生命周期

```
步骤 1: 从 main 拉分支
        git checkout main
        git pull
        git checkout -b feature/logo-upload

步骤 2: 在分支上开发
        写代码 → 编译通过 → git add + commit
        每天结束时，分支上的所有代码都已经提交

步骤 3: 功能完成 → 测试通过 → 合并回 main
        git checkout main
        git merge feature/logo-upload
        git push

步骤 4: 删除分支
        git branch -d feature/logo-upload
```

### 2.4 实验性功能怎么处理

这是你最关心的问题。规则很简单：

```
实验满意 → 合并到 main
实验不满意 → 删除分支，main 干干净净
实验不满意，但部分代码有参考价值 → 新开分支，copy 需要的文件过去
```

**永远不要在 main 上做实验。** 分支就是用来"试错"的。删掉一个分支的代价是零——10 行代码和 1000 行代码一样，一个命令就没了。

---

## 三、多需求并行管理

### 3.1 排优先级

每个需求进入开发前，先定优先级：

| 级别 | 定义 | 示例 |
|------|------|------|
| P0 | 不修它别的没法做 | BLE 连接稳定性、协议解析错误 |
| P1 | 核心功能 | Logo 上传、跑步机 UI |
| P2 | 重要但可延后 | 3D 展示、音效引擎 |
| P3 | 锦上添花 | 陀螺仪联动、社交分享 |

### 3.2 一次只做一个 P0/P1 的主体开发

```
不是: 同时开发 Logo 上传 + 跑步机 UI（两个功能混在一起）
而是:
  周一~周三: feature/logo-upload（专注 Logo）
  周三完成 → 合并到 main
  周四~周五: feature/treadmill-ui（专注跑步机）
```

### 3.3 并行开发的唯一方式：多分支

如果你确实需要同时推进两个功能（例如 BLE 连接稳定性修复不影响 Logo 上传开发）：

```bash
git checkout feature/logo-upload
# 写 Logo 相关代码...
git add . && git commit -m "Logo 数据包编码完成"

git checkout feature/treadmill-ui
# 写跑步机相关代码...
git add . && git commit -m "跑步机页面骨架完成"

# 需要切回去？
git checkout feature/logo-upload
# 继续写，互不影响
```

### 3.4 一个功能的所有相关改动在同一个分支

| 一个功能涉及 | 都在同一个分支 |
|------------|-------------|
| 数据模型 | ✅ |
| 协议命令 | ✅ |
| Repository | ✅ |
| UseCase | ✅ |
| Provider | ✅ |
| Screen UI | ✅ |
| 测试 | ✅ |

---

## 四、软硬件协作流程

### 4.1 核心原则：契约先行

```
永远不在两边同时改协议——先更新 contract，双方确认，再各自开发。
```

### 4.2 完整流程

```
步骤 1: 定契约（写文档，不改代码）
        App 端和硬件端确认新命令格式
        → 写入 protocol-contract.md
        → 双方确认无误

步骤 2: 各自开发（完全并行）
        硬件端：按契约实现固件 → 用串口自测
        App 端：按契约实现发送 → 写单元测试验证格式

步骤 3: 联调
        硬件自测通过 → App 单元测试通过 → 联调
        → 格式一致 → 一次搞定
```

### 4.3 契约更新模板

每次需要新增/修改协议命令时：

```
【协议变更提案】

新增命令: LED_GRADIENT:zone:r:g:b:speed
参数: zone=0-3, r/g/b=0-255, speed=1-100
确认响应: OK:LED_GRADIENT
错误响应: LED_ERROR:GRADIENT:reason

硬件端影响: 需新增 led_gradient_handler
App端影响: 需新增 command_builder 方法 + protocol_parser 正则

双方确认？
```

### 4.4 关键约束

| 约束 | 原因 |
|------|------|
| 硬件端不可变命令格式（已在 protocol-contract.md） | ESP32 固件 hardcode |
| 新命令必须硬件先支持，App 后适配 | 避免 App 发了命令硬件不认识 |
| 硬件联调必须在 App 单元测试全部通过后 | 减少无效联调时间 |

---

## 五、日常开发节奏

### 5.1 每日开始

```bash
# 1. 确认当前在哪个分支
git branch

# 2. 确认 main 有没有新更新
git fetch origin

# 3. 如果有新更新，合并到当前分支
git merge origin/main
```

### 5.2 每次提交

写完一个完整的小步 → 编译通过 → 提交

```
提交信息格式:
  feat: 做什么
  fix: 修什么
  refactor: 重构什么

示例:
  feat: 完成 Logo 数据包十六进制编码
  fix: 修复 BLE 发送队列竞态条件
  refactor: 拆分 protocol_parser 中的 LED 命令处理
```

每次提交只改一件事。不要"feat: Logo 上传 + 顺便修连接 bug"。

### 5.3 每日结束

```bash
# 1. 确保所有改动已提交
git status   # 应该是 clean

# 2. 推送到远程
git push origin feature/xxx

# 3. 更新 session-handoff.md（三行就行）
今天做了什么 + 明天继续什么 + 遇到什么问题
```

---

## 六、合并到 main 的条件

一个功能分支要合并到 main，必须全部通过：

- [ ] 功能完整实现（按需求文档逐条验收）
- [ ] `flutter analyze` 零错误
- [ ] `flutter build apk --debug` 编译通过
- [ ] 所有新增文件 ≤ 300 行
- [ ] import 方向检查通过（没有跨层）
- [ ] 新文件有职责声明
- [ ] 相关单元测试通过（如果有）
- [ ] 实机测试通过（涉及 BLE 的功能）
- [ ] session-handoff.md 已更新

**有一条不通过，不合并。**

---

## 七、回滚流程（出问题了怎么办）

### 7.1 开发分支上的代码想回退

```bash
# 看提交历史
git log --oneline

# 回退到指定提交
git reset --hard <commit-hash>

# 回退之后改主意了？
git reflog   # 可以看到被回退的提交
git reset --hard <之前那个commit>
```

### 7.2 合并到 main 后发现问题

```
方案 A: 如果刚合并，直接撤销合并
git revert <merge-commit-hash>

方案 B: 开 fix 分支修
git checkout -b fix/xxx
# ... 修 ...
# 合并回 main
```

---

## 八、禁止行为

| 禁止 | 原因 |
|------|------|
| 在 main 分支上直接改代码 | main 是稳定版，改动必须通过分支合并 |
| 一个分支做多个功能 | 混在一起无法单独回滚 |
| 不提交代码就切分支 | 未提交的改动会跟到另一个分支 |
| 合并前不跑 flutter analyze | 编译错误的代码可能进入 main |
| 不更新 protocol-contract 就改协议 | 软件和硬件对不上 |
| 软硬同时改协议 | 谁先改谁先死 |

---

## 九、快速参考卡

```bash
# 开始新功能
git checkout main && git pull && git checkout -b feature/xxx

# 查看当前分支
git branch

# 提交代码
git add . && git commit -m "feat: xxx"

# 推送
git push origin feature/xxx

# 切到另一个分支
git checkout feature/yyy

# 废弃当前分支（回到 clean main）
git checkout main && git branch -D feature/xxx

# 查看提交历史
git log --oneline -10
```
