---
description: "RTL 生成强制工作流。任何 agent 在生成或修改 Verilog/SystemVerilog RTL 之前，必须先完成 需求 → 协议规则 + 状态机 + 不变量 + 数据通路约束 → RTL 的四段式推导，并把推导过程留痕，禁止直接写 RTL。"
applyTo: "**/*.{v,sv,vh,svh}"
---

# RTL 生成强制工作流

任何 agent 在生成或修改 RTL（含新模块、改接口、改时序、改状态机、改控制信号、改数据通路）前，**必须** 按以下四段顺序推进，且每段都要在回复或落盘记录中显式给出，不允许跳过任何一段直接写代码。

只读类问题（仅解释代码、回答原理、做 RECALL）不强制走完整流程，但若结论会被用于后续 RTL 改动，则改动那一步必须补齐。

## 阶段 1 — 需求

把任务转写为可验证的需求清单：
- 功能目标：模块要做什么、对外提供什么行为
- 输入与输出端口（含位宽、方向、时钟域、复位策略）
- 性能/时序约束：单周期/多周期/流水线、吞吐、关键路径预期
- 与上下游模块的边界：谁产生、谁消费、是否有 backpressure
- 不在范围内的事项（显式列出 out-of-scope）

## 阶段 2a — 协议规则

枚举本模块涉及的握手、总线、内部接口协议：
- 握手类型（valid/ready、req/ack、固定时序、组合返回）
- 信号在哪一拍稳定、谁先抬、谁先撤
- 一次事务的最小/最大周期数，是否允许背靠背
- 错误/异常路径如何上报，是否会丢弃或重试
- 与已有模块、规范（如 RV32I、AXI-Lite、SRAM-like）的对齐点

## 阶段 2b — 状态机

为每条受控时序行为给出状态机描述：
- 状态枚举与语义；初始状态与复位行为
- 状态转换条件（组合输入 + 当前状态）
- 每个状态下的输出行为（Moore/Mealy 标明）
- 非法状态/未覆盖输入的处理策略
- 用文字 + 转移表或简图表达，必要时用 Mermaid

## 阶段 2c — 不变量

显式列出模块在任意周期都必须成立的性质，作为后续断言/审查依据：
- 互斥不变量（如同一周期内最多一个 write enable 有效）
- 守恒不变量（如计数器范围、FIFO 占用范围）
- 协议不变量（如 valid 撤销前不能改变 payload）
- 复位后状态不变量
- 与外部规范一致性不变量（如寄存器写入规则、CSR WPRI/WLRL/WARL）
- 每条不变量需指明：触发条件、表达式、违反时的后果

## 阶段 2d — 数据通路约束

在写 RTL 前先固定数据通路骨架：
- 关键寄存器、组合网络、选择器拓扑
- 位宽、符号扩展、对齐规则、字节使能策略
- 多源驱动如何仲裁（mux 选择信号来源）
- 关键路径预算（哪段必须组合直达，哪段必须打拍）
- 与存储/外设/CSR 的接口时序点

## 阶段 2e — RTL 级电路拓扑（写代码前的强制产物，先画后审）

**在写任何一行 RTL 之前，必须先输出 RTL 级电路拓扑，不要直接写代码。** 拓扑生成后，
必须先自审拓扑是否正确（端口/状态/复位优先级/共享资源是否自洽），审阅通过后才把拓扑翻译成 RTL。

拓扑必须显式包含以下 9 项：
1. **module 边界与接口协议**：每个端口的方向/位宽/时钟域/复位；握手协议（valid/ready、req/ack、组合返回）。
2. **所有状态寄存器**：逐个列出（名字、位宽、复位值、由哪个时序块 `always @(posedge clk)` 更新、更新使能条件）。
3. **所有主要组合逻辑块**：每个组合块 `always @(*)` / `assign` 网络的职责与输入→输出。
4. **FSM 状态与状态转移**：状态枚举、初始/复位状态、转移条件、每态输出（Moore/Mealy）。
5. **pipeline stage 与 valid/ready 流向**：每级寄存器边界、valid/ready 如何在级间传播、背压点。
6. **flush/stall/kill/reset 优先级**：当多个控制信号同周期出现时的明确优先级顺序（如 reset > flush > stall > 正常推进）。
7. **资源复制或共享**：哪些资源（加法器/乘法器/端口/存储）复制、哪些共享；共享资源**必须显式给出 mux + enable + 控制逻辑来源**。
8. **可能的 critical path**：指出预计最长组合路径大致经过哪些块（如 mul → align → wide-add → LZC → normalize → round）。
9. **function vs 显式硬件的划分**：明确哪些逻辑允许用 function（仅小型纯组合 helper），哪些**必须**显式写成时序块 `always @(posedge clk)` / 组合块 `always @(*)` / 子 module。

> 单个纯组合算术 gate（无状态/无 FSM/无握手，如 FMA/ALU 子运算）允许用精简拓扑：寄存器=无、
> FSM=无、pipeline=无，但仍必须显式给出第 1/3/7/8/9 项（接口、组合块、共享 mux、critical path、function 划分）。

## 硬件结构编码规范（按真实硬件结构写，不按软件函数组织）

落 RTL 时必须遵守，违反即返工：

