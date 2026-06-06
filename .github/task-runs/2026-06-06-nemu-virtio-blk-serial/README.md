# NEMU Virtio Blk Serial

## 背景

继续推进 NEMU virtio-blk/rootfs 的 Linux-visible 设备契约。NEMU 已有 `VIRTIO_BLK_T_GET_ID` 分支，但原实现只向第一个 writable descriptor 写一次字符串，没有验证 Linux 是否通过 `/sys/block/vda/serial` 实际触发该控制请求。

## 改动

- `nemu/src/device/disk.c`
  - 新增 `VIRTIO_BLK_ID_BYTES=20` 与 `VIRTIO_BLK_ID_STRING="ysyx-nemu-virtio-blk"`。
  - 新增 `virtio_blk_write_id()`，构造固定 20B ID buffer，并可跨多个 writable descriptor 写满。
  - `VIRTIO_BLK_T_GET_ID` 现在要求写满 20B；数据段不可写或空间不足时返回 `VIRTIO_BLK_S_IOERR`。
- `Linux/scripts/check-nemu-systemd-guest.sh`
  - 新增 `__NEMU_CHECK_VDA_SERIAL__` marker。
  - 硬检查 `/sys/block/vda/serial == ysyx-nemu-virtio-blk`，触发 Linux `virtblk_get_id()` -> `VIRTIO_BLK_T_GET_ID`。

## 快速验证

- `bash -n Linux/scripts/check-nemu-systemd-guest.sh`: PASS
- `NEMU_HOME=/home/lyg/PA/ysyx-workbench/nemu make -C nemu -j$(nproc)`: PASS
- `git diff --check -- nemu/src/device/disk.c Linux/scripts/check-nemu-systemd-guest.sh`: PASS

## Focused Gate

由 `run-gate.sh` 启动：

```sh
timeout 2200s make -C Linux check-nemu-systemd-guest \
  NEMU_SYSTEMD_CHECK_LOG_DIR=/home/lyg/PA/ysyx-workbench/Linux/env/logs/linux-front/riscv64-nemu-virtio-blk-serial-gate \
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
237	845	20	1102	0	1	8	2	32	1	1	25000000000
```

关键 marker：

- `__NEMU_CHECK_PASS__:systemd-runtime-daemon-reload`
- `__NEMU_CHECK_PASS__:systemd-runtime-unit-cleanup`
- `__NEMU_CHECK_VDA_SERIAL__:ysyx-nemu-virtio-blk`
- `__NEMU_CHECK_PASS__:vda-serial-get-id`
- `__NEMU_SYSTEMD_CHECK_DONE__ rc=0`
- `__NEMU_SYSTEMD_POWEROFF_BEGIN__`
- `syscon-reset: poweroff requested value=0x00005555`
- `HIT GOOD TRAP`

失败扫描：无行首真实 `__NEMU_CHECK_FAIL__` marker。

## 说明

本轮 focused gate 的 `guest_check_seconds=845` 主要耗在既有 runtime unit reload 慢路径；serial/GET_ID marker 通过后，后续 rootfs/direct IO 和 poweroff 均继续通过。

## 边界

本轮只声明块设备身份控制请求与 sysfs serial 路径闭合。仍未实现或声明：discard/write-zeroes/secure erase、多队列、event idx、malformed descriptor fuzz、断电恢复、fsck 恢复或 QEMU 级完整 block 设备。
