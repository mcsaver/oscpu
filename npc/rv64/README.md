# 承岳64（ChengYue64）

本目录的默认 RV64 实现为 **承岳64 v1.0.0**，版本由
[core-version.mk](core-version.mk) 定义。默认 RTL 位于 `vsrc/chengyue64/`，
仿真宿主位于 `sim/`，差分检查位于 `difftest/`，测试用例位于 `testbench/chengyue64/`，构建输出位于 `build/chengyue64/`。

## 按用途查找

| 要了解的内容 | 文档入口 | 对应目录职责 |
| --- | --- | --- |
| CPU、系统顶层与模块连接 | [架构入口](ARCHITECTURE.md) | `vsrc/chengyue64/` 保存主线 RTL 和就近维护的模块说明 |
| 设计规范、取舍与文献 | [设计文档](design/README.md) | `design/` 区分主线设计、共享 IP 规范和旧核资料 |
| 模块、整核、软件回归 | [验证入口](testbench/chengyue64/README.md) | `testbench/` 保存具体测试用例、oracle 和回归脚本 |
| NEMU 参考接口、CSR 比较与比较时机 | [DiffTest](difftest/README.md) | `difftest/src/r64_difftest.cpp` 实现参考模型适配及状态比较 |
| Linux、L2/L3、UART、磁盘与 NPU 运行 | [系统仿真](sim/README.md) | `sim/` 保存宿主、镜像与设备支持、仿真 RTL 封装 |
| 综合、时序约束与 hold 修复 | [综合与 STA](syn/README.md) | `syn/` 保存 ASIC 综合/STA 的约束与工具 |
| 性能和行为模型 | [模型入口](model/README.md) | `model/` 独立说明各模型的精度、速度和验证范围 |
| 正式版本的验证结果和 CPI/STA 数据 | [v1.0.0 版本说明](releases/chengyue64-v1.0.0/README.md) | `releases/` 保存指定版本的发布记录 |
| 重写过程、冻结候选与旧核记录 | [历史文档](design/history/README.md) | `design/history/` 保存已被后续主线替代的记录 |

`sim/src/r64_sim_main.cpp` 采集 RTL 退休和 trap 事件，通过独立的 DiffTest 接口调用 NEMU。
`testbench` 使用这套运行设施组织用例，三者通过 [sim/build.mk](sim/build.mk) 共享构建规则。
生产 RTL 仍位于 `vsrc/`，仿真专用封装位于 `sim/vsrc/`。

## 常用命令

从工作区根目录运行：

```sh
make -C npc/rv64 version
make -C npc/rv64                         # 构建默认系统仿真器
make -C npc/rv64 lint
make -C npc/rv64 test                    # 模块测试及相关矩阵
make -C npc/rv64 core-test               # 整核、系统、吞吐及 I/O 定向验证
make -C npc/rv64 software-test          # AM、官方 ISA、ACT4
make -C npc/rv64 run IMG=/absolute/guest.bin RUN_ARGS="--maxcycles=20000000 --progress"
```

目标由 [Makefile](Makefile) 定义；更多回归、系统运行和综合命令在上表各入口中维护。
`npc/sim BACKEND=rv64` 的构建、lint 和运行仍转发至此工程。
`regression` 包含 lint、模块、整核、非 OS 软件和设备测试；Linux L2/L3 与 Tensor/NPU
使用单独目标，其结果不能由短回归代替。

## 当前版本与历史兼容

正式命名于 2026-09-16，原开发名为 `rebuildcore`。`vsrc/rebuild` 和 `testbench/rebuild`
保留为正式目录的兼容链接；部分旧核 RTL 路径链接到
[旧核源码包](../pack/rv64core-legacy-20260916/README.md)。
默认构建不使用[legacy/sim/](legacy/README.md) 中的旧核仿真器和 `Makefile.legacy`。

`eval/`、`perf/`、`vivado/` 中保留的旧流程有各自适用范围，不能用其历史指标描述承岳64。
当前版本的测量范围以[发布说明](releases/chengyue64-v1.0.0/README.md)为准：
**1 ns / 1 GHz 时序尚未闭合**，版本命名和目录整理不构成新的功能或 PPA 验证。
