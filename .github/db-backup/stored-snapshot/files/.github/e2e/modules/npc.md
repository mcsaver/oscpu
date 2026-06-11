# npc E2E Contract

- **范围**: `npc/sim`、`npc/single`、`npc/soc`、`npc/rv64`。
- **上游**: am-kernels 镜像、NEMU reference、ysyxSoC CPU ABI。
- **下游**: DiffTest、SoC、STA/PPA、RV64 Linux。
- **L0 gate**: `npc-sim-contract` 和 `npc-sim-status`。
- **L1 gate**: `npc-cpu-tests-full` 通过 `riscv32-npc` 全量 `am-kernels/tests/cpu-tests` 验证 target 路径；后端跟随 `npc/sim` 当前配置，不在 e2e 中偷偷切换。
- **证据**: backend status、全量 cpu-tests PASS 汇总、NPC log、cycles/commits/CPI；若当前后端启用 DiffTest，则同时记录 DiffTest 结果。
- **升级路线**: 分别升级 `npc-single`、`npc-soc`、`npc-rv64` 的 smoke/regression profile。
