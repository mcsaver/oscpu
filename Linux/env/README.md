# RV64 Linux/Ubuntu 本地开发环境目录

本目录用于把 RV64 Linux/Ubuntu bring-up 所需的外部套件统一收进 ysyx-workbench，避免散落到 `/tmp` 或其它宿主路径。

默认布局：

- `src/opensbi/`：OpenSBI 源码
- `src/linux/`：Linux kernel 源码与构建产物
- `src/busybox-<version>/`：BusyBox 源码与静态 busybox
- `downloads/`：Linux、Ubuntu Base、BusyBox 等下载包和校验文件
- `build/opensbi-npc/`：OpenSBI for NPC 构建目录
- `images/initramfs/`：BusyBox initramfs
- `images/ubuntu2204/`：Ubuntu 22.04 rootfs/initramfs 镜像
- `tools/python/`：RV64 bring-up 脚本使用的本地 Python venv
- `tools/qemu/`：可选的本地 `qemu-system-riscv64` 安装目录
- `toolchains/`：可选的本地 RISC-V 交叉工具链目录
- `tmp/`：构建脚本的短生命周期临时文件
- `logs/`：Linux/Ubuntu smoke 日志

这些内容通常很大且可重新生成，因此默认被 `.gitignore` 忽略；仓库只跟踪脚本、配置和本说明。
如果本机已经有系统级 `riscv64-linux-gnu-*`、`dtc`、`verilator` 等基础命令，脚本会直接复用；若要把自带工具链也收进工作区，可放到 `toolchains/riscv64-linux-gnu/` 或 `toolchains/riscv/` 下，对应脚本会优先使用这里的前缀。

常用入口：

- `make -C Linux qemu-build`：把 QEMU riscv64-softmmu 构建/安装到 `tools/qemu/`
- `make -C Linux ARCH=riscv64-npc BOOT=ubuntu-shell run`：用 NPC/Verilator 启动 Ubuntu shell initramfs gate
- `make -C Linux ARCH=riscv64-nemu run`：用 NEMU 启动完整 Ubuntu rootfs 路线，默认 `MAX_CYCLES=0` 为无限预算
- `make -C Linux ARCH=riscv64-nemu check-ubuntu-rootfs`：检查 ext4 rootfs 实物并报告是否含 systemd 候选入口
- `make -C Linux ARCH=riscv64-nemu check-ubuntu-rootfs-systemd`：把 systemd 作为硬门槛；Ubuntu Base/fakeroot shell-only 镜像会明确失败
- `make -C Linux ARCH=riscv64-nemu ubuntu-rootfs-systemd-image`：无 sudo/debootstrap/qemu-user-static 时，用 apt 沙箱下载 jammy/riscv64 的 systemd 相关 deb 并解包进 rootfs，形成 systemd gate 候选镜像
- `make -C Linux check-nemu-systemd-guest`：启动 NEMU Ubuntu rootfs，在 guest 内检查 systemd running、systemd target 链、serial-getty@ttyS0、systemd manager API、journald、system bus/dbus、systemd-run transient service/timer/cgroup/journal、runtime unit reload request/start/output/status/cgroup/journal/cleanup、伪文件系统挂载与 fstype、udevd/udev settle、`/dev/hwrng`/virtio-rng、`/dev/rtc0`/goldfish-rtc、TTY/console、UART RX 命令突发、基础 shell syscall、riscv64 ELF syscall probe（含 mremap/mprotect/madvise/mincore、epoll/timerfd、periodic timerfd、ppoll/pselect、setitimer、POSIX timer signal、signalfd、pidfd/waitid、inotify、futex、prctl/getrandom、Unix socket SCM_RIGHTS、pipe2/dup3、sendfile/splice、statx/openat2/faccessat2/getdents64/renameat2/copy_file_range、close_range、linkat/fchmodat/utimensat/directory-fsync、fcntl record lock、relative/absolute sleep、PTY/termios/devpts/job-control 等 systemd/tty 常用机制）、timer、`/dev/vda` 容量/逻辑与物理块大小、discard/write-zeroes queue limit、serial/GET_ID、sysfs driver、virtio modalias/status/feature 协商（含 BLK_SIZE/FLUSH/DISCARD/WRITE_ZEROES/INDIRECT/EVENT_IDX/VERSION_1 和 RNG device id 4）、udev properties、`/dev/disk` symlink、`/proc/interrupts` 中 ttyS0/virtio/riscv-timer 可见性、virtio-blk direct read 后 IRQ 增长、direct block read、高 offset sha256 读回、rootfs direct IO、4 个并发 direct IO job、rootfs 元数据树压力、rootfs 压力写回、短 soak 和 guest 自然 poweroff，并生成含 `poweroff_seconds`、`fs_tree_files` 与 `uart_rx_stress_lines` 的 `perf.tsv`。DISCARD/WRITE_ZEROES gate 只检查 Linux-visible queue limit 与 feature bit，不在已挂载 rootfs 上执行破坏性擦除命令。runtime unit reload 使用短 `daemon-reload`/PID1 `SIGHUP` 发起 reload，再以 runtime unit start/output 证明 PID1 已加载，避免长轮询 `systemctl show`。默认 gate 预算为 `NEMU_SYSTEMD_CHECK_MAX_CYCLES=25000000000`；syscall probe 默认使用 `riscv64-linux-gnu-gcc` 构建，可用 `RISCV64_LINUX_GCC=...` 覆盖或 `NEMU_SYSTEMD_SYSCALL_PROBE=0` 临时关闭
- `make -C Linux check-nemu-performance-config`：确认 NEMU 默认 Ubuntu gate 使用 `CONFIG_PERFORMANCE=y`，并拒绝 trace、difftest、watchpoint、BPU/统计、ASAN、runtime check 和 RISC-V debug log 漏开；调试 trace 时可显式传 `NEMU_DEFCONFIG=riscv64-linux_debug_defconfig NEMU_PERFORMANCE_REQUIRED=0`
- `make -C Linux check-nemu-systemd-guest-long`：启动同一套 NEMU Ubuntu rootfs，默认跑 120s soak、16MiB rootfs stress、128 个元数据文件、64 轮进程循环、768 行 UART RX 突发和 4 个 2MiB 并发 direct IO job，生成独立 `perf.tsv`，适合作为长稳态 gate
- `make -C Linux check-nemu-systemd-guest-soak`：启动同一套 NEMU Ubuntu rootfs，默认跑 300s soak、32MiB rootfs stress、256 个元数据文件、128 轮进程循环、1024 行 UART RX 突发和 4 个 4MiB 并发 direct IO job，生成独立 `perf.tsv`，适合作为设备模型或 timer/interrupt 改动后的重型稳态 gate
- `make -C Linux qemu-ubuntu-shell`：用本地 QEMU 启动同一份 Ubuntu 22.04 shell initramfs，作为 NPC RTL bring-up 的参考路径

