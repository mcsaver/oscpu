# NPC Single 使用说明

## 这是什么

`npc/single` 现在包含两部分：

- 一版 RV32 五级流水核心 RTL，位于 `vsrc/`
- 一套参考 NEMU 分层方式组织的 Verilator + DPI 宿主仿真环境，位于 `csrc/`

当前目标不是完整 SoC，而是先提供一条稳定的 bring-up 闭环：

1. 用 `abstract-machine` 和 `am-kernels` 生成 `riscv32-npc` 裸机镜像
2. 把 `.bin` 镜像装进 `pmem@0x80000000`
3. 通过 DPI 模拟最小 MMIO 设备并运行程序
4. 用 `ebreak + a0` 退出程序，或输出 trap/timeout 信息

## 目录结构

```text
npc/single/
├── Makefile                 # Verilator 构建、运行和清理入口
├── vsrc/
│   ├── filelist.mk          # RTL/仿真源文件统一清单
│   ├── include/             # 全局宏和编码定义
│   ├── core/                # NpcCore、CSR、寄存器堆和流水控制
│   ├── frontend/            # 取指、RVC 解压、IF 缓冲和 BPU
│   ├── decode/              # 译码与立即数生成
│   ├── execute/             # ALU、比较器和多周期除法器
│   ├── memory/              # LSU 与 MEM 阶段控制/数据路径
│   ├── cache/               # ICache、DCache 与 fence.i cache 控制
│   ├── bus/                 # AXI-like 总线、crossbar 和默认 slave
│   ├── common/              # SRAM-like 通用存储封装
│   ├── pipeline/            # IF/ID、ID/EX、EX/MEM、MEM/WB 寄存器
│   ├── writeback/           # 写回选择逻辑
│   └── sim/                 # 含 DPI-C 的 Verilator 仿真顶层
└── csrc/
    ├── main.cpp             # 启动入口
    ├── monitor/             # 参数解析、初始化/收尾顺序
    ├── cpu/                 # 执行循环、trace、退出/超时报告
    ├── memory/              # PMEM 与镜像装载
    ├── device/              # MMIO 注册、串口、RTC、键盘、VGA
    └── dpi.cpp              # SystemVerilog <-> C++ 总线桥
```

## 当前地址图

`NpcSimTop` 和宿主侧环境当前对齐 NEMU 风格的最小地址图：

- `uart`: `0x10000000` - `0x10000fff`，独立 `Uart` RTL 设备核心经 `AxiLiteToUart` 适配层接入 AXI-Lite crossbar
- `pmem`: `0x80000000`
- `serial`: `0xa00003f8`
- `rtc`: `0xa0000048`
- `keyboard`: `0xa0000060`
- `vgactl`: `0xa0000100`
- `framebuffer`: `0xa1000000`

对应的 AM 平台头文件在 `abstract-machine/am/src/riscv/npc/npc.h`。

## 依赖准备

至少需要下面几项可用：

- `verilator` 在 `PATH` 中
- RISC-V 32 位交叉工具链可用，用于 `abstract-machine` 和 `am-kernels`
- 当前工作区已经存在 `abstract-machine/` 和 `am-kernels/`
- 如果你希望 NPC 直接弹出 VGA 窗口并从窗口接收键盘事件，构建时还需要可被 `pkg-config` 或 `sdl2-config` 发现的 SDL2 开发包；缺失时 Makefile 会自动退回 headless framebuffer + stdin 键盘桥

如果你平时通过环境变量工作，建议至少保证：

```bash
export AM_HOME=/home/lyg/PA/ysyx-workbench/abstract-machine
export NPC_HOME=/home/lyg/PA/ysyx-workbench/npc
```

项目根目录的 `init.sh` 也可以帮助你把这些变量写进 `~/.bashrc`。

## Kconfig 配置

`npc/single` 现在已经接入一套参考 NEMU 的配置链路。首次进入目录后，建议先生成默认配置：

```bash
make -C /home/lyg/PA/ysyx-workbench/npc/single default_defconfig
```

如果你想修改默认行为，比如 batch、wave trace、text trace、SDB、watchpoint、difftest 或默认最大周期数，可以执行：

```bash
make -C /home/lyg/PA/ysyx-workbench/npc/single menuconfig
```

当前配置会生成到下面这些文件中：

