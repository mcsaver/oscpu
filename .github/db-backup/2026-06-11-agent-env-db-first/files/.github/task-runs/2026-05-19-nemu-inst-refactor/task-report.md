# Task Report: 2026-05-19-nemu-inst-refactor

## Metadata
- task_id: 2026-05-19-nemu-inst-refactor
- status: completed
- owner: Codex
- started_at: 2026-05-19 16:23 +0800
- updated_at: 2026-05-19 16:26 +0800
- graph_template: rv32-reference-loop
- graph_mode: static

## Request
按“基础设施放一起、扩展放一起、分门别类、接口少且易读、运行速度快”的目标，重构 `nemu/src/isa/riscv32/inst.c`，避免拼凑式实现。

## Context Read
- `.github/AGENTS.md`
- `.github/copilot-instructions.md`
- `.github/memory/project-status.md`
- `.github/memory/known-issues.md`
- `.github/memory/modules/nemu.md`
- `.github/memory/modules/abstract-machine.md`
- `.github/memory/modules/am-kernels.md`
- `.github/instructions/memory-protocol.instructions.md`

## Execution Graph
- recall: 读取工程规则与历史记忆，确认当前默认闭环是 `am-kernels -> abstract-machine -> NEMU(reference)`。
- analyze-inst: 阅读 `inst.c`、取指路径、CSR/trap 语义和扩展配置边界，确认需要保留 RV32C 可变长取指、M/B/C Kconfig 门控、illegal trap 行为和 `R(0)=0` 约束。
- baseline: 先运行 `make -C nemu -j4` 与 `make -C am-kernels/tests/cpu-tests ARCH=riscv32-nemu ALL=add run`，记录重构前最小功能/速度基线。
- refactor: 将 `inst.c` 重排为基础设施、CSR、RV32I、RV32M、Zba/Zbb/Zbc/Zbs、RV32C、顶层分发七段；移除 X-macro 表生成层，保留低层数 `static inline` + switch；修正 RV32M `mul` 的宿主有符号溢出风险。
- verify: 重跑 NEMU 构建、cpu-tests 全量、`add` 单项、`yield-os` smoke 和 diff whitespace 检查。
- record: 更新项目总览、模块笔记和本 task-run。

## Verification
- `make -C nemu -j4`: PASS
- `timeout 180s make -C am-kernels/tests/cpu-tests ARCH=riscv32-nemu run`: PASS, 35/35
- `make -C am-kernels/tests/cpu-tests ARCH=riscv32-nemu ALL=add run`: PASS, 840 inst / 9 us / 93.3 MIPS
- `timeout 1s make -C am-kernels/kernels/yield-os ARCH=riscv32-nemu c`: timeout 124 as expected, output contained repeated `ABAB...`
- `git diff --check -- nemu/src/isa/riscv32/inst.c`: PASS

## Changed Files
- `nemu/src/isa/riscv32/inst.c`
- `.github/memory/project-status.md`
- `.github/memory/modules/nemu.md`
- `.github/memory/modules/am-kernels.md`
- `.github/task-runs/2026-05-19-nemu-inst-refactor/task-report.md`
- `.github/task-runs/2026-05-19-nemu-inst-refactor/dispatch-log.md`

## Result
`inst.c` 已形成更接近规范编码分区的结构：基础设施集中，RV32I 热路径直达，M/B/C 扩展按模块收口，非法编码仍走标准 illegal instruction trap，现有 AM/NEMU 回归通过。
