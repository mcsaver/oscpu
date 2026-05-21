# DiffTest 模块笔记

## 当前状态
<!-- DiffTest 配置与通过情况 -->
- 2026-05-21: NPC difftest 默认语义已按验证预期调整：`CONFIG_NPC_DIFFTEST=y` 时，`npc_simconfig_init()` 默认置 `difftest=true`，启动后自动加载 `NPC_DEFAULT_DIFF_SO`（当前为 `nemu/build/riscv32-nemu-interpreter-so`），每条 NPC commit 后执行 `ref_exec(1)` 并比较提交后 GPR/PC。`--diff=default|path` 现在用于显式选择 reference，新增 `--no-diff` 用于本次运行裸跑；`perf_defconfig` 仍保持 `CONFIG_NPC_DIFFTEST=n`，从编译期去掉 reference loader 与热路径检查。welcome 会显示 `Difftest: ON/OFF`，ON 为绿色、OFF 为红色。验证：`make -C npc/single -j4` PASS；`NpcSimTop --help` 显示 `--no-diff`；直接运行 `add-riscv32-npc.bin --no-progress` 默认打印 `[npc-diff] reference enabled...`、`Difftest: ON` 并 GOOD TRAP；追加 `--no-diff --no-progress` 后不加载 reference、显示 `Difftest: OFF` 且 GOOD TRAP。
- 2026-05-20: NPC difftest 由单纯运行时 `--diff=...` 扩展为两层开关：先用 `CONFIG_NPC_DIFFTEST` 决定是否编译 difftest 能力，再用运行参数 `--diff=default|path` 决定本次是否启用 reference。`default_defconfig` 保持 `CONFIG_NPC_DIFFTEST=y`，`perf_defconfig` 使用 `CONFIG_NPC_DIFFTEST=n`；关闭时 `difftest.cpp` 不参与构建，`-ldl` 不参与链接，提交热路径不检查 difftest 状态。验证：关闭配置构建 + 裸跑 `cpu-tests add` PASS；打开配置后 `cpu-tests add NPC_RUN_ARGS='--diff=default -m 0'` PASS；本地最终恢复为进入任务前的关闭配置。
- 2026-05-19: NPC 扩到 RV32IMC + Zba/Zbb/Zbc/Zbs + cache/fence.i + BPU 后，`--diff=default` 继续以 NEMU shared object 为参考，比较范围仍为提交后 GPR 与 PC；全量 `timeout 900s make -C am-kernels/tests/cpu-tests ARCH=riscv32-npc run NPC_RUN_ARGS='--diff=default -m 0'` 38/38 PASS。benchmark 也在同一 difftest 参数下通过：CoreMark 默认 1000 iterations、Dhrystone 默认 500000 runs、MicroBench `mainargs=test` 全部 `HIT GOOD TRAP`。新增 RVC 路径下，NPC 提交给 difftest 的 `commit_inst_o` 是解压后的内部 32-bit 指令，PC 对比以 `commit_next_pc_o` 为准。
- 2026-05-19: 本轮按当前源码复核 `riscv32-npc` difftest，`--diff=default` 的启动日志显示实际加载 `/home/lyg/PA/ysyx-workbench/nemu/build/riscv32-nemu-interpreter-so`；NEMU 自身的 `riscv32-nemu` 回归仍开启 Spike difftest，并加载 `nemu/tools/spike-diff/build/riscv32-spike-so`。验证：`make -C npc/single difftest-ref`、`make -C npc/single lint`、`timeout 300s make -C am-kernels/tests/cpu-tests ARCH=riscv32-npc run NPC_RUN_ARGS='--diff=default -m 0'`，NPC 35/35 PASS；`timeout 180s make -C am-kernels/tests/cpu-tests ARCH=riscv32-nemu run`，NEMU 35/35 PASS。
- 2026-05-19: `riscv32-npc` 已具备运行时可选 difftest：命令行 `--diff=default` 使用 `npc/single/Makefile` 注入的默认 reference so（当前源码为 `nemu/build/riscv32-nemu-interpreter-so`），也可用 `--diff=/path/to/ref.so` 指定；`--diff-port=N` 透传给 reference init。当前比较范围为 RV32 GPR[0..31] 与提交后 PC，不比较 CSR；MMIO 指令通过 `npc_difftest_skip_ref()` 做 reference skip + DUT 状态同步。
- 2026-05-19: 已验证 NPC difftest 回归：`make -C nemu/tools/spike-diff GUEST_ISA=riscv32 SHARE=1 ENGINE=interpreter`、`make -C npc/single lint`、`make -C npc/single` 均通过；`make -C am-kernels/tests/cpu-tests ARCH=riscv32-npc ALL=add run NPC_RUN_ARGS='--diff=default -m 0'` PASS；`timeout 240s make -C am-kernels/tests/cpu-tests ARCH=riscv32-npc run NPC_RUN_ARGS='--diff=default -m 0'` 35/35 PASS；Dhrystone/CoreMark 默认负载和 MicroBench `mainargs=test` 均 PASS。

## 不一致历史
<!-- 曾出现的 NPC vs NEMU 不一致记录 -->

## 踩坑记录
<!-- 本模块特有的问题和经验 -->
- 2026-05-19: `fence.i` + cache 的 difftest 成功依赖两侧语义同步：NEMU reference 本身按 ISA 重新执行自修改代码；NPC 侧 host cache 必须在 RTL 检测到 EX-stage `fence.i` 时 flush I/D cache，否则下一次 indirect call 可能从 ICache 取到修改前的旧指令，表现为 GPR/PC mismatch。
- 2026-05-19: 当前工作区 difftest 有两层参考路径：NPC 的 `--diff=default` 实测加载 NEMU shared object；NEMU 自身的 `CONFIG_DIFFTEST_REF_SPIKE=y` 再加载 `nemu/tools/spike-diff/build/riscv32-spike-so`。排查 reference 差异时先看启动日志中的实际 so 路径，不要只根据历史记忆判断。
- 2026-05-19: 差分 PC 必须来自提交级 `commit_next_pc_o`，不能用 RTL `debug_pc_o` 或 fetch PC 推断；流水线里 fetch frontier 与“当前提交指令之后的架构 PC”经常不同，尤其是 branch/JAL/JALR/mret 与 LSU stall 后。
- 2026-05-19: MicroBench 含 C++ benchmark，当前系统缺 `riscv64-linux-gnu-g++`；可用 `/home/lyg/riscv-toolchain/riscv/bin/riscv64-unknown-elf-g++`，运行时需覆盖 `CROSS_COMPILE=/home/lyg/riscv-toolchain/riscv/bin/riscv64-unknown-elf-` 后再构建。
