# 面向 500 MHz 的整体性能架构多轮方案（2026-10-13）

状态：**纯架构候选，未实现、未仿真、未综合或 STA；本文不改变生产拓扑和正式 PPA 状态。**

工作区为 `/home/lyg/PA/ysyx-workbench`，分支 `ai`。本轮主 agent 确认的实现基线为
`e44dac90b`，语义上是已集成 R1 Q-only DCache B credit 与 R3 registered protection holder 的当前默认。
R4 是相同 RTL 的真实 clock-buffer 处理结果。本文只写本文件，不修改 RTL、TB、约束或其他架构文档。
面积本轮基本不作为淘汰条件；实际时序、周期、功耗与功能合同仍分别报告。

## 1. 建议与可观察目标

推荐主线是：**保留保护寄存边界，与时序方案共同切开返回到调度的组合链，再用更早的真实请求事实提前安置消费者；只有测得待值挤占或同 bank 读冲突时，才分别增加待值资源或复制缓存读视图。**

依次设计三个候选方向；P2 的位置、容量和带宽分别做独立子实验：

1. **P1：从真实翻译请求接受事件提前发布 load 调度 promise。** 只提前等待，不提前宣称值、权限或完成。
2. **P2：给 load 依赖的简单 ALU 增加独立待值位置。** P2a 保持 1 信用、单 lane，只迁移位置；P2b 才单独试 1→4 信用，P2c 再单独试双 lane 带宽。
3. **P3：每个 DCache bank 复制一次完整读视图。** 只解决同 bank 双 load 的读端口冲突；每份真实 1RW 宏仍承担写维护。

本轮架构交付的 acceptance 是：每个候选都有明确周期/容量/归属合同、独立 A/B、反证条件与最小反例；
两份架构方案由全新评估 agent 独立评估。实现和测量不是本文的完成条件。

后续实现优化的目标是同配置完整 CoreMark 10 和 Dhrystone 10000 的 CPI 恢复或改善，
同时向 2 ns 收敛；不能将某一个局部等待计数下降作为程序加速。
以当前 R3 为直接实验基准，以 R1 的完整 cycles 为累计性能对照：
CoreMark ≤ 4,016,641、Dhrystone ≤ 5,691,655 才能说两项完整周期代价均已追回。
暂时未达到这一累计目标的中间候选可以继续被验证，但不得称为已完成性能恢复。

固定 ISA、双发射 OoO、两个真实 memory datapath、precise trap、访存顺序、PMP/PMA、
owner/epoch、恢复、取消排空、ready/valid、backpressure 和 progress 合同。
不改 workload、checker、频率目标或时序约束来制造收益。

## 2. 证据边界与当前状态

### 2.1 已测结果

主要精简来源：

- [ECOS 四轮结果](../../../../build/ecos-opt-20261012/RESULT.md)；
- [保护寄存边界结果](memory-protection-boundary-20261012.md)；
- [本轮独立取证摘要](../../../../build/arch-parallel-20261013/architecture-facts.json)。

本角色只读上述摘要与架构文档，不沿其中的源码、网表或原始日志指针继续读取。
同一事实有冲突时，优先采用绑定当前工作区的独立摘要；
例如 Backend 拓扑开头的旧说明没有完整包含后续 Memory 值公告机制，不能据其旧文断言当前没有该路径。

| 项目 | 已确认事实及适用范围 |
| --- | --- |
| 工况 | ICS55 + ECOS SRAM，TT 1.2 V / 25°C，500 MHz / 2 ns，原 0.05 ns uncertainty；pre-layout ideal-clock / pin-cap 模型 |
| R3 → R4 | RTL 相同，R4 加真实 buffer；最终 setup WNS −3.226368427 ns，hold WNS −0.313464463 ns，pulse slack +0.549876153 ns |
| 保护 | 两 lane 的 raw PMP 到公开保护结果已被真实 holder Q 截断；含 invalid payload 恒取 Q；每 lane II=1，Bare 最终 latency 1→2 |
| 当前最差路径 | DCache 返回资格 → LSU 最终值公告 → IQ 当拍 wake/select → 源 preg 选择 → RR shift 准备，arrival 5.1427 ns |
| 最差路径限制 | 该条路径不含 ECOS SRAM read-data arc；不能把复制 SRAM 直接解释成切断当前最差链 |
| 功能范围 | R1/R3 各 10 个全核 DiffTest 场景、7 个双发射热窗口通过；每窗口 768 instructions / 384 cycles |
| 当前测量限制 | setup/hold 仍 FAIL；无合格 Fmax、无活动率功耗结果；不由 WNS 换算真实 runtime |

| 完整 workload | commits | R1 cycles / CPI | R3 cycles / CPI | 增加 cycles |
| --- | ---: | ---: | ---: | ---: |
| CoreMark 10 | 3,218,537 | 4,016,641 / 1.247971050 | 4,223,831 / 1.312345019 | 207,190（+5.158290%） |
| Dhrystone 10000 | 4,260,629 | 5,691,655 / 1.335872004 | 5,792,104 / 1.359448100 | 100,449（+1.764847%） |

这些额外周期是完整程序差值，**不是已经归因给 load-use 的 stall 数**。
R3 的 load_profile / latency bins 缺失，尚无 protection 多一拍与依赖链、token 满、
RR pending、缓存同 bank、维护或慢 owner 阻塞之间的完整因果分解。

### 2.2 当前 profile 对选题的约束

下表来自当前 R3 的独立取证摘要；分母分别为 4,223,832 与 5,792,105 个 profile 采样周期，
与最终程序 cycles 各差 1。各项非互斥，不能相加，也不能逐项当成可消除周期数。

