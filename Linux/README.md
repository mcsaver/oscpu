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
# 当前已能进入 ttyS0 root shell 且 systemd is-system-running=running，但还不是 QEMU 级通用机器。
make ARCH=riscv64-nemu run

# NEMU Ubuntu/systemd 自动化验收：在 guest 内检查 systemd、伪文件系统挂载、
# tty/console、timer sleep、/dev/vda/rootfs 和小规模写回/sync。
make check-nemu-systemd-guest

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

验收口径仍按项目记忆分层：`ubuntu-shell` 只代表 initramfs 内官方 Ubuntu `/bin/sh -c` gate；`ubuntu-rootfs`、virtio-blk、Linux-visible display 和完整设备栈是独立 gate。当前 Ubuntu Base + fakeroot 产物可作为 shell/rootfs gate；需要 `systemd` gate 时，优先使用具备 sudo、`debootstrap` 与 `qemu-riscv64-static` 的环境重建，并用 `check-ubuntu-rootfs-systemd` 验证实物。若当前机器缺这些工具，可用 `ubuntu-rootfs-systemd-image` 生成 apt/dpkg-deb overlay 候选镜像继续调试 systemd 启动；当前 NEMU 已用该路线证明 ttyS0 root shell 与 systemd `running`，并可通过 `check-nemu-systemd-guest` 做 guest 内自动化回归。边界仍然有效：NEMU 的 virtio-blk/UART/PLIC 是 Linux bring-up 所需的最小模型，完整 virtio 特性、长期设备压力和 QEMU 级通用虚拟机不能由单次 systemd running gate 代替。
