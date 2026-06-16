# Dispatch Log

## RECALL

- 读取当前 NEMU/agent/e2e 规则与记忆，确认 wide-ifetch 是 [76] 未闭合 fast-path 矩阵项。
- 保持 NEMU-only，未使用 NPC/integrated profile，也未从 `.github/db-backup` 读取答案。

## DISPATCH

运行：

```bash
NEMU_INTERPRETER_WIDE_IFETCH=0 \
NEMU_PYTHON_INT_CHECK_LOG_DIR=/home/lyg/PA/ysyx-workbench/.github/task-runs/2026-06-16-nemu-python-int-wide-ifetch-off-focused/evidence/nemu-python-int-preflight \
NEMU_PYTHON_INT_ROOTFS_OVERLAY=/home/lyg/PA/ysyx-workbench/.github/task-runs/2026-06-16-nemu-python-int-wide-ifetch-off-focused/evidence/nemu-python-int-preflight/rootfs-overlay.raw \
NEMU_PYTHON_INT_LOOPS=3 \
NEMU_PYTHON_INT_POWEROFF=0 \
NEMU_PYTHON_INT_CHECK_MAX_CYCLES=60000000000 \
NEMU_PYTHON_INT_CHECK_TIMEOUT=2400 \
make -C Linux ARCH=riscv64-nemu check-nemu-python-int-preflight
```

## VERIFY

- 退出码 `0`。
- host 输出显示 `runtime wide_ifetch: 0`。
- `console.log` 含 focused loop 1/2/3 的 rc=0 和 done rc=0。
- 无 `__NEMU_CHECK_FAIL__` 或 `__PYTHON_INT_PREFLIGHT_FAIL__` 命中。

