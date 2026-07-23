# v8i RTL derivation

## Holder / dataflow

`ROB allocation PID -> FP IQ -> issue packet -> {arith meta | exec1 | long meta}`

`execution raw winner -> result exact-open/claim -> FP PRF+Busy+wakeup+done FIFO`

`done FIFO raw head -> formal exact-open/claim -> shared WB/ROB/GPR/public`

`done FIFO occupied PID -> completion_pending_mask -> fence every non-formal completion source`

`arith[1..5]+exec1+long+fifo_count -> execution launch credit -> issue packet hold/launch`

## 关键结构选择

- 不把 generation 作为平行 shadow pipeline；直接替换每个 raw-index Q holder，避免两份身份漂移。
- 不把 exact-open 接入 ready/FSM；stale 数据沿原 transport terminal 排空。
- 不把 result candidate 与 formal head 合并成一个 query，因为 streaming FIFO 下两者可同拍出现；
  分别使用两个 ROB Q-only query。
- 不提前进入 arch-stable/PPA；`OooFpArithGate` macro placeholder 只做接口同步。
- 不另建与 FIFO 平行的 pending scoreboard；已授权 result 原子 push 的 FIFO Q entry 本身就是
  completion-owner token，避免 identity/payload 两份状态漂移。
- 不用旧 `fifo_count<=2` 经验阈值推断容量；直接计算每个 post-launch Q holder 的精确占用，
  因 kill、raw stale drain 与 holder transfer 会自然反映在下一拍 credit 中。

## reviewer 反例处置

- 跨周期 duplicate claim：确认存在，新增 FIFO pending capability，并要求 EX0(P)/第二 FP(P)
  延迟一拍反例和 fence mutation。
- FIFO 不可背压容量：确认旧 `count<=2` 不覆盖 exec1/long/issue timing，新增精确 launch credit、
  16 拍 shared-WB 阻塞与第 9 个 packet hold 反例。
- pending/authorization 只门控 actual side effects；raw source take、shared-WB route/ready 与 tracker
  terminal 不读它们。
- branch、pending-system/CSR、全核 census 与 global no-live-reuse仍作为 residual RED。
- implementation reviewer 的同槽 replacement 反例以一拍 push-survival assertion 锁定：push
  捕获 slot/PID/kill-derived tombstone，下一沿检查新 token 完整驻留；direct TB 构造 credit 使其
  production-unreachable 的 full/head=tail 状态，验证 defensive 分支本身。
- stale formal `P={g,i}` 与 live `Q={g+1,i}` 同 raw index时，pending lookup、claim equality与
  raw route 都按 full PID 分离；EX0(Q) 和 FP result(Q) 各有 actual-positive directed evidence。
- `arith > exec1 > long` 的固定优先级有限进展依赖有限 ROB 与 eventual-ready；本轮有九操作真实
  drain 和全模块回归，但没有独立形式证明，保持审查 residual risk。
