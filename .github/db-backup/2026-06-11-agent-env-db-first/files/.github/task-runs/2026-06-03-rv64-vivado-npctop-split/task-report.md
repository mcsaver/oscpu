# Task Report

## 基本信息

- `task_id`: `2026-06-03-rv64-vivado-npctop-split`
- `task_slug`: `rv64-vivado-npctop-split`
- `graph_template`: `verilator-tapeout-readiness-loop`
- `graph_mode`: `static+dynamic`
- `status`: `completed`
- `owner`: `codex`
- `started_at`: `2026-06-03 14:00`
- `updated_at`: `2026-06-03 14:35`

## 任务目标

- `source_request`: 用户要求将 Vivado 索引里的未用旧 core/仿真层 RTL 移除，把真正的 NPC 顶层作为可综合顶层；AXI、UART、CLINT、PLIC 应在真实顶层集成，外部只保留 Verilator/DPIC 仿真包裹层。
- `goal`: 建立 `NpcTop` 可综合顶层，保留 `NpcSimTop` 作为 DPIC wrapper，并让 `fpga` Vivado 工程默认索引 `NpcTop`。
- `scope`: `npc/rv64/vsrc` 顶层 RTL/filelist、`npc/rv64/Makefile` 默认综合入口、`fpga` Vivado 工程入口与文档。

## 选图说明

- `selected_template`: `verilator-tapeout-readiness-loop`
- `why_this_graph`: 任务目标是把 Verilator 仿真外壳和 Vivado/综合顶层分层，属于流片/综合准备度治理。
- `dynamic_nodes_added`: `vivado-project-index-check`
- `why_dynamic_nodes_were_needed`: 用户反馈 Vivado GUI 源索引异常，需要额外验证 `.xpr` 未索引 DPIC/sim/legacy 文件。

## 节点概览

| node_id | owner_agent | status | inputs | outputs | evidence |
| ------- | ----------- | ------ | ------ | ------- | -------- |
| `rtl-boundary-split` | `codex` | `completed` | `NpcSimTop.sv`, `NpcCoreTop.v`, bus/peripheral RTL | 新增 `NpcTop.v`，`NpcSimTop` 改为 wrapper | `make -C npc/rv64 lint` PASS |
| `filelist-cleanup` | `codex` | `completed` | `npc/rv64/vsrc/filelist.mk`, `fpga/Makefile` | `RTL_CORE_SRCS` 包含 `NpcTop.v`，Vivado 默认 `TOP=NpcTop` | `make -C fpga filelist` 输出 42 RTL 源 |
| `vivado-project-index-check` | `codex` | `completed` | `fpga/scripts/create_rv64_core_project.tcl` | `fpga/vivado/npc_rv64_top/npc_rv64_top.xpr` | `.xpr` 中 `TopModule=NpcTop`，无 `NpcSimTop/AxiDpi/AxiLiteVirtioBlk/vsrc/sim/vsrc/legacy` 命中 |

## 关键产物

- `artifacts`: `npc/rv64/vsrc/core/NpcTop.v`, `fpga/vivado/npc_rv64_top/npc_rv64_top.xpr`, `fpga/filelists/npc_rv64_top_files.f`
- `logs_or_traces`: `fpga/reports/npc_rv64_top_vivado.log`, `fpga/reports/compile_order.rpt`
- `linked_memory_updates`: `.github/memory/project-status.md`, `.github/memory/modules/npc.md`

## 当前阻塞点

- `blockers`: 无功能性阻塞。
- `missing_dependencies`: 未再次启动完整 Vivado synthesis。
- `risk_assessment`: 上一轮完整 Vivado synth 在 `OooDataWordCache/OooFetchPacketCache` 附近出现高内存压力；继续做综合/时序前建议优先治理 FPGA RAM 推断和 fetch packet cache 全表 invalidate 网络。

## 下一步建议

1. 在 `fpga` 下用 `make synth VIVADO_THREADS=1` 或更小 cache 参数跑一次受控综合，确认 `NpcTop` OOC 报告。
2. 优先把 `OooDataWordCache` 改为同步 RAM/读改写状态机，把 `OooFetchPacketCache` 的 store invalidate 从全表组合扫描改为索引化或分周期流程。

## 模板升级候选

- `repeated_dynamic_subgraph`: `vivado-project-index-check`
- `should_promote_to_static_template`: `true`
- `reason`: 后续每次调整 Verilator/Vivado 分层都应检查 `.xpr` 和 filelist 中是否误纳入 DPIC/sim/legacy 文件。

## 收尾结论

- `final_result`: 已完成 `NpcTop` 可综合顶层和 `NpcSimTop` DPIC wrapper 分层，Vivado 工程默认索引 `NpcTop`。
- `evidence_summary`: `make -C npc/rv64 lint` PASS；`make -C fpga filelist` PASS 且 42 个源无 sim/DPI/legacy；`make -C fpga project` PASS 且 `.xpr` 顶层为 `NpcTop`。
- `notes`: 本轮只重建 Vivado 工程索引，不重复跑完整综合，避免再次触发高内存占用。
