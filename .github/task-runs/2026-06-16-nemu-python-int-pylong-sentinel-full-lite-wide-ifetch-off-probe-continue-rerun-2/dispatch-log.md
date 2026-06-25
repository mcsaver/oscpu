# Dispatch Log

## 2026-06-16

- 依据 [76] 的重型采样策略，继续运行同口径 `full-lite + NEMU_INTERPRETER_WIDE_IFETCH=0`。
- 运行前检查 WSL 进程，发现 NPC raw-proc 诊断仍在运行；按 NEMU/NPC 并行开发隔离策略保留，不杀 NPC 流程。
- 新建独立 task-run 与 overlay，避免覆盖上一条 PASS 样本。
- 执行 `run-heavy.sh`，NEMU full Ubuntu 进入 guest 并完成 preflight 流程，最终 `run.rc=2`。
- 解析 `python-int-preflight-summary.tsv`：前四个 stage PASS，`runtime-after-journal` 与 `after-runtime` FAIL。
- 解析 `console.log` 和 `run.log`：失败 stage 的 `args.loops` 仍是 `int` 类型，但 `ob_size` 变为 `-9223372036854775807`，`ob_digit0` 仍为 `10`。
- 确认 runner 侧 console-visible `__NEMU_PYTHON_INT_STAGE_PROBE_RC__` 生效，可以把失败 probe rc 从 stage log 带到主 console。

## Evidence

- `evidence/nemu-python-int-full-lite-wide-ifetch-off-probe-continue-rerun-2/console.log`
- `evidence/nemu-python-int-full-lite-wide-ifetch-off-probe-continue-rerun-2/run.log`
- `evidence/nemu-python-int-full-lite-wide-ifetch-off-probe-continue-rerun-2/python-int-preflight-summary.tsv`
- `evidence/nemu-python-int-full-lite-wide-ifetch-off-probe-continue-rerun-2/python-int-preflight.cmd`