```text
npc/single/.config
npc/single/include/config/auto.conf
npc/single/include/generated/autoconf.h
```

如果你确认新的默认配置应该被保留下来，可以再执行：

```bash
make -C /home/lyg/PA/ysyx-workbench/npc/single savedefconfig
```

其中 `CONFIG_NPC_BATCH_MODE` 现在默认打开，等价于把 `-b` 作为默认启动方式，因此直接运行测试镜像时不会再先停在 `(npc)` 等你手动按 `c`；如果某次只是临时想进 monitor，可直接追加 `--no-batch`，不需要回去改配置重编。`CONFIG_NPC_DEFAULT_MAX_CYCLES` 用来设置默认超时周期数，并且现在支持把值设成 `0` 来关闭超时，适合 CoreMark 这类较大的测试。`CONFIG_NPC_HAS_VGA` 控制 guest 是否看到 `vgactl/framebuffer` 这组 MMIO；关闭后，AM 的 `GPU_CONFIG.present` 会回到 `false`，适合临时退回纯串口/键盘路径排查问题。`CONFIG_NPC_DIFFTEST` 决定是否把差分测试能力编进二进制，并且打开后启动时默认逐条驱动 NEMU reference 做提交级对比；如果某次只想裸跑，可追加 `--no-diff`，性能跑分则建议直接使用关闭该项的 `perf_defconfig`，这样 `difftest.cpp` 不参与 Verilator 构建，也不会在提交热路径检查 reference 状态。`CONFIG_NPC_TEXT_TRACE` 是软件文本 trace 的总构建开关，打开后 itrace/mtrace/dtrace 三类能力一起编进二进制；`CONFIG_NPC_ITRACE_BY_DEFAULT`、`CONFIG_NPC_MTRACE_BY_DEFAULT`、`CONFIG_NPC_DTRACE_BY_DEFAULT` 只控制启动后的默认运行状态，单次运行仍可用 `--itrace/--mtrace/--dtrace` 或 monitor 命令临时调整。

另外，`CONFIG_NPC_PROGRESS_BY_DEFAULT` 用来控制启动后是否默认打印长跑进度；打开后，`CONFIG_NPC_DEFAULT_PROGRESS_INTERVAL` 再控制进度输出间隔，单位是“已提交指令数”。默认间隔为 `10000000`，表示每执行一千万条已提交指令打印一次 `[progress] ...`；如果你希望默认静默运行，可以直接关闭 `CONFIG_NPC_PROGRESS_BY_DEFAULT`，单次运行仍可用 `--progress` 临时打开。

## 快速开始

### 1. 只检查 RTL 和顶层封装

```bash
make -C /home/lyg/PA/ysyx-workbench/npc/single lint
```

这个目标只做 Verilator lint，不会生成仿真二进制。

### 2. 构建仿真器

```bash
make -C /home/lyg/PA/ysyx-workbench/npc/single
```

生成物默认在：

```text
npc/single/build/NpcSimTop
```

### 3. 先生成一个 AM 镜像

以 `hello` 为例：

```bash
AM_HOME=/home/lyg/PA/ysyx-workbench/abstract-machine \
make -C /home/lyg/PA/ysyx-workbench/am-kernels/kernels/hello ARCH=riscv32-npc image
```

生成的镜像通常位于：

```text
am-kernels/kernels/hello/build/hello-riscv32-npc.bin
```

### 4. 直接运行镜像

```bash
make -C /home/lyg/PA/ysyx-workbench/npc/single run \
  IMG=/home/lyg/PA/ysyx-workbench/am-kernels/kernels/hello/build/hello-riscv32-npc.bin
```

如果程序正常退出，你会看到类似输出：

```text
Hello, AbstractMachine!
[cpu-exec.cpp:...] npc: HIT GOOD TRAP at pc = 0x800000xx
[cpu-exec.cpp:...] host time spent = ... us
[cpu-exec.cpp:...] total guest instructions = ...
[cpu-exec.cpp:...] simulation frequency = ... inst/s
```

也就是说，当前 NPC 在程序结束时会额外给出一组 NEMU 风格的统计摘要，方便直接对比 `host time spent / total guest instructions / simulation frequency`。

## 从 AM 侧直接运行

`abstract-machine/scripts/platform/npc.mk` 已经把 `run` 入口接到 `npc/single`，所以也可以直接这样用：

