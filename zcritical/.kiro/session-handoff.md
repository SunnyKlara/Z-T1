# APP端 — 会话交接 (可直接执行)

> **给下一个 AI**: 读完这页你就知道该做什么。这里是全部参数，不需要去别的文件找。
> **施工图**: `steering/development-blueprint.md` — 完整阶段规划、任务清单、验收标准

---

## 当前阶段: Phase 1 — APP 骨架 (📍 A1+A2 ✅ 完成 → 待 A3: BLE连接层)

> 完整 Phase 1 包含 A1(应用入口) → A2(用户中心) → A3(BLE连接层)
> 详见 `steering/development-blueprint.md` 第二节

### 架构决策（已确认，无需再讨论 ✅）

- ✅ SplashScreen 要加 — 品牌展示 + 用户协议
- ✅ Onboarding 3页 — 权限1 + 权限2 + 完成
- ✅ HomeShell 用 GoRouter Shell route
- ✅ 抽屉极简 — 只有用户中心 + Logo管理
- ✅ User Center 用分区标题 + icon tile 列表（参考 RideWind settings_screen 的 `_sectionTitle` + `_tile`）
- ✅ 无独立 NoDeviceScreen — 未连接状态做顶部 Banner
- ✅ 纯黑背景 #000000，全部代码绘制，不用图片
- ✅ Logo Management 独立在抽屉（不在 User Center 里）

### 任务清单

| 阶段 | # | 文件 | 职责 | 状态 |
|------|---|------|------|------|
| A1 | 1 | `core/router/app_router.dart` | 扩展路由：/splash, /onboarding, /user-center, /logo, Shell route | ✅ |
| A1 | 2 | `splash_screen.dart` | 品牌Logo(代码绘制) + "开始使用"按钮 + 用户协议勾选 | ✅ |
| A1 | 3 | `onboarding_screen.dart` | 3页 PageView 引导 + 底部指示器 | ✅ |
| A1 | 4 | `home_shell.dart` | GoRouter ShellRoute body + Stack(右上☰) + Drawer | ✅ |
| A1 | 5 | `drawer_widget.dart` | 品牌区+版本号 + 👤用户中心 + 🖼️Logo管理 | ✅ |
| A2 | 6 | `user_center_screen.dart` | 分区标题 + icon tile 列表（设备/维护/关于/重置） | ✅ |
| A2 | 7 | `logo_management_screen.dart` | Logo槽位状态展示 + 上传引导 | ✅ |

### 路由流

```
/splash          → SplashScreen（风洞Logo + 协议勾选 + 开始使用）
  ↓ 勾选协议 + 点击
/onboarding      → OnboardingScreen（3页引导 → 开始探索）
  ↓ 点击开始探索
/                → ShellRoute → HomeShell(Stack: HomeScreen + ☰)
  ↓ ☰菜单
  ├── 👤用户中心 → /user-center → UserCenterScreen（分区 tile 列表）
  └── 🖼️Logo管理 → /logo → LogoManagementScreen（预览 + 上传引导）
```

### 新增/修改文件清单

| 文件 | 类型 | STEER 块 | 职责声明 |
|------|------|----------|---------|
| `splash/splash_screen.dart` | 新建 | ✅ | ✅ |
| `splash/onboarding_screen.dart` | 新建 | ✅ | ✅ |
| `home/home_shell.dart` | 新建 | ✅ | ✅ |
| `home/drawer_widget.dart` | 新建 | ✅ | ✅ |
| `user_center/user_center_screen.dart` | 新建 | ✅ | ✅ |
| `logo/logo_management_screen.dart` | 新建 | ✅ | ✅ |
| `core/router/app_router.dart` | 修改 | ✅ | ✅ |

### 已完成面板（不要动 ✅）

| 文件 | 行数 |
|------|------|
| `pace_panel.dart` | 236 |
| `running_panel.dart` | 359 |
| `colorize_panel.dart` | 315 |
| `rgb_panel.dart` | 345 |
| `home_page_view.dart` | 33 |

### 验证结果

- [x] `flutter analyze` 零错误 ✅
- [x] 所有新文件有 `STEER` 块 + 职责声明 ✅
- [x] 没有 import `data/` 层 ✅
- [x] 路由流完整：Splash → Onboarding → HomeShell → Drawer → UserCenter / LogoManagement ✅

### 待办（A3 阶段：BLE 连接层）

| 优先级 | 任务 | 说明 |
|--------|------|------|
| 1 | BLE Provider 层 | ble_scan_provider / ble_connection_provider / ble_status_provider |
| 2 | BLE 连接状态管理 | 扫描、连接、断开、状态同步 |
| 3 | HomeShell BLE Banner | 顶部细条，未连接时显示"未连接设备 — 点击连接" |
| 4 | 数据绑定 | 将 BLE 状态注入 HomeShell / Drawer / UserCenter |

### 关键常量

```
颜色:
  背景:   Color(0xFF000000) 纯黑
  主色:   Color(0xFF00BCD4) 青色
  高亮:   Color(0xFF00E5FF) 亮青
  文字:   Colors.white / Colors.white70
  按钮:   Colors.white 背景 + Colors.black 前景

路由:
  /splash       → SplashScreen
  /onboarding   → OnboardingScreen
  /             → HomeScreen (Shell body)
  /user-center  → UserCenterScreen
  /logo         → LogoManagementScreen
```

---

*最后更新: 2026-05-09 | A1 + A2 完成，架构边界验证通过，进入 A3 BLE 连接层*
