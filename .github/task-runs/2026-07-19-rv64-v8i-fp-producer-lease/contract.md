# RV64 v8i FP ProducerId lease 合同

## 状态与允许签收范围

- `task_class=architecture_closure_without_ppa_promotion`
- `parent_goal_state=active`
- `promotion_eligible=false`
- normative spec：`npc/rv64/design/specs/ooo-fp-producer-lease.md`

本节点只签收 FP IQ、issue packet、arith/exec1/long、done FIFO 的 full ProducerId lease，以及
执行结果和 formal FPWB 两个副作用点的 exact-open/claim authorization。branch、pending-system/
CSR、完整 holder census、global no-live-reuse 与 PPA 均保持 RED。

## 冻结设计

1. 六类 FP Q holder 只保存 full PID；raw index只作低位投影。
2. 六类 Q-only lease 的并集进入 dispatch birth fence，禁止 next/ready/query/authority 派生 mask。
3. raw `arith > exec1 > long` take 与 shared-WB route/ready继续负责 progress；authorization只门控
   actual side effects。
4. result candidate 只有 exact-open 且未被更高同 PID actual claim占用时，才写 FP PRF、清
   busy、wake、push done FIFO；还必须不存在 edge-old FP completion owner。
5. formal FPWB head 只有 exact-open 且未被 `EX0 > EX1 > memory > MulDiv > CLMUL` 同 PID claim
   占用时，才进入 WB/ROB/GPR/Busy/IQ/public side effects；raw stale head仍可 pop。
6. done FIFO occupied entry 是跨周期 completion-owner token；token 存在期间，所有非 formal
   同 PID source 均 fail closed，只有对应 FIFO token 到 head 后可尝试 formal。
7. execution launch 只在 `arith[1..5]+exec1+long+fifo_count < 8` 时发生；issue packet 可无损保持，
   不可背压结果不得依赖到达拍临时找 FIFO 槽。
8. raw formal head 与 result candidate 同 PID时，pending owner使 candidate fail closed。
9. kill/flush/reset、edge-old death/birth 与 holder-local duplicate assertions遵循 normative spec。
10. FIFO 同槽 defensive replacement 必须由 new push 原子决定 valid/full PID/tombstone；edge-old
    kill 或 pop 不得污染新 token。旧 generation formal raw transport 也不得阻塞同 raw index 的
    新 generation actual side effect。

## 硬门

- focused release 与 `OOO_ASSERT`；
- compile-success semantic mutation；
- relevant module aggregate；
- source-bound structural audit、RTL style、contract checker；
- strict lint 与 architecture inventory必须如实保留 RED，不得豁免；
- 独立 reviewer 反例必须转成 spec/TB/mutation/audit或剩余风险；
- task-run、memory、DB/e2e、strict guard 收尾。

## reviewer amendment v8i.1

独立契约审查 verdict=`gap`，两个 blocker 均进入冻结实现与硬门：

1. “result 已接受但 ROB 仍 `!done`”形成跨周期重复完成窗口；以 done FIFO Q token 的
   `completion_pending_mask` 作为生产态排他 capability，并把所有非 formal 完成源接入 fence。
2. “8-entry FIFO 满时第 9 个不可背压 arith result 无承接位置”；以全部 post-launch Q holder
   occupancy 推导 execution-launch credit，并要求长背压定向测试和删计数/gate mutation。

## reviewer amendment v8i.2

实现审查 verdict=`pass`、blocker=0。两个可直接构造的证据盲区仍被升级为硬证据：

1. full FIFO 同槽 `pop+push+kill` 由 push-survival assertion 与 old-only/new-only/neither-kill 三组
   directed case 锁定 new token 覆盖语义；
2. stale `P={g,i}` formal raw route 与 live `Q={g+1,i}` 共用 raw index时，Q 的 EX0/FP-result
   actual-positive 均必须成立。

固定优先级 FP completion 的独立 formal liveness 仍未完成，只能保留 residual risk；不得据此把
本地功能硬门或全核架构状态提升为 GREEN。
