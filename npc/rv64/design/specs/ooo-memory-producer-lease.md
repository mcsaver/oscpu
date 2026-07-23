# 规范：异步内存 ProducerId 租约与完成资格（v8g）

> 模块：`OooMemOwnerTracker`、`OooIntBackend`、`OooDispatchBackend`、`OooRob`。
> 状态：**v8g memory active-owner scoped implementation GREEN；全核架构/PPA 仍 RED**。
> 本规范只关闭 memory active-owner
> 作用域；MulDiv、CLMUL、FP、分支/恢复持有者与全核 `global_still_live_reference_set`
> 继续为 RED，禁止把本规范解释为全核 ProducerId 回绕已关闭。

## 1. 目的与范围

ROB 的 4-bit generation 会有限回绕。仅比较 `{generation,rob_idx}` 不能证明一个迟到的
异步内存响应不会命中新分配的同名 incarnation。v8g 在已有 exact
`{owner_kind,owner_token,mmu_epoch}` 生命周期上增加不可变 ProducerId 元数据，并用寄存的
memory-live PID 位图阻断同名 ROB 候选分配。

本切片负责：

1. memory reservation 只从当前 ROB incarnation 创建 owner；
2. token 在整个逻辑 owner 生命周期内间接携带同一个 ProducerId；
3. memory completion 在 ROB/PRF/BusyTable/IQ/public pulse 前通过完整 ProducerId 的
   current-and-open 查询；
4. ROB 双 lane 候选在 parent dispatch ready 处读取 edge-old memory lease 位图；
5. AMO/physical STORE 在不可逆 request fire 点重新证明 exact
   capability、PID 等于当前 ROB head、ROB launch-open 且 one-shot 未发送；
6. exact terminal/free 后仍禁止同沿重用，下一沿才可重新分配同名 PID。

不在本切片内：扩大 memory 并发宽度、修改 AXI ABI、把 PID 宽字段穿过 bridge、改变
store 精确 B terminal、综合/STA/PPA 晋级或关闭其它执行域的 lease。

## 2. 接口契约

### 2.1 端口与责任

| 边界 | 字段/握手 | 时序与 owner | 契约 |
| --- | --- | --- | --- |
| issue → tracker | `alloc_valid/ready/token` + `alloc_producer_id` | `OooMemOwnerTracker` 读取 edge-old token/PID live Q | 只有 current-authorized memory issue 可申请；token 空闲且 PID 不在 live 位图才 ready |
| tracker → memory holders | `owner_token` + kind/epoch/PID tables | tables 与 token live Q 同源寄存 | 消费者必须先证明 `live && kind==holder.kind && epoch==holder.epoch`，再可使用 PID；raw ROB index 只作年龄/寻址 |
| tracker → dispatch | `producer_live_mask[2**PRODUCER_ID_W-1:0]` | 完全寄存、edge-old | parent ready 只索引候选 PID，不读取 MIQ/SQ/bridge CAM，不形成 holder→ready 组合树 |
| ROB → dispatch | `dispatch0/1_producer_id` | Q-only candidate | lane0=`tail` 的 next generation；lane1 固定为 `tail+1` 的 next generation，不依赖本拍 fire |
| dispatch accept | `dispatch0/1_valid && ready` | parent 是唯一 acceptance owner | `fire -> !producer_live_mask[candidate]`；mandatory pair 两候选都 clear，否则 lane0 也不得单独接受；optional lane1 可被丢弃 |
| dispatch/ROB head → SQ | dispatch PID、head PID | SQ allocation 保存 full PID；raw idx 仍作年龄 | bind、physical request、terminal release 都须 full PID exact；不同 generation 的同 raw idx 不授权 |
| tracker/AMO → request arbiter | interphase exact tuple + token→PID + ROB head PID | request fire 当拍 | AMO write 必须 interphase valid、exact-live、tracker PID=head PID、ROB launch-open、`!amo_write_sent`；flush/restore/kill 同拍仍禁止 |
| SQ → request arbiter | SQ bound exact tuple + SQ/head PID | request fire 当拍 | physical STORE 必须 SQ bound、tuple exact-live、tracker PID=SQ PID=head PID、ROB launch-open、`!request_sent`；AW/W 不是 lease terminal |
| tracker/MIQ → ROB query | `completion2_query_valid + producer_id -> match` | ROB Q-only `valid && !done && exact && !killed-now` | query 只给 eligibility；真正 side effect/transport terminal 由下述 `completion_fire` 原子事件决定 |

