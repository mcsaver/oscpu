# RV64 Sv39 Page-Fault Precise Trap

## 目标

- 在 `npc/rv64` OoO core 中把 IFU/LSU Sv39 page/access fault 接入 CSR 精确异常路径。
- 扩展“小型 Linux 启动”测试，使其覆盖新接入的复杂异常路径。
- 保留已达成的 RV64 OoO 功能/构建回归，并记录 CPI 复验状态。

## RTL 推导

### 1. 需求

Linux 早期启动不仅需要 Sv39 success-path translation，还需要 page fault 能按 RISC-V 特权规范进入 trap handler：`sepc/scause/stval` 或 `mepc/mcause/mtval` 必须在精确异常边界更新，且异常目标由 `medeleg/stvec/mtvec` 决定。此前 IFU fetch fault 仍走前端 fatal trap，LSU page fault 虽能被 memory bridge 标注为 page fault，但后端 commit 的 `cause/tval` 没有透出到 `OooAluFetchCore` 的 CSR trap 输入。

### 2. 协议规则 / 状态机

- 后端 load/store page/access fault 由 ROB head commit 暴露，是精确异常点。
- `commit0` 异常优先；若 `commit0` 正常、`commit1` 异常，则 `commit0` 可以同拍提交，trap PC/cause/tval 来自 `commit1`。
- commit 异常当拍送 `CsrFile.trap_mem_*`，随后打一拍 `core_trap_flush_q` 清空 OoO 后端和前端年轻状态，避免组合信号反向驱动 slice `flush_i`。
- IFU instruction page/access fault 属于尚未进入后端的同步异常，前端先 `stop_pending` 等更老 ROB/IQ drain，drain 完成当拍送 `CsrFile.trap_ex_*` 并跳 `csr_trap_target`。
- `EBREAK` 继续作为实验壳退出边界，不改为架构 trap。

### 3. 不变量 / 数据通路

- `stval/mtval` 对 IFU fault 为 faulting PC，对 LSU fault 为 effective address。
- CSR delegation 仍由 `CsrFile` 统一处理，前端只负责提供精确 `pc/cause/tval`。
- 异常 redirect 清空 fetch FIFO/outstanding/branch prefetch/spec checkpoint/pending 控制状态，防止错路包或年轻 ROB 项在 handler 之后提交。
- 不把 commit-exception 组合信号直接接入 `OooAluCoreSlice.flush_i`，避免 Icarus/Verilator 0-time 组合反馈。

### 4. RTL 落点

- `npc/rv64/vsrc/ooo/OooAluCoreSlice.v`
  - 新增 `commit0_cause_o/commit0_tval_o/commit1_cause_o/commit1_tval_o` 输出。
- `npc/rv64/vsrc/ooo/OooAluFetchCore.v`
  - 新增 `pending_arch_trap_q`、CSR trap mux、commit exception trap path、`core_trap_flush_q`。
  - `trap_mem_*` 接后端 commit exception；`trap_ex_*` 接 ecall 与 front-end pending arch trap。
- `npc/rv64/testbench/tests/tb_ooo_sv39_boot.sv`
  - 扩展 S-mode handler，分别覆盖 ecall、load page fault、instruction page fault 的 `scause/sepc/stval`。
  - Root page table 仅映射 VPN2=2，其他 PTE 显式返回 0，避免未知 PTE 误命中。

## 验证

- PASS: `make -C npc/rv64/testbench TESTS="tb_ooo_sv39_boot" RESULT_DIR=/tmp/rv64-sv39-fault run`
- PASS: `make -C npc/rv64/testbench TESTS="tb_ooo_sv39_boot tb_ooo_int_backend tb_ooo_priv_system" RESULT_DIR=/tmp/rv64-sv39-fault-focused run`
- PASS: `make -C npc/sim BACKEND=rv64 lint`
- PASS: `make -C npc/sim BACKEND=rv64 -j4`
- PASS: `make -C am-kernels/tests/cpu-tests ARCH=riscv64-npc run NPC_RUN_ARGS="--no-progress -m 0"`，40/40 PASS

## 未完成 / 风险

- CoreMark `ITERATIONS=1000` 本轮复跑在运行中触发 WSL `Wsl/Service/E_UNEXPECTED`/崩溃，未获得新的 CPI 复验证据。最近一次完整 CoreMark 证据仍是 `2026-05-30-rv64-sv39-bridge` 中的 `cycles=247287514/commits=317356136/CPI=0.779`。
- 当前测试是小型 Linux 启动模拟，不等于真实 Linux 已启动；仍缺 SBI、PLIC、virtio、DTB、真实 kernel/rootfs 加载和更完整平台中断/设备模型。
- `npc/rv64/testbench` 全量仍受历史 `tb_ooo_alu_fetch_core` 旧预期阻塞，本轮只复跑 focused gate。
