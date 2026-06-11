# hardware-flow E2E Contract

- **范围**: `am-kernels -> abstract-machine -> nemu/npc/sim -> difftest` 的跨模块编排。
- **上游**: `abstract-machine`、`am-kernels`、`nemu`、`npc-sim`。
- **下游**: `npc`、`difftest`、`ysyx-soc`、`yosys-sta`。
- **L0 gate**: `npc-sim-status` 记录真实后端。
- **L1 gate**: `reference/full` profile 调用 `scripts/am-regression.sh`。
- **证据**: `status.txt`、NEMU/NPC 日志、task-run 节点表。
- **升级路线**: 把参考/target 产物标准化为可比较 JSON 摘要。
