# Dispatch Log

## 基本信息

- `task_id`: `2026-06-03-rv64-vivado-npctop-split`
- `task_slug`: `rv64-vivado-npctop-split`
- `graph_template`: `verilator-tapeout-readiness-loop`
- `log_policy`: `append-only`

---

### [2026-06-03 14:05] `rtl-boundary-split` - `completed`

- `owner_agent`: `codex`
- `trigger`: 用户要求将真正 `NpcTop` 作为综合/时序顶层，DPIC 只留外层仿真 wrapper。
- `depends_on`: 当前 RV64 OoO 顶层与 bus/peripheral 拓扑。
- `inputs`: `npc/rv64/vsrc/sim/NpcSimTop.sv`, `npc/rv64/vsrc/core/NpcCoreTop.v`, `npc/rv64/vsrc/bus/*.v`
- `action`: 新增 `NpcTop.v`，下沉 core、AXI crossbar、UART、CLINT、PLIC、默认 slave；`NpcSimTop` 改为实例化 `NpcTop` 并连接 DPI memory/virtio。
- `outputs`: `npc/rv64/vsrc/core/NpcTop.v`, 更新后的 `NpcSimTop.sv`
- `evidence`: `make -C npc/rv64 lint` PASS
- `handoff_to`: `filelist-cleanup`
- `next_step`: 更新 `RTL_CORE_SRCS` 与 Vivado 默认 top。
- `notes`: 仿真统计仍通过层次化只读路径观察 `u_top.u_core/...`。

### [2026-06-03 14:20] `filelist-cleanup` - `completed`

- `owner_agent`: `codex`
- `trigger`: Vivado Sources GUI 显示孤立平台模块，用户要求清理索引。
- `depends_on`: `rtl-boundary-split`
- `inputs`: `npc/rv64/vsrc/filelist.mk`, `npc/rv64/Makefile`, `fpga/Makefile`
- `action`: 将 `NpcTop.v` 纳入 `RTL_CORE_SRCS`；默认 `RTL_CORE_TOP=NpcTop`；`fpga` 默认工程改为 `npc_rv64_top/TOP=NpcTop`；修复 filelist 生成脚本的内层 make 目录打印污染。
- `outputs`: `fpga/filelists/npc_rv64_top_files.f`
- `evidence`: `make -C fpga filelist` PASS，输出 42 个 RTL 源。
- `handoff_to`: `vivado-project-index-check`
- `next_step`: 创建 Vivado 工程并检查 `.xpr`。
- `notes`: 检查确认 filelist 无 `vsrc/sim`、`AxiDpi`、`AxiLiteVirtioBlk`、`vsrc/legacy`。

### [2026-06-03 14:28] `vivado-project-index-check` - `completed`

- `owner_agent`: `codex`
- `trigger`: 需要让 Vivado 工程从 `NpcTop` 展开真实层级。
- `depends_on`: `filelist-cleanup`
- `inputs`: `fpga/scripts/create_rv64_core_project.tcl`, `fpga/filelists/npc_rv64_top_files.f`
- `action`: 执行 `make -C fpga project` 创建 Vivado batch 工程。
- `outputs`: `fpga/vivado/npc_rv64_top/npc_rv64_top.xpr`, `fpga/reports/compile_order.rpt`
- `evidence`: Vivado v2025.2 batch PASS；`.xpr` 中 `TopModule=NpcTop`；匹配检查无 `NpcSimTop/AxiDpi/AxiLiteVirtioBlk/vsrc/sim/vsrc/legacy`。
- `handoff_to`: `memory-update`
- `next_step`: 记录 memory 与本 task-run。
- `notes`: 未启动完整 synthesis，避免重复触发高内存压力。
