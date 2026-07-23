# RV64 v8l 全局 ProducerId holder census 与有限代际 no-live-reuse 合同

## C0 范围、目标与声明边界

本合同覆盖当前 production `NpcTop -> NpcCoreTop -> OooCoreTopGlue -> OooIntBackend`
实例路径中，从 ROB allocation 到所有整数、浮点、访存、长延迟、分支和 pending CSR
附加持有者的完整 `ProducerId` 生命周期。目标是把 v8c 的 file/module lexical census
升级为当前 production RTL 的字段级 holder 账本，并让有限宽 generation 在回绕时仍满足：

```text
任一 edge-old holder 仍持有 P 时，ROB dispatch 不得出生同一个 P。
```

本切片只允许把 `global_no_live_reuse` 提升为“当前 elaborated production path、当前 manifest
与当前参数族内 GREEN”。它不等价于完整形式证明，不把 architecture inventory 的其他 RED
硬门改成 GREEN；`promotion_eligible=false`，在 architecture hard gates 全绿前不运行或发布新的
综合/STA/power/Pareto 结论。

## C1 身份真源与字段规则

1. 唯一事务身份是 `P={generation,index}`。`index=P[ROB_INDEX_W-1:0]` 只允许作年龄、数组寻址
   或 legacy boundary projection，不能独立授权 completion、commit、memory launch 或复用。
2. `OooRob.slot_generation_q[index]` 是 generation 真源；只有真实 dispatch fire 才使该 slot 的
   generation candidate 出生并随 ROB/IQ/下游 packet 传播。
3. 任一跨周期、可能影响 WB/commit/redirect/memory side effect 的 resident packet，要么直接保存
   full P，要么保存一个仍由 `OooMemOwnerTracker` 精确映射到 full P 的 live token。
4. assertion-only previous-value/debug shadow 不属于 production holder；pre-ROB control/trap event 在
   ROB allocation 前也没有 P。两类对象必须在 census 中显式 EXEMPT，不能从扫描中静默消失。
5. 当前 IntIQ 每个 entry 只有一个 full-P 字段 `producer_id_q[k]`，它是该 uop 的 owner P；源依赖只
   保存 physical-register tag (`src*_preg_q/fp_st_preg_q`) 与 sticky-ready，不保存 producer P，也不会
   用 P 匹配 wakeup。因此 IntIQ mask 精确解码所有、且仅有 valid entry 的 `producer_id_q[k]`。未来
   若引入 full-P source tag，静态发现集合变化必须先扩展 census 与 mask，不能沿用本豁免。

## C2 当前 holder 分类与唯一 lease 证明面

| holder 类 | resident state | lease 根 / 证明方式 |
| --- | --- | --- |
| ROB authority | per-slot valid + generation | slot valid 阻止同 raw slot birth；generation 产生 candidate |
| integer IQ | `valid_q[k] + producer_id_q[k]` | 新增 Q-only `producer_live_mask_o`，直接进入 dispatch fence |
| integer EX0/EX1 | `PipeStageReg.valid + packed full P` | 新增 Q-only transient mask，直接进入 dispatch fence |
| branch resolve | `PipeStageReg.valid + packed full P` | 新增 Q-only transient mask；同时与 raw EX0 full P coherence |
| memory reservation | `mem_issue_res_valid_q + producer_id_q` | 新增 Q-only transient mask；capture 同沿也出生 tracker token |
| memory owner domain | tracker `live_q/token->producer_id_q/producer_live_q` | tracker 的 registered PID mask；MIQ/bridge/buffer 用 exact token 间接覆盖 |
| store queue | `valid_q[k] + producer_id_q[k] + token` | dispatch 后先由 int-IQ mask 覆盖，issue 后由 tracker 覆盖；逐 entry assertion 证明无空窗 |
| MulDiv / CLMUL | owner valid + full P | 各自 Q-only onehot mask |
| FP IQ/issue/arith/exec/long/done FIFO | 各层 valid + full P | `OooFpBackend.producer_live_mask_o` 已覆盖全部六类 Q holder |
| pending CSR | raw `producer_valid_q + producer_id_q` | raw Q-only pending mask；exact commit/global flush 才 death |
| assertion/debug shadows | `*_prev_q`, mutation/check registers | EXEMPT；不得驱动 production side effect 或 lease |
| pre-ROB control/trap events | pending event payload without full P | EXEMPT；真实 ROB enqueue 前无 P |

