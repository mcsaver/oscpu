# Memory 时序边界候选与轮次（2026-10-13）

> 本文保留设计/评审时的候选状态；实际实施、保留点和测量结论见[多轮实测报告](memory-implementation-evaluation-20261013.md)。实现合同采用独立评审收紧后的版本，尤其保持原 allocating error/poison refill 的维护写规则。

状态：**架构候选，尚未实现、仿真、综合或 STA。** 本文由时序导向 CPU Architect 编写，供新上下文独立架构评估及主任务派发实现。只修改本文；不更新生产拓扑，不把候选写成现状。

## 1. 目标、父点与证据边界

实际工作树为 `/home/lyg/PA/ysyx-workbench`，本轮共同事实锚点是 T1 / `35a8a1d24`。保留 ICS55 + ECOS SRAM、TT 1.2 V / 25°C、500 MHz / 2 ns、0.05 ns uncertainty 和原输入/输出约束。双发射 OoO、ready/valid、完整身份、取消排空、precise trap、访存序和真实副作用不可退化。面积次要但实测；功耗 UNKNOWN。

当前 T1 的 setup / hold / pulse / period slack 为 −2.549148798 / −0.313464463 / +0.549876153 / +0.408300072 ns；flat buffered 面积为 2,415,687.980301 µm²。完整 CoreMark10 / Dhrystone10000 分别为 4,423,886 / 6,033,084 cycles，commits 为 3,218,537 / 4,260,629。500 MHz 仍 FAIL，原 ICache hold 是独立问题，本文候选不承诺修复它。pre-layout slack 不换算合格 Fmax。

输入限定为：

- [共同目标与父点](../../../../build/memory-rounds-20261013/architecture-brief.md)。
- [本轮共同实现事实](../../../../build/memory-rounds-20261013/memory-architecture-facts.md)：独立角色有界核实；本轮未新跑仿真或 EDA。
- [架构入口](../../ARCHITECTURE.md)、[公共协议](../../vsrc/PROTOCOLS.md)、[LSU 拓扑](../../vsrc/lsu/TOPOLOGY.md)、[翻译/保护拓扑](../../vsrc/memory/TOPOLOGY.md)：协议与结构背景；历史段落不覆盖共同事实。
- [上一轮实测架构裁决](../../../../build/arch-impl-20261013/measured-architecture-review.md)：T1 保留、T2-min 未选为默认及比较限制。

Architect 未读取 RTL、TB、网表、波形或原始实现日志，没有沿事实稿的源码指针打开实现。下文周期关系中，现状来自共同事实；新结构的周期、收益及路径迁移均是待验证预测。

可观察 acceptance criteria 是：受影响 owner/字节/顺序/进度合同成立；目标组合依赖确实改变且新路径被报告；原条件下真实 STA 与完整 workload 可比较。方案成稿只完成架构交付，不能代替上述实现结果或正式 promotion。

## 2. 关键链与两种不同的切法

共同事实中的已映射路径为：

`reset → 保护响应 valid → 当前成功翻译响应选择 → Split aligned flow → Service read empty flow → bank1 lookup/read grant → bank1 live write-ready → 公共 R ready/fire → bank0 refill 写 → bank0 overlay 捕获`。

保护 payload 已经经过 Q。残余路径涉及当前有效性及后续选择，不能把 Protection 的已关闭 EMPTY_FLOW 再当新实验。bank1 信用被选择要求 beat bank=1，bank0 refill 写要求 beat bank=0；这一局部互斥解释了重汇合，但整体敏化性仍 UNKNOWN。不得设置 false path、取消 reset 输入约束，或据无效 payload 声称没有时序问题。

本文保留两个主候选：

