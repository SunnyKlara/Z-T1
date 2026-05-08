# ZCritical 编码约定

> **用途**: 所有 AI 会话和开发者必须遵守的统一编码规范。
> **优先级**: 硬性规则（标记 ⚠️）不可违反，软性规则（标记 💡）强烈建议。

---

## 一、文件组织 ⚠️

### 文件行数：分层策略（不是一刀切）

核心原则：**一个文件只做一件事。行数是检测职责膨胀的"信号"，不是目的。**

| 区域 | 最大行数 | 策略 |
|------|---------|------|
| `lib/` 源码（核心业务） | **350 行** | 严格限制。超过必须说明理由并计划拆分 |
| `lib/` 配置文件（router、theme、di） | **500 行** | 允许放宽。声明式配置天然较长 |
| `test/` 测试文件 | **600 行** | 允许放宽。集成测试场景多 |
| 生成代码（`*.g.dart`、`*.freezed.dart`） | 不限制 | 工具生成，不入仓库审查 |
| `.kiro/steering/` 文档 | 不限制 | 但不建议超过 300 行，保证可读性 |

### 行数检查时机

| 时机 | 频率 | 执行方式 |
|------|------|---------|
| IDE 中 | **不检查** | 不打断开发心流 |
| AI 写文件前 | **自查** | AI 预估行数，超 350 行先说明理由或拆分方案 |
| Git 提交前（后续 CI） | 每次提交 | 脚本检查 lib/ 核心业务文件 |
| 每月瘦身审计 | 每月一次 | 手动 review 接近上限的文件 |

### 其他文件组织规则

| 规则 | 说明 |
|------|------|
| 一文件一职责 | 每个文件只做一件事，文件名即职责 |
| 私有优先 | 不导出到外部的符号一律加 `_` 前缀 |

## 二、命名规范

| 类型 | 风格 | 示例 |
|------|------|------|
| 文件 | snake_case | `ble_scanner.dart` |
| 类/枚举/混入 | PascalCase | `BleScanner`, `FanSpeed` |
| 变量/函数/方法 | camelCase | `fanSpeed`, `parseResponse()` |
| 常量 | SCREAMING_SNAKE_CASE | `MAX_MTU_SIZE` |
| Riverpod Provider | camelCase + Provider 后缀 | `fanSpeedProvider` |
| UseCase | PascalCase + UseCase 后缀 | `ConnectDeviceUseCase` |
| Repository 接口 | PascalCase + Repository 后缀 | `DeviceRepository` |
| Repository 实现 | PascalCase + Impl 后缀 | `DeviceRepositoryImpl` |

## 三、代码风格 💡

### 导入顺序
```dart
// 1. Dart SDK
import 'dart:async';

// 2. Flutter SDK
import 'package:flutter/material.dart';

// 3. 第三方包
import 'package:riverpod_annotation/riverpod_annotation.dart';

// 4. 项目内部（相对路径）
import '../../domain/models/fan_speed.dart';
```

### 注释规范
- 公共 API 必须用 `///` 文档注释说明用途
- 复杂逻辑用 `//` 解释为什么这么做，而不是做了什么
- 不要注释掉的代码——删掉，Git 历史能找到

### 错误处理
- domain 层不抛异常，返回 `Result<T>`（来自 core/result.dart）
- data 层用 `Result.failure()` 包装异常
- UI 层通过 Provider 的 `AsyncValue` 自然处理错误状态
- 不用 `dynamic` 类型——写明确的类型

## 四、状态管理 ⚠️

| 规则 | 说明 |
|------|------|
| Screen 不持状态 | 所有状态在 Riverpod Provider 中，Screen 只读 |
| 不使用 StatefulWidget | 统一用 `ConsumerWidget` / `ConsumerStatefulWidget` |
| 不手动 dispose | 用 `autoDispose` 修饰 Provider，框架自动管理生命周期 |
| 不变 StateNotifier | 用 `@riverpod` 注解 + code-gen，不用手写 StateNotifier |

## 五、测试要求 💡

| 层级 | 覆盖要求 | 工具 |
|------|---------|------|
| domain 模型 | 序列化/反序列化 round-trip | freezed 自带 |
| domain usecase | 100% 逻辑分支 | mocktail |
| data repository | 核心方法 mock 测试 | mocktail |
| data protocol codec | 所有命令/响应 encode/decode | 纯函数，无需 mock |
| UI widget | 关键交互 golden test | flutter_test |

## 六、新增平台检查清单

添加新平台支持时：
- [ ] `PlatformCapability` 新增对应实现类
- [ ] `pubspec.yaml` 无新增平台专属依赖（除非必要）
- [ ] MethodChannel 名称统一为 `com.zcritical.ridewind/xxx`
- [ ] 原生代码放在对应平台目录的 `audio/` 子包中

## 七、禁止事项 ⚠️

1. **禁止** 在 UI 层直接访问 BLE Service
2. **禁止** 在 Provider 中直接操作 `StreamController`
3. **禁止** 使用 `Timer` 而不用 `Ref.keepAlive()` 管理生命周期
4. **禁止** 使用 `Platform.isAndroid` / `Platform.isIOS` 做平台判断——用 `PlatformCapability` 抽象
5. **禁止** 在 Stream 的 listen 回调中不保存 `StreamSubscription` 引用
6. **禁止** 硬编码字符串——UI 文字进 ARB，配置值进 const
7. **禁止** lib/ 核心业务文件超过 350 行无拆分计划
