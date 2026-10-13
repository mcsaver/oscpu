# 2026-10-13 时序导向架构候选与多轮实验

状态：**架构提案，尚未实施 T1/T2/T3，也未执行新仿真、综合或 STA。** 本文只由纯架构角色编写，交给全新上下文的独立评估角色审查。实际 worktree 为 `/home/lyg/PA/ysyx-workbench`，分支 `ai`；唯一写入范围为本文。未读取 RTL、TB、网表、波形或原始实现日志，未修改生产拓扑。

目标保持 ICS55 / ECOS SRAM、TT 1.2 V / 25°C、500 MHz / 2 ns 以及原有约束；保留商业功能、双发射 OoO、精确 trap、恢复、访存顺序与进度。面积为次要目标，允许增加寄存器、端口、值副本和局部调度资源；不能由此推导功耗不受约束。当前任务交付可审查的架构方案，后续实现与测量由主 agent 安排对应 owner。

## 1. 事实起点与验收对象

可读来源：

- [上批结果](../../../../build/ecos-opt-20261012/RESULT.md)：已完成 R1–R4 的条件、数值和范围。
- [R3 最差路径语义摘要](../../../../build/ecos-opt-20261012/forensics/round3-protection/semantic-summary.json)：独立映射取证，只使用精简语义事实。
- [本轮有界架构事实](../../../../build/arch-parallel-20261013/architecture-facts.json)：主 agent 于 2026-10-13 静态核实当前实现；没有新仿真或 STA。
- [公共协议](../../vsrc/PROTOCOLS.md)、[Backend 拓扑](../../vsrc/backend/TOPOLOGY.md)、[LSU 拓扑](../../vsrc/lsu/TOPOLOGY.md)：状态 owner、接口与历史周期说明。较早 topology 的一般读路径不能覆盖后来加入的完整值直接准入。
- [已采用的保护边界](memory-protection-boundary-20261012.md)：R3 的既有取舍，不是本文新候选。

本轮主 agent 已将已测实现固化为基线 `e44dac90b`；上述历史测量仍按各自冻结输入解释，本轮未改 RTL。

当前默认含 Q-only DCache B credit 与完整 Protection holder 边界；Bare 最终保护响应由 1 拍增为 2 拍，两数据 lane 的局部 II 仍为 1。已映射证明 raw PMP 前缀被 holder Q 截断。

| 已测量 | R3 原始映射 | R4 相同 RTL 加显式 clock buffer |
| --- | ---: | ---: |
| 单元及宏面积 | 2.402403 mm² | 2.414770 mm² |
| setup WNS | −3.226368427 ns | −3.226368427 ns |
| hold WNS | −0.313464463 ns | −0.313464463 ns |
| pulse slack | −20.870256424 ns | +0.549876153 ns |
| minimum-period slack | +0.408300072 ns | +0.408300072 ns |

这些是 pre-layout、ideal-clock、无提取互连寄生的结果，**500 MHz 仍 FAIL**，没有可报告的合格 Fmax 或带活动率功耗结果。当前最差 hold 终点为 ICache 宏 D[0]。DCache 为 4 颗真实 256×64 SRAM，ICache 为 2 颗真实 256×128 SRAM，DFF 为 132509。

| 完整 workload | 当前 cycles | commits | CPI | 相对 R1 cycles |
| --- | ---: | ---: | ---: | ---: |
| CoreMark 10 | 4,223,831 | 3,218,537 | 1.312345019 | +5.1583% |
| Dhrystone 10000 | 5,792,104 | 4,260,629 | 1.359448100 | +1.76485% |

新最差 setup 链为：

`DCache retained address → response 资格 → Split/Service → LSU 最终 load 值公告 → ExecutionOwners 认证 → IQ 同拍 wake/eligible/grant/select → source preg 选择 → RR shift_amount 捕获`

已测 arrival 5.1427 ns、required 1.9163 ns；不含 PMP 或 SRAM read-data arc。路径累计 landmark 约为 response valid 0.8495 ns、LSU notice 1.6238 ns、IQ resolved valid 2.7196 ns、source preg 4.2859 ns。**这些数值只定位同一旧网表的串联结构，不能相减后当作候选寄存级延迟或预测 WNS。** 新寄存器位置会改变负载、选择和映射；其他路径也可能接替最差路径。

本轮方案的可观察验收对象是：

1. 每轮能用实际映射证据确认所声明的组合边界；同时报告全核 setup/hold/pulse/period 与路径迁移。
2. 同配置实际双发射和最终完成合同保持，定向反例不触发错误；不通过让等待离开 IQ 就宣称 CPI 改善。
3. 完整 CoreMark 10、Dhrystone 10000 的 commits、cycles、CPI 和程序/真实 DiffTest 检查可比较；局部 II=1 不替代它们。
4. 架构收益、单项中间态与最终 500 MHz 合格分开。没有证据时保留 UNKNOWN，不以面积或局部时序替代 correctness。

