# V11X CONTROL-EVENT/V9R compact current-design report

## Outcome

`CONTROL-EVENT-G1` local semantic evidence is current at
`sha256:82febf4aa834d61be398197015257714cc53d81f9291a2ba998ba28644041ac4`.
Production RTL was not modified. The final architecture audit reports
`semantic_evidence=PASS`, while `closed_binding=GAP` remains intentional because
the full-core candidate still declares `sha256:04c545...`.

## Root cause and correction

The old V9O/V9R debt binding depended on broad historical source identities and
retained `.vvp` images that had correctly been removed during workspace
cleanup. The compact replacement separates:

- current full-RTL pre/post identity;
- selected RTL/TB/checker/runner identity;
- normalized simulator logs and source-changing negative RTL patches;
- the global module/architecture/PPA boundary, which remains independently
  evaluated instead of being duplicated in this debt package.

The first independent review found that the initial compact V9R set did not
dynamically bind an already-resident retry holder during C0. The final set
reuses `tb_ooo_int_backend_v11l_memory_retry_holder`, observes both holder tuples
for two barrier cycles, and rejects a separate request-gate mutation for each
bank.

## Verification

- V9O focused: `10/10 PASS`.
- V9O `OOO_CSR_QUEUE_HEAD=1`: `3/3 PASS`.
- V9O compile-success RTL variants: `11/11 rejected` (`10` dynamic, `1` lint).
- V9R/V11L baseline: `3/3 PASS`.
- V9R/V11L compile-success RTL variants: `5/5 rejected`.
- Focused checker tests: `16/16 PASS` across both compact tools and the relevant architecture-validator cases.
- Architecture audit and stored-result verification: return code `0`,
  `architecture_freeze=GAP`, `ppa=UNQUALIFIED`, `promotion_eligible=false`,
  `blockers=52`.
- `debt.CONTROL-EVENT-G1.semantic_evidence=PASS`;
  `debt.CONTROL-EVENT-G1.closed_binding=GAP` due solely to the declared
  full-core candidate cohort mismatch.

The full `test_arch_stable_freeze` suite previously produced `52/53 PASS`; its
single failure is the current-workspace test that still expects all listed old
`04c545...` debt evidence to be current despite the live `82febf...` RTL. The
assertion was not weakened or masked. The current audit records those stale
bindings explicitly.

## Retention and failed attempts

- Compiled `.vvp` images are created only under one task-owned `/tmp` root and
  removed by the runner trap.
- Five full mutated RTL copies were replaced by reconstructible unified patches;
  task-run size fell from about `4.0 MiB` to `2.4 MiB`.
- Final task-run retention: `0` `.vvp`, `0` full mutated RTL copies, five V9R
  patches, normalized logs, status receipts, source snapshots and result JSON.
- `development-attempt-1-note.json` preserves the checker-module import defect
  that failed before compilation.
- `development-attempt-2-note.json` preserves the canonical `make -C npc/rv64`
  working-directory defect. The RTL simulations and negative variants in that
  attempt completed, but the attempt remains FAIL because its final checker
  invocation did not complete.

## Next mainline boundary

Do not infer whole-core GREEN from this local closure. The next dependency is
to rebuild the full-core cohort on `82febf...` and then rebind the remaining
stale semantic evidence in dependency order. A system replay is required only
when the refreshed elaborated RTL, simulator/device semantics or frozen system
inputs differ from their accepted evidence contract.
