# Task Report

## 基本信息

- `task_id`: `2026-05-19-npc-nemu-gap-cputest-diff`
- `task_slug`: `npc-nemu-gap-cputest-diff`
- `graph_template`: `rv32-reference-loop`
- `graph_mode`: `static`
- `status`: `completed`
- `owner`: `codex`
- `started_at`: `2026-05-19 22:07 CST`
- `updated_at`: `2026-05-19 22:17 CST`

## 任务目标

- `source_request`: 对比 NEMU 和 NPC，确认还有哪些功能未实现，补齐后跑全量 cpu-tests difftest。
- `goal`: 以当前源码和真实回归判断 `riscv32-npc` 是否仍缺少 cpu-tests 所需功能。
- `scope`: NEMU/NPC RV32 ISA 与 AM cpu-tests 路径；不把 NEMU 当前额外的可选 M/B/C、cache/BPU 性能模型或更完整设备能力纳入本轮必须实现范围。

## 选图说明

- `selected_template`: `rv32-reference-loop`
- `why_this_graph`: 本轮需要用 NEMU/Spike 参考路径和 NPC/Verilator 目标路径做可比较验证。
- `dynamic_nodes_added`: 无
- `why_dynamic_nodes_were_needed`: 无真实失败点，未扩展动态 debug 图。

## 节点概览

| node_id | owner_agent | status | inputs | outputs | evidence |
| ------- | ----------- | ------ | ------ | ------- | -------- |
| recall | codex | completed | AGENTS、copilot、memory、npc study 笔记 | 约束与历史状态摘要 | 已读取 `.github/AGENTS.md`、`.github/copilot-instructions.md`、相关 memory 与 study 文件 |
| compare-scope | codex | completed | NEMU/NPC 配置、AM makefile、NPC DecodeUnit/NpcCore/difftest | `riscv32-npc` cpu-tests 范围为 `rv32i_zicsr`，NEMU 额外 M/B/C/cache/BPU 不属本轮阻塞 | `abstract-machine/scripts/riscv32-npc.mk` 固定 `-march=rv32i_zicsr` |
| build-ref | codex | completed | 当前工作区源码 | NPC difftest reference 与仿真器可用 | `make -C npc/single difftest-ref`、`make -C npc/single lint`、`make -C npc/single` 通过 |
| npc-cputest-diff | codex | completed | `riscv32-npc` 全量 cpu-tests | 35/35 PASS | `timeout 300s make -C am-kernels/tests/cpu-tests ARCH=riscv32-npc run NPC_RUN_ARGS='--diff=default -m 0'` |
| nemu-reference-regression | codex | completed | 当前 NEMU 配置 | 参考路径 35/35 PASS | `timeout 180s make -C am-kernels/tests/cpu-tests ARCH=riscv32-nemu run` |
| record | codex | completed | 回归结论 | memory 与 task-run 更新 | 本目录与 `.github/memory/*` 更新 |

## 关键产物

- `artifacts`: 本文件、`dispatch-log.md`
- `logs_or_traces`: 终端回归输出；`am-kernels/tests/cpu-tests/build/nemu-log.txt` 由 NEMU 回归刷新
- `linked_memory_updates`: `.github/memory/project-status.md`、`.github/memory/modules/npc.md`、`.github/memory/modules/am-kernels.md`、`.github/memory/modules/difftest.md`

## 当前阻塞点

- `blockers`: 无
- `missing_dependencies`: 无
- `risk_assessment`: 本轮只证明 cpu-tests 所需 `rv32i_zicsr` 与提交级 GPR/PC difftest 闭环；未证明 NPC 已支持 NEMU 的可选 RV32M/B/C、cache/BPU 性能模型、外部中断/mtime 或完整设备长测。

## 下一步建议

1. 若要继续扩大 NEMU/NPC 功能一致性，优先做 `am-tests` 中 CTE/设备可自动化子项，而不是直接要求 NEMU 全部可选扩展。
2. 若想让 NPC 支持 NEMU 当前可选 `M/B/C` guest 编译配置，需要先单独立项扩展 ISA、译码、执行单元和 difftest ISA 字符串。

## 模板升级候选

- `repeated_dynamic_subgraph`: 无
- `should_promote_to_static_template`: 否
- `reason`: 现有 `rv32-reference-loop` 足够覆盖。

## 收尾结论

- `final_result`: 未发现新的 cpu-tests 阻塞缺口，未修改 RTL/host 源码。
- `evidence_summary`: NPC `riscv32-npc` 全量 cpu-tests 在 `--diff=default -m 0` 下 35/35 PASS；NEMU `riscv32-nemu` 全量 cpu-tests 35/35 PASS；NPC lint 与默认构建通过。
- `notes`: 当前 `--diff=default` 实测加载 `nemu/build/riscv32-nemu-interpreter-so`；NEMU 自身回归仍使用 Spike difftest。
