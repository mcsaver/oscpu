# 规范：FP 算术门 OooFpArithGate

> 模块：`vsrc/execute/OooFpArithGate.v`。历史流水化背景见
> `history/ooo-fp-arith-pipeline.md`；本文记录当前 RTL 事实与综合待办。

## 1. 目的与范围

`OooFpArithGate` 负责 FP short arithmetic 的 FADD/FSUB、FMUL、FMADD/FMSUB/FNMADD/FNMSUB
数据通路，覆盖单精度 NaN-boxed 与双精度路径，输出 value 与 fflags。它不负责 FP class/compare/sgnj/convert，
不负责 FDIV/FSQRT 长延迟迭代，也不负责 pending FP 的 drain/精确提交策略。

当前模块同时保留两套接口：

- 旧 pending FP 串行接口：`start_i -> done_o`，父级在 backend drained 后发起一次 op，操作数全程稳定。
- B-FP 自流水接口：`launch_valid_i -> out_valid_o`，5 级 meta 链携带 ROB/pdest/kind/double，支持每拍 launch。

## 2. 接口契约

| 端口 | 方向 | 时序 | 含义 |
| --- | --- | --- | --- |
| `clk/rst/flush_i` | in | 时序 | reset/flush 清 `latency_cnt`、meta 链和对齐链 |
| `start_i` | in | level | 旧 pending 接口的启动/保持信号；保持到 `done_o` 后父级撤销 |
| `done_o` | out | level | `start_i` 后第 `FP_ARITH_LATENCY=5` 拍拉高并保持 |
| `frs1/2/3_value_i` | in | sampled | 各流水级每拍采样；旧 pending 模式要求父级保持稳定 |
| `double_i/sub_op_i/negate_product_i/subtract_addend_i/rm_i` | in | sampled | 精度、操作与舍入模式 |
| `addsub/mul/fma_{value,fflags}_o` | out | registered | 旧 pending 接口按 op 选择末级结果 |
| `launch_valid_i` | in | pulse/stream | B-FP 自流水 launch，有效时 meta 进入 stage1 |
| `launch_producer_id_i/launch_pdest_i/launch_kind_i` | in | sampled | 自流水 meta；ProducerId 为唯一身份，kind: 0=addsub, 1=mul, 2=fma |
| `out_producer_id_o/out_rob_idx_o` | out | combinational from Q | full PID 与其低位 raw-index 投影 |
| `owner_valid_o/owner_producer_id_o` | out | Q-only observation | 五级 resident meta lease，供父层解码 live mask |
| `kill_valid_i/kill_rob_idx_i/rob_head_idx_i` | in | combinational-to-clock | age-squash 清 younger in-flight meta valid |
| `out_valid_o/out_*` | out | registered meta + mux | stage5 输出，自流水写回入口消费 |

旧 pending 时序：

```text
cycle:   T0   T1   T2   T3   T4   T5   T6
start_i  1    1    1    1    1    1    0
done_o   0    0    0    0    0    1    0
result   -- pipeline registers settle -- valid at done
```

B-FP 自流水时序：

```text
cycle:        T0   T1   T2   T3   T4   T5
launch_valid  1    n    n    n    n    n
meta stage     1    2    3    4    5   out
out_valid      0    0    0    0    0    1
```

## 3. 状态与时序模型

模块没有显式 FSM，主要状态为：

- `latency_cnt`：旧 pending 接口计数器。`rst || flush_i || !start_i` 清 0；`start_i` 保持时递增到 5。
- FADD/FSUB 双精度与单精度流水：当前 RTL 注释以当前实现为准，双/单路径独立，末级寄存 value+fflags。
- FMUL 双精度与单精度流水：乘积、规格化、subnormal/round 分级打拍。
- FMA 双精度与单精度流水：5 级路径，包含 product、128-bit 对齐/宽加、LZC/normalize、round/pack。
- `meta_valid_q[1:5]` / `meta_producer_id_q` / `meta_pdest_q` / `meta_double_q` / `meta_kind_q`：B-FP 自流水身份链；不得另存平行 raw ROB identity。
- `addsub_a*_q` / `mul_a*_q`：把较浅的 addsub/mul 结果对齐到统一 stage5。

