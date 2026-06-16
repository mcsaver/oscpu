# Dispatch Log

## 基本信息

- `task_id`: `2026-05-30-rv64-uart-plic-source`
- `task_slug`: `rv64-uart-plic-source`
- `graph_template`: `custom`
- `log_policy`: `append-only`

## 记录格式

每次节点派发、状态变化、失败恢复、handoff 或证据补充时，追加一个条目。

---

### [2026-05-30 21:45] `inspect-platform-gap` - `completed`

- `owner_agent`: Codex
- `trigger`: 继续目标要求的 Linux boot 平台闭环。
- `depends_on`: 上轮 PLIC MMIO/pending 注入 smoke。
- `inputs`: `.github/memory/*`, `npc/rv64` UART/PLIC/CLINT RTL, `am-kernels` cpu-tests。
- `action`: 串行检索当前 UART/PLIC/source 接线，确认 PLIC source 仍缺真实设备驱动，UART 对 RV64 aligned byte MMIO 的 LSR 可见性也不完整。
- `outputs`: 选定 UART THRE interrupt -> PLIC source 1 作为本轮推进点。
- `evidence`: `NpcSimTop` 原 PLIC `.source_irq_i(1'b0)`；`Uart` 原只在 offset `+4` 返回 status word。
- `handoff_to`: `rtl-uart-irq`
- `next_step`: 按 RTL 四段式推导并实现 UART IRQ。
- `notes`: WSL 并行命令仍可能触发 vsock 异常，本轮验证改回串行。

### [2026-05-30 21:48] `rtl-uart-irq` - `completed`

- `owner_agent`: Codex
- `trigger`: UART 需要成为 PLIC 的真实 source。
- `depends_on`: `inspect-platform-gap`
- `inputs`: `Uart.v`, `AxiLiteToUart.v`
- `action`: 为 UART 增加 `IER/IIR/LCR/LSR` 最小状态模型、aligned beat read byte mux、`irq_o`；adapter 透出 `uart_irq_o`。
- `outputs`: UART THRE interrupt 可由 `IER[1]` 触发，IIR read 清 pending。
- `evidence`: `tb_uart`、`tb_axi_lite_to_uart` PASS。
- `handoff_to`: `rtl-plic-gateway`
- `next_step`: 防止 PLIC level source 在 claim 后立即重复 pending。
- `notes`: UART 仍不建模 RX FIFO/baud/FIFO depth。

### [2026-05-30 21:50] `rtl-plic-gateway` - `completed`

- `owner_agent`: Codex
- `trigger`: 真实 level source 不能继续使用纯 pending bit 模型。
- `depends_on`: `rtl-uart-irq`
- `inputs`: `AxiLitePlic.v`
- `action`: 增加 `in_service_q`，claim 读进入 in-service，completion 写 source id 1 退出；in-service 期间屏蔽 source re-pending，completion 时若 source 仍高则重新 pending。
- `outputs`: PLIC claim/complete 更接近真实 gateway 边界。
- `evidence`: `tb_axi_lite_plic` PASS，覆盖 level source in-service/re-pend。
- `handoff_to`: `wire-top`
- `next_step`: 顶层接线。
- `notes`: 仍是单 source 模型。

### [2026-05-30 21:52] `wire-top` - `completed`

- `owner_agent`: Codex
- `trigger`: 让真实 `NpcSimTop` 的 external IRQ 来自 UART。
- `depends_on`: `rtl-uart-irq`, `rtl-plic-gateway`
- `inputs`: `NpcSimTop.sv`
- `action`: 新增 `uart_irq_w`，`AxiLiteToUart.uart_irq_o` 接入 `AxiLitePlic.source_irq_i`。
- `outputs`: UART -> PLIC -> core external IRQ 路径闭合。
- `evidence`: rv64 lint/build PASS。
- `handoff_to`: `mini-boot-test`
- `next_step`: 写端到端 cpu-test。
- `notes`: `plic-sirq` 的软件 pending 注入仍保留用于受控 smoke。

### [2026-05-30 21:53] `mini-boot-test` - `completed`

- `owner_agent`: Codex
- `trigger`: 需要证明不是只在模块 testbench 内成立。
- `depends_on`: `wire-top`
- `inputs`: `am-kernels/tests/cpu-tests`
- `action`: 新增 `uart-plic-sirq.c`：S-mode 配 PLIC，写 UART `IER[1]` 触发 THRE interrupt，`wfi` 后进入 S handler，claim source 1、读 `IIR=0x02`、关 IER、complete、`sret`。
- `outputs`: 真实 `NpcSimTop` 端到端 UART external interrupt mini boot。
- `evidence`: `uart-plic-sirq` PASS，`HIT GOOD TRAP`，`cycles=458/commits=115/CPI=3.983`。
- `handoff_to`: `regression`
- `next_step`: 复跑 focused 回归和 smoke。
- `notes`: 这是设备语义测试，不作为性能基准。

### [2026-05-30 21:54] `regression` - `completed`

- `owner_agent`: Codex
- `trigger`: 确认新 UART/PLIC 行为不破坏既有路径。
- `depends_on`: `mini-boot-test`
- `inputs`: focused testbench, rv64 lint/build, `plic-sirq`, `add`
- `action`: 串行运行 8 项 focused、lint、build、两个 external interrupt cpu-test、基础 add smoke 和 `git diff --check`。
- `outputs`: 验证闭环。
- `evidence`: focused 8/8 PASS；rv64 lint/build PASS；`uart-plic-sirq` PASS；`plic-sirq` PASS；`add` PASS，`CPI=0.900`；`git diff --check` PASS。
- `handoff_to`: `memory-record`
- `next_step`: 更新 memory/task-run。
- `notes`: 真实 Linux boot 仍需 virtio/blk、DTB、OpenSBI/kernel image。

### [2026-05-30 21:54] `memory-record` - `completed`

- `owner_agent`: Codex
- `trigger`: 仓库规则要求完成后同步 project/module/task-run 记忆。
- `depends_on`: `regression`
- `inputs`: 修改清单、RTL 推导、验证结果、已知限制。
- `action`: 更新 project status、NPC/AM 模块笔记、known issue，并创建本目录 task report/dispatch log。
- `outputs`: `.github/memory/project-status.md`, `.github/memory/modules/npc.md`, `.github/memory/modules/am-kernels.md`, `.github/memory/known-issues.md`, `.github/task-runs/2026-05-30-rv64-uart-plic-source/*`
- `evidence`: 本文件与 task report。
- `handoff_to`: none
- `next_step`: virtio/blk + DTB/SBI 方向。
- `notes`: 不把 UART interrupt smoke 误报为完整 Linux boot。
