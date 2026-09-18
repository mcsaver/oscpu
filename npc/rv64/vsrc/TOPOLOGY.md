# 承岳64全核拓扑与本轮优化入口

范围为实际 R64CoreTop 与包含 Fabric/设备的 R64SystemTop。以 BUS 第四批为基线；面积只记录，优先比较正确性、时序和 CPI。不能把文件列表等同于实际实例：通用参考 helper 和可选 Tensor 数据通路需与生产 elaboration 区分。

```mermaid
flowchart TB
  F["Frontend：Fetch/Align/Predict/4条指令FIFO"] --> DE["DecodeStage：4条"]
  DE --> B["原子 birth：ROB + Rename + IQ + LSQ"]
  B --> IQ["IQ：ready/age/resource top2"]
  IQ --> RR["RegRead：2个ingress / 每lane2个terminal；4GPR+3FPR"]
  RR --> EX["Execute：ALU x2 / MUL / DIV / CLMUL"]
  RR --> FP["FP dispatch：FMA / FAST / LONG"]
  RR --> LS["LSU：20项owner / 翻译 / 转发 / 完成"]
  RR --> SE["Serial：CSR/FENCE/系统指令"]
  EX --> WB["Writeback：9源选2 / owner certificate"]
  FP --> WB
  LS --> WB
  SE --> WB
  WB --> ROB["ROB32：generation/完成/异常/回滚"]
  ROB --> CM["Commit：双退休前缀 / 精确副作用"]
  CM --> AR["架构 Rename / CSR"]
  AR --> B
  WB --> IQ
  WB --> RR
  EX -. "ALU early wake / data bypass" .-> IQ
  EX -. "ALU data bypass" .-> RR
  EX -. "branch preview / resolve" .-> ROB
  ROB -. "kill / undo / reuse barrier" .-> IQ
  ROB -. "kill / owner drain" .-> LS
  ROB -. "redirect" .-> F
  CM -. "trap / xRET / fence / CSR context" .-> F
  F --> IT["I translation / ICache"]
  LS --> DT["D translation x2 / Protection x2"]
  DT --> MS["Split / MemoryService / DCache"]
  IT --> PP["I PTW / PtePort"]
  DT --> PP
  PP --> MS
  IT --> AX["AXI read adapter"]
  MS --> AX
  MS --> AW["AXI write adapter"]
  AX --> FA["Fabric：4read/2write owner；memory+MMIO read groups"]
  AW --> FA
  FA --> DEV["PSRAM/SDRAM/外部MMIO；CLINT/PLIC/UART/RTC/syscon"]
  DEV -. "time / IRQ / control event" .-> AR
```

请求、返回、信用与取消是四张相互约束的网络。图中实线为主要请求/结果，虚线为提前唤醒、恢复、上下文与事件。ROB tag、LSQ slot/token、Fabric事务槽和 AXI ID 属于不同命名空间；只在明确接收边沿建立对应关系。

| 模块域 | 详细拓扑 | 本轮处理与判据 |
|---|---|---|
| 前端 | [Frontend](frontend/TOPOLOGY.md) | 空槽准备、部分消费指针、RAS并行转发；先要求相同 CPI/恢复计数。 |
| 后端 | [Backend](backend/TOPOLOGY.md) | 双空项前缀、IQ空行数据准备、静态年龄矩阵；IQ32 单独试验。 |
| 整数/浮点执行 | [Arithmetic/FP](fp/TOPOLOGY.md) | 保持拍数的公共 carry finish；FP四源选择与数据捕获。 |
| 提交控制 | [Control](control/TOPOLOGY.md) | 保留精确事件边界和现有 CSR 快路径；基准未显示扩大串行快路径的收益依据。 |
| 翻译/保护/缓存 | [Memory](memory/TOPOLOGY.md) | TLB空项、PTE空闲数据、ICache查询准备；最终按STA优化DCache物理写口。 |
| LSU | [LSU](lsu/TOPOLOGY.md) | 保留 pin/排空契约；STA反馈轮将宽转发数据提前至驻留query阶段准备，并移除物理发出时的重复 MEMORY 状态写入。 |
| BUS/平台 | [BUS](bus/TOPOLOGY.md) | 保留四批结构；与Core一同综合，确认全核路径而非只测孤立Fabric。 |

基线事实：CoreMark 9,573,233 cycles / 3,218,524 retired，CPI 2.974417155；Dhrystone 15,259,347 / 4,260,670，CPI 3.581443059。26项观察计数有重叠，不能直接求和为总停顿。

完整 SystemTop 基线在1ns/0.05ns uncertainty、icsprout55 TT1.2V25C下，setup=-2.803282499ns，hold=-0.036660694ns，真实状态为 FAIL。最差链已定位至 DCache bank 写数据；不是所有模块频率都由这一个数代表。后续所有结论以同源测量为准，不能把数据路径优化直接换算为已实现的硅后Fmax。

对应结果：[全拓扑迭代目录](../../../tmp/rv64-whole-topology-20260908/PLAN.md)。每阶段保存源码差异、配置、功能/CPI结果、STA路径与RTL对应，再清除综合网表及可再生构建产物。

