# RV64 hardware-professional 任务措辞

本文件是 RV64 RTL、微架构、验证和 PPA 子任务的自然语言入口。它只把任务事实放回 CPU 设计语境；
路径、读写集合、工程命令、上下文、反例出口和验证门槛仍由机器合同原样承载。

## 专业术语剖面

- 每份任务正文开头先给出正向本地边界：工作对象是本地 RV64 Verilog/SystemVerilog 处理器；输入、
  工程动作和产物落在合同授权的本地 RTL、spec、testbench、EDA 工具与生成证据范围内。
- 使用 RV64、RTL、双发射、OoO、流水级、reservation、ProducerId、ROB、IQ、MIQ、LSQ/SQ、
  DTLB、cache、AXI、READY/VALID、synthesis、STA、Power 和 PPA 等与实际设计一致的术语。
- 模块名、信号名、路径、命令和反引号内容保持原样；存在跨领域歧义时补充“CPU 微架构、事务、
  时序或验证”上下文，并在首次出现时给出对象、层级、作用域和工程目的。
- 协调状态、派发管线、措辞策略和父任务管理信息留在 JSON/dispatch log，不进入 RTL reviewer 的
  渲染文本；渲染文本只保留具体硬件事实、合同绑定与工程动作。
- 本地 RTL 子 agent 的初始上下文只使用经校验的合同渲染结果；设计事实由合同路径与随附材料提供，
  不继承父任务完整对话历史。该分层不改变模型、RTL 读取、实现、验证、EDA 或 PPA 能力。
- 结构化机器合同承载来源、路径、命令和协调字段；`goal`、`deliverables`、`success_criteria` 与
  `supplied_material` 只写处理器 module/signal/transaction、流水层级、周期条件和验证目的。
- 合同验证器检查结构和证据绑定，不按单个自然语言词组裁剪合法任务。`kill_valid_i`、PMP、
  privilege、access fault、memory protection、permission check 和 store probe 等真实架构术语照原义保留。
- 专业措辞不能扩大或收窄子任务合同中的源码集合、输出文件、工程命令或推理范围。
- Python/JSON 证据工具复核仍以具体 CPU 债务项、module/signal 或本地 RTL 证据路径作主语；随后写
  schema 字段、定向单测和返回码。不得让泛化的软件校验活动取代处理器工程对象。

以下是语义限定示例，不是关键词黑名单：

- `kill_valid_i` 表述为某流水级对年轻事务的取消信号；`flush_i` 表述为指定状态持有者的流水清空输入；
- checkpoint recovery 表述为 ROB/rename/LSQ 等具体持有者的恢复边界，replay 表述为 final-PA SQ 判定后的
  load retry 生命周期；
- fault injection 表述为 testbench 对指定 RTL 接口和周期施加的异常激励；compile-success RTL mutation
  表述为改动某一 source edge 并由指定 oracle 检出的验证变异；
- bypass 只有在真实数据旁路、控制旁路或被验证的错误连接语义中使用，并同时写明 module/signal/path；
  privilege 只按 RISC-V 特权级、PMP/PMA 或访问异常语义使用。

### IFU/AXI/PMP 字段级写法

用户可见进度、子 agent 技术字段和终审摘要使用下面的可重建硬件事实：

| 工程性质 | 推荐叙述 |
| --- | --- |
| instruction 属性选择 | `ARPROT[2]` 为 instruction 属性；当 `SLAVE_EXEC_MASK[decoded]==0` 时，`AxiCrossbar` 在 slave 观察 `ARVALID` 前选择 default slave |
| AR 通道反压 | 在 `ARVALID && !ARREADY` 周期内，由已锁存 transaction owner 保持 `ARADDR/ARSIZE/ARPROT` |
| instruction PMP | `PmpChecker` 对当前 instruction halfword 的相同 PA、2B access size 与 EXEC 权限进行判定 |
| DPI 访问边界 | `AxiDpiSlave` 将 AXI size 转换为 `nbytes`；PMEM 尾界 2B 读取边界 oracle 证明不读取相邻字节 |
| 负向 RTL 验证 | 编译成功的负向 RTL 变体改变一条指定 source edge，并由对应定向 testbench marker 或断言检出 |
| lane fault owner | lane0/lane1 instruction page/access fault 的 PC、cause、tval owner 经过 decoder、capture、pending 与 drain 保持一致 |

