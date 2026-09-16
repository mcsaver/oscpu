# 规范：FP 算术门 OooFpArithGate

> wrapper：`vsrc/execute/OooFpArithGate.v`；production children：
> `OooFpAddSubPipe.v` / `OooFpMulProductPipe.v` / `OooFpMulNormRoundPipe.v` /
> `OooFpFmaAlignAddPipe.v` / `OooFpFmaNormRoundPipe.v`。历史流水化背景见
> `history/ooo-fp-arith-pipeline.md`；本文记录当前 RTL 事实与综合待办。

## 1. 目的与范围

`OooFpArithGate` 及五个 production children 负责 FP short arithmetic 的
FADD/FSUB、FMUL、FMADD/FMSUB/FNMADD/FNMSUB 数据通路，覆盖单精度
NaN-boxed 与双精度路径，输出 value 与 fflags。wrapper 只拥有事务
meta/kill/owner 与浅路径对齐；children 独占数值 stage Q。它们不负责 FP class/compare/sgnj/convert，
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

### 2.1 Production-child 端口冻结

children 无 `valid/ready` handshake，每拍无条件采样/推进数值。`launch_valid_i`、
ProducerId/pdest/kind/double meta、ROB-age kill 和 writeback/commit 均只属于 wrapper/
backend；children 不能创建第二份 transaction valid 或 commit owner。

| Child | 输入方向/边界 | 输出方向/边界 | 时序所有权 |
| --- | --- | --- | --- |
| `OooFpAddSubPipe` | `frs1/2,sub_op,rm` 组合输入 | double/single `{value,fflags}` S3 Q | AddSub S1/S2/S3 |
| `OooFpMulProductPipe` | `frs1/2,rm` 组合输入 | special/spval/spff/product/exp/sign/rm S1 Q | Mul S1 |
| `OooFpMulNormRoundPipe` | MulProduct S1 Q 直接驱动 S2 combinational | double/single `{value,fflags}` S3 Q | Mul S2/S3；module 边界不打拍 |
| `OooFpFmaAlignAddPipe` | `frs1/2/3,negate,subtract,rm` 组合输入 | full `mag[127:0]`/ref/sign/rm/special/spval/spff S3 Q | FMA S1/S2/S3 |
| `OooFpFmaNormRoundPipe` | FmaAlignAdd S3 Q 直接驱动 S4 combinational | double/single `{value,fflags}` S5 Q | FMA S4/S5；module 边界不打拍 |

helper 可见性也是接口的一部分：使用 predicate/round/shift/LZC 的 child 在自身
module lexical scope 内 include `OooFpPredicates.v` / `OooFpRound.v`；wrapper 不 include
这些 helper，也不拥有 short-arithmetic helper state。

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

该边界没有显式 FSM，没有 stall/backpressure。冻结的 stage/cycle 所有权如下：

| Resident stage | 数值 Q 唯一 owner | wrapper 事务状态 | 跨 child 边界 |
| --- | --- | --- | --- |
| S1 | AddSub S1；MulProduct S1；FmaAlignAdd S1 | `meta_*_q[1]` | 无 |
| S2 | AddSub S2；MulNormRound S2；FmaAlignAdd S2 | `meta_*_q[2]` | Mul S1 Q -> S2 comb，零额外寄存级 |
| S3 | AddSub S3 `{value,fflags}`；MulNormRound S3 `{value,fflags}`；FmaAlignAdd S3 full Q | `meta_*_q[3]` | 无 |
| S4 | FmaNormRound S4；wrapper AddSub/Mul `*_s4_result_q[68:0]` | `meta_*_q[4]` | FMA S3 Q -> S4 comb，零额外寄存级 |
| S5/out | FmaNormRound S5 `{value,fflags}`；wrapper AddSub/Mul `*_s5_result_q[68:0]` | `meta_*_q[5]` | resident `meta_kind_q[5]`/`meta_double_q[5]` 选择原子 bundle |

wrapper 状态：

- `latency_cnt`：旧 pending 接口计数器。`rst || flush_i || !start_i` 清 0；
  `start_i` 保持时递增到 5。
- `meta_valid_q[1:5]` / `meta_producer_id_q` / `meta_pdest_q` /
  `meta_double_q` / `meta_kind_q`：唯一 B-FP transaction owner；不得另存平行
  raw ROB identity。