## 2. 只围绕当前链建立周期与 owner 模型

当前 Memory 有两路 `{valid, full tag, data64}` 公告。它无 ready/ack，不持有完成 owner；驻留完成候选可重复发布，成功的真实 raw response ingress 接受可补充空公告槽。公告已包含 load 格式化、split 和逐字节 forwarding 的最终数值。异常不公告；公告机会丢失只牺牲提前供值，原 ResponseIngress/CQ/WB 负责规范完成。IQ/RR 背压不得阻挡物理终端排空。

ExecutionOwners 依据完整生产者 tag、当前 birth 类型与目的 preg、live、kill/flush 认证。规范 WB 接受终结该租约；新 birth 覆盖同槽元数据。**延迟一个 preg-only 的旧认证结果再使用不合法。** 新层保存 full tag，并在消费处重新核对 producer 身份；generation、birth/reuse fence 与局部 Recovery 窗口必须继续成立。

当前认证公告可同拍使 IQ 可选，并在同一个 issue 接受沿直接捕获 RR terminal 的 owner、操作数和 shift 预处理；fallback 则先保存 ingress，后续读出。新增边界的周期代价必须相对此真实分流点计算，不能只相对旧的一般 PRF 读图计算。

以下用 e0 表示“基线当前拍已有可用最终值，且满足当拍 IQ 选择、RR 完整值准入的接受沿”，只比较同一个依赖消费者、无额外背压的可达快路径；它不是 DCache 请求到返回的固定周期承诺。

| 架构点 | e0 | e1 | e2 | e3 |
| --- | --- | --- | --- | --- |
| 当前默认 | 可直接捕获 RR terminal 操作数 | 后续 Execute 资格 | — | — |
| T1 | notice 全包进入公告 Q | Q 后认证、选择，可直接捕获 terminal | 后续 Execute 资格 | — |
| T1+T2 | notice Q | 选中 owner/source 进入 issue capsule Q | 由 capsule Q 读值、准备并捕获 terminal | 后续 Execute 资格 |
| T1+T2+T3 | notice Q | 认证值进入 memo，load 调度状态进入 IQ Q | 仅由 Q 状态选择并捕获 capsule | 由 capsule Q 读值、捕获 terminal；Execute 再按原合同 |

表中 T3 的目标快路径多一次 load wake→select 边界。原本等待较久、已由 WB canonical ready、已在 RR 驻留等情况可隐藏部分或全部新增等待；实际 Execute 和提交延迟由测量给出。每级仍允许两条/拍的连续独立流；依赖延迟增加与稳态 II 不变可以同时成立。

## 3. 三类候选与推荐

| 候选 | 结构区别 | 主要收益假设 | CPI/资源代价与风险 | 建议 |
| --- | --- | --- | --- | --- |
| A：逐段登记 | T1 公告 Q、T2 issue capsule Q、T3 Q 唤醒与值 memo，依次加入 | 把返回资格、身份认证/唤醒、年龄选择、宽值/shift 准备分到可测边界 | 快路径新增拍数；更多时钟负载；可能暴露非 load 路径 | 首选，逐轮比较，允许保留已成立的中间态 |
| B：消费者驻留后接值 | 配合性能方案的提前 load 调度与独立待值站，真实值经公告 Q 注入已登记消费者 | 返回不再负责寻找/选择消费者；可隐藏 A 的部分调度拍 | 需限制 pending owner、避免 HOL、禁止无真值执行与递归 promise 扩散 | 在 A 的已测父点上独立 A/B，不先假定能追回一拍 |
| C：分布式 operand-ready 调度 | 将统一 IQ 的 source 选择/读值前移为每项 operand 预备，局部 bank 选 ready owner | 用面积换短本地唤醒、局部仲裁与已准备值读出 | 更新广播、值复制、全序配对、功耗和验证成本大；局部不平衡 | A/CPI 取舍不理想且剩余路径支持时再做替代实验 |

**推荐顺序是 A 的 T1 → T2 → T3，每轮保留父点。** 不把这写成必须叠满三拍的结论：若 T1/T2 后最差路径迁到无关网络，T3 的优先级应由新鲜路径决定；T3 可作为机制实验，但不能把旧路径的直觉当成新收益证据。B 用于解决已测延迟/占位成本，C 用于较大结构替换，二者不与 A 全部一次堆叠。

## 4. 第一轮 T1：最终值公告整体登记

### 假设与边界

假设 H1：当前最大串联的一部分来自 Memory 最终值资格与执行域 wake/select 在同一拍。把**完整两路公告**登记，可使 raw response 不再组合影响当前 IQ 选择或 RR 捕获。

在 Memory 公告出口至 ExecutionOwners 认证入口之间，设置两路单拍采样寄存器，每路保存 valid、full tag、data64。它是**没有 ready/ack 的公告延迟层，不是 completion FIFO，也不建立新事务 owner**。每拍采样；驻留重复可再次采样；空周期 valid=0。数据与身份始终从同一拍 Q 输出，invalid 周期也不选择 raw payload。宽值可无条件预采样，valid 的清除/认证不应重新控制整段宽值选择。

