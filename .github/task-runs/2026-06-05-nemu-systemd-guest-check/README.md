# NEMU Ubuntu systemd guest-check

## 目标
- 为 `make -C Linux ARCH=riscv64-nemu run` 当前完整 Ubuntu 22.04.5 rootfs 路线补一个可重复自动化 gate。
- 在 guest 内验证 systemd、伪文件系统、TTY、virtio rootfs、timer、proc/syscall 基础路径和 dmesg critical 状态。

## 根因与修复
- 首次 gate 失败时，systemd 还在 `starting`，但主要新根因是 `findmnt` 在 `fcvt.s.d` 上触发 `SIGILL`。
- `nemu/src/isa/riscv64/inst.c` 已补齐官方 RV64F/D `fcvt.s.d` 与 `fcvt.d.s`，避免对 Linux 用户态做特判。
- `Linux/scripts/check-nemu-systemd-guest.sh` 现在拿到 root prompt 后会轮询 systemd 到 `running`，并只把行首真实 `__NEMU_CHECK_FAIL__:` 作为失败标记。
- `nemu/src/device/serial.c` 支持 `NEMU_SERIAL_FIFO`，每次自动化运行可使用独立 FIFO，避免复用 `/tmp/nemu.serial` 污染输入。

## 2026-06-05 加强版
- guest-check 新增可配置 `NEMU_SYSTEMD_SOAK_SECONDS`、`NEMU_SYSTEMD_FS_STRESS_MIB`、`NEMU_SYSTEMD_PROCESS_LOOPS` 和 `NEMU_SYSTEMD_INPUT_DELAY`，默认 20s soak、4MiB rootfs 压力写回、16 轮 fork/wait。
- guest 内新增基础 syscall 小电池：mkdir/write/read、symlink/readlink、chmod/stat、rename/copy/cmp、pipe/wc、fork/wait、execve、signal kill/wait。
- rootfs 验证从 32KiB 小写回扩展到 4MiB `dd conv=fsync`、copy、cmp、sync；timer/interrupt 增加 soak 期间 uptime 前进和 `/proc/stat intr` 单调性检查。
- 调试中发现旧 UART 一次性 `cat` 长脚本到串口 FIFO 会让 guest tty/shell 丢掉函数定义和变量，表现为 `pass: command not found`、压力写回变量为空；16550A UART 重构后，脚本默认 `NEMU_SYSTEMD_INPUT_DELAY=0`，直接整段写入 FIFO 也可稳定通过。另一次失败来自 `/proc/interrupts` 求和不稳定，已改用 `/proc/stat` 的 `intr` 总计。
- 继续补入块设备可见性：host 端注入 rootfs backing image 字节数，guest 端检查 `blockdev --getsize64 /dev/vda` 与之相等，并检查 `/sys/block/vda/queue/logical_block_size=512`。
- 继续补入块设备/rootfs direct IO：guest 端检查 rootfs fstype、`/dev/vda` 64KiB `iflag=direct` 直接读、`blockdev --flushbufs /dev/vda`、rootfs 文件 128KiB `oflag=direct conv=fsync` 写入和 `iflag=direct` 读回 `cmp`。
- 新增 long gate：`make -C Linux check-nemu-systemd-guest-long` 默认 120s soak、16MiB rootfs stress、64 轮 fork/wait、30B 指令预算和独立 log dir。
- guest 侧补入 `ttyS0-stty`、`ttyS0-write`、`console-write` 与 `fifo-ipc`，把 tty/console 写路径和 FIFO IPC 纳入自动化验收。
- 新增 `perf.tsv`：host 侧记录 boot、guest-check、total 墙钟耗时和当前压力参数；guest 侧输出 uptime begin/end marker。
- 新增真实 riscv64 ELF syscall probe：host 侧用 `riscv64-linux-gnu-gcc` 构建 `Linux/tools/nemu-systemd-syscall-probe.c`，strip/base64 后注入 guest，覆盖 `mmap/msync/pread`、`posix_fallocate`、`flock`、`syncfs`、`O_DIRECT`、`socketpair`、`eventfd/poll`、`epoll/timerfd`、`ppoll/pselect`、`setitimer/SIGALRM`、`signalfd`、`pidfd/waitid`、`PTY/termios/devpts/job-control`、`inotify`、`futex wait/wake`、`prctl/getrandom`、`statx/openat2/linkat/fchmodat/utimensat/directory-fsync`、`memfd`、`fork/pipe/execve` 和 `clock_gettime/nanosleep`。可用 `RISCV64_LINUX_GCC=...` 覆盖编译器或 `NEMU_SYSTEMD_SYSCALL_PROBE=0` 临时关闭。
- 新增 udev/sysfs/virtio-blk 可见性检查：guest 端逐项验证 `/dev` 为 `devtmpfs`、`/proc` 为 `proc`、`/sys` 为 `sysfs`、`/run` 为 `tmpfs`、`/dev/pts` 为 `devpts`、`/dev/shm` 为 `tmpfs`、`/sys/fs/cgroup` 为 `cgroup2`；同时检查 `udevadm` 存在、`udevadm settle` 成功、`systemd-udevd.service` active、`/dev/vda` 是 block special file、`/sys/class/block/vda/dev`、`/sys/class/block/vda/device/driver=virtio_blk`、udev properties 和 `/dev/disk/*` symlink。
- 新增 systemd-run transient service/timer 检查：guest 内由 PID1 创建 transient service，验证 `--wait` 成功、service 输出文件、`Result=success`、cgroup v2 路径和 journal stdout；再创建 transient timer，验证 timer 触发并写入 marker。