字段级 census 必须同时列出 direct full-P holder、packed-stage holder、token-indirect holder、ROB
authority 与 EXEMPT state。静态 checker 必须 fail closed：新增可综合 `producer_id_q`/
`producer_live_q`/packed ProducerId stage 或 token-indirect owner 未加入 manifest 时失败。checker
只对当前 source tree、当前 production instance roots 和冻结的 packed/token anchors 声称字段级完整；
不声称开放世界 Verilog 语义解析完整。

当前 WB/redirect census 还固定以下事实：EX0/EX1 `PipeStageReg.down_ready_i=1`，不存在 WB hold/skid；
WB arbitration 只是从 edge-old Q holder 组合选择，不另存 P。FP done FIFO 已在 FP aggregate 中；
memory terminal collector 只保存 token 且由 tracker 覆盖；branch redirect 唯一跨周期 P packet 就是
列出的 branch-resolve stage。static checker 必须扫描全部可综合 full-P 声明和所有
`PipeStageReg` payload anchor；出现新的 skid/replay/completion/redirect Q 即使名字不同，也要因未
登记 anchor 而失败。

## C3 接口结构合同

### C3.1 新增/收敛接口

```text
OooIntIssueQueue.producer_live_mask_o[2^PRODUCER_ID_W-1:0]
  = OR(valid_q[k] ? onehot(producer_id_q[k]) : 0)

OooDispatchBackend.producer_live_mask_o
  = producer_live_mask_i | int_iq_producer_live_mask

OooIntBackend.external_live_mask
  = memory_tracker | muldiv | clmul | fp | pending_csr | transient

OooIntBackend.producer_live_mask_w
  = OooDispatchBackend.producer_live_mask_o
```

`producer_live_mask_i` 继续只承载 DispatchBackend 之外的 Q holder；DispatchBackend 在本地加入
integer IQ mask，并把完整 mask 导出供集成断言/TB 观察。所有 lane0、mandatory lane1、optional lane1
collision gate 与 assertion 必须读取同一个完整 mask，禁止 assertion 看完整 mask而 production ready
仍看旧外部子集。

### C3.2 transient mask

`transient = mem_res | ex0 | ex1 | branch_resolve`，每项只由对应 edge-old registered valid 与
registered full P 解码。即使 branch 与 EX0 正常同 P、memory reservation 与 tracker 正常同 P，仍
保留直接 contributor；这样 malformed coherence 不会同时把持有者从 birth fence 隐去，重复 bit
只做 OR，不产生多重权限。

### C3.3 参数与宽度

- mask width 固定为 `1 << PRODUCER_ID_W`；默认 `ROB_INDEX_W=4, PRODUCER_GEN_W=4`。
- 验证必须另以 `PRODUCER_GEN_W=1` 编译 finite-wrap focused case，证明安全性不依赖“generation
  很宽、测试跑不到回绕”。
- `PRODUCER_GEN_W>=1`；任何负 repeat、固定 4-bit generation、raw-index-only mask lookup 都是失败。

## C4 控制与优先级合同

1. dispatch candidate `P0/P1` 的最终 ready 必须分别满足完整 mask 对应 bit 为 0；mandatory lane1
   冲突原子阻断 lane0，optional lane1 冲突只丢 lane1。
2. reset、flush、checkpoint restore、ROB walk/recover 的既有 dispatch freeze 优先级保持高于 birth。
3. holder birth 只能来自该 holder 的真实 capture/fire；holder death 只能来自其既有 consume、exact
   terminal、selective kill、flush/reset 或 exact commit 事件。
4. mask 不授予任何 side effect；它只是否定新的 birth。completion/commit/launch 仍需各域 exact-open、
   pending-owner、same-edge claim 和 token tuple 授权。
5. 同一个 P 在多个正常重叠 holder 中出现是允许的；同一域中两个独立 live owner 使用同 P 仍由
   现有 uniqueness assertion fail-loud。

## C5 时序与组合环合同

1. 每个 contributor 只能读取 edge-old Q：`valid_q`、registered stage valid、registered owner valid、
   registered tracker mask 或 raw pending lease。禁止读取 dispatch D、candidate/fire、ready、next-state、
   completion authorization 或 kill-now 派生的 effective valid。
2. dispatch ready 只做 `complete_mask[candidate_P]` 的 indexed Q lookup。holder CAM/scan 在各 owner
   本地生成 Q mask；不得把 candidate/ready 反送进 mask 生成。
