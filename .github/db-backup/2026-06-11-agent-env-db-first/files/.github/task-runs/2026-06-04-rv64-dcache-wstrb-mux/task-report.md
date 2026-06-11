# Task Report: RV64 OooDataWordCache WSTRB Mux

## 结论
`OooDataWordCache` 的 store-hit partial write merge 已从函数内 byte loop 收敛为 RV64 固定 8-lane byte-enable mux；功能协议保持不变，并新增 direct testbench 覆盖关键不变量。

## RTL 推导摘要
- 需求：保持 word D-cache lookup/fill/store/invalidate 语义，只清理 store-hit byte strobe merge 的仿真式 loop。
- 协议：lookup 组合返回；fill/store 在时钟沿落库；store commit 才能更新 cache；partial miss 不 allocate，full miss allocate。
- 状态机：无新增 FSM；仅保留 `valid_q/addr_q/data_q` 三类状态。
- 不变量：valid=0 不命中；hit 需要 cacheable+valid+tag；partial hit 只改 strobe byte；partial miss 不分配；full miss 分配；invalidate_all 清 valid。
- 数据通路：`merge_wstrb64()` 展开 byte7..byte0 八个固定 mux；store miss 分配仍直接写完整 word。

## 变更
- `npc/rv64/vsrc/cache/OooDataWordCache.v`
  - 删除 `merge_wstrb()` 内 `integer byte_idx` 与 procedural `for`。
  - 新增 `merge_wstrb64()` 显式 8-lane mux。
- `npc/rv64/testbench/tests/tb_ooo_data_word_cache.sv`
  - 新增 direct cache testbench。
- `npc/rv64/testbench/Makefile`
  - 接入 `tb_ooo_data_word_cache`。

## 验证结果
- `make -C npc/rv64/testbench TESTS="tb_ooo_data_word_cache" run`：PASS，结果目录 `npc/rv64/perf/results/20260604-122035/module-testbench`。
- `make -C npc/rv64/testbench TESTS="tb_ooo_data_word_cache tb_ooo_mem_axi_bridge" run`：2/2 PASS，结果目录 `npc/rv64/perf/results/20260604-122125/module-testbench`。
- `make -C npc/rv64/testbench TESTS="tb_ooo_data_word_cache tb_ooo_mem_axi_bridge tb_ooo_sv39_boot tb_ooo_alu_fetch_core" run`：4/4 PASS，结果目录 `npc/rv64/perf/results/20260604-122137/module-testbench`。
- `make -C npc/rv64 lint`：PASS。
- `make -C npc/rv64 -j2`：PASS。
- `make -C Linux/tools smoke-opensbi`：PASS；build time `12:21:58, Jun 4 2026`；OpenSBI v1.8 banner、`S` marker、GOOD TRAP；`cycles=4847043`、`commits=4626235`、`CPI=1.048`、`CLINT mtime = 4847043 (mtime-cycles=+0, match=yes)`。

## 边界
- 本轮不是 line-based D-cache。
- 本轮不引入多 outstanding、LSQ、store buffer、replacement/coherency 协议。
- 本轮不包含 CPU-test 全量性能 A/B 或综合/STA/PPA signoff。
