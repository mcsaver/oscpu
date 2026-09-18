# 承岳64 系统运行

当前 CPU 为 `R64CoreTop`，平台为 `R64SystemTop`，Tensor 平台为 `R64TensorSystemTop`。
系统入口使用本目录的 [R64SystemTestTop.sv](vsrc/R64SystemTestTop.sv) 和
[r64_sim_main.cpp](src/r64_sim_main.cpp)；逐退休 PC/GPR/FPR 检查与每拍事件完成后的选定 CSR
检查见 [DiffTest 说明](../difftest/README.md)。旧 `NpcSimTop` 的运行或 PPA 证据格式不适用于此入口。

本文件集中维护使用方式；架构与历史结果分别见 [ARCHITECTURE.md](../ARCHITECTURE.md)
和 [完整替换记录](../design/arch/rv64-replacement.md)。

## 源码职责

| 目录 | 职责 |
| --- | --- |
| [src/](src/) | 仿真主循环、镜像装载调度、AXI 外存/设备服务、UART 输入输出与运行终态 |
| [include/](include/) | 镜像与 block 模型，以及 Verilator 运行时适配 |
| [vsrc/](vsrc/) | 核/系统/Tensor 的 RTL 仿真封装与观测、DPI 和平台接入封装 |
| [../difftest/](../difftest/README.md) | NEMU 参考接口与架构状态比较策略 |
| [../testbench/chengyue64/](../testbench/chengyue64/README.md) | 模块 TB、定向程序、回归 runner 与测试生成器 |

`r64_sim_main.cpp` 从退休记录恢复 DUT 架构状态，向 DiffTest 提交事件；真实 CSR 由封装输出。
默认模型适配头为 `r64_verilator_dut.h`。CXXRTL/network 用 `R64_DUT_HEADER` 指定其他适配头，
提供同一组 DUT 端口、`eval()/final()` 和 `r64::initialize_dut()`；各后端编译同一个宿主源文件
和独立差分引擎，不截取或改写主程序。构建与常用运行仍可从 RV64 根 Makefile 进入。

本目录 [Makefile](Makefile) 提供 `core`、`system`、`tensor` 和 `lint`，共用
[build.mk](build.mk)；具体测试由 `testbench/` 调用同一套构建规则。生成文件仍写入
`rv64/build/chengyue64/{core,system,tensor-system}`，可分别用 `CORE_BUILD_DIR`、
`SYSTEM_BUILD_DIR`、`TENSOR_BUILD_DIR` 覆盖。

## L2 / L3 分层验证

从工作区根运行：

```sh
make -C npc/rv64 all difftest-ref
make -C npc/rv64 device-test
make -C npc/rv64 l2-test SYSTEM_CASE=all CORE_THREADS=2
make -C npc/rv64 l3-test SYSTEM_CASE=all CORE_THREADS=2

# 复用已有标准 L3 镜像目录：
make -C npc/rv64 l3-test SYSTEM_IMAGES=/absolute/l3-images SYSTEM_CASE=all CORE_THREADS=2
```

未提供 `SYSTEM_IMAGES` 时，根 [Makefile](../Makefile) 调用 Linux 目录中的
[L2 镜像脚本](../../../Linux/scripts/build-rv64-mini-system.sh) 或
[L3 镜像脚本](../../../Linux/scripts/build-rv64-lightweight-linux.sh)。
随后由 [run_r64_system.py](../testbench/chengyue64/scripts/run_r64_system.py) 执行与检查。

| 参数 | 用途 |
| --- | --- |
| `SYSTEM_IMAGES` | 已有标准镜像目录；L2 包含 `fw_jump.bin`、`mini-system.bin`、`mini-system.dtb`；L3 包含 `fw_jump.bin`、`Image`、`guest.dtb`、`initramfs.cpio` |
| `SYSTEM_CASE` | 默认 `all`；子场景选择以 runner 引用的 L2/L3 场景定义为准 |
| `SYSTEM_TIMEOUT` | 宿主超时秒数，默认 14400 |
| `SYSTEM_RUN_ARGS` | 传给 Python runner 的附加参数，例如 `--max-cycles`、`--progress`、`--stalls` |
| `CORE_THREADS` | Verilator 宿主线程数；不改变 RTL 时钟或流水拍数 |
| `CORE_JOBS` | 构建并行度 |

