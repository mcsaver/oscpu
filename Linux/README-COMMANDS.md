# Linux 命令与默认行为手册

本手册是 `Linux/Makefile` 的用户入口说明，回答三件事：

1. 一条命令实际会选择 NPC 还是 NEMU；
2. 它会使用串口、可见 SDL 窗口，还是后台 Xvfb；
3. 它会构建、运行、验证或删除哪些产物。

简明总览见 [README.md](README.md)，环境目录布局见
[env/README.md](env/README.md)。目标和变量的最终事实来源是
[Makefile](Makefile)；文档与实现有冲突时，以 Makefile 为准并同步修正文档。

## 1. 命令应该在哪里执行

从仓库根目录进入本目录后执行：

```sh
cd Linux
make help
```

如果当前位于仓库根目录，把每条命令的 `make` 改为 `make -C Linux`：

```sh
# Linux/ 内
make ARCH=riscv64-nemu run

# 仓库根目录内，语义完全相同
make -C Linux ARCH=riscv64-nemu run
```

Make 变量可以放在目标前后。为了便于复制和审查，本手册统一写成
`make VAR=value target`。

## 2. 三十秒速查

| 想做什么 | 命令 | 能看到什么 |
| --- | --- | --- |
| 不确定目标 | `make` 或 `make help` | 只打印帮助，不构建、不启动 |
| 查看本次选择 | `make ARCH=riscv64-nemu paths` | 打印解析后的平台、镜像、模拟器、日志和 overlay 路径 |
| NPC 启动 Ubuntu | `make ARCH=riscv64-npc run` | 当前终端中的串口控制台 |
| NEMU 无图形启动 Ubuntu | `make ARCH=riscv64-nemu run` | 当前终端中的 `ttyS0`；不会打开 SDL |
| NEMU 可见图形启动 Ubuntu | `make run-ubuntu-gui` | 当前终端 `ttyS0` + SDL 窗口 `tty1` |
| 自动验证 GUI | `make check-nemu-gui` | Xvfb 内自动运行；通常没有可见窗口，结果在日志和截图中 |
| 验证 NEMU systemd | `make check-nemu-systemd-guest` | 自动串口 gate，完成后自然关机 |
| 跑当前 NEMU 演进聚合 | `make check-nemu-evolution` | block、reboot、systemd、持久化四组 gate |
| 仅准备当前启动资源 | `make ARCH=riscv64-nemu prepare` | 构建，不启动 guest |
| 检查已有产物 | `make ARCH=riscv64-nemu check` | 只检查当前组合的实物，不补建 |
| 清 NEMU 前端构建目录 | `make ARCH=riscv64-nemu clean` | 只删除本次解析出的 `BUILD_DIR` |
| 清 NEMU 日志 | `make ARCH=riscv64-nemu clean-logs` | 删除 NEMU 的 Linux 前端 `LOG_ROOT`；不传 ARCH 会清 NPC 前端日志 |

## 3. 最重要的默认契约

裸 `make` 的默认目标是 `help`。裸 `make run` 才会运行，而且它等价于：

```sh
make ARCH=riscv64-npc BOOT=ubuntu-rootfs run
```

| 项目 | 默认值 | 影响 |
| --- | --- | --- |
| 默认目标 | `help` | 裸 `make` 不会构建或启动 |
| `ARCH` | `riscv64-npc` | 默认选择 NPC RV64 Verilator |
| `BOOT` | `ubuntu-rootfs` | 默认选择完整 Ubuntu ext4 rootfs |
| `LINUX_FEATURE_PROFILE` | `headless` | 普通 Linux 内核不启用 FB/VT 图形控制台 |
| `NEMU_DEFCONFIG` | `riscv64-linux_defconfig` | 普通 NEMU 构建不含 VGA/SDL |
| `NEMU_DISPLAY` | `0` | 普通 DTB 不启用 simplefb/virtio-input GUI 节点 |
| `NEMU_VIRTIO_INPUT` | 跟随 `NEMU_DISPLAY` | 普通 headless 路线默认关闭键盘设备 |
| NEMU `MAX_CYCLES` | `0` | 无限指令预算，直到关机、重启或人为终止 |
| NPC `MAX_CYCLES` | `3000000000` | NPC 的默认仿真预算 |
| `PROGRESS` | `50000000` | NPC 默认进度输出间隔 |
| `JOBS` | 宿主 `nproc` | Linux/OpenSBI 等构建并行度 |
| `EXTRA_ARGS` | 空 | 追加给模拟器的命令行参数 |
| `BOOTARGS_EXTRA` | 空 | 追加给 Linux bootargs |
| `NEMU_RUN_ROOTFS_OVERLAY_RESET` | `1` | 普通 NEMU rootfs 每次新命令默认重置运行 overlay |
| `NEMU_RUN_MAX_BOOTS` | `2` | 一次 `run` 最多允许 boot1 + 一次 reboot |
| Ubuntu | jammy / 22.04.5 / riscv64 | rootfs 下载和构建基线 |
| Linux | 6.6 | 内核源码基线 |
| OpenSBI | 1.8 | 固件源码基线 |
| rootfs flavor | `systemd-minimal` | 普通 Ubuntu/systemd 路线的用户态基线 |

