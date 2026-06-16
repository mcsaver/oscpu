# Task Report

## 基本信息

- `task_id`: `2026-04-13-rv32i-nonpipe-core`
- `task_slug`: `rv32i-nonpipe-core`
- `graph_template`: `custom`
- `graph_mode`: `dynamic`
- `status`: `completed`
- `owner`: `GitHub Copilot`
- `started_at`: `2026-04-13`
- `updated_at`: `2026-04-13`

## 任务目标

- `source_request`: `根据学习经验，设计一个近似商业级别的 RV32I 非流水线核心，RTL 放到 npc/single/vsrc，并使用主 agent 调用子 agent 实现。`
- `goal`: `在 npc/single/vsrc 中落一版可综合、可 lint 的 RV32I 非流水线核心骨架，并把控制、访存、提交和 trap 边界一次收清。`
- `scope`: `define 宏体系、寄存器堆、译码、立即数、ALU、比较、LSU、WBU、顶层多周期控制状态机、ecall/ebreak 退出协议，以及 task-run / memory 记录。`

## 选图说明

- `selected_template`: `custom`
- `why_this_graph`: `当前任务属于 NPC 目标路径 bring-up，但工作区还没有现成的 NPC 静态图模板可直接覆盖“study -> 现状盘点 -> 架构收敛 -> RTL 实现 -> lint -> 记录”整条链路，因此本轮采用主 agent + 子 agent 的动态拆解。`
- `dynamic_nodes_added`: `survey-existing`, `study-recall`, `architecture-synthesis`, `rtl-implement`, `lint-validate`, `review-and-record`
- `why_dynamic_nodes_were_needed`: `现有工程只有 define 和 RegisterFile 占位骨架，需要先确认设计边界和已知资料，再进入实现。`

## 节点概览

| node_id | owner_agent | status | inputs | outputs | evidence |
| ------- | ----------- | ------ | ------ | ------- | -------- |
| `study-recall` | `GitHub Copilot` | `completed` | `project-status.md`、`modules/npc.md`、study 索引和专题笔记 | 任务边界、实现约束 | 已读取记忆与 `npc/single/design/study/*.md` |
| `survey-existing` | `Explore` | `completed` | `npc/single/` 当前目录树 | 现有工程盘点 | 子 agent 返回“仅有 define / RegisterFile 骨架” |
| `architecture-synthesis` | `npc` | `completed` | study 笔记、现有 vsrc | 核心模块边界与工程化取舍 | 子 agent 返回“单在途多周期 + 统一控制包 + WBU 提交点”建议 |
| `rtl-implement` | `GitHub Copilot` | `completed` | 架构建议、study 笔记 | `NpcCore` 与 8 个辅助 RTL 文件 | `npc/single/vsrc` 下新增/重写 9 个 RTL 文件 |
| `lint-validate` | `GitHub Copilot` | `completed` | 新 RTL 文件 | 通过 lint 的实现 | `verilator --lint-only -Wall ...` 通过 |
| `review-and-record` | `npc` + `GitHub Copilot` | `completed` | 已通过 lint 的 RTL | 残余风险、task-run、memory 更新 | 子 agent 审查指出 trap 仍为 halt-only，记录已补齐 |

## 关键产物

- `artifacts`: `npc/single/vsrc/define.v`、`RegisterFile.v`、`ImmGen.v`、`DecodeUnit.v`、`ALU.v`、`CompareUnit.v`、`LSU.v`、`WBU.v`、`NpcCore.v`
- `logs_or_traces`: `在 npc/single/vsrc 执行 verilator --lint-only -Wall NpcCore.v DecodeUnit.v ImmGen.v RegisterFile.v ALU.v CompareUnit.v LSU.v WBU.v 通过`
- `linked_memory_updates`: `.github/memory/project-status.md`、`.github/memory/modules/npc.md`、`.github/memory/decisions.md`

## 当前阻塞点

- `blockers`: `无硬阻塞，当前 RTL 已通过静态检查。`
- `missing_dependencies`: `尚无仿真 testbench、镜像加载器和 NEMU 对拍链路。`
- `risk_assessment`: `当前普通异常仍为 halt-only trap，尚未形成 CSR + mtvec + MRET 的可恢复异常闭环；但 ecall/ebreak 已显式收口为 EEI 退出协议。FENCE/FENCE.I 在当前无 cache 假设下按 no-op 处理。`

## 下一步建议

1. 补最小 CSR / trap controller，把 halt-only trap 升级成可重定向异常入口。
2. 增加 testbench 和 directed tests，优先覆盖 branch、load/store、misaligned trap 与 ecall/ebreak。
3. 明确 IFU/LSU 请求-响应契约，并为后续接入 pmem 或 difftest 预留更稳定的适配层。

## 模板升级候选

- `repeated_dynamic_subgraph`: `study -> survey-existing -> architecture-synthesis -> rtl-implement -> lint-validate -> review-and-record`
- `should_promote_to_static_template`: `yes`
- `reason`: `NPC bring-up 类任务高度可能重复这条链路，后续可沉淀为单独的 NPC RTL bring-up 静态图模板。`

## 收尾结论

- `final_result`: `已在 npc/single/vsrc 落成一版 define 驱动的 RV32I 非流水线核心，具备统一控制包、双读单写寄存器堆、完整 RV32I 主干译码、LSU 访存语义、WBU 提交口、ecall/ebreak 显式退出协议和顶层多周期状态机。`
- `evidence_summary`: `get_errors 检查通过；Verilator lint 通过；NPC 子 agent 审查确认 RV32I 主干指令覆盖完整，当前新增的 ecall/ebreak 退出语义已可被外部 testbench 直接观测。`
- `notes`: `当前实现是“单在途、多周期、普通异常 trap 停机、ecall/ebreak 走退出协议”的工程化首版，适合作为后续 CSR / PMEM / difftest 接入基座。`
