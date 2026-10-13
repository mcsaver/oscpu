# Memory 独立架构复核与实现裁决（2026-10-13）

> 本文保留设计/评审时的候选状态；实际实施、保留点和测量结论见[多轮实测报告](memory-implementation-evaluation-20261013.md)。实现合同采用独立评审收紧后的版本，尤其保持原 allocating error/poison refill 的维护写规则。

**裁决：从 T1 单独实现 M-R；依据该轮真实路径与完整 workload 结果，再决定是否实施 M-S。**
M-R 采用本次 R beat 自身键的 Q-state 维护写容量查询，不复用 B-key 信用，不新增 beat 缓存、
维护槽或流水拍。两稿的主体合同可以支持这个有界实验；下文收紧的合同应直接随任务交给 worker，
无需再增加人工批准。本文没有实现、仿真、综合或 STA 结果，不构成 correctness、500 MHz 或正式
Architecture/Pareto promotion 结论。

本角色使用独立上下文，实际工作树为 `/home/lyg/PA/ysyx-workbench`，仅新增本文。
未读取 RTL、TB、网表、波形或原始实现日志，未沿来源指针打开实现，未修改作者稿或生产拓扑。

## 1. 共同事实与评审范围

输入限于：

- [共同目标与父点](../../../../build/memory-rounds-20261013/architecture-brief.md)。
- [有界实现事实](../../../../build/memory-rounds-20261013/memory-architecture-facts.md)。
- [时序候选稿](memory-timing-rounds-20261013.md)与[性能候选稿](memory-performance-rounds-20261013.md)。
- 主 agent 于本次评审期间提供的补充实现事实：**当前 R 维护写的真实资格是 REFILL、
  allocate 与真实 R fire；error/poison 并不一概禁止写维护 FIFO，valid/install 等后续处理另有原规则。**
  来源为主 agent 对本轮实现的有界核实与消息回传，非新测量；本文不将其泛化到其它配置。

共同父点为 T1 / `35a8a1d24`。保留 ICS55 + ECOS、TT 1.2 V / 25°C、500 MHz / 2 ns、
0.05 ns uncertainty、原输入/输出约束、宏与工具口径。T1 buffered setup / hold 为
−2.549148798 / −0.313464463 ns，pulse / period 为 +0.549876153 / +0.408300072 ns；
flat area 为 2,415,687.980301 µm²。完整 CoreMark10 为 4,423,886 cycles / 3,218,537 commits，
Dhry10000 为 6,033,084 / 4,260,629。历史系统 10/10 与七个双发射热窗的通过只绑定父点。

现有关键路径经过当前请求、bank lookup、live write-ready 与公共 refill fire，再到 overlay。
局部 bank 选择互斥不构成整条路径不可敏化的证明；不得改 false path、reset 约束或频率目标。
ICache hold 问题独立存在，本轮改善 setup 也不能宣布 500 MHz 合格。

本次接受标准是：真实 accepted write 有唯一合法落点，字节与终端精确一次，原 owner/取消排空/
副作用/访存序不变，原公平条件下无新增永久等待；随后同口径量出目标依赖、新最差路径与完整 CPI。
没有待补事实妨碍当前有界实现选择；收益和精确吞吐仍需实测。

## 2. 必须收紧的合同

| 问题 | 独立裁决及 worker 应遵守的合同 |
| --- | --- |
| error/poison 被误当成“不需要写” | 时序稿 §4.1 关于“错误或 poison beat 排空而不写”的例举不能作为分类规则。性能稿 §4.2 的“无需写入”也只能指父点原谓词本就不写的分支。**只替换原 R 写容量来源，原 REFILL/allocate、写使能、byte mask、invalid、error/poison、install 与终端条件逐项保持。** 不新添跳过写、忽略容量或直接吞掉返回的路径。 |
| permit 被当成 owner 或可延期兑现的票据 | permit 是本拍旧 Q 对本拍真实 R-key 的容量判断；它不占槽、不推进 beat、不建立返回信用。每个实际 R 接受边沿使用当拍对应状态的许可。不得把 permit 寄存一拍后在没有 slot/key 预约的情况下消费；新增预约会改变本候选范围，本轮不做。 |
| 同 bank 以 B valid 抢占，或 R/B 相互等待 | 沿用父点完整的同 bank 冲突谓词，竞争点以**真实 B fire 优先**。B 原自身资格、B-key Q 容量与终端信用先形成可接受性，R 按原冲突条件避让；不能新增 B-ready 等 R-ready、R-ready 又等 B-ready 的环。仅 B valid 且未 fire 不能新增 R 阻挡。也不能把原竞争谓词扩大到父点原本无此竞争的分支。 |
| 同一 Q 许可对应多个写消费者 | 每 bank 仍只有原逻辑写入口；原同 bank 排他仲裁保证一个入口不被 B/R 双消费。不同 bank 保持原可行并行。leaf 对上层已接受的维护写必须兑现，不能再拿 live ready 拒绝，也不能用 permit 单独改 valid、字节或 owner。 |
| “四拍公平”被推导成固定 refill 完成界 | 保留 dirty 状态最多连续四次真实 read、随后给维护 drain 的原规则。它约束本地 read 与维护的竞争，不给任意 B 流、AXI 背压或终端背压下的完整 refill 固定时限。R 等待不得重置额度或阻止 drain。 |
| M-S 被写成所有请求强制登记 | M-S 只关闭现有普通 read empty-flow。prepared route 仍含当前身份/仲裁控制，aux、特殊访问和原分类不扩张。claim 限于被关闭的 incoming read 分支；不是所有 Service 控制都断链。 |

