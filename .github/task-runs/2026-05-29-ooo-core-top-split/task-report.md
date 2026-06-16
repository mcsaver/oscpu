# Task Report

## 基本信息

- `task_id`: `2026-05-29-ooo-core-top-split`
- `task_slug`: `ooo-core-top-split`
- `graph_template`: `npc-sim-regression`
- `graph_mode`: `static+dynamic`
- `status`: `completed`
- `owner`: `Codex`
- `started_at`: `2026-05-29`
- `updated_at`: `2026-05-29`

## 任务目标

- `source_request`: 用户指出当前 OoO 只接在仿真顶层，要求新增 core top 管理核心，把仿真与 core 分离，并让乱序超标量真正接入 core。
- `goal`: 在不牺牲 CPU-test 正确性的前提下，把 `NpcSimTop` 从核心管理者收敛为 Verilator/DPI 平台壳。
- `scope`: `npc/single` core/sim RTL 顶层、OoO fetch/memory 非零延迟协议修复、filelist/Makefile 顶层入口、CPU-test 回归与 memory 记录。

## 选图说明

- `selected_template`: `npc-sim-regression`
- `why_this_graph`: 本任务跨 RTL core 边界、仿真顶层和全量 CPU-test 正确性回归，需要先重构接口，再用回归闭环证明行为未破坏。
- `dynamic_nodes_added`: `ooo-fetch-latency-fix`, `ooo-buffer-address-fix`
- `why_dynamic_nodes_were_needed`: 新 core top 切换到真实 IFU/LSU 总线桥后，暴露了旧一拍 DPI 直连隐藏的 fetch bypass PC 推进和 memory buffer 对齐地址问题。

## 节点概览

| node_id | owner_agent | status | inputs | outputs | evidence |
| ------- | ----------- | ------ | ------ | ------- | -------- |
| `read-boundary` | Codex | completed | `NpcSimTop.sv`, `NpcCore.v`, `OooAluFetchCore.v`, `NpcAxiBus.v`, `AxiDpiSlave.sv` | core/sim 边界设计 | 确认旧 OoO 在 `NpcSimTop` 内直连 DPI fetch/mem，绕过总线 |
| `add-core-top` | Codex | completed | 现有顺序核/OoO 接口 | `NpcCoreTop.v` | 新 top 默认封装 `NpcCore`，实验宏下封装 `OooAluFetchCore` 与 fetch/mem bridge |
| `refactor-sim-top` | Codex | completed | `NpcSimTop.sv` | 仿真顶层统一实例化 `NpcCoreTop` | OoO 私有 DPI fetch/mem block 已移除，IFU/LSU 统一接 `NpcAxiBus` |
| `ooo-fetch-latency-fix` | Codex | completed | 代表测试 ABORT、VCD `/tmp/coretop.vcd` | `OooAluFetchCore` bypass response 推进 `next_fetch_pc_q` | 修复后 `add/bitmanip/recursion/fence-i` PASS |
| `ooo-buffer-address-fix` | Codex | completed | `mem-test/string` BAD TRAP、VCD `/tmp/memtest.vcd` | `OooIntBackend` buffer request 使用 word-aligned address | 修复后 `mem-test/string` PASS |
| `regression` | Codex | completed | OoO 最终构建 | CPU-test 全量结果 | `/tmp/ysyx-ooo-full-cputests-coretop.tsv`, `40/40 PASS`, weighted CPI `4.690321` |

## 关键产物

- `artifacts`: `npc/single/vsrc/core/NpcCoreTop.v`, `npc/single/vsrc/sim/NpcSimTop.sv`, `npc/single/vsrc/filelist.mk`, `npc/single/Makefile`
- `logs_or_traces`: `/tmp/coretop.vcd`, `/tmp/memtest.vcd`, `/tmp/ysyx-ooo-full-cputests-coretop.tsv`
- `linked_memory_updates`: `.github/memory/project-status.md`, `.github/memory/modules/npc.md`

## 当前阻塞点

- `blockers`: 无；架构切分和全量正确性已闭合。
- `missing_dependencies`: 无。
- `risk_assessment`: 当前 OoO CPI 从直连 DPI 的约 `0.61` 退到真实总线桥下的 `4.69`，这是有意保守化的结构代价；后续性能优化必须在 core 内补宽 I-cache/LSQ/多 outstanding，不能回退到仿真顶层私有直连。

## 下一步建议

1. 把 `OooFetchAxiBridge` 替换为 core 内可综合 2-wide I-cache 或 packet cache，并证明 response/bypass/outstanding PC 所有权。
2. 把 `OooMemAxiBridge` 替换为 LSQ/store-commit/multi-outstanding 设计，先覆盖 store->load、unalign、lane1 load、MMIO ordering。

## 模板升级候选

- `repeated_dynamic_subgraph`: `真实总线延迟暴露旧一拍 DPI 假设 -> VCD 定位 -> RTL 协议修复 -> CPU-test focused/full 回归`
- `should_promote_to_static_template`: `true`
- `reason`: 后续从仿真 shortcut 迁移到可综合边界时会反复遇到同类 latency/ownership 问题，应固化为回归调试子图。

## 收尾结论

- `final_result`: 已新增 core top 并完成 OoO 从仿真顶层私有直连接入 core 的切分。
- `evidence_summary`: OoO build PASS；代表 `add/bitmanip/mem-test/string/recursion/fence-i` PASS；CPU-test 全量 `40/40 PASS`，weighted CPI `4.690321`；默认非 OoO build + `cpu-tests add` PASS。
- `notes`: 当前结果优先正确性和架构边界，性能退化已记录为下一阶段 core 内部优化目标。
