# FP arithmetic synthesis-timeout physical-closure architecture v1

RV64 RTL 结论｜对象=NpcTop→OooFpBackend→OooFpArithGate/五 production child 与 traceable-9d8b-fp-arith-children-a1｜周期/配置=launch→out 5 cycles、1/cycle；mapped-5ns-fp-arith-production-children-inline-v1@5.0ns｜TB/EDA 观测=134-source/inline 接入成立；5400s 综合窗口结束时 yosys-abc 仍活跃，synth/OpenSTA/parser/binding 未完成；本审查未运行 EDA｜范围=GAP

## 裁决

保留当前五-child RTL 边界，阻止同 run-id 或仅延长时间的整核 inline 重跑。唯一下一实验是：在同一新 run-id 内，把五个 production child 分别用相同 icsprout55、5.0ns、Yosys/ABC 选项做真实 OOC 映射与 STA，生成绑定 mapped netlist 的顺序 Liberty；随后保持 OooFpArithGate wrapper inline，把五个 child 作为带真实面积与寄存边界时序的 macro 回接 NpcTop。

## 已证事实

- 顶层状态是 `FAIL rc=1 stage=evidence-complete evidence_complete=0 cleanup_rc=0`。
- `synth_rc=1`、`opensta_rc=1`、`parser_rc=1`、`binding_rc=2`；没有 `summary.json`、mapped netlist、`synth_stat.txt` 或 OpenSTA 产物。
- 进程快照只证明 5400s 总综合窗口结束时 `yosys-abc` 仍活跃，不能定位具体 child，也不能声称 ABC 自身运行了完整 5400s。
- `SYNTH_FLATTEN=0` 且 wrapper/五 child 已列入 keep hierarchy；当前 Yosys 仍只对完整设计调用一次 ABC，完成后才写 stat/netlist。因此再加 keep hierarchy 不是新实验。
- 134-source manifest、inline 参数和源码哈希只证明 read/elaboration 输入接入，不证明 mapped visibility。
- 当前 parser 要求 wrapper 和五 child 在同一整核 `synth_stat` 内各有唯一实例及非零 cells/area；OOC 路线必须改为逐-child内部收据与 NpcTop 边界收据的组合绑定。

## Architecture IR

```text
NpcTop/core
└─ OooFpBackend
   ├─ issue_fire && op_arith
   └─ OooFpArithGate                    wrapper owner
      ├─ meta/valid/PID/pdest/kind/double/kill S1-S5
      ├─ OooFpAddSubPipe                numeric S1-S3
      ├─ OooFpMulProductPipe            numeric S1 Q
      │  └─ OooFpMulNormRoundPipe       S1 Q→S2 comb，numeric S2-S3
      ├─ OooFpFmaAlignAddPipe           numeric S1-S3、full mag[127:0]
      │  └─ OooFpFmaNormRoundPipe       S3 Q→S4 comb、numeric S4-S5
      ├─ AddSub/Mul atomic {value,fflags} S4-S5
      └─ resident S5 kind/double mux
         └─ completion arbitration → authorized result → done FIFO → ROB/commit
```

```text
134 RTL sources + Registry projection
  → read/elaboration + blackbox/keep hierarchy
  → coarse/fine synth + dfflibmap
  → single hierarchical Yosys ABC
  × timeout
  → [未生成] synth_stat/netlist
  → [未运行] OpenSTA FP slack/internal paths
  → [未运行] parser
  → [FAIL] Registry binding
```

`OooFpFmaAlignAddPipe` 的并行 single/double 乘法、128-bit align/jam 与 add/sub，以及 `OooFpFmaNormRoundPipe` 的 128-bit LZC/shift-jam 是合理嫌疑，但不是已证 timeout owner。

## 路线裁决

| 路线 | 裁决 | 原因 |
|---|---|---|
| 延长整核 inline | BLOCK | 无模块进度 marker 或收敛证据，重复同一失败输入不能定位问题 |
| 逐 child 轮流 inline 到整核 | BLOCK | 仍进入同一个全设计 ABC，多次整核运行不能形成一次组合证据 |
| 五 child OOC netlist + 顺序 Liberty + wrapper inline | SELECT | 保留现有寄存级边界，可拆开复杂 cone，并恢复顶层 setup/clk-to-Q 时序 |
| 层次化 ABC | DEFER | 现有流程已保层次；真正可缓存的分模块 ABC 仍需 OOC 身份与收据 |
| 未测热点 RTL 重写 | BLOCK | timeout owner 未知，可能破坏 FMA jam、single-round、value/fflags 与五拍语义 |

