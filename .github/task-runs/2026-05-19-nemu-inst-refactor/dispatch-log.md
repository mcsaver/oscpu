# Dispatch Log: 2026-05-19-nemu-inst-refactor

## Timeline

- 2026-05-19 16:23 +0800: 读取 AGENTS、Copilot 指令、project-status、known-issues 与 NEMU/AM/am-kernels 模块记忆，确认必须先定位结构边界并在完成后写回记忆。
- 2026-05-19 16:23 +0800: 检查 `nemu/src/isa/riscv32/inst.c` 当前 X-macro 表驱动形态、CSR 入口、RV32C 立即数、RV32M/Zb 扩展和 `isa_exec_once()` 可变长取指。
- 2026-05-19 16:24 +0800: 建立基线，`make -C nemu -j4` PASS，`make -C am-kernels/tests/cpu-tests ARCH=riscv32-nemu ALL=add run` PASS，`add` 为 840 inst / 8 us / 105 MIPS。
- 2026-05-19 16:24 +0800: 重构 `inst.c`，按基础设施、CSR、RV32I、RV32M、Zba/Zbb/Zbc/Zbs、RV32C、顶层分发重排；移除 X-macro 表生成层，保留直接 switch 与 `static inline`。
- 2026-05-19 16:25 +0800: 首轮构建发现并修正类型/表达式细节，随后 `make -C nemu -j4` PASS。
- 2026-05-19 16:25 +0800: 执行全量 `cpu-tests`，本地 M/B/C 开启、DIFFTEST 关闭配置下 35/35 PASS。
- 2026-05-19 16:25 +0800: 执行 `ALL=add` 单项，PASS，840 inst / 9 us / 93.3 MIPS；该微基准耗时很短，只作为退化 smoke，不作为稳定性能结论。
- 2026-05-19 16:26 +0800: 执行 `yield-os` 1s smoke，输出重复 `ABAB...` 后因程序常驻被 timeout 终止，符合预期。
- 2026-05-19 16:26 +0800: `git diff --check -- nemu/src/isa/riscv32/inst.c` PASS。
- 2026-05-19 16:26 +0800: 更新项目记忆与本 task-run。
