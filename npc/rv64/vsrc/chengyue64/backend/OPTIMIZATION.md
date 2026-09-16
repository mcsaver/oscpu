# Backend 架构优化分析

日期：2026-09-07。本文先保留 2026-09-07 优化前的分析与证据，后续实施状态另列于文末。拓扑已更新为当前 RTL；下文各候选中的“当前”描述分析时基线，不能代替新的实测结果。

## 结论与优先级

当前优化应分成两条线：

- **时序线优先处理控制网络**：全局 flush 经分支发布重新进入 kill，再进入完成授权；LSU 复用保护经 ROB 分配进入统一 birth。两条链已有整核映射路径证据。
- **CPI 线优先处理依赖循环和服务等待**：ALU 早唤醒的提前空间、WB 新来源的申请延迟、RegRead 混合 FU 的队头阻塞。结构存在，但尚未测出这些机制在 CoreMark 中各占多少周期。

不能仅因 IQ 内部选择器多就判定 IQ 是首要时序瓶颈，也不能把独立 ALU 的 CPI 0.5 当成依赖链已经足够短。当前双 birth、双 issue、双 WB、双 retire 的基本宽度先保留；容量扩张放到原因归属明确之后。

## 本次新增的时序依据

使用上一轮 candidate-v2 的 R64CoreTop 映射网表，保留原 icsprout55 TT、1 ns 时钟、50 ps uncertainty 和原 I/O 约束。没有重新综合，没有删除 reset/flush 路径，也没有修改 false-path/multicycle 约束。

每组按映射寄存器 Q 名选择 D 端点；综合别名可能进入同一组，因此不是完整、互斥的模块面积分区。第一列测量允许所有起点；第二列额外限制由寄存器时钟端发起，用于区分外部 reset 与内部控制网络。后者仍包括 Commit 等跨模块起点，不等于正常运行数据通路的专属时序。

| 目的端点组 | 原约束下 slack / ns | 寄存器发起 slack / ns | 寄存器发起的最差起点 |
| --- | ---: | ---: | --- |
| IQ ready 及就绪查询状态 | -1.847649 | -1.641632 | Commit event_trap_q |
| IQ birth/年龄/串行依赖状态 | -1.644740 | -1.532930 | LSU request_queue_tag_q |
| RR issue 捕获与读地址 | -1.358955 | -1.126651 | ROB head/commit tag |
| RR 操作数与转发捕获 | -1.609677 | -1.403661 | Commit event_trap_q |
| RR 队列控制 | -1.649510 | -1.443494 | Commit event_trap_q |
| GPR/FPR 数据阵列 | -1.749302 | -1.543286 | Commit event_trap_q |
| Rename 状态 | -1.647219 | -1.497917 | LSU request_queue_tag_q |
| WB 调度摘要与 grant | -1.342425 | -1.136409 | Commit event_trap_q |
| WB 接受与 owner certificate | -1.586015 | -1.379998 | Commit event_trap_q |
| ROB 完成/恢复控制 | -1.541332 | -1.437179 | LSU request_queue_tag_q |

这些组的 unrestricted 最差起点均为 rst_i。完整门级路径进一步确认：

1. Commit event_trap_q → full_flush → ALU resolve 的 flush 资格判断 → branch redirect 汇合 → ROB kill mask → 完成/唤醒授权 → IQ ready、PRF 或 WB 请求状态。公共 flush 缓冲节点的扇出为 95、负载约 0.080962 pF，单级延迟约 0.484494 ns；路径还包含后续资格选择逻辑，不能把全部违例归因于一个缓冲器。
2. LSU request_queue_tag_q → 队列/LSU reuse bitmap → ROB tail 槽位查询 → birth0 → IQ 年龄状态。这条路径不是执行数据计算，但它决定新指令何时能进入机器。
3. RR 捕获组的最差寄存器路径由 ROB head/commit tag 发起，经过选择控制到 FPR 读地址。这是进一步检查 Serial 头身份检查、IQ 选择和 FP 读计划的依据，尚不能证明整个 16 路 pair selector 是主因。

原整核全局 setup slack 仍为 **-3.433340 ns**，最差端点仍是 Dcache 数据阵列写入。Backend 优化有独立价值，但不会自动消除该全局瓶颈；布局前 STA 也不能直接宣称已达到某个实际芯片频率。

