# Memory 性能导向有界实验设计（2026-10-13）

> 本文保留设计/评审时的候选状态；实际实施、保留点和测量结论见[多轮实测报告](memory-implementation-evaluation-20261013.md)。实现合同采用独立评审收紧后的版本，尤其保持原 allocating error/poison refill 的维护写规则。

状态：候选合同，尚未实现或测量。只设计两个可区分的切片；本稿不改变生产拓扑，也不声称 CPI、timing 或功耗已改善。

## 1. 目标、父点与事实边界

工作树为 `/home/lyg/PA/ysyx-workbench`，共同父点为 T1（起点 HEAD `35a8a1d24`）。
目标保持 ICS55 + ECOS SRAM、TT 1.2 V / 25°C、500 MHz / 2 ns 和原 0.05 ns uncertainty；
面积次要但同口径测量。完整身份、取消排空、精确异常、访存序、真实副作用、双发射和进度不退化。

共同输入为 [architecture-brief](../../../../build/memory-rounds-20261013/architecture-brief.md) 与
[实现事实摘要](../../../../build/memory-rounds-20261013/memory-architecture-facts.md)；
后者来自独立取证，已区分源码事实、已有测量和 UNKNOWN。本角色只读这些摘要及
[公共协议](../../vsrc/PROTOCOLS.md)、[LSU 拓扑](../../vsrc/lsu/TOPOLOGY.md)、
[架构入口](../../ARCHITECTURE.md)，未沿实现指针读取 RTL、TB、网表或原始日志。

T1 完整 CoreMark10 为 4,423,886 cycles / 3,218,537 commits；
Dhrystone10000 为 6,033,084 / 4,260,629。系统 10/10、双发射 7 个 CPI=0.5 热窗口通过。
同口径 buffered setup / hold 为 −2.549148798 / −0.313464463 ns，
pulse / period 为 +0.549876153 / +0.408300072 ns，flat area 为 2,415,687.980301 µm²。
这是已测父点，500 MHz 仍 FAIL；不能把 pre-layout slack 换成合格 Fmax。

当前保存的结构时序链穿过普通 read 空流、bank1 的 lookup/drain/live write-ready、
公共 refill fire，抵达 bank0 overlay 捕获。局部 refill bank 选择互斥，
整条路径可敏化性 UNKNOWN；不得据此加 false path，也不得更改 reset 或原 SDC。
ICache hold 问题独立存在，本稿候选不承诺修复。

## 2. 性能选择：先解除 R 信用对当前读授权的依赖，再按残余路径决定 read 边界

| 候选 | 主要变量与资源变化 | 延迟、II 和代价假设 | 选择理由 |
| --- | --- | --- | --- |
| **R（M-R）：refill 按自身键使用 Q-state 写信用** | 改变 R 写容量判据；不增加 FIFO、refill owner 或 R 管线级 | 不固定增加 CPU clean-hit 延迟；放弃 head-key 即时合并，可能增加 refill 停顿，实际 R II 与全核 CPI 待测 | 针对公共 refill 的跨 bank 反馈，性能成本局限于具体 FIFO 冲突状态，推荐先试 |
| **S（M-S）：关闭 Service 普通 read 空流** | 生产 `CPU_READ_EMPTY_FLOW=0`；复用每 lane 两个原请求槽 | 原本空流成功的普通 cached CPU read 到 Cache 接受新增一拍；无阻挡稳态仍 II=1/lane；满两槽不借同拍 pop | 已有参数、边界明确；若 R 后仍有主导的当前 read→Cache 路径，则用这一拍换真正 read payload 边界 |

这是性能导向的顺序建议。新的独立架构评估可结合时序稿选择先 S 的诊断价值，
但必须记录实际父点；不得把两稿不同父点的最好 CPI/slack 拼成组合收益。
本轮不同时关闭 LSU 的 `TRANSLATION_QUERY_BYPASS`，不关闭 prepared store mirror，
不增 query/Service/FIFO 深度，不把 Split 慢 owner 改作全流寄存级。

“没有固定加拍”仅描述结构；R 可能因背压增加程序周期。
“II=1/lane”仅描述 S 的可用稳定流；CPU/PTW 仲裁、同 bank 配对和返回拥塞仍会降低实际吞吐。
两个候选都没有足够证据预测全核 CPI 百分比。

