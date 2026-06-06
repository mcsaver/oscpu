# NEMU Ubuntu syscall probe 扩展

## 目标
- 继续推进完整 Ubuntu 22.04.5 的“更多系统调用稳定性”证据。
- 在既有 systemd/dbus/tty/rootfs gate 基础上，把 VM 管理、Unix socket fd 传递和文件零拷贝路径纳入真实 riscv64 ELF guest probe。

## 实现
- `Linux/tools/nemu-systemd-syscall-probe.c` 新增：
  - `mremap-anon`：匿名映射扩容后校验原页内容保持。
  - `mprotect-readonly-page`：把匿名页切到只读后读回校验，再恢复可写。
  - `unix-scm-rights`：通过 `AF_UNIX` datagram `sendmsg/recvmsg + SCM_RIGHTS` 传递文件描述符，并用接收端 fd 读回 payload。
  - `sendfile-regular-file`：普通文件到普通文件的 `sendfile` 拷贝和 pattern 校验。
  - `splice-file-pipe-file`：普通文件 -> pipe -> 普通文件的 `splice` 拷贝和 pattern 校验。
- `Linux/README.md` 与 `Linux/env/README.md` 同步更新默认 syscall probe 覆盖清单。

## 验证
- `riscv64-linux-gnu-gcc -O2 -Wall -Werror -o /tmp/nemu-systemd-syscall-probe.riscv64 Linux/tools/nemu-systemd-syscall-probe.c`：PASS。
- `bash -n Linux/scripts/check-nemu-systemd-guest.sh`：PASS。
- `git diff --check -- Linux/tools/nemu-systemd-syscall-probe.c Linux/scripts/check-nemu-systemd-guest.sh`：PASS。
- Focused gate：
  `timeout 1500s make -C Linux check-nemu-systemd-guest NEMU_SYSTEMD_CHECK_LOG_DIR=/home/lyg/PA/ysyx-workbench/Linux/env/logs/linux-front/riscv64-nemu-syscall-expanded-check NEMU_SYSTEMD_SOAK_SECONDS=0 NEMU_SYSTEMD_FS_STRESS_MIB=1 NEMU_SYSTEMD_PROCESS_LOOPS=4 NEMU_SYSTEMD_BLOCK_PARALLEL_JOBS=2 NEMU_SYSTEMD_BLOCK_JOB_MIB=1 NEMU_SYSTEMD_UART_RX_STRESS_LINES=128`
  PASS。
- perf：`boot_seconds=239`、`guest_check_seconds=200`、`poweroff_seconds=23`、`total_seconds=462`、`uart_rx_stress_lines=128`。

## 关键 marker
- `__NEMU_SYSCALL_PROBE_PASS__:mremap-anon`
- `__NEMU_SYSCALL_PROBE_PASS__:mprotect-readonly-page`
- `__NEMU_SYSCALL_PROBE_PASS__:unix-scm-rights`
- `__NEMU_SYSCALL_PROBE_PASS__:sendfile-regular-file`
- `__NEMU_SYSCALL_PROBE_PASS__:splice-file-pipe-file`
- `__NEMU_SYSCALL_PROBE_DONE__ rc=0`
- `__NEMU_CHECK_PASS__:syscall-probe`
- `__NEMU_UART_RX_STRESS_COUNT__:128/128`
- `__NEMU_SYSTEMD_CHECK_DONE__ rc=0`
- `syscon-reset: poweroff requested value=0x00005555`
- `HIT GOOD TRAP`

## 边界
- 这扩大了完整 Ubuntu 用户态常见 syscall 面，尤其是 dynamic loader/glibc VM 操作、dbus/systemd 常见 fd passing 和文件零拷贝路径。
- 仍不等同于多小时 soak、virtio malformed descriptor fuzz、多队列、多设备错误路径或 QEMU 级完整虚拟机声明。
