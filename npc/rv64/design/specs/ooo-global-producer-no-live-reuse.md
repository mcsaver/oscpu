# OoO 全局 ProducerId 持有者与有限代际不复用合同

> 状态：V11N current-production-top 审计合同。字段 census 与
> `NpcTop` product elaboration instance graph 已闭合；44 个语义单元中 27 个
> 具有当前或明确限定的 source-bound 正/负向语义证据，余下 17 个保持 GAP。
> 因而全局 no-live-reuse、完整双 memory、系统级验证、全核 architecture promotion
> 和 PPA 仍按 `../arch/rv64-architecture-ppa-contract.md` 保持 RED/unpromoted。

## 1. 身份与出生门

唯一事务身份为：

```text
P = {generation, rob_index}
```

ROB 的 `dispatch*_generation_candidate_w` 是出生身份唯一来源。dispatch guard、ROB 写槽和
下游 capture 必须消费同一个 exported P，不允许分别重算 generation，也不允许只用
`rob_index` 查询 lease。ROB 不借用同拍 commit 空位，generation 加法显式限制在
`PRODUCER_GEN_W` 位，因此回绕是定义明确的模运算。

```text
complete_live[P] = external_live[P] OR integer_iq_live[P]
dispatch_fire(P) -> !complete_live_old[P]
```

所有 birth ready/fire 都只读 edge-old Q holder。新出生 P 不得自阻塞；旧 holder 在其死亡沿
仍阻塞，只有下一周期才释放。

## 2. 当前生产 holder 域

完整机器清单是 `../arch/producer-holder-census.json`，由 checker 按字段和 packed stage
逐项核对。当前域分为：

- 直接 full-P Q：integer/FP IQ、EX0/EX1、memory reservation、retire-resident LQ、
  MulDiv、CLMUL、FP arith/exec1/long/done FIFO、branch resolve packet、dispatched
  pending system/CSR；
- tracker 映射：memory owner token 在 `OooMemOwnerTracker` 中不可变映射到 full P；
- 间接 token Q：memory reservation/buffer/pending、MIQ、SQ、AXI bridge 和 terminal
  collector。任一 resident token 必须属于 tracker 的 edge-old `live_q`；
- ROB generation authority：`slot_generation_q`。ROB 本体不是额外 lease mask，因为槽在
  commit 前不会被重新分配，且不借同拍 commit 空位；
- EXEMPT：pre-ROB control/trap metadata、组合 wire、ready/fire/next-state、断言 shadow 和
  allocator cursor。EXEMPT 不得独立授权 WB、redirect、memory side effect 或新出生。

Integer IQ 的源依赖是 physical-register tag + sticky-ready，不是 ProducerId；当前唯一 full-P
字段是 uop owner `producer_id_q`。今后若新增 full-P source tag、replay/skid/completion FIFO、
redirect packet 或 owner-token Q，静态 checker 必须先 RED，直到清单和 lease 证明同步更新。

## 3. Memory 原子交接

IQ memory owner 只在 tracker 分配成功时离队：

```text
capture_candidate = present && current_P
capture           = capture_candidate && tracker_alloc_ready
IQ_pop(memory)    = stale_drop || capture
STORE_bind        = capture && owner_kind==STORE
```

若 tracker backpressure，IQ 不 pop、reservation 不 capture、SQ 不 bind。成功交接沿由旧 IntIQ Q
lease 覆盖；下一拍 reservation Q 与 tracker Q 同时出现，且 token→P 映射保持稳定。MIQ、SQ、
buffer、bridge 与 terminal collector 只携 token 的阶段必须满足：

```text
indirect_resident_token_set subset_of tracker_live_q
```

STORE 在 dispatch 后、issue 前由 IntIQ lease 覆盖；bind 后由 tracker lease 覆盖。SQ 的 raw
full P 另由独立 assertion 扫描，防止 token handoff 或清单遗漏制造空窗。

ordinary LOAD 在 dispatch fire 时同时建立 LQ full-P holder；其 lease 横跨 reservation、MIQ
transport、formal WB 与 ROB retirement。branch recovery 后已 launch 的 incomplete load 以 killed
tombstone 继续持有 full P，直到精确 memory terminal；因此 LQ mask 不能退化为 MIQ occupancy mask，
也不能在 normal transport terminal 上提前清除。

normal terminal 可以先于 formal completion 到达。LQ 必须以 `terminal_seen_q[]` 记录该精确事件：
entry 仍保留到 ROB release，但不得再次 issue/query/response；后续 recovery 对该 entry 直接 clear，
不得转换成等待第二个 terminal 的 killed tombstone。同一 full ProducerId 的第二个 normal terminal
是合同违例，必须由断言拒绝；不得增加去重/吞事件逻辑来制造 PASS。

