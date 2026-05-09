# 软硬件协同 Git 工作流

> **用途**: 统一固件和 APP 两端的 Git 分支策略和提交规范。
> **核心理念**: 软硬件独立开发、独立提交、定期合并。

---

## 一、分支策略

```
main ──────────────────────────────────────────→
  │
  ├── firmware/xxx     ← 固件改动（所有 C/ESP-IDF 文件）
  ├── app/xxx          ← APP 改动（所有 Dart/Flutter 文件）
  ├── protocol/xxx     ← 协议变更（两端都要改）
  └── steering/xxx     ← 文档/steering 更新
```

**规则：**

| 改动范围 | 分支前缀 | 示例 |
|---------|---------|------|
| 只改固件 | `firmware/` | `firmware/fix-encoder-bounce` |
| 只改 APP | `app/` | `app/ui-onboarding` |
| 同时改两端 | `protocol/` | `protocol/add-wind-mode` |
| 只改文档 | `steering/` | `steering/update-architecture` |

---

## 二、提交消息格式

```
<type>(<scope>): <简短描述>

<详细说明（可选）>
```

**type：**
- `feat`: 新功能
- `fix`: Bug 修复
- `refactor`: 重构（不改变功能）
- `docs`: 文档变更
- `style`: 格式修改
- `test`: 测试相关

**scope：**
- `fw`: 固件
- `app`: APP
- `proto`: 协议
- `steer`: steering 文档
- `build`: 构建系统

**示例：**
```
feat(fw): add encoder debounce config

feat(app): implement colorize panel skeleton

fix(fw): encoder direction reversal resets accumulator

docs(steer): add firmware coding standards
```

---

## 三、合并原则

### 3.1 先合固件，再合 APP

如果协议变更同时涉及两端：

1. 固件分支先合入 main（固件功能实现 + 测试）
2. APP 分支基于 main 合入（使用固件已确认的协议格式）

### 3.2 独立变更直接合

- 纯固件改动不阻塞 APP
- 纯 APP 改动不阻塞固件
- 各自独立 merge

### 3.3 每次提交只做一件事

| ✅ 允许 | ❌ 禁止 |
|--------|--------|
| 修一个固件 Bug | 修固件 Bug + 顺便改 LED 预设 |
| 加一个 APP 面板 | 加面板 + 顺便改 BLE 连接 |

---

## 四、冲突处理

### 协议文件冲突 (protocol-contract.md)

协议文件可能被两端同时修改。解决冲突的优先级：
1. 以固件端实现为准 → 因为固件是硬件真值源
2. 冲突时保留两端的参数定义，合并到协议文件中
3. 如果两端对同一命令理解不同 → 必须先讨论再改

### steering 文件冲突

直接合并。steering 文件是活的文档，可以有差异。

---

## 五、版本迭代节奏

```
Week 1-2: 固件修 Bug + APP UI 骨架 ← 互不阻塞，独立分支
Week 3-4: APP BLE 连接层 ← 需要固件设备，开始联调
Week 5-6: 协议完善 + 新功能 ← 密切协同，protocol/ 分支
```

---

*创建日期: 2026-05-08*
