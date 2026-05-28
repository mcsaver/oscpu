# AM-Kernels 模块笔记

## 测试通过情况
<!-- 各测试集的通过状态 -->
- [2026-05-24] `am-kernels/tests/cpu-tests/tests/mem-test.c` 已从 SRAM-only 扩展为同时覆盖 cacheable PSRAM/DCache。测试保留栈上 `scratch` 的 `sb/sh/sw/lb/lbu/lh/lhu/lw` 检查，另访问 `0x80000000` 写读 word、byte lane 和 signed `lb`，再写 `0x80001000` 强制同 index 不同 tag 替换，最后重读 `0x80000000` 校验 dirty writeback/refill。验证：`ARCH=riscv32-ysyxsoc ALL=mem-test YSYXSOC_RUN_ARGS="--no-diff --no-progress -m 0"` PASS，NPC 统计显示 `dcache: access=12, hit=9, miss=3`、`dcache writeback = 16`；ysyxSoCFull `soc-run` 加载该 `.bin` 后 GOOD TRAP；ELF `text=780,data=0,bss=0`，仍不写可写全局变量。
- [2026-05-23] `char-test` 已复用于验证 MROM 启动后的 ysyxSoC TRM：`ALL=char-test ARCH=riscv32-ysyxsoc YSYXSOC_RUN_ARGS="--no-diff --no-progress -m 0"` PASS，日志显示镜像加载到 MROM `[0x20000000, 0x20000fff]`，串口输出 `putch path` 与 `AM_UART_TX path` 两行，最终 `HIT GOOD TRAP at pc = 0x2000009e`。ELF 检查显示 entry `0x20000000`，首条 `_start` 指令为 `li s0,0`，`_stack_pointer/_heap_start=0x0f001000`。
- [2026-05-23] `am-kernels/tests/cpu-tests/tests/char-test.c` 新增 UART 字符输出 smoke：所有平台先通过 `putch()` 打印 `0123456789 ABC xyz`；`riscv32-ysyxsoc` 下额外走 `AM_UART_CONFIG/AM_UART_TX/AM_UART_RX`，验证 UART present、TX 输出 `ysyxsoc UART OK`、无输入时 RX 为 `-1`。该测试只覆盖串口路径，不需要完整 `ioe_init()`。验证：`ALL=char-test ARCH=riscv32-ysyxsoc` 在 `--no-diff` 与 `--diff=default` 下均 PASS；`ARCH=riscv32-ysyxsoc` 全量 cpu-tests 39/39 PASS；`ALL=char-test ARCH=riscv32-npc` PASS。
- [2026-05-23] 新增 `riscv32-ysyxsoc` AM 平台后，`am-kernels/tests/cpu-tests` 可直接以 ysyxSoC 地址图构建和运行：命令 `AM_HOME=${YSYX_HOME}/abstract-machine NEMU_HOME=${YSYX_HOME}/nemu timeout 900s make -C am-kernels/tests/cpu-tests ARCH=riscv32-ysyxsoc run YSYXSOC_RUN_ARGS="--diff=default --no-progress -m 0"` 结果 38/38 PASS，启动日志显示通过 `npc/sim BACKEND=soc` 进入 `npc/soc` 且 Difftest ON。另执行 `make -C am-kernels/tests/am-tests ARCH=riscv32-ysyxsoc image` 构建通过，证明 IOE 分发表和设备 stub 可链接。
- [2026-05-19] `riscv32-npc` 对齐 NEMU 可选功能后，cpu-tests 新增 `bitmanip.c`、`compressed.c`、`fence-i.c` 覆盖 Zba/Zbb/Zbc/Zbs、RV32C 与自修改代码 `fence.i`；全量 `timeout 900s make -C am-kernels/tests/cpu-tests ARCH=riscv32-npc run NPC_RUN_ARGS='--diff=default -m 0'` 结果为 38/38 PASS。测试列表包含新增 `bitmanip/compressed/fence-i`，并覆盖原有 `mul-longlong/div/crc32/quick-sort/matrix-mul` 等长项。
- [2026-05-19] 复核 NEMU/NPC 当前工作区状态：`timeout 300s make -C am-kernels/tests/cpu-tests ARCH=riscv32-npc run NPC_RUN_ARGS='--diff=default -m 0'` 在 35 个 cpu-tests 上全部 PASS；同轮补跑 `timeout 180s make -C am-kernels/tests/cpu-tests ARCH=riscv32-nemu run` 也为 35/35 PASS。结论是当前 cpu-tests 所需功能在 `riscv32-npc` 上已实现，无新增失败项需要修复。
- [2026-05-19] `riscv32-npc` 接入 Spike difftest 后，`timeout 240s make -C am-kernels/tests/cpu-tests ARCH=riscv32-npc run NPC_RUN_ARGS='--diff=default -m 0'` 在 35 个 cpu-tests 上全部 PASS；单项 `ALL=add` 也以同一 difftest 参数 PASS，输出 `cycles=2319`、`commits=839`、`CPI=2.764`。
- [2026-05-19] NEMU RV32 `inst.c` 译码结构重构后，在本地 `RISCV_EXT_M/B/C=y`、DIFFTEST 关闭配置下，`timeout 180s make -C am-kernels/tests/cpu-tests ARCH=riscv32-nemu run` 仍为 35/35 PASS；`ALL=add` 单项 PASS（840 inst / 9 us / 93.3 MIPS）；`timeout 1s make -C am-kernels/kernels/yield-os ARCH=riscv32-nemu c` 可输出 `ABAB...` 后按预期被 timeout 终止。
- [2026-05-19] NEMU RV32 IMBC 修复后，`RISCV_EXT_M=y`、`RISCV_EXT_B=y`、`RISCV_EXT_C=y`、`CONFIG_DIFFTEST=y`、Spike REF 下执行 `timeout 180s make -C am-kernels/tests/cpu-tests ARCH=riscv32-nemu run`，cpu-tests 35/35 全部 PASS。此前失败集中在 `c.bnez/c.beqz` 立即数拼接错误和 Spike REF 未编入 B 扩展指令两类问题。
- [2026-05-19] NEMU IMBC 配置桥接验证新增三组 smoke：默认本地配置（`RISCV_EXT_M=y`、B/C 关闭、DIFFTEST 开启）下 `make -C am-kernels/tests/cpu-tests ARCH=riscv32-nemu ALL=add run` PASS，ELF 属性为 `rv32i_m_zicsr`；临时关闭 M 后 `ALL=mul-longlong` 以 `rv32i_zicsr` PASS，证明软件 libgcc 乘法路径可用；临时开启 M+B+C 后 `ALL=add` PASS，ELF 属性包含 `rv32i_m_c_zicsr_zba_zbb_zbc_zbs` 且反汇编出现 `c.*` 压缩指令。
- [2026-05-19] `am-kernels/kernels/yield-os` 已可在 `ARCH=riscv32-nemu` 上作为协作式上下文切换 smoke 测试运行；`timeout 3s make -C am-kernels/kernels/yield-os ARCH=riscv32-nemu c` 构建通过并打印交替 `ABAB...`，随后因程序本身无限循环被 timeout 结束。该结果依赖本轮补齐的 AM RISC-V NEMU `kcontext()` 与 trap.S 返回上下文恢复。
- [2026-05-19] 文档审计确认 NEMU `am-tests mainargs=d` 的旧 GPU 高级接口缺口已经由 2026-04-14 的 `AM_GPU_MEMCPY/AM_GPU_RENDER` 补齐记录覆盖；当前模块笔记不再把 NEMU devscan 的 `access nonexist register` 当作活跃问题。后续若 devscan 再失败，优先重新看真实日志与平台注册表，而不是沿用 2026-04-13 的旧结论。
- [2026-04-13] 本地统一回归入口已落到 `scripts/am-regression.sh`：默认跑 `alu/cpu/klib/am(h/a)/devscan smoke + benchmark`，日志目录固定为 `am-kernels/build/regression/<时间戳>/`，`latest` 总是指向最新一轮结果。
- [2026-04-13] `scripts/am-regression.sh --watch` 已验证可用；监控目录发生源码修改后，会自动启动新一轮回归，适合做 `abstract-machine` / `nemu` / `am-kernels` 小步修改后的本地守护回归。
- [2026-04-13] `ARCH=riscv32-nemu` 回归通过：`alu-tests`、`cpu-tests` 35 项、`klib-tests` 4 项、`am-tests mainargs=h`、`am-tests mainargs=a` 均在 NEMU batch 模式下跑到 `HIT GOOD TRAP`。
- [2026-04-13] `am-tests mainargs=d` 曾未通过，且当时确认不是 `stdlib` 回归：日志在 `Screen size: 400 x 300` 后报 `AM Panic: access nonexist register`，根因是 `platform/nemu` 当时没有实现 `AM_GPU_MEMCPY/AM_GPU_RENDER`。该条是历史记录，已被 2026-04-14 高级 GPU ABI 修复覆盖。

