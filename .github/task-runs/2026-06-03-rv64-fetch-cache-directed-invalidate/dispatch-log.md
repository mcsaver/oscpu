# Dispatch Log

日期：2026-06-03

## 1. 选择边界

- `action`: 复核 `OooAluFetchCore` 内 FP helper 和 cache/BPU 全表结构。
- `finding`: FP arithmetic/div/sqrt 仍是大块组合 helper，直接整体拆分风险高；`OooFetchPacketCache` 的 store invalidate 是更小且可证明覆盖集合的 PPA 风险点。
- `decision`: 本轮先处理 fetch packet cache store invalidate，保持 FP 执行边界作为后续独立任务。

## 2. RTL 推导

- `rule`: fetch packet 覆盖 `fetch_pc..fetch_pc+7`。
- `rule`: store invalidate 按 4B word 对齐后覆盖 `store_word..store_word+3`。
- `derivation`: 合法 halfword PC 与该 store word 重叠时，只可能是 `store_word-6/-4/-2/+0/+2`。
- `implementation`: 在 halfword index 域计算 base `+ {-3,-2,-1,0,+1}` 五个候选，再用 `same_fetch_window()` 对实际 `pc_q[idx]` 复验。

## 3. 修改记录

- `action`: 删除 `integer invalidate_idx` 和 `for (invalidate_idx=0; invalidate_idx<ENTRY_COUNT; ...)` 全表扫描。
- `action`: 新增 `INVALIDATE_DELTA_1/2/3`、`invalidate_base_idx_w`、五个候选 index。
- `action`: `entry_index()` 入参收窄为 `pc[INDEX_W:1]`，避免 strict lint 下高位未使用。
- `evidence`: `npc/rv64/vsrc/cache/OooFetchPacketCache.v`

## 4. Lint 反馈

- `attempt`: 初版在 `same_fetch_window()` 内加入临时 `store_word_addr`，严格 lint 报 `BLKSEQ`。
- `fix`: 改回纯表达式计算。
- `attempt`: 初版用宽候选 PC wire 后再取 index，严格 lint 报高位未使用。
- `fix`: 直接在 halfword index 域做候选偏移，去掉无意义宽数据路径。
- `result`: 单模块严格 Verilator lint PASS。

## 5. 验证

- `command`: `verilator --lint-only -Wall -Wno-WIDTHEXPAND -Wno-WIDTHTRUNC -I... --top-module OooFetchPacketCache npc/rv64/vsrc/cache/OooFetchPacketCache.v`
- `result`: PASS
- `command`: `make -C npc/rv64 lint`
- `result`: PASS
- `command`: `make -C npc/rv64/testbench TESTS=tb_ooo_fetch_axi_bridge RESULT_TIMESTAMP=20260603-fetch-cache-directed-inv run`
- `result`: PASS
- `command`: `make -C npc/rv64 -j2`
- `result`: PASS
- `command`: `make -C Linux/tools smoke-jal-link smoke-branch-raw smoke-muldiv`
- `result`: PASS，三个用例均 GOOD TRAP
- `command`: `git diff --check`
- `result`: PASS

## 6. 结论

- `final_result`: fetch packet cache 的 store invalidate 已从 `ENTRY_COUNT` 全表扫描收敛为固定 5 候选定点失效，重叠判断仍由 `same_fetch_window()` 保守复验。
- `remaining_risk`: cache RAM 化、global clear generation bit、BPU/BTB 表项清理和 FP arithmetic/div/sqrt 执行边界仍是后续 ASIC RTL 化工作。
