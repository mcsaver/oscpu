# version_0820 NPU 架构与验收合同

## 1. 目标与边界

本目录实现一个面向 `npc/rv64` 的 RISC-V Tensor 协处理器，并以 Verilator 作为近期功能验证平台。
Tensor 指令编码与语义以同目录 PDF《基于 RISC-V 的 Tensor 扩展指令集》为规范输入；本文只补充
该 PDF 没有定义、但软硬件集成必须具备的平台接口与验证边界，不另行发明冲突的指令编码。

本项目必须满足以下工程边界：

- 所有新增源码、下载物、模型、构建产物和日志都位于 `npu/version_0820/`；临时文件只位于
  `npu/version_0820/tmp/`。
- 本项目当前处于**功能实现阶段**。NPU 只作为 Verilator RTL/host 功能仿真对象，不执行、也不以任何
  方式调用综合、STA、面积、功耗或 PPA 流程；不得用功能仿真结果外推物理实现结论。
- `npc/rv64/` 是 NPU 控制核，允许为 NPU-first 协处理器事务进行大幅 production RTL 调整。CPU 修改
  必须通过受影响模块的 Verilator 定向正向、反压/flush/异常负向和集成测试；本目标同样禁止为 CPU
  运行综合、STA 或 PPA 测评。
- NPU RTL DUT 与 Verilator/host-only oracle 严格分层；DPI、文件 IO、GGUF/模型解析和宿主线程不得
  混入 RTL DUT。此分层只用于行为与证据边界，不构成本阶段的可综合性声明。
- 默认验证使用 Verilator。问题定位阶段允许 assertions/waveform；问题闭合后的默认运行关闭二者，
  并启用 Verilator 与宿主编译器的最高实用优化级别。
- 模型验收使用用户指定的 Qwen3.5-0.8B。模型仓库名、量化格式和许可证必须在下载前由官方或上游
  一手来源核实，不能用相近型号冒充。
- Qwen 的主要计算必须由 NPU 协处理器完成。目标 opclass 的 CPU 软件 fallback、host 直接代算或
  “unsupported 后透明回落”一律 fail-closed；每个模型测试必须同时核对 NPU issue/completion 计数、
  目标 offload 数、`cpu_fallback_attempts == 0` 和 `host_tensor_arithmetic == 0`，不能只看最终文本是否合理。

当前明确不在本切片范围内：

- 宣称完整覆盖 PDF 中全部卷积、浮点、SFU、Gather/Scatter、多核消息和 DMA 变体；
- 运行或发布 NPU/CPU 的综合、STA、面积、功耗、PPA、Pareto 或流片签核结果；
- 把宿主快速功能模型称为 NPU RTL 数据通路，或把 CPU oracle 的 tokens/s 称为 NPU 仿真吞吐；
- 允许目标主要算子在最终模型验收中静默绕过 NPU。

## 2. 从规范冻结的事实

### 2.1 指令编码

- 所有 Tensor 扩展指令使用 major opcode `7'b1011011`（RISC-V `custom-2`）。
- CSR/TCR 配置指令是单个 32-bit word，配置指令使用 `funct3=3'b100`。
- TIU 计算指令与 GDMA 指令由 `LO[31:0]`、`HI[63:32]` 两个各自带 `custom-2` opcode 的 32-bit
  word 组成。
- TIU `HI` 的目标/源字段为 `td=HI[19:15]`、`ts1=HI[11:7]`；`LO` 携带 `ts4=LO[24:20]`、
  `ts3=LO[19:15]`、`ts2=LO[11:7]` 和子操作字段。
- GDMA 的 Tensor ID 是 6 bit；TIU/配置路径的操作数 ID 是 5 bit。

### 2.2 Tensor 状态

- TCR 共 40 项：CR `R0..R7`、TR `R8..R31`、GR `R32..R39`。
- CR 描述常量；TR 描述 LMEM Tensor；GR 描述 GMEM/SMEM Tensor。
- PDF 为 TR 定义 256 bit 描述符，为 GR 定义 288 bit 描述符，但 `rvt_tr/rvt_gr` 只定义了前
  64 bit 的更新方法。
- `teew/subtype` 共同决定整数或浮点类型；高性能整型矩阵乘 `rvt_mm2.*` 的输入为 S8/U8，未量化
  输出为 S32/U32。

### 2.3 引擎与同步

