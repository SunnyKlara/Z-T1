# 🎨 UI 设计令牌（Design Tokens）

> **优先级**: CRITICAL — 所有 UI 组件必须使用这些常量，禁止硬编码
> **用途**: 解决 AI 做 UI 时"美感不足"的问题。AI 只能组合这些令牌，不能发明新值。
> **创建**: 2026-05-08

---

## 一、颜色系统

### 主色调

```dart
// 背景
static const bgPrimary   = Color(0xFF000000);  // 纯黑背景
static const bgSecondary = Color(0xFF1A1A1A);  // 卡片背景
static const bgTertiary  = Color(0xFF2A2A2A);  // 输入框/按钮背景

// 品牌色
static const brandPrimary   = Color(0xFF00BCD4);  // 青色（主色）
static const brandSecondary = Color(0xFF00E5FF);  // 亮青（高亮）
static const brandAccent    = Color(0xFFFF5722);  // 橙色（警告/强调）

// 文字
static const textPrimary   = Color(0xFFFFFFFF);   // 主文字
static const textSecondary = Color(0xB3FFFFFF);   // 70%透明度，次要文字
static const textTertiary  = Color(0x80FFFFFF);   // 50%透明度，提示文字
static const textLink      = Color(0xFF2196F3);   // 链接文字

// 状态色
static const success = Color(0xFF4CAF50);  // 绿色
static const warning = Color(0xFFFF9800);  // 橙色
static const error   = Color(0xFFF44336);  // 红色
static const info    = Color(0xFF2196F3);  // 蓝色
```

### 使用规则

| 场景 | 使用颜色 |
|------|---------|
| 页面背景 | `bgPrimary` |
| 卡片/面板背景 | `bgSecondary` |
| 主按钮 | `brandPrimary` 背景 + `textPrimary` 文字 |
| 次要按钮 | `bgTertiary` 背景 + `textPrimary` 文字 |
| 标题文字 | `textPrimary` |
| 描述文字 | `textSecondary` |
| 提示/占位符 | `textTertiary` |
| 链接 | `textLink` |
| 成功状态 | `success` |
| 错误状态 | `error` |

---

## 二、字体系统

```dart
// 字号
static const fontSizeXs   = 12.0;  // 极小文字（标签、角标）
static const fontSizeSm   = 14.0;  // 小文字（辅助说明）
static const fontSizeBase = 16.0;  // 正文
static const fontSizeMd   = 17.0;  // 按钮文字
static const fontSizeLg   = 20.0;  // 小标题
static const fontSizeXl   = 24.0;  // 中标题
static const fontSize2xl  = 32.0;  // 大标题
static const fontSize3xl  = 48.0;  // 超大标题（Splash/Onboarding）

// 字重
static const fontWeightNormal = FontWeight.w400;
static const fontWeightMedium = FontWeight.w500;
static const fontWeightSemiBold = FontWeight.w600;
static const fontWeightBold = FontWeight.w700;
static const fontWeightExtraBold = FontWeight.w800;

// 行高
static const lineHeightTight = 1.2;    // 标题
static const lineHeightNormal = 1.5;   // 正文
static const lineHeightRelaxed = 1.75; // 长段落
```

### 字体组合预设

```dart
// 大标题（Splash/Onboarding）
TextStyle heading1 = TextStyle(
  fontSize: fontSize3xl,
  fontWeight: fontWeightExtraBold,
  letterSpacing: -0.5,
  color: textPrimary,
);

// 面板标题
TextStyle heading2 = TextStyle(
  fontSize: fontSizeXl,
  fontWeight: fontWeightBold,
  color: textPrimary,
);

// 卡片标题
TextStyle heading3 = TextStyle(
  fontSize: fontSizeLg,
  fontWeight: fontWeightSemiBold,
  color: textPrimary,
);

// 正文
TextStyle body = TextStyle(
  fontSize: fontSizeBase,
  fontWeight: fontWeightNormal,
  height: lineHeightNormal,
  color: textSecondary,
);

// 按钮文字
TextStyle button = TextStyle(
  fontSize: fontSizeMd,
  fontWeight: fontWeightSemiBold,
  color: textPrimary,
);

// 辅助文字
TextStyle caption = TextStyle(
  fontSize: fontSizeSm,
  fontWeight: fontWeightNormal,
  color: textTertiary,
);
```

---

## 三、间距系统

```dart
// 基础间距单位（4px 基准）
static const space1 = 4.0;   // 极紧凑
static const space2 = 8.0;   // 紧凑
static const space3 = 12.0;  // 标准
static const space4 = 16.0;  // 舒适
static const space5 = 20.0;  // 宽松
static const space6 = 24.0;  // 很宽松
static const space8 = 32.0;  // 大间距
static const space10 = 40.0; // 超大间距
static const space12 = 48.0; // 页面边距
static const space16 = 64.0; // 区块间距
```

