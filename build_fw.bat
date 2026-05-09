@echo off
REM ZCritical 固件一键构建
REM 用法: build_fw.bat [set-target|build|flash|monitor]
REM 必须已安装 ESP-IDF 并配置好环境变量

cd /d firmware\zcritical-esp

if "%1"=="set-target" (
    echo === 设置芯片目标 ===
    idf.py set-target esp32s3
) else if "%1"=="flash" (
    echo === 烧录 ===
    idf.py flash
) else if "%1"=="monitor" (
    echo === 串口监控 ===
    idf.py monitor
) else (
    echo === 编译 ===
    idf.py build
)

cd /d ..\..
