# ═══════════════════════════════════════════════════════════════
# STEER: 反臃肿 | max_lines=30 | scope=firmware | 修改前读 anti-bloat.md
#
# 职责: ESP-IDF 顶层构建配置
# ═══════════════════════════════════════════════════════════════
cmake_minimum_required(VERSION 3.16)
include($ENV{IDF_PATH}/tools/cmake/project.cmake)
project(zcritical-esp)