所有来源一致过 Q，包括 resident 候选与 early physical 补充。只关补充路径、只登记 valid、或者 invalid 时恢复 raw 数据均不等价于 H1。

### 周期、吞吐与恢复合同

- 该机会驱动的 load 消费者最早准入晚 1 拍；已驻留等待或规范 WB 先到时，实际代价可能被隐藏。
- 固定两 lane，每拍最多采样 2 条，不反压、不增加完成租约，II=1/lane；不保证任意公告永不被覆盖，因为原合同本来允许错过提前观察。
- Q 后在实际 IQ/RR 使用处，以保存的 full tag 重新认证。禁止把 e0 的 preg-only 授权移到 e1 直接使用；租约已被 WB 终结时拒绝旧公告，使用规范 WB/PRF fallback。
- reset/fullflush 清公告 valid；选择性取消、当前 local Recovery 和 birth/reuse fence 在消费者处继续抑制。取消与公告采样同沿不能复活年轻 owner。
- 重复公告最多是幂等供值/唤醒；不得重复完成、重复释放、清 scoreboard busy 或创建 ROB done。物理 response、ResponseIngress、CQ、WB 原有流量不等公告层。

**规范完成 fallback 必须零丢失。** 旧消费者须保留原 WB wake、PRF 写入、RR 单拍 WB 捕获/arrival history；新 birth 须保留 deferred Scoreboard 查询、已提交的 PRF 值与同沿 WB 旁路。拒绝旧公告不能抑制这些通路，也不能把尚未捕获真值的 pending 清零。最小三方交叉为：公告 Q 可用、生产者规范 WB 接受、消费者 birth/issue/transfer 在同沿各自发生；随后即使公告不再重复，消费者仍必须执行正确值。重新认证拒绝可以丢失提前机会，不能丢失规范 WB 完成或导致永久等待。

### 预期、最小验证与淘汰

setup 预期：raw retained address/response 到 IQ/RR 的原贯穿锥在公告 Q 终止；新瓶颈可能是“公告 Q→认证→IQ→RR”或其它路径。T1 不保证后半链满足 2 ns。

最小反例是：e0 捕获生产者 A 的唯一公告；e1 A 被 kill 或其 WB 终结；同槽随后 birth B。任何 B 消费者被 A 值解除 pending 都应失败。再覆盖双 lane 不同 tag、同 preg 多合法值一致性、公告重复、IQ/RR 满、resident 占槽与 early 补槽、fullflush 同沿、有异常而无公告。

验证 owner 需给出：定向身份/取消结果、真实两 lane II、公告丢失时规范 WB 仍完成、原程序/DiffTest 与完整两 workload，以及实际 mapped 锥和全局 STA。无需为可逆文档运行测试。

淘汰/修正条件：只登记 valid 未断宽值或身份路径；由公告反压终端；新增重复完成或 stale 值；两 lane 被串成一路；当前 raw 路径仍穿过 Q。若断链已证明但全局最差迁移，不单凭 WNS 未动否定机制；若目标路径群也无改善且 CPI 增加，T1 当前实现受支配，应修正或回退。

## 5. 第二轮 T2：选择结束后才开始 operand 与 shift 准备

### 假设与结构

假设 H2：即使 H1 成立，当前同拍“认证/选择→源 preg 编码→GPR 多路选择/转发→shift 捕获”仍过长。设置真正的 issue capsule 边界，所有需要这条输入路径的 IQ 发射先登记 owner 和 source 地址，operand 准备只读该 Q。

capsule 包含完整消费者 tag、uop/静态预控制、source preg 与 used/fp/pending、LSQ slot、年龄信息。若组合 T3，还必须逐 operand 携带 §6 新增的 expected producer key 与规范值来源状态；这些不是当前 T2 字段已经提供的能力。IQ 真实 issue 接受才把调度持有责任转交 capsule，且只转交一次。移位类型、立即数分类等与数值无关的控制可在 birth/存储时预备；shift amount 必须由最终 B 值产生，不能用未就绪 PRF 或旧 forwarding 值。

每 lane 以两项 capsule 为候选容量，使出旧/进新可同沿而保持 Q-only 信用；再接原 terminal。实际实现可复用原 ingress 存储，只要达到同样边界与连续流合同。容量是显式候选，不把旧 topology 的 1 ingress+2 terminal 当成已足够的证明。满 Q 不借当前 Execute pop；稳态占用一项时持续出/入仍应 II=1。

### 周期、owner 与副作用

