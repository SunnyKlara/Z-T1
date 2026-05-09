# ⚠️ 固件端开发流程规范

> **优先级**: CRITICAL — 和 APP 端同样的契约驱动模式
> **作用域**: 固件端 — 所有 C 代码改动遵循此流程
> **对标**: zcritical/.kiro/steering/contract-driven-collaboration.md

---

## 一、核心理念：先定接口，再写实现

```
嵌入式 C 代码最怕的：
  ❌ "先写着试试" → 函数签名不对 → 调用方全得改
  ❌ "这里加个全局变量" → 其他地方不知道 → 竞态 Bug
  ❌ "这个 case 我直接塞 main.c" → 一路膨胀到 893 行
  
固件开发同样需要设计契约：
  不是"写完再改"，而是"确认再写"。
```

---

## 二、三层开发流程

### 第一层：功能契约

用结构化模板描述需求：

```yaml
Feature: 新增 BLE 命令 START_LIGHT

Data:
  - light_mode: uint8_t, 0-2 (0=off, 1=manual, 2=auto)
  - light_brightness: uint8_t, 0-100

Actions:
  - set_light_mode(uint8_t mode) → OK:START_LIGHT / ERR:START_LIGHT:reason
  - get_light_mode() → 返回当前模式

Protocol:
  - 命令: START_LIGHT:mode:brightness\n
  - 响应: OK:START_LIGHT\r\n
  - 查询: GET:START_LIGHT → START_LIGHT_REPORT:mode:brightness\r\n

Affected files:
  - 新增 cmd_type_t 枚举值: CMD_START_LIGHT, CMD_GET_START_LIGHT
  - protocol.c: 新增解析 case
  - main.c (或 command_dispatch.c): 新增 dispatch case
  - app_state.h: 可选新增字段

Constraints:
  - 不改变已有命令格式
  - 必须先更新 protocol-contract.md
```

### 第二层：设计契约

AI 输出具体的技术方案：

```
【技术方案】

1. protocol.h - 新增枚举
   typedef enum {
       // ... existing ...
       CMD_START_LIGHT,      // START_LIGHT:mode:brightness
       CMD_GET_START_LIGHT,  // GET:START_LIGHT
   } cmd_type_t;

   新增 param union 字段（如需要）

2. protocol.c - 新增解析
   在 parse_command() 中添加:
   - 匹配 "START_LIGHT:%d:%d" → cmd.type = CMD_START_LIGHT
   - 匹配 "GET:START_LIGHT" → cmd.type = CMD_GET_START_LIGHT

3. command_dispatch.c - 新增处理
   case CMD_START_LIGHT:
       if (mode > 2) { ble_notify_err("START_LIGHT:INVALID_MODE"); break; }
       g_app_state.light_mode = mode;
       g_app_state.light_brightness = brightness;
       if (mode == 1) apply_manual_brightness(brightness);
       if (mode == 2) start_auto_light();
       ble_notify("OK:START_LIGHT");
       break;

4. app_state.h - 新增字段
   // ══ 灯光 ══  (上限: 5个字段)
   uint8_t light_mode;       // 0=off, 1=manual, 2=auto
   uint8_t light_brightness; // 0-100

5. steering/protocol-contract.md - 新增命令定义

文件影响:
  修改: protocol.h (+3行), protocol.c (+10行), command_dispatch.c (+25行)
  修改: app_state.h (+2字段)
  修改: steering/protocol-contract.md (+5行)
  预估总量: ~45行，不超任何文件的限制

确认？
```

### 第三层：实现

按契约写代码 → 编译通过 → 检查行数 → 提交。

---

## 三、固件端对应的"新功能三步走"

### 和 APP 端防臃肿纲领第 4 条一致：

```
Q1: 这个功能属于哪个域？
    (风扇/PWM / 加湿器 / LED / 速度 / UI / 音频 / Logo / BLE / WiFi / 存储 / ...)

Q2: 这个域对应的文件在哪？
    (列出具体 .c 文件路径)

Q3: 现有文件能容纳吗？
    - 职责匹配吗？（检查文件头部的"不做什么"）
    - 加了之后行数还在限制以内吗？
    → 任何一个答案是"否"，新建文件
```

---

## 四、编译验证铁律

**每一层写完必须编译通过才能进入下一层。**

```bash
# 固件编译验证
idf.py build

# 如果失败 → 不继续下一步
# 如果通过 → 进入下一层
```

和 APP 端的 `flutter analyze` 对应。

---

## 五、协议变更流程

```
1. 先更新 steering/protocol-contract.md
   → 添加新命令定义
   → 标注 (PENDING: 固件已实现, APP待实现) 或 (PENDING: 固件待实现, APP已实现)

2. 固件端实现
   → protocol.h: 新增枚举
   → protocol.c: 新增解析
   → command_dispatch.c: 新增 dispatch case
   → 编译验证

3. 更新 UX 测试大纲
   → 在对应章节添加新命令的测试用例

4. 更新 protocol-contract.md
   → 将 PENDING 改为对应状态
```

---

## 六、提交规范

```
提交格式:
  feat(fw): 做什么
  fix(fw): 修什么
  refactor(fw): 重构什么

示例:
  feat(fw): add START_LIGHT command
  fix(fw): encoder rotation direction reversal bug
  refactor(fw): split main.c into dispatch + logo_receiver
```

每次提交只做一件事。

---

*创建日期: 2026-05-08*
