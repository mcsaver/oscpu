# Linux / Ubuntu 22.04 启动入口

这个目录是 RV64 Linux/Ubuntu bring-up 的顶层入口。`npc/rv64` 只保留 core RTL、testbench 和 Verilator 仿真本体；OpenSBI、Linux、Ubuntu、DTB、initramfs/rootfs、QEMU reference 和启动脚本统一放在这里。

命令规范：

- `ARCH` 表示仿真/目标架构，当前基准是 `riscv64-npc`。
- `BOOT` 表示启动场景，默认是 `ubuntu-rootfs`。
- `make ARCH=riscv64-npc run` 必须表示完整 Ubuntu rootfs 路线，不会偷偷降级成 shell initramfs gate。

常用命令：

```sh
cd Linux

# 完整 Ubuntu rootfs 路线。当前 virtio-blk/rootfs 后端仍是后续 gate，
# 因此这条命令用于继续调试完整 Linux，不等同于已通过。
make ARCH=riscv64-npc run

# 已闭合的 Ubuntu /bin/sh initramfs gate，必须显式选择。
make ARCH=riscv64-npc BOOT=ubuntu-shell run

# 轻量 Ubuntu os-release probe。
make ARCH=riscv64-npc BOOT=ubuntu-probe run

# 打印当前 ARCH/BOOT 对应资源路径。
make ARCH=riscv64-npc paths

# 构建当前 BOOT 所需资源。
make ARCH=riscv64-npc prepare
```

等价别名：

```sh
make ARCH=riscv64-npc run-ubuntu-rootfs
make ARCH=riscv64-npc run-ubuntu-shell
make ARCH=riscv64-npc run-ubuntu-probe
```

当前资源布局：

- `Linux/env/`：外部源码、下载缓存、OpenSBI/Linux/QEMU 构建产物、Ubuntu 镜像和日志。
- `Linux/build/`：DTB/DTS 等 Linux 启动相关中间产物。
- `Linux/scripts/`：OpenSBI/Linux/Ubuntu/QEMU 构建和运行脚本。
- `Linux/platform/`：平台 YAML 与 DTB 生成器。
- `Linux/configs/`：Linux boot/trace 用的 RV64 仿真器 profile。
- `Linux/tools/`：Linux bring-up 专用 focused gates、小 payload 和 Ubuntu init 源码。
- `npc/rv64/`：RV64 core RTL、testbench、Kconfig 和 Verilator 仿真本体。

验收口径仍按项目记忆分层：`ubuntu-shell` 只代表 initramfs 内官方 Ubuntu `/bin/sh -c` gate；`ubuntu-rootfs`、virtio-blk、Linux-visible display 和完整设备栈是后续独立 gate。
