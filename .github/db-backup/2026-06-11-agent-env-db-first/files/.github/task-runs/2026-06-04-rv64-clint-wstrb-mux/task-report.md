# 2026-06-04 RV64 CLINT wstrb mux 任务报告

## 任务目标

继续按商业 ASIC 级 RTL 写法推进仿真顶层实例化模块。本轮目标是 `NpcTop` 中的 `AxiLiteClint`：保留现有 CLINT-like MMIO 行为，同时把 byte strobe 写合并从功能仿真式 procedural loop 收敛为显式 byte mux 网络。

## RTL 推导摘要

### 需求

- 保持 `msip/mtimecmp/mtime` 的当前读写语义。
- 保持 `msip_irq_o = msip_q`、`mtip_irq_o = (mtime_q >= mtimecmp_q)` 和 `mtime_o` 输出。
- 支持当前使用的 `DATA_W=32/STRB_W=4` testbench 场景和 `DATA_W=64/STRB_W=8` 顶层场景。
- 本轮只处理 byte strobe merge 写法，不新增多 hart CLINT、完整 ACLINT 地址图、错误响应或 timer frequency 建模。

### 协议规则

- 模块仍是单 outstanding AXI-Lite slave。
- `ARVALID && ARREADY` 后锁出一次 `RVALID/RDATA`，`RVALID` 保持到 `RREADY`。
- AW/W 可以同拍或分拍任意顺序到达；二者到齐后 `write_done_w` 产生一次寄存器副作用和一次 `BVALID`。
- `RRESP/BRESP` 固定 OKAY。
- `mtime_q` 默认每拍加 `MTIME_INCREMENT`；写 `mtime` 的事务在同一 always 块后部覆盖当拍自增，沿用旧行为。

### 状态机

- 无新增显式状态机。
- 隐式读状态由 `s_axi_rvalid_o` 表示：idle -> rvalid -> idle。
- 隐式写状态由 `aw_seen_q/w_seen_q/s_axi_bvalid_o` 表示：idle 可接 AW/W；单通道先到则保持 seen；两通道到齐后进入 bvalid；B ready 后回 idle。
- reset 清空 outstanding，`msip=0`、`mtime=0`、`mtimecmp=64'hffff_ffff_ffff_ffff`。

### 不变量

- 每个写事务最多产生一次寄存器副作用。
- `MSIP` 只在 `WSTRB[0]` 有效时用写数据 bit0 更新。
- `MTIMECMP_LO/MTIME_LO` 使用 aligned byte merge；64-bit beat 可更新完整 64 位，32-bit beat 的高 lane 固定无效。
- `MTIMECMP_HI/MTIME_HI` 只用写数据低 4 byte 更新目标寄存器高 32 位，写数据高 4 byte 被忽略。
- 未实现 offset 读 0，写无副作用。

### 数据通路约束

- `write_data_w/write_strb_w` 先 padding 到 `write_data_pad_w[63:0]` 和 `write_strb_pad_w[7:0]`。
- `apply_wstrb64_aligned()` 展开为 8 个固定 byte-enable mux。
- `apply_wstrb64_high_word()` 展开为 4 个 high-word byte-enable mux。
- 函数内不再使用 `integer` 或 procedural `for`，每个 byte lane 的 old/new 选择在 RTL 中可直接审查。

## 改动清单

- `npc/rv64/vsrc/bus/AxiLiteClint.v`
  - 删除函数内 byte-lane loop。
  - 新增固定 64-bit padding 和显式 byte mux merge。
  - 明确 `*_HI` 只消费低 4 lane。
- `npc/rv64/testbench/tests/tb_axi_lite_clint.sv`
  - 新增 AW/W 分拍写任务。
  - 新增 64-bit high-word offset 写入与高 lane 忽略覆盖。

## 验证证据

- `rg -n "for\\s*\\(|integer\\s+\\w+" npc/rv64/vsrc/bus/AxiLiteClint.v` 无输出。
- `make -C npc/rv64/testbench TESTS="tb_axi_lite_clint" run` PASS，结果目录 `npc/rv64/perf/results/20260604-113945/module-testbench`。
- `make -C npc/rv64/testbench TESTS="tb_axi_lite_clint tb_ooo_priv_system" run` PASS，结果目录 `npc/rv64/perf/results/20260604-114005/module-testbench`。
- `make -C npc/rv64 lint` PASS。
- `make -C npc/rv64 -j2` PASS。
- `make -C Linux/tools smoke-opensbi` PASS：OpenSBI v1.8 banner 与 `S` marker 可见，GOOD TRAP，`cycles=4847043/commits=4626235/CPI=1.048`，`CLINT mtime = 4847043 (mtime-cycles=+0, match=yes)`。

## 边界

- 该任务只声明 CLINT byte strobe mux RTL 风格收敛。
- 不声明完整 ACLINT/CLINT 多 hart 设备、Linux tick 长测、多源 PLIC/TTY、virtio/rootfs 或最终综合/STA/PPA signoff 完成。
