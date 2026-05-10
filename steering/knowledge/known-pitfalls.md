# ⚠️ 已知坑位清单（RideWind 踩过的坑）

> **优先级**: CRITICAL — 每个坑都对应一个真实 bug
> **用途**: 新对话 AI 必须读取此文件，避免重复踩坑
> **创建**: 2026-05-08

---

## 一、BLE 通信坑

### 坑 1：BLE MTU 分片导致命令截断

**现象**：APP 发送长命令（如 Logo 数据包），固件只收到前半段。

**根因**：BLE MTU 默认 23 字节，协商后 247 字节。超过 MTU 的数据会被分片，但固件没有重组逻辑。

**解决方案**：
```c
// 固件端必须有 MTU 重组缓冲区
#define RX_BUF_SIZE 512
static char s_rx_buf[RX_BUF_SIZE];
static uint16_t s_rx_len = 0;

// 每次收到数据追加到缓冲区，遇到 '\n' 才解析
```

**验收**：发送 500 字节命令，固件能完整接收并解析。

---

### 坑 2：BLE 通知拥塞导致 ACK 丢失

**现象**：Logo 上传时，固件发送 ACK，APP 没收到，超时重试。

**根因**：BLE TX 缓冲区满了，`esp_ble_gatts_send_indicate()` 返回 `ESP_GATT_CONGESTED`，但代码没有重试。

**解决方案**：
```c
// 发送通知时必须重试
for (int retry = 0; retry < 10; retry++) {
    esp_err_t err = esp_ble_gatts_send_indicate(...);
    if (err == ESP_OK) return;
    if (err == ESP_GATT_CONGESTED) {
        vTaskDelay(pdMS_TO_TICKS(20));  // 等待 TX 缓冲区释放
        continue;
    }
    return;  // 其他错误直接返回
}
```

**验收**：连续发送 100 个通知，APP 全部收到。

---

### 坑 3：BLE 连接断开后状态未清理

**现象**：设备断开后，APP 仍显示"已连接"，操作无响应。

**根因**：固件端 `s_connected = false` 但没通知 APP；APP 端没监听连接状态变化。

**解决方案**：
- 固件：断开时发送 `DISCONNECTED` 报告
- APP：监听 BLE 连接状态，断开时更新 UI

**验收**：关闭设备蓝牙，APP 在 3 秒内显示"未连接"。

---

## 二、Logo 上传坑

### 坑 4：Logo 数据包乱序

**现象**：上传的 Logo 显示花屏。

**根因**：BLE 是无序传输，数据包可能乱序到达。固件没有包序号校验。

**解决方案**：
```
协议格式：LOGO_UPLOAD:seq/total:crc32:data
- seq: 当前包序号（从1开始）
- total: 总包数
- crc32: 本包数据 CRC
- data: 实际数据（Base64 编码）

固件端校验：
1. seq 必须等于 expected_seq
2. crc32 必须匹配
3. 乱序包丢弃，等待重传
```

**验收**：上传完整 Logo，显示正确。

---

### 坑 5：PSRAM 不足导致上传失败

**现象**：上传到一半失败。

**根因**：Logo 数据 115200 字节，PSRAM 分配失败或碎片化。

**解决方案**：
- 使用 `heap_caps_malloc(115200, MALLOC_CAP_SPIRAM)` 分配 PSRAM
- 上传前检查可用 PSRAM
- 分块写入 LittleFS，不一次性加载全部

**验收**：连续上传 5 次 Logo，全部成功。

---

### 坑 6：CRC32 校验不一致

**现象**：APP 计算的 CRC 和固件计算的不同。

**根因**：CRC32 多项式不同（标准是 0xEDB88320，但有些库用 0x04C11DB7）。

**解决方案**：
- 两端使用相同多项式：`0xEDB88320`
- 使用相同的初始值：`0xFFFFFFFF`
- 使用相同的异或输出：`0xFFFFFFFF`

**验收**：同一数据，两端计算的 CRC32 一致。

---

## 三、音频坑

### 坑 7：I2S 音频爆音

**现象**：播放引擎音频时有"咔咔"声。

**根因**：I2S 缓冲区欠载（underrun），数据没及时填充。

**解决方案**：
```c
// 使用双缓冲（ping-pong buffer）
// 一个缓冲区播放时，另一个填充数据
// 缓冲区大小至少 2048 采样
```

**验收**：连续播放 10 分钟，无爆音。

---

### 坑 8：音频采样率不匹配

**现象**：音频播放速度异常（太快或太慢）。

**根因**：合成采样率和 I2S 配置采样率不一致。

