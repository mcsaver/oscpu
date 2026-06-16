# 2026-06-04 RV64 PLIC bitmap/wstrb dispatch log

## 目标

- 继续按仿真顶层实例化模块推进 RV64 core/SoC RTL 商业风格收敛。
- 本轮选择 `npc/rv64/vsrc/bus/AxiLitePlic.v`，原因是它位于 `NpcTop` 平台设备路径，旧实现仍存在 byte strobe 语义粗糙和 claim 仲裁线性扫描。

## 四段式推导

- 需求：保持当前 PLIC-like 设备对 source 1..31、M/S enable、pending、priority、threshold、claim/complete 和 `external_irq_o` 的既有行为；修正 `pending/enable` 只看 `WSTRB[0]` 的 bitmap 写入；去掉 byte merge loop，并把 claim 仲裁改成更适合 PPA 审查的结构。
- 协议规则：AXI-Lite 仍是单 outstanding slave，AW/W 可同拍或分拍；claim read 清 pending 并置 in-service；complete 清 in-service，若对应 source 仍为 level high 则 re-pend；software pending 写入保持在 claim clear 之后、complete re-pend 之前。
- 状态机：不新增显式 FSM，继续使用 `aw_seen_q/w_seen_q/s_axi_rvalid_o/s_axi_bvalid_o` 管理事务；PLIC 状态仍由 priority、pending、in-service、enable、threshold 寄存器组成。
- 不变量与数据通路：source0 永远无效；`WSTRB` 只更新对应 byte；同 priority 保留低 source ID；写数据/strobe padding 到固定 64-bit/8-lane；32-bit word merge 展开为 4 个 byte mux；pending level set 使用向量 OR；claim 选择使用 32 路候选加 16/8/4/2 级比较树。

## 修改记录

- `npc/rv64/vsrc/bus/AxiLitePlic.v`
  - 新增 `write_data_pad_w[63:0]` / `write_strb_pad_w[7:0]`。
  - `apply_wstrb32_lane()` 改成显式 4-lane byte mux。
  - `bitmap32()` 改成清零后低位映射，不再使用 function 内 loop。
  - `pending_next_r` 改成 vector OR 生成 source level pending，并支持 pending bitmap byte strobe merge。
  - `enable_m_q/enable_s_q` 改成按 byte strobe merge，不再只看 `WSTRB[0]`。
  - claim 仲裁改成 source candidate + balanced compare tree，替代旧 procedural scan chain。
- `npc/rv64/testbench/tests/tb_axi_lite_plic.sv`
  - 新增 source9 priority、byte1 enable strobe、source pending/claim/complete 覆盖。
  - 新增 source9 software pending byte1 strobe 注入覆盖。

## 验证记录

- `make -C npc/rv64/testbench TESTS="tb_axi_lite_plic" run` PASS，结果目录 `npc/rv64/perf/results/20260604-115404/module-testbench`。
- `make -C npc/rv64/testbench TESTS="tb_axi_lite_plic tb_ooo_priv_system tb_axi_lite_to_uart" run` PASS，最终结果目录 `npc/rv64/perf/results/20260604-115618/module-testbench`。
- `make -C npc/rv64 lint` PASS。
- `make -C npc/rv64 -j2` PASS。
- `make -C Linux/tools smoke-opensbi` PASS，OpenSBI v1.8 banner、`S` marker、GOOD TRAP，build time `11:55:08, Jun 4 2026`，`cycles=4847043/commits=4626235/CPI=1.048`。

## 边界

- 本轮不声明完整多 hart PLIC、完整 gateway/edge-trigger 模型、virtio 多源长期压力、DTB 设备模型完备或最终综合/STA/PPA signoff。
