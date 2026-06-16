# Task Report

## 基本信息

- `task_id`: `2026-06-06-nemu-virtio-blk-topology`
- `task_slug`: `nemu-virtio-blk-topology`
- `graph_template`: `rv64-ubuntu-rootfs-loop`
- `graph_mode`: `static+dynamic`
- `status`: `completed`
- `owner`: `codex`
- `started_at`: `2026-06-06`
- `updated_at`: `2026-06-06`

## 任务目标

- `source_request`: 用户要求继续按上传建议优化 NEMU，使其逐步能启动完整规模 Ubuntu 22.04；上传路线图阶段 A 包含“完善 virtio-blk feature：capacity/topology”等设备契约。
- `goal`: 为 NEMU virtio-blk 暴露 Linux 可见的 topology feature/config，并用 Ubuntu rootfs/systemd focused gate 证明 queue topology 由 guest 读取并通过。
- `scope`: 本切片只闭合 `VIRTIO_BLK_F_TOPOLOGY` 和 sysfs queue topology；不声明多队列、event idx、discard/write-zeroes、异步 I/O 或完整 Ubuntu VM 完成。

## 选图说明

- `selected_template`: `rv64-ubuntu-rootfs-loop`
- `why_this_graph`: topology 是 rootfs block 设备契约的一部分，必须同时覆盖 virtio config、feature negotiation、Linux driver/sysfs 和完整 rootfs gate。
- `dynamic_nodes_added`: `virtio-topology-contract`、`guest-topology-gate`
- `why_dynamic_nodes_were_needed`: 既有 rootfs gate 已覆盖 blk_size/flush/indirect/serial，但没有证明 topology feature bit 和 Linux queue topology。

## 节点概览

| node_id | owner_agent | status | inputs | outputs | evidence |
| ------- | ----------- | ------ | ------ | ------- | -------- |
| `recall` | `codex` | `completed` | 上传路线图、AGENTS、RV64/rootfs instructions、memory | 选择阶段 A virtio-blk topology 子项 | 完成判定钩子要求只记录子项 |
| `virtio-topology-contract` | `codex` | `completed` | Linux `virtio_blk.h`、`virtio_blk.c`、NEMU `disk.c` | `VIRTIO_BLK_F_TOPOLOGY` bit 10，config fields 24/25/26/28 | NEMU 构建 PASS |
| `guest-topology-gate` | `codex` | `completed` | `check-nemu-systemd-guest.sh` | 新增 `minimum_io_size`、`optimal_io_size`、`alignment_offset` 和 bit10 gate | focused gate PASS |
| `verify` | `codex` | `completed` | NEMU binary、Ubuntu rootfs、OpenSBI/rootfs DTB | `.github/task-runs/2026-06-06-nemu-virtio-blk-topology` | perf `237/576/21/834s`，systemd rc=0，`HIT GOOD TRAP` |
| `record` | `codex` | `completed` | 验证日志和 marker | memory/task-run 更新 | `project-status.md`、`modules/nemu.md`、`known-issues.md` |

## 关键产物

- `artifacts`: `nemu/src/device/disk.c`、`Linux/scripts/check-nemu-systemd-guest.sh`
- `logs_or_traces`: `.github/task-runs/2026-06-06-nemu-virtio-blk-topology/console.log`、`perf.tsv`
- `linked_memory_updates`: `.github/memory/project-status.md`、`.github/memory/modules/nemu.md`、`.github/memory/known-issues.md`

## 当前阻塞点

- `blockers`: 无 topology 子项阻塞。
- `missing_dependencies`: 完整 block 设备仍缺 `CONFIG_WCE`、`EVENT_IDX`、`DISCARD`、`WRITE_ZEROES`、`MQ`、malformed descriptor fuzz 和异步 I/O。
- `risk_assessment`: 当前 topology 字段是保守功能模型，适合 Linux bring-up；不能当作真实磁盘复杂拓扑或 QEMU 级 block 后端。

## 下一步建议

1. 继续阶段 A virtio-blk：选择 `CONFIG_WCE/writeback` 或 `DISCARD/WRITE_ZEROES`，先做 Linux-visible feature + sysfs/命令 gate。
2. 进入阶段 B 性能项：`pread/pwrite` 替换 `fseeko+fread/fwrite`，并用同一 guest gate 做 A/B perf 对照。

## 模板升级候选

- `repeated_dynamic_subgraph`: `virtio-feature-contract -> config-field -> linux-sysfs-gate -> focused-rootfs-run`
- `should_promote_to_static_template`: `no`
- `reason`: 目前仍是阶段 A 中单个 virtio feature 补洞，可继续挂在 `rv64-ubuntu-rootfs-loop` 下。

## 收尾结论

- `final_result`: `VIRTIO_BLK_F_TOPOLOGY` 子任务完成并通过 Ubuntu rootfs/systemd focused gate；总目标保持 active。
- `evidence_summary`: marker `__NEMU_CHECK_VDA_MIN_IO__:512`、`__NEMU_CHECK_VDA_OPT_IO__:0`、`__NEMU_CHECK_VDA_ALIGNMENT_OFFSET__:0`、`__NEMU_CHECK_PASS__:vda-minimum-io-size`、`__NEMU_CHECK_PASS__:vda-optimal-io-size`、`__NEMU_CHECK_PASS__:vda-alignment-offset`、`__NEMU_CHECK_PASS__:virtio-blk-feature-topology`、`__NEMU_SYSTEMD_CHECK_DONE__ rc=0`、`HIT GOOD TRAP`。
- `notes`: 根据完成判定钩子，本记录只能称为 virtio-blk topology 切片完成，不能把完整 Ubuntu 2204/完整 VM 路线标为完成。
