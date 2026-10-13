# 数据保护结果的寄存边界：2026-10-12 实施与实验结果

状态：**已采纳 A：R3 已按两份已测 candidate 文件的相同内容集成为默认 RTL，测试／拓扑补丁同步合入，正式模块入口 4/4 PASS。R4 相同 ICG buffer 实验也已完成。相对 R1／R2，setup 改善 0.294662953 ns、面积减少 3328.08 µm²；CoreMark 周期增加 5.1583%，Dhrystone 增加 1.76485%。当前是继续收敛 500 MHz 的实验默认：setup／hold 仍 FAIL，不声称目标达标或实际程序加速。** 工作区为 `/home/lyg/PA/ysyx-workbench`，分支 `ai`。目标继续为 55 nm ECOS、TT 1.2 V／25°C、500 MHz／2 ns 实验；ISA、双发射 OoO、精确 fault、访存顺序、恢复与进度合同保持。

前一轮宏化实验的 setup 回退与面积收益仍以 [ECOS DCache 结果](ecos-memory-adaptation-20261012.md) 为准。作为基线的 Q-only B credit／head 恒冻结改动完整 benchmark 的 counter/CPI 与宏化基线完全一致；现已取得 source 不变的 TT／2 ns STA，setup 改善且面积略降，因此保留该改动，数值见 §4.1。工具域的 ICG 负载修复另行负责，不改变本候选的架构合同；比较两套新 STA 时须保持其物理处理口径一致。**已有结果对应冻结输入；工作区采用哪一默认实现与正式 PPA 资格是两件事。本轮已选择并集成 R3 作为后续实验默认实现，R1＋R2 的无 CPI 回退结果保留作对照，不以尚未完成 PPA 资格化阻止正常合入。**

## 1. 决策所需的已核实事实

独立取证确认了以下实际边界；Architect 仅读摘要，未打开 RTL、TB、网表或原始日志：

- Bare 数据 fast path 只绕过 lookup Q，仍在真实接受边沿捕获 outcome Q，不是请求直通保护。outcome 保存 PA／last 等信息；PMA class/fault 从这些 Q 组合产生，不能把它额外算作独立 PMA 寄存级。
- DataProtection 每 lane 已有一项 holder，保存 PA、class、cause、protection、base_fault、needs_ad、PMP enabled/no-match-fault，以及 16-bit overlap/deny。最低重叠项优先选择和最终 fault 位于这些事实 Q 后。
- 本次实验起点的生产实例只显式选择 PMA_PREPARED=1，EMPTY_FLOW 默认开启。空时可以直接交付保护结果，受阻时捕获上述完整事实。关闭 EMPTY_FLOW 会强制使用已有 holder Q，不必新建 payload。
- 已有输入 ready 为“holder 空，或旧响应本拍可消费”，允许同沿出旧进新。因此关闭 EMPTY_FLOW 后，**每 lane 稳态 II=1，两个 lane 独立**；不是把单项容量改为隔拍接受。当前 LSU 对翻译响应的 ready 恒为非 reset，服务还用有效 token 账本限定响应资格。
- DataTranslationService 每 lane 四项已接受 token/protection，最终受保护响应真实 fire 才 pop 账本。新增一拍只延长已有租约，不增加 owner 数量；单独看到保护 II=1，仍不能推导端到端信用永不阻塞。
- 原 holder 在空槽或旧响应可消费时同步预写 payload/facts，即使 req_valid=0 也可预写。预写不建立 owner。全部公开结果字段均已有 Q 或由 Q 后 finish 推导；Service 只在 protected_valid 且账本非空时发布，LSU 只在 terminal fire 后使用 token/结果建立后续资格。独立实现角色未发现 invalid raw 被预写后、不重新采样就能发布 owner 的依赖。
- PMP 对有效 owner 的取样定义是 DataProtection 的真实接受边沿；空槽预写不是另一种权限授权。SATP、有效权限、PBMT、access 在更早的 translation request 接受时保存；不能把两者混成同一上下文快照。

