# OooFpArithGate 多周期流水化(FP arith pipelining)

> ⚠ **部分细节待校正**：§4 表的 FADD 级数等流水细节与当前 RTL 注释有出入，以
> `../../vsrc/execute/OooFpArithGate.v` 为准。整个 FP 子系统将随 **B-FP**（FP 执行簇，见
> `../arch/ooo-core-architecture.md` §8.3/8.4）整体重写，届时本 spec 一并校正。

> 2026-06-29。把 FP 加减/乘/乘加(FADD/FSUB、FMUL、FMADD 系列)从单拍纯组合
> 改为内部多级流水,消除「FP arith 是真 Fmax 封顶」(known-issues [T1])。
> bit-exact 按构造保持(算术逐行不变,仅插流水寄存器);经金标 + difftest + smoke 验证。

## 1. 背景与目标

- **根因(known-issues [T1])**:`OooFpArithGate.v` 原为纯组合,时序 OOC 实测它是真正的
  Fmax 封顶:**FMA 173 级 / 36.5ns、FMUL 91 级、FADD 69 级**,全部远深于
  OooDispatchBackend(**39 级 / 7.95ns**)。即核真实 Fmax 受单周期 FP arith 限(~28MHz),
  不是 dispatch(~126MHz)。
- **目标**:把 FP arith 流水化,使其每级 logic levels ≤ dispatch(39),让 FP arith 不再是
  Fmax 封顶;数值结果 bit-exact 不变。

## 2. 关键架构前提:FP 执行完全串行

FP op 在 `OooPendingFpSequencer` 边界**完全串行**:一次只有一个 FP op 在飞,且发射前
backend 已 drain、核已 stop_pending。其直接推论(本设计的基石):

1. **操作数 `frsN` 在整个 pending 期间稳定**(div/sqrt 的结果装配在 N 拍后还读它们,已证)。
2. **无吞吐型流水需求**:op 一个一个来、之间全 drain,真流水(每拍收新 op)零收益。

故采用**「固定 FP_ARITH_LATENCY 拍多周期」**:数据通路内部切级 + done 计数器延后通知,
而非吞吐型流水。这比真流水简单得多(无冒险/旁路/反压逻辑)。

## 3. 控制机制(多周期 + 内部流水)

`OooFpArithGate` 由纯组合改为时序,新增端口 `clk/rst/flush_i/start_i` 与输出 `done_o`:

- `start_i` = `compute_start`(本 arith op 已 drain、操作数稳定),拉高启动流水、保持到父模块
  锁存 `compute_done`。
- 内部 `latency_cnt` 从 start 起逐拍计数,到 `FP_ARITH_LATENCY` 拍拉高 `done_o` 并保持;
  start 落下 / flush / rst 清零。
- 数据通路结果经各 op 的若干级寄存器打拍;**操作数稳定 → 每个 op 的流水输出在其自身深度即
  稳定并保持到第 LATENCY 拍**,故较浅的 op(FADD/FMUL)无需直通对齐,done 拍直接采样其末级
  寄存器即有效。

爆炸半径(4 文件,全在 execute 子系统内,drain-gate/control-plane/glue **无需改**——它们本就
等 `compute_done`):

| 文件 | 改动 |
| --- | --- |
| `execute/OooFpArithGate.v` | 纯组合 → 时序 + 内部多级流水(主体) |
| `execute/OooFpPendingExec.v` | 接 `clk/rst/flush/compute_start`,导出 `compute_ready_o`(= `!is_pipelined_arith \|\| arith_done`) |
| `execute/OooExecuteBackend.v` | 一根新内部线 `compute_ready` 连 gate→sequencer |
| `execute/OooPendingFpSequencer.v` | `compute_done` 锁存用 `compute_ready_i` 门控(延后 LATENCY 拍) |

非流水 compute(convert/compare/sgnj/class/move/minmax)`compute_ready` 恒 1,行为与原单拍一致。

## 4. 各 op 流水切级(算术逐行不变 → bit-exact)

统一延迟 **FP_ARITH_LATENCY = 5**(= 最深的 FMA;较浅 op 输出稳定保持到第 5 拍)。
double/single 两条独立流水(宽度/偏置/slice 不同),输出端 `double_i` mux。value 与 fflags
**合并**进同一流水(共享中间寄存器,去除原 value/fflags 双块的重复 datapath)。