| 已有 profile 占比 | CoreMark | Dhrystone | 允许的解释 |
| --- | ---: | ---: | --- |
| frontend empty | 16.2258% | 7.8760% | 有供给不足观察，未分出 cache/恢复/预测原因 |
| frontend full | 26.9601% | 36.0261% | 也存在下游不接收，不能把 empty 全归前端 |
| decode ROB block | 11.4149% | 39.8585% | Dhry 的在飞生命周期更值得观察，未证明应扩 ROB |
| decode IQ block | 18.9600% | 0.0067% | 两程序不同，不支持统一扩大 IQ |
| decode LSQ block | 0.0046% | 2.9364% | 不支持先统一扩大 LSQ |
| issue zero | 46.7260% | 49.1056% | IQ→RR 实际接受现象，不等于没有执行或没有真实值 |
| WB backpressure | 18.5630% | 27.8416% | 可能与值可见和 head 等待有关，未分清来源及关键性 |
| ROB nonempty/notdone | 48.4757% | 55.4878% | 存在完成等待，未分清 load、算术、store 或资源 |

branch_redirect 为 49,426 / 30,188，prediction_redirect 为 45,526 / 30,737；
没有 branch 分母、唯一事件匹配或本轮热点分解，不能将这些数直接称为 misprediction rate。

### 2.3 文档结构事实与未测利用率

架构依据是 [公共协议](../../vsrc/PROTOCOLS.md)、
[Backend 拓扑](../../vsrc/backend/TOPOLOGY.md)、
[LSU 拓扑](../../vsrc/lsu/TOPOLOGY.md) 和
[Memory 拓扑](../../vsrc/memory/TOPOLOGY.md)。以下是文档合同，不补造当前利用率：

- 两宽 birth/issue/普通 WB/retire；ROB32、IQ16、LSQ20；GPR/FPR 各 64×64 bit。
- RR 有两 lane，各 1 ingress + 2 terminal，共 6 个保持位置；现有受限 escape 只让合格后排 ALU 绕过 MDU/FP head。
- DataTranslationService 每 lane 4 个 token，真实终端 response fire 才释放；cancel 不删除服务租约。
- DCache 为 8 KiB、2 way、64 sets、64 B line、PA[3] 双 bank；4 颗真实 256×64 单 1RW 宏。
  clean hit 每 bank 每拍一读，两个不同 bank 可并行；每 bank 两项 write-combine FIFO。
  dirty 竞争最多连续 4 次真实 lookup 后给 oldest 一次 masked write；不能无限 1R1W。
- DCache 有一个主 read/refill/特殊事务 owner 和一个独立普通 cached-store B owner；
  受限 hit 可与慢事务重叠，额外 miss 等待。
- Memory 两路最终值公告 non-owning，无 ready/ack，可重复且可错过；
  原 ingress/CQ/WB 始终负责规范完成。当前已确认可同拍影响 IQ 和 RR 完整值准入。
- 当前没有 translation-accept 或 physical-accept load promise；已有 load promise 来自
  LSU 结果被 WB transport 真实捕获。以下提前 promise 是新机制。
- ExecutionOwners 的当前 lease 用完整 tag、当前 birth/load/write/GPR 身份认证；
  accepted WB 终结该 lease，后续 birth 覆盖身份。延迟公告不能仅保留 preg 而任意跨复用。

## 3. 三种因果假设与架构边界

| 候选 | 单一性能假设 | 新资源/周期改变 | 不成立时的竞争解释 |
| --- | --- | --- | --- |
| P1 提前 request promise | load 值返回时才选择消费者，存在可被提前等待覆盖的调度/读准备时间 | 两路事件 Q；最多一个提前等待 owner 独占整个既有 RR lane1，准入前该 lane 全空；规范 load latency 不变 | promise 到达太晚；consumer 尚未 birth；链不关键；整 lane 隔离成本抵消收益 |
| P2 独立待值位置 | 已证明 P1 的提前量有效，但其隔离 lane 的成本抵消收益 | P2a 只迁移一个待值 owner；P2b 容量 1→4、仍单 lane；P2c 保持 4 项再扩双 lane；就绪后均经过本地值 Q | 程序主要等待生产者真值/ROB head；迁移、扩槽或带宽各自不能降低关键等待 |
| P3 复制每 bank 读视图 | 两个已就绪、允许接受的 load 经常竞争同一 bank 的单读口 | 每 bank 两份完整读视图，共 8 个 DCache 宏；逻辑容量仍 8 KiB | miss/写维护/LSQ顺序/前端才是限制；双读碰撞不在关键链 |

只有 P1 直接针对“时序切分后如何隐藏调度时间”。P2 和 P3 是有针对性的资源实验，不把面积放宽解释成所有容量一并翻倍。

一条消费者指令始终只有一份执行归属：IQ → RR，或 IQ → 待值站 → 实际 ALU 接受。
ROB/preg/LSQ 的架构分配合同不变；候选不能多发同一指令，也不能因为等待位置变了就清 busy、设置 done 或发布副作用。

## 4. P1：真实翻译接受触发的有限提前调度

### 4.1 为什么选择这个边界

先前考虑在真实物理 load accept 时发布 promise，但 clean cache hit 的接受到返回合同只有一拍。
若事件再经过 Q 和 IQ 的 Q 更新，可能已没有领先最终值的窗口。
因此首个性能实验把事件放在更早的**首次真实 translation request accept**：
该时刻 canonical LSQ 已有身份，翻译/保护租约确已建立，而 R3 的保护及后续访存尚未完成。

