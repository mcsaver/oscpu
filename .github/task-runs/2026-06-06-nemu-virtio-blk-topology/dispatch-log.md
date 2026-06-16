# Dispatch Log

## 基本信息

- `task_id`: `2026-06-06-nemu-virtio-blk-topology`
- `task_slug`: `nemu-virtio-blk-topology`
- `graph_template`: `rv64-ubuntu-rootfs-loop`
- `log_policy`: `append-only`

## 记录格式

每次节点派发、状态变化、失败恢复、handoff 或证据补充时，追加一个条目。

---

### [2026-06-06 19:40] `recall` - `completed`

- `owner_agent`: `codex`
- `trigger`: 自动继续 active goal。
- `depends_on`: 无
- `inputs`: 上传路线图、`.github/AGENTS.md`、RV64/rootfs instructions、memory
- `action`: 复核阶段 A 剩余项，选择 virtio-blk capacity/topology 子项。
- `outputs`: 本轮 scope 为 `VIRTIO_BLK_F_TOPOLOGY`。
- `evidence`: memory 中 RTC/RNG 已闭合，virtio-blk 仍有 feature/capacity/topology 缺口。
- `handoff_to`: `virtio-topology-contract`
- `next_step`: 修改 `disk.c`。
- `notes`: 总 goal 不关闭。

### [2026-06-06 19:50] `virtio-topology-contract` - `completed`

- `owner_agent`: `codex`
- `trigger`: Linux `virtio_blk` 支持 `VIRTIO_BLK_F_TOPOLOGY` 并会读取 config 字段。
- `depends_on`: `recall`
- `inputs`: `Linux/env/src/linux/include/uapi/linux/virtio_blk.h`、`Linux/env/src/linux/drivers/block/virtio_blk.c`、`nemu/src/device/disk.c`
- `action`: 增加 feature bit 10，并返回 `physical_block_exp=0`、`alignment_offset=0`、`min_io_size=1`、`opt_io_size=0`。
- `outputs`: NEMU virtio-blk topology feature/config。
- `evidence`: `NEMU_HOME=... make -C nemu -j$(nproc)` PASS。
- `handoff_to`: `guest-topology-gate`
- `next_step`: 新增 guest sysfs 检查。
- `notes`: 只暴露保守一致拓扑，不声明复杂磁盘 layout。

### [2026-06-06 20:00] `guest-topology-gate` - `completed`

- `owner_agent`: `codex`
- `trigger`: 需要证明 Linux driver 真协商 feature 并更新 queue topology。
- `depends_on`: `virtio-topology-contract`
- `inputs`: `Linux/scripts/check-nemu-systemd-guest.sh`
- `action`: 读取 `/sys/block/vda/queue/minimum_io_size`、`optimal_io_size`、`/sys/block/vda/alignment_offset`，并检查 virtio features bit 10。
- `outputs`: 新增 topology marker 和 hard gate。
- `evidence`: `bash -n` PASS，`git diff --check` PASS。
- `handoff_to`: `verify`
- `next_step`: 跑 focused Ubuntu gate。
- `notes`: 与既有 blk_size/flush/indirect gate 放在同一段。

### [2026-06-06 20:15] `verify` - `completed`

- `owner_agent`: `codex`
- `trigger`: 代码和脚本静态验证已通过。
- `depends_on`: `guest-topology-gate`
- `inputs`: NEMU binary、Ubuntu rootfs、OpenSBI、NEMU rootfs DTB
- `action`: 运行 focused `make -C Linux ARCH=riscv64-nemu ... check-nemu-systemd-guest`，压力参数为 0s soak、1MiB fs stress、8 metadata files、4 process loops、64 UART RX lines、1 个 1MiB direct IO job。
- `outputs`: `.github/task-runs/2026-06-06-nemu-virtio-blk-topology/console.log`、`perf.tsv`
- `evidence`: gate PASS；perf `boot=237s/guest_check=576s/poweroff=21s/total=834s`；marker `__NEMU_CHECK_VDA_MIN_IO__:512`、`__NEMU_CHECK_VDA_OPT_IO__:0`、`__NEMU_CHECK_VDA_ALIGNMENT_OFFSET__:0`、`virtio-blk-feature-topology`、systemd rc=0、`HIT GOOD TRAP`。
- `handoff_to`: `record`
- `next_step`: 更新 memory。
- `notes`: 失败扫描只命中 shell 函数定义行，没有实际 fail marker。

### [2026-06-06 20:30] `record` - `completed`

- `owner_agent`: `codex`
- `trigger`: 跨模块/长链调试要求 RECORD。
- `depends_on`: `verify`
- `inputs`: 验证命令、perf、console marker
- `action`: 更新 `.github/memory/project-status.md`、`.github/memory/modules/nemu.md`、`.github/memory/known-issues.md`，补 task-run 报告。
- `outputs`: 本目录 `task-report.md`、`dispatch-log.md`
- `evidence`: 文件已写入，并纳入最终 diff/空白检查。
- `handoff_to`: 无
- `next_step`: 继续路线图剩余项。
- `notes`: 本轮只记录 topology 切片完成。