- 原完整值直接准入的 ALU/MEM 最早多 1 拍；影响可能不限于 load-use。原已走 ingress 的指令可复用既有读边沿，不应机械再加一层同功能等待。
- 普通 ALU RAW 链、地址生成、分支入口与 dual-issue 热窗口都要独立测；历史“普通 RAW 两拍”不能自动作为改后承诺。
- 取消 capsule 不发布下游 owner；已转到 terminal 的 owner 只由 terminal 取消/消费。transfer 与 refill 使用各自旧/新身份，不把同沿 WB 数值给错 owner。
- WB/ALU/notice 的一次性值必须在输入、capsule 等待、transfer 各位置有合法捕获/fallback；不得因补了一拍就使用旧 PRF 解除 pending。
- Execute 的 MEM/MDU/FP/Serial 仍只消费登记数值齐备的 valid；ALU/分支局部真实值合同保持，不把 local valid 合回共享 FU 仲裁。
- 生效边界必须涵盖宽操作数与 shift 的 D 路径。仅把名字改成 capsule、但保留 IQ 当拍 source 驱动另一条 complete-admit 路径，不满足 H2。

### 预期、验证与淘汰

setup 预期：IQ source 选择只到 capsule D；PRF/旁路/shift 由 capsule Q 起步。认证+IQ 选择和 operand 段各自仍需真实 STA，不给 ns 收益预测。

最小反例是：旧 capsule X 在唯一 WB 值到来沿 transfer，空位同沿 refill Y；X/Y 必须保存不同身份、pending、值和预控制。加入 terminal 两项全满、两 lane 连续不同源、pending 与 canonical ready 混合、FPR f0、x0、第三源、branch/MEM/Serial 及恢复抢占。

验证量除共同完整程序/STA 外，至少包括实际 IQ→RR 与 RR→Execute 接受、ALU RAW/不同 load-use 延迟、capsule/terminal 占用与阻塞。确认没有把零发射改善换成 RR 等待，连续独立流仍双发射。

淘汰条件：新增结构每 lane 只能隔拍进入；ready 借本拍 pop 重建跨级长链；ALU 快路径广泛退化而目标路径群无对应改善；或映射显示 direct-admit 仍绕过 capsule。若 operand 段因 PRF mux 本身成为最差，允许使用复制读口/预解码作为**同一阶段内资源变体**重新比较，不能直接宣称再加寄存器即可收敛。

## 6. 第三轮 T3：load wake 更新与 IQ 选择分拍

### 假设与值保全

假设 H3：在 T1/T2 后，“公告 Q→owner 认证→IQ 依赖匹配→eligible/年龄/配对→capsule D”仍限制周期。当前 load 公告只更新 IQ 寄存调度事实，下拍选择只读 Q；新的认证结果不再当拍修改 eligible/grant/source 选择。

**只有把 ready 登记而不处理单拍值的生命期是不完整方案。** T3 增加执行域内按 GPR preg 索引的实际值 memo，保存 full producer tag、data64、valid；容量候选为覆盖当前 64 个 GPR preg，最多两路 notice 写入，读通道按每拍双发射两整数源配置。它不是第二份 canonical PRF，也不拥有 busy 或架构完成。

- 只有已认证的普通整数 load 真值可填充；IQ 记录的是可提前调度事实。源未获得规范 WB ready 时，仍携 pending，不能把“有 memo”当作 PRF 已写。
- 后续 capsule/驻留消费者读取 memo 时用完整生产者身份再次认证；source preg、命名空间、birth/kill/reuse 必须一致。wide data 由登记地址选，窄认证只决定能否捕获，不重新进入 IQ 选择。
- 每项至对应 WB、取消、重用或 reset/fullflush 为止；WB 接受后转用已授权 WB/PRF，不能靠已终结 ExecutionOwners 租约继续盲供值。匹配的 WB 同沿与 notice 冲突时，以规范 WB 完成/值为准并撤销该 memo 的提前资格。
- 新 birth/reuse 清旧 memo 资格，其优先级高于旧公告安装；同 preg 双有效公告必须同完整身份且同值，否则是错误，不以固定优先级掩盖。
- 更新调度 Q 与 memo 必须使用同一次认证；旧 IQ owner 删除与同槽新 birth 时，不继承旧 wake 事实。
- 现有两拍 birth fence/Recovery delivery 不被 memo 取代。若现有本地事件不足以证明失效及时，实现角色应扩展明确的本地失效/代际合同；不能默认 4-bit generation 永远不会回绕。

这轮把值生命周期设施与“只从 Q 选择”作为同一个完整候选，否则 Q 唤醒可能丢失唯一值而制造大量等 WB 周期。若实现选择允许丢失提前值、只靠 WB fallback，correctness 可以保持，但必须单独标成简化变体，不能与有 memo 方案混报 CPI。

### 消费者操作数与生产者身份的绑定（独立评估后的必要新增合同）

**T3 条件保留。以下目录、逐源绑定及规范值版本记录是候选新增接口/状态，尚未核实为当前实现能力。** 当前 T2 的 consumer tag/source preg 本身不足以实现 T3；T3 必须把下述信息与生命周期一起实现并验证。不能从 preg 查到 memo 内容后，再用同一内容证明消费者本来就依赖该生产者。