## T1：在同一取消边界内缩短 flush/kill 控制串联

源码：[R64Execute](R64Execute.v)、[R64Rob](R64Rob.v)、[R64Commit](../control/R64Commit.v)。

当前已经有 raw redirect_pending、prepared cancel、局部 WB owner certificate，且 ROB 的 freeze 已使用 pending 摘要。还没有被完全切断的是实际 kill/完成授权链，不能把已有机制当成尚未实现的方案。

建议先做同拍、等价的控制因式分解：

- 保留分支的原始寄存事实、full tag、preview plan；由最终消费者统一处理 reset/full_flush/partial kill 优先级。
- 对本身已经以 !rst && !flush 保护的 PRF 写入、canonical wake 和完成事件，检查能否使用 raw pending + 已验证 plan 的局部取消谓词，避免先把 flush 送入分支 valid，再绕回 kill mask。
- 外部可见 redirect、真实副作用接受仍使用完整合法性条件；prepared 摘要只参与其被证明等价的消费者，不扩大它的授权能力。
- Commit 可以在现有事件状态转换时预译码 apply/restart 阶段，形成短的本地控制。必须保持 trap_prepare、CSR 状态更新、redirect 的原有拍数和顺序。
- 再评估按 ROB bank/消费者复制窄控制状态和物理扇出修复。综合可能合并等价副本，因此用实际映射路径判断，不能仅靠 RTL 多写几个寄存器宣布扇出下降。

**首个验收**：分支 redirect、full flush、WB、head store 完成同拍，以及恢复途中更老分支覆盖时，实际 birth/kill/wake/PRF-write/commit 事件与原逻辑等价；新增路径缩短且正常执行不加拍。不能仅将 kill 寄存一拍，否则错误路径指令可能多获得一次授权。reset 不从 STA 中屏蔽。

## T2：把跨模块复用查询变为已登记的占用摘要

源码：[R64Lsu](../lsu/R64Lsu.v)、[R64Rob](R64Rob.v)。

当前 LSU 的 reuse_block 合并 LSQ、descriptor、query、translation、raw、forward、completion、physical_hold、store_done 等仍在持有事务的状态。ROB 再用 tail 索引该 bitmap，参与统一 birth。这个保护是必要的：ROB 指令取消后，外部返回和内部暂存仍可能晚到。

建议先比较两个有界实现：

- 在持有 tag 的小队列接受 owner 的同一拍登记 ROB 槽位 one-hot，reuse 输出组合只做占用掩码与 OR，移除 tag→slot 译码。
- 或由每个 owner 域维护已登记的槽位占用摘要，按真实 acquire/release 更新，再由 ROB 消费。完整 tag 继续用于数据/返回归属，bitmap 仅表示物理槽位暂不可复用。

内部从 descriptor 移到 query、从 query 移到 physical_hold，不等于释放整个事务；同一个 ROB slot 同时被多个位置引用时，也不能用一次 pop 直接清掉总 bit。需要引用计数、逐域占用位或等价守恒实现。同拍交接不得出现一拍“未占用”漏洞；允许保守晚释放的方案必须明确测量新增 reuse stall。

**首个验收**：reuse 摘要绝不漏报仍在排空的引用；覆盖 kill 后返回、内部转移、同槽多引用、同拍出入、generation 回绕和槽位重用。对比上述 LSU tag→ROB birth→IQ 路径及 reuse 导致的 birth 停顿。保留 MEM 在统一 birth 时预留 LSQ 的策略，不推迟到执行阶段再建立内存年龄。

## C1：用有保证的数据可用时刻缩短 ALU 依赖循环

源码：[R64Execute 中 R64AluLane](R64Execute.v)、[R64Issue](R64Issue.v)、[R64RegRead](R64RegRead.v)。

当前只有成为 ALU 结果队头的生产者才允许 early wake；后续 RR 读取由头部 bypass 或正常 WB/PRF 供数。这条路径已经存在，下一步是判断能否提前一拍建立“数据在消费者读取时一定可用”的事实。

在消费者已经驻留 IQ、其它源 ready、生产者成为结果队头且没有背压的理想条件下，按 RTL 边界推导：

