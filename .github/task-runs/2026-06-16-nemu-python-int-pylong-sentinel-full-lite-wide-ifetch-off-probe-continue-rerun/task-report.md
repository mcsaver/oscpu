# Task Report

## 基本信息

- `task_id`: 2026-06-16-nemu-python-int-pylong-sentinel-full-lite-wide-ifetch-off-probe-continue-rerun
- `trace_id`: manual:nemu-python-int-pylong-sentinel-full-lite-wide-ifetch-off-probe-continue-rerun
- `profile`: nemu-dev / manual heavy focused reproducer
- `status`: completed-pass
- `owner`: nemu + agent-system

## 任务目标

- 用已修 runner 重新运行 `full-lite + NEMU_INTERPRETER_WIDE_IFETCH=0` 重型 focused reproducer。
- 验证 prewarm-fail 继续 probe 的 runner 修改没有破坏正常 PASS 路径，并继续采样 [76] 的复现概率。

## 配置

- full Ubuntu 22.04 rootfs，独立 overlay: `evidence/nemu-python-int-full-lite-wide-ifetch-off-probe-continue-rerun/rootfs-overlay.raw`
- `NEMU_INTERPRETER_WIDE_IFETCH=0`
- `NEMU_PYTHON_INT_STAGE_MODE=full-lite`
- `NEMU_PYTHON_INT_LOOPS=10`
- `NEMU_PYTHON_INT_CHECK_MAX_CYCLES=320000000000`
- `NEMU_PYTHON_INT_CHECK_TIMEOUT=9000`
- `NEMU_PYTHON_INT_BOOT_TIMEOUT=3600`
- `NEMU_PYTHON_INT_POWEROFF=0`

## 结果

- `run.rc`: 0
- summary: `status=pass`
- runtime flags: `wide_ifetch=0 decode_cache=1 vaddr_host_fast=1 mmu_tlb=1`
- six stages all `stage_rc.*=0`
- timing: boot 138s, total 358s

## 关键证据

- `__NEMU_PYTHON_INT_PREFLIGHT_DONE__ rc=0`
- `PYLONG_ARGS_LOOPS_OB_SIZE=1`
- `PYLONG_ARGS_LOOPS_OB_DIGIT0=10`
- `PYLONG_ARGS_LOOP_STOP_OB_DIGIT0=11`
- `PYLONG_VALUE_2_LAYOUT_OK=1`
- `PYLONG_INT_FROM_BYTES_BYTES_LAYOUT_OK=1`
- 负向扫描无 `Traceback`、`OverflowError`、`ValueError`、`AssertionError`、`PYLONG_*_MISMATCH` 或 `PYLONG_*_ERROR`。

## 关联修复验证

- 上传到 guest 的 `python-int-preflight.cmd` 包含 `__NEMU_PYTHON_INT_STAGE_PREWARM_FAILED_PROBE_CONTINUE__` 与 `__NEMU_PYTHON_INT_STAGE_PROBE_RC__`。
- 因本 run 未触发 prewarm failure，console 不会出现 `PREWARM_FAILED_PROBE_CONTINUE`，这是正常 PASS 路径。
- `.github/task-runs/2026-06-16-2026-06-16-nemu-pylong-console-visible-probe-rc-contract/` 证明 NEMU-only e2e 合同已覆盖新增 marker。

## 边界

- 这是同配置的一条 PASS 样本，不能抵消前两条 `full-lite + wide-ifetch-off` fail-diagnostic。
- [76] 仍是 NEMU full Ubuntu 当前 blocker；下一次复现应观察 console-visible probe rc 和对象状态。