上述是实现合同的确定化，不是已观察到父点存在这些 bug。作者稿不在本角色写入范围内；
当措辞有歧义时，交给 worker 的具体任务应采用本节的收紧版本。

## 3. M-R 的容量论证、周期与资源

R-key 必须为本次真实 refill owner / beat 的 `{bank, way, fill-index}`。
R 未 fire 时，其 beat 位置与身份维持原持有规则；查询键不能来自 B mirror、当前 CPU 请求、
下一未接受 beat 或仅凭 AXI valid 推进。新增的是正确键的查询能力，物理 owner 仍是原 slow owner。

对同一个旧 Q 快照，按以下有先后关系的规则判断：

| 旧状态 | R 容量判断 | 为什么可兑现 |
| --- | --- | --- |
| 命中已占用 head | 拒绝，即使另一槽为空 | head 可能已进入 drain，候选不依赖本拍 lookup 阻止 drain 的机会，也不建立重复 key |
| 未命中 head，命中 tail | 允许原 byte-mask 合并 | 目标是未冻结的原 tail，实际消费只更新对应的接受字节 |
| 无匹配，旧 Q 有空槽 | 允许分配 | 使用已存在的空槽，不借本拍 drain；原仲裁排除同 bank 第二写消费者 |
| 无匹配且旧 Q 满 | 拒绝 | 同沿 pop/drain 不形成当前可用信用 |

这个论证依赖**查询、实际 R 键、同 bank 仲裁与消费处于同一个接受边沿**。
只证明查询布尔值正确，却让实际写使用另一键、另一拍状态或另一个目标 bank，仍然错误。
“Q-state”不意味着整个 ready 只能从一个寄存器输出：原合法资格和实际 B 冲突仍存在，
但本次 R 容量不能再通过当前 lookup/read grant/drain 获得。

tail 合并与 old-head drain/移除在父点允许的同沿发生时，合并必须针对旧 tail。
若该 tail 同沿晋升成 head，晋升内容必须包含这次接受的全部新 mask/data；
原 head 的维护写仍使用其原被冻结版本。不得先晋升后把合并丢掉，也不得把新数据写进正在 drain
的旧 head。晋升后的 head 从下一旧 Q 视图起按 head 规则拒绝合并。

同拍 lookup overlay 保持原按实际 read fire 捕获的语义：仅同 key/way 且有效 mask 的已接受
写字节覆盖旧 FIFO 字节；只有 permit、invalid beat 或不匹配键不能覆盖。held lookup 结果不能因
后续 FIFO 移动而换版本。上述逻辑写和 SRAM 1RW 端口授权是两层资源，不能用写容量许可取代
read-ready、公平性或实际 SRAM 操作。

M-R 不增加两槽容量、slow owner 数、SRAM 端口或固定 hit 流水级。旧 Q 空闲或可合并 tail 的
beat 不因本候选固定多一拍；head-key beat 要等待原维护机制改变 Q，具体接受 II 待测。
禁止把“不加固定拍”写成“CPI 必不回退”，也禁止从两个槽推断两写/拍。

## 4. 等待依赖与恢复判断

在两稿及共同事实限定下，M-R 没有必须引入的新 owner 或等待资源；以下依赖不变就没有
被本方案要求的新等待环。但这是合同层判断，不代替实际实现的循环、饥饿和动态验证。

| 合法等待 | 进度出口与禁止新增的反向依赖 |
| --- | --- |
| R 等自身 FIFO 容量 | 旧 head 按原机制 drain。drain 不等本次 R fire，不等 Service 队列为空，也不因 R valid 而冻结。read 连续占用受原四次额度约束。 |
| R 按原同 bank 规则让真实 B fire | B 使用自身 owner/key/终端信用；B 不等待 R 接受才释放 FIFO。B 仅 valid、被终端背压时不能新增资源占用。持续可接受 B 是否使 R 饥饿仍按父点仲裁及环境条件评价，不发明新的固定完成界。 |
| Service Q 等 cache 接受 | cache 已在飞 R/B、维护 drain 和可排空响应继续推进，不以 Service 清空为前提。M-S 只改变新 read 的驻留边界。 |
| 已死亡 LSQ owner 等物理返回 | 原 accepted transaction 继续 drain，死亡返回只回收原在飞责任，不产生活完成。不能等待该 LSQ 行提前复用，也不能先清除保管请求的 Q。 |