这只证明“该 owner 的请求被翻译服务接受”，**不证明翻译成功、权限允许、属于 RAM、
cache hit、短延迟或必然产生数值**。page walk、PMP fault、IO 排序与 miss 都可以很久才终结。
不能以未决权限、未决 store ordering 或地址预测发物理请求；物理访问仍走原合同。

事件仅允许普通对齐整数 load，排除 FP、atomic、非对齐/split、触发器访问及重复 A/D/replay；
缺少满足条件的事实就走现有路径。首次真实接受事件按 canonical owner 记录一次，
event 被丢失只少一次提前调度机会，不需要重发来保证完成。

### 4.2 接口、容量与归属

- 每 lane 一个采样事件 Q，保存 valid、完整 producer tag 和需要的类型事实。
  捕获由实际 translation fire 产生；不存在 translation ready → IQ 本拍选择的组合直通。
- 接收方按当前 ExecutionOwners 完整身份认证，映射到目的 GPR。
  promise 是 source 调度事实，不能把 Scoreboard busy 清零、写 PRF 或替代规范 WB。
- 第一轮只允许**一个全局提前等待消费者 C**，放在 RR lane1，但必须先满足下文的整 lane 空闲准入与独占合同；不能只检查一个 terminal 空位。
  仅简单整数 ALU、恰好一个未决 load 源、其余使用源已有真实就绪事实，才能占用这一个信用。
  两个相同逻辑源指向同一 producer 仍是一个身份，但必须覆盖两个操作数位置。
- 不把 ready_bin 中的 promised 项误当成真实值已齐；不允许另一个 promised 源参加首轮。
- consumer 的完整 tag、源 preg、pending producer 的完整身份及普通 RR 元数据一起转移。
  未获提前信用时保留 IQ owner 和原选择路径，不生成额外重试 owner。
- 这个 consumer 提前 IQ→RR 接受时，**不再向下游消费者传播 issue-time ALU promise**。
  后续仍可由真实执行后的已登记 ALU token/head 或规范 WB 唤醒。
  不能把一次 load 请求放大为任意长的提前等待链。
- 信用及 lane1 独占状态从实际 IQ→issue capsule/RR 接受到该 consumer 真正离开 RR 或被本地恢复取消为止；
  不借当拍释放量形成组合信用。额外保守一拍只影响尝试机会，不影响正常路径。
- 不改变 producer 的翻译 token、物理 owner、CQ、WB、store permission 或 ROB 退休责任。

**准入与固定隔离是必要 correctness 条件。** C 只能在 lane1 的 issue capsule、ingress、
全部 terminal 及任何已接受但尚未落槽的该 lane owner 均为空时接受。
这一判断使用完整的已登记占用/在途信用；不能只因 terminal 空就忽略先前接受的 MEM。
C 的接受沿原子设置 lane1 独占 Q，排除同沿其他 lane1 接受；从下一拍起禁止任何普通候选、
转移或另一个 promise owner 进入该 lane。所有普通新候选必须走原 lane0，未获 lane0 信用则留 IQ。
C 后面不能排入 S，也不能以“等将来再换 lane”接受 S。

独占持续到 C 真正 fire 离开或被本地取消，并按 Q 信用在后续拍恢复普通 lane1 准入；
C 已获真值但尚未获 ALU 接受时仍保持独占。不允许借同沿取消/pop 搭载新 owner。
因此 C 在整个未决窗口内是 lane1 唯一 owner，不能阻塞任何已驻留该 lane 的老操作。

明确反例是：更老 store S 未 bind，年轻 load L 的翻译已接受但仍等 S 的地址/数据/顺序；
L 的 consumer C 提前成为 lane1 pending ALU head，若随后把 S 放到该 lane 的 C 后，
现有 escape 不允许 S 越过 C，会形成 S→L→C→S。**仅说 lane0 空闲不能解这个环。**
修订后的禁止准入使 S 在 IQ 等候 lane0；若 S 已在 lane1，则 C 根本不能接受。
不增加跨类 escape、迁移或再次派发机制。

lane0 必须能承载解除 L 等待所需的普通/长延迟/必要串行操作；
WB、物理完成、恢复与取消排空必须独立前进。这些是实现角色需核实的条件，当前不伪称已验证。
若存在必须走 lane1 的必要操作，或未能覆盖该 lane 的全部在途 owner，P1 作为条件候选直接淘汰，
不以任意延迟可恢复、外部最终响应或宽泛 lane0 可用代替证明。

### 4.3 周期合同

以 t0 为首次 translation accept：

| 边沿 | 候选最早行为；均受现有 Q 信用和调度条件约束 |
| --- | --- |
| t0 | 原翻译租约建立；同沿只采样新 event Q |
| t1 | 执行域认证 event Q，并更新已有 IQ source 的 promised Q；不承诺数值 |
| t2 或以后 | IQ 从已登记资格选择 consumer；仅 lane1 全空且可原子独占时接受到登记入口，否则 consumer 留 IQ |
| 后续原读阶段 | 捕获其他真实源，并等待带同一 producer 身份的最终值或规范 WB |
| v：合法最终值被本地捕获 | pending 清除与真实值一起登记；不由 raw response 直通执行 |
| v+1 或以后 | 数值齐全且真实 FU 接受时才执行一次；下游背压则保持 |

t2 不是所有 load 的固定时间，v 更不是 t0 的固定偏移。事件漏收、晚 birth、恢复或 WB 先到时回退现有真实值路径。
为与 timing 的 issue capsule 保持一致，不允许 t2 的当前 IQ 选择穿透到 PRF/shift 预处理。

