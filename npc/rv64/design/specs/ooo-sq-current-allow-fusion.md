# 规范：SQ current-head same-cycle allow-only lookup fusion

> 状态：功能候选实施中；只融合 strict full-exact `allow`，不融合 `forward/replay`。

## 1. 动机与资格化依据

原路径把 registered station 中的 cached normal load 在 bridge `S_IDLE` 接纳为 active owner，进入
`S_SQ_QUERY` 后下一拍才读 StoreQueue，再启动 D-cache lookup。qualification v1 在 admission 同拍
观察真实 SQ CAM，且与功能前驱逐周期等价：

| workload | ROI cycles | exact current query | allow | allow / ROI cycle |
|---|---:|---:|---:|---:|
| CoreMark | 5,141,086 | 504,088 | 470,188 | 9.1457% |
| Dhrystone | 9,151,522 | 840,012 | 800,015 | 8.7419% |

allow 占 exact 的 93.27% / 95.24%，足以授权功能 A/B。事件数是理论 bubble 删除机会，不是端到端
周期收益保证；真实收益取决于 ROB 临界路径、cache miss 和其他并发延迟。

## 2. Source partition

bridge/backend 复用现有 station payload 与 owner face：

```text
active:
  !station_source
  + current MIQ head

station-current:
  station_source
  + !owner_query_valid
  + !current_response_exact_candidate
  + current MIQ head

station-next:
  station_source
  + owner_query_valid
  + current_response_exact_candidate
  + next MIQ head
```

`owner_query_valid` 源于 bridge edge-old FSM：`S_IDLE` 为 0，其余 active 状态为 1。它是 current 与
production-next 的强制互斥分割。malformed/stale current response 即使 tuple 偶然等于 current MIQ
head，也不能重新分类为 station-current。

station-current predicate 是 always-on production 逻辑；`CONFIG_NPC_OOO_STATS` 下的
`stats_current_head_sq_probe_w` 只是同一事件的观察别名。功能不能依赖 stats 宏。

## 3. Allow 原子边沿

station-current 保留 qualification 的完整安全域：bridge `S_IDLE` admission、station/current tracker
identity、LOAD、owner not killed、无 flush/barrier、最终 PA 已知、无 translation/page/PMP/PMA
fault、cached、非 line-cross、合法 normalized byte mask，并在 backend 继续经过 current MIQ tuple、
live owner tracker、完整 producer→ROB、effective kill 与 LQ-open exact。

若真实 SQ decision 严格 onehot allow，则 cycle N：

```text
station final PA / owner
  -> current full exact
  -> SQ CAM allow
  -> D-cache lookup enable + station req_cache_addr

posedge N:
  station -> active owner
  req_cache_addr -> paddr_q
  class/strb -> active Q
  LQ PA/class/strb/ordered update
  cache captures lookup
  state -> S_LOOKUP
```

cycle N+1 的同步 cache 结果由刚锁存的 active owner 与 `paddr_q` 消费。current allow 拍不得同时
产生 response、drop、AXI、maintenance、retry transfer/capture 或 MIQ pop。

组合 query 必须从 `idle_stage_advance_w` 起步。不得读取 `rsp_ready`，不得反向驱动 station ready/
stage advance，也不得把 current source接入包含 response-credit 的宽泛 `stage_advance_w` 锥；这样
保持 `station Q → backend combinational decision → lookup enable` 单向，避免重建组合环。

## 4. 非 allow 回退

current `forward/replay/invalid/inexact` 均不在 station 拍执行终端动作或写 LQ。上升沿仍按既有
station→active 传输并进入 `S_SQ_QUERY`，下一拍对最新 SQ 状态重新查询；中间边沿 store fill、
commit、drain/free 可以改变判决，因此禁止缓存或复用上一拍非 allow 结果。

retry credit/holder 仍只接受 registered active query。current source没有 retry credit，不能 capture
retry 或 pop MIQ。production-next 的既有 LQ update 不得被 current allow-only gate 误伤。

## 5. 恢复、双 bank 与 X 安全

- current fire 必须蕴含 source current、full exact、known strict onehot allow 与 safe domain；任何 X、
  多热或全零 decision fail closed。
- flush/MMU flush/full barrier、RMW busy、kill、identity mismatch、fault/noncached/line-cross 时 query/
  fire 为零；allow 后下一拍 flush 使用既有 `S_LOOKUP` drop/recovery，终端精确一次。
- bank0/bank1分别使用本 bank MIQ/tracker/LQ/SQ port。双 allow 可同拍更新；allow/replay 混合只允许
  allow bank lookup/update。same-ProducerId 双写仍为错误，不得削弱 LoadQueue 断言。
- production station-next 继续要求 active owner face + exact current response + next head；malformed
  production必须 replay且不得 current lookup/LQ update。

## 6. 验证与接受边界

focused 必须直接观察 lookup address/enable、边沿后 owner/paddr/state/cache pending、LQ payload/
ordered、fallback action quiet、malformed production、双 bank混合和至少一个 flush或miss continuation。
回归至少包括 SQ focused、V8S dual-memory、V9R retry、bridge、LoadQueue 和无 `UNOPTFLAT` lint。

冻结 CoreMark/Dhrystone A/B 需要保持 GOOD TRAP、DiffTest、retired/commits，两个 workload 均不回退且
至少一个改善。功能通过后也只能称 local retained candidate；真实组合锥的频率、面积和功耗仍需
mapped synthesis/STA/PPA 独立资格化。
