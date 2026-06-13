# Dispatch Log: RV64 OooDataWordCache WSTRB Mux

## 任务
- 日期：2026-06-04
- 目标：继续按商业 ASIC RTL 风格推进 RV64 core，清理真实路径中的仿真式数据通路写法。
- 当前节点：`OooDataWordCache` store-hit byte strobe merge。

## 需求
- 保持 `OooMemAxiBridge` 中 physical word D-cache 的组合 lookup、read fill、store commit 和 invalidate 行为。
- 将旧 `merge_wstrb()` 的 `for (byte_idx < STRB_W)` byte loop 改成 RV64 固定 8-lane mux。
- 新增 direct testbench 锁住 byte merge 与 cache 分配/失效规则。
- 不引入 line cache、多 outstanding、LSQ、store buffer 或替换策略改动。

## 协议规则
- `req_lookup` 与 `walk_lookup` 为组合查询，cacheable 仅限 PMEM window。
- `fill_valid_i` 在时钟沿写入 valid/tag/data。
- `store_commit_i` 表示 store 已经到达 D-cache 副作用边界；未提交或被 flush abort 的 store 不更新 cache。
- store hit 时按 `store_wstrb_i` 更新 selected byte。
- store miss 时只有 full-word strobe 才 allocate；partial strobe 不 allocate。
- `store_invalidate_all_i` 在 commit 周期清 valid。

## 状态机与不变量
- 无显式 FSM；状态为 `valid_q/addr_q/data_q`。
- reset 只清 valid，payload 在 invalid 时为 don't-care。
- hit 必须满足 cacheable、valid 和完整 word address tag 相等。
- partial store hit 不得改未选 byte。
- partial store miss 不得产生 valid entry。
- full store miss 可创建 valid entry。
- invalidate_all 后旧 entry 不得继续命中。

## 数据通路
- `merge_wstrb64()` 显式展开 byte7..byte0 八个 old/new mux。
- store hit 路径只调用该 mux。
- store miss 分配路径直接写完整 `store_data_i`。

## 验证调度
- `make -C npc/rv64/testbench TESTS="tb_ooo_data_word_cache" run`
- `make -C npc/rv64/testbench TESTS="tb_ooo_data_word_cache tb_ooo_mem_axi_bridge" run`
- `make -C npc/rv64/testbench TESTS="tb_ooo_data_word_cache tb_ooo_mem_axi_bridge tb_ooo_sv39_boot tb_ooo_alu_fetch_core" run`
- `make -C npc/rv64 lint`
- `make -C npc/rv64 -j2`
- `make -C Linux/tools smoke-opensbi`
- scoped `git diff --check`
