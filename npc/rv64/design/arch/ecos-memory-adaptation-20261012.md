# ECOS DCache SRAM 适配：2026-10-12 实施合同与实验结果

状态：**四颗 masked SRAM 与真实 B holder 已实现并完成功能、完整 benchmark A/B 及 TT 综合/STA 实验。两个完整基准的周期不变，整核映射面积下降 17.2187335%；setup WNS 恶化 1.887566805 ns，整体 STA FAIL，尚未达到 500 MHz。** 本轮使用 ECOS 工业库，core 与宏均以 TT 1.2 V／25°C、500 MHz／2 ns 为实验目标，不倍频，不增加 SS、多角或 P&R 门槛。双发射 OoO、ISA/特权、精确异常、访存顺序、双 memory datapath、真实 B 终端、恢复与进度要求保持。

实际工作区 `/home/lyg/PA/ysyx-workbench`，分支 `ai`。Architect 只读架构资料与独立摘要；`/root/dcache_ecos_impl` 负责 RTL/wrapper/TB，主 agent 负责全核、性能、综合和结果留存。本文区分已实施合同、已测结果与未实施的下一轮候选；本轮不再改 RTL，不更新生产现状拓扑。

## 1. 最终选择：四颗 256×64 masked 宏 + 每 bank 两项写合并 FIFO

**采用四颗真实 `ics55_ecos_sram_256x64_m4`，每 bank-way 一颗。** 保持 8 KiB、2-way、64 sets、64 B line、PA[3] 两 bank，以及原 word index `{PA[11:6], PA[5:4]}`。每 bank 两 way 成对读取，两个 bank 独立前进，无维护冲突时保留每拍两个不同 bank 的 load 接受能力。

每 bank 共享两项关联写合并 FIFO，key 为 `{way,index}`，整个 DCache 共四项；并有 lookup 转发快照与 held-read 数据。数据 SRAM 单端口，FIFO 将逻辑写接受与物理端口写入分开，保存尚未落宏的最新字节。tag/valid/LRU 本轮仍用标准单元。

该型号 WEB[63:0] 为**低有效逐 bit 写许可**，可直接实现 byte write：一个有效 byte 对应的八个 WEB bit 为 0，其余为 1；读操作不使能任何写 bit。full/partial 条目均只需一次 masked 写。**生产方案取消 RMW，也不新增 ww fallback 分支。** 宏写开始沿仍拒绝同 key 合并，避免把尚未写入的新字节随旧 entry 一起清掉。

四颗宏容量恰好 8 KiB，每颗 Liberty area 为 17492.01405 µm²，四颗合计 **69968.0562 µm²**；这是 data 宏面积，不含 tag、FIFO、控制和其它核心逻辑。整核实测见 §7：面积降低，所测完整基准周期保持，时序回退；宏面积本身不能证明整体 PPA 改善。

先前四颗 256×128 ww、各用低 64 bit 的 RMW 方案已被这个可得配置取代。ww leaf 的 15 项测试 PASS 仅是探索结果，不证明当前 masked 模式。旧包不能代表 ECOS 所有可获得配置，本轮不再为它保留不必要的生产复杂度。

## 2. 库与当前接口的证据边界

主 agent 已真实取得 ECOS 官方包并核对 SHA：`npc/rv64/third_party/ics55_ecos_sram/ics55_ecos_sram_256x64_m4/`，包含八个 corner 的 Liberty、LEF、core/full/stub 模型及 CPF；来源记录为 `source-256x64.json`。vendor 已核实：同步单 1RW 共址、64-bit WEB 低有效逐 bit 写、write-through、无 reset；MARE=0 是已表征模式。这是真包，不是 preview；本轮仅使用 TT。新宏的时序必须用其自身库，不能沿用 256×128 ww 的 clock→Q 数字。已核实该 MARE=0 TT 的 read clock→Q：rise 1.1194–1.3983 ns、fall 1.0842–1.3540 ns；read minimum period 1.4396–1.5883 ns、write 1.4189–1.5879 ns；minimum high 0.1991–0.2040 ns、low 0.4546–0.5648 ns。slew 轴 0.008–0.4 ns，Q load 0.005–0.3 pF。2 ns 减去最坏表内读 clock→Q 后剩 0.6017 ns，再扣 50 ps uncertainty 剩 0.5517 ns，尚需承载 FF setup、overlay 与 logic/wire；这支持开展实验，不是整条返回路径 PASS。纯摘要见 [新宏 TT 时序](../../../../build/ecos-dcache-20261012/library-query/tt-timing-summary.json)，库读弧:157、CLK 约束:20446/20466 由主 agent 核实。