同拍优先级：

1. `rst || flush_i` 清所有时序状态。
2. 否则 meta 链恒推进；stage1 接收 `launch_valid_i && !fp_meta_killed(launch_producer_id_i[ROB_INDEX_W-1:0])`。
3. 每级推进时对上一拍 meta 再做 age-squash，`out_valid_o` 对 stage5 meta 组合复核一次 kill。

## 4. 不变量

- `done_o` 只能在 `start_i` 保持且 `latency_cnt==5` 时为 1；flush/reset 或父级撤 `start_i` 后清零。
- 旧 pending 模式下父级必须保持操作数与控制位稳定直到 `done_o`；否则结果不可定义。
- 自流水模式下 `out_valid_o` 必须蕴含 stage5 meta valid 且未被当前 kill 判年轻。
- `launch_kind_i` 只允许 0/1/2；其它编码在 `out_value_o/out_fflags_o` 默认走 addsub 分支，
  不应由合法 decode 产生。当前 `OOO_ASSERT` 已在 `launch_valid_i && launch_kind_i==3` 时 `$error`。
- FADD/FMUL/FMA 的 fflags 必须随 value 走同一流水级，避免 value 与异常标志错拍。

目前这些不变量由 focused TB、`OOO_ASSERT`、riscv-tests 与 full-state difftest 分层覆盖。后续触碰
B-FP 自流水接口时应继续补独立断言或 checker，尤其是 `out_valid` kill、flush 清链、kind 合法性与
value/fflags 对齐。

## 5. 关键路径与综合考量

历史 FPGA/OOC 结论显示，FP arith 已从原单拍纯组合改为内部多级流水，避免单拍 173 级 FMA 组合锥。当前 Yosys/stdcell 拆账给出新边界：

- OOC coarse PASS，`synth_check` 0 problems。
- coarse 规模：`2138 cells`，含 `16 $macc_v2`、`127 $alu`、`797 $mux`、`191 $sdff`、`1 $sdffe`、`10 $shl`。
- OOC full stdcell 在 `1200s` 窗口内终止于 `ABC pass` 的 gate netlist extraction：
  `Extracting gate netlist of module \OooFpArithGate ... Terminated`。
- 2026-07-08 子路径 output cone probe 进一步拆账：
  - AddSub cone coarse PASS，full stdcell PASS，area `15782.760000`。
  - Mul cone coarse PASS（`4 $macc_v2`），full stdcell `600s` 内仍终止于 ABC gate netlist extraction。
  - FMA cone coarse PASS（`14 $macc_v2`、`35734 wire bits`），full stdcell `600s` 内仍终止于 ABC gate netlist extraction。
- 2026-07-08 Mul/FMA internal standalone cone probe 继续拆账：
  - `OooFpMulProductProbe` full PASS，ABC `19488` gates，area `41726.44`，delay `35.00`。
  - `OooFpMulNormRoundProbe` full PASS，ABC `5345` gates，area `9883.16`，delay `46.00`。
  - `OooFpFmaRefProbe` full PASS，ABC `3284` gates，area `6006.00`，delay `38.00`。
  - `OooFpFmaAlignAddProbe` full PASS，ABC `12001` gates，area `22277.92`，delay `48.00`。
  - `OooFpFmaNormRoundProbe` full PASS，ABC `5635` gates，area `11052.44`，delay `43.00`。

因此当前 blocker 不是读入/粗综合，也不是 AddSub 输出锥；Mul/FMA 内部 standalone 子段也不是单独不可综合。
剩余 full stdcell 长尾更像是完整 output cone 中 double/single 双路径、raw product、128-bit align/add、
normalize/round 与输出 mux 同时进入 ABC 后的累计映射成本。下一步应把 probe 结论转为正式模块/流水边界，
或定义明确 macro/iterative 边界，并用 common/debug 语义审核证据约束任何生产 RTL 拆分。

## 6. 验证计划

已用：

