# RV64 Direct RAS Return CPI 优化

## 背景

上一轮已完成 bridge-local ITLB/DTLB 与分页后物理 D-cache 命中路径，`branch-fallthrough-save` 仍显示大量 `JALR/return` 等待：`cycles=1995/commits=1457/CPI=1.369`，`control wait jump=965`。本轮继续处理用户要求中的 branch/jump wait，优先利用已有 RAS return fast path。

## 改动

- `npc/rv64/vsrc/ooo/OooAluFetchCore.v`: 将 `ENABLE_DIRECT_RAS_RET` 从 `1'b0` 改为 `1'b1`。满足 `jalr x0, x1/x5, 0`、RAS reliable/non-empty 时，前端直接以 RAS top redirect，并向 backend 派发 return uop。
- `npc/rv64/testbench/tests/tb_ooo_alu_fetch_core.sv`: 将过时的 `u_int_backend.fast_branch_resolve_valid_q` 层级窥探改为当前 `dut.core_dispatch_branch_resolve_valid_w`。

保留的安全边界：

- `satp/sfence.vma` 提交路径已有 RAS/JALR/branch target 预测状态清理。
- `sv39-ras-relocate` 继续验证跨地址空间切换后不使用低地址旧 RAS target。
- call/return 仍通过既有 backend uop/ROB 路径提交，direct path 只提前取指 redirect。

## 验证

- `make -C npc/rv64/testbench TESTS="tb_ooo_priv_system tb_ooo_sv39_boot tb_ooo_mem_axi_bridge" RESULT_DIR=/tmp/rv64tb-ras-ret-reliable LOG_DIR=/tmp/rv64tb-ras-ret-reliable/logs run`
  - 3/3 PASS。
- `make -C am-kernels/tests/cpu-tests ARCH=riscv64-npc ALL="branch-fallthrough-save sv39-ras-relocate sbi-ipi-reset-hsm linux-mini-boot plic-sirq uart-plic-sirq" run NPC_RUN_ARGS="--no-progress --max-cycles 20000000"`
  - 6/6 PASS。
- `make -C am-kernels/tests/cpu-tests ARCH=riscv64-npc run NPC_RUN_ARGS="--no-progress --max-cycles 20000000"`
  - 56/56 PASS，日志见 `cpu-tests.log`。
- `make -B -C npc/rv64 -j1`
  - PASS。
- `git diff --check`
  - PASS。

## 性能结果

上一轮 TLB/physical D-cache 基线：`cycles=188587/commits=148426/weighted CPI=1.271`。

本轮 direct RAS return：`cycles=183747/commits=148426/weighted CPI=1.238`。

总 cycles 减少 `4840`，未发现 CPU-test 单项 cycles regression。

代表样本：

- `branch-fallthrough-save`: `1995->1597 cycles`，`CPI 1.369->1.096`，`jump wait 965->0`。
- `matrix-mul`: `6504->5592 cycles`。
- `recursion`: `6432->6038 cycles`。
- `linux-mini-boot`: `18176->18154 cycles`。
- `sv39-ras-relocate`: 保持 `6972/2632/CPI=2.649`，跨 `satp` RAS 边界仍正确。

## 备注

`tb_ooo_alu_fetch_core` 的陈旧层级引用已修，但该 testbench 行为断言仍与当前 RV64 privilege/LSU/exit 协议不同步；临时把 direct RAS 开关关回时同样失败，说明不是本轮 RAS 优化造成。详见 known issue [33]。
