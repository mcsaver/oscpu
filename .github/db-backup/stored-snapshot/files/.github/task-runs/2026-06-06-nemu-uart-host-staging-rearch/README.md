# NEMU UART host staging 重新分层

## 背景

用户明确要求 UART 不要继续沿着旧 mini 串口补丁化设计，而是自行重新架构。此前 `uart16550` 已经是 opaque core，但为了吃下 host 一次性写入的 guest-check 脚本，core 内仍保留了 1MiB ingress staging；这会让“仿真前端输入缓存”和“真实 16550A 硬件 FIFO”混在同一个设备对象里。

## 本轮设计

- `uart16550` core 只维护真实 16550A 寄存器、guest-visible RX FIFO、LSR/IIR/IER/FCR/LCR/MCR/MSR 语义和 level IRQ。
- 1MiB host 脚本输入缓存迁移到 `SerialPort` 前端，命名为 host RX staging；前端通过 `uart16550_rx_room()` 按硬件 FIFO 空间分批把字节送到 core。
- `uart16550_receive()` 改为返回实际接收字节数；如果外部绕过前端一次送超过硬件 FIFO 的字节，core 会按硬件 overrun 语义置 `LSR.OE`，不会继续伪装成大 FIFO。
- `uart16550-smoke` 同步改为验证硬件 FIFO room、overrun 置位、分批接收、loopback、DLAB、THRI/RDI/CTI 和 8-bit/32-bit bus profile。

## 验证

- `cc -std=c11 -Wall -Wextra -Werror -I nemu/include nemu/tools/uart16550-smoke.c nemu/src/device/uart16550.c -o /tmp/uart16550-smoke && /tmp/uart16550-smoke`: PASS。
- `NEMU_HOME=/home/lyg/PA/ysyx-workbench/nemu make -C nemu -j$(nproc)`: PASS。
- `bash -n Linux/scripts/check-nemu-systemd-guest.sh`: PASS。
- `git diff --check -- nemu/include/device/uart16550.h nemu/src/device/uart16550.c nemu/src/device/serial.c nemu/tools/uart16550-smoke.c Linux/scripts/check-nemu-systemd-guest.sh`: PASS。
- Focused gate `run-gate.sh`: PASS，`run.status=0`。

## Focused Gate

命令见 `run-gate.sh`。参数为完整 Ubuntu rootfs + systemd，关闭 syscall probe，0s soak，1MiB rootfs stress，8 个元数据文件，2 轮 process loop，128 行 UART RX burst，1 个 1MiB 并发 direct IO job，25B max cycles。

`Linux/env/logs/linux-front/riscv64-nemu-uart-host-staging-rearch/perf.tsv`:

```text
boot_seconds	guest_check_seconds	poweroff_seconds	total_seconds	soak_seconds	fs_stress_mib	fs_tree_files	process_loops	uart_rx_stress_lines	block_parallel_jobs	block_job_mib	max_cycles
237	964	20	1221	0	1	8	2	128	1	1	25000000000
```

关键 marker:

- `__NEMU_UART_RX_STRESS_COUNT__:128/128`
- `__NEMU_CHECK_PASS__:uart-rx-command-burst`
- `__NEMU_CHECK_PASS__:systemd-runtime-daemon-reload`
- `__NEMU_CHECK_PASS__:systemd-runtime-unit-cleanup`
- `__NEMU_CHECK_PASS__:ttyS0-write`
- `__NEMU_CHECK_PASS__:vda-serial-get-id`
- `__NEMU_SYSTEMD_CHECK_DONE__ rc=0`
- `__NEMU_SYSTEMD_POWEROFF_BEGIN__`
- `reboot: Power down`
- `HIT GOOD TRAP`

说明：本轮 `guest_check_seconds=964s` 主要来自既有 runtime unit reload 慢路径；UART RX burst 在前半段已经 PASS，没有出现旧的脚本函数/变量被串口输入丢失问题。

## 边界

这次证明的是 UART 架构职责重新分层后，NEMU 完整 Ubuntu/systemd/ttyS0 默认路径、128 行 host-to-UART 命令突发和自然 poweroff 仍然成立。它不声明周期精确 baud、完整 flow-control/break、多 UART、错误注入或 QEMU 级完整串口设备。