可隐藏的时间只能从真实边沿统计：某 consumer 已在等待位置、其他源已准备，
到最终值合法捕获之间的领先量，以及完整关键依赖链上的执行接受改善。
“提前 1 拍更新 promised”本身不是节省 1 个程序周期的证明。

### 4.4 取消、复用和精确异常

恢复先按原本地域合同杀死 consumer；pending 的存储位置必须参与已有 owner/reuse 保护。
producer 的取消不会删除已接受翻译/总线事务，服务照常排空；其后续公告不能唤醒新 generation。

合法最终值第一次被捕获时需完整身份认证，不能跨任意延迟只靠 preg 命中。
成功规范 WB 与晚公告同沿时，WB 具有数值捕获优先级；lease 终结后不能靠旧公告重新建立 ready。
一旦合法值已成为仍存活 consumer 的本地操作数快照，不要求 producer 在未来仍保持 live lease；
producer 退休后不能反过来抹掉已捕获真值。新的 consumer 槽先初始化 pending/valid，绝不继承旧快照。

翻译/访存 fault 不产生成功值；consumer 等待或在 precise trap/recovery 时取消。
IO load 未满足原 head/order 条件前不发物理事务。
canonical completion/WB、recover 和不可取消事务排空不得以“等待消费者还没就绪”为前提。

### 4.5 观测与反证

实现/验证角色只需围绕该假设补最小分解：

- 每个提前 consumer 的 producer key、t0/t1/实际 RR admit/最终值捕获/Execute fire 或 cancel；
  只回传有界 histogram 与计数摘要，不交原始 trace 给 Architect。
- event 到最终值的提前量；consumer 已 birth 且其余源已真实齐备的比例；
  提前信用命中、信用满、错过公告后由 WB 补偿的次数。
- 提前 owner 的驻留分布、对普通 ready 指令造成的额外 RR 等待、实际 Execute 0/1/2、
  完整 cycles/commits；不能只看 IQ 发射率。
- 同父点 STA 中 raw request/response 是否又进入 IQ 选择或 shift D；
  当前最差链被切开不等于全核 setup/hold 已通过。

淘汰 P1 的证据：没有正的有效提前量；提前进入 RR 的消费者在完整关键链上不早执行；
整 lane 隔离使任一完整 workload 回退且没有事先明确的 P2a 位置迁移补偿证据；
或必须重接 raw ready/return 才能获得收益。
允许保留一次已声明的“安全隔离占用 lane1”中间态交给 P2a 验证；P2a 不兑现就回退这一支，
不事后无限增加补偿模块。

最小反例包括：

1. S→L→C→S 反例：先让 S 未 bind、L 翻译接受且等 S，再提前安置 C；
   之后 S 不得接受到 C 后，只能沿 lane0 完成 bind、解除 L 等待。另测 S 已在 lane1
   ingress/terminal/issue capsule 三处时，C 均被禁止准入；不能靠超时取消伪造进度。
2. 长 page walk/uncached/故意延迟响应后成功与 fault 两类终结：提前占用 ≤1，lane1 只有 C，
   older 正常指令、原 WB 与恢复仍前进；无限外部背压不被伪称为本地可保证有限完成。
3. load 后接长 ALU 依赖链：只预置一个 consumer，不递归填满 RR。
4. cancel + 延迟公告 + 相同 ROB slot/preg 复用；旧值不能进入新 consumer。
5. 同沿 WB 结束 producer lease、notice 到达、consumer 取消与 RR slot refill：
   无旧 pending、无重复执行，合法存活快照不丢失。
6. 双 lane 请求、丢失/重复 promise、丢失/重复公告：最终仍靠规范 WB 完成一次。

## 5. P2：位置、容量、带宽分别验证

### 5.1 三个独立子实验

P2a 只检验“P1 的提前等待有用，但为保证进度而独占 lane1 的成本抵消收益”。
需要 P1 的提前量和 lane1 隔离阻塞摘要支持；aggregate IQ block 或 ROB notdone 不足以启动盲扩。
如果值本身到得晚、没有可重叠工作，直接停止本方向。

| 子实验 | 固定父点 | 唯一被检验变化 | 保持项 |
| --- | --- | --- | --- |
| P2a：位置迁移 | 安全合同已成立的 P1 | 一个提前 owner 从 RR lane1 迁到独立等待槽，恢复普通 RR lane1 | 仍 1 个全局信用、单条登记入口、最多一项待值执行候选且只接 ALU lane1；同一 promise 条件、调度策略和值捕获边界 |
| P2b：容量 | 固定且单独测得的 P2a | 等待槽/全局信用 1→4 | 仍单 lane、每拍最多接受/读取/提出一项待值候选；同一份读副本与仲裁，不同时双 lane 化 |
| P2c：带宽，条件备选 | 固定且已证明容量有用的 P2b | 同样 4 项改为 2 lane×2 项，待值入口/读准备/候选最多两项/拍 | 不再增加容量，不改变 ROB/IQ/LSQ、WB 宽度、cache 或 promise 触发时点 |

P2b 需要 P2a 信用满且被拒的消费者存在可隐藏等待的证据；
P2c 需要 P2b 单入口/读准备/候选服务本身阻塞已可服务工作。
子实验分别取得 A/B，不将 1 信用单 lane 与 4 信用双 lane 的总差值称作“仅位置迁移”收益。
推荐核心轮次仍是 P1、P2a、P3，P2b/P2c 不因被定义就必须实施。