平台默认值来自
[scripts/platform/npc.mk](scripts/platform/npc.mk) 和
[scripts/platform/nemu.mk](scripts/platform/nemu.mk)。普通 NEMU 配置见
[../nemu/configs/riscv64-linux_defconfig](../nemu/configs/riscv64-linux_defconfig)，
GUI 配置见
[../nemu/configs/riscv64-linux-gui_defconfig](../nemu/configs/riscv64-linux-gui_defconfig)。

### `ARCH` 的有效值

| 值 | 用途 |
| --- | --- |
| `riscv64-npc` | 本工程 NPC RV64 RTL/Verilator 平台 |
| `riscv64-nemu` | NEMU RV64 Linux 参考平台 |

不要把 `ARCH=riscv64-nemu` 理解为“启用图形”。它只选择平台。

### `BOOT` 的有效值

| 值 | 启动内容 | 典型用途 |
| --- | --- | --- |
| `ubuntu-rootfs` | OpenSBI + Linux + DTB + Ubuntu ext4/virtio-blk | 默认完整系统 |
| `ubuntu-shell` | Ubuntu shell initramfs | 轻量 shell bring-up |
| `ubuntu-probe` | Ubuntu os-release probe initramfs | 快速用户态探测 |
| `busybox-initramfs` | BusyBox initramfs | 最小 Linux bring-up |
| `kernel` | OpenSBI + Linux + DTB，不挂 rootfs/initrd | 只观察内核早期启动 |

## 4. 为什么普通 NEMU `run` 没有 VGA

这条命令有意走 headless profile：

```sh
make ARCH=riscv64-nemu run
```

它使用 `riscv64-linux_defconfig`、`LINUX_FEATURE_PROFILE=headless` 和
`NEMU_DISPLAY=0`，所以交互位置是当前终端里的 `ttyS0`
（字母 `S`、数字 `0`），不会创建 SDL 窗口。

可见图形入口是：

```sh
make run-ubuntu-gui
```

这个 wrapper 会作为一个整体切换：

- `ARCH=riscv64-nemu` 与 `BOOT=ubuntu-rootfs`；
- NEMU GUI defconfig、独立 NEMU 配置目录和构建目录；
- Linux `display` profile、独立内核 `O=` 目录；
- `NEMU_DISPLAY=1`、simple-framebuffer 与标准 virtio-input；
- 含 `tty1` root autologin 契约的独立 GUI rootfs/overlay；
- 独立 OpenSBI、DTB、日志和截图路径。

因此不要在普通命令后只追加 `NEMU_DISPLAY=1`。它不足以同步切换 NEMU
Kconfig、Linux Kconfig、rootfs 与隔离产物，可能产生“DTB 宣称有设备、实际
模拟器没有”或“有 framebuffer、内核没有 fbcon”的不一致组合。

GUI 正常时同时存在两个控制台：

| 位置 | guest 控制台 | 作用 |
| --- | --- | --- |
| 启动 `make` 的终端 | `ttyS0` | 启动日志、调试和恢复通道 |
| SDL 800×600 窗口 | `tty1` / fbcon | 屏幕与键盘交互 |

这里的“GUI”是 NEMU 简易 VGA framebuffer 上的 Linux 文本控制台：
simplefb/fbcon 负责显示，virtio-input 负责键盘。它不是桌面 Ubuntu、DRM
`virtio-gpu`、3D 图形或 GPU 加速环境。

终端仍输出串口日志并不表示 VGA 没启动。NEMU 参数 `-b` 只是关闭交互式
SDB 提示符，不会关闭 SDL。bootargs 中出现 `console=tty0` 也不等于显示设备
已经编译和启用。