- 规范区分 TIU 计算引擎和 GDMA 引擎。
- `rvt_sync_i rs,_engine` 必须等待它之前的目标引擎命令完成；完成后把 `rs` 中的 tag 写入
  `CSR.sync_tag`。`_engine=0/1/2` 分别表示全部/TIU/GDMA。
- CPU 读取 `sync_tag` 后该寄存器自动清零。
- DMA 在 GMEM 与 LMEM 之间搬运 Tensor；计算指令主要消费 CR/TR。

## 3. 规范缺口与本项目的平台补充

下列信息无法从 PDF 得到，必须显式标为平台 ABI，不能伪称为 ISA 原文：

1. **64-bit 指令原子性缺口**：`0x5b` 的低位模式在标准 RISC-V 长度判定中仍是 32-bit 指令，PDF
   没有定义两个 word 的取指、异常、跨页、分支落点或乱序原子性。本项目定义软件/测试输入按
   little-endian `LO` 后 `HI` 顺序提交，并在协处理器边界一次性合并为 64-bit command。
2. **完整 TCR 写入缺口**：PDF 没有给出 shape/stride 高位字段的指令写入方法。本项目提供独立的
   MMIO descriptor window 写入 TCR 高 64-bit word；word0 仍可由正式 `rvt_cr/rvt_tr/rvt_gr` 更新。
3. **队列/异常缺口**：PDF 没有定义队列深度、非法描述符、越界、总线错误或数据类型不匹配的
   architectural trap。本项目通过 MMIO `STATUS/ERROR` fail-closed 上报，错误命令不产生部分完成。
4. **一致性缺口**：PDF 没有定义 CPU cache coherence、IOMMU、页表或虚拟地址翻译。本切片的 GMEM
   地址按已验证的物理地址处理，软件在交接前后承担 cache clean/invalidate；不能据此宣称硬件一致性。
5. **LANE/EU 参数缺口**：PDF 没有给出 `LANE_NUM/EU_NUM` 的强制值。本项目参数化实现，首个
   Verilator RTL MVP 使用小规模、单命令、确定性数据通路；host oracle 必须另行标注且不得计作 NPU。

## 4. `npc/rv64` 协处理器接入策略

### 4.1 bring-up/回滚兼容路径（illegal trap + MMIO）

`NpcTop` 已把 legacy-MMIO 窗口导出为一组独立 AXI-Lite slave 端口；当前地址合同为：

- base：`0x0000_0000_1200_0000`
- mask：`0xffff_ffff_fe00_0000`
- window：32 MiB

本目录的仿真 wrapper 可在该窗口内实现 NPU MMIO slave。Guest 侧执行真实 `custom-2` word 时，基线
`npc/rv64` 会产生 precise illegal-instruction trap；本目录提供的 M-mode 兼容处理器按以下规则转发：

1. 单字配置指令：从 trap frame 读取编码中的 GPR `rs`，向 NPU 写 `CMD_LO/RS_VALUE` 后 doorbell。
2. 64-bit `LO` word：保存 word 和 PC，令 `mepc += 4`，暂不发命令。
3. 紧接的合法 `HI` word：与已保存 `LO` 合并为 64-bit command 后 doorbell；不相邻、类型不匹配或
   跨控制流时清除 pending pair 并报告错误。
4. `sync.i`：doorbell 后轮询低开销 `STATUS`/`SYNC_TAG`；轮询受超时上限约束，不能无限卡死。
5. 非 Tensor illegal instruction：链回原 trap 处理，不得被 NPU handler 吞掉。

该路径只用于 bring-up、差分定位和 direct-path 回滚；每个 word 都有 trap 开销，且无法满足“模型主要
计算强制走 NPU 直连事务”的最终验收。它不得作为模型性能路径，也不得把 host/TLM 代算计入 NPU
offload 计数。

### 4.2 当前目标：NPU-first 直接发射路径

本目标已授权修改 `npc/rv64`。direct custom-2 路径必须冻结 fetch/pair → decode → pending owner →
NPU request → completion → ROB precise commit/flush 的完整事务，并覆盖跨模块 backpressure、kill、
异常序、提交可见性和 DMA/cache ordering。正式结构以通过路由的 CPU Architect Architecture IR 和
六类接口合同为准；在该合同落盘并通过定向反例前，不实施症状级译码补丁。