独立 current-source 取证与 worker 已确认：

- 原 data 为四个 256×64 逻辑数组，各 1 个同步 read + 1 个独立 byte-enable write；tag 每 way 64×52、2R1W。data/tag 无全数组 reset。
- lookup 或 DELIVER held-bank refresh 在读接受边沿捕获 tag/valid/data；baseline hit 最早下一拍返回，不同 bank 双 load 可每拍接受。
- direct store 的 AW/W 可在请求接受拍发出，最快下一拍接收 B；新增读端口背压必须同步约束这次副作用接受。
- 成功 B/refill R 生成逻辑写，原每 bank 单拍 pending 在下一拍落数组，并为同址 lookup 提供 byte forwarding；新实现已由两项 FIFO 接替它。
- refill 是八个 64-bit beat，交替写两 bank；最后 beat 原边沿安装 tag/valid；DELIVER 的 held-bank 刷新必须看见新数据。
- 当前集成前 DCache data 是寄存器/选择网络，tag 是 DFF/mux；最终旧网表只有 ICache 的两个宏。九项同源基线测试 PASS 包含一拍命中、双 bank 流、真实 R/B、写冲突、pending 转发与重叠 miss。

接口来源由独立角色核对 `R64Dcache.v:417–437,534–541` 和 [LSU 拓扑](../../vsrc/lsu/TOPOLOGY.md) 后摘要提供。Architect 未打开 RTL、网表、原始日志或宏模型。

## 3. FIFO、合并与实际写入

每项至少保存 valid、way、index、64-bit payload、8-bit byte mask 与最老关系。关联命中非 drain 条目时按 byte 合并，同 key 最多一项；同字节以最新真实接受写为准，合并不改变条目原年龄。未置 mask 的 byte 没有新值语义，不得拿任意 payload 覆盖 SRAM。

采用 worker 已确认的最小结构：**移除原一拍 pending**，合法成功 B 或 refill R 的真实接受直接写入 FIFO。若两槽满且 incoming key 没有可合并项，或者该 key 正在本沿 drain，则在 B/R 接受前背压；不能先接受没有落点的数据，再假定下一拍一定有空间。B error 仍正常交付真实错误终端，不创建 cache 数据写；现有 poison/invalidate 写资格保持。

每次 drain 选择已登记的最老条目，输出其 index/data/WEB，真实宏写边沿完成后才清退 entry：

- drain 开始沿，同 key 新 logical write 必须被拒绝，不能新建第二项同 key 或覆盖后再一起清退；
- 其它 key 可以向另一空槽写入或合并；
- 不借同沿清退产生新的槽信用；
- partial write 直接使用逐 bit WEB，未使能 bit 由宏保持，不读旧值、不建立 RMW owner；
- 已接受写不因 cache invalidate 被删除；真实 macro drain 不改变 tag valid。

逻辑写进入 FIFO后即纳入后续 lookup 的缓存可见性；物理宏写只是后备更新。它不是外部 store 更早确认，store 的成功/错误仍由真实 B 决定。

### 3.1 真实 B 接受与稳定的 store 终端

已发现合法反例：若 fast store terminal 的 valid 直接门控 FIFO credit，valid=1/ready=0 后，独立 refill 占用最后空槽会使 credit 降低，从而撤回已呈现 valid；该三 owner 场景已由定向反例复现。leaf 层同 key drain 也会改变信用，但这里不将它单独宣称为完整 DCache 可达反例。该接口是 valid/ready，不是允许撤回的 candidate；必须修复，不能放宽 checker。

采用**一项弹性真实 B 终端 holder，可保留空槽直通**：

