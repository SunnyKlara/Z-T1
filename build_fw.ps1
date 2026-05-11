# ═══════════════════════════════════════════════════════════════
# ZCritical 固件构建脚本 (PowerShell)
#
# 用法:
#   .\build_fw.ps1                 # 编译
#   .\build_fw.ps1 set-target      # 设置芯片目标 esp32s3
#   .\build_fw.ps1 clean           # 清理构建
#   .\build_fw.ps1 full           # set-target + 编译
#   .\build_fw.ps1 flash           # 烧录
#   .\build_fw.ps1 monitor         # 串口监控
#   .\build_fw.ps1 build-flash     # 编译 + 烧录
#   .\build_fw.ps1 all             # 编译 + 烧录 + 监控
#
# 环境: ESP-IDF v5.3.5 安装在 C:\Espressif\frameworks\esp-idf-v5.3.5
# ═══════════════════════════════════════════════════════════════

param(
    [ValidateSet("set-target", "clean", "full", "flash", "monitor", "build-flash", "all", "build")]
    [string]$Action = "build"
)

$ErrorActionPreference = "Stop"
$IDF_PATH = "C:\Espressif\frameworks\esp-idf-v5.3.5"
$PROJECT_DIR = Join-Path $PSScriptRoot "firmware\zcritical-esp"

Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host " ZCritical ESP32-S3 Firmware Build" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

# ── 激活 ESP-IDF 环境 ──
if (-not (Test-Path (Join-Path $IDF_PATH "export.ps1"))) {
    Write-Host "ERROR: ESP-IDF 未找到: $IDF_PATH" -ForegroundColor Red
    Write-Host "请确认 ESP-IDF 已安装在指定路径，或修改本脚本第 30 行的 `$IDF_PATH" -ForegroundColor Yellow
    exit 1
}

Write-Host "Activating ESP-IDF environment..." -ForegroundColor Yellow
$env:IDF_PATH = $IDF_PATH
& "$IDF_PATH\export.ps1" *>&1 | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: ESP-IDF environment activation failed (exit code: $LASTEXITCODE)" -ForegroundColor Red
    exit 1
}
Write-Host "ESP-IDF environment ready" -ForegroundColor Green

# ── 切换到项目目录 ──
Push-Location $PROJECT_DIR

function Run-Idf {
    param([string]$Cmd, [string]$Description)
    Write-Host ""
    Write-Host "==> $Description" -ForegroundColor Yellow
    Write-Host "    idf.py $Cmd" -ForegroundColor DarkGray
    idf.py $Cmd 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Host ""
        Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Red
        Write-Host "BUILD FAILED (exit code: $LASTEXITCODE)" -ForegroundColor Red
        Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Red
        Pop-Location
        exit 1
    }
}

# ── 检查 partitions.csv ──
if (-not (Test-Path "partitions.csv")) {
    Write-Host "partitions.csv not found, copying from reference..." -ForegroundColor Yellow
    Copy-Item (Join-Path $PSScriptRoot "reference\ridewind-esp\partitions.csv") "partitions.csv" -Force
}

# ── 执行 ──
switch ($Action) {
    "set-target"  { Run-Idf "set-target esp32s3" "设置芯片目标" }
    "clean"       { Run-Idf "clean" "清理构建" }
    "full"        {
        Run-Idf "set-target esp32s3" "设置芯片目标"
        Run-Idf "build" "编译固件"
    }
    "build"       { Run-Idf "build" "编译固件" }
    "flash"       { Run-Idf "flash" "烧录固件" }
    "monitor"     { Run-Idf "monitor" "串口监控" }
    "build-flash" {
        Run-Idf "build" "编译固件"
        Run-Idf "flash" "烧录固件"
    }
    "all"         {
        Run-Idf "build" "编译固件"
        Run-Idf "flash" "烧录固件"
        Run-Idf "monitor" "串口监控"
    }
}

Pop-Location
Write-Host ""
Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Green
Write-Host "DONE: $Action" -ForegroundColor Green
Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Green
