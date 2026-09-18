# NPC soc 模块级 testbench

本目录保存 `npc/soc/vsrc` 纯 RTL 核心模块的独立自检 testbench。每个 testbench 都只实例化目标模块或目标模块的直接封装，避免依赖 `NpcSimTop.sv` 的 DPI-C 宿主仿真壳。

## 使用方式

```sh
make -C npc/soc/testbench run
```

默认结果会保留到：

```text
npc/soc/testbench/build/results/<timestamp>/module-testbench/
```

其中 `summary.txt` 是总表，`logs/*.log` 是每个模块 testbench 的编译和运行日志。也可以显式指定结果目录：

```sh
make -C npc/soc/testbench run RESULT_DIR=build/results/manual/module-testbench
```

流水线级性能气泡仿真使用独立目标 `pipe_test`：

```sh
make -C npc/soc/testbench pipe_test
```

默认结果会保留到：

```text
npc/soc/perf/results/<timestamp>/pipe-test/
```

其中 `bubble_report.txt` 记录 MEM/DCache 侧指标，`stage_bubble_report.txt` 记录跨流水级指标，包括 `ICache -> IfStage -> IF/ID` hit 直通、MEM 级 DCache hit、以及 ID 级 load-use 气泡。需要记录优化前基线时，可以临时关闭对应零等待断言：

```sh
make -C npc/soc/testbench pipe_test PIPE_EXPECT_LOAD_HIT_ZERO=0 PIPE_RESULT_DIR=../perf/results/manual/pipe-test-baseline
make -C npc/soc/testbench pipe_test PIPE_EXPECT_FRONTEND_HIT_ZERO=0 PIPE_RESULT_DIR=../perf/results/manual/frontend-baseline
```

## 覆盖范围

- 组合基础模块：`ALU`、`CompareUnit`、`ImmGen`、`WBU`
- 译码与访存模块：`DecodeUnit`、`DecodeStage`、`LSUControl`、`LSUDataPath`、`LSU`
- 状态模块：`RegisterFile`、四个流水线寄存器、`MemoryStageControl`、`MemoryStage`
- 控制和长延迟模块：`CacheControl`、`PipelineControl`、`Rv32Divider`、`BranchPredictor`
- cache / IF / core smoke：`ICache`、`DCache`、`IfStage`、`NpcCore`

`pipe_test` 不是单模块 PASS/FAIL 用例，而是流水线级微基准：`pipe_test.sv` 把 `MemoryStage`、`DCache` 和 `PipelineControl` 放在同一个仿真里，`stage_pipe_test.sv` 进一步把 `ICache`、`IfStage`、`IfIdPipeReg`、MEM 级和控制级组合到一个专门顶层里，按流水线边界提取气泡并验证后续性能优化是否真的减少等待周期。

`NpcSimTop.sv` 是含 DPI-C 的仿真平台壳，不属于纯 RTL unit test；它继续由 `npc/soc` 原有 Verilator lint/build 与 AM difftest 回归覆盖。

## 职责边界

`tests/` 保存自检用例，`common/` 保存编码和断言辅助。生产模块来自
[`../vsrc/filelist.mk`](../vsrc/filelist.mk)；程序仿真壳在
[`../sim/`](../sim/README.md)，参考模型同步和架构状态比较在
[`../difftest/`](../difftest/README.md)。旧的模块测试记录仍保留在 `../perf/results/`；新结果默认写入本目录的 `build/results/`。
