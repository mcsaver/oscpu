# Dispatch Log

## 基本信息

- `task_id`: 2026-06-16-nemu-python-int-pylong-sentinel-systemctl-lite-host-fast-off-heavy
- `trace_id`: manual:nemu-python-int-pylong-sentinel-systemctl-lite-host-fast-off-heavy
- `graph_template`: hardware-aware-software-loop + rv64-ubuntu-probe-loop
- `log_policy`: append-only

---

### [2026-06-16 16:16 +0800] `run-heavy` - `in-progress`

- `owner_agent`: nemu
- `module`: nemu
- `depends_on`: PyLongObject sentinel contract rerun PASS
- `inputs`: full Ubuntu rootfs, `check-nemu-python-int-preflight`, `NEMU_VADDR_HOST_FAST=0`
- `action`: 执行 `run-heavy.sh`
- `outputs`: NEMU systemctl-lite PyLong sentinel heavy run
- `evidence`: `evidence/nemu-python-int-systemctl-lite-host-fast-off-heavy/run.log`
- `notes`: 保持 NEMU-only，不清理并行 NPC 长跑；wall time 不作为性能基线。

### [2026-06-16 16:26 +0800] `run-heavy` - `PASS`

- `owner_agent`: nemu
- `module`: nemu
- `outputs`: `run.rc=0`，summary `status=pass`，8 个 stage rc 全 0
- `evidence`: `python-int-preflight-summary.tsv`、`console.log`、`run.rc`
- `notes`: guest PyLong layout 为 legacy；无 PyLong mismatch/error/Traceback。
