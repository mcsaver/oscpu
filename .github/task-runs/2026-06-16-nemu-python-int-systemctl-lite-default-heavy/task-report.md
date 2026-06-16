# Task Report

## 基本信息

- `task_id`: 2026-06-16-nemu-python-int-systemctl-lite-default-heavy
- `task_slug`: nemu-python-int-systemctl-lite-default-heavy
- `profile`: nemu-dev
- `owner`: nemu

## 目标

在 NEMU-only 环境中运行 `check-nemu-python-int-preflight` 的 `systemctl-lite` 重型 staged gate，贴近 full Ubuntu systemctl/daemon-reload/root-enable/runtime-start 时序，继续定位 PyLong/int transient blocker。

## 配置

- `NEMU_PYTHON_INT_STAGE_MODE`: `systemctl-lite`
- `NEMU_PYTHON_INT_LOOPS`: `10`
- `NEMU_PYTHON_INT_STAGE_TIMEOUT`: `180`
- `NEMU_PYTHON_INT_CHECK_MAX_CYCLES`: `160000000000`
- `NEMU_PYTHON_INT_CHECK_TIMEOUT`: `3600`
- `NEMU_PYTHON_INT_BOOT_TIMEOUT`: `1500`
- `NEMU_PYTHON_INT_POWEROFF`: `0`
- runtime fast path: default enabled

## 结果

- `status`: completed
- `final_result`: PASS; default fast-path `systemctl-lite` staged PyLong gate did not reproduce the transient.
- `boot_seconds`: `75`
- `total_seconds`: `204`
- `stage_count`: `8`
- `stage_rc`: all `0`

## 结论

默认 fast path 下，`systemctl-lite` 覆盖 `daemon-reload`、root enable、runtime start 和 systemctl 后置阶段，10 loops 共 80 次 PyLong/int probe 全部 PASS。该结果不能排除 wide-ifetch、host-fast 或其它路径；它提供了一个更贴近 systemctl 时序的基线，后续应在同一 `systemctl-lite` 配置下切 `NEMU_INTERPRETER_WIDE_IFETCH=0` 和 `NEMU_VADDR_HOST_FAST=0` 继续做 A/B。

## 证据

- `run_script`: `.github/task-runs/2026-06-16-nemu-python-int-systemctl-lite-default-heavy/run-systemctl-lite-default-heavy.sh`
- `run_log`: `.github/task-runs/2026-06-16-nemu-python-int-systemctl-lite-default-heavy/evidence/run.log`
- `summary`: `.github/task-runs/2026-06-16-nemu-python-int-systemctl-lite-default-heavy/evidence/python-int-systemctl-lite-default/python-int-preflight-summary.tsv`
- `console`: `.github/task-runs/2026-06-16-nemu-python-int-systemctl-lite-default-heavy/evidence/python-int-systemctl-lite-default/console.log`
- `nemu_log`: `.github/task-runs/2026-06-16-nemu-python-int-systemctl-lite-default-heavy/evidence/python-int-systemctl-lite-default/nemu.log`
- `run_rc`: `.github/task-runs/2026-06-16-nemu-python-int-systemctl-lite-default-heavy/evidence/run.rc`