`make check-nemu-gui` 是自动化 gate：它在 Xvfb 中启动 GUI，验证
framebuffer、fbcon/tty1、SDL 画面和宿主按键到 virtio-input 再到 guest 的闭环，
并保存截图。因此它通常不会弹出肉眼可见窗口。想亲自操作屏幕应使用
`make run-ubuntu-gui`。

## 5. 启动命令

### 通用 `run`

```sh
make ARCH=<平台> BOOT=<启动场景> run
```

`run` 会先构建当前组合缺少或过期的依赖，再启动对应模拟器并用 `tee`
保存控制台日志。NEMU rootfs 路线会通过 wrapper 识别 guest 生命周期：

- poweroff：正常退出；
- reboot：NEMU 返回专用状态 32，wrapper 启动一个新的 NEMU 进程；
- 其他非零状态：命令失败；
- 默认最多两次启动，可用 `NEMU_RUN_MAX_BOOTS` 覆盖。

常用示例：

```sh
make ARCH=riscv64-npc BOOT=ubuntu-rootfs run
make ARCH=riscv64-nemu BOOT=ubuntu-rootfs run
make ARCH=riscv64-npc BOOT=ubuntu-shell run
make ARCH=riscv64-nemu BOOT=busybox-initramfs run
```

### 启动别名

以下目标只替你设置 `BOOT`，`ARCH` 仍继承命令行或默认值：

| 目标 | 等价场景 |
| --- | --- |
| `run-ubuntu-rootfs` | `BOOT=ubuntu-rootfs run` |
| `run-ubuntu-shell` | `BOOT=ubuntu-shell run` |
| `run-ubuntu-probe` | `BOOT=ubuntu-probe run` |
| `run-busybox-initramfs` | `BOOT=busybox-initramfs run` |
| `run-kernel` | `BOOT=kernel run` |

例如 `make run-ubuntu-shell` 默认仍使用 NPC；若要 NEMU，必须写：

```sh
make ARCH=riscv64-nemu run-ubuntu-shell
```

`run-ubuntu-gui` 不是普通别名。它是固定选择 NEMU 并切换整套 GUI 隔离
profile 的专用 wrapper。

## 6. 准备与构建目标

| 目标 | 用法和边界 |
| --- | --- |
| `setup-env` | 准备本地依赖、源码和下载缓存；首次环境初始化时使用，可能访问网络 |
| `prepare` | 只构建当前 `ARCH + BOOT` 的 `run` 依赖，不启动 |
| `prepare-all` | 构建当前 `ARCH` 的所有 headless 启动资源；不包含 GUI、interactive/full rootfs 或长时间回归 |
| `linux-defconfig` | 同步 NPC RTL/仿真使用的 Linux 相关 defconfig 状态 |
| `linux-trace-defconfig` | 切换 NPC 的 trace 配置；用于调试，不是性能回归配置 |
| `nemu-linux-defconfig` | 把 `NEMU_DEFCONFIG` 同步到 `NEMU_CONFIG_DIR`；普通运行默认是 `nemu/`，GUI wrapper 才会注入隔离配置目录；应带 `ARCH=riscv64-nemu` |
| `sim` | 构建当前平台模拟器 |
| `check-sim` | 检查/补建当前平台模拟器，防止配置变化后复用旧二进制 |
| `linux-image` | 构建当前平台/profile 的 Linux `Image` |
| `busybox-initramfs` | 构建 BusyBox initramfs |
| `ubuntu-probe-initramfs` | 构建 Ubuntu probe initramfs |
| `ubuntu-shell-initramfs` | 构建 Ubuntu shell initramfs |
| `ubuntu-rootfs-image` | 构建默认 Ubuntu ext4 rootfs 及配套 rootfs cpio |
| `dtb` | 构建 kernel-only DTB |
| `initramfs-dtb` | 构建 BusyBox initramfs DTB |
| `ubuntu-initramfs-dtb` | 构建 Ubuntu probe DTB |
| `ubuntu-shell-initramfs-dtb` | 构建 Ubuntu shell DTB |
| `rootfs-dtb` | 构建 Ubuntu rootfs/virtio-blk DTB |
| `opensbi` | 构建 kernel-only OpenSBI 固件 |
| `opensbi-busybox` | 构建 BusyBox 启动固件 |
| `opensbi-ubuntu-probe` | 构建 Ubuntu probe 启动固件 |
| `opensbi-ubuntu-shell` | 构建 Ubuntu shell 启动固件 |
| `opensbi-rootfs` | 构建 Ubuntu rootfs 启动固件 |

常用方式：

