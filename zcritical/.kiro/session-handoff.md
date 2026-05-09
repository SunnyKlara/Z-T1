# APP端 — 会话交接 (2026-05-09)

> **给下一个 AI**: 读完这页你就知道该做什么。这里是全部参数，不需要去别的文件找。

---

## 当前阶段: 第一圈 APP 端体验原型 ✅ 完成

> 第一圈 APP 端全部完成。下一步：固件端 B1 HAL 驱动（firmware/b1-hal 分支）。

### Git 分支结构

```
main ← app/a1-a2-entry-usercenter (已合并)
  ├── app/a3-ble-connect ← [当前] APP端第一圈全部完成
  └── firmware/b1-hal     ← 固件端 B1 HAL 待开始
```

### 第一圈完成清单

| # | 文件 | 职责 | 状态 |
|---|------|------|------|
| 1 | `scan/device_scan_screen.dart` | 扫描页: RideWind声波动画 + 5秒弹窗3D模型 + 背景模糊 | ✅ |
| 2 | `about/about_screen.dart` | 关于页: 版本信息 + 开发者模式入口(版本号点5次) | ✅ |
| 3 | `debug/debug_screen.dart` | 调试页: Mock诊断数据 + 日志导出入口 | ✅ |
| 4 | `home/drawer_widget.dart` | Drawer: ☰下拉菜单(用户中心/Logo管理) | ✅ |
| 5 | `home/panels/colorize_panel.dart` | 14条胶囊水平滚动 + 三角指示器 + 转盘动画 | ✅ |
| 6 | `home/home_screen.dart` | 主页: 顶部导航栏(返回+☰) + 风洞模型 + 4面板PageView | ✅ |
| 7 | `core/router/app_router.dart` | 路由: /splash→/home→/about /debug /user-center | ✅ |

### 路由流

```
/splash        → DeviceScanScreen（声波动画→弹窗→主页）
/home          → HomeScreen（风洞模型 + 4面板 + ☰菜单）
/about         → AboutScreen（版本信息 + 开发者模式）
/debug         → DebugScreen（Mock诊断数据）
/user-center   → UserCenterScreen（分区tile列表）
/logo          → LogoManagementScreen（预留）
```

### 设计要点

- 纯黑背景 #000000，全部代码绘制，不用图片
- ☰汉堡菜单在右上角，三条横线深灰高亮色
- 风洞3D模型占屏幕约28%高度
- 下半控制面板左右padding=4
- ColorizePanel: ListView水平滚动，14条胶囊同时可见

### 验证结果

- [x] `flutter analyze` 零错误 ✅
- [x] 所有新文件有 `STEER` 块 + 职责声明 ✅
- [x] GoRouter 路由全链路通畅 ✅
- [x] 提交已推送到 app/a3-ble-connect ✅

### 下一步：固件端 B1 HAL 驱动

| 任务 | 分支 |
|------|------|
| 固件 B1: HAL 驱动 (gpio/pwm/led/lcd/encoder/audio) | firmware/b1-hal |
| APP 端打磨（功能完整后统一做） | 后续 |

---

*最后更新: 2026-05-09 | 第一圈 APP 端体验原型完成*
