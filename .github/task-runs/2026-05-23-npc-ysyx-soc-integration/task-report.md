# Task Report

## 基本信息

- `task_id`: `2026-05-23-npc-ysyx-soc-integration`
- `task_slug`: `npc-ysyx-soc-integration`
- `graph_template`: `custom`
- `graph_mode`: `dynamic`
- `status`: `completed`
- `owner`: `Codex`
- `started_at`: `2026-05-23`
- `updated_at`: `2026-05-23`

## 任务目标

- `source_request`: 按截图任务把 NPC 接入 ysyxSoC，补完整 AXI4 master 顶层、Verilator 文件列表/include 路径/编译选项、SoC 顶层 CPU 名称和 DPI stub。
- `goal`: 让 `ysyxSoCFull` 能实例化当前 NPC CPU，并通过 Verilator lint、构建和最小复位仿真。
- `scope`: `npc/single/vsrc/core/NpcCore.v`、`npc/single/vsrc/core/ysyx_26010035.v`、`npc/single/vsrc/bus/NpcSoCAxiBridge.v`、`npc/single/vsrc/filelist.mk`、`npc/single/Makefile`、`npc/single/csrc/soc-main.cpp`、`ysyxSoC/src/CPU.scala`、`ysyxSoC/build/ysyxSoCFull.v`、直接实例化 `NpcCore` 的模块 testbench。

## 选图说明

- `selected_template`: `custom`
- `why_this_graph`: 本任务跨 NPC RTL、ysyxSoC Chisel wrapper、Verilator build 和 C++ 仿真入口，不是单模块 bug 修复。
- `dynamic_nodes_added`: `recall`、`derive-rtl`、`implement-wrapper`、`implement-build`、`verify`、`record`
- `why_dynamic_nodes_were_needed`: 需要先对齐 `ysyxSoC/spec/cpu-interface.md` 的端口契约，再把 NPC 内部 IFU/LSU single-beat 协议收敛到一路 AXI4 master。

## RTL 推导摘要

- 需求层：新增 ysyxSoC 规范 CPU 顶层 `ysyx_26010035`，端口命名、方向和位宽严格匹配 `spec/cpu-interface.md`；`NpcCore` 保持内部 IFU/LSU AXI-like 边界，只新增 `ifu_axi_abort_o` 把原本层次引用的取指 flush 事件显式导出。
- 协议层：ysyxSoC 侧只有一路 AXI4 master；桥接层将 LSU read 优先于 IFU read，写通道直接透传 LSU AW/W/B；所有访问按 single-beat AXI4 发出，`id=0`、`len=0`、`size=3'b010`、`burst=2'b01`、`wlast=1`。
- 状态机层：读桥使用 `RD_IDLE -> RD_AR -> RD_R`。`RD_IDLE` 选中 IFU/LSU 请求并等待/发出 AR；`RD_AR` 在 AR 未握手前允许 IFU abort 取消；`RD_R` 等待 R 返回，若 IFU 已 abort 则 drain/drop 旧响应，避免 orphan response 阻塞后续 LSU/IFU。
- 不变量层：未使用的 AXI4 slave 输出全部绑 0；未使用的 slave 输入只做 reduction 消耗；SoC 顶层名与 `marchid=26010035` 保持一致；仿真构建的 warning 抑制只挂在 SoC 专用目标，不影响默认 NPC lint。
- 数据通路骨架：`ysyx_26010035` 实例化 `NpcCore` 与 `NpcSoCAxiBridge`；`io_interrupt` 接 `irq_external_i`，软件/时钟中断暂置 0；commit/trap/debug 观测口在 SoC wrapper 内部消耗，不进入 ysyxSoC ABI。

## 节点概览

| node_id | owner_agent | status | inputs | outputs | evidence |
| ------- | ----------- | ------ | ------ | ------- | -------- |
| `recall` | Codex | completed | AGENTS、memory、ysyxSoC spec、现有 NPC RTL | 确认接口、构建链和学号模块名 | 已读取项目规则和 `ysyxSoC/spec/cpu-interface.md` |
| `derive-rtl` | Codex | completed | `NpcCore` IFU/LSU 协议、AXI4 master 规范 | RTL 推导摘要 | 本文件“RTL 推导摘要” |
| `implement-wrapper` | Codex | completed | `NpcCore` 与 AXI4 port list | `ysyx_26010035`、`NpcSoCAxiBridge`、`ifu_axi_abort_o` | `make -C npc/single lint` PASS |
| `implement-build` | Codex | completed | filelist、Makefile、ysyxSoC CPU wrapper | `soc/soc-lint` 目标、include 路径、DPI stubs、CPU 名称替换 | `make -C npc/single soc-lint` PASS |
| `verify` | Codex | completed | 修改后 RTL/build/C++ | lint/build/烟测/testbench 通过 | 见 evidence summary |
| `record` | Codex | completed | 改动和验证结果 | task-run 与 memory 更新 | 本目录记录、`project-status.md`、`modules/npc.md` |

## 关键产物

- `artifacts`: `npc/single/vsrc/core/ysyx_26010035.v`、`npc/single/vsrc/bus/NpcSoCAxiBridge.v`、`npc/single/csrc/soc-main.cpp`
- `logs_or_traces`: 终端验证命令输出
- `linked_memory_updates`: `.github/memory/project-status.md`、`.github/memory/modules/npc.md`

## 当前阻塞点

- `blockers`: 无
- `missing_dependencies`: SoC 运行有效程序、Flash/MROM 真实存储模型和 ysyxSoC 外设行为验证不在本轮范围；当前 `flash_read/mrom_read` 按任务要求提供 assert stub。
- `risk_assessment`: `make soc` 已能生成并链接最小可执行文件，但该入口只做复位和 1000 周期空跑烟测，不等价于完整 ysyxSoC 软件栈验证。

## 下一步建议

1. 若要跑真实 SoC 程序，补 Flash/MROM 加载模型，替换当前 assert stub。
2. 对 `NpcSoCAxiBridge` 增加定向 testbench，覆盖 IFU abort drop、LSU read 优先级、AW/W 不同拍到达和 R/B response 保持。

## 模板升级候选

- `repeated_dynamic_subgraph`: `cpu-interface-spec -> rtl-wrapper -> build-target -> verilator-smoke`
- `should_promote_to_static_template`: 否
- `reason`: ysyxSoC 接入是阶段性任务，后续更多是外设/存储模型验证，而不是重复包装顶层。

## 收尾结论

- `final_result`: NPC 已具备 ysyxSoC 规范 CPU 顶层，`ysyxSoCFull` 可实例化 `ysyx_26010035` 并通过 Verilator lint/build/最小仿真。
- `evidence_summary`: `make -C npc/single lint` PASS；`make -C npc/single soc-lint` PASS；`make -C npc/single soc` PASS；`./npc/single/build/ysyxSoCFull` 退出码 0；`make -C ysyxSoC verilog` no-op PASS；三个直接实例化 `NpcCore` 的 Icarus testbench 均 PASS。
- `notes`: `ysyxSoC/` 当前在外层仓库中仍显示为未跟踪目录；本轮按任务需要修改其中 `src/CPU.scala` 和 `build/ysyxSoCFull.v`。
