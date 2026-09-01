# RV64 AxiCrossbar live 完整写对资格化结果

资格化通过，授权下一项单变量功能实验 `axi-crossbar-live-pair-target-offer-v1`。

| workload | ROI cycles / retired | live complete pairs | target inactive / active | older holder | same-target conflict | narrow eligible | target READY 11 |
|---|---:|---:|---:|---:|---:|---:|---:|
| CoreMark | 4,570,581 / 3,183,617 | 144,201 | 144,201 / 0 | 0 | 0 | 144,201 | 144,201 |
| Dhrystone | 7,321,712 / 4,250,000 | 600,000 | 600,000 / 0 | 0 | 0 | 600,000 | 600,000 |

两项的 live pair 全部来自 crossbar master1、全部译码到 target11；arbiter/source/READY、held-grant
READY/master/target 与 live bucket 均精确守恒。probe complete=1、available=1、overflow=0、invalid=0，
GOOD TRAP、DiffTest ON、termination_rc=0，且 ROI cycles/retired 与 c50a predecessor 精确一致。

Dhrystone 的 `write_response=1,180,002 = 2 * 590,001`，同时 probe 观察到 590,001 个
ROB-head-visible write-response grant 事件；这证明当前常见 store 仍有 `live input -> holder/grant` 与
target registered B 两拍结构。新候选最多删除前一拍，不能消除 `AxiDpiSlave` 注册 B 的外部固定拍。

结构机会 ceiling 是 CoreMark 144,201、Dhrystone 600,000 local cycles，但端到端收益不允许直接
按事件数宣称；最终裁决必须使用功能实现后的 exact-predecessor CoreMark/Dhrystone A/B。

本结果没有 fresh mapped synthesis/STA/area/power。新增 forward cone 将从 bridge/arbiter/adapter
继续延伸到 crossbar target 输出，因此 PPA 保持 `UNQUALIFIED`、`promotion_eligible=false`。
