# V9Z pending-arch-trap memory-terminal report

## Status

`PASS` for the V9Z pending architectural-trap combinational
memory-owner-terminal subrange.

Current local RV64 RTL design ID:
`sha256:bbb9c95199ada2e0e8160c235705a270f924240b28fde6e611bd9342398084c9`.

This result does not close post-fire exactly-once behavior, overlap priority,
simulation exit, seven-kind serialized exactly-once retirement,
`SERIALIZE-G1`, full Linux flag-on, architecture-stable, synthesis/STA/power,
or PPA.  `ppa=UNQUALIFIED`.

## Root cause and pre-fix RED

The pre-fix `OooPendingDrainResolveGate` required
`mem_owner_terminalized_i` for a pending system control but not for
`pending_arch_trap_i`.  With a drained backend, ready control consumer,
`pending_arch_trap_i=1`, `pending_system_i=0`, and an active older memory
holder (`mem_owner_terminalized_i=0`), `drain_complete_o` could assert in the
same combinational cycle.  `OooCsrTrapRequestMux` then asserted:

- `pending_arch_trap_fire_o`;
- `trap_ex_valid_o`;
- `priv_predictor_boundary_o`.

The integrated pre-fix test compiled successfully and failed exactly those
four active-holder observations:

- `pre-fix-red-result.md`;
- `pre-fix-red/logs/tb_ooo_pending_arch_trap_memory_terminal.log`.

That original RED log did not embed a pre-fix source hash.  It is therefore
reported separately from the later reproducible, hash-bound
`drop-arch-trap-terminal-term` compile-success mutation.

## Minimal RTL implementation

`OooPendingDrainResolveGate` now uses:

```verilog
wire pending_serialized_mem_terminal_w =
    !(pending_system_i || pending_arch_trap_i) ||
    mem_owner_terminalized_i;
```

This condition:

- blocks a pending architectural trap while an older memory holder is active
  without an exact accepted terminal transfer;
- accepts an exact same-edge terminal transfer and the
  collector-pending-only phase through the existing production scalar;
- is true for unrelated drained control cycles carrying neither serialized
  owner, so it is not a new global memory-owner gate;
- preserves the independent ordinary-FENCE
  `!pending_system_fence_i || mem_idle_i` conjunct;
- adds no register, terminal-event filter, or deduplication state.

Production RTL SHA-256:

- `OooPendingDrainResolveGate.v`:
  `6318e792ebd9bf5fdd27fbe5f8f2bedded83c705d32926ee7e48c6a16d98269f`;
- `OooCsrTrapRequestMux.v`:
  `3d1a9e2b712b15c1af7247ba5d4863e23e38e0136af28af837a42acf61a5a6a8`.

## Focused verification

`tb_ooo_pending_arch_trap_memory_terminal` directly connects the production
drain gate to `OooCsrTrapRequestMux` and observes:

- active-holder suppression of drain, arch-trap fire, trap request, and
  predictor boundary;
- exact terminal / collector-pending-only eligibility;
- architectural trap PC/cause/tval payload;
- unrelated-control non-overconstraint;
- overlapping serialized-owner use of the exact terminal scalar;
- preservation of ordinary-FENCE full-memory-idle behavior.

`tb_ooo_pending_drain_resolve_gate` independently checks the gate equation,
the V9Y non-FENCE and CSR paths, and the ordinary-FENCE condition.
`tb_ooo_csr_trap_request_mux` preserves the standalone mux regression.

Results:

- assertion enabled: all three focused tests PASS;
- assertion disabled: drain-gate and gate-to-mux integration PASS;
- markers:
  `[V9Z-ARCH-TRAP-MEM-TERMINAL]` and `[V9Z-DRAIN-GATE]`;
- focused logs:
  `focused-green/logs/` and `focused-green-no-assert/logs/`.

The gate-to-mux testbench SHA-256 is
`7d8f60b80c07e2321fcd0c048f5301a4b1815c08e09806d37256791c10b6f7ef`.

## Compile-success negative RTL variants

`mutations/summary.json` records 4/4 independently compiled variants rejected
by their designated dynamic oracle:

1. remove the pending-architectural-trap term;
2. replace the exact terminal scalar with full `mem_idle_i`;
3. apply the memory-owner scalar unconditionally to unrelated control cycles;
4. remove the ordinary-FENCE full-`mem_idle_i` term.

Every variant has `compile_rc=0`, `simulation_rc=1`, and its expected
`[CHECK-FAIL]` marker.  Summary SHA-256:
`4017395a26a78afe0b4845b71c48bbcda54627e832674d9bfc1d38c7560d3127`.

## Current-design layered evidence

- Module aggregate:
  `module-current/summary.txt`, total 112, passed 112, failed 0.
