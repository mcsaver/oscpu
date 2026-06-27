# npc/rv64 ACT4 PMP closure

## Scope

- Objective: close the current RV64 core-level ACT4 PMP gate without claiming full CPU sign-off.
- Taxonomy area: cross-cutting control plus memory subsystem, because PMP CSR state feeds fetch/load/store physical access checks.
- Test assets and logs remain under `npc/rv64/testsuites` and `npc/rv64/perf/results`; this task-run only indexes evidence.

## Root Cause

- `pmpaddr` did not mask unimplemented high PA bits. The implemented physical address contract is PA[55:2], so CSR bits above that must read as zero after writes.
- On RV64, odd PMP config CSRs such as `pmpcfg1` and `pmpcfg3` are illegal. Treating them as legal WARL-zero made ACT4 `pmpsm_csr_walk-01` miss four expected illegal-instruction traps, leaving the trap signature offset at zero instead of `0x80`.

## RTL And TB Changes

- `npc/rv64/vsrc/include/define.v`: added `PMP_PADDR_BITS`, `PMP_ADDR_BITS`, and `PMP_ADDR_MASK`.
- `npc/rv64/vsrc/core/CsrFile.v`: masks PMPADDR writes/exports and only marks `pmpcfg0`/`pmpcfg2` as known on RV64.
- `npc/rv64/testbench/tests/tb_csr_file.sv`: covers PMPADDR masking and odd `pmpcfg` illegal read/write behavior.
- Existing PMP integration remains: 16 PMP entries, `PmpChecker`, fetch PMP checks, data PMP checks, and top/testbench PMP CSR wiring.

## Verification

- Focused module: `make -C npc/rv64/testbench TESTS='tb_csr_file tb_ooo_fetch_axi_bridge tb_ooo_mem_axi_bridge' RESULT_DIR=../perf/results/20260627-act4-rva22s64-pmpcfg-odd-illegal/module-focused run`
  - Result: 3/3 PASS.
  - Evidence: `npc/rv64/perf/results/20260627-act4-rva22s64-pmpcfg-odd-illegal/module-focused/summary.txt`
- Lint/build:
  - `make -C npc/rv64 lint` PASS.
  - `make -C npc/rv64 -j2` PASS.
- ACT4 PMPSm:
  - Suite: `priv/pmp/pmp64/PMPSm`
  - Result: 51/51 PASS.
  - Evidence: `npc/rv64/perf/results/20260627-act4-rva22s64-priv-pmpsm-after-pmpcfg-odd-illegal/20260627-105719-1678454/status.txt`
- ACT4 PMPS/PMPU:
  - Suites: `priv/pmp/pmp64/PMPS,priv/pmp/pmp64/PMPU`
  - Result: 18/18 PASS.
  - Evidence: `npc/rv64/perf/results/20260627-act4-rva22s64-priv-pmp-spu-after-pmpcfg-odd-illegal/20260627-105736-1679907/status.txt`
- Official riscv-tests:
  - Suites: `rv64ui,rv64um,rv64uc,rv64uzba,rv64uzbb,rv64uzbc,rv64uzbs,rv64uf,rv64ud,rv64ua,rv64mi,rv64si`
  - Result: 177/177 PASS, fail=0.
  - Evidence: `npc/rv64/perf/results/20260627-act4-rva22s64-pmp/core-regress-official-after-pmpcfg-odd-illegal/20260627-105956-1682451/status.txt`

## Remaining Boundary

- This closes the current RV64 ACT4 PMP core gate.
- It does not close Zicbo, complete ACT4/UDB, Linux/full-system, formal/property sign-off, PPA, timing, CDC, reset, physical implementation, or complete industrial CPU sign-off.