- `addsub_s4/s5_result_q` / `mul_s4/s5_result_q`：每个都是 69-bit
  `{fflags,value}` 原子对齐状态。S4 捕获依据必须是 resident
  `meta_double_q[3]`，不是 current `double_i`。

同拍优先级：

1. wrapper 与五 children 皆以 `rst || flush_i` 清自身 Q；flush 无需 ready
   应答，且不创建 completion。
2. 否则 children 数值链恒推进，wrapper meta S1 接收
   `launch_valid_i && !younger(launch PID, kill, head)`。
3. wrapper 每级推进时对上拍 resident meta 做 ROB circular-age squash；
   `out_valid_o` 对 S5 resident meta 组合复核当前 kill，因而 S5 same-window kill
   不泄漏 completion。

FMA `mag[127:0]` 不得在 child 边界截断；`mag[0]` 保留
`fp_shift_right_jam_128` 的 jam，S4/S5 将完整尾部归约到 sticky，只在 S5
执行一次 fused rounding。

## 4. 不变量

- `done_o` 只能在 `start_i` 保持且 `latency_cnt==5` 时为 1；flush/reset 或父级撤 `start_i` 后清零。
- 旧 pending 模式下父级必须保持操作数与控制位稳定直到 `done_o`；否则结果不可定义。
- 自流水模式下 `out_valid_o` 必须蕴含 stage5 meta valid 且未被当前 kill 判年轻。
- `launch_kind_i` 只允许 0/1/2；其它编码在 `out_value_o/out_fflags_o` 默认走 addsub 分支，
  不应由合法 decode 产生。当前 `OOO_ASSERT` 已在 `launch_valid_i && launch_kind_i==3` 时 `$error`。
- FADD/FMUL/FMA 的 fflags 必须随 value 走同一流水级，避免 value 与异常标志错拍。
- Mul S1 Q -> S2 combinational 与 FMA S3 Q -> S4 combinational 边界不得增加
  寄存级；`launch -> out` 继续为 5 stages，throughput 为 1/cycle。
- child 不拥有 valid/ROB/kill/commit；wrapper 不拥有 AddSub/Mul/FMA S1-S5
  short-arithmetic numeric/fflags Q。

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

因此当前 blocker 不是读入/粗综合，也不是 AddSub 输出锥；Mul/FMA 内部
standalone 子段也不是单独不可综合。这些 probe 已转为上述五个 production
child 边界；本次不重跑综合/STA，新 `mapped-5ns-fp-arith-production-children-inline-v1`
只是 `development/UNMEASURED/GAP/noncanonical` 配置，不构成 PPA 收敛声明。

## 6. 验证计划

已用：

- `tb_ooo_fp_arith_gate`：覆盖精确 FADD/FSUB/FMUL/FMADD/FMSUB 单/双精度样例，
  NaN/Inf/subnormal/fflags 与 fused single-round cancellation oracle，并等待 `done_o` 后采样。
- `tb_ooo_fp_arith_gate`：覆盖 B-FP `launch/out` 自流水接口的连续三拍 addsub/mul/fma launch，
  检查 stage5 连续输出 meta（ROB/pdest）与 value/fflags；覆盖 younger-than-kill 的在飞 meta 清 valid、
  flush 清在飞 meta、逐拍 5-stage owner/out、same-cycle launch kill、resident S1-S5 kill，
  以及连续 mixed-precision/kind 的 resident double/kind 和原子 value/fflags 对齐。
- `run_ooo_fp_arith_child_mutations.py`：静态审计唯一 state owner/helper lexical scope/
  full-mag jam 与零拍边界；17 个负向版本必须编译成功，并由动态 TB marker 或
  结构 oracle 唯一拒绝。矩阵显式包含 Mul S4/S5 旁路错拍、wrapper 重获 helper
  lexical owner 与 full ProducerId generation-bit 损坏；wrapper、五 child、四个
  include、TB、checker、Makefile、filelist 与 runner 的 before/after hash 必须完全一致。