- 真实 B ready 由终端 holder 的已登记空位及本次合法成功缓存写的 FIFO 信用决定，不再要求下游 store terminal ready。B error 或无需 cache 写的情况，不受无关 FIFO 空间限制。
- 同一个真实 B fire 恰好一次写入 FIFO（适用时），并把完整 tag/token/error/tval 终端直接交付或捕获到 holder；若下游 ready=0，该边沿 B 已接受，由 holder 接续 valid。
- holder 驻留后，其 valid/payload 不再依赖 FIFO credit、head drain 或 refill。旧 holder 优先，满时拒绝新 B，不借同沿下游释放的槽；sink ready=1 的空槽路径可以保持 B 与 terminal 同沿完成。
- pending terminal 保留原唯一 store owner 及相应 busy/drain 责任，直到 terminal 真正消费。不得因 B 已收而允许身份/描述符提前复用；flush、invalidate、run=0 不删除已接受终端。
- B 对 R 的优先级只根据**真实 B fire**，不能因尚未接受的 B valid 一直阻挡独立 R。保持原同 bank 写口冲突处理。

新增压力定向已先令 terminal valid=1、ready=0，再触发 FIFO 槽/credit 变化，验证 valid 与 payload 连续保持且最终只 fire 一次。恢复旧 B 握手的反事实版本被原 stable-VALID checker 在 455 ns 抓到；最终版本 39 次接受／39 次返回、mutation 1，证明这项检查能区分所修反例。此 holder 修复了稳定性，但空槽直通仍保留组合路径；§9 单独记录由此发现的时序问题。

## 4. lookup 与宏 Q 保持

一个 bank lookup 只在两 way data、tag/valid 和 metadata 都能形成同一请求时获成对 grant。不能一 way 已读、另一 way 未读却推进 owner，tag/valid 也只在真实 grant 时捕获。

该新 lookup 的 launch 边沿保存转发快照：匹配 key 的已有 FIFO 字节，以及该沿真实接受的合法 logical write。明确采用 **write-first**：同沿新 logical write 字节优先；其它 byte 来自此前 pending 内容或宏数据。两个 way 分别匹配，禁止跨 way 借值。已经在更早边沿 launch 的旧 lookup 只使用其原快照，不能被后来写改写。

macro write-through 或下一次读会改变 Q，裸 Q 不能长期代表驻留 lookup。用 held-read 数据保证原响应受阻、后台写和新的宏操作都不会破坏它；macro/held 来源选择、overlay、tag、way、fault 和 owner 必须对齐。已呈现的 valid/payload 在背压中保持，不因 FIFO 合并、后续写或 invalidate 重选。

| core 边沿 | 正常 read 路径 | write drain 路径 |
| --- | --- | --- |
| e0 | 成对 launch，捕获对应 tag/metadata 和转发快照 | 仅本 bank 维护 grant：一次实际 masked 写，不能同时接受本 bank 新 lookup |
| e1 | TT 返回预算成立时最早响应；需要时捕获 held-read | 下一次 read 可以查询更新后的 SRAM；e0 清退后的信用按已登记状态发布 |

无冲突 hit 保持一拍响应和 II=1，已由生产 SET_W=6 的 800 次命中与 400 拍双 bank 热读 A/B 验证。macro Q＋overlay＋接收边界若真实超过 2 ns，应返回实测路径和最小流水候选，不倍频、不加虚假时序例外。

## 5. 两 bank 独立仲裁与进度

每 bank 独立仲裁 lookup、held-bank refresh 和 FIFO drain。读成对占用该 bank 两 way，写占用目标 way；首版为清晰性允许一次写阻塞本 bank 的整对 lookup，另一 bank 继续前进。不能为一 bank 的维护无理由停止两个 bank 或整个 AXI 服务。

公平策略：有 dirty 条目时最多连续授予四次 lookup，随后服务最老 dirty；没有 lookup 时直接后台 drain。真正获 grant 的 held-bank refresh 计入相同读额度，未接受候选不计数。新写/合并不重置已经累计的额度，实际 drain 后再恢复相应预算。持续读、持续新写或下游 response 长背压都不能让旧写永不落宏。

macro drain 只依赖本地 FIFO 和 SRAM 时钟，不能等待新的 CPU 请求、AXI 响应或 response ready。禁止形成“FIFO 等响应释放、响应又等 FIFO 排空”的循环。

接口背压必须覆盖所有实际路径：

- FIFO full/drain-key 冲突在真实 R/B fire 前反馈；
- 读维护使 req_ready=0 时，direct AW/W 不能另行建立请求或副作用 owner；
- DELIVER held-bank refresh 没有 read grant 就继续持有，不能把状态名当作刷新已完成；
- 已接受命令仍保持并排空，lookup stall 不冻结在飞总线事务。

