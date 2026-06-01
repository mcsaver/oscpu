---
description: "RV64 Linux rootfs/virtio-blk 约束。处理 Ubuntu rootfs、virtio-mmio block、PLIC 多源中断、/dev/vda 或 root=/dev/vda 启动时使用。"
applyTo: "npc/rv64/**"
---

# Virtio Rootfs 约束

## 核心判断

initramfs 和 rootfs 是两个不同 gate。`root=/dev/vda` 或 DTB 中出现 virtio 节点，不代表 virtio-blk 已实现，也不代表 Ubuntu rootfs 可启动。

## rootfs 最低闭环

完整 rootfs 路线至少需要：

1. virtio-mmio register model。
2. vring descriptor / avail / used ring 协议。
3. host block image backend。
4. PLIC 多源中断，至少 UART IRQ1 + virtio IRQ2。
5. DTB virtio-mmio 节点与实际地址、中断号一致。
6. Linux kernel config 启用 virtio-mmio 与 virtio-blk。
7. guest 日志出现 virtio probe、`/dev/vda` 和 rootfs mount 证据。

## 禁止误判

- 不把 Ubuntu Base rootfs 目录或 ext4 镜像存在当作 rootfs 启动成功。
- 不把 initramfs `/bin/sh` 当作 rootfs `/dev/vda` 启动。
- 不用 host 直接读写 rootfs 文件替代 guest block IO 协议。
- 不用单源 PLIC 临时特判绕过 virtio 中断设计。

## 验证建议

先做小型 virtio-blk smoke，再进入完整 Ubuntu rootfs：

```text
virtio-mmio-id -> queue-setup -> single-sector-read -> interrupt -> linux-probe -> mount-rootfs
```

每个阶段都要保留日志和 task-run 记录。
