# NPC RV64 本地开发环境目录

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

- `make -C npc/rv64 qemu`：把 QEMU riscv64-softmmu 构建/安装到 `tools/qemu/`
- `make -C npc/rv64 qemu-ubuntu-initramfs`：用本地 QEMU 启动同一份 Ubuntu 22.04 probe initramfs，作为 NPC RTL bring-up 的参考路径
