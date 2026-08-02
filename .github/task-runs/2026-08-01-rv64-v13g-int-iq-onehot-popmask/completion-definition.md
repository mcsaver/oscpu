# V13G completion definition — OooIntIssueQueue onehot pop mask

- Parent：V13F current-source local baseline，design-id
  `sha256:29c0afe820a5ce58a1299da1faaefabce6f9038156f628e9f0f3ff3b6e23f483`。
- 状态：`DEVELOPMENT_CHECKPOINT_PASS`；局部与 full-core coarse 已完成，独立终审裁决为
  `APPROVED_DEVELOPMENT_CHECKPOINT`。

## 单机制与冻结合同

`OooIntIssueSelect8` 已产生 mutually-exclusive owner onehot。候选用
`issue*_onehot_w & {8{issue*_fire_w}}` 与 memory-pair `8'b0000_0011` 形成 8-bit remove mask，
让 packed compaction 直接按 entry bit 判定 pop；删除 binary index 编码后再逐项比较的回译。

以下全部冻结：selector eligibility/steering、issue valid/ready 与 payload ownership、最多双 pop、
packed-age 顺序、dispatch append、sticky wake、kill survivor、flush/reset 优先级、full ProducerId、
N+1 latency、Universal owner/memory-pair 合同及现有断言。`write_i` 与 payload copy 本轮不改。

## 分层验证与判定

1. `tb_ooo_int_issue_queue` 在 `OOO_ASSERT` 下跑 stimulus-owned V11F edge model 的
   `OOO_PRODUCER_GEN_W=1/4`，并在 production `GEN_W=4` 跑全量 TB；既有 directed oracle 必须覆盖
   issue0-only、issue1、双 pop、memory pair、stall、dispatch append、kill/wake，并且精确 PASS、
   无 RTL assertion marker。通用 TB 的 V8O 场景不支持 `GEN_W=1`，父/候选同配失败只记配置 GAP。
2. 同 V13F 配置运行 200 MHz `OooIntIssueQueue` coarse；结构检查必须 0 problems。若 generic
   cell/mux 明显恶化，可在 mapped 前停止并回滚。
3. 若 coarse 未拒绝，运行同 liberty、同 mapped flow 与 5 ns ideal-clock OpenSTA，比较
   `cells/area/sequential area/worst slack/top40 family`。只有 mapped area 不增且 worst slack 有
   可重复正收益时才允许进入 parent；否则 `DOMINATED_ROLLBACK`。
4. parent/full-core/power/system 只在局部候选晋级后运行；未运行项不得写 PASS。
5. 保留源码身份、stat/check/STA、精简日志与裁决；删除 `.vvp` 和精确 PPA runtime。

## 完成事实

- 功能：G1/G4 V11F edge model PASS；G4 全量 IQ TB PASS；dispatch/int-backend/alu-decode-backend
  3/3 PASS；RTL style PASS。
- local coarse：`4430→4385 cells`、`$eq 198→184`、`$logic_and 379→353`，`$mux/$pmux` 不变。
- local mapped：`34468→33284 cells`、area `75205.48→74917.64`、sequential area 不变；
  5 ns worst slack `+2.233862638→+2.406632185 ns`。
- full-core coarse：同 design/config 父基线 `51129→51084 cells`、wire bits
  `1690602→1690585`，局部结构 delta 精确传播；`synth_check=0`，候选 design-id 前后相同。
- full-core mapped/STA、qualified power、system transaction 未运行；当前结论仅为开发检查点。
- 四态 selector knownness、普通双 memory lane 的 downstream READY 原子耦合、完整 architecture
  cohort 仍为显式 GAP；本轮没有削弱断言或把这些未运行项写成 PASS。
- 独立审查记录见 `review-result.md`；所有合同内 WSL 命令停止后已归还 single-flight shell。
