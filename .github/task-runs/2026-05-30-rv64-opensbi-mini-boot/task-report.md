# RV64 OpenSBI Mini Boot Task Report

## 目标

在 `npc/rv64` 上继续推进 Linux boot 闭环：运行真实 OpenSBI，并用一个 mini S-mode payload 验证 handoff、DTB 传参、UART 输出和退出路径，同时补测试覆盖新增固件边界。

## 根因链路

1. 旧卡点 `pc=0x80006656` 反查为 OpenSBI `sbi_hart_hang()`。
2. 调用链定位到 `sbi_domain_init()` 返回错误；继续检查发现 `FW_TEXT_START=0x80001000` 让 `_fw_rw_start - _fw_start = 0x3f000`，不满足 OpenSBI 对 `fw_rw_offset` 的 power-of-2 约束。
3. 改用默认 OpenSBI text start 并通过 `FW_FDT_PATH` embedded DTB 后，OpenSBI 进入 semihosting probe，但 NPC 把 magic sequence 中的 `ebreak` 当作 AM halt。
4. 将 semihost magic `0x01f01013, ebreak, 0x40705013` 中的 `ebreak` 改为架构 breakpoint trap，保留普通 `ebreak` 的 AM halt 语义，OpenSBI 可继续执行并 handoff 到 payload。
5. mini payload 初版用 `lw` 读取 FDT magic 会因 `0xedfe0dd0` sign-extend 而误判，改为 `lwu` 后通过。

## 主要改动

- `npc/rv64/vsrc/ooo/OooAluFetchCore.v`: 识别 semihosting magic `ebreak`，通过精确 trap 写 `mcause=EXC_BREAKPOINT`，普通 `ebreak` 仍作为实验壳退出。
- `npc/rv64/vsrc/core/CsrFile.v`: `misa` 报告 RV64 I/M/A/B/C/S/U，满足 OpenSBI early probe。
- `am-kernels/tests/cpu-tests/tests/semihost-ebreak.c`: 覆盖 semihost magic breakpoint trap 和普通 AM halt 不冲突。
- `am-kernels/tests/cpu-tests/tests/misa-priv.c`: 覆盖 `misa` MXL 与扩展位。
- `am-kernels/tests/cpu-tests/tests/compressed.c`: 扩展 RV64C 指令覆盖。
- `npc/rv64/tools/Makefile`: 新增 `smoke-opensbi` target。
- `npc/rv64/tools/mini-linux-payload.S`: S-mode payload 检查 `a0/a1/DTB magic`，UART 打印 `S` 后 GOOD TRAP。

## 验证

- `make -C npc/sim BACKEND=rv64 -j4`: PASS。
- `make -C am-kernels/tests/cpu-tests AM_HOME=/home/lyg/PA/ysyx-workbench/abstract-machine ARCH=riscv64-npc NPC_SIM_BACKEND=rv64 ALL="bitmanip semihost-ebreak misa-priv counteren-time sbi-timer linux-handoff compressed" run NPC_RUN_ARGS="--no-progress --max-cycles 5000000"`: 全部 PASS。
- `make -C npc/rv64/tools smoke-opensbi OPENSBI_FW_JUMP_BIN=/tmp/ysyx-opensbi/build-npc/platform/generic/firmware/fw_jump.bin OPENSBI_MAX_CYCLES=5000000`: PASS，OpenSBI v1.8 banner 完整输出，payload 打印 `S`，GOOD TRAP，`cycles=4366855/commits=4626201/CPI=0.944`。
- `make -C npc/rv64/tools smoke-dtb`: PASS，`cycles=38987/commits=75158/CPI=0.519`。
- `make -C am-kernels/benchmarks/coremark AM_HOME=/home/lyg/PA/ysyx-workbench/abstract-machine ARCH=riscv64-npc NPC_SIM_BACKEND=rv64 ITERATIONS=10 run NPC_RUN_ARGS="--no-progress --max-cycles 20000000"`: PASS，`cycles=2518692/commits=3216171/CPI=0.783`。

## 剩余限制

当前结果是真实 OpenSBI + mini S-mode payload，不是完整 Linux kernel boot。还缺真实 kernel/rootfs、virtio/blk、多源 PLIC、完整设备树/驱动行为，以及 OpenSBI smoke 自身低于 0.8 CPI 的优化证据。