已选结构、相对周期、pair/sidecar FSM、六类合同、required-offload 计数点、实现 footprint、
Verilator/mutation 计划和未闭合 GAP 统一维护在
[`RV64_DIRECT_NPU_CONTRACT.md`](./RV64_DIRECT_NPU_CONTRACT.md)。当前实现已经让真实 RV64 取指流经过
pair owner、decode/dispatch、ROB sidecar、不可回滚 NPU request、terminal exact-match 和 precise commit；
四条单字 CONFIG 可建立一个 `VECTOR_F32/P00` descriptor，紧邻 LO+HI 宏命令会等待真实
`TensorNpuCoprocessor` 经共享 raw GMEM 完成后才退休。项目内 fresh、O3、无 assert/无 waveform 的系统
测试同时覆盖 command/terminal backpressure、成功 raw-bit oracle 和 NPU 错误的 precise exception。

该实现仍是受限 slice，不得扩大解释为完整模型 CPU 前端：CONFIG 编码目前只承载 P00 所需的
`src0/src1/dst/sequence`，GMEM 使用独占 uncached 物理 aperture；尚无所有宏 kernel 的通用 descriptor
提交、cache coherence/IOMMU 或 Qwen 全图经 RV64 指令逐节点发射的证据。动态 backend 的 host 前端只
负责 Verilator command/GMEM 握手，不能代替这个剩余 ISA/CPU 集成 GAP。

最终模型路径必须为 NPU-required：软件或指令元数据明确目标 opclass，CPU 对其只负责发起、等待和
精确提交；NPU 不支持、队列/描述符错误或协议异常必须返回精确错误或 trap，不能透明改由 CPU 计算。
允许 CPU 执行的集合仅限显式登记的轻量控制/标量工作（例如 tokenization、采样、循环调度及尚未列为
目标 opclass 的小型标量算子），并通过计数器与测试 manifest 与主要计算集合区分。

## 5. RTL 阶段 1：可验证需求

### 5.1 功能目标

首个 Verilator RTL 功能 MVP 必须：

- 接收单个 32-bit 配置命令或已合并的 64-bit Tensor command；
- 实现 CR/TR/GR word0、关键 CSR、descriptor window 和只读状态；
- 实现 `rvt_dma_ld`、`rvt_dma_st` 的线性连续布局子集；
- 实现 `rvt_mm2_nn` 的 S8/U8 × S8/U8 → S32/U32、可选 bias、可选 ReLU 子集；
- 实现 `rvt_sync_i` 的 all/TIU/GDMA 完成 tag；
- 对未实现 opcode、描述符越界、LMEM 越界、shape 不相容和总线错误给出确定性错误码；
- 提供命令数、TIU 周期、DMA 字节数等性能计数器。
- 提供 `npu_required_issued/completed`、按 opclass 的 offload 数与 `cpu_fallback_major_ops` 观测；模型
  回归要求 required issue/completion 与 manifest 一致且 fallback 为 0。

### 5.2 端口与时钟

- 单时钟域 `clk`，同步高有效复位 `rst`。
- command：`cmd_valid/cmd_ready/cmd_is_64/cmd_bits[63:0]/cmd_rs_value[63:0]`。
- descriptor：`desc_valid/desc_ready/desc_id[5:0]/desc_word[2:0]/desc_wdata[63:0]`。
- GMEM master：单 outstanding 的 64-bit request/response ready-valid 接口，含地址、读写、WSTRB 和
  error。
- host LMEM debug port 仅用于 Verilator directed test，默认参数关闭；不能进入正式 SoC 接口。
- status：`busy/error/error_code/sync_tag/sync_tag_valid` 以及只读计数器。

### 5.3 性能/时序目标

- MVP 只保证功能正确，允许单命令串行；command 在 `IDLE` 时一拍接收。
- GMEM 请求最多一个 outstanding；发出后不允许取消。
- MM2 使用明确打拍的 MAC 数据通路，目标为每周期至少完成一个 S8/U8 乘加；不以该 MVP 的
  tokens/s 代表最终 NPU 性能。
- 组合路径不得跨越 command decode → descriptor read → multiply → accumulator → memory write 全链；
  decode、MAC 和 writeback 至少由状态寄存器分隔。

## 6. RTL 阶段 2a：协议规则

### P1 command ready-valid

