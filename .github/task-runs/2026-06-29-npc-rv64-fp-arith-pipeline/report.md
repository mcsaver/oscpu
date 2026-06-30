# Task-run: FP arith 流水化(rv64 OOO 核)

- **日期**: 2026-06-29
- **目标**: 把 `OooFpArithGate`(FADD/FSUB、FMUL、FMADD 系列)从单拍纯组合流水化,消除
  known-issues [T1]「FP arith 是真 Fmax 封顶」(FMA 173 级/36.5ns ≫ dispatch 39/7.95ns)。
- **用户决策**: 「三类算术一次到位」(FADD+FMUL+FMA 全部流水化)。
- **结论**: 完成。最深 FP arith 级 **31 级/6.32ns < dispatch 39/7.95ns**,FP arith 不再封顶。
  全 gate 绿,bit-exact。

## 调度(分相位,逐相位验证)

| 相位 | 内容 | 验证 |
| --- | --- | --- |
| Phase 0 | 多周期控制机制(gate 变时序 + compute_ready 门控),datapath 未动(latency-1) | module TB + golden 23 + smoke 13 + difftest 41,结果 bit-identical 仅延后 1 拍 |
| Phase 1 | FMA 4 级流水(切 decode+积 / 宽度 / 对齐+宽加 / lzc+norm+round) | golden fmadd + difftest 41(随机 FMA)+ smoke;OOC 173→50 级 |
| Phase 2 | FMUL/FADD 流水 + 迭代再平衡 | 见下 |
| Final | 全 gate + 模块 OOC + 记录 | 全绿 |

## Phase 2 迭代(OOC 数据驱动再平衡)

| 步骤 | 改动 | OOC 最深级 |
| --- | --- | --- |
| FMUL 2 级(切积后) | 积进 DSP,norm/round 全堆一级 | 82(FMUL S2,切错点) |
| FMUL 3 级 + exp `signed[13:0]` | 拆 round;窄化指数算术 | 53(FMUL S2 norm 仍深) |
| FMUL subnormal→S3 + FMA 4→5 级 | subnormal/norm 解耦;FMA S4 拆 lzc+norm / round | 55(FADD S2,唯一未拆) |
| FADD 2→3 级(round→S3) | 拆 round | **31(FMA S4)< dispatch** |

最终级数:**FADD 3、FMUL 3、FMA 5**,统一 `FP_ARITH_LATENCY=5`。

## 关键设计点

1. **FP 完全串行 + 操作数稳定** → 多周期(非吞吐流水);较浅 op 输出稳定保持到 done 拍,无需直通对齐。
2. **控制爆炸半径 4 文件**(drain-gate/control-plane/glue 不变,本就等 `compute_done`)。
3. **bit-exact 按构造**:算术逐行不变,仅插寄存器;value+fflags 合并去重。
4. **压到 ≤ dispatch 的招**:exp 标量 `integer→signed[13:0]`(CARRY4 减半)、subnormal/norm 分级、round/norm 解耦、积进 DSP。

## 证据

- 全 gate eval: `npc/rv64/eval/results/20260629-121008-fp-arith-pipeline-final/summary.md`
  —— module TB 112/112、riscv-tests 271、AM 57、difftest 41、FP smoke 13、CPI 1.3449。
- 模块 OOC: `npc/rv64/vivado/out/latest-mod/timing_paths.rpt`(最深 31 级/6.32ns)。
- spec: `npc/rv64/design/specs/ooo-fp-arith-pipeline.md`。
- 改动文件: `OooFpArithGate.v`(主体)、`OooFpPendingExec.v`、`OooExecuteBackend.v`、
  `OooPendingFpSequencer.v`、`tb_ooo_fp_arith_gate.sv`(时钟协议)、`tb_ooo_pending_fp_sequencer.sv`。

## 边界/残留

- CPI 1.3386→1.3449(+0.5%):FP 由 1 拍变 3-5 拍,集中在 `fp-difftest-probe` 合成 FP 压测
  (cpi 5.079);真实代码 FP 稀少(AM soft-float,只 Linux libm/libc 用 HW FP)故可忽略。
- 模块 OOC 是 logic-levels 代理(全核 P&R 在 16GB WSL 不可行);未做全核 STA。
- 本任务只声明 FP arith 流水化 + FP 不再封顶;dispatch(整数侧)流水化仍是下一时序大目标。
