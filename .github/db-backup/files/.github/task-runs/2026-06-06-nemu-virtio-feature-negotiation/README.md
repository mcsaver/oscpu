# 2026-06-06 NEMU virtio feature negotiation

## 目标

- 继续推进完整 Ubuntu 22.04 rootfs 路线中的块设备/rootfs 可靠性。
- 把 NEMU virtio-blk 从“Linux 正常路径能用”继续收紧到“feature negotiation 不静默接受错误 feature，并且 Linux guest 能观测到关键 feature 已协商”。

## 改动

- `nemu/src/device/disk.c`
  - 新增 `virtio_blk_device_features(sel)` 作为设备支持 feature 的单一来源。
  - 新增 `virtio_blk_driver_features_supported()`，检查 driver 写入的 feature 必须是设备支持集合的子集。
  - driver 设置 `STATUS.FEATURES_OK` 时，若存在 unsupported bit，设备清掉 `FEATURES_OK`。这符合 virtio 协商语义，避免错误协商继续进入 `DRIVER_OK`。
- `Linux/scripts/check-nemu-systemd-guest.sh`
  - 新增 Linux sysfs 检查：`/sys/class/block/vda/device`、modalias、status、features bitstring。
  - 硬检查 bit 32 `VIRTIO_F_VERSION_1`、bit 9 `VIRTIO_BLK_F_FLUSH`、bit 28 `VIRTIO_RING_F_INDIRECT_DESC` 已协商。
- `Linux/README.md`、`Linux/env/README.md`
  - 补充默认 guest gate 已覆盖 virtio modalias/status/feature 协商。

## 调试记录

- 第一次 focused gate 失败在 `virtio-vda-modalias`。
- root cause 是脚本期望把 vendor 写成 16-bit `v00005859`；Linux `virtio.c` 的 modalias 按 32-bit 打印，实际应为 `virtio:d00000002v58535959`。
- 修正期望后，同一类 focused gate 通过。

## 验证

- `bash -n Linux/scripts/check-nemu-systemd-guest.sh`：PASS。
- `NEMU_HOME=/home/lyg/PA/ysyx-workbench/nemu make -C nemu -j$(nproc)`：PASS，重新编译并链接 `src/device/disk.c`。
- `git diff --check -- nemu/src/device/disk.c Linux/scripts/check-nemu-systemd-guest.sh`：PASS。
- focused NEMU Ubuntu gate：
  - 命令参数：`NEMU_SYSTEMD_SYSCALL_PROBE=0`、`NEMU_SYSTEMD_SOAK_SECONDS=0`、`NEMU_SYSTEMD_FS_STRESS_MIB=1`、`NEMU_SYSTEMD_FS_TREE_FILES=8`、`NEMU_SYSTEMD_PROCESS_LOOPS=2`、`NEMU_SYSTEMD_UART_RX_STRESS_LINES=32`、`NEMU_SYSTEMD_BLOCK_PARALLEL_JOBS=1`、`NEMU_SYSTEMD_BLOCK_JOB_MIB=1`。
  - 日志目录：`Linux/env/logs/linux-front/riscv64-nemu-virtio-feature-gate-v2/`
  - `perf.tsv`: `boot_seconds=240`、`guest_check_seconds=510`、`poweroff_seconds=20`、`total_seconds=770`、`max_cycles=25000000000`
  - 关键 marker：`virtio-vda-modalias`、`virtio-vda-status`、`virtio-vda-features-bitstring`、`virtio-feature-version-1`、`virtio-blk-feature-flush`、`virtio-ring-feature-indirect-desc`、`vda-direct-read`、`vda-direct-read-sha256-windows`、`rootfs-metadata-tree`、`rootfs-direct-io`、`rootfs-parallel-direct-io`、`rootfs-stress-copy-cmp` 全 PASS。
  - 收尾：`__NEMU_SYSTEMD_CHECK_DONE__ rc=0`、`__NEMU_SYSTEMD_POWEROFF_BEGIN__`、`HIT GOOD TRAP`。
  - 失败扫描：无 `^__NEMU_CHECK_FAIL__:` 或 `^__NEMU_SYSCALL_PROBE_FAIL__`。

## 边界

- 这次增强的是 feature negotiation 和 Linux-visible virtio feature 证据。
- 仍未完成：多队列、event idx、discard/write-zeroes、malformed descriptor fuzz、多 outstanding 压力和更长时间 block 设备稳定性。