- `tb_ooo_fp_arith_gate`：覆盖若干精确 FADD/FSUB/FMUL/FMADD/FMSUB 单/双精度样例，等待 `done_o` 后采样。
- `tb_ooo_fp_arith_gate`：覆盖 B-FP `launch/out` 自流水接口的连续三拍 addsub/mul/fma launch，
  检查 stage5 连续输出 meta（ROB/pdest）与 value/fflags；覆盖 younger-than-kill 的在飞 meta 清 valid、
  flush 清在飞 meta、确定性单/双混合 back-to-back。
- `check-contract`：`OOO_ASSERT` 覆盖非法 `launch_kind_i=3`，契约断言基线 11 -> 12。
- 历史官方 FP 回归 / difftest / smoke：见 `history/ooo-fp-arith-pipeline.md`。

审核口径：

- `vsrc/common` 与 `vsrc/debug` 的作用之一是审核 RTL 是否符合 spec 语义。本文当前切片是单模块
  FP 算术流水接口验证；若后续修改 B-FP 与 backend/redirect/kill age 的跨模块语义，应先查/补
  common facts 与 debug checker，再把综合/时序优化结论写入证据包。

缺口：

- B-FP 自流水接口仍缺随机 back-to-back 混合单/双精度的更高覆盖；当前 deterministic mixed smoke
  已覆盖基础 double bit / value / fflags 对齐，但不是随机压力。
- OOC full stdcell 尚未闭合，不能作为 STA-ready 标准单元网表。
- addsub/mul/fma output cone probe 与 Mul/FMA internal standalone probe 已完成；AddSub 与所有内部 standalone
  子段 full 已过，但完整 Mul/FMA output cone 仍未闭合。后续重点不再是重复拆同一组内部 helper，而是正式
  降低完整 cone 累计压力，并补等价/回归/checker 证据。

## 7. Macro/OOC Contract v0

状态：ACTIVE decision placeholder。该合同只把当前综合/时序优化边界写成可审查假设，不等价于
Liberty/LEF 宏模型、完整 stdcell 网表或 STA-ready 结论。

当前 v0 决策：

- 生产语义边界仍是当前 `OooFpArithGate` RTL，`FP_ARITH_LATENCY=5`。
- `NpcTop` synthesis 可以把 `OooFpArithGate` 保留为 module-level blackbox/OOC 边界做结构 sanity，
  但报告必须标注 unknown area/timing，不能当作闭合 PPA。
- 当前 internal standalone probes 只作为后续生产拆分的证据，不是已接入 filelist 的生产子模块。
- 优先候选顺序：AddSub 维持当前 full-pass stdcell 候选；Mul product + norm/round 生产拆分；
  FMA align/add + norm/round 生产拆分；仅当 value/fflags/meta/kill/flush 等价证据齐全时，才考虑
  iterative 或硬宏 multiplier/FMA。

接口/语义不可变量：

| Fact | Contract |
| --- | --- |
| pending latency | `5 cycles` |
| B-FP launch/out latency | `5 cycles` |
| launch throughput | `1 op/cycle` |
| flush/reset | clears latency counter plus meta/data valid chain |
| kill visibility | same-cycle launch gate plus pipeline meta squash; `out_valid_o` suppressed for younger-than-kill |
| value/fflags alignment | same pipeline stage; stage5 for B-FP output |
| valid launch kinds | `0/1/2` |
| OOC evidence status | coarse PASS; full stdcell open |

综合证据口径：

| Evidence item | Status |
| --- | --- |
| OOC coarse | PASS; `2138 cells`, `16 $macc_v2`, `191 $sdff` |
| full module stdcell | open; `1200s` ABC gate netlist extraction timeout |
| AddSub cone | full PASS; area `15782.760000` |
| Mul/FMA output cones | coarse PASS; full timeout |
| internal standalone cones | all full PASS; Mul product `41726.44`, Mul norm/round `9883.16`, FMA ref `6006.00`, FMA align/add `22277.92`, FMA norm/round `11052.44` |

面积/时序占位：

- 本模块不是表类 macro 的 state-bit placeholder；它是算术流水/stdcell macro 候选。
- probe area/delay 只能作为 non-signoff split evidence，不是完整 module area/timing。
- 顶层 unknown area 保持 open，直到获得完整 module OOC timing report，或形成生产 child-boundary 集合并补齐顶层约束。

STA 接入前置条件：