- producer 可独立拉高 `cmd_valid`；在 `cmd_valid && !cmd_ready` 期间，全部 command payload 必须稳定。
- `cmd_fire = cmd_valid && cmd_ready`；每次 fire 只创建一个事务。
- MVP 的 `cmd_ready` 仅在复位结束且全局 `IDLE`、没有 sticky error 时为 1。
- sticky error 必须由显式 clear/error-reset MMIO 动作清除，不能因下一条命令静默消失。

### P2 descriptor 写

- descriptor 写只在全局 `IDLE` 接收，防止正在执行的命令观察到撕裂描述符。
- `desc_id < 40`；CR 只允许 word0，TR 只允许 word0..3，GR 只允许 word0..4。
- 与 command 同拍到达时 command 优先，`desc_ready=0`，避免两个 producer 同拍写同一状态。

### P3 GMEM master

- request valid 到 fire 前地址、write、wdata、wstrb 全部保持。
- 一次 fire 后必须等唯一 response；response 到达前不得发第二个 request。
- 已 fire 的请求不能因新命令、sync 或 error 被取消，只能 drain response 后转 COMPLETE/ERROR。
- response error 令当前命令失败；失败后不得继续发后续 Tensor beat。

### P4 completion 与 sync

- 普通命令完成只更新 engine counters/status，不写 `sync_tag`。
- `sync.i` 只有在其目标引擎的所有先前命令完成后才写 tag；MVP 串行实现中仍保留 `_engine` 合法性检查。
- `sync_tag_valid` 在软件读取/ack 前保持；tag payload 在 valid 期间稳定。

## 7. RTL 阶段 2b：状态机

### 7.1 顶层命令状态机

| 状态 | 含义 | 退出条件 |
| --- | --- | --- |
| `IDLE` | 可接 command 或 descriptor write | `cmd_fire -> DECODE` |
| `DECODE` | 分类 config/TIU/GDMA/sync 并检查固定编码 | config 成功 `-> COMPLETE`；TIU `-> TIU_RUN`；GDMA `-> DMA_RUN`；非法 `-> ERROR_DRAIN` |
| `TIU_RUN` | MM2 引擎拥有 LMEM 端口 | `tiu_done -> COMPLETE`；`tiu_error -> ERROR_DRAIN` |
| `DMA_RUN` | DMA 引擎拥有 LMEM 与 GMEM 端口 | `dma_done -> COMPLETE`；`dma_error -> ERROR_DRAIN` |
| `SYNC_WAIT` | 等待 `_engine` 指定的先前事务完成 | 条件满足、tag 写入 `-> COMPLETE` |
| `COMPLETE` | 形成单拍 completion/counter 更新 | 无条件 `-> IDLE` |
| `ERROR_DRAIN` | 若已有 GMEM outstanding，先等待 response；随后锁存错误 | drain 完成 `-> ERROR_HOLD` |
| `ERROR_HOLD` | sticky error，拒绝新命令 | explicit clear `-> IDLE` |

非法状态 fail-closed 转 `ERROR_HOLD`，错误码为 `INTERNAL_STATE`。

### 7.2 MM2 嵌套循环状态机

`MM2_SETUP -> MM2_READ -> MM2_MAC -> MM2_NEXT_K -> MM2_BIAS_RELU -> MM2_WRITE ->
MM2_NEXT_N -> MM2_NEXT_M -> MM2_DONE`。

- `m/n/k` 计数器从 0 开始，边界来自冻结 descriptor。
- `MM2_READ` 读取一个 x/w 元素；`MM2_MAC` 对符号属性完成扩展后更新至少 32-bit accumulator。
- k 完成后才加 bias/ReLU；输出按 out descriptor 的元素宽度和 stride 写回。
- `_rq=1`、transpose 变体、非 S8/U8 输入或非 S32/U32 输出在 MVP 返回 `UNSUPPORTED_VARIANT`，不得
  悄悄按其它语义执行。

### 7.3 DMA 状态机

`DMA_SETUP -> DMA_ISSUE_READ -> DMA_WAIT_READ -> DMA_WRITE_LMEM` 用于 load；
`DMA_SETUP -> DMA_READ_LMEM -> DMA_ISSUE_WRITE -> DMA_WAIT_WRITE` 用于 store。每个 beat 完成后更新
地址与 remaining bytes，直到 `DMA_DONE`。

## 8. RTL 阶段 2c：不变量

