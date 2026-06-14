# NEMU Virtio Blk Size

## 背景

继续推进完整 Ubuntu 22.04 rootfs/块设备契约。此前 NEMU virtio-blk 已支持现代 virtio-mmio、单队列、FLUSH、INDIRECT_DESC、VERSION_1 和 feature 子集校验；本轮补齐 Linux `virtio_blk` 驱动常用的标准 block size feature，避免 guest 只是依赖内核默认 512B。

## 改动

- `nemu/src/device/disk.c`
  - 新增 `VIRTIO_BLK_F_BLK_SIZE = 6`。
  - device feature sel0 返回 `BLK_SIZE | FLUSH | INDIRECT_DESC`。
  - virtio-blk config offset 20 返回 `blk_size=512`，对齐 Linux `struct virtio_blk_config.blk_size`。
- `Linux/scripts/check-nemu-systemd-guest.sh`
  - 新增 `__NEMU_CHECK_VDA_PHYSICAL_BLOCK__` marker。
  - 要求 `/sys/block/vda/queue/physical_block_size == 512`。
  - 要求 Linux sysfs virtio features bitstring 中 bit 6 为 1，并输出 `virtio-blk-feature-blk-size` PASS。

## 快速验证

- `bash -n Linux/scripts/check-nemu-systemd-guest.sh`: PASS
- `NEMU_HOME=/home/lyg/PA/ysyx-workbench/nemu make -C nemu -j$(nproc)`: PASS
- `git diff --check -- nemu/src/device/disk.c Linux/scripts/check-nemu-systemd-guest.sh`: PASS

## Focused Gate

由 `run-gate.sh` 启动：

```sh
timeout 2200s make -C Linux check-nemu-systemd-guest \
  NEMU_SYSTEMD_CHECK_LOG_DIR=/home/lyg/PA/ysyx-workbench/Linux/env/logs/linux-front/riscv64-nemu-virtio-blk-size-gate \
  NEMU_SYSTEMD_CHECK_MAX_CYCLES=25000000000 \
  NEMU_SYSTEMD_CHECK_TIMEOUT=1900 \
  NEMU_SYSTEMD_RELOAD_TIMEOUT=60 \
  NEMU_SYSTEMD_SOAK_SECONDS=0 \
  NEMU_SYSTEMD_FS_STRESS_MIB=1 \
  NEMU_SYSTEMD_FS_TREE_FILES=8 \
  NEMU_SYSTEMD_PROCESS_LOOPS=2 \
  NEMU_SYSTEMD_UART_RX_STRESS_LINES=32 \
  NEMU_SYSTEMD_BLOCK_PARALLEL_JOBS=1 \
  NEMU_SYSTEMD_BLOCK_JOB_MIB=1 \
  NEMU_SYSTEMD_SYSCALL_PROBE=0
```

结果：`run.status=0`

`perf.tsv`:

```text
boot_seconds	guest_check_seconds	poweroff_seconds	total_seconds	soak_seconds	fs_stress_mib	fs_tree_files	process_loops	uart_rx_stress_lines	block_parallel_jobs	block_job_mib	max_cycles
231	523	20	774	0	1	8	2	32	1	1	25000000000
```

关键 marker：

- `__NEMU_CHECK_VDA_LOGICAL_BLOCK__:512`
- `__NEMU_CHECK_VDA_PHYSICAL_BLOCK__:512`
- `__NEMU_CHECK_VIRTIO_FEATURES__:0000001001000000000000000000100010000000000000000000000000000000`
- `__NEMU_CHECK_PASS__:virtio-blk-feature-blk-size`
- `__NEMU_CHECK_PASS__:systemd-runtime-unit-cleanup`
- `__NEMU_SYSTEMD_CHECK_DONE__ rc=0`
- `__NEMU_SYSTEMD_POWEROFF_BEGIN__`
- `syscon-reset: poweroff requested value=0x00005555`
- `HIT GOOD TRAP`

失败扫描：无行首真实 `__NEMU_CHECK_FAIL__` marker。

## 边界

本轮只声明标准 `blk_size=512` config 与 Linux 队列块大小协商路径闭合。仍未实现或声明：多队列、event idx、discard/write-zeroes/secure erase、malformed descriptor fuzz、断电恢复、fsck 恢复或 QEMU 级完整 block 设备。