**独立的身份来源。** 在 Execution 域内新增 SourceBindingDirectory，按 GPR preg 保存该物理位置最近一次真实 writer birth 的完整 producer tag，以及实际授权 PRF 写入对应的版本标签。前者只由真实 birth/恢复生命周期更新；后者只由已经过生命周期域认证、且实际写 PRF 的 WB 事件更新。它们是权威事件的版本投影，不替代 Scoreboard busy，不从 notice/memo 建立、改写或推断。各版本键至少包含命名空间、preg、完整 producer tag。错误完成、load promise、early notice、memo valid 都不是规范 PRF 写入证据。

**在消费者 birth 绑定，不在消费 memo 时猜测。** 每个使用的 GPR operand 从已完成重命名的 source preg 查询该目录，形成自己的 expected producer key；同时保留消费者 full tag、source 序号和 pending/值已捕获状态。真实双 birth 必须按程序顺序做身份前递：lane1 若依赖同沿 lane0 的新目的 preg，绑定 lane0 的新 producer key；lane0 自己的旧 source 不得绑定到自己的新 destination。相同沿已发生的 writer birth 前递只采用实际 birth，不能采用候选分配。x0 使用常量状态，无 producer 依赖；复位/已初始化的 canonical 源使用明确的初始化版本，其可读性仍由原初始化和 Scoreboard 规则决定。

该键作为 operand 元数据随 **IQ → T2 capsule → RR terminal/独立待值站** 一起转移，stall 时保持，transfer/refill 分别处理旧/新消费者。IQ 删除旧项、新 birth 初始化时不得继承旧键。允许值已捕获的源保存自己的已认证值并解除外部依赖；未捕获源绝不能在之后重新读取“当前 preg 对应谁”来改写 expected key。

**供值与 canonical 切换使用两个不同证据。**

| 操作 | 必须使用的独立证据 | 不允许的替代 |
| --- | --- | --- |
| 安装 load memo | notice 保存的 producer full tag 经当前 ExecutionOwners 认证，并与真实 birth 目录的当前版本一致 | 仅凭 preg 或 memo 旧标签认证新 notice |
| IQ 保存提前可调度事实 | 消费者 expected key 与该认证 notice key 一致；仍保存 pending | 只匹配 preg 就设置 canonical ready |
| capsule/驻留源读取 memo | operand expected key = memo key = 当前有效 producer 身份；再次认证后捕获实际值 | 由 memo 返回的 key 临时构造 expected key |
| 已有未捕获源接收规范 WB | 已授权实际 PRF 写事件的 key = operand expected key；原 WB 捕获/旁路保存该值，或标记需读同版本 PRF | 只看到 ExecutionOwners 租约消失就清 pending |
| WB 之后读取 PRF | operand expected key = 该 preg 当前分配版本 = 实际 PRF 已写版本，且唯一 Scoreboard 报告 canonical ready | memo 失效、owner 不存在或 preg 数字相等 |
| WB 之后的新消费者 birth | 从真实 birth 目录取得版本，以上述规范 PRF 已写版本/Scoreboard 事实初始化；同沿 WB 走下述原子规则 | 依赖已消失 notice 再唤醒一次 |

因此 producer 的 ExecutionOwners lease 可以在 WB 后终结，而其已写 PRF 的版本事实继续保留；二者不是同一 valid。fullflush 清投机消费者、memo 与被取消 producer 的提前资格，但不能无故抹去恢复后仍由 committed map 引用的 canonical PRF 版本。只有实际 PRF/reset 初始化或后续真实写入改变相应数据版本。此恢复投影如何接入当前接口仍需实现角色核实，不能把 fullflush 后所有源当成未初始化。

**同沿优先级以身份和 owner 分开定义。** reset/fullflush/选择性取消先剥夺受影响消费者和提前结果的消费资格；仍合法的 older WB 与外部排空保持原合同。其余并发按以下原子效果解释：

1. 对旧存活消费者，先用其沿前 expected key 对照当沿已授权 WB；匹配即捕获值，或沿后走该版本的 PRF fallback。旧 capsule transfer 使用这一有效结果，再处理新项 refill。
2. 对同身份的 notice 与 WB，WB 是规范值来源；更新 PRF 已写版本/原 Scoreboard 事实，撤销 memo 提前资格。不得因为撤销 memo 丢掉该唯一 WB，或保留 pending 等待不会再发生的公告。
3. 同沿新消费者 birth 按重命名后的 source 和真实 writer birth 前递取得自己的键，再结合匹配的当沿 WB 形成沿后 canonical 状态；它不继承被删除 IQ 项的键。即使错过公告，也可在后续读已写 PRF。
4. 同 preg 的新 producer birth 更新当前分配版本、令新版本 busy，并使旧 memo 失效，优先于旧 notice 安装。旧 WB 即使获准写入，也只记录其旧 PRF 版本，不能清新版本 busy、不能授权新消费者；新版本须等自己的真值/WB。
5. 若旧消费者仍需从该 preg 读取值，同 preg 复用不得使其未捕获绑定悬空。实现必须证明现有分配/退休/恢复规则对此成立；若同沿先捕获了旧值，旧消费者可继续使用已保存值。发现未捕获旧依赖与真实复用同时存在，应报合同失败，不能无限等待、改绑新 owner 或延迟不可取消终端来掩盖。

