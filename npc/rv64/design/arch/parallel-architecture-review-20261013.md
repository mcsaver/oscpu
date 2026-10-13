# 2026-10-13 并行架构方案独立评估

状态：**独立架构评审完成，已复审原作者定向修订；认可下述条件和实验顺序，不是实现、功能、CPI 或 500 MHz PASS。**
实际 worktree：/home/lyg/PA/ysyx-workbench，分支 ai，已测实现基线 e44dac90b。
本评审使用全新上下文，只读规则、架构资料与精简事实；未读取 RTL/TB/网表/波形/原始日志，未执行仿真或 EDA。
唯一写入为本文；没有改动两份设计稿、生产实现或执行 Git 提交。

## 1. 评审对象与证据边界

评审对象为[时序方案](timing-architecture-rounds-20261013.md) T1/T2/T3 与[性能方案](performance-architecture-rounds-20261013.md) P1/P2/P3。
最终评审版本包含 T3 的 SourceBindingDirectory、P1 整 lane 独占、P2a/b/c 独立对照，以及 P3 重查与同批双 hit 的 LRU 澄清。
事实依据为[本轮精简事实](../../../../build/arch-parallel-20261013/architecture-facts.json)、[已测结果](../../../../build/ecos-opt-20261012/RESULT.md)、
[保护边界](memory-protection-boundary-20261012.md)、[公共协议](../../vsrc/PROTOCOLS.md)及 Backend/LSU 拓扑；不沿实现指针读取。
文档中的新增接口和方案目标不提升为当前实现事实；缺少的信息继续标为 UNKNOWN。

硬约束保持 ICS55+ECOS、TT 1.2 V/25°C、500 MHz/2 ns 与原约束，以及商业功能、双发射 OoO、precise trap、owner/取消、访存序和进度。
面积降为次要因素；更多状态不免除时钟负载、读写端口、最短路径和真实 SRAM 维护成本。

当前 buffered setup/hold WNS 为 **−3.226368427/−0.313464463 ns**，pulse/period slack 为 **+0.549876153/+0.408300072 ns**。
CoreMark10：4,223,831 cycles、3,218,537 commits；Dhry10000：5,792,104 cycles、4,260,629 commits。
当前仍为 pre-layout ideal-clock 结果，**500 MHz FAIL**；没有新实现数据，不预测 ns 收益，也不由 WNS 推算 Fmax。
当前最差链是返回资格→公告→认证→IQ 当拍选择→source preg→RR shift，未包含 SRAM read-data arc。
排序服从已确认的组合链和生命周期风险；aggregate blocker 百分比不能作为各候选可回收周期预算。

## 2. 六项最终裁决

| 候选 | 明确结论 | 依据、条件与优先级 |
| --- | --- | --- |
| T1 公告全包 Q | **推荐首轮** | 命中已测贯穿链；两路 non-owning 公告不改变规范完成 owner。身份重认证和丢公告回退已明确，适合最先检验实际断链与 CPI 代价。 |
| T2 issue capsule | **条件保留** | 可拆开选择与读值/shift；代价覆盖所有原 direct-admit ALU/MEM，不能只统计 load-use。T1 后新鲜路径仍支持时优先于 T3。 |
| T3 Q wake+memo | **条件保留** | 修订已补独立 producer 身份来源、逐源 expected key 和规范 PRF 写版本。接口、恢复与 birth 前递代价未验证；只有 load wake/select 仍限制周期时实施。 |
| P1 translation promise | **条件保留** | 修订用整 lane 空闲准入和独占排除等待环；更早事件并不保证有效提前量。lane0 必要操作可达及全部在途占用覆盖仍 UNKNOWN，必须实际证明。 |
| P2 独立待值站 | **条件保留** | P2a 单信用迁移先测隔离收益，P2b 再测容量，P2c 再测带宽；原归因混合已消除。只在 P1 提前有用且独占成本真实存在时推进。 |
| P3 同 bank 双读 | **暂不推荐首批** | loser 重查、唯一慢 owner、写副本及双 hit 规则已补齐；但没有 same-bank 关键冲突实测，且不直接切断当前最差链。取得针对性因果证据后可重新选择。 |