```bash
AM_HOME=/home/lyg/PA/ysyx-workbench/abstract-machine \
make -C /home/lyg/PA/ysyx-workbench/am-kernels/kernels/hello ARCH=riscv32-npc run
```

这个路径会自动：

1. 构建 ELF
2. 生成 `.bin`
3. 回填 `mainargs`
4. 调用 `npc/single` 的 `make run`

## 网表综合与 STA

如果你想对当前可综合核心 `NpcCore` 直接做标准单元网表综合和 STA，现在不用再切到 `yosys-sta/` 目录手动拼长命令；直接在 `npc/single` 下运行下面两条入口即可：

```bash
make -C /home/lyg/PA/ysyx-workbench/npc/single syn
make -C /home/lyg/PA/ysyx-workbench/npc/single sta
```

其中：

- `make syn`：只跑 `yosys-sta` 的标准单元综合，生成 `NpcCore.netlist.v` 和综合统计
- `make sta`：在综合基础上继续跑 iEDA 的时序/功耗分析，生成 `.rpt/.pwr/.cap/.fanout/.trans`
- 这条流程默认只综合 `RTL_CORE_SRCS` 中的 `NpcCore` 及其纯 RTL 子模块，不会把带 `DPI-C` 的 `NpcSimTop.sv` 混进综合网表

默认结果目录位于：

```text
npc/single/build/sta/NpcCore-500MHz/
```

常用覆写参数如下：

- `STA_CLK_FREQ_MHZ=<MHz>`：覆盖时钟频率，默认 `500`
- `STA_CLK_PORT_NAME=<port>`：覆盖时钟端口名，默认 `clk`
- `STA_SDC_FILE=<path>`：覆盖 SDC 约束文件，默认复用 `yosys-sta/scripts/default.sdc`
- `STA_RESULT_ROOT=<dir>`：覆盖综合/STA 结果根目录，默认 `npc/single/build/sta`

例如，跑一次 `800MHz` 的 STA：

```bash
make -C /home/lyg/PA/ysyx-workbench/npc/single sta STA_CLK_FREQ_MHZ=800
```

或者把结果输出到单独目录：

```bash
make -C /home/lyg/PA/ysyx-workbench/npc/single sta \
  STA_CLK_FREQ_MHZ=800 \
  STA_RESULT_ROOT=/home/lyg/PA/ysyx-workbench/npc/single/build/sta-800
```

这组入口默认依赖工作区里的：

- `oss-cad-suite/bin/yosys`
- `yosys-sta/bin/iEDA`
- `yosys-sta/pdk/icsprout55`

如果这些工具或资源缺失，`make syn` / `make sta` 会先在 NPC Makefile 的环境检查阶段直接报出缺失项，而不是等子流程跑到一半才失败。

## 常用运行参数

仿真器当前支持下面几项参数：

- `-b`, `--batch`: 跳过 `(npc)` 提示符，直接持续运行到程序退出、异常或超时
- `-l path`, `--log path`: 把 welcome、host 运行日志以及 guest 串口输出同时写到文件
- `--vga`, `--no-vga`: 临时打开或关闭 VGA MMIO 设备，不需要回 `menuconfig` 重编
- `--itrace`: 打开提交级指令 trace
- `--itrace-cond EXPR`: 为 `itrace` 指定运行时条件表达式，也支持 `true/false`
- `--mtrace`: 打开数据访存 trace
- `--dtrace`: 打开 MMIO 设备访存 trace
- `--max-cycles N`: 限制最大执行周期数，传 `0` 可关闭超时，避免大型测试被固定周期数截断
- `--progress`: 打开周期性进度输出；如果默认配置里本来关着，会自动回退到每 `10000000` 条提交指令打印一次
- `--no-progress`: 关闭周期性进度输出
- `--progress-interval N`: 指定 progress 输出间隔，单位是“已提交指令数”，传 `0` 表示关闭
- `--trace`: 打开 VCD 波形，默认输出到 `build/npc-wave.vcd`
- `--trace-file path`: 指定 VCD 输出文件
- `--stdin-kbd`: 打开宿主 stdin 键盘桥
- `--diff=default|path`: 在已编译 `CONFIG_NPC_DIFFTEST=y` 时指定 difftest reference；`default` 使用 `nemu/build/riscv32-nemu-interpreter-so`
- `--diff-port N`: 指定 difftest reference 初始化端口，默认 `1234`
- `--no-diff`: 本次运行显式关闭 difftest，用于临时裸跑或观察性能差异