token 是能力句柄，不是 PID 的替代编码。合法间接载体必须同时满足：token live、kind/epoch
exact、`producer_id_table[token]` 在 token 生命周期内不变。任一 holder 仍驻留而 token 已 free
属于契约违例；不得回退到 raw ROB index 授权。

### 2.2 ready/stall DAG

```text
tracker.producer_live_q (registered)
          |
          v
ROB Q-only candidate PID --> indexed collision bit --> OooDispatchBackend parent ready

MIQ/SQ/bridge token arrays --------------------------X  (不得进入 ready)
```

- `dispatch0_ready` 必须包含 lane0 lease-clear；mandatory lane1 的 pair-ready 还包含 lane1
  lease-clear。
- `dispatch1_ready` 只在 lane0 fire 后有效，并再次包含 lane1 lease-clear。
- collision 只制造前端/dispatch backpressure，不改变 ROB generation，不提前 free memory owner。
- memory response 的 exact-open 查询不得回灌 request-ready；closed/stale response 按既有
  transport 规则 drain，并禁止 side effect。
- `query_match` 与“有 completion credit”是两件事。open owner 无 credit 时必须保持 response；
  只有 closed/cancelled response 可以无副作用 drain。
- 当前结构的 PRF/Busy/IQ/public pulse/SQ fill 均是同拍无 ready sink，因而
  `side_effect_credit=1`；`all_sink_credit` 只由 edge-old WB 空位与 terminal collector
  可接收性组成，不得读取本拍 STORE release、token free 或 SQ 释放后空位。
- 对稳定 open response、terminal credit 稳定且 `side_effect_credit=1`，既有
  `mem_rsp_waiting_for_wb` 必须禁止新 lane1 EX
  占位，memory 优先于 long/FP；在 terminal credit 稳定时，首个 WB-credit
  stall 之后最迟下一拍 grant。这一 bounded-grant 必须由 watchdog 断言承重。

### 2.3 flush / recovery「谁清谁保持」

| 事件 | 清除 | 保持 | 终止/授权规则 |
| --- | --- | --- | --- |
| hard reset | token live、PID live、metadata、reservation/MIQ/SQ live | 无 | reset 拍 dispatch/query fail closed |
| global `flush_i` / checkpoint restore | 未发 speculative reservation/buffer；ROB/IQ 由既有 owner 清理 | 已发 AXI、nokill physical STORE、terminal collector pending、对应 token/PID lease | 只由 exact drop/response/SQ release terminal free；禁止直接清 lease |
| branch mispredict | strictly-younger reservation/MIQ/SQ 按现有年龄律取消 | boundary/older owner、已发需 drain owner | 新 reservation capture 必须先 current-exact；迟到 younger response drain 无 WB |
| exact LOAD/ATOMIC terminal | 对应 token、PID lease（collector dequeue edge） | 其它 token/PID | 同沿 ROB candidate 仍看 edge-old live=1；次沿才可复用 |
| STORE 等待 B | 无 | SQ、MIQ/bridge、token/PID lease、原始 VA 与异常 owner | AW/W、commit意图、flush均不得 release；只有 B 精确接收后才可 terminal |
| STORE B terminal + ROB/SQ release | B status 已精确进入 formal completion，且 SQ/MIQ/bridge authority全部结束后对应 token、PID lease | committed store 的既有外部写结果 | closed DRAIN completion 是 fatal contract violation；可 drain 总线但不得产生正常 STORE death（包括自身 token） |

### 2.4 同拍优先级与事件代数

1. reset 高于所有状态更新；ready/query 同拍 fail closed。
2. 非 reset 拍，所有 birth/death 都从 edge-old 状态判定；被本拍 free 的 token 或 PID
   不能作为本拍 alloc 候选。
3. 不同 token/PID 的 terminal 与 allocation 可同拍；同 PID 的 allocation 必须 backpressure。
4. response 先形成 exact owner tuple 与 PID eligibility；open owner 只有在所有 sink credit
   同拍可用时才形成 `completion_fire`。前者、query match、credit 三者都不能互相替代。
5. raw `rob_idx` 的年龄比较只决定 strictly-younger/older；任何完成、release 或副作用资格
   不得只凭 raw index。
