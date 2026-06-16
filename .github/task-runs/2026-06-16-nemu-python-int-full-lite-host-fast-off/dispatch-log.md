# Dispatch Log

## 基本信息

- `task_id`: 2026-06-16-nemu-python-int-full-lite-host-fast-off
- `task_slug`: nemu-python-int-full-lite-host-fast-off
- `graph_template`: `hardware-aware-software-loop`
- `log_policy`: `append-only`

---

### [2026-06-16] `host-fast-off-staged-run` - `PASS`

- `owner_agent`: Codex
- `trigger`: staged PyLong fast-path A/B
- `depends_on`: wide-ifetch-off-diag-rerun
- `inputs`: `NEMU_VADDR_HOST_FAST=0`, `NEMU_PYTHON_INT_STAGE_MODE=full-lite`, `NEMU_PYTHON_INT_LOOPS=5`, `MAX_CYCLES=120000000000`
- `action`: 运行 `make -C Linux ARCH=riscv64-nemu ... check-nemu-python-int-preflight`
- `outputs`: all stages rc=0，done rc=0
- `evidence`: `.github/task-runs/2026-06-16-nemu-python-int-full-lite-host-fast-off/evidence/nemu-python-int-preflight/python-int-preflight-summary.tsv`
- `handoff_to`: memory-record
- `next_step`: index evidence and update memory
- `notes`: slow path total_seconds=479。
