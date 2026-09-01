# RV64 dual-memory arbiter IDLE write admission 本地候选契约

## 目标

实现 `dual-mem-arbiter-idle-write-admission-v1`：`OooDualMemAxiArbiter` 在 `S_IDLE` 已经合法选出
write winner时，当拍向 downstream lane adapter展示该 winner 的 AW/W，而不是先注册 owner再空等
一拍。read selection保持 registered。

本候选还包含一个语义等价的DAG闭合：从
`OooMemAxiBridge.write_irrevocably_presented_w`删除已被 registered write-state/VALID项严格吸收的
`aw_fire_w/w_fire_w`。stalled VALID、escaped-write、kill maintenance与B terminal authority均不得
改变；唯一目的与可观察效果是禁止 downstream READY经peer maintenance回到另一 lane ARVALID。

精确功能合同以
`npc/rv64/design/specs/ooo-dual-mem-arbiter-idle-write-admission.md` 为准。旧 F0 IDLE-quiet条款在
本候选 write-only eligibility内被新版本替代，其余 owner、fairness、stall、reset、response与
flush边界继续有效。

## Acceptance criteria

1. release与 `OOO_ASSERT` focused TB覆盖 source/READY矩阵、partial retry、poison、两 lane竞争、
   read registered、B backpressure、reset与 illegal negative，均非真空 PASS。
2. Verilator release/assert lint与 current full-core stats/non-stats lint PASS，不出现 `UNOPTFLAT`；
   full-top不得存在 `ARVALID -> arbiter -> WREADY -> maintenance -> peer cache -> ARVALID` 环。
3. dual-memory wrapper、adapter、memory bridge、xbar及 owner-timing直接相关回归 PASS；memory bridge
   还必须覆盖 killed A/D maintenance、mismatched-owner fail-closed、pre-write kill no-authority与
   selective A/D drain。
4. exact predecessor固定为 design ID
   `sha256:24849eb786b11715023bb3d512519a0e3bda4c61765686d3c180890e2977572a`：
   CoreMark ROI 4,667,639 / retired 3,183,617；Dhrystone ROI 7,891,545 / retired 4,250,000。
5. 两项 GOOD TRAP、DiffTest ON、code0、CRC/功能输出与 ROI retired保持；两项 ROI不得回归，至少
   一项严格改善；Dhrystone AXI write-request residency必须严格下降。
6. performance counter与 SQ receipt complete/available/conservation=1、overflow/invalid=0。

## 声明与回退

在 same-identity mapped synthesis/STA/area/power前固定 `PPA=UNQUALIFIED`、
`promotion_eligible=false`。CPI成功只允许保留为 local exploratory candidate；物理路径若不合格，
只回退本候选 write direct admission，不回退前驱 retained改动。