collector pending 期间 tracker token→ProducerId 映射必须保持 edge-old 稳定，dequeue/free
同沿 allocation 不得借用该 token。LQ entry 已清且 tracker 随后 exact-free 后，
production response/drop/reservation/buffer/retry source 必须永久结束旧 tuple 的发射资格。
若旧 `{kind,token,epoch}` 跨越 allocator cursor 环回，在同 token 已绑定新 ProducerId 后再次
到达，collector 的局部 tuple 比较会把它解释为新 owner；因此 source one-shot 与 holder census
是承重合同，不能被“collector 会自行去重”的假设替代。V11I 要以 assertions-on/off 的真实
32-token 环回和 compile-success stale-source variant 分别证明 production 静默与 fail-loud
敏感性。

所有本地 holder 还必须满足 `valid => identity known`：有效 full-P Q 在参与 onehot/位图索引前
必须是确定的二态值，有效 token Q 在参与 tracker/residency 索引前也必须是确定的二态值。该约束
由 holder 所在模块的 raw Q 断言承担，顶层 union/subset 断言不能替代它；否则 X 索引可能让
“没有遗漏”的比较本身变成空洞值。

## 4. 自动发现与验证

日常入口：

```bash
make -C npc/rv64 check-producer-holder-census
make -C npc/rv64 check-contract
make -C npc/rv64 check-global-producer-no-live-reuse
```

checker 会：

1. 去除 comment/string 和 `OOO_ASSERT` shadow 后，枚举全部
   `[PRODUCER_ID_W-1:0] *_q` 字段；所有 exact-width `reg/logic` 即使不以 `_q` 命名也必须进入
   显式组合豁免表，防止用命名变化绕过 holder 发现；
2. 递归解析 `PipeStageReg.WIDTH`，枚举所有含 ProducerId/generation 的 packed stage；
3. 枚举 production `_token_q` 字段，并要求每项归类为 indirect holder、derived alias 或明确的
   allocator cursor exemption；
4. 锁定 Q-only union、full-P guard、ROB candidate/store 同源、memory tracker、FP union 和
   SQ observational owner view；
5. 输出 manifest/checker/逐源文件 SHA-256 与 source-set SHA-256；
6. 运行 compile-independent mutation self-test，证明新增字段/packed stage/token、删 IntIQ
   union、改 raw-index lookup、manifest 自我晋级都会 fail closed。

动态门还必须运行 v8l focused runner：assert/release、真实 `GEN_W=1`
allocate→issue→WB→commit 整圈回绕、死亡沿、memory tracker backpressure/cancel/recovery，以及
compile-success semantic mutation。TB reference 直接扫描 raw Q holder，不复用 production mask。
`check-global-producer-no-live-reuse` 是该动态门的长期入口；它先运行静态 census，再执行绑定 task-run
runner，并要求 mutation 先成功生成 vvp 后才允许以预期运行后果计为击杀。

## 5. 声明边界

静态 census PASS 只表示当前 source-tree 的字段级清单闭合。V11J 以当前 product
配置重新 elaboration，证明 15 个 holder module 仍对应 17 个实例和 194 个可达实例，且两个
`OooMemInflightQueue` 与两个 `OooMemAxiBridge` 实例保持独立可审计；因此
`instance_graph_complete=true`。

V11B/V11C/V11D/V11E/V11F/V11G/V11H/V11J/V11K/V11L/V11M/V11N
语义账本将 44 个 census 单元展开成 50 条
unit×instance 绑定。当前
`terminal-output0-token`、`terminal-output1-token` 和 `terminal-pending-set`
通过 12 路 ingress lane、2 路 tracker-free lane、accepted-only transfer authority、
非对称 output turnover/hold、unknown-value 断言与 3 个 compile-success RTL
反例的联合检查；`memory-tracker-producer-map` 与 `memory-tracker-live-set`
通过 assert/release 2/2、4 类 X-known 负向、逐沿 exact token→ProducerId/kind/epoch
scoreboard，以及关闭 checker/`OOO_ASSERT` 后仍由 TB 拒绝的 9 个 compile-success
RTL 反例。`tracker-next-token-cursor` 另由完全基于 stimulus 与沿前 expected
live/PID/cursor 状态的参数化 scoreboard 核对 4-token 与 production 32-token
配置；assert/release 四个 profile 覆盖 lane0/lane1-only、双出生、blocked lane、
原子单 credit、idle/full hold、exact/bulk death 同沿不可见、全环扫描与回绕，
并在关闭 `OOO_ASSERT` 后拒绝 9 个 compile-success cursor RTL 反例。生产
`OooMemOwnerTracker.v` 未修改。

