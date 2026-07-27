# V9Z dispatch log

## Shell ownership

- Windows to WSL engineering commands remain single-flight.
- A contracted RTL reviewer may temporarily own the only WSL command lane.
- While that reviewer is active, the root node runs no WSL command.

## Pre-fix state

- Root traced `pending_arch_trap_q` through
  `OooPendingDrainResolveGate.drain_complete_o` to
  `OooCsrTrapRequestMux.pending_arch_trap_fire_o`.
- The pre-fix RTL gated the exact memory-owner terminal predicate only for
  `pending_system_i`; the pending architectural-trap consumer is a concrete
  GAP.
- Reviewer v1 contract:
  `.github/task-runs/2026-07-27-rv64-v9z-serialize-arch-trap-terminal/subagent-contracts/reviewer-v1.json`;
  SHA-256
  `4e3623d6fe948c48604fa7b21d290e9d7da48dadde0c84d47c5329984c7a4ad9`;
  canonical `create → validate → render` PASS.
- Reviewer v1 stopped all WSL commands and explicitly returned the unique
  command lane to root.
- Reviewer verdict: pre-fix `GAP`; the active-holder counterexample reaches
  `drain_complete_o`, `pending_arch_trap_fire_o`, `trap_ex_valid_o`, and
  `priv_predictor_boundary_o`.
- Reviewer report:
  `reviewer-report-v1.md`.
- Root reproduced the counterexample with the integrated gate-to-trap-mux
  testbench.  The pre-fix compile passed and the simulation failed with four
  active-holder observations.
- Root applied the minimal shared serialized-control terminal qualifier and
  preserved the independent ordinary-FENCE full-`mem_idle_i` conjunct.

## Final state

- Focused assertion-on gate/mux integration: PASS.
- Focused assertion-off gate/mux integration: PASS.
- Compile-success RTL mutations: 4/4 rejected by distinct dynamic markers.
- Module aggregate: 112/112 PASS.
- Functional aggregate: PASS, design ID
  `sha256:bbb9c95199ada2e0e8160c235705a270f924240b28fde6e611bd9342398084c9`.
- Architecture aggregate: DI-1..DI-5 and OOO-1..OOO-4 all GREEN under the
  same design ID.
- Reviewer v2 contract:
  `subagent-contracts/reviewer-v2.json`;
  SHA-256
  `66f6519d35e690f5b93555e2abbed76ffd6c0683a584a452d86f1a29bd1b8ce2`;
  canonical `create → validate → render` PASS.
- Reviewer v2 stopped all read-only WSL commands and explicitly returned the
  unique command lane.
- Reviewer v2 verdict: V9Z minimal combinational boundary `PASS`; post-fire
  next-edge clear/exactly-once and arch-trap overlap with
  ECALL/IRQ/xRET/CSR/FENCE remain `GAP`.
- Reviewer report: `reviewer-report-v2.md`.

## Execution notes

- The first foreground functional command reached the launcher timeout.
  Its remaining official-test child completed, but no AM/benchmark/final
  aggregate was published; that partial run is not completion evidence.
- Root waited for the process to exit before starting one monitored canonical
  functional aggregate.  The second run alone published the current PASS
  result.
- Architecture canonical replay then ran single-flight and published the
  nine-record current-design GREEN set.