## 唯一下一实验

新增非 canonical 配置 `mapped-5ns-fp-arith-production-children-ooc-boundary-v1`，仅允许一个全新 run-id：

1. 五个 child 分别以当前源码、`ics55_LLSC_H7CL_typ_tt_1p2_25_nldm.lib`、5.0ns 及相同 Yosys/ABC 选项 OOC 映射。每个必须产生 mapped netlist、`synth_check=0`、非零 cells/area、完整 endpoint slack inventory，以及至少一条包含真实 mapped cell 的内部路径。
2. 从同一 mapped netlist/corner 表征顺序 Liberty：输入只建立到 `clk` 的 setup/hold，输出只建立 `clk`→Q；`rst`/`flush_i` 按同步控制处理；禁止伪造跨多级 input→output combinational arc。
3. NpcTop 保持 `OooFpArithGate` inline，只把五 child 换成上述真实 macro；SRAM/BPU 继续现有 placeholder。顶层必须证明 wrapper/五 child 实例数、FP wrapper placeholder 消失、unknown 集合严格为一份 Sram4096x199、两份 Sram4096x113 与一份 OooBranchDirectionPredictor，并观察 MulProduct Q→MulNorm setup、FmaAlign Q→FmaNorm setup、AddSub/Mul→wrapper S4、FmaNorm→wrapper/backend 边界路径。
4. 每个 Liberty 必须绑定 child RTL、Predicates、Round、define、mapped netlist、std-lib、Yosys/ABC/OpenSTA、SDC、slew/load 表及生成器 SHA；任一漂移 fail closed。
5. 单 EDA 进程、`nice -n 10`；每 child synth 1800s、每 child STA/characterization 600s、NpcTop synth 5400s、NpcTop OpenSTA 1200s，总硬上限 18600s，runtime disk 上限 12GiB。
6. 只有五份 OOC、五份 Liberty、NpcTop synth/STA、parser、Registry binding、before/after manifest 和 cleanup 全部通过时才写 `[TRACEABLE-FP-OOC-COMPOSITE][PASS]`；首次失败封存，不复用 run-id。

## Registry 生命周期

- inline v1：`FAILED_INCOMPLETE/FAIL/ROLLBACK/GAP/noncanonical/nonchampion` 历史负结果。
- OOC v1 运行前：`development/UNMEASURED/GAP/noncanonical/nonchampion`。
- 完整成功后最多：`development/MEASURED_DIAGNOSTIC/GAP`。SRAM/BPU placeholder、IO constraints、power/LEF 未闭合，不能称 PPA PASS 或进入 Pareto front。
- 任一阶段失败：`FAILED_INCOMPLETE/GAP/ROLLBACK`。

## 反例与未知项

- 历史 AddSub/standalone cone 曾完成，反驳所有 FP child 单独都不可映射；旧 NpcTop placeholder baseline 完成，只证明工具链能工作，不证明 FP 是唯一根因。
- 当前 ABC 正处理的精确 module、节点规模、内存压力与收敛趋势未知；FMA child 在当前 production identity 和 icsprout55 下的真实 OOC 结果未知；顺序 Liberty characterization 尚未实现。
- 替代根因仍包括 FMA 宽移位/加法锥、Mul product、ABC DELAY/fraig/retime、其它 current-core module 与主机资源。
- 实现需新 implementation 合同，授权 OOC runner/Tcl、Liberty 生成/校验、组合 parser/schema、Registry 配置和新 evidence 目录。

## 身份与执行边界

- 合同 SHA-256：`62f604f1236db5bc67498bb04aa724877f25b9c4df38b22cd704343953d00c15`
- live design：`sha256:9d8bb6af7534717f6ed4b9f93b14f63aef407f5b2bc57feb43aef37ccbfbef5d`
- status SHA：`f923a8ae87f26025bdec54301bf96013c31c323228a3c04f266705cfb5a4fe5e`
- command-status SHA：`d569048290fb9d403f21c2568e55b18da9e4389d83101b84c3bc3da59d62bc37`
- synth log SHA：`c5dd8022e3a6c0b941eaf23a3be07c027c33ab4d50ee5e8ee2e2626598680545`
- source manifest SHA：`31461879c39a5190c6a59d9ba2073d92f5ebd4f3ddd45e0fe2f71ca532c3450d`
- 本节点写入、测试、仿真、综合、OpenSTA、STA 次数均为 0；限定 `git diff --check` 返回 0。