| 候选 | 主要变量 | 结构目标 | 新增资源与周期 | 首要代价假设 |
| --- | --- | --- | --- | --- |
| **M-R：正确 R-key 的 Q-state 容量查询** | 只改变 refill 逻辑写信用的依据；保留真实 read grant | 从 R 容量许可中移除当前 lookup → drain → live write-ready 依赖 | 不增加 beat holder、FIFO 深度或固定 hit 流水级；仍用每 bank 两槽 FIFO | 部分 head 同键合并不能立即接受，可能增加 refill 等待 |
| **M-S：Service 普通 read 结束空流** | 只将生产 Service 的 CPU_READ_EMPTY_FLOW 置 0 | incoming read descriptor 先进入现有请求 Q | 不增加存储；原空流 read 的 Service 接受到 cache 接受通常 +1 拍 | 暴露的 load-use 延迟、顺序 Split 子读及排队可能增加完整周期 |

M-R 是信用依赖的切分，不是给 R beat 再寄存一拍；M-S 是请求生命周期中已有 Q 成为强制边界。二者的因果链和成本不同，不在首轮同时修改。

建议先从 T1 比较 M-R：它直接针对 bank lookup → refill 信用链且没有固定 hit 加拍。若真实映射/STA 没有进展，回到 T1 比较 M-S；若 M-R 有实测进展而新 worst 仍由当前请求跨越 Service，可在保留的 M-R 上再比较 M-S。这个次序是当前证据下的建议，不是固定必须做完的清单。每轮都报告相对直接父点及 T1 的累计变化，不能拼接不同父点的最好指标。

## 3. 共同 owner 与恢复合同

多个 holder 表示同一 LSQ transaction 的不同阶段，不能把各队列槽数相加成独立架构 owner 数。区分 canonical 指令身份、物理传输保管责任和缓存字节维护责任：

| 阶段 | 唯一负责的状态及转移事件 | 取消、不可逆与释放 |
| --- | --- | --- |
| CPU 尚未获物理接受 | LSU canonical row 持有完整 tag/slot、顺序和副作用授权；prepared mirror 只是可覆盖的数据准备 | kill 可阻止尚未接受的发布。mirror 不占请求信用，不算新 owner |
| CPU/Split → Service 实际 fire | Service 的原队列或实际 cache 接受点保管同一物理请求；LSU 登记 mem-issued/effect，并保留返回所需身份 | 即使只进 Service Q，后面也没有 kill/flush 取消通路。不能因 flush 清队列，不能提前复用 LSQ 行 |
| Service → DCache 实际 fire | 只转移一次 transport 保管责任；source+token、地址、操作、数据/字节信息使用同一个获准来源 | CPU/PTW 配对变化不得重标记旧项；aux busy 持续到其返回被客户端接受 |
| DCache → AXI / R、B 接受 | 原 lookup、slow refill owner、独立 store B owner 和终端 holder 维持身份；真实通道 fire 唯一建立相应事实 | 不可撤销 AXI 必须 drain；AW/W、准备或 FIFO 信用不代表成功 B，不提前完成 store |
| 已接受缓存逻辑写 → FIFO → SRAM | FIFO 持有已接受字节及目标 key；后台 drain 完成真实 1RW 写 | invalidate/poison 不得使已接受事务消失或重新建立非法 valid；reset 保持原系统协调合同 |

共同冲突规则：

1. 旧已占用请求优先；只有真实 admission/fire 才建立或转移 owner，request hint 和 payload 预写不建立 owner。
2. 未取得 head/effect 资格的 store、IO、LR/SC、AMO、CAS 不因新增边界提前发出。特殊访问、fault、A/D 和非对齐规则保持。
3. 同 bank B/R 逻辑写冲突沿用**实际 B fire 优先**；仅 B valid 且被阻塞不能占住 R。不同 bank 合法并行保持。
4. 一次 accepted write 只形成一次字节更新、mutation 与终端事实。leaf 不得在调用方已接受后再用 live ready 拒绝它。
5. 当前 reset/cancel/invalidate 的资格抑制不被改作数据清零或全宽选择捷径。invalid 宽 payload 可以残留，但不能形成有效 owner、有效字节或副作用；准备内容与有效性必须同龄。