`rob-slot-generation` 由 V11E 沿前独立 generation/valid/done/head/tail/count/
recovery model 逐沿核对全部 16 个 slot；`PRODUCER_GEN_W=1/4` 的
assert/release 四个 profile 覆盖 lane0 actual、lane1 actual、lane1 pair candidate、
accepted-only write、ordinary flush 保留、hard reset seed、selective-recovery
walk carrier、commit/reuse、full ROB 连续两沿拒绝、full+commit 不借槽，以及
current/completion/resolve 对每个 generation bit 的 exact query。关闭
`OOO_ASSERT` 后，17 个 compile-success RTL 反例在两种 generation width 下的
34 个仿真均由同一独立 oracle 拒绝；production `OooRob.v` 未修改。有限位宽
回绕后相同 ProducerId 再现仍由外部 holder collision fence 决定，不被误写成
`OooRob` 局部缺陷。

`integer-iq-producers` 由 V11F 的 stimulus-owned 八槽 full-ProducerId list
逐沿核对 raw `valid_q/producer_id_q`、Q-only live mask 与 issue/pair carrier；
`PRODUCER_GEN_W=1/4` 的 assert/release 四个 profile 覆盖双出生、full 拒绝、
READY/recovery 保持、非零 index overtaking、单/双 terminal fire、同沿替换、
memory pair READY-low 与 pop2、ROB-index 回绕 selective kill、flush/reset。
oracle 不从 DUT mask 或 raw Q 反推 expected；关闭 `OOO_ASSERT` 后，20 个
compile-success RTL 反例在两种 generation width 下的 40 个仿真全部由同一
`[V11F-INT-IQ-ORACLE][FAIL]` 路径拒绝，包含 lane0/lane1/compaction 三类
X-bearing full-P 反例。production `OooIntIssueQueue.v` 未修改。

`store-queue-producers` 与 `store-queue-owner-tokens` 由 V11G 的 stimulus-owned
四槽 entry/owner tuple model 逐沿核对；GEN_W=1/4、assert/release 四个 profile
和 24 个 compile-success RTL 反例的 48 次 assertion-off 仿真均闭合。production
`OooStoreQueue.v` 未修改。

`load-queue-producers` 由 V11H 的 stimulus-owned 四槽 model 核对 raw
`valid_q/launched_q/completed_q/killed_q/terminal_seen_q/producer_id_q` 与最终 PA
metadata。GEN_W=1/4、assert/release 四个 profile 覆盖 normal terminal 先于
completion、terminal 后 recovery、killed drain、retire reuse、同沿
launch/completion/terminal recovery priority；31 个 compile-success RTL 反例在
两种 generation width 下的 62 次 assertion-off 仿真全部由
`[V11H-LQ-PRODUCER-ORACLE][FAIL]` 拒绝。pre-fix 反例固定为
`count=1/live=1/killed=1`，production 修复增加 `terminal_seen_q[]`。
production RTL 还必须以 `[V11H-LQ-PID-KNOWN]` 直接断言
`valid_q => full producer_id_q known`；GEN_W=4 unknown-generation probe
必须失败，而四个合法 profile 与 ordinary LQ/parent 回归不得误触发。

`bridge-active-token`、`bridge-response-token`、`bridge-stage-token`、
`bridge-verified-token-alias` 与 `bridge-residency-set` 由 V11J 的
stimulus-owned 双实例 tuple/residency oracle 闭合。32 个 profile 包含
assert/release production、kind/epoch X 注入和 13 个 compile-success RTL
反例的 assert/release 双配置；26 次负向仿真必须全部被拒绝。oracle 每拍分别核对
`u_bridge0/u_bridge1` 的 stage、active、response、verified
`{kind,token,epoch}` 与完整 32-bit residency set，不从 DUT query 或 raw holder
反推 expected。三个 ordinary bridge regression 也必须同时 PASS。
production `OooMemAxiBridge.v` 的唯一改动是 `OOO_ASSERT` 下新增
`[V11J-BRIDGE-*-TUPLE-KNOWN]`，不改变 release FSM、holder 或 datapath。

V11K 对两个产品 `OooMemInflightQueue` 实例使用 stimulus-owned 固定
owner-tuple schedule，覆盖 capture/hold、cross-instance reject、flush/kill、
exact consume 与 32-bit occupancy exact-set。canonical attempt-3 包含
2 个 production baseline、12×2 个 compile-success RTL 变体和
4×2 个 accepted-push/valid-head-pop X/Z interface probe；三个普通回归
分别绑定 7/7/43 个执行输入及 `.vvp`/post-hash。生产差异仍只位于
`OOO_ASSERT`；V11J/V11K 完整两态 Yosys JSON 均为 130 modules、
176087 cells，canonical logic SHA-256 相同。