每次执行在 `npc/rv64/build/chengyue64/l2-run-*` 或 `l3-run-*` 保留独立目录，
含 `console.log`、`command.json`、模型副本及 `summary.json`。
仅 `SYSTEM_CASE=all` 表示相应层的完整 guest 场景。运行中、超时、缺少终态和缺少所需阶段输出
都不计通过；runner 检查自然 syscon 关机、UART 输入顺序及对应 guest 阶段。

2026-09-15 的完整替换记录包含 L2 all、Linux 6.6 + PID1 L3 all 和 NPU 主工作流通过结果。
其中 L3 为 23,863,944 次退休、75,766,731 周期和一次自然关机。
这些数字是该次运行的历史结果，详细范围见 [完整替换记录](../design/arch/rv64-replacement.md)。

## 直接加载多镜像

```sh
make -C npc/rv64 run IMG=/absolute/fw_jump.bin \
  RUN_ARGS="--system --memory=0x08000000 --load=0x80400000:/absolute/Image --load=0x82300000:/absolute/guest.dtb --load=0x84000000:/absolute/initramfs.cpio --uart-stdin --maxcycles=1500000000 --progress"
```

`IMG` 指定启动镜像，`--load=地址:路径` 可重复提供其它镜像。
`--memory` 指定 RAM 字节数，要求按 4 KiB 对齐且在 4 KiB–1 GiB 范围内。
`--maxcycles` 是仿真周期上限；超限视为失败。

`--system` 使 `EBREAK` 进入正常异常处理，以真实 syscon 关机为结束条件。
syscon 信号可能先于存储指令退休到达，宿主会等待参考端执行相同 MMIO 写入并完成状态检查。
`--expect=TEXT` 要求关机前出现指定 UART 输出，本身不会提前结束仿真。
系统模式不能与 `--tohost` 同用。

## UART 与 block

`--uart-input=MARKER:BYTES` 在 guest 输出指定文本后发送测试输入，可重复使用；
`--uart-stdin` 接收真实标准输入。UART RTL 支持 8250 的 MCR/MSR/SCR、16 字节 RX FIFO、
回环和中断读确认。仿真接口传送完整字符，不模拟串行位线和波特率时间。
DUT 与参考模型的 UART 输出按字节比较。

`--block=/absolute/writable-run.ext4` 连接 virtio-mmio IRQ2。直接调用者应传入可写的运行副本；
[Linux Makefile](../../../Linux/Makefile) 会从模板创建独立副本，参考侧另外使用独立快照。
宿主 block 模型复用 NEMU 设备代码但独立实例化，ISA 参考的内存、设备、磁盘及执行状态保持独立。
这不取消 PC/GPR/FPR 和选定 CSR 检查。

外部 AXI-Lite 端点还提供 RAM 及已有 legacy RTC/VGA/framebuffer 仿真设备；具体行为以
宿主实现和 [system I/O 测试程序](../testbench/chengyue64/programs/r64_core_system_io.S) 为准。

## Linux 与 NPU 主入口

[Linux Makefile](../../../Linux/Makefile) 的 NPC `sim/run` 主入口已使用本原生系统。
其 `NPC_SIM_THREADS` 默认 2；本目录核心短回归的 `CORE_THREADS` 默认 1。
镜像、rootfs 与运行 profile 由 [Linux 文档](../../../Linux/README.md) 维护。

NPU 主工作流从工作区根运行：

```sh
bash npu/version_0820/scripts/run_rv64_direct_npu_system.sh
```

该入口内部 CPU 已切换为原生核；旧 OoO 内部统计请求不适用，新路径报告实际事务时序。
脚本源码见 [NPU 系统入口](../../../npu/version_0820/scripts/run_rv64_direct_npu_system.sh)。
本目录的 `make -C npc/rv64 tensor-test` 是另一个有明确覆盖范围的定向回归，见
[验证 README](../testbench/chengyue64/README.md) 与 [DiffTest 的 Tensor 边界](../difftest/README.md)。

OpenSBI、kernel、PID1、rootfs mount、完整 Ubuntu、NPU 主工作流与 1 GHz PPA
必须分别依据对应结果判断。L3 all 通过不等于完整 Ubuntu 通过，系统功能通过也不等于时序闭合。