| 时钟边沿 | 事件 |
| --- | --- |
| t0 | 生产者进入 ALU 的寄存计算阶段 |
| t1 | 生产者结果进入队列；消费者 ready 位捕获 early wake |
| t2 | 消费者 issue，进入 RR ingress |
| t3 | 消费者物理读取/转发快照进入 terminal |
| t4 | 消费者进入 ALU |

这是 RTL 拍序推导，尚未用独立依赖链测试测定；它说明稳态独立吞吐和依赖指令间隔是不同指标。

首选探索**受限的接受时唤醒**：只对已明确占有结果空间、不会被更老结果遮住、能够保证后续读边沿取得结果的短 ALU 生效。可以先限制在无更老在途/排队结果的情形；不能将它直接推广到 MDU、FP、load 或结果队列有前驱的情形。若需要独立旁路保持槽，数据必须保持到 canonical WB 或取消，不能只发一拍脉冲。

这会引入 Execute 接受→ROB owner 认证→IQ ready 的新控制路径，必须和 T1 的时序一起评估。当前按实际头部数据可用性唤醒的逻辑保留为其它情形的基础路径。不能用“固定算术延迟”代替端到端数据可用性证明。

**首个验收**：串行整数依赖链的相邻执行间隔、ALU→branch 间隔和稳态 cycles 减少；独立双 ALU 吞吐不退化；WB 堵塞、kill、同拍写回、preg 重用、消费者延后读取均得到正确数据。若新关键路径抵消周期收益，则不保留。

## C2：缩短 WB 新来源申请延迟，再考虑提高空槽利用率

源码：[R64Writeback](R64Writeback.v)。

当前是已有公平轮转的 9→2 网络，不是固定 ALU 优先。request_q 先采样来源 valid，再产生寄存 grant；实际接受在后续的当前 valid/ready 边沿完成。持续来源可以 II=1，但刚出现且未获 grant 的结果经过额外调度阶段；授予空来源的端口也可能闲置。

第一步比较：由 FU 已登记的结果头占用摘要直接参与下一拍 grant 选择，减少对已经属于 Q 状态的信息再次采样。摘要不带宽数据、不由同拍 ready 决定，也不提前授权数据；最终 capture 仍验证当前 valid、full tag 与取消状态。这个方案只承诺探索减少新来源调度延迟，不声称立即实现每拍都填满端口。

若统计显示闲置 grant 仍占明显周期，再试有容量保留的结果 staging 或受控 fallback。不得让宽结果在最终 kill/take 后重新选路；不能接回 source-ready→FU-valid→全局仲裁→source-ready 的组合环。已有 FU 结果队列尽量复用，避免九个来源全部额外加深。局部 FP 自身还有 4→1 汇合，需要同时计入。

**首个验收**：每类结果从 ready 到 accepted 的平均/尾部等待；存在合法待完成结果时实际空 WB 槽的数量；ROB 头等待完成的周期；ALU 结果队列满导致的停止；持续九源的公平性。平均结果产出若已超过两个/拍，单纯增加缓存不能提升长期服务上限。不要先扩到四 WB，它会联动 PRF 端口、ROB 完成和 wake 网络。

## C3：给 RegRead 的混合队头增加受限绕行

源码：[R64RegRead](R64RegRead.v)、[R64Execute](R64Execute.v)。

当前每个物理 lane 是 ingress 1 + terminal 2；terminal 头可能等待 DIV/FP 接口，而后面的 ALU 或已预留 LSQ 的 MEM 已具备操作数。两路 FIFO 不能保证消除各自内部的队头阻塞。

建议先将同一 lane 的两个 terminal 槽改为可独立释放的驻留槽，增加选择剩余可服务槽的能力；保留当前 lane 和 4 GPR/3 FPR 读口。两槽都可服务时仍优先老者；老者目标不可服务而年轻者目标可服务时允许后者前进。对 Serial 保持现有屏障和 head 身份；MEM 始终携带原 LSQ slot/full tag。

这里至少需要同时解决：

