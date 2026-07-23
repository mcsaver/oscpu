# V9E architecture evidence workflow provenance rebind

## Scope

- Object: local RV64 Verilog/SystemVerilog processor architecture evidence.
- Allowed change: update the recorded hash of `npc/rv64/Makefile` in both the
  mandatory `provenance` field and any optional `source_manifest` field after
  adding the independent `check-xret-current-mode` evidence entry point.
- Excluded claims: this operation does not rerun or replace the nine directed
  architecture tests and does not alter their commands, logs, metrics,
  artifacts, status, or current RTL design binding.

## Fail-closed conditions

The task-local rebind utility must reject the operation unless all conditions
below hold:

1. The manifest contains exactly the nine DI-1..DI-5 and OOO-1..OOO-4 records.
2. The manifest `design_id` equals the complete current RV64 RTL source-set ID.
3. Architecture gates are either RED only at `provenance_files` and
   `provenance_digest`, or already GREEN after a prior provenance-only pass.
4. Every changed source-binding section has no live mismatch other than
   `npc/rv64/Makefile`, and its pre-change aggregate binds its recorded map.
5. Removing each record's `provenance` and optional `source_manifest` objects
   yields identical canonical projections before and after the rewrite.
6. Evaluating the candidate manifest makes all nine architecture gates GREEN.

Only after all six checks pass may the utility atomically replace the manifest.
It also emits a JSON audit containing the before/after manifest hashes, the
unchanged semantic-projection hashes, all nine per-record provenance digests,
and the pre/post gate results.

## Canonical command

```sh
python3 .github/task-runs/2026-07-21-rv64-v9e-xret-current-design/rebind-architecture-workflow-provenance.py \
  --repo-root . \
  --manifest npc/rv64/eval/ppa/evidence/architecture-current.json \
  --audit .github/task-runs/2026-07-21-rv64-v9e-xret-current-design/evidence/architecture-provenance-rebind.json
```

The first V9E pass repaired the nine `provenance` objects.  The following
arch-stable forward test exposed four optional `source_manifest` objects with
the same sole Makefile drift.  The corrected utility was therefore run a
second time with audit output `evidence/architecture-source-manifest-rebind.json`;
the first audit is retained as evidence of the discovered coverage gap.

An independent byte-level reconstruction then removes one exact literal V9E
`check-xret-current-mode` target block from the live Makefile.  The resulting
bytes reproduce the old SHA-256 recorded by all thirteen source-binding
sections, while the unmodified live bytes reproduce every new SHA-256.  This
proves the permitted Makefile delta contains no unrelated byte change; see
`evidence/makefile-xret-delta-proof.json`.
