# Dispatch Log

| node_id | owner | status | evidence |
| --- | --- | --- | --- |
| recall | agent-system | PASS | live `.github/AGENTS.md`、copilot instructions、project-status、known-issues、nemu/agent-system memory、agent-e2e workflow |
| implement-focused-probe | nemu | PASS | `Linux/tools/nemu-python-int-preflight.py`、`Linux/scripts/check-nemu-python-int-preflight.sh`、`Linux/Makefile` |
| e2e-contract | agent-system | PASS | `.github/task-runs/2026-06-16-2026-06-16-nemu-python-int-focused-contract-rerun/` |
| real-focused-run | nemu | PASS | `evidence/nemu-python-int-preflight/console.log`、`nemu.log`、`python-int-preflight.cmd` |
| record | agent-system | PASS | 本 report、memory 待同步 |

## 关键命令

```bash
bash -n Linux/scripts/check-nemu-python-int-preflight.sh scripts/e2e/modules/nemu.sh
python3 -m py_compile Linux/tools/nemu-python-int-preflight.py
make -C Linux ARCH=riscv64-nemu check-nemu-python-int-preflight -n
NEMU_PYTHON_INT_CHECK_LOG_DIR=/home/lyg/PA/ysyx-workbench/.github/task-runs/2026-06-16-nemu-python-int-focused-gate/evidence/nemu-python-int-preflight \
NEMU_PYTHON_INT_ROOTFS_OVERLAY=/home/lyg/PA/ysyx-workbench/.github/task-runs/2026-06-16-nemu-python-int-focused-gate/evidence/nemu-python-int-preflight/rootfs-overlay.raw \
NEMU_PYTHON_INT_LOOPS=1 \
NEMU_PYTHON_INT_POWEROFF=0 \
NEMU_PYTHON_INT_CHECK_MAX_CYCLES=20000000000 \
NEMU_PYTHON_INT_CHECK_TIMEOUT=1200 \
make -C Linux ARCH=riscv64-nemu check-nemu-python-int-preflight
scripts/agent-e2e.sh --profile nemu-ubuntu-profile --task-slug 2026-06-16-nemu-python-int-focused-contract-rerun --stop-on-fail
```
