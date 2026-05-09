# 执行异常处理手册

> **用途**: 开发中遇到具体问题时的快速诊断和解决指南。不替代创造性思考，只解决"卡住"的情况。
> **创建**: 2026-05-08

---

## APP 端常见问题

| 问题 | 可能原因 | 解决方向 |
|------|---------|---------|
| `flutter analyze` 不通过 | 新建文件没有 STEER 块 | 看 `anti-bloat.md` 防线3 |
| 文件超过 350 行 | 塞了太多职责 | 看 `anti-bloat.md` 防线1，计划拆分 |
| 不知道该放哪个目录 | 架构方向不明确 | 看 `reconstruction-blueprint.md` 架构图 |
| 不知道跳转逻辑 | 路由不清楚 | 看 `session-handoff.md` 中的路由表 |
| 不知道 BLE 消息格式 | 协议格式不确定 | 看 `steering/protocol-contract.md` |
| 不知道命名风格 | 命名不一致 | 看 `steering/naming-conventions.md` |

## 固件端常见问题

| 问题 | 可能原因 | 解决方向 |
|------|---------|---------|
| `idf.py build` 不通过 | 缺少 STEER 块 | 看 `anti-bloat.md` 防线3 |
| 文件超过行数上限 | 驱动混杂了渲染 | 看 `anti-bloat.md` 防线1 |
| 不知道该放 core/ 还是 modules/ | 看是否被多个模块依赖 | core/ = 跨模块共享, modules/ = 单个功能 |
| 不知道引脚号 | 硬件参数遗忘 | 看 `session-handoff.md` 的硬件参数表 |
| 不知道 BLE 响应格式 | 协议格式不确定 | 看 `steering/protocol-contract.md` |
| 不知道该先写哪个 HAL | 依赖顺序不清 | gpio → pwm → led → lcd → encoder → audio |
| 想知道原来的实现 | 需要参考 | `reference/ridewind-esp/main/` |

## 协作问题

| 问题 | 解决方向 |
|------|---------|
| 两端协议不一致 | 以 `protocol-contract.md` 为准。以固件端实现为"硬件真值" |
| 两个对话改同一个文件 | Git 冲突。两端物理上不会冲突（Dart vs C） |
| 不知道上次做到哪 | 读 `session-handoff.md` |
| 架构决策不确定 | 看 `global-development-roadmap.md` 第4节"架构决策记录" |
| AI 偏离了 steering | 让它重新读 `global-development-roadmap.md` + 对应端的 `session-handoff.md` |

---

*创建日期: 2026-05-08*
