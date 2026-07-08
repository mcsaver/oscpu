# Evidence Index: uart-procassinit-rv64-build-unblock

## Context

- `context-brief.md`: bounded context for `Uart PROCASSINIT`, Verilator build, and RV64 validation.
- `profile-resolve.md`: agent-e2e profile list captured before guard.

## RTL / Build Evidence

- `evidence/make-rv64-lint.log`
  - `make -C npc/rv64 lint` PASS.
  - Confirms `Uart.v PROCASSINIT` warning-as-error no longer blocks lint.
- `evidence/make-rv64-build.log`
  - Incremental `make -C npc/rv64 -j2` after the successful rebuild.
- `evidence/build-artifact-stat.log`
  - `Uart.v` mtime: `2026-07-08 02:43:14 +0800`.
  - `build/NpcSimTop` mtime: `2026-07-08 02:44:44 +0800`, newer than the changed RTL.

## Functional Evidence

- `evidence/tb-ooo-muldiv-unit.log`
  - Focused module testbench PASS.
  - Result dir: `npc/rv64/perf/results/20260708-uart-procassinit-evidence/module-testbench`.
- `evidence/linux-tools-short-smokes.log`
  - `smoke-muldiv`, `smoke-jal-link`, `smoke-branch-raw`, `smoke-sret-user-sv39-halfword` all HIT GOOD TRAP.
  - Logs show current `NpcSimTop` Build time `02:43:47, Jul 8 2026`.
- `evidence/check-rtl-style.log`
  - PASS: synthesizable RTL remains `.v` style and does not use SV always_comb/always_ff/logic.
- `evidence/check-contract.log`
  - PASS: `--assert`, `OOO_ASSERT`, and `$error` count 11/11 all satisfy the contract ratchet.
- `evidence/agent-e2e-guard-strict.log`
  - PASS: strict guard found current evidence for `agent-system`, `rv64-linux`, and `npc-dev`.

## Semantic Audit Layer Evidence

- `evidence/debug-common-files.log`
  - Lists active `npc/rv64/vsrc/common` facts and `npc/rv64/vsrc/debug` checkers.
- `evidence/filelist-common-slice.log`
  - Captures `filelist.mk` common/header slice.
- `evidence/filelist-debug-slice.log`
  - Captures `filelist.mk` debug checker slice.
- `evidence/debug-observability-slice.log`
  - Captures the project spec text describing debug/common as FSM/spec semantic observability and checker infrastructure.