NEMU UART 维护口径：当前 ttyS0 使用 opaque `Uart16550 *` 设备对象，公共头不再暴露 FIFO 或寄存器影子布局；`uart16550` core 只保留真实 16B RX FIFO 与寄存器/IRQ 语义，host 脚本输入的大 staging 和 4KiB 串口 TX 宿主缓冲都放在 `SerialPort` 前端，再按 `uart16550_rx_room()` 分批送入 core，TX 按行、按块或设备轮询 flush 到 stderr；SoC adapter 只做 MMIO/PIO 映射、TX 和 PLIC IRQ1 接线。

NEMU performance 维护口径：当前 Ubuntu performance 配置关闭 cache/MTRACE 后，虚拟地址层对已翻译且落在 PMEM 的访问使用 `vaddr.c` direct host-buffer fast path；Sv39 TLB entry 同时缓存可选 `host_page`，并分离取指 iTLB 与数据 dTLB，让 TLB 命中路径直接得到 `trans.host_addr`，减少 RAM 访问继续进入 paddr/MMIO 分发链的开销。解释器层已启用保守 basic-block/TB 边界批执行：普通连续指令最多按 16 条聚成一块，branch/jump、SYSTEM/CSR/WFI/sret/mret/sfence.vma、fence、store/AMO 或压缩控制/存储指令都会立即收束，设备轮询用 `device_update_after_inst()` 按退休 guest 指令数维持原节流口径。RVC wide ifetch 在同页 PMEM host pointer 命中时一次读取 4 字节，并按低 2 bit 判断 16-bit/32-bit 指令长度；跨页、MMIO 或 fault 仍走旧精确路径。解释器预译码 cache 会缓存 `PC + raw-inst` 对应的分发类别、寄存器号和立即数，命中前仍真实取指并比对原始指令，`fence.i` 会清空缓存。TB 边界中断 fast flag 会先用 CSR enable/global、CLINT pending 与 PLIC raw pending 做保守判断，确定无可投递中断时跳过完整 `isa_query_intr()`。设备/MMIO 访问仍由 paddr 层处理，不改变 Linux 可见平台设备；这仍不是完整 TB cache、物理代码页失效体系或 DBT。

当前无免密 sudo、`debootstrap` 或 `qemu-riscv64-static` 时，`build-ubuntu-rootfs.sh` 会回退到 Ubuntu Base + fakeroot 路线；若要生成完整 systemd rootfs，可在具备这些工具的环境中设置 `UBUNTU_ROOTFS_REQUIRE_SYSTEMD=1` 后重建，脚本会在无法满足 systemd 路线时直接失败。若只是继续推进 NEMU 的 systemd 启动调试，可用 `UBUNTU_ROOTFS_SYSTEMD_OVERLAY=1` 或 `ubuntu-rootfs-systemd-image` 生成 chrootless overlay 候选镜像；当前 NEMU 已有运行证据证明该候选镜像可进入 ttyS0 root shell 且 systemd 为 `running`，`check-nemu-systemd-guest` 还能自动覆盖 systemd target 链、serial-getty、journal/dbus、transient unit/timer、runtime unit reload request/start/output/status/cgroup/journal/cleanup、syscall、udev/sysfs/virtio-blk、`/dev/hwrng`/virtio-rng、`/dev/rtc0`/goldfish-rtc 与 `/proc/interrupts` 中 ttyS0/virtio/riscv-timer 可见性、virtio-blk IRQ 增长、discard/write-zeroes queue limit、rootfs 元数据树压力、rootfs 压力写回、direct IO、并发 direct IO、timer、短 soak 和 `systemctl poweroff` 到 NEMU GOOD TRAP 的自然关机链路；runtime reload 采用短 `daemon-reload`/PID1 `SIGHUP` 后用 unit start/output 证明收敛，不再把 D-Bus `show` 长轮询放在热等待路径中。`check-nemu-systemd-guest-soak` 则提供更重的 300s 稳态验收。NEMU UART 当前按公共 16550A core、bus profile、`SerialPort` host staging/TX buffering/front-end、SoC adapter 和 PLIC IRQ1 glue 分层维护；当前 Linux DTS 路线使用 `reg-shift=0/io-width=1`，standalone smoke 另覆盖 32-bit stride profile，NEMU rootfs DTB 另含标准 syscon-poweroff/reboot 节点、NEMU 专用 `virtio_rng0` 节点和 `RTC0: google,goldfish-rtc` 节点；后续仍需用更长时间窗口和更强 virtio/TTY/interrupt 压力测试补足 QEMU 级设备完整性证据。
