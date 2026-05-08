# ZCritical 技术策略

> **用途**: 新功能开发的技术方案决策指南。
> **核心理念**: 这不是重构，是全面重新设计。RideWind 是反面参考。

---

## 一、UI 渲染策略：贴图 → 代码绘制

### 为什么

RideWind 大量使用整张贴图（PNG/JPG）作为页面底图，导致了：
- 响应式布局失败（固定尺寸贴图无法适配不同屏幕）
- 主题切换不可能（深色模式需要另一套图）
- 国际化不可能（文字写死在图里）
- 动效不可能（图片是死的）
- 维护成本极高（改一个字 → 重新出图 → 替换 → 测试）

### 目标

**zcritical 的每一页 UI 都完全由 Flutter Widget + CustomPainter 绘制，不使用任何整页贴图。**

### 交付物清单

| 页面 | 当前（RideWind 贴图）| zcritical 方案 |
|------|-------------------|---------------|
| 首页仪表盘 | `connected_interface.png` 整张图 | Stack: 背景渐变 + 风速显示 + 模式选择 + 状态指示 |
| 设备扫描页 | `device_product.png` 静态图 | Product3DView（序列帧/3D组件） |
| 速度控制 | `speed_control_container.png` | CustomPainter: 仪表盘 + 数字显示 + 风速条 |
| 颜色选择 | `color_picker_container.png` | CustomPainter: 色轮 + RGB 滑块 |
| RGB 设置 | `rgb_settings_clean.png` | Widget 组合: R/G/B 独立控制器 |
| 运行模式 | `running_mode.png` | Widget 组合: 模式卡片 + 图标 |

### Widget 绘制 vs CustomPainter 的选择

| 场景 | 用什么 | 原因 |
|------|--------|------|
| 按钮、文字、列表、卡片 | 标准 Widget | Flutter 自带响应式 |
| 仪表盘刻度、指针 | CustomPainter | 需要精确的绘图控制 |
| 色轮（HSL 颜色选择） | CustomPainter | 图形学计算，无法用标准 Widget |
| 风速指示条 | CustomPainter + 动画 | 需要平滑的过渡效果 |
| 状态指示灯 | 标准 Widget（Container + 圆角） | 简单几何形状 |
| 背景纹理/渐变 | BoxDecoration | Flutter 原生支持 |

### 过渡策略

逐页替换，每完成一页就删除对应的旧贴图：
1. 首页仪表盘（验证布局方案）
2. 颜色选择页（验证 CustomPainter）
3. 设置页（验证主题）
4. Logo 上传页（最后替换）

---

## 二、3D 模型展示策略

### 现状

RideWind 已有 `Product360View` 组件，基于序列帧方案（36 帧 WebP，离线渲染）。但目前只有 demo 线框，实际产品模型帧未就位。

### 方案选择

| 阶段 | 方案 | 说明 |
|------|------|------|
| **现在** | 序列帧升级版 | 36 帧 × N 个状态（不同 LED 颜色/风速）|
| **后续** | 序列帧 + 叶片动画叠加 | 风洞本体序列帧 + 叶片用代码动画绘制叠加 |
| **远期** | 实时 3D 渲染 | GLB 模型 + 实时渲染引擎 |

### 为什么不用实时 3D 渲染（现在）

- Flutter 没有官方 3D 渲染支持
- model_viewer_plus（WebView 方案）iOS/Android 行为不一致
- 序列帧在视觉质量、性能、跨平台一致性上完胜
- 一个桌面风洞模型的展示场景下，有限的旋转角度完全够用

### 序列帧升级计划

```
资源目录: assets/product_360/
  frame_default_00.webp ~ frame_default_35.webp  （默认状态）
  frame_red_00.webp ~ frame_red_35.webp          （红色 LED 状态）
  frame_blue_00.webp ~ frame_blue_35.webp        （蓝色 LED 状态）
  ...（按需增加状态）
```

代码侧：`Product3DView` 组件接收当前 `DeviceState`，自动切换帧组：
- LED 颜色变了 → 切换到对应颜色的帧组
- 风速变了 → 叠加叶片动画速度
- 陀螺仪倾斜 → 旋转角度联动

### 包体积预算

| 内容 | 大小 |
|------|------|
| 1 组序列帧（36帧，1080×1080，q85 WebP）| ~2.8MB |
| 3 组序列帧（默认 + 红 + 蓝）| ~8.4MB |
| 建议最多 3 组 | < 10MB |

---

## 三、硬件控制精准性策略

### 三大原则

**原则 1: 乐观更新 + 硬件确认**