- 出口 valid/payload 在未接受时如何保持。若接收者使用 held ready/valid，已 offer 的 owner 必须锁住；不能因为 ready 改变就偷偷换包。
- 可服务选择若用 FU 当前 ready，会把下游 ready 加进宽 mux。更稳妥的方案是窄请求、实际容量 reservation 和已登记服务选择，但要计算新增仲裁拍的代价。
- 普通周期的队头快路径不要因偶发绕行无条件多一拍；否则稀少 HOL 收益可能小于所有指令的固定损失。
- 操作数、forward snapshot、FPR rank、预译码、full tag 和 LSQ slot 必须同 owner 移动，槽位变化不是重新读取 PRF。

对于已经向 FP/MEM 等接收者发布、尚未接受的请求，可选实现是在受影响的 FU 入口保留一个小的保持槽，由它继续持有原 owner，RR 只选择尚未对外发布的驻留槽。另一种实现是消费可保留的 FU credit 后才建立 offer。两者都要计算新增存储、仲裁和正常路径延迟。

因此这是一项跨 RR/Execute 接口的独立实验，而非只换一个 head mux。不能只放大原 FIFO，也不能仅把 FU 的当前 ready 接到 IQ：这既可能延长 ready 回路，也不能撤回已进入 RR 的堵塞指令。当前 RR 早已在完成一次读取后释放读端口，不需要再“修复读端口长期被占用”。

**首个验收**：人为堵住一个长单元入口，证明同 lane 后继 ALU/MEM 在解除堵塞前获得实际接受；反向压力、两个 lane 争同 FU、持续服务、kill/flush、输出背压和单 lane 接受都正确。统计真实 workload 的“头不可服务、后继可服务”周期，决定是否保留。

## C4/T3：按真实资源足迹配对，再选择性简化 IQ

当前 compatible 主要按 class 判断：ALU+ALU、MEM+MEM 可以；同 MDU class 不能同拍配对。但 Execute 内 MUL、DIV、CLMUL 是独立单元，并有独立 long_taken 和 ready。

可以先在 birth 时记录 MUL/DIV/CLMUL 子类型，将它们作为不同入口资源；支持不同 MDU 子类型配对，仍禁止争同一入口。保留每对 raw FPR 源数 <=3 的当前约束，不顺手扩读口。FP 仍是单入口，不能照搬 MDU 的放宽。

这一项范围小、容易用独立 MUL+DIV 等定向流验证，但未必帮助几乎不含相应混合的程序。可以作为第一批小改动，但不能赋予最高的预期 CoreMark 收益。

IQ 的 16 个假设 first 对应 16 个 second selector 用面积换并行选择深度。直接改成“选 first 后再串行选 second”很可能减少面积却恶化时序。若路径归属确认值得做，可试按功能资源和 FPR 源数分组，每组先取足够数量的最老候选，再完成双槽匹配；每类只取一个候选会丢掉 ALU+ALU、MEM+MEM 的双发机会。队列加倍会扩大年龄/兼容矩阵和 wake 比较，应放后面。

## C5：按语义区分 Serial 完成与全局重启

当前每次 Serial 退休都建立 restart/full_flush，包括注释明确提到的只读 CSR/FENCE/WFI。这个范围比“所有操作都需要前端重新取指”宽。

首个候选可以是明确列举、不改变执行/翻译/取指上下文的 CSR 读取：仍到 ROB 头执行、保持访问权限/异常处理、只在退休产生架构影响；完成后释放 serial_dependency，使后继继续。副作用、计数器时刻、pending IRQ、异常和调试仍需逐项核对。

FENCE、FENCE.I、SFENCE.VMA、xRET、satp/mstatus 写以及 WFI 各自有不同的排序/恢复语义，不能按名字一并去掉重启。先只修改 whitelist 子集。该方向更可能帮助系统/CSR 密集程序，对 CoreMark 的价值需以动态出现次数证明。

**首个验收**：目标子集的 flush 和重复 fetch 减少；非目标 Serial 行为保持；head 等待、IRQ、异常、CSR read/RMW 和 younger dependency 释放全部正确。

## 后置方案

