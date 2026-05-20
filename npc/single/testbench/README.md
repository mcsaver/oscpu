# NPC single 模块级 testbench

本目录保存 `npc/single/vsrc` 纯 RTL 核心模块的独立自检 testbench。每个 testbench 都只实例化目标模块或目标模块的直接封装，避免依赖 `NpcSimTop.sv` 的 DPI-C 宿主仿真壳。

## 使用方式

```sh
make -C npc/single/testbench run
```

默认结果会保留到：

```text
npc/single/perf/results/<timestamp>/module-testbench/
```

其中 `summary.txt` 是总表，`logs/*.log` 是每个模块 testbench 的编译和运行日志。也可以显式指定结果目录：

```sh
make -C npc/single/testbench run RESULT_DIR=../perf/results/manual/module-testbench
```

## 覆盖范围

- 组合基础模块：`ALU`、`CompareUnit`、`ImmGen`、`WBU`
- 译码与访存模块：`DecodeUnit`、`DecodeStage`、`LSUControl`、`LSUDataPath`、`LSU`
- 状态模块：`RegisterFile`、四个流水线寄存器、`MemoryStageControl`、`MemoryStage`
- 控制和长延迟模块：`CacheControl`、`PipelineControl`、`Rv32Divider`、`BranchPredictor`
- cache / IF / core smoke：`ICache`、`DCache`、`IfStage`、`NpcCore`

`NpcSimTop.sv` 是含 DPI-C 的仿真平台壳，不属于纯 RTL unit test；它继续由 `npc/single` 原有 Verilator lint/build 与 AM difftest 回归覆盖。