- current-identity module receipt：
  `.github/task-runs/2026-08-09-rv64-bpu-inline-ppa-d3f3-a1/evidence/fp-arith-functional-evidence-closure-v1/module-result.json`
  直接绑定 focused raw `tb_ooo_fp_arith_gate.log`、17-mutant evidence 与 functional
  input manifest 的 SHA-256。Registry 的 FP `module_test` observation 只接受
  `design_id=sha256:9d8bb6af...`、`status=PASS` 且 inventory 精确包含本 TB；历史
  full-module receipt 原文件保留但不再充当当前 FP module observation。
- `check-contract`：`OOO_ASSERT` 覆盖非法 `launch_kind_i=3`，契约断言基线 11 -> 12。
- 历史官方 FP 回归 / difftest / smoke：见 `history/ooo-fp-arith-pipeline.md`。

审核口径：

- `vsrc/common` 与 `vsrc/debug` 的作用之一是审核 RTL 是否符合 spec 语义。本文当前切片是单模块
  FP 算术流水接口验证；若后续修改 B-FP 与 backend/redirect/kill age 的跨模块语义，应先查/补
  common facts 与 debug checker，再把综合/时序优化结论写入证据包。

缺口：

- B-FP 自流水接口仍缺随机 back-to-back 混合单/双精度长压力；当前
  deterministic continuous mixed 已覆盖 resident double/kind/value/fflags，但不是随机穷举。
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
- internal standalone probes 已机械转为 filelist 内的五个 production children；算术表达式、
  寄存级数、backend 调用链和接口协议不变。
- 当前物理策略是 wrapper/五 child inline + keep hierarchy；只 blackbox
  两个 SRAM 与 BPU。此配置尚未测量，不是 canonical/champion。

接口/语义不可变量：

| Fact | Contract |
| --- | --- |
| pending latency | `5 cycles` |
| B-FP launch/out latency | `5 cycles` |
| launch throughput | `1 op/cycle` |
| flush/reset | clears latency counter, wrapper meta/alignment Q, and every child numeric Q |
| kill visibility | same-cycle launch gate plus pipeline meta squash; `out_valid_o` suppressed for younger-than-kill |
| value/fflags alignment | same pipeline stage; stage5 for B-FP output |
| valid launch kinds | `0/1/2` |
| production child status | RTL/TB evidence pending final gates; physical PPA remains GAP |

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
- [x] 产出并接入五个 production children，保持冻结 5-stage 语义。
- [ ] 若改 latency/边界，补 random B-FP mixed-precision pressure 与 common/debug checker。
- [ ] 接入真实 STA constraints 并消除顶层 unknown area/timing。

### 7.1 `ooc_sta_abstraction` composite 诊断边界

整核 `mapped-5ns-fp-arith-production-children-inline-v1` 已证明 134-source 与
inline/keep-hierarchy 输入接入，但 ABC 在 5400 秒窗口未完成，尚未证明 mapped
visibility。唯一下一实验改用
`mapped-5ns-fp-arith-production-children-ooc-boundary-v1`：

- `OooFpArithGate` 保持 inline；五 production child 各自用真实 stdcell OOC
  netlist 做 max/min 内部 STA，再以 `OOC_STA_ABSTRACTION` sequential Liberty 回接
  同一 `NpcTop` 5.0ns 图；两个 SRAM 与 BPU 仍是 unknown placeholder。
- 五个 production child 共用的 direct Yosys invocation 固定为
  `-q -Q -T -t -l <child-yosys.log>`：原生 `-t` 只增加每条 child 日志的
  wall-time 前缀，使 fresh run 能区分进入 `10.6.1` gate-netlist extraction 前后的
  耗时；top `YOSYS_ARGS="-q -Q -T"`、child synthesis `1800s`、child OpenSTA
  `600s`、`SYNTH_SHARE=0`、PDK/Tcl 与 RTL/design-id 均不由该日志切片改变。
- 每个 child 的 Registry `source_closure` 是身份域，继续绑定 `define.v`、使用的
  helper、child RTL 与 `filelist.mk`；`compile_sources` 是该闭包的精确 Verilog
  子集且必须包含 child RTL。runner 分别封存 `source-closure.sha256` 与
  `compile-sources.sha256`，child Yosys 只消费 `compile_sources`，不得把 Make
  metadata 当 Verilog，也不得在 runner 临时按后缀推导第二真源。
