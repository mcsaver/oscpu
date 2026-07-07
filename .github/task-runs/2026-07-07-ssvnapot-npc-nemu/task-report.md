# Task Report: ssvnapot npc/nemu

- `status`: completed
- `profile`: npc-dev
- `profile`: nemu-dev
- `profile`: difftest
- `task`: Implement Svnapot 64KiB NAPOT behavior in NPC and align with existing NEMU behavior.
- `started_at`: 2026-07-07
- `completed_at`: 2026-07-07

## Summary

NPC now accepts legal Svnapot 64KiB NAPOT leaf PTEs in both instruction and data Sv39 walkers, computes NAPOT PA bits from VA[15:12], and rechecks TLB hits with the stored leaf level. Invalid NAPOT encodings, non-leaf PTE.N, and level1/2 leaf PTE.N still fault. NEMU already had matching Svnapot behavior; this task only corrected stale comments there.

## Verification

- `make -C npc/rv64 check-rtl-style`: PASS。
- focused bridge TB: PASS 2/2。
- `make -C npc/rv64 lint`: PASS。
- `make -C npc/rv64 -j2`: PASS。
- `make -C npc/rv64 check-contract`: PASS。
- `make -C nemu NEMU_HOME=/home/lyg/PA/ysyx-workbench/nemu -j2`: PASS。
- `rv64ssvnapot-p-napot` NPC `--no-diff`: TOHOST PASS。
- `rv64ssvnapot-p-napot` NPC+NEMU full-state difftest: TOHOST PASS。
- scoped `git diff --check`: PASS。
- `scripts/agent-e2e.sh --guard --guard-mode strict`: PASS (`agent-system` 用既有证据，`npc-dev`/`nemu-dev`/`difftest` 用本任务证据包)。

## Reviewer Notes

No interface/FSM/handshake changed. The remaining risk is scope: this was a focused Svnapot closure, not a full riscv-tests or Linux regression.
