# Task Report

## 基本信息

- `task_id`: `2026-05-23-npc-single-soc-split`
- `task_slug`: `npc-single-soc-split`
- `graph_template`: `custom`
- `graph_mode`: `dynamic`
- `status`: `completed`
- `owner`: `Codex`
- `started_at`: `2026-05-23`
- `updated_at`: `2026-05-23`

## 任务目标

- `source_request`: 用户要求保留两个版本：`npc/single` 放未接入 ysyxSoCFull 的老 core，新增 `npc/soc` 放接入 ysyxSoC 的 core，直接复制一份来管理。
- `goal`: 让 `npc/single` 回到 NPC 自己的 `NpcSimTop + DPI` 仿真入口；让 `npc/soc` 独立保存 ysyxSoC 接入版本并能继续 `soc/soc-lint`。
- `scope`: `npc/single/**`、新增 `npc/soc/**`、`.gitignore`、项目 memory 与 task-run 记录。

## 选图说明

- `selected_template`: `custom`
- `why_this_graph`: 本任务是目录级版本拆分，涉及 RTL ABI、Makefile 目标和构建验证，不属于单模块 bug。
- `dynamic_nodes_added`: `copy-integrated-tree`、`restore-single-abi`、`verify-both-trees`、`record`
- `why_dynamic_nodes_were_needed`: 需要先保留当前 integrated 状态，再恢复 `single`，否则会丢失刚完成的 SoC 接入产物。

## RTL 推导摘要

- 需求：`npc/single` 应继续作为不依赖 ysyxSoCFull 的老 NPC 版本，`NpcCore` 端口恢复为旧 IFU/LSU AXI-like ABI；`npc/soc` 保留 ysyxSoC wrapper、AXI4 bridge 和 SoC 构建目标。
- 协议：`single` 中 `NpcAxiBus` 仍通过层次化引用 `u_core.ex_any_flush_w` 获取 IFU abort，避免给老 `NpcCore` ABI 增加 SoC 专用端口；`soc` 中保留 `ifu_axi_abort_o`，供 `NpcSoCAxiBridge` 在 AXI4 R 通道 drain/drop 旧响应。
- 状态机：`single` 不新增状态机；恢复到 `NpcSimTop/NpcAxiBus` 原有 IFU abort 处理。`soc` 维持此前 `NpcSoCAxiBridge` 的 `RD_IDLE/RD_AR/RD_R` 读桥状态机。
- 不变量：`single` 不包含 `ysyx_26010035`、`NpcSoCAxiBridge`、`soc/soc-lint` 和 `soc-main.cpp`；`soc` 作为复制版保留完整接入链。两个目录的默认 `make lint` 都应通过。
- 数据通路：`single` 路径为 `NpcCore -> NpcSimTop -> NpcAxiBus/AxiDpiSlave`；`soc` 路径为 `ysyxSoCFull -> ysyx_26010035 -> NpcCore + NpcSoCAxiBridge`。

## 节点概览

| node_id | owner_agent | status | inputs | outputs | evidence |
| ------- | ----------- | ------ | ------ | ------- | -------- |
| `copy-integrated-tree` | Codex | completed | 当前已接入 SoC 的 `npc/single` | 新增 `npc/soc`，排除 build/perf results/testbench build | `npc/soc/Makefile` 保留 `soc/soc-lint` |
| `restore-single-abi` | Codex | completed | `npc/single` SoC 接入改动 | 移除 SoC 目标和 wrapper/bridge，恢复 `NpcCore` 老端口 | `rg` 确认 single 无 `ysyx_26010035/NpcSoCAxiBridge/soc-lint` |
| `verify-both-trees` | Codex | completed | 两套目录 | lint/build/smoke 通过 | 见 evidence summary |
| `record` | Codex | completed | 改动与验证结果 | 本 task-run 与 memory 更新 | 本目录与 `.github/memory/*` |

## 关键产物

- `artifacts`: `npc/soc/` 完整 SoC 接入目录；`npc/single/` 恢复为非 ysyxSoCFull 版本。
- `logs_or_traces`: 终端验证命令输出。
- `linked_memory_updates`: `.github/memory/project-status.md`、`.github/memory/modules/npc.md`

## 当前阻塞点

- `blockers`: 无
- `missing_dependencies`: 无
- `risk_assessment`: `npc/soc` 是目录复制，会和 `npc/single` 后续演进产生双份维护成本；后续修改公共 core 时需要明确是否同步到两个目录。

## 下一步建议

1. 后续老 NPC 仿真默认在 `npc/single` 运行；ysyxSoC 接入验证默认在 `npc/soc` 运行。
2. 如果两个目录长期共存，建议后续补 README，明确哪些配置/脚本/测试分别属于 single 与 soc。

## 模板升级候选

- `repeated_dynamic_subgraph`: 无
- `should_promote_to_static_template`: 否
- `reason`: 这是一次目录拆分任务。

## 收尾结论

- `final_result`: 已新增 `npc/soc` 作为 ysyxSoC 接入版本，并将 `npc/single` 恢复为不包含 ysyxSoCFull 接入目标的老 NPC 版本。
- `evidence_summary`: `make -C npc/single lint` PASS；`make -C npc/soc lint` PASS；`make -C npc/soc soc-lint` PASS；`make -C npc/soc soc` PASS；`./npc/soc/build/ysyxSoCFull` 退出码 0；`npc/single` 的 `tb_npc_core_smoke/mcycle/interrupt` 均 PASS；`git diff --check -- npc/single npc/soc ...` PASS。
- `notes`: 复制时排除了 `build/`、`perf/results/`、`testbench/build/`，并在 `.gitignore` 补入 `npc/soc` 的构建/生成目录和 `gmon.out`，避免把大量生成产物纳入新目录。