## 6. refill、invalidate、错误与原子操作

DCache 新 FIFO 提供完整 byte forwarding，因而不机械要求末 refill beat 后先排空全部物理写才安装 tag。可以保持原末 beat 的安装边沿，但必须证明：

1. 八个真实 beat 已完整正确接受，每个 word 已在 SRAM 或在可靠且可转发的 FIFO 中。
2. 同 key 唯一、drain 同沿禁止接收同 key、新写合并保留最新 byte，旧 drain 不会晚到覆盖新 refill。
3. 最后 beat 没有 FIFO 落点就不 fire，tag/valid 不提前安装。
4. 原 beat error、poison/invalidate 规则继续阻止成功安装；错误/poison 仍恰好一次产生原语义终端，不因未安装 tag 永久等待。

invalidate 清 tag valid/poison，**不清已接受 FIFO**。晚到物理写不能重新建立 tag valid；新 refill 与旧 pending 同 key 时仍按冻结/合并规则处理。reset 可以清 FIFO，同时 cache valid 全部失效，但仍遵循系统 reset 合同，不能当普通取消。

真实 B 决定成功/错误；错误 B 不修改 cache 有效数据。保留 LR reservation 清除时点、SC 最终检查、CAS/AMO 正确旧值、split 子写顺序、store-active 排除、LSU 年龄与 source pin 规则。cache FIFO 的 accept/drain 不能替代架构完成、原子结果或精确 trap。

## 7. 已完成验证与可比较结果

本节使用最终四颗 masked 宏＋B holder 的独立执行摘要。16 项既有定向加新增 pressure（共 17 项）、6 个参数配置、2883 项模型对照通过；18,000 拍 oracle 的 cycle/vendor 两种模型指标一致。strict lint、10 个全核 DiffTest、7 个热窗口全部通过，热窗口 CPI=0.5；生产命中 A/B 保持 800 次一拍命中和 400 拍双 bank 热读。上述证据覆盖本轮执行范围，不等同于全状态形式等价或完整系统签核。

完整、同 workload 的严格 A/B 没有缩短迭代数；最终两侧所有采集的 profile 与 load latency bins 一致：

| 完整 workload | 原实现 cycles / commits / CPI | 最终宏化 cycles / commits / CPI |
| --- | --- | --- |
| CoreMark 10 | 4016641 / 3218537 / 1.2479710502 | 4016641 / 3218537 / 1.2479710502 |
| Dhrystone 10000 | 5691655 / 4260629 / 1.3358720039 | 5691655 / 4260629 / 1.3358720039 |

这支持“本轮所测完整基准没有 CPI 回退”，不推出所有 workload 都没有维护冲突。精简结果见 [性能 A/B](../../../../build/ecos-dcache-20261012/performance-comparison.json)。

同 TT 1.2 V／25°C、500 MHz／2 ns 的真实全核映射包含四颗 DCache masked 宏与两颗 ICache 宏：

| 指标 | 原实现 | 最终宏化 | 判断 |
| --- | ---: | ---: | --- |
| macro-inclusive 映射面积（µm²） | 2906950.524099 | 2406410.460301 | 减少 17.2187335% |
| DFF 数量 | 198598 | 132509 | 减少 66089 |
| ICG 数量 | 10780 | 2610 | 减少 8170 |
| global setup WNS（ns） | -3.147320986 | -5.034887791 | 恶化 1.887566805 ns |
| 最终 hold WNS（ns） | — | -0.313464463 | FAIL |
| 最终 minimum-period slack（ns） | — | +0.408300072 | 此检查通过 |
| 最终 global pulse slack（ns） | — | -20.870256424 | FAIL |

结果见 [面积与 STA 对比](../../../../build/ecos-dcache-20261012/ppa-comparison.json)。这些是综合映射与 STA 的实验结果，不是 P&R 面积或签核频率；未取得合格 activity power。本轮确认真实 SRAM 宏化、功能回归与面积收益，**不构成 500 MHz 达标或 PPA 全面改善**。minimum-period 单项为正不能抵消 setup、hold 或 pulse 失败；已知门控时钟负载问题也不能解释 §9 的新 setup 控制链。

实现已按 ECOS 单 1RW、逐 bit WEB 的限制设置 FIFO、仲裁、保持/转发和集成背压。每轮综合按用户要求仅保留结果摘要与必要精简失败证据；可再生网表/中间物由主 agent/实现 owner 在提取结果并确认无工具占用后清理。