```sh
# 只准备 NEMU 完整 Ubuntu 启动所需实物
make ARCH=riscv64-nemu BOOT=ubuntu-rootfs prepare

# 只构建 NEMU 模拟器
make ARCH=riscv64-nemu sim

# 先确认最终写到哪里
make ARCH=riscv64-nemu BOOT=ubuntu-rootfs paths
```

NEMU 与 NPC 共享下载缓存和源码，但 Linux `O=`、OpenSBI、镜像、日志等默认
分别写入 `Linux/env/platforms/nemu/` 和 `Linux/env/platforms/npc/`。
GUI 入口又在 NEMU 平台内使用独立路径，避免 headless/GUI 配置互相覆盖。

## 7. Ubuntu rootfs 目标

### 构建 flavor

| 目标 | 结果 |
| --- | --- |
| `ubuntu-rootfs-image` | 默认 systemd-minimal Ubuntu ext4 及配套 cpio |
| `ubuntu-rootfs-systemd-image` | 构建 systemd-minimal 候选 ext4 及配套 cpio |
| `ubuntu-rootfs-systemd-overlay` | `systemd-image` 的兼容入口；它会走同一完整配方，不是“仅修改现有镜像”的轻量命令 |
| `ubuntu-rootfs-systemd-strict-image` | 构建独立严格验证 ext4/cpio，由 systemd one-shot 完成检查和关机 |
| `ubuntu-rootfs-interactive-image` | 独立 interactive ext4/cpio，加入串口调试常用工具，默认 ext4 为 4 GiB |
| `ubuntu-rootfs-full-image` | 独立 full/server-like ext4/cpio，加入更多服务和管理工具，默认 ext4 为 8 GiB |
| `ubuntu-rootfs-flavors-check` | 只检查 flavor manifest 一致性，不下载、不重建镜像 |

`full` 仍不是桌面 Ubuntu；它也不自动证明 SMP、PCI、外网、快照或 QEMU
等价能力。

### 检查 flavor

| 目标 | 检查对象 |
| --- | --- |
| `check-ubuntu-rootfs` | 当前 `UBUNTU_ROOTFS_IMAGE` 的基本实物和 systemd readiness；其前置依赖可能在产物缺失时构建默认 ext4/cpio |
| `ubuntu-rootfs-check` | `check-ubuntu-rootfs` 的兼容别名 |
| `check-ubuntu-rootfs-systemd` | systemd-minimal 硬门槛；失败时会重建后复查 |
| `check-ubuntu-rootfs-systemd-minimal` | 上一目标的兼容别名 |
| `check-ubuntu-rootfs-systemd-strict` | strict 镜像；失败时重建后复查 |
| `check-ubuntu-rootfs-interactive` | interactive 镜像；失败时重建后复查 |
| `check-ubuntu-rootfs-full` | full 镜像；失败时重建后复查 |

例如：

```sh
make ARCH=riscv64-nemu ubuntu-rootfs-full-image
make ARCH=riscv64-nemu check-ubuntu-rootfs-full
```

## 8. GUI、设备与 CPU 专项验证

| 目标 | 验证范围 | 是否弹可见窗口 |
| --- | --- | --- |
| `check-nemu-gui` | 配置、simplefb/fbcon/tty1、SDL 画面、virtio-input、按键闭环和关机 | 通常否，使用 Xvfb |
| `check-nemu-gui-config` | NEMU/DT/Linux GUI 配置契约 | 否 |
| `check-nemu-kernel-config` | 当前 NEMU Linux 内核配置契约 | 否 |
| `check-nemu-virtio-input` | 配置区、event/status 队列、坏 descriptor、按键过滤、PLIC IRQ7 | 否，裸机 gate |
| `check-nemu-retirement-sdtrig` | `minstret` 退休语义和未实现 Sdtrig CSR 非法指令语义 | 否，裸机 gate |

`check-nemu-gui-config` 和 `check-nemu-kernel-config` 是组合 gate 的组件接口，
不会自行注入 GUI defconfig、`display` kernel profile 或 GUI 隔离目录。普通用户要
验证完整 GUI 应运行 `check-nemu-gui`；只有在显式复现同一套 profile/path 参数时
才单独调用组件目标。

`check-nemu-evolution` 当前不包含上述 GUI、input 或 retirement/Sdtrig gate；
修改这些子系统后应单独运行对应目标。

## 9. NEMU Ubuntu/systemd 回归

