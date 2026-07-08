# Context Brief: flag-ON Linux focused smokes

- `profile`: npc-dev
- `profile`: rv64-linux
- `source`: `python3 scripts/github_index_db.py brief "OOO_CSR_QUEUE_HEAD flag ON full Linux boot -v full-state difftest serialize-at-retire" --profile npc-dev`
- `source`: `python3 scripts/github_index_db.py brief "rv64-linux focused smokes OOO_CSR_QUEUE_HEAD virtio-blk sret sv39" --profile rv64-linux`

## Recall

The current B7 lifecycle said the four CSR/priv/full-state guard steps were already complete and `OOO_CSR_QUEUE_HEAD=1` was no longer blocked by a CSR difftest blind spot. The remaining default-on prerequisites were Linux boot coverage and `-v-`/full-state difftest.

This slice narrowed the Linux prerequisite: focused SRET/Sv39/pagefault/virtio-blk smokes now run through the flag-ON NPC binary. Full Ubuntu/rootfs boot and `-v-`/full-state difftest remain open.