## 8. 其它结构的 SRAM 优先级

| 结构 | 当前真实接口/规模 | 本轮决定 |
| --- | --- | --- |
| ICache data | 两颗 256×128 ww 真宏，整 sector 写 | 保留，与新增 DCache 宏共同验证 TT |
| DCache data | 8 KiB，byte write 与读并发需适配单口 | 本文四颗 masked 宏＋FIFO |
| DCache tag | 每 way 64×52、2R1W，总约 6.5 Kbit | 保留 FF；bit mask 不消除多端口需求 |
| PRF | GPR/FPR 各 64×64，4G/3F 读、两 WB 与旁路 | 保留；单口替换需 bank/复制/调度重构 |
| ROB / IQ / LSQ | ROB32 多更新与双退休；IQ16 全行 ready/年龄/配对；LSQ20 PA/年龄和逐 byte source 匹配 | 保留；不是普通单口 FIFO，包含多端口/CAM 可见性 |
| BHT / 间接 BTB / FTB | 约 384 B / 640 B / 1312 B；组合查询与训练/repair 多种更新 | BTB/FTB 可作后续 fetch 流水＋更新队列候选；本轮不改，mask 也不自动解决读旧计数/多更新 |
| RAS / TLB | RAS8 多查询/journal；三个全相联 16-entry TLB 并行比较/批量失效 | 保留 FF，不强套本轮单口宏 |
| 小 FIFO | 常见每 lane 2–3 项，预写、组合 head、取消 | 保留 FF，避免容量浪费和无谓协议延迟 |
| L2 | 当前生产核无 L2，I/D 直接接两-client AXI read | 不凭名称新增不存在的 SRAM 对象 |

上述库存由独立角色核对当前实现后摘要回传，不能将它解释为所有这些结构永远不应 SRAM 化。它只决定本轮优先级。

