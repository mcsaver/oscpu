# V11I attempt-10 checker validation

## Selected artifact identity

- Summary SHA-256:
  `41087b7ddcda060ea8587878e68aa7529e4ed7a076d7cb9fb7d8c8f6571722e6`.
- Validation receipt SHA-256:
  `b674da863d7a6fdda64aab94501513a58aa5f8453689159cbac2ae30f056aa70`.
- Canonical design-id:
  `sha256:78f154580593b5a3442ed6cf5ca2159ef18779a3903a70e816f34a7e1aff481f`.
- Production profiles: 2/2 compile rc=0, simulation rc=0.
- Stale-tuple profiles: 2/2 compile rc=0, expected simulation rc=1 with
  one exact holder-next or raw-Q ABA marker.
- Runner inputs and full RTL identity: pre/post identical.

## Commands and observations

1. Runner classifier tests:
   `python3 npc/rv64/testbench/scripts/test_run_v11i_terminal_lifecycle.py -v`
   → 6/6 PASS.
2. Immutable attempt-9 under the corrected validator:
   `v11i_terminal_lifecycle_evidence.py --summary ...attempt-9/summary.json`
   → rc=1,
   `[V11I-EVIDENCE-VALIDATION][FAIL] terminal lifecycle contract binding mismatch`.
3. Versioned attempt-10 generation:
   `run_v11i_terminal_lifecycle.py --result-dir ...attempt-10`
   → 4/4 PASS, `source_unchanged=1`, `rtl_unchanged=1`.
4. Attempt-10 validation:
   `v11i_terminal_lifecycle_evidence.py --summary ...attempt-10/summary.json
   --receipt-out ...attempt-10/validation-receipt.json`
   → PASS.
5. Validator tests with attempt-10:
   `V11I_EVIDENCE_SUMMARY=...attempt-10/summary.json
   python3 .../test_v11i_terminal_lifecycle_evidence.py -v`
   → 8/8 PASS.

The eight validator tests include explicit negative cases for a lane6 contract
observation and a commands.json record missing
`-DV11I_TERMINAL_LIFECYCLE_FOCUSED`. No production RTL or full-system workload
was changed or executed.

