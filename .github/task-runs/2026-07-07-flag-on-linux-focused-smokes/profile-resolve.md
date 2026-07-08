# Profile Resolve

- `profile`: npc-dev
  - Triggered by `npc/rv64/Makefile`, `npc/rv64/csrc/device/virtio_blk.c`, and B7 arch/spec memory updates.
- `profile`: rv64-linux
  - Triggered by `Linux/Makefile` and focused smoke sources under `Linux/tools/`.

## Selected Evidence

- Rebuilt default and flag-ON NPC simulators.
- Verified `NPC_OOO_CSR_QUEUE_HEAD=1` resolves `NPC_SIM` to `npc/rv64/build-csrqh/NpcSimTop`.
- Ran flag-ON focused Linux smokes: SRET/Sv39, halfword, restore, pagefault, virtio-blk.
- Ran default `smoke-virtio-blk` after rebuilding the default simulator.