- shared Yosys 在 retained `synth-design.json` 前执行
  `splitnets -format __v -ports`；manifest 必须保留逐位 raw port、offset 与 bit
  identity，再由 Registry `input_ports/output_ports` 唯一重建 family-level canonical
  ports 和 raw-to-family/index 映射。split family 只接受 scalar、方向一致、canonical
  decimal index、连续 `0..width-1` 与 `offset=index`（index0 可省略 offset）；完整
  unsplit vector 也可接受，但 split/unsplit 混用、缺位、重复、越界或未知 family
  一律 fail closed。
- retained Yosys JSON 可同时携带完整 mapped top 与 stdlib module shells。manifest
  分类必须以绑定 stdlib whitelist 优先：同名 definition 只接受 exact Yosys
  canonical `blackbox=1` 且 `cells={}`，实例仍计为 `standard_cell_leaf`；缺失/false
  blackbox、非空 body、whitelist 缺项或 stdlib/RTL 同名碰撞一律拒绝。只有不在
  whitelist 且不是 blackbox shell 的 module 才可递归为 `hierarchical_rtl`。完整 A4
  `OooFpAddSubPipe` 证据口径是 7146 leaf instances，不能裁剪 module universe 或以
  单 leaf fixture 替代。完整 unsplit vector 的 `offset/upto/signed` 仅接受 absent/0，
  即 Registry 可证明的 zero-offset unsigned descending 表示。
- output timing 以 run-bound `output-bit-driver-contract.json` 为唯一分类真值：每个
  Registry output member 必须绑定 raw/OpenSTA object、net、唯一 mapped driver
  instance/cell/pin、bound stdlib output-pin `function` 及 synth-design、netlist
  manifest、whitelist、stdlib、run identity。只允许 `DYNAMIC`、`CONSTANT_0`、
  `CONSTANT_1` 完整互斥分区；不得由“OpenSTA 没找到路径”反推常量。A7 的
  `addsub_d_fflags_q_o[3]` 和 `addsub_s_fflags_q_o[3]` 共享 net 204，均由唯一
  `TIELOH7L.Z/function="0"` 结构证明；d-side 其余 `{0,1,2,4}` 是
  `DFFQX1H7L.Q` dynamic。
- Python→OpenSTA 的 Tcl 投影必须是严格 list-of-lists：共享 row encoder 只接受
  不含 brace/backslash 的非空安全 atom，并对每个 atom brace quote、再对整行增加
  一层 brace。child `output-bit-driver-contract.tcl` 每行固定 6 字段，行数等于
  Registry output width 总和（`OooFpAddSubPipe` 为 138）；top
  `fp_ooc_boundary_contract` 固定 5 行、每行 8 字段。扁平 atom 列表、缺/多字段、
  跨行合并、unsafe atom 或行数漂移必须在 OpenSTA query 前 fail closed。
- OpenSTA 对每个 `DYNAMIC` bit 必须观察真实 register-Q→exact output member
  PathEnd，并在下一 query 前物化 delay/slack/start/end；结构常量 bit 必须严格
  零 Q-path 且 timing 字段为 N/A。family summary 只从 dynamic members 派生，
  允许显式 all-constant family。Liberty 的 mixed vector 外层 bus 仅保留
  `bus_type/direction`：dynamic nested bit pin 只有独立抽象 state function 与
  rising-edge timing，constant
  nested bit pin 只有 literal `function : "0"/"1"`，严禁 bus-level timing/function
  继承或同一 member 同时携带 function 与 ordinary timing。绑定 stdlib 的 literal
  output pin 必须以结构化、注释/空白无关的 nested-group parser 检查：只接受零
  `timing` group，或 `tied_off : true` 且无 `related_pin`、`timing_type`、`when`、
  propagation/constraint table 的隔离 SI group；`timing()`、换行或注释变体不得绕过，
  也不得把合法 `tied_off` SI 数据误判为 register-Q timing。
- focused 量具必须在同一、固定 SHA 的 OpenSTA 3.1 进程中真正实例化生成后的
  `OooFpAddSubPipe` Liberty：用结构化 propagated-logic API 同时观察 nested DZ bit
  与其相连 top port 为 `0`，排除 `set_case_analysis/set_logic_*` seed；相邻 dynamic
  fflags bit 必须非 literal 且至少有一个 `Reg Clk to Q` edge/arc，constant bit 则
  不得有任何 non-wire incoming timing edge。该诊断不是形式等价或 signoff。
