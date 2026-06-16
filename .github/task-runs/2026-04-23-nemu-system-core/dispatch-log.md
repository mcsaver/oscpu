# Dispatch Log

## 基本信息

- `task_id`: `2026-04-23-nemu-system-core`
- `task_slug`: `nemu-system-core`
- `graph_template`: `rv32-reference-loop`
- `log_policy`: `append-only`

## 记录格式

每次节点派发、状态变化、失败恢复、handoff 或证据补充时，追加一个条目。

---

### [2026-04-23 17:48] `recall` - `completed`

- `owner_agent`: Codex
- `trigger`: 用户请求补全异常处理 `inst` 核心。
- `depends_on`: 无
- `inputs`: `.github/AGENTS.md`、`.github/copilot-instructions.md`、memory、NPC study、NEMU/AM 源码。
- `action`: 梳理 AM CTE 对 `csrr/csrw/csrs/csrc/ecall/mret` 的依赖。
- `outputs`: 确认缺口在 NEMU `SYSTEM` opcode 分发。
- `evidence`: `inst.c` 原先仅处理 `ebreak`。
- `handoff_to`: `implement-system`
- `next_step`: 补 CSR 和 trap 指令语义。
- `notes`: 外部中断不是本轮范围。

### [2026-04-23 17:48] `implement-system` - `completed`

- `owner_agent`: Codex
- `trigger`: `recall`
- `depends_on`: `recall`
- `inputs`: `inst.c`、`isa-def.h`、`intr.c`
- `action`: 新增 CSR read/write 分发、`ecall`、`mret`、`wfi` no-op，并补 trap 入口状态维护。
- `outputs`: NEMU 可构建。
- `evidence`: `make -C nemu -j4` 通过。
- `handoff_to`: `verify`
- `next_step`: 运行 AM 测试。
- `notes`: 构建期间 `.git/index` 写入失败为 ignored。

### [2026-04-23 17:48] `am-cte-build-fix` - `completed`

- `owner_agent`: Codex
- `trigger`: AM CTE 构建失败。
- `depends_on`: `implement-system`
- `inputs`: `abstract-machine/am/src/riscv/nemu/cte.c`、`abstract-machine/am/src/riscv/riscv.h`
- `action`: 在 AM RISC-V 公共头补 `MSTATUS_MIE`。
- `outputs`: CTE 可继续构建。
- `evidence`: `am-tests mainargs=i` 重新构建通过并进入运行。
- `handoff_to`: `verify`
- `next_step`: 验证 yield 输出。
- `notes`: 该缺口是验证时暴露的跨模块接口缺失。

### [2026-04-23 17:48] `verify` - `completed`

- `owner_agent`: Codex
- `trigger`: 代码补全完成。
- `depends_on`: `implement-system`, `am-cte-build-fix`
- `inputs`: NEMU 与 AM 镜像。
- `action`: 运行 NEMU 构建、CPU add 单测、AM interrupt/yield smoke。
- `outputs`: 构建与核心回归通过，yield smoke 在 timeout 前持续输出 `y`。
- `evidence`: `make -C nemu -j4` exit 0；`make -C am-kernels/tests/cpu-tests ARCH=riscv32-nemu ALL=add run` PASS；`timeout 3s make -C am-kernels/tests/am-tests ARCH=riscv32-nemu c mainargs=i` 输出 `Hello, AM World` 与 `yyyy`。
- `handoff_to`: `record`
- `next_step`: 更新长期记忆。
- `notes`: timeout 退出码 124 是预期截断，因为 interrupt/yield 测试本身无限循环。
