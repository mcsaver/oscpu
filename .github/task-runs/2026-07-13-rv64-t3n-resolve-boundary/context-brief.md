# Agent Brief

- `source`: live-or-stored
- `profile`: npc-dev
- `terms`: issue resolve redirect pipeline branch mispredict dispatch ready 200MHz
- `token_estimate`: 1209 / 2400

## Profile Suggestions

- `npc-dev` score=8 matched=requested-profile command=`scripts/agent-e2e.sh --profile npc-dev`
- `nemu` score=4 matched=branch, dispatch, ready, resolve command=`scripts/agent-e2e.sh --profile nemu`
- `agent-system` score=3 matched=branch, dispatch, resolve command=`scripts/agent-e2e.sh --profile agent-system`
- `yosys-sta` score=3 matched=branch, issue, resolve command=`scripts/agent-e2e.sh --profile yosys-sta`
- `github-index` score=2 matched=dispatch, resolve command=`scripts/agent-e2e.sh --profile github-index`

## Commands

- `python3 scripts/github_index_db.py brief <terms> --profile <profile>`
- `python3 scripts/github_index_db.py load --source auto --path <path>`
- `python3 scripts/github_index_db.py audit-db-first`
- `python3 scripts/github_index_db.py audit-markdown-coverage --fail-on-live-evidence`
- `scripts/agent-e2e.sh --list-profiles`
- `scripts/agent-e2e.sh --profile npc-dev`

## Recalled contract

The bounded recall selected the workspace `AGENTS.md`, `.github/AGENTS.md`,
`.github/copilot-instructions.md`, project status/known issues, the Agent E2E
README, and the `npc-dev` profile.  The operative requirements are: trace the
cross-module dataflow before changing RTL, fix the root cause, preserve evidence
in a task-run, update project/module memory, run a matching profile plus strict
guard, and use Ubuntu directly for all engineering commands behind the Windows
`wsl.exe` launcher.

## Missing profile paths reported by recall

- `.github/e2e/modules/npc-dev.md`
- `.github/agents/npc-dev.agent.md`
- `.github/memory/modules/npc-dev.md`