| 目标 | 适用场景 |
| --- | --- |
| `check-nemu-systemd-guest` | 默认 systemd-minimal 完整 gate；含启动、设备、网络、TTY、syscall、rootfs 写回、短 soak 和自然关机 |
| `check-nemu-systemd-guest-interactive` | 使用 interactive 独立 rootfs 跑同类 gate |
| `check-nemu-systemd-guest-full` | 使用 full 独立 rootfs 跑 focused gate |
| `check-nemu-python-int-preflight` | full rootfs 的 Python 整数工作负载预检 |
| `check-nemu-systemd-guest-long` | 较长稳定性 gate：默认 120 秒 soak、16 MiB 文件系统压力 |
| `check-nemu-systemd-guest-soak` | 重型稳定性 gate：默认 300 秒 soak、32 MiB 文件系统压力 |
| `check-nemu-systemd-guest-full-soak` | full rootfs + 重型 soak 参数 |
| `check-nemu-systemd-guest-tap` | 先要求 TAP preflight ready，再跑默认 rootfs TAP gate |
| `check-nemu-systemd-guest-full-tap` | 先要求 TAP preflight ready，再跑 full rootfs TAP gate |
| `check-nemu-reboot-loop` | 裸机验证 reboot 返回 32、宿主重启和最终 poweroff |
| `check-nemu-virtio-blk-error` | persistent overlay 上的 virtio-blk 异常/边界 descriptor |
| `check-nemu-reboot-persistence` | 两个 NEMU 进程间复用 overlay，验证数据持久且 backing 不变 |
| `check-nemu-evolution` | 顺序聚合 blk-error、reboot-loop、默认 systemd guest、reboot-persistence |

默认 `check-nemu-systemd-guest` 的主要预算是 50,000,000,000 指令、
1800 秒宿主超时、900 秒启动超时和 20 秒短 soak。`long`、`soak` 与
`full-soak` 是显著更重的回归，不应被当成日常快速 smoke。

调试 trace 时，performance 配置守门会有意失败。可以明确选择调试配置：

```sh
make \
  ARCH=riscv64-nemu \
  NEMU_DEFCONFIG=riscv64-linux_debug_defconfig \
  NEMU_PERFORMANCE_REQUIRED=0 \
  check-nemu-systemd-guest
```

不要把 `NEMU_PERFORMANCE_REQUIRED=0` 写进默认命令；它只适合已知需要
trace/debug 的运行。

## 10. NPC Ubuntu/systemd 回归

| 目标 | 用途 |
| --- | --- |
| `check-npc-systemd-guest` | NPC 最小 guest gate，通过 UART RX 驱动检查 |
| `check-npc-systemd-guest-full` | 更严格的 NPC UART gate，并要求自然关机 |
| `check-npc-systemd-guest-systemd-strict` | strict rootfs 的 systemd one-shot gate，UART RX 保持为 0 |

这些 wrapper 会固定 `ARCH=riscv64-npc`，不需要再传 ARCH。

## 11. NEMU 管理与配置检查

下列目标面向 NEMU。建议始终显式写 `ARCH=riscv64-nemu`；遗漏时某些目标
会进入 NPC 分支并只打印 `skip`，容易被误认为已经验证成功。

| 目标 | 用途 |
| --- | --- |
| `check-nemu-performance-config` | 检查 performance defconfig，拒绝 trace/difftest/watchpoint/统计/调试开关污染长跑 |
| `nemu-machine-info` | 不启动 guest，导出 ISA、内存、timer、设备及 MMIO/PIO 清单 |
| `nemu-rootfs-machine-info` | 打开 rootfs backing，导出 virtio-blk 容量、扇区和只读/writeback 状态 |
| `nemu-rootfs-overlay-machine-info` | 打开 backing + sparse overlay/sidecar，导出实际写入目标 |
| `nemu-monitor-cmd-smoke` | 验证一次性 `--monitor-cmd`，默认命令为 `info r` |
| `nemu-qmp-smoke` | 验证 QMP 查询、run-control、事件、quit 和畸形帧 fail-closed |
| `nemu-gdbstub-smoke` | 验证 GDB stub 管理入口及失败语义 |

示例：

```sh
make ARCH=riscv64-nemu check-nemu-performance-config
make ARCH=riscv64-nemu nemu-machine-info
make ARCH=riscv64-nemu nemu-qmp-smoke
```

## 12. TAP 与网络命令

默认 NEMU systemd gate 使用 hostless 网络；它能验证 guest 设备枚举、
固定 MAC、DHCP、DNS、TCP health、ARP 和 ICMP，但不表示已经接入宿主 TAP、
NAT 或公网。

