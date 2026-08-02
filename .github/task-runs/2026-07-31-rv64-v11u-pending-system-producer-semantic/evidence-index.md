# Evidence index

## Retained runner evidence

- Attempts 1 and 3 retain original `FAIL` status and diagnostics; attempt-4 retains its original PASS result but is superseded because its shared-TB source binding is no longer current.
- Canonical current evidence: `evidence/attempt-5/runner.status`, `summary.json`, `source-before.sha256`, `source-after.sha256`, `artifact-cleanup.json`, `profiles/` and `regressions/`.
- Attempt-5 result: 37/37 profiles, 18 mutations / 21 mutation profiles, 4/4 regressions and 66/66 retired artifacts.
- The generated TB overlays and Make include are intentionally absent after validation; their path/SHA/size and replacement receipts remain in `summary.json` and `artifact-cleanup.json`.

## Replay and ledger evidence

- V11H checker replay: `evidence/v11h-checker-replay-after-v11u-attempt-10-receipt.json`.
- Current ledger: `evidence/ledger-attempt-10/producer-holder-semantic-coverage.json`.
- Current holder graph: `.github/task-runs/2026-07-31-rv64-axi-xbar-naming-refresh/evidence/current-holder-instance-graph/holder-instance-graph.json`.
- Result: design ID `sha256:82febf4aa834d61be398197015257714cc53d81f9291a2ba998ba28644041ac4`, global `GAP`, 37 PASS / 7 FP GAP; V11U binding is `CURRENT_SELECTED_SOURCE_AND_TB_BOUND`.
- Historical VVP bytes removed during workspace compaction are fail-closed through `.github/task-runs/2026-07-31-task-run-artifact-compaction/semantic-vvp-retirement.json`.

## Independent review

- Pre-closure GAP review: `subagent-contracts/v11u-pending-system-producer-review.json` and the first section of `review-result.md`.
- Final scoped PASS review: `subagent-contracts/v11u-pending-system-producer-review-v2.json`, SHA-256 `eb5d71e4...02f30`, and the second section of `review-result.md`.

## Reusable verification entry points

- Runner and unit tests: `npc/rv64/testbench/scripts/run_v11u_pending_system_producer_semantic.py`, `test_run_v11u_pending_system_producer_semantic.py`.
- Ledger checker and tests: `npc/rv64/eval/ppa/tools/producer_holder_semantic_coverage.py`, `npc/rv64/eval/ppa/tests/test_producer_holder_semantic_coverage.py`.
- Delivery gate: `make -C npc/rv64 check-producer-holder-semantic-coverage`.

The final delivery invocation returned 0 after 19 instance/census tests, 15 census-related tests, 112 replay/semantic tests, current graph/census markers, V11H replay PASS and the expected 37/7 global ledger boundary.
