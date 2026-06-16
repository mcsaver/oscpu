# 2026-06-04 RV64 FP Addsub LZC Tree Dispatch Log

## Context

- 目标：继续按商业 ASIC RTL 风格收敛 RV64 `OooAluFetchCore`，本轮聚焦 FP add/sub 异号相减后的规格化路径。
- 旧实现：double 路径用 55 次 procedural loop，single 路径用 26 次 procedural loop，每次检查最高位、左移一位并递减指数。
- 约束：保持 `FADD/FSUB.{S,D}` focused 行为、pending FP short compute latch、drain/commit 和写回边界；不新增状态机或握手。

## Derivation

- 需求：把功能仿真式逐 bit normalize loop 替换成宽度固定、层级明确、便于综合审查的 LZC + barrel-style shift 数据通路。
- 协议规则：`fp_addsub_d_value` 与 `fp_addsub_s_value` 仍是纯组合函数，同周期返回；父级 pending FP 只看到原 helper 的返回值。
- 状态机：无新增状态；父级 `pending_fp_q`、`pending_fp_compute_done_q`、long-op 状态和 drain-complete 规则不变。
- 不变量：异号相减后 `sig_norm==0` 仍走 zero 结果；非零时旧循环等价于在 `sig_norm` 最高位未归位且 `exp_z>1` 时连续左移，因此新位移量必须为 `min(LZC(sig_norm), exp_z - 1)`；不得跨过 `exp_z==1` 的 subnormal 边界；同号加法 carry normalize、guard/sticky、round increment、NaN/Inf/zero 处理不变。
- 数据通路约束：`fp_lzc_64` 使用 64->32->16->8->4->2 leading-zero priority tree；`fp_lzc_56` 和 `fp_lzc_27` 将 significand MSB 对齐到 64-bit helper；减法路径一次性生成 `norm_shift`，再统一左移 `sig_norm` 并扣减 `exp_z`。

## Implementation Notes

- 修改 `npc/rv64/vsrc/ooo/frontend/OooAluFetchCore.v`。
- 新增 `fp_lzc_64/fp_lzc_56/fp_lzc_27` helper。
- `fp_addsub_d_value` 删除局部 `integer norm_idx` 和 55 次 normalize loop，改为 `norm_lzc/norm_shift/norm_exp_limit`。
- `fp_addsub_s_value` 删除局部 `integer norm_idx` 和 26 次 normalize loop，改为 single 宽度的同构 `norm_lzc/norm_shift/norm_exp_limit`。

## Verification

- 静态扫描 `for (norm_idx = 0; norm_idx < 55/26)`：无目标残留。
- `make -C npc/rv64/testbench TESTS=tb_ooo_alu_fetch_core run`：PASS。
- `make -C npc/rv64 lint`：PASS。
- `make -C npc/rv64 -j2`：PASS。
- 新二进制 build time：`10:53:04, Jun 4 2026`。
- `make -C Linux/tools smoke-fp-addsub smoke-fp-mul smoke-fp-convert`：全部 GOOD TRAP，分别为 `266/86`、`287/89`、`192/65`。
- `git diff --check`：PASS。

## Boundaries

- 本轮只处理 FP add/sub subtract normalizer 的 procedural loop。
- 剩余 FP mul/div/sqrt normalizer loop、full fflags、dynamic rounding 全矩阵和综合/STA/PPA signoff 仍未闭合。
