# Dispatch Log

## DISPATCH

修改后运行：

```bash
NEMU_PYTHON_INT_CHECK_LOG_DIR=/home/lyg/PA/ysyx-workbench/.github/task-runs/2026-06-16-nemu-python-int-summary-default-3loop/evidence/nemu-python-int-preflight \
NEMU_PYTHON_INT_ROOTFS_OVERLAY=/home/lyg/PA/ysyx-workbench/.github/task-runs/2026-06-16-nemu-python-int-summary-default-3loop/evidence/nemu-python-int-preflight/rootfs-overlay.raw \
NEMU_PYTHON_INT_LOOPS=3 \
NEMU_PYTHON_INT_POWEROFF=0 \
NEMU_PYTHON_INT_CHECK_MAX_CYCLES=60000000000 \
NEMU_PYTHON_INT_CHECK_TIMEOUT=1800 \
make -C Linux ARCH=riscv64-nemu check-nemu-python-int-preflight
```

## VERIFY

- 退出码 `0`。
- `python-int-preflight-summary.tsv` 包含 runtime flags、`status	pass`、done line、boot/total seconds。
- `scripts/agent-e2e.sh --validate-profile --profile nemu-ubuntu-profile` 在脚本变更后 PASS。

