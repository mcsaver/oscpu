# NEMU virtio-blk 链解析与 rootfs 容量 gate

## 目标
- 继续推进完整 Ubuntu 22.04 rootfs 路线中的块设备可靠性。
- 不满足于“能 mount `/dev/vda`”，而是让 virtqueue 链解析、flush 和 guest 可见容量更接近 Linux/virtio 真实契约。

## 实现
- `nemu/src/device/disk.c` 新增 indirect descriptor 支持，并向 guest 报告 `VIRTIO_RING_F_INDIRECT_DESC`。
- virtqueue chain 解析增加循环检测、guest memory 边界检查、嵌套 indirect 拒绝、header/status 边界检查和读写方向校验。
- 设备 features 新增 `VIRTIO_BLK_F_FLUSH`；FLUSH 请求现在执行 `fflush()+fsync()`，不只停在 stdio buffer。
- block read/write 会校验请求不越过 host backing image 大小，越界返回 `VIRTIO_BLK_S_IOERR`。
- `Linux/scripts/check-nemu-systemd-guest.sh` 注入 host rootfs image 字节数；guest 端检查 `/dev/vda` 的 `blockdev --getsize64` 与 backing image 一致，并检查 logical block size 为 512。

## 验证
- `NEMU_HOME=/home/lyg/PA/ysyx-workbench/nemu make -C nemu -j$(nproc)`：PASS。
- `bash -n Linux/scripts/check-nemu-systemd-guest.sh`：PASS。
- `git diff --check -- nemu/src/device/disk.c Linux/scripts/check-nemu-systemd-guest.sh`：PASS。
- `make -C Linux check-nemu-systemd-guest`：PASS，用时约 305s。

关键日志：
- `Linux/env/logs/linux-front/riscv64-nemu-systemd-guest-check/console.log`
- 可见 `__NEMU_CHECK_VDA_SIZE__:2147483648`、`__NEMU_CHECK_PASS__:vda-size-matches-rootfs`、`__NEMU_CHECK_VDA_LOGICAL_BLOCK__:512`、`__NEMU_CHECK_PASS__:vda-logical-block-size`、`__NEMU_CHECK_FS_STRESS_BYTES__:4194304/4194304`、`__NEMU_CHECK_PASS__:rootfs-stress-copy-cmp`、`__NEMU_SYSTEMD_CHECK_DONE__ rc=0`。

## 边界
- 当前仍是单队列 virtio-blk 功能模型，不是完整 QEMU 级 virtio-blk。
- 还未覆盖 event idx、多队列、descriptor fuzz、discard/write-zeroes、错误注入或大规模长期 I/O 压力。
