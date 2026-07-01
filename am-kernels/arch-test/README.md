# ACT4 Arch Tests

这个目录把 `riscv-arch-test`/ACT4 的最终 ELF 运行方式搬到 `am-kernels` 侧，目标是用同一批架构测试检查 NEMU 和 NPC 的 ISA/特权行为是否完备。

## 测试来源

- 外部测试源：`npc/rv64/testsuites/core-tests/src/riscv-arch-test`，来自官方 RISC-V Architectural Test Framework。
- 生成入口：`npc/rv64/testsuites/scripts/npc-rv64-act4-preflight.sh`。
- 默认复用产物：`npc/rv64/testsuites/core-tests/act4-npc-final-work-script/sail-rv64-max/elfs`。
- 退出协议：ACT4 ELF 写 `tohost` 符号。值 `1` 表示 PASS，其他非零值按 riscv-tests/ACT4 约定解码为失败码。

这里没有把 ACT4 改写成 AM runtime 程序。原因是 ACT4 本身会测试 `ebreak/ecall/trap` 等指令和异常路径，如果用 AM 的 `ebreak+a0` 当统一退出协议，会和被测指令语义互相干扰。现在采用 `tohost` 监控，NEMU/NPC 只在命令行显式传入 `--tohost=ADDR` 时启用，不影响已有 AM/cpu-tests。

## 常用命令

列出已有 ACT4 suite：

```sh
make -C am-kernels/arch-test list
```

跑一个 NEMU smoke：

```sh
make -C am-kernels/arch-test smoke
```

跑 NEMU 的 RV64I I-extension 全套：

```sh
make -C am-kernels/arch-test run-nemu ACT4_SUITES=rv64i/I
```

跑 NPC：

```sh
make -C am-kernels/arch-test run-npc ACT4_SUITES=rv64i/I
```

同一批 ELF 同时跑 NEMU 和 NPC：

```sh
make -C am-kernels/arch-test run-both ACT4_SUITES=rv64i/I ACT4_LIMIT=5
```

重新生成最终 ELF：

```sh
make -C am-kernels/arch-test build-final ACT4_EXTENSIONS=rv64i
```

## 结果位置

- 二进制镜像：`am-kernels/arch-test/build/bin/`
- 运行日志：`am-kernels/arch-test/build/logs/`
- 汇总表：`am-kernels/arch-test/build/summary.tsv`

## 边界

`rv64i/I`、`rv64i/M` 适合先作为 NEMU/NPC 基础完整性回归；`priv/Sv` 会触及 Sv39、异常委托、CSR、页表和平台中断等系统能力，失败时通常要按具体日志继续定位，不应简单归因为 ACT4 框架问题。
