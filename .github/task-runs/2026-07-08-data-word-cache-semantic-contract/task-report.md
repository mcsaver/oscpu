# OooDataWordCache semantic contract report

## Objective

Close the stale “no dedicated D-cache spec/checker” gap in the four-blackbox Yosys macro-boundary checklist, while keeping the current phase in correctness and synthesis preparation only.

## Changes

- Added `npc/rv64/design/specs/ooo-data-word-cache.md`.
- Added `npc/rv64/vsrc/common/OooDataWordCacheFacts.vh`.
- Added `npc/rv64/vsrc/debug/OooDataWordCacheChecker.sv`.
- Extended `npc/rv64/testbench/tests/tb_ooo_data_word_cache.sv` to compile the checker and cover unaligned window reads, line-cross detection, cross-line miss, and cross-line store invalidation.
- Updated `npc/rv64/testbench/Makefile` and `npc/rv64/vsrc/filelist.mk` so the focused TB sees the debug checker without putting it into `RTL_CORE_SRCS`.
- Updated `npc/rv64/design/specs/README.md`, `npc/rv64/design/specs/ooo-mem-axi-bridge-fsm.md`, `npc/rv64/design/specs/yosys-macro-boundary-contracts.md`, and `npc/rv64/vsrc/README.md`.

## Contract Coverage

The new D-cache spec freezes these semantic points:

- req hit requires PMEM cacheable and non-crossing 8B line window;
- non-crossing hit data is the line shifted by `addr[2:0] * 8`;
- crossing req must miss and is left to the bridge as a window read without fill;
- store hit performs byte-lane write-update;
- store miss is write-no-allocate;
- crossing store conservatively invalidates the current and next matching lines;
- fill must be PMEM cacheable and 8B aligned.

The debug/common layer now has a stable facts table and a checker with immediate assertions. The checker is first used by the focused TB; top-level XMR non-vacuum evidence remains a future task, not a completed claim.

## Evidence

- `evidence/tb-ooo-data-word-cache.log`: `make -C npc/rv64/testbench TESTS=tb_ooo_data_word_cache ... run` PASS.
- `evidence/check-macro-contracts.log`: four-blackbox macro contract checker PASS after the D-cache row was updated.
- `evidence/git-status-scope.log`: scoped worktree paths touched by this slice.
- `scripts/agent-e2e.sh --profile npc-dev --task-slug data-word-cache-semantic-contract --stop-on-fail`: PASS, run `.github/task-runs/2026-07-08-data-word-cache-semantic-contract-2`.
- `scripts/agent-e2e.sh --profile yosys-sta --task-slug data-word-cache-semantic-contract --stop-on-fail`: PASS, run `.github/task-runs/2026-07-08-data-word-cache-semantic-contract-3`.
- `scripts/agent-e2e.sh --guard --guard-mode strict`: PASS.
- `git diff --check`, `python3 scripts/github_index_db.py doctor --fail-on-drift`, and `python3 scripts/github_index_db.py audit-db-first`: PASS.

## Interpretation

This closes the dedicated D-cache spec/checker gap called out by the macro-boundary contract. It does not close timing, area, SRAM replacement, OOC synthesis, or STA. The remaining D-cache macro tasks are now explicit in `ooo-data-word-cache.md` and `yosys-macro-boundary-contracts.md`.

## Boundary

No Ubuntu/rootfs boot was started. No production D-cache behavior was changed; the RTL functional change is limited to test/debug/spec assets and testbench coverage.
