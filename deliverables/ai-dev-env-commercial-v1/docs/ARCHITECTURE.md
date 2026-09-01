# Architecture

```text
user objective + acceptance criteria + worktree
                    |
          direct local engineering
                    |
          focused domain evidence
                    |
             result / release
```

## Canonical contract

- `.github/AGENTS.md` owns shared operating behavior.
- Root compatibility files are thin shims.
- Domain instructions own RTL, DiffTest, Linux, synthesis, STA and PPA correctness.

## Optional persistence

- SQLite memory: `.github/cache/github-index.sqlite`
- Stored docs: agents、instructions、memory、task-run Markdown
- Evidence index: `evidence_assets`
- Contracts: schema、observability、runtime artifacts、delivery

这些设施只在历史召回、跨会话持久化、published evidence 或 release 中选用。

## Skill

- Live rule packs under `.github/skills/`
- 环境维护入口：`.github/skills/agent-env-maintenance/SKILL.md`
- Skill 保持短小、可直接读取；复杂细节放入 scripts、instructions 或 DB-backed docs。

## Agent

- Agent docs: `.github/agents/*.agent.md`
- Profile graph: `.github/e2e/profiles/*.tsv`
- Maintenance gates: `scripts/agent-maintain.sh`
- Lightweight task controller: `scripts/agent-flow.c` via `scripts/agent-flow.sh`
- Optional report chain: task-report、dispatch-log、run-manifest、evidence-index

## Delivery

- Active delivery root: `deliverables/ai-dev-env-commercial-v1/`
- Legacy backup: `.github/archive/legacy-ai-dev-env-2026-06-13/`
- Package script: `scripts/package-ai-dev-env.sh`
- Audit: `python3 scripts/github_index_db.py delivery-audit`
