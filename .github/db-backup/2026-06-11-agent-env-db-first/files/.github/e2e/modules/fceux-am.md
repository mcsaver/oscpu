# fceux-am E2E Contract

- **范围**: NES emulator on AM/NEMU/NPC、ROM 生成、图形/输入/音频空桩边界。
- **上游**: abstract-machine、am-kernels、NEMU/NPC IOE。
- **下游**: AM device loop、游戏工作负载回归。
- **L0 gate**: `fceux-am-contract` 检查 Makefile、agent 和 memory。
- **L1 gate**: 后续无 ROM build smoke + 有 ROM 运行 smoke。
- **证据**: ROM table、build log、guest output、BAD/GOOD TRAP。
- **升级路线**: 将无 ROM/有 ROM 两类 gate 分开，避免资源缺失误判。
