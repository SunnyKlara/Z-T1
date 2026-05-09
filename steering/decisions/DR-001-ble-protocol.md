# DR-001: BLE 通信协议方案

| 字段 | 值 |
|------|-----|
| **状态** | 已确认 |
| **决策日期** | 2026-05-09 |
| **涉及模块** | 两端 |
| **决策者** | Klara |

## 1. 背景

RideWind（旧项目）使用了文本协议 `KEY:VALUE\n` 通过 BLE GATT 单 Characteristic（0xFFE1）与 APP 通信。在新项目 ZCritical 白板重建中，需要确认是否沿用此方案。

## 2. 方案对比

| 方案 | 描述 | 优点 | 缺点 | 评估 |
|------|------|------|------|------|
| A: GATT + 文本协议 | 单 Char (FFE1), `FAN:50\n` 格式, write-without-response + notify | 标准化, 人类可读, 灵活扩展, flutter_blue_plus 直接支持 | 文本解析有开销, 包体较大 | ✅ 选用 |
| B: GATT + 二进制协议 | struct 序列化, 二进制包 | 包体小, 解析快 | 调试困难, 扩展需同步修改 struct, 维护成本高 | ❌ 不适合小团队 |
| C: 多 Characteristic | 每个功能独立 Char UUID | 无需命令解析, 原生支持好 | GATT 表膨胀, ESP-IDF API 繁重, 扩展需两端改 Char 定义 | ❌ ESP32 GATT API 不支持 |

## 3. 最终选择

**方案 A: GATT + 文本协议**。

理由：
1. 命令最长不超过几十字节（Logo 上传除外），文本协议的传输开销微不足道
2. BLE MTU 247 字节足够容纳绝大多数命令，无需二进制压缩
3. 人类可读 → 调试工具直接看 LOG → 不需要专用协议分析器
4. 加新命令只需按格式添加一行，不需要改 struct、不需要两端同步序列化代码
5. 小团队最友好——维护成本最低
6. 协议格式已经是协议契约（`steering/specs/protocol-contract.md`），不需要重写

## 4. 放弃的方案

- **二进制协议**：包体更小（省 30-50%），但调试用不上、团队规模小不需要、新增命令代价大
- **多 Characteristic**：ESP-IDF `esp_ble_gatts_create_attr_tab` 定义 GATT 表已经繁琐，多 Char 会显著增加固件端代码量和 BUG 概率

## 5. 改进点（相比 RideWind）

| 问题 | RideWind | ZCritical |
|------|---------|-----------|
| 固件命令分发 | if-else 链 O(n) | hash 表 O(1) |
| APP 协议解析 | class 单例 300+ 行 | 纯函数, 拆分到 3-4 个文件 `protocol_parser.dart` / `command_builder.dart` / `response_router.dart` |
| 固件 MTU 重组 | 512B 线性缓冲 | 环形缓冲区, 防溢出 |
| Notify 拥塞 | 无重试 → 丢 ACK | 10次重试 + 20ms 延时 |

## 6. 实施步骤

1. APP 端: `data/datasources/protocol/protocol_parser.dart` — 纯函数 `Mapping<String,dynamic> parse(String raw)`
2. APP 端: `data/datasources/protocol/command_builder.dart` — `String cmd = build('FAN', [50])` → `"FAN:50\n"`
3. APP 端: `data/datasources/protocol/response_router.dart` — 按命令类型路由响应到对应 Provider
4. APP 端: `data/mappers/protocol_mapper.dart` — 协议字符串 → 领域模型
5. 固件端: `core/protocol/proto_parser.c` — hash 表命令分发
6. 固件端: `core/protocol/proto_ble.c` — BLE 收发 + 环形缓冲

## 7. 相关参考

- 协议契约: `steering/specs/protocol-contract.md` (第 1-7 节)
- 旧 APP BLE 参考: `reference/RideWind/lib/services/ble_service.dart`
- 旧固件 BLE 参考: `reference/ridewind-esp/main/services/ble_service.c`
- 已知陷阱: `steering/knowledge/known-pitfalls.md` (坑 1-3)
