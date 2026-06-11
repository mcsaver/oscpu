# NEMU Ubuntu systemd soak gate

## 目标

- 为完整 Ubuntu 22.04.5 推进新增一档比 `check-nemu-systemd-guest-long` 更重的自动化稳定性 gate。
- 重点覆盖长期运行稳定性、timer/interrupt 单调性、TTY/console、systemd running、syscall probe、rootfs 写回和并发 direct IO。

## Makefile 入口

- 新增 `make -C Linux check-nemu-systemd-guest-soak`。
- 默认参数：
  - `NEMU_SYSTEMD_CHECK_LOG_DIR=$(LOG_ROOT)/riscv64-nemu-systemd-guest-soak-check`
  - `NEMU_SYSTEMD_CHECK_MAX_CYCLES=60000000000`
  - `NEMU_SYSTEMD_CHECK_TIMEOUT=2400`
  - `NEMU_SYSTEMD_SOAK_SECONDS=300`
  - `NEMU_SYSTEMD_FS_STRESS_MIB=32`
  - `NEMU_SYSTEMD_PROCESS_LOOPS=128`
  - `NEMU_SYSTEMD_BLOCK_PARALLEL_JOBS=4`
  - `NEMU_SYSTEMD_BLOCK_JOB_MIB=4`

## 验证

- `bash -n Linux/scripts/check-nemu-systemd-guest.sh`：PASS。
- `make -C Linux -n check-nemu-systemd-guest-soak`：PASS，dry-run 展开为 60B 指令预算、300s soak、32MiB rootfs stress、128 轮进程循环和 4 个 4MiB 并发 direct IO job。
- `make -C Linux check-nemu-systemd-guest-soak`：PASS。

`perf.tsv`：

```text
boot_seconds	guest_check_seconds	total_seconds	soak_seconds	fs_stress_mib	process_loops	block_parallel_jobs	block_job_mib	max_cycles
232	310	542	300	32	128	4	4	60000000000
```

关键 console marker：

- `__NEMU_CHECK_PASS__:systemd-running`
- `__NEMU_CHECK_PASS__:ttyS0-stty`
- `__NEMU_CHECK_PASS__:ttyS0-write`
- `__NEMU_CHECK_PASS__:console-write`
- `__NEMU_CHECK_PASS__:fifo-ipc`
- `__NEMU_CHECK_PASS__:fork-wait-loop`
- `__NEMU_SYSCALL_PROBE_PASS__:ppoll-pipe`
- `__NEMU_SYSCALL_PROBE_PASS__:pselect-pipe`
- `__NEMU_SYSCALL_PROBE_PASS__:setitimer-sigalrm`
- `__NEMU_SYSCALL_PROBE_PASS__:pty-controlling-tty`
- `__NEMU_SYSCALL_PROBE_PASS__:pty-foreground-pgrp`
- `__NEMU_SYSCALL_PROBE_PASS__:pty-sigwinch`
- `__NEMU_SYSCALL_PROBE_PASS__:pidfd-open`
- `__NEMU_SYSCALL_PROBE_PASS__:pidfd-send-signal`
- `__NEMU_SYSCALL_PROBE_PASS__:pidfd-poll-exit`
- `__NEMU_SYSCALL_PROBE_PASS__:waitid-pidfd`
- `__NEMU_SYSCALL_PROBE_PASS__:prctl-name`
- `__NEMU_SYSCALL_PROBE_PASS__:getrandom`
- `__NEMU_CHECK_PASS__:syscall-probe`
- `__NEMU_CHECK_BLOCK_PARALLEL_BYTES__:16777216/16777216`
- `__NEMU_CHECK_FS_STRESS_BYTES__:33554432/33554432`
- `__NEMU_CHECK_PASS__:rootfs-stress-copy-cmp`
- `__NEMU_CHECK_SOAK_UPTIME__:563->1057`
- `__NEMU_CHECK_INTERRUPTS__:145570->269759`
- `__NEMU_CHECK_PASS__:soak-uptime`
- `__NEMU_CHECK_PASS__:interrupts-stat-monotonic`
- `__NEMU_CHECK_PASS__:dmesg-no-critical`
- `__NEMU_SYSTEMD_CHECK_DONE__ rc=0`

## 边界

- 这条 gate 把 20s 默认 gate 和 120s long gate 往 300s 稳态推进，能作为后续设备模型、timer/interrupt 或 rootfs 路径改动后的重型回归。
- 它仍不是多小时 soak、virtio malformed descriptor fuzz、多队列设备模型或 QEMU 等价完整虚拟机声明。
