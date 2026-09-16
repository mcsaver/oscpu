# OoO 全局 ProducerId 持有者与有限代际不复用合同

> 状态：V14H current-production global closure。字段 census 与
> `NpcTop` product elaboration instance graph 已闭合；机器账本当前为 44/44
> semantic PASS、50 条 unit×instance binding 无局部 GAP。V14H 显式合并 V14G
> current dynamic fence、V11B/C/D/E/M 支撑证据与 NpcTop optional lane1 恒低产品接线，
> 因此仅 `global_no_live_reuse=GREEN`；全核 architecture 仍为 RED，当前设计系统重认证
> 仍为 REQUIRED，PPA 仍为 UNPROMOTED。

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

当前动态门运行稳定 V14G runner，而不再执行历史 task-run 中的 v8l 脚本。runner 将
`tb_ooo_int_backend_v14g_global_owner_fence.svh` 通过三个唯一 anchor 注入临时 TB；共享
`tb_ooo_int_backend.sv` 保持 SHA-256
`2eea52178419fe53d741bca48a78f8edca09e11af93be256ec8466ba11b23613`，避免无关测试新增使已有
source-bound evidence 整体漂移。临时 generated TB、负向 RTL copy 与 vvp 在判定后全部删除。

V14G 对 `PRODUCER_GEN_W=4/1` 分别运行 assertions-on/off，共 4 个 production baseline；真实 LOAD
从 IntIQ Q 经 capture edge 交接到 reservation+LQ+tracker，flush 通过 collector ingress lane6 的
精确 `{kind,token,epoch}` 进入 pending，tracker dequeue0/free 的 edge-old 周期继续阻塞 exact P，
下一周期才开放。full-P lane0、mandatory lane1 pair、optional lane1 drop 与同 raw index 错 generation
均有定向生命周期 oracle。V14G 的 `memory_pid` 与 reservation tuple 部分读取 DUT-observed identity，
因此不得把 V14G 单独写成全字段 stimulus-owned；身份权威、cursor 与 pair/lane7 结论必须与
V11D/V11E/V11M 的独立 scoreboard 合取。11 类 compile-success RTL source mutation 在两种
generation width 下形成 22 个
release 负向 profile；每个都必须先成功生成非空 vvp，再由唯一预期 stage marker 拒绝，且不得出现
global/TB PASS。lane7 当前动态语义仍由 hash-bound V11M reservation evidence 提供，V14G 不把
lane6 本轮运行误写成 lane7 重跑。

V14H 把动态执行与日常判定分离。`check-global-producer-no-live-reuse` 只验证紧凑 receipt、当前 RTL
design-id、V14G executable input、Icarus simulator identity、V11 支撑摘要以及冻结的产品 elaboration，
不重复编译 26 个 profile。只有需要刷新动态证据时才运行：

```bash
make -C npc/rv64 refresh-global-producer-no-live-reuse
```

刷新目标运行 V14G 后重建 compact receipt 与 semantic ledger；临时 generated TB、负向 RTL copy 和 vvp
仍全部删除。完整字段 census/instance graph 的重建继续由 `check-producer-holder-census` 显式运行。

V14G 中的 optional lane1 force probe 只证明 `OooDispatchBackend` 的组合语义，不能单独证明产品可达性。
V14H 直接读取当前 NpcTop 的完整 Yosys JSON，逐级核对
`OooBranchAppendDispatchGate.dispatch1_optional_o=1'b0` 经 Frontend、CoreTopGlue、ExecuteBackend、
AluCoreSlice、AluDecodeBackend、IntBackend、DispatchBackend 到 IntIssueQueue 的同一层次连接。因此当前
配置的正确分类是 `PRODUCT_INACTIVE_CONSTANT_LOW`，不是缺少一条合法动态激励。

## 5. 声明边界

静态 census PASS 只表示当前 source-tree 的字段级清单闭合。V11J 以当前 product
配置重新 elaboration，证明 15 个 holder module 仍对应 17 个实例和 194 个可达实例，且两个
`OooMemInflightQueue` 与两个 `OooMemAxiBridge` 实例保持独立可审计；因此
`instance_graph_complete=true`。

