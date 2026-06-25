# Dispatch Log

## RECALL

- 读取 `.github/AGENTS.md`、`.github/copilot-instructions.md`、`.github/memory/project-status.md`、`.github/memory/known-issues.md`、`.github/memory/modules/nemu.md`、`.github/memory/modules/agent-system.md`、`.github/instructions/agent-e2e-workflow.instructions.md` 和 `.github/e2e/README.md`。
- 当前 blocker 为 [76] NEMU full Ubuntu Python/PyLong transient；最近 host-fast-off sentinel heavy run PASS，但不能关闭根因。

## PLAN

1. 使用 full rootfs、独立 overlay 和 `NEMU_INTERPRETER_WIDE_IFETCH=0` 跑 `full-lite` staged PyLongObject sentinel。
2. 解析 summary、console 和 PyLong marker。
3. 若暴露工具/e2e 证据缺口，优先修工具与合同。
4. 归档 task-run、更新 memory/DB，并运行 doctor/audit。

## DISPATCH

- 新增并运行 `run-heavy.sh`。
- 运行结果为 fail-diagnostic，summary 指向 `after-runtime` stage rc=1。
- 解析 `console.log`，确认 `lsb_release` regex `OverflowError` 和 `args.loops` PyLong/int corruption 同轮出现。

## ADAPT

- 发现 probe 只在 baseline 成功后输出 `PYLONG_ARGS_LOOPS_*`，而本次失败发生在 baseline 前。
- 修改 `Linux/tools/nemu-python-int-preflight.py`，新增 `emit_pylong_error_state()` 并覆盖 `ARGS_LOOPS` 参数阶段错误态。
- 修改 `scripts/e2e/modules/nemu.sh` 和三份 e2e/workflow 文档。
- 首轮 `nemu-dev` 合同 run 失败在静态合同过拟合运行期字面量，修为检查 helper 调用和 `%s_ERROR_STATE` 模板后 rerun PASS。

## VERIFY

- `python3 -m py_compile Linux/tools/nemu-python-int-preflight.py`: PASS。
- host normal smoke `--loops 1`: PASS。
- host error-state smoke `--loops 18446744073709551616`: rc=1 且输出 `PYLONG_ARGS_LOOPS_ERROR_STATE_*`。
- `bash -n scripts/e2e/modules/nemu.sh scripts/agent-e2e.sh run-heavy.sh`: PASS。
- `scripts/agent-e2e.sh --validate-profile --profile nemu-ubuntu-profile`: PASS。
- `.github/task-runs/2026-06-16-2026-06-16-nemu-python-int-args-loop-error-state-contract-rerun/`: PASS。

## RECORD

- 本 task-run 记录 fail-diagnostic 和工具/e2e 修复。
- 后续稳定结论写入 `.github/memory/project-status.md`、`.github/memory/modules/nemu.md`、`.github/memory/modules/agent-system.md` 与 `.github/memory/known-issues.md`。