3. birth 沿看到 edge-old holder 无效，不会自阻断；death 沿仍看到 edge-old holder 有效，因此同沿
   candidate 必须保持 blocked，下一拍才开放。
4. 允许的 handoff 必须满足“源 Q 在 capture edge 前仍 live；目的 Q 在 edge 后立即 live”：

```text
ROB dispatch -> IntIQ / FpIQ (+ SQ shadow when store)
IntIQ issue  -> EX0/EX1 | branch-resolve | mem-res+tracker | MulDiv | CLMUL
FpIQ issue   -> FP issue/arith/exec/long/done chain
mem-res      -> MIQ/buffer/SQ/bridge under the same tracker token
terminal     -> exact death/tombstone drain
```

任一 handoff 若在源 mask 清除与目的 mask 建立之间出现一拍空窗即为 P0 失败。

### C5.1 ROB candidate 与真实 birth 同源

当前 ROB 不借用同拍 commit 释放的 slot；dispatch ready 只读 edge-old `count_q/free_slots_w`。对每条
lane：

```text
alloc_index      = exported dispatch_rob_idx
alloc_generation = slot_generation_q[alloc_index] + 1 mod 2^GEN_W
alloc_P          = {alloc_generation, alloc_index}
alloc_fire       -> slot_generation_q[alloc_index] <= alloc_generation
                 && downstream dispatch packet carries exactly alloc_P
```

DispatchBackend collision gate、实际 ROB 写入、IQ/FP/pending capture 和 assertion 必须消费同一个
exported `alloc_P`。禁止用 edge 后 generation、只用 raw index 或另行重构 P。独立 TB reference
monitor 直接扫描原始 holder fields 生成 `reference_live(P)`，不能复用 production mask；它检查
`alloc_fire -> !reference_live(alloc_P)`，用于捕获“控制和 assertion 共读同一个漏项 mask”的假绿。

### C5.2 memory tracker 原子生命周期

```text
mem_iq_pop(current P) <-> capture_candidate(P)
capture = capture_candidate && tracker_alloc_ready
memory IQ ready = current ? tracker_alloc_ready : stale_drop_ready
capture -> 同沿 {mem_res.valid,P,token}=1 且 tracker{token}=live/P
indirect_live(token) -> tracker_live(token)
tracker_live(token) && any_indirect_live(token) -> tracker P/kind/epoch 稳定且 token 不可复用
tracker death -> 本沿所有 direct/indirect owner 均 terminal/released 或同沿由其它 direct lease 覆盖
```

backpressure 时 `tracker_alloc_ready=0` 必须同时阻止 IQ pop、mem-res/SQ bind/MIQ/buffer/bridge capture；
selective kill/flush/replay/terminal arbitration 不得留下 downstream owner 而提前清 tracker。上述关系既
要有 production assertions，也要有不读取 production PID mask 的 TB reference scan 与
compile-success mutation。

## C6 reset、恢复、异常与 compatibility 合同

### reset/flush/recovery

- reset/global flush 清除所有可撤销 direct holder 与 mask；pending CSR、memory accepted owner 等按其
  已冻结的 exact death/tombstone 规则处理。
- selective branch recovery 只清严格 younger holder；边界及 older holder 保持 P 与 mask。
- recovery/kill 同拍 dispatch 已由 registered freeze 阻断；不得依赖 mask 的 next-state 提前释放。

### 异常/取消

- stale generation、raw-index match/full-P mismatch、token kind/epoch/PID mismatch 均 fail closed；允许
  transport drain，但不得产生 ROB done、PRF/FPR wake/write、commit、redirect 或 memory launch。
- memory fatal poison、FP killed tombstone、pending CSR malformed metadata 都必须继续保留其已冻结的
  lease/death 语义，不能为了减少 mask bit 早清 owner。

### compatibility

- 不改变 ISA、双发射 prefix、IQ N+1 select、WB lane priority、ROB commit width、memory token ABI、FP
  credit、branch resolve payload 或 pending CSR commit ABI。
- 新 output 只作 Q-only lease/观察；未连接的 standalone TB 不得改变功能。
- 默认参数下 legacy module aggregate、v8f-v8k focused 与 contract/static gates必须不回退。

## C7 可执行不变量

