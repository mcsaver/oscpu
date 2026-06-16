# NEMU Ubuntu block direct IO gate

## 目标
- 继续推进完整 Ubuntu 22.04.5 的块设备/rootfs 挂载方式完善。
- 在已有 `/dev/vda` 容量、logical block size、rootfs stress 之外，补充 Linux driver 直接块设备读、flushbufs 和 rootfs direct IO 证据。

## 实现
- 修改 `Linux/scripts/check-nemu-systemd-guest.sh`。
- 新增 guest 检查：
  - `stat -f -c %T /` 输出 rootfs 文件系统类型，接受 ext4 在 GNU stat 中常见的 `ext2/ext3`。
  - `dd if=/dev/vda ... iflag=direct` 直接读取 64KiB。
  - host 侧对 rootfs 镜像尾部高 offset 64KiB 窗口计算 sha256，guest 侧从 `/dev/vda` 同一 offset 用 `iflag=direct,fullblock` 读回并比对 sha256，验证 virtio-blk/backing image 的高地址映射没有截断或回卷。
  - `blockdev --flushbufs /dev/vda`。
  - rootfs 文件 128KiB `dd oflag=direct conv=fsync` 写入，再 `iflag=direct` 读回并 `cmp`。
  - 多个并发 rootfs direct IO job 同时写入、direct 读回并逐个 `cmp`，默认短 gate 为 4 个 1MiB job，长 gate 为 4 个 2MiB job。

## 验证
- `bash -n Linux/scripts/check-nemu-systemd-guest.sh`：PASS。
- `git diff --check -- Linux/scripts/check-nemu-systemd-guest.sh`：PASS。
- `make -C Linux check-nemu-systemd-guest`：PASS，perf 为 `boot_seconds=244`、`guest_check_seconds=106`、`total_seconds=350`。
- `make -C Linux check-nemu-systemd-guest-long`：PASS，perf 为 `boot_seconds=242`、`guest_check_seconds=170`、`total_seconds=412`、`soak_seconds=120`、`fs_stress_mib=16`、`process_loops=64`、`max_cycles=30000000000`。
- 并发 direct IO 加入后复跑 `make -C Linux check-nemu-systemd-guest`：PASS，perf 为 `boot_seconds=243`、`guest_check_seconds=116`、`total_seconds=359`、`block_parallel_jobs=4`、`block_job_mib=1`。
- 并发 direct IO 加入后复跑 long gate 时先发现 `/proc/stat intr` 单次 awk 采样可偶发读成 0，导致 `interrupts-stat-monotonic` false fail；脚本已改为 sed 提取首个数字并重试 3 次。
- 修正采样后复跑 `make -C Linux check-nemu-systemd-guest-long`：PASS，perf 为 `boot_seconds=242`、`guest_check_seconds=191`、`total_seconds=433`、`soak_seconds=120`、`fs_stress_mib=16`、`process_loops=64`、`block_parallel_jobs=4`、`block_job_mib=2`、`max_cycles=30000000000`。
- 高 offset sha256 校验加入后首次尝试对 start/middle/tail 三个窗口都和 host 启动前镜像比对，默认 gate 完整跑完但最终 rc=1：start/middle hash mismatch，tail match。根因是 rootfs 读写挂载后 systemd/journal 会合法改写前部和中部块，不能把活 rootfs 的这些区域当成静态 backing image 比对；这不是 virtio offset 读错。
- 修正为保留原有 `/dev/vda` head 64KiB direct read 字节数检查，并只对镜像尾部高 offset 稳定窗口做强 sha256 比对。复跑 `timeout 1400s make -C Linux check-nemu-systemd-guest`：PASS，perf 为 `boot_seconds=233`、`guest_check_seconds=193`、`total_seconds=426`，host 侧 `vda hash windows=1`。

关键 marker：
- `__NEMU_CHECK_ROOT_FSTYPE__:ext2/ext3`
- `__NEMU_CHECK_VDA_DIRECT_READ_BYTES__:65536`
- `__NEMU_CHECK_PASS__:vda-direct-read`
- `__NEMU_CHECK_VDA_WINDOW_SHA256__:2147418112:de2f256064a0af797747c2b97505dc0b9f3df0de4f489eac731c23ae9ca9cc31:de2f256064a0af797747c2b97505dc0b9f3df0de4f489eac731c23ae9ca9cc31`
- `__NEMU_CHECK_VDA_WINDOW_COUNT__:1`
- `__NEMU_CHECK_PASS__:vda-direct-read-sha256-windows`
- `__NEMU_CHECK_PASS__:vda-flushbufs`
- `__NEMU_CHECK_ROOTFS_DIRECT_BYTES__:131072`
- `__NEMU_CHECK_PASS__:rootfs-direct-io`
- `__NEMU_CHECK_BLOCK_PARALLEL_JOB__:0:1048576`
- `__NEMU_CHECK_BLOCK_PARALLEL_JOB__:1:1048576`
- `__NEMU_CHECK_BLOCK_PARALLEL_JOB__:2:1048576`
- `__NEMU_CHECK_BLOCK_PARALLEL_JOB__:3:1048576`
- `__NEMU_CHECK_BLOCK_PARALLEL_BYTES__:4194304/4194304`
- `__NEMU_CHECK_PASS__:rootfs-parallel-direct-io`
- `__NEMU_CHECK_FS_STRESS_BYTES__:4194304/4194304`
- `__NEMU_SYSTEMD_CHECK_DONE__ rc=0`

long gate 追加 marker：
- `__NEMU_CHECK_ROOT_FSTYPE__:ext2/ext3`
- `__NEMU_CHECK_VDA_DIRECT_READ_BYTES__:65536`
- `__NEMU_CHECK_PASS__:vda-direct-read`
- `__NEMU_CHECK_PASS__:vda-flushbufs`
- `__NEMU_CHECK_ROOTFS_DIRECT_BYTES__:131072`
- `__NEMU_CHECK_PASS__:rootfs-direct-io`
- `__NEMU_CHECK_BLOCK_PARALLEL_JOB__:0:2097152`
- `__NEMU_CHECK_BLOCK_PARALLEL_JOB__:1:2097152`
- `__NEMU_CHECK_BLOCK_PARALLEL_JOB__:2:2097152`
- `__NEMU_CHECK_BLOCK_PARALLEL_JOB__:3:2097152`
- `__NEMU_CHECK_BLOCK_PARALLEL_BYTES__:8388608/8388608`
- `__NEMU_CHECK_PASS__:rootfs-parallel-direct-io`
- `__NEMU_CHECK_FS_STRESS_BYTES__:16777216/16777216`
- `__NEMU_CHECK_SOAK_UPTIME__:515->713`
- `__NEMU_CHECK_INTERRUPTS__:132771->182586`
- `__NEMU_SYSTEMD_CHECK_DONE__ rc=0`

## 边界
- 这覆盖了 Linux 正常 driver/direct IO/flushbufs 路径，并把多个 guest 进程同时触发 rootfs direct IO 的稳定性纳入默认 gate。
- 活 rootfs 的前部/中部区域会被 systemd/journal 正常写入；跨 host/guest 的静态 sha256 比对应优先选稳定高 offset 或在只读镜像/冻结文件系统场景下执行。
- 仍未覆盖 malformed virtqueue descriptor fuzz、多队列、多 outstanding 或异常注入。
