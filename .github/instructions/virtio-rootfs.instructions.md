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
- 单源 PLIC 临时特判不能替代完整 virtio 中断设计。
- 可写 ext4 模板不能跨系统回放直接复用：证据 run 应先内容寻址模板，再用
  `Linux/scripts/prepare-npc-rootfs-run-image.sh` 创建独立 block-image 工作副本。NPC 只挂载副本，
  模板前后 SHA-256 必须相同；副本的 pre-run SHA 必须等于模板，post-run 允许反映 guest 合法写入。
- `mkfs.ext4 -d` 的 UUID/时间元数据以及 rootfs 文件时间会使新构建镜像的二进制 SHA 随轮次变化；
  未显式启用可复现镜像构建时，不得把历史镜像 SHA 当作本轮期望常量。应在静态内容检查通过后记录
  本轮 template/CPIO SHA 及构建输入 SHA，再用该 template SHA 约束工作副本并核验模板前后不变。

## 验证建议

先做小型 virtio-blk smoke，再进入完整 Ubuntu rootfs：

```text
virtio-mmio-id -> queue-setup -> single-sector-read -> interrupt -> linux-probe -> mount-rootfs
```

每个阶段都要保留日志和 task-run 记录。
