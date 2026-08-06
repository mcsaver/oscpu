# RV64 Linux Bring-up Profile

本目录把 Linux/Ubuntu bring-up 所需的平台参数收敛成三个 yml,按 NEMU/NPC 分开管理:

- `common-rv64.yml`:两侧必须一致的共享 SoC 契约(内存/装载布局/共有设备 clint、plic、uart0、virtio_blk、reset_syscon/共享 bootargs/rng-seed)。NEMU 是 NPC 的 golden reference,difftest 与 golden bring-up 对比要求这些字段不允许在平台间漂移。
- `npc-rv64.yml`:NPC 平台差异(产物路径、rootfs bootargs 缺省)。`ARCH=riscv64-npc` 时被 Makefile 自动选中。
- `nemu-rv64.yml`:NEMU 平台差异(产物路径、NEMU 独有设备 virtio_rng/virtio_net/goldfish_rtc、rootfs bootargs 真源)。`ARCH=riscv64-nemu` 时被 Makefile 自动选中。

平台 yml 以顶层 `base: common-rv64.yml` 引用共享契约,`gen_dts.py` 递归加载并深合并(平台键覆盖 base,dict 递归、标量整体替换)。

`gen_dts.py` 的生成模式:

- `kernel` 模式:保持现有 OpenSBI + Linux kernel smoke,不声明 initrd/rootfs；
  需要 OpenSBI 独占关机设备时可显式加 `--reset-syscon`。
- `initramfs` 模式:在 `/chosen` 里生成 `linux,initrd-start/end`,目标是先进入 BusyBox `/bin/sh`。
- `ubuntu_initramfs` bootargs:配合官方 Ubuntu Base 22.04 riscv64 cpio,目标是先执行 guest `/init` 并打印 `/etc/os-release`。
- `rootfs` 模式:Ubuntu 22.04 rootfs + virtio-mmio block 的设备树形态；共有 reset-syscon 节点由 NPC/NEMU 两侧 rootfs DTB 规则都以 `--reset-syscon` 打开，NEMU 独有的 virtio-rng/virtio-net/goldfish-rtc 仅由 NEMU 规则打开。

L3 轻量 Linux 使用一份共享有效 DTB：它同时包含 initramfs 地址、
`rdinit=/init` 和 reset-syscon，并通过 `FW_FDT_PATH` 嵌入 OpenSBI；
`guest.dtb` 与 `opensbi-platform.dtb` 必须逐字节一致。OpenSBI 启动时会把
内嵌 FDT 复制到 `FW_JUMP_FDT_ADDR`，所以不能再用一份不含 initrd 的独立
platform DTB 覆盖 Linux 输入。L3 内核配置显式关闭 Linux syscon poweroff
驱动，因此 PID1 的 poweroff 仍必须经过 SBI SRST，再由 OpenSBI 写
`0x5555` 到本地 syscon，不能绕过固件链路。

L2 mini-system 使用 `build-rv64-mini-system.sh` 生成一份 OpenSBI + S/U payload、有效 DTB 与
`fw_jump.bin`，由 `run-mini-system-current.sh` 在 production `NpcSimTop` 上选择
`privilege/sv39/timer/interrupt/atomic-mmio/shutdown/all`。产物只保留一个 current identity cache，
task-run 仅保存 binding、phase/terminal、断言、哈希与 bounded 日志；只有 `all` 可以形成完整 L2 签核。

L2/L3 共享的当前 `NpcSimTop` 由 `build-current-simulator-cache.sh` 生成；cache 除 RTL design-id 外还绑定
vsrc、csrc、Makefile 与生效配置的内容哈希。每次 layer runner 在执行前复核该 source-id，完成后先做
post-binding 与 runtime cleanup，再以 evidence manifest/verification/seal 授权 PASS。L3 的两次 UART RX
必须分别落在 ARM/RX phase 之间并观测到 `uart_irq=1,plic_irq=1`；关机顺序用 UART TX 字节流和 syscon
cycle/commit 直接绑定。

长期原则:

- 修改 RAM、镜像装载地址,或 clint/plic/uart0/virtio_blk 等共有设备的基址/中断号,改 `common-rv64.yml`(设备地址还需同步 AM/NEMU/NPC 三侧 `device_address.h` 并过 `check-device-address-map.sh` 门禁);平台独有设备与产物路径改对应平台 yml;再由脚本生成 DTS/boot 入口。
- DTB 产物文件名(`npc-rv64-*.dtb`)是跨脚本 API(`build-opensbi.sh` 按 basename 分发、e2e 契约硬编码路径),不要改名。
- 外部源码包、下载缓存、本地 Python venv、rootfs/initramfs 镜像和 smoke 日志默认放在 `Linux/env/`,DTB/DTS 生成物默认放在 `Linux/build/`。如果需要自带 RISC-V 工具链,也优先放到 `Linux/env/toolchains/` 并让脚本自动优先使用。