直接运行时，把参数放到 `RUN_ARGS`：

```bash
make -C /home/lyg/PA/ysyx-workbench/npc/single run \
  IMG=/home/lyg/PA/ysyx-workbench/am-kernels/kernels/hello/build/hello-riscv32-npc.bin \
  RUN_ARGS='--max-cycles 500000 --progress-interval 1000000 --trace --trace-file build/hello.vcd --log build/hello.log'
```

从 AM 侧运行时，把参数放到 `NPC_RUN_ARGS`：

```bash
AM_HOME=/home/lyg/PA/ysyx-workbench/abstract-machine \
make -C /home/lyg/PA/ysyx-workbench/am-kernels/kernels/hello ARCH=riscv32-npc run \
  NPC_RUN_ARGS='--max-cycles 500000 --progress-interval 1000000 --trace --trace-file build/hello.vcd --log build/hello.log'
```

如果要跑 difftest，先确认 `menuconfig` 中 `CONFIG_NPC_DIFFTEST=y`，再构建 reference：

```bash
make -C /home/lyg/PA/ysyx-workbench/npc/single difftest-ref
```

此时运行默认就会逐条对比 NEMU reference；如果想显式写清 reference，可保留 `--diff=default`：

```bash
make -C /home/lyg/PA/ysyx-workbench/am-kernels/tests/cpu-tests ARCH=riscv32-npc ALL=add run \
  NPC_RUN_ARGS='--diff=default --max-cycles 0'
```

## Monitor 和 batch

当前默认配置下，`NpcSimTop` 会直接以 batch 方式启动，等价于内建 `-b`，这样回归或跑测试镜像时不会再先停在 `(npc)` 提示符等手动输入 `c`。如果你想临时进入交互 monitor，可在命令行追加 `--no-batch`；显式传 `-b` 或 `--batch` 则继续强制走 batch。

如果你在 batch 或 `c` 路径下运行的是 CoreMark 这类长测试，可以额外打开 `--progress` 或显式指定 `--progress-interval N`；NPC 会按“已提交指令数”周期性打印一行进度，告诉你仿真仍在推进，而不是静默卡死。`si` 这类定步执行不会触发这类进度刷屏。

交互模式下，当前已经支持这组 NEMU 风格命令：

- `help`: 查看命令说明
- `c`: 连续运行
- `q`: 退出 monitor
- `si [N]`: 单步执行 `N` 条已提交指令，默认 1
- `info r`: 查看 32 个 GPR 和 `pc`
- `info w`: 查看当前 watchpoint 列表
- `info s`: 查看 NPC 状态、`pc`、核心状态编码、cycles、commits、host-us、inst/s
- `info t`: 查看 `itrace/mtrace/dtrace` 的 build 能力、运行时开关和当前 `itrace` 条件
- `x N EXPR`: 从表达式求值得到的地址开始查看 `N` 个字
- `p EXPR`: 计算表达式，支持寄存器、常数、逻辑/算术运算和一元解引用
- `w EXPR`: 建立 watchpoint
- `d N`: 删除 watchpoint
- `trace itrace|mtrace|dtrace on|off`: 在 monitor 里动态开关软件 trace
- `trace cond EXPR`: 在 monitor 里更新 `itrace` 条件

一个最小交互示例如下：

```bash
./npc/single/build/NpcSimTop \
  /home/lyg/PA/ysyx-workbench/am-kernels/kernels/hello/build/hello-riscv32-npc.bin \
  --max-cycles 200000
```

进入 `(npc)` 后，可以连续执行：

```text
help
info r
p $pc
si 1
w $pc
c
```

当前 `si N` 是按“提交条数”计数，并且在停下前会额外推进一个不产生新提交的周期，所以命令返回时看到的 `pc` 会前推到下一条待执行指令，更接近 NEMU 的单步观察体验。

当前 `Ctrl-C` 的语义也做了区分：

- 程序正在 `c` 或 batch 连续执行时，`Ctrl-C` 会先中断执行并回到 monitor
- 如果已经停在 `(npc)` 提示符上，再按一次 `Ctrl-C` 会直接退出整个 NPC 进程

## 软件 trace

