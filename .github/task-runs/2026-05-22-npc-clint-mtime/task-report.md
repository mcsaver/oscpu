# Task Report: NPC CLINT mtime

## 结果
- 已为 core 留出 `irq_software_i/irq_timer_i/irq_external_i` 标准端口。
- 已新增 CLINT AXI-Lite slave，并接入 `NpcSimTop` 地址窗口 `0x0200_0000..0x0200_ffff`。
- 已实现 `mtime` 64-bit 状态、每拍递增、RV32 低/高 32 位 MMIO 读写和 WSTRB 部分写。
- 已把硬件 IRQ pending 合成到 `CSR_MIP` 读值。

## 主要改动
- `npc/single/vsrc/include/define.v`：新增 CLINT base/mask 与 interrupt 相关宏。
- `npc/single/vsrc/bus/AxiLiteClint.v`：新增 CLINT-like AXI-Lite 设备。
- `npc/single/vsrc/sim/NpcSimTop.sv`：crossbar 增加 CLINT slave，连接 CLINT IRQ 到 core。
- `npc/single/vsrc/core/NpcCore.v`、`npc/single/vsrc/core/CsrFile.v`：新增标准 IRQ 输入端口，并在 `mip` 读路径合成硬件 pending。
- `npc/single/vsrc/filelist.mk`、`npc/single/testbench/Makefile`：接入新增 RTL 和测试。
- `npc/single/testbench/tests/tb_axi_lite_clint.sv`：新增 CLINT `mtime` 单测；core smoke/mcycle 测试补齐 IRQ 端口连接。

## 当前边界
- `msip`、`mtimecmp`、`MTIP/MSIP` 真实触发还未实现。
- core 只暴露 IRQ 端口并让 `mip` 可见 pending，本轮没有实现中断优先级、进入 trap、`mcause` interrupt bit 或 `mret` 后恢复中断等完整行为。
- 本地 cpu-tests 回归显示 `Difftest: OFF`，后续做 timer interrupt 时需要单独设计参考模型对齐策略。

## 验证证据
- `make -C npc/single/testbench RESULT_DIR=/tmp/npc-clint-tests run`：25/25 PASS。
- `make -C npc/single lint`：PASS。
- `make -C npc/single -j14`：PASS。
- `make -C npc/single/testbench PIPE_RESULT_DIR=/tmp/npc-clint-pipe pipe_test`：PASS。
- `AM_HOME=/home/lyg/PA/ysyx-workbench/abstract-machine make -C am-kernels/tests/cpu-tests ARCH=riscv32-npc run`：38/38 PASS，当前二进制显示 `Difftest: OFF`。
- `git diff --check`：PASS。
