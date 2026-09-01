# RV64 current-head SQ idle fusion qualification：测量契约

## 目标

精确量化 `OooMemAxiBridge` 在 `S_IDLE && stage_advance_w` 接纳当前 MIQ-head load 的同一拍，
真实 StoreQueue 对最终 PA/owner tuple 给出的 `allow/forward/replay` 判决。此 task-run 只增加
`CONFIG_NPC_OOO_STATS` 下的只读 qualification probe 与 host counter，不实现 SQ-query bubble
fusion，也不改变非 stats build。

这里的 `idle` 专指 **bridge `S_IDLE` admission**，不是 StoreQueue empty。probe 不得以
`sq_empty` 或 `drain_inflight` 为 gate；有未清 store 但 CAM 仍判定 allow 的动态事件正是需要
保留的目标样本。

下一拍 `S_SQ_QUERY` 的实际结果只能叫 delayed/post proxy：store fill、commit、drain/free 可能在
中间边沿改变 SQ 状态，不能据此声称同拍可融合。本 task-run 不接受这种替代。

## 只读 probe 契约

- probe event 必须恰好是 `state_q == S_IDLE && stage_advance_w` 且 station load 落在现有 final-PA
  cached safe domain；按 admission event 计数，不按 station 驻留周期重复计数。
- probe 复用现有 SQ query payload/CAM，只在 `CONFIG_NPC_OOO_STATS` 下有效；非 stats build 的
  query 与 functional RTL 行为逐位不变。
- backend 必须把 station source 与 current MIQ head 做完整 owner kind/token/epoch、tracker producer
  identity、effective-kill 与 LQ-open exact 检查；ROB-head 子集使用完整 producer ID，不只比较可
  wrap/reuse 的 ROB index。
- probe 判决不得驱动 bridge state、cache lookup、response、retry credit、MIQ pop、LQ/SQ/ROB
  update、holder capture 或任何 architectural/transport side effect。
- 既有 F4 retiring-current/next-head station lookahead 的 identity、lookup 与 LQ update 语义不得改变。

## Counter schema

独立输出 schema：`npc-rv64-sq-idle-fusion-qualification-v1`。bank0/bank1 先各自产生 event bit，
host 逐 lane 相加；禁止用 OR 合并同拍双 lane event。

- `prequal`：安全域成立且 IDLE 本拍接纳；
- `exact`：probe 与 current MIQ head、owner tracker 和开放 LQ entry 完整匹配；
- `allow`、`forward`、`replay`：`exact` 且 SQ decision 严格 one-hot 的互斥分类；
- `invalid`：`exact` 但 decision 不是严格 one-hot；
- `allow_rob_head`：`allow` 且 current head 的完整 producer ID 等于 launch-open ROB head。

必须满足：

```text
exact == allow + forward + replay + invalid
prequal >= exact
allow_rob_head <= allow
identity_or_lq_reject == prequal - exact
```

ROI 与 whole-run 分别打印 `SQ_IDLE_FUSION_REGION`、`SQ_IDLE_FUSION_FINAL`；保留现有
`npc-rv64-performance-counter-v4` 不变。

ROI snapshot 与现有 `step_cycle()`/boundary 顺序一致，start=`S`、end=`E` 的 counter delta
覆盖 `(S,E]`；这是逐 cycle event，不做 retire-lane suffix 修正。

## Acceptance criteria

1. Bridge focused TB 在 stats build 中证明 probe payload 为 station 的最终 PA/owner，且
   allow/forward/replay 三臂非真空；probe 拍不发 lookup、不提前转状态，下一拍仍走当前
   `S_SQ_QUERY`。store/probe/noncached/DTLB miss/fault/line-cross/identity mismatch 均不 probe。
2. Backend focused TB 证明 station-current query 可 exact 并由真实 StoreQueue 产生
   allow/forward/replay；`retry_ready=0`，且 retry capture、MIQ pop、LQ/ROB/holder update 均为零。
3. Host counter 单测覆盖双 lane 同拍计数、ROI snapshot delta、underflow/overflow/malformed 与三条
   守恒关系；现有 performance-counter-v4 parser/test 不回退。
4. `CONFIG_NPC_OOO_STATS=y` 的冻结全核 smoke 保持 GOOD TRAP、DiffTest、retired/commits 与 probe
   前 candidate 完全一致；新 schema `available=1`、`overflow=0`、`malformed=0`、`conservation=1`。
5. 至少一个冻结 workload 的 `prequal>0`、`exact>0`、`allow>0`；若 `allow=0`，本 task-run 仍可
   作为有效反证关闭候选，但不得继续实现 fusion。

## 声明边界

本阶段只资格化动态机会与无副作用观测链。它不建立 CPI 改善，不构成 synthesis/STA/area/power
证据，也不允许宣称 SQ fusion 已实现。固定为 `PPA=UNQUALIFIED`、`promotion_eligible=false`。
