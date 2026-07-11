# Retained memory history restoration verification

The generated snapshot review found that three 2026-06-25 history groups were absent from the current DB-backed documents. They were restored from the tracked recovery snapshot into the complete materialized documents and written back through `update-stored`; no RTL or executable code was changed.

## Restored retained documents

```text
PASS update-stored .github/memory/modules/abstract-machine.md bytes=30707 chunks=9
PASS update-stored .github/memory/modules/am-kernels.md bytes=35362 chunks=10
PASS update-stored .github/memory/modules/nemu.md bytes=550998 chunks=106
PASS snapshot-stored documents=5284 backup_dir=.github/db-backup/stored-snapshot manifest_entries=5386
```

Relative to the previously tracked recovery snapshot, `abstract-machine.md` is byte-restored and has no diff. The updated `am-kernels.md` and `nemu.md` snapshots contain only later additions (`5/0` and `11/0` added/deleted lines); the reviewed 2026-06-25 history is no longer deleted.

## Fresh profile and guard

The task report records `agent-system` completed with all nine nodes PASS. The fresh evidence also satisfies the semantic guard for an agent-system source path:

```text
[agent-e2e-guard] mode=strict changed_paths=1 required_profiles=1
[agent-e2e-guard] PASS profile=agent-system evidence=.github/task-runs/2026-07-12-strict-guard-memory-history-restore-agent-system reason=.github/e2e/README.md
```

The repository-wide guard inferred only `npc-dev` from the remaining user-owned dirty RTL paths and accepted their existing semantically fresh evidence:

```text
[agent-e2e-guard] mode=strict changed_paths=34 required_profiles=1
[agent-e2e-guard] PASS profile=npc-dev evidence=.github/task-runs/2026-07-11-rv64-authority-evidence-final-npc-dev reason=npc/rv64/vsrc/debug/OooAdUpdateChecker.sv; npc/rv64/vsrc/frontend/OooFrontend.v; npc/rv64/vsrc/sim/NpcSimTop.sv
```

## Final audits

```text
PASS artifact-audit contract=.github/ai-env/contracts/agent-env-runtime-artifacts.json roots=2 ignore_patterns=27 tracked_runtime_files=5666 tracked_heavy_files=0
PASS markdown-coverage active_md=7457 db_owned=5267 shims=18 live_evidence=0 live_rules=1
PASS db-first-audit candidates=5247 stored=5289 materialized=5127 shims=18 backup_entries=5400 backup_dir=.github/db-backup
```

`git diff --check` exited 0. This restores retained history and validates the evidence store only; it does not claim RV64 RTL completion or physical 200 MHz closure.
