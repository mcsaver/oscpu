# RV64 V13E OooLoadQueue onehot entry write

Status: `NEGATIVE_CANDIDATE_ROLLED_BACK` / mapped PPA dominated / promotion ineligible

## 对象与假设

- parent design-id：`29c0afe8…f483`
- parent `OooLoadQueue.v`：`5dc60f2f…c92f`
- candidate `OooLoadQueue.v`：`a29819b5…bfd8`
- 单机制：保留 V13B 两个 edge-old lowest-onehot grant，删除 onehot→binary index 编码以及动态
  array index 写回；以对应 onehot bit 直接限定每个 entry 的双 lane allocation 写入。
- 假设：减少 encoder/decode 与 `alloc*_ready` global reduction 回灌，可降低 entry D mux 成本。

## 周期与语义

- free bitmap、两个 grant、ready、lane1 prefix、flush mask、edge-old slot policy 全部不变。
- lane0 local fire 为 `onehot0[i] && alloc0_valid && !flush`；lane1 local fire 为
  `onehot1[i] && alloc0_valid && alloc1_valid && !flush`。第二 onehot 存在时已蕴含两个 ready，
  因而在二态网络及仿真 known-free overlay 中与 parent fire/index 写入逐周期等价。
- 两个 onehot 互斥，lane1 的 procedural NBA 顺序仍保持在 lane0 之后。
- 端口、参数、寄存状态、reset、full ProducerId、lifecycle、release/recovery/terminal 优先级和
  assertion 集未改变。

## 功能证据

- candidate `tb_ooo_load_queue` + `OOO_ASSERT`：PASS；包括 unknown-valid occupied、双 alloc 与
  existing lookup/release contract。
- stimulus-owned raw-Q：`GEN_W=1/4 × OOO_ASSERT on/off` 四档 PASS。
- rollback 后同一 focused assertion TB：PASS。
- mapped 早停后未运行真实 `tb_ooo_int_backend`、DI-5、RTL style、31×2 mutation、NpcTop coarse、
  full-core mapped/STA、power 或 system；这些项均为 `NOT_RUN`，不是 PASS。

## 局部 PPA A/B

配置：`OooLoadQueue`、200 MHz、flatten=1、share=0、Yosys 0.66+197、icsprout55、OpenSTA
3.1.0、5 ns ideal clock、zero I/O delay。baseline 直接复用 V13D 对同一 parent source hash 的冻结结果。

| metric | parent | candidate | delta |
| --- | ---: | ---: | ---: |
| coarse cells | 4,568 | 3,189 | -1,379 |
| coarse `$mux` | 1,790 | 528 | -1,262 |
| coarse wire bits | 41,922 | 28,557 | -13,365 |
| mapped cells | 18,979 | 19,888 | +909 |
| mapped area | 44,073.68 | 45,097.92 | +1,024.24 |
| sequential area | 9,264.64 | 9,264.64 | 0 |
| worst slack | +3.475173950 ns | +3.370205879 ns | -0.104968071 ns |

coarse IR 显著缩小，但 mapped 标准单元面积与最差 slack 同时退化。candidate worst path 从
`valid_q[0]` 经 allocator/reconvergent entry control 到 `ordered_q[11]`；因此 generic `$mux` 降低
不能作为该编码方式的 PPA 晋级依据。判定为 `DOMINATED_ROLLBACK`。

## 回退、清理与声明边界

- candidate RTL/spec 快照、focused/raw-Q 日志、coarse/mapped statistic/check、OpenSTA top-40/
  setup/console 与压缩 Yosys console已保留。
- live RTL/spec 已恢复 `5dc60f2f…c92f / e2d5f60d…6a6`；没有创建新的 production design-id，
  不为已回退候选触发系统重跑。
- 精确 runtime 目录中 `113,782,010` bytes / 15 个可再生网表与中间文件已删除；不可直接恢复，
  可由冻结源码、配置及工具版本重建。
- 本轮结论仅为 `diagnostic negative candidate`，不外推 full-core、power、system 或物理签核结论。

## 独立终审

- 结论：`APPROVED_NOT_PROMOTION_ELIGIBLE`；批准早停、证据留存和 production 回退，不批准候选晋级。
- 等价范围收紧为：grant 已知且为 `onehot0`、两 lane grant 互斥、edge-old/prefix gating 不变；
  不声明 multi-hot 或任意 X/Z 内部状态下的无条件四态等价。
- reviewer 未发现假绿或证据数值失配，并确认 mapped area/timing 同时被 parent 支配后继续运行
  parent/DI-5/NpcTop/power/system 不会改变本轮 rollback 决策。
