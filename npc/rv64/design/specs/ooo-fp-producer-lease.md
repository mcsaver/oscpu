# 规范：FP ProducerId lease、双阶段完成授权与 raw drain（v8i）

> 状态：architecture closure，`promotion_eligible=false`。本规范只覆盖 production FP IQ、
> issue packet、arith/exec1/long metadata、done FIFO 及其在整数后端中的完成授权。branch、
> pending-system/CSR、全核 holder census 与 finite-generation global no-live-reuse 继续 RED。

## 1. Root cause 与范围

当前 `OooFpBackend` 的 FP 事务身份在六类 Q holder 中仅保存 raw ROB index：

1. `OooFpIssueQueue` resident entry；
2. FP IQ→execute issue packet；
3. `OooFpArithGate` 五级 metadata pipeline；
4. exec1 组合类结果 stage；
5. long-op metadata/done hold；
6. done FIFO 到 `fpwb` formal completion。

generation 回绕后，仅凭 index 无法区分旧事务与当前 ROB incarnation。更重要的是，FP FPR
结果在进入 formal-WB FIFO 前就会写 FP PRF、清 busy 并广播 wakeup；因此只在最终 `fpwb`
端增加 exact-open 比较不能关闭前级副作用。

本切片不改变 FP 数值算法、FP arith 五拍延迟、三源 raw 仲裁优先级、done FIFO 深度、共享
WB transport 优先级或恢复年龄定义。它把完整 ProducerId 作为唯一时序身份，并分别授权：

- **result candidate**：执行结果进入 FP PRF/Busy/wakeup 与 done FIFO；
- **formal FPWB head**：done FIFO 进入 shared WB/ROB/GPR/public completion。

## 2. 身份与 holder 合同

`ProducerId={generation[3:0],rob_idx[3:0]}`，宽度由 `OOO_PRODUCER_ID_W` 定义。

### FP-PID-I1：唯一时序身份

上述六类 holder 只能寄存 full ProducerId。raw ROB index 只能由
`producer_id[ROB_INDEX_W-1:0]` 组合投影，用于年龄、既有 payload ABI 或观测；不得并列保存
第二份 raw identity state。

### FP-PID-I2：Q-only lease

`OooFpBackend.producer_live_mask_o` 只能由以下 edge-old Q 状态解码并集生成：

- FP IQ valid entries；
- issue packet `down_valid` + full PID payload；
- arith meta stage1..5 valid + full PID；
- exec1 stage `down_valid` + full PID payload；
- `long_meta_valid_q` + full PID；
- done FIFO 当前 head/count 覆盖的所有占用 entry + full PID。

禁止把 dispatch input、issue combinational output、result candidate、next-state、ready、query-open
或 completion authorization 混入 live mask。lease 在 raw terminal/kill/flush 沿仍反映 edge-old
holder，下一拍才释放；若同沿把身份转移到下一 Q holder，旧 Q lease 已足以阻止同沿 birth。

### FP-PID-I3：局部无重复 owner

同一 full PID 在 FP IQ 内、arith 五级内、done FIFO 内以及六类 holder 之间最多出现一次。
双 dispatch candidate 的 PID 不同由 ROB `tail/tail+1` 合同继承；任何重复 PID 必须在
`OOO_ASSERT` 下 fail closed。

### FP-PID-I3A：result-pending completion owner

已授权 result candidate 必须在同一时钟沿原子写入 done FIFO；FIFO 的每个 occupied Q entry
既是 formal payload holder，也是该 full PID 的跨周期 completion-owner token。由全部 occupied
entry（包括 killed tombstone）解码得到 `completion_pending_mask`。在 token raw-pop 之前，除该
token 到达 FIFO head 后发起的 formal FPWB 外，EX0、EX1、memory、MulDiv、CLMUL 与新的 FP
result candidate 均不得对相同 PID 产生 actual side effect。断言只负责报错，生产态门控必须
fail closed。

### FP-PID-I3B：不可背压结果的 launch credit

IQ→execute packet 是可保持的 pre-launch holder；它只有在以下 edge-old execution-credit 使用量
严格小于 FIFO 深度时才可 `issue_fire`：

`arith_meta_valid[1..5] + exec1_valid + long_meta_valid + done_fifo_count < 8`。