推荐顺序是 **T1 → 按新路径决定 T2/T3 → 在选定时序父点比较 P1/P2**；P3 排在有证据的 bank 冲突之后。
不要求叠满全部候选，不把“已定义三个实验”变成必须实施无证据结构的理由。

## 3. 正确性缺口与修订复审

### R1：P1 的队列等待环——设计层已排除，实现证明仍缺

原稿未排除：更老 store S 尚未 bind；年轻 load L 已 translation accept 但须等 S；
L 的 consumer C 成为 lane1 pending ALU head，S 随后进入同 lane并排在 C 后，形成 S→L→C→S。
已有 escape 不允许 MEM 越过 pending ALU；仅有 lane0 空闲不能救已经驻留 lane1 的 S。

修订要求 capsule/ingress/全部 terminal/已接受在途 owner 全空才能接纳 C，并在接受沿原子独占整个 lane1。
C 真正离开或取消前禁止任何其他 owner 进入；S 已驻留则 C 不准入，S 尚在 IQ 则必须走 lane0。
该合同排除了上述环，且没有削弱访存序或增添重发机制。
**lane0 能否承载所有必要操作、独占是否覆盖全部实际存储位置尚未验证，P1 不能据文档称 progress PASS。**
长 fault/pagewalk/IO/miss 时独占会减少正常双发射机会，须计入完整 CPI，不能只观察提前 consumer。

### R2：T3 的 producer 身份来源——设计层已闭环

原稿只明确 consumer tag/source preg，却要求 memo 消费时核对完整 producer，存在身份来源空缺。
修订增加由真实 writer birth 和实际授权 PRF 写入分别更新的版本投影；consumer birth 从重命名源绑定 expected key，
包含同沿 lane0 producer→lane1 consumer 前递，并把该键随 IQ→capsule→terminal/站保存。
memo 的身份与 consumer 期望身份独立产生；WB 后用当前分配版本、PRF 已写版本及唯一 Scoreboard canonical ready 回退。
fullflush 不抹掉 committed map 仍引用的 canonical 值版本；旧未捕获依赖与同 preg 复用不得共存。

这关闭“从 memo 内容反推自身正确身份”的缺口；目录不是第二份 busy/map/完成授权。
接口可用性、恢复投影、无悬空复用和 generation 回绕保护均是待实现证明，不凭 full-tag 位宽自动成立。
目录、双 birth 前递、恢复与多源读可能新增关键路径；T3 的成本不再仅是一个 64 项值数组。

### R3：P2 位置、容量、带宽混合——实验对照已修正

P2a 保持 P1 的 1 信用、单入口/单执行候选，只迁移到独立位置并恢复普通 RR lane1。
P2b 从固定 P2a 单独将信用/槽 1→4，保持单 lane与同一读副本；P2c 才在四槽不变时改为双 lane。
分别验证位置隔离、容量与带宽，不能把 P2c 对 P1 的总差值归因于单一因素。
P2a 的私有 capsule/读副本属于隔离结构，不能先占普通 RR 再等搬迁，否则会重新制造 R1。

### R4：P3 双 miss loser 与副本版本——设计层已闭环

已接受 loser 保留原 descriptor/token 并进入 NEEDS_RECHECK；旧 miss/way/LRU 不能直接用于新事务。
真实 read grant 后重新取得 tag/data/FIFO 快照；fresh miss 只在唯一慢 owner 真正空闲时转交。
DELIVER 重读义务覆盖新增保留槽，但不等待 loser 接管或完成；重查计入四次读额度并服从 dirty write，
同时在合法读机会优先于新 lookup，避免维护与重读相互等待。

最终局部修订区分实质 tag/data/invalidate 变化与纯 LRU 更新：
同批双 hit 按共同沿前快照认证，接受后合并 LRU，不能因彼此的 LRU 效果反向撤销；
仍等 slow owner 的 miss 在授予沿重核 victim。此澄清已实际复读，不以口头说明代替文档。
上述是候选合同闭环，不是 SRAM、返回保持或进度已验证。

## 4. 生命周期检查与最小反例

