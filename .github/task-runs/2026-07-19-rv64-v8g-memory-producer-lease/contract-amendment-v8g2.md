# v8g.2 second-review blocker amendment

## 二次独立复核结果

reviewer 确认 v8g.1 修正了首轮 3 个 blocker 的主方向，但拒绝给出 scoped
green，因为仍有 4 个可实现反例：

1. `effective_killed` 可使旧式 `completion_fire` 与 `closed_drain_fire` 同拍为真；
2. head PID 相等不能替代 STORE SQ / AMO interphase 的 exact capability 与 one-shot；
3. B 与同 PID `done_now` 同拍若进普通 death，会在未接受 B status 时释放 lease；
4. open response 虽可安全 stall，但尚未冻结 collector credit、无组合环和有界 WB grant。

二次 verdict 为“不可进入 RTL”。父目标保持 `active`，未重复派发也未弱化语义。

## 冻结修订

| blocker | v8g.2 冻结结论 | 承重证据 |
| --- | --- | --- |
| 分类重叠 | `owner_open=exact&&live&&rob_match&&!killed&&!done_now`，`owner_closed=exact&&!owner_open`；credit 不参与分类 | open/closed onehot 断言 + killed/exact 定向例 |
| launch capability | STORE 要求 SQ bound exact-live tuple + tracker/SQ/head PID chain + ROB launch-open + `!request_sent`；AMO 要求 interphase exact-live tuple + head PID + launch-open + `!amo_write_sent` | stale tuple、wrong generation、restore-before-fire、one-shot mutation |
| closed B death | closed physical DRAIN 只做 bus pop + fatal；不 WB、不进 normal collector、不清任何 normal STORE death，自身 live token 保持 poison 到 quiesce/reset | B+EX same-PID `done_now` 同拍例；death mask 变异 |
| credit/活性 | open/normal-closed 都在 terminal credit 后 pop；credit 只读 edge-old pending/其它 ingress/WB 空位，不读 release/free；stable open response 通过 lane1 EX admission gate 保证首个 full-WB stall 后下拍 memory grant | collector-backpressure hold、连续 EX 压力 watchdog、credit-cone 结构审计 |

## edge-old B release 公式

```text
b_release[t] =
  b_completion_fire[t] &&
  exact_old_live_store_tuple[t] &&
  last_authority_handoff_fire[t] &&
  no_authority_remains_after_this_event[t]
```

该式不读同拍刚写的 `sq_terminal_q`，不读 release 后空位；dispatch/alloc
继续读 edge-old PID/token live，所以 B completion/release 同拍不会重用。

active spec、task contract 与 RTL derivation 已同步 v8g.2；再次 reviewer clearance
前仍不进入 RTL。
