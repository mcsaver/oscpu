# OooBranchBpuUpdateGate Spec

> ⚠️ **状态(2026-07-03 RTL 重读)**:旧四个 update 臂(direct/pending/drained/commit)在 mode=1+`OOO_DBRANCH_DOMAIN_A` 下全死——direct 臂依赖拍内快解析(恒 0),pending/drained/commit 三臂依赖 pending_branch(capture 被 `!rob_walk_mode` 门死);BPU 回训唯一活源 = F2 issue-resolve 臂(`resolve_update_*`,后端每条条件分支 resolve 拍回训,含预测正确者),模块内注释自证(`OooBranchBpuUpdateGate.v:33-35`);另 `branch_bpu_pending0_capture` 因 `direct_branch0_dispatch_valid` 恒 0 而语义漂移为"每个 head0 分支拍都置位",现仅驱动 lookup_event 统计;拆除计划见 `../arch/ooo-core-architecture.md` §8.3。下文保留其设计语义描述,并已补记 resolve 臂。

## Scope

`OooBranchBpuUpdateGate` owns the combinational predicates and muxing used to
feed branch direction predictor lookup/update sideband logic in
`OooFrontend` (formerly `OooAluFetchCore`).

It does not store predictor state, mutate BHT/PHT entries, compare branch
operands, update RAS/BTB state, or own any pending branch register. The parent
remains the owner of branch state, resolve/recovery sequencing, the
`OooBranchDirectionPredictor` table instance, and PC/outstanding control.

## Inputs

- Frontend run/packet state used to capture pending branch lookup sideband
  facts.
- Direct branch fire and BHT valid sideband facts.
- Direct branch resolve, pending branch resolve, drained pending branch, and
  pending branch commit-resolve events.
- Pending/direct branch prediction metadata: predicted-taken, PC, BHT index,
  resolved next PC, target PC, and actual taken facts.
- F2 issue-resolve update sideband: `resolve_update_valid/taken/pred_taken/
  pc/bht_idx` exported from the backend branch resolve bus (BHT index and
  predicted-taken travel with the uop through the issue queue).

## Outputs

- Pending lane0/lane1 branch lookup capture predicates.
- Aggregate branch lookup event and BHT-valid sideband status.
- Direct, pending, drained, and commit update class predicates.
- Aggregate update-valid and pending-like update predicates.
- Selected actual-taken value, selected predicted-taken value, correctness
  predicate, update PC, and update BHT index.

## Invariants

- Pending lane0 capture requires frontend not flushing, runnable, a dispatch
  packet, lane0 branch, and no direct lane0 branch dispatch.
- Pending lane1 capture requires frontend not flushing, runnable, a dispatch
  packet, lane1 barrier fire, and raw lane1 branch.
- Lookup event is true when a direct branch fires or either pending capture
  fires.
- Lookup BHT-valid is the OR of the valid bit attached to whichever direct or
  pending lookup event fires.
- Direct update mirrors direct branch resolve valid.
- Pending update requires stop-pending branch ownership, pending branch already
  dispatched, and branch resolve pending-match.
- Drained update requires stop-pending branch ownership, drain complete, and an
  undispatched pending branch.
- Commit update mirrors pending branch commit-resolve.
- Update-valid is the OR of the four legacy update classes plus the F2
  issue-resolve update event.
- Pending-like updates are pending/drained/commit updates; they select pending
  PC/BHT/prediction metadata.
- Pending resolve actual-taken is true only when the resolve target equals the
  pending branch target and the resolve is not misaligned.
- Drained and commit updates use the stored pending branch taken bit.
- Direct update uses the direct branch resolved-taken bit.
- When no pending-like or direct class fires, taken/predicted-taken/PC/BHT
  index all fall back to the F2 resolve-update metadata (the only live source
  in mode=1).
- Update correctness is selected predicted-taken equal to selected actual-taken.

## Non-Goals

- No predictor arrays or saturating counter updates.
- No branch operand compare.
- No state machine ownership.
- No RAS/BTB updates.
- No fetch redirect or recovery sequencing.