| 目标 | 行为 |
| --- | --- |
| `check-nemu-tap-host` | 只读检查宿主 TAP/NAT 条件 |
| `show-nemu-tap-setup` | 只打印需要用户/root 执行的配置命令，不修改宿主 |
| `show-nemu-tap-teardown` | 只打印拆除命令，不修改宿主 |
| `check-nemu-systemd-guest-tap` | 要求 TAP 已 ready，然后运行默认 rootfs TAP gate |
| `check-nemu-systemd-guest-full-tap` | 要求 TAP 已 ready，然后运行 full rootfs TAP gate |

默认 TAP 参数：

| 变量 | 默认值 |
| --- | --- |
| `NEMU_TAP_IFNAME` | 若 `NEMU_SYSTEMD_NET_TAP` 非空则继承它，否则为 `nemu-tap0` |
| `NEMU_TAP_HOST_IPV4_CIDR` | `10.0.3.1/24` |
| `NEMU_TAP_GUEST_IPV4_CIDR` | `10.0.3.15/24` |
| `NEMU_TAP_GATEWAY` | `10.0.3.1` |
| `NEMU_TAP_DNS` | `1.1.1.1` |
| `NEMU_TAP_NAT_SOURCE_CIDR` | `10.0.3.0/24` |
| `NEMU_TAP_ENABLE_NAT` | `0` |
| `NEMU_TAP_UPLINK_IFACE` | 空 |
| `NEMU_TAP_PING_TARGET` | 空 |
| `NEMU_TAP_HTTP_URL` | 空 |
| `NEMU_TAP_REQUIRE_EXTERNAL` | `0` |
| `NEMU_TAP_REQUIRE_PACKETS` | `0` |

推荐流程：

```sh
make ARCH=riscv64-nemu show-nemu-tap-setup
# 审查输出，并由用户在宿主明确执行所需的特权命令
make ARCH=riscv64-nemu check-nemu-tap-host
make ARCH=riscv64-nemu check-nemu-systemd-guest-tap
```

外部 ping/HTTP 目标和“必须看到外部包”默认都未启用。需要证明外网能力时，
应显式配置目标和 hard gate，不能从 hostless 或默认 TAP 结果外推。

## 13. QEMU 参考入口

| 目标 | 用途 |
| --- | --- |
| `qemu` | `qemu-ubuntu-shell` 的别名 |
| `qemu-build` | 构建并安装本地 `qemu-system-riscv64` 到 `Linux/env/tools/qemu/` |
| `qemu-ubuntu-probe` | 用 QEMU 跑 Ubuntu probe initramfs |
| `qemu-ubuntu-shell` | 用 QEMU 跑 Ubuntu shell initramfs，作为参考路径 |

这些入口是 NPC bring-up reference，不是 NEMU VGA 入口。`qemu-build` 与 ARCH
无关；运行脚本默认使用 `QEMU_PLATFORM=npc`，而且不会自动补建 QEMU、NPC
Linux Image 或 initramfs。推荐不要给 QEMU 运行目标追加 ARCH，先明确准备 NPC
产物：

```sh
make qemu-build
make ARCH=riscv64-npc linux-image ubuntu-shell-initramfs
make qemu-ubuntu-shell
```

除非同时一致地覆盖所有 QEMU kernel/initramfs/path 参数，否则不要给
`qemu-ubuntu-shell` 传 `ARCH=riscv64-nemu`；它可能把 NEMU cpio 与脚本默认的
NPC Image 混合起来。

## 14. Focused tools 与 smoke

| 目标 | 用途 |
| --- | --- |
| `tools-build` | 构建 `Linux/tools` 全部工具 |
| `boot-tools` | 构建 boot 相关工具 |
| `tools-smoke` | 检查/构建 NPC simulator，再聚合 CPU/ISA `TOOL_SMOKES`；不含下面的 boot/device smoke |
| `tools-clean` | 清理 `Linux/tools` 构建产物 |
| `smoke-dtb` | DTB focused gate |
| `smoke-opensbi` / `smoke-opensbi-sbi` | OpenSBI/SBI runtime focused gate |
| `smoke-virtio-blk` | 通过 virtio-mmio 读取 Ubuntu ext4 superblock |

可单独运行的 CPU focused 目标包括：

- `smoke-jal-link`、`smoke-branch-raw`；
- `smoke-sret-user`、`smoke-sret-user-pagefault`、
  `smoke-sret-user-sv39`、`smoke-sret-user-sv39-halfword`、
  `smoke-sret-restore`、`smoke-ras-trap-boundary`；
