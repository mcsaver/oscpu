# V9C INSTRET-G1 derivation

## Stage 1 — architectural requirement

`minstret` counts architecturally retired instructions, not backend completions.  A precise synchronous exception is
reported on the final commit interface but is not retired.  A serialized control instruction is materialized as a
lane-0 pseudo-commit only when its architectural effect actually occurs, so that visible event contributes one.
The full-core increment must therefore be the population count of final visible, valid, non-exception commit lanes.

## Stage 2a — protocol rules

1. Evaluate the final commit interface after control-pseudo-commit, core lane-0, branch-append, and core lane-1
   priority have selected the two visible lanes.
2. Define `laneN_retired = commitN_valid && !commitN_exception` and
   `retire_count = lane0_retired + lane1_retired`.
3. A control pseudo-commit is legal only as non-exceptional lane 0 with lane 1 suppressed; its count is one.
4. A precise exception contributes zero and cannot be followed by a same-cycle younger lane-1 retirement.
5. `CsrFile` samples only this final count; any pre-mux or backend-local count is diagnostic and cannot increment
   architectural state.

## Stage 2b — state transition

`OooCommitOutputMux` owns no state.  On each active edge, when cycle counting is enabled and `mcountinhibit.IR=0`,
`CsrFile.csr_minstret_q` transitions from `Q` to `Q + retire_count`.  Reset clears it.  Existing explicit CSR-write
priority is unchanged.

## Stage 2c — invariants

1. `retire_count == popcount(final_valid & ~final_exception)` and `retire_count <= 2`.
2. final control pseudo-commit -> `{lane0_valid, lane0_exception, lane1_valid, retire_count}={1,0,0,1}`.
3. final exceptional lane -> that lane contributes zero; lane-0 exception -> lane 1 invalid.
4. program-end `minstret` equals the accumulated independent final-lane oracle.
5. removing exception filtering, counting a pre-mux source, or wiring `CsrFile` to a core-local count is observable in
   the same full-core program simulation.

## Stage 2d — datapath and topology

```text
ROB/core commits -----------+
control pseudo-commit ------+--> OooCommitOutputMux final lanes
branch append --------------+                  |
                                                +--> final retire_count
                                                        |
                                                        v
                                               NpcCoreTop / CsrFile minstret
```

No new production state, bypass, queue, or combinational feedback is introduced.  The planned implementation
footprint is the existing full-core Sv39 test, a deterministic temporary-source variant runner, an evidence builder,
and architecture-ledger/checker metadata.

## Stage 3 — implementation checkpoint

Production RTL did not require a change.  The implementation adds only verification and evidence plumbing:

- the existing full-core `tb_ooo_sv39_boot` now counts exact final-bus exception and MRET/SRET/SFENCE.VMA events,
  checks `retire_count` against the final-lane population every cycle, and checks the following CsrFile edge delta;
- a temporary-source runner reconstructs three production RTL variants without editing the live files and requires
  each variant to compile/elaborate before the existing assertion or program oracle rejects it dynamically;
- a fail-closed builder binds the full RTL design identity, focused/program logs, variant source/log hashes and
  exact claim boundary; `arch_stable_freeze.py` independently reconstructs those semantics before accepting a
  CLOSED ledger entry;
- `make -C npc/rv64 check-instret-retirement` is the permanent canonical entry.

## Stage 4 — verification closure

The canonical focused run is PASS on
`design_id=sha256:6236b176da0c10bccac9c2feb405a0d65ba586d826616f0beaeee0cbbfe2f3dc`:

- program events: exception lanes 2/2 zero delta; MRET/SRET/SFENCE.VMA 1/6/1; control events 8/8 exact delta one;
- CsrFile previous-edge delta checks: 1052;
- focused tests: commit-output mux, core slice and CsrFile 3/3 PASS;
- current-source RTL variants: compile-success 3/3, dynamic rejection 3/3, production source unchanged;
- current dynamically derived module aggregate: 109/109 PASS;
- evidence parser/semantic-validator unit tests: 8/8 PASS.

Full architecture/arch-stable replay, independent workspace-file review, DB memory and e2e/strict guard remain the
enclosing V9C completion steps.  Formal PPA remains `UNQUALIFIED` and unpromoted.
