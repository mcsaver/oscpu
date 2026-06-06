# Linux / Ubuntu 22.04 启动入口

这个目录是 RV64 Linux/Ubuntu bring-up 的顶层入口。`npc/rv64` 只保留 core RTL、testbench 和 Verilator 仿真本体；OpenSBI、Linux、Ubuntu、DTB、initramfs/rootfs、QEMU reference 和启动脚本统一放在这里。

命令规范：

- `ARCH` 表示仿真/目标架构，当前基准是 `riscv64-npc`。
- `BOOT` 表示启动场景，默认是 `ubuntu-rootfs`。
- `make ARCH=riscv64-npc run` 必须表示完整 Ubuntu rootfs 路线，不会偷偷降级成 shell initramfs gate。
- `make ARCH=riscv64-nemu run` 使用同一套 kernel/DTB/rootfs 启动 NEMU 参考入口，默认构建 no-PMU OpenSBI，且 `MAX_CYCLES=0` 表示无限预算。

常用命令：

```sh
cd Linux

# 完整 Ubuntu rootfs 路线。当前 virtio-blk/rootfs 后端仍是后续 gate，
# 因此这条命令用于继续调试完整 Linux，不等同于已通过。
make ARCH=riscv64-npc run

# 用 NEMU 跑同一条完整 Ubuntu rootfs 路线。
# 当前已能进入 ttyS0 root shell、systemd running，并通过 syscon/SRST 完成自然 poweroff；
# 但还不是 QEMU 级通用机器。
make ARCH=riscv64-nemu run

# NEMU Ubuntu/systemd 自动化验收：在 guest 内检查 systemd target/getty、journal/dbus、
# systemd-run transient service/timer/cgroup/journal、runtime unit reload request/start/output/status/cgroup/journal/cleanup、伪文件系统挂载、
# tty/console、基础 shell syscall、riscv64 ELF syscall probe（含 mremap/mprotect、madvise/mincore、
# epoll/timerfd、
# periodic timerfd、ppoll/pselect、setitimer、POSIX timer signal、signalfd、pidfd/waitid、inotify、futex、prctl/getrandom、
# Unix socket SCM_RIGHTS、pipe2/dup3、sendfile/splice、
# faccessat2/getdents64/fcntl record lock、linkat/fchmodat/utimensat/directory-fsync、
# PTY/termios/devpts/job-control 等 systemd/tty 常用机制）、timer sleep、absolute clock_nanosleep、
# /dev/vda 容量/逻辑与物理块大小、serial/GET_ID、virtio modalias/status/feature 协商（含 BLK_SIZE/FLUSH/INDIRECT/VERSION_1）、
# direct block read、高 offset sha256 读回、rootfs direct IO、并发 direct IO、
# /proc/interrupts 中 ttyS0/virtio/riscv-timer 可见性、virtio-blk direct read 后 IRQ 增长、
# rootfs 元数据树压力、rootfs 压力写回和短 soak。
# 所有 guest 检查通过后默认执行 systemctl poweroff，要求 OpenSBI syscon-poweroff
# 写 NEMU syscon-reset MMIO 并让 NEMU 正常退出。运行后会在 log dir 生成 perf.tsv，
# 记录 boot、guest-check、poweroff 和 total 墙钟耗时。
# 默认 gate 会先确认 NEMU performance 配置已生效，避免 trace/stat/debug 计数拖慢长跑；
# runtime unit reload 采用短 daemon-reload/SIGHUP 后直接 start unit，并用 output 证明 PID1 已加载，避免 systemctl show 长轮询。
# 默认 NEMU_SYSTEMD_CHECK_MAX_CYCLES=25000000000，以覆盖 runtime reload 和 syscall probe。
make check-nemu-systemd-guest

# 调试卡点时可以显式切到 debug defconfig 并放开 performance 守门。
NEMU_DEFCONFIG=riscv64-linux_debug_defconfig NEMU_PERFORMANCE_REQUIRED=0 make check-nemu-systemd-guest

# 更长的 NEMU Ubuntu/systemd 稳定性 gate，默认 120s soak、
# 16MiB rootfs stress、128 个元数据文件、64 轮 fork/wait、768 行 UART RX 突发输入
# 和 4 个 2MiB 并发 direct IO job，
# 日志和 perf.tsv 写入独立目录。
make check-nemu-systemd-guest-long

# 更重的 NEMU Ubuntu/systemd soak gate，默认 300s soak、
# 32MiB rootfs stress、256 个元数据文件、128 轮 fork/wait、1024 行 UART RX 突发输入
# 和 4 个 4MiB 并发 direct IO job，
# 用于改设备模型、timer/interrupt 或 rootfs 路径后的长稳态复验。
make check-nemu-systemd-guest-soak

# syscall probe 默认由 riscv64-linux-gnu-gcc 构建后经串口注入 guest。
# 缺交叉编译器时可指定 RISCV64_LINUX_GCC，或临时关闭：
NEMU_SYSTEMD_SYSCALL_PROBE=0 make check-nemu-systemd-guest

# 已闭合的 Ubuntu /bin/sh initramfs gate，必须显式选择。
make ARCH=riscv64-npc BOOT=ubuntu-shell run

# 轻量 Ubuntu os-release probe。
make ARCH=riscv64-npc BOOT=ubuntu-probe run

# 打印当前 ARCH/BOOT 对应资源路径。
make ARCH=riscv64-npc paths
make ARCH=riscv64-nemu paths

# 检查 ext4 rootfs 实物是否至少具备 /init、/bin/sh、os-release，并报告 systemd readiness。
make ARCH=riscv64-nemu check-ubuntu-rootfs

# 严格要求 systemd rootfs；当前 Ubuntu Base/fakeroot 镜像会在这里明确失败。
make ARCH=riscv64-nemu check-ubuntu-rootfs-systemd

# 无 sudo/debootstrap/qemu-user-static 时的过渡路线：用 apt + dpkg-deb 把
# systemd/udev/dbus 等 riscv64 deb 解包到 Ubuntu Base rootfs，形成可进入
# systemd gate 的候选镜像。它不能替代 debootstrap 二阶段配置结果。
make ARCH=riscv64-nemu ubuntu-rootfs-systemd-image

# 构建当前 BOOT 所需资源。
make ARCH=riscv64-npc prepare
make ARCH=riscv64-nemu prepare
```

