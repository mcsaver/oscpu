# OooFpArithGate FMA fused — RTL 级电路拓扑(规范范例)

> 本文是 `.github/instructions/rtl-generation-workflow.instructions.md` "阶段 2e:写码前先出
> 拓扑、自审后再翻译成 RTL" 的**留痕与范例**。对象是 `vsrc/execute/OooFpArithGate.v` 中
> FP#2 修复落地的 fused multiply-add(FMADD/FMSUB/FNMADD/FNMSUB,单/双精度)纯组合数据通路。

## 0. 需求
- 计算 `±(a*b) ± c`,IEEE-754 binary64/binary32,**单次舍入**(fused),5 种舍入模式(rm,
  DYN 由父模块替换为 frm)。
- 输出 53/24-bit 结果 value(NaN-boxed for single)+ 5-bit fflags(NV/OF/UF/NX;FMA 无 DZ)。
- 纯组合,单拍出结果;由父模块 OooFpPendingExec 在下游打拍。

## 1. module 边界与接口协议
- 输入:`frs1/2/3_value_i`(64b 各)、`double_i`、`negate_product_i`、`subtract_addend_i`、`rm_i[2:0]`。
- 输出:`fma_value_o[63:0]`、`fma_fflags_o[4:0]`。
- 协议:**纯组合,无握手**;输入稳定即组合产出。

## 2. 所有状态寄存器
- **无**。本 gate 无任何时序状态(无 always @(posedge))。结果寄存在父模块的 FP 结果流水寄存器。

## 3. 主要组合逻辑块(always @(*) + assign)
- `always @(*) fma_double_datapath`:双精度全通路,算 `fma_d_value/fma_d_fflags`。
- `always @(*) fma_single_datapath`:单精度全通路(场宽/偏置/slice 按 single),算 `fma_s_value/fma_s_fflags`。
- `assign fma_value_o/fma_fflags_o`:输出 mux(见 §7)。
- 每个 always@* 块内部子阶段(组合,顺序即数据流):
  1. 特殊值译码(NaN/Inf/Zero × a/b/c,invalid: inf*0 / inf-inf)。
  2. 宽积:`product = sig_a * sig_b`(53×53→106b / 24×24→48b)。
  3. 指数/权重:`ep,ec` LSB 权重;`pw,cw` 经 lzc 求 MSB 权重;`ref_w = max(pw,cw)`。
  4. 对齐:`shift_p/shift_c = e* - ref_w + 126`;左移(较大)或 `fp_shift_right_jam_128`(较小,入 sticky)。
  5. 宽加/减:同号加、异号按大小相减(`mag`,128b)。
  6. 规格化:`fp_lzc_128(mag)` → 左移到 MSB@127;`e_biased = ref_w + 1024/128 - lzc`。
  7. 次正规右移(e_biased<1)+ 末级 guard/round/sticky 单舍入(`fp_round_increment`)。
  8. 组装 + 上溢饱和(`fp_overflow_d/s`)+ fflags(`fp_round_flags_d/s`)。

## 4. FSM 状态与转移
- **无 FSM**(单拍组合)。

## 5. pipeline stage 与 valid/ready
- **无**(组合 gate,不持 valid/ready;背压由父模块处理)。

## 6. flush/stall/kill/reset 优先级
- **无**(无状态,无需 reset/flush/kill)。

## 7. 资源复制 vs 共享
- 双精度 / 单精度通路**复制**(两个独立 always@* 块),便于各自定宽。
- **共享输出端口**:`assign fma_value_o = double_i ? fma_d_value : fma_s_value;`(fflags 同)
  —— 显式 mux,选择信号 `double_i`。
- 综合后两路的 53×53 / 24×24 乘法器与 128b 加法器可能被工具共享,但 RTL 层独立、可读。

## 8. 可能的 critical path
- `53×53 尾数乘法器 → addend 对齐 barrel shifter → 128b 宽加/减(进位链)
   → 128b LZC 优先编码器 → 规格化 barrel shifter → 末级舍入进位加法器`。
- FMA 是最长 FP 组合路径(乘+对齐+宽加+前导零+规格化+舍入串联)。若 FP 成为 Fmax 瓶颈,
  此通路应优先流水化(乘法段 / 对齐+加段 / 规格化+舍入段 分拍)。当前 Fmax 限制者是
  OooDispatchBackend(见 modules/npc.md),FP 未进关键路径,故保持单拍。

## 9. function vs 显式硬件划分
- **显式 always@***:整条 FMA 数据通路(§3),使乘法器/对齐/宽加/规格化/舍入结构可见。
- **允许 function(小型纯组合原语,iverilog 位选兼容)**:`fp_lzc_128/106/48`(优先编码器)、
  `fp_shift_right_jam_128`(barrel shifter+sticky)、`fp_round_increment`、`fp_round_flags_d/s`、
  `fp_overflow_d/s`、NaN/inf/zero 谓词。
- **关键字**:用 `always @(*)` 而非 SV `always_comb`——iverilog 12.0 对 always_comb 内变量
  常量位选静默错仿真(见 known-issues.md 2026-06-29)。

## 自审结论(翻译成 RTL 前)
- 端口/特殊值/对齐/规格化/舍入/次正规/上溢覆盖完整;product=0 不可折叠进主通路(ep 伪权重
  污染 ref,单列),c=0 可折叠(addend_field=0)。无状态故无 reset/flush 风险。共享仅输出 mux。
- **验证**:rv64uf/ud-p-fmadd 官方金标(结果+fflags)+ 4000 迭代随机有限操作数 difftest 对
  NEMU softfloat fused 逐指令 bit-exact + 全 gate 绿(112/271/57+smoke13,CPI 1.3386 不变)。