- `smoke-fp-loadstore`、`smoke-fp-fcsr`、`smoke-fp-fmv-fclass`、
  `smoke-fp-convert`、`smoke-fp-compare-sgnj`、`smoke-fp-minmax`、
  `smoke-fp-addsub`、`smoke-fp-mul`、`smoke-fp-div`、`smoke-fp-sqrt`。

例如：

```sh
make ARCH=riscv64-npc smoke-sret-user-sv39
make ARCH=riscv64-npc tools-smoke
```

这些顶层目标会转发到 `Linux/tools`。直接使用 `make -C Linux/tools ...`
的更底层目标属于专项开发接口，不在本顶层手册逐项展开。

当前这些 CPU/ISA 与 boot/device 顶层 smoke 都把 `NPC_SIM` 传给
`Linux/tools`，因此应使用 `ARCH=riscv64-npc`。`tools-smoke` 只聚合上面列出的
CPU/ISA smoke；`smoke-dtb`、`smoke-opensbi*` 和 `smoke-virtio-blk` 必须按需
单独运行。不要用 `ARCH=riscv64-nemu tools-smoke`，否则前置检查与实际传入的
NPC simulator 可能不一致。

## 15. 查看、检查与清理

### `help`

`make` 和 `make help` 等价，只打印常用入口。帮助页是速查，不是完整索引；
完整说明使用本手册。

### `paths`

`paths` 不构建、不启动，打印 Make 最终解析出的平台、profile、模拟器、
kernel、固件、DTB、initrd/rootfs、flavor、overlay 和日志路径。任何不确定的
覆盖都先用同样参数跑一次 `paths`：

```sh
make ARCH=riscv64-nemu BOOT=ubuntu-rootfs paths
make ARCH=riscv64-npc BOOT=ubuntu-shell paths
```

普通 NEMU `run` 的关键判定字段应是：

```text
LINUX_FEATURE_PROFILE=headless
NEMU_DEFCONFIG=riscv64-linux_defconfig
NEMU_DISPLAY=0
NEMU_VIRTIO_INPUT=0
```

`paths` 只显示当前这一层 Make 直接解析的变量，不会替你展开另一个目标内部的
递归 wrapper。不要用 `make paths run-ubuntu-gui` 作为 GUI 预览；那会同时请求
运行 GUI。可见图形始终直接使用 `make run-ubuntu-gui`。

### `check`

`check` 不等于“完整回归”。它只确认当前组合的 simulator、Image、firmware、
DTB、可选 initrd/rootfs 实物存在，并在有 rootfs 时执行基本检查；缺失就失败，
不会代替专项 gate。

### `clean`

`clean` 只删除当前解析到的 `BUILD_DIR`。默认 ARCH 是 NPC，所以：

```sh
make clean
```

默认清理 NPC 的顶层 build，而不是 NEMU、Linux `O=`、OpenSBI、rootfs、GUI
或全部平台产物。清理前先跑同参数的 `paths`。

### `clean-logs`

`clean-logs` 删除当前平台的 `LOG_ROOT`。必须显式选择平台：

```sh
make ARCH=riscv64-nemu clean-logs
make ARCH=riscv64-npc clean-logs
```

不要省略 ARCH 后再假定清的是 NEMU；默认会选择 NPC。

## 16. NEMU rootfs overlay 与持久化

普通 NEMU `ubuntu-rootfs` 运行不会直接写 backing ext4，而是在日志目录创建
sparse overlay 和 sidecar。默认 `NEMU_RUN_ROOTFS_OVERLAY_RESET=1`，含义是
每次新的 `make ... run` 在 boot1 前重置 overlay；同一次命令内的 reboot
仍复用它。

因此，在 guest 中创建的文件默认不会跨两次独立的 `make run` 保留。需要手工
连续调试并保留上次修改时：

```sh
make \
  ARCH=riscv64-nemu \
  NEMU_RUN_ROOTFS_OVERLAY_RESET=0 \
  run
```

先用 `paths` 查看 `NEMU_RUN_ROOTFS_OVERLAY`，不要误删 backing 镜像。
需要验证跨重启持久化语义时，使用隔离的
`make check-nemu-reboot-persistence`，不要用日常运行目录替代 gate。

## 17. 常用覆盖变量

