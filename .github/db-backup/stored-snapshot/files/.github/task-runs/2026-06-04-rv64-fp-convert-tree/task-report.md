# 2026-06-04 RV64 FP Convert Tree Task Report

## Summary

本轮把 `OooAluFetchCore` 的 FP convert helper 中三处逐 bit procedural scan 改成固定组合树：最高置位查找使用分层 priority tree，舍入 sticky 使用 byte 级低位 OR 选择器。外部 FCVT 语义和 pending FP 状态边界不变。

## RTL 推导摘要

- 需求：保持 `FCVT.D.{W,WU,L,LU}` 与 `FCVT.{W,WU,L,LU}.D` 既有 focused 行为，同时去掉 convert helper 中的按位循环扫描。
- 协议：helper 仍是纯组合、同周期返回；不新增握手、流水拍或 backpressure。
- 状态机：无新增状态；父级 pending FP、short compute latch 和 long-op 状态不变。
- 不变量：MSB index 必须等价旧最高位扫描；sticky 只能覆盖 guard 以下被舍弃低位；饱和、NaN、Inf、符号、word/dword、signed/unsigned 和 rounding mode 规则不变。
- 数据通路：`fp_u64_msb_index` 为 64->32->16->8->4->2 优先树；`fp_u64_low_or` 为 byte OR + full-byte prefix mux + partial-byte mux。

## Changed Files

- `npc/rv64/vsrc/ooo/frontend/OooAluFetchCore.v`
- `.github/memory/project-status.md`
- `.github/memory/modules/npc.md`
- `.github/memory/known-issues.md`

## Validation Evidence

- 目标 `bit_idx` 循环静态扫描无残留。
- `tb_ooo_alu_fetch_core`：PASS。
- Verilator lint：PASS。
- RV64 Verilator build：PASS。
- FP smoke：`convert/fmv-fclass/fcsr/addsub/mul` 全部 GOOD TRAP。
- `git diff --check`：PASS。

## Boundaries

- 本轮只处理 FP convert 的 MSB/sticky 组合网络。
- 剩余 FP add/sub/mul/div/sqrt normalizer loop、full fflags、dynamic rounding 全矩阵和综合/STA/PPA signoff 仍未闭合。