```
用户操作 → UI 立即响应（乐观） → 发送命令到硬件 → 等确认
  → 确认 OK: 不修正 UI
  → 确认超时: 重试 3 次
  → 重试失败: 回滚 UI + 提示用户"设备未响应"
```

**原则 2: 定期状态同步**

```
启动时: GET:ALL 同步完整设备状态
运行中: 每 5 秒一次 GET:ALL 心跳
硬件上报: SPEED_REPORT 优先级最高，立即覆盖本地状态
```

**原则 3: 操作防抖不丢命令**

```
拖动滑块:
  UI: 实时跟随手指
  发送: 每 150ms 发一次（防抖）
  手指抬起: 立即发最后一次值（确保不丢）
  
快速切换预设:
  每次切换都立即发送
  不需要防抖（预设切换是离散操作）
```

### 发送队列设计

```
[命令] → sendQueue → 逐个发送 → 等硬件确认
                     ↓ 确认 OK → 发下一个
                     ↓ 超时 500ms → 重试
                     ↓ 重试 3 次都失败 → 通知用户

关键：不取消正在发送的命令，用 Completer 链串行化
      不用布尔标志 _isSending（RideWind 的 bug 根源）
```

### 发送队列实现要点

```dart
// 伪代码（最终实现用 Dart）
class BleCommandQueue {
  Completer<void>? _current;
  
  Future<Result> send(String command) async {
    // 等上一个命令发完
    while (_current != null && !_current!.isCompleted) {
      await _current!.future;
    }
    
    // 发当前命令
    _current = Completer<void>();
    try {
      await _writeToDevice(command);
      return await _waitForAck(command, timeout: 500ms);
    } catch (e) {
      // 重试
      for (int i = 0; i < 2; i++) {
        try {
          await _writeToDevice(command);
          return await _waitForAck(command, timeout: 500ms);
        } catch (_) {}
      }
      return Result.failure('设备未响应');
    } finally {
      _current!.complete();
    }
  }
}
```

---

## 四、新功能开发标准流程

### 流程

```
提出需求
  ↓
【步骤 1】场景分析（不写代码）
  - 用户什么时候用？操作路径是什么？
  - 这个功能属于哪个域？
  - 有没有 RideWind 中的类似功能可以参考或避免？
  ↓
【步骤 2】技术方案（写在 spec 或 steering 文档）
  - 新增/修改哪些文件？
  - 分别放在哪层（core/domain/data/presentation）？
  - 需要新协议命令吗？需要改固件吗？
  - 每个新文件 ≤ 300 行吗？
  ↓
【步骤 3】方案检查
  - import 方向是否正确？
  - 有没有重复现有功能？
  - 有没有破坏现有 API？
  ↓
【步骤 4】小步实现（每步可验证）
  - 先写数据模型（freezed）
  - 再写数据源 / 协议扩展
  - 再写 Repository
  - 再写 Provider
  - 最后写 UI
  - 每一步写完都能编译运行
  ↓
【步骤 5】文档更新
  - migration-map.md 更新新文件映射
  - 有新协议命令 → protocol-contract.md
  - 有新规范 → conventions.md
  - 有新风险 → technical-risks.md
```

### 示例：新增"3D 模型展示"功能

| 步骤 | 具体内容 |
|------|---------|
| 场景分析 | 用户在设备详情页看到风洞模型的交互式 3D 展示 |
| 技术方案 | 新增 `presentation/widgets/product_3d_view.dart` 和 `data/services/frame_loader.dart` |
| 方案检查 | import 方向 ✅，文件行数 ✅（各 < 200 行），无协议变更 ✅ |
| 小步实现 | 占位组件 → 帧加载 → 手势交互 → 状态联动 |
| 文档更新 | migration-map + technical-strategy（本文件）|

---

## 五、UI 色彩与主题系统

### 代码化主题

因为 UI 全部代码绘制，主题系统可以做到：

```dart
// 所有颜色都从 Theme 取，不硬编码
final bgColor = Theme.of(context).colorScheme.surface;
final accentColor = Theme.of(context).colorScheme.primary;
final textColor = Theme.of(context).colorScheme.onSurface;
```

### 深色模式（默认）和浅色模式

桌面风洞模型主要在室内使用，深色模式是默认选项：
- 深色背景：`#121218`（微蓝黑，不是纯黑）
- 主色：品牌色（待你选定）
- 文字：`#E8E8EC`
- 卡片背景：`#1E1E28`

浅色模式作为备选（白天户外使用场景）。

### 品牌色决策

品牌色是你需要决定的，建议考虑：
- 科技蓝（`#4A90D9`）— 精密仪器感
- 赛车红（`#E74C3C`）— 速度/激情
- 风洞银（`#B0B8C8`）— 工业金属感
- 自定义（根据品牌 VI）
