# Reference 项目失败分析

> **类型**: 参考知识 / 教训提炼
> **维护者**: 用户
> **废弃条件**: 新项目稳定交付后归档
> **创建**: 2026-05-11

---

## 它是什么

`reference/RideWind`（旧 APP）和 `reference/ridewind-esp`（旧固件）是 ZCritical/T1 桌面智能风洞的前身。

## 为什么烂尾

**不是因为功能写不出来。** 大部分功能已完成并通过硬件验证：
WS2812B LED 驱动、GC9A01 LCD SPI、EC11 编码器消抖、LEDC PWM 风扇调速、BLE GATT 服务、文本协议解析、14 种 LED 预设、I2S 音频引擎。

**烂尾根本原因：架构混乱，野蛮生长。**
1. `main.c` 膨胀到 893 行——初始化+命令分发+Logo上传全挤一起
2. 没有分层架构——驱动/应用/服务互相依赖
3. 没有唯一真值源——引脚定义散落多处，改时遗漏
4. UI 页面耦合——改一个影响其他
5. 全局变量无节制——AppState 200 字段
6. 无设计决策记录——后来者不知道为什么这样写

维护成本高到不可承受 → 无法继续开发 → 烂尾。

## 能学到什么

| reference 的错误 | 我们的应对 |
|-----------------|-----------|
| 没有分层架构 | core + modules 双区架构（明确依赖方向）|
| 没有唯一真值源 | hardware-config.md / protocol-contract.md |
| 没有设计决策记录 | steering/ 文档体系 + DR 系列 |
| 野蛮生长 | 防臃肿纲领（anti-bloat.md）|
| 没有 AI 协作规范 | ai-proactive-guidance.md |
| 没有知识传承 | 本文件 + conversation-lessons.md |

## 正确用法

**不是"不能看"的禁区，而是"已验证"的知识库。**

1. 打开 reference/README.md → 找到目标功能对应的旧文件
2. 读取旧代码 → 提取已验证的硬件参数（引脚、时序、初始化序列）
3. 关掉旧代码 → 在新架构下重构逻辑
4. 不复用代码结构，但充分信任已验证的参数值

已验证可直接使用的参数：GC9A01 init sequence、WS2812B RMT 时序、14 种 LED 预设 RGB 值、协议命令格式（已提炼到 protocol-contract.md）。

---

*创建日: 2026-05-11 | 作为 conversation-lessons.md 教训1 的补充*
