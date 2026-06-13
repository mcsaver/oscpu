# Task Report

## 基本信息

- `task_id`: `2026-05-22-nemu-npc-feature-parity`
- `task_slug`: `nemu-npc-feature-parity`
- `graph_template`: `rv32-reference-loop`
- `graph_mode`: `static+dynamic`
- `status`: `completed`
- `owner`: `Codex`
- `started_at`: `2026-05-22`
- `updated_at`: `2026-05-22`

## 任务目标

- `source_request`: 用户要求把 NPC 已实现但 NEMU 缺失的部分补到 NEMU，并跑过 difftest。
- `goal`: 让 NEMU reference 支持当前 NPC 已实现的关键 machine CSR、CLINT 和 M-mode interrupt 参考语义，并通过 NPC -> NEMU difftest 回归。
- `scope`: NEMU RISC-V CSR/trap/CLINT、NEMU 物理地址分发、AM `riscv32-nemu` guest ISA 声明；不修改 NPC RTL 功能。

## 选图说明

- `selected_template`: `rv32-reference-loop`
- `why_this_graph`: 本任务本质是恢复 `am-kernels -> NPC(target) -> NEMU(reference)` 的可比较闭环。
- `dynamic_nodes_added`: `env-fix-zifencei`
- `why_dynamic_nodes_were_needed`: NEMU 回归暴露 `fence.i` 汇编阶段缺 `_zifencei`，属于 AM guest 编译参数与 NEMU 译码能力不一致。

## 节点概览

| node_id | owner_agent | status | inputs | outputs | evidence |
| ------- | ----------- | ------ | ------ | ------- | -------- |
| recall | Codex | completed | `.github/AGENTS.md`、memory、NPC study | 约束与缺口清单 | 已读项目规则、NEMU/NPC/difftest/AM 模块记忆 |
| compare-npc-nemu | Codex | completed | NPC `CsrFile/AxiLiteClint`、NEMU `inst.c/intr.c/paddr.c` | CSR/CLINT/interrupt 差距定位 | NEMU 缺 `mvendorid/marchid/mcycle/CLINT/isa_query_intr` |
| implement-reference | Codex | completed | 差距清单 | NEMU CSR/CLINT/interrupt 补丁与 AM `_zifencei` 补丁 | `make -C nemu -j4` PASS |
| build-ref | Codex | completed | NEMU 修改 | `riscv32-nemu-interpreter-so` | `make -C npc/single difftest-ref` PASS |
| verify | Codex | completed | NEMU/NPC/AM 修改 | NEMU 与 NPC difftest 回归 | NEMU cpu-tests 38/38 PASS；NPC difftest cpu-tests 38/38 PASS；`git diff --check` PASS |
| record | Codex | completed | 验证结论 | memory 与 task-run 记录 | 本目录与相关 memory 已更新 |

## 关键产物

- `artifacts`: NEMU reference 支持 CLINT MMIO、machine CSR、M-mode interrupt query；AM `riscv32-nemu` 声明 `_zifencei`。
- `logs_or_traces`: `/tmp/nemu-cputests.log`、`/tmp/npc-difftest-cputests.log`
- `linked_memory_updates`: `.github/memory/project-status.md`、`.github/memory/modules/nemu.md`、`.github/memory/modules/difftest.md`、`.github/memory/modules/abstract-machine.md`

## 当前阻塞点

- `blockers`: 无。
- `missing_dependencies`: 无。
- `risk_assessment`: NEMU 的 `mtime/mcycle` 是指令级近似，不与 NPC RTL cycle 精确对齐；后续若直接比较自然递增计数值或 timer 精确触发点，需要单独 difftest 同步/skip 设计。

## 下一步建议

1. 为 CLINT/MSIP 或 CSR identity 增加专门 smoke 测试，覆盖 reference 新能力。
2. 若要做 MTIP 长链 difftest，先设计 NPC 中断非提交周期与 NEMU `ref_exec(1)` 的对齐协议。

## 模板升级候选

- `repeated_dynamic_subgraph`: 无。
- `should_promote_to_static_template`: 否。
- `reason`: 本次只是 `rv32-reference-loop` 中补一个 AM guest 编译参数节点。

## 收尾结论

- `final_result`: 已补齐 NEMU 当前参考模型缺口，并恢复 NPC -> NEMU difftest cpu-tests 38/38 PASS。
- `evidence_summary`: NEMU build、reference so build、NEMU cpu-tests、NPC difftest cpu-tests、`git diff --check` 均通过。
- `notes`: 工作区仍有既有未跟踪 `ysyxSoC/`，本任务未处理。
