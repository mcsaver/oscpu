# 2026-06-04 RV64 FP Sqrt LZC Tree Task Report

## Summary

本轮把 `OooAluFetchCore` 的 FSQRT subnormal normalize 与 radicand 构造从逐 bit procedural loop 改成 bounded LZC shift。外部 `FSQRT.{S,D}` 行为、`OooFpSqrtIter` 握手和 pending FP 状态边界不变。

## RTL 推导摘要

- 需求：保持 sqrt focused 行为，同时去掉 double 52 次、single 23 次 subnormal normalize loop。
- 协议：helper 仍是纯组合、同周期返回；不新增握手、流水拍或 backpressure。
- 状态机：无新增状态；父级 pending FP long-op 和子级 sqrt iterator 状态不变。
- 不变量：新 shift 必须等价旧循环的 `min(LZC(sig), 52/23)`；normalized significand、`exp_unbiased`、指数奇偶 radicand 选择和 root/remainder rounding 输入保持不变。
- 数据通路：新增 `fp_norm_shift_53/fp_norm_shift_24`，通过 `fp_lzc_64` 生成受旧循环上界限制的 normalize shift。

## Changed Files

- `npc/rv64/vsrc/ooo/frontend/OooAluFetchCore.v`
- `.github/memory/project-status.md`
- `.github/memory/modules/npc.md`
- `.github/memory/known-issues.md`

## Validation Evidence

- 目标 `norm_idx/bit_idx` 循环静态扫描无残留。
- `tb_ooo_alu_fetch_core`：PASS。
- Verilator lint：PASS。
- RV64 Verilator build：PASS。
- FP smoke：`sqrt/div/mul/addsub/convert` 全部 GOOD TRAP。
- `git diff --check`：PASS。

## Boundaries

- 本轮只处理 FSQRT subnormal normalize/radicand helper。
- Full fflags、dynamic rounding 全矩阵、高吞吐 FPU pipeline 和综合/STA/PPA signoff 仍未闭合。
