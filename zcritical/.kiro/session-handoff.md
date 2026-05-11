# APP端 - 会话交接 (2026-05-11)

## 硬事实

- 用户有 ESP32-S3 开发板在手边，随时可以烧录测试
- 不需要问"能不能实机测"——代码写好用户会自动验证

## 当前状态

Phase 1 APP骨架 (A1+A2+A3) 全部完成。**BLE 连接已验证成功** ✅

### BLE 连接链路（全通）

物理连接 → MTU=247 → 连接优先级=high → discoverServices(3服务) → FFE0/FFE1 匹配 → setNotifyValue → **连接完成 → 进入主页** ✅

服务清单: `1801`(GAP), `1800`(GATT), `ffe0`(自定义, char=`ffe1` write+notify)

### 性能优化（2026-05-11）

| 优化项 | 效果 |
|--------|------|
| 扫描早停（发现 T1 立即停止） | 扫描从 ~12s → ~2-3s |
| MTU 跳过（检测已达标不二次协商） | 连接从 ~1.4s → ~1.1s |
| UUID 防御性处理（length>=8 判断+try/catch） | 消灭 RangeError 崩溃 |

### 历史修复（已解决，保留记录）

- `flutter_blue_plus 1.35.2`: `device.discoverServices()` 替代废弃的 `device.services`
- `device_scan_screen.dart`: 对接真实 BLE 扫描 + 声波动画
- 固件广播: `include_name=true`，设备名 "T1" 在广播包中
- 权限: Android `BLUETOOTH_CONNECT` 运行时请求（MIUI 必须）
- UUID 短格式: ESP32 返回 4 字符 UUID（如 `1800`），substring 越界已防御

代码在 `app/a3-ble-connect` 分支，未合入 main。

## 开发经验文档

已记录 → `steering/knowledge/ble-dev-experience.md`（5 个坑 + 调试方法论 + 架构要点）

## 下一步

BLE 连接已打通。下一步按用户指示走：命令收发验证、UI 面板对接真实数据、或固件端精装。

## Git 分支

```
main
  app/a1-a2-entry-usercenter (已合并)
  app/a3-ble-connect (当前)
```
