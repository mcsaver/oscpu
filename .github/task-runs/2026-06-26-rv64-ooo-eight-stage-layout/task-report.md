# RV64 OoO Vsrc Layout

## Scope

- Refactor `npc/rv64/vsrc` so the outer directories are the only physical RTL
  hierarchy.
- Map the active OoO implementation onto the requested CPU core categories:
  front-end, rename/allocate, OoO scheduling, register read/bypass, execution,
  memory subsystem, writeback/commit, and cross-cutting control.
- Keep module names and public ports stable.
- Limit behavior-changing risk to mechanical front-end extractions: move the
  return-address stack state into `OooRasStack`, move the return-continuation
  pending state into `OooReturnContBuffer`, then move branch-target capture
  pending state into `OooBranchTargetCaptureBuffer`.
- Add focused evidence for new helpers and keep default/legacy regression
  status explicit instead of treating focused OoO PASS as full-suite PASS.

## RTL derivation

- Requirements: make the active RV64 OoO RTL match the core microarchitecture
  taxonomy without keeping a parallel `ooo/` directory tree.
- Protocol rules: RAS update is single-clock; reset/flush has priority, then
  clear, then pop, then push. Return-continuation update is also single-clock;
  reset/flush clears first, then RAS clear, then capture, then consume.
  Branch-target capture update is single-clock; reset/flush clears first,
  precise trap global clear wins over arm, direct branch arm wins over ordinary
  frontend clear, and hit clear is gated off during branch-target cache
  invalidate-all.
- FSM/state: `OooRasStack` owns only `stack_q/count_q/reliable_q`;
  `OooReturnContBuffer` owns only pending continuation valid/PC/next PC/inst.
  `OooBranchTargetCaptureBuffer` owns only one pending branch PC/target PC
  entry and response-hit detection. The front-end still owns fetch, redirect,
  FIFO seed paths, safe decode, and recovery state.
- Invariants: RAS empty/full/top/reliable behavior matches the old local state;
  full push overwrites the last slot and clears reliability; clear restores an
  empty reliable stack. Branch-target capture payload is stable while pending,
  clears to zero when idle, and never decides whether an instruction is safe to
  cache.
- Datapath constraints: no module port renames, no external bus protocol
  change, no ROB/IQ/PRF contract change.

## Changes

- Removed the `vsrc/ooo` shell and moved OoO-specific RTL into outer `vsrc`
  directories:
  `frontend/`, `decode/`, `cache/`, `rename_allocate/`, `scheduling/`,
  `regread_bypass/`, `execute/`, `memory/`, `writeback/`, `control/`.
- Updated `npc/rv64/vsrc/filelist.mk` so module tests and default RV64 builds
  consume the new paths.
- Added `npc/rv64/vsrc/frontend/OooRasStack.v`.
- Added `npc/rv64/vsrc/frontend/OooReturnContBuffer.v`.
- Added `npc/rv64/vsrc/frontend/OooBranchTargetCaptureBuffer.v`.
- Added `npc/rv64/testbench/tests/tb_ooo_branch_target_capture_buffer.sv`.
- Rebaselined `tb_multiplier` and `tb_divider` for RV64 XLEN expectations.
- Rebaselined legacy cache/core tests for RV64 64-bit cache beats,
  `STRB_W=8`, synchronous SRAM reads, and zero-extended physical address
  construction in legacy `NpcCore` smoke programs.
- Added `npc/rv64/vsrc/README.md` and `npc/rv64/vsrc/control/README.md`.

## Verification

- `tb_ooo_alu_fetch_core`: PASS.
- `tb_ooo_dispatch_backend`: PASS.
- `tb_ooo_int_backend`: PASS.
- `tb_ooo_fetch_axi_bridge`: PASS.
- `tb_ooo_mem_axi_bridge`: PASS.
- `tb_ooo_fp_iter`: PASS.
- `tb_ooo_branch_target_capture_buffer`: PASS.
- `tb_multiplier`: PASS after XLEN-aware expected values.
- `tb_divider`: PASS after XLEN-aware latency guard and expected values.
- `tb_icache`: PASS after 64-bit fill beat rebaseline.
- `tb_dcache`: PASS after 64-bit beat/8-bit strobe rebaseline.
- `tb_npc_core_smoke`: PASS after 64-bit IFU beat and RV64 address fix.
- `tb_npc_core_mcycle`: PASS after 64-bit IFU beat fix.
- `tb_npc_core_interrupt`: PASS after 64-bit IFU beat and RV64 `mtvec`
  address fix.
- `make -C npc/rv64/testbench ... run`: PASS, 52/52 module tests.
- `make -C npc/rv64 lint`: PASS.
- `make -B -C npc/rv64 -j2`: PASS.
- `make -C Linux/tools smoke-jal-link smoke-branch-raw smoke-ras-trap-boundary`:
  PASS / GOOD TRAP.
- `git diff --check`: PASS.

Focused module logs are under
`npc/rv64/perf/results/20260626-vsrc-merged-layout/module-testbench/logs/`.

Return-continuation extraction was rechecked with `tb_ooo_alu_fetch_core` and
`tb_ooo_int_backend`; focused logs are under
`npc/rv64/perf/results/20260626-return-cont-buffer/module-testbench/logs/`.

Branch-target capture extraction was rechecked with `tb_ooo_alu_fetch_core` and
`tb_ooo_int_backend`; focused logs are under
`npc/rv64/perf/results/20260626-branch-target-capture-buffer/module-testbench/logs/`.

Default `make -C npc/rv64/testbench run` now passes 52/52. The stale
aggregate FAIL list was caused by old RV32-style expectations in legacy
cache/core tests, not by the branch-target capture extraction. Known issue
[100] records the root cause and closure.

## Boundary

This pass fixes the physical RTL framework and extracts RAS, the adjacent
return-continuation buffer, and branch-target capture pending state. It does
not split all cross-cutting control out of `OooAluFetchCore`; `control/` is now
the outer-directory landing zone for later flush/recovery/CSR/interrupt
refactors. It also intentionally leaves the fetch FIFO and branch-prefetch state
in place until redirect and seed paths are normalized. Full industrial signoff
still requires broader system-level gates beyond module-level regression.