当前这套 NEMU 风格壳已经把 `itrace/mtrace/dtrace` 做成“编译期能力 + 运行时开关”的两层模型：

- `itrace`: 记录已提交指令，支持条件表达式过滤，并会追加反汇编结果；若存在寄存器写回，日志里的 `xN<=VALUE` 表示“提交后的新值”
- `mtrace`: 只记录真实数据 `load/store`，不会把 IFU 取指混进日志
- `dtrace`: 记录 MMIO 设备访问，当前从 `device/map` 层统一收口

如果你只是临时追一段执行，不需要回 `menuconfig` 改默认配置，直接在运行时打开即可。

如果你希望日志文件默认就更接近 NEMU 的调试风格，可以在 `menuconfig` 里把 `NPC_LOG_FILE` 和 `NPC_*TRACE_BY_DEFAULT` 一起打开；这样 batch 运行时，`npc-log.txt` 会同时保留 welcome、guest 串口输出以及 `itrace/mtrace/dtrace`。

### 1. batch 下追首条提交的 itrace

```bash
./npc/single/build/NpcSimTop \
  /home/lyg/PA/ysyx-workbench/am-kernels/kernels/hello/build/hello-riscv32-npc.bin \
  -b --itrace --itrace-cond '$pc == 0x80000000' \
  --log build/itrace.log --max-cycles 200000
```

这类用法适合确认 reset 后第一条指令、某个跳转点、某段地址范围是否按预期提交。

### 2. batch 下同时看数据访存和设备访问

```bash
./npc/single/build/NpcSimTop \
  /home/lyg/PA/ysyx-workbench/am-kernels/kernels/hello/build/hello-riscv32-npc.bin \
  -b --mtrace --dtrace \
  --log build/mtrace-dtrace.log --max-cycles 200000
```

这类用法更适合排查“guest 为什么一直在读某块数据”或“串口/RTC/键盘 MMIO 是否真的被打到了”。当前 `hello` 打印字符串时会看到成批 `mtrace load`，那是 guest 逐字读取字符串，而不是 ifetch 噪音。

### 3. monitor 里动态开关 trace

进入 `(npc)` 后，可以直接这样操作：

```text
info t
trace itrace on
trace cond $pc == 0x80000000
si 2
trace mtrace on
c
```

其中：

- `trace cond true` 会把条件恢复成“不过滤”
- `info t` 里的 `build=y/n` 表示这项能力是否编进了当前二进制
- 如果某项 trace 没有编进二进制，monitor 和 CLI 都会提示你回 `menuconfig` 打开后重编

## 键盘交互

当前键盘桥支持三种模式：SDL 窗口模式优先服务图形程序，stdin 模式继续保留给终端交互和脚本化回归。

### 1. SDL 窗口模式

如果构建时检测到了 SDL2，NPC 会在 guest 首次提交 VGA sync 时弹出窗口；后续窗口里的 `keydown/keyup` 会直接被编码成 NEMU/AM 兼容的 `keydown/keycode` 事件。

这个模式适合 `typing-game`、`litenes`、`am-tests mainargs=v` 这类同时依赖 VGA 和键盘的程序，不需要额外打开 `--stdin-kbd`。

### 2. 终端交互模式

如果 stdin 是 TTY，并且打开了 `--stdin-kbd`，宿主会把终端切到原始模式，把输入转换成 NEMU/AM 兼容的 `keydown/keycode` 事件。

示例：

```bash
AM_HOME=/home/lyg/PA/ysyx-workbench/abstract-machine \
make -C /home/lyg/PA/ysyx-workbench/am-kernels/tests/am-tests ARCH=riscv32-npc run \
  mainargs=k NPC_RUN_ARGS='--stdin-kbd --max-cycles 500000 --no-itrace'
```

### 3. 脚本化模式

如果 stdin 不是 TTY，比如来自管道，仿真器会把它当作可回归的事件源。这适合自动化验证。

注意：脚本化输入时不要直接把管道喂给 `make ... run`，构建过程可能会抢先消费 stdin。最稳的方式是先把 `mainargs` 回填进镜像，再直接运行 `NpcSimTop`。

示例：

