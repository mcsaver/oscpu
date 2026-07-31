# Evidence index

## Retained runner evidence

- Attempt-1 original status and diagnostic: `evidence/attempt-1/runner.status`, `evidence/attempt-1/error.txt`.
- Attempt-2 terminal status: `evidence/attempt-2/runner.status`.
- Attempt-2 auditable summary: `evidence/attempt-2/summary.json`.
- Current source binding: `evidence/attempt-2/source-before.sha256`, `evidence/attempt-2/source-after.sha256`.
- Compact artifact retirement: `evidence/attempt-2/artifact-cleanup.json`.
- Directed simulation logs and profile receipts: `evidence/attempt-2/profiles/` and `evidence/attempt-2/regressions/`.

## Ledger evidence

- Current ledger: `evidence/semantic-ledger-current/producer-holder-semantic-coverage.json`.
- Result: `GAP`, design ID `sha256:82febf4aa834d61be398197015257714cc53d81f9291a2ba998ba28644041ac4`, 37 PASS / 7 GAP.
- V11U binding: `CURRENT_SELECTED_SOURCE_AND_TB_BOUND`.

## Reusable verification entry points

- Runner: `npc/rv64/testbench/scripts/run_v11u_pending_system_producer_semantic.py`.
- Runner unit tests: `npc/rv64/testbench/scripts/test_run_v11u_pending_system_producer_semantic.py`.
- Ledger checker: `npc/rv64/eval/ppa/tools/producer_holder_semantic_coverage.py`.
- Ledger checker tests: `npc/rv64/eval/ppa/tests/test_producer_holder_semantic_coverage.py`.

