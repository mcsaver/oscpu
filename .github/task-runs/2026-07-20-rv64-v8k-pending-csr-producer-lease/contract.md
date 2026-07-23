# v8k pending-system CSR ProducerId lease 与提交授权合同

## C0 范围与声明等级

本合同只冻结 `pending-system CSR capture -> drain -> backend dispatch -> ROB commit -> CSR side
effect` 链上的 ProducerId 生命周期、提交授权和 birth fence。非 CSR 的 ECALL/xRET/WFI/
SFENCE/FENCE.I/IRQ 继续在排空后的 pre-ROB 控制边界执行，不为它们伪造 ProducerId。

本切片属于架构闭合，`promotion_eligible=false`。focused/module/变异通过只能支持 v8k
scoped 结论，不能外推全核 finite-generation no-live-reuse、architecture inventory、Linux、
综合/STA 或 PPA。

## C1 身份出生与唯一 holder

1. pending SYSTEM capture 时事务尚未进入 ROB，`producer_valid=0`；PC/inst 不是事务身份。
2. 只有真实 `system_csr_dispatch_fire` 才出生 full
   `P={generation[PRODUCER_GEN_W-1:0], rob_idx[ROB_INDEX_W-1:0]}`，并在该上升沿把 backend
   `dispatch0_producer_id` 锁存到 `OooPendingSystemSequencer`。
3. 从该沿后到合法 death edge，pending sequencer 是该 pending CSR 的唯一附加 Q holder；
   raw `producer_valid_q -> valid && csr && dispatched` 是必须成立的诊断不变量，P 不变；但
   birth fence 与提交封口必须直接读取 raw lease，不能把 metadata 一致性故障变成复用窗口。
4. raw ROB index 如需观测，只能由 `P[ROB_INDEX_W-1:0]` 投影；PC 只作 payload coherence，
   不得替代 P。
5. sequencer empty 的定义是 `!valid_q && !producer_valid_q`。任何非 empty recapture 均须
   生产态拒绝并 fail-loud，不能覆盖 pre-ROB payload、P 或 post-dispatch payload。

## C2 Q-only birth fence 与无环边界

`pending_system_producer_live_mask` 只能由 sequencer 的 edge-old raw
`producer_valid_q/producer_id_q` 解码：

```text
lease_mask[P] = producer_valid_q && producer_id_q == P
global_external_live_mask = memory | muldiv | clmul | fp | pending_csr
```

- `producer_valid_o` 必须原样导出 raw `producer_valid_q`。`valid/csr/dispatched` 只用于
  assertion 与 commit candidate，不得相与到 live mask。
- mask 经 `OooCoreTopGlue -> OooExecuteBackend -> OooAluCoreSlice ->
  OooAluDecodeBackend -> OooIntBackend` 下传后并入既有 dispatch birth fence。
- mask 禁止读取 dispatch candidate/fire、commit、ready、组合 authorization 或 capture D；
  因而不存在 `candidate -> mask -> ready -> fire -> holder` 组合反馈。
- dispatch 出生沿看到 edge-old `producer_valid_q=0`，不会自阻断；death 沿仍看到 edge-old
  lease，因此同沿不得借回同一 P，下一拍才释放。
- backend dispatch PID 和 commit head PID 只作为向控制面的观察输出，不进入 transport ready。

## C3 精确提交授权与 head0 回退封口

定义：

```text
logical_claim = pending.valid && pending.csr && pending.dispatched
claim_seal   = pending.producer_valid || logical_claim
candidate    = logical_claim && pending.producer_valid && core_commit0_csr
pid_match    = core_commit0_producer_id == pending.producer_id
pc_match     = core_commit0_pc == pending.pc
pending_commit = candidate && pid_match && pc_match
```

只有 `pending_commit` 可以驱动 pending CSR 的 CsrFile write、SATP boundary、pending clear、
serial redirect/retirement 等既有副作用。完整 P 是授权主键，PC 是额外 fail-closed coherence；
同 raw index 不同 generation、同 PC 不同 P、同 P 不同 PC 均不得提交。

`head0_csr_commit` 的回退规则固定为：

```text
head0_commit = OOO_CSR_QUEUE_HEAD && core_commit0_csr && !claim_seal
```

理由：pending CSR 只在 backend 已排空后才 dispatch；逻辑 claim 或 raw lease 任一存在时均不允许
另一个合法 CSR 提交者。若 metadata 被部分清除或 P/PC mismatch，pending 与 head0 两路必须同时
为 0，禁止把一致性故障重新解释为普通 head0 CSR。pre-dispatch 的 raw lease=0、logical claim=0
中间态仍允许更老的 queue-head CSR 正常提交。

## C4 生命周期、死亡边与同拍优先级

| 事件 | pending payload | lease | 提交能力 |
|---|---|---|---|
| reset / global flush | 清 | 清 | 0 |
| pre-ROB `pending_system_clear` | 清 | 无 lease | 0 |
| empty + IRQ/head0/lane1 capture | 建立 pre-ROB payload | 保持无效 | 0 |
| 合法 CSR dispatch fire(P) | `dispatched=1` | 出生 P | 0 |
| dispatched CSR 等待 ROB head | 保持 | P 稳定且 live | 0 |
| exact commit(P)+PC coherence | 沿前脉冲 | 沿后由 exact death 清 | 1，且仅一次 |
| stale/mismatch core commit | 保持并 fail-loud | 保持 | pending/head0 两路均 0 |
| live lease + ordinary clear/recapture/clear-dispatched | 保持并 fail-loud | 保持 | 不得丢失归属 |
| backend global flush（`core_local_flush`） | 与 ROB 同沿清 | 与 ROB 同沿清 | 0 |