### 使用规则

| 场景 | 间距 |
|------|------|
| 元素内边距（按钮、输入框） | `space3` (12) 或 `space4` (16) |
| 列表项间距 | `space2` (8) |
| 卡片内边距 | `space4` (16) |
| 区块间距（标题与内容） | `space6` (24) |
| 页面边距 | `space12` (48) |
| 大区块间距 | `space16` (64) |

---

## 四、圆角系统

```dart
static const radiusSm = 8.0;   // 小圆角（按钮、标签）
static const radiusMd = 12.0;  // 中圆角（卡片、输入框）
static const radiusLg = 16.0;  // 大圆角（面板、对话框）
static const radiusXl = 24.0;  // 超大圆角（特殊组件）
static const radiusFull = 999.0; // 全圆角（圆形按钮、头像）
```

### 使用规则

| 组件 | 圆角 |
|------|------|
| 按钮 | `radiusSm` (8) |
| 卡片/面板 | `radiusMd` (12) |
| 对话框 | `radiusLg` (16) |
| 圆形按钮 | `radiusFull` |
| 输入框 | `radiusMd` (12) |

---

## 五、阴影系统

```dart
// 卡片阴影
static const shadowCard = BoxShadow(
  color: Color(0x1A000000),  // 10% 黑色
  blurRadius: 8,
  offset: Offset(0, 2),
);

// 悬浮阴影
static const shadowElevated = BoxShadow(
  color: Color(0x33000000),  // 20% 黑色
  blurRadius: 16,
  offset: Offset(0, 4),
);

// 按钮按下态阴影（无阴影）
static const shadowPressed = BoxShadow(
  color: Color(0x00000000),
  blurRadius: 0,
  offset: Offset(0, 0),
);
```

---

## 六、按钮规范

### 主按钮

```dart
Container(
  width: 320,
  height: 58,
  decoration: BoxDecoration(
    color: brandPrimary,
    borderRadius: BorderRadius.circular(radiusSm),
  ),
  child: Center(
    child: Text('按钮文字', style: button),
  ),
)
```

### 次要按钮

```dart
Container(
  width: 320,
  height: 58,
  decoration: BoxDecoration(
    color: bgTertiary,
    borderRadius: BorderRadius.circular(radiusSm),
  ),
  child: Center(
    child: Text('按钮文字', style: button),
  ),
)
```

### 圆形图标按钮

```dart
Container(
  width: 56,
  height: 56,
  decoration: BoxDecoration(
    color: Color(0x33FFFFFF),  // 20% 白色
    shape: BoxShape.circle,
  ),
  child: Icon(Icons.menu, color: textPrimary),
)
```

---

## 七、动画规范

```dart
// 页面切换
static const pageTransitionDuration = Duration(milliseconds: 300);

// 组件出现/消失
static const fadeDuration = Duration(milliseconds: 200);

// 按钮按下反馈
static const pressDuration = Duration(milliseconds: 100);

// 加载动画
static const loadingDuration = Duration(milliseconds: 1500);
```

---

## 八、禁止行为

| 禁止 | 原因 |
|------|------|
| 硬编码颜色值（如 `Color(0xFF123456)`） | 破坏设计一致性 |
| 使用令牌表外的颜色 | 视觉不协调 |
| 自创间距值（如 `padding: 13`） | 破坏节奏感 |
| 混用圆角系统 | 视觉不统一 |
| 无阴影层级 | 缺乏层次感 |

---

## 九、UI 组件模板

### 卡片组件

```dart
Container(
  margin: EdgeInsets.symmetric(horizontal: space4, vertical: space2),
  padding: EdgeInsets.all(space4),
  decoration: BoxDecoration(
    color: bgSecondary,
    borderRadius: BorderRadius.circular(radiusMd),
    boxShadow: [shadowCard],
  ),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('标题', style: heading3),
      SizedBox(height: space2),
      Text('描述', style: body),
    ],
  ),
)
```

### 列表项

```dart
Padding(
  padding: EdgeInsets.symmetric(horizontal: space4, vertical: space2),
  child: Row(
    children: [
      Icon(Icons.settings, color: brandPrimary, size: 24),
      SizedBox(width: space3),
      Text('设置', style: TextStyle(fontSize: fontSizeBase, color: textPrimary)),
      Spacer(),
      Icon(Icons.chevron_right, color: textTertiary),
    ],
  ),
)
```

---

*AI 做 UI 时只能使用这些令牌，不能发明新值*
