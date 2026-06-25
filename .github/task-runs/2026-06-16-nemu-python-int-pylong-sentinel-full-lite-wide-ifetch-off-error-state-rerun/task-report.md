# Task Report

## 基本信息

- `task_id`: 2026-06-16-nemu-python-int-pylong-sentinel-full-lite-wide-ifetch-off-error-state-rerun
- `trace_id`: manual:nemu-python-int-pylong-sentinel-full-lite-wide-ifetch-off-error-state-rerun
- `profile`: nemu-dev / manual heavy focused reproducer
- `status`: fail-diagnostic
- `owner`: nemu + agent-system

## 任务目标

- 使用当前 `PyLongObject` sentinel 重新运行 `full-lite + NEMU_INTERPRETER_WIDE_IFETCH=0` 重型 focused reproducer。
- 验证前一轮 `ARGS_LOOPS` 参数阶段异常 evidence gap 是否能在再次复现时输出对象级状态。

## 配置

- full Ubuntu 22.04 rootfs，独立 overlay: `evidence/nemu-python-int-full-lite-wide-ifetch-off-error-state-rerun/rootfs-overlay.raw`
- `NEMU_INTERPRETER_WIDE_IFETCH=0`
- `NEMU_PYTHON_INT_STAGE_MODE=full-lite`
- `NEMU_PYTHON_INT_LOOPS=10`
- `NEMU_PYTHON_INT_CHECK_MAX_CYCLES=320000000000`
- `NEMU_PYTHON_INT_CHECK_TIMEOUT=9000`
- `NEMU_PYTHON_INT_BOOT_TIMEOUT=3600`
- `NEMU_PYTHON_INT_POWEROFF=0`

## 结果

- `run.rc`: 2
- summary: `status=fail`
- runtime flags: `wide_ifetch=0 decode_cache=1 vaddr_host_fast=1 mmu_tlb=1`
- stage rc:
  - `before-runtime`: 0
  - `runtime-after-core-tools`: 0
  - `runtime-after-identity`: 0
  - `runtime-after-systemd-files`: 0
  - `runtime-after-journal`: 0
  - `after-runtime`: 1
- timing: boot 139s, total 344s

## 关键证据

- `runtime-after-journal` prewarm 和 PyLong/int probe 均 PASS，console 中 `PYLONG_ARGS_LOOPS_OB_SIZE=1`、`PYLONG_ARGS_LOOPS_OB_DIGIT0=10`、`PYLONG_ARGS_LOOP_STOP_OB_DIGIT0=11`。
- `after-runtime` 在 prewarm 阶段触发 `/usr/lib/python3.10/datetime.py` 的 `timedelta(days=999999999, ...)` assert: `assert abs(microseconds) < 3.1e6`。
- 因旧 runner 在 prewarm fail 后直接短路，本 run 仍未进入 `after-runtime` 的 PyLong probe，因此没有产生 `ARGS_LOOPS_ERROR_STATE`。

## 修复/适配

- `Linux/scripts/check-nemu-python-int-preflight.sh` 已改为 prewarm fail 后仍继续尝试同 stage PyLong probe。
- 新增 marker:
  - `__NEMU_PYTHON_INT_STAGE_PREWARM_FAILED_PROBE_CONTINUE__:<stage>:<rc>`
  - `__NEMU_PYTHON_INT_STAGE_PROBE_RC__:<stage>:<rc>`
- `scripts/e2e/modules/nemu.sh` 与 `.github/e2e/modules/nemu.md` 已同步合同。

## 验证

- `python3 -m py_compile Linux/tools/nemu-python-int-preflight.py` PASS
- `bash -n Linux/scripts/check-nemu-python-int-preflight.sh scripts/e2e/modules/nemu.sh scripts/agent-e2e.sh .../run-heavy.sh` PASS
- `scripts/agent-e2e.sh --validate-profile --profile nemu-dev` PASS
- `.github/task-runs/2026-06-16-2026-06-16-nemu-pylong-prewarm-fail-probe-contract/` PASS，slice log 含新增 marker 的 PASS 行。

## 边界

- 这是 NEMU full Ubuntu PyLong/int blocker 的重型复现和 evidence 采集链修复，不是完整 Ubuntu 22.04 hard gate 完成。
- 本 run 再次证明 `full-lite + wide-ifetch-off` 可复现 [76]，但失败点在 prewarm `datetime` assert；下一轮应使用已修 runner 重跑同配置，确认 prewarm fail 后能继续输出 PyLong object sentinel。
