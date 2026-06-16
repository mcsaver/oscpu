# 2026-06-04 RV64 FP Addsub LZC Tree Task Report

## Summary

本轮把 `OooAluFetchCore` 的 FP add/sub 异号相减规格化路径从逐 bit procedural loop 改成 fixed LZC priority tree + 一次性左移/指数扣减。外部 `FADD/FSUB.{S,D}` 行为和 pending FP 状态边界不变。

## RTL 推导摘要

- 需求：保持 add/sub focused 行为，同时去掉 double 55 次、single 26 次逐 bit normalize loop。
- 协议：helper 仍是纯组合、同周期返回；不新增握手、流水拍或 backpressure。
- 状态机：无新增状态；父级 pending FP、short compute latch 和 long-op 状态不变。
- 不变量：新 `norm_shift` 必须等价旧循环的 `min(LZC(sig_norm), exp_z - 1)`；`exp_z==1` subnormal 边界、zero、NaN/Inf、同号加法 carry normalize 和 guard/sticky 舍入输入保持不变。
- 数据通路：新增 `fp_lzc_64` leading-zero tree，包装出 `fp_lzc_56/fp_lzc_27`，减法路径一次性完成 normalize shift。

## Changed Files

- `npc/rv64/vsrc/ooo/frontend/OooAluFetchCore.v`
- `.github/memory/project-status.md`
- `.github/memory/modules/npc.md`
- `.github/memory/known-issues.md`

## Validation Evidence

- 目标 `norm_idx < 55/26` 循环静态扫描无残留。
- `tb_ooo_alu_fetch_core`：PASS。
- Verilator lint：PASS。
- RV64 Verilator build：PASS。
- FP smoke：`addsub/mul/convert` 全部 GOOD TRAP。
- `git diff --check`：PASS。

## Boundaries

- 本轮只处理 FP add/sub subtract normalizer。
- 剩余 FP mul/div/sqrt normalizer loop、full fflags、dynamic rounding 全矩阵和综合/STA/PPA signoff 仍未闭合。
