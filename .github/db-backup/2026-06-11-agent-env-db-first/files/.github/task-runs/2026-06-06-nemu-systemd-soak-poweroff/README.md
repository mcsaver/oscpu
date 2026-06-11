# NEMU systemd 300s soak + poweroff

## 目标
- 用重型 gate 复验完整 Ubuntu 22.04.5 systemd 在 NEMU 上的长期稳定性、块设备压力、timer/interrupt 单调性和自然关机链路。
- 覆盖默认 gate 之外的 300s soak、32MiB rootfs stress、128 轮进程循环、4 个 4MiB 并发 direct IO job。

## 命令
- 后台启动脚本：`bash .github/task-runs/2026-06-06-nemu-systemd-soak-poweroff/run-soak.sh`
- 实际内部命令：`timeout 2600s make -C Linux check-nemu-systemd-guest-soak`
- 状态文件：`run.status` 为 `0`。

## 结果
- `check-ubuntu-rootfs-systemd`：PASS，rootfs 包含 systemd、udevd、dbus、agetty/login、PAM、lp64d linker 和 e2scrub 入口。
- `check-nemu-performance-config`：PASS，输出 `__NEMU_PERFORMANCE_CONFIG__:ok`。
- NEMU 使用 `npc-rv64-nemu-rootfs.dtb`，OpenSBI banner 显示 `Platform Reboot Device : syscon-reboot` 与 `Platform Shutdown Device : syscon-poweroff`。
- `Linux/env/logs/linux-front/riscv64-nemu-systemd-guest-soak-check/perf.tsv`：
  `boot_seconds=234`、`guest_check_seconds=390`、`poweroff_seconds=19`、`total_seconds=643`、`soak_seconds=300`、`fs_stress_mib=32`、`process_loops=128`、`block_parallel_jobs=4`、`block_job_mib=4`、`max_cycles=60000000000`。

## 关键证据
- systemd/TTY：`systemd-running` PASS，`serial-getty-ttyS0-active` PASS。
- systemd transient：`__NEMU_CHECK_SYSTEMD_TRANSIENT_RESULT__:success`。
- syscall probe：`__NEMU_SYSCALL_PROBE_DONE__ rc=0`。
- 并发 direct IO：`__NEMU_CHECK_BLOCK_PARALLEL_BYTES__:16777216/16777216`。
- rootfs stress：`__NEMU_CHECK_FS_STRESS_BYTES__:33554432/33554432`。
- soak/timer/interrupt：`__NEMU_CHECK_SOAK_UPTIME__:660->1156`，`__NEMU_CHECK_INTERRUPTS__:170813->295430`。
- dmesg critical：`__NEMU_CHECK_PASS__:dmesg-no-critical`。
- guest 检查完成：`__NEMU_SYSTEMD_CHECK_DONE__ rc=0`。
- 自然关机：`__NEMU_SYSTEMD_POWEROFF_BEGIN__`，systemd 到 `System Power Off`，Linux 打印 `reboot: Power down`，NEMU 打印 `syscon-reset: poweroff requested value=0x00005555` 和 `HIT GOOD TRAP`。

## 边界
- 这次把“长期运行稳定性”从默认 20s gate 推进到 300s soak，并证明自然 poweroff 在重压后仍可用。
- 仍不声明 QEMU 级完整虚拟机：virtio malformed descriptor、多队列、多设备错误路径、更长多小时 session 和复杂交互 TTY 还需要继续补 gate。
