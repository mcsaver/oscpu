# Dispatch Log

## 节点

| node_id | depends_on | 动作 | 结果 |
| --- | --- | --- | --- |
| recall | - | 读取 AGENTS、Copilot 指令、project/known issues、NPC memory、RTL workflow、study 索引和 BPU 相关源码 | 完成 |
| design | recall | 明确 IF predict / EX resolve 边界，确定 gshare index 需要随流水传递 | 完成 |
| implement-rtl | design | 修改 `BranchPredictor`、`IfStage`、流水寄存器和 `NpcCore` | 完成 |
| implement-stats | design | 在 `NpcSimTop` 与 `cpu-exec.cpp` 加 BPU lookup/resolve 统计 | 完成 |
| tests | implement-rtl, implement-stats | 更新 testbench 并运行模块/RTL/AM 回归 | 完成 |
| record | tests | 更新 memory 与 task-run 记录 | 完成 |

## 关键证据

- 模块级回归：`/tmp/npc-bpu-stats-tests`，21/21 PASS。
- Verilator lint：PASS。
- Verilator build：PASS。
- 定向 cpu-tests：`if-else` PASS，`switch/recursion/compressed` PASS。
- 全量 cpu-tests：38/38 PASS。
