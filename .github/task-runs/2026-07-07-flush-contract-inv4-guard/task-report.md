# Task Report: flush contract INV-4 guard

- `status`: completed
- `profile`: npc-dev
- `profile`: agent-system
- `profile`: difftest
- `profile`: nemu-dev
- `task`: Continue B7 flag-ON preparation by landing flush/redirect INV-4 in-RTL guards and lifecycle-correcting related task lists.
- `started_at`: 2026-07-07
- `completed_at`: 2026-07-07

## Summary

INV-4 is no longer a stale backlog item. The current Phase1 truth is now encoded in RTL assertions: head0-CSR commit is blocked unless memory is idle, and SQ flush cannot clear committed stores. The contract text was updated from the old `SQ empty` wording to the actual `mem_idle` semantics.

## Verification

- Scoped `git diff --check`: PASS.
- `make -C npc/rv64 check-contract`: PASS (`11/11`).
- `make -C npc/rv64 -j2`: PASS.
- `make -C npc/rv64/testbench TESTS="tb_ooo_store_queue tb_ooo_rob" run`: PASS 2/2.
- `scripts/agent-e2e.sh --guard --guard-mode strict`: PASS (`npc-dev` resolved to this task-run).

## Reviewer Notes

This closes one B7 flag-ON guardrail, not B7 itself. The remaining explicit checklist is full Linux boot, `-v-`/full-state difftest, and the glue TB CsrFile stub before considering `OOO_CSR_QUEUE_HEAD` default-on.