### 5.2 等待位置、读准备与归属

P2a 独立一槽保存 consumer 完整 tag、pending producer 身份、源 preg、源使用类型、
真实操作数/valid、必要 ALU 控制与生命周期元数据。它复用原 ROB/preg 身份，
不增加出生容量，且不占正常 RR 的 issue capsule、ingress、terminal 或其入口信用。
不能先在普通 RR 排队再等待搬进独立槽，否则重新引入 P1 的 S→L→C→S 风险。

P2a 采用独立的单条 issue capsule 和一份 64×64 bit、两读口 GPR 副本，
只从已登记 capsule 开始读操作数；保留 P1 的相应登记/读/值 Q 边界。
新增 4,096 bit 是数据存储量而非映射面积。
这份读资源是位置隔离所需的私有读准备，不提高一个待值 owner 的入口或出口宽度。
正常 RR 恢复原 4G/3F 读预算和六个保持位置。
P2b 仍使用这同一份读副本；只有 P2c 增加第二份并单独评价带宽及扇出成本。

副本只接收相同的两路 canonical authorized WB，x0、初始化、同沿写读优先级与原 PRF 一致；
没有第二份 busy、Rename map 或独立写回授权。
源真值公告/WB 按完整身份捕获；未决源不能从旧 PRF 解除。
站内合法快照保持到消费或取消；当前 IQ 选择不能穿透到读/shift。

### 5.3 执行与进度

P2a 仅单槽 `valid Q && all-values-ready Q` 才能向 ALU lane1 提出候选。
P2b 在四槽中选择已登记 ready 候选，未决槽不能挡住其他 ready 槽；
P2c 才变成每 lane 的两槽选择。所有模式都禁止 raw notice 参与本拍 select，
值至少经过本地 Q，shift 只由捕获的 B 值形成。

P2a/P2b 只在 ALU lane1 增加“正常 RR 或等待站”二选一，总待值执行最多一项/拍；
P2c 才在两个 ALU lane 分别二选一。全核总接受始终最多两个 ALU/拍。
候选未 fire 可重选，真正接受时 consumer/tag/操作数/控制一致；
本站只接受简单 ALU，MEM、branch、MDU、FP、Serial 保留原路径。

每个新增二选一采用登记的有界公平选择：双方持续可接受时，
四次实际可用 ALU 接受机会内双方均有服务。
预算只在可服务机会推进，不强行接受 FU 不 ready 的操作；
不新增跨 ROB 查询的全局年龄优先树。

站满只禁止新的提前等待准入，IQ 仍可向正常 RR 发射 ready 指令。
pending 站内 owner 不占普通 RR、canonical completion、WB、kill、translation drain 的入口或出口信用。
S→L→C→S 反例中 C 留独立站，S 可按原规则进入任一普通 RR lane，
不可能排在独立站的 C 后；生产者进度不依赖该站先空。
禁止递归 promise 的 P1 条件在所有子实验中保持。

reset/fullflush/本地 kill 抑制真实执行；旧 owner 先消费，同沿 refill 最后初始化新 owner；
一项最多一次真实离站。独立站 occupied owner 参与既有复用保护。
恢复或 WB 正常完成不等待独立站释放。

### 5.4 观测、反证与最小验证

P2a 观察同一 1 信用下 lane1 正常工作恢复后，consumer 执行、正常 ready 等待和完整 cycles 是否改善；
P2b 单独观察容量拒绝与相应关键等待是否下降；P2c 单独观察带宽服务等待是否下降。
每个子实验都报告实际 Execute，不能只用 IQ 空项增加证明成功。

不做无依据的 4/8/16 扫描。若独立站 pending 满且没有其他可执行工作，
说明受 producer 真值/依赖宽度限制，不继续扩容量或带宽。

最小反例：

- 对 P2a 重放 S→L→C→S：C 占独立槽，S 沿普通 RR 完成；站满不禁止 S 的 issue/bind；
- P2a 一个、P2b/P2c 四个 producer 长期未返回，另有老的 ALU/MEM/Serial：
  正常通道、规范完成和恢复均继续；
- P2b 老 pending + 年轻 ready，持续 RR ready + 待值 ready：无 head 阻塞且有界公平；
- 每个 issue capsule、读副本、值捕获、候选等待、fire 位置分别 cancel/flush 和复用；
- 两路 WB、同 preg 值冲突、WB/notice 同沿、x0、单拍公告错过：唯一授权事实不分歧；
- P2a/P2b 待值 fire ≤1，P2c 待值 fire ≤2，所有模式全核 fire ≤2、owner 只执行一次。

各子实验若只降低局部等待而 cycles 不改善，或形成新的长链，单独回退该子实验；
不能用后续扩容量/加宽掩盖位置迁移未兑现。P2a 不兑现时再决定是否同时回退 P1。

## 6. P3：同 bank 双读视图，保留真实 SRAM 和写维护

### 6.1 单假设与必要观测

此轮检验：两个已准备好的普通 load 常因 PA[3] 相同不能同拍接受，
而这类冲突影响完整程序关键完成或供给。

实施前由验证角色分开报告：

- 本来就符合现有 ordering/holder/slow-owner 条件的两个请求中，同 bank 冲突实际阻止接受的周期；
- 同一请求的 dirty write maintenance、miss owner、same-set exclusion、response backpressure；
- 两请求的命中情况、相关 consumer 是否在关键等待、bank 负载分布。

这些条件交叠时不能将同一周期同时计作每个候选的可恢复预算。
如果冲突量不显著，P3 本轮直接不选；至少三个实验已被定义，不意味着必须无依据运行所有硬件候选。

