# Dispatch Log

## 基本信息

- `task_id`: `2026-06-06-nemu-virtio-blk-config-wce`
- `task_slug`: `nemu-virtio-blk-config-wce`
- `graph_template`: `rv64-ubuntu-rootfs-loop`
- `log_policy`: `append-only`

## 记录格式

每次节点派发、状态变化、失败恢复、handoff 或证据补充时，追加一个条目。

---

### [2026-06-06 20:45] `recall` - `completed`

- `owner_agent`: `codex`
- `trigger`: 自动继续 active goal。
- `depends_on`: 无
- `inputs`: 上传路线图、memory、Linux `virtio_blk` 源码
- `action`: 选择阶段 A virtio-blk `CONFIG_WCE/cache_type` 子项。
- `outputs`: 本轮 scope 为 feature bit 11 和 sysfs cache_type。
- `evidence`: Linux 驱动 `cache_type_store()` 通过 config `wce` 1-byte write 控制缓存模式。
- `handoff_to`: `virtio-cache-mode-contract`
- `next_step`: 修改 NEMU `disk.c`。
- `notes`: 不关闭总 goal。

### [2026-06-06 20:55] `virtio-cache-mode-contract` - `completed`

- `owner_agent`: `codex`
- `trigger`: Linux 需要 `VIRTIO_BLK_F_CONFIG_WCE` 才让 `cache_type` 可写。
- `depends_on`: `recall`
- `inputs`: `Linux/env/src/linux/include/uapi/linux/virtio_blk.h`、`Linux/env/src/linux/drivers/block/virtio_blk.c`、`nemu/src/device/disk.c`
- `action`: 暴露 feature bit 11，新增 config offset 32 `wce` 读写，补 1/2/4B MMIO config write，write-through 模式下 `T_OUT` 完成前同步落盘。
- `outputs`: NEMU virtio-blk cache mode 可配置。
- `evidence`: `NEMU_HOME=... make -C nemu -j$(nproc)` PASS。
- `handoff_to`: `guest-cache-type-gate`
- `next_step`: 在 guest-check 中验证 sysfs 可写。
- `notes`: 默认保持 write back。

### [2026-06-06 21:05] `guest-cache-type-gate` - `completed`

- `owner_agent`: `codex`
- `trigger`: 需要证明 Linux guest 真能读写 cache mode。
- `depends_on`: `virtio-cache-mode-contract`
- `inputs`: `Linux/scripts/check-nemu-systemd-guest.sh`
- `action`: 检查 `/sys/block/vda/cache_type` 可见可写，执行 `write through` 和 `write back` 双向切换，并检查 virtio features bit 11。
- `outputs`: 新增 cache_type marker 和 hard gate。
- `evidence`: `bash -n` PASS，`git diff --check` PASS。
- `handoff_to`: `verify`
- `next_step`: 跑 focused Ubuntu gate。
- `notes`: cache_type 切回 write back 后继续跑后续 rootfs stress。

### [2026-06-06 21:20] `verify` - `completed`

- `owner_agent`: `codex`
- `trigger`: 静态验证和 NEMU 构建已通过。
- `depends_on`: `guest-cache-type-gate`
- `inputs`: NEMU binary、Ubuntu rootfs、OpenSBI、NEMU rootfs DTB
- `action`: 运行 focused `make -C Linux ARCH=riscv64-nemu ... check-nemu-systemd-guest`，压力参数为 0s soak、1MiB fs stress、8 metadata files、4 process loops、64 UART RX lines、1 个 1MiB direct IO job。
- `outputs`: `.github/task-runs/2026-06-06-nemu-virtio-blk-config-wce/console.log`、`perf.tsv`
- `evidence`: gate PASS；perf `boot=234s/guest_check=591s/poweroff=20s/total=845s`；marker `__NEMU_CHECK_VDA_CACHE_TYPE__:write back`、`vda-cache-type-visible/writable/write-through/write-back`、`virtio-blk-feature-config-wce`、systemd rc=0、`HIT GOOD TRAP`。
- `handoff_to`: `record`
- `next_step`: 更新 memory。
- `notes`: 日志扫描中的 `PROCESS_LOOPS`、函数定义和 dmesg grep 模式是假阳性，不是实际 fail/panic。

### [2026-06-06 21:35] `record` - `completed`

- `owner_agent`: `codex`
- `trigger`: 跨模块/长链调试要求 RECORD。
- `depends_on`: `verify`
- `inputs`: 验证命令、perf、console marker
- `action`: 更新 `.github/memory/project-status.md`、`.github/memory/modules/nemu.md`、`.github/memory/known-issues.md`，补 task-run 报告。
- `outputs`: 本目录 `task-report.md`、`dispatch-log.md`
- `evidence`: 文件已写入，并纳入最终 diff/空白检查。
- `handoff_to`: 无
- `next_step`: 继续路线图剩余项。
- `notes`: 本轮只记录 CONFIG_WCE 切片完成。
