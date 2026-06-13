# RV64 UART RX Wait Smoke

- date: 2026-06-12
- scope: NPC rv64core UART RX host injection gate
- result: PASS

## What Changed

- `NPC_UART_RX_WAIT=<pattern>` now holds host-provided UART RX bytes until the guest console output contains the pattern.
- The UART RX e2e smoke now waits for `OpenSBI` before releasing `NPC_UART_RX_TEXT=xy`, making it closer to NEMU's FIFO/prompt-gated guest command flow.

## Evidence

- `evidence/npc-rv64-uart-rx-smoke/module-testbench.log`
  - `PASS tb_uart`
  - `PASS tb_axi_lite_to_uart`
- `evidence/npc-rv64-uart-rx-smoke/runtime.log`
  - `loaded bytes=2 ... wait='OpenSBI'`
  - `waiting for guest output pattern='OpenSBI' before releasing bytes=2`
  - guest output contains `OpenSBI`
  - `wait pattern matched; releasing input`
  - `pop=1 ... data=0x78`
  - `pop=2 ... data=0x79`

## Limits

- This smoke proves gated UART RX release during OpenSBI/Linux startup.
- It does not claim a full Ubuntu 22.04 login shell; the runtime intentionally stops at the configured 8,000,000-cycle budget.
