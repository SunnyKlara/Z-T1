# 🧭 用户体验设计指南

> **优先级**: CRITICAL — 所有功能必须从用户角度设计
> **用途**: 解决"AI 只从代码逻辑思考，不考虑用户体验"的问题
> **创建**: 2026-05-08

---

## 一、核心原则

### 1. 用户永远是对的

- 用户不理解技术术语（BLE、MTU、CRC32）
- 用户只关心：能不能用、好不好用、出了问题怎么办
- 所有提示文案必须用用户语言，不是技术语言

### 2. 反馈必须即时

- 任何操作必须在 100ms 内有视觉反馈
- 超过 500ms 的操作必须显示加载状态
- 操作完成必须有成功/失败提示

### 3. 错误必须可恢复

- 不要只显示"Error"
- 告诉用户：发生了什么 + 怎么解决
- 提供重试按钮

---

## 二、操作反馈规范

### 按钮点击反馈

```dart
// 所有按钮必须有按下态
ElevatedButton(
  onPressed: () async {
    setState(() => _isLoading = true);
    try {
      await doSomething();
      _showSuccess('操作成功');
    } catch (e) {
      _showError('操作失败：${e.message}');
    } finally {
      setState(() => _isLoading = false);
    }
  },
  child: _isLoading
      ? SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        )
      : Text('按钮文字'),
)
```

### 加载状态

| 场景 | 反馈方式 |
|------|---------|
| 页面加载 | 全屏加载指示器（居中） |
| 局部加载 | 局部加载指示器（替换内容区） |
| 按钮操作 | 按钮变 loading 状态 + 禁用 |
| 后台操作 | Toast 提示"正在处理..." |

### 成功/失败提示

```dart
// 成功提示（绿色）
_showSuccess('已连接到设备');

// 失败提示（红色 + 建议）
_showError('连接失败。请确保设备已开机并在蓝牙范围内。');

// 警告提示（橙色）
_showWarning('电量低于 20%，建议充电');
```

---

## 三、错误处理规范

### 错误提示格式

```
[问题描述] + [建议操作]

示例：
✅ "连接失败。请确保设备已开机并在蓝牙范围内。"
✅ "上传失败。请检查网络连接后重试。"
✅ "设备无响应。请重启设备后重试。"

❌ "BLE Error 0x85"
❌ "TimeoutException"
❌ "Connection refused"
```

### 错误分级

| 级别 | 表现 | 示例 |
|------|------|------|
| 提示 | Toast，3秒自动消失 | "已保存到草稿" |
| 警告 | 对话框，需要用户确认 | "确定要删除吗？" |
| 错误 | 对话框 + 重试按钮 | "连接失败，请重试" |
| 致命 | 全屏错误页 + 操作指引 | "设备不兼容，请联系客服" |

---

## 四、用户操作流程

### BLE 连接流程

```
1. 用户点击"连接设备"
   ↓
2. 显示扫描动画（"正在搜索设备..."）
   ↓
3. 找到设备 → 显示设备列表
   ↓
4. 用户选择设备 → 显示连接动画
   ↓
5. 连接成功 → 显示"已连接" + 进入主页
   连接失败 → 显示错误 + 重试按钮
```

### Logo 上传流程

```
1. 用户选择图片
   ↓
2. 显示预览 + "上传"按钮
   ↓
3. 点击上传 → 显示进度条（0% → 100%）
   ↓
4. 上传中：显示"正在上传... 45%"
   ↓
5. 上传成功 → 显示"上传成功" + 预览
   上传失败 → 显示错误 + 重试按钮
```

### 设置修改流程

```
1. 用户修改设置
   ↓
2. 立即显示"已保存"（Toast）
   ↓
3. 如果同步到设备 → 显示"同步中..."
   ↓
4. 同步成功 → 无额外提示
   同步失败 → 显示"同步失败，设置已本地保存"
```

---

## 五、空状态设计

### 无设备时

```dart
Column(
  mainAxisAlignment: MainAxisAlignment.center,
  children: [
    Icon(Icons.bluetooth_disabled, size: 64, color: textTertiary),
    SizedBox(height: space4),
    Text('未连接设备', style: heading3),
    SizedBox(height: space2),
    Text('请先连接您的风洞设备', style: body),
    SizedBox(height: space6),
    PrimaryButton('连接设备', onPressed: _connect),
  ],
)
```

### 无 Logo 时

```dart
Column(
  mainAxisAlignment: MainAxisAlignment.center,
  children: [
    Icon(Icons.image, size: 64, color: textTertiary),
    SizedBox(height: space4),
    Text('暂无自定义 Logo', style: heading3),
    SizedBox(height: space2),
    Text('上传您的专属 Logo', style: body),
    SizedBox(height: space6),
    PrimaryButton('上传 Logo', onPressed: _upload),
  ],
)
```

---

## 六、无障碍设计

### 对比度要求

- 文字与背景对比度 ≥ 4.5:1
- 大文字（≥18px）对比度 ≥ 3:1
- 使用 [WebAIM Contrast Checker](https://webaim.org/resources/contrastchecker/) 验证

### 触摸区域

- 所有可点击元素最小尺寸 48×48
- 元素间距 ≥ 8px
- 重要操作按钮放在屏幕下半部分（拇指可达区域）

### 文字大小

- 最小可读文字 12px
- 正文 16px
- 标题 ≥ 20px
- 支持系统字体缩放

---

## 七、性能体验

### 启动时间

- 冷启动 ≤ 2 秒（显示 Splash）
- 热启动 ≤ 1 秒

### 页面切换

- 页面切换动画 ≤ 300ms
- 切换过程无卡顿

### 列表滚动

- 60fps 流畅滚动
- 图片懒加载
- 长列表使用 ListView.builder

---

## 八、文案规范

### 按钮文案

| 场景 | 文案 |
|------|------|
| 确认操作 | "确定" / "确认" |
| 取消操作 | "取消" |
| 删除操作 | "删除" |
| 保存操作 | "保存" |
| 连接操作 | "连接" / "断开" |
| 上传操作 | "上传" |
| 重试操作 | "重试" |

### 提示文案

| 场景 | 文案 |
|------|------|
| 加载中 | "正在加载..." |
| 保存成功 | "已保存" |
| 连接成功 | "已连接" |
| 连接失败 | "连接失败，请重试" |
| 上传中 | "正在上传... X%" |
| 上传成功 | "上传成功" |
| 上传失败 | "上传失败，请重试" |

### 禁止使用的文案

| 禁止 | 替代 |
|------|------|
| "Error" | "出错了" |
| "Timeout" | "请求超时" |
| "404" | "页面不存在" |
| "BLE disconnected" | "设备已断开" |
| "CRC mismatch" | "数据校验失败" |

---

## 九、用户体验检查清单

每个功能完成后，对照此清单检查：

- [ ] 操作有即时反馈（100ms 内）
- [ ] 耗时操作有加载状态
- [ ] 成功/失败有明确提示
- [ ] 错误提示包含建议操作
- [ ] 空状态有引导文案
- [ ] 按钮有按下态
- [ ] 触摸区域 ≥ 48×48
- [ ] 文字对比度达标
- [ ] 文案使用用户语言（非技术术语）
- [ ] 提供重试/取消操作

---

*AI 实现功能时必须考虑用户体验，不只是代码逻辑*
