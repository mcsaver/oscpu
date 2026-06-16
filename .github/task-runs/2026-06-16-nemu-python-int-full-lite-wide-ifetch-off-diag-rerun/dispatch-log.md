# Dispatch Log

## 基本信息

- `task_id`: 2026-06-16-nemu-python-int-full-lite-wide-ifetch-off-diag-rerun
- `task_slug`: nemu-python-int-full-lite-wide-ifetch-off-diag-rerun
- `graph_template`: `hardware-aware-software-loop`
- `log_policy`: `append-only`

---

### [2026-06-16] `add-loop-arg-diagnostics` - `PASS`

- `owner_agent`: Codex
- `trigger`: prior run failed in `range(1, args.loops + 1)`
- `depends_on`: wide-ifetch-off-staged-run
- `inputs`: `Linux/tools/nemu-python-int-preflight.py`
- `action`: 增加 `ARGS_LOOPS_TYPE/REPR/BIT_LENGTH/PLUS_ONE` marker，捕获异常时打印 traceback。
- `outputs`: enhanced probe SHA `d71f7c98589044ad571aa82b6b1ecc5e899269ca5aec447f6c81e9dfa357fd83`
- `evidence`: `python3 -m py_compile Linux/tools/nemu-python-int-preflight.py` PASS
- `handoff_to`: wide-ifetch-off-diag-rerun
- `next_step`: 同场景重跑
- `notes`: 不改变 gate 语义，只提高故障可观测性。

### [2026-06-16] `wide-ifetch-off-diag-rerun` - `PASS`

- `owner_agent`: Codex
- `trigger`: validate transient reproducibility
- `depends_on`: add-loop-arg-diagnostics
- `inputs`: `NEMU_INTERPRETER_WIDE_IFETCH=0`, `full-lite`, loops=5, 80B max inst
- `action`: 运行同场景 staged gate
- `outputs`: all stages rc=0
- `evidence`: `.github/task-runs/2026-06-16-nemu-python-int-full-lite-wide-ifetch-off-diag-rerun/evidence/nemu-python-int-preflight/python-int-preflight-summary.tsv`
- `handoff_to`: host-fast-off-staged-run
- `next_step`: 跑 host-fast-off 对照
- `notes`: 本 run 未复现先前 `args.loops + 1` overflow。