- 每个 child 必须观察 `port_to_register`、`register_to_port`、同步
  `rst/flush_i -> register`；除单级 `OooFpMulProductPipe` 明确 N/A 外还必须观察
  `register_to_register`。Liberty 对每个非 clock input 建 setup/hold、对每个 output
  建 clk-to-Q，不建 PI-to-PO、timing exception、异步 recovery/removal 或 power 模型。
- child OpenSTA 的 `exact_port_family` 只接受 Registry width=1 的 exact scalar，或
  width>1 时单一的 `family[N]`、`family__vN`、`family_N_` indexed style；regexp
  必须由 brace-quoted `format` 构造，避免 Tcl 把 `[0-9]` 当命令替换。每个 index
  必须是 canonical decimal、方向一致、唯一并连续覆盖 `0..width-1`；near-name、
  mixed-style、leading-zero、缺位、重复与越界即使 cardinality 偶合也必须拒绝。
- top 必须逐项观察冻结的五条 boundary class：AddSub S3→wrapper S4、MulProduct
  S1→MulNorm S2、MulNorm S3→wrapper S4、FmaAlign S3→FmaNorm S4、FmaNorm
  S5→`OooFpBackend` completion FIFO register-D。最后一条不能把
  `OooFpArithGate.out_value_o/out_fflags_o` 伪装成不存在的 `NpcTop` ports；真实 sink
  固定为 `u_core/u_ooo_core/u_execute_backend/u_core_slice/u_decode_backend/u_int_backend/u_fp_backend`
  下 `df_value_q` 512-bit family 与 `df_fflags_q` 40-bit family。零 negative slack 是合法 clean 结果；若 child 内有负
  slack，组合 result 必须保留为 `VIOLATED`，不能被 top clean 结果掩盖。
- top stdcell area 不含五 macro；composite area 只加每个 child OOC area 一次。
  child/macro 同时以 stdcell 重复实现、缺失/重复实例、零 cells/area、漏计/双计均拒绝。
- 即使 runner 完整 PASS，模型仍无 power/signoff characterization，状态固定为
  `DIAGNOSTIC_ONLY/GAP/noncanonical/nonchampion`；只允许后续一个全新 run-id 的
  fail-closed 实验，不能复用失败或半成品目录。
- 每个非 clock input（包含独立 `rst`、`flush_i`）与每个 output 都必须保留真实
  OpenSTA object name、max/min path-delay、delay/slack、object class 和声明/观察
  cardinality。setup=`max(0, 5.0-input_delay-worst_slack)`、
  hold=`max(0,input_delay-worst_slack)`、clk-to-Q=`max(0.001,worst_path_delay)`；
  inventory 指纹及公式一并进入 canonical Liberty，禁止用常数替代测量。
- child path-delay 测量只使用 `get_property $PathEnd points` 返回的同一组 `Path`
  对象及其 `get_property ... arrival`；这些 `PropertyValue` 已处于 UI 纳秒域，禁止
  再调用 `sta::time_sta_ui`，也禁止与 SWIG raw-second `Path arrival` 混算。input→D
  取末点 arrival 减首点 zero input seed；Q→output 在显式 0ns 上升沿、source/network
  latency=0、ideal unpropagated clock 下取末点累计 arrival，不能用末减首丢掉真实
  clk-to-Q。每个 PathEnd 同时闭合 constrained、min/max、check role、实际 query object
  集合，以及 startpoint/endpoint 与 points 首尾 pin 一致性。
- `find_timing_paths` 返回的 PathEnd 与 points 仅在下一次 Search query 前有效。
  `collect_arc_family` 必须在每个逐位 query 内完成验证并把 startpoint、endpoint、
  delay、slack 固化为普通 Tcl 值；全局 worst 选择不得跨 query 保存 PathEnd/points。
  composite parser 对 arc inventory 的 object family 与 Tcl `exact_port_family` 同构，
  严格接受 scalar、`family[N]`、`family__vN`、`family_N_` 单一 style 及 canonical
  `0..width-1`，从而直接接受 A6 mapped manifest 而拒绝 near-name、leading-zero、
  missing、duplicate、mixed-style 与 out-of-range。因为 Tcl family 来自 linked child
  顶层 `get_ports`，inventory 的 `PORT` object name 必须保留完整身份且不得包含 `/`
  owner；parser 禁止用 `rsplit` 丢弃层级后接受跨 owner replay。该限制只作用于 PORT
  family，真实 register-D/Q `startpoint/endpoint` 层次 pin 继续合法。
