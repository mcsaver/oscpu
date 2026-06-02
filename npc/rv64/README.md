# NPC RV64 使用说明

`npc/rv64` 是从 `npc/single` 派生的 RV64 基础核心后端，用于通过 `npc/sim BACKEND=rv64` 运行 `ARCH=riscv64-npc` 的 Abstract Machine 镜像。

## 当前定位

- ISA 目标：RV64IM + Zicsr + Zifencei 基础路径。
- 数据宽度：`XLEN=64`，PC/GPR/CSR/AXI data/DPI payload 均按 64 位处理。
- 访存宽度：LSU 使用 8-byte bus word 和 `WSTRB[7:0]`，支持 byte/half/word/dword load/store。
- 运行入口：外部请优先使用 `npc/sim` 或 AM 的 `ARCH=riscv64-npc`，不要直接把上层脚本绑到 `npc/rv64` 私有路径。
- Linux/Ubuntu 启动入口：OpenSBI、Linux kernel、DTB、initramfs/rootfs、QEMU reference、focused bring-up tools 和日志套件统一在仓库根目录 `Linux/` 下维护；`npc/rv64` 只保留 core RTL、testbench、Kconfig 和 Verilator 仿真本体。

## 快速命令

```bash
make -C npc/sim rv64_defconfig
make -C npc/sim BACKEND=rv64 lint
make -C npc/sim BACKEND=rv64 -j4
```

AM/cpu-tests 回归：

```bash
export AM_HOME=/home/lyg/PA/ysyx-workbench/abstract-machine
export NPC_HOME=/home/lyg/PA/ysyx-workbench/npc
make -C am-kernels/tests/cpu-tests ARCH=riscv64-npc run \
  NPC_RUN_ARGS="--no-progress --max-cycles 20000000"
```

当前验证结果：RV64 基础 cpu-tests `38/38 PASS`。`bitmanip` 和 `compressed` 仍是 RV32 扩展测试口径，`ARCH=riscv64-npc` 下暂不纳入基础全量。

## Difftest 状态

当前默认关闭 `CONFIG_NPC_DIFFTEST`。原因是本仓库 NEMU 的 RV64 reference 仍不完整：`src/isa/riscv64` 不存在，现有执行器也缺 RV64 load/store、OP-32 和 RV64M 等语义。后续若要打开 RV64 difftest，需要先补齐 NEMU RV64 reference。

## 生成物

以下路径为生成物，已在仓库 `.gitignore` 中忽略：

- `npc/rv64/.config`
- `npc/rv64/build/`
- `npc/rv64/include/config/`
- `npc/rv64/include/generated/`
- `npc/rv64/testbench/build/`