真实 module/signal/file/test/log/schema 标识符保持原样；若历史 testbench 名或 marker 使用较宽泛命名，
邻近正文补充上表中的字段级含义，不重命名证据。该写法不减少源码集合、工程命令、实现能力、负向
RTL 变体、断言或覆盖矩阵。

RTL 技术目标完整写明实际工程意图、对象、层级、周期条件和证据边界。措辞规范只提高领域准确性和
可审计性，不改变任务意图或技术门槛。

## 长期 goal 引用

长期 goal 只需引用一次本剖面：

> 主 agent、子 agent 与技术记录统一采用 `rv64-hardware-professional`：以本地 RV64
> module/signal/transaction 为主语，写明流水级、周期或配置、RTL/spec/TB/EDA 动作、证据路径与
> PASS/GAP 边界；协调元数据留在 task-run JSON。真实 RTL 标识符原样保留；源码探索、工程命令、
> 负向 RTL 变体、断言、覆盖、独立复核与 PPA 分析能力保持完整。

长期 goal 不再展开词语或场景清单；具体硬件术语在对应 module、signal、transaction 的技术正文中自然出现。

## 最终回复证据顺序

- 第一行使用
  `RV64 RTL 结论｜对象=<module/signal/本地证据路径>｜周期/配置=<cycle/config>｜TB/EDA 观测=<结果>｜范围=<PASS/GAP/inconclusive>`。
- 本地 JSON 证据校验出现意外接受或拒绝时，写明 CPU 证据对象、具体 schema 字段、工作区相对路径、
  定向单测和返回码，不只给脱离处理器工程对象的泛化标签。
- 该顺序不删除反例、未知项、替代假设、原始日志 marker、真实文件名、失败返回值或
  `scope_extension_request`，也不改变源码、命令、EDA 或推理能力。

## 子任务正文结构

渲染文本只需要以下硬件事实：

1. 工程域：本地 RV64 CPU Verilog/SystemVerilog 微架构、验证或 PPA；
2. 目标：要冻结或验证的协议、状态机、数据通路、时序路径或 PPA 假设；
3. 合同路径/SHA 与 RTL 输入集合；
4. 工程动作：允许执行的 compile、simulation、lint、synthesis、STA 或只读源码检索；
5. 交付：反例、波形/日志观测、RTL diff、mutation 结果、指标和证据边界；
6. 结论出口：`PASS`、`GAP`、`inconclusive`、替代假设及 `scope_extension_request`。

技术提示保持紧凑，同时完整保留调用链、必要命令、未知项、替代假设和反例复核能力。

## 架构门表达模板

每个 DI/OOO gate 都用“source topology + dynamic observation + compile-success mutation + same-design
provenance”表达。DI-5 结论给出 trace 周期、issue IPC、两 bank 的 AGU/translation/physical SQ
query/cache admission/completion、完整 ProducerId、READY mask、partial consume、ROB wrap 与反馈 SCC。
OOO-3 结论给出 LQ/SQ lifecycle、final-PA disposition、checkpoint tombstone drain、ROB retire authority、
store request/B/retirement 次序和精确异常。

DI-5 GREEN 不能外推为 DI-1/DI-2 memory ordering、OOO-3/OOO-4 recovery、shared raw AXI 持续 miss
吞吐、整体架构 GREEN 或 PPA 合格。只有 architecture hard gates 全部闭合且同一 design/provenance 的
synthesis、STA 与 Power 证据可比时，才能讨论正式 PPA promotion。

## 子 agent 派发

本地 RTL 子 agent 使用 `.github/skills/prepare-rtl-task-contract/` 的 create→validate→render 管线。
创建子 agent 时使用 `fork_turns="none"`，渲染结果即完整初始提示；必要设计上下文必须由合同列明。
需要追踪调用链时使用限定路径的 `workspace-files`；冻结材料的第二遍逻辑复核才使用 no-tools 模式。
审查者可以报告任意数量的反例、覆盖洞、`inconclusive` 或 `scope_extension_request`；实现、验证和 PPA
任务按节点需要保留对应工程能力，不因措辞模板统一降级为只读复核。