| 检查项 | 可接受合同及必须实际验证的边界 |
| --- | --- |
| 事件年龄 | T1 valid/tag/data 整体Q；P1 t0 accept、t1认证写promise Q、t2选择；P2从ready Q选择。invalid时不得恢复raw旁路，当前kill/birth不能与旧payload错配。 |
| full-tag/generation/reuse | T1消费处重认证；T3/P1/P2保存source身份。新增capsule/站owner进入reuse并集，转移无空窗，release可保守晚一拍；有限generation必须有旧观察状态失效证明。 |
| WB终结与新birth | 对旧consumer捕获匹配WB，再处理transfer/refill；新writer birth的busy优先于旧WB清busy，旧WB不得授权新版本。已捕获的合法consumer快照不因producer退休而消失。 |
| 单拍notice丢失 | ingress/CQ/WB独立完成。旧consumer、同沿新birth、未开始读的capsule分别靠WB捕获/history或canonical PRF回退；不得反复查询已覆盖history，不得等永不重发的公告。 |
| 等待站owner | IQ真实fire才转移且只保留一份调度owner；credit覆盖capsule及站内全部在途阶段。kill与transfer/refill同沿只终结旧owner一次，新owner重新初始化。 |
| fault/pagewalk/miss进度 | fault无成功值；consumer等precise trap取消；翻译/外部终端独立排空。P1检查S→L→C；P2满站不能占普通RR/WB/recovery/drain信用。有限完成以外部响应和服务机会为前提。 |
| 递归消费者 | P1与所有P2子实验都禁止未获真值的提前ALU继续发布issue-time promise；只能由真实登记结果/规范WB继续唤醒，不能把load请求扩散成任意长待值链。 |
| 本地公平 | 检查站内old pending/young ready、多个ready槽、普通RR与站持续ready；二选一公平预算只按真实ALU可服务机会推进。内部槽选择不得长期饿死同一个ready owner。 |
| GPR读副本 | P2a/b一份，P2c两份；只接同一canonical authorized GPR WB。检查x0、初始化、命名空间、双WB冲突、同沿读写、复用及每份副本一致性；没有副本busy。 |
| SRAM副本 | 全副本同沿广播写，每份仍1RW；每lookup独立forward/held快照。两个读消耗两份维护额度，后台写不能同时承诺两读；同line/同set双miss均需独立owner与fresh重查。 |

T3 memo 可以缓存已认证真值；其命中只允许携 pending 的提前调度，不能使 PRF 旧值可读或代替 Scoreboard。
memo 失效只丢提前机会，规范完成仍可靠；版本不一致须报合同失败，不能静默永久等待。
T2 的周期账至少分开原 direct-admit ALU、direct-admit MEM、原 ingress、branch/FP/第三源。
前两类最早准入目标多一拍，其余是否复用已有读阶段 UNKNOWN；独立流 II=1 不证明 RAW 不变。
历史“普通ALU RAW两拍”不能自动成为 T2 的新承诺。

## 5. 组合后的时序边界

- T1+P1：translation fire只到event Q，最终值只到notice Q；promise不证明成功、RAM或hit。
- T2+P1/P2：当前IQ source不驱动PRF/shift直达terminal；先捕获capsule/source Q。
- T3+P2：notice/memo只更新本地值/ready Q，不能解除本拍ALU选择资格；统一提前值缓存和consumer快照语义。
- P2信用不得由本拍Execute pop/WB/kill重新组合串回IQ或LSU；仲裁只接受同一登记owner的控制与数值。
- P3返回合并不绕过T1，写维护不重建lookup→B credit旧链；目录/多副本写扇出与新mux也必须进入真实STA。
- T2/T3与分布式operand调度C、P2与C先作替代对照，不同时叠加两套owner/值体系归因。

## 6. 可执行的联合实验顺序

以下是未来实现/验证角色的任务单，本轮不执行。每轮固定父点，保留失败结果，不要求全部条件候选必做。
共同保持完整CoreMark10/Dhry10000、程序oracle/CRC/真实DiffTest、同一生产配置/库/2ns约束与clock-buffer处理。
报告commits/cycles/CPI、真实Execute 0/1/2、相关驻留，以及全局setup/hold/pulse/period和目标路径迁移。
每轮运行对应最小定向反例；既有10+7结果不得复用为新候选功能证明，最终集成另补适用整体回归。

