# Dispatch Log: NPC CLINT mtime

## 任务
- 用户要求先保留标准化中断端口，并先实现 CLINT 中的 `mtime`。
- 范围限定在 NPC single RTL、仿真顶层、模块测试和项目记忆记录。

## 上下文
- 按仓库规则先阅读 `.github/AGENTS.md`、`.github/copilot-instructions.md`、project/module memory、known issues、NPC study notes 与 RTL generation workflow。
- 当前 RTL 已按 `vsrc/filelist.mk` 分目录维护，新增 RTL 需要接入统一 filelist。
- 现有 CSR 已由 `CsrFile` 管理，适合在 CSR 边界挂硬件 pending 输入。

## RTL 推导
- 需求：新增标准 CLINT-like AXI-Lite slave，地址窗口为 `0x0200_0000..0x0200_ffff`；第一阶段只保证 64-bit `mtime` 递增，并能通过 RV32 低/高 32 位 MMIO 读写。`NpcCore` 暴露 software/timer/external interrupt 输入端口，但本轮不做异步中断仲裁和 trap。
- 协议：沿用现有 single-beat AXI-Lite。AR fire 后锁存读数据并保持 `RVALID` 到 `RREADY`；AW/W 允许乱序到达，分别锁存，到齐后执行一次写 side effect，并保持 `BVALID` 到 `BREADY`。
- 状态：`s_axi_rvalid_o/s_axi_bvalid_o/aw_seen_q/w_seen_q` 加锁存的 AW 地址、W 数据、WSTRB；`mtime_q` 是唯一计时状态。
- 不变量：`RVALID/BVALID` 未 ready 前 payload 不变；一次 AW/W 组合只触发一次写；`mtime_q` 单驱动；未实现的 `msip/mtimecmp` 不产生中断，IRQ 输出固定 0。
- 数据通路：`mtime_q` 默认每拍加 `MTIME_INCREMENT`；读 offset `0xbff8/0xbffc` 返回低/高 32 位；写同 offset 时用 `WSTRB` 按字节更新对应半字。

## 实施
- `define.v` 增加 CLINT AXI base/mask，以及 machine interrupt cause、`mip/mie` bit 宏。
- 新增 `AxiLiteClint`，实现 AXI-Lite slave、`mtime` 分半读写、byte strobe 和递增。
- `NpcSimTop` 的 AXI slave 从 4 路扩为 5 路，加入 CLINT 表项和实例，CLINT IRQ 线接入 core。
- `NpcCore/CsrFile` 增加 `irq_software_i/irq_timer_i/irq_external_i`，`CSR_MIP` 读值合成硬件 pending。
- 更新 core smoke/mcycle 测试实例端口，新增 `tb_axi_lite_clint` 覆盖 `mtime` 读写和递增。

## 验证
- `make -C npc/single/testbench RESULT_DIR=/tmp/npc-clint-tests run`：25/25 PASS。
- `make -C npc/single lint`：PASS。
- `make -C npc/single -j14`：PASS，生成 `build/NpcSimTop`。
- `make -C npc/single/testbench PIPE_RESULT_DIR=/tmp/npc-clint-pipe pipe_test`：PASS。
- `AM_HOME=/home/lyg/PA/ysyx-workbench/abstract-machine make -C am-kernels/tests/cpu-tests ARCH=riscv32-npc run`：38/38 PASS；本地显示 `Difftest: OFF`。
- `git diff --check`：PASS。

## 后续
- 实现 `msip` 和 `mtimecmp` 寄存器，生成 `MTIP/MSIP`。
- 在 `CsrFile` 或独立 trap controller 中实现 `mstatus.MIE & mie & mip` 仲裁、优先级和 interrupt trap side effect。
- 补充 interrupt/trap difftest 策略，避免 reference 与 DUT 的外设时间源不同步。
