# Strict guard semantic freshness verification

- implementation HEAD: `b68fc1ec2`
- agent-system evidence: `.github/task-runs/2026-07-12-strict-guard-semantic-freshness-agent-system-3`
- npc-dev evidence for the pre-existing dirty RTL paths: `.github/task-runs/2026-07-11-rv64-authority-evidence-final-npc-dev`

## Repository strict guard

```bash
scripts/agent-e2e.sh --guard --guard-mode strict \
  --evidence-dir .github/task-runs/2026-07-12-strict-guard-semantic-freshness-agent-system-3 \
  --evidence-dir .github/task-runs/2026-07-11-rv64-authority-evidence-final-npc-dev
```

```text
[agent-e2e-guard] mode=strict changed_paths=42 required_profiles=2
[agent-e2e-guard] PASS profile=agent-system evidence=.github/task-runs/2026-07-12-strict-guard-semantic-freshness-agent-system-3 reason=.github/e2e/README.md; .github/instructions/agent-e2e-workflow.instructions.md; scripts/README.md
[agent-e2e-guard] PASS profile=npc-dev evidence=.github/task-runs/2026-07-11-rv64-authority-evidence-final-npc-dev reason=npc/rv64/vsrc/debug/OooAdUpdateChecker.sv; npc/rv64/vsrc/frontend/OooFrontend.v; npc/rv64/vsrc/sim/NpcSimTop.sv
```

## Guard implementation path

```bash
scripts/agent-e2e.sh --guard --guard-mode strict \
  --path scripts/agent-e2e.sh \
  --evidence-dir .github/task-runs/2026-07-12-strict-guard-semantic-freshness-agent-system-3
```

```text
[agent-e2e-guard] mode=strict changed_paths=1 required_profiles=1
[agent-e2e-guard] PASS profile=agent-system evidence=.github/task-runs/2026-07-12-strict-guard-semantic-freshness-agent-system-3 reason=scripts/agent-e2e.sh
```

## Final audits

```text
PASS artifact-audit contract=.github/ai-env/contracts/agent-env-runtime-artifacts.json roots=2 ignore_patterns=27 tracked_runtime_files=5666 tracked_heavy_files=0
PASS markdown-coverage active_md=7452 db_owned=5262 shims=16 live_evidence=0 live_rules=1
PASS db-first-audit candidates=5247 stored=5284 materialized=5129 shims=16 backup_entries=5395 backup_dir=.github/db-backup
```

`git diff --check` and shell syntax validation both exited 0. These results prove the guard/evidence lifecycle only; they do not claim RV64 RTL completion or physical 200 MHz closure.
