# Dispatch Log: RV64 Sv39 Bridge

## 读取与约束

- 已按 AGENTS 要求读取 `.github/AGENTS.md`、`.github/copilot-instructions.md`、`.github/memory/project-status.md`、`.github/memory/known-issues.md`、`.github/memory/modules/npc.md` 与 NPC RTL workflow/study 指令。
- 任务跨多个 RTL 文件，先梳理 CSR 状态来源、IFU/LSU bridge、OoO 后端异常 cause 数据流，再修改。

## 调试过程

- 初版 `tb_ooo_sv39_boot` 失败点是 LSU 未观察到页表 walk 和数据访问。
- 临时提交 trace 显示 S-mode 程序把数据虚拟地址算成 `0x0000080000003000`，超出 1GB identity superpage，而不是预期 `0x80003000`。
- 修复测试程序地址构造为 `auipc x11, 3; addi x11, x11, -0xa0`，并用两个 `nop` 保持原 ecall/handler 检查布局；随后移除临时 trace。

## 执行命令

- `make -C npc/rv64/testbench TESTS="tb_ooo_sv39_boot" RESULT_DIR=/tmp/rv64-sv39-boot run`
- `make -C npc/rv64/testbench TESTS="tb_ooo_sv39_boot tb_ooo_int_backend tb_ooo_priv_system" RESULT_DIR=/tmp/rv64-sv39-focused run`
- `make -C npc/sim BACKEND=rv64 lint`
- `make -C npc/sim BACKEND=rv64 -j4`
- `AM_HOME=/home/lyg/PA/ysyx-workbench/abstract-machine make -C am-kernels/tests/cpu-tests ARCH=riscv64-npc run NPC_RUN_ARGS="--no-progress --max-cycles 2000000"`
- `AM_HOME=/home/lyg/PA/ysyx-workbench/abstract-machine make -C am-kernels/benchmarks/coremark ARCH=riscv64-npc ITERATIONS=1000 run NPC_RUN_ARGS="--no-progress --max-cycles 1000000000"`
- `rg -n "[ \t]$" ...changed-files... || true`

## 结果

- Sv39 小型 boot 测试 PASS，focused privilege/AMO 回归 PASS。
- rv64 lint/build PASS。
- cpu-tests 40/40 PASS。
- CoreMark PASS，CPI `0.779`，满足 `< 0.8` 阈值。
