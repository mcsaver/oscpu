# RV64 NEMU DiffTest 闭环任务报告

## 目标

在 `npc/rv64` 后端中补齐 RV64 指令/仿真/AM/NEMU reference 链路，使 `npc/sim` 切到 RV64 后 AM 自动生成 RV64 `lp64` 镜像，并以 NEMU RV64 reference 跑通 cpu-tests 全量和 CoreMark DiffTest。

## 关键改动

- NEMU：`GUEST_ISA=riscv64` 复用共享 RISC-V 源目录，补齐 RV64 CPU_state/CSR、RV64I load/store/OP-32、RV64M/W、RV64B/Zba/Zbb/Zbc/Zbs、RV64C、64-bit trap/打印，并新增 `riscv64-npc_defconfig`。
- NPC：`npc/rv64` 默认开启 DiffTest，`difftest-ref` 构建 `riscv64-nemu-interpreter-so`；RV64 RVC 解码、Zba `.uw`、64-bit bitmanip 与 OP-32 写回控制完成对齐。
- AM/am-kernels：`riscv64-npc` 使用 `rv64im_zicsr_zifencei_zba_zbb_zbc_zbs/lp64`，`riscv32-npc.mk` 可随 `npc/sim` 后端自动切到 RV64；cpu-tests 的 `bitmanip/compressed` 改成 RV64-aware；CoreMark `ITERATIONS` 可由 Makefile 覆盖。
- 调试修复：关闭 NEMU RV64 reference 的 `CONFIG_MEM_RANDOM`，避免 CoreMark 未显式写满的栈槽在高字节上与 NPC 零初始化 PMEM 分叉；补齐 CoreMark 生成的 `slli.uw/sh*add.uw`。

## 验证

- `make -C npc/sim BACKEND=rv64 lint` PASS。
- `make -C npc/sim BACKEND=rv64 -j4` PASS。
- `cd nemu && make riscv64-npc_defconfig && make GUEST_ISA=riscv64 SHARE=1 ENGINE=interpreter -j4` PASS。
- `cd am-kernels/tests/cpu-tests && make ARCH=riscv64-npc run`：40/40 PASS，DiffTest ON。
- `cd am-kernels/benchmarks/coremark && make ARCH=riscv64-npc ITERATIONS=1000 NPC_RUN_ARGS="--max=2500000000 --no-progress" run`：`CoreMark PASS`，`HIT GOOD TRAP`，DiffTest ON，`cycles=1915750807`，`commits=318393507`。

## 结论

RV64 的 NPC/AM/NEMU DiffTest 功能闭环已完成，cpu-tests 全量和 CoreMark 默认迭代均通过。后续如果恢复 RV64 RTL cache 或扩展更多特权级语义，需要继续以 NEMU reference + DiffTest 长跑作为验收门槛。