- register path 只能从实际 Q/output pin launch，D pin 只可作 endpoint。Yosys
  `check -mapped -assert` 与绑定 stdlib leaf whitelist 双门拒绝 `$*` generic 或未知 leaf。
  top 五条 boundary 使用 Registry 生成的精确 instance/pin family，并与实际
  OpenSTA pin/register-D 集合交叉；completion FIFO sink 还必须逐 pin 验证 input
  direction、实际 parent leaf cell、完整 backend owner hierarchy 与 512/40 cardinality。
  cleanup 前保留同一 mapped design JSON 派生的完整
  port/leaf-cell/instance manifest；最终状态统一封存在 evidence 内
  `gate-status.txt`。

## 8. 风险与回退

- 继续增加流水级会改变 FP latency；旧 pending 模式可通过 `done_o` 适配，但自流水接口的 stage5 约定需要同步更新 meta/对齐链与测试。
- FMA 数值路径很宽，功能修改风险高；应优先做不改数值语义的结构拆账、子模块边界和综合策略实验。
- 若采用 blackbox/macro 边界，只能作为综合定位或未实现宏边界，不得宣称完整 stdcell/STA-ready。

## 9. 变更记录

- 2026-08-11：A10 在 `OooFpMulProductPipe` child synthesis 的 `1800s` 边界返回
  `rc124`，旧日志最后只到 `10.6.1 Extracting gate netlist`，无 wall-time，不能区分
  extraction 前后耗时。production child direct Yosys 现唯一使用
  `-q -Q -T -t -l`；静态 oracle 锁定五 child、1800/600 秒预算、top 无 `-t`，并拒绝
  删除、重复、环境变量错放、top-only、预算漂移及次序漂移的 Bash-compile-success
  变异。本次未运行 production Yosys/OpenSTA/STA/RTL sim，A10 与 FP RTL 冻结，
  PPA 仍为 GAP；只有独立只读 review RETAIN 后才可授权全新 run-id。
- 2026-08-11：修正 A8 `OooFpAddSubPipe` 138-bit driver contract 的 Tcl row
  投影。旧 emitter 把每个字段分别 brace quote，却没有把整行再封为一个 outer-list
  element，导致 138×6 被 Tcl 扁平为 828 个元素；top 五条 boundary 存在同型
  5×8→40 静态反例。共享 nested-row encoder、实际 Tcl parser 正例/负向变异与
  Registry row-shape 合同现锁定 138×6/5×8；A8 与 FP RTL 冻结，未运行
  production Yosys/OpenSTA/STA，PPA 仍为 GAP。
- 2026-08-10：按独立 review 修正 arc inventory PORT owner 同构性。Python parser
  现对完整顶层 port name 做 fullmatch，并在 family coverage 前拒绝任何 slash owner；
  A6 underscore 0..63 与四种 canonical style 仍接受，跨 owner 连续索引、统一伪 owner
  与 slash scalar alias 均 fail closed。PathEnd 与层次化 register pin 语义不变，未运行
  production EDA，PPA 仍为 GAP。
- 2026-08-10：修正 production child arc collector 的 Search-owned PathEnd 生命周期，
  逐 bit 查询当拍固化 ordinary values；新增 bit0 为全局 worst、bit1 最后查询的真实
  2-bit OpenSTA harness。同时令 composite parser 镜像 Tcl 的 underscore port family
  严格语法并直接绑定 A6 manifest。本次不运行 production EDA，A6 与 FP RTL 冻结。
- 2026-08-10：修正 A6 child OpenSTA PathEnd arrival 测量。删除 PathEnd 不存在的
  `path_delay/delay/arrival` 属性探测，统一使用 points 中 Path 的 UI-ns arrival；
  input→D 与 Q→output 分别使用 zero-seed 差分和 zero-clock-origin 累计末点口径，
  由真实 DFFQX1H7L+BUFX1H7L OpenSTA harness 锁住单位域、check role 与 clk-to-Q
  保留。本次不运行 production Yosys/OpenSTA/STA，A6 冻结且 PPA 仍为 GAP。
