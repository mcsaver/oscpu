# Dispatch Log

- 读取 B7/serialize 相关文档后，发现 `ooo-flush-redirect-contract.md` 仍把 INV-4 作为待办，并且旧草案写成 `serial_flush` 必须在 `SQ empty` 拍触发。
- 对照 `serialize-at-retire-phase1.md §10.4` 和 RTL，确认该草案已漂移：当前正确门控是 `mem_idle`，不是 `mem_retire_quiet/sq_empty`。
- 在 `OooRob` 中新增 head0-CSR commit 不得在 `mem_quiet_i=0` 时发生的 `OOO_ASSERT`。
- 在 `OooStoreQueue` 中新增 flush 不得清 committed 或同拍 mark store 的 `OOO_ASSERT`。
- 将 `contract-assert-baseline.txt` 从 9 提升到 11。
- 更新 `ooo-flush-redirect-contract.md`、`serialize-at-retire-phase1.md`、`ROADMAP.md`、project-status 与 npc memory，把 INV-4 从待办迁移到已落地状态，并保留 B7 未完成边界。