每次 execution launch 原子取得一个 completion credit。事务在 arith/exec1/long 与 FIFO 间转移
不改变 credit 数；pre-FIFO kill/closed-result raw drain 释放 credit，FIFO raw-pop 释放 credit。
credit 只能由 Q occupancy 推导，不得读取 result authorization、query-open、ready 或 next-state。
这保证任何已发射且不可背压的 arith result 到达时都有物理 FIFO 槽；可以保守拒绝“同拍 pop
释放的未来 credit”，但不得超发。

### FP-PID-I3C：FIFO push 原子性

同拍 `pop+push`（包括 defensive full/head=tail 同槽 replacement）时，新 push 必须原子决定目标
slot 的 `valid/full PID/pdest/rd_en/value/fflags/killed`。edge-old token 的 kill/tombstone 更新与 pop
不得覆盖或污染新 token。`OOO_ASSERT` 必须捕获每次 push 的 slot/PID/kill-derived tombstone，并在
下一沿确认该 token 完整驻留至少一个周期。

## 3. raw transport 与 actual authority

### FP-PID-I4：执行端 raw take

三源 raw 仲裁保持：`arith > exec1 > long`。kill-now 仍在 raw candidate 前剔除 strictly-younger
事务；胜出的 raw candidate 无论 authorization 是否成立，都必须让其源按既有 terminal 规则前进
或释放，以便旧结果排空。authorization 不得反馈到 arith pipeline、exec1 `down_ready`、long
meta release、issue ready 或 raw arbitration。

### FP-PID-I5：result candidate exact-open

FP backend 输出 `result_query_valid/result_query_producer_id` raw fact；ROB query 必须同时满足：

- query valid；
- 非 reset/flush；
- PID 低位所指 slot valid；
- slot generation 与 full PID 完全相等；
- slot `!done`；
- target 未在本拍 kill/recovery cut 中失去资格。

只有 `result_authorized = exact_open && !completion_pending[PID] &&
!same_edge_higher_claim` 才能驱动 FP PRF write、FP busy clear、FP wakeup、done FIFO push。
push 与这些副作用必须是同一个 actual fact，借此原子建立跨周期 completion owner。raw candidate
在 authorization=false 时只排空，不得留下任何延迟 side effect。

### FP-PID-I6：formal FPWB exact-open

done FIFO head 输出 raw `fpwb_valid/full_pid/payload`。shared-WB route 与 `fpwb_ready` 只由 raw
transport facts产生；ROB exact-open 和 same-edge claim 只门控 actual WB/ROB/GPR/Busy/IQ/public
valid。stale/closed head 获得 raw route 时仍被 pop，但所有 architectural/microarchitectural
side effect 必须为零。

## 4. completion-owner 与同沿 claim 全序

edge-old `completion_pending_mask[P]=1` 优先于普通同沿 source priority：它表示 P 已经把唯一
completion capability 交给 FIFO token。此时所有非 formal source 对 P 均 fail closed；只有承载
P 的 FIFO head 可尝试 formal exact-open。即使 token 尚未到 head，后来的同 PID source 也不能
绕过它提前完成 ROB。

对尚无 pending token 的 PID，普通 per-PID claim 顺序冻结为：

`EX0 > EX1 > memory > MulDiv > CLMUL > FP formal head`。

FP result candidate 是进入 formal FIFO 前的副作用点，低于上述 actual claims；一旦获胜，它在
该沿 push token，并从下一拍起由 pending owner 获得跨周期排他权。若同拍存在相同 PID 的 raw
FP formal head，pending mask 已强制抑制 candidate。不同 PID 可在同拍各自完成。

claim 比较只能读取 full PID 与 actual claim facts，不得进入 raw route、ready、holder mask、
issue/execute FSM 或 Q state update。每周期、每 full PID 最多一个 actual side-effect owner。

## 5. kill / flush / reset

- reset/flush 清所有 FP identity valid/Q occupancy；payload 可留脏但不得在 valid=0 时授权。
- kill/recovery cut 仍按 PID 低位 raw index 做环形年龄；generation 不参与年龄，只参与 incarnation
  equality。
- kill/flush 当拍禁止 FP IQ refill、issue launch 和新 holder birth；被取消事务不得产生 candidate
  或 formal actual completion。
