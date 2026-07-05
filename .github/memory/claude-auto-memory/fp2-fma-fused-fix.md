---
name: fp2-fma-fused-fix
description: "FP#2 fused multiply-add single-rounding fix landed in OooFpArithGate.v + how it was verified"
metadata: 
  node_type: memory
  type: project
  originSessionId: 0353a89c-6ba9-4a48-b7b5-b2e6baab6210
---

RV64 OoO 核 FP#2(FMA 双舍入)已修复(2026-06-29),`npc/rv64/vsrc/execute/OooFpArithGate.v`。

**问题:** 旧 `fp_fma_value` = round(round(a*b)+c),双舍入(最多 1 ULP 误差),违反 IEEE-754 FMA 单舍入。

**修复:** 真 fused 数据通路,两个显式 `always @(*)` 组合块(双/单精度)各算 {value,fflags},`double_i` 输出 mux。算法:精确宽积(106/48-bit)与 addend 在 128-bit 定点场 anchor-at-larger 对齐(较小操作数 shift-right-jam 入 sticky)→ 宽加/减 → 单次规格化(128b LZC)→ 单次舍入。场:bit b 权重 = ref-126+b;E_biased = ref+1024-lzc(double)/ref+128-lzc(single)。c=0 折叠进主通路(addend_field=0);product=0 单列(其 ep 伪权重会污染 ref)。新增 helper `fp_shift_right_jam_128`(OooFpRound.v)。

**验证(bit-exact):** ① rv64uf/ud-p-fmadd 官方金标(结果+fflags)② 4000 迭代随机有限操作数 difftest 对 NEMU softfloat fused 逐指令全匹配(经 `fp-difftest-probe.c` 扩展版临时压测,确认后还原提交版)③ module TB 112、riscv 271、AM 57、FP smoke 13 全绿,CPI 1.3386 不变。

**形态教训:** 先写成大 function 被规范否决,再写成 `always_comb` 被 iverilog 拒(见 [[verilog-not-systemverilog-for-synth]]),最终 `always @(*)` 显式组合块全绿。是遵循 [[rtl-coding-standard]] 的范例。难点是双舍入暴露概率低,必须靠 difftest 大样本而非官方 fmadd 测(后者改前也过)。

**时序代价发现(2026-06-29 OOC,见 known-issues [T1]):** fused 单舍入需宽数据通路(128b 对齐 barrel+128b LZC+规格化 barrel),实测 OooFpArithGate 组合路径 fused FMA=173 级/36.5ns,旧双舍入=152 级/32.67ns(+14%/+12%)。**更大发现:FP FMA 单周期(OooPendingFpSequencer:120-121)且 ~36ns,约 4× dispatch 的 39 级/7.95ns——FP FMA 才是核真正 Fmax 封顶**,此前因仅 OOC dispatch、FP 从未做时序 OOC、全核 P&R 不可行而被遗漏。fusion 时序代价 modest 且为正确性必需;真正高优先级时序优化=把 FP arith/FMA 流水化 2-3 级(设计级)。OooFpArithGate 纯组合无 clk,时序 OOC 须用 `set_max_delay -from all_inputs -to all_outputs` 而非 create_clock。
