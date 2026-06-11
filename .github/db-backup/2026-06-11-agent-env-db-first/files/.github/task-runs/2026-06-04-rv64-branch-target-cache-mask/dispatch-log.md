# RV64 Branch Target Cache Invalidate Mask 调度记录

- 时间: 2026-06-04
- 范围: `npc/rv64/vsrc/frontend/OooBranchTargetCache.v`、`npc/rv64/testbench/Makefile`、`npc/rv64/testbench/tests/tb_ooo_branch_target_cache.sv`
- 目标: 将 store overlap invalidation 从时序块内 procedural entry 扫描收敛为结构化 mask 网络，并补 direct module testbench。

## 四阶段推导

1. 需求: 保持 branch target cache 的 capture、lookup、store invalidate、clear 和 invalidate_all 行为，同时提升 store invalidation 写法的 ASIC 可审查性。
2. 协议规则: lookup 为组合 direct-mapped 查询；capture 在时钟沿写 entry；store_fire 会清除 target fetch word 被 store address 覆盖的 entry；同周期 store 覆盖 capture target 时不能生成有效 entry。
3. 状态机与不变量: 无新增 FSM；`valid_q=0` 不命中；hit 需要 branch PC 和 target PC 都精确匹配；reset/clear/invalidate_all 只清 valid，payload invalid 时为 don't-care。
4. RTL 约束: 用 `store_invalidate_mask_w` 结构化生成每个 entry 的清除条件，时序块只做 valid vector mask；用 `capture_blocked_by_store_w` 显式描述 same-cycle hazard。

## 执行记录

- 检查原模块和前端调用边界后，保留既有 valid-only reset/clear/invalidate_all 风格。
- 修改 RTL: 删除时序块内 invalidate scan，新增 `gen_store_invalidate` 和 capture block 条件。
- 新增 testbench: 覆盖 reset miss、双 entry capture/hit、PC/target mismatch、store selective invalidate、same-cycle store/capture block、clear、invalidate_all 和 lookup index。
- 首次 direct TB 因 `BR0/BR1` 同 index 导致合法覆盖失败，修正 testbench 地址到不同 direct-mapped index 后通过。

## 验证

- `make -C npc/rv64/testbench TESTS="tb_ooo_branch_target_cache" run` PASS，结果目录 `npc/rv64/perf/results/20260604-123132/module-testbench`。
- `make -C npc/rv64/testbench TESTS="tb_ooo_branch_target_cache tb_ooo_alu_fetch_core tb_ooo_fetch_trap_gate" run` PASS，结果目录 `npc/rv64/perf/results/20260604-123148/module-testbench`。
- `rg -n "integer\s+invalidate_idx|lint_off|BLKSEQ" npc/rv64/vsrc/frontend/OooBranchTargetCache.v` 无输出。
- `make -C npc/rv64 lint` PASS。
- `make -C npc/rv64 -j2` PASS。
- `make -C Linux/tools smoke-opensbi` PASS，build time `12:32:26, Jun 4 2026`，GOOD TRAP，`cycles=4847043/commits=4626235/CPI=1.048`。

## 边界

- 本轮不新增完整 BTB、非 return JALR target prediction、分支方向预测、RAS 改动、line-based I-cache、多 outstanding 或综合/STA/PPA signoff。
