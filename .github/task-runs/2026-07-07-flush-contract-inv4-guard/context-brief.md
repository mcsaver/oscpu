# Context Brief: flush contract INV-4 guard

- 用户目标是持续推进任务，且相关任务清单要在对应 `.md` 中体现。
- `ROADMAP.md` 当前指向 B7 flag-ON 前置：full Linux boot、`-v-`/full-state difftest、glue TB CsrFile stub；上轮已关闭四步护栏链。
- `ooo-flush-redirect-contract.md` §6.4/§8 仍记录 Step 0/INV-4 未落地；但同文档后续记录显示 INV-1/2/3、GAP-6、UC-A 已落。
- `serialize-at-retire-phase1.md §10.4` 是 INV-4 的当前语义真源：head0-CSR 退休不能等 `SQ empty`，只能等 `mem_idle`，否则 younger uncommitted store 会让 SQ 永不空而死锁。
- 当前 RTL 也与 §10.4 一致：`OooIntBackend` 把 `OooRob.mem_quiet_i` 接到 `mem_idle_o`，并保留 `mem_retire_quiet_o` 给 drain/backend_drained。
- 因此本切片的真实工作是：把 INV-4 两半接进 in-RTL `OOO_ASSERT`，并把 contract/phase1/ROADMAP/memory 的待办状态校正。