## 2026-06-05 udev/sysfs/virtio-blk 复验
- `bash -n Linux/scripts/check-nemu-systemd-guest.sh`：PASS。
- `git diff --check -- nemu/src/device/serial.c nemu/src/device/uart16550.c nemu/include/device/uart16550.h nemu/src/memory/soc.c nemu/src/device/filelist.mk nemu/tools/uart16550-smoke.c Linux/scripts/check-nemu-systemd-guest.sh`：PASS。
- `make -C Linux check-nemu-systemd-guest`：PASS，perf 为 `boot_seconds=225`、`guest_check_seconds=134`、`total_seconds=359`。
- 关键 marker：`mount-fstype-/dev`、`mount-fstype-/proc`、`mount-fstype-/sys`、`mount-fstype-/run`、`mount-fstype-/dev/pts`、`mount-fstype-/dev/shm`、`mount-fstype-/sys/fs/cgroup`、`udevadm-present`、`udev-settle`、`udevd-active`、`vda-block-node`、`sysfs-vda-dev`、`sysfs-vda-block`、`sysfs-vda-driver`、`udev-vda-properties`、`dev-disk-symlink`、`proc-partitions-vda`、`dmesg-no-critical`、`__NEMU_SYSTEMD_CHECK_DONE__ rc=0` 全部 PASS。
- 实测值：`__NEMU_CHECK_VDA_DEV_NODE__:block special file fe:0`，`__NEMU_CHECK_VDA_SYS_DEV__:254:0`，`__NEMU_CHECK_VDA_DRIVER__:virtio_blk`，`__NEMU_CHECK_DEV_DISK_LINK__:/dev/disk/by-id/virtio-ysyx-nemu-virtio-blk`，`__NEMU_CHECK_ROOT_SOURCE__:/dev/vda`。

## 2026-06-05 systemd manager/journal/dbus 复验
- `bash -n Linux/scripts/check-nemu-systemd-guest.sh`：PASS。
- `git diff --check -- Linux/scripts/check-nemu-systemd-guest.sh`：PASS。
- `make -C Linux check-nemu-systemd-guest`：PASS，perf 为 `boot_seconds=233`、`guest_check_seconds=143`、`total_seconds=376`。
- 新增 marker：`systemd-version`、`systemd-show-system-state`、`systemd-show-failed-count`、`journald-active`、`journalctl-present`、`journalctl-boot-read`、`dbus-active`、`busctl-present`、`busctl-system-list`、`dmesg-no-critical`、`__NEMU_SYSTEMD_CHECK_DONE__ rc=0` 全部 PASS。
- 实测值：`__NEMU_CHECK_SYSTEMD_VERSION__:systemd 249 (249.11-0ubuntu3.20)`、`__NEMU_CHECK_SYSTEMD_SHOW_STATE__:running`、`__NEMU_CHECK_SYSTEMD_FAILED_COUNT__:0`。

