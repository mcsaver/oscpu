# Dispatch Log

## 基本信息

- `task_id`: 2026-06-16-nemu-python-int-full-lite-staged-focused
- `task_slug`: nemu-python-int-full-lite-staged-focused
- `graph_template`: `hardware-aware-software-loop`
- `log_policy`: `append-only`

---

### [2026-06-16] `recall-current-state` - `PASS`

- `owner_agent`: Codex
- `trigger`: active goal continuation
- `depends_on`: none
- `inputs`: `.github/AGENTS.md`, `.github/copilot-instructions.md`, `.github/memory/project-status.md`, `.github/memory/known-issues.md`
- `action`: 确认 issue [76] 剩余缺口是 focused 3-loop 触发率不足，需要更接近 full hard gate 的 before/runtime/after stage。
- `outputs`: staged focused gate plan
- `evidence`: `.github/memory/known-issues.md` issue [76]
- `handoff_to`: implement-staged-gate
- `next_step`: 修改 focused runner 和 e2e contract
- `notes`: 未读取 `.github/db-backup`。

### [2026-06-16] `implement-staged-gate` - `PASS`

- `owner_agent`: Codex
- `trigger`: PyLong focused gate 需要多阶段时序
- `depends_on`: recall-current-state
- `inputs`: `Linux/scripts/check-nemu-python-int-preflight.sh`, `Linux/Makefile`, `scripts/e2e/modules/nemu.sh`
- `action`: 增加 `NEMU_PYTHON_INT_STAGE_MODE`、`NEMU_PYTHON_INT_TAGS`、`NEMU_PYTHON_INT_STAGE_PREWARM`、`NEMU_PYTHON_INT_STAGE_TIMEOUT`，并让 Makefile/e2e 静态合同透传和检查这些字段。
- `outputs`: staged PyLong focused gate
- `evidence`: git diff
- `handoff_to`: validate-contract
- `next_step`: 运行静态验证
- `notes`: 默认 mode 仍为 `focused`，不移除旧单阶段能力。

### [2026-06-16] `validate-contract` - `PASS`

- `owner_agent`: Codex
- `trigger`: staged gate source changed
- `depends_on`: implement-staged-gate
- `inputs`: source files
- `action`: 运行 `bash -n Linux/scripts/check-nemu-python-int-preflight.sh scripts/e2e/modules/nemu.sh scripts/agent-e2e.sh` 和 `scripts/agent-e2e.sh --validate-profile --profile nemu-ubuntu-profile`。
- `outputs`: syntax/profile-boundary PASS
- `evidence`: terminal output
- `handoff_to`: python-int-staged-focused-gate
- `next_step`: 启动真实 full rootfs run
- `notes`: `nemu-ubuntu-profile` 仍为 NEMU-only closure。

### [2026-06-16] `python-int-staged-focused-gate` - `PASS`

- `owner_agent`: Codex
- `trigger`: 用户要求不用轻量，直接上重型测试
- `depends_on`: validate-contract
- `inputs`: full rootfs, `NEMU_PYTHON_INT_STAGE_MODE=full-lite`, `NEMU_PYTHON_INT_LOOPS=5`, `NEMU_PYTHON_INT_CHECK_MAX_CYCLES=80000000000`, `NEMU_PYTHON_INT_CHECK_TIMEOUT=2400`, `NEMU_PYTHON_INT_POWEROFF=0`
- `action`: 运行 `make -C Linux ARCH=riscv64-nemu ... check-nemu-python-int-preflight`
- `outputs`: stage_count=6, stage rc all 0, done rc=0
- `evidence`: `.github/task-runs/2026-06-16-nemu-python-int-full-lite-staged-focused/evidence/nemu-python-int-preflight/console.log`, `python-int-preflight-summary.tsv`
- `handoff_to`: memory-record
- `next_step`: index evidence and update memory
- `notes`: 本 run 未复现 PyLong corruption；不能关闭 issue [76]。
