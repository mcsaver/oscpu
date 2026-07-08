# Task Report: flag-ON Linux focused smokes

- `status`: completed
- `profile`: npc-dev
- `profile`: rv64-linux
- `task`: Close the B7 flag-ON focused Linux smoke prerequisite and update lifecycle docs without claiming full rootfs boot completion.
- `started_at`: 2026-07-07
- `completed_at`: 2026-07-07

## Summary

I added a reproducible `OOO_CSR_QUEUE_HEAD=1` simulator path (`build-csrqh/NpcSimTop`) and wired Linux to select it with `NPC_OOO_CSR_QUEUE_HEAD=1`. I also repaired stale focused smoke assumptions: SRET/Sv39 smokes now configure PMP before entering S/U, and the virtio-blk DPI model now interprets NPC LSU low-lane wstrb correctly for 32-bit MMIO registers at offsets like `0x014`.

## Verification

- Flag-ON NPC build: PASS.
- Linux flag-ON path resolution: PASS, points at `npc/rv64/build-csrqh/NpcSimTop`.
- Flag-ON focused Linux smokes: 5/5 PASS (`sret-user-sv39`, `sret-user-sv39-halfword`, `sret-restore`, `sret-user-pagefault`, `virtio-blk`).
- Default `smoke-virtio-blk`: PASS after rebuilding default `NpcSimTop`.

## Reviewer Notes

This removes the focused Linux smoke gap from the B7 default-on checklist. It does not justify flipping `OOO_CSR_QUEUE_HEAD` to default 1 yet; full Ubuntu/rootfs boot and `-v-`/full-state difftest remain required.

