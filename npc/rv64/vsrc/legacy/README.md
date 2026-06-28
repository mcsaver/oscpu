# RV64 legacy RTL 目录

本目录统一管理当前 RV64/OoO 主仿真路径未编入的历史 RTL。

- 本目录保持单层文件列表，避免和 `vsrc/cache`、`vsrc/core`、`vsrc/frontend`
  等活动目录形成重复层级。
- 文件包括早期顺序流水线、旧 cache/frontend/pipeline regs、旧
  `RegisterFile/PipelineControl/Rv32Multiplier/Rv32Divider/MemoryStage`
  等实现。

当前活动路径是 `NpcSimTop -> NpcCoreTop -> OooCoreTopGlue`，对应文件由
`vsrc/filelist.mk` 的 `RTL_CORE_SRCS` 维护。legacy 文件不进入默认 Verilator
构建，但保留 `RTL_*` 变量，方便历史模块 testbench 按需复跑和对比。
