# Context Brief: ssvnapot npc/nemu

- `python3 scripts/github_index_db.py brief ssvnapot svnapot npc nemu` 指向同一条边界：NEMU 已实现 Svnapot 64KiB NAPOT leaf，NPC 仍把 leaf PTE.N 当 reserved fault。
- `python3 scripts/github_index_db.py brief ssvnapot svnapot ptw pte npc nemu --profile difftest` 的核心召回：完整 riscv-tests full-state difftest 暴露 `ssvnapot/Svnapot` 是真分歧；NEMU 对齐 sail-rv64-max，NPC 缺扩展实现。
- `.github/memory/modules/nemu.md` 既有记录：`mmu.c pte_napot_mask` 已实现 level0 + `PTE.N` + `PPN[3:0]=0b1000`，低 PPN bit 取自 VA。
- `.github/memory/modules/npc.md` / known issues 既有记录：NPC 当时 `Svnapot` 未覆盖，PTE reserved/fault 规则此前把 N 当 reserved。
- `rv64ssvnapot/napot.S` 特性：裸跑下不实现 Svnapot 也可能被 handler skip 成 pass；必须用 NPC+NEMU full-state difftest 判定两侧是否真正对齐。