| 变量 | 何时覆盖 | 示例 |
| --- | --- | --- |
| `ARCH` | 选择 NPC/NEMU | `ARCH=riscv64-nemu` |
| `BOOT` | 选择 rootfs/initramfs/kernel | `BOOT=ubuntu-shell` |
| `MAX_CYCLES` | 限制或放宽模拟指令预算 | `MAX_CYCLES=1000000000` |
| `JOBS` | 控制构建并行度 | `JOBS=8` |
| `EXTRA_ARGS` | 追加模拟器参数 | `EXTRA_ARGS='...'` |
| `BOOTARGS_EXTRA` | 追加 Linux bootargs | `BOOTARGS_EXTRA='loglevel=7'` |
| `NEMU_DEFCONFIG` | 明确切换 NEMU debug/performance 配置 | `NEMU_DEFCONFIG=riscv64-linux_debug_defconfig` |
| `NEMU_PERFORMANCE_REQUIRED` | 调试时暂时放开性能配置 gate | `NEMU_PERFORMANCE_REQUIRED=0` |
| `NEMU_RUN_ROOTFS_OVERLAY_RESET` | 决定普通 NEMU run 是否重置 overlay | `NEMU_RUN_ROOTFS_OVERLAY_RESET=0` |
| `NEMU_RUN_MAX_BOOTS` | 设置一次 run 的最大启动次数 | `NEMU_RUN_MAX_BOOTS=3` |

对路径、rootfs、GUI build 或网络变量做高级覆盖前，先执行相同变量组合的
`paths`，再确认它没有指向另一个平台的可变产物。

## 18. 常见误用与正确写法

| 误用/误解 | 实际结果 | 正确做法 |
| --- | --- | --- |
| 裸 `make` 会启动 Ubuntu | 只显示 help | 使用 `make run` 或明确 ARCH/BOOT |
| `ARCH=riscv64-nemu` 等于启用 VGA | 只选择 NEMU 平台 | 可见屏幕用 `make run-ubuntu-gui` |
| 给普通 run 加 `NEMU_DISPLAY=1` | 只改一部分契约，可能配置错配 | 使用完整 GUI wrapper |
| 终端仍有 `ttyS0` 所以 VGA 失败 | GUI 有意保留双控制台 | 同时查看 SDL 的 `tty1` |
| `check-nemu-gui` 应该弹窗口 | 它在 Xvfb 中自动验证 | 人工交互用 `run-ubuntu-gui` |
| NEMU `-b` 关闭 SDL | `-b` 只关闭交互式 SDB | SDL 由 GUI Kconfig/profile 决定 |
| `prepare-all` 会构建仓库全部内容 | 只覆盖当前 ARCH 的 headless 启动资源 | GUI/full/soak 分别运行专用目标 |
| `check-nemu-evolution` 包含所有 NEMU gate | 不含 GUI/input/retirement | 按改动范围补跑专项 gate |
| NEMU 管理目标省略 ARCH 也会检查 NEMU | 部分 NPC 分支只输出 skip | 显式写 `ARCH=riscv64-nemu` |
| 两次普通 NEMU run 会保留 guest 文件 | 默认重置 overlay | 调试时显式 `NEMU_RUN_ROOTFS_OVERLAY_RESET=0` |
| `ubuntu-rootfs-systemd-overlay` 只是轻量 overlay | 与 systemd-image 共用完整配方 | 把它视为兼容入口 |
| `check` 是完整验收 | 只检查当前组合实物 | 使用对应 `check-nemu-*` 或 `check-npc-*` |
| 裸 `make clean-logs` 清 NEMU 日志 | 默认清 NPC 日志 | 显式传 `ARCH=riscv64-nemu` |
| `show-nemu-tap-setup` 会配置宿主 | 只打印计划 | 审查后由用户明确执行特权命令 |

## 19. 面向用户与内部目标的边界

本手册只记录可以直接调用的公开目标。Makefile 中以 `__` 开头的目标
（例如 `__check-nemu-gui`）是 wrapper 的内部实现，依赖 wrapper 注入隔离路径、
profile、超时和检查参数。不要直接调用它们。

新增或修改公开目标时，应同时完成以下维护：

1. 在 [Makefile](Makefile) 的 `help` 中加入最常用入口；
2. 在本手册对应分类中记录用途、默认值、可见输出和副作用；
3. 如果默认行为改变，同步更新 [README.md](README.md) 首屏契约；
4. 如果产物布局改变，同步更新 [env/README.md](env/README.md)；
5. 用 `make help`、`make ... paths` 和直接相关的最小 gate 验证文档所述行为。
