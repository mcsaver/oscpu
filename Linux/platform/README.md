# RV64 Linux Bring-up Profile

本目录把 Linux/Ubuntu bring-up 所需的平台参数收敛成三个 yml,按 NEMU/NPC 分开管理:

- `common-rv64.yml`:两侧必须一致的共享 SoC 契约(内存/装载布局/共有设备 clint、plic、uart0、virtio_blk/共享 bootargs/rng-seed)。NEMU 是 NPC 的 golden reference,difftest 与 golden bring-up 对比要求这些字段不允许在平台间漂移。
- `npc-rv64.yml`:NPC 平台差异(产物路径、rootfs bootargs 缺省)。`ARCH=riscv64-npc` 时被 Makefile 自动选中。
- `nemu-rv64.yml`:NEMU 平台差异(产物路径、NEMU 独有设备 virtio_rng/virtio_net/goldfish_rtc/reset_syscon、rootfs bootargs 真源)。`ARCH=riscv64-nemu` 时被 Makefile 自动选中。

平台 yml 以顶层 `base: common-rv64.yml` 引用共享契约,`gen_dts.py` 递归加载并深合并(平台键覆盖 base,dict 递归、标量整体替换)。

`gen_dts.py` 的生成模式:

- `kernel` 模式:保持现有 OpenSBI + Linux kernel smoke,不声明 initrd/rootfs。
- `initramfs` 模式:在 `/chosen` 里生成 `linux,initrd-start/end`,目标是先进入 BusyBox `/bin/sh`。
- `ubuntu_initramfs` bootargs:配合官方 Ubuntu Base 22.04 riscv64 cpio,目标是先执行 guest `/init` 并打印 `/etc/os-release`。
- `rootfs` 模式:Ubuntu 22.04 rootfs + virtio-mmio block 的设备树形态;NEMU 独有设备节点仅在 `--reset-syscon/--virtio-rng/--virtio-net/--goldfish-rtc` 开关打开时进入 DTS(仅 NEMU rootfs DTB 规则传这些开关)。

长期原则:

- 修改 RAM、镜像装载地址,或 clint/plic/uart0/virtio_blk 等共有设备的基址/中断号,改 `common-rv64.yml`(设备地址还需同步 AM/NEMU/NPC 三侧 `device_address.h` 并过 `check-device-address-map.sh` 门禁);平台独有设备与产物路径改对应平台 yml;再由脚本生成 DTS/boot 入口。
- DTB 产物文件名(`npc-rv64-*.dtb`)是跨脚本 API(`build-opensbi.sh` 按 basename 分发、e2e 契约硬编码路径),不要改名。
- 外部源码包、下载缓存、本地 Python venv、rootfs/initramfs 镜像和 smoke 日志默认放在 `Linux/env/`,DTB/DTS 生成物默认放在 `Linux/build/`。如果需要自带 RISC-V 工具链,也优先放到 `Linux/env/toolchains/` 并让脚本自动优先使用。
