# AI 会话交接记录

> **用途**: 每次和 AI 协作后记录进度，让下一个 AI 会话无需重复工作。
> **更新**: 每次完成有意义的对话或代码变更后更新。

---

## 最新状态（更新于 2026-05-07 16:00）

### 当前项目阶段

**Phase 1 骨架先行 — 回合 1 完成**。首页上下分屏 + 滑动面板骨架已就位。

### 项目快照

| 维度 | 状态 |
|------|------|
| **阶段** | Phase 1 回合 1 ✅ — 骨架验证 |
| **编译** | `flutter analyze` — No issues found |
| **源码** | 13 个文件，全部手写 |
| **设计方向** | 极简纯黑 — 无顶部栏、无底部导航、无指示器、无文字 |

### lib/ 目录结构

```
lib/
├── main.dart
├── app.dart
├── core/
│   ├── error/result.dart
│   ├── utils/logger.dart
│   ├── theme/app_theme.dart
│   ├── di/injection_container.dart
│   └── router/app_router.dart
├── domain/
│   └── models/
│       ├── device.dart
│       └── connection_state.dart
└── presentation/
    └── screens/
        └── home/
            ├── home_screen.dart       ← 40/60 分屏骨架
            └── home_page_view.dart    ← 4 页滑动占位
```

### 首页布局

- 纯黑背景 `#000000`
- 上半 40%：3D 产品占位区（线框）
- 下半 60%：PageView，4 页占位面板
- 无任何 UI 装饰元素（无文字、无指示器、无导航）
- BouncingScrollPhysics 实现惯性滑动

### 下一步：回合 2 — 上半风洞模型 Demo

CustomPainter 绘制风洞线框 + 旋转交互。

### 当前项目阶段

**Phase 0 技术验证链 — ✅ 全部完成**。8/8 步通过 `flutter analyze`。

### Phase 0 进度

| Step | 文件 | 状态 |
|------|------|------|
| 1 | `pubspec.yaml` update | ✅ Done — 10 deps, 45 transitive |
| 2 | `flutter analyze` baseline | ✅ Done — No issues found |
| 3 | `core/error/result.dart` | ✅ Done — `Result<T>` sealed class，145 行 |
| 4 | `core/utils/logger.dart` | ✅ Done — 封装 logger 2.5.0，80 行 |
| 5 | `core/theme/app_theme.dart` | ✅ Done — Material3 深色/浅色主题 + 颜色常量，210 行 |
| 6 | `core/di/injection_container.dart` | ✅ Done — GetIt + SharedPreferences，80 行 |
| 7 | `domain/models/device.dart` + `connection_state.dart` | ✅ Done — Device 模型 + 连接状态枚举，140 行 |
| 8 | `core/router/app_router.dart` + `app.dart` update | ✅ Done — GoRouter + ProviderScope + 主题接入，100 行 |

**🎉 Phase 0 全部 8 步完成！`flutter analyze` — No issues found!**

| Step | 文件 | 状态 |
|------|------|------|
| 1 | `pubspec.yaml` update | ✅ Done — 10 deps, 45 transitive |
| 2 | `flutter analyze` baseline | ✅ Done — No issues found |
| 3 | `core/error/result.dart` | ✅ Done — `Result<T>` sealed class，145 行 |
| 4 | `core/utils/logger.dart` | ✅ Done — 封装 logger 2.5.0，80 行 |
| 5 | `core/theme/app_theme.dart` | ✅ Done — Material3 深色/浅色主题 + 颜色常量，210 行 |
| 6 | `core/di/injection_container.dart` | ✅ Done — GetIt + SharedPreferences，80 行 |
| 7 | `domain/models/device.dart` + `connection_state.dart` | ⏳ Next |
| 8 | `core/router/app_router.dart` + `app.dart` update | ⏳ Pending |

### 最近完成的对话

