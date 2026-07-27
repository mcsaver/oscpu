# V9Z strict-guard status

## Final profile evidence before the closing guard

- `npc-dev`:
  `.github/task-runs/2026-07-27-rv64-pending-architectural-trap-memory-terminal-revtag-v9z/`;
  bounded recall complete, 5/5 nodes PASS, canonical publication completed.
- `agent-system`:
  `.github/task-runs/2026-07-27-pending-architectural-trap-memory-terminal-agent-system-revtag-v9za/`;
  bounded recall complete, 11/11 nodes PASS, canonical publication completed.
- The preceding diagnostic run
  `.github/task-runs/2026-07-27-rv64-single-flight-reviewer-provenance-revtag-v9z/`
  remains `blocked`: all 11 executable nodes passed, but the task slug added
  `rv64` to an otherwise agent-system-local focus and no one independent
  non-history chunk contained the complete term set.  The rerun used the
  already published NPC module-memory vocabulary and did not relax the
  independent-focus gate.
- An earlier corrected run with suffix `revtag-v9z` also completed, but a
  subsequent DB backup reconciliation refreshed the three DB-owned memory
  files.  The final `revtag-v9za` run is the freshness-qualified
  agent-system evidence used by the closing guard.

## Strict guard

Command:

```text
scripts/agent-e2e.sh --guard --guard-mode strict
```

Observed result:

- changed paths: 2373;
- required profiles: 5;
- `agent-system`: PASS;
- `npc-dev`: PASS;
- `difftest`: PASS;
- `github-index`: PASS;
- `rv64-linux`: FAIL, missing completed current evidence.

The `rv64-linux` result is an explicit system-level evidence GAP.  The
existing 36,000-second rootfs run did not reach all 17 guest checks, natural
poweroff, reset-syscon, `GOOD TRAP`, or the complete terminal transaction.
It is not reclassified as RTL failure or Linux PASS, and the V9Z
combinational result does not depend on that exemption.
