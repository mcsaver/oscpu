# FpAlu — 浮点算术单元

**文件**:`src/core/execute/FpAlu.hh` · **↔ npc**:`OooFpArithGate` / `OooFp*`(FP 数据通路)

## 职责
一个**全流水** FP 功能单元 + 长延迟 FDIV。计算用 host `double`(位型经 `std::bit_cast`),
与 `FunctionalBackend` **逐位同源**(含 nan/inf)→ difftest 护栏。属 `*Gate`(计算)+ 一个 `FunctionalUnit`(结构冒险)。

## 状态
- `fu_`:一个 `FunctionalUnit`(流水 II,`latency`/`width` 来自 `OooConfig.fp`)。
- `div_lat_`:FDIV 完成延迟(`OooConfig.fdiv_lat`,长于普通 FP)。

## 接口
- `can_issue(cycle)` / `reserve(cycle)` / `next_free()`:结构冒险仲裁(与 Alu/MulDiv 同构)。
- `latency(op)`:FDIV → `div_lat_`,其余 → `fu_.latency()`。
- `compute(op, a, b)`:`FADD/FMUL/FDIV`(`fbits(f64(a) ⊕ f64(b))`)、`FCVTIF`(int→double)、`FCVTFI`(double→int 截断)、`FCMP`(`f64(a)<f64(b)`)。

## 寄存器约定
物理寄存器统一 64-bit,承载 int 或 double 位型。`f0..f31 = 架构寄存器 32..63`(需 `num_arch_regs>=64`,`num_phys_regs>=128`);FP 与 int 共用 rename/PRF/IQ/ROB/LSQ 通路(IQ ready 类 5)。

## 不变量 / 行为
- golden 与详细核用同一 host-double 语义 → 结果逐位一致(不做软件 IEEE 模拟,靠宿主 FPU)。
- FDIV 长延迟通过完成事件 `when = cur + latency(FDIV)` 建模,不占额外 II 之外的发射带宽。

## 测试
`make run-fp`:demo(FADD/FMUL/FDIV/FCVT/FCMP 数值正确)+ fuzz 2 万程序 / 20.7 万 FP op 对拍金标准(regs+mem bit-exact)。