V11L 对 `OooIntBackend` 的两路 memory retry producer/token holder 使用
stimulus-owned edge model。GEN_W=1/4、assert/release 共 34 个 profile、
32 个 compile-success release mutation 和 3 个 ordinary regression 均闭合；
四个 `memory-retry{0,1}-{producer-cache,token}` 单元在当前产品实例上晋级
PASS。production `OooIntBackend.v` 未修改。

V11M 对两路 memory reservation producer/token holder 使用 generation=1、
owner token 28/29→30/31 的完整位宽 identity，逐沿覆盖 pair birth、READY=00
hold、READY=10/01 lane isolation、request→MIQ exact transfer、local terminal、
selective/global recovery、pair turnover 与 tracker death。assert/release
baseline、37 个 compile-success release mutation 和 3 个 ordinary regression
形成 39/39、37/37、3/3 的 current-bound 证据；其中两路 ProducerId generation
truncate 与两路 token high-bit truncate 均成功编译并由 lane-exact oracle
拒绝。四个 `memory-reservation{,1}-{producer,token}` 单元晋级 PASS。
token 28 的 testbench cursor 注入只证明 holder 位宽，不外推 allocator 自然
可达性；production `OooIntBackend.v` 未修改。

V11N 对 `OooIntBackend` 的 singleton memory-pending ProducerId cache/token
使用 stimulus-owned generation=1、owner token=28，覆盖 AMO birth、read
pending hold、read→write phase、write-grant stall、write fire 后 hold、
lane0 final、lane9 interphase cancel、read fault no-lane9-duplicate 与 tracker
death。dispatch lane1 的 AMO 只验证为调度到 execution terminal0；
`issue1_is_amo_w=1'b0`，不得把它误写成 terminal1 AMO。GEN_W=1/4、
assert/release 四个 baseline 与 13 类 compile-success release mutation 的
26 次仿真全部闭合，三个 ordinary regression PASS。expected PID/token 不读取
DUT pending holder，full-width capture/read/write/lane9 截断与错误相位 mutation
均由 exact-stage oracle 拒绝。`memory-pending-producer-cache` 与
`memory-pending-token` 晋级 PASS；production `OooIntBackend.v` 未修改。

`memory-buffer-token` 不由 V11N 代替。当前 product `ENABLE_DUAL_MEM=1` 下 legacy
buffer path 为参数静态关闭，但在建立 product-inactive exemption 或配置专属动态
证据前，该单元继续保持独立 GAP。

局部证据重放必须区分绑定强度。V11B–V11H 的旧 full-design snapshot 不得改写
design-id；仅当 policy 中逐项列出的 RTL、include/filelist 与 testbench SHA-256
全部仍匹配当前工作区时，台账才可标记
`CURRENT_SELECTED_SOURCE_AND_TB_BOUND`。V8L 的旧 full snapshot 因 LoadQueue
变化只能标记 `HISTORICAL_FULL_RTL_BOUND`。V11H focused attempt-4 原始
`FAIL@semantic-ledger-unit` 永久保留；独立 checker replay 只消费冻结的 4 个
正向配置、1 个 raw-Q assertion probe、31×2 负向仿真及 pre/post 输入，
生成新 PASS receipt，且明确历史 full-RTL snapshot 不是当前设计，只允许以
未漂移的 LoadQueue RTL 与两份 TB 作 selected binding，
`rtl_simulation_reexecuted=false`。系统边界
必须用 exact object 记录 local closure 不要求重跑、system promotion 要求重跑、
当前未运行；字段删除或弱化必须 fail closed。

其余 17 个单元继续记录具体覆盖缺口，所以
`semantic_complete=false`，global no-live-reuse 仍为 RED。

不得把字段 census、实例图或 27/44 局部语义 PASS 单独外推为完整架构 GREEN、
系统级 GREEN、200 MHz、Power 或 PPA promotion。只有所有 44 个单元在各自
product instance 上具备当前 source-bound 正向、反例与语义 oracle，且全局门重新验证，
才允许晋级 global no-live-reuse。

V11H 修改了 production core RTL 语义，因此旧 A3 系统 evidence 不再是当前设计绑定。
新的完整系统运行是未来 system-level promotion 的前置条件；本地 focused closure 不自动
启动该高成本运行，也不能用旧 A3 checker replay 代替当前设计的系统验证。V11J
断言增量以及 V11K/V11L/V11M/V11N 的 verification-only 增量本身不增加新的完整系统
重跑触发条件。