**代际与事实 GAP。** 完整 ROB tag 的有限 generation 必须与上述绑定、memo 和 birth/reuse 规则一起证明无别名；不假定它永不回绕。若不能证明旧观察状态在同一完整 key 再次出现前已经失效/捕获，就必须新增明确的 allocation-version 及其回绕合同，或淘汰有 memo 的 T3。目录的具体输入接口、same-birth 前递、恢复后的 canonical 版本保留与无悬空复用，目前只有候选合同，没有实现证据。缺任一项时 T3 仍为条件候选，不能交给 worker 仅添加 preg-indexed memo 就声称合同闭合。

最小新增反例包括：同沿 lane0 producer/lane1 consumer birth；notice Q + producer WB + 新消费者 birth 三者同沿后公告永久消失；旧 capsule 捕获 WB/transfer 与新项 refill 同沿；旧 WB + 同 preg 新 writer birth；生产者错误完成无 PRF 写；恢复后 committed-map 源仍能读 canonical 值；足够次数的槽/generation 重用。每例分别检查 expected key 来源、实际捕获值/PRF版本、pending 终结和无悬空依赖，而非只检查 memo 内部标签自洽。

### 周期、吞吐与恢复

尚未 canonical ready 的 load 消费者最早再晚 1 拍获得选择资格；独立已 ready 操作不因这次 load notice 的更新停顿。wake 接收 2 路/拍，IQ 出口仍 2 路/拍；memo 读写冲突若引入资源停顿，必须单独计数且不破坏进度。

本轮首先只处理新鲜 load notice→IQ 选择路径；若 ALU/WB 同拍 wake 仍是最差，需按新路径证据设计后续变体，不把它们悄悄归入 T3 并将额外 ALU 延迟全部归因 load。Execution.Scoreboard 仍为唯一 busy 真源。

### 预期、验证与淘汰

setup 预期：认证/匹配终止于 IQ 调度 Q 与 memo Q，年龄/兼容/端口预算选择只接收登记资格。可能出现高扇出 wake 写使能或 memo 读的新最差路径，面积充裕不消除布线/功耗风险。 新增身份目录、双 birth 前递、恢复版本维护与多源读网络的时序代价仍 UNKNOWN；T3 的实际路径比较必须同时观察 birth、恢复和多读网络的路径迁移，不能只检查原 load-return 链，也不能把目录标签相等当作第二份 busy 授权。

最小反例是：load A 唯一真值公告后数拍 IQ 无法选择；其后 WB、cancel、同槽/同 preg 新 birth 分别发生。消费必须得到 A 的合法值或规范 WB fallback，永远不能命中被重用的 memo。另测同沿 notice+WB、双 notice 同/异 preg、IQ 同槽删旧生新、两路 reader 同项、pending consumer 被 flush、序列化与精确 fault。

淘汰条件：真实 busy/PRF 语义被 memo 取代；有限等待后失去规范 WB 进度；只凭 preg 读取跨代值；为了双写/多读建立新的同拍全局仲裁链；结构切分和 setup 无改善、CPI 却继续变差。若 wake 写扇出成为限制，下一步应评估候选 C 的局部化，而非无限堆 memo 或扩大 IQ。

## 7. 面积宽松时的较大替代：operand-ready 分布式调度

候选 C 用“更多状态与局部读资源”替换后段关键网络，不只是加深 A：

- 以当前 IQ16 为比较容量，候选划分为 4 组×4 项；每条消费者只在一个 home group 持有调度 owner。每组保留源身份、used/pending、实际已捕获值和静态控制；ready 由本地寄存事实给出。
- 生效前尚未有真值的源继续 pending；规范 PRF 读、已认证公告和 WB 逐步填充本地值。即使重复值存储，canonical PRF/Scoreboard/ROB owner 不变。
- 每组最多提出两名本地候选，全局只做组间最终双选择；**同组必须能贡献两名**，不能把固定一组一路造成的单发射伪称保留双发射。Serial、年龄、FPR预算及 FU 配对仍施加原合同。
- 全局选择输出只捕获已登记值/身份；不在最终 select 后重新读大 PRF、做 source tag 搜索、或拿当前 notice 解锁 operand。shift 类型可预备，shift amount 仍由已认证 B 值产生并登记。
- 可复制 GPR/FPR 读视图或用更多物理读端口完成预读，所有副本由同一授权 WB 与初始化规则更新。若扩展 FP 读口，需单独说明对原配对预算的变化，不能当成免费 dual-issue。
- 取消、同沿生灭与 WB 配对由各 home group 核对；引用的是 producer full identity。值副本既不能延长 ROB owner，也不能独自阻塞不可取消总线排空。
- 分配不应静态按指令类别绑死 home group；home 空间不足、组间仲裁、公平性和等待龄均需观测，避免全局空位仍阻塞的结构退化。

