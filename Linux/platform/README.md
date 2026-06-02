# NPC RV64 Linux Bring-up Profile

本目录把 Linux/Ubuntu bring-up 所需的平台参数收敛成 `npc-rv64.yml`。

- `kernel` 模式：保持现有 OpenSBI + Linux kernel smoke，不声明 initrd/rootfs。
- `initramfs` 模式：在 `/chosen` 里生成 `linux,initrd-start/end`，目标是先进入 BusyBox `/bin/sh`。
- `ubuntu_initramfs` bootargs：配合官方 Ubuntu Base 22.04 riscv64 cpio，目标是先执行 guest `/init` 并打印 `/etc/os-release`。
- `rootfs` 模式：预留 Ubuntu 22.04 rootfs + virtio-mmio block 的设备树形态；当前 RTL 还需要补 virtio-blk、多源 PLIC、UART RX 和 F/D 后才能把它作为最终通过标准。

长期原则：修改 RAM、镜像地址、设备基址或中断号时，优先改 `npc-rv64.yml`，再由脚本生成 DTS/boot 入口。
外部源码包、下载缓存、本地 Python venv、rootfs/initramfs 镜像和 smoke 日志默认放在 `Linux/env/`，DTB/DTS 生成物默认放在 `Linux/build/`。如果需要自带 RISC-V 工具链，也优先放到 `Linux/env/toolchains/` 并让脚本自动优先使用。
