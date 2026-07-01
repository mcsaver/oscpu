# Dispatch Log：ACT4 arch-test + NEMU tohost/Linux 设备图

| node_id | owner_agent | module | status | inputs | outputs | evidence |
| --- | --- | --- | --- | --- | --- | --- |
| act4-runner | Codex | am-kernels | PASS | `npc/rv64/testsuites/core-tests` ACT4 final ELF、`riscv64-unknown-elf-nm/objcopy` | `am-kernels/arch-test` Makefile/README/runner | `make -C am-kernels/arch-test list` PASS；`make -C am-kernels/arch-test smoke` PASS |
| nemu-tohost | Codex | nemu | PASS | ACT4/riscv-tests `tohost` 符号和值编码 | NEMU `--tohost=ADDR`、paddr/DMA/vaddr host-fast 写监控 | ACT4 smoke 输出 `TOHOST PASS` 与 `HIT GOOD TRAP` |
| linux-device-map | Codex | nemu/Linux | PASS | `Linux/platform/npc-rv64.yml` / generated DTB | RV64 system Kconfig/defconfig Linux MMIO、performance config gate | `check-nemu-performance-config.sh` PASS；NEMU log 显示 Linux MMIO 地址图 |
| focused-regression | Codex | am-kernels/nemu | PASS | `ACT4_SUITES=rv64i/I ACT4_LIMIT=3` | NEMU focused ACT4 回归 | `I-add-00`、`I-addi-00`、`I-addiw-00` PASS |
