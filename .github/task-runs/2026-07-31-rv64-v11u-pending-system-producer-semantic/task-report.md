# V11U task report

## Outcome

The current-source `pending-system-producer` semantic unit is eligible for ledger closure. Production RTL was not modified. The semantic ledger now reports 37 PASS and 7 GAP across 44 units; all remaining GAP units are floating-point producer paths.

## Attempt history

- `evidence/attempt-1/runner.status` remains `FAIL`. Its failures were evidence-instrument issues: an unrelated width-1 backend matrix assumption, assertion probe priority, and stable-marker matching. No production RTL failure was inferred and no historical artifact was overwritten.
- `evidence/attempt-2/runner.status` is `PASS rc=0 stage=complete evidence_complete=1 cleanup_rc=0`.
- Attempt-2 reports 24/24 focused profiles, 10/10 mutation cases, 12/12 mutation simulations, and 4/4 ordinary regressions.
- Cleanup retired 28 focused compile images, 4 regression compile images, and 10 generated negative RTL variants. All 42 records retain path, SHA-256, size, and kind; the files themselves are absent.

## Scope decisions

- Current source pre/post manifests and design ID match.
- The historical `v8k-pending-system-stale-source` policy entry is retained.
- A new current selected-source/TB evidence set closes only `pending-system-producer`.
- Full-system execution, synthesis, STA, power, and PPA were not triggered because production RTL and simulator semantics did not change.

