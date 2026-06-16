# RV64 RTL PPA/可综合边界审计

- **日期**: 2026-06-03
- **任务**: 从仿真顶层 `NpcSimTop` 出发，逐层梳理当前 RV64 core/平台例化模块，识别功能仿真写法、商业 ASIC RTL 规范风险、PPA 风险与后续改造顺序。
- **范围**: `npc/rv64/vsrc/sim`、`npc/rv64/vsrc/core`、`npc/rv64/vsrc/bus`、`npc/rv64/vsrc/cache`、`npc/rv64/vsrc/common`、`npc/rv64/vsrc/frontend`、`npc/rv64/vsrc/ooo`。
- **本轮边界**: 只做结构审计和路线记录，不落高风险 RTL 修改；后续任何 RTL 改动需补齐“需求 -> 协议/状态机/不变量 -> 数据通路 -> RTL”四段式推导。

## RECALL

已读资料：

- `.github/AGENTS.md`
- `.github/copilot-instructions.md`
- `.github/memory/project-status.md`
- `.github/memory/known-issues.md`
- `.github/memory/modules/npc.md`
- `.github/instructions/rtl-generation-workflow.instructions.md`
- `.github/instructions/npc-optimization-workflow.instructions.md`
- `.github/instructions/verilator-tapeout-realism.instructions.md`
- `.github/instructions/memory-protocol.instructions.md`
- `.github/agents/verilator-tapeout.agent.md`
- `npc/rv64/README.md`
- `npc/rv64/design/study/README.md`

关键约束摘要：

- `NpcSimTop`/DPI/host C++ 可以服务 Verilator，但不能混入可综合 `RTL_CORE_SRCS`。
- 性能/PPA 改动不能只看单个 smoke；触碰 core 性能路径后必须跑 RV64 CPU-test 全量并报告 CPI 分布。
- 任何 RTL 改动前必须显式给出需求、协议/状态机/不变量、数据通路约束。
- 复杂/跨模块任务需在 `.github/task-runs/` 留证据，并把稳定结论回写 `.github/memory/modules/npc.md`。

## 模块树

```text
NpcSimTop
├── NpcTop
│   ├── NpcCoreTop
│   │   ├── OooFetchAxiBridge
│   │   │   ├── OooFetchPacketCache
│   │   │   └── OooSv39Tlb
│   │   ├── OooMemAxiBridge
│   │   │   ├── OooDataWordCache
│   │   │   └── OooSv39Tlb
│   │   └── OooAluFetchCore
│   │       ├── OooFpDecode x2
│   │       ├── OooRvcDecompressor x2
│   │       ├── OooJalrBtb
│   │       ├── OooBranchTargetCache
│   │       ├── OooBranchDirectionPredictor
│   │       ├── CsrFile
│   │       ├── DecodeStage x6 -> DecodeUnit + ImmGen
│   │       └── OooAluCoreSlice
│   │           ├── OooAluDecodeBackend -> DecodeStage x2 + OooIntBackend
│   │           └── OooArchRegFile
│   ├── NpcAxiBus -> AxiLiteXbar
│   ├── AxiLiteToUart -> Uart
│   ├── AxiLiteClint
│   ├── AxiLitePlic
│   └── AxiDefaultSlave 生成实例
├── AxiLiteVirtioBlk
├── AxiDpiSlave(psram)
└── AxiDpiSlave(legacy-mmio)
```

## 审计结论

### 1. 仿真/可综合边界

- `NpcSimTop.sv` 中 DPI import、层次化采样和 host 事件集中在仿真顶层，未进入 `RTL_CORE_SRCS`，边界方向正确。
- `NpcTop.v` 已成为可综合 SoC-level top，内部只例化 core、AXI-like bus、UART、CLINT、PLIC、默认错误 slave，并把 PSRAM/legacy MMIO/virtio 作为外部 AXI-Lite 端口导出。
- 当前可综合源未扫描到 DPI、`initial`、`$finish`、`$display`、`force/release` 等直接仿真硬伤；`make -C npc/rv64 lint` PASS。

### 2. 顶层与总线

