# V11I existing-test disposition

## Semantic-delta boundary

- Production core RTL semantic delta: **none**.
- Verification delta: the compile-define-isolated V11I path in
  `tb_ooo_int_backend.sv` changed from an intermediate lane6 local-terminal
  stimulus to the final real lane0 response-terminal path.
- Tooling delta: the existing owner-tracker test's source binding now includes its
  already-existing semantic checker; the V11I Make targets now run the versioned
  runner and independent validator.
- Existing ISA-visible result, owner identity, exactly-once terminal, recovery,
  exception-order and memory-order contracts were not changed.
- The seven row-level classifications are six `KEEP` plus one `REBIND`.
  Final-review v5 independently approved every row and the document-level binding;
  no `UPDATE_CONTRACT`, `OBSOLETE_WITH_EVIDENCE`, `RTL_REGRESSION` or
  `UNKNOWN_PENDING_REVIEW` remains in this impact set.

The old hashes below are from `ai@04a35d411b06e3db852b93a3e548efa7dc986bd7`;
the new hashes are from the reviewed V11I worktree.

## Impact set

| test_path | tested_contract | contract_class | implementation_dependency | test_disposition | disposition_reason | required_change | old_test_sha | new_test_sha | sensitivity_evidence | historical_evidence_preserved | reviewer_conclusion |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `npc/rv64/testbench/tests/tb_ooo_mem_owner_terminal_collector.sv` | accepted `{kind,token,epoch}` capture, backpressure hold and exactly-once dequeue | stable module-interface / transaction-lifecycle invariant | collector public ports and registered pending state | KEEP | V11I adds no collector RTL or checker semantic change | none | `e4dfea8e…` | `e4dfea8e…` | layered attempt-2 PASS; V11I stale-tuple variant is rejected downstream | all earlier attempts and raw logs retained | v5 APPROVED_FOR_CURRENT_SCOPE |
| `npc/rv64/testbench/tests/tb_ooo_mem_owner_tracker.sv` plus `tb_ooo_mem_owner_tracker_semantic_checker.sv` | allocation, edge-old live hold, exact free and full-P binding | stable module-interface / transaction-identity invariant | testbench source list must elaborate the existing semantic-checker module | REBIND | layered attempt-1 exposed a missing source-file binding; checker inputs, decisions and accepted set are unchanged | add the existing checker source to `TB_SRCS_tb_ooo_mem_owner_tracker` only | test `e80a219a…`; checker `06ad5c9c…`; Makefile `39a54499…` | test `e80a219a…`; checker `06ad5c9c…`; Makefile `5fb1f2ca…` | layered attempt-1 compile rc=2 is retained; attempt-2 PASS after binding repair | both failed and passing compile evidence retained | v5 APPROVED_FOR_CURRENT_SCOPE |
| `npc/rv64/testbench/tests/tb_ooo_load_queue.sv` | full-P holder residency, exact terminal history and recovery clear | stable architecture / transaction-lifecycle invariant | production LQ ports and raw state observations | KEEP | no V11I production or expected-result change | none | `4db5d72e…` | `4db5d72e…` | layered attempt-2 PASS; V11H mutation evidence remains the sensitivity owner | V11H and V11I evidence remain separate and retained | v5 APPROVED_FOR_CURRENT_SCOPE |
| `npc/rv64/testbench/tests/tb_ooo_int_backend.sv` default mode | ordinary backend dispatch, execute, memory and retirement behavior | stable integration / ISA-visible invariant | default compile path; V11I code is selected only by `-DV11I_TERMINAL_LIFECYCLE_FOCUSED` | KEEP | the existing default checker and expected results are unchanged | none for default mode | `e3c385ac…` | `be96c5f2…` | layered attempt-2 ordinary IntBackend PASS | intermediate V11I attempt history retained separately | v5 APPROVED_FOR_CURRENT_SCOPE |
| `npc/rv64/testbench/tests/tb_ooo_mem_axi_bridge.sv` | bridge request/response terminal ownership and backpressure | stable module-interface / transaction-lifecycle invariant | bridge ports and existing checker | KEEP | no bridge RTL, stimulus, checker or expected-result change | none | `fc6d14ad…` | `fc6d14ad…` | layered attempt-2 PASS | raw log retained | v5 APPROVED_FOR_CURRENT_SCOPE |
| `npc/rv64/testbench/tests/tb_ooo_dual_mem_bridge_wrapper.sv` | dual-lane bridge arbitration and exact terminal carriage | stable integration / transaction-lifecycle invariant | wrapper ports and existing checker | KEEP | no wrapper RTL, stimulus, checker or expected-result change | none | `8e9e58ec…` | `8e9e58ec…` | layered attempt-2 PASS | raw log retained | v5 APPROVED_FOR_CURRENT_SCOPE |
| `npc/rv64/testbench/tests/tb_ooo_int_backend.sv` with `tb_ooo_int_backend_v8x_bridge.svh` | parent recovery and backend/bridge owner preservation | stable architecture / recovery invariant | `-DV8X_BACKEND_BRIDGE_RECOVERY_FOCUSED` compile path; V11I compile-define branch remains inactive | KEEP | no V8X contract, checker or expected-result change | none | TB `e3c385ac…`; include `afc893e5…` | TB `be96c5f2…`; include `afc893e5…` | layered attempt-2 V8X parent recovery PASS | earlier V8X evidence and current raw log retained | v5 APPROVED_FOR_CURRENT_SCOPE |

## New regression owner

`-DV11I_TERMINAL_LIFECYCLE_FOCUSED` selects a new focused regression owner, not an
existing test being reclassified. Its production assert/release 2/2 PASS and
compile-success stale-tuple assert/release 2/2 expected rejection are bound to
the versioned V11I evidence series. Attempt-9 remains immutable with its internally
inconsistent lane6 contract field; attempt-10 remains immutable with its
checker-test sensitivity GAP. Attempt-11 is the selected lane0-bound evidence.
The intermediate lane6-focused attempts remain preserved and were not rewritten
as existing-contract changes.
