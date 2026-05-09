# 契约驱动协作

> **用途**: 解决自然语言与代码之间的鸿沟。AI 不能听懂你脑子里的想法，所以必须在写代码前确立契约。
> **核心原则**: 先写接口/模型/状态定义 → 你确认 → 再写实现。不跳跃，不猜。

---

## 问题分析

```
你的想法                    AI 生成代码
  │                            ▲
  │ 模糊的自然语言              │ 精确的代码
  │                            │
  └──────── 鸿沟 ──────────────┘
  
AI 在这中间做了大量你意识不到的设计决策：
  - 状态放哪？Provider / StatefulWidget / 全局变量
  - 错误怎么处理？抛异常 / 返回 null / Result<T>
  - 组件拆成几个文件？
  - 命名用什么？setSpeed / changeSpeed / updateWind
```

等代码写完了你才看到这些决策，但那时候已经晚了。

---

## 解决方案：三层契约

### 第一层：功能契约（用模板描述需求）

你不需要写代码，只需要填写结构化模板。**用这个模板提需求，而不是用自然语言描述。**

```yaml
Feature: 风速控制
Data:
  - WindSpeed: double, 0-100, 默认 0
  - WindMode: manual | auto, 默认 manual
Actions:
  - 设置风速: setSpeed(double) → 成功/失败
  - 切换模式: toggleMode() → 成功/失败
  - 增量调节: adjustSpeed(+1 或 -1) → 成功/失败
UI:
  - 滑块控制风速
  - 模式切换按钮
  - 实时数值显示（大字居中）
  - 离线时显示 "未连接" 提示
States:
  - 正常: 显示当前风速和模式
  - 离线: 滑块禁用，显示 "未连接"
  - 执行中: 滑块禁用，显示加载动画
  - 失败: 显示错误提示，3秒后自动恢复
```

**这个模板你不写代码，只写你要什么。**

### 第二层：设计契约（AI 输出接口和模型）

AI 收到你的模板后，**先不写代码**，而是输出设计契约：

```dart
// --- 模型 ---
class WindControlState {
  final double speed;         // 0.0 - 100.0
  final WindMode mode;        // manual / auto
  final bool isOnline;
  final bool isExecuting;
  final String? lastError;
}

// --- Provider 接口 ---
abstract class WindControlNotifier implements StateNotifier<WindControlState> {
  Future<Result<void>> setSpeed(double speed);
  Future<Result<void>> toggleMode();
  Future<Result<void>> adjustSpeed(double delta);
}

// --- 文件拆分 ---
lib/
  domain/models/wind_control_state.dart   (~50行)
  presentation/providers/device/wind_control_provider.dart (~150行)
  presentation/widgets/running/throttle_control.dart       (~200行)
  presentation/screens/running/running_page.dart           (~100行，新增风速部分)
```

**这个契约你认为 OK，AI 才动笔写代码。** 你不需要读懂每一个方法签名，只需要确认：
- "对，我就需要这些状态"
- "对，操作就是这三个"
- "对，文件就该这么放"

### 第三层：实现（AI 按契约写代码）

AI 按契约写代码，写完立即 `flutter analyze` 验证。

---

## 给你一个具体的对比

### ❌ 旧方式（自然语言 → 直接写代码）

```
你: "我要一个风速控制页面，能拖滑块调速，有个按钮切手动自动模式"

AI: [写了 300 行代码]

你: "等等，这个 Provider 叫 WindSpeedNotifier，为什么不是 WindControlProvider？"
    "还有为什么滑块范围是 0-100，我觉得应该是 0-100%"
    "离线状态怎么处理的？我没看到"
    ...
```

### ✅ 新方式（契约先行）

```
你: [填写功能契约模板]
    Feature: 风速控制
    Data: WindSpeed (0%-100%), WindMode (manual/auto)
    ...

AI: [输出设计契约，不写代码]
    这是模型和接口设计，你确认一下：
    - WindControlState 包含 5 个字段
    - WindControlNotifier 提供 3 个方法
    - 拆成 2 个文件
    有问题吗？

你: "模式改成 cruising/sport/exhibition 三种"
    "速度范围应该是 0-100 不是百分比"

AI: [修改契约]
    好的，改好了。确认吗？

你: "确认，写吧"

AI: [按契约写代码，写完验证]
    ✅ flutter analyze 通过
    ✅ 每文件 ≤ 350 行
```

**关键区别：问题发现在契约阶段，而不是代码阶段。改契约一行字，改代码可能几百行。**

---

## 协作铁律补充

> **铁律 0: 没有契约，不写代码。**
> 
> 任何需求——哪怕"就改一行"——先写功能契约。AI 必须输出设计契约让你确认。确认后才动笔。

这不是仪式感。这是从 RideWind 教训中提炼出的最高效防错误方案。

---

## 什么时候可以跳过契约

| 场景 | 是否需要契约 |
|------|------------|
| 新建一个文件 | ✅ 必须 |
| 修改现有文件的逻辑 | ✅ 必须（至少二层契约） |
| 修复一个明确的 bug（你知道原因和修复方式） | ⚠️ 简化契约（只说明改什么、为什么） |
| 格式化、重命名等纯机械操作 | ❌ 可以跳过 |

---

## 快速参考：功能契约模板

```yaml
Feature: [功能名称]
Data:
  - [数据名]: [类型], [范围/约束], [默认值]
Actions:
  - [操作名]: [输入参数] → [输出]
UI:
  - [UI 元素描述]
States:
  - [状态名]: [该状态下的 UI 表现]
Constraints:
  - [限制条件，如"不能超过 X"、"必须和硬件同步"]
```

复制这个模板，填入你的需求，发给 AI。这就是你的"需求编程语言"。
