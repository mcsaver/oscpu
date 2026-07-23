# v8k pending CSR ProducerId lease RTL derivation

## 1. Root cause

原链路把 lane1/head0 pending CSR 在排空后重新注入 ROB，但 pending owner 只保存
`PC/inst/dispatched`。ROB 内部已经以 `ProducerId={generation,index}` 区分事务，控制面却用 PC
判断 pending commit，并用 `!pending_commit` 作为普通 head0 CSR 的回退条件。因此存在两个同源问题：

1. pending sequencer 是真实的 post-dispatch stateful holder，却没有进入 full-PID live census；
2. PID/PC mismatch 会把 pending 授权失败错误解释成 head0 授权成功，而不是 fail closed。

症状级增加 PC 比较或 raw ROB index 都不能修复 generation reuse，也不能关闭 partial-metadata
故障下的 fallback。

## 2. Owner/source-of-truth

- pre-ROB owner：`OooPendingSystemSequencer.valid/csr/...`，尚未分配 ProducerId；
- birth event：`system_csr_dispatch_fire_w == core_dispatch0_fire_w`；
- transaction identity：该沿 `OooIntBackend.dispatch0_producer_id_o` 的 full PID；
- post-birth additional holder：sequencer 的 raw `producer_valid_q/producer_id_q`；
- storage owner：ROB slot；commit witness 是 `commit0_producer_id_o`；
- side-effect authority：`OooCsrAccessRequestMux.pending_system_csr_commit_o`；
- death witness：exact pending commit，或与 ROB 同沿的 `core_local_flush_w`/reset。

PC 只保留为 payload coherence，不能替代 PID。

## 3. Birth/hold/death equations

```text
empty = !pending.valid_q && !pending.producer_valid_q

birth = system_csr_dispatch_fire
     && pending.valid_q && pending.csr_q
     && !pending.dispatched_q && !pending.producer_valid_q
     && !system_csr_admission_clear

lease_next =
  0                 on reset/core_local_flush
  0                 on exact pending_commit
  {1, dispatch_pid} on birth
  lease_q           otherwise
```

Capture 时不制造 PID；只有真实 ROB enqueue 才 birth。live lease 时 ordinary clear、
`clear_dispatched`、refresh、第二次 dispatch 或 recapture 都保持 Q 并由 assertion fail-loud。

## 4. Q-only no-live-reuse fence

```text
pending_mask = producer_valid_q ? onehot(producer_id_q) : 0
external_live_mask = memory | muldiv | clmul | fp | pending_mask
dispatch_ready[P] &= !external_live_mask[P]
```

`pending_mask` 只读 raw Q，不读 metadata、ready、fire、commit、authorization 或 capture D。
出生沿看到 edge-old lease=0，不会自阻断；死亡沿仍看到 edge-old lease=1，同沿不能借回 P，下一拍
释放。完整 transport 为：

```text
ControlPlane Q lease
  -> CoreTopGlue
  -> ExecuteBackend
  -> AluCoreSlice
  -> AluDecodeBackend
  -> IntBackend producer_live_mask

IntBackend dispatch/head full PID
  -> AluDecodeBackend
  -> AluCoreSlice
  -> ExecuteBackend
  -> CoreTopGlue
  -> ControlPlane sequencer/CSR mux
```

所有 wrapper 都传 full PID；没有从 raw index 重建 generation。

## 5. Commit capability and fallback seal

```text
logical_claim = pending.valid && pending.csr && pending.dispatched
claim_seal = pending.raw_producer_valid || logical_claim

pending_commit = logical_claim
              && pending.raw_producer_valid
              && core_commit0_csr
              && core_commit0_pid == pending_pid
              && core_commit0_pc  == pending_pc

head0_commit = OOO_CSR_QUEUE_HEAD
            && core_commit0_csr
            && !claim_seal
```

raw-only、logical-only、same-index/different-generation、same-P/different-PC 都令 pending/head0 两路
为 0。pre-dispatch pending 尚无 raw lease/logical claim，因此不会误挡更老的 direct head0 CSR。

## 6. Enqueue/cancel/flush ordering

`OooPendingDrainResolveGate.system_csr_dispatch_valid_o` 先读取
`system_csr_dispatch_cancel_w = rst || core_local_flush_w || system_csr_admission_clear_w`。其中
`system_csr_admission_clear_w` 枚举不读取 backend ready/fire 的 ordinary-clear witness；完整
`pending_system_clear_w` 的 direct-frontend 分支不反喂 admission，避免
`valid -> ready -> direct fire -> clear -> valid` 组合环。pending-system owner 令 `can_run=0`，
`[V8K-PENDING-CSR-DIRECT-FLUSH-MUTEX]` 独立守住 direct flush 互斥。因此可达高优先级 clear/flush
同拍不会产生“ROB enqueue 但 lease 未出生”。sequencer reset 与
`OooExecuteBackend.u_core_slice.flush_i` 都使用同一 `core_local_flush_w`，保证 ROB 和附加 holder
同沿死亡。

pending-jump 的 witness 使用
`resolve_ready && (misaligned || nolink_commit || redirect_after_dispatch)`，不能用裸
`resolve_ready` 作保守上位取消：后者若为持续电平，会让 pre-ROB pending CSR 永久保持 stop owner
却永不 birth。standalone admission-gate TB 固定 `ready=1`、三项 outcome=0，要求 cancel=0；对应
compile-success mutation 把条件退化为裸 ready，必须被该反例拒绝。

## 7. Executable evidence mapping

- sequencer legal path：pre-ROB no-P、nonzero-generation birth、hold、exact-death+ordinary-clear cross、
  backend flush；
- release malformed probes：partial metadata、live clear、live clear-dispatched 均保持 raw lease；
- assertion-negative probes：partial metadata 与 live clear 均命中承重 marker；
- CSR mux：exact、stale generation、PC mismatch、raw-only、logical-only、pre-dispatch fallback；
- IntBackend：onehot census、exact PID reuse fence、death reopen、public dispatch/commit PID transport；
- real privilege forward：lane1 CSRRW 的 edge-old birth、下一拍 live census、exact PID+PC commit、
  head0=0、下一拍 death 各 exactly once；
- compile-success mutations：删 raw output、death fence、generation capture/compare、PC compare、claim
  seal、dispatch cancel、holder-mask contributor，均必须由对应语义测试击杀。

本推导仅支持 v8k dispatched pending CSR scoped 架构结论，`promotion_eligible=false`；不外推全核
holder census、Linux 或 PPA。