### 6.2 结构和周期

每 bank 对原两 way 数据建立 A/B 两份完整副本：
DCache 从 4 个 256×64 1RW 宏变成 8 个同类型真实宏；ICache 的两宏保持原合同。
逻辑容量仍为 8 KiB、2 way、64 sets、64 B line；不是把副本当成 16 KiB 容量。

每 bank 最多两个 lookup/response 位置，tag/valid 读视图同步扩展。
两路总输入和对 LSU 的总返回都仍不超过两项/拍，不把 4 个物理 lookup 位置宣称为四宽 CPU。
lane 与 bank 解耦，每个响应持有原 source/token/full-owner 路由信息。

两请求在同 bank 时分到 A/B，在异 bank 时各用一个视图；分配只用已登记信用。
clean hit 保留一拍同步读目标，II 在同 bank 双读场景由最多 1 请求/拍变成最多 2 请求/拍。
这是候选局部能力目标，实际能否保持一拍和 2 ns 需测量，不能从宏数量推出。

**写操作广播到全部副本的同一实际边沿。**
成功 B/refill 的逻辑写仍先进入原每 bank 两项 write-combine FIFO；
背景 drain 获得写授权时同时更新该 bank 的 A/B 同 key/mask/data，
不得一份已更新而另一份仍被当成最新可读。
广播写时两个 1RW 副本均不能同时执行新的读。

保持现有有界维护原则，但读额度按实际授予的 lookup 数计数：
两读同拍消耗两次读额度；有 dirty head 时，最多累计四次实际 lookup 授权后必须让 oldest 写入。
因而连续脏冲突时大致是“两拍各两读 + 至少一拍广播写”的服务形态，
不能宣称持续每拍两读再加一写。保持空闲读拍立即维护和 Q-only B 信用，不借同沿 drain 信用。

### 6.3 版本、归属与慢路径

每个 lookup 分别保存该接受边沿的 FIFO forwarding mask/data 快照；
同沿新逻辑写的新字节仍覆盖旧 FIFO 字节。
每份宏 Q 在可能被后台访问改变前，各自保存仍被持有的 lookup 结果。
副本不同地址的读 Q 不是同一个数据状态，不能共用一个 held-read snapshot。

成功 B 仍只为原 store owner 产生一次 mutation 与一个规范终端；
复制两份 SRAM 写不代表两个架构 store。
B error、poison、invalidate、reset、LR reservation、SC/AMO 排他性、source pin 与 forwarding winner 保持。
invalidate 同时作用所有 tag/valid 视图；FIFO 后续排空不得重新建立有效 line。

本轮不增加 MSHR、外部 outstanding、store B owner 或 commit store 数。
slow read/refill 与 B owner 的原 bank/set 排除规则先保留，避免同时扩大一致性范围。
请求和响应 lane 按 token 路由，不能假定 bank0 永远对应 load lane0。

**双 lookup 已接受但只有一个慢 owner 时，loser 不能沿用旧 miss/way/LRU 判断。**
两个请求各自的完整 descriptor/token 仍由对应 lookup 槽负责；
唯一慢 owner 获得 winner 的实际转交后，loser 进入 NEEDS_RECHECK，
占用原槽并背压该槽，不能丢弃、发第二个外部事务或要求上游重送。
winner 的 response/错误只属于 winner，不自动替 loser 产生完成。

首轮采用保守的每槽 fresh/check-valid，而非会回绕的有限版本号：
对尚未转交慢 owner、也尚未成为最终响应快照的 lookup，
其他事务的 tag/valid 发布、相关成功 B/refill 逻辑字节写、poison/invalidate
均撤销其 check-valid 并要求重查；同沿有这些实质变化时撤销优先于采用旧比较结果。

仅 LRU 替换次序变化不撤销合法 hit 的 tag/data 新鲜性。本批两个合法 hit 基于共同沿前
tag/valid 状态与各自数据快照认证；实际接受后才按 lane0→lane1 合并 LRU 更新，
该更新不能反向否定本批 hit，也不能使二者互相撤销。LRU 变化只使仍等待 slow owner 的
miss 替换决策失效，victim 在真正授予沿重新核对/选择。tag/data/invalidate 等实质变化
仍保留上述撤销/poison 优先级，不因这一 LRU 规则放行冲突请求。
已持有的合法 response 快照继续履行原 VALID/payload 保持与 poison 合同，
不能因为一个新 lookup 需要重查而撤回已发布响应。
refill 的 tag 发布只在原完整/有效条件满足时发生；仍在 FIFO 的新字节由重查时快照转发。

重查具有以下固定责任与转移：

| 状态/边沿 | loser 与唯一慢 owner 的合同 |
| --- | --- |
| NEEDS_RECHECK | 保留请求身份；旧 tag/way/data/LRU 结果不可用于返回或 miss 发射 |
| 真实 read grant | 占用对应 1RW 副本端口，重新捕获当次 tag/valid 与 FIFO/同沿新字节快照；原请求不再次计为接受 |
| 同步 read 返回 | 无并发失效事件才建立新的 check-valid；否则仍需重查 |
| 重查 hit | 按新鲜匹配捕获自己的最终响应；可以成为 winner refill 后的 hit，但不是复制 winner 的 response |
| 重查 miss、slow owner 忙 | 保持完整请求；后续 tag/LRU/字节变化再次撤销 fresh，不预先锁住未来替换 way |
| 重查 miss、slow owner 空闲且 fresh | 在唯一实际授予沿转交完整 owner；用此刻有效的 tag/LRU 状态选择/锁存替换；同沿失效事件则不授予 |
| 已转交后 | lookup 不能再发该请求；慢 owner 到真实终端完成保持该唯一归属；其原响应释放边界不提前 |

