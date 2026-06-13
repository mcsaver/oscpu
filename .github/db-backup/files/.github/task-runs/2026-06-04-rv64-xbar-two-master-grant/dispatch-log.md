# Dispatch Log: RV64 AxiLiteXbar Two-Master Grant

## 任务
- 日期：2026-06-04
- 目标：继续按商业 ASIC RTL 风格审查仿真顶层下的实例化模块，本轮聚焦 `AxiLiteXbar`。
- 范围：`NpcAxiBus` 当前真实 IFU/LSU 两 master、平台多 slave AXI-Lite xbar；允许按验证需求新增 testbench。

## 需求
- 保持既有 AXI-Lite-like 单 beat 协议、地址映射、default slave、read abort/drop-drain、AW/W split 收集与 response owner route。
- 当前 `NpcAxiBus` 实例为 `M_COUNT=2`，旧 grant 仍用 `for (step < M_COUNT)` 按 RR 扫描 master；需要把真实热路径改为固定、可审查的 2-way select。
- 不在本轮引入多 outstanding、response queue、重排序或 line-fill cache。

## 协议规则
- 每个 slave 的 read/write 同一时刻最多一个 active owner。
- Read grant 只在 slave idle、master read 未 busy、AR target 命中且未 abort 时产生。
- Read abort 后，如果 slave AR 已送出，xbar 消费并 drop 后续 R；如果未送出，可直接释放 owner。
- Write grant 只在 slave idle、master write 未 busy、AW/W 都 hold 且 target 命中时产生。
- B/R response 只回到已记录 owner；drop response 不得回 master。

## 状态机与不变量
- 不新增状态机，保留 `rd_active/rd_ar_sent/rd_drop/rd_owner/rd_resp_valid` 与 `wr_active/wr_aw_sent/wr_w_sent/wr_owner`。
- master busy 位继续串行化同一 master 的同通道事务。
- 同一 slave 每周期最多一个 grant。
- RR 指针只在实际 grant 后翻转到另一 master。
- `M_COUNT!=2` fallback 保持原有通用扫描语义。

## 修改路径
- `npc/rv64/vsrc/bus/AxiLiteXbar.v`
- `npc/rv64/testbench/Makefile`
- `npc/rv64/testbench/tests/tb_axi_lite_xbar.sv`

## 验证调度
- `make -C npc/rv64/testbench TESTS="tb_axi_lite_xbar" run`
- `make -C npc/rv64/testbench TESTS="tb_axi_lite_xbar tb_ooo_fetch_axi_bridge tb_ooo_mem_axi_bridge tb_axi_lite_plic tb_axi_lite_clint tb_axi_lite_to_uart" run`
- `make -C npc/rv64 lint`
- `make -C npc/rv64 -j2`
- `make -C Linux/tools smoke-opensbi`
- `git diff --check` scoped to touched files and records
