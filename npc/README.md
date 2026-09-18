# NPC 顶层入口

`npc/` 是工程总入口，[sim/](sim/README.md) 负责选择和转发后端。
外部模块可继续通过 `npc/sim` 运行；后端内部按设计、仿真、差分检查和测试用例分工。

- `single`: 默认后端，面向 AM / `riscv32-npc` / `NpcSimTop` 自仿真，不接入 ysyxSoCFull。
- `rv64`: **承岳64（ChengYue64）v1.0.0**，RV64 正式主线；详见 [rv64/README.md](rv64/README.md)。
- `soc`: 从 `single` 复制出的 ysyxSoC 接入版本，保留 `ysyx_26010035`、`NpcSoCAxiBridge` 和 `soc/soc-lint`。

## 目录职责

| 内容 | 目录 | 放置原则 |
| --- | --- | --- |
| 后端选择与统一命令 | [sim/](sim/README.md) | 只做选择、配置和转发 |
| 后端工程 | [single/](single/README.md)、[soc/](soc/README.md)、[rv64/](rv64/README.md) | 保留各自 RTL、配置和构建边界 |
| 可综合硬件 | 各后端 `vsrc/` | CPU、总线、平台硬件与源文件清单 |
| 仿真运行设施 | 各后端 `sim/` | `src/` 宿主，`include/` 头文件，`vsrc/` 仿真专用 RTL/DPI 封装 |
| 差分测试机制 | 各后端 `difftest/` | 参考模型加载、状态同步、架构比较及对应接口 |
| 具体测试用例 | 各后端 `testbench/` | 激励、断言、oracle、测试程序和回归脚本 |
| 设计说明 | 各后端 `design/` | 规范、设计取舍、学习资料；历史记录另列 |
| 综合与时序 | 各后端 `syn/` | 约束、综合/STA 脚本和使用说明 |
| 实验 IFU | [rv-cpu/](rv-cpu/README.md) | 独立实验，不是三个正式后端之一 |
| 外部测试资产 | [testsuites/](testsuites/README.md) | 保留测试来源，不混入仿真器实现 |
| 历史性能结果 | [perf/](perf/README.md) | 保留原始结果目录，当前结论看对应后端和版本 |
| 封存源码包 | [pack/](pack/README.md) | 固定历史快照，不随当前路径整理改写 |

RV64 另有 `model/`（行为/性能模型）、`releases/`（版本记录）和 `legacy/`
（仍被旧入口引用的仿真宿主）。`build/` 保存生成文件，不作为源码或文档入口。

DiffTest 是供仿真宿主调用的检查机制，`.sv` testbench 是带有具体激励和断言的测试。
二者可以配合使用，因此分别归入 `difftest/` 与 `testbench/`；语言后缀不决定目录职责。

常用命令：

```sh
make -C npc lint
make -C npc run IMG=/path/to/image.bin RUN_ARGS='--no-progress -m 0'
make -C npc BACKEND=soc lint
make -C npc soc-lint
make -C npc soc
```

如果希望持久切换默认后端，推荐走 `npc/sim` 自己的 Kconfig 配置：

```sh
make -C npc/sim menuconfig
make -C npc/sim single_defconfig
make -C npc/sim soc_defconfig
make -C npc switch BACKEND=soc
make -C npc status
make -C npc switch BACKEND=single
```

`BACKEND=am` 是 `single` 的别名，`BACKEND=ysyx-soc` 是 `soc` 的别名。`abstract-machine` 的 `riscv32-npc run` 入口会直接调用 `npc/sim`；默认跟随 `npc/sim/.config`，仓库默认配置为 `single`，需要临时切到 SoC 复制版时可传 `NPC_SIM_BACKEND=soc`。旧的 `NPC_PLATFORM=soc` 仍保留兼容。若要配置当前真实后端自身的 Kconfig，可从顶层使用 `make -C npc backend-menuconfig` 或 `make -C npc backend-perf_defconfig`。

## RV64 正式主线与旧核归档

`make -C npc BACKEND=rv64 lint` 和 `make -C npc/rv64` 使用承岳64。
旧 rv64core 独立源码包位于 [pack/rv64core-legacy-20260916](pack/rv64core-legacy-20260916/README.md)。
