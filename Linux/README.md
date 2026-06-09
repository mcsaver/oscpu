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
# systemd-run transient service/timer/cgroup/journal、runtime unit reload request/start/output/status/cgroup/journal/cleanup、伪文件系统挂载、udev/sysfs、
# /dev/hwrng/virtio-rng、/dev/rtc0/goldfish-rtc、1GiB MemTotal、virtio-net/eth0 可见性与 hostless DHCP/DNS/TCP burst/ARP/ICMP echo、tty/console、基础 shell syscall、riscv64 ELF syscall probe（含 mremap/mprotect、madvise/mincore、
# epoll/timerfd、
# periodic timerfd、ppoll/pselect、setitimer、POSIX timer signal、signalfd、pidfd/waitid、inotify、futex、prctl/getrandom、
# Unix socket SCM_RIGHTS、pipe2/dup3、sendfile/splice、
# faccessat2/getdents64/fcntl record lock、linkat/fchmodat/utimensat/directory-fsync、
# PTY/termios/devpts/job-control 等 systemd/tty 常用机制）、timer sleep、absolute clock_nanosleep、
# /dev/vda 容量/逻辑与物理块大小、discard/write-zeroes queue limit、serial/GET_ID、virtio modalias/status/feature 协商（含 BLK_SIZE/FLUSH/DISCARD/WRITE_ZEROES/INDIRECT/EVENT_IDX/VERSION_1）、
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

# 不启动 guest，导出当前 NEMU 二进制的机器/设备清单。
# 该清单用于确认 B/E/cache、CLINT timebase/CSR time source、1GiB memory
# 和 UART/virtio/syscon MMIO/IRQ 是否被实际纳入生产 gate。
make ARCH=riscv64-nemu nemu-machine-info

# 不启动 guest，但真实打开 Ubuntu ext4 rootfs block 镜像。
# 用于确认 virtio-blk device id、容量、sector 数和只读状态没有漂移。
make ARCH=riscv64-nemu nemu-rootfs-machine-info

# NEMU RV64A 精确异常 smoke：不启动 Linux，验证有效 AMO/LR/SC 非对齐
# 必须投递 load/store address-misaligned trap，而不是 illegal instruction。
make -C tools smoke-nemu-amo-misaligned

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

UART 架构边界：NEMU 的 ttyS0 路线现在使用 opaque `Uart16550 *` 设备对象，公共头只暴露 config/ops/bus profile、FIFO room 和读写/service/receive API；寄存器、真实 16B RX FIFO 与 IRQ pending 状态由 `uart16550.c` 私有维护，1MiB host 输入 staging 和 4KiB 串口 TX 宿主缓冲属于 `SerialPort` 前端，前端按 `uart16550_rx_room()` 分批送入 core，TX 缓冲按行、按块或设备轮询 flush 到 stderr，SoC adapter 仍只负责映射、TX 与 PLIC IRQ1 接线。

串口输入链路：你在宿主终端手动键入或自动化脚本写入的内容都只是字节流，不是直接传给 Ubuntu 的 shell 命令对象。手动路径通常是 host terminal/stdin -> NEMU `serial.c` host input poll -> `SerialPort` staging -> `uart16550_receive()` -> 16550 RX FIFO -> Linux `8250/ns16550a` 驱动 -> `/dev/ttyS0` -> `serial-getty`/login -> bash；focused gate 路径把 stdin 换成 `NEMU_SERIAL_FIFO`，并用 `NEMU_SYSTEMD_INPUT_CHUNK_BYTES` 分块写入。若人工粘贴太快看到 `hostnamectllsb_release` 或 `topfree` 这类命令粘连，优先按真实串口过载/交互时序问题处理：逐行输入、降低粘贴速度，或走 `check-nemu-systemd-guest` 的 base64 上传 + sha256 校验脚本路径，而不是先怀疑 Ubuntu 不识别命令。

Ubuntu 常用命令边界：当前 rootfs 是 minimized Ubuntu 22.04，不会默认带所有交互便利包。systemd rootfs 默认包清单包含 `procps`、`systemd`、`util-linux` 和 `lsb-release`，因此 `free`、`top`、`uptime`、`systemctl`、`hostnamectl` 与 `lsb_release` 属于应被生产 gate 保护的基础可见能力；`htop` 仍是可选交互工具，需要网络/apt 可用时按需安装，不作为启动正确性 hard gate。