可读架构合同见 [公共协议 §5](../../vsrc/PROTOCOLS.md)、[Memory 拓扑](../../vsrc/memory/TOPOLOGY.md) 和 [LSU 拓扑](../../vsrc/lsu/TOPOLOGY.md)。独立纯事实摘要见 [PMP 边界事实](../../../../build/ecos-opt-20261012/pmp-boundary-facts.json)。实现指针仅供追溯：DataProtection:63–124，DataTranslation:110–180、267–325，DataTranslationService:103–163，Lsu:425–438。本文不沿这些指针读取实现。

## 2. 已集成的最小切分：强制经过已有 Protection holder

**实现已按完整的 Protection 寄存输出边界集成，映射边界及全局时序效果已测，见 §4.2。** 改动包含两个紧密关联的部分：数据 DataProtection 实例显式选择 EMPTY_FLOW=0；该模式下所有公开 PA/class/cause/fault/protection/needs_ad 等结果及 finish 所用事实恒取现有 holder Q，即使 valid=0 也不选择 raw。EMPTY_FLOW=1 的原通用行为保持，不扩展全核参数矩阵。该改变不用于取指保护，也不改变 PMP 配置／地址的架构状态或共享 decode 发布方式。

保留原有 PA/class/cause/protection、base fault、needs_ad、overlap/deny 等全部事实捕获与最终优先级判定。**输入事实捕获和空槽／消费槽的同步预写条件完全保持，不另加“仅真实 req_fire 才写 Q”的门控。** invalid 输出可随时钟沿的 Q 预写更新，但在边沿之间不跟随 raw／当前 PMP 组合变化；这里“始终取 Q”不表示无 owner 时永久冻结旧数据。原 holder 数据布局、valid 更新、旧结果优先、同沿替换、error 和 owner 路由保持；不新增影子权限状态、第二队列或额外容量。Bare outcome 快路径、LSU 的 translation-query bypass、Service read 空槽直通保持本轮原状态，避免一次改多个边界而无法归因。

| 边沿／场景 | 原空槽直通 | 候选 |
| --- | --- | --- |
| e0 前已有有效 outcome，保护 holder 空 | 允许 e0 接受并将完整保护结果交付 LSU | e0 接受并把完整保护事实写入现有 holder |
| e1 | 后续 owner 按原路径前进 | 最早消费 e0 的已登记结果；可同沿接收下一个 owner 的事实 |
| 连续无阻挡流 | 每 lane 最多一项／拍 | 每 lane 最多一项／拍，结果流整体晚一拍 |
| 输出受阻 | 原规则保存完整事实 | 继续保存原 owner 全部事实；不得用新请求或新 PMP 状态重算已持有结果 |
| invalid holder | 原模式可选 raw 输出并同步预写 | 对外仅取 Q；原同步预写继续，不建立 owner，也不引入组合 raw 输出 |
| 两 lane／fault／取消 | 各自顺序与终端规则 | 全部保持，不把某类结果绕回未登记路径 |

这把“PMP decode＋范围比较／overlap/deny”与“最低匹配选择／fault＋LSU 后续资格及请求选择”放到已有 Q 的两侧；最终 fault 仍可在 Q 后组合生成，**不是另加一层最终 fault 寄存器**。独立取证确认原实现的 invalid 输出仍可能选 raw，因此仅关 valid 直通并不满足本候选：恒取 Q 的输出选择是注册模式的必要收敛。同步空槽预写以 Q 为终点，仍构成真实寄存边界；其数据不因无 owner 就需要 false path。实际映射必须核实该边界以及其它剩余路径，既有分段不能直接推导改后 WNS 或保证 2 ns。

唯一备选是关闭 LSU 的 TRANSLATION_QUERY_BYPASS：成功且无顺序依赖的普通整数 load 经既有每 lane 两槽 forward_query Q，最短路径增加一拍，局部仍可 II=1。但 PMP→LSU query/state 选择仍在同拍，不能截断保护前缀本身，因此不作为本候选的首刀。仅关闭 Service.CPU_READ_EMPTY_FLOW 切的是更晚 cache 尾段，也不应因存在参数而先行实施。

## 3. Owner、精确错误、PMP 修改与恢复合同

**租约与配对。** invalid Q 预写不分配 owner，真实请求接受才发布 valid；DataProtection 捕获有效事实也不代表翻译服务已完成。token/protection 账本仅在最终 protected response fire 后推进；LSU 的 tr_issued、canonical row 与完整 ROB tag 保留至该终端消费。旧结果出／新事实入同沿，对外使用沿前旧 Q＋旧账本 head；沿后使用新 Q＋已推进的 head。因此必须将旧 token 对应旧 Q、新 token 对应新捕获事实，不能提前 pop、重复响应、跳过 fault 或用下一 owner 的属性完成上一 owner。