V11B–V11V
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

`memory-buffer-token` 不由 V11N 代替。V11O 将当前 product `ENABLE_DUAL_MEM=1` 下的参数链、birth/request
恒零与 8 个静态反例，同 legacy 配置的 4 个正向 profile、8 类 compile-success mutation 的 16 次仿真
以及 3 个 ordinary regression 合取；因此该单元已独立 PASS，不能仅凭产品恒禁跳过 legacy 语义。

局部证据重放必须区分绑定强度。V11B–V11H 的旧 full-design snapshot 不得改写
design-id；仅当 policy 中逐项列出的 RTL、include/filelist 与 testbench SHA-256
全部仍匹配当前工作区时，台账才可标记
`CURRENT_SELECTED_SOURCE_AND_TB_BOUND`。V8L 的旧 full snapshot 因 LoadQueue
变化只能标记 `HISTORICAL_FULL_RTL_BOUND`。V11H focused attempt-4 原始
`FAIL@semantic-ledger-unit` 永久保留；独立 checker replay 只消费冻结的 4 个
正向配置、1 个 raw-Q assertion probe、31×2 负向仿真及 pre/post 输入，
生成新 PASS receipt，且明确历史 full-RTL snapshot 不是当前设计，只允许以
未漂移的 LoadQueue RTL 与两份 TB 作 selected binding，
`rtl_simulation_reexecuted=false`。系统边界必须使用独立 exact object：局部 closure
不隐式触发系统运行，system promotion 只接受当前 design/config/guest 绑定的完整执行，
或在运行语义未变化时对完整冻结输入执行 versioned checker replay；字段删除或弱化必须
fail closed。

当前 44 个单元均为 `semantic_status=PASS`，`units_semantic_gap=0`。V14H receipt 进一步要求：V14G
4/4 baseline 与 22/22 compile-success mutation 精确闭合；V11B/C/D/E/M 的 collector accept/free、
tracker cursor、GEN_W=1/4、pair-credit 与 lane6/lane7 字段不可削弱；optional lane1 产品链必须仍为恒 0。
compact receipt 还必须消费每个 profile 的 observed `oracle_stages`、compile-command/artifact SHA-256
与非空 log 摘要；stage 漂移或 log 摘要畸形由独立负例拒绝。它允许原 runtime payload 在冻结后退休，
所以摘要绑定不等价于重放原始日志语义。上述条件与当前 design/tool/product identities 同时成立时，
机器账本顶层为 `PASS`，且
`promotion.global_no_live_reuse=GREEN`。任一字段、源哈希、simulator binary、产品接线或证据摘要漂移都
fail closed，不允许只修改 receipt 制造晋级。

不得把字段 census、实例图、44/44 局部语义 PASS、V14G focused PASS 或本次局部 GREEN 单独外推为
完整架构 GREEN、200 MHz、Power 或 PPA promotion。V14H global receipt 固定保持
`whole_architecture=RED`、`system_recertification=REQUIRED` 与 `ppa=UNPROMOTED`；这些字段被改为更强
结论时，正负向单测必须拒绝。聚合语义账本另行消费 V14E A2 system receipt，且只在当前 RTL、
配置、guest/boot artifact、冻结 console/NPC log、post-binding 与 current checker replay 全部精确匹配时，
把账本顶层标记为 `system_recertification=PASS_CURRENT_CONFIG`。这不修改 V14H receipt 的声明边界。

V11H 修改了 production core RTL 语义，因此旧 A3 系统 evidence 不再是当前设计绑定，且不能
用旧 A3 checker replay 代替当前设计的系统验证。V14E A2 随后在当前 design-id 上完成了完整系统
运行；其原始执行、自然关机终态、assertion、配置与 pre/post hash 证据由独立 system receipt 保留。
当前 checker/parser 只对 A2 冻结输入重放，并保留失败的 A1 状态。V11J 断言增量以及
V11K/V11L/V11M/V11N 的 verification-only 增量本身不增加新的完整系统重跑触发条件。