## 2026-06-05 systemd target/getty 复验
- `bash -n Linux/scripts/check-nemu-systemd-guest.sh`：PASS。
- `git diff --check -- Linux/scripts/check-nemu-systemd-guest.sh`：PASS。
- `make -C Linux check-nemu-systemd-guest`：PASS，perf 为 `boot_seconds=233`、`guest_check_seconds=152`、`total_seconds=385`。
- 新增 marker：`systemd-target-local-fs.target`、`systemd-target-sysinit.target`、`systemd-target-basic.target`、`systemd-target-multi-user.target`、`systemd-target-getty.target`、`serial-getty-ttyS0-active`、`__NEMU_SYSTEMD_CHECK_DONE__ rc=0` 全部 PASS。
- 实测值：`__NEMU_CHECK_SYSTEMD_UNIT__:local-fs.target:active`、`sysinit.target:active`、`basic.target:active`、`multi-user.target:active`、`getty.target:active`、`serial-getty@ttyS0.service:active`。

## 2026-06-05 systemd transient service/timer 复验
- `bash -n Linux/scripts/check-nemu-systemd-guest.sh`：PASS。
- `make -C Linux ARCH=riscv64-nemu check-nemu-performance-config`：PASS，输出 `__NEMU_PERFORMANCE_CONFIG__:ok`。
- `git diff --check -- Linux/scripts/check-nemu-systemd-guest.sh Linux/scripts/check-nemu-performance-config.sh`：PASS。
- `make -C Linux check-nemu-systemd-guest`：PASS，perf 为 `boot_seconds=233`、`guest_check_seconds=189`、`total_seconds=422`。
- 新增 marker：`systemd-run-present`、`systemd-run-transient-service`、`systemd-transient-service-output`、`systemd-transient-service-result`、`systemd-transient-service-cgroup`、`systemd-transient-service-journal`、`systemd-run-transient-timer`、`systemd-transient-timer-fired`、`__NEMU_SYSTEMD_CHECK_DONE__ rc=0` 全部 PASS。
- 实测值：`__NEMU_CHECK_SYSTEMD_TRANSIENT_RESULT__:success`，`perf.tsv` 为 `233/189/422/20/4/16/4/1/12000000000`。

## 2026-06-05 UART bus profile 复验
- UART bus profile 合约落地后复跑默认 gate：`timeout 1400s make -C Linux check-nemu-systemd-guest` PASS。
- perf 为 `boot_seconds=236`、`guest_check_seconds=190`、`total_seconds=426`、`soak_seconds=20`、`fs_stress_mib=4`、`process_loops=16`、`block_parallel_jobs=4`、`block_job_mib=1`、`max_cycles=12000000000`。
- 关键 marker：`systemd-running`、`serial-getty-ttyS0-active`、systemd transient service/timer 全 PASS、`__NEMU_CHECK_SYSTEMD_TRANSIENT_RESULT__:success`、`ttyS0-node`、`console-node`、`ttyS0-stty`、`ttyS0-write`、`console-write`、`fifo-ipc`、`__NEMU_SYSCALL_PROBE_DONE__ rc=0`、soak uptime `604->639`、interrupts `156336->164965`、最终 `__NEMU_SYSTEMD_CHECK_DONE__ rc=0`。
- 本次验证说明 UART 从 byte-contiguous 假设推进到显式 bus profile 后，当前 `ns16550a/reg-shift=0` Linux 路线仍能完成 ttyS0 输入输出、systemd job/timer 和短稳态检查；边界仍不是周期精确 UART 或 QEMU 级完整串口设备。

