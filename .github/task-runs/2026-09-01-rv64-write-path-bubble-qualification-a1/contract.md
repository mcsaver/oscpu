# RV64 写路径固定空拍 stats-only 资格化契约

## 目标与冻结源码

本轮只测量 retained `sq-current-head-allow-lookup-fusion-v1` 源码上仍未修改的三个写路径边界：

1. `OooDualMemAxiArbiter` 处于 `S_IDLE` 时的写选择拍；
2. `AxiCrossbar` target 空闲时对完整 held AW/W pair 的 grant 拍；
3. `AxiCrossbar` 同拍接收完整 live AW/W pair 的入口。

冻结 production design identity 为
`sha256:78108874864cbfe2bb9a9c9753e3e7ae6dcf8f865aeb0d891c6cf4a566bb6cec`
（155 个 production RTL 文件）。诊断探针必须是外部 bind/build extension，不得修改 production RTL
或功能接口。

## 机会定义

### A. Arbiter IDLE 写选择

只在 arbiter 精确处于 `S_IDLE`、既有 fail-closed classifier 给出
`capture_valid && capture_write` 且选中 lane 已知时开始计数。分别统计：

- 选中 source 的 AW/W VALID 四象限（`11/10/01/00`）；
- downstream adapter 的 AW/W READY 四象限（`11/10/01/00`）；
- lane0/lane1 winner 与双 lane contention；
- source 完整 pair 且 READY=`11`，即严格的一拍 fall-through 机会。

read selection、非法 read+write、reset 与非 winner lane 均不得进入该机会计数。

### B. Crossbar held-pair grant 当拍 target offer

既有 `wr_grant_valid_r` 每个有效 bit 精确计一次 grant，并绑定既有
`wr_grant_master_r` 与 target index。统计被选 target 的 AW/W READY 四象限（`11/10/01/00`）、
同拍 target BVALID、cycle/event 数、各 master/target 分布，以及该拍 ROB head 是否归因为 AXI
write response。

严格 direct-offer 机会定义为 grant 且 READY=`11`、BVALID=0。partial READY 只保留为独立事实；
没有功能 A/B 前不得把它解释成完整一拍收益。

### C. Crossbar live 完整 pair direct-active capture

统计当前 master-facing 接口上同一 master 的 AW 与 W 同拍 fire，再按 decoded target active/inactive、
是否存在更老的 held complete pair、同 target contention 分桶。本轮只是机会 census，不授权越过旧
holder 或改变 round-robin 顺序。

## 计数与 fail-closed 要求

- 所有计数使用 predecessor CoreMark/Dhrystone 相同 PC ROI，cycle window 固定为
  `(start edge, end edge]`。
- `arbiter_events == sum(source_valid_matrix)`，同时等于 downstream READY matrix 与 lane winner
  之和。
- `xbar_grants == ready11 + ready10 + ready01 + ready00`，并等于 master 与 target bucket 总和；
  `grant_cycles <= xbar_grants`。
- state、owner、grant、decoded target、VALID、READY 或 BVALID 中任何 X/Z 都置 `invalid>0`；
  unknown 不得被静默分类为机会。
- 同一 master 同拍被 grant 到多个 target、grant 到已 active target，或同一 target 多 grant均非法。
- final marker 恰好出现一次，必须报告 complete=1、available=1、overflow=0、invalid=0，且全部
  conservation check 为真。

## Workload acceptance

诊断 build 使用 predecessor 完全相同的 CoreMark/Dhrystone 冻结镜像、ROI PC 与 runtime 参数。
两项都必须保持：

- GOOD TRAP、DiffTest ON、exit code 0；
- CoreMark ROI `cycles=4,785,064`、`retired=3,183,617`；
- Dhrystone ROI `cycles=8,481,505`、`retired=4,250,000`；
- predecessor checksum/功能输出与 SQ receipt 不变量。

探针必须 lint；parser 必须拒绝重复、截断、不守恒、unknown 或 malformed marker。focused synthetic
probe run 必须覆盖 READY 四象限和至少一个 invalid mutation。

## 裁决边界

本任务只授权测量，不授权功能 fall-through、store early completion、B suppression、owner reassignment
或任何 PPA 声明。候选选择还必须结合测得的事件分布与独立架构审查。mapped synthesis/STA/area/
power 继续固定为 `UNQUALIFIED`，`promotion_eligible=false`。

