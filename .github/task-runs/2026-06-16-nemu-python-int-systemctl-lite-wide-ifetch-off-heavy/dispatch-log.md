# Dispatch Log

## RECALL

- 读取 `.github/memory/project-status.md`、`.github/memory/known-issues.md`、`.github/memory/modules/nemu.md`、`.github/memory/modules/agent-system.md`。
- 复核 `Linux/scripts/check-nemu-python-int-preflight.sh` 与 `Linux/tools/nemu-python-int-preflight.py` 当前实现。

## PLAN

- 使用已有 `check-nemu-python-int-preflight` Make target。
- 与默认 `systemctl-lite` baseline 保持同 stage/loops 口径。
- 只关闭 `NEMU_INTERPRETER_WIDE_IFETCH`，并放宽 timeout/cycle 预算，避免并行 NPC 负载造成误判。

## DISPATCH

- `scripts/agent-e2e.sh --validate-profile --profile nemu-ubuntu-profile`：PASS。
- `pgrep -af check-nemu-python-int-preflight`：无活跃 NEMU PyLong run。
- `pgrep -af NpcSimTop`：发现 NPC tty-reader access trace 长跑；按用户要求不清理、不杀进程，仅在 report 中记录并放宽预算。

## VERIFY

- runner 语法：`bash -n .../run-systemctl-lite-wide-ifetch-off-heavy.sh` PASS。
- 后台启动：Windows `wsl.exe` PID `4428`。
- `run.rc=0`。
- `run.log`：`[nemu-python-int] PASS`，`boot_seconds=145 total_seconds=371`。
- summary：
  - `status=pass`
  - `runtime.wide_ifetch=0`
  - `stage_count=8`
  - all `stage_rc.*=0`
  - `done_line=__NEMU_PYTHON_INT_PREFLIGHT_DONE__ rc=0`
- console stage markers：
  - `__NEMU_PYTHON_INT_STAGE_RC__:before-runtime:0`
  - `__NEMU_PYTHON_INT_STAGE_RC__:runtime-after-core-tools:0`
  - `__NEMU_PYTHON_INT_STAGE_RC__:runtime-after-systemd-files:0`
  - `__NEMU_PYTHON_INT_STAGE_RC__:runtime-after-systemctl-daemon-reload:0`
  - `__NEMU_PYTHON_INT_STAGE_RC__:runtime-after-systemctl-root-enable:0`
  - `__NEMU_PYTHON_INT_STAGE_RC__:runtime-after-systemctl-runtime-start:0`
  - `__NEMU_PYTHON_INT_STAGE_RC__:runtime-after-systemctl:0`
  - `__NEMU_PYTHON_INT_STAGE_RC__:after-runtime:0`
- console 负向扫描：未发现 `__NEMU_CHECK_FAIL__`、`Traceback`、`OverflowError`、`ValueError`、`AssertionError`。

## RECORD

- `index-evidence --write-index --yes`：PASS，`assets=9 runs=1 index_docs=1 stored_index_docs=1`。
- `archive-markdown ... --backup-dir .github/db-backup/task-runs --yes`：PASS，stored `task-report.md`、`dispatch-log.md`、`evidence-index.md`。
- 更新 `.github/memory/project-status.md`、`.github/memory/modules/nemu.md`、`.github/memory/known-issues.md`、`.github/memory/modules/agent-system.md`。
- `update-stored` 同步上述 memory；最终 doctor verbose 发现 live `.github/memory/modules/npc.md` 也有 strict stale，按 live 文件同步 stored，避免当前 memory drift 残留。
- `snapshot-stored --backup-dir .github/db-backup/stored-snapshot --yes`：PASS。
- `doctor --fail-on-drift --show-nonblocking-drift`：PASS，`blocking_drift=0 nonblocking_drift=0`。
- `audit-db-first`：PASS。
- `audit-markdown-coverage --fail-on-live-evidence`：PASS。
