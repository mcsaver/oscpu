# 规范：current-head SQ same-cycle qualification probe

> 状态：测量链实施中；仅 `CONFIG_NPC_OOO_STATS`，不实现 SQ-query bubble fusion。

## 1. 要回答的问题

`OooMemAxiBridge` 已把一项 load 放入 registered station 后，当前路径在 `S_IDLE` admission
边沿把它转成 active owner，再到下一拍 `S_SQ_QUERY` 才读取 StoreQueue。候选优化是：若在
station admission 同拍就能证明 SQ `allow`，让 D-cache lookup 与 station→active transfer 同边沿
发生，从而删除固定 query bubble。

在修改功能路径前必须先回答真实动态机会：

```text
bridge S_IDLE && stage_advance
  -> station final PA / owner tuple
  -> current MIQ-head + tracker + LQ-open exact
  -> real SQ CAM allow / forward / replay
```

下一拍 `S_SQ_QUERY` 的真实结果不等价于同拍结果：store fill、commit、drain 或 free 可在中间边沿
改变 CAM 内容。因此资格化使用同拍只读 probe，不用 delayed proxy。

这里的 `idle` 是 bridge `S_IDLE`，不是 SQ empty。有 older store 但 CAM 仍能判 `allow` 的样本是
优化机会的一部分，不能用 `sq_empty` 或 `drain_inflight` 过滤掉。

## 2. Probe source 与安全域

bridge SQ query 共有三种互斥 source：

1. active source：registered active owner 在 production `S_SQ_QUERY` 的真实查询；
2. station-next source：F4 current response hit 时对 next MIQ head 的 production lookahead；
3. stats-current source：本规范新增，只在 bridge `S_IDLE && stage_advance` 对 current MIQ head 查询。

stats-current 只在 `CONFIG_NPC_OOO_STATS` 下编译为真，并要求 station/current expected/tracker
identity、LOAD、最终 PA 已知、cached typed class、合法 normalized mask、非 line-cross、无 DTLB/
page/PMP/PMA fault、无 flush/barrier。它复用既有 query payload 与真实 SQ CAM，但不得并入
station-next 的 lookup fire 或 FSM selector。

非 stats build 中第三 source 固定为零；active 与 station-next 的 query、lookup、LQ update 与 retry
语义不变。

## 3. Backend identity 与无副作用边界

backend 必须把 station source 分成：

- production next：存在 exact current-response candidate，tuple 匹配 MIQ next head；
- stats current：不存在 current-response candidate，tuple 匹配 MIQ current head。

两类都继续经过 owner tracker live/kind/epoch、完整 producer→ROB、effective-kill 与 LQ-open 检查，
之后才允许真实 SQ CAM 分类。selected ROB/killed 只有 production-next 才选择 next entry。

SQ CAM 本身是组合只读。stats-current 明确禁止所有状态/transport side effect：

- `retry_ready=0`、无 retry capture、无 query-owned MIQ pop；
- LQ query valid/open 保留用于 exact，但 `query_update=0`；
- 不发 D-cache lookup、AXI、response、drop 或 maintenance；
- 不选择 bridge forward/allow/replay 的 production state transition；
- 不改 SQ、ROB、WB、owner tracker、station/active holder。

不能把所有 station-source LQ update 都关掉：production station-next 已用它预记录下一 load 的
PA/class/strb/ordered，这是既有 F4 行为。

## 4. Counter schema

schema 为 `npc-rv64-sq-idle-fusion-qualification-v1`。每 lane 每个 admission event 形成：

- `prequal`：stats-current safe-domain probe；
- `exact`：current MIQ/tracker/LQ-open 完整 exact；
- `allow`、`forward`、`replay`：exact 且 decision 严格 X-safe one-hot；
- `invalid`：exact 但 decision 不是严格 one-hot；
- `allow_rob_head`：allow 且 launch-open ROB head 的完整 producer ID 相同。

两 lane 以 field-major 2-bit pair 打包进 OOO stats DPI mask；host 对 pair 做 popcount，`2'b11`
必须累加 2，禁止 OR 少算。bits `[13:0]` 依次为 prequal、exact、allow、forward、replay、invalid、
allow_rob_head 的 `{lane1,lane0}`，`[31:14]` 保留且必须为零。

守恒：

```text
exact == allow + forward + replay + invalid
prequal >= exact
identity_or_lq_reject == prequal - exact
allow_rob_head <= allow
```

输出独立 `SQ_IDLE_FUSION_REGION` 与 `SQ_IDLE_FUSION_FINAL` marker；现有
`npc-rv64-performance-counter-v4` 不增字段、不改 schema。ROI cycle snapshot delta 覆盖 `(S,E]`，
不使用 retire-lane endpoint 修正。

## 5. 验证与决策规则

- bridge focused：allow/forward/replay 三臂的 probe/payload 非真空，但 lookup/action 恒静默，
  transfer 后仍进入既有 `S_SQ_QUERY`；所有安全域反例不 probe；
- backend focused：真实 SQ allow/forward/replay，stats-current exact，LQ update/retry capture/MIQ pop
  为零；production-next regression 保持；
- host/parser：双 lane 同拍、reserved/malformed、overflow/underflow、ROI delta、守恒与
  region≤final；
- frozen full-core：GOOD TRAP、DiffTest、retired/commits 与 probe 前完全一致，新 schema 完整守恒。

只有 `allow>0` 且观测链无副作用时才进入功能 fusion 实现。`forward` 属于另一种“SQ 前递直返”
候选，不能混进 allow fusion；`replay` 明确不能跳过 query state。若 allow 为零，则本测量作为
有效反证关闭该候选。

## 6. 声明边界

probe 在 stats build 中会增加真实 SQ CAM 的组合翻转和 fanout；即便功能周期完全相同，也不能
声称 timing/power 零扰动。非 stats build 第三 source编译为零。本阶段不建立 CPI、synthesis、
STA、area 或 power 结论，固定为 `PPA=UNQUALIFIED`、`promotion_eligible=false`。