## 基准测试结果
<!-- CoreMark/Dhrystone/MicroBench 性能数据 -->
- [2026-05-19] `riscv32-npc` 对齐 RV32IMBC/cache/BPU 后，benchmark 在 `NPC_RUN_ARGS='--diff=default -m 0'` 下通过：CoreMark 默认 `1000` iterations PASS，`Total time (ms)=742229`，`CoreMark PASS 3 Marks`，NPC 统计 `cycles=1632703802`、`commits=746654109`、`CPI=2.187`；Dhrystone 默认 `500000` runs PASS，`Finished in 222718 ms`，`Dhrystone PASS 3 Marks`，NPC 统计 `cycles=469040116`、`commits=230019046`、`CPI=2.039`；MicroBench 使用 `mainargs=test` 10/10 项 PASS，`Scored time=516.820 ms`、`Total time=665.287 ms`，NPC 统计 `cycles=1112846`、`commits=522957`、`CPI=2.128`。
- [2026-05-19] `riscv32-npc` + Spike difftest benchmark 回归：Dhrystone 默认 `500000` runs PASS，`Finished in 202068 ms`，`Dhrystone PASS 4 Marks`，NPC 统计 `cycles=562049286`、`commits=230018912`、`CPI=2.443`；CoreMark 默认 `1000` iterations PASS，`Total time (ms)=694189`，`CoreMark PASS 4 Marks`，NPC 统计 `cycles=1947323432`、`commits=746654025`、`CPI=2.608`；MicroBench 使用 `mainargs=test` 完整 10 项 PASS，`Scored time=460.022 ms`、`Total time=598.276 ms`，NPC 统计 `cycles=1303514`、`commits=522588`、`CPI=2.494`。
- [2026-04-13] `Dhrystone PASS 537 Marks`，`500000` 次运行完成于 `1639 ms`。
- [2026-04-13] `MicroBench PASS 1563 Marks`，`Scored time: 12086.902 ms`，`Total time: 13983.183 ms`。
- [2026-04-13] `CoreMark PASS 1203 Marks`，`1000` 次迭代总耗时 `2428 ms`。