等价别名：

```sh
make ARCH=riscv64-npc run-ubuntu-rootfs
make ARCH=riscv64-npc run-ubuntu-shell
make ARCH=riscv64-npc run-ubuntu-probe
make ARCH=riscv64-nemu run-ubuntu-rootfs
```

当前资源布局：

- `Linux/env/`：外部源码、下载缓存、OpenSBI/Linux/QEMU 构建产物、Ubuntu 镜像和日志。
- `Linux/build/`：DTB/DTS 等 Linux 启动相关中间产物。
- `Linux/scripts/`：OpenSBI/Linux/Ubuntu/QEMU 构建和运行脚本。
- `Linux/platform/`：平台 YAML 与 DTB 生成器。
- `Linux/configs/`：Linux boot/trace 用的 RV64 仿真器 profile。
- `Linux/tools/`：Linux bring-up 专用 focused gates、小 payload 和 Ubuntu init 源码。
- `npc/rv64/`：RV64 core RTL、testbench、Kconfig 和 Verilator 仿真本体。

UART 架构边界：NEMU 的 ttyS0 路线现在使用 opaque `Uart16550 *` 设备对象，公共头只暴露 config/ops/bus profile、FIFO room 和读写/service/receive API；寄存器、真实 16B RX FIFO 与 IRQ pending 状态由 `uart16550.c` 私有维护，1MiB host 输入 staging 属于 `SerialPort` 前端，前端按 `uart16550_rx_room()` 分批送入 core，SoC adapter 仍只负责映射、TX 与 PLIC IRQ1 接线。

验收口径仍按项目记忆分层：`ubuntu-shell` 只代表 initramfs 内官方 Ubuntu `/bin/sh -c` gate；`ubuntu-rootfs`、virtio-blk、Linux-visible display 和完整设备栈是独立 gate。当前 Ubuntu Base + fakeroot 产物可作为 shell/rootfs gate；需要 `systemd` gate 时，优先使用具备 sudo、`debootstrap` 与 `qemu-riscv64-static` 的环境重建，并用 `check-ubuntu-rootfs-systemd` 验证实物。若当前机器缺这些工具，可用 `ubuntu-rootfs-systemd-image` 生成 apt/dpkg-deb overlay 候选镜像继续调试 systemd 启动；当前 NEMU 已用该路线证明 ttyS0 root shell 与 systemd `running`，并可通过 `check-nemu-systemd-guest` 做 guest 内自动化回归。该回归还覆盖 systemd target 链、serial-getty@ttyS0、systemd manager API、journald、system bus/dbus、systemd-run transient service/timer、runtime unit reload request/start/output/status/cgroup/journal/cleanup（短 daemon-reload/SIGHUP 后用 unit start/output 证明 PID1 已加载，避免长轮询 `systemctl show`）、伪文件系统 fstype、udev/sysfs/virtio-blk 可见性、virtio modalias/status/feature 协商、基础 syscall 小电池、VM syscall（mremap/mprotect/madvise/mincore）、现代 FS syscall（statx/openat2/faccessat2/getdents64/renameat2/copy_file_range/close_range/linkat/fchmodat/utimensat/directory-fsync/fcntl record lock）、Unix socket fd 传递（SCM_RIGHTS）、pipe2/dup3、sendfile/splice 零拷贝路径、timer syscall（one-shot/periodic timerfd、setitimer、POSIX timer signal、relative/absolute sleep）、UART RX 命令突发、rootfs 元数据树压力、rootfs 压力写回、direct IO、`/dev/vda` 高 offset sha256 读回、并发 direct IO、timer、短时间 soak 和 guest 侧自然 poweroff；需要更重的长期运行证据时使用 `check-nemu-systemd-guest-soak`。`ARCH=riscv64-nemu` 的 rootfs 路线使用 NEMU 专用 `npc-rv64-nemu-rootfs.dtb`，额外暴露标准 `syscon-poweroff/syscon-reboot`，让 systemd -> kernel -> OpenSBI SRST -> NEMU `syscon-reset` 的关机链闭合。边界仍然有效：NEMU UART 已按公共 16550A core + bus profile + SerialPort host staging/front-end + SoC adapter + PLIC glue 重新架构，不再是旧 mini 串口；core 只建模真实 UART FIFO，host 脚本大缓冲在前端；当前 profile 对齐 DTS `ns16550a/reg-shift=0`，并已用 32-bit stride smoke 覆盖未来扩展边界。但 virtio-blk/UART/PLIC 仍是 Linux bring-up 功能模型，完整 virtio 特性、长期设备压力和 QEMU 级通用虚拟机不能由单次 systemd running/poweroff gate 代替。