- Functional aggregate:
  `npc/rv64/eval/ppa/evidence/functional-aggregate-result.json`,
  `status=PASS`, `exit_code=0`, module 112/112, official 177/177, AM 59/59,
  DiffTest mismatches 0, CoreMark 10 iterations / CRC `0xfcaf`, and
  Dhrystone 10,000 runs.
- Architecture:
  `architecture/final-architecture-hard-gates.json`, DI-1..DI-5 and
  OOO-1..OOO-4 all GREEN, `overall_status=GREEN`, `exit_code=0`.
- Functional and architecture evidence bind the design ID shown above.

The first foreground functional invocation reached the launcher timeout.  Its
orphaned official stage completed but did not publish AM, benchmark, or final
aggregate evidence and is not counted as PASS.  Root waited for that process
to exit, then ran one monitored canonical aggregate from the start; only the
fully published second run is used above.

The corresponding executable workflow rule is now part of
`.github/instructions/agent-e2e-workflow.instructions.md`: a foreground tool
timeout is not process exit; a matching live WSL child retains the unique
engineering-command lane; intermediate phase completion without the
canonical final result/publication remains `GAP`.  Long canonical flows may
use one hidden `Start-Process wsl.exe` with retained PID and log paths, with
PowerShell-only polling before the next WSL command.

## Implementer / reviewer result

Implementer conclusion: the root cause is a missing architectural-trap
consumer term at the existing exact memory-owner terminal boundary.  The
minimal combinational change, integrated TB, four mutations, and current
design regressions satisfy the V9Z subrange without modifying producer,
collector, tracker, CSR dispatch, or FENCE state.

Independent reviewer v1 found the pre-fix active-holder counterexample and
defined the minimal Boolean boundary.  Independent reviewer v2 then checked
the final RTL/TB hashes, mutation summary, 146-file architecture manifest,
functional result, and architecture aggregate.  It returned:

- `PASS` for the V9Z minimal combinational boundary;
- `GAP` for the wider post-fire and overlap scope.

Review artifacts:

- `reviewer-report-v1.md`;
- `reviewer-report-v2.md`;
- `subagent-contracts/reviewer-v1.json`;
- `subagent-contracts/reviewer-v2.json`, SHA-256
  `66f6519d35e690f5b93555e2abbed76ffd6c0683a584a452d86f1a29bd1b8ce2`.

Both reviewers stopped their read-only WSL commands and explicitly returned
the unique command lane.

## AI workflow and closing guard

- DB-owned memory was published before task-specific recall.
- `npc-dev` run
  `.github/task-runs/2026-07-27-rv64-pending-architectural-trap-memory-terminal-revtag-v9z/`
  completed with bounded recall and 5/5 PASS nodes.
- The first `agent-system` task slug added `rv64` to the independent focus
  conjunction and correctly remained blocked even though its 11 executable
  nodes passed.  That diagnostic run is preserved and is not completion
  evidence.
- The corrected `agent-system` run
  `.github/task-runs/2026-07-27-pending-architectural-trap-memory-terminal-agent-system-revtag-v9za/`
  reused the already published NPC memory vocabulary, completed bounded
  recall, and published 11/11 PASS nodes without weakening the recall gate.
  Its `v9za` suffix is the freshness-qualified rerun after DB backup
  reconciliation; the preceding completed `v9z` run is retained but is not
  the closing-guard candidate.
- strict guard accepts `agent-system`, `npc-dev`, `difftest`, and
  `github-index`.  It remains nonzero only for `rv64-linux`, whose existing
  long rootfs execution lacks complete guest/terminal/natural-poweroff
  evidence.  This is retained as a system-level exemption/GAP, not as PASS.
- `evidence/artifact-manifest.json` deterministically binds the task-run
  artifacts plus the referenced live RTL, TB, specification, aggregate,
  memory, and workflow files by path, size, and SHA-256.
  `evidence-index.md` is generated from that raw manifest by the canonical
  DB evidence indexer.

Detailed status: `strict-guard-status.md`.

## Explicit remaining GAP

The current integration TB is combinational.  It does not prove that the
registered pending architectural-trap owner clears on the next edge, that a
held source cannot repeat CSR/redirect side effects, or that simultaneous
architectural trap and ECALL/IRQ/xRET/CSR/FENCE sources have a complete
onehot/priority contract.

The next contract must include:

- `OooPendingTrapExitSequencer`;
- `OooPendingSystemSequencer`;
- `OooControlEventApplySequencer`;
- the production `CsrFile` path;
- a clocked gate-to-owner-to-CSR integration test.

Required observations are fire-to-next-edge clear, no duplicate side effect
without a new capture, and either explicit priority or constructive
unreachability for each overlap.  Simulation exit remains a separate
serialized-owner contract.

`SERIALIZE-G1` therefore remains `OPEN`; seven-kind exactly-once, Linux
terminal evidence, architecture-stable freeze, and PPA remain on the active
mainline.
