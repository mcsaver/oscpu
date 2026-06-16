# Dispatch Log

## 基本信息

- `task_id`: 2026-06-16-nemu-python-int-systemctl-lite-host-fast-off-heavy
- `trace_id`: manual:nemu-python-int-systemctl-lite-host-fast-off-heavy
- `task_slug`: nemu-python-int-systemctl-lite-host-fast-off-heavy
- `graph_template`: hardware-aware-software-loop + modular-agent-e2e
- `profile`: nemu-ubuntu-profile
- `log_policy`: append-only

---

### [2026-06-16] `recall-profile-boundary` - `PASS`

- `owner_agent`: agent-system
- `module`: nemu
- `trigger`: user goal continuation
- `depends_on`:
- `inputs`: `.github/memory/modules/nemu.md` + `.github/memory/modules/agent-system.md`
- `action`: 复核 PyLong/int [76] 当前状态，验证 `nemu-ubuntu-profile` 为 NEMU-only closure
- `outputs`: `scripts/agent-e2e.sh --validate-profile --profile nemu-ubuntu-profile` PASS
- `evidence`: terminal output
- `handoff_to`: `run-host-fast-off-systemctl-lite`
- `next_step`: 创建并启动 host-fast-off systemctl-lite 重型 A/B
- `notes`: 启动前发现 NPC `tty-reader-raw-bytes-loop` 仍活跃；本轮记录并继续，不杀 NPC。

### [2026-06-16] `run-host-fast-off-systemctl-lite` - `in-progress`

- `owner_agent`: nemu
- `module`: nemu
- `trigger`: PyLong/int [76] host fast path A/B
- `depends_on`: `recall-profile-boundary`
- `inputs`: full Ubuntu rootfs、独立 overlay、`NEMU_VADDR_HOST_FAST=0`
- `action`: `run-systemctl-lite-host-fast-off-heavy.sh`
- `outputs`: `evidence/run.log`、`evidence/run.rc`、`python-int-preflight-summary.tsv`、guest console
- `evidence`: `.github/task-runs/2026-06-16-nemu-python-int-systemctl-lite-host-fast-off-heavy/evidence/`
- `handoff_to`: `inspect-host-fast-off-result`
- `next_step`: 等待 run 完成并做 stage/negative scan
- `notes`: wall time 受并行 NPC 负载影响，不作为性能基线。

### [2026-06-16] `inspect-host-fast-off-result` - `FAIL-diagnostic`

- `owner_agent`: nemu
- `module`: nemu
- `trigger`: `run-host-fast-off-systemctl-lite` 完成
- `depends_on`: `run-host-fast-off-systemctl-lite`
- `inputs`: `evidence/run.log`、`evidence/run.rc`、`evidence/python-int-systemctl-lite-host-fast-off/console.log`
- `action`: 扫描 `__NEMU_PYTHON_INT_STAGE_RC__`、`Traceback`、`__NEMU_PYTHON_INT_PREFLIGHT_DONE__`
- `outputs`: `runtime-after-systemctl` 阶段 `datetime.timedelta(microseconds=1)` 断言失败，`after-runtime` 随后恢复为 `rc=0`
- `evidence`: `.github/task-runs/2026-06-16-nemu-python-int-systemctl-lite-host-fast-off-heavy/evidence/python-int-systemctl-lite-host-fast-off/console.log`
- `handoff_to`: `fix-summary-finalizer`
- `next_step`: 修复失败路径 summary 不 finalize 的环境证据链 bug
- `notes`: `NEMU_VADDR_HOST_FAST=0` 下仍复现，因此 host fast vaddr path 不是必要条件或不是唯一触发条件。

### [2026-06-16] `fix-summary-finalizer` - `PASS`

- `owner_agent`: agent-system
- `module`: nemu + agent-system
- `trigger`: 本 run 的 `python-int-preflight-summary.tsv` 只停在 `status=started`
- `depends_on`: `inspect-host-fast-off-result`
- `inputs`: `Linux/scripts/check-nemu-python-int-preflight.sh`、`scripts/e2e/modules/nemu.sh`
- `action`: 增加 `append_summary_result()`，让失败路径写出 `status=fail`、`fail_reason`、`stage_rc.*`、`boot_seconds`/`total_seconds`；更新 NEMU slice e2e 合同
- `outputs`: 修复后失败路径不再丢最终 summary
- `evidence`: `.github/task-runs/2026-06-16-2026-06-16-nemu-python-int-summary-finalize-contract-rerun/`
- `handoff_to`: `record-memory-and-index`
- `next_step`: 更新 memory、索引 evidence、运行 DB audit
- `notes`: 同时修复 e2e 合同对 `UBUNTU_ROOTFS_REQUIRE_NPC_TTY_READER` 透传的旧字符串误判。
