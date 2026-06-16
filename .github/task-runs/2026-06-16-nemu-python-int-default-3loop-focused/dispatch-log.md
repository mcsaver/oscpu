# Dispatch Log

## RECALL

- 读取 `.github/AGENTS.md`、`.github/copilot-instructions.md`、`.github/memory/project-status.md`、`.github/memory/known-issues.md`、`.github/memory/modules/nemu.md`、`.github/memory/modules/agent-system.md`、`.github/instructions/agent-e2e-workflow.instructions.md`、`.github/e2e/README.md`。
- 约束：NEMU-only，不切 NPC，不从备份取答案；WSL 工程命令 single-flight。

## DISPATCH

运行：

```bash
NEMU_PYTHON_INT_CHECK_LOG_DIR=/home/lyg/PA/ysyx-workbench/.github/task-runs/2026-06-16-nemu-python-int-default-3loop-focused/evidence/nemu-python-int-preflight \
NEMU_PYTHON_INT_ROOTFS_OVERLAY=/home/lyg/PA/ysyx-workbench/.github/task-runs/2026-06-16-nemu-python-int-default-3loop-focused/evidence/nemu-python-int-preflight/rootfs-overlay.raw \
NEMU_PYTHON_INT_LOOPS=3 \
NEMU_PYTHON_INT_POWEROFF=0 \
NEMU_PYTHON_INT_CHECK_MAX_CYCLES=60000000000 \
NEMU_PYTHON_INT_CHECK_TIMEOUT=1800 \
make -C Linux ARCH=riscv64-nemu check-nemu-python-int-preflight
```

## VERIFY

- 退出码 `0`。
- `console.log` 含 focused loop 1/2/3 的 rc=0 和 done rc=0。
- 无 `__NEMU_CHECK_FAIL__` 或 `__PYTHON_INT_PREFLIGHT_FAIL__` 命中。