M-R 不搬动副作用边界。M-S 的 CPU→Service 实际 fire 仍是原不可取消的物理接受，即使请求只在
Service Q；LSU 的 mem-issued/effect 与完整身份保留到原返回回收点。prepared mirror 只是数据准备，
不能发明 owner、完成信用或 store 许可。实际 store/IO/atomic 仍先满足原 head/effect 资格，
AW/W、permit 或入队都不冒充成功 B。

flush/reservation-clear 不是外部 AXI cancel。invalidate/poison 的原数据、valid、安装与排空顺序保持，
不清掉已接受事务，不复活旧 tag，不允许年轻副作用越过 precise trap。reset 同样沿用系统既有合同。
多个 holder 的容量不得求和宣称新增独立 LSQ owner；本轮不改变 20 行 LSQ 或辅助客户端 busy/返回责任。

## 5. 可直接交验证角色的最小反例

下列是需要区分的前件，不要求新建测试框架；已有真实 leaf/cache、Service 与 LSU oracle 能覆盖的
直接复用。计数或断言必须证明本次候选相关前件确实发生，不能仅引用测试名字或历史 PASS。

| 反例 | 最小激励与错误实现的结果 | 正确观测 |
| --- | --- | --- |
| C1：B-key 冒充 R-key | FIFO 满且 head=H、tail=T；B-key=T 有合并信用，R-key=H 或不匹配 K。若复用 B 许可，R 会更新被冻结 head 或没有落点。再做反向合法键对照。 | 对真实 R-key 的许可与实际写落点一致，无重复 key；R 不借 B 信用。 |
| C2：陈旧许可 | 拍 n 只有 head=H，R-key=K 查到空槽；同 bank B 在 n 实际 fire 填满该空槽，R 被仲裁挡住。拍 n+1 head 尚未 drain，若沿用寄存的旧 permit 接受 K 就超卖。连续 lookup 可在原公平额度内维持此状态。 | n+1 按新 Q 拒绝 K；不靠叶端撤销已接受写修补。 |
| C3：B valid 被误当接受 | 同 bank B valid，但原终端信用阻塞，B 未 fire；R 有自己键的合法容量且父点其它资格满足。 | 不新增 B-valid 对 R 的封锁；反向使 B 真 fire 时，原竞争 R 必须避让。 |
| C4：head 等待形成闭环 | R-key=head 且稳定等 ready，持续 hot lookup；错误实现因等 R 接受而暂停维护，或由 R 等待重置 read 额度。 | 原最多四次连续真实 read 规则仍给 old-head drain；Q 改变后 R 可重试。检查实际 drain/恢复，不能只看最终 timeout。 |
| C5：tail 晋升丢字节 | 父点合法的 head drain/移除与 R 对 tail 的部分 mask 合并同沿，随后读取全部相关字节。另用原合法 read/逻辑写共存场景验证 overlay。 | 晋升后的项含新旧字节的正确合并；旧 head 的 drain 版本与 held lookup 不被污染。不强求同 bank SRAM read 与 drain 同沿这种非法组合。 |
| C6：错误返回被偷偷改写规则 | allocate=1 的原 REFILL 路径遇 error/poison；让 FIFO 无信用，再释放信用，并与父点相同事件条件对照。另覆盖原非 allocate/invalid 分支。 | 保留父点原写/ready/byte/install/终端判定；不能新增 error/poison 跳过写或跳过容量，也不能为原本无等待的分支新增等待。 |
| C7：并行与精确一次 | 不同 bank 的合法 R/B 同时接受，同 bank 原竞争排除，B terminal 背压，R 最后 beat 背压，再全 beat/bank 读回。 | 合法并行非零，真实接受/字节 mutation/终端相符；B 不重复接收，beat 不因 ready 或 permit 单独推进。 |
| C8：M-S 驻留与取消 | 普通 read 在 E0 仅被 Service Q 接受，随后 kill/flush；cache 阻塞后恢复；辅以满两槽 pop、旧 head、新 CPU1/aux 配对与 prepared+lane1 read。 | 对同 token，原空流 0→1 边沿、无阻挡持续流 II=1/lane、满 Q 不借 pop；请求/返回恰一次，完整来源不重标，死亡 owner 排空后才释放。 |

