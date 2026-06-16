# RV64 Branch Target Cache Invalidate Mask 任务报告

## 结论

`OooBranchTargetCache` 的 store overlap invalidation 已从 sequential procedural entry scan 改为 structural mask + valid-vector clear。新增 direct testbench 覆盖 store selective invalidate 和 same-cycle store/capture hazard，相关前端回归、lint、build 与 OpenSBI smoke 均通过。

## 改动

- `OooBranchTargetCache.v`: 新增 `store_invalidate_mask_w` generate 网络；时钟沿用 `valid_q & ~store_invalidate_mask_w` 清 valid；新增 `capture_blocked_by_store_w` 阻止同周期污染 capture。
- `tb_ooo_branch_target_cache.sv`: 新增 direct-mapped BTB 行为测试，包括 mismatch、selective invalidate、same-cycle block、clear/invalidate_all。
- `testbench/Makefile`: 接入新 testbench。
- `.github/memory/*`: 记录本次 PPA 写法收敛、验证和边界。

## 验证证据

- `make -C npc/rv64/testbench TESTS="tb_ooo_branch_target_cache" run`: PASS。
- `make -C npc/rv64/testbench TESTS="tb_ooo_branch_target_cache tb_ooo_alu_fetch_core tb_ooo_fetch_trap_gate" run`: PASS。
- `make -C npc/rv64 lint`: PASS。
- `make -C npc/rv64 -j2`: PASS。
- `make -C Linux/tools smoke-opensbi`: PASS，OpenSBI v1.8 banner、`S` marker、GOOD TRAP，`cycles=4847043/commits=4626235/CPI=1.048`。

## 风险与后续

- 该模块仍是 direct-mapped target cache；store invalidation 只按当前 target fetch word overlap 契约清 valid。
- 后续若推进非 return indirect JALR prediction/BTB 或更强 branch speculation，需要重新定义预测状态的 flush、satp 切换、store self-modifying overlap 和 selective squash 边界。
