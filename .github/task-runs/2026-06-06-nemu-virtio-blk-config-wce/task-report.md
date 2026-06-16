# Task Report

## 基本信息

- `task_id`: `2026-06-06-nemu-virtio-blk-config-wce`
- `task_slug`: `nemu-virtio-blk-config-wce`
- `graph_template`: `rv64-ubuntu-rootfs-loop`
- `graph_mode`: `static+dynamic`
- `status`: `completed`
- `owner`: `codex`
- `started_at`: `2026-06-06`
- `updated_at`: `2026-06-06`

## 任务目标

- `source_request`: 用户要求继续按上传建议优化 NEMU，使其逐步能启动完整规模 Ubuntu 22.04；上传路线图阶段 A 包含“完善 virtio-blk feature”。
- `goal`: 为 NEMU virtio-blk 增加 `VIRTIO_BLK_F_CONFIG_WCE`，让 Linux `/sys/block/vda/cache_type` 可读可写，并让 write-through 对后端写入产生真实同步语义。
- `scope`: 本切片只闭合 CONFIG_WCE/cache_type；不声明 discard/write-zeroes、event idx、多队列、异步 I/O 或完整 Ubuntu VM 完成。

## 选图说明

- `selected_template`: `rv64-ubuntu-rootfs-loop`
- `why_this_graph`: CONFIG_WCE 是 rootfs block 设备契约的一部分，需要覆盖 virtio feature、config read/write、Linux sysfs 和完整 rootfs/systemd gate。
- `dynamic_nodes_added`: `virtio-cache-mode-contract`、`guest-cache-type-gate`
- `why_dynamic_nodes_were_needed`: 既有 gate 已覆盖 flush/topology，但没有证明 Linux 可以配置 cache mode。

## 节点概览

| node_id | owner_agent | status | inputs | outputs | evidence |
| ------- | ----------- | ------ | ------ | ------- | -------- |
| `recall` | `codex` | `completed` | 上传路线图、memory、Linux `virtio_blk` 驱动 | 选择 CONFIG_WCE/cache_type 子项 | 不关闭总 goal |
| `virtio-cache-mode-contract` | `codex` | `completed` | `virtio_blk.h`、`virtio_blk.c`、NEMU `disk.c` | feature bit 11、config `wce` read/write、write-through fsync | NEMU 构建 PASS |
| `guest-cache-type-gate` | `codex` | `completed` | `check-nemu-systemd-guest.sh` | cache_type 可见/可写/双向切换 gate | 脚本语法和 diff check PASS |
| `verify` | `codex` | `completed` | NEMU binary、Ubuntu rootfs、OpenSBI、NEMU rootfs DTB | `.github/task-runs/2026-06-06-nemu-virtio-blk-config-wce` | focused gate PASS |
| `record` | `codex` | `completed` | perf、console marker、验证输出 | memory/task-run 更新 | project-status、modules/nemu、known-issues |

## 关键产物

- `artifacts`: `nemu/src/device/disk.c`、`Linux/scripts/check-nemu-systemd-guest.sh`
- `logs_or_traces`: `.github/task-runs/2026-06-06-nemu-virtio-blk-config-wce/console.log`、`perf.tsv`
- `linked_memory_updates`: `.github/memory/project-status.md`、`.github/memory/modules/nemu.md`、`.github/memory/known-issues.md`

## 当前阻塞点

- `blockers`: 无 CONFIG_WCE 子项阻塞。
- `missing_dependencies`: 完整 block 设备仍缺 discard/write-zeroes、event idx、多队列、malformed descriptor fuzz、异步 I/O 和断电恢复 gate。
- `risk_assessment`: write-through 当前用同步 `fflush+fsync` 实现，语义清楚但不是性能优化；性能路线应另走 `pread/pwrite`、批处理或异步 I/O。

## 下一步建议

1. 继续阶段 A：补 `DISCARD`/`WRITE_ZEROES` 中较低风险的一项，并用 `fstrim` 或 `blkdiscard` 类 guest gate 验证。
2. 进入阶段 B：将 virtio-blk 后端从 `fseeko+fread/fwrite` 改为 `pread/pwrite`，减少共享文件偏移和 seek 成本，用同一 focused gate 做 perf A/B。

## 模板升级候选

- `repeated_dynamic_subgraph`: `virtio-feature-contract -> config-rw -> linux-sysfs-rw-gate -> focused-rootfs-run`
- `should_promote_to_static_template`: `no`
- `reason`: 仍是阶段 A 单个 virtio feature 补洞。

## 收尾结论

- `final_result`: `VIRTIO_BLK_F_CONFIG_WCE` 子任务完成并通过 Ubuntu rootfs/systemd focused gate；总目标保持 active。
- `evidence_summary`: marker `__NEMU_CHECK_VDA_CACHE_TYPE__:write back`、`vda-cache-type-visible`、`vda-cache-type-writable`、`vda-cache-type-write-through`、`vda-cache-type-write-back`、`virtio-blk-feature-config-wce`、`__NEMU_SYSTEMD_CHECK_DONE__ rc=0`、`HIT GOOD TRAP`；perf `234/591/20/845s`。
- `notes`: 根据完成判定钩子，本记录只能称为 CONFIG_WCE 切片完成，不能把完整 Ubuntu 2204/完整 VM 路线标为完成。