C6 的比较是**保持原条件与结果规则**，不是要求 M-R 与 T1 每拍 R-ready 完全相等；
M-R 本就有意在 head 合并场景保守等待。验证应把这一明确容量差别与误改 error/poison 分类区分。
不得通过同时改变 error 注入、allocate 条件、byte oracle 或 checker 来“证明等价”。

## 6. M-S 的条件裁决与实验变量

M-R 首轮仅改 R 写容量依据，保持 T1 的 RR 三个 direct 选项、load notice Q、
`MEM_TERMINAL_CURRENT=1`、LSU 翻译 bypass、Service read flow、prepared 路径、FIFO 深度、
宏与仲裁策略。为了落实正确 R-key 查询所需的端口/组合逻辑属于同一切片，但不可暗中新增状态或
改 admission；真实伴随改动由 worker 在摘要中列明。

随后按下表决定下一步：

| M-R 实测 | 后续动作 |
| --- | --- |
| 正确性失败或目标依赖仍未按合同改变 | 修复实现或撤销此切片；不把错误当作可接受 CPI 代价，也不靠叠 M-S 遮住合同缺口。 |
| 目标依赖移除，真实路径改善，而新主导路径仍穿 Service 当前普通 read | 可从明确保留的 M-R 父点单独比较 M-S，得到 R→R+S 的增量；同时报告相对 T1 的累计值。 |
| 目标与全局 timing 均无收益，完整 workload 变差 | 默认回到 T1；若当前证据仍支持 Service read 切点，再做 T1→M-S。保留 M-R 负结果。 |
| 新最差已移出本切片，或 M-R 本身已使后续 M-S 假设失去依据 | 先解释新瓶颈，不自动做完预列候选。局部目标改善与全局 WNS 未变分别报告。 |

M-S 只将生产 `CPU_READ_EMPTY_FLOW` 改为 0。E0 入原 Q，原空流请求最早 E1 被 cache 接受；
T1 已因背压入 Q 的请求不应再被强行多排一级。两槽/lane 的旧 Q 信用与旧 head 优先不变，
无阻挡一入一出可 II=1/lane，满槽不能借当拍 pop。异 bank/仲裁限制和 Split 逐字节 SEND/WAIT
造成的实际代价仍需测量，不将局部 +1 当完整程序周期上界。

prepared 的当前身份/类型/仲裁选择仍保留，普通 read 的 Q 边界不等于整个 Service 的 Q 边界。
时序稿提出的 M-SP 属作者条件续轮设想，**不在本次实现裁决内**；本评审不另设第三套架构，
也不把后续测量视作必须追加它的清单。

CPI 对每项完整 workload 用实际 cycles/commits 计算。R-head 拒绝、B 冲突、满 Q、empty-flow
使用率等观测可能重叠，不能相加分解 CPI。先用真实目标路径与完整计数判断是否存在代价，再用这些
窄观测区分原因；不预先要求全仓 profile，不混入 T2-min 的 RR 变化，也不拼接不同父点的最佳值。

## 7. 真正待测项与交付边界

实现/验证角色完成当前切片直接相关的编译、边界验证及原断言，复用共同事实所列的 leaf/cache、
detached-store、Service 与 owner/reuse 测试；仅为 C1–C8 尚缺的真实前件补定向激励。
随后保持主任务原适用系统/DiffTest 与双发射验证范围、完整 CoreMark10/Dhry10000、
真实 raw/clock-buffer 映射和 STA 比较口径。确定性输入默认一次，异常或工具噪声才说明重复理由。

真正尚未知道的是：

- R 自身键 Q 查询是否在实际映射中切掉 lookup/drain 对容量的依赖；新 R-key 比较、B fire、
  当前 prepared 控制等是否迁为关键路径。
- 原 head 合并机会的损失频率、实际 R 接受间隔、维护进度与完整 workload CPI 代价。
- 若实施 M-S，原空流利用、暴露 load-use、Split 子读与排队重叠的真实成本。
- 同原约束的完整 setup/hold/pulse/period、面积以及残余路径；原 ICache hold 是否仍 FAIL。
- 保存跨 bank 时序路径的完整可敏化性与合格功耗；二者均不能由本合同推断。

每轮返回精简的同源摘要：直接父点及实际变更、功能与终端范围、cycles/commits、
四项 slack/面积/宏与约束、目标锥是否改变、新最差路径、假设被支持或反证之处。
结构切分、局部 II、动态 correctness 和物理时序分别报告；未测写 GAP，
面积收益不能补偿正确性或 timing 失败，pre-layout slack 不换算合格 Fmax。

**可交 worker 的裁决已闭合：实施正确 R-key 的即时 Q 容量查询，保持原 R/B 接受、字节、
error/poison/allocate 和恢复语义；按反例确认容量与进度，再用真实数据决定 M-S。
这里没有新增批准流程，也没有声明优化已实现。**