时序全序固定为：`reset/backend-global-flush > exact live death > pre-ROB explicit clear > empty
capture > legal dispatch birth > non-live clear_dispatched > pre-dispatch rdata refresh > hold`。
live lease 不接受 ordinary clear、recapture 或 `clear_dispatched`；合法 post-dispatch death 白名单
只有 reset、与 ROB 同沿的 `core_local_flush`、或 exact pending commit。未来若增加 selective death，
必须携带 pid-matched ROB kill witness 后重新冻结合同。

`system_csr_dispatch_valid/fire` 还必须被 reset、`core_local_flush` 与所有无反馈的 ordinary-clear
witness 门控。完整 `pending_system_clear` 含 backend-ready 派生的 `direct_frontend_flush`，不得直接
反喂 admission，否则形成 `valid -> ready -> direct fire -> clear -> valid` 组合环；pending-system
owner 令 `can_run=0`，所以 direct frontend flush 与该 replay 必须由独立 assertion 证明互斥。
任何 level-ready 必须先与真实 clear outcome 相与后才能取得取消能力；尤其 pending-jump 只有
`resolve_ready && (misaligned || nolink_commit || redirect_after_dispatch)` 才是 clear witness，裸
`resolve_ready` 不得造成 pending CSR 的有界进展自锁。
若同拍存在可达 cancel witness，ROB lane0 不得接受该 pending CSR，从源头避免“ROB 已出生 P、
sequencer 未锁存 P”的 orphan。

## C5 可执行不变量

- `[V8K-PENDING-CSR-LEASE-SHAPE]`：raw `producer_valid_q` 蕴含
  `valid_q && csr_q && dispatched_q`。
- `[V8K-PENDING-CSR-DISPATCH-BIRTH]`：dispatch fire 蕴含 edge-old valid CSR、未 dispatched、
  未持 lease；沿后保存输入 full P。
- `[V8K-PENDING-CSR-LEASE-STABLE]`：无 death edge时 live P 与 pending PC/inst 保持不变。
- `[V8K-PENDING-CSR-NO-RECAPTURE]`：任何 non-empty holder 与 capture 不共拍；live lease 与
  ordinary clear/clear-dispatched 不共拍；生产逻辑即使收到违约输入也保持原 holder。
- `[V8K-PENDING-CSR-EXACT-COMMIT]`：任何 pending CSR commit 蕴含 full P exact match 与 PC match。
- `[V8K-PENDING-CSR-STALE-SILENT]`：claim active 而 P/PC mismatch 时 pending/head0 commit、SATP
  commit 和相关架构副作用均为 0。
- `[V8K-PENDING-CSR-HEAD0-DISJOINT]`：pending commit 与 head0 commit 互斥；raw lease 或
  logical claim 任一存在时 head0 commit 恒 0。
- `[V8K-PENDING-CSR-QONLY-LIVE]`：pending live mask 只读 raw sequencer Q lease，不能引用
  metadata、ready/fire/commit/authorization。
- `[V8K-PENDING-CSR-FIRE-COHERENCE]`：`system_csr_dispatch_fire` 必须等于被选中的 backend lane0
  实际接收事件，锁存的 P 低位等于本次 ROB dispatch index。
- `[V8K-PENDING-CSR-DEATH-WITNESS]`：raw lease 的下降沿只允许 exact pending commit、reset 或
  与 ROB 同沿的 backend global flush。
- `[V8K-PENDING-CSR-NO-ORPHAN-BIRTH]`：任何 system CSR ROB enqueue 同沿必须出生 raw lease；
  reset/flush/ordinary clear 同拍必须令 enqueue=0。

每条承重断言必须有定向违约或 compile-success mutation 命中，不能只依赖正向回归。

## C6 必需验证

1. sequencer：pre-ROB capture 无 lease；dispatch 后 full nonzero-generation P 保持；exact death；
   reset/backend flush；non-empty recapture、live ordinary clear 与 clear-dispatched 被拒绝；
   P/PC/inst 稳定；逐一部分清除 valid/csr/dispatched 时 raw lease 仍承重。
2. CSR mux：exact P+PC 提交；same raw/different generation、same PC/different P、same P/different
   PC 全静默；raw lease/logical claim 任一存在时不得落入 head0；pre-dispatch older head0 仍可提交。
3. IntBackend/dispatch：pending Q lease 的 bit 被并入 birth fence；candidate 与 live P 冲突时
   ready fail-closed；lease death 只在下一拍开放，不形成组合环。
4. top integration：system CSR fire 锁存该次 backend dispatch P，commit head P 原样回传；副作用
   only-once，direct head0 CSR 与 pre-dispatch younger pending CSR 共存不回退；fire 与 reset/global
   flush/trap/direct/generic clear 全交叉，只有真实 enqueue 才出生 lease。
5. compile-success mutation 至少删除 generation compare、producer-valid、claim-active head0 fence、
   Q-only live-mask contributor、dispatch capture 或 live recapture fence之一，并由 focused/static
   证据击杀。
6. legacy v8d-v8j、相关 CSR/pending focused、fresh module aggregate 与 contract/static guard 不回退。