- **显式区分时序与组合块**：时序状态更新只在时序块；组合逻辑只在组合块。不要用 `assign` 串接掩盖时序/组合边界。
- **可综合 .v 用 Verilog-2001 always 关键字，不用 SV 的 always_comb/always_ff（关键工具链约束）**：
  本仓库"模块 testbench" gate 用 **Icarus iverilog 12.0**，实测其对 **`always_comb` 关键字** 内的变量常量位选会发
  `sorry: constant selects in always_* processes ... all bits will be included`（**静默错仿真** + 全核 build 失败 Error 10）；
  而 **`always @(*)`（组合）与 `always @(posedge clk)`（时序）** 对同样的常量位选完全正确。
  Verilator / Vivado(`read_verilog -sv`) 两者都支持。因此：
  - 时序：写 `always @(posedge clk)` / `always @(posedge clk or negedge rst_n)`，**不写 `always_ff`**。
  - 组合：写 `always @(*)`，**不写 `always_comb`**。
  - `always_ff`/`always_comb`/`logic` 等 SV 关键字**只允许出现在 `.sv` 验证代码**（testbench/DPI/仿真顶层）。
  - 这条不削弱"显式区分时序/组合"的要求——`always @(posedge)` 与 `always @(*)` 同样显式;只是关键字按 iverilog 兼容性选择。
- **组合块无锁存**：`always @(*)` 内所有被赋值的变量必须在块顶给默认值，或在所有路径都赋值，避免推断锁存器（命名块内可声明局部变量）。
- **function 只能用于小型纯组合 helper**（如 lzc 前导零、barrel shift-right-jam、round-increment、saturate、predicate 这类可复用纯组合数据通路原语）。纯组合算术 datapath 优先用 `always @(*)` 显式块描述，而非塞进大 function。
- **禁止把以下逻辑封装进 function**：状态更新、仲裁（arbiter）、valid/ready 握手、flush/kill、issue/select、ROB/LSQ 更新、divider/任何 FSM。这些必须显式写成 `always @(posedge clk)`/`always @(*)`/子 module，使寄存器、控制流、共享资源在结构上可见。
- **每个 for-loop 必须注明综合后对应什么硬件**（如：展开成 N 路并行比较器 / 优先编码器 / barrel shifter mux 树 / 复制 N 份运算单元）。
- **每个共享资源必须显式给出 mux、enable 和控制逻辑**，不允许靠工具自动推断共享。
- **注明关键路径大概位置**，便于后续时序优化定位。

## RTL 文件分工（.v 描述硬件，.sv 仅用于验证）

- **真实可综合硬件一律写在 `.v` 文件**，用 Verilog-2001 风格（`always @(posedge clk)` / `always @(*)` / `wire`+`reg` / `function`+`assign`）。
  Vivado 用 `read_verilog -sv` 读 `.v`、Verilator 默认按 SV 解析 `.v`，但**为兼容 iverilog 模块 TB gate，可综合 .v 不使用 `always_comb`/`always_ff` 关键字**（见上节）。
- **`.sv` 文件仅用于验证**：testbench、DPI、仿真顶层（如 `vsrc/sim/*.sv`）、断言环境。`.sv` 里可自由用 `always_ff`/`always_comb`/`logic`。不要用 `.sv` 描述会进入综合网表的真实硬件。
- 新增可综合模块时加入综合文件清单（`vsrc/filelist.mk`），不要把含 DPI-C 的仿真 `.sv` 混进综合网表。
- **本地验证回环**：可综合 RTL 改动后必须同时过 ① Verilator(`make lint` + sim)② **Icarus iverilog 模块 TB**（`testbench/`，对 `always_comb` 常量位选会静默错/失败，是最易被忽视的 gate）③ 适用时 Vivado OOC。三者工具链对 SV 子集支持不同，只过其一不够。

## 阶段 3 — RTL

只有当上述推导（含阶段 2e 拓扑且已自审）都已显式给出后，才开始落 RTL：
- 实现顺序遵循“数据通路骨架 → 状态机/控制 → 协议接口 → 不变量对应的断言或注释”
- 每个关键 always/assign 必须能映射回阶段 2 中的某一条规则、状态或不变量
- 复杂分支需在代码注释中标注对应的状态/不变量编号
- 落盘后回写一段简短自检：列出每条不变量是如何被实现保证的（结构性保证 / 断言 / testbench 覆盖）

## 留痕要求

- 在对话或落盘 RTL 的同一回复中，按 阶段 1 / 2a / 2b / 2c / 2d / 3 的顺序给出推导
- 涉及落盘的 RTL 改动，应在 `.github/task-runs/<日期-任务名>/task-report.md` 中追加“RTL 推导摘要”一节，至少保留：需求要点、关键不变量、状态机骨架、数据通路骨架；不要只记录最终代码
- 模块级的稳定结论（接口协议、不变量、状态机）应回写到 `.github/memory/modules/npc.md` 或对应模块笔记，避免下次重复推导

## 禁止行为

- 禁止跳过阶段 1–2 直接给出 RTL 代码块
- 禁止用“与现有风格保持一致”替代显式协议/状态机/不变量说明
- 禁止仅凭波形或测试通过就认定不变量成立；不变量必须有结构性论证或断言
- 禁止把 bug 修复直接缝在出错的 always 块里而不回到阶段 2 重新审视协议/状态机/不变量