它可能缩短局部匹配和全局多路选择，但新成本包括多副本写入、broadcast 扇出、额外 clock sinks 与 home 失衡；尚无 ns/CPI 预测。最小反例至少包含同组两个最老 ready、另一组更老受 Serial 阻挡、广播只命中一个源、跨组相同 preg、取消与 home 重用。若只支持每组一名、必须重复存调度 owner、或源值更新仍组合穿过全局选择，则不满足候选定义。

C 与 A 的公告 Q 可组合；C 的 operand-resident 方案替代 T2 capsule/T3 memo 的一部分，不能把两套值与 owner 体系简单相加。C 与性能候选的独立待值站 P2 首先择一比较，避免无法判断收益来自容量、局部化还是新增路径。

## 8. 与性能方向方案的组合点和冲突

另一个纯架构方案由独立 agent 编写于 [性能方向方案](performance-architecture-rounds-20261013.md)。下表是本轮纯架构交流后的组合合同，尚未实现或验证；以独立评估后的统一版本为实现输入。

| 性能候选 | 可组合点 | 必须避免的冲突 |
| --- | --- | --- |
| P1：translation request 真实接受后登记 load 调度提示 | 消费者可在 T1 公告抵达前进入受控等待，隐藏部分 T1/T2/T3 调度拍 | 翻译尚未证明权限/PMA，不得把事件称为 hit/RAM/成功；只允许受限 pending ALU，不能产生数值、清 busy、设置 done 或递归发出无值 promise；事件也必须登记，不能新增 translation accept→IQ 当拍链 |
| P2：独立待值站（先单信用迁移，再扩容/加宽） | 已登记消费者直接从 notice Q/memo 捕获实际值，值齐再通过登记资格进入 Execute；减少现有 RR 被 pending 占满 | 从 IQ 真正移交的消费者只能有一个调度 owner；先以 P2a 保持单信用/单 lane 做位置迁移，P2b 再将同 lane 容量扩至 4，P2c 最后变更双 lane 映射；保留固定仲裁、取消与公平进度，不把 ready 组合穿回 IQ/LSU 信用；与 C 先择一实验 |
| P3：DCache 读视图复制/同 bank 并行 | 在真实 bank 冲突限制下改善供给；与返回边界 T1 正交 | 新候选响应仲裁/合并不能绕过 notice Q；SRAM 写广播与维护 owner 必须一致。当前最差无 SRAM read-data arc，不能称为针对当前 setup 的首刀 |
| 扩资源隐藏延迟 | 证据支持时增加待值容量/读口，仍 2-wide | 不凭面积许可盲增 ROB/IQ，也不把重合 blocker 百分比相加当可恢复周期 |

P1 的首选事件已从较晚 physical request accept 调整为 translation request accept，原因是要取得更多潜在提前量；这是设计假设，不是当前 profile 已证明有多少隐藏空间。fault、IO 或长 miss 可以使它等待很久，因此其容量限制与 P2 进度合同是实质必要条件。

性能方案若只让 IQ 提早变空，而实际 Execute、commit 与 cycles 不改善，不视为成功。P1 要同时保持独立指令通道进度；在现有 RR 上实验时，P1 仅允许一个待值简单 ALU 消费者进入整个 capsule/ingress/terminal 均空的 lane1，并从接受到离开/取消以 Q 状态独占该 lane；后续普通 owner 不得排在它后面，必要独立操作由 lane0 前进。若 lane0 不能保证这些操作进度，P1 淘汰。这样才能排除较老 store 尚未 bind、load 等该 store、消费者等 load、store 又排在消费者后的循环等待；不能只凭“最多一个 pending”宣称安全。

## 9. 实验组织、证据与停止条件

| 轮次 | 唯一主要假设与父点 | 周期/吞吐预期 | 必须回传的最小区分证据 |
| --- | --- | --- | --- |
| T1 | H1；当前 R3 默认 RTL，同口径 R4 clock 处理 | 依赖该公告的准入机会 +1；两路公告/拍，不反压 | raw→IQ/RR 真正被 Q 截断；full-tag 重认证/丢公告 fallback；完整 CPI 与 STA |
| T2 | H2；保留已测 T1 父点 | 原直接准入项 +1、旧 ingress 可复用；每 lane II1 | IQ source→operand 的边界；ALU/load-use 延迟与连续双发射；capsule/terminal 占位、完整 CPI/STA |
| T3 | H3；保留已测 T1+T2 父点，或依新鲜路径调整顺序 | fresh load wake→选择 +1；已 ready 流不变，memo 读写需达到预算 | IQ 选择仅 Q 资格；一拍值跨等待/reuse/WB 正确；路径迁移、完整 CPI/STA |
| 条件后续 B 或 C | 从最合适的已测 A 父点分支，不混合换基线 | 尝试隐藏已测额外等待或以资源替代阶段 | 对应瓶颈必须先有因果计数；单独与父点比较，保留非收益/失败结果 |

