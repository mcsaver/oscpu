# Task Report: RV64 AxiLiteXbar Two-Master Grant

## 结论
`AxiLiteXbar` 已完成当前 IFU/LSU `M_COUNT=2` grant 热路径的一轮商业 RTL 风格收敛：read/write per-slave grant 不再在真实双 master 场景下依赖变量步进扫描，而是显式 2-way priority select；通用 `M_COUNT!=2` fallback 保留。

## RTL 变更
- Read grant：当 `M_COUNT==2` 时，按 `rd_rr_q[s]` 显式尝试 master0/master1 或 master1/master0；要求 slave read idle、master read 非 busy、target 命中且未处于 abort 屏蔽。
- Write grant：当 `M_COUNT==2` 时，按 `wr_rr_q[s]` 显式尝试两路 master；要求 AW/W 都已 hold、master write 非 busy且 target 命中。
- RR 更新、owner 记录、abort/drop-drain、AW/W split 和 R/B response route 保持既有状态机边界。

## Testbench
新增 `tb_axi_lite_xbar`，覆盖：
- default slave route；
- R response buffer；
- read abort 后 drop-drain；
- 两 master 同 slave round-robin；
- AW/W 分拍到达；
- B response owner route。

## 验证结果
- `make -C npc/rv64/testbench TESTS="tb_axi_lite_xbar" run`：PASS，结果目录 `npc/rv64/perf/results/20260604-120751/module-testbench`。
- `make -C npc/rv64/testbench TESTS="tb_axi_lite_xbar tb_ooo_fetch_axi_bridge tb_ooo_mem_axi_bridge tb_axi_lite_plic tb_axi_lite_clint tb_axi_lite_to_uart" run`：6/6 PASS，结果目录 `npc/rv64/perf/results/20260604-120814/module-testbench`。
- `make -C npc/rv64 lint`：PASS。
- `make -C npc/rv64 -j2`：PASS。
- `make -C Linux/tools smoke-opensbi`：PASS；新二进制 build time `12:08:31, Jun 4 2026`；OpenSBI v1.8 banner、`S` marker、GOOD TRAP；`cycles=4847043`、`commits=4626235`、`CPI=1.048`、`CLINT mtime = 4847043 (mtime-cycles=+0, match=yes)`。

## 边界
- 本轮不是多 outstanding xbar。
- 本轮不引入 response route queue 或重排序。
- 本轮不声明完整 line-based cache、host 仿真性能 A/B、综合/STA 或最终平台 PPA signoff。