**解决方案**：
- 统一使用 44100Hz
- 合成代码和 I2S 配置使用同一常量

**验收**：播放标准 440Hz 正弦波，频率正确。

---

## 四、硬件驱动坑

### 坑 9：WS2812B 时序要求严格

**现象**：LED 颜色显示错误或闪烁。

**根因**：WS2812B 对时序要求严格（T0H/T0L/T1H/T1L），软件延时不精确。

**解决方案**：
- 使用 RMT 外设或 SPI 模拟
- 不要使用 `vTaskDelay` 控制时序

**验收**：设置 14 种预设颜色，显示正确。

---

### 坑 10：GC9A01 LCD 初始化序列

**现象**：LCD 白屏或显示异常。

**根因**：初始化命令序列不完整或时序不对。

**解决方案**：
- 使用完整的初始化序列（从 reference 提取）
- SPI 频率不超过 40MHz
- 每次发送命令后延时 10ms

**验收**：显示测试图案，颜色正确。

---

### 坑 11：EC11 编码器抖动

**现象**：旋转编码器时，数值跳变。

**根因**：机械抖动导致多次触发中断。

**解决方案**：
```c
// 软件消抖：检测到变化后延时 5ms 再读取
// 或使用硬件 RC 滤波
```

**验收**：旋转一圈，数值变化 24（步长 4 × 24 步）。

---

## 五、用户体验坑

### 坑 12：加载状态缺失

**现象**：用户点击按钮后无反馈，以为没点到，重复点击。

**根因**：操作耗时但 UI 没显示加载状态。

**解决方案**：
- 任何超过 500ms 的操作必须显示加载指示器
- 按钮点击后禁用，直到操作完成

**验收**：点击耗时操作按钮，立即显示加载状态。

---

### 坑 13：错误提示不友好

**现象**：操作失败后只显示"Error"，用户不知道怎么办。

**根因**：错误信息是技术术语，不是用户语言。

**解决方案**：
- 错误提示格式：`[问题描述] + [建议操作]`
- 示例：`"连接失败。请确保设备已开机并在蓝牙范围内。"`

**验收**：所有错误场景都有友好的提示文案。

---

## 六、开发流程坑

### 坑 14：参数变更未同步

**现象**：LED 从 10 颗改为 6 颗，但 APP 和固件不一致。

**根因**：口头改了参数，没更新文档。

**解决方案**：
- 所有硬件参数集中在 `hardware-config.md`
- 任何变更必须先改此文件，再改代码

**验收**：两端读取同一配置文件，参数一致。

---

### 坑 15：对话上下文丢失

**现象**：新对话 AI 不知道之前的决策，重复讨论或做出矛盾决策。

**根因**：对话过长开新对话，但没更新 session-handoff。

**解决方案**：
- 每次对话结束必须更新 `session-handoff.md`
- 新对话 AI 第一件事读 handoff 文件

**验收**：新对话 AI 能准确知道当前进度和待办。

---

*每个坑都对应一个真实 bug，开发时必须对照检查*

---

## 七、路由迁移坑

### 坑 16：GoRouter 迁移遗漏 Navigator 调用

**现象**：APP 已迁移到 GoRouter，但部分页面仍使用 `Navigator.push/pop`，导致路由栈混乱、页面返回异常。

**根因**：迁移时只关注了主要路由跳转（`pushNamed` → `context.go`），遗漏了以下场景：
- 对话框中的 `Navigator.pop(context)` → 应改为 `context.pop()`
- 抽屉关闭的 `Navigator.pop(context)` → 应改为 `context.pop()`
- `Navigator.pushReplacement` → 应改为 `context.go()` 或 `context.replace()`
- `Navigator.pushNamedAndRemoveUntil` → 应改为 `context.go()`

**解决方案**：
```dart
// ❌ 错误：混用 Navigator 和 GoRouter
Navigator.pop(context);           // 对话框关闭
Navigator.pushNamed(context, '/'); // 页面跳转
Navigator.pushReplacementNamed(context, '/home');

// ✅ 正确：统一使用 GoRouter context 扩展方法
context.pop();                    // 关闭对话框/抽屉
context.go('/');                  // 页面跳转（清除栈）
context.replace('/home');         // 替换当前页面
```

**迁移检查清单**：
1. 添加 `import 'package:go_router/go_router.dart';`
2. 全局搜索 `Navigator\.` 确认无遗漏
3. 特别注意：对话框、SnackBar、Drawer 中的 pop 操作
4. 测试所有页面跳转和返回路径

**验收**：`grep -r "Navigator\." lib/` 返回 0 结果（除非有特殊场景必须使用）。