- `[V8L-INT-IQ-LEASE-DECODE]`：每个 valid IntIQ entry 的 full P bit 必须在 IQ mask 中；invalid entry
  不得因 dirty payload贡献 bit。
- `[V8L-GLOBAL-LEASE-UNION]`：完整 mask 精确等于外部 mask与 IntIQ mask之 OR。
- `[V8L-TRANSIENT-LEASE]`：mem-res、EX0、EX1、branch raw stage 任一 valid 时完整 mask含其 P。
- `[V8L-SQ-LEASE-COVER]`：每个 valid SQ full P 始终由完整 mask覆盖。
- `[V8L-MEM-TOKEN-LEASE-COVER]`：mem reservation/buffer/pending/MIQ/SQ active token 必须 live，且直接
  保存 P 的对象与 tracker table P exact match。
- `[V8L-DISPATCH-NO-LIVE-REUSE]`：任一 lane fire 蕴含完整 mask在其 P 位为 0。
- `[V8L-HANDOFF-NO-GAP]`：IntIQ→各目的的 capture edge 前源 bit为1，edge 后目的/全局 bit仍为1。
- `[V8L-DEATH-EDGE-BLOCK]`：最后一个 holder 在当前 edge death 时，当前 edge candidate仍不得 fire；
  仅下一 cycle 可 fire。
- `[V8L-FINITE-WRAP]`：`GEN_W=1` 时自然推进 slot generation 回绕到 held P，candidate必须持续 stall；
  holder death后的下一 cycle才能复用。
- `[V8L-ALLOC-P-SOURCE]`：每个真实 ROB allocation fire 被 mask 检查的 P、写入 slot 的
  generation/index 与下游 capture P 逐位相同；commit/free 同拍不改变本沿 candidate。
- `[V8L-TRACKER-ATOMIC-HANDOFF]`：memory IQ pop、tracker allocation、mem-res capture 和 SQ owner
  bind 的成功集合满足冻结方程；任何 partial success 均 fail-loud。
- `[V8L-REFERENCE-NO-LIVE-REUSE]`：独立 reference monitor 从 raw holder fields/valid/token table
  重建 live set，任何 allocation fire 不得命中；reference 逻辑禁止读取 production
  `*_live_mask*`。

## C8 必需验证与 mutation

1. IntIQ unit：dual birth、hold、compaction、issue death、selective kill、flush，mask必须逐 entry 精确。
2. Dispatch unit：resident IQ 的非零 generation P 被人为构造为 stale detached holder时，完整 mask
   必须阻断同 P；issue/pop death edge仍阻断，下一拍开放。
3. `GEN_W=1` finite wrap：同一 production ROB/Dispatch RTL 用真实 allocate/WB/commit 推进两轮
   slot generation，外部 Q lease 持有第一轮 P；回绕 candidate 停住，释放沿前仍停住，释放后开放。
   该通用 birth-fence 反例与逐 domain raw-holder->mask/reference tests 组合：每类 direct/packed/
   token-indirect holder 都必须把同一 P 投影成相同 complete bit；不得把“通用 wrap”和“domain
   映射”任一单独外推。
4. IntBackend：分别激活 mem-res、EX0、EX1、branch、memory tracker、MulDiv、CLMUL、FP、pending CSR
   contributor，验证完整 mask与 handoff无空窗；SQ/indirect token coverage assertion非真空。
5. compile-success mutation 至少包括：删 IntIQ union、把 IQ mask 改读 next-state、把 lookup 退化为
   raw index、删 transient contributor、提前按 effective-valid 清 lease、允许 tracker alloc 失败时
   IQ pop/downstream capture、提前复用 live token。每个 mutation 必须由定向 TB 或静态 checker
   击杀，不能以编译失败计数。
6. 永久 static gate：manifest/RTL anchor一致、发现集合一致、所有 contributor/dispatch lookup/断言
   marker存在；checker自身必须有漏 holder、伪 GREEN、漏 packed anchor、漏 token-indirect class 和
   EXEMPT 越权 mutation。
7. checker 与 evidence 必须绑定 manifest/checker SHA、production define/config、RTL source manifest
   及每个 focused binary/log；新增 full-P 字段、packed stage、token holder 或 EXEMPT 条目时先 RED。
8. legacy v8f-v8k、fresh full module aggregate、RTL style、contract count与 full lint均需留证；完整
   architecture hard gates仍按真实结果输出，未全绿即禁止PPA推广。
