# RV64 NEMU DiffTest 调度记录

## 调用链梳理

1. `am-kernels` 通过 `ARCH=riscv64-npc` 进入 `abstract-machine/scripts/riscv64-npc.mk`。
2. AM 平台运行桥调用 `npc/sim run BACKEND=rv64`，由 `npc/sim/backends/rv64.mk` 转到 `npc/rv64`。
3. `npc/rv64` 运行时加载 `nemu/build/riscv64-nemu-interpreter-so`，逐条提交后做 DiffTest。
4. NEMU RV64 reference 通过 `GUEST_ISA=riscv64` 走共享 RISC-V 源，使用 `CONFIG_ISA64` 参数化执行语义。

## 调试节点

- cpu-tests 初期已可自检通过，但 DiffTest reference 缺失；先建立 NEMU RV64 shared object 构建路径。
- CoreMark 首次 mismatch 于 `ld a5,16(sp)`，反汇编确认高 16 位来自未显式写入栈字节；根因是 NEMU `CONFIG_MEM_RANDOM=y`，NPC PMEM 为零初始化。修复为 `riscv64-npc_defconfig` 显式关闭 `MEM_RANDOM`。
- CoreMark 重新编译后生成 Zba 指令 `slli.uw/sh1add.uw/sh2add.uw`，暴露 NEMU/NPC 均未覆盖 Zba `.uw`；补齐 `.uw` 语义。
- `sh1add.uw` 后出现 x6 mismatch，根因是 OP-32 Zba 在 DecodeUnit 中先落入 default 清掉写回控制，后续只置 bitmanip/illegal；修复为识别 OP-32 Zba 时恢复 `RD_EN/NEED_WB/WB_SEL_ALU`。

## 最终证据

- `/tmp/rv64_cpu_tests_all.log`：测试列表 40 项全部 PASS。
- `/tmp/rv64_coremark_diff_default.log`：CoreMark 1000 iterations PASS，`HIT GOOD TRAP`，无 DiffTest mismatch。
- `/tmp/rv64_coremark_diff_iter10.log`：短迭代 CoreMark PASS，用于快速覆盖 Zba 生成路径。