## 4. M-R：R 使用自身 key 的保守容量信用

### 4.1 结构与精确范围

当前 B 已有 Q-only store probe，查询的是 B owner 的 way/index；R 需要的是唯一 slow refill owner 所属 way/fill-index。两个 key 可能不同，现有 B-credit 数值不能服务 R。

候选新增或复用**独立的 R-key 查询能力**，对正确目标 bank 的 FIFO 旧 Q 状态判断容量。这里“Q-state”指信用不依赖本拍 lookup、read grant、drain 或借本拍释放的槽；不是把一个 ready 位延迟一拍。若实现将信用位寄存而没有同时保留 slot/key 所有权，会产生陈旧信用，违反本文合同。

R 查询键必须对应本次实际可接受 beat：

- bank、way、index 由原 refill owner 与本次 beat 的既定位置确定；不能来自 B mirror、当前 CPU 请求或未获接受的下一 beat。
- beat 背压时，位置和完整响应 metadata 保持，不能让查询键先行推进；只有原真实接受事件推进 beat 生命周期。
- worker 需核对实际键的生产者和保持边界。若某键不由现有 owner/beat 状态提供，不能悄悄新增预授予状态；必要伴随改动及其等待语义须明确回传。

每 bank 的容量判定采用旧 FIFO 状态：

| 与 R-key 的关系 | 本轮信用 |
| --- | --- |
| 与已占用 head 同 key | 拒绝，包括另一槽为空的情况，避免重复 key 与 head 修改 |
| 与已占用非 head 槽同 key | 允许按原 byte-mask 合并，新接受字节优先 |
| 没有同 key，且旧 Q 有真实空槽 | 允许分配一个槽 |
| 没有同 key，旧 Q 已满 | 拒绝，不借同沿 drain |

这只是逻辑写容量。必须继续组合原 REFILL/allocate/reset、响应身份、错误/poison/invalidate、B 同 bank 优先及其它合法资格；不能用容量查询代替 SRAM read-ready、单端口仲裁或有效 beat 判定。

以抽象事件表示：R 的实际通道接受仍由原 valid/ready fire 定义；每 bank 的有效 refill mutation 必须恰好等于“真实 R fire 且本 beat 合法向该 bank 写入”。需要排空而不写缓存的错误或 poison beat 继续按原条件接受，不能因为不存在可写 FIFO 槽而新增不必要等待，也不能误把它们分配成 FIFO owner。

### 4.2 容量、II 与周期

每 bank 仍为两槽；全局仍为一个 slow refill owner。新增查询口不增加独立 miss 容量、不增加 R beat 缓冲，也不提供额外 SRAM 写端口。

该改变不固定增加命中请求或响应流水级。无冲突且有旧 Q 信用的 beat 可以沿原周期接受。但原实现允许“同 head key、当前 lookup 阻止 drain”时继续合并，候选保守拒绝这种情况。因而 refill 接受 II 是工况相关的，不能承诺所有持续 refill 均 II=1；也不能从两槽容量推断两写/拍。

head 被禁止合并后必须通过原真实 drain 取得进度。保留每 bank 最多连续四次真实 lookup 后为 oldest drain 的规则；新 R 等待不得重置额度、取消 drain，或要求“先接受这个 R 才允许释放它正在等待的 head”。tail 合并与 old head drain 同沿时，以同一个旧 Q 状态分配/合并；晋升后的 head 从新边沿起冻结。

### 4.3 路径变化、失效条件与收益假设

因果链为：R 容量只看 FIFO Q 与正确 R-key → lookup/read grant 不再决定 R 信用 → 当前 request 经 bank1 lookup 到公共 refill 接受的那一段应消失或显著缩短。

