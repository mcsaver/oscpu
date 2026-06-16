# Dispatch Log

## 基本信息

- `task_id`: `2026-05-23-npc-ysyx-soc-integration`
- `task_slug`: `npc-ysyx-soc-integration`
- `graph_template`: `custom`
- `log_policy`: `append-only`

## 记录格式

每次节点派发、状态变化、失败恢复、handoff 或证据补充时，追加一个条目。

---

### [2026-05-23 00:00] `recall` - `completed`

- `owner_agent`: Codex
- `trigger`: 用户要求继续完成截图中的 ysyxSoC 接入任务。
- `depends_on`: 无
- `inputs`: `.github/AGENTS.md`、项目 memory、`ysyxSoC/spec/cpu-interface.md`、NPC RTL/filelist/Makefile。
- `action`: 梳理 CPU 顶层端口契约、现有 `NpcCore` IFU/LSU 协议、ysyxSoC 生成顶层实例名和 Verilator 构建入口。
- `outputs`: 确定新增 `ysyx_26010035` wrapper 与 `NpcSoCAxiBridge`，并将 SoC 构建做成独立 `soc/soc-lint` 目标。
- `evidence`: `marchid=26010035`，`ysyxSoCFull.v` 原实例名为 `ysyx_00000000`。
- `handoff_to`: `derive-rtl`
- `next_step`: 写 RTL 推导并落地桥接模块。
- `notes`: 默认 NPC `NpcSimTop` 保持原仿真入口，SoC 接入不替换现有运行链路。

### [2026-05-23 00:00] `derive-rtl` - `completed`

- `owner_agent`: Codex
- `trigger`: 需要把 IFU/LSU single-beat 协议映射到完整 AXI4 master。
- `depends_on`: `recall`
- `inputs`: `NpcCore` 内部总线、AXI4 master/slave 端口、IFU flush/abort 需求。
- `action`: 明确 LSU read 优先、IFU abort cancel/drop、single-beat AXI4 固定 payload、unused slave 输出绑 0 的规则。
- `outputs`: RTL 推导摘要。
- `evidence`: `task-report.md` 的“RTL 推导摘要”。
- `handoff_to`: `implement-wrapper`
- `next_step`: 新增 wrapper/bridge 并显式导出 `ifu_axi_abort_o`。
- `notes`: 不把 ysyxSoC 外设细节推进 `NpcCore` 内部。

### [2026-05-23 00:00] `implement-wrapper` - `completed`

- `owner_agent`: Codex
- `trigger`: RTL 推导完成。
- `depends_on`: `derive-rtl`
- `inputs`: `NpcCore.v`、`NpcSimTop.sv`、三个核级 testbench。
- `action`: 新增 `NpcSoCAxiBridge.v` 与 `ysyx_26010035.v`；`NpcCore` 新增 `ifu_axi_abort_o`；`NpcSimTop` 和核级 testbench 改为连接该端口。
- `outputs`: SoC CPU wrapper 与 AXI4 bridge。
- `evidence`: `make -C npc/single lint` PASS；`tb_npc_core_smoke/mcycle/interrupt` PASS。
- `handoff_to`: `implement-build`
- `next_step`: 接入 Verilator SoC 构建和 ysyxSoC CPU 名称。
- `notes`: 旧 `NpcSimTop` 中的层次引用 `u_core.ex_any_flush_w` 被公开端口替代。

### [2026-05-23 00:00] `implement-build` - `completed`

- `owner_agent`: Codex
- `trigger`: SoC wrapper 已具备。
- `depends_on`: `implement-wrapper`
- `inputs`: `filelist.mk`、`npc/single/Makefile`、`ysyxSoC/src/CPU.scala`、`ysyxSoC/build/ysyxSoCFull.v`。
- `action`: 新增 `SOC_CPU_SRCS`、`soc`、`soc-lint`、ysyxSoC perip 源文件和 UART/SPI include 路径；添加 `--timescale "1ns/1ns"`、`--no-timing`；补 `soc-main.cpp` 和 `flash_read/mrom_read` assert stubs；将 SoC CPU 名称改为 `ysyx_26010035`。
- `outputs`: `make -C npc/single soc` 可生成 `npc/single/build/ysyxSoCFull`。
- `evidence`: `make -C npc/single soc-lint` PASS；`make -C npc/single soc` PASS。
- `handoff_to`: `verify`
- `next_step`: 运行最小仿真和回归。
- `notes`: SoC 专用 warning 抑制集中在 `SOC_VERILATOR_WARN_FLAGS`，默认 `lint` 不受影响。

### [2026-05-23 00:00] `verify` - `completed`

- `owner_agent`: Codex
- `trigger`: build 入口已完成。
- `depends_on`: `implement-build`
- `inputs`: 修改后的 RTL、Makefile、C++ stub、ysyxSoC 生成物。
- `action`: 运行 Verilator lint/build、ysyxSoC Makefile no-op 检查、SoC 最小可执行文件烟测、三个核级 Icarus testbench。
- `outputs`: 验证通过。
- `evidence`: `make -C npc/single lint` PASS；`make -C npc/single soc-lint` PASS；`make -C npc/single soc` PASS；`./npc/single/build/ysyxSoCFull` 退出码 0；`make -C ysyxSoC verilog` no-op PASS；`tb_npc_core_smoke/mcycle/interrupt` PASS。
- `handoff_to`: `record`
- `next_step`: 更新 memory 与 task-run。
- `notes`: SoC 可执行文件当前只验证复位和空跑，不加载真实程序。

### [2026-05-23 00:00] `record` - `completed`

- `owner_agent`: Codex
- `trigger`: 验证完成。
- `depends_on`: `verify`
- `inputs`: 改动摘要、验证证据和剩余边界。
- `action`: 创建本 task-run，追加 project status 与 NPC memory。
- `outputs`: `task-report.md`、`dispatch-log.md`、memory 更新。
- `evidence`: 本目录文件与 `.github/memory/project-status.md`、`.github/memory/modules/npc.md`。
- `handoff_to`: 无
- `next_step`: 后续可补真实 Flash/MROM 模型和桥接 testbench。
- `notes`: 无。