## 2026-06-05 timer/interrupt syscall 复验
- syscall probe 新增 periodic timerfd、POSIX timer signal 和 absolute `clock_nanosleep` 后复跑默认 gate：`timeout 1400s make -C Linux check-nemu-systemd-guest` PASS。
- perf 为 `boot_seconds=236`、`guest_check_seconds=190`、`total_seconds=426`、`soak_seconds=20`、`fs_stress_mib=4`、`process_loops=16`、`block_parallel_jobs=4`、`block_job_mib=1`、`max_cycles=12000000000`。
- 新增 marker：`periodic-timerfd`、`posix-timer-signal`、`clock-nanosleep-abstime` 全 PASS；既有 `epoll-timerfd`、`setitimer-sigalrm`、`clock-nanosleep` 仍 PASS；`__NEMU_SYSCALL_PROBE_DONE__ rc=0`，soak uptime `605->639`，interrupts `156439->165024`，最终 `__NEMU_SYSTEMD_CHECK_DONE__ rc=0`。
- 本次验证加强 timer/interrupt 稳定性证据，但仍是默认短 soak 与 focused syscall 覆盖，不替代 120s/300s gate 或多小时长期运行。

## 2026-06-05 vda 高 offset sha256 复验
- guest-check 新增 host/guest `/dev/vda` 高 offset 读回比对：host 对 rootfs backing image 尾部 64KiB 窗口计算 sha256，guest 从 `/dev/vda` 同一 offset 用 direct IO 读出并比对。
- 初版对 start/middle/tail 三个窗口都和 host 启动前镜像比对，默认 gate 最终 rc=1；日志显示 start/middle mismatch、tail match。根因是 Ubuntu rootfs 为读写挂载，systemd/journal 启动中会合法改写前部和中部块，因此不能把活 rootfs 的这些区域当成静态镜像校验。
- 修正后保留 head 64KiB direct-read 字节数检查，并对稳定尾部窗口做强 hash 比对。`timeout 1400s make -C Linux check-nemu-systemd-guest` PASS，perf 为 `boot_seconds=233`、`guest_check_seconds=193`、`total_seconds=426`。
- 新增 marker：`__NEMU_CHECK_VDA_WINDOW_SHA256__:2147418112:de2f256064a0af797747c2b97505dc0b9f3df0de4f489eac731c23ae9ca9cc31:de2f256064a0af797747c2b97505dc0b9f3df0de4f489eac731c23ae9ca9cc31`、`__NEMU_CHECK_VDA_WINDOW_COUNT__:1`、`vda-direct-read-sha256-windows` PASS；既有 `vda-direct-read`、`vda-flushbufs`、rootfs direct IO、并发 direct IO 和 rootfs stress 仍 PASS，最终 `__NEMU_SYSTEMD_CHECK_DONE__ rc=0`。

## 2026-06-05 systemd poweroff/syscon 复验
- NEMU 专用 rootfs DTB `npc-rv64-nemu-rootfs.dtb` 新增标准 `syscon-poweroff/syscon-reboot` 节点，OpenSBI 可通过 SRST 使用该 syscon；普通 NPC rootfs DTB 不带这个 NEMU-only 节点。
- NEMU 新增 `syscon-reset` MMIO 设备，收到 poweroff value `0x5555` 或 reboot value `0x7777` 后让 NEMU 以 GOOD TRAP 结束；当前 reboot 仍建模为仿真成功退出，不做整机重启循环。
- `check-nemu-systemd-guest.sh` 默认在所有 guest 检查通过后输出 `__NEMU_SYSTEMD_POWEROFF_BEGIN__` 并执行 `systemctl --no-wall poweroff`，host 侧等待 NEMU 自然退出；`perf.tsv` 新增 `poweroff_seconds`。
- 复验：`timeout 1700s make -C Linux check-nemu-systemd-guest` PASS，perf 为 `boot_seconds=237`、`guest_check_seconds=197`、`poweroff_seconds=20`、`total_seconds=454`。
- 关键 marker：`__NEMU_SYSTEMD_CHECK_DONE__ rc=0`、`__NEMU_SYSTEMD_POWEROFF_BEGIN__`、`reboot: Power down`、`syscon-reset: poweroff requested value=0x00005555`、`nemu: HIT GOOD TRAP`。日志检查确认无 `syscon-poweroff.*failed` 或 `probe of .*syscon`。

## 验证
- `bash -n Linux/scripts/check-nemu-systemd-guest.sh`：PASS。
- `git diff --check -- Linux/scripts/check-nemu-systemd-guest.sh Linux/Makefile`：PASS。
- `NEMU_HOME=/home/lyg/PA/ysyx-workbench/nemu make -C nemu -j$(nproc)`：PASS。
- `make -C Linux check-nemu-systemd-guest`：PASS。
- `make -C Linux check-nemu-systemd-guest-long`：PASS。

