# RV64 SQ current-head allow-only 同拍 lookup：本地候选契约

## 目标

候选 `sq-current-head-allow-lookup-fusion-v1` 删除 cached normal load 从 bridge registered station
进入 active owner 后固定停留 `S_SQ_QUERY` 的一拍：当 bridge 仍在 `S_IDLE` 接纳 current MIQ head、
完整身份/LQ-open 检查成立且真实 StoreQueue CAM 严格判定 `allow` 时，同拍启动 D-cache lookup，
并在同一上升沿完成 station→active、最终 PA/属性锁存和 LQ ordered 更新，下一拍直接进入
`S_LOOKUP`。

资格化前驱 `sq-idle-fusion-qualification-a1` 已在冻结 CoreMark/Dhrystone 上证明：ROI 内 allow
分别为 470,188 / 800,015 次，且 stats-only 探针不改变 cycles、retired 或 commits。

## 精确生命周期

功能 query source 使用现有接口编码，不新增跨模块端口：

```text
active           = !station_source
station-current  = station_source && !owner_query_valid
station-next     = station_source && owner_query_valid && exact_current_response
```

`owner_query_valid` 是 current/next 的必要分割，禁止只凭 tuple 与 MIQ current/next head 相等来
推测 source。station-current 始终从 `idle_stage_advance_w` 起步，不能重新接入包含 response credit
的宽泛组合锥。

current 拍的结果严格分为：

- full-exact + strict onehot `allow`：只启动一次 D-cache lookup；同边沿锁存 active owner、最终 PA、
  cache class/strb，并更新对应 LQ entry 的 PA/class/strb/ordered；下一态 `S_LOOKUP`；
- `forward`、`replay`、invalid 或任何 inexact：本拍不 lookup、不 response、不 AXI、不 retry
  capture、不 MIQ pop、不 LQ update；只按原路径锁存 active owner并进入 `S_SQ_QUERY`，下一拍以
  当时 SQ 状态重新查询；
- flush、MMU flush、full-flush barrier、RMW busy、kill、identity mismatch、translation/fault、
  noncached、line-cross 或非法 mask：不得形成 current functional query/fire。

current allow 的 lookup、active owner/paddr 锁存与 LQ update 是一个原子边沿；lookup 地址必须是
station 的 `req_cache_addr_w`，不能使用尚未更新的 `paddr_q`。同步 SRAM 结果只能在下一拍由同一
active owner 与锁存后的 `paddr_q` 消费。

## 必须保持的既有行为

- production station-next 仍要求 owner face 有效、current response exact、next MIQ head exact 与
  `rsp_ready`；它的 lookup/LQ update/response fusion 不得回退。
- malformed production current response 必须 fail-closed replay，不能别名为 station-current。
- retry credit/holder capture 继续只属于 registered active `S_SQ_QUERY`；所有 station source 均无
  retry credit。
- MIQ pop 只来自真实 response terminal、合法 active retry transfer 或既有 drop terminal；current
  query/fire 本身不得 pop。
- current allow 之后若 flush/kill 到达，既有 `S_LOOKUP` recovery 必须精确 drop 一次，不能交付
  stale hit、发 speculative AR 或泄漏 owner/LQ。
- 双 bank 可同拍 independently allow；allow/replay 混合时只能更新并 lookup allow bank；禁止同一
  ProducerId 被两个 LQ query 同拍写入。
- `sq_empty` 与 `drain_inflight` 不是资格条件；真实 SQ CAM 判决始终是唯一 ordering authority。
- active SQ query、PTW/DTLB continuation、noncached/device、forward、replay、store、maintenance、
  response/backpressure 与 AXI owner 语义不变。

## Acceptance criteria

1. Bridge focused TB 非真空覆盖 current allow 同拍 lookup、station final PA、边沿后 `S_LOOKUP`、
   active owner/paddr/lookup pending；forward/replay/inexact 回落 `S_SQ_QUERY`；负向安全域和
   malformed production 均不 lookup。至少再覆盖 allow 后 flush 或 miss 生命周期之一。
2. Backend focused TB 覆盖双 bank current allow 的 LQ PA/class/strb/ordered 更新，同时证明 MIQ
   resident、retry credit/capture/pop 为零；current forward/replay 不更新；production-next update
   与 malformed production fail-closed 保持。至少覆盖一组双 bank allow/replay 混合。
3. `OOO_ASSERT` 锁定 source partition、strict exact onehot fire、allow-only side effect、原子 owner/
   paddr/LQ transfer、非 allow action-quiet、flush/RMW/kill 屏蔽与 production malformed contract。
4. `sq-idle-fusion-qualification-focused`、V8S dual-memory、V9R retry handoff、bridge full regression、
   LoadQueue 直接相关测试和 Verilator lint 全部通过；lint 不得出现 `UNOPTFLAT`。
5. 用资格化前驱的同一 stats config、同一冻结镜像、ROI 与 runtime 参数跑 CoreMark/Dhrystone A/B。
   两边都必须 GOOD TRAP、DiffTest ON、终止码 0，ROI retired 与 full commits 完全相同；任一
   workload 的 ROI cycles 不得回退，且至少一个 workload 必须严格改善。
6. SQ counter receipt 继续满足 complete/available/conservation=1、overflow/malformed/invalid=0；
   functional current allow fire 与 receipt 中 strict current allow 逐事件一致。性能收益不得被解释为
   allow 次数的机械一比一兑现。

## 声明边界

该候选把真实 `station owner/final PA → MIQ/tracker/LQ exact → SQ CAM allow → D-cache lookup enable`
组合锥带入功能路径。focused、lint 和 full-core CPI 不能替代 synthesis/STA/area/power；在完成当前
mapped PPA 前固定为 `PPA=UNQUALIFIED`、`promotion_eligible=false`。若功能或性能 acceptance
失败，只回退本候选的 current allow lookup/LQ update，不回退 qualification 计数链、adapter
fall-through 或其他已有优化。

## 首次 A/B 后的等价口径精化

原 acceptance 5 把 `full commits` 完全相同作为所有 workload 的无条件要求。CoreMark 首次 A/B
证明这个量在本 workload 上不是性能不变量：ROI 结束后程序读取 cycle-derived RTC，随后用该值
执行整数除法、分数计算和十进制格式化。优化使输出合法地从 `5141 ms / 5 Marks / 1.945` 变为
`4786 ms / 6 Marks / 2.089`，因此 ROI 后动态指令数减少 13；但 ROI start/end retired、ROI retired、
全部 CRC、iteration/seed、GOOD TRAP、DiffTest 与终止码均相同。

为避免用被优化目标本身派生的报告路径制造 false fail，acceptance 5 的等价权威精化为：

- ROI retired 与 start/end retired 必须完全相同；
- 不读取时间/周期的固定 workload，full commits 必须完全相同；
- ROI 后读取 RTC/cycle 并据此分支或格式化的 workload，允许已定位、仅发生于 ROI 后的 full-commit
  差异，但必须逐项保持算法 checksum/功能结果、GOOD TRAP、DiffTest、终止码与 ROI 边界身份；
- 任何差异必须在结果中明示，不能写成 full commits 相同。

这项精化不放宽 ROI correctness，也不允许用计时输出解释 ROI 内 retired、checksum、trap 或
DiffTest 的任何漂移。