- `NpcTop` 的 16 路 slave 地址图和端口切片可综合，但大量手写扁平总线切片影响可读性，后续商业风格应优先改成 SystemVerilog `interface`/packed struct 或统一 slice helper。
- `AxiLiteXbar` 当前是功能完整的 single-beat AXI-like crossbar，但在 `always @(*)` 中对 `S_COUNT*M_COUNT` 进行多层组合扫描，并在文件级关闭 `UNUSEDSIGNAL`。PPA 风险是仲裁/译码路径集中、参数扩展后关键路径不可控；规范风险是 lint waiver 粒度过粗。
- 后续建议把 xbar 分为“地址译码寄存化 + 每 slave 独立仲裁 + response route queue”，先保持 single outstanding 语义，再考虑多 outstanding。

### 3. IFU/LSU bridge 与 cache/TLB

- `OooFetchAxiBridge`、`OooMemAxiBridge` 采用明确 FSM，结构上比仿真一拍 memory 更接近硬件；Sv39 page-walk、abort/drop、TLB/cache 命中路径已有较清楚边界。
- `OooFetchPacketCache` 在 store invalidate 时全表扫描 `ENTRY_COUNT`；`OooBranchTargetCache` 在 store/fence 边界也全表扫描；BPU reset 对 BHT/local PHT 全表同步清零。这些功能正确，但 ASIC PPA 上会形成大扇出/大面积复位或组合比较网络。
- `OooDataWordCache` 是 word-cache/mini cache，不是 line-based cache。它适合当前 Verilator/Linux bring-up，但后续 PPA/性能目标应转向真实 line fill、tag/data RAM、store buffer/DMA 一致性协议。

### 4. OoO 前端/后端大模块

- `OooAluFetchCore` 约 5539 行，是当前最大风险点：前端控制、CSR/trap 协议、RVC、BPU/RAS、FP 串行路径、若干组合 FP helper 和 backend slice 接口仍集中在一个模块里。
- `OooAluFetchCore` 中 FDIV/FSQRT 仍使用组合 integer quotient/sqrt helper，`OooIntBackend` 中 RV64M `op1 / op2`、`op1 % op2` 也会被综合成重组合算子或大 IP 推断。它们能服务 focused gate，但不是优秀 PPA 的长期 RTL。
- `OooIntIssueQueue`、`OooRob`、`OooRenameMap` 等模块已经拆分，但 issue 选择/压缩/旁路仍以全表扫描为主。后续若扩大窗口或提频，应改成 age matrix、ready vector + priority encoder、物理 RAM/多读端口策略，而不是继续堆组合扫描。

## 优先级路线

1. **P0 边界保持**: 保持 `NpcSimTop`/`AxiDpiSlave`/`AxiLiteVirtioBlk` 为 simulation-only；`NpcTop` 作为 ASIC/FPGA 顶层，不把 DPI、host event 或层次化采样搬进 core。
2. **P1 先拆 FPU/M 执行**: 将 `OooAluFetchCore` 中 FP 算术/转换 helper 和 `OooIntBackend` 中 `/`、`%` 收敛成独立多周期执行单元，使用 request/response/kill/fflags 协议。
3. **P1 规范化 xbar**: 将 `AxiLiteXbar` 的组合仲裁拆成清晰状态机和可局部验证的 route queue，去掉文件级 lint waiver。
4. **P2 cache/TLB SRAM 化**: 把 packet/word cache 逐步替换成 tag/data RAM + line fill；清表/失效从全表扫描改为 valid bit bank、generation bit 或 set/way 定点 invalidate。
5. **P2 OoO 队列结构化**: ROB/IQ/rename/free-list 继续拆分控制与存储体，明确 flush checkpoint 代价和恢复协议，避免大规模 full snapshot 成为面积瓶颈。
6. **P3 接口风格升级**: 在确定工具链支持后，把活动 RTL 迁到 `.sv`，采用 `logic`、`always_ff`、`always_comb`、`typedef enum logic`、interface/modport 或 packed struct 降低扁平端口噪声。

## 验证证据

- `make -C npc/rv64 lint` PASS。
- 静态扫描确认 DPI 只出现在 `npc/rv64/vsrc/sim/{NpcSimTop.sv,AxiDpiSlave.sv,AxiLiteVirtioBlk.sv}`。
- 规模统计：活动 RV64 RTL/sim 总计约 18020 行，其中 `OooAluFetchCore.v` 5539 行、`OooIntBackend.v` 1878 行、`OooIntIssueQueue.v` 934 行，是后续拆分/PPA 重点。

## 下一步建议

下一轮建议先做一个单模块闭环：从 `OooIntBackend` 的 RV64M 除法/取模或 `OooAluFetchCore` 的 FP helper 中选一个，按四段式推导设计多周期执行单元，补 focused testbench，再跑 RV64 CPU-test 全量。
