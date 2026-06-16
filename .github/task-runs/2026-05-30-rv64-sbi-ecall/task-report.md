# RV64 SBI Ecall And S External IRQ Coverage

## 目标

- 在既有 RV64 OoO Linux 前置路径上补齐真实 Linux/OpenSBI 早期常见的 SBI trap 与 supervisor external interrupt 控制边界。
- 覆盖 S-mode `ecall` 不被 `medeleg` 委托时进入 M-mode firmware handler，再由 `mret` 返回 S-mode 继续执行。
- 覆盖 S-mode 打开 `sie.SEIE/sstatus.SIE` 后，外部中断进入 S handler，再由 `sret` 返回 S-mode。

## 现状与缺口

- 已有 `tb_ooo_priv_system` 覆盖 M-mode trap、timer interrupt、S-mode delegated ecall 和 `SRET`。
- 已有 `tb_ooo_sv39_boot` 覆盖 M-mode handoff、Sv39 success path、load/inst page fault delegation。
- 缺口一是 SBI 风格 S-mode `ecall`：真实 Linux 在 S-mode 发起 SBI 调用时应 trap 到 M-mode firmware，而不是进入 S-mode OS handler。
- 缺口二是 supervisor external interrupt：完整 PLIC 尚未实现，但 core 侧 `SEIP -> stvec -> sret` 控制流需要先有 focused 覆盖。

## SBI Ecall 测试设计

- 新增 `MODE_SBI_ECALL` 到 `tb_ooo_priv_system`。
- M-mode firmware:
  - 设置 `mtvec=HANDLER_PC`。
  - 写 `medeleg=0`，显式不委托 S-mode ecall。
  - 设置 `mepc=S_ENTRY_PC` 与 `mstatus.MPP=S`。
  - `mret` 进入 S-mode。
- S-mode payload:
  - 执行普通 ALU 指令，证明 handoff 后 S-mode 代码已运行。
  - 执行 `ecall`。
  - 等 M handler 写回 `mepc+4` 并 `mret` 后继续执行到 `ebreak`。
- M-mode SBI handler:
  - 读取 `mcause/mepc/mstatus`。
  - 保存原始 `mepc`，再将 `mepc += 4` 写回。
  - 执行 marker ALU 指令并 `mret`。

## 验证点

- `exit_valid=1` 且通过 `ebreak` 退出。
- `exit_is_ecall=0`，说明 S-mode ecall 是架构 trap，不是仿真壳退出。
- 观察到 M-mode handler fetch，且未进入 S-mode handler。
- `mcause=EXC_ECALL_SMODE`。
- 原始 `mepc=S_ENTRY_PC+4`，写回返回点 `S_ENTRY_PC+8`。
- `mstatus.MPP=S`，证明 trap 记录了来自 S-mode。
- handler marker、S-mode ecall 前后 marker 均写入预期寄存器。

## S External IRQ 测试设计

- 新增 `MODE_S_EXT_IRQ` 到 `tb_ooo_priv_system`。
- M-mode firmware:
  - 设置 `stvec=S_HANDLER_PC`。
  - 设置 `mideleg` 外部中断委托位。
  - 设置 `mepc=S_ENTRY_PC` 与 `mstatus.MPP=S`。
  - `mret` 进入 S-mode。
- S-mode payload:
  - 写 `sie.SEIE`。
  - 写 `sstatus.SIE`。
  - 执行 `wfi`，等待外部中断。
  - `sret` 返回后继续执行到 `ebreak`。
- S-mode handler:
  - 读取 `scause/sepc/sstatus`。
  - 执行 marker ALU 指令并 `sret`。

## S External IRQ 验证点

- `exit_valid=1` 且通过 `ebreak` 退出。
- 观察到 S-mode handler fetch，且未进入 M-mode handler。
- `scause=MCAUSE_INTERRUPT|IRQ_CAUSE_SEI`。
- `sepc=S_ENTRY_PC+0x10`，即被中断的 `wfi`。
- `sstatus.SPP=S`，证明 trap 记录了来自 S-mode。
- handler marker、S-mode fallthrough marker 均写入预期寄存器。

## 验证结果

- PASS: `make -C npc/rv64/testbench TESTS="tb_ooo_priv_system" RESULT_DIR=/tmp/rv64-priv-sbi run`
- PASS: `make -C npc/rv64/testbench TESTS="tb_ooo_priv_system" RESULT_DIR=/tmp/rv64-priv-sirq run`
- PASS: `make -C npc/rv64/testbench TESTS="tb_ooo_priv_system tb_ooo_sv39_boot tb_ooo_mem_axi_bridge tb_ooo_int_backend" RESULT_DIR=/tmp/rv64-linux-sbi-focused run`
- PASS: `make -C npc/rv64/testbench TESTS="tb_ooo_priv_system tb_ooo_sv39_boot tb_ooo_mem_axi_bridge tb_ooo_int_backend" RESULT_DIR=/tmp/rv64-linux-sbi-sirq-focused run`

## 剩余风险

- 本轮只新增 focused mini boot 覆盖，没有实现完整 SBI 服务表或 PLIC 设备。
- 真实 Linux boot 仍需要 PLIC/virtio/DTB/真实 kernel 镜像加载，以及更完整的 timer/IPI/console SBI 语义。
