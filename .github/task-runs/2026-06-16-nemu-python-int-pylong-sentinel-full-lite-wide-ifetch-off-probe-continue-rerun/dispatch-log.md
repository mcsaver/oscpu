# Dispatch Log

## 2026-06-16

- 依据 [76] 剩余缺口，用已修 `check-nemu-python-int-preflight.sh` 再跑同口径 `full-lite + NEMU_INTERPRETER_WIDE_IFETCH=0`。
- 运行前检查 WSL 进程，确认没有本 agent 遗留的 stale `github_index_db.py smoke`；NPC raw-proc 诊断仍在运行，按并行开发策略保留不杀，只作为环境背景记录。
- 新建独立 `run-heavy.sh`，避免覆盖前两条 fail-diagnostic evidence。
- 重型 run 退出 0，summary 显示 6 个 stage 全部 rc=0，`__NEMU_PYTHON_INT_PREFLIGHT_DONE__ rc=0`。
- 解析 console：PyLongObject sentinel 正常，未见 traceback/overflow/value/assert/mismatch。
- 运行 `nemu-dev` e2e 合同 `.github/task-runs/2026-06-16-2026-06-16-nemu-pylong-console-visible-probe-rc-contract/`，验证新增 prewarm/probe rc marker 已纳入 NEMU-only profile。

## Evidence

- `evidence/nemu-python-int-full-lite-wide-ifetch-off-probe-continue-rerun/console.log`
- `evidence/nemu-python-int-full-lite-wide-ifetch-off-probe-continue-rerun/run.log`
- `evidence/nemu-python-int-full-lite-wide-ifetch-off-probe-continue-rerun/python-int-preflight-summary.tsv`
- `.github/task-runs/2026-06-16-2026-06-16-nemu-pylong-console-visible-probe-rc-contract/`
