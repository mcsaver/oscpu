# Dispatch Log

## RECALL
- 读取 AGENTS/copilot/memory/known-issues 及 NPC RV64 设计规格。
- 使用 github index brief 召回 Svnapot/NPC/NEMU/difftest 历史边界。

## PLAN
- 在 NPC 取指/访存 PTW 放行合法 Svnapot 64KiB leaf。
- 同步 TLB hit 的 PA 拼接与 leaf level 复核。
- 保持 NEMU 既有实现，仅修正陈旧注释。
- 用 focused TB、RTL lint/build/contract、NEMU build、ssvnapot full-state difftest 验证。

## IMPLEMENT
- `OooFetchAxiBridge.v` / `OooMemAxiBridge.v`: `pte_reserved_fault(pte, svpbmt_en, level)`，合法 level0 64KiB NAPOT leaf 放行，非法 N 编码 fault。
- `OooSv39Tlb.v`: NAPOT PA 拼接使用 VA[15:12]。
- `define.v`: 新增 `SV39_PTE_N`。
- focused TB 补合法/非法 NAPOT、非 leaf、level1 leaf 与 PA 拼接检查。
- NEMU `isa-def.h/mmu.c` 注释更新为“Svnapot 已实现，Svpbmt 等仍未实现/仅 WARL”。

## VERIFY
- `make -C npc/rv64 check-rtl-style`: PASS。
- `make -C npc/rv64/testbench TESTS="tb_ooo_fetch_axi_bridge tb_ooo_mem_axi_bridge" RESULT_DIR=../perf/results/20260707-ssvnapot-focused/module-testbench run`: PASS 2/2。
- `make -C npc/rv64 lint`: PASS。
- `make -C npc/rv64 -j2`: PASS。
- `make -C npc/rv64 check-contract`: PASS，断言计数当前=9/基线=9。
- `make -C nemu NEMU_HOME=/home/lyg/PA/ysyx-workbench/nemu -j2`: PASS。
- `NpcSimTop --no-diff rv64ssvnapot-p-napot.bin`: TOHOST PASS，cycles=448，commits=171。
- `NpcSimTop --diff=nemu/build/riscv64-nemu-interpreter-so rv64ssvnapot-p-napot.bin`: TOHOST PASS，cycles=448，commits=171。
- scoped `git diff --check`: PASS。
- `scripts/agent-e2e.sh --guard --guard-mode strict`: PASS。

## RECORD
- 更新 `.github/memory/project-status.md`。
- 更新 `.github/memory/modules/{npc,nemu,difftest}.md`。
- 更新 NPC 设计规格：`ooo-sv39-tlb.md`、`ooo-fetch-axi-bridge.md`、`ooo-mem-axi-bridge-fsm.md`。
