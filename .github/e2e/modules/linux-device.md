# linux-device E2E Contract

- **范围**: UART、CLINT、PLIC、virtio-mmio、rootfs、Linux driver probe。
- **上游**: rv64-linux rootfs/device tree。
- **下游**: Ubuntu rootfs loop、systemd gate。
- **L0 gate**: `linux-device-contract` 检查 virtio-rootfs instruction、DTS 生成器和 guest-check。
- **L1 gate**: 后续 focused virtio/PLIC/UART guest marker。
- **证据**: DTB nodes、`/proc/interrupts`、`/dev/vda`、virtio modalias。
- **升级路线**: 将设备契约拆成 UART/PLIC/virtio-blk/virtio-rng 子 profile。
