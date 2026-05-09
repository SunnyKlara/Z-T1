# ═══════════════════════════════════════════════════════════════
# STEER: 反臃肿 | max_lines=20 | scope=firmware | 修改前读 anti-bloat.md
#
# 职责: 主组件构建配置 — 注册源文件目录
# ═══════════════════════════════════════════════════════════════
idf_component_register(
    SRCS "main.c"
    INCLUDE_DIRS "."
    REQUIRES nvs_flash
)