## 踩坑记录
<!-- 本模块特有的问题和经验 -->
- `microbench` 依赖 C++ 交叉编译器；当前环境没有 `riscv64-linux-gnu-g++`，但有 `${RISCV_TOOLCHAIN_ROOT}/riscv/bin/riscv64-unknown-elf-g++`。在 `ARCH=riscv32-npc` 上跑 MicroBench 时可用 `CROSS_COMPILE=${RISCV_TOOLCHAIN_ROOT}/riscv/bin/riscv64-unknown-elf-` 覆盖工具链前缀。
- hello/mainargs 调试时要区分平台：native 依赖宿主环境变量 mainargs；riscv32-nemu 与 npc 依赖镜像里的静态 mainargs 区域，改的是生成后的 bin，不是运行时环境。
- `am-tests` 不能机械地“全量 batch 跑到底”：`devscan()` 末尾有 `while (1)`，`intr/rtc/video/keyboard/mp/vm` 也多为常驻或交互型测试，回归时应优先筛选可自动结束子项。
- `devscan()` 曾在 NEMU 上因 `AM_GPU_MEMCPY/AM_GPU_RENDER` 未注册而落到 `access nonexist register`；该缺口已补齐。做回归归因时仍要先区分“最近代码改坏”和“平台能力缺口”，但不要再把 NEMU 高级 GPU ABI 当成当前默认缺口。
