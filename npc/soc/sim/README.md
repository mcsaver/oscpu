# NPC SoC 仿真宿主

本目录负责 Verilator 生命周期、镜像装载、仿真设备、monitor 和 DPI 桥接。
参考模型同步与比较独立放在 [`../difftest/`](../difftest/README.md)，模块自检放在
[`../testbench/`](../testbench/README.md)。所有命令从工作区根目录运行。

| 文件 / 目录 | 职责 |
| --- | --- |
| `src/main.c`、`src/cpu/cpu-exec.cpp` | `NpcSimTop` 宿主入口、时钟驱动、提交事件、退出与超时 |
| `src/monitor/` | 参数解析、SDB、表达式、watchpoint、软件 trace |
| `src/memory/`、`src/device/` | 镜像、MROM/SRAM/PMEM、MMIO 和模拟设备 |
| `src/dpi.c` | `NpcSimTop` 的 DPI 桥 |
| `src/soc-main.cpp` | 独立的 `ysyxSoCFull` 宿主 |
| `include/` | 宿主公共接口 |
| `vsrc/` | `NpcSimTop.sv`、`AxiDpiSlave.sv` 仿真封装 |
| `filelist.mk` | 仿真源清单；生产 RTL 来自 `../vsrc/filelist.mk` |

## 两个运行入口

| 入口 | 构建 / 运行 | 行为 |
| --- | --- | --- |
| `NpcSimTop` | `make -C npc/soc` / `make -C npc/soc run` | 自仿真宿主，支持设备、monitor、trace 与可选 DiffTest |
| `ysyxSoCFull` | `make -C npc/soc soc` / `make -C npc/soc soc-run` | 连接工作区 `ysyxSoC/` 的生成 RTL 和外设；使用独立宿主，尚未接入这里的 DiffTest 比较器 |

这两个入口的 `main` 单独链接。对应的静态检查分别为 `make -C npc/soc lint` 和
`make -C npc/soc soc-lint`。

## 复位地址和镜像

当前 `NpcSimTop` 与 `ysyxSoCFull` 都从 `0x20000000` 开始取指。
`NpcSimTop` 的宿主存储区域定义在 [`include/utils.h`](include/utils.h)，由
[`src/memory/paddr.c`](src/memory/paddr.c) 装载：

| 区域 | 地址 | 容量 |
| --- | --- | --- |
| MROM | `0x20000000` | 4 KiB，镜像从复位地址装入 |
| SRAM | `0x0f000000` | 8 KiB |
| PMEM | `0x80000000` | 128 MiB |

`NpcSimTop` 还提供宿主 MMIO：串口 `0xa00003f8`、RTC `0xa0000048`、键盘
`0xa0000060`、VGA 控制 `0xa0000100`、framebuffer `0xa1000000`。
`ysyxSoCFull` 的外设地址和 CPU 接口以工作区
[`ysyxSoC/spec/cpu-interface.md`](../../../ysyxSoC/spec/cpu-interface.md) 为准。

用于这里的程序应按 SoC 平台链接。AM 的 `riscv32-ysyxsoc` 使用
`abstract-machine/scripts/linker-ysyxsoc.ld`；`riscv32-npc` 的 `0x80000000`
链接布局属于 Single 后端，不能直接套用。

```sh
AM_HOME=$PWD/abstract-machine make -C am-kernels/kernels/hello ARCH=riscv32-ysyxsoc image
make -C npc/soc run IMG="$PWD/am-kernels/kernels/hello/build/hello-riscv32-ysyxsoc.bin"
```

镜像需满足当前 4 KiB MROM 容量；装载器会拒绝过大镜像。
AM 的 `make ... ARCH=riscv32-ysyxsoc run` 通过 `npc/sim BACKEND=soc run`
进入 `NpcSimTop`。运行参数使用 `YSYXSOC_RUN_ARGS`（默认继承 `NPC_RUN_ARGS`）。

`soc-run` 使用独立的 `ysyxSoCFull` 宿主：

```sh
make -C npc/soc soc-run RUN_ARGS='--max-cycles 1000000'
make -C npc/soc soc-run IMG=/path/to/soc-image.bin RUN_ARGS='--max-cycles 1000000'
```

仅 `soc-run` 在没有镜像时内置 `li a0, 0; ebreak` smoke 程序。
普通 `NpcSimTop` 宿主需要提供镜像。

## 配置、调试与 DiffTest

首次配置、交互配置和配置保存仍使用后端根目录入口：

```sh
make -C npc/soc default_defconfig
make -C npc/soc menuconfig
make -C npc/soc savedefconfig
```

`.config`、`include/config/auto.conf` 与 `include/generated/autoconf.h` 保存选择和生成结果。
构建依赖 C++ 编译器、Verilator 和工作区 NEMU；开启软件反汇编时使用 NEMU 的 Capstone，
检测到 SDL2 时可提供窗口，否则保留 headless framebuffer 行为。

`NpcSimTop` 运行时常用 `--no-batch` 进入 monitor，`--max-cycles N` 限制周期数，
`--trace` / `--trace-file` 记录波形，`--itrace` / `--mtrace` / `--dtrace` 选择软件 trace。
这些能力受 Kconfig 构建选项约束，完整运行参数可查询 `build/NpcSimTop --help`。
monitor、trace、键盘与 framebuffer 的共同使用方式见
[`Single 仿真宿主说明`](../../single/sim/README.md)，其中镜像和后端路径应按本页替换。

DiffTest 使用 `CONFIG_NPC_DIFFTEST=y`；当前 SoC 复位地址位于本地 MROM，因此还要求
`CONFIG_NPC_SOC_DIFFTEST=y`，参考 NEMU 启用 `CONFIG_SOC_SIM=y`。
`configs/difftest_defconfig` 提供后端侧配置。`--diff=default|path` 指定参考库，
`--diff-port=N` 指定初始化端口，`--no-diff` 在单次运行中关闭比较。
接口、比较范围和内存同步要求见 [`../difftest/README.md`](../difftest/README.md)。

`ebreak` 使用 `a0` 判断 GOOD/BAD TRAP；异常与超时独立报告。
构建和退出行为由当前源码及相关测试决定。旧版从 Single 复制的运行说明保留在
[`design/history/`](../design/history/single-derived-usage.md)，只作历史资料。
