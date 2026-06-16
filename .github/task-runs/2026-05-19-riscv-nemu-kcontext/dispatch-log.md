# Dispatch Log

## 基本信息

- `task_id`: `2026-05-19-riscv-nemu-kcontext`
- `task_slug`: `riscv-nemu-kcontext`
- `graph_template`: `rv32-reference-loop`
- `log_policy`: `append-only`

## 记录格式

每次节点派发、状态变化、失败恢复、handoff 或证据补充时，追加一个条目。

---

### [2026-05-19 10:41] `recall` - `completed`

- `owner_agent`: `codex`
- `trigger`: 用户要求完成 NEMU 相关内容，结合上一轮解释定位到 `yield-os` 依赖 `kcontext()`。
- `depends_on`: 无
- `inputs`: `.github/AGENTS.md`、`.github/copilot-instructions.md`、`.github/memory/project-status.md`、`.github/memory/known-issues.md`、相关模块 memory、RISC-V CTE/trap 源码。
- `action`: 梳理 `yield()`、`__am_irq_handle()`、`trap.S`、`kcontext()` 调用链。
- `outputs`: 明确根因是 `riscv/nemu/cte.c::kcontext()` 空桩，以及 `riscv/nemu/trap.S` 没有使用 handler 返回的 `Context *`。
- `evidence`: 源码中 `kcontext()` 直接 `return NULL`；`trap.S` 在 `call __am_irq_handle` 后继续从旧 `sp` 恢复。
- `handoff_to`: `fix`
- `next_step`: 实现初始内核上下文并让 trap.S 切换恢复现场。
- `notes`: 当前任务只处理 `riscv32-nemu`。

### [2026-05-19 10:41] `fix` - `completed`

- `owner_agent`: `codex`
- `trigger`: `recall` 节点确认实现缺口。
- `depends_on`: `recall`
- `inputs`: `Context` 布局、RISC-V `mret` 语义、`yield-os` 调度模型。
- `action`: 在 `kcontext()` 中构造对齐后的初始 `Context`；按 PA 讲义为 riscv32 设置 `mstatus=0x1800`（`MPP=M`）；把 trap.S `CONTEXT_SIZE` 对齐到 `Context`，并在 handler 返回后 `mv sp, a0`。
- `outputs`: 3 个源码文件完成修改。
- `evidence`: `abstract-machine/am/src/riscv/nemu/cte.c`、`abstract-machine/am/src/riscv/nemu/trap.S`、`abstract-machine/am/src/riscv/riscv.h` 的 diff。
- `handoff_to`: `verify`
- `next_step`: 构建并运行目标程序。
- `notes`: `npc/single/gmon.out` 为既有无关改动，未触碰。

### [2026-05-19 10:41] `verify` - `completed`

- `owner_agent`: `codex`
- `trigger`: 源码实现完成。
- `depends_on`: `fix`
- `inputs`: 修改后的 AM RISC-V NEMU CTE。
- `action`: 运行 `yield-os`、`cpu-tests add`、`am-tests mainargs=i`。
- `outputs`: `yield-os` 输出交替 `ABAB...`；`cpu-tests add` PASS；`am-tests mainargs=i` 输出 `Hello, AM World` 和 `y`。
- `evidence`: `timeout 3s make -C am-kernels/kernels/yield-os ARCH=riscv32-nemu c` 退出 124 为无限循环 timeout 预期；`make -C am-kernels/tests/cpu-tests ARCH=riscv32-nemu ALL=add run` 退出 0；`timeout 3s make -C am-kernels/tests/am-tests ARCH=riscv32-nemu c mainargs=i` 输出 `y` 后 timeout。
- `handoff_to`: `record`
- `next_step`: 更新记忆文件和任务记录。
- `notes`: NEMU 当前开启 difftest，因此运行日志中有 Spike 差分库加载信息。

### [2026-05-19 10:41] `record` - `completed`

- `owner_agent`: `codex`
- `trigger`: 验证完成。
- `depends_on`: `verify`
- `inputs`: 改动摘要和验证证据。
- `action`: 更新 project/module memory，创建本任务报告与派发日志。
- `outputs`: `.github/memory/project-status.md`、`.github/memory/modules/abstract-machine.md`、`.github/memory/modules/nemu.md`、`.github/memory/modules/am-kernels.md`、`.github/task-runs/2026-05-19-riscv-nemu-kcontext/`。
- `evidence`: 本文件与 `task-report.md`。
- `handoff_to`: 无
- `next_step`: 向用户汇报。
- `notes`: 无