| ID | 触发条件 | 必须成立 | 违反后果 |
| --- | --- | --- | --- |
| I1 | `cmd_valid && !cmd_ready` | command payload 全字段稳定 | 重复/错配 Tensor 命令 |
| I2 | 任意周期 | `tiu_active + dma_active <= 1`（MVP） | LMEM 多 owner 冲突 |
| I3 | GMEM request 已 fire、response 未返回 | outstanding=1 且 request 计数不增加 | 丢 response/乱序 |
| I4 | descriptor 写 fire | 全局 IDLE 且 id/word 合法 | 执行中描述符撕裂 |
| I5 | LMEM write enable | 地址 < `LMEM_BYTES`，byte enable 非零 | 存储越界/静默破坏 |
| I6 | MM2 `MM2_MAC` | `m<m_max && n<n_max && k<k_max` | 读错 Tensor 元素 |
| I7 | `sync_tag_valid` | tag 保持到 ack，且对应先前目标命令已完成 | 假完成/丢 tag |
| I8 | sticky error | `cmd_ready=0 && desc_ready=0` | 错误后继续污染状态 |
| I9 | reset 后且无 fire | 不产生 GMEM/LMEM 写 | 无因写入 |
| I10 | unsupported command | 不产生 Tensor/GMEM 写，错误码确定 | 部分执行假绿 |

debug 构建把能编码的 I1..I10 转成 Verilog 时钟块立即断言；fast 默认构建通过预处理完全关闭断言。
定向 testbench 必须包含至少一个负向样本证明错误路径可达，不能只验证 PASS 路径。

## 9. RTL 阶段 2d：数据通路约束

- TCR 存储：40 × 320 bit 统一物理槽，CR/TR/GR 通过合法 word mask 区分；读取时只导出冻结副本。
- CSR：`padding/inserts/stencil/ctrl/dma_idx/sync_tag` 独立寄存器；MVP 只实现已用字段，其余保留位读零。
- LMEM：参数化 byte array，两个读端口（x/w）和一个写端口；DMA 与 TIU 由显式 owner mux 仲裁。
- MM2：两个 8-bit operand → signed/unsigned 扩展 → 16-bit product → 至少 40-bit internal accumulator →
  明确饱和/截断到 S32/U32。bias 和 ReLU 位于 k-loop 之后。
- DMA：64-bit GMEM beat 与 byte-addressed LMEM 之间通过 alignment/byte-lane mux 转换；首尾非对齐 beat
  用 WSTRB，不允许覆盖 Tensor 外字节。
- 多源写 TCR/CSR/LMEM 必须有显式 mux、enable 和优先级，不依赖多个 always block 的隐式 last-wins。

## 10. RTL 阶段 2e：电路拓扑

### 10.1 module 与端口

```text
TensorNpuCoprocessor
├── TensorNpuCommandDecoder      64/32-bit decode，纯组合
├── TensorNpuRegisterFile        40 TCR + CSR + descriptor snapshot
├── TensorNpuMm2Engine           m/n/k FSM + MAC + bias/ReLU
├── TensorNpuDmaEngine           单 outstanding GMEM master
├── TensorNpuLocalMemory         byte array，2R1W
└── TensorNpuMmioBridge          可选 AXI-Lite slave，连接 npc/rv64 legacy-MMIO
```

RTL DUT 模块使用 `.v`、Verilog-2001 `always @(*)/always @(posedge clk)`；testbench/DPI/sim top 使用
`.sv` 或 C++。一个 module 对应一个源文件；本约定用于 Verilator 可移植性，不声明或触发综合资格。

### 10.2 状态寄存器

- top：`state_q`、`cmd_q`、`cmd_rs_q`、`error_q/error_code_q`、completion/counters。
- register file：40 个 descriptor slot、CSR fields、`sync_tag_q/sync_tag_valid_q`。
- MM2：`state_q`、`m_q/n_q/k_q`、shape/stride/base snapshot、operand/data pipeline、accumulator。
- DMA：`state_q`、src/dst/remaining、outstanding、read-data holding register。
- LMEM：byte storage；只有显式 write enable 的时钟块更新。

### 10.3 主要组合块

- command fixed-bit/format decoder；
- descriptor legality 与 address generator；
- LMEM owner mux；
- MM2 signedness/product/next-accumulator；
- DMA alignment、WSTRB 与 next-address；
- status/error read mux。

### 10.4 pipeline 与 backpressure

