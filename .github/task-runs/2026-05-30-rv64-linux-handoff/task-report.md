# RV64 Linux Handoff Mini Boot

## 目标

继续推进真实 Linux/OpenSBI 启动前置能力，补齐 RISC-V Linux boot protocol 最核心的入口约定：firmware 进入 S-mode payload 时必须保留 `a0=hartid` 与 `a1=DTB physical address`，payload 能通过该指针读取 FDT header，且之后的 SBI 调用确实来自 S-mode。

## 改动

- `am-kernels/tests/cpu-tests/tests/linux-handoff.c`
  - M-mode firmware 设置 `mtvec`，将 `mstatus.MPP=S` 与 `mepc=s_linux_payload` 写好后 `mret`。
  - `mret` 前通过入口寄存器传入 `a0=BOOT_HARTID` 与 `a1=fake_dtb_paddr`。
  - S-mode payload 验证 `hartid`、DTB 地址、FDT big-endian `magic/totalsize/version/boot_cpuid_phys`。
  - payload 发测试 SBI `ecall` 回 M-mode。
  - M-mode trap handler 记录 `mcause/a0/a1/a7`，payload 验证 `mcause=EXC_ECALL_SMODE` 与 handoff 参数未变。

## 验证

- `make -C am-kernels/tests/cpu-tests AM_HOME=/home/lyg/PA/ysyx-workbench/abstract-machine ARCH=riscv64-npc NPC_SIM_BACKEND=rv64 ALL=linux-handoff run NPC_RUN_ARGS="--no-progress --max-cycles 5000000"`
  - PASS
  - `cycles=529 / commits=143 / CPI=3.699`
- `make -C am-kernels/tests/cpu-tests AM_HOME=/home/lyg/PA/ysyx-workbench/abstract-machine ARCH=riscv64-npc NPC_SIM_BACKEND=rv64 ALL="linux-handoff sbi-base-console counteren-time sbi-timer" run NPC_RUN_ARGS="--no-progress --max-cycles 5000000"`
  - PASS 4/4

## 限制

本轮是 AM 内 mini payload，不是完整 Linux 或 OpenSBI。它证明 a0/a1/DTB handoff、S-mode payload 与 SBI ecall 边界闭合；真实启动仍需要实际 OpenSBI/kernel/DTB 镜像、多源 PLIC、virtio/blk、IPI/reset/HSM 与更完整设备树。