| 日期 | 对话内容 | 关键产出 |
|------|---------|---------|
| 2026-05-07 | **AI 协作效率优化** | 创建 `ai-efficiency-log.md`（4条效率规则）。更新 `ai-collaboration.md`——增加"工具调用效率规则"章节（并行调用、写验一体、按需读取、路径简化、Phase 0 一步做完）。更新 `session-handoff.md` |
| 2026-05-07 | **Phase 0 Step 3** | 创建 `lib/core/error/result.dart` — `Result<T>` sealed class，含 `_Ok`/`_Failure` 变体。`flutter analyze` 通过 |
| 2026-05-07 | **分层行数策略 + 删除 hook** | 删除 2 个打断开发的 hook。更新 `conventions.md`、`anti-bloat.md`：分层行数 350/500/600。行数检查不在 IDE 中打断，改为 AI 自查 + CI |
| 2026-05-07 | **开发工作流规范** | 创建 `development-workflow.md` — Git 分支策略、多需求并行、软硬件协作、日常节奏 |
| 2026-05-07 | **架构审计 + 地图创建** | 创建 `architecture-map.md`，8 个改进提案全部纳入。完整 133 文件目录树 |
| 2026-05-07 | AI 角色定义 — 解决"知识缺口" | 创建 `senior-dev-role.md`，AI 必须是技术合伙人 |
| 2026-05-07 | 沟通模板 — 解决"怎么跟 AI 说话" | 创建 `communication-template.md`，4 个模板 + AI 回应格式 |
| 2026-05-07 | AI 主动思考/建议规则 | 更新 `ai-collaboration.md`，铁律 1 扩展 + 铁律 6 新增 |
| 2026-05-07 | 工程管理规范 | 创建 `engineering-process.md`，6 阶段完整流程 |
| 2026-05-07 | 产品定位深度探讨 | 确认"桌面风洞模型"定位，颠覆 UX 方向 |
| 2026-05-07 | 用户体验设计纲领 | 创建 `ux-principles.md`，5 个核心场景 |
| 2026-05-07 | 防臃肿机制 | 创建 `anti-bloat.md`，7 道防线 |
| 2026-05-07 | 技术策略 | 创建 `technical-strategy.md` |
| 2026-05-07 | 编码规范 + 迁移映射 | 创建 `conventions.md` + `migration-map.md` |
| 2026-05-05 | 协议契约 + 技术风险 | 创建 `protocol-contract.md` + `technical-risks.md`

### 已确认的关键决策

1. **产品定位**: 桌面风洞模型（非车载风扇），体验型 App（非工具型）
2. **平台策略**: 主力 Android + iOS，其他平台配套展示
3. **包名**: `com.zcritical.ridewind`，App 未上架，无历史包袱
4. **旧代码态度**: RideWind 仅作参考，不复用任何代码
5. **UI 渲染**: 全部 Widget/CustomPainter 代码绘制，不使用整张贴图
6. **3D 展示**: 序列帧方案（36帧WebP），后续可升级
7. **架构**: Clean Architecture + Riverpod 2.x + GoRouter
8. **每文件 ≤ 350 行**: 核心业务严格，配置/测试放宽（350/500/600）
9. **代码生成全部移除**: freezed/json_serializable/build_runner 因 Flutter 3.41.6 缺少 `_macros` SDK 无法使用。模型和 DI 手写。
10. **工具调用效率规则**: 并行优先、写验一体、按需读取、路径简化

### Steering 文件清单（18 个）

| 文件 | 用途 |
|------|------|
| `START-HERE.md` | 新 AI 入口，必读 |
| `architecture-map.md` | 完整目录树 + 每文件职责 + import 规则 + Phase 0 最小集 |
| `ai-efficiency-log.md` | **新增** AI 协作效率优化经验日志 |
| `senior-dev-role.md` | AI 角色定义 — 技术合伙人 |
| `ai-collaboration.md` | AI 协作铁律 + 工具调用效率规则 |
| `communication-template.md` | 4 个沟通模板 + AI 回应格式 |
| `engineering-process.md` | 6 阶段工程管理规范 |
| `engineering-standards.md` | 质量门禁体系 |
| `development-workflow.md` | Git 分支策略、多需求并行、软硬件协作 |
| `reconstruction-blueprint.md` | 项目全貌、架构蓝图 |
| `protocol-contract.md` | 与 ESP32 的不可变协议边界 |
| `technical-risks.md` | 18 个已知技术债务 |
| `ux-principles.md` | 用户体验设计纲领 |
| `anti-bloat.md` | 防止代码腐烂的 7 道防线 |
| `conventions.md` | 编码规范（分层行数限制） |
| `migration-map.md` | 旧文件 → 新文件映射 |
| `technical-strategy.md` | UI代码化 + 3D方案 + 硬件精准 |

### 给下一个 AI 的话

> 来，先读 `START-HERE.md`。这个项目不是在写代码——它在重新设计一个产品。用户是车模爱好者，不是司机。App 要有仪式感，不是工具感。RideWind 是反面教材，不要复制它的任何代码和设计思路。每一条协议边界在 `protocol-contract.md` 里。
> 
> **当前阶段：Phase 0 技术验证链。** Step 1-3 已完成。下一步是 Step 4: `core/utils/logger.dart`。
> 
> **效率要求**：读文件时并行读取；写完代码立即跑 `flutter analyze`；无依赖的 Phase 0 步骤可以在一个回合里并行创建多个文件。详见 `ai-efficiency-log.md`。
