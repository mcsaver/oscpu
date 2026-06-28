# 任务报告

## 基本信息

- `task_id`: `2026-06-27-npc-rv64-npccoretop-csr-hoist`
- `task_slug`: `npc-rv64-npccoretop-csr-hoist`
- `graph_template`: `custom`
- `graph_mode`: `dynamic`
- `status`: `completed`
- `owner`: `codex`
- `started_at`: `2026-06-27`
- `updated_at`: `2026-06-27`

## 任务目标

- `source_request`: 用户要求让 `NpcCoreTop` 中直接例化更多模块，不要把分层后的模块继续都挤进 `OooCoreTopGlue`。
- `goal`: 把 CSR/privilege/PMP 与 FPR 状态 owner 从 `OooCoreTopGlue` 上提到 `NpcCoreTop`，让顶层直接拥有 control 与 regread/bypass 状态实例。
- `scope`: `npc/rv64/vsrc/core/{NpcCoreTop.v,OooCoreTopGlue.v}`、直接 glue testbench、README/spec/memory/task-run。

## 选图说明

- `selected_template`: `custom`
- `why_this_graph`: 这是 RTL 架构层级迁移切片，不是完整 e2e 或 Linux bring-up。
- `dynamic_nodes_added`: recall -> rtl-derive -> implement -> focused-verify -> full-verify -> record
- `why_dynamic_nodes_were_needed`: 用户要求改变顶层实例层级，需要同时覆盖 RTL 接线、testbench 适配、lint/build 和架构记录。

## 节点概览

| 节点ID (`node_id`) | 负责 Agent (`owner_agent`) | 状态 (`status`) | 输入 (`inputs`) | 输出 (`outputs`) | 证据 (`evidence`) |
| ------------------ | -------------------------- | --------------- | --------------- | --------------- | ----------------- |
| recall | codex | completed | AGENTS/copilot/memory/npc RTL workflow | 边界与验证约束 | 本报告 |
| rtl-derive | codex | completed | `NpcCoreTop`/`OooCoreTopGlue` 当前层级 | RTL 推导摘要 | 本报告“RTL 推导摘要” |
| implement | codex | completed | glue 内部 `CsrFile`/`OooFpRegFile` 实例 | `NpcCoreTop` 直接例化 `CsrFile` 与 `OooFpRegFile`，glue 改为 CSR/FPR 事件/状态边界 | 源码 diff |
| focused-verify | codex | completed | focused module TB | 5/5 PASS | `npc/rv64/perf/results/20260627-ooo-core-npccoretop-csr-hoist/focused/` |
| full-verify | codex | completed | 默认 testbench、lint、build | 103/103 PASS；lint PASS；build PASS | `npc/rv64/perf/results/20260627-ooo-core-npccoretop-csr-hoist/all/` |
| record | codex | completed | README/spec/memory/task-run | 文档和 memory 更新 | 本报告、memory、README/spec |

## RTL 推导摘要

### 需求

- `NpcCoreTop` 必须直接例化更多分层模块，不能让 `OooCoreTopGlue` 继续持有所有状态实例。
- 本轮选择 CSR/privilege/PMP 和 FPR 状态作为低风险上提切片，因为 `CsrFile` 与 `OooFpRegFile` 都已经是清晰状态 owner，且顶层/FP pending 路径已经有明确的事件和状态边界。

### 协议规则

- CSR access、trap mem/ex/irq、xRET、FP fflags、instret/cycle enable 仍由 core glue 内精确控制路径同拍产生。
- CSR 状态更新仍只由 `CsrFile` 内部时序处理；移动实例层级不改变 CSR 写入、trap 副作用、irq pending、privilege/PMP 输出协议。
- `NpcCoreTop` 将 `CsrFile` 输出的 privilege/PMP 状态直接供给 fetch/memory AXI bridge，并回灌给 core glue。
- FPR 读地址、load 写回和 FP compute/long 结果写回仍由 core glue 内的 pending/commit 路径产生；FPR 状态更新仍只由 `OooFpRegFile` 内部时序处理。

### 状态机

- 本切片不修改 `CsrFile` 或 `OooFpRegFile` 内部状态机。
- `OooCoreTopGlue` 删除内部 `CsrFile` 和 `OooFpRegFile` 实例，不新增状态；只保留事件生成和状态消费。
- 直接面向 glue 的 testbench 通过 `tb_ooo_core_top_glue_csr.svh` 外置同一 CSR/FPR 状态实例，保留 `dut.*` 探针层级。

### 不变量

- `CsrFile` 的 `cycle_count_enable` 仍为 `run && !halted`。
- `instret_inc` 仍使用 core slice 产生的 `core_retire_count_w`，不是最终外部 retire mux 后的其它值。
- FP fflags、trap mem/ex/irq、mret/sret 输入逐线等价迁移。
- CSR rdata/illegal/irq/target/privilege/mstatus/satp/PMP 输出逐线回灌给原 glue 消费点。
- FPR read address、load write、result write 逐线等价迁移，read data 逐线回灌给 `OooFpPendingExec`。

### 数据通路骨架

- `OooCoreTopGlue -> CsrFile`: `csr_access_*`、`pending_system_csr_commit`、trap mem/ex/irq、xRET、FP fflags、instret/cycle enable。
- `CsrFile -> OooCoreTopGlue`: CSR read/illegal、IRQ pending/cause、trap/return target、privilege/mstatus/satp/PMP。
- `CsrFile -> fetch/memory bridge`: privilege、mstatus、satp、Svpbmt、PMP state 由 `NpcCoreTop` 直接接入。
- `OooCoreTopGlue -> OooFpRegFile`: pending FP read address、FPR load write、FPR result write。
- `OooFpRegFile -> OooCoreTopGlue`: pending FP FRS1/FRS2/FRS3 read data。

## 关键产物

- `artifacts`: `NpcCoreTop` 直接例化 `CsrFile` 与 `OooFpRegFile`；`OooCoreTopGlue` 新增 CSR/FPR 边界端口并删除内部 `CsrFile`/`OooFpRegFile`；新增 `testbench/common/tb_ooo_core_top_glue_csr.svh`。
- `logs_or_traces`: `npc/rv64/perf/results/20260627-ooo-core-npccoretop-csr-hoist/`
- `linked_memory_updates`: `.github/memory/project-status.md`、`.github/memory/modules/npc.md`

## 当前阻塞点

- `blockers`: 无
- `missing_dependencies`: 无
- `risk_assessment`: 状态实例层级迁移，focused/default/lint/build 均已通过；剩余风险是更大 frontend/control wrapper 化仍未完成。

## 下一步建议

1. 继续把 execute core slice 或 frontend 状态 wrapper 逐步上提到 `NpcCoreTop`，让顶层按目录分层直接装配。
2. 再推进 `frontend/OooFrontend.v` 与 `control/OooControlPlane.v`，但 wrapper 内必须只聚合同目录职责。

## 收尾结论

- `final_result`: completed
- `evidence_summary`: focused `tb_ooo_core_top_glue tb_ooo_fetch_trap_gate tb_ooo_priv_system tb_ooo_sv39_boot tb_ooo_fp_reg_file` 5/5 PASS；默认 module testbench 103/103 PASS；`make -C npc/rv64 lint` PASS；`make -C npc/rv64 -j2` PASS。
- `notes`: 本切片迁出 CSR/FPR 状态 owner，不代表完整 `OooFrontend.v`/`OooControlPlane.v` wrapper 或 FP 巨石拆分完成。