**precise fault。** 原 page fault、PMA/PMP access fault、范围溢出、部分覆盖拒绝、最低 PMP 重叠优先级及 fault/cause/tval 选择均保持。fault 返回可以晚一拍，不能在等待保护判定时试发物理访问，也不能让 fault owner 取得 store/A-D 副作用许可。普通 store 的提前翻译与真实 head/A-D 授权继续分开，原子、IO、非对齐及 split 错误合同不变。

**PMP/CSR。** PMP 写只在合法 Serial 与 ROB 退休 owner 匹配的边沿更新，CSR 写并不普遍等待 memory drain。已核实 serial_active Q 仍阻止年轻操作 issue，CSR commit 边沿登记的非 scratch restart 在下一周期使 full flush 生效；不能把“年轻 owner 此拍不能 issue”写成“它们此拍已经被 restart 取消”。旧取消翻译租约可以仍在排空。PMP 仍在真实 DataProtection 接受沿取样，沿前已有 PMP Q 决定当次事实，已持有事实不随之后的 CSR 改动重新解释。候选不增加全局 PMP 派生寄存状态，因此不引入新 CSR 与旧 decode 分拍发布的问题，也不擅自给 PMP 写增加 drain 等待。

上述串行事实支持保留原顺序合同。新增真实 LSU＋Service 定向已覆盖 held 期间 PMP allow→deny、随后 kill 与完整 tag 复用，验证旧事实保持和取消排空；原有检查包含 CSR lock/WARL。**这些通过不等于覆盖所有 CSR commit／残余 token／恢复并发组合**；尚不能对未执行的完整可达集合下结论。独立来源指针：Issue:243–245、491–493；Rob:218–219、306–308；Serial:107、134；Commit:99–100、168–176；可读定义见 [Control 拓扑](../../vsrc/control/TOPOLOGY.md)。

**恢复与进度。** 数据翻译服务没有 ROB kill/flush 删除租约接口。cancel 后仍返回并排空，LSU 依据原存活／完整 tag 规则抑制架构结果，不能因增加一拍就提前复用 slot/tag。SFENCE 的 poison/TLB 失效和既有 PTE 事务排空规则保持；新增等待不能重新授权旧 walk、丢弃已接受物理事务或复活年轻结果。reset 保持已有 valid 清除合同。旧 holder 在背压中不可被覆盖，消费旧项时的同沿替换不得变成“必须先空一拍”。

## 4. 已验证事实与完整 CPI 代价

以下采用独立实现/验证角色及主 agent 回传的 round3 已测 overlay 结果；主 agent 随后将相同两文件及对应测试／拓扑补丁集成，并通过正式模块入口 4/4 检查。这些执行结果不扩大为完整系统签核：

- 28 项定向正向与 strict Service lint 通过；新增覆盖包括 48 个 token、8 个取消排空、46 次同沿旧结果消费／新事实捕获、32 请求的 II=1，以及 8 次 invalid Q 拍内隔离扰动。
- 原源码在相同 invalid-raw 检查下触发负向，候选通过；证明该检查能识别本次修复的无效输出组合穿透。
- 真实 LSU＋Service 覆盖 held 期间 PMP allow→deny、随后 kill 和 full-tag 复用。已执行定向不能代替所有 CSR 并发状态的验证。
- 10 个全核 DiffTest 短程序、7 个热窗口通过；各热窗口仍为 768 instructions／384 cycles，CPI=0.5。

定向结果摘要见 [round3 Protection 验证](../../../../build/ecos-opt-20261012/round3-protection/summary.json)。局部 II=1 与热窗口 CPI=0.5 没有消除完整程序中的延迟代价。完整、未缩短 workload 的 A/B 如下，提交数两侧一致：

| 完整 workload | commits（两侧一致） | 基线 cycles → 候选 cycles | 基线 CPI → 候选 CPI | cycles 增幅 |
| --- | ---: | ---: | ---: | ---: |
| CoreMark 10 | 3218537 | 4016641 → 4223831 | 1.2479710502 → 1.3123450189 | +5.1583% |
| Dhrystone 10000 | 4260629 | 5691655 → 5792104 | 1.3358720039 → 1.3594481003 | +1.76485% |

