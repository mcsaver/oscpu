# 2026-06-04 RV64 FP Mul LZC Tree Dispatch Log

## Context

- 目标：继续按商业 ASIC RTL 风格收敛 RV64 `OooAluFetchCore`，本轮聚焦 FP multiply product normalize。
- 旧实现：double 路径用 105 次 procedural loop，single 路径用 47 次 procedural loop，每次检查 product 最高两位、左移一位并递减指数。
- 约束：保持 `FMUL.{S,D}` focused 行为、pending FP short compute latch、drain/commit 和写回边界；不新增状态机或握手。

## Derivation

- 需求：把功能仿真式逐 bit normalize loop 替换成宽度固定、层级明确、便于综合审查的 LZC + barrel-style shift 数据通路。
- 协议规则：`fp_mul_d_value` 与 `fp_mul_s_value` 仍是纯组合函数，同周期返回；上游 pending FP 只看到原 helper 的返回值。
- 状态机：无新增状态；父级 `pending_fp_q`、`pending_fp_compute_done_q`、long-op 状态和 drain-complete 规则不变。
- 不变量：旧循环在 `product_norm` 非零、product 最高两位均为 0、且 `exp_z>1` 时左移；因此新位移量必须为 `min(max(LZC(product_norm)-1, 0), exp_z-1)`；不得跨过 `exp_z==1` 的 subnormal 边界；NaN/Inf/zero、后续 subnormal 右移 jam、`product_norm[top]` 分支、guard/sticky 和 round increment 不变。
- 数据通路约束：`fp_lzc_128` 复用两个 `fp_lzc_64`，`fp_lzc_106/fp_lzc_48` 将 product MSB 对齐到 LZC helper；乘法路径一次性生成 `norm_shift`，再统一左移 `product_norm` 并扣减 `exp_z`。

## Implementation Notes

- 修改 `npc/rv64/vsrc/ooo/frontend/OooAluFetchCore.v`。
- 新增 `fp_lzc_128/fp_lzc_106/fp_lzc_48` helper。
- `fp_mul_d_value` 删除局部 `integer norm_idx` 和 105 次 normalize loop，改为 `norm_lzc/norm_required/norm_shift`。
- `fp_mul_s_value` 删除局部 `integer norm_idx` 和 47 次 normalize loop，改为 single 宽度的同构 `norm_lzc/norm_required/norm_shift`。

## Verification

- 静态扫描 `for (norm_idx = 0; norm_idx < 105/47)`：无目标残留。
- `make -C npc/rv64/testbench TESTS=tb_ooo_alu_fetch_core run`：PASS。
- `make -C npc/rv64 lint`：PASS。
- `make -C npc/rv64 -j2`：PASS。
- 新二进制 build time：`11:01:57, Jun 4 2026`。
- `make -C Linux/tools smoke-fp-mul smoke-fp-addsub smoke-fp-convert smoke-fp-div smoke-fp-sqrt`：全部 GOOD TRAP，分别为 `287/89`、`266/86`、`192/65`、`946/100`、`1039/94`。
- `git diff --check`：PASS。

## Boundaries

- 本轮只处理 FP multiply product normalizer 的 procedural loop。
- 剩余 FP sqrt/radicand normalizer loop、full fflags、dynamic rounding 全矩阵和综合/STA/PPA signoff 仍未闭合。
