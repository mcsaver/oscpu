# Dispatch Log

## 基本信息

- `task_id`: `2026-05-22-npc-machine-interrupt`
- `task_slug`: `npc-machine-interrupt`
- `graph_template`: `rv32-reference-loop`
- `log_policy`: `append-only`

## 记录格式

每次节点派发、状态变化、失败恢复、handoff 或证据补充时，追加一个条目。

---

### [2026-05-22 19:20] `spec-study` - `completed`

- `owner_agent`: `codex`
- `trigger`: 用户要求学习 RISC-V 特权级手册并实现中断功能。
- `depends_on`: 项目约束文档与 NPC module memory。
- `inputs`: RISC-V privileged ISA manual snapshot、`.github/AGENTS.md`、NPC CSR/CLINT 笔记。
- `action`: 提取 M-mode interrupt 条件、`mip/mie/mstatus` 关系、`mcause` interrupt bit、`mtimecmp -> MTIP` 语义。
- `outputs`: 限定实现范围为 M-only、Direct `mtvec`、MSI/MTI/MEI。
- `evidence`: 官方手册 `https://riscv.github.io/riscv-isa-manual/snapshot/privileged`。
- `handoff_to`: `rtl-analysis`
- `next_step`: 推导 CSR/CLINT/流水线接入点。
- `notes`: 不实现 S-mode/delegation/PLIC/vectored `mtvec`。

### [2026-05-22 19:35] `rtl-analysis` - `completed`

- `owner_agent`: `codex`
- `trigger`: spec 语义已收敛。
- `depends_on`: `spec-study`
- `inputs`: `AxiLiteClint.v`、`CsrFile.v`、`PipelineControl.v`、`NpcCore.v`、`NpcSimTop.sv`。
- `action`: 分析调用链和数据流，确定 EX 精确边界接收中断，CSR side effect 优先级为 MEM fault > EX exception > IRQ trap > MRET > CSR write。
- `outputs`: RTL 修改计划和不变量：同拍最多一个 trap side effect、硬件 pending 不被 CSR 写清、被中断指令不提交、不更新 BPU。
- `evidence`: 代码阅读与对话中的 RTL 推导。
- `handoff_to`: `implementation`
- `next_step`: 修改 CLINT、CSR、流水线控制与顶层接线。
- `notes`: `mtimecmp` reset 取全 1，避免 reset 后立即 MTIP。

### [2026-05-22 19:55] `implementation` - `completed`

- `owner_agent`: `codex`
- `trigger`: RTL 推导完成。
- `depends_on`: `rtl-analysis`
- `inputs`: 现有 RTL 与 testbench。
- `action`: 实现 `msip/mtimecmp/MTIP`，新增 CSR interrupt pending/cause 输出和 IRQ trap 输入，流水线加入 interrupt flush/redirect/fatal 处理，新增 core interrupt 定向测试。
- `outputs`: `AxiLiteClint/CsrFile/PipelineControl/NpcCore/NpcSimTop` 与 testbench 更新。
- `evidence`: 源码修改完成。
- `handoff_to`: `verification`
- `next_step`: 运行模块、流水线、lint/build 和 AM 回归。
- `notes`: 新增 `tb_npc_core_interrupt` 验证 timer interrupt 杀掉下一条指令并写入 `mcause/mepc/mstatus`。

### [2026-05-22 20:08] `verification` - `completed`

- `owner_agent`: `codex`
- `trigger`: 实现完成。
- `depends_on`: `implementation`
- `inputs`: 更新后的 RTL/testbench。
- `action`: 串行运行模块回归、pipe test、lint、Verilator build、AM cpu-tests。
- `outputs`: 全部 PASS。
- `evidence`: `make -C npc/single/testbench RESULT_DIR=/tmp/npc-interrupt-tests-serial run` 26/26 PASS；`make -C npc/single/testbench PIPE_RESULT_DIR=/tmp/npc-interrupt-pipe pipe_test` PASS；`make -C npc/single lint` PASS；`make -C npc/single -j14` PASS；`make -C am-kernels/tests/cpu-tests ARCH=riscv32-npc run` 38/38 PASS；`git diff --check` PASS。
- `handoff_to`: `memory-update`
- `next_step`: 写项目记忆和 task-run。
- `notes`: 曾出现同一 build 目录并行写 `.vvp` 的伪错误，串行重跑确认通过。

### [2026-05-22 20:09] `memory-update` - `completed`

- `owner_agent`: `codex`
- `trigger`: 验证完成。
- `depends_on`: `verification`
- `inputs`: 验证结果与本轮设计结论。
- `action`: 更新 `.github/memory/project-status.md`、`.github/memory/modules/npc.md` 并创建本 task-run。
- `outputs`: 项目记忆同步完成。
- `evidence`: 本目录 `task-report.md` 与 `dispatch-log.md`。
- `handoff_to`: null
- `next_step`: 可继续做 `mret`/software interrupt/difftest interrupt 对齐专项。
- `notes`: 本轮没有新增 known issue。
