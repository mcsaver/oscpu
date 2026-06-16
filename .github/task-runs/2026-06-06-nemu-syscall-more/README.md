# NEMU Ubuntu syscall probe 扩展二次更新

## 目标
- 继续推进完整 Ubuntu 22.04.5 的“更多系统调用稳定性”证据。
- 在既有 mmap/mremap/mprotect、epoll/timerfd、pidfd、PTY、SCM_RIGHTS、sendfile/splice 等覆盖之外，补入 systemd/udev/dbus/ld.so 常见但 shell 难以直接验证的 VM hint、page residency、目录枚举、权限检查、record lock 和 fd/pipe 复制路径。

## 实现
- `Linux/tools/nemu-systemd-syscall-probe.c` 新增：
  - `madvise-willneed`
  - `mincore-resident`
  - `fcntl-record-lock`
  - `faccessat2-eaccess`
  - `getdents64-dir`
  - `pipe2-cloexec-nonblock`
  - `dup3-pipe-write`
- 新 probe 继续作为真实 riscv64 ELF 交叉编译，经串口注入 Ubuntu guest 内执行。

## 验证
- `riscv64-linux-gnu-gcc -O2 -Wall -Werror -o /tmp/nemu-systemd-syscall-probe.riscv64 Linux/tools/nemu-systemd-syscall-probe.c`：PASS。
- `riscv64-linux-gnu-strip /tmp/nemu-systemd-syscall-probe.riscv64` 后大小为 34824B。
- `bash -n Linux/scripts/check-nemu-systemd-guest.sh`：PASS。
- `git diff --check -- Linux/tools/nemu-systemd-syscall-probe.c Linux/scripts/check-nemu-systemd-guest.sh`：PASS。
- focused gate：

```sh
timeout 1500s make -C Linux check-nemu-systemd-guest \
  NEMU_SYSTEMD_CHECK_LOG_DIR=/home/lyg/PA/ysyx-workbench/Linux/env/logs/linux-front/riscv64-nemu-syscall-more-check \
  NEMU_SYSTEMD_SOAK_SECONDS=0 \
  NEMU_SYSTEMD_FS_STRESS_MIB=1 \
  NEMU_SYSTEMD_FS_TREE_FILES=16 \
  NEMU_SYSTEMD_PROCESS_LOOPS=4 \
  NEMU_SYSTEMD_BLOCK_PARALLEL_JOBS=2 \
  NEMU_SYSTEMD_BLOCK_JOB_MIB=1 \
  NEMU_SYSTEMD_UART_RX_STRESS_LINES=128
```

- 结果：PASS。
- `perf.tsv`: `boot_seconds=238`、`guest_check_seconds=246`、`poweroff_seconds=20`、`total_seconds=504`、`fs_tree_files=16`、`uart_rx_stress_lines=128`。

## 关键 marker
- `__NEMU_SYSCALL_PROBE_PASS__:madvise-willneed`
- `__NEMU_SYSCALL_PROBE_PASS__:mincore-resident`
- `__NEMU_SYSCALL_PROBE_PASS__:fcntl-record-lock`
- `__NEMU_SYSCALL_PROBE_PASS__:faccessat2-eaccess`
- `__NEMU_SYSCALL_PROBE_PASS__:getdents64-dir`
- `__NEMU_SYSCALL_PROBE_PASS__:pipe2-cloexec-nonblock`
- `__NEMU_SYSCALL_PROBE_PASS__:dup3-pipe-write`
- `__NEMU_SYSCALL_PROBE_DONE__ rc=0`
- `__NEMU_SYSTEMD_CHECK_DONE__ rc=0`
- `syscon-reset: poweroff requested value=0x00005555`
- `HIT GOOD TRAP`

失败扫描只命中 guest 脚本里执行的 grep 命令回显，没有行首真实 `__NEMU_CHECK_FAIL__:`、`__NEMU_SYSCALL_PROBE_FAIL__`、panic/Oops/segfault。

## 边界
- 这扩大的是 Ubuntu/systemd 默认路径的 syscall 覆盖面，不是完整 syscall fuzz。
- 仍不声明多小时长期运行、virtio 多队列、malformed descriptor fuzz、多设备异常路径或 QEMU 级完整虚拟机。
