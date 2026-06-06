# NEMU Ubuntu systemd syscall probe

## 目标
- 继续推进完整 Ubuntu 22.04.5 的“更多系统调用稳定性”证据。
- 在 shell 命令小电池之外，增加一个真正运行在 guest 内的 riscv64 ELF，覆盖 VM、IPC、文件锁、直接 IO、exec/fork/timer 等路径。

## 实现
- 新增 `Linux/tools/nemu-systemd-syscall-probe.c`。
- `Linux/scripts/check-nemu-systemd-guest.sh` 默认用 `riscv64-linux-gnu-gcc` 构建 probe，strip 后 base64 注入 guest，再在 `/root/nemu-systemd-guest-check.d` 下执行。
- 可配置项：
  - `RISCV64_LINUX_GCC=...`：指定交叉编译器。
  - `NEMU_SYSTEMD_SYSCALL_PROBE=0`：临时关闭 probe。
- probe 覆盖：
  - `mmap + msync + pread`
  - `posix_fallocate`
  - `flock`
  - `syncfs`
  - `O_DIRECT write + fsync`
  - `socketpair`
  - `eventfd + poll`
  - `epoll + timerfd`
  - periodic `timerfd`
  - `ppoll + pselect`
  - `setitimer + SIGALRM`
  - POSIX `timer_create/timer_settime + SIGUSR2`
  - `signalfd`
  - `PTY + termios + TIOCGWINSZ/TIOCSWINSZ`
  - PTY controlling TTY、foreground process group 和 `SIGWINCH`
  - `inotify`
  - `futex wait/wake`
  - `pidfd_open + pidfd_send_signal + poll + waitid(P_PIDFD)`
  - `prctl(PR_SET_NAME/PR_GET_NAME)`
  - `getrandom`
  - `statx`
  - `openat2`
  - `copy_file_range`
  - `renameat2(RENAME_NOREPLACE)`
  - `close_range`
  - `linkat + hardlink nlink/statx`
  - `fchmodat`
  - `utimensat`
  - directory `fsync`
  - `memfd_create + mmap`
  - `fork + pipe + execve`
  - `clock_gettime + nanosleep`
  - `clock_nanosleep(CLOCK_MONOTONIC, TIMER_ABSTIME)`

## 调试记录
- 首次 guest-check 失败在 `execve-true`，根因是 probe 硬编码 `/bin/true`。
- 当前 rootfs 的 merged-/usr 兼容并不保证 `/bin/true`，但 `/usr/bin/true` 存在，shell 侧原本也通过 `/usr/bin/env true` 验证。
- 修正为先 `execl("/usr/bin/true", ...)`，再 fallback `execlp("true", ...)`，避免把 rootfs 兼容路径误当成 syscall/NEMU 失败。