## 分配、执行与完成信用的完整连接

下图是主数据流之外的资源网络。箭头表示资格或可用空间的传递，不代表组合穿透，也不能把队列深度相加作为独立指令容量。

```mermaid
flowchart LR
  RF["ROB空槽 + 旧owner复用保护"] --> B["按程序顺序形成birth前缀"]
  PF["GPR/FPR free位图<br/>仅实际目的写需要"] --> B
  IF["IQ空行Q态信用"] --> B
  LF["LSQ free Q态信用<br/>仅MEM需要"] --> B
  B --> OWN["同一边沿建立ROB / Rename / IQ / LSQ绑定"]
  OWN --> IQ["IQ：已唤醒候选 / 年龄 / 资源配对"]
  RP["RR ingress/terminal信用<br/>4GPR + 3FPR读口预算"] --> IQ
  IQ --> RR["RR保持完整owner与读取计划"]
  FU["各FU预约/terminal信用"] --> RR
  RR --> EXEC["实际FU或LSU bind接受"]
  EXEC --> T["局部terminal：ALU/MDU/FP/LSU/Serial"]
  WC["WB寄存grant与结果槽"] --> T
  T --> WB["WB捕获 / ROB owner认证"]
  WB --> IQ
  RET --> RF
  RET["双退休前缀 / 旧preg回收 / LSQ commit"] --> PF
  RET -->|"store commit / pin条件"| LREL["LSU：load完成捕获 / dead排空 / 无引用store释放"]
  LREL --> LF
  WB --> RET
```

birth受阻的IQ、ROB、PRF、LSQ观察计数可能同时为真；它们不能相加成为总停顿。IQ变大可能只让指令更早进入ROB，从而把信用压力移到ROB。完成也有两层选择：FP/LSU先在本地形成结果，再参与全核9选2。局部结果已算完，不等于已唤醒消费者或可退休。

## 恢复和不可取消事务的连接

```mermaid
flowchart LR
  BR["分支preview / resolve"] --> RP["ROB恢复计划 / 年轻后缀"]
  RP --> K["kill / prepared cancel"]
  RP --> UN["每拍最多2项逆序undo"] --> RN["Rename恢复"]
  CM["Commit已寄存trap / xRET / serial事件"] --> FL["full flush / redirect"]
  FL --> RN
  K --> LOCAL["IQ / RR / FU / WB的可取消owner"]
  FL --> LOCAL
  K --> LS["LSU：取消未发请求；已接受请求登记dead"]
  FL --> LS
  LS --> DR["翻译与物理响应继续drain"]
  DR --> RE["逐份引用释放 / reuse_block"] --> RA["ROB槽复用资格 / 分配"]
  BR --> FE["Frontend训练 / redirect"]
  FL --> FE
  FE --> FD["旧取指事务按owner排空"]
  AX["已接受AR / AW / W<br/>BUS没有ROB kill输入"] --> DR
```

ROB tag、LSQ slot、Service source/token、AXI ID与Fabric事务槽属于不同标识空间。取消指令可以撤销其结果发布资格，但不能把已经接受的外部事务当作未发生，也不能在旧引用释放前复用其身份。

整合版DCache的pending write属于已接受的缓存更新，不是新发出的一条CPU指令或新的外部store。满足驻留命中且未poison/invalidate条件的成功B，以及可分配refill的真实R，产生缓存逻辑写事件；待写状态按byte向lookup转发，下一拍落阵列。它不受ROB分支kill撤销；invalidate清除tag valid，迟到的阵列写不能重新安装valid。LSU源store在无引用后释放时，后续物理查询仍能观察到一致的缓存数据。

整机综合反馈按 DCache 高扇出写数据 → LSU query_take 控制宽转发快照 / 冗余状态更新推进。各轮测量保留在结果目录；对外请求发布、pin释放、已发owner及完成资格维持原拍数，详细边界见 LSU 图。

## 最终 STA 暴露的跨模块路径

DCache和LSU宽数据优化后，完整SystemTop最差setup=-2.261837959ns，端点为LSU forward_mask_q[19][6]。这条路径实际经过query取消资格、MemorySplit和MemoryService，再返回LSU。它是有效性与接收信用的组合往返，图中的末端寄存器承接路径，不代表组合环。

```mermaid
flowchart LR
  C["reset / Commit flush / ROB cancel"] --> Q["query tag选择取消资格"]
  Q --> V["query valid → LSU mem_valid"]
  V --> SP["MemorySplit：对齐与双lane路由"]
  SP --> SV["MemoryService：CPU/aux配对"]
  SV --> R["cpu_ready → mem_ready → query_take"]
  R --> M["Q：forward_mask发布"]
```

这说明后续应把mask/descriptor的准备与可见性、以及Split/Service的寄存信用作为独立实验。不能为缩短路径撤销真实取消检查，或让尚未接收的请求提前成为已发owner。本轮完整结果、IQ16/32取舍及后续验证问题见[最终评估](../../../tmp/rv64-whole-topology-20260908/REPORT.md)。
