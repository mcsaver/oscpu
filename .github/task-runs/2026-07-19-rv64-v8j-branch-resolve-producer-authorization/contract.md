# v8j branch-resolve ProducerId authorization contract

## C0 范围与声明等级

本合同只冻结 `OooIntBackend → OooDispatchBackend → OooRob` 的 branch-resolve producer
authorization。任务类别为架构闭合，`promotion_eligible=false`，不形成 PPA、频率或全核正确性结论。

## C1 身份与 holder

1. 每次 `issue0_ctrlflow_fire` 产生一个 full ProducerId P，并同时进入 EX0 q 和 branch-resolve q。
2. branch-resolve q 只能保存 full P；对外 raw ROB boundary 必须是 `P[ROB_INDEX_W-1:0]` 的投影。
3. branch-resolve q 与 EX0 q 必须 full-PID 相等；raw index 相等不构成 coherence。
4. coherence 只能读取原始寄存 holder `ex0_valid_q` 与 `ex0_producer_id_q`。禁止读取
   `ex0_pre_auth_valid_w`、`ex0_producer_open_w`、`ex0_wb_valid_w` 或任何经过 completion query、
   `kill_valid_i`、semantic-valid 门控的派生信号；否则会从 EX0 路径把 self-kill 反馈环接回来。

## C2 cycle-free resolve query

ROB 增加用途单一的 resolve query：

```text
resolve_open(P) = query_valid
               && !reset && !flush
               && !recover_q
               && rob.valid[P.index]
               && !rob.done[P.index]
               && rob.full_pid[P.index] == P
```

- query 只读 edge-old ROB state，不写状态，不进入 ready、issue、transport 或 credit。
- query 不读取同拍 `kill_valid_i`。当前唯一 kill source 是被授权 resolve 自己；把 self-kill 纳入
  query 会形成组合反馈，并错误拒绝必须存活的 branch boundary。
- 已在进行的 prior recovery (`recover_q=1`) 必须拒绝新 resolve capability。
- “`kill_valid_i` 唯一由本 capability 产生”是本合同的结构前提。若未来引入独立的同拍 older-kill，
  必须先扩展无环的仲裁/年龄合同，不得直接沿用本 query。
- `flush_i` / `checkpoint_restore_i` 必须是外部死亡边，不能由本 capability、redirect 或 ROB-walk
  组合反向产生；结构审计必须证明不存在旁路反馈。
- 既有 `producer_target_killed_now` 被多个 query 并行调用；函数必须为 `automatic`，且
  `head/kill/recovery` 全部作为显式实参进入调用表达式。禁止在函数体隐式读取这些全局信号，
  否则同 raw index 下 kill 翻转可能不触发仿真重新求值并残留上一拍结果。

## C3 actual branch capability

```text
candidate(P) = resolve_stage_valid && !reset && !flush && !checkpoint_restore
coherent(P)  = ex0_valid_q && ex0_producer_id_q == P
authorized(P)= candidate(P) && resolve_open(P) && coherent(P)
```

只有 `authorized(P)` 可以驱动全部语义输出：resolve valid/payload、mispredict、redirect、ROB walk、
BPU update 和所有 selective kill。raw candidate 可被无条件一拍消费，但不得产生任何控制副作用。
这里的 `ex0_valid_q` 是物理寄存 token，不是正式 WB/完成授权 valid。

## C4 flush/kill/recovery 表

| 同拍事件 | resolve q 状态 | query | actual capability |
|---|---|---|---|
| reset / global flush | 清 q | closed | 0，所有 payload 输出归零 |
| checkpoint restore | 清 q | 不作为授权依据 | 0，所有 payload 输出归零 |
| prior ROB recovery (`recover_q=1`) | 不应有新 q | closed | 0 |
| current P mispredict self-kill | q 正常消费 | 不读 self-kill | P 可授权，严格年轻后缀被取消 |
| P slot invalid/done/generation mismatch | q 可物理消费 | closed | 0 |
| EX0 absent/full-PID mismatch | q 可物理消费 | 可 open | 0，生产态 fail-closed |

优先级全序：`reset/global flush > checkpoint/prior recovery > exact-open + full-PID coherence >
authorized branch effect > ordinary consumption`。上层既有 `trap/exit > CSR/xRET > branch > BPU/RAS >
顺序 PC` redirect 全序不变。

## C5 可执行不变量

- `[V8J-BRANCH-FULL-PID-COHERENT]`：actual branch capability 必须与 raw registered EX0 token 的
  full PID 完全相等。
- `[V8J-BRANCH-RESOLVE-AUTH]`：任何语义输出必须蕴含 resolve query open。
- `[V8J-BRANCH-STALE-SILENT]`：candidate 存在但 query closed/coherence false 时，所有语义输出为零。
- `[V8J-BRANCH-PID-PROJECTION]`：对外 raw index等于 authorized P 的低位。
- `[V8J-BRANCH-QUERY-NO-TRANSPORT]`：query match 不得出现在 stage ready/valid 保持方程中。
- `[V8J-BRANCH-RAW-EX0-ONLY]`：coherence 锥不得引用 completion-open、killed-now、WB-valid 或
  `kill_valid_i`；resolve query 锥也不得引用 `kill_valid_i`。

每条 assertion 必须由定向违约或 compile-success mutation 证明非真空。

## C6 必需验证

1. live P：ROB exact-open、EX0/resolve P 相等，correct resolve 与 mispredict 均只脉冲一次。
2. stale P/live Q 同 raw index：query closed，redirect/kill/BPU-facing resolve 全静默。
3. ROB Q open，但 resolve P/EX0 Q generation 不同：即使 raw index相同也 fail-closed。
4. done/invalid/prior-recovery/reset/flush/checkpoint death edge 全静默。
5. current mispredict self-kill 不形成组合环；所有 resolve 语义输出恰好一拍，boundary P 正常完成，
   严格年轻事务仍被取消。
6. 结构依赖审计证明 capability 只读取 raw `ex0_valid_q/P`，query 不读取 `kill_valid_i`，且
   `flush/checkpoint` 不是 capability 的组合后代。
7. generic completion query 保持同一 P/idx，先置 current kill 再撤销；撤销后必须组合重开，
   证明 killed-now 的全部敏感性依赖已显式化。
8. 删除 generation、query、raw-EX0 coherence、done/recovery/cancel 任一 fence，或把 coherence
   换成 semantic EX0 valid / 把 query 换成 killed-now-inclusive 的 compile-success mutation，
   必须被定向证据、结构审计或 lint 检出。
