# OoO Sim Top Dual Commit

## 目标

把 ALU-only OoO 实验核从模块 testbench 推进到真实 Verilator 仿真边界：`NpcSimTop` 可以在显式实验构建下实例化 `OooAluFetchCore`，host 能正确消费同周期双提交，并用一个 raw ALU 程序证明这条路径可以从 DPI PMEM 取指、提交、`ebreak` GOOD TRAP。

## RTL 推导摘要

- 需求：默认 `NpcCore` 主线必须保持不变；实验路径只通过 `NPC_OOO_ALU_EXPERIMENT=1` 打开。实验核复用 IFU AXI-like read channel，不接 LSU，不承诺 AM 全程序。
- 协议：IFU 请求/响应继续走 `NpcAxiBus -> AxiDpiSlave`；实验路径的 LSU 输出全部 tie-off，输入响应仅作为 unused 观测。commit DPI 允许同一 posedge 被调用两次，调用顺序就是程序提交序。
- 状态机：`OooAluFetchCore` 原 fetch/dispatch/halt FSM 保持；新增 lane0 `ebreak` 在 `S_DISPATCH` 中优先于 unsupported trap，直接进入 `S_HALT` 并拉起 exit。lane1 `ebreak` 暂不做半包派发，仍属于未支持边界。
- 不变量：默认构建没有 `u_ooo_core`，实验构建没有 `u_core` 层次化引用；一个仿真周期最多记录两条 commit；每条 commit 的 GPR snapshot 表示该条提交后的架构状态；实验路径不产生 cache/BPU 统计事件。
- 数据通路：`NpcSimTop` 用 `ifdef` 切换 core 实例；实验路径把 `commit0/1` 分别映射到 `npc_commit_event`，把 `exit_valid` 映射到 `npc_exit_event`，把 `trap_valid` 映射到 `npc_trap_event`。host `cpu-exec.cpp` 从单个 `g_commit_event` 改成 2-entry `g_commit_events`。

## 改动

- `npc/single/Makefile`：新增 `NPC_OOO_ALU_EXPERIMENT=1` 构建开关，并让 lint/build 都传 Verilator define。
- `npc/single/vsrc/sim/NpcSimTop.sv`：新增 OoO 实验实例分支，默认流水线实例分支不变。
- `npc/single/csrc/cpu/cpu-exec.cpp`：commit 事件改为 2-entry 队列，每条事件保存提交后 GPR 快照。
- `npc/single/vsrc/ooo/OooAluFetchCore.v`：新增 lane0 `ebreak` exit 输出。
- `npc/single/vsrc/ooo/OooIntIssueQueue.v`：改为组合 next-state + 时序落库，解决 Verilator 顶层实例化时的数组 for-loop 非阻塞赋值不兼容。
- `OooRob/OooFreeList/OooRenameMap/OooAluDecodeBackend/OooIntBackend`：收敛实验顶层 lint 暴露的位宽与 unused 告警。

## 验证

- `make -C npc/single NPC_OOO_ALU_EXPERIMENT=1 lint`：PASS。
- `make -C npc/single BUILD_DIR=/tmp/npc-ooo-alu-sim-build NPC_OOO_ALU_EXPERIMENT=1 -j4`：PASS。
- `/tmp/npc-ooo-alu-sim-build/NpcSimTop /tmp/ooo-alu-ebreak.bin --no-progress -m 200`：GOOD TRAP，`cycles=29`、`commits=6`、`CPI=4.833`。
- OoO 定向套件 11 个 testbench：PASS。
- 默认 `make -C npc/single lint`：PASS。
- `make -C npc/single/testbench BUILD_DIR=/tmp/npc-single-full-tb5-build RESULT_DIR=/tmp/npc-single-full-tb5-results run`：38/38 PASS。
- 默认 `make -C npc/single -j4`：PASS。
- `AM_HOME=/home/lyg/PA/ysyx-workbench/abstract-machine make -C am-kernels/tests/cpu-tests ARCH=riscv32-npc ALL=add run`：GOOD TRAP，`cycles=1509`、`commits=838`、`CPI=1.801`。

## 结论

本轮完成了“真实仿真壳可切到 OoO 实验核”和“host 可处理双提交”的关键边界，后续扩展不再只能依赖孤立 testbench。

CPI=0.5 还未达成。实验 raw 程序 CPI 目前为 4.833，主要受前端串行两次取指和 ALU-only 范围限制；默认 AM 主线仍是顺序流水线 CPI=1.801。下一步应优先做取指带宽和 fetch buffer，再补 LSQ、branch checkpoint/rollback、CSR/trap，使实验路径逐步替代默认主线。