实现与验证角色持有原始材料；Architect 只接收版本/配置/工况、测量/推断、owner/周期摘要及来源指针。正常实验不需要额外 receipt、固定 YAML 或人为审批阶段。

共同测量需保持 R64CoreTop、实际生产配置/filelist、ICS55/ECOS 宏、TT/2ns/0.05ns uncertainty、tool/约束、相同 clock buffer 处理和完整 workload 一致。可以分别保留 raw 与 repaired 结果，但不能以 T1 raw 对比 T2 repaired 归因架构。新副本/端口不许被意外 blackbox、DFF 回退或剪掉。面积/DFF/宏/clock-sink 数记录真实变化；本任务不以原面积预算淘汰方案。

定向验证覆盖对应反例后，用原程序检查、CRC/真实 DiffTest 和完整两个 workload 验证实际影响；受影响配置/系统/ISA回归由验证 owner 按范围完成。7 个既有双发射热窗口可作稳态检查，不能取代新增待值/恢复反例或完整 workload。确定性配置默认一次，只有失败、噪声或新变更才增加重复。

当前 aggregate 观察中，CoreMark IQ block 18.96%、Dhrystone 0.0067%，ROB block 分别 11.4149%/39.8585%，均非互斥原因；没有 protection 额外拍的因果分解，也没有 RR pending/full、bank 维护与 miss owner 的分解。本轮只要求补充会区分候选的有限量：最终公告到消费 Execute 的依赖延迟、待值占位/挡住独立工作、实际双发射、规范 WB fallback 与新边界接收率。不能据 aggregate 百分比预报 CPI 可恢复比例。

停止/淘汰按下列事实决定：

- 任何 correctness、owner、副作用、进度或双发射合同违反，当前候选不能作为默认收益点；修正后重新比较，不放宽 checker。
- 未形成声明边界，应修正实现或淘汰该具体做法；不能用“RTL 看起来分级”替代 mapped 证据。
- 局部路径已改善而最差路径迁移，是下一轮问题定位；既不保证应长期保留，也不等于本轮毫无作用。
- 在同口径下，目标路径群/全局 setup 无收益且完整 cycles 更坏的候选受支配；不能靠面积宽松继续无条件叠级。
- 尚无合格频率时不报告执行时间改善；同为合格 500 MHz 时，cycles 增长就是运行时间增长。不可把 WNS 代入公式估 Fmax。
- tool/环境失败或不匹配的 A/B 是证据 GAP，不是机制被反证。正式 Architecture/Pareto promotion 另需真实证据与独立审查，本文不执行 promotion。

## 10. 架构与物理实现的责任分界

| 问题 | 架构责任 | 实现/时钟/物理 owner 责任 |
| --- | --- | --- |
| 长组合串联 | 明确寄存边界、owner 生命周期、周期/II、数据与资格同龄、恢复/副作用合同 | RTL 实现及真实 mapped cone、setup 路径、约束覆盖；不得让旁路穿回 |
| ICache 宏 D[0] hold | 保持正确采样周期/宏接口语义；新增流水也必须保持最短路径可验证 | 取证具体 min path、库/corner、clock skew；适当数据延迟/缓冲/布局和 hold 修复，并复查 setup |
| ICG/pulse/CTS | 报告新增 clock sinks 与活动率风险；允许合理寄存/复制但不承诺免费时钟 | 真实 buffer/CTS、合法 Liberty load/slew、pulse/period、寄生与适用 corner；R4 只是映射级处理 |
| 功耗 | 以局部化、实际事件驱动、避免无效多副本广播为候选，保持 wake/progress | 带活动率功耗与时钟树测量；无结果时明确 UNKNOWN |
| 500 MHz 结论 | 用同口径 correctness+CPI+STA 摘要判断是否值得继续 | 满足全部适用 setup、hold、pulse、period 和物理证据，不以单一 WNS 或 buffer 通过代替 |

不以新增流水声称修好了 ICache hold，不用 false-path/multicycle、降低频率、更换更松 workload 或 SRAM 模型制造通过。更多寄存器可能增加短路径、时钟负载和功耗；这些是需测的代价。若 hold/CTS 与架构实现没有共享可变资源，可并行推进，不让一个领域的未闭合伪装成另一个领域的收益或权限障碍。

本方案供全新独立评估角色重点检查：T1 延迟公告在 WB/复用后的认证；T2 对非 load 快路径的真实代价；T3 memo 是否悄悄成为第二份 ready/owner 真源；P1/P2 是否导致 wait-owner 堵住进度；三轮假设是否可由指定证据独立反证。当前建议只代表实验顺序，不代表任何新时序、CPI、功耗或 500 MHz 达标结论。