**DELIVER 的重读义务延伸到新增 retained lookup。**
winner 在 DELIVER 记录需刷新 lookup 的集合，对它们取得实际宏 read grant 并登记重查结果；
不得仅修改 valid/fresh 位就宣称已重读。
一个 loser 重查仍为 miss也能结束它对 winner 的“重读义务”，不要求它先取得慢 owner。
因此 winner 的退出不等待 loser 的慢事务完成，避免
“winner 等 loser 接管、loser 等 winner 释放”的环。
winner 的真实 response 信用/owner 释放仍遵循原合同；义务完成后 loser 留本地等待，
慢 owner 释放后才可能单独获授予。若又有使 fresh 失效的事件，loser 在获授予前重新检查。

重查使用与普通 lookup 相同的真实读仲裁和写维护额度，每个重查 read grant 同样消耗一次读额度；
达到四次后先广播 drain oldest，再继续读。
DELIVER 的 pending refresh 在下一个合法读机会优先于新 CPU lookup，
避免新双读流饿死它；该优先级不能越过必须执行的 dirty 写。
背景写前分别保护所有仍活跃的 held-read Q。
反复重查不重复做请求计数、架构 mutation 或 LRU access 更新；
真正成立的同沿双 hit 的 LRU 更新按入口 lane0→lane1 确定顺序。
上述 fresh/重读只对 cache 内部资格负责，不改 LSQ 的顺序与既有转发快照语义。

### 6.4 反证与验证

局部正向需要同时看到同 bank 双 hit 的真实 accept/return 两宽、不同地址正确、
同一地址两个独立 token 各返回一次，以及不改变单请求的数值/错误语义。
局部带宽改善后仍必须完整 CoreMark/Dhry A/B；若 cycles 无改善，不能以 microbenchmark 两倍带宽推广。

最小反例：

1. 同 bank 双读 + 同沿 B/refill 新字节 + partial mask：两者都观察各自逻辑读快照；
2. 两个 held lookup 期间后台写改变 macro Q：两个快照均不被污染；
3. 队满、head-key B、持续双读、refill 写竞争：bounded dirty fairness 和 terminal VALID 保持；
4. 两 miss 分别覆盖同 line、同 set 不同 tag、不同 set：winner refill 改变 tag/LRU 后 loser 必须真实重读；同 line 可变 hit，同 set 新替换不能沿用旧 way。winner 错误不复制给 loser，唯一慢 owner 无重叠授予；
5. loser 重查与 B 字节更新、invalidate、tag 发布同沿，以及 dirty FIFO 满、双响应背压和持续新双读：fresh 不误用，DELIVER 真实重读有限前进且不等待 loser 接管；
6. invalidate/poison、B error、LR/SC/AMO 穿插：无副本分歧、无重复 mutation 或提前副作用。

STA 须证明更多 tag/response 合并没有重新串到 IQ/RR；复用 timing 的公告 Q。
若实测大头是 dirty maintenance 或慢 owner，复制读视图的单假设被反证，
不能静默增加异步副本写传播或多 MSHR 来继续宣称同一个实验成功。

## 7. 与时序方案的组合、互斥及实验顺序

相关文档为 [时序架构多轮方案](timing-architecture-rounds-20261013.md)；
具体轮名以该文最终版为准。共同边界是：

1. 最终值公告整体登记，valid/tag/data 同龄，接收时完整身份认证；
2. issue capsule/source preg 登记后才做 PRF/operand/shift 准备；
3. 若继续拆 wake/select，只从 Q 调度资格选择；跨拍值需可靠留存或规范 WB 回退。

| 配合关系 | 可组合之处 | 不能混合或偷渡之处 |
| --- | --- | --- |
| 公告 Q × P1 | P1 让消费者在公告到达前进入等待，可能隐藏新增返回观察延迟 | 不能重新从 raw response 做同拍 select；promise 不能冒充真实值 |
| issue capsule × P1/P2 | 提前的源地址与控制有时间经过登记读准备 | 不允许以性能为由恢复当前 IQ→PRF→shift 直通 |
| Q-only wake/select × P2 | consumer 已驻留后，值到只更新本地 ready Q，下一拍选本站 | 不能让本站成为另一套 raw wake/select→ALU 链 |
| timing 的值 memo × P2 | 可共享一份“按完整 producer 身份关联的已捕获真值”设计 | 不并行做两套独立真源；WB lease 终结、同沿值捕获和 consumer 快照存续需统一 |
| 分布式 IQ/operand 队列 × P2 | 属于同一调度问题的替代实现方向 | 不在同一 A/B 同时加入，避免用两套容量/仲裁掩盖失败 |
| 公告 Q × P3 | 复制读带宽后仍经同一登记公告边界 | 缓存双读返回不能绕开该 Q 或增加全核发射宽度 |

推荐实验组织如下；每一行只增加一个被检验的架构假设，主 agent 可按新证据调整顺序，不需要人工重批。

