# 启动入口

> **唯一必读。2 分钟。**

---

## 项目

ZCritical T1 桌面智能风洞。ESP32-S3 + Flutter APP。BLE\n协议。

## AI 能力

能写 C/Dart · idf.py build(v5.3.5) · 读 reference · 搜文档
不能烧录 · 不能看硬件 → 用户烧录反馈。**不要问有硬件吗。**

## 当前状态

固件 → firmware/zcritical-esp/.kiro/session-handoff.md（B0✅ B1✅ B2待执行）
APP → zcritical/.kiro/session-handoff.md

## 必知

1. 硬件参数 → steering/specs/hardware-config.md
2. BLE协议 → steering/specs/protocol-contract.md
3. 架构：core(hal/protocol/state)+modules / hal不依赖modules
4. Reference：提取参数→新架构重构
5. 职责单一>行数 · 直接执行 · 配置双向同步

## 深入

二十场对话教训 → steering/knowledge/conversation-lessons.md
Reference烂尾 → steering/knowledge/why-reference-failed.md
AI行为规范 → steering/guides/ai-proactive-guidance.md
文档全貌 → steering/specs/project-overview.md

---

*瘦身后 | B1✅ | 2026-05-11*