## 验证
- `bash -n Linux/scripts/check-nemu-systemd-guest.sh`：PASS。
- `riscv64-linux-gnu-gcc -O2 -Wall -Werror -o Linux/env/tmp/nemu-systemd-syscall-probe.riscv64 Linux/tools/nemu-systemd-syscall-probe.c`：PASS。
- `riscv64-linux-gnu-strip` 后 probe 为 14344B，base64 payload 为 19380B。
- `git diff --check -- Linux/scripts/check-nemu-systemd-guest.sh Linux/tools/nemu-systemd-syscall-probe.c`：PASS。
- `make -C Linux check-nemu-systemd-guest`：PASS，perf 为 `boot_seconds=240`、`guest_check_seconds=98`、`total_seconds=338`。
- `make -C Linux check-nemu-systemd-guest-long`：PASS，perf 为 `boot_seconds=244`、`guest_check_seconds=167`、`total_seconds=411`、`soak_seconds=120`、`fs_stress_mib=16`、`process_loops=64`、`max_cycles=30000000000`。
- 扩展 systemd event-loop 相关 syscall 后，`riscv64-linux-gnu-gcc -O2 -Wall -Werror -o /tmp/nemu-systemd-syscall-probe.riscv64 Linux/tools/nemu-systemd-syscall-probe.c`：PASS；strip 后 probe 为 18440B。
- 扩展后 `make -C Linux check-nemu-systemd-guest`：PASS，perf 为 `boot_seconds=244`、`guest_check_seconds=125`、`total_seconds=369`。
- 扩展后 `make -C Linux check-nemu-systemd-guest-long`：PASS，perf 为 `boot_seconds=237`、`guest_check_seconds=191`、`total_seconds=428`、`soak_seconds=120`、`fs_stress_mib=16`、`process_loops=64`、`block_parallel_jobs=4`、`block_job_mib=2`、`max_cycles=30000000000`。
- 扩展 PTY/termios/devpts 后，`riscv64-linux-gnu-gcc -O2 -Wall -Werror -o /tmp/nemu-systemd-syscall-probe.riscv64 Linux/tools/nemu-systemd-syscall-probe.c`：PASS；strip 后 probe 为 18440B。
- PTY 扩展后 `make -C Linux check-nemu-systemd-guest`：PASS，perf 为 `boot_seconds=229`、`guest_check_seconds=118`、`total_seconds=347`。
- PTY 扩展后 `make -C Linux check-nemu-systemd-guest-long`：PASS，perf 为 `boot_seconds=227`、`guest_check_seconds=181`、`total_seconds=408`、`soak_seconds=120`、`fs_stress_mib=16`、`process_loops=64`、`block_parallel_jobs=4`、`block_job_mib=2`、`max_cycles=30000000000`。
- 扩展 PTY job-control 后，修正 child 写 pipe result 未检查返回值导致的 `-Werror=unused-result`，`riscv64-linux-gnu-gcc -O2 -Wall -Werror -o /tmp/nemu-systemd-syscall-probe.riscv64 Linux/tools/nemu-systemd-syscall-probe.c && riscv64-linux-gnu-strip ...`：PASS；strip 后 probe 为 18440B。
- PTY job-control 扩展后 `make -C Linux check-nemu-systemd-guest`：PASS，perf 为 `boot_seconds=236`、`guest_check_seconds=120`、`total_seconds=356`，`pty-controlling-tty/pty-foreground-pgrp/pty-sigwinch` 全 PASS。
- PTY job-control 扩展后 `make -C Linux check-nemu-systemd-guest-long`：PASS，perf 为 `boot_seconds=228`、`guest_check_seconds=188`、`total_seconds=416`、`soak_seconds=120`、`fs_stress_mib=16`、`process_loops=64`、`block_parallel_jobs=4`、`block_job_mib=2`、`max_cycles=30000000000`。
- 扩展 timer/signal/poll/pidfd/process-misc 后，`riscv64-linux-gnu-gcc -O2 -Wall -Werror -o /tmp/nemu-systemd-syscall-probe.riscv64 Linux/tools/nemu-systemd-syscall-probe.c && riscv64-linux-gnu-strip ...`：PASS；strip 后 probe 为 22536B。调试中发现 riscv64 交叉头文件只有 `__NR_pidfd_*`、没有 `SYS_pidfd_*` 宏，已补 fallback，避免 pidfd 误 skip。
- timer/signal/pidfd 扩展后 `make -C Linux check-nemu-systemd-guest`：PASS，perf 为 `boot_seconds=229`、`guest_check_seconds=126`、`total_seconds=355`，新增 `ppoll-pipe/pselect-pipe/setitimer-sigalrm/pidfd-open/pidfd-send-signal/pidfd-poll-exit/waitid-pidfd/prctl-name/getrandom` 全 PASS。
- timer/signal/pidfd 扩展后 `make -C Linux check-nemu-systemd-guest-long`：PASS，perf 为 `boot_seconds=229`、`guest_check_seconds=193`、`total_seconds=422`、`soak_seconds=120`、`fs_stress_mib=16`、`process_loops=64`、`block_parallel_jobs=4`、`block_job_mib=2`、`max_cycles=30000000000`。
- 扩展现代 FS syscall 后，`riscv64-linux-gnu-gcc -O2 -Wall -Werror -o /tmp/nemu-systemd-syscall-probe.riscv64 Linux/tools/nemu-systemd-syscall-probe.c && riscv64-linux-gnu-strip ...`：PASS；strip 后 probe 为 26632B。
- 现代 FS syscall 扩展后 `make -C Linux check-nemu-systemd-guest`：PASS，perf 为 `boot_seconds=227`、`guest_check_seconds=164`、`total_seconds=391`，新增 `statx-dir/openat2-create-write/statx-file-size/copy-file-range/renameat2-noreplace/close-range` 全 PASS。
- 扩展 rootfs metadata syscall 后，`riscv64-linux-gnu-gcc -O2 -Wall -Werror -o /tmp/nemu-systemd-syscall-probe.riscv64 Linux/tools/nemu-systemd-syscall-probe.c && riscv64-linux-gnu-strip ...`：PASS；strip 后 probe 为 26632B。
- rootfs metadata 扩展后 `make -C Linux check-nemu-systemd-guest`：PASS，perf 为 `boot_seconds=229`、`guest_check_seconds=187`、`total_seconds=416`，新增 `linkat-hardlink/fchmodat-hardlink/utimensat-hardlink/directory-fsync` 全 PASS。
- 扩展 timer/interrupt syscall 后，probe 新增 `periodic-timerfd`、`posix-timer-signal` 和 `clock-nanosleep-abstime`，覆盖 periodic hrtimer、POSIX timer signal delivery 与 absolute sleep 路径。`riscv64-linux-gnu-gcc -O2 -Wall -Werror -o /tmp/nemu-systemd-syscall-probe.riscv64 Linux/tools/nemu-systemd-syscall-probe.c && riscv64-linux-gnu-strip ...`：PASS；strip 后 probe 为 26632B。
- timer/interrupt syscall 扩展后 `timeout 1400s make -C Linux check-nemu-systemd-guest`：PASS，perf 为 `boot_seconds=236`、`guest_check_seconds=190`、`total_seconds=426`。新增 marker `periodic-timerfd/posix-timer-signal/clock-nanosleep-abstime` 全 PASS；soak uptime `605->639`，interrupts `156439->165024`，最终 `__NEMU_SYSTEMD_CHECK_DONE__ rc=0`。