## 3. 共同 owner 与实际接受合同

必须分清三个事件：

1. 准备：prepared mirror 或无效槽预写只复制 payload；不创建 owner、请求容量、完成信用或副作用许可。
2. LSU→Physical/Service 实际 fire：成为不可取消的物理请求；副作用请求先满足原 head/effect 资格，
   普通 load 保留原可投机接受资格。此时可能仅进 Service Q，LSU 仍按原类型登记 mem-issued/effect，
   并保持原 LSQ 身份到返回排空。
3. Service→DCache、R/B channel 各自的实际 fire：分别转移请求持有责任或接受外部结果，
   不能由上游入队、permit、AXI AW/W 或 ready 单独冒充。

Service 两槽、query 两槽、physical holder 和 Cache stage 是同一事务的流水表示，
不能相加声称新增独立 LSQ owner 容量。CPU 槽位与完整 tag 的复用受原在飞事实约束；
Service 的 source+opaque token 仅用于回包，不能自行推断 ROB 年龄。

物理接受前仍执行原取消和授权；接受后即使 LSQ owner 死亡也不得撤销 Service/Cache/AXI 事务。
返回按原完整身份只 drain 一次，不能复活活完成。已授权副作用及真实 B 错误走原精确终端；
prepared mirror 匹配不等于副作用获准。invalidate/poison 不撤销外部事务；
reset 仍遵守本地和外部服务的既有共同 reset 合同。

## 4. 候选 R：不给 refill 使用 B owner 的信用

### 4.1 查询、许可和消费

R 写容量查询必须使用**本次 slow refill owner 的真实 R 键**：
`{bank, way, fill-index}`。现有 store probe 查询 B owner 的键，其返回数值不能复用给 R。
本候选要求 R 的 key/owner 来自既有驻留 refill 状态；若实现侧发现某字段受当前未接受请求选择，
应回报并修订合同，不能暗中加 descriptor stage 后仍归为同一实验。

每 bank 仍只有原两个维护槽。对正确 R 键，Q-state 许可规则为：

- 有匹配 head：不给 R 合并许可，即使另一槽空闲也不能建立重复 key。
- 无匹配 head、匹配 tail：允许按原新字节覆盖旧字节规则合并。
- 无匹配 key、存在旧 Q 空槽：允许分配。
- 其余拒绝；不借本拍 drain 释放的空间，不因本拍 lookup/read grant 改变许可。

许可是**本拍对旧状态的容量判断**，不是登记预约，不占 FIFO，也不创建 R owner。
实际容量消费仍只在原 REFILL/allocate/reset 等资格满足且真实 R fire 时发生。
R 未 fire 时，slow owner 的 beat/key 不推进，输入 payload 遵守原背压稳定合同。
不能把前一拍的 permit 直接寄存后无保留地兑现，否则 B/drain/合并可改变其落点。

同 bank 的真实 B fire 继续优先，阻止竞争同一写入口的 R fire；
只有 B valid 而未 fire 不应凭空阻挡原本可接受的 R。
不同 bank 保持原本可行的并行写，不能为了简化信用把两 bank 锁成全局单写。
B 保持 B-key Q probe、原终端信用、真实 B 一次 mutation 和精确响应。
R 已被上层接受后，leaf 必须接住该逻辑写；不能再以 live ready 撤销它。

### 4.2 数据版本、恢复和端口资源

真实单端口宏的 read grant、最多连续四个 read 后 drain 的公平性、held lookup 结果、
lookup launch 时 FIFO 字节快照及同拍已接受新写字节优先均保持原合同。
Q-state R 信用不能代替 SRAM 单端口授权，也不能跳过维护写。
同 key 部分 mask 合并、同拍 overlay、新字节覆盖顺序仍由实际写事件决定，
不得在只有 permit 或无效 R payload 时更新有效字节。

只有既有需要缓存逻辑写的 refill 子路径使用该容量查询；
error、poison、非 allocate、invalidate 与终端处理保持原规则，不能为无需写入的返回新建等待条件。
invalidate 后维护队列继续排空但不能重建 valid；已接受外部 R/B 不因本地失效丢失终端。

### 4.3 有界收益假设与反证

因果链是：R 信用只读自身键和维护槽 Q → 当前 lookup/drain 不再控制该 R 写容量 →
目标 bank1 live-ready→公共 R fire→bank0 overlay 路径的这一段应消失。
这不保证全局 worst 改善：prepared 当前选择、其他 R/B 控制及不相关路径可能接替。

