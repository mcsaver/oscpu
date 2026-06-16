# NEMU Ubuntu rootfs metadata tree gate

## 目标
- 继续推进完整 Ubuntu 22.04.5 的 rootfs/块设备挂载方式完善。
- 在既有大文件写回、direct IO、并发 direct IO 和高 offset `/dev/vda` hash 之外，补一个 ext4/VFS 元数据 churn gate。

## 实现
- `Linux/Makefile` 新增：
  - `NEMU_SYSTEMD_FS_TREE_FILES ?= 64`
  - `NEMU_SYSTEMD_LONG_FS_TREE_FILES ?= 128`
  - `NEMU_SYSTEMD_SOAK_FS_TREE_FILES ?= 256`
- `Linux/scripts/check-nemu-systemd-guest.sh` 新增 `NEMU_SYSTEMD_FS_TREE_FILES`：
  - host 侧打印参数并写入 `perf.tsv` 的 `fs_tree_files` 列。
  - guest 侧创建分桶目录树，批量写文件、创建 hardlink、rename 到另一目录。
  - 每个文件校验 moved file 与 hardlink 内容一致、inode 一致。
  - 最后用 `find -type f` 统计文件数，要求 `2 * NEMU_GUEST_FS_TREE_FILES`，并输出 `rootfs-metadata-tree` PASS。
- `Linux/README.md` 和 `Linux/env/README.md` 更新默认/long/soak gate 覆盖说明。

## 验证
- `bash -n Linux/scripts/check-nemu-systemd-guest.sh`：PASS。
- `git diff --check -- Linux/Makefile Linux/scripts/check-nemu-systemd-guest.sh`：PASS。
- `make -C Linux -n check-nemu-systemd-guest-long`：确认 `NEMU_SYSTEMD_FS_TREE_FILES=128` 被传入。
- Focused gate：
  `timeout 1500s make -C Linux check-nemu-systemd-guest NEMU_SYSTEMD_CHECK_LOG_DIR=/home/lyg/PA/ysyx-workbench/Linux/env/logs/linux-front/riscv64-nemu-rootfs-metadata-tree-check NEMU_SYSTEMD_SOAK_SECONDS=0 NEMU_SYSTEMD_FS_STRESS_MIB=1 NEMU_SYSTEMD_FS_TREE_FILES=64 NEMU_SYSTEMD_PROCESS_LOOPS=4 NEMU_SYSTEMD_BLOCK_PARALLEL_JOBS=2 NEMU_SYSTEMD_BLOCK_JOB_MIB=1 NEMU_SYSTEMD_UART_RX_STRESS_LINES=128`
  PASS。
- perf：`boot_seconds=234`、`guest_check_seconds=326`、`poweroff_seconds=20`、`total_seconds=580`、`fs_tree_files=64`。

## 关键 marker
- `__NEMU_CHECK_FS_TREE_FILES__:128/128`
- `__NEMU_CHECK_PASS__:rootfs-metadata-tree`
- `__NEMU_UART_RX_STRESS_COUNT__:128/128`
- `__NEMU_SYSCALL_PROBE_DONE__ rc=0`
- `__NEMU_CHECK_PASS__:syscall-probe`
- `__NEMU_SYSTEMD_CHECK_DONE__ rc=0`
- `syscon-reset: poweroff requested value=0x00005555`
- `HIT GOOD TRAP`

## 边界
- 这增强的是 ext4/rootfs 元数据路径和 virtio-blk backing store 在当前单队列功能模型下的实际 guest 证据。
- 仍不等同于断电恢复、fsck 恢复、virtio malformed descriptor fuzz、多队列、多小时 soak 或 QEMU 级完整虚拟机声明。