6. 同 PID 的两个 completion source 若同拍读到 edge-old `!done`，由 WB owner 仲裁产生唯一
   grant；loser 不得产生副作用。EX 同拍已完成同 PID 时，memory response按 `done_now` closed
   drain并触发 duplicate-source 断言，而不是形成第二次 WB。
7. `owner_open` 和 `owner_closed` 是互斥、完备的 tuple 分类；credit 只能决定
   fire，不得把 open-but-stalled 重分类为 closed。

birth/death 采用集合事件代数，不用过程语句先后定义赢家：

```text
death[t] = exact_tagged_free[t] OR qualified_store_release[t]
birth[t] = alloc_fire && alloc_token==t && !old_live_q[t] && !old_producer_live_q[alloc_pid]
pid_clear[p] = OR_t(death[t] && old_producer_id_q[t]==p)
pid_set[p]   = OR_t(birth[t] && alloc_pid==p)
live_d          = (live_q & ~death) | birth
producer_live_d = (producer_live_q & ~pid_clear) | pid_set
```

`qualified_store_release` 只允许两类：明确未发且所有 reservation/buffer/SQ/bridge/MIQ/pending
authority 已终止；或 aggregate B 已握手、B status 已被 exact completion 接收且同沿完成最后
authority handoff。仅 `kind==STORE`、SQ dequeue、ROB commit 意图、AW/W fire 或 flush 都不充分。
该判定只读 edge-old authority 与当拍事件脉冲，不读同拍刚写入的
`sq_terminal_q`，也不允许 release 产生的空位反向授权 B completion。

## 3. 状态与时序模型

### 3.1 tracker 状态

每个 token 只有两个逻辑状态：

```text
FREE
  -- alloc_fire(current PID && token free && PID lease clear) -->
LIVE {kind, epoch, producer_id}
  -- exact tagged free / STORE-only effective release --> FREE
```

全局 `producer_live_q[pid]` 与 token live 集合一一对应。`LIVE` 期间 kind、epoch、PID 不变；
metadata 仅在该 token 下一次合法 allocation 时覆盖。`popcount(producer_live_q)` 必须等于
`live_count`，两个 live token 不得映射同一 PID。

### 3.2 memory completion 时序

```text
response valid + exact owner tuple
          |
          +--> transport fire / MIQ pop / terminal collection
          |
          `--> token -> immutable PID -> ROB completion-open query
                                      |
                         match --------+--> formal WB side effects
                         mismatch ----------> drain only; no WB/PRF/wakeup
```

LOAD/PROBE/kill 可合法进入 mismatch drain；nonkill physical STORE DRAIN 的 mismatch 表示
owner 生命周期破坏，必须触发立即断言。completion query 只读 ROB Q，不读 WB 或 ready。

### 3.3 completion acceptance

```text
tracker_exact = tracker_live && tracker_kind==miq_kind &&
                tracker_epoch==miq_epoch
owner_open = exact_tuple && tracker_exact && rob_query_match &&
             !effective_killed && !done_now
owner_closed = exact_tuple && !owner_open

side_effect_credit = 1
all_sink_credit = wb_credit_if_needed && terminal_credit
completion_fire = response_valid && owner_open && all_sink_credit
legal_closed_terminal_fire = response_valid && owner_closed &&
                             tracker_exact && legal_cancel_safe &&
                             terminal_credit
fatal_irrevocable_fire = response_valid && owner_closed &&
                         (!tracker_exact || physical_drain_kind ||
                          amo_write_sent)
```

- open owner 无 credit：`ready=0`，response payload、MIQ head、token/PID lease 全保持。
- `completion_fire`：transport pop、ROB/PRF/Busy/IQ/public side effects 与 terminal ingress 同拍；
  tracker 实际 free 仍由 lossless collector/effective STORE release兑现。
- `legal_closed_terminal_fire`：只对 tracker-exact LOAD/PROBE，以及 AMO write 尚未
  fire 的 read/interphase 取消做无副作用 drain；AMO read 不得进入 write phase。
  collector 无 credit 时不得提前 pop。
- `fatal_irrevocable_fire`：包括 tracker dead/tag mismatch、closed physical STORE DRAIN
  与 `amo_write_sent=1` 后的 closed final response。可解总线占用，但必须立即 fatal；不产生 WB、不进
  normal terminal collector、不产生任何正常 STORE death，包括当前 token。若该 token
  edge-old live，其保持 poison/live 直到 fatal quiesce/reset，或另立的全机停顿清理协议。
- `terminal_credit` 只读 collector edge-old pending 与不依赖任何 ready/fire/grant
  的其它 ingress raw-valid+tuple。固定优先级为其它不可反压 terminal 候选优先、
  response 后选；其它 ingress acceptance 不读 response valid/fire/credit。这是整个
  组合锥的单向规则，不只是文本上禁止直接回读。
- exact tuple mismatch 不算 closed owner：不得 pop/free；必须触发 owner mismatch 断言并由既有
  transport quarantine/drain 规则收敛，不能误释放 MIQ head。

### 3.4 不可逆 request-fire 授权

```text
rob_head_owner_open = head_exact_valid && !head_done