- 2026-08-10：修正 A5 child OpenSTA port-family 解析。冻结 A5 AddSub retained
  manifest 的 `family_0_` split ports 作为真实正例；`exact_port_family` 现以
  Tcl-safe brace-quoted patterns 精确接受 scalar/bracket/`__v`/underscore 四种
  Registry 形态并闭合 index/direction/style，而非只比较 cardinality。本次不运行
  production Yosys/OpenSTA/STA，PPA 仍为 GAP。
- 2026-08-10：修正 retained manifest 对 stdlib blackbox definitions 的分类优先级。
  冻结 A4 完整 `synth-design.json` 中同名 stdlib shells 现按绑定 whitelist 识别为
  leaf，并严格验证 canonical blackbox/empty body；完整 7146 cells/census 与
  raw273→canonical11 直接闭合，不再使用裁剪后的单-leaf fixture。本次未运行
  production EDA，PPA 仍为 GAP。
- 2026-08-10：修正 A4 retained manifest 对 post-split ports 的解释。真实
  `OooFpAddSubPipe` 273 个 raw scalar ports 现按 Registry 11 个 family/273 bits
  精确 canonicalize，同时保留 raw 名称、bits、offset 和映射；A4 状态与
  `synth-design.json` 冻结不改，本次不运行 production EDA，PPA 仍为 GAP。
- 2026-08-10：修正 OOC composite child source domain：Registry 对五 child 显式
  区分含 `filelist.mk` 的身份 `source_closure` 与只含 Verilog 的
  `compile_sources`；runner 双 manifest 封存且 child Yosys 只消费后者。A3 首个
  AddSub 前端的 `ERROR: Unterminated preprocessor conditional!` 作为冻结反例保留，
  本次未运行 production EDA，PPA 仍为 GAP。
- 2026-08-10：修正 OOC composite 最后一条 top boundary：`out_value_o/out_fflags_o`
  是 `OooFpArithGate` 端口而非 `NpcTop` ports，真实路径经 `arith_out_value_w`/
  `arith_out_fflags_w` 和 completion arbitration 捕获到 `OooFpBackend` 八项 done FIFO
  的 `df_value_q`/`df_fflags_q` register-D。Registry、top Tcl、parser 与负向测试现按
  精确 linked hierarchy、parent leaf cell、方向和 512/40 cardinality fail closed；未运行 EDA。
- 2026-08-10：按独立 BLOCK 终审修复 OOC composite 七项确定性 blocker：真实逐端口
  arc 机械生成 Liberty、Q launch、rst/flush/全部 port family 独立覆盖、mapped leaf
  whitelist、精确 top object class、cleanup 后 retained manifest 与统一 gate-status。
  仍只验证工具，不运行 production EDA，PPA 保持 GAP。
- 2026-08-10：新增版本化 FP OOC composite 工具合同。Registry 单源区分 inline
  wrapper、五 known OOC child macro 与 SRAM/BPU unknown placeholder；parser、Tcl、
  runner、identity/area/timing receipts 共用 `fp-arith-ooc-composite-v1`。本次只实现并
  定向测试工具，不运行 production synthesis/OpenSTA，PPA 仍为 GAP。
- 2026-08-10：补 current-design functional evidence closure。最终 runner 对完整
  functional 15 路依赖做 before/after 哈希，直接封存 focused raw log，并把 mutation
  matrix 扩到 17 项（新增 Mul S4/S5、wrapper helper owner、ProducerId corruption）。
  FP module observation 改绑同身份 module result；旧 official/full dynamic evidence
  仍为 stale/GAP，物理配置继续 `development/UNMEASURED/GAP/noncanonical`。
- 2026-08-10：按 Architecture IR 将 short-arithmetic 数值流水机械拆成五个
  production children。wrapper 仅保留 legacy start/done、S1-S5 transaction meta/ROB-age
  kill/owner、AddSub/Mul 69-bit 原子对齐与 resident S5 mux。Mul S1 Q->S2 comb、
  FMA full S3 Q->S4 comb 不增加拍，`mag[0]` jam 与 fused single-round 保持。新物理
  config 只登记 `development/UNMEASURED/GAP/noncanonical`，本次不运行综合/STA。
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