可能的新 worst 包括 refill key 比较 → R ready、B 实际接受/终端信用 → 同 bank R 排除、FIFO Q → overlay 选择，以及上游 descriptor → bank 本地 lookup。公共 bank 选择和窄 reset 资格仍存在；不声称整个跨 bank 组合图为零。

若以下任一情况出现，不能按原方案保留：

- B-key 与 R-key 混用、已接受写被 leaf 二次拒绝、重复 key、byte 不一致或不可逆 owner 遗失；
- 当前 lookup/drain 仍进入 R 容量许可，实际映射未实现宣称的断链；
- 有持续可服务的 FIFO drain 却因新增 R/B 等待环无法前进；
- 同口径全局/目标 timing 无进展而完整周期增加。

若目标锥确已改变但全局 worst 转移，报告目标域与新 worst 的真实数值再选择下一轮；局部结构成立本身不等于 500 MHz 进展。若 setup 改善且 CPI 退步，作为实际 tradeoff 记录，下一步必须解释尚缺的收敛收益，不能凭“以后可能有用”自动设为默认。

## 5. M-S：复用 Service 请求 Q，结束普通 read 空流

### 5.1 单变量实现合同

只把 PhysicalMemory 对现有 Service `CPU_READ_EMPTY_FLOW` 的生产实参改为 0；不改变 LSU `TRANSLATION_QUERY_BYPASS`、EARLY_STORE、CPU_PREPARE_HINTS、CPU/PTW 仲裁、lane 配对、队列深度或 cache 返回空流。

凡原来满足 read empty-flow 的 CPU cached-read，先按原获准来源完整进入既有请求 Q。cache 阻塞时的保存路径继续使用原 Q；关闭空流后不再存在“同一请求既入 Q 又被 cache 直接接受”的双 owner。原 read 分类保持，适用的 Split 子请求也不能被漏掉；aux、store、atomic、NC 原分类不得因简化表达而变成普通 read。

Q 内包包含实际物理来源和 token，以及完整地址、操作/属性、字节/数据等字段。prepared mirror 的身份匹配不能代替本次请求的真实身份；配对时必须捕获实际获准的 CPU lane 或 aux 来源，不能固定取 CPU0。

Service admission 仍只看旧 Q 容量。没有新完成信用，也不把下游 cache-ready 组合借给满队列。当前请求选择可以影响新 Q 的 D，但不得穿过关闭的 read 数据旁路成为本拍 cache descriptor。

### 5.2 周期和队列关系

以 E0 表示 CPU→Service 接受边沿，并固定相同仲裁、无背压、队列原空：

| 事件 | T1 read empty-flow | M-S |
| --- | --- | --- |
| E0 | Service 和 cache 可同沿接受同一包，队列无驻留副本 | Service 完整捕获原 Q，cache 本沿不接受这个新包 |
| E1 | 已在 cache 的请求按原后继推进 | cache 最早接受 Q 中该包 |
| 持续独立流 | 受两 bank、下游和配对限制 | 队列旧占用为一项时可同沿出旧进新，每 physical lane 可 II=1 |
| 满两槽后的第一拍 pop | admission 不借本沿释放 | 同样不借；空位下一拍可见，恢复处有输入气泡 |

因此“空载延迟 +1”与“条件下稳态 II=1”同时成立，不应以满后一次气泡宣称稳态 II=2。最大两请求/拍依赖异 bank 与原仲裁资格；它不是任意 CPU/PTW、same-bank 或写组合的保证。Split 单慢 owner 的逐字节 SEND/WAIT 可能为每个适用子读支付等待，不能只测对齐双读就解释所有程序。

M-S 不改变 CPU→Service 实际 fire 作为不可取消边界：被取消的请求即使只在 Q，也必须继续完成物理返回，LSU 只丢弃死亡指令的架构结果。Q 不可因 ROB kill、flush 或错误猜测直接清掉。两个 aux 返回 holder 与 busy 生命周期保持原状。

