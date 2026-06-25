# Task Report

## 基本信息

- `task_id`: 2026-06-16-nemu-python-int-pylong-sentinel-full-lite-wide-ifetch-off-heavy
- `trace_id`: manual:2026-06-16-nemu-python-int-pylong-sentinel-full-lite-wide-ifetch-off-heavy
- `task_slug`: nemu-python-int-pylong-sentinel-full-lite-wide-ifetch-off-heavy
- `graph_template`: hardware-aware-software-loop + rv64-ubuntu-probe-loop
- `profile`: nemu-dev / nemu-ubuntu-profile static contract
- `graph_mode`: dynamic diagnostic slice
- `status`: fail-diagnostic
- `owner`: nemu + agent-system
- `started_at`: 2026-06-16
- `updated_at`: 2026-06-16

## 任务目标

- `source_request`: 继续推进 NEMU full Ubuntu 22.04，并让 agent/e2e/DB memory 协同开发；不要用轻量替代重测。
- `goal`: 在更可能复现的 `full-lite + NEMU_INTERPRETER_WIDE_IFETCH=0` 时序下运行 PyLongObject sentinel，捕获 [76] PyLong/int transient 的对象级证据。
- `scope`: NEMU-only full rootfs focused/staged reproducer；不切到 NPC，不声明完整 Ubuntu 22.04 已完成。

## 执行配置

- `script`: `.github/task-runs/2026-06-16-nemu-python-int-pylong-sentinel-full-lite-wide-ifetch-off-heavy/run-heavy.sh`
- `target`: `make -C Linux ARCH=riscv64-nemu check-nemu-python-int-preflight`
- `runtime`: `NEMU_INTERPRETER_WIDE_IFETCH=0`
- `stage_mode`: `full-lite`
- `loops`: `10`
- `max_cycles`: `320000000000`
- `boot_timeout`: `3600`
- `check_timeout`: `9000`
- `poweroff`: `0`
- `rootfs_overlay`: `evidence/nemu-python-int-full-lite-wide-ifetch-off-heavy/rootfs-overlay.raw`

## 结果摘要

- `run.rc`: `2`
- `summary.status`: `fail`
- `summary.done_line`: `__NEMU_PYTHON_INT_PREFLIGHT_DONE__ rc=1`
- `summary.stage_rc.before-runtime`: `0`
- `summary.stage_rc.runtime-after-core-tools`: `0`
- `summary.stage_rc.runtime-after-identity`: `0`
- `summary.stage_rc.runtime-after-systemd-files`: `0`
- `summary.stage_rc.runtime-after-journal`: `0`
- `summary.stage_rc.after-runtime`: `1`
- `boot_seconds`: `139`
- `total_seconds`: `358`

## 关键证据

- `runtime-after-journal` stage 中 PyLong/int probe 第 1 轮仍 PASS，并打印正常 `PYLONG_ARGS_LOOPS_OB_SIZE:1`、`PYLONG_ARGS_LOOPS_OB_DIGIT0:10`、`PYLONG_VALUE_2_LAYOUT_OK:1`、`PYLONG_INT_FROM_BYTES_BYTES_LAYOUT_OK:1`。
- 紧接着普通 `lsb_release` 路径在 `textwrap -> re.compile -> sre_parse` 触发 `OverflowError: the repetition number is too large`。
- `after-runtime` prewarm 自身仍 rc=0，但 probe 进入参数阶段时 `repr(args.loops)` 抛 `ValueError: Exceeds the limit (4300)`，`args.loops + 1` 抛 `OverflowError: too many digits in integer`，同时 `ARGS_LOOPS_BIT_LENGTH` 变为 `276701161105643274181`。
- 该 run 复现了 [76] 的同类小整数/PyLong transient，且位置在 probe baseline 之前，说明对象级 sentinel 必须覆盖 `ARGS_LOOPS` 参数阶段失败。

## 本轮修复

- `Linux/tools/nemu-python-int-preflight.py` 新增 `emit_pylong_error_state()`。
- 当 `ARGS_LOOPS_REPR`、`ARGS_LOOPS_BIT_LENGTH`、`ARGS_LOOPS_PLUS_ONE` 出错，或 `ARGS_LOOPS_BIT_LENGTH > 63` 时，probe 会输出 `PYLONG_ARGS_LOOPS_ERROR_STATE_*`；如果 `loop_stop` 已生成，也输出 `PYLONG_ARGS_LOOP_STOP_ERROR_STATE_*`。
- `scripts/e2e/modules/nemu.sh` 的 static contract 增加 `emit_pylong_error_state("ARGS_LOOPS"`、`%s_ERROR_STATE`、`ARGS_LOOPS_MAX_REASONABLE_BIT_LENGTH`、`ARGS_LOOPS_BIT_LENGTH_CMP_ERROR`。
- `.github/e2e/modules/nemu.md`、`.github/e2e/README.md` 和 `.github/instructions/agent-e2e-workflow.instructions.md` 已同步参数阶段错误态要求。

## 验证

- `python3 -m py_compile Linux/tools/nemu-python-int-preflight.py` PASS。
- 正常 host smoke：`python3 Linux/tools/nemu-python-int-preflight.py --tag host-normal-after-args-state --loops 1` PASS。
- 参数错误态 host smoke：`--loops 18446744073709551616` 按预期 rc=1，并输出 `PYLONG_ARGS_LOOPS_ERROR_STATE_*` 与 `PYLONG_ARGS_LOOP_STOP_ERROR_STATE_*`。
- `bash -n scripts/e2e/modules/nemu.sh scripts/agent-e2e.sh run-heavy.sh` PASS。
- `scripts/agent-e2e.sh --validate-profile --profile nemu-ubuntu-profile` PASS。
- 首轮 `nemu-dev` 合同 run 暴露 e2e 静态合同过拟合运行期字面量 `ARGS_LOOPS_ERROR_STATE`，已修为 helper 调用 + `%s_ERROR_STATE` 模板；rerun `.github/task-runs/2026-06-16-2026-06-16-nemu-python-int-args-loop-error-state-contract-rerun/` PASS。

## 边界

- 这不是 NEMU full Ubuntu 22.04 完成证据；[76] 仍 active。
- 本轮没有定位确定根因，只把复现概率较高的 wide-ifetch-off/full-lite 样本带入 PyLongObject sentinel，并修掉参数阶段证据缺口。
- 当前证据表明 `args.loops`/small-int 状态可在 stage 之间 transient 污染；下一步应用新 `ARGS_LOOPS_ERROR_STATE` sentinel 复跑同类 heavy，或继续从 wide ifetch/guest memory/Python object state 切分。
