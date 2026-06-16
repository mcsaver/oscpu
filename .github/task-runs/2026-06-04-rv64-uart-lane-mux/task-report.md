# RV64 UART Lane Mux PPA Cleanup

## Summary

本轮把 `npc/rv64/vsrc/bus/Uart.v` 的 16550 subset 寄存器窗口从 procedural byte-lane loop 改为固定 lane mux / next-value 结构，并给 `tb_uart` 增加 64-bit 实例覆盖当前 `NpcTop` 使用的 `DATA_W=64/STRB_W=8`。

## RTL 推导摘要

### 需求

- 保持 UART 当前可见行为：
  - `THR` lane0 写且 `DLAB=0` 时输出 `tx_valid/tx_data`。
  - `IER[3:0]`、`IIR` THRE pending、`FCR` FIFO enable/trigger、`LCR` DLAB、`DLL/DLM` divisor、compat status 与 LSR read value 语义不变。
  - 支持 32-bit testbench 和 RV64 `NpcTop` 64-bit AXI beat。
- 去掉 `read_lane_i/write_lane_i` procedural loop，让 byte lane 与寄存器副作用关系显式。
- 不实现 RX FIFO、真实 baud/FIFO timing、完整 16550、TTY 输入或新中断源。

### 协议规则

- `Uart` 是 native register IP；AXI valid/ready 仍由 `AxiLiteToUart` 负责。
- `reg_read_valid_i` 只产生 access pulse；read data 是组合窗口，不新增状态。
- `reg_write_valid_i` 当拍根据 `reg_write_addr_i + lane` 与 `reg_write_strb_i[lane]` 生成 next-value，时钟沿更新寄存器。
- DLAB 判定使用旧 `lcr_q[7]`，同一 beat 写 LCR 不影响其它 lane 的 DLL/DLM/THR 解码。
- `tx_valid_o` 仍只由 `addr==0 && strb[0] && !DLAB` 触发。

### 状态机

- 无新增状态机。
- 仅保留五个 UART 寄存器：
  - `ier_q`
  - `dll_q`
  - `dlm_q`
  - `fcr_q`
  - `lcr_q`
- reset 后：`IER=0`、`DLL=1`、`DLM=0`、`FCR=0`、`LCR=0`。

### 不变量

- 未实现 offset 读 0，写无副作用。
- `IER` 写入只保留低 4 bit。
- `FCR` 写入只保留 `8'hc1`。
- `DLAB=0` 时 offset 0 为 THR/RBR，offset 1 为 IER；`DLAB=1` 时 offset 0/1 为 DLL/DLM。
- `uart_read_byte()` 不隐式引用函数外部寄存器；所有动态依赖必须作为函数入参，避免仿真敏感性和审查隐藏依赖。

### 数据通路约束

- 低 4 lane 和高 4 lane 分别用常量范围 padding 到 64-bit。
- read path：固定展开 `reg_read_addr_i + 0..7`，每个 lane 调 `uart_read_byte()`。
- write path：固定展开 8 个 lane case，更新五个 next-value。
- sequential path：只用 nonblocking assignment 落库，不在时序块内做 procedural lane loop。

## Changed Files

- `npc/rv64/vsrc/bus/Uart.v`
- `npc/rv64/testbench/tests/tb_uart.sv`

## Verification

- `make -C npc/rv64/testbench TESTS="tb_uart tb_axi_lite_to_uart" run`
  - PASS，结果目录：`npc/rv64/perf/results/20260604-112644/module-testbench`
- `rg -n "for \(|read_lane|write_lane|integer .*lane" npc/rv64/vsrc/bus/Uart.v`
  - 无命中。
- `make -C npc/rv64 lint`
  - PASS。
- `make -C npc/rv64 -j2`
  - PASS。
- `make -C Linux/tools smoke-opensbi`
  - PASS，OpenSBI v1.8 banner 与 `S` marker 可见，GOOD TRAP。
  - `cycles=4847043`，`commits=4626235`。
- `git diff --check -- npc/rv64/vsrc/bus/Uart.v npc/rv64/testbench/tests/tb_uart.sv`
  - PASS。

## Boundary

- 本轮只收敛 UART byte-lane RTL 描述，不声明完整 UART/TTY/RX 或 Linux 平台设备栈完成。
- `make -C Linux ARCH=riscv64-npc smoke-opensbi` 当前在 OpenSBI 重建阶段因 generic platform MIPS/Andes undefined reference 失败，未进入 NPC；本轮用 `Linux/tools smoke-opensbi` 作为 UART 输出端到端证据。