### 5.3 invalid payload、残余 prepared 路径和下一小步

共同事实确认关闭 read flow 后，普通 read payload 包括 invalid 周期均取既有 queue Q。但 lane0 还可以由当前 identity/op/cache/fast-store/仲裁选择另一个已寄存的 prepared payload，valid 也可能来自当前 CPU valid。

因此首轮 claim 仅为“incoming read 数据分支不再直接驱动 cache”；不能写成“所有 Service current 控制均已断开”。映射检查须分别观察普通 read 分支与残余 prepared 选择，不用只检查若干 payload bit 冒充整个输出边界。

**M-SP 是条件续轮，不与 M-S 首轮合并：**若 M-S 的新关键路径仍穿过 prepared 选择，再只将 Service 的 `CPU_PREPARE_HINTS` 关闭。真实 store 按原 CPU 请求及授权入现有 Q；不关闭上游 EARLY_STORE，不改副作用授权和 B 完成。prepared mirror 可失去快速用途，但不会因此成为 pending owner。

M-SP 不扩容，原可由 mirror 直接接受的空队列 store 至少多一个 Service→cache 等待边界。read 和 prepared 两项空流都关闭后，目标是 cache 宽 descriptor 仅从原请求 Q 及其 Q 状态选择，包括 invalid 周期；当前 CPU 身份/操作/仲裁只影响新 Q 捕获。窄 reset/原有效资格仍按系统合同处理，不据此承诺所有 reset→cache D 路径消失。最终 Q 来源及剩余组合依赖由 mapped 结果核实。

若 M-S 没有时序收益却增加周期，不默认继续叠 M-SP；只有明确残余 prepared 锥的证据才支持这个续轮。M-SP 的 store 延迟和并发成本单独计量。

## 6. 最小反例与验证计划

下表交由实现/验证角色执行。既有测试源码中存在检查，不等于本轮已 PASS；新增定向激励只覆盖现有 oracle 的真实空缺，不新建全仓验证框架。

| 候选/边界 | 最小有区分力的反例 | 所需观测与既有验证面 |
| --- | --- | --- |
| M-R 正确键 | B-key 可合并而 R-key 命中冻结 head/无槽；再交换两个 key，使 R 合法而 B 阻塞 | 同一个实际 R-key 上验证 query⇒已接受写有落点；不能只沿用 B 同键测试。扩展现有 leaf probe/byte oracle |
| M-R 公平与互斥 | hot lookup 持续、head-key R、被阻塞 B、满 FIFO；同 bank 与异 bank R/B | 四次真实 read 额度不被新 R 重置，必要 drain 发生；B valid 未 fire 不阻塞 R；真实接受计数与 mutation 一一对应 |
| M-R 字节/终端 | accepted R 与 B 的不同 key/byte mask，held lookup、错误/poison/invalidate、最后 beat 背压 | 使用原独立逐 byte 和 held-result oracle；合法同拍 forwarding 的前件要有非零观测，不能借未打印 pending_hits 的 PASS 推断覆盖 |
| M-S Q 与 II | 空队列双 lane、旧 head 优先、满两槽且本沿 pop、cache 连续背压后恢复、aux 配对选 CPU1 | 现有 Service EMPTY_FLOW A/B 及真实 cache/PTE integration；对相同 token 记录 admission/cache edge、接受/返回数、payload 稳定和持续流 |
| M-S owner 与恢复 | 入 Service Q 后 kill/flush，后续 response；source/token 复用企图；Split 子读错误 | LSU 原 owner/reuse、Service 返回与 misaligned 生命周期相关用例；确认原 mem-issued 保留及死亡事务 drain |
| 条件 M-SP | mirror 身份过期/新 tag 同槽、准备项替换、store 入 Q 后背压、真实 B error/held terminal | prepared-reuse 与 Service/cache store 合同；确认真实请求授权一次、没有早 B/重复 mutation |