- **分支 map checkpoint**：当前 youngest-first 每拍两条 undo。先量化 redirect 后“前端已能提供指令，但 rename 仍在 undo”的暴露周期，再决定 checkpoint 个数和 free-list 恢复实现。恢复时间可能被前端重填覆盖，不能简单把 killed/2 当成可节省周期。
- **ROB/IQ/LSQ/PRF 加容量**：先确认满队列是容量瓶颈，还是 WB/HOL/翻译/复用保护的反压结果。物理寄存器释放仍依赖提交/恢复。
- **更宽旁路/四 WB/分布式 IQ**：会同时改变多端口阵列、全局 tag 比较和结果流；不是当前首个实验。
- **取消 birth 时预留 LSQ 或取消 reuse_block**：会触及未知 older store、IO 分类、晚返回和 generation 复用，不作为性能快捷方式。

## 建议的最小实验顺序

| 轮次 | 只改变的机制 | 主要判据 |
| --- | --- | --- |
| 1T | flush/partial kill 的本地等价资格判断 | 真实事件同拍等价；上述控制路径缩短 |
| 1C | 已认证、受限短 ALU 提前唤醒 | 依赖链减少周期且新时序不抵消收益 |
| 2T | LSU 复用占用的登记摘要 | 无漏保护；birth 路径缩短；保守释放停顿可接受 |
| 2C | WB 新来源调度 | 新来源/ROB 头等待下降；长期公平性保留 |
| 3C | RR 两槽受限绕行 | 实际 HOL 被打破且无固定正常路径惩罚 |
| 4 | MDU 细分配对、Serial 子集、IQ 选择结构 | 各自独立 A/B 后决定 |

T/C 表示不同目标的实验，不要求同一轮合并提交。优先级可由少量被动计数调整，但每次保留独立可归因的对照。瓶颈计数可重叠，不能直接相加等于可节省 cycles；退休停顿需区分 ROB 空、头未完成、Serial/recovery 和 trace 外部反压。

上一轮 CoreMark 整个程序 cycles 从 10,272,184 变为 10,275,408（+0.0314%），Dhrystone 基本不变，而多个局部阻塞实验有明确改善。这说明局部机制改善不等于应用收益。后续最终评估仍看相同 workload/工具/约束下的 cycles、CPI、CoreMark 计时区间、面积和 mapped STA；频率与 CPI 的联合收益使用比较关系
`执行时间比例 = (cycles_new / cycles_old) × (frequency_old / frequency_new)`，
实际频率未收敛时不将其当成已实现性能。

## 证据位置与本次完成范围

- [拓扑](TOPOLOGY.md)；当前相关 RTL 均在同目录及 control/lsu 中。
- [上一轮软件与整核评估](../../../../../tmp/rv64-lsu-network-complete-20260907/REPORT.md)。
- [本次 Backend 分组脚本](../../../../../tmp/rv64-lsu-network-complete-20260907/collect_backend_groups.py)。
- [分组及 RTL 起终点](../../../../../tmp/rv64-lsu-network-complete-20260907/candidate-v2/sta/R64CoreTop-1000MHz/backend-groups/result-with-rtl.json)。同目录保存全部 22 个原始 .rpt、groups.json、report.tcl 和 run.log。

上述内容为实施前分析。T1、T2、C1、C2、C3、C4 的 MDU 部分、C5 的 scratch 只读白名单已经形成独立候选快照并完成定向验证。IQ 选择器整体重构、分支 checkpoint、队列扩容仍是后置研究项。最终组合的完整测试、CPI 与映射结果见 [本轮实施报告](../../../../../tmp/rv64-backend-network-opt-20260907/REPORT.md)。所有负 slack 均按实际结果保留。


## 最终实施结论（C6）

七项有界候选已实现并完成同版本完整功能、软件、CoreMark/Dhrystone 与真实综合/STA。最终保留 C6：CoreMark 总周期 -5.5187%、Dhrystone -2.5770%，面积 +0.04686%；全局 setup/hold 与原基线相同，仍未收敛到 1 GHz。

验证中发现并修正了第一版接受时唤醒的取消→fire→early tag→owner 长链。最终 IQ 含 reset 的 slack 仍比基线差 0.068264 ns，寄存器起点差 0.274281 ns；RR 操作数、PRF、WB 接受认证等路径改善。完整表与保留条件见 [实施报告](../../../../../tmp/rv64-backend-network-opt-20260907/REPORT.md)，不把本轮描述成全面时序改善。