DTS ISA 边界：`Linux/platform/gen_dts.py` 现在同时输出兼容旧内核的 `riscv,isa = "rv64imafdc_zicsr_zifencei"`，以及 Linux 现代 binding 使用的 `riscv,isa-base = "rv64i"` 和 `riscv,isa-extensions = "i", "m", "a", "f", "d", "c", "zicsr", "zifencei"`。这样当前内核不再需要回退到 deprecated `riscv,isa` 解析；DTS 没有声明 B/Zba/Zbb/Zbc/Zbs，因为当前 NEMU Ubuntu defconfig 没有把 B 扩展作为 Linux 平台能力暴露。

NEMU 机器清单边界：`make ARCH=riscv64-nemu nemu-machine-info` 会运行当前 NEMU 二进制的 `--machine-info`，在不开 guest 的情况下导出 ISA/engine/performance、B/E/cache 状态、CLINT 10MHz timebase、`time/timeh` CSR source、1GiB memory、boot 参数、UART/virtio-blk/virtio-rng/goldfish-rtc/virtio-net/syscon 的 MMIO/IRQ、QMP `startup-query-cont-stop-runtime-query` 边界、实际注册的 MMIO/PIO map，以及无镜像时 virtio-blk `detached/device_id=0/capacity=0`。`make ARCH=riscv64-nemu nemu-rootfs-machine-info` 会先验证 systemd rootfs 实物，再真实打开 Ubuntu ext4 镜像并导出 `attached/device_id=2/capacity/readonly`。`nemu-ubuntu` e2e 会检查这些条目，防止 menuconfig、DTB、设备注册表、CLINT/CSR time 和 rootfs block 后端漂移。该清单只是非交互 introspection，不是完整 GDB stub、完整 QMP 命令集、snapshot/checkpoint、热插拔能力或 wall-clock time model。

NEMU 精确异常边界：`make -C tools smoke-nemu-amo-misaligned` 会在真实 NEMU 上运行一个裸机 RV64A payload，分别触发 `lr.w/sc.w/amoadd.w/lr.d/sc.d/amoadd.d` 非对齐访问，并在 trap handler 中校验 `mcause/mtval` 后通过 syscon poweroff 产生 `HIT GOOD TRAP`。该 smoke 用来防止有效 AMO/LR/SC 又退化成 illegal instruction；它不声明跨页 AMO、LR/SC 多核 reservation、SMP memory model 或普通 misaligned load/store 全矩阵完成。

性能边界：NEMU Ubuntu performance 配置关闭 cache/MTRACE 后，`vaddr.c` 会在虚拟地址翻译完成且物理地址落入 PMEM 时使用 `host_read/host_write(trans.host_addr)` 访问宿主内存；Sv39 TLB entry 同步缓存可选 `host_page`，并将取指 iTLB 与数据 dTLB 分离，减少 instruction fetch 和 load/store 翻译互相驱逐。解释器层新增保守 basic-block/TB 边界批执行：普通连续指令最多按 16 条聚成一块，中断查询与设备轮询移到块边界；遇到 branch/jump、SYSTEM/CSR/WFI/sret/mret/sfence.vma、fence、store/AMO 或压缩控制/存储指令立即收束，`device_update_after_inst()` 继续按退休 guest 指令数维持原 64 指令节流口径。RVC wide ifetch 在同页 PMEM host pointer 命中时一次读取 4 字节，用低 2 bit 决定 16-bit/32-bit 指令长度，减少压缩指令路径重复 vaddr/MMU/TLB 取指；跨页、MMIO 或 fault 仍回退旧精确路径。解释器 decode cache 会缓存 `PC + raw-inst` 对应的预译码分发类别、寄存器号和立即数，命中时仍先真实取指并比对原始指令，`fence.i` 会清空缓存。TB 边界中断 fast flag 会在进入完整 `isa_query_intr()` 前先用 CSR enable/global、CLINT pending 和 PLIC raw pending 做保守判定，只有存在可能可投递中断时才走完整 pending 计算。`time/timeh` CSR 现在读取 CLINT `mtime`，CLINT timebase 为 10MHz；当前 CLINT source 仍是 instruction-driven，用于维持慢解释器下 timer/systemd gate 的稳定性。virtio-blk 数据描述符若落在 guest PMEM，`disk.c` 会把 `guest_to_host()` 后的 host buffer 直接交给 `disk_pread_all()`/`disk_pwrite_all()`，避免 4KiB 临时栈缓冲和 `pmem_read/write` 拷贝；越界、跨非 PMEM 或无法直接映射时仍回退旧分块路径，write-through sync 语义保持不变。非 PMEM/MMIO 页仍回落 `paddr_read/write`，因此 UART、virtio、PLIC、CLINT、syscon 等设备语义不变。该切片是 RAM fast path + host-page TLB + iTLB/dTLB 分离 + 保守 TB 批执行 + RVC wide ifetch + 保守预译码 cache + 中断 fast flag + CSR time 读 CLINT mtime + virtio-blk direct guest-buffer I/O，不等同于完整 TB cache、物理代码页失效体系、wall-clock CLINT、异步 block I/O 或 DBT/JIT。