| op | 级数 | 切级边界 |
| --- | --- | --- |
| **FADD/FSUB** | 3 | S1 译码+特殊值+对齐(shift-right-jam) → S2 同号加/异号减+规格化 LZC → S3 舍入+组装 |
| **FMUL** | 3 | S1 译码+特殊值+53×53 积(进 DSP) → S2 左规格化 → S3 subnormal 右移+舍入+组装 |
| **FMA** | 5 | S1 特殊值+积+指数基 → S2 LZC+宽度→ref_w→移位量 → S3 128b 对齐+128b 宽加→mag → S4 128b LZC+规格化+subnormal → S5 舍入+组装 |

关键设计点:
- **积进 DSP**:53×53 / 24×24 尾数乘法器在独立 S1 末打拍 → Vivado 映射 DSP48(MREG/PREG),
  该级 LUT 逻辑级数很浅。
- **指数算术窄化**:FMUL/FMA 的 `exp_z`/`e_biased` 等从 `integer`(32-bit)改为 `signed[13:0]`
  (值域 [-1021,3072] 远在内),把指数加减比较的 CARRY4 链长度减半 —— 这是把 FMUL 从 82 级
  压到 ≤ dispatch 的关键。FADD 的 exp_z 本就是 [10:0]/[7:0] 窄位宽,无需改。
- **subnormal 与 norm 解耦**:FMUL 的两个 106-bit barrel shift(左规 + subnormal 右移)串联是
  深锥,把 subnormal 右移从 S2 移到 S3,与左规分到两级。
- **round 与 norm 解耦**:FADD/FMUL/FMA 都把末级舍入(54b 进位加 + 组装比较)切到独立的最后一级。

## 5. 时序结果(模块 OOC,xc7a100t,周期约束 2.0ns)

| 阶段 | 最深 logic levels / logic delay | 说明 |
| --- | --- | --- |
| 原单拍组合 | FMA **173 / 36.5ns** | 真 Fmax 封顶(known-issues [T1]) |
| FMA 4 级 | 50 / 10.1ns | FMA S4(lzc+norm+subnorm+round)仍 > dispatch |
| FMUL 2 级(切错点) | 82 | 积进 DSP,norm/round 全堆一级 |
| FMUL 3 级 + exp 窄化 | 53 | norm 级仍 > dispatch |
| **最终(FADD3/FMUL3/FMA5)** | **31 / 6.32ns**(FMA S4 单精度) | **< dispatch 39 / 7.95ns** |

**结论**:FP arith 最深级 **31 级 / 6.3ns < dispatch 39 级 / 7.95ns**。FP arith 已**不再是 Fmax 封顶**;
核 Fmax 现由 dispatch(整数侧 rename/alloc/IQ 单拍链)封顶。从 173→31 级(5.6× 变浅),
从封顶项(36.5ns)降到 dispatch 之下(6.3ns)。

## 6. 验证(bit-exact)

- **模块 TB**:`tb_ooo_fp_arith_gate.sv` 改为时钟协议(等 `done_o` 再采样,与 LATENCY 解耦),PASS。
- **官方金标**:`rv64uf/ud-p-{fadd,fmadd,fdiv,fcvt,fmin,fclass,fcmp,move,recoding,ldst,structural}`
  共 **23/23 PASS**(含 fmadd = FMADD/FMSUB/FNMADD/FNMSUB 金标向量)。
- **difftest**:对 NEMU softfloat 逐指令(含 `fp-difftest-probe` 随机 FMA),见最终 eval。
- **FP 硬件 smoke**:`addsub/mul/fma/div/sqrt/dynrm/corner/...` **13/13 PASS**。
- **全 gate 回归**:见 `.github/task-runs/2026-06-29-npc-rv64-fp-arith-pipeline/`。

## 7. CPI 影响

FP arith 由 1 拍变 3~5 拍。FP 完全串行且稀少(AM 全 soft-float 不执行硬件 FP;只有 Linux
libm/libc 用),CPI 影响可忽略;换 ~5.6× 浅的 FP arith 关键路径(Fmax 不再受 FP 限)。
