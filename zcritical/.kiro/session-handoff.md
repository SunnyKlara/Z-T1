# APP端 — 会话交接 (可直接执行)

> **给下一个 AI**: 读完这页你就知道该做什么。这里是全部参数，不需要去别的文件找。

---

## 当前阶段: Phase 1 — APP 骨架 (📍 A3: BLE连接层 ✅ 完成)

> 完整 Phase 1 包含 A1(应用入口) → A2(用户中心) → A3(BLE连接层)
> Phase 1 全部完成！下一步：Phase 3 APP 核心功能 / Phase 2 固件骨架

### Git 分支结构

```
main ← app/a1-a2-entry-usercenter (A1+A2 已合并)
  ├── app/a3-ble-connect ← [当前] 待合并到 main
  └── firmware/b1-hal     ← 固件端（另一段对话处理）
```

### 任务完成清单

| 阶段 | # | 文件 | 职责 | 状态 |
|------|---|------|------|------|
| A1 | 1 | `core/router/app_router.dart` | 路由：/splash, /onboarding, /, /user-center, /logo | ✅ |
| A1 | 2 | `splash/splash_screen.dart` | 品牌Logo + 协议勾选 + 开始使用 | ✅ |
| A1 | 3 | `splash/onboarding_screen.dart` | 3页引导 + 指示器 + 下一步 | ✅ |
| A1 | 4 | `home/home_shell.dart` | ShellRoute + Stack + ☰ + Drawer + BLE Banner | ✅ |
| A1 | 5 | `home/drawer_widget.dart` | 品牌区 + 👤用户中心 + 🖼️Logo管理 | ✅ |
| A2 | 6 | `user_center/user_center_screen.dart` | 分区标题 + tile列表 + 连接状态 | ✅ |
| A2 | 7 | `logo/logo_management_screen.dart` | Logo槽位 + 上传引导 | ✅ |
| A3 | 8 | `domain/models/connection_state.dart` | DeviceConnectionState 枚举 | ✅ |
| A3 | 9 | `presentation/providers/ble/ble_status_provider.dart` | BLE适配器状态 | ✅ |
| A3 | 10 | `presentation/providers/ble/ble_scan_provider.dart` | 扫描状态 + 设备列表 | ✅ |
| A3 | 11 | `presentation/providers/ble/ble_connection_provider.dart` | 连接状态管理 | ✅ |
| A3 | 12 | `presentation/widgets/ble/ble_connection_banner.dart` | 顶部BLE状态Banner(4色) | ✅ |

### 路由流

```
/splash          → SplashScreen
/onboarding      → OnboardingScreen
/                → ShellRoute(HomeShell)
  │                  ├── BleConnectionBanner（未连接/连接中提示条）
  │                  ├── HomeScreen（风洞 + 4面板）
  │                  └── ☰ → Drawer
  ├── /user-center → UserCenterScreen（分区tile列表 + 连接设备显示）
  └── /logo        → LogoManagementScreen
```

### Provider 架构（骨架阶段）

```
ble_status_provider      → BleAdapterState (unknown/unavailable/on/off...)
ble_scan_provider        → BleScanState + List<DiscoveredDevice>
ble_connection_provider  → DeviceConnectionState + ConnectedDevice

派生 Provider:
  isBleAvailableProvider → bool（蓝牙是否可用）
  t1DevicesProvider      → List<DiscoveredDevice>（T1设备按信号排序）
  isDeviceConnectedProvider → bool
```

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
- [x] domain 层纯 Dart，零外部依赖 ✅
- [x] Provider 层纯状态管理，不耦合 UI ✅

### 下一步：Phase 3 APP 核心功能

| 优先级 | 任务 | 分支 |
|--------|------|------|
| 1 | BLE data 层实现 (ble_service / ble_scanner / ble_connection) | `app/c1-ble-data` |
| 2 | 协议解析 (protocol_parser / command_builder / response_router) | `app/c2-protocol` |
| 3 | Provider → data 层绑定 (替换骨架状态为真实 BLE 回调) | `app/c3-binding` |
| 4 | 面板数据绑定 (4个 Panel 连接真实数据) | `app/c4-panels` |

---

*最后更新: 2026-05-09 | Phase 1 (A1+A2+A3) 全部完成*
