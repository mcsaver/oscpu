# Task Report: rv64-uart-rx-smoke-manual

- **profile**: manual targeted node check for `npc-rv64-uart-rx-smoke`
- **status**: PASS
- **date**: 2026-06-12
- **purpose**: 验证 NPC RV64 16550 UART RX 寄存器语义和 DPI 宿主输入注入链路。

## Evidence

- `evidence/npc-rv64-uart-rx-smoke/module-testbench.log`
- `evidence/npc-rv64-uart-rx-smoke/runtime.log`
- `evidence/npc-rv64-uart-rx-smoke/runtime/console.log`
- `evidence/npc-rv64-uart-rx-smoke/runtime/npc.log`

## Result

- `tb_uart` PASS
- `tb_axi_lite_to_uart` PASS
- Runtime smoke PASS: `NPC_UART_RX_TEXT=xy NPC_UART_RX_TRACE=1` 在 1000-cycle NPC run 中记录 `loaded bytes=2`、`pop=1 data=0x78`、`pop=2 data=0x79`。

## Boundary

该 run 只证明 UART RX/RDA/DPI 注入链路可用，不声明 Ubuntu systemd userspace、login 或 shell 已完成。
