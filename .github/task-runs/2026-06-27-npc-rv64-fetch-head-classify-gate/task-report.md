# 任务报告

## 基本信息

- `task_id`: `2026-06-27-npc-rv64-fetch-head-classify-gate`
- `task_slug`: `npc-rv64-fetch-head-classify-gate`
- `graph_template`: `custom`
- `graph_mode`: `dynamic`
- `status`: `completed`
- `owner`: `codex`
- `started_at`: `2026-06-27`
- `updated_at`: `2026-06-27`

## 任务目标

- `source_request`: 用户选择继续工业化拆分 RV64 RTL 边界，并要求所有产物按项目规则放入工作区。
- `goal`: 从 `OooAluFetchCore` 中抽出单槽 fetch head 分类纯组合 owner，降低父模块重复分类逻辑。
- `scope`: `npc/rv64` RTL/spec/testbench/task-run/memory；不处理性能优化、不改变 CSR/pending/fetch 状态 owner。

## 选图说明

- `selected_template`: `custom`
- `why_this_graph`: 当前任务是 RV64 RTL 边界拆分，不直接属于 Linux bring-up 或 e2e 环境自检；采用小切片 RTL 工作流。
- `dynamic_nodes_added`: `recall -> spec -> plan -> test -> rtl -> focused-verify -> regression -> record`
- `why_dynamic_nodes_were_needed`: 该 helper 是新的工业化拆分切片，仓库尚无专用静态图。

## 节点概览

| 节点ID (`node_id`) | 负责 Agent (`owner_agent`) | 状态 (`status`) | 输入 (`inputs`) | 输出 (`outputs`) | 证据 (`evidence`) |
| ------------------ | -------------------------- | --------------- | --------------- | --------------- | ----------------- |
| `recall` | `codex` | `completed` | AGENTS、Copilot 指令、memory、RV64 README/spec、vsrc 边界 | 当前 RTL 边界与验证约束 | 对话工具输出 |
| `spec` | `codex` | `completed` | `OooAluFetchCore` head 分类源码 | `npc/rv64/design/specs/ooo-fetch-head-classify-gate.md` | 文件已落盘 |
| `plan` | `codex` | `completed` | spec、源码信号名、验证入口 | `implementation-plan.md` | 文件已落盘并随执行更新 |
| `test` | `codex` | `completed` | spec 验证计划 | `tb_ooo_fetch_head_classify_gate.sv` | RED: missing module 失败符合预期 |
| `rtl` | `codex` | `completed` | failing TB 与现有 head 分类逻辑 | classifier RTL、filelist、父模块接线 | `OooFetchHeadClassifyGate.v` 已接入 |
| `focused-verify` | `codex` | `completed` | 新 RTL | focused test/lint/build | focused 3/3 PASS，lint/build PASS |
| `regression` | `codex` | `completed` | focused PASS | full module/official smoke | module TB 101/101 PASS；official smoke overall_rc=0 |
| `record` | `codex` | `completed` | 验证证据 | memory/task-run 更新 | 本报告、dispatch log、memory、vsrc README 已更新 |

## 关键产物

- `artifacts`: `npc/rv64/design/specs/ooo-fetch-head-classify-gate.md`、`npc/rv64/vsrc/frontend/OooFetchHeadClassifyGate.v`、`npc/rv64/testbench/tests/tb_ooo_fetch_head_classify_gate.sv`
- `logs_or_traces`: `npc/rv64/perf/results/20260627-fetch-head-classify/`
- `linked_memory_updates`: `.github/memory/modules/npc.md`、`.github/memory/project-status.md`、`npc/rv64/vsrc/README.md`

## 当前阻塞点

- `blockers`: 无
- `missing_dependencies`: 无
- `risk_assessment`: 该切片移动 FP decode 与 privileged illegal 组合 facts，重点风险 semihost EBREAK、Svinval/TVM、FS-off FP 与 fetch fault 优先级已由独立 TB、父模块 TB、full module TB 和 official smoke 覆盖。

## 下一步建议

1. 下一轮建议继续选择父模块中重复且纯组合的 fetch/head facts 边界，避免先动 pending/CSR 时序 owner。
2. 若转向性能优化，应先复核最新 core-regress CPI 明细，再选择高 CPI 的 DIV/FP-div 或 memory-barrier 路径。

## 模板升级候选

- `repeated_dynamic_subgraph`: `rtl-owner-split`
- `should_promote_to_static_template`: `true`
- `reason`: `OooAluFetchCore` 已连续多轮按纯组合 gate/state owner 拆分，节点结构稳定。

## 收尾结论

- `final_result`: 完成 `OooFetchHeadClassifyGate` 设计、测试、RTL 接入和项目记录。
- `evidence_summary`: RED missing module；classifier 单测 PASS；focused 3/3 PASS；full module testbench 101/101 PASS；`make -C npc/rv64 lint` PASS；`make -C npc/rv64 -j2` PASS；official `rv64ui/rv64mi/rv64si` smoke overall_rc=0。
- `notes`: 本轮不把完整工业 CPU sign-off、Linux/full-system、formal/PPA/timing/CDC/reset/物理签核作为完成范围。
