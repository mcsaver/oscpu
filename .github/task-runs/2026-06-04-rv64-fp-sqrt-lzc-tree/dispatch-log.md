# 2026-06-04 RV64 FP Sqrt LZC Tree Dispatch Log

## Context

- 目标：继续按商业 ASIC RTL 风格收敛 RV64 `OooAluFetchCore`，本轮聚焦 FSQRT subnormal normalize 与 radicand 构造。
- 旧实现：`fp_sqrt_d_value` 与 `fp_sqrt_radicand_value` 的 double 路径用 52 次 procedural loop，single 路径用 23 次 procedural loop，每次检查 hidden bit、左移 significand 并递减 `exp_unbiased`。
- 约束：保持 `FSQRT.{S,D}` focused 行为、`OooFpSqrtIter` long-op 握手、pending FP long result latch、drain/commit 和写回边界；不新增状态机或握手。

## Derivation

- 需求：把功能仿真式逐 bit subnormal normalize loop 替换成宽度固定、层级明确、便于综合审查的 bounded LZC shift 数据通路。
- 协议规则：sqrt value/radicand helper 仍是纯组合函数，同周期给父级 long-op start/result path 使用。
- 状态机：无新增状态；父级 `pending_fp_long_pending_q/done_q/result_q` 和子级 `OooFpSqrtIter` start/busy/done/flush 协议不变。
- 不变量：旧循环只在 exponent 为 0 时运行，最多左移 52/23 次，直到 hidden bit 归位；因此新位移量必须为 `min(LZC(sig), 52)` 或 `min(LZC(sig), 23)`；非零 subnormal 的 normalized significand、`exp_unbiased` 扣减量、指数奇偶 radicand 选择、后续 `sqrt_exp`、root/remainder rounding 输入不变；zero/NaN/Inf/negative 特例仍由原外层分支处理。
- 数据通路约束：`fp_norm_shift_53/fp_norm_shift_24` 复用 `fp_lzc_64`，并按旧循环上界饱和；sqrt value 和 radicand helper 一次性左移 significand 并扣减指数。

## Implementation Notes

- 修改 `npc/rv64/vsrc/ooo/frontend/OooAluFetchCore.v`。
- 新增 `fp_norm_shift_53/fp_norm_shift_24` helper。
- `fp_sqrt_d_value` 删除局部 `integer norm_idx` 和 52 次 normalize loop。
- `fp_sqrt_s_value` 删除局部 `integer norm_idx` 和 23 次 normalize loop。
- `fp_sqrt_radicand_value` 删除 double/single 两个 normalize loop，改为 `norm_shift_d/norm_shift_s`。

## Verification

- 静态扫描 `for ((norm_idx|bit_idx))` 与局部 `integer norm_idx/bit_idx`：无残留。
- `make -C npc/rv64/testbench TESTS=tb_ooo_alu_fetch_core run`：PASS。
- `make -C npc/rv64 lint`：PASS。
- `make -C npc/rv64 -j2`：PASS。
- 新二进制 build time：`11:08:46, Jun 4 2026`。
- `make -C Linux/tools smoke-fp-sqrt smoke-fp-div smoke-fp-mul smoke-fp-addsub smoke-fp-convert`：全部 GOOD TRAP，分别为 `1039/94`、`946/100`、`287/89`、`266/86`、`192/65`。
- `git diff --check`：PASS。

## Boundaries

- 本轮只处理 FSQRT subnormal normalize/radicand procedural loop。
- Full fflags、dynamic rounding 全矩阵、高吞吐 FPU pipeline 和综合/STA/PPA signoff 仍未闭合。
