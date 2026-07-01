# 任务报告：ACT4 架构测试迁移与 NEMU Linux 设备图对齐

## 任务

把 ACT4 架构测试入口迁移到 `am-kernels/arch-test`，并让 NEMU 能通过 `tohost` 监控运行这些官方风格的架构测试；同时按用户要求，将 NEMU RV64 system 设备配置统一到 Linux 设备树来源，即 `Linux/platform/npc-rv64.yml`。

## Root Cause

旧 NEMU RV64 system 配置仍混用 AM/legacy 设备地址。`HAS_DISK=y` 时 `DISK_CTL_MMIO=0xa0000300` 的 0x1000 区间会覆盖 `SERIAL_MMIO=0xa00003f8` 的 0x1000 区间，ACT4 smoke 首次运行即在 MMIO map 初始化阶段暴露重叠错误。更深层的问题是 NEMU defconfig/Kconfig 与 Linux 平台设备图不一致：Linux DTS 的真实 source-of-truth 是 `Linux/platform/npc-rv64.yml`，设备地址应为 UART `0x10000000`、virtio-blk `0x10001000`、virtio-rng `0x10002000`、goldfish-rtc `0x10003000`、virtio-net `0x10004000`、syscon reset `0x00100000`。

ACT4/riscv-arch-test 的退出协议不是 AM 的 `ebreak+a0`，而是写 `tohost`。若强行用 C/AM halt 包裹，会干扰 ebreak/trap/privileged 类测试的原始语义；因此正确迁移方式是保持 ELF 原始布局，运行器从 ELF 符号表提取 `tohost` 地址，模拟器负责监控该地址。

## 改动

- 新增 `am-kernels/arch-test`，提供 `make list/smoke/run-nemu/run-npc/run-both/build-final/build-nemu/build-npc/clean`，默认复用 `npc/rv64/testsuites/core-tests` 下 ACT4 final ELF。
- NEMU 增加 `--tohost=ADDR`，在 paddr PMEM/DMA 写和 vaddr host-fast 写路径检测 `tohost` 非零写入，`1` 判 PASS，其他非零按 riscv-tests/ACT4 编码解码为失败。
- NEMU Kconfig/`riscv64-npc_defconfig` 改为 Linux 设备图：1GiB PMEM、PMEM malloc、Linux UART/virtio-blk/rng/net/goldfish-rtc/syscon 地址，关闭 legacy timer/keyboard/VGA/audio。
- `Linux/scripts/check-nemu-performance-config.sh` 增加 Linux 设备地址和 legacy 设备关闭门禁，防止后续配置漂移。

## 验证

- `bash -n am-kernels/arch-test/scripts/act4-arch-run.sh`
- `bash -n Linux/scripts/check-nemu-performance-config.sh`
- `make -C nemu NEMU_HOME=/home/lyg/PA/ysyx-workbench/nemu -j2`
- `NEMU_CONFIG=... NEMU_AUTOCONF=... bash Linux/scripts/check-nemu-performance-config.sh`
- `make -C am-kernels/arch-test list`
- `make -C am-kernels/arch-test smoke`
- `make -C am-kernels/arch-test run-nemu ACT4_SUITES=rv64i/I ACT4_LIMIT=3`
- `git diff --check` 针对本轮改动文件通过

关键运行证据：Linux defconfig 下 ACT4 smoke 日志显示 PMEM `[0x80000000, 0xbfffffff]`，MMIO 为 serial `0x10000000`、virtio-blk `0x10001000`、virtio-rng `0x10002000`、virtio-net `0x10004000`、goldfish-rtc `0x10003000`、syscon-reset `0x00100000`，并最终输出 `TOHOST PASS` 与 `HIT GOOD TRAP`。`run-nemu ACT4_SUITES=rv64i/I ACT4_LIMIT=3` 通过 `I-add-00`、`I-addi-00`、`I-addiw-00`。

## 边界

本轮闭合的是 ACT4 final ELF 运行入口、NEMU `tohost` 退出协议、以及 RV64 system 设备图与 Linux DTS source-of-truth 的一致性。它不代表 ACT4 全量套件已经全部跑完，也不代表 NPC 侧所有 ACT4 项均已签核；全量扩展可在该 runner 上继续用 `ACT4_SUITES`/`ACT4_LIMIT` 分批推进。
