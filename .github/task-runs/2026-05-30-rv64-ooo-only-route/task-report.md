# RV64 OoO-Only Route Task Report

## 任务

用户要求 `npc/rv64` 不再保留顺序核/乱序核二选一配置，只保留乱序超标量相关路径，其他配置和路由直接删除。

## 修改

- `npc/rv64/Makefile`
  - 删除 `NPC_OOO_ALU_EXPERIMENT` 配置变量。
  - 删除 `-DNPC_OOO_ALU_EXPERIMENT` RTL/C++ 条件编译注入。
- `npc/rv64/vsrc/core/NpcCoreTop.v`
  - 删除 `ifndef NPC_OOO_ALU_EXPERIMENT` 的顺序核实例分支。
  - 删除 `u_inorder`、单提交 tie-off、顺序核 IRQ/flush/exit PC 路由。
  - RV64 core-top 现在固定为 `OooFetchAxiBridge + OooMemAxiBridge + OooAluFetchCore`。
- `npc/rv64/vsrc/sim/NpcSimTop.sv`
  - 删除 in-order cache/BPU 统计层次引用。
  - 删除 `NPC_OOO_ALU_EXPERIMENT` 条件统计分支。
  - 只保留 OoO bridge/core 的 cache、BPU lookup/resolve 和 OoO pipeline 统计。
- `npc/rv64/csrc/cpu/cpu-exec.cpp`
  - 删除 host 侧 `NPC_OOO_ALU_EXPERIMENT` 条件编译。
  - OoO commit-time control-flow 统计固定启用。
- `npc/rv64/vsrc/filelist.mk`
  - 默认 RV64 源集中移除顺序流水线专用模块：in-order core、IfStage/BranchPredictor、ICache/DCache、pipeline regs、CSR/RegisterFile、Rv32Multiplier/Divider 等。
  - 保留 OoO 实际依赖的 `DecodeStage/DecodeUnit/ImmGen/LSU/WBU/ALU/CompareUnit` 与 bus/bridge/ooo 模块。

## 验证

- 路由检查：
  - `rg "NPC_OOO_ALU_EXPERIMENT|u_inorder" npc/rv64`
  - 结果：无输出。
- Lint/build：
  - `make -C npc/sim BACKEND=rv64 clean && make -C npc/sim BACKEND=rv64 lint`
  - `make -C npc/sim BACKEND=rv64 -j4`
  - 结果：PASS；Verilator/C++ 命令不再包含 `-DNPC_OOO_ALU_EXPERIMENT`。
- 单项 smoke：
  - `ARCH=riscv64-npc ALL=add`
  - 结果：`HIT GOOD TRAP`，`cycles=755`、`commits=839`、`CPI=0.900`，并打印 `=== OoO Pipeline Statistics ===`。
- CPU-tests：
  - `AM_HOME=/home/lyg/PA/ysyx-workbench/abstract-machine make -C am-kernels/tests/cpu-tests ARCH=riscv64-npc run NPC_RUN_ARGS="--no-progress --max-cycles 2000000"`
  - 结果：`40/40 PASS`。
  - 平均 CPI `1.414`；最高 `dummy (46/12/CPI=3.833)`，最低 `shuixianhua (3429/6077/CPI=0.564)`，近平均 `hello-str (2128/1510/CPI=1.409)`。
- CoreMark：
  - `AM_HOME=/home/lyg/PA/ysyx-workbench/abstract-machine make -C am-kernels/benchmarks/coremark ARCH=riscv64-npc ITERATIONS=1000 run NPC_RUN_ARGS="--no-progress --max-cycles 1000000000"`
  - 结果：`CoreMark PASS 8 Marks`，`HIT GOOD TRAP`，`cycles=247287514`、`commits=317356136`、`CPI=0.779`。

## 结论

`npc/rv64` 已经没有顺序核/乱序核配置路由，RV64 默认构建就是乱序超标量路径；删路由后 CoreMark CPI 保持 `0.779`，满足上一轮性能基线。
