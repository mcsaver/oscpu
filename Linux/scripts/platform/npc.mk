# NPC RV64 Verilator 目标平台的默认构建命名空间。
# 该平台保留 NPC 长跑预算和带 PMU 的 OpenSBI 默认值，
# 可与 NEMU 平台同时构建而不共享 Linux/OpenSBI 输出目录。

LINUX_PLATFORM_DESC := NPC RV64 Verilator target platform
PLATFORM_DEFAULT_MAX_CYCLES := 3000000000
PLATFORM_OPENSBI_PROFILE := npc
PLATFORM_OPENSBI_DISABLE_PMU := 0