原可穿过空保护 holder 的结果最早交付晚一拍；DCache 接受到返回的本地命中合同与双 bank 能力不由此改变。普通 load 到依赖消费者、fault 通知、取消租约排空，以及相关信用/LSQ 等待可以受到影响。现在已观测到完整 CPI 回退，但当前摘要不足以把每一项额外周期精确分配给依赖链、信用占用或其它调度原因，不补造 profile 根因。

### 4.1 已测并保留的 Q-credit 基线

主 agent 已回传 round1 source 不变、TT 1.2 V／25°C、2 ns 的完整 STA 结果；它对应 Q-only B credit／head 恒冻结，**不是 round3 Protection 切分的时序结果**：

| 指标 | Q-credit 改动前 | Q-credit 改动后 |
| --- | ---: | ---: |
| 映射面积（µm²） | 2406410.460301 | 2405730.620301 |
| setup WNS（ns） | -5.034887791 | -3.521031380 |
| hold WNS（ns） | -0.313464463 | -0.313464463 |
| pulse slack（ns） | -20.870256424 | -20.870256424 |

setup 改善 **1.513856411 ns**，面积减少 **679.84 µm²**；两项完整程序的 CPI 与计数完全相同，故 Q-credit 已决定保留。setup、hold 和 pulse 仍失败，不代表 500 MHz 达标。

独立实现事实取证确认，R1 最差 setup 起点仍为 PMP config[19]，终点由 IQ dependency 迁移到 DCache bank0 的 lookup 字节转发快照 overlay_data_q[0][51]，**这是 lookup snapshot，不是 FIFO 槽状态**；D arrival 为 **5.4505 ns**。PMP→LSU→Split／Service CPU valid 前缀仍为 **3.2898 ns**，随后经 cache 另一 bank 的读／写 ready、data_write 至 overlay next。末段包含 beat bank0/1 互斥选择重收敛，不能把整条静态路径宣称为已证明同拍可激活；STA FAIL 保持，不据此设置 false path。该新鲜映射支持了原先的保护前缀切分假设，来源见 [R1 语义摘要](../../../../build/ecos-opt-20261012/forensics/round1-qcredit/semantic-summary.json)。

### 4.2 R3 真实边界、指标与瓶颈迁移

同 TT 1.2 V／25°C、2 ns、尚未修复 ICG 负载的可比较结果如下：

| 指标 | R1 Q-credit | R3 Protection holder |
| --- | ---: | ---: |
| 映射面积（µm²） | 2405730.620301 | 2402402.540301 |
| setup WNS（ns） | -3.521031380 | -3.226368427 |
| hold WNS（ns） | -0.313464463 | -0.313464463 |
| raw pulse slack（ns） | -20.870256424 | -20.870256424 |
| minimum-period slack（ns） | +0.408300072 | +0.408300072 |

R3 setup 改善 **0.294662953 ns**，面积减少 **3328.08 µm²**；功能与完整 CPI 代价见 §4。setup、hold、raw pulse 仍失败，minimum-period 的正 slack 不能抵消其它失败。

独立映射核对已确认两 lane 的 public final_fault 只来自 holder 捕获的 overlap/deny/base-fault/PMP-enabled/no-match 等 Q 事实，经 Q 后优先级逻辑生成；反向追踪无 unresolved，未见 raw PMP 配置／range 直通。两 lane 的 registered 模式包含 invalid public payload 恒选 Q。**原 PMP→LSU 直接前缀已被真实寄存边界截断**，不再只是静态架构假设，见 [映射后的保护边界摘要](../../../../build/ecos-opt-20261012/forensics/round3-protection/protection-mapped-fault-boundary.json)。

R3 全局最差路径迁移为 DCache bank0 retained address bit61→hit response-valid→MemoryService／Split 返回→LSU early load-value notice／load tag→IQ resolved-value-valid／eligible／grant／select→source physical-register selection→RegRead shift_amount_q[3][1]，D arrival 为 **5.1427 ns**。cache response valid、LSU early value、IQ resolved valid、source physical register 的累计 arrival 分别约为 0.8495、1.6238、2.7196、4.2859 ns。PMP 不在这条新最差路径中。

