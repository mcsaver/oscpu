# RV64 Ubuntu probe SEIP/UART 可见性修复

## 目标

把 RV64 Ubuntu probe 从“`/init` 的 `write()` 已返回但 guest 看不到 `[ysyx-init]`”继续下切，修到至少能在 NPC/Verilator 上 guest-visible 地输出 probe marker。

## 根因

`CsrFile` 将 PLIC external IRQ 映射到 S 态 `MIP_SEIP` 时误用了 `mideleg[IRQ_CAUSE_MEI]`。Linux/OpenSBI 使用的是 supervisor external interrupt 的 delegation 位 `SEI(cause=9)`；因此修复前 UART IER 写入后 `uart_irq/plic_irq` 已经抬高，但 S 态 8250 中断服务没有按 `SEIP` 被推进，用户态 `write()` 返回后不会写 UART THR。

## 修改

- `npc/rv64/vsrc/bus/AxiLiteToUart.v`: 暴露 UART MMIO access 的 offset/wdata/wstrb/rdata。
- `npc/rv64/vsrc/sim/NpcSimTop.sv`: 将 UART access 元数据传给 DPI；新增 `npc_irq_event()` 记录 `uart_irq/plic_irq` 边沿。
- `npc/rv64/csrc/dpi.c`: 新增 `NPC_UART_ACCESS_TRACE`、`NPC_UART_ACCESS_TRACE_MIN_COMMIT`、`NPC_UART_ACCESS_TRACE_LIMIT`、`NPC_IRQ_TRACE`、`NPC_IRQ_TRACE_MIN_COMMIT`、`NPC_IRQ_TRACE_LIMIT`。
- `npc/rv64/vsrc/core/CsrFile.v`: 外部中断生成 `MIP_SEIP` 与 lower-privilege `MIP_MEIP` 屏蔽改用 `IRQ_CAUSE_SEI`。
- `npc/rv64/testbench/tests/tb_axi_lite_to_uart.sv`: 覆盖 UART access 元数据。
- `npc/rv64/testbench/tests/tb_ooo_priv_system.sv`: S external IRQ 测试改为设置 `mideleg` bit 9。

## 证据

- 负证据长跑 `npc/rv64/env/logs/codex-ubuntu-irq-after-ier/`:
  - `Run /init as init process`
  - UART IER lane1 写入：`access=1 cycle=944429182 commit=147702359 write addr=0x000 wdata=0x700 wstrb=0x2`
  - IRQ 线抬高：`uart_irq=1 plic_irq=1`
  - `write_all+0x10` 返回点命中 7 次，但 `uart-trace tx=0`、`ysyx-init=0`

- 修复后长跑 `npc/rv64/env/logs/codex-sei-fix-ubuntu-ysyx-init/`:
  - `Run /init as init process`
  - IER 写入后 PLIC 被 claim：`uart_irq=1 plic_irq=1` 随后 `plic_irq=0`
  - THR lane0 写入：`tx_valid=1 tx_data=0x5b '['`，随后输出 `y/s/y/x/-/i/n/i/t`
  - `guest-watch` 命中 `ysyx-init`
  - `exit via guest-watch, code=0, cycles=944473126, commits=147708786`

## 回归

- `make -C npc/rv64/testbench run TESTS=tb_axi_lite_to_uart` PASS
- `make -C npc/rv64/testbench run TESTS=tb_ooo_priv_system` PASS
- `make -C npc/rv64 default` PASS
- `NPC_UART_ACCESS_TRACE=1 NPC_UART_TX_TRACE=1 make -C npc/rv64/tools smoke-ubuntu-probe-watch ... UBUNTU_PROBE_EXPECT="OpenSBI v1.8"` PASS
- `NPC_GUEST_EXPECT=ysyx-init` 的 Ubuntu probe 长跑 PASS

## 边界

这次只闭合到 rv64imac syscall-only probe marker 可见。还不能声称 NPC 已完整启动官方 Ubuntu `/bin/sh`，也不能声称完整 `/etc/os-release`、rootfs mount、virtio/blk 或流片级 SoC 平台已经闭合。