- command 没有队列：`IDLE` fire 后 payload 打拍，直到 COMPLETE/ERROR 不再 ready。
- MM2 至少分为 descriptor/setup、operand read、MAC、writeback 边界。
- GMEM backpressure 只冻结 DMA FSM；不得回退已经 fire 的请求。

### 10.5 控制优先级

`reset > outstanding-response-drain > sticky-error > completion > engine-progress > new-command > descriptor-write`。

### 10.6 资源复制/共享

- 一个 MAC 资源由 MM2 独占；MVP 不在多个 Tensor op 间共享仲裁。
- LMEM 两读一写端口由 TIU/DMA/host-debug 显式 owner mux 共享；engine active 优先于 host-debug。
- GMEM master只归 DMA；TIU 不得旁路访问 GMEM。

### 10.7 预期关键路径

- MM2：LMEM read → signed/unsigned extend → 8×8 multiply → accumulator add；必要时在 multiply/add 间打拍。
- DMA：address low bits → byte-lane shift/WSTRB mux → GMEM request payload。
- command decode 不得与上述数值路径组合贯通。

### 10.8 function 边界

- 只允许小型纯组合 helper：descriptor word mask、dtype byte width、saturate、地址偏移。
- FSM、valid/ready、outstanding、仲裁、计数器和 flush/error 控制必须显式写在组合/时序块或子 module，
  不得封装进 function。

### 10.9 拓扑自审结论

- 命令、描述符和 LMEM 各有唯一写 owner；MVP 全局串行避免 TIU/GDMA 数据竞争。
- GMEM 已 fire 请求由 ERROR_DRAIN 负责收尾，符合“不可取消、只能 drain”的事务规则。
- host-only 入口不进入 NPU RTL wrapper；快速 oracle 路径不会被误计入 NPU offload 或 host-sim
  tokens/s。
- 当前最大功能缺口是完整 instruction coverage 与 Qwen 数据路径；因此本拓扑只授权首个 MVP，不能据此
  宣称整个长期目标完成。

## 11. Verilator 验证分层

### 11.1 debug

- assertions：开；
- waveform：仅失败复现时显式开；
- 优化：保留足够可观测性；
- 用例：编码/非法编码、descriptor 边界、DMA 正负向、MM2 小矩阵、sync 顺序、backpressure。

### 11.2 fast（默认）

- Verilator `-O3`，宿主 C++ `-O3 -DNDEBUG -march=native`；
- assertions：关；waveform：不编译；
- 固定 seed/thread/config；
- 内建 max cycles、no-progress timeout、max generated tokens、上下文上限和 EOF/interrupt 清理；
- 输出 wall time、generated tokens、tokens/s，并区分模型 prompt evaluation 与 generation。

## 12. Qwen3.5-0.8B 验收矩阵

模型与运行时核实完成后，测试资产固定在本目录：

| 层级 | 输入 | 目的 | 默认上限 |
| --- | --- | --- | --- |
| `cpu-oracle-smoke` | 1 个极短确定性 prompt | 只生成固定 token/logit golden；不得作为 NPU 验收 | 8 output tokens |
| `npu-model-smoke` | 同一固定 prompt/token IDs | 验 direct CPU→NPU 路径、模型状态和终止，主要 op 必须 offload | 8 output tokens |
| `npu-model-regression` | 预制中文、英文、算术、状态 reset | 避免直接 interactive 卡住，并核对 token golden/offload manifest | 每条 16 output tokens |
| `npu-op-smoke` | 固定小 Tensor | 证明 Verilated command/decoder/MM2/DMA 路径 | 固定 max cycles |
| `chat` | shell stdin | 用户最终直接对话；目标主要算子 NPU-required | 默认 64 output tokens，可显式覆盖 |

每个非交互用例固定模型 hash、prompt hash、seed、temperature、context、threads、command line 和返回码。
模型用例还必须固定预期 opclass/offload 数，验证 `npu_required_issued == npu_required_completed`、
`cpu_fallback_major_ops == 0`，并证明这些计数来自 Verilated NPU transaction，而非 host oracle。

`tokens/s` 分栏报告：CPU oracle reference、Verilator NPU host-sim prompt、Verilator NPU host-sim generation；
至少保留 `generated_tokens / generation_wall_seconds`、TTFT、cycles/token 和 NPU stall/bus wait cycles。当前
阶段没有综合/目标时钟证据，因此不报告或杜撰 projected hardware tokens/s。
