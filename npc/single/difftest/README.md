# NPC Single DiffTest

本目录保存参考模型的加载、状态同步和比较逻辑。它由仿真宿主复用；具体 RTL 自检用例位于
[`../testbench/`](../testbench/README.md)。

| 文件 | 职责 |
| --- | --- |
| [`src/difftest.cpp`](src/difftest.cpp) | 加载 NEMU 动态库、推进参考模型、比较 PC 和 32 个 GPR |
| [`include/cpu/difftest.h`](include/cpu/difftest.h) | 宿主调用接口，以及未启用 DiffTest 时的内联实现 |
| [`filelist.mk`](filelist.mk) | 独立维护 DiffTest 源码和头文件清单 |

调用链为 `sim/src/cpu/cpu-exec.cpp` → `npc_difftest_step()` → NEMU 的
`difftest_exec(1)` / `difftest_regcpy()` → PC/GPR 比较。DUT 数据使用提交后的 `next_pc`，
并将当前提交的写回值叠加到寄存器快照中。当前 RV32 接口只比较 PC 和 GPR，不直接读取 CSR
快照；RV64 后端的比较范围见 [`../../rv64/difftest/`](../../rv64/difftest/README.md)。

初始化通过 `difftest_init`、`difftest_memcpy`、`difftest_regcpy` 同步镜像与复位状态。
宿主设备访问需要跳过参考执行时会调用 `npc_difftest_skip_ref()`，下一次提交把 DUT 状态同步到参考端；
正常提交仍逐条推进并比较，发生不一致会使仿真失败。

`CONFIG_NPC_DIFFTEST=y` 时链接本目录实现和 `libdl`，构建时关闭则不链接 `difftest.cpp`。
配置、`--diff=default|path` / `--no-diff` / `--diff-port` 参数与运行命令见
[`../sim/README.md`](../sim/README.md)。默认参考库是
`nemu/build/riscv32-nemu-interpreter-so`，可用 `make -C npc/single difftest-ref` 构建。
