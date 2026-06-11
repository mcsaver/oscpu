# RV64 Fetch Packet Cache Invalidate Mask 调度记录

- 时间: 2026-06-04
- 范围: `npc/rv64/vsrc/cache/OooFetchPacketCache.v`、`npc/rv64/testbench/Makefile`、`npc/rv64/testbench/tests/tb_ooo_fetch_packet_cache.sv`
- 状态: 已实现并验证通过。

## 四阶段推导

1. 需求: 保持 fetch packet cache 的组合 lookup、fill 写入、store/fence overlap invalidate、clear/reset 语义，同时把时序块内五个候选 index 的重复清 valid 分支收敛成显式 next-state 数据通路。
2. 协议规则: lookup 为组合读；`lookup_context_hit` 表示同 index context 匹配，`lookup_hit` 还需要 PC tag 匹配且当前 invalidate 不覆盖 lookup packet；fill 在时钟沿写 entry；invalidate 的 store word 与 packet window overlap 时清 valid；同周期 fill 被 store 覆盖时阻止写入。
3. 状态机与不变量: 无新增 FSM；reset/clear 只清 valid；valid=0 不命中；context hit 不能替代 PC tag hit；store invalidate 只能清重叠 packet；同周期 store 覆盖 fill packet 后不得产生新 hit。
4. 数据通路约束: 保留五个候选 index `{base-6, base-4, base-2, base, base+2}`，不改成全表 CAM 扫描；每个候选生成 hit，组合 next-state 只对命中的 indexed valid bit 清零，再处理未被覆盖的 fill valid bit，时钟沿统一落 `valid_q`。

## 已执行

- 修改 `OooFetchPacketCache.v`: 新增候选 invalidate hit 和 `valid_next_r` 组合 next-state，避免时序块内多处写 `valid_q`，也避免为 4096-entry valid vector 生成宽动态 one-hot shifter。
- 新增 `tb_ooo_fetch_packet_cache.sv`: 覆盖 reset miss、bare hit、same-index PC mismatch、paged context mismatch/hit、store selective invalidate、same-cycle store/fill block、clear。
- 更新 testbench Makefile，接入 `tb_ooo_fetch_packet_cache`。

## 验证

- `make -C npc/rv64/testbench TESTS="tb_ooo_fetch_packet_cache" run` PASS，结果目录 `npc/rv64/perf/results/20260604-153251/module-testbench`。
- `make -C npc/rv64/testbench TESTS="tb_ooo_fetch_packet_cache tb_ooo_fetch_axi_bridge tb_ooo_alu_fetch_core" run` PASS，结果目录 `npc/rv64/perf/results/20260604-153342/module-testbench`。
- 静态扫描 `invalidate_.*mask|<< invalidate|lint_off|BLKSEQ|integer\s+invalidate` 无命中。
- `make -C npc/rv64 lint` PASS。
- `make -C npc/rv64 -j2` PASS。
- `make -C Linux/tools smoke-opensbi` PASS，OpenSBI v1.8 banner、`S` marker 和 GOOD TRAP 可见。

备注：权限恢复后不再使用 sandbox override；验证过程中 WSL 曾出现一次 `Wsl/Service/E_UNEXPECTED`，探活并重跑相关回归后通过。后续若再出现该错误，应优先区分 Codex sandbox 配置与 WSL 服务状态，必要时改用 Windows 侧直接读写 `\\wsl$` 文件，避免重复卡在手动批准路径。