```bash
AM_HOME=/home/lyg/PA/ysyx-workbench/abstract-machine \
make -C /home/lyg/PA/ysyx-workbench/am-kernels/tests/am-tests ARCH=riscv32-npc insert-arg mainargs=k

printf 'a' | /home/lyg/PA/ysyx-workbench/npc/single/build/NpcSimTop \
  /home/lyg/PA/ysyx-workbench/am-kernels/tests/am-tests/build/amtest-riscv32-npc.bin \
  --stdin-kbd --max-cycles 500000 --no-itrace
```

如果链路正常，`readkey test` 会打印类似：

```text
Try to press any key (uart or keyboard)...
Got  (kbd): A (43) DOWN
Got  (kbd): A (43) UP
```

注意：`keyboard_test()` 本身是无限轮询，所以超时不等于功能失败。这里真正的成功标准是 guest 已经看到了 `DOWN/UP` 事件。

## VGA 测试语义

`am-tests mainargs=v` 和 `am-tests mainargs=d` 都会碰到 VGA，但两者测试的层级不同：

- `mainargs=v` 只验证基础 framebuffer 语义，也就是 `AM_GPU_FBDRAW` 能不能把一块像素矩形拷到 `FB_ADDR` 并通过 sync 刷出来
- `mainargs=d` 的 `devscan` 会继续验证高级 GPU ABI：先通过 `AM_GPU_MEMCPY` 把 canvas/texture 数据搬进一块 GPU 软显存，再通过 `AM_GPU_RENDER` 按根节点把树形画布渲染到 framebuffer

这也是为什么“基础 VGA 已经能画图”并不等于“devscan 已经通过”。如果 `GPU_MEMCPY/GPU_RENDER` 没补齐，`mainargs=v` 可能正常，但 `mainargs=d` 仍会在 GPU 阶段报 `access nonexist register`。

## 退出、异常和超时

当前有三类常见结束方式。

### 正常退出

程序通过 `ebreak + a0` 结束，宿主会打印：

```text
[npc] program exited via ebreak ... with code=N
```

### 异常停机

如果核心命中了当前支持范围内的 trap，宿主会打印：

```text
[npc] trap: cause=X pc=... tval=...
```

### 超时退出

如果程序没有结束且达到了 `--max-cycles` 上限，宿主会打印：

```text
[npc] timeout after ... cycles, last pc=... state=...
```

## 调试建议

建议优先使用下面这条最小闭环检查路径：

1. `make -C npc/single lint`
2. `make -C npc/single`
3. `make -C am-kernels/kernels/hello ARCH=riscv32-npc image`
4. `make -C npc/single run IMG=...`
5. 如需波形，再打开 `--trace` 和 `--trace-file`

如果要排查输入问题，优先先跑 `am-tests` 的 `mainargs=k`，再决定是否继续扩设备。

## 当前限制

这套环境已经适合 RV32I bring-up 和 AM 最小程序回归，但还不是完整平台：

- 普通 trap 目前仍是 halt-only 语义，还没有最小 CSR/trap handler 闭环
- 设备当前已覆盖 `serial/rtc/keyboard/vgactl/framebuffer`，并支持 `GPU_CONFIG/GPU_STATUS/GPU_FBDRAW/GPU_MEMCPY/GPU_RENDER`
- 如果构建时未检测到 SDL2，VGA 仍能走 headless framebuffer 语义，但不会弹出窗口，也不会有窗口键盘事件
- NEMU 上的 `am-tests mainargs=d` 现在已经能穿过 VGA 阶段并跑到 `Test End!`
- NPC 上的 `am-tests mainargs=d` 当前主要瓶颈已经不是 VGA，而是前面的 `timer_test` 忙等循环对多周期核太重，后面还叠加了磁盘设备尚未实现；因此若它还没完整跑完，先不要再把问题归因到 VGA 缺口
- 还没有 `mtime/mtimecmp`、完整 UART 状态机和更真实的总线协议
- DPI 总线目前是“一拍请求、一拍返回”的简单模型，目标是 bring-up，而不是最终 SoC 互连

## 推荐阅读

开始继续扩这个环境前，建议先看：

- `npc/single/design/study/README.md`
- `npc/single/design/study/RISC-V-spec-functional-sim-notes.md`
- `npc/single/design/study/RISC-V-spec-hardware-architecture-notes.md`

前两者帮助你理解当前功能仿真边界，后一份更适合后续补 CSR、trap controller、`mtime/mtimecmp` 和 PMEM/MMIO 边界。
