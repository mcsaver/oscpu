# Dispatch Log

## 2026-06-16

- 读取当前 NEMU/agent/e2e 记忆后，确认 [76] 仍为 NEMU full Ubuntu 当前 blocker，下一步要求 focused/staged reproducer 保留 PyLongObject sentinel。
- 旧 `.github/task-runs/2026-06-16-nemu-python-int-pylong-sentinel-full-lite-wide-ifetch-off-heavy/` 已登记 raw evidence 并归档 Markdown；该 run 复现 `after-runtime` 参数小整数污染，但运行时 probe 还没有 `ARGS_LOOPS_ERROR_STATE`。
- 新建本目录 `run-heavy.sh`，使用当前工作树 probe 重跑同口径 `full-lite + wide-ifetch-off + LOOPS=10 + 320B cycles`。
- 运行前发现 NPC raw-bytes 诊断仍活跃；按当前并行开发策略保留不杀。发现此前超时的 `github_index_db.py smoke` 残留，为本 agent 造成的 stale 环境进程，已清理。
- 重型 rerun 结果为 fail-diagnostic：`runtime-after-journal` PASS，`after-runtime` prewarm `datetime.timedelta` assert，summary finalizer 正常写出 fail 和 stage rc。
- 适配 runner：prewarm fail 后仍继续尝试同 stage PyLong probe，并输出 `PREWARM_FAILED_PROBE_CONTINUE` 与 `STAGE_PROBE_RC`。
- 运行 `nemu-dev` e2e 合同，验证新增 marker 已被 NEMU-only profile 覆盖。

## Evidence

- `evidence/nemu-python-int-full-lite-wide-ifetch-off-error-state-rerun/console.log`
- `evidence/nemu-python-int-full-lite-wide-ifetch-off-error-state-rerun/run.log`
- `evidence/nemu-python-int-full-lite-wide-ifetch-off-error-state-rerun/python-int-preflight-summary.tsv`
- `.github/task-runs/2026-06-16-2026-06-16-nemu-pylong-prewarm-fail-probe-contract/`
