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
- `make -C Linux check-nemu-systemd-guest`：启动 NEMU Ubuntu rootfs，在 guest 内检查 systemd running、伪文件系统挂载、TTY/console、timer、`/dev/vda` 和 rootfs 小规模写回
- `make -C Linux qemu-ubuntu-shell`：用本地 QEMU 启动同一份 Ubuntu 22.04 shell initramfs，作为 NPC RTL bring-up 的参考路径

当前无免密 sudo、`debootstrap` 或 `qemu-riscv64-static` 时，`build-ubuntu-rootfs.sh` 会回退到 Ubuntu Base + fakeroot 路线；若要生成完整 systemd rootfs，可在具备这些工具的环境中设置 `UBUNTU_ROOTFS_REQUIRE_SYSTEMD=1` 后重建，脚本会在无法满足 systemd 路线时直接失败。若只是继续推进 NEMU 的 systemd 启动调试，可用 `UBUNTU_ROOTFS_SYSTEMD_OVERLAY=1` 或 `ubuntu-rootfs-systemd-image` 生成 chrootless overlay 候选镜像；当前 NEMU 已有运行证据证明该候选镜像可进入 ttyS0 root shell 且 systemd 为 `running`。后续仍需用更长时间窗口和更强 virtio/TTY/interrupt 压力测试补足 QEMU 级设备完整性证据。