| 次序 | 固定父点 → 候选 | 主要因果判断 |
| --- | --- | --- |
| S0 | R3/R4 原报告 + 当前同源补观测 | 补齐最低成本的 request/value/RR 等待分解；不声称新性能结果 |
| S1 | 时序侧最小登记公告边界，及其逐项 issue/read 切分 | 先量化具体切分成本与真实断链；这是后续性能补偿的固定父点 |
| P1 | 选定时序父点 → 仅提前 request promise | 是否存在有效提前量，是否改善 load consumer 的真实执行和完整 cycles |
| P2a | 固定安全 P1 → 1 信用、单 lane 的独立等待位置 | 只评价移除 P1 整 lane 隔离的收益；不混入扩容量/加宽 |
| P2b / P2c，条件备选 | P2a → 单 lane 1→4 信用；再由固定 P2b → 4 项双 lane | 容量与带宽分别有证据、分别 A/B，不能合并归因 |
| P3 | 已选定固定父点 → 仅 DCache 双读视图 | 在已观察同 bank 冲突时，实际双读是否进入程序关键收益 |

若 S1 一次包含多个 timing 机制，必须先保留时序方案自身的单项 A/B，
再固定其中一个已明确版本给 P1；不能把切分、P1、P2、P3 全部一起改完后反推各自贡献。
P3 可与 P1/P2 在独立候选 worktree 并行研究，但联合版本仍要重新取得同源完整结果。
采用哪个中间默认和正式 Architecture/Pareto promotion 是两件事。

## 8. 本轮不优先的扩展及原因

- **统一扩大 ROB/IQ/LSQ**：两个程序的阻塞分布不同；还没有 source-ready、真实 occupancy 和
  head-wait 相关性，扩大可能只拉长选择/取消/唤醒。先处理生命周期和等待位置。
- **翻译 token 4→8**：增加 holder 延迟不等于 4 token 已满。
  对无下游阻挡、每 lane 一请求/拍、固定 Bare 两拍的简化流，稳态在飞量约为两项；
  这只是 Little's-law 式架构推断，不覆盖 Sv39/walk/排空和当前实际实现全部边界。
  必须先看到 token-full 导致真实未接受且下游能够继续服务，才讨论扩深。
- **WB 两口直接扩四口**：WB backpressure 不是“两个额外口可消掉的周期”。
  原调度提示调整曾出现两个短程序收益相反；本轮没有各源 burst、head-critical 与端口瓶颈分解。
  保持双退休合同下，额外端口只能争取突发延迟收益，不能直接宣称退休吞吐翻倍。
- **多 MSHR / 更多 AXI outstanding**：现有唯一慢 owner 是已知结构限制，但 miss criticality、
  总线 ID/顺序/响应信用尚 UNKNOWN。需另立事务生命周期候选，包括 line 合并、same-set、
  refill/store/atomic、错误及取消 drain，不能作为 P3 隐藏附带项。
- **PMP 预授权/恢复 raw 保护直通**：可能改变配置采样时点或重新接上已切断长链，
  与当前目标冲突。本轮保留 R3。
- **预测器扩展**：历史热点和已有 1024 方向/128 FTB 不等于当前主要损失已证实。
  没有本轮正确匹配的预测/恢复统计前，不把增加预测表与 load-use 实验混在一起。
- **将 1RW 复制称为 1R1W**：副本每个边沿仍只能读或写；真实写广播会占用读机会。
  分时不同步副本将引入版本/选择/维护合同，属于另一个候选。

这些选择没有降低性能目标；它们限制每次实验的变量，使失败可以解释并回滚。

## 9. 最小验证计划与交付给独立评估者的 GAP

后续实现角色按每轮受影响合同运行对应 directed/module/域整合，
覆盖上文具体反例；没有改 checker 时不新增无关 checker 自证。
确定性同源 A/B 默认一次，只有噪声、随机、配置漂移或真实矛盾才扩展复验。
每轮报告应同时包含：

- 原 benchmark 输入、CoreMark 10/Dhrystone 10000、原 CRC/程序 oracle、
  commits、cycles、CPI；热窗口只证明对应局部能力；
- IQ 接受、真实 Execute、等待驻留及完整终态，确认不是把等待从 IQ 搬到 RR/新站；
- 当前保留的双发射、OoO、precise fault、取消排空与 side-effect 反例；
- 同 RTL/config、库、tool/version、corner、约束、clock-buffer 处理下的真实映射/STA，
  保持真实宏实例；setup、hold、pulse 分开，不以改善的一个端点替代全核检查；
- 已知与未测的功能范围。形成最终集成候选时，由主 agent 安排适用整体回归，
  不能把本文定向计划或既有 10+7 结果当成新实现的完整资格。

本文件没有要求本轮架构角色执行任何 EDA 或仿真，也没有把完整 promotion 流程引入普通架构设计。
新评估者重点应独立审查以下 GAP：

1. P1 的 translation accept→事件 Q→IQ Q 是否真正早于 consumer 最终值和登记读准备；
2. P1 整 lane 空闲准入/独占能否覆盖所有在途 owner并排除 S→L→C→S；P2a 保持 1 信用的独立位置及后续满站是否保留 producer/WB/recover/IO-order 进度；
3. 延迟公告的完整身份、WB 同沿 lease 终结、已捕获 consumer 快照和新 birth 能否一致处理；
4. P2 本地仲裁与读副本是否在不重建长链的情况下真的降低关键 consumer 延迟；
5. P3 的同 bank 冲突是否有程序因果证据；loser fresh/实际重查/慢 owner 转交与 DELIVER 义务是否闭合，副本快照和写广播是否遵守真实 1RW；
6. 两项完整 CPI 及 2 ns setup/hold 是否最终同时满足，而不是挑选不同父点的有利数值。

本轮结论是上述少量可比较架构候选与推荐实验顺序。**没有候选收益实测，
没有声称已经追回 R3 的 CPI 代价，也没有声称达到 500 MHz 或实际运行时间改善。**
