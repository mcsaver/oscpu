# 任务报告

## 基本信息

- `task_id`: `2026-06-27-npc-rv64-fetch-head-pair-gate`
- `task_slug`: `npc-rv64-fetch-head-pair-gate`
- `graph_template`: `custom`
- `graph_mode`: `dynamic`
- `status`: `completed`
- `owner`: `codex`
- `started_at`: `2026-06-27`
- `updated_at`: `2026-06-27`

## 任务目标

- `source_request`: 用户要求继续优化 RV64 RTL，并沿用 Superpowers 工作流。
- `goal`: 从 `OooAluFetchCore` 抽出 fetch head pair 纯组合 owner，承接双槽可见性、分类实例、branch-spec dispatch block 和 dispatch0 facts。
- `scope`: `npc/rv64` RTL/spec/testbench/task-run/memory；不处理性能 CPI 改动、不移动 pending/CSR/fetch FIFO/RAS/BPU 状态。

## 选图说明

- `selected_template`: `custom`
- `why_this_graph`: 当前任务是 RV64 RTL 边界拆分小切片，不直接属于 Linux bring-up 或 e2e 环境自检。
- `dynamic_nodes_added`: `recall -> spec -> plan -> test -> rtl -> focused-verify -> regression -> record`
- `why_dynamic_nodes_were_needed`: `OooAluFetchCore` 连续工业化拆分中尚无专用静态模板。

## 节点概览

| 节点ID (`node_id`) | 负责 Agent (`owner_agent`) | 状态 (`status`) | 输入 (`inputs`) | 输出 (`outputs`) | 证据 (`evidence`) |
| ------------------ | -------------------------- | --------------- | --------------- | --------------- | ----------------- |
| `recall` | `codex` | `completed` | AGENTS、Copilot 指令、memory、RV64 workflow、`OooAluFetchCore` | 下一刀选择 `OooFetchHeadPairGate` | 对话工具输出 |
| `spec` | `codex` | `completed` | head pair 源码和上一轮 classifier 边界 | `npc/rv64/design/specs/ooo-fetch-head-pair-gate.md` | 文件已落盘 |
| `plan` | `codex` | `completed` | spec、源码信号名、验证入口 | `implementation-plan.md` | 文件已落盘并勾选完成 |
| `test` | `codex` | `completed` | spec 验证计划 | failing focused TB | RED 缺模块失败符合预期 |
| `rtl` | `codex` | `completed` | failing TB 与现有 head pair 逻辑 | pair gate RTL 与父模块接线 | pair gate 单测 PASS |
| `focused-verify` | `codex` | `completed` | 新 RTL | focused test/lint/build | focused 4/4 PASS；lint/build PASS |
| `regression` | `codex` | `completed` | focused PASS | full module/official smoke | module 102/102 PASS；official `overall_rc=0` |
| `record` | `codex` | `completed` | 验证证据 | memory/task-run 更新 | 本 task-run、`vsrc/README.md` 与 memory 已更新 |

## RTL 推导摘要

- `需求要点`: 双槽 head 可见性和 dispatch0 facts 当前仍分散在 `OooAluFetchCore` 前段，且直接包围两个 classifier 实例。
- `协议规则`: lane1 可见性受 lane0 fetch fault、lane0 branch/jump/stop 和 slot1 response 约束；dispatch0 facts 只由 `dispatch_valid` 门控，不消费 ready/unsupported。
- `状态机`: 无状态机，纯组合。
- `不变量`: lane0 fault/stop/control-stop 抑制 lane1；branch-spec inactive 时 dispatch block 为 0；FS-off FP 走 arch trap 不走 dispatch0 FP；direct branch0 dispatch valid 等于 dispatch0 branch。
- `数据通路骨架`: lane0 fault/decode -> head0 classifier -> lane1 fault/decode -> head1 classifier -> branch-spec block -> dispatch valid/facts。

## 当前阻塞点

- `blockers`: 无
- `missing_dependencies`: 无
- `risk_assessment`: 已用 pair gate 单测、主 fetch core focused 回归、默认 module regression、Verilator lint/build 和 official `rv64ui/rv64mi/rv64si` smoke 覆盖本切片主要风险；剩余风险属于 Linux/full-system、formal/PPA/timing/CDC/reset/物理签核等非本轮范围。

## 下一步建议

1. 继续沿 `OooAluFetchCore` 剩余组合密集区寻找下一块纯组合 owner。
2. 下一刀仍应先写 spec/TB，再移动 RTL。

## 收尾结论

- `final_result`: 完成。`OooFetchHeadPairGate` 已接入 `OooAluFetchCore`，旧 head pair 内联分类和 dispatch0 facts 赋值已移除。
- `evidence_summary`: RED `tb_ooo_fetch_head_pair_gate` 缺模块失败符合预期；module `tb_ooo_fetch_head_pair_gate` PASS；focused 4/4 PASS；默认 module testbench 102/102 PASS；`make -C npc/rv64 lint` PASS；`make -C npc/rv64` PASS；official `rv64ui/rv64mi/rv64si` smoke `overall_rc=0`，证据目录 `npc/rv64/perf/results/20260627-fetch-head-pair/`。
- `notes`: 本轮不把完整工业 CPU sign-off、Linux/full-system、formal/PPA/timing/CDC/reset/物理签核作为完成范围。
