# v8j branch-resolve holder census delta

## 边界

- source：`OooIntBackend` lane0 control-flow issue fire。
- stateful holder：`u_branch_resolve_stage` 一拍 q。
- co-holder：`u_ex0_stage`，由同一 fire 产生，已保存 full ProducerId。
- authority sink：frontend redirect、ROB-walk boundary、BPU update、integer/FP IQ、MulDiv、CLMUL、
  memory reservation/MIQ/SQ 的 selective kill。

## 当前状态

| holder/capability | 当前身份 | 当前资格 | 风险 |
|---|---|---|---|
| branch resolve q | raw ROB index | stage valid + cancel mask | 旧 generation 可借同 raw index 取得控制副作用 |
| EX0 q | full ProducerId | ROB completion exact-open + pending/claim fence | 已 scoped GREEN |
| downstream branch valid | 不携身份的布尔 capability | 直接继承 raw resolve valid | capability 尚未由 full PID 权威签发 |

## v8j 目标状态

- resolve q 保存 full `P={generation,index}`，raw boundary 只从 P 低位投影。
- ROB 提供用途单一的 `resolve_query_match(P)`：`valid && exact P && !done && !recover_q &&
  !reset/flush`。它刻意不读取同拍 `kill_valid_i`，因为该 kill 正是 P 自己生成且 boundary 必须存活；
  这也切断 query→mispredict→kill→query 的组合反馈。
- actual branch capability 还要求 raw registered EX0 co-holder `ex0_valid_q` 且 full PID 与 resolve P
  完全相等；禁止用 completion/semantic valid 做 coherence，以免经 killed-now 把 self-kill 组合环接回。identity
  mismatch 在生产态 fail-closed，assertion 只负责暴露错误，不承担安全机制。
- 不新增 state、ready、FIFO 或 birth fence：resolve q 与 EX0 q 同生同死，ROB query 只签发
  actual capability，不进入 transport/ready。

## 仍不覆盖

- pending-system/CSR、pending trap/exit、其它 detached owner；
- full-core field/instance census 和 finite-generation global no-live-reuse；
- 系统验证及 PPA promotion。
