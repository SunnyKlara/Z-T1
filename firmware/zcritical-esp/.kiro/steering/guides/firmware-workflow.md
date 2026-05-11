# 固件端 — 构建流程指南

> **优先级**: CRITICAL — 每次对话必须能独立构建
> **维护者**: AI

---

## 一、环境要求

| 软件 | 版本 | 安装路径 |
|------|------|---------|
| ESP-IDF | v5.3.5 | `C:\Espressif\frameworks\esp-idf-v5.3.5` |
| Python | 3.11 | `C:\Espressif\python_env\idf5.3_py3.11_env` |
| Git | 2.44+ | `C:\Espressif\tools\idf-git` |

### Windows 环境变量

每次构建前必须激活 ESP-IDF 环境：

```powershell
# 方法 1: 使用构建脚本（推荐）
.\build_fw.ps1 full          # set-target + build
.\build_fw.ps1 build        # 仅 build
.\build_fw.ps1 flash        # 仅烧录
.\build_fw.ps1 monitor      # 仅监控
.\build_fw.ps1 build-flash  # build + 烧录
.\build_fw.ps1 all          # build + 烧录 + 监控

# 方法 2: 手动激活环境
cd C:\Espressif\frameworks\esp-idf-v5.3.5
.\export.ps1
idf.py build
idf.py flash
idf.py monitor
```

### Linux/macOS

```bash
. $HOME/esp/esp-idf-v5.3.5/export.sh
idf.py build
```

---

## 二、构建命令速查

| 命令 | 说明 | 预期时间 |
|------|------|---------|
| `.\build_fw.ps1 full` | 首次：set-target + 编译 | ~3-5 min |
| `.\build_fw.ps1 build` | 增量编译 | ~30-60s |
| `.\build_fw.ps1 flash` | 烧录 | ~10s |
| `.\build_fw.ps1 monitor` | 串口监控 | — |
| `.\build_fw.ps1 clean` | 清理构建产物 | — |
| `.\build_fw.ps1 build-flash` | 编译 + 烧录 | ~1 min |

---

## 三、首次构建流程

```
1. 打开 PowerShell，进入项目根目录
2. 运行: .\build_fw.ps1 full
3. 等待编译完成（零错误零警告）
4. 运行: .\build_fw.ps1 flash    (烧录)
5. 运行: .\build_fw.ps1 monitor  (监控日志)
6. 用手机 BLE 扫描，确认设备名 "T1" 出现
```

---

## 四、常见问题

### idf.py 找不到

**原因**: 未激活 ESP-IDF 环境。
**解决**: 必须先运行 `.\build_fw.ps1`（脚本内已自动激活）。

### partitions.csv 找不到

**原因**: `sdkconfig.defaults` 引用了 `partitions.csv`，但文件不存在。
**解决**: `build_fw.ps1` 会自动从 `reference/ridewind-esp/partitions.csv` 复制。

### BLE 广播看不到 "T1"

**排查步骤**:
1. 检查串口日志是否有 "Advertising started"
2. 检查 BLE 参数（Service UUID 0xFFE0, Char UUID 0xFFE1）
3. 检查手机 BLE 扫描 App 是否支持 BLE 4.2

---

## 五、构建产物

```
firmware/zcritical-esp/build/
├── zcritical-esp.bin    <- 主固件
├── bootloader/          <- 引导程序
├── partition_table/     <- 分区表
└── esp-idf/             <- IDF 库
```

---

## 六、AI 构建检查清单

每次 `idf.py build` 后检查：

- [ ] 零 Error（必须）
- [ ] 零 Warning（必须）
- [ ] 输出包含 `zcritical-esp.bin`
- [ ] 输出包含 `bootloader/bootloader.bin`
- [ ] BUILD SUCCESSFUL

---

*创建: 2026-05-11*
