# RV64 Fetch Packet Cache Invalidate Mask 任务报告

## 当前结论

`OooFetchPacketCache` 的 store/fence overlap invalidation 已完成并验证：当前实现为结构化候选 hit + valid-vector next-state，时钟沿只有一个 owner 更新 `valid_q`。新增 direct testbench 已落盘并接入 Makefile，direct TB、相关前端 TB、lint、顶层 build 和 OpenSBI smoke 均通过。

## 改动摘要

- `OooFetchPacketCache.v`: 保留五个 overlap 候选 index，新增每候选 hit 与 `valid_next_r`；组合 next-state 清命中 valid bit并合并 fill valid，时钟沿只由一个 nonblocking assignment 更新 `valid_q`。
- `tb_ooo_fetch_packet_cache.sv`: 新增 direct module testbench，覆盖 lookup context/tag、store selective invalidate、same-cycle store/fill block 和 clear。
- `testbench/Makefile`: 新增 `tb_ooo_fetch_packet_cache` 目标。

## RTL 推导摘要

- 需求要点: 不改变 packet cache 的 lookup/fill/invalidate/clear/reset 对外行为，只把重复时序清 valid 分支变成结构化 next-state 数据通路。
- 协议: lookup 组合返回；fill 时钟沿写 entry；invalidate 表示 store word 与 8-byte fetch packet window overlap；同周期 fill 若 overlap 必须被阻止。
- 状态机: 无新增状态，仅 valid vector 和 payload arrays；reset/clear 清 valid。
- 不变量: valid=0 不命中；最终 hit 必须 PC tag 匹配；store invalidate 不应误清不相交 packet；store/fill 同窗口同周期后不得命中。
- 数据通路: 五个候选 index 只生成 hit，不做 ENTRY_COUNT 全表 CAM 扫描，也不做 ENTRY_COUNT 宽动态 one-hot shifter；组合 next-state 对 indexed bit 清零/置位后统一落库。

## 验证状态

已验证:

- `make -C npc/rv64/testbench TESTS="tb_ooo_fetch_packet_cache" run` PASS，结果目录 `npc/rv64/perf/results/20260604-153251/module-testbench`。
- `make -C npc/rv64/testbench TESTS="tb_ooo_fetch_packet_cache tb_ooo_fetch_axi_bridge tb_ooo_alu_fetch_core" run` PASS，结果目录 `npc/rv64/perf/results/20260604-153342/module-testbench`。过程中 WSL 曾出现一次 `Wsl/Service/E_UNEXPECTED`，探活后重跑通过。
- 静态扫描 `invalidate_.*mask|<< invalidate|lint_off|BLKSEQ|integer\s+invalidate` 无命中。
- `make -C npc/rv64 lint` PASS。
- `make -C npc/rv64 -j2` PASS。
- `make -C Linux/tools smoke-opensbi` PASS，OpenSBI v1.8 banner 与 `S` marker 可见，GOOD TRAP，`cycles=4847043/commits=4626235/CPI=1.048`。

边界：该任务只声明当前 fetch packet mini-cache 的 overlap invalidate/valid next-state 写法和 direct 覆盖完成，不声明 line-based I-cache、多 outstanding、完整 frontend speculation/rollback、选择性 squash 或综合/STA/PPA signoff。
