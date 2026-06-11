# NEMU UART Opaque Rearch

## 背景

用户要求 UART 不能继续在旧 mini UART 基础上局部补丁，而要自行重新架构设计。此前 NEMU 已有公共 16550A core、bus profile、`SerialPort` 前端、SoC adapter 和 PLIC glue；本轮继续收紧为 opaque 设备对象，防止外部模块依赖 UART 内部寄存器/FIFO 布局。

## 改动

- `nemu/include/device/uart16550.h` 只暴露 `Uart16550` 不透明类型、`Uart16550Config`、ops、bus profile 与读写/service/receive API。
- `nemu/src/device/uart16550.c` 私有维护寄存器、RX FIFO、1MiB ingress staging、THRI/RDI/CTI/MSI/RLSI level IRQ 等 16550A 语义。
- `nemu/src/device/serial.c` 的 `SerialPort` 改为持有 `Uart16550 *`，只负责 IOMap、host FIFO/stdin、TX 输出与 PLIC IRQ1 接线。
- `nemu/src/memory/soc.c` 的 ysyxSoC UART adapter 也改为动态创建同一 opaque core，不再静态嵌入 UART 内部状态。
- `nemu/tools/uart16550-smoke.c` 迁移到 create/destroy API。

## 验证

- `cc -std=c11 -Wall -Wextra -I nemu/include nemu/tools/uart16550-smoke.c nemu/src/device/uart16550.c -o /tmp/uart16550-smoke && /tmp/uart16550-smoke`: PASS
- `NEMU_HOME=/home/lyg/PA/ysyx-workbench/nemu make -C nemu -j$(nproc)`: PASS
- `bash -n Linux/scripts/check-nemu-systemd-guest.sh`: PASS
- `git diff --check -- nemu/include/device/uart16550.h nemu/src/device/uart16550.c nemu/src/device/serial.c nemu/src/memory/soc.c nemu/tools/uart16550-smoke.c`: PASS
- Focused Ubuntu gate `riscv64-nemu-uart-opaque-rearch`: PASS

## Gate 参数与结果

命令由 `run-gate.sh` 启动，关键参数：

- `NEMU_SYSTEMD_CHECK_MAX_CYCLES=25000000000`
- `NEMU_SYSTEMD_CHECK_TIMEOUT=1900`
- `NEMU_SYSTEMD_RELOAD_TIMEOUT=60`
- `NEMU_SYSTEMD_SOAK_SECONDS=0`
- `NEMU_SYSTEMD_UART_RX_STRESS_LINES=96`
- `NEMU_SYSTEMD_FS_TREE_FILES=8`
- `NEMU_SYSTEMD_BLOCK_PARALLEL_JOBS=1`
- `NEMU_SYSTEMD_BLOCK_JOB_MIB=1`
- `NEMU_SYSTEMD_SYSCALL_PROBE=0`

`perf.tsv`:

```text
boot_seconds	guest_check_seconds	poweroff_seconds	total_seconds	soak_seconds	fs_stress_mib	fs_tree_files	process_loops	uart_rx_stress_lines	block_parallel_jobs	block_job_mib	max_cycles
243	530	21	794	0	1	8	2	96	1	1	25000000000
```

关键 marker：

- `__NEMU_UART_RX_STRESS_COUNT__:96/96`
- `__NEMU_CHECK_PASS__:uart-rx-command-burst`
- `__NEMU_CHECK_PASS__:systemd-runtime-daemon-reload`
- `__NEMU_CHECK_PASS__:systemd-runtime-unit-cleanup`
- `__NEMU_SYSTEMD_CHECK_DONE__ rc=0`
- `__NEMU_SYSTEMD_POWEROFF_BEGIN__`
- `syscon-reset: poweroff requested value=0x00005555`
- `HIT GOOD TRAP`

失败扫描未发现真实 `__NEMU_CHECK_FAIL__` marker；console 中的 `fail()` 函数定义回显不是失败。

## 边界

本轮证明 NEMU UART 内部状态已封装，且完整 Ubuntu/systemd/ttyS0 默认路径、host->UART RX 命令突发、runtime unit 和自然 poweroff 未被破坏。它不声明周期精确 baud、flow-control、break、多 UART、错误注入或 QEMU 级完整串口设备。