性能预期只限于：FIFO 空闲/tail 可合并/旧空槽场景无需固定新增拍；
损失来自原先“R 命中 head，且当前 lookup 阻止 drain”的即时合并机会。
head 必须通过原维护机制排空，下一拍 Q 容量才重新可用。
若该状态在完整 workload 中频繁，或 refill 停顿拉长依赖链，R 的周期成本可以高于 S。

以下任一项反证当前合同或其收益假设：

- 写入错 key、重复 key、被接受逻辑写无落点、byte/held-result 错误、丢失或重复 R/B owner。
- 当前 lookup 仍决定新 R 写容量，目标锥没有实际断开。
- 基线能完成的公平输入在候选中形成永久等待。
- 完整 bench 回退而同约束目标锥、全局 timing 均无可解释收益。

## 5. 候选 S：沿用已有容量，付一拍时不要付重复排队代价

S 仅将生产 Service 的现有普通 read 空流参数从 1 改为 0。
不新增 holder、不改变 CPU/PTW 选择、lane 配对、实际接受式、请求顺序或 head 优先级。
普通 read 包包括 invalid 周期的输出均取既有 Q；不以当前 incoming valid 重新选其宽 payload。

若普通 read 在边沿 E 被 Service 接受，T1 空流可同时被 DCache 接受；
S 在 E 捕获到原请求 Q，最早 E+1 由 DCache 接受。若 T1 当时也因 Cache 背压入 Q，
S 不必额外再排一层；因此不能把所有 read 总数乘一当作完整程序周期差。

无阻挡、原 Q 保持一项驻留时，E+1 可发 A 并接受 B，随后逐拍发旧、入新，
每 lane 稳态 II=1。若原 Q 已满两项，E 的 pop 不能反向产生 E 的 admission；
最早 E+1 旧 Q 空位可用于新入。这是原容量信用的恢复停顿，不能靠借当拍 pop 消除。
双 lane/异 bank 的理想能力为最多两条每拍；不保证所有 CPU/PTW 组合都达到。

prepared store 镜像仍是原先的 Q 数据准备。它在两请求 Q 为空、完整身份/类型/原仲裁匹配、
实际 CPU valid 和已授权请求成立时，仍可直接送 DCache；不匹配或背压仍恰好入原 Q 一次。
lane0 的镜像选择保留当前控制依赖，**S 不能称整个 Service 输出控制或所有输入完全断链**。
若它成为新 worst，另取证后再比较其代价，不在本轮顺手关闭。

S 的预测是普通 incoming read payload 到 Cache 不再空流，不是固定 CPI 改善。
若出现无阻挡每隔拍才接受一条、同 token 入队并 direct 两次、旧 head 被新包覆盖、
aux/CPU 真实身份错配或取消后槽位提前复用，应视为实现错误而非新增流水的正常代价。

## 6. 等待环与最小反例

| 反例 | 必须满足的合同 | 能否宣称数值进度界 |
| --- | --- | --- |
| R 键等于 FIFO head，持续热 lookup | R 等容量不能冻结 read 配额或阻止 old head drain；最多四次真实 read 授权后原维护写仍可发生 | 四次额度只约束本 bank 维护，不能推出任意 B 竞争下完整 refill 的固定完成周期 |
| 同 bank B 和 R 同时有许可、只余一个槽 | 真实 B fire 优先；R 不消费同一槽。B valid 但终端受阻时保留原可行 R 进度 | 不新承诺外部 AXI/终端的等待上界 |
| B 键可合并而 R 键无空间 | R 必须查询自己的键并等待，不能借 B permit；释放容量后继续推进 | 以真实可达输入定向验证 |
| R valid 等 ready，leaf 等 R fire 才愿 drain | 禁止这一新环；维护 drain 由本地状态/真实 read 配额决定，不等待待接受 R | 出现公平输入永久等待即反证 |
| S 两槽满，Cache 等返回被消费，LSU 发生 kill | 既有返回消费/死 owner drain 不得改成等待 Service 请求队列空；物理 owner 保留到响应 | 下游公平服务假设下维持原进度 |
| prepared A 已复制但未接受；owner 取消后槽位变为 B | 镜像无 owner，真实激活仍核对完整身份；旧 A 不能被新 B 误用，不能持有取消应答 | 不因镜像增加新的等待者 |