验收口径仍按项目记忆分层：`ubuntu-shell` 只代表 initramfs 内官方 Ubuntu `/bin/sh -c` gate；`ubuntu-rootfs`、virtio-blk、Linux-visible display 和完整设备栈是独立 gate。当前 Ubuntu Base + fakeroot 产物可作为 shell/rootfs gate；需要 `systemd` gate 时，优先使用具备 sudo、`debootstrap` 与 `qemu-riscv64-static` 的环境重建，并用 `check-ubuntu-rootfs-systemd` 验证实物。若当前机器缺这些工具，可用 `ubuntu-rootfs-systemd-image` 生成 apt/dpkg-deb overlay 候选镜像继续调试 systemd 启动；当前 NEMU 已用该路线证明 ttyS0 root shell 与 systemd `running`，并可通过 `check-nemu-systemd-guest` 做 guest 内自动化回归。该回归还覆盖 systemd target 链、serial-getty@ttyS0、systemd manager API、journald、system bus/dbus、systemd-run transient service/timer、runtime unit reload request/start/output/status/cgroup/journal/cleanup（短 daemon-reload/SIGHUP 后用 unit start/output 证明 PID1 已加载，避免长轮询 `systemctl show`）、伪文件系统 fstype、udev/sysfs/virtio-blk、`/dev/hwrng`/virtio-rng、`/dev/rtc0`/goldfish-rtc、1GiB MemTotal、virtio-net `eth0`/MAC 可见性、hostless DHCP offer/ack、hostless DNS A 记录、hostless TCP burst health check、静态 IPv4 fallback、hostless ARP/ICMP echo、virtio modalias/status/feature 协商（含 DISCARD/WRITE_ZEROES/EVENT_IDX）、基础 syscall 小电池、VM syscall（mremap/mprotect/madvise/mincore）、现代 FS syscall（statx/openat2/faccessat2/getdents64/renameat2/copy_file_range/close_range/linkat/fchmodat/utimensat/directory-fsync/fcntl record lock）、Unix socket fd 传递（SCM_RIGHTS）、pipe2/dup3、sendfile/splice 零拷贝路径、timer syscall（one-shot/periodic timerfd、setitimer、POSIX timer signal、relative/absolute sleep）、UART RX 命令突发、rootfs 元数据树压力、rootfs 压力写回、direct IO、`/dev/vda` 高 offset sha256 读回、并发 direct IO、timer、短时间 soak 和 guest 侧自然 poweroff；需要更重的长期运行证据时使用 `check-nemu-systemd-guest-soak`。`ARCH=riscv64-nemu` 的 rootfs 路线使用 NEMU 专用 `npc-rv64-nemu-rootfs.dtb`，DTB memory 与 NEMU `CONFIG_MSIZE` 对齐为 1GiB，并额外暴露标准 `syscon-poweroff/syscon-reboot`、`virtio_rng0`、`virtio_net0` 与 `RTC0: google,goldfish-rtc`，让 systemd -> kernel -> OpenSBI SRST -> NEMU `syscon-reset` 的关机链闭合，让 Linux 运行期 hwrng 走 virtio-rng 设备路径，让 virtio_net driver 枚举一个固定 MAC 的接口，并通过内置 `10.0.2.2` DHCP/DNS/TCP/ARP/ICMP responder 验证最小 TX/RX 数据路径，让系统时钟从 RTC 设备初始化。边界仍然有效：NEMU UART 已按公共 16550A core + bus profile + SerialPort host staging/front-end + SoC adapter + PLIC glue 重新架构，不再是旧 mini 串口；core 只建模真实 UART FIFO，host 脚本大缓冲在前端；virtio-net 当前支持固定 `10.0.2.2` hostless DHCP lease、`nemu.local` DNS A 记录、`/nemu-health` TCP/HTTP 204 burst 健康检查、ARP/ICMP echo，用于证明最小 TX/RX 数据路径；仍没有 TAP/NAT/外网收发后端；virtio-blk 的 DISCARD/WRITE_ZEROES gate 只检查 Linux-visible queue limit 与 feature bit，不在已挂载 rootfs 上执行破坏性擦除命令。当前 profile 对齐 DTS `ns16550a/reg-shift=0`，并已用 32-bit stride smoke 覆盖未来扩展边界。但 virtio-blk/virtio-rng/virtio-net/goldfish-rtc/UART/PLIC 仍是 Linux bring-up 功能模型，完整 virtio 特性、长期设备压力和 QEMU 级通用虚拟机不能由单次 systemd running/poweroff gate 代替。