rob_head_launch_open = rob_head_owner_open &&
                       !recovering && !flush && !restore && !killed_now

store_request_fire ->
  sq_owner_bound && exact_live(sq_kind,sq_token,sq_epoch) &&
  tracker_pid == sq_pid && sq_pid == rob_head_pid &&
  rob_head_launch_open && !request_sent

amo_write_fire ->
  interphase_valid && exact_live(ATOMIC,interphase_token,interphase_epoch) &&
  tracker_pid == rob_head_pid && rob_head_launch_open && !amo_write_sent
```

两个 fire 同沿都置各自 one-shot sent Q。request 发出后，对应 ROB head 的 full
PID 必须保持 exact-valid、`!head_done`、未 terminal/未 retire/未 recycle，直到 B 或
AMO 最终 response 的 `completion_fire`。AW/W、地址/数据就绪或任何旧执行路径均不得
提前置 `head_done`；最终 response `completion_fire` 是该 owner 唯一允许的
done/terminal 事件。若 restore 位于 reservation/interphase 与 physical fire
之间，本拍 request 必须 fail closed。

`rob_head_launch_open` 只回答“本拍能否首次发出不可逆物理写”，因此选择性恢复会暂时
将其拉低。`rob_head_owner_open` 回答“当前精确 ROB 队头是否仍为未完成 owner”，不读
`recovering/flush/restore`。request-fire 之后的驻留断言必须检查
`rob_head_owner_open + exact head index + full PID`，不能继续要求 launch-open；这样既允许
严格更年轻的分支恢复，也不会放过队头提前 done、retire 或 recycle。全局 flush 若真的
移除已发出写的 ROB owner，owner-open 会随精确队头丢失而关闭，断言仍应报错。

### 3.4.1 response-credit 物理断环

full-chip elaboration 会把 bridge back-to-back station、request ready、local terminal 与
collector credit 拼成一个完整组合锥；仅在布尔语义上“同 token 不会冲突”不足以让工具或物理
实现证明无环。v8g 因此冻结以下代码形状：

1. bridge active-drop 与 station-drop raw terminal 不得读取 `stage_advance`、response ready 或
   request ready；flush/kill 与 edge-old FSM/station Q 已足以决定 terminal。
2. station tracker query 的 valid 固定为 registered `stg_valid_q`，不能由 advance/fire 限定。
3. resident local-complete 直接使用 local reason 与 issue eligibility 的布尔因式分解，不能经过
   读取 bridge request-ready 的 generic consume/can-fire 锥。
4. younger-killed buffer 不进入 request grant；cancel 只读 registered buffer Q、kill/flush/restore，
   不用 request fire 区分本地 cancel 与 MIQ handoff。
5. response lane0 与其它五路 raw terminal 的 token mask 必须分别由 scalar valid/token 构造；
   不允许从包含 response fire 的 packed vector 切片后再反馈 response credit。
6. station 的 final-PA SQ query 是只读判决面，`allow` 不等于 SRAM lookup 授权；仅当
   `rsp_ready` 同拍为 1 时允许 `dcache_lookup_en`。若当前 response 占满唯一返回信用，station
   可以保持 `allow`，但 lookup 必须为 0，并在沿后走已寄存的 response/active 状态。
7. per-bank retry holder 会关闭该 bank 的**新增 load admission**，但不会抹除 bridge 中已经驻留
   的另一条事务。retry 与 active/station 可以同时有效，只要 full owner token 不同；同一 token
   同时出现在 retry 与 active/station 才是重复 owner，必须由立即断言拒绝。

上述规则由 full lint 与 compile-success structural mutations 双重承重。结构变异允许功能仿真
继续 PASS，但静态审计必须精确 RED；这类证据不能被普通动态回归替代。

### 3.5 寄存器与更新优先级

| 寄存状态 | reset | 更新 | 保持 |
| --- | --- | --- | --- |
| `live_q[token]` | 0 | exact free/release 清；不同 token alloc 置 | 无事件 |
| `kind_q/epoch_q/producer_id_q[token]` | 0 | 仅 alloc fire 写 | free 后可留脏但无资格 |
| `producer_live_q[pid]` | 0 | exact free/release 清对应旧 metadata；alloc 置新 PID | 无事件 |
| ROB `slot_generation_q` | 全 1 | 仅 accepted dispatch 对候选槽 +1 | collision stall、flush、terminal |

## 4. 不变量与立即断言

- **MEM-PID-I1 一一映射**：live token ↔ 一个 live PID；消费者只能在 kind/epoch
  tracker-exact 后使用该 PID；两个 live token 不得同 PID；两个
  bitmap 的 popcount 与 `live_count` 一致。
- **MEM-PID-I2 不可变元数据**：token live 且无 terminal 时 kind/epoch/PID 逐位稳定。
- **MEM-PID-I3 当前 owner 创建**：`mem_owner_alloc_fire -> issue_pid_current`；current mismatch
  不得 capture reservation、不得创建 token。
- **MEM-PID-I4 scoped no-live-reuse**：`dispatch_fire(candidate) ->
  !memory_producer_live_q[candidate]`；release 同沿仍不能 fire 同 PID。
- **MEM-PID-I5 exact completion**：任一 memory WB/PRF/Busy/IQ/public pulse 蕴含
  `completion_fire && completion2_query_match` 且 WB raw index 等于 PID 低位。
- **MEM-PID-I6 transport/authority 分离**：owner-tuple mismatch 不 pop；PID mismatch 可 drain
  stale speculative response但无 side effect；DRAIN mismatch 必须报错。
- **MEM-PID-I7 ready 无 holder CAM**：dispatch collision 只依赖 ROB Q candidate 与 tracker
  registered PID bitmap。
- **MEM-PID-I8 不可逆 launch**：`AMO_write_fire || physical_STORE_fire` 必须满足
  §3.4 的 exact capability、PID chain、ROB launch-open 与 one-shot 条件；LOAD/PROBE 的
  speculative request 不能被该规则误写为已 commit。
- **MEM-PID-I9 B 承重 terminal**：已发 STORE 在 aggregate B exact acceptance 前 token/PID
  lease 恒 live；AW/W、SQ release request、flush 均不能单独构成 death；B 与同 PID
  `done_now` 同拍只能 fatal drain，不能形成 normal death。
- **MEM-PID-I10 完成原子性**：open response 无 credit 不 pop、不 free、不产生任一 sink side
  effect；`completion_fire` 对本 uop 至多一次，同 PID `done_now` 不能双完成。
- **MEM-PID-I11 分类互斥**：exact tuple 的 owner-open/owner-closed onehot；open-but-stalled
  不得触发 closed path，tuple mismatch 不属于任一可 pop 分类。
- **MEM-PID-I12 有界活性**：稳定 open response 且 terminal credit 稳定时，若本拍
  WB 满，则下一拍必须有 `completion_fire`；等待拍禁止 lane1 EX
  新占位，`side_effect_credit` 在本结构必须为常 1。
- **MEM-PID-I13 post-launch done 唯一性**：STORE/AMO physical request 已发且最终
  response 未 `completion_fire` 时，ROB head full PID 保持 exact-open/`!done`；任何早于
  final response 的 done 必须触发断言。
- **MEM-PID-I14 response-ready 单向 DAG**：bridge raw terminal/station query、local terminal、
  killed-buffer cancel 与 lanes1..5 token mask 均不得组合读取 response/request ready、response
  fire 或由其派生的 advance/grant；full lint 不得新增 response-ready SCC。

每条立即断言都必须有 compile-success 定向变异证明会响；仅编译失败不算检出。

## 5. 关键路径与 PPA 边界

dispatch 新增的是“Q-only candidate PID 索引寄存 bitmap”的单级资格，不允许加入 MIQ/SQ
compare tree。tracker 增加 PID metadata/bitmap 是架构正确性成本。本切片在功能闭环前不运行
PPA 晋级；即使后续诊断综合有改善，也只能写 diagnostic proxy，不能声称 200 MHz closure。

## 6. 验证计划

1. tracker leaf：唯一 PID、duplicate PID backpressure、free/release 后一拍复用、同沿不复用、
   bitmap/table/popcount 守恒。
2. ROB/dispatch：lane0 collision、mandatory lane1 collision、optional lane1 drop、lane1 candidate
   与 fire 解耦、reset/flush fail closed。
3. backend：reservation current mismatch 不创建 owner；AMO/STORE launch exact capability +
   head-PID + ROB-open + one-shot；
   LOAD/PROBE/AMO/STORE B 正常 exact completion；open-no-credit hold；stale PID response drain
   无 WB/无 AMO write phase；DRAIN mismatch 断言；collector backpressure 保持。
4. 承重交叉：B error 连续 WB stall 后仅一次精确异常/释放；B 与 EX 同 PID
   `done_now` 同拍 fatal 且无 death；restore 介于 reservation/interphase 与 fire 时不发请求；
   连续 EX completion 下 memory 下拍获得 completion fire；closed response 无 terminal
   credit 不 pop；tracker epoch mismatch 不完成/不 free；AMO write 已发后 closed final
   response fatal 且无 normal death；AW/W 后 ROB done 提前的变异必须被检出。
5. mutation：删除 dispatch collision、允许同沿 reuse、常量 PID、memory WB 绕过 exact-open、
   current mismatch 仍 capture、lane1 candidate 重新依赖 fire。
6. focused release/assert、module aggregate、`check-contract`、结构审计与 strict guard。

最终结果：focused release/assert 各 7/7，29/29 compile-success mutations（25 个动态后果、
4 个仿真等价结构违约）全部命中，module aggregate 105/105；full lint 保持继承 115 条 warning，
normalized signature 与 v8d byte-equal，新增 response-ready SCC 为零。架构 hard-gate self-test
15/15，但真实全局裁决仍为 `OVERALL: RED`，因此未授权 synthesis/STA/PPA promotion。

## 7. 风险与回退

- 256-bit PID bitmap 是有限 ProducerId 空间的显式状态，不等于全核 live set。
- 若 candidate→ready 出现组合环，回退到冻结合同检查 lane1 candidate owner；禁止删 lease gate。
- 若 STORE DRAIN exact-open 失败，保留失败证据并修 owner 生命周期；禁止把 DRAIN 当 killed load 丢弃。
- 全核 lint 既有 warning baseline 必须归一化比较，不能将非零 baseline 写成 GREEN。

## 8. 变更记录

- 2026-07-19：v8g contract freeze；冻结 token-indirected ProducerId carrier、registered memory
  lease bitmap、parent dispatch collision gate、third ROB completion query 与 scoped claim 边界。
- 2026-07-19（review amendment v8g.1）：补齐 AMO/STORE request-fire head-PID 授权、STORE B
  承重 terminal、`completion_fire` credit 原子性、`done_now` 唯一 grant 与显式 birth/death 代数。
- 2026-07-19（review amendment v8g.2）：补齐 open/closed 互斥分类、request-fire
  exact capability/ROB launch-open/one-shot、closed DRAIN 无 normal STORE death、collector credit
  与 memory completion bounded grant。
- 2026-07-19（review amendment v8g.3）：补齐 tracker kind/epoch exact-tag、post-launch
  `!head_done` 唯一终点、terminal raw-candidate 单向优先级、`side_effect_credit=1`
  以及已发 AMO write 的 closed-final fatal/poison 规则。
- 2026-07-19（implementation close）：memory lease、dispatch collision、ROB completion2、
  STORE/AMO post-launch 与 response-credit 单向 DAG 落地；29/29 mutation、105/105 module、
  style/contract/structural audit PASS。全核 no-live-reuse 与 PPA promotion 保持 RED。
- 2026-07-22（V9L current-design correction）：把 ROB 队头的首次物理写许可与发射后持续
  owner 资格拆成 `rob_head_launch_open` / `rob_head_owner_open`；补齐 station lookup 对
  registered response credit 的约束，以及 retry holder 与不同 token bridge residency 的合法并存。
  正向专项与四项 compile-success RTL 断言验证变体均绑定当前 design-id；PPA 仍未资格化。