需要组合场景时优先复用共同事实中 `tb_r64_service_read_empty`、`tb_r64_service_read_cache`、`tb_r64_dcache_ecos_data`、`tb_r64_dcache_detached_store` 等已有 oracle；具体命令与适用参数由实现角色选择。对于协议根本不允许同拍发生的情形，返回局部不可能条件并采用合法对照，不能伪造 coverage。

每个实际候选另完成：

- 与其修改直接相关的编译/lint、边界动态验证和必要断言；涉及的系统 DiffTest 场景保持原真实 oracle，并运行当前 10 场景集合和七个双发射热窗以保持对照边界。
- 相同完整 CoreMark10、Dhrystone10000；保留 commits、cycles、原 DiffTest/断言及正常终态。热窗 CPI=0.5 只证明对应独立流能力，不证明 load-use 或全核 CPI。
- 同配置 raw 与 clock-buffer 的真实映射/STA，分别比较 setup/hold/pulse/period 与 flat 面积，保持四个 DCache 和两个 ICache 真实 SRAM 宏。新 worst、目标路径群最坏值及结构切分均提供精简摘要。
- M-R 检查 lookup/drain→R 容量许可的保守组合依赖及实际消费；M-S 检查关闭分支、现有 queue FF 后的实际 cache 消费和残余 prepared 控制。边界不能因目标集合为空、无用 Q 或综合删掉消费者而假 PASS。

动态 PASS 不证明 ns，图上断链不证明全局 WNS，STA 不证明精确异常或 owner 生命周期。新的 hold 违例、宏替换或约束漂移都必须单独报告。原 ICache hold 未闭合时仍不得宣称 500 MHz 合格。

## 7. CPI 预测、观测与轮次停止

当前 workload 的空流比例、暴露依赖、R head 合并损失率均 UNKNOWN，不能给出可信的百分比或 ns 预测。可以提出可反证的方向：

- M-R 的空 FIFO、非 head 合并与 clean hit 不应固定加拍；若完整周期增加，应先核对 R head-key 拒绝、真实 drain 等待以及 B/R 冲突是否增加。若周期增加来自其它路径，原归因被反证。
- M-S 对原空流请求的 cache 最早接受多一个边沿；已经排队的请求不必再多一拍。第一阶模型可用“原空流次数 × 新增局部边沿 × 暴露比例”，但它不是整核周期上界：调度、branch timing、PTW 和 Split 串行化会改变暴露与重叠。
- M-SP 的首要成本在 prepared 命中 store 的 cache 接受与后续 B/退休等待；不能把 read 指标变化当其唯一成本。
- 完整 CPI 使用各 workload 的实际 commits 作分母。现有 observer 非互斥；等待项只能帮助区分解释，不能相加制造周期分解。

只采与因果链直接相关的窄观测：请求 admission/cache edge、empty-flow 适用次数、队列旧占用导致的拒绝、R 因 head-key/满槽/B 实际冲突等待、实际 read/drain/R/B 接受和返回计数。必要时区分等待重叠，不能用新增 profile 修改工作负载或放宽 checker。

任何 correctness 反例首先修复或撤销对应候选，不带失败继续叠下一架构变化。功能保持但没有目标/全局时序收益且 CPI 更差时，默认回到直接父点；真实面积收益可保留实验记录，但不因此优先于本轮时序/CPI 目标。若收益只在局部路径群而全局仍被别处限制，先判断下一瓶颈及剩余预算，不机械叠加全部候选。

最终由主任务把同一共同事实与本文候选合同交给新的独立架构评估；重点复核 R 键的生命周期、stale credit、B/R 等待环、物理接受后的不可取消性、prepared 残余路径，以及容量/II/延迟的区别。用户已授权端到端多轮优化，修订明确后可直接派 worker 实现并测量，无需新增人工审批。