因此全局只改善约 0.295 ns，反映新的 load-return→同拍 wake/select→operand/shift 预处理长链接替成为限制；不能据此断言保护局部前缀本身只缩短了 0.295 ns。这个观察支持继续使用已切开的保护边界开展后续收敛，但没有证明某个可实现频率或实际程序加速。

### 4.3 已完成的相同 ICG 负载修复对照

R2 在 R1 上、R4 在 R3 上均加入 **6310 个真实 buffer**，保持相同输入／SDC／TT 库口径：

| 指标 | R2：R1＋buffer | R4：R3＋同样 buffer |
| --- | ---: | ---: |
| 映射面积（µm²） | 2418098.220301 | 2414770.140301 |
| setup WNS（ns） | -3.521031380 | -3.226368427 |
| hold WNS（ns） | -0.313464463 | -0.313464463 |
| global pulse slack（ns） | +0.549876153 | +0.549876153 |
| minimum-period slack（ns） | +0.408300072 | +0.408300072 |

ICG 修复使 pulse 检查通过，但两侧 setup／hold 均仍 FAIL。相同 buffer 处理后的 R2↔R4 差值与原 R1↔R3 架构对照一致，因而将 Protection 的 setup／面积变化与 ICG pulse 修复分开解释。采用原 ideal-clock SDC，结果仍为 prelayout，不等于 CTS 或 500 MHz 达标。ICG 精简来源见 [clock before/after](../../../../build/ecos-opt-20261012/forensics/round2-clock-tree/clock-before-after.json)。

R4 与本轮全部综合／仿真均已结束；原始 STA 保留 raw 对照，显式 sta-clock 入口已集成并完成真实 Yosys 入口 probe。主 agent 已完成四轮最终结果留存与中间物清理，见[最终清理摘要](../../../../build/ecos-opt-20261012/final-cleanup-summary.json)。该工具入口事实不改变上述实际 STA 判定。

## 5. 已执行默认选择：A，R3 作为后续实验起点

**已选择并执行 A：R3 合入默认 RTL，作为未达到 500 MHz 的实验中间态。** R1＋R2 保留为已测、无 CPI 回退的对照结果，供后续判断累计代价；当前默认是已集成的 Protection 寄存边界，不是仅保留隔离材料。

选择依据是用户当前目标仍为保持商业功能合同并向 2 ns 收敛。R3 已真实切断 PMP 结果的组合贯穿，保持 owner／fault／取消合同和局部双 lane II=1，并使全局瓶颈迁移到另一条长链。在多轮收敛中保留这个已成立的边界，比仅因当前全局改善被另一链限制而回到旧保护贯穿，更有利于继续推进同一结构。缺少正式 PPA 资格不是工作区合入的新门槛；不过工作区合入也不改变当前 STA FAIL 的事实。

这一默认选择明确承担已测代价：CoreMark +5.1583%、Dhrystone +1.76485% cycles。它是以长期 500 MHz 结构收敛为目标的工程取舍，**不是已经证明的完整运行时间收益**。当前资料不足以证明这一具体一拍切分是唯一必需或最终最优；若后续同合同实现能以更低 CPI 代价解除同一限制，可以重新比较并替换。本文不扩展新的切分方案。

运行时间按 cycles／实际合格频率比较。在两侧频率均已有可比较的真实时序依据时，候选要抵消当前周期增加，需要频率比 `f_candidate/f_baseline` 至少为 CoreMark 的 **1.051583**、Dhrystone 的 **1.0176485**；严格改善还需超过相应值。这只是盈亏平衡条件，不能把 WNS 代入一个公式就宣称获得该频率比。若两侧均能以相同 500 MHz 合格运行，当前候选的执行时间仍分别增加 5.1583% 与 1.76485%。

后续按相同库、约束、ICG 处理与完整 workload 继续逐项报告；不以局部 II=1 隐去 CPI 成本，不以面积改善抵消 setup／hold 失败，也不通过 false path、放宽 checker 或减少 workload 制造收益。综合中间物在必要结果采集完成后仍由主 agent 清理。本轮默认实现选择、合入与已有实验均已完成；新的优化轮不在本文范围内。
