# Dispatch Log

- `2026-05-31` `rv64-linux`: 复核 AGENTS/instructions/memory 和用户上传文档，确认当前主线为 Verilator RV64 Ubuntu probe，证据层级不得从 `init-executed` 越级到完整 Ubuntu。
- `2026-05-31` `linux-device`: 对比 NPC 日志和 Linux 8250 源码，确认 `[ysyx-init] Ubun` 正好 16 字节，与 `PORT_16550A tx_loadsz=16` 对齐，优先检查 UART THRE refill 语义。
- `2026-05-31` `linux-device`: 修改 `Uart.v`：补 DLAB、FCR FIFO enable、IIR FIFO/THRI 报告，并把 THRE IRQ 改为当前零延迟 TX 模型下的 level 条件。
- `2026-05-31` `linux-device`: 更新 `tb_uart` 与 `tb_axi_lite_to_uart`，覆盖 level IRQ、FCR/IIR、DLAB divisor 和 THR 恢复；复跑 `tb_axi_lite_plic`。
- `2026-05-31` `verilator-tapeout`: 重编译 `npc/rv64` Verilator 顶层，确认改动能进入真实仿真二进制。
- `2026-05-31` `ysyx-coordinator`: 更新 project/module/known-issues memory，并记录本 task-run。