- done FIFO killed/tombstone entry 在 pop 前仍持有 lease，但只能 raw drain，不能重新取得 authority。

## 6. 接口与结构边界

- `OooFpIssueQueue`：dispatch/issue full PID，raw issue index为组合投影，输出 Q-only live mask。
- `OooFpArithGate`：launch/out full PID；五级 meta 只保存 full PID，并导出五组 Q-only
  owner-valid/PID 观测供父层解码。数值 macro/OOC 语义与五拍延迟不变；placeholder liberty 接口
  必须同步，但本轮不产生任何 PPA 声明。
- `OooFpBackend`：issue/exec1/long/FIFO payload 全部携 full PID；输出 result query、formal PID 与
  FP live/pending mask，输入 result authorization；由 Q occupancy 计算 launch credit。
- `OooRob/OooDispatchBackend`：增加两个 Q-only exact-open query，分别服务 result candidate 与
  formal FPWB head。
- `OooIntBackend`：把 FP Q-only lease 并入 dispatch live mask；生成两个 authorization 与 claim
  fence；raw FP route/ready不读 authority。

## 7. 必须验证的反例

1. 非零 generation 在 FP IQ→issue→arith/exec1/long→done FIFO→formal WB 全链保持；逐 holder
   截断 generation 的 compile-success mutation 必须被检出。
2. vacant、wrong-generation、done、kill-now、flush 对 result/formal 两个 query 都拒绝；exact-open
   正控通过。
3. result candidate authorization=false 时，raw source被消费，但 FP PRF、busy、wakeup、FIFO
   count 均不变；删除任一 side-effect gate 的 mutation 必须失败。
4. formal head authorization=false 时，raw ready/pop仍发生，而 WB/ROB/GPR/Busy/IQ/public valid
   全静默；把 authority 接入 ready 或把 raw route当 actual valid 的 mutation 必须失败。
5. EX0/EX1/memory/MulDiv/CLMUL/FP formal 与 result candidate 的同 PID/不同 PID claim matrix；
   每个同 PID fence 删除 mutation必须失败。
6. IQ、issue、arith、exec1、long、FIFO 每类 Q-only lease 的 birth/hold/terminal/kill/flush
   death-edge；从 union 删除任一类 mask 的 mutation必须失败。
7. arith/exec1/long raw priority、持续 shared-WB 背压、FIFO 同拍 push/pop、killed tombstone drain，
   确保 generation/authorization 不改变 transport progress。
8. source-bound structural audit 必须拒绝 parallel raw identity state、next/ready/query 派生 mask、
   authority→ready/FSM 回边和 actual/public 使用 raw valid。
9. FP result(P) 已 push、formal 受阻期间，下一拍注入 EX0(P) 与第二个 FP candidate(P)：二者都
   必须 raw drain/hold 后静默，只有原 FIFO token 可 formal；删除 pending fence 的 mutation 必须失败。
10. shared-WB 至少持续阻塞 16 拍并连续发射 arith/exec1/long 混合结果：execution-credit 达到 8
    后 issue packet 必须保持，所有已 launch 结果均有 FIFO 承接；删除任一 holder 计数或 credit
    gate 的 compile-success mutation 必须失败。覆盖 count=7 时 push、pop、push+pop 及 killed
    tombstone pop 的指针/count/valid 原子更新。
11. 构造 full/head=tail 的 defensive 同槽 `pop+push+kill`，分别覆盖旧 P 被 kill/new Q 存活、
    旧 P 存活/new Q 被 kill、kill cut 对 P/Q 均不命中；下一拍 valid/PID/tombstone 必须属于 Q。
12. stale formal `P={g,i}` 占 raw route时，live `Q={g+1,i}` 的 EX0 与 FP-result actual-positive
    必须各自成立；禁止把 pending、same-edge claim 或 route 比较退化为 raw index equality。

## 8. 明确非声明

本切片不证明 branch/pending-system/CSR holder、全核 last-reference、generation 整圈回绕的
global no-live-reuse、full-core architecture GREEN、DiffTest/Linux、200MHz、area、STA、Power 或
Pareto 改善。所有综合/STA（若运行）只能标记 diagnostic、`promotion_eligible=false`。
