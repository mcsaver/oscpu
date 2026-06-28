# 任务报告

## 基本信息

- `task_id`: `2026-06-27-npc-rv64-ooo-core-controlflow-decompose`
- `task_slug`: `npc-rv64-ooo-core-controlflow-decompose`
- `graph_template`: `custom`
- `graph_mode`: `dynamic`
- `status`: `completed`
- `owner`: `codex`
- `started_at`: `2026-06-27`
- `updated_at`: `2026-06-27`

## 任务目标

- `source_request`: 用户要求继续优化 `OooCoreTopGlue`，不是只改名，而是继续把原 `OooAluFetchCore` 巨石中的功能逻辑按目录边界解耦。
- `goal`: 把 core glue 剩余的 direct control-flow、predictor update、CSR illegal probe、synthetic lane1 retire 和 core slice 准入规则下沉到对应职责目录。
- `scope`: `npc/rv64/vsrc/{frontend,control,writeback,core}/`、`npc/rv64/vsrc/filelist.mk`、相关 README/spec/memory/task-run。

## 选图说明

- `selected_template`: `custom`
- `why_this_graph`: 这是 RV64 RTL 架构拆分切片，不是完整 e2e 或 Linux bring-up gate。
- `dynamic_nodes_added`: recall -> rtl-derive -> implement -> focused-verify -> full-verify -> record
- `why_dynamic_nodes_were_needed`: 用户要求的是跨目录 RTL 解耦，现有静态图不能精确描述 core glue 巨石拆分边界。

## 节点概览

| 节点ID (`node_id`) | 负责 Agent (`owner_agent`) | 状态 (`status`) | 输入 (`inputs`) | 输出 (`outputs`) | 证据 (`evidence`) |
| ------------------ | -------------------------- | --------------- | --------------- | --------------- | ----------------- |
| recall | codex | completed | AGENTS/copilot/memory/npc RTL workflow | 边界与验证约束 | 本报告 |
| rtl-derive | codex | completed | 剩余 core glue 组合公式 | RTL 推导摘要 | 本报告“RTL 推导摘要” |
| implement | codex | completed | `OooCoreTopGlue.v` 残留 direct/control/writeback 公式 | 新增 owner module 与接线 | 源码 diff |
| focused-verify | codex | completed | focused module TB | 5/5 PASS | `npc/rv64/perf/results/20260627-ooo-core-controlflow-decompose/focused/` |
| full-verify | codex | completed | 默认 testbench、lint、build | 103/103 PASS；lint PASS；build PASS | `npc/rv64/perf/results/20260627-ooo-core-controlflow-decompose/all/` |
| record | codex | completed | docs/memory/task-run | README/spec/memory/task-run 更新 | 本报告、`vsrc/README.md`、`control/README.md`、memory |

## RTL 推导摘要

### 需求

- 将 `core/OooCoreTopGlue.v` 中仍表达功能语义的组合规则继续迁出：
  direct branch/JAL/RET/return-cont、predictor update、branch prefetch request fire、
  CSR illegal lane probe、synthetic lane1 return commit/drop、core slice flush/commit 准入。
- 新模块均为纯组合 owner，不新增时序状态，不改变现有 sequencer 寄存器归属。
- 父模块只保留跨目录 wire、实例化和少量事实 bus 装配。

### 协议规则

- direct control-flow、predictor update、CSR probe、synthetic commit gate 和 core slice gate 全部是同拍组合返回。
- `OooBranchPrefetchRequestGate` 继续生成 `req_valid/req_pc`，新增 `req_fire=req_valid && req_ready`，不改变 ready/valid 先后关系。
- synthetic lane1 return 的状态仍由 `OooSyntheticLane1RetSequencer` 持有，commit/drop 事件由 writeback gate 生成后反馈给 sequencer 和 commit mux。

### 状态机

- 本切片无新增状态机。
- 已有状态机保持原 owner：RAS、return-cont、branch-spec tracker、fetch PC outstanding、pending sequencer、synthetic lane1 ret sequencer、control flush sequencer、core slice。

### 不变量

- direct JAL target/link/call、direct RET target 和 return-cont capture/match 与迁移前逐位等价。
- branch target cache capture 与 JALR BTB update 只在原命中/安全/resolve 条件满足时拉高。
- synthetic lane1 return 的 before-core0、after-core0、drop-branch 三种 commit 互斥语义保持原优先级。
- core commit ready 仍要求外部 `commit_ready` 且无 trap flush、serial flush、branch checkpoint pending、branch spec active 或 checkpoint restore。
- core commit1 block 仍只在无 control pseudo commit、存在 synthetic ret pending、未 drop-match 且 branch 已见/commit0 匹配时拉高。

### 数据通路骨架

- `frontend/OooDirectControlFlowGate.v` 输出 direct branch/JAL/RET/return-cont 事件，驱动 fetch request mux、RAS update、return-cont buffer、pending arbiter 和 backend dispatch mux。
- `frontend/OooPredictorUpdateGate.v` 输出 branch target cache capture 与 JALR BTB update。
- `control/OooCsrIllegalProbeGate.v` 输出 lane0/lane1 CSR illegal probe。
- `writeback/OooSyntheticLane1RetCommitGate.v` 输出 synthetic retire/drop 事件，驱动 synthetic sequencer 与 commit output mux。
- `control/OooCoreSliceControlGate.v` 输出 checkpoint、flush、commit-ready、commit1-block 和 memory issue block，驱动 core slice 与 flush sequencer。

## 关键产物

- `artifacts`: 新增 `OooDirectControlFlowGate.v`、`OooPredictorUpdateGate.v`、`OooSyntheticLane1RetCommitGate.v`、`OooCoreSliceControlGate.v`、`OooCsrIllegalProbeGate.v`。
- `logs_or_traces`: `npc/rv64/perf/results/20260627-ooo-core-controlflow-decompose/`
- `linked_memory_updates`: `.github/memory/project-status.md`、`.github/memory/modules/npc.md`

## 当前阻塞点

- `blockers`: 无
- `missing_dependencies`: 无
- `risk_assessment`: 纯组合等价迁移，focused/default/lint/build 均已通过；剩余风险是更大 wrapper 化和 packed bus 化仍未完成。

## 下一步建议

1. 继续把 `dispatch0_facts`、`direct_branch_spec_start=0` 等剩余装配线纳入更上层 bus/wrapper。
2. 后续再推进 `frontend/OooFrontend.v` 与 `control/OooControlPlane.v` wrapper，而不是把功能规则写回 core glue。

## 模板升级候选

- `repeated_dynamic_subgraph`: `npc/rv64` RTL 巨石拆分切片
- `should_promote_to_static_template`: `no`
- `reason`: 当前仍是特定模块架构治理，不需要提升为通用静态图。

## 收尾结论

- `final_result`: completed
- `evidence_summary`: focused `tb_ooo_core_top_glue tb_ooo_fetch_trap_gate tb_ooo_priv_system tb_ooo_pending_dispatch_arbiter tb_decode_unit` 5/5 PASS；默认 module testbench 103/103 PASS；`make -C npc/rv64 lint` PASS；`make -C npc/rv64 -j2` PASS；旧公式残留扫描无输出；旧 `OooAluFetchCore` 名称在 vsrc/testbench/filelist 范围无输出；scoped `git diff --check` 与新文件/文档尾随空白扫描 PASS。
- `notes`: 本切片不代表完整 `OooFrontend.v`/`OooControlPlane.v` wrapper 或 FP 巨石拆分完成。
