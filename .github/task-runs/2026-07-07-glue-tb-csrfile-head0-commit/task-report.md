# Task Report: glue TB CsrFile head0 commit

- `status`: completed
- `profile`: npc-dev
- `task`: Close the stale B7 glue TB CsrFile stub prerequisite by wiring head0 CSR commit into the existing stub and updating current lifecycle docs.
- `started_at`: 2026-07-07
- `completed_at`: 2026-07-07

## Summary

The listed "glue TB CsrFile stub" item was half true but stale. The stub already existed; it just did not commit CSR writes from the queue-head CSR path. I wired `head0_csr_commit_w` into the TB CsrFile stub and matched the real top-level commit rule used by `NpcCoreTop`.

## Verification

- Default `tb_ooo_core_top_glue`: PASS.
- Flag-ON `tb_ooo_core_top_glue` with `-DOOO_CSR_QUEUE_HEAD=1`: PASS.
- Flag-ON log confirms the define was present in the compile command.
- `git diff --check`: PASS.
- `make -C npc/rv64 check-contract`: PASS (`11/11`).
- `scripts/agent-e2e.sh --guard --guard-mode strict`: PASS (`npc-dev` resolved to this task-run).

## Reviewer Notes

This removes glue TB from the B7 default-on prerequisite list. It does not justify flipping `OOO_CSR_QUEUE_HEAD` by itself; full Linux boot and `-v-`/full-state difftest remain open.