R 与 S 组合时，Service 持有 read 不得变成 FIFO 维护写/外部返回的前提；
R 等写容量也不得等待“所有 Service 槽清空”。原接口没有这种依赖，候选不能引入。
下游永久不 ready 的情况不作进度承诺；应保住稳定性与 owner，恢复服务后继续排空。
保留原 arbitration 的公平性和适用条件，不用“四拍 drain”替代系统级死锁判断。

## 7. 最小实现验证与观测

执行与原始证据由实现/验证角色负责。本稿只规定对应 claim 必需的观察，不新建验证框架：

- **R 局部**：在现有真实 leaf/cache 验证上覆盖 R/B 不同键、R head/tail/空槽/满槽，
  同 bank 真实 B 优先及 B 未 fire、不同 bank 并行、连续热 lookup 的维护进度；
  对接受写使用逐 byte 独立 oracle，验证同拍 overlay 和 held lookup 版本。
  R-specific 前件必须非零，不能以只测 B 同键 probe 的 PASS 代替。
- **S 局部**：利用已有 EMPTY_FLOW A/B 验证同 token 的 Service/cache 接受边沿，
  空流 0→1 拍、连续普通 read 的 II=1/lane、满 Q 不借 pop、旧 head 优先、
  prepared+lane1 read、aux busy/返回背压、CPU/PTE 配对、kill/drain/reuse。
- **相邻事务**：真实 Service→Cache 集成中的 miss/refill/B-held、NC/store/CAS，
  并确认无重复 physical fire、mem-issued 或终端；R 变化复用现有 detached-store 和 byte oracle。
  只有新合同未覆盖的前件才补最小 directed case。
- **全核与物理**：沿主任务既有适用功能/DiffTest、系统与双发射面验证，
  使用同完整 CoreMark10/Dhry10000 输入和计数范围；真实宏/filelist、tool/corner/SDC 保持可比，
  取得完整 setup/hold/pulse/period、面积、新 worst 和目标锥变化。
  不以局部 II 代替全核 CPI，不以局部时序断链代替 500 MHz PASS。

R 的最少解释性观测为：因 R-head 被拒的拍数及后续 drain/恢复、真实 R beat 接受间隔、
同 bank B 阻挡与异 bank 并行。S 为：实际普通 read 入 Service 与入 Cache 的边沿差、
Q 满拒绝和请求/终端精确计数。可复用现有计数；新增观测只用于区分该轮因果链。
这些事件可能重叠，不能相加作 CPI 分解。完整 bench 计数和原始架构 oracle 不变。

## 8. 按实测推进及停止条件

1. **建议第一轮 T1→R**：只改变 refill 的正确键 Q-state 写容量判据；
   先排除信用/字节/进度错误，再取得完整 bench 与同约束 STA。
   若目标锥确实消失且新路径有继续价值，R 可留作已验证实验父点；
   有周期代价必须逐 workload 明报，不能自行升级为默认或正式 promotion。
2. **按反馈决定 S**：若 R 未断预期锥，先定位证据或实现缺口；若 R 已断而最差仍穿当前普通 read，
   再从明确保留的父点做 S。若 R 无收益且产生代价，恢复 T1 后测试 S；
   若先采用时序稿的 S，R 也只在新路径仍支持其因果假设时继续。
3. **只在需要归因时做组合或对照**：记录 T1→S 或 R→R+S 的实际配置。
   组合可以同时保留两项合同，但任何改动 FIFO 容量、准备路径、仲裁优先级或新增级都应另命名，
   不把必要伴随改动藏在一个参数实验里。
4. 每轮同时报告相对其父点与原始 T1 的 cycles/commits、实际结构变化、slack/area 和 correctness。
   已知所有现点 timing 不合格，保留发展候选不等于架构/Pareto promotion。
   新 worst 已移出本切片、同约束收益反复不成立或出现协议/进度反例时停止清单式叠加。

未测 GAP：两个 empty-flow 的完整 workload 使用率、R-head 合并机会频率、实际 refill 与 CPI 代价、
新 mapped 边界/全局 worst、跨 bank 保存路径的完整可敏化性和功耗。
这些指标由后续同配置实测收敛，不影响当前有界合同交付。
