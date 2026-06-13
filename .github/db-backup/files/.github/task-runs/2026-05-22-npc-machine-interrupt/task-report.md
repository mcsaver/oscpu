# Task Report

## 基本信息

- `task_id`: `2026-05-22-npc-machine-interrupt`
- `task_slug`: `npc-machine-interrupt`
- `graph_template`: `rv32-reference-loop`
- `graph_mode`: `static+dynamic`
- `status`: `completed`
- `owner`: `codex`
- `started_at`: `2026-05-22 19:20 CST`
- `updated_at`: `2026-05-22 20:09 CST`

## 任务目标

- `source_request`: 用户要求学习 RISC-V 特权级手册并为 NPC 实现中断功能。
- `goal`: 建立最小 M-mode 异步中断闭环，使 CLINT 的 `msip/mtimecmp` 能通过 CSR 仲裁触发精确 trap。
- `scope`: M-only、Direct `mtvec`、MSI/MTI/MEI；不包含 S-mode/delegation/PLIC/vectored `mtvec` 或 difftest 中断对齐专项。

## 选图说明

- `selected_template`: `rv32-reference-loop`
- `why_this_graph`: 本任务需要先从 RISC-V privileged spec 提取语义，再落到 RTL CSR/CLINT/流水线精确异常路径，并用 AM cpu-tests 回归。
- `dynamic_nodes_added`: `clint-irq-source`、`csr-interrupt-arbiter`、`pipeline-precise-irq`
- `why_dynamic_nodes_were_needed`: 既有工程只有 `mtime` 计数和 IRQ 输入预留，没有 `mtimecmp -> MTIP`、CSR interrupt side effect 或流水线接收点。

## 节点概览

| node_id | owner_agent | status | inputs | outputs | evidence |
| ------- | ----------- | ------ | ------ | ------- | -------- |
| `spec-study` | codex | completed | RISC-V privileged ISA manual, local CSR/CLINT notes | 中断条件、`mcause` interrupt bit、MTIP 触发规则 | 官方手册 snapshot: `https://riscv.github.io/riscv-isa-manual/snapshot/privileged` |
| `rtl-analysis` | codex | completed | `AxiLiteClint/CsrFile/PipelineControl/NpcCore` | 需求/协议/FSM/不变量/数据通路推导 | 对话记录与本报告 |
| `implementation` | codex | completed | RTL 与 testbench | CLINT pending、CSR 仲裁、EX 精确 interrupt trap | 修改 `vsrc/bus/core/sim` 与 `testbench` |
| `verification` | codex | completed | 模块单测、pipe test、lint/build、cpu-tests | 全部 PASS | 见 `evidence_summary` |
| `memory-update` | codex | completed | 项目记忆协议 | 更新 project status、NPC module note、task-run | `.github/memory/*` 与本目录 |

## 关键产物

- `artifacts`: `AxiLiteClint` 的 `msip/mtimecmp/mtime` 实现；`CsrFile` 的 interrupt pending/cause 仲裁与 trap side effect；`PipelineControl/NpcCore` 的 EX 精确 interrupt redirect/flush；`tb_npc_core_interrupt`。
- `logs_or_traces`: `/tmp/npc-interrupt-tests-serial`、`/tmp/npc-interrupt-pipe`、cpu-tests 控制台 PASS 汇总。
- `linked_memory_updates`: `.github/memory/project-status.md`、`.github/memory/modules/npc.md`。

## 当前阻塞点

- `blockers`: 无。
- `missing_dependencies`: 若要和 NEMU difftest 精确对齐中断，需要后续实现 interrupt 注入/skip 策略。
- `risk_assessment`: 当前只覆盖 Direct `mtvec` 和 M-mode；真实 OS timer interrupt 还需要软件正确设置 `mtimecmp/mie/mstatus` 并处理 `mret` 闭环。

## 下一步建议

1. 用最小 bare-metal 程序覆盖 `mret` 返回后继续执行、重设 `mtimecmp` 清 MTIP、软件中断 `msip` set/clear。
2. 规划 difftest 中断同步策略，避免异步 trap 与参考模型提交边界误比对。

## 模板升级候选

- `repeated_dynamic_subgraph`: `spec -> csr semantics -> pipeline precise trap -> directed RTL test`
- `should_promote_to_static_template`: `true`
- `reason`: CSR/trap 类任务会反复出现，适合沉淀成固定硬件语义落地流程。

## 收尾结论

- `final_result`: NPC 已具备最小 M-mode machine interrupt 功能闭环。
- `evidence_summary`: `make -C npc/single/testbench RESULT_DIR=/tmp/npc-interrupt-tests-serial run` 26/26 PASS；`make -C npc/single/testbench PIPE_RESULT_DIR=/tmp/npc-interrupt-pipe pipe_test` PASS；`make -C npc/single lint` PASS；`make -C npc/single -j14` PASS；`make -C am-kernels/tests/cpu-tests ARCH=riscv32-npc run` 38/38 PASS；本地显示 Difftest OFF；本轮 RTL/test 路径 `git diff --check` PASS。
- `notes`: 曾遇到并行运行同一 testbench build 目录导致 `.vvp` 生成文件竞争的伪错误，串行重跑后确认不是 RTL 问题。
