# APP端 — 会话交接 (可直接执行)

> **给下一个 AI**: 读完这页你就知道该做什么。这里是全部参数，不需要去别的文件找。
> **施工图**: `steering/development-blueprint.md` — 完整阶段规划、任务清单、验收标准

---

## 当前阶段: Phase 1 — APP 骨架 (📍 A1: 应用入口)

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

### 本次对话任务清单

| # | 文件 | 职责 | 上限 |
|---|------|------|------|
| 1 | `app.dart` | 修改入口流：isFirstLaunch → 决定 Splash 或 HomeShell | 已有 |
| 2 | `core/router/app_router.dart` | 扩展路由：/splash, /onboarding, /user-center, /logo, Shell route | 已有 |
| 3 | `splash_screen.dart` | 品牌Logo(代码绘制) + "开始使用"按钮 + 用户协议勾选 | 180行 |
| 4 | `onboarding_screen.dart` | 3页 PageView 引导 + 底部指示器(选中短条/未选中长条) | 150行 |
| 5 | `home_shell.dart` | GoRouter ShellRoute body + Stack(Positioned右上☰按钮) + Drawer | 80行 |
| 6 | `drawer_widget.dart` | 品牌区(logo+版本号) + 👤用户中心 + 🖼️Logo管理 | 80行 |

### 具体参数

**SplashScreen:**
- 背景: `Color(0xFF000000)`
- 品牌Logo: 用代码绘制 "ZCritical" 文字 + 风洞线框图形
- 协议勾选: 圆框 + 红色内圆点 + "我已阅读并同意" + 链接文字(蓝色)
- 按钮: 白底黑字, 圆角29, 宽320高58
- 用户协议和隐私政策: 硬编码文本, 弹窗展示

**OnboardingScreen (3页):**
- PageView 可滑动
- 标题: 48号字, w800
- 描述: 20号字, 白色70%透明度
- 底部: 3个指示器横条 + 下一步按钮(264行复用SplashScreen样式)
- 第1页: "允许通知权限" + 描述
- 第2页: "允许附近设备权限" + 描述
- 第3页: "全部就绪！" + 按钮文案变为"开始探索"
- 完成后: markOnboardingComplete() → pushAndRemoveUntil → HomeShell

**HomeShell:**
- GoRouter ShellRoute 管理 body
- Stack 叠加: 主内容 + Positioned(top-right) ☰按钮(56x56, 白色半透明圆形)
- ☰按钮 → openEndDrawer
- Drawer: 从右滑出, 黑色背景, 宽 ~280px
- BLE Banner: 顶部细条, 未连接时显示 "未连接设备 — 点击连接"(待A3实现)

**Drawer:**
- 品牌区: "ZCritical" 文字 + 版本号(连点5次解锁开发者选项)
- 👤 用户中心 → /user-center
- 🖼️ Logo 管理 → /logo
- 分隔线
- (预留扩展位)

### 关键常量

```
颜色:
  背景:   Color(0xFF000000) 纯黑
  主色:   Color(0xFF00BCD4) 青色
  高亮:   Color(0xFF00E5FF) 亮青
  文字:   Colors.white / Colors.white70
  按钮:   Colors.white 背景 + Colors.black 前景

字体:
  大标题: 48px, w800, letterSpacing -0.5
  描述:   20px, w400, height 1.5
  按钮:   17px, w600

路由:
  /splash       → SplashScreen
  /onboarding   → OnboardingScreen
  /             → HomeScreen (Shell body)
  /user-center  → UserCenterScreen
  /logo         → LogoManagementScreen
```

### 已完成面板（不要动 ✅）

| 文件 | 行数 |
|------|------|
| `pace_panel.dart` | 236 |
| `running_panel.dart` | 359 |
| `colorize_panel.dart` | 315 |
| `rgb_panel.dart` | 345 |
| `home_page_view.dart` | 33 |

### 验证标准

- [ ] `flutter analyze` 零错误
- [ ] 每新文件 ≤ 上限行数
- [ ] 新文件有 `STEER` 块 + 职责声明
- [ ] 没有 import `data/` 层
- [ ] 输出合规检查报告

---

*最后更新: 2026-05-08 | 架构讨论已全部确认，可直接执行*
