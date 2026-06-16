# Task Report

## 基本信息

- `task_id`: `2026-05-23-npc-soc-device-map`
- `task_slug`: `npc-soc-device-map`
- `graph_template`: `custom`
- `graph_mode`: `dynamic`
- `status`: `completed`
- `owner`: `Codex`
- `started_at`: `2026-05-23`
- `updated_at`: `2026-05-23`

## 任务目标

- `source_request`: 按用户给出的 ysyxSoC 设备地址表，为 CLINT/SRAM/UART/SPI/GPIO/PS2/MROM/VGA/Flash/ChipLink/PSRAM/SDRAM 等设备预留接口。
- `goal`: 在 NPC 仿真顶层总线保留这些地址窗口，未实现设备先有明确 SLVERR 响应，后续替换真实 IP 时不改 `NpcCore`。
- `scope`: `npc/single/vsrc/include/define.v`、`npc/single/vsrc/sim/NpcSimTop.sv`；补充任务记录和 NPC 模块记忆。

## 选图说明

- `selected_template`: `custom`
- `why_this_graph`: 本任务是 RTL 总线地址图扩展，不属于 bug 复现，也不是完整 AM 设备闭环实现。
- `dynamic_nodes_added`: `recall`、`derive-rtl`、`implement-map`、`verify`、`record`
- `why_dynamic_nodes_were_needed`: 需要先确认现有 NPC core/SoC 边界，再决定设备接口放在 `NpcSimTop` 而不是 `NpcCore`。

## RTL 推导摘要

- 需求：`NpcCore` 保持 IFU/LSU AXI-like master ABI 不变；`NpcSimTop` 按表预留 SoC slave 窗口。已有 CLINT/UART/PSRAM 仿真通路继续接真实实现，未实现窗口接错误 slave。
- 协议规则：继续使用现有 single-beat AXI-like valid/ready。未实现设备读返回 `rresp=2'b10`，写返回 `bresp=2'b10`，不能静默返回 OKAY。
- 状态机：crossbar 不新增状态机；未实现窗口复用 `AxiDefaultSlave` 的 `rvalid/bvalid/aw_seen/w_seen` 状态机；CLINT/UART/PSRAM 沿用已有状态机。
- 不变量：地址表按 first-match 解码；default slot 位于最后；未实现窗口必须命中 stub；core ABI 不随外设列表扩展；legacy DPI MMIO 是当前 AM/NEMU 兼容例外，不属于严格 SoC 地址表。
- 数据通路骨架：`define.v` 定义 base/mask；`NpcSimTop` 固定 slave index 并通过 generate 为 stub 窗口实例化 `AxiDefaultSlave`；PSRAM 地址窗口接 `AxiDpiSlave` 以保持 0x8000_0000 镜像执行路径。

## 节点概览

| node_id | owner_agent | status | inputs | outputs | evidence |
| ------- | ----------- | ------ | ------ | ------- | -------- |
| `recall` | Codex | completed | AGENTS、memory、NPC study、现有 RTL | 确认设备应挂在 `NpcSimTop/NpcAxiBus` 层 | 已读取 `.github/**` 与 `npc/single/design/study/**` |
| `derive-rtl` | Codex | completed | 用户地址表、现有 bus 协议 | RTL 推导摘要 | 本文件“RTL 推导摘要” |
| `implement-map` | Codex | completed | `define.v`、`NpcSimTop.sv` | 新增地址宏、15 个 slave 槽位、stub generate | `git diff --check` PASS |
| `verify` | Codex | completed | 修改后 RTL | lint/build/smoke 通过 | `make -C npc/single lint` PASS；`make -C npc/single -j14` PASS；`add-riscv32-npc.bin` GOOD TRAP |
| `record` | Codex | completed | 改动和验证结果 | task-run 与 memory 更新 | 本目录记录、`project-status.md`、`modules/npc.md` |

## 关键产物

- `artifacts`: `npc/single/vsrc/include/define.v`，`npc/single/vsrc/sim/NpcSimTop.sv`
- `logs_or_traces`: 终端验证命令输出
- `linked_memory_updates`: `.github/memory/project-status.md`，`.github/memory/modules/npc.md`

## 当前阻塞点

- `blockers`: 无
- `missing_dependencies`: 未实现设备本体、APB/AXI4 适配、严格 ysyxSoC AM 地址迁移均不在本轮范围。
- `risk_assessment`: 当前为了兼容已有 AM/NEMU 设备，`legacy MMIO` 仍在 `0xa000_0000..0xa1ff_ffff` 覆盖 SDRAM 低 32MB；切换到严格 SoC 地址表时需要迁移或删除该兼容窗口。

## 下一步建议

1. 若要严格对齐 ysyxSoC，迁移 AM/NPC 的串口、键盘、VGA、timer 地址到表内设备窗口，并删除 legacy MMIO 覆盖。
2. 逐个用真实 IP 替换对应 `AxiDefaultSlave` stub，优先处理 PS2/VGA/SPI/Flash 这类软件可见外设。

## 模板升级候选

- `repeated_dynamic_subgraph`: 无
- `should_promote_to_static_template`: 否
- `reason`: 这是一次地址图预留，不是重复出现的调试子图。

## 收尾结论

- `final_result`: NPC 仿真顶层已按表预留 SoC 设备地址窗口，未实现设备有明确错误响应，PSRAM/CLINT/UART 保持可运行路径。
- `evidence_summary`: `lint`、Verilator 构建、`add` smoke 均通过。
- `notes`: `NpcCore` 未改端口；设备接口保留在平台总线层。
