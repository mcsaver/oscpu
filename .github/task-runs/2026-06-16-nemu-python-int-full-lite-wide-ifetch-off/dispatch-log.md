# Dispatch Log

## 基本信息

- `task_id`: 2026-06-16-nemu-python-int-full-lite-wide-ifetch-off
- `task_slug`: nemu-python-int-full-lite-wide-ifetch-off
- `graph_template`: `hardware-aware-software-loop`
- `log_policy`: `append-only`

---

### [2026-06-16] `wide-ifetch-off-staged-run` - `FAIL-as-signal`

- `owner_agent`: Codex
- `trigger`: staged PyLong fast-path A/B
- `depends_on`: staged focused gate implementation
- `inputs`: `NEMU_INTERPRETER_WIDE_IFETCH=0`, `NEMU_PYTHON_INT_STAGE_MODE=full-lite`, `NEMU_PYTHON_INT_LOOPS=5`, `MAX_CYCLES=80000000000`
- `action`: 运行 `make -C Linux ARCH=riscv64-nemu ... check-nemu-python-int-preflight`
- `outputs`: `runtime-after-journal` stage rc=1，done rc=1
- `evidence`: `.github/task-runs/2026-06-16-nemu-python-int-full-lite-wide-ifetch-off/evidence/nemu-python-int-preflight/console.log`
- `handoff_to`: wide-ifetch-off-diag-rerun
- `next_step`: 增强 probe loops 参数诊断后重跑
- `notes`: `after-runtime` stage 恢复 rc=0，符合 transient 形态。

