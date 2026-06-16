# RV64 PLIC read helper waiver 清理

## 目标

继续按商业 ASIC RTL 风格清理 RV64 活动平台 RTL 中的仿真式写法。本轮聚焦：

- `npc/rv64/vsrc/bus/AxiLitePlic.v`

目标是删除 `read_plic_word()` 内的函数局部 blocking 赋值和 `BLKSEQ` waiver，不改变 PLIC-like 设备的 AXI-Lite、pending、claim/complete 或外部中断语义。

## RTL 推导

### 需求

`AxiLitePlic` 是 `NpcTop` 平台级中断控制器，Linux/rootfs 路线依赖 UART、virtio-blk 等 source 经 PLIC/CSR 进入 core。旧 `read_plic_word()` 为 priority 区域读数据时先声明局部 `word_index`，再用 blocking 赋值 `word_index = addr_low[21:2]`，因此需要 `BLKSEQ` waiver。

该 helper 是纯组合 read-data mux，不应依赖函数内临时变量和 lint waiver。商业 RTL 审查更希望地址切片直接进入 mux/array helper，时序 always 只负责采样 read response。

### 协议规则

- AXI-Lite read：`ar_fire` 后 `s_axi_rvalid_o` 拉高，并把 `read_plic_word(read_addr_low_w)` 采入 `s_axi_rdata_o`。
- AXI-Lite write：AW/W 可分开到达，`write_done_w` 后统一更新寄存器并返回 B。
- Priority 区域按 32-bit word 编址；在 64-bit DATA_W 下，低 32-bit 返回当前 source priority，高 32-bit 返回下一 source priority。
- Pending/enable/threshold/claim-complete 地址映射和 side effect 不变。

### 状态机/不变量

- 本轮不改状态机。`rvalid/bvalid/aw_seen/w_seen`、`pending_q`、`in_service_q`、enable/threshold/priority 寄存器更新规则保持原样。
- `priority_at(index)` 的越界保护保持：`index < SOURCE_NUM` 才访问 `priority_q[index]`，否则返回 0。
- `source0` 继续固定为不可 pending、不可 in-service。
- claim read 仍清 pending 并置 in-service；complete 后若 level source 仍为 1，则重新置 pending。
- `external_irq_o` 仍由 M/S claim id 非零组合得到。

### 数据通路约束

- 删除 `read_plic_word()` 的局部 `word_index` reg。
- Priority 区域读路径直接使用：
  - low lane: `priority_at(addr_low[21:2])`
  - high lane: `priority_at(addr_low[21:2] + 22'd1)`
- 不新增端口、不改 filelist、不改 testbench。

## 代码改动

- `read_plic_word()` 删除局部 `word_index` 和 `BLKSEQ` waiver。
- 在 priority read 分支加一条中文注释，说明 64-bit beat 返回相邻两个 source priority。

## 验证

- `Select-String -Path npc/rv64/vsrc/bus/AxiLitePlic.v -Pattern 'lint_off|lint_on|BLKSEQ'`: 无命中
- `verilator --lint-only -Wall -Wno-WIDTHEXPAND -Wno-WIDTHTRUNC +incdir+./npc/rv64/vsrc/include --top-module AxiLitePlic npc/rv64/vsrc/bus/AxiLitePlic.v`: PASS
- `make -C npc/rv64/testbench TESTS='tb_axi_lite_plic tb_axi_lite_to_uart tb_ooo_priv_system' RESULT_TIMESTAMP=20260603-plic-read-helper-cleanup run`: PASS 3/3
- `make -C npc/rv64 lint`: PASS
- `make -C npc/rv64 -j2`: PASS
- `make -C Linux/tools smoke-jal-link smoke-virtio-blk`: GOOD TRAP
  - `smoke-jal-link`: cycles=41, commits=16
  - `smoke-virtio-blk`: cycles=18293, commits=7844
- `git diff --check`: PASS

## 边界

- 本轮是 helper/lint 风格清理，不是 PLIC 功能扩展。
- `AxiLitePlic` 仍是当前 RV64 平台的 PLIC-like 单 hart简化模型；完整 Linux 设备栈仍需按多 source、gateway、UART RX/TTY、virtio IRQ 压力等后续 gate 单独推进。
- 本轮未改变 DATA_W/STRB_W 参数约束，也未重构 priority array 或 source arbitration。
