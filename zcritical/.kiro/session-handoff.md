# APP端 - 会话交接 (2026-05-09)

## 硬事实

- 用户有 ESP32-S3 开发板在手边，随时可以烧录测试
- 不需要问"能不能实机测"——代码写好用户会自动验证

## 当前状态

Phase 1 APP骨架 (A1+A2+A3) 全部完成。flutter analyze 零错误。
代码在 `app/a3-ble-connect` 分支，未合入 main（需实机验证后合并）。

## 已完成

**APP 端 UI (7页面)**:
- SplashScreen + OnboardingScreen (品牌Logo + 3页引导)
- HomeShell (GoRouter ShellRoute + BLE Banner + 右上角菜单按钮 + Drawer)
- HomeScreen (风洞视图 + 4面板 PageView)
- UserCenterScreen (分区标题 + icon tile列表)
- LogoManagementScreen (Logo槽位 + 上传引导)
- 路由: /splash -> /onboarding -> / -> /user-center -> /logo

**Provider 层 (骨架阶段，Mock状态)**:
- ble_status_provider (BLE适配器状态)
- ble_scan_provider (扫描状态 + 设备列表)
- ble_connection_provider (连接状态管理)
- BleConnectionBanner (顶部4色状态提示条)

**Domain 层**:
- DeviceConnectionState 枚举
- Device 模型

**已完成面板 (不要动)**:
- pace_panel.dart (236行)
- running_panel.dart (359行)
- colorize_panel.dart (315行)
- rgb_panel.dart (345行)
- home_page_view.dart (33行)

## 文档体系

- steering/decisions/: 3篇技术决策 (DR-001 BLE / DR-002 音频 / DR-003 LVGL)
- steering/roadmap/development-rhythm.md: 四圈迭代模型
- steering/specs/product-requirements-audit.md: 功能审计(P0-P9)

## 下一步: 第一圈 - 体验原型

按 development-rhythm.md 进入第一圈。
任务: 补齐APP端UI原型 + 固件端硬件基础验证。
用Mock数据驱动，不涉及BLE真实通信。

## Git 分支

```
main
  app/a1-a2-entry-usercenter (已合并)
  app/a3-ble-connect (当前, 有未提交文档改动)
  firmware/b1-hal (固件端, 待开始)
```