行业 primary 参考由主 agent 核实：[HPDcache 官方架构](https://openhw-group-cv-hpdcache.readthedocs-hosted.com/architecture.html) 采用同步单口 SRAM、端口仲裁/replay 与 FF write buffer，支持显式写缓存适配真实端口的结构；本核仍等真实 B，不照搬 early store acknowledgement。[BOOM predictor](https://docs.boom-core.org/en/latest/sections/branch-prediction/backing-predictor.html) 将 SRAM 访问与 fetch 流水共同设计；[BOOM PRF](https://docs.boom-core.org/en/latest/sections/reg-file-bypass-network.html) 说明多端口/bypass 约束，不能推导本核可直接用单口替换。实际型号以取得的真包为准，公开产品信息见 [ECOS 官方 SRAM 项目](https://github.com/openecos-projects/ics55_ecos_sram)。

## 9. 时序回退与下一轮最小候选（未实施）

本轮最差路径从 PMP 配置 bit 19 到 IQ row 15 的 serial-dependency bit 10。PMP→LSU→Split 的前缀到 3.2898 ns 与旧路径一致；MemoryService→DCache 请求地址为 3.7477 ns，旧值 3.7531 ns。新增的连续控制链如下，数字是本次映射的累计 arrival，不是将来切级后的时延预测：

| 架构边界 | arrival（ns） |
| --- | ---: |
| DCache 当前 lookup/read admission | 4.4152 |
| bank FIFO 当前 drain/lock 相关 probe credit | 4.6866 |
| 空 B holder 的 store terminal 直通 valid | 4.9561 |
| LSU 弹性 store completion | 5.5227 |
| ROB head exception bypass | 5.8664 |
| Commit 有序双退休 ready | 6.1478 |
| ROB serial release | 6.7196 |
| IQ serial dependency D | 6.9495 |

独立取证确认：匹配 FIFO head 的写信用在同拍 drain 时不可用，而是否 drain 取决于当前 lookup 是否占宏读口。这项信用进入真实 B 完成的空槽直通路径，串到 LSU、ROB、Commit 和 IQ。B holder 在驻留时保证稳定，但空时没有寄存隔断。最差路径**不包含 SRAM clock→Q 或 byte-forward 数据弧**，因此本轮负面时序不能归因于 SRAM 读数据变慢。旧最差终点为 DCache tag 读寄存器，arrival 5.0606 ns；新链改变了终点与跨域范围。来源见 [最差路径语义摘要](../../../../build/ecos-dcache-20261012/critical-path-evidence/semantic-summary.txt)。这是静态映射事实，未证明动态敏化，也不授权设 false path。

下一轮优先比较两个有界切分，当前实测结果保持原样：

| 待测候选 | 机制与周期合同 | 代价与反证条件 |
| --- | --- | --- |
| A：B 写信用只依赖已登记 FIFO 状态及已登记 B owner key | 占用的最老 head 始终对 B 合并冻结；只允许非 head 同 key 合并，或无重复 key 的真实空槽。不以本拍 lookup/drain 改变这项信用。保留现有 B holder 及空槽直通；无维护冲突的 load 仍可一拍返回。 | 减少 head 合并机会，可能增加实际宏写、局部读冲突和 B 等待。若仍通过通用 live write-ready 或其它资格条件重新依赖 lookup，则未切断所针对的链。 |
| B：B terminal 仅从 holder Q 输出 | e0 真实 B fire 同时写 FIFO（适用时）并捕获完整终端，e1 最早被 LSU 消费；取消空槽 terminal-valid 直通。B 接受、错误语义和原 owner 保持至消费的规则不变。 | 最快 B→terminal 增加一 core cycle，可能推迟 store 退休或后续 store 接受。确定切断当前跨域串接，但原 probe→B-ready 路径及其它新最差路径仍须测量。 |

**优先做 A 的单一切片；B 作为边界更直接的对照/备选。** A 针对本轮新增依赖，且不先加入固定的终端延迟。它不是把组合信用改名为寄存信用：B 的 bank/key 必须来自已登记 owner，信用只能由 FIFO 的 Q 状态计算，不能再与包含当前 read/drain 的通用 write-ready 相与。这个 Q 信用必须足以保证真实 B fire 当沿有落点；若做不到，需改为 B 或明确的预留结构，不能把接受条件与实际写入拆开。

A 的同 key 与进度合同必须同时满足：

- B key 等于占用 head 时，即使另一槽空闲也拒绝，不创建第二个同 key；非 head 合并或空槽分配可与旧 head drain 并存。
- B/fire 仍优先于竞争同写入口的 R；仅有 B valid 不阻挡 R。head 清退、tail 晋升与同时合并必须保持最新 byte 和单一 key，不借同沿清退槽。
- 保留四次真实 read grant 后的 oldest drain，新 R/合并不能重置额度。对持续有效的 head-key B，在宏正常运行、holder 可接收的前提下，局部等待由剩余不超过四次读 grant、一次实际 drain 及随后 Q 信用可见界定；不把外部 B 延迟或终端背压计入这一局部界限。
- 保留现有稳定 terminal holder、真实 B 才写 cache、error 不写、invalidate 不删已接受 FIFO、两 bank 独立及 owner 恰好一次排空；不通过放宽 ready/valid 或全局串行化取得时序收益。

CPI 代价只能分清局部机制，不能预先报零。A 无固定新增 hit 或 terminal 延迟，但额外 head 等待与写端口占用会改变队列和访存交叠。B 对原可直通且没有其它阻挡的单次 B terminal 固定增加一拍；一阶估算可看未被其它执行隐藏的 store 终端数／commits，但这不是全局 CPI 上界，因为双退休、owner 复用和后续访存调度也会变化。两者都不保证 2 ns：即使按现有链把 terminal 后段截出，4.9561→6.9495 ns 已约 1.9934 ns，尚未加入新起点 clock→Q、setup 和 uncertainty，且重新映射会改变延迟。

最小反证实验由实现/验证角色在下一轮执行：先保留并通过现有 held-B pressure、真实 B/error、同 key 合并/清退与双 bank 场景，再补 A 特有的 head 常冻结／tail 晋升／连续 R 竞争进度，或 B 特有的 e0 接受、e1 返回和跨 invalidate 终端保持；随后用同 TT/2 ns 全核映射检查 lookup→probe→terminal 依赖是否真正消失及最差路径是否迁移，用相同完整 CoreMark 10、Dhrystone 10000 和采集口径量测 CPI。若依赖仍在、写丢失/重复、稳定性失败、出现饥饿或 CPI 代价不合适，应撤销该候选或重新选择切分，不改本轮负面结果、不加假时序例外。本轮只交付这些下一步建议。
