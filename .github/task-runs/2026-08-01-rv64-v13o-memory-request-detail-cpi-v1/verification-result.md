# V13O verification result

- primary classification: `verification`
- secondary intent: `performance-cpi`
- declaration: `APPROVED_CPI_DIAGNOSTIC_ONLY`
- promotion state: `NOT_ELIGIBLE`

## Deterministic evidence

| Check | Result | Bound artifact |
| --- | --- | --- |
| current-config CoreMark v8/v4 run | PASS | `evidence/coremark-current/counter-check-result.json` |
| final-closure frozen-log replay | PASS | `evidence/checker-replay-current-closure/replay-result.json` |
| focused policy/checker tests | PASS, 57/57 | `evidence/focused-policy-tests.log` |
| fail-closed task-run status tests | PASS | `evidence/task-run-status-tests.log` |
| independent review | GAP / diagnostic-only approval | `reviewer-result.md` |

The frozen-log replay reproduced the semantic, region, CPI-stack and two-slot
objects byte-for-field under the final measurement-contract/policy/schema/
checker/test hashes.  The saved build log contains `--assert`,
`+define+OOO_ASSERT` and `+define+OOO_TERMINAL_HOLDER_ASSERT`; however its SHA
was not frozen in the pre-run identity or original post-run binding, so this is
not cryptographic proof that the bound simulator executable came from that log.

## Observed request residency

- region cycles: 5,395,310
- retired instructions: 3,183,617
- request-outstanding cycles: 1,111,757
- `S_WRITE_RESP`: 690,056 cycles
- `S_WRITE_RESP / request_outstanding`: 0.620689593139508
- detail unknown: 0

These figures are a current-config residency decomposition.  They do not prove
exclusive causality, a qualified performance baseline, production semantic
identity, or a CPI/PPA promotion.

## Explicit GAP

- V13N aggregates were not independently recomputed by the reviewer.
- Production and elaborated RTL identity are not bound by V13O.
- Assertion flags are a post-hoc saved-log observation, not an executable-bound
  proof; late-B negative-mutation sensitivity is also outside this task.
- No synthesis, STA or power evidence was produced.
- An earlier broad PPA-test discovery exposed stale historical/source bindings;
  its output was not retained as a V13O artifact and is excluded from PASS
  evidence.  Only the bounded 57-test result above is claimed.

## Storage result

- The 230,228,532-byte Verilator build tree was deleted by the fail-closed run
  driver after evidence publication.
- Frozen raw/build logs remain under this task-run, not under a temporary path.
- A rebuildable 90,511-byte Python cache directory was removed after replay.