- blackbox 报告必须列出 `5 cycles` latency、`1 op/cycle` launch throughput、kill/flush 假设、
  value/fflags/meta 等价口径以及 unknown area/timing。
- 若接入 stdcell OOC 网表，必须先有完整 module OOC synthesis/STA 证据，或有可审查的 child-boundary set。
- 任何 latency、流水级或生产子边界修改，都必须同步 focused/random TB，并用 `vsrc/common` facts 与
  `vsrc/debug` checker 审核 RTL 是否仍符合本 spec 语义。

任务清单：

- [x] 记录 focused TB、contract assert、OOC probe 证据。
- [x] 定义 module-level macro/OOC decision placeholder v0。
- [ ] 产出 production child split 或 full module OOC timing report。
- [ ] 若改 latency/边界，补 random B-FP mixed-precision pressure 与 common/debug checker。
- [ ] 接入真实 STA constraints 并消除顶层 unknown area/timing。

## 8. 风险与回退

- 继续增加流水级会改变 FP latency；旧 pending 模式可通过 `done_o` 适配，但自流水接口的 stage5 约定需要同步更新 meta/对齐链与测试。
- FMA 数值路径很宽，功能修改风险高；应优先做不改数值语义的结构拆账、子模块边界和综合策略实验。
- 若采用 blackbox/macro 边界，只能作为综合定位或未实现宏边界，不得宣称完整 stdcell/STA-ready。

## 9. 变更记录

- 2026-07-08：新增 Macro/OOC Contract v0。当前生产语义边界保持 `OooFpArithGate` 5-cycle RTL；
  module-level blackbox/OOC 仅作为 non-signoff 结构 sanity。internal standalone probes 转为生产拆分候选证据，
  真正关闭仍需要 full module OOC timing report 或 production child split + 顶层 STA 约束。
- 2026-07-08：完成 task-run-only Mul/FMA internal standalone cone OOC probe。5 个内部 probe 均 coarse/full
  PASS：Mul product area `41726.44`，Mul normalize/round area `9883.16`，FMA ref area `6006.00`，
  FMA align/add area `22277.92`，FMA normalize/round area `11052.44`。结论：Mul/FMA output cone timeout
  不是单个内部 helper 不可综合，而是完整宽 datapath/output mux 组合后的累计 ABC 成本。证据
  `.github/task-runs/2026-07-08-fp-arith-internal-cones/`。
- 2026-07-08：完成 task-run-only addsub/mul/fma output cone OOC probe。AddSub cone full stdcell PASS，
  area `15782.760000`；Mul/FMA cone coarse PASS，但 full 均在 `600s` 内终止于 ABC gate netlist extraction。
  该 probe 不进入生产 filelist，只用于 synthesis 长尾定位。证据 `.github/task-runs/2026-07-08-fp-arith-cone-ooc/`。
- 2026-07-08：`tb_ooo_fp_arith_gate` 继续补 B-FP 自流水正确性：flush 清在飞 meta、确定性单/双混合
  back-to-back；`OooFpArithGate` 新增 `OOO_ASSERT` 防非法 `launch_kind_i=3`，`check-contract` 基线
  11 -> 12。focused TB、`lint`、`check-rtl-style`、`check-contract`、`git diff --check` PASS。
  OOC coarse Yosys PASS，`synth_check` 0 problems，证明断言未进入综合路径。
  证据 `.github/task-runs/2026-07-08-fp-arith-flush-kind-guard/`。
- 2026-07-08：`tb_ooo_fp_arith_gate` 补 B-FP `launch/out` 自流水基础覆盖：连续三拍发射 addsub/mul/fma 并检查连续输出，另测 younger-than-kill meta 不得 `out_valid`。focused TB PASS，`lint`/`check-rtl-style`/`check-contract` PASS。证据 `.github/task-runs/2026-07-08-fp-arith-launch-out-tb/`。
- 2026-07-08：新增当前规范。Yosys OOC coarse PASS，full stdcell 在 1200s 内终止于 ABC gate netlist extraction；focused `tb_ooo_fp_arith_gate` PASS。证据 `.github/task-runs/2026-07-08-yosys-fp-arith-gate-ooc/`。
