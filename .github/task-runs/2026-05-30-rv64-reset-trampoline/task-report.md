# RV64 Reset Trampoline Handoff

## 目标

把 `npc/rv64` 的多镜像 host loader 和 Linux/OpenSBI reset 入口 ABI 接起来：复位从 `0x80000000` 开始执行一个很小的 trampoline，由它设置 `a0=hartid`、`a1=DTB paddr`，再跳到 firmware/kernel payload 地址。

## 改动

- `npc/rv64/tools/linux-boot-trampoline.S`
  - 构建为可装载到 reset PC 的 raw binary。
  - 启动后写 `a0=BOOT_HARTID`、`a1=DTB_ADDR`。
  - 通过 `t2` 执行 `jalr x0, 0(t2)` 跳到 `NEXT_ADDR`。
  - 使用 `.option norvc`，避免 reset handoff 自身混入压缩指令。
- `npc/rv64/tools/Makefile`
  - 自动选择 `/home/lyg/riscv-toolchain/riscv/bin/riscv64-unknown-elf-` 或 `riscv64-linux-gnu-` 交叉工具链。
  - 支持 `TRAMPOLINE_TEXT`、`BOOT_HARTID`、`NEXT_ADDR`、`DTB_ADDR` 参数。
  - 先生成 ELF，再用 `objcopy -O binary` 生成 raw bin。

## 验证

- `make -C npc/rv64/tools NEXT_ADDR=0x80001000 DTB_ADDR=0x80002000 BOOT_HARTID=0`
  - PASS
  - 生成 `npc/rv64/tools/build/linux-boot-trampoline.bin`
- 三镜像 handoff：
  - `--load=0x80000000:npc/rv64/tools/build/linux-boot-trampoline.bin`
  - `--load=0x80001000:/tmp/rv64-payload.bin`
  - `--load=0x80002000:/tmp/rv64-fake.dtb`
  - PASS，payload 验证 `a0=0`、`a1=0x80002000`、fake FDT magic `d00dfeed`
  - `HIT GOOD TRAP`
  - `cycles=94 / commits=27 / CPI=3.481`
  - `dcache load: access=4, hit=3, miss=1`

## 限制

本轮验证的是 reset trampoline 与多镜像装载、入口寄存器 ABI、DTB 指针读取链路，不是完整 OpenSBI 或 Linux。真实启动仍需要准备真实 OpenSBI/kernel/DTB 镜像，并继续补 SBI IPI/reset/HSM、多源 PLIC、virtio/blk、设备树和块设备路径。
