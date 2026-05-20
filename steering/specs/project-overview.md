# 项目总览 — 文档索引

> **唯一入口**: `steering/START-HERE.md`。本文件是完整文档索引。

---

## 产品

ZCritical T1 — 桌面智能风洞。ESP32-S3 + Flutter APP。BLE 文本协议。

## 核心文档（新 AI 启动路径）

| # | 文件 | 何时读 |
|---|------|--------|
| 1 | `steering/START-HERE.md` | 唯一必读 |
| 2 | `firmware/zcritical-esp/.kiro/session-handoff.md` | 固件状态 |
| 3 | `zcritical/.kiro/session-handoff.md` | APP 状态 |

## 唯一真值源

| 文件 | 内容 |
|------|------|
| `steering/specs/hardware-config.md` | 硬件引脚、外设参数 |
| `steering/specs/protocol-contract.md` | BLE 命令、LED预设、速度映射 |

## 架构与规范

| 文件 | 内容 |
|------|------|
| `firmware/zcritical-esp/.kiro/steering/specs/architecture.md` | 固件架构：core+modules |
| `firmware/zcritical-esp/.kiro/steering/guides/anti-bloat.md` | 防臃肿纲领 |
| `steering/guides/ai-proactive-guidance.md` | AI 行为规范（争议义务§八） |
| `steering/specs/ui-design-tokens.md` | UI 令牌 |
| `steering/guides/git-workflow.md` | Git 工作流 |

## 知识传承

| 文件 | 内容 |
|------|------|
| `steering/knowledge/conversation-lessons.md` | 9 条核心教训 |
| `steering/knowledge/why-reference-failed.md` | 烂尾分析 |
| `steering/knowledge/ai-capability-profile.md` | AI 能力边界 |
| `steering/knowledge/known-pitfalls.md` | 技术陷阱 |
| `steering/knowledge/troubleshooting.md` | 排错 |
| `steering/knowledge/documentation-patterns.md` | 文档管理模式提炼（可复用到其他项目） |
| `reference/README.md` | 矿藏地图 |

## 不可变约束

BLE Service 0xFFE0 Char 0xFFE1 / 设备名 T1 / Logo 240×240 RGB565 115200字节 / CRC32 0xEDB88320 / LED 14种预设 / 文本\n协议 / hal不依赖modules

---

*精简: 2026-05-11 | 300行 → 50行*