关键日志：
- `Linux/env/logs/linux-front/riscv64-nemu-systemd-guest-check/console.log`
- 其中可见 `__NEMU_CHECK_PASS__:systemd-running`、`__NEMU_CHECK_PASS__:ttyS0-write`、`__NEMU_CHECK_PASS__:console-write`、`__NEMU_CHECK_PASS__:fifo-ipc`、`__NEMU_SYSCALL_PROBE_PASS__:mmap-msync`、`__NEMU_SYSCALL_PROBE_PASS__:odirect-write-fsync`、`__NEMU_SYSCALL_PROBE_PASS__:epoll-timerfd`、`__NEMU_SYSCALL_PROBE_PASS__:ppoll-pipe`、`__NEMU_SYSCALL_PROBE_PASS__:pselect-pipe`、`__NEMU_SYSCALL_PROBE_PASS__:setitimer-sigalrm`、`__NEMU_SYSCALL_PROBE_PASS__:signalfd`、`__NEMU_SYSCALL_PROBE_PASS__:pidfd-open`、`__NEMU_SYSCALL_PROBE_PASS__:pidfd-send-signal`、`__NEMU_SYSCALL_PROBE_PASS__:pidfd-poll-exit`、`__NEMU_SYSCALL_PROBE_PASS__:waitid-pidfd`、`__NEMU_SYSCALL_PROBE_PASS__:pty-termios`、`__NEMU_SYSCALL_PROBE_PASS__:pty-controlling-tty`、`__NEMU_SYSCALL_PROBE_PASS__:inotify-create-close`、`__NEMU_SYSCALL_PROBE_PASS__:futex-wait-wake`、`__NEMU_SYSCALL_PROBE_PASS__:prctl-name`、`__NEMU_SYSCALL_PROBE_PASS__:getrandom`、`__NEMU_SYSCALL_PROBE_PASS__:memfd-mmap`、`__NEMU_SYSCALL_PROBE_PASS__:fork-pipe-execve`、`__NEMU_SYSCALL_PROBE_DONE__ rc=0`、`__NEMU_CHECK_PASS__:syscall-probe`、`__NEMU_CHECK_BLOCK_PARALLEL_BYTES__:4194304/4194304`、`__NEMU_CHECK_FS_STRESS_BYTES__:4194304/4194304`、`__NEMU_CHECK_SOAK_UPTIME__:512->547`、`__NEMU_CHECK_INTERRUPTS__:132323->140887`、`__NEMU_CHECK_PASS__:dmesg-no-critical`、`__NEMU_SYSTEMD_CHECK_DONE__ rc=0`。
- long log `Linux/env/logs/linux-front/riscv64-nemu-systemd-guest-long-check/console.log` 可见 syscall probe 全 PASS、`ttyS0-write`、`console-write`、`fifo-ipc`、`__NEMU_CHECK_BLOCK_PARALLEL_BYTES__:8388608/8388608`、`__NEMU_CHECK_FS_STRESS_BYTES__:16777216/16777216`、`__NEMU_CHECK_SOAK_UPTIME__:533->731`、`__NEMU_CHECK_INTERRUPTS__:137575->187433`、`__NEMU_SYSTEMD_CHECK_DONE__ rc=0`。
- 默认短 gate 加入 systemd transient service/timer 后，`Linux/env/logs/linux-front/riscv64-nemu-systemd-guest-check/perf.tsv` 当前 baseline 为 `boot_seconds=233`、`guest_check_seconds=189`、`total_seconds=422`、`soak_seconds=20`、`fs_stress_mib=4`、`process_loops=16`、`block_parallel_jobs=4`、`block_job_mib=1`。

## 边界
- 该 gate 说明当前 NEMU 可自动化启动完整 Ubuntu 22.04.5 systemd 并完成基础 guest 内检查。
- 仍不声明 NEMU 已达到 QEMU 级完整虚拟机；virtio/UART/PLIC 仍是当前 Linux bring-up 需要的最小设备模型，后续还要做长期运行、virtio 压力、更多设备和交互语义验证。
