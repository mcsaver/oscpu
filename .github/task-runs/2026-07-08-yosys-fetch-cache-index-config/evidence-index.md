# Evidence Index: yosys-fetch-cache-index-config

## Context
- `context-brief.md`: DB bounded context for `OooFetchPacketCache` / `OooMulDivUnit` / Yosys memory-map blockers.
- `profile-resolve.md`: available agent-e2e profiles captured before final guard runs.

## Synthesis Evidence
- `evidence/syn-100mhz/make-syn-fetch-packet-cache-index8-gate.markers.log`
  - `OooFetchPacketCache` with `STA_VERILOG_DEFINES=OOO_FETCH_PACKET_CACHE_INDEX_W=8`.
  - Negative evidence: reached `MEMORY_MAP` / `ABC`, then terminated before full stdcell completion.
- `evidence/syn-100mhz/make-syn-fetch-packet-cache-index8-gate.tail.log`
  - Tail for the same negative run.
- `evidence/syn-100mhz/make-syn-fetch-packet-cache-index8-gate.log.gz`
  - Full compressed raw log.
- `evidence/syn-100mhz/make-syn-fetch-axi-bridge-cache-blackbox.markers.log`
  - `OooFetchAxiBridge` full stdcell PASS with `OooFetchPacketCache` blackboxed.
  - Confirms explicit macro boundary support and reports unknown cache macro area.
- `evidence/syn-100mhz/make-syn-fetch-axi-bridge-cache-blackbox.tail.log`
  - Tail for the bridge blackbox PASS.
- `evidence/syn-100mhz/make-syn-fetch-axi-bridge-cache-blackbox.log.gz`
  - Full compressed raw log.
- `evidence/syn-100mhz/make-syn-npctop-cache-blackbox.markers.log`
  - Pre-iter-mul `NpcTop + OooFetchPacketCache blackbox` negative run.
  - Terminates at ABC extraction for `OooMulDivUnit`.
- `evidence/syn-100mhz/make-syn-npctop-cache-blackbox.tail.log`
  - Tail for the pre-iter-mul top run.
- `evidence/syn-100mhz/make-syn-npctop-cache-blackbox.log.gz`
  - Full compressed raw log.
- `evidence/syn-100mhz/make-syn-ooo-muldiv-unit-iter-mul.markers.log`
  - `OooMulDivUnit` after iterative multiply OOC full stdcell PASS.
- `evidence/syn-100mhz/make-syn-ooo-muldiv-unit-iter-mul.tail.log`
  - Tail for the MulDiv OOC PASS.
- `evidence/syn-100mhz/make-syn-ooo-muldiv-unit-iter-mul.log.gz`
  - Full compressed raw log.
- `evidence/syn-100mhz/make-syn-npctop-cache-blackbox-iter-mul.markers.log`
  - Post-iter-mul `NpcTop + OooFetchPacketCache blackbox` negative run.
  - Advances past `OooMulDivUnit`; timeout occurs at `OooFpArithGate`.
- `evidence/syn-100mhz/make-syn-npctop-cache-blackbox-iter-mul.tail.log`
  - Tail for the post-iter-mul top run.
- `evidence/syn-100mhz/make-syn-npctop-cache-blackbox-iter-mul.log.gz`
  - Full compressed raw log.

## Functional / Tool Evidence
- `npc/rv64/perf/results/20260708-021407/module-testbench/logs/tb_ooo_muldiv_unit.log`
  - Focused `tb_ooo_muldiv_unit` PASS with matching oss-cad-suite `vvp`.
- `npc/rv64/perf/results/20260708-023134/module-testbench/logs/tb_ooo_int_backend.log`
  - Integration TB compile limitation: existing Icarus declare-after-use / implicit-wire issues, not used as MulDiv behavior evidence.
- Terminal evidence:
  - `make -C npc/rv64 check-rtl-style` PASS.
  - `make -C npc/rv64 lint` and `make -C npc/rv64 -j2` blocked by existing `Uart.v` `PROCASSINIT` warning-as-error under current Verilator.
  - `make -C Linux/tools smoke-muldiv` PASS only on stale pre-change `NpcSimTop` binary, so not counted as current RTL validation.
