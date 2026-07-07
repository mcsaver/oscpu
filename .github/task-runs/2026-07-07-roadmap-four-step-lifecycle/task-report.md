# Task Report: roadmap four-step lifecycle

- `status`: completed
- `profile`: npc-dev
- `profile`: nemu-dev
- `profile`: difftest
- `profile`: agent-system
- `task`: Close stale ROADMAP four-step lifecycle and finish the remaining workspace-tool Kconfig reverse dependency.
- `started_at`: 2026-07-07
- `completed_at`: 2026-07-07

## Summary

The ROADMAP four-step guardrail chain is now lifecycle-correct: steps already completed by previous engineering work are marked complete, the remaining real implementation gap was fixed, and the next action is narrowed to B7 flag-ON prerequisites. `tool/kconfig` and `tool/fixdep` now build through a workspace-level `scripts/build.mk` instead of depending on NEMU's build template.

## Verification

- `make -B -C tool/kconfig NAME=conf`: PASS.
- `make -B -C tool/kconfig NAME=mconf`: PASS.
- `make -B -C tool/fixdep`: PASS.
- `make -C nemu NEMU_HOME=/home/lyg/PA/ysyx-workbench/nemu -j2`: PASS.
- `make -C npc/rv64 -j2`: PASS.
- `make -C npc/rv64 check-contract`: PASS.
- scoped `git diff --check`: PASS.
- `scripts/agent-e2e.sh --guard --guard-mode strict`: PASS (`agent-system`, `difftest`, `nemu-dev`, `npc-dev` all resolved to this task-run).

## Reviewer Notes

B7 remains flag-gated and default-off. The task did not change NEMU or NPC architectural behavior; code changes are limited to workspace tool build plumbing, plus lifecycle-correct documentation and comments.