| 轮次 | 唯一主假设与对照 | 必要观测 | 淘汰/继续条件 |
| --- | --- | --- | --- |
| J1 | 当前已测点→仅T1：公告Q切断返回/调度串联 | raw→IQ/RR mapped锥；唯一notice丢失、WB/birth/kill交叉；完整CPI/STA | 未断锥、丢完成、两lane串行则修正或淘汰；路径迁移后再定下一刀，不声称2ns已过。 |
| J2 | 固定T1→仅T2：选择后读值/shift仍限制周期 | 各类direct/ingress延迟与占比、ALU RAW/MEM/branch、双发射II、capsule占用 | 广泛ALU/MEM代价且目标路径无收益则淘汰；不能只挑load局部收益。 |
| J3 | 固定T1+T2→T3完整身份闭环：load wake/select仍是限制 | Q资格、memo失效/WB回退、birth/恢复/多读路径迁移、完整CPI/STA | 新鲜瓶颈已无关则不做；第二busy、跨代值、规范回退不前进立即拒绝当前实现。 |
| J4 | 选定时序父点→修订P1，固定1信用：存在有效重叠窗口 | t0/promise/入RR/真值/Execute histogram；S→L→C、长fault/walk；lane1独占损失 | lane0可达或全在途隔离不成立则淘汰；无正提前量/关键Execute不早则不进P2补偿。 |
| J5 | 固定P1→P2a，仍1信用单lane：隔离等待位置有收益 | 相同提前consumer的值到达/执行、普通ready延迟、owner迁移、读副本、公平性 | 只使IQ更空、cycles不改善或新长链则回退；不以扩信用掩盖隔离无效。 |
| J6 | 固定P2a→P2b，仅单lane容量1→4：更多待值并发有收益 | 信用拒绝是否挡住有效提前机会、四槽pending/ready驻留、完整cycles | pending满且无重叠工作或完整cycles不改善则保留小信用，不盲扫容量。 |
| J7 | 固定P2b→P2c，仅四槽双lane：单入口/读/候选带宽是限制 | 已可服务工作被单lane挡住的周期、实际两候选服务、第二读副本扇出/STA | 没有带宽因果证据不做；完整cycles不改善或新长链则退回P2b。 |
| J8 | 固定已选父点→P3：same-bank端口冲突是关键可恢复等待 | 先分离maintenance/miss/order冲突；双hit真实2宽、loser重验、写广播/版本 | 无因果冲突不做；micro带宽提高但完整cycles不改善则不保留。 |

J1/J2/J3均可保留有依据的中间态；最佳父点不含T3时，P1/P2不必为了顺序补T3。
J5/J6/J7分别评价位置、容量、带宽；三者不能合并成一轮再倒推原因。
局部目标路径改善但全局瓶颈迁移，既非500MHz成功，也不能仅凭WNS未动否定已证明的断链。
同口径目标路径无改善且完整cycles更坏则受支配；工具失败/配置不匹配是证据GAP，不是机制被反证。
联合版本须重新取得同源整体证据，不能拼接不同父点的最好CPI与WNS。
ICache hold和时钟/物理收敛可由相应owner并行处理，新增流水不自动修好−0.313464463ns hold。
累计周期恢复目标为CoreMark≤4,016,641、Dhry≤5,691,655；满足此值仍不等于500MHz合格。

## 7. 最终结论与剩余阻断项

本次发现的等待环、producer身份来源、实验变量混合、双miss版本及双hit LRU自作用问题，均已在原作者文档中定向修订并复审。
**架构评审认可 T1 为首轮，其余按表中条件保留或延后；本次没有要求继续扩展设计的未关闭文字合同阻断。**
实现侧仍有实质 UNKNOWN：P1 lane0必要操作可达/完整独占，T3身份与恢复接口/代际保护，
单拍WB跨新增位置可靠捕获，P2公平与副本一致性，P3真实重查/维护进度，以及所有候选完整CPI/STA。
这些是后续可证伪实验的观测对象，不是新人工审批、全仓调查或重读已清理大网表的要求。
**架构评审通过不代表 RTL正确性通过、实测性能改善或500MHz/正式PPA资格；现有500MHz仍FAIL。**
