# Task Report

## 基本信息

- `task_id`: `2026-05-29-ooo-simtop-stats-audit`
- `task_slug`: `ooo-simtop-stats-audit`
- `graph_template`: `regression-debug-loop`
- `graph_mode`: `static+dynamic`
- `status`: `completed`
- `owner`: `Codex`
- `started_at`: `2026-05-29`
- `updated_at`: `2026-05-29`

## 任务目标

- `source_request`: 用户询问新加 OoO/superscalar 后仿真顶层是否正常，以及为什么相关统计失效。
- `goal`: 审计并修复 `NpcSimTop`、`NpcCoreTop`、OoO core 与 host 统计 DPI 之间的数据流缺口，恢复 OoO control-flow 统计。
- `scope`: 修复 host 统计侧；不修改 RTL 数据通路。

## 选图说明

- `selected_template`: `regression-debug-loop`
- `why_this_graph`: 现象是统计回归，需要从输出日志回溯到仿真顶层、核心封装和 host 累加函数。
- `dynamic_nodes_added`: `simtop-stat-chain-audit`
- `why_dynamic_nodes_were_needed`: 该问题不是功能 BAD TRAP，而是统计事件数据源迁移遗漏。

## 节点概览

| node_id | owner_agent | status | inputs | outputs | evidence |
| ------- | ----------- | ------ | ------ | ------- | -------- |
| recall | Codex | completed | AGENTS、copilot instructions、memory、NPC study | 读取 OoO/core-top 与统计历史约束 | `.github/memory/project-status.md`、`.github/memory/modules/npc.md`、`.github/memory/known-issues.md` |
| simtop-stat-chain-audit | Codex | completed | `NpcSimTop.sv`、`NpcCoreTop.v`、`cpu-exec.cpp`、`OooAluFetchCore.v` | 确认 OoO 模式下 cache/OoO 统计有源，Branch/BPU 统计 tie-off | `NpcSimTop.sv:559-583`、`NpcSimTop.sv:639-674`、`cpu-exec.cpp:243-318` |
| verify | Codex | completed | 当前构建 | 构建 up-to-date，说明截图现象对应当前 OoO 二进制 | `make -C npc/single NPC_OOO_ALU_EXPERIMENT=1 -j4` 返回 `Nothing to be done for 'default'.` |
| host-stat-fix | Codex | completed | `cpu-exec.cpp` commit 事件与 OoO cycle 事件 | 从 OoO commit stream 恢复 Branch/JAL/JALR/ret 与方向预测统计；branch prefetch hit 改为上升沿计数 | `npc/single/csrc/cpu/cpu-exec.cpp` |
| verify-fix | Codex | completed | OoO/非 OoO 构建与 OoO CPU-test 冒烟 | OoO 统计不再全 0；非 OoO 构建仍通过；最终二进制重建回 OoO | `add-riscv32-npc.bin` GOOD TRAP，`conditional branch=145`、`JAL=75`、`JALR=74` |
| simtop-lookup-fix | Codex | completed | `NpcSimTop.sv` 与 `OooAluFetchCore` 层次化信号 | 从仿真顶层接入 OoO BTB/JALR target 与 RAS lookup 事件 | `NpcSimTop.sv` |
| verify-lookup-fix | Codex | completed | OoO/非 OoO 构建与多个 OoO CPU-test 样本 | RAS lookup 与 BTB/JALR target miss 恢复非零；构建宏隔离正常 | `add`、`recursion`、`hello-str` GOOD TRAP |
| record | Codex | completed | 审计结论 | 更新项目状态、NPC 模块笔记与本 task-run | `.github/memory/project-status.md`、`.github/memory/modules/npc.md` |

## 关键产物

- `artifacts`: `npc/single/csrc/cpu/cpu-exec.cpp`、`npc/single/vsrc/sim/NpcSimTop.sv`
- `logs_or_traces`: 终端构建输出、OoO 冒烟运行统计、源码行级审计。
- `linked_memory_updates`: `.github/memory/project-status.md`、`.github/memory/modules/npc.md`

## 当前阻塞点

- `blockers`: 无。
- `missing_dependencies`: 若要统计 branch target cache 本身的命中率，还应单独定义该缓存的 lookup/hit 事件；当前恢复的是报告行里的 JALR target/return lookup。
- `risk_assessment`: 本次从 OoO commit stream 恢复可由 `pc/inst/next_pc` 严格推导的 resolve 统计，并从 `NpcSimTop` 用层次化引用只读采样 OoO JALR/RAS lookup 事件，避免复用顺序核 `u_inorder` 路径；OoO 当前没有 JALR BTB 预测器，所以 BTB/JALR lookup 只会产生 miss，hit 为 0 是符合实现的。

## 下一步建议

1. 后续可把 branch target cache 的 lookup/hit 与 branch prefetch 的 request/fill/consume 拆成独立画像，避免和 JALR target/RAS 统计混在一起。
2. 若后续实现真正的 OoO JALR BTB，再把 `sim_ooo_btb_lookup_event_w` 的 hit 侧接到对应 target 命中信号。

## 模板升级候选

- `repeated_dynamic_subgraph`: `simtop-stat-chain-audit`
- `should_promote_to_static_template`: `false`
- `reason`: 当前是一次统计迁移遗漏审计，尚未形成反复复用的完整模板。

## 收尾结论

- `final_result`: 仿真顶层功能接线整体正常；截图里的 Branch/BPU 统计全 0 根因是 OoO 模式下统计事件没有接入数据源。现已从 OoO commit stream 恢复 Branch/JAL/JALR/ret 与基础 direction accuracy 统计，从 `NpcSimTop` 层次化引用恢复 BTB/JALR target 与 RAS lookup 统计，并修正 branch prefetch hit 重复计数。
- `evidence_summary`: OoO `add-riscv32-npc.bin` GOOD TRAP 后统计恢复为 `conditional branch=145`、`JAL=75`、`JALR=74`、`branch accuracy=73/145`、`RAS lookup=hit 74/miss 0`；`recursion` GOOD TRAP 且 `BTB JALR lookup=hit 0/miss 218`、`RAS lookup=hit 129/miss 0`；OoO 与非 OoO build 均通过，最终二进制重建回 OoO。
- `notes`: OoO 当前没有 JALR BTB 预测器，因此 BTB/JALR target lookup 的 hit 为 0；这不是统计链路失效，而是当前实现语义。