关键 guest marker：
- `__NEMU_SYSCALL_PROBE_PASS__:mmap-msync`
- `__NEMU_SYSCALL_PROBE_PASS__:pread-mmap-file`
- `__NEMU_SYSCALL_PROBE_PASS__:posix-fallocate`
- `__NEMU_SYSCALL_PROBE_PASS__:flock`
- `__NEMU_SYSCALL_PROBE_PASS__:syncfs`
- `__NEMU_SYSCALL_PROBE_PASS__:odirect-write-fsync`
- `__NEMU_SYSCALL_PROBE_PASS__:socketpair`
- `__NEMU_SYSCALL_PROBE_PASS__:eventfd-poll-read`
- `__NEMU_SYSCALL_PROBE_PASS__:epoll-timerfd`
- `__NEMU_SYSCALL_PROBE_PASS__:periodic-timerfd`
- `__NEMU_SYSCALL_PROBE_PASS__:ppoll-pipe`
- `__NEMU_SYSCALL_PROBE_PASS__:pselect-pipe`
- `__NEMU_SYSCALL_PROBE_PASS__:setitimer-sigalrm`
- `__NEMU_SYSCALL_PROBE_PASS__:posix-timer-signal`
- `__NEMU_SYSCALL_PROBE_PASS__:signalfd`
- `__NEMU_SYSCALL_PROBE_PASS__:pty-termios`
- `__NEMU_SYSCALL_PROBE_PASS__:pty-winsize`
- `__NEMU_SYSCALL_PROBE_PASS__:pty-master-slave`
- `__NEMU_SYSCALL_PROBE_PASS__:pty-controlling-tty`
- `__NEMU_SYSCALL_PROBE_PASS__:pty-foreground-pgrp`
- `__NEMU_SYSCALL_PROBE_PASS__:pty-sigwinch`
- `__NEMU_SYSCALL_PROBE_PASS__:inotify-create-close`
- `__NEMU_SYSCALL_PROBE_PASS__:futex-wait-wake`
- `__NEMU_SYSCALL_PROBE_PASS__:pidfd-open`
- `__NEMU_SYSCALL_PROBE_PASS__:pidfd-send-signal`
- `__NEMU_SYSCALL_PROBE_PASS__:pidfd-poll-exit`
- `__NEMU_SYSCALL_PROBE_PASS__:waitid-pidfd`
- `__NEMU_SYSCALL_PROBE_PASS__:prctl-name`
- `__NEMU_SYSCALL_PROBE_PASS__:getrandom`
- `__NEMU_SYSCALL_PROBE_PASS__:statx-dir`
- `__NEMU_SYSCALL_PROBE_PASS__:openat2-create-write`
- `__NEMU_SYSCALL_PROBE_PASS__:statx-file-size`
- `__NEMU_SYSCALL_PROBE_PASS__:copy-file-range`
- `__NEMU_SYSCALL_PROBE_PASS__:renameat2-noreplace`
- `__NEMU_SYSCALL_PROBE_PASS__:close-range`
- `__NEMU_SYSCALL_PROBE_PASS__:linkat-hardlink`
- `__NEMU_SYSCALL_PROBE_PASS__:fchmodat-hardlink`
- `__NEMU_SYSCALL_PROBE_PASS__:utimensat-hardlink`
- `__NEMU_SYSCALL_PROBE_PASS__:directory-fsync`
- `__NEMU_SYSCALL_PROBE_PASS__:memfd-mmap`
- `__NEMU_SYSCALL_PROBE_PASS__:fork-pipe-execve`
- `__NEMU_SYSCALL_PROBE_PASS__:clock-nanosleep`
- `__NEMU_SYSCALL_PROBE_PASS__:clock-nanosleep-abstime`
- `__NEMU_SYSCALL_PROBE_DONE__ rc=0`
- `__NEMU_CHECK_PASS__:syscall-probe`
- `__NEMU_SYSTEMD_CHECK_DONE__ rc=0`

long gate 追加 marker：
- 16MiB rootfs stress：`__NEMU_CHECK_FS_STRESS_BYTES__:16777216/16777216`
- 120s soak：最新 timer/signal/pidfd 扩展后为 `__NEMU_CHECK_SOAK_UPTIME__:533->731`
- interrupt monotonic：最新 timer/signal/pidfd 扩展后为 `__NEMU_CHECK_INTERRUPTS__:137575->187433`
- `__NEMU_SYSTEMD_CHECK_DONE__ rc=0`

## 边界
- 这是一次默认短 gate 中的 syscall/VM/IPC/FS 增强，不等于多小时 soak。
- 仍未覆盖 virtio malformed descriptor fuzz、多队列、多设备并发、异常注入或 QEMU 级完整设备模型。
