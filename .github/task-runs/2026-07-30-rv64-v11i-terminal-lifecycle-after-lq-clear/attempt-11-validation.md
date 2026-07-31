# V11I attempt-11 checker validation

## Selected artifact identity

- Summary SHA-256:
  `972273f51b128c81d91fcfd1d93ba70c1792c19055a7930c885fc1703bab23cb`.
- Validation receipt SHA-256:
  `3764e0c556b7060c33557016e43aa6156b75789526ff564aada89b21c97e5e60`.
- Source manifest pre/post SHA-256:
  `aa4ab9ff32b6f5290cba4605327f047b7bbc591788bdc52bdb314e2ab0adf4ba`.
- Canonical design-id:
  `sha256:78f154580593b5a3442ed6cf5ca2159ef18779a3903a70e816f34a7e1aff481f`.
- Production profiles: 2/2 compile rc=0, simulation rc=0.
- Stale-tuple profiles: 2/2 compile rc=0, expected simulation rc=1 with
  one exact holder-next or raw-Q ABA marker.
- Runner inputs and full RTL identity: pre/post identical.

## Checker sensitivity

- Runner classifier tests: 6/6 PASS.
- Evidence validator tests: 8/8 PASS.
- The lane6 mutation is rejected by the exact contract comparison.
- The missing-focused-define fixture is written as
  `commands-without-focused-define/commands.json`, so it passes the commands-path
  binding and reaches the intended field check.
- That test requires the exact error
  `production-assert: focused compile define is missing`; rejection at
  `commands.json binding is incomplete` no longer satisfies it.

Attempt-9 and attempt-10 remain immutable superseded evidence. No production RTL,
event-deduplication logic, assertion semantics or full-system workload changed.

