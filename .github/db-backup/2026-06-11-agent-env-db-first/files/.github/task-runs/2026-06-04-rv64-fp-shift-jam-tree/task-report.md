# 2026-06-04 RV64 FP Shift Jam Tree Task Report

## Summary

本轮把 `OooAluFetchCore` 中四个 FP shift-right-jam helper 从逐 bit sticky 扫描改成固定层级 barrel-jam 组合网络。功能语义保持不变，但 RTL 结构从“循环描述”变成“宽度和层级明确的数据通路”，更适合后续 ASIC PPA 审查。

## Changed Files

- `npc/rv64/vsrc/ooo/frontend/OooAluFetchCore.v`
- `.github/memory/project-status.md`
- `.github/memory/modules/npc.md`
- `.github/memory/known-issues.md`

## Design Result

- `fp_shift_right_jam_56`：1/2/4/8/16/32 staged jam shift。
- `fp_shift_right_jam_27`：1/2/4/8/16 staged jam shift。
- `fp_shift_right_jam_106`：1/2/4/8/16/32/64 staged jam shift。
- `fp_shift_right_jam_48`：1/2/4/8/16/32 staged jam shift。

每一级使用常量右移，并把该级丢弃低位 OR 回 `stage_next[0]`，因此多级组合后仍保持原 right shift jam 语义。

## Validation Evidence

- `tb_ooo_alu_fetch_core`：PASS。
- Verilator lint：PASS。
- RV64 Verilator build：PASS。
- FP smoke：`addsub/mul/div/sqrt/convert` 全部 GOOD TRAP。
- 静态扫描确认目标 helper 中旧逐 bit `for` 循环已消失。
- `git diff --check`：PASS。

## Boundaries

- 本轮不改变 FP 指令 latency、pending FP 状态机、FDIV/FSQRT 迭代单元或 short compute latch。
- 本轮不声明完整 FPU pipeline、normalization LZC 全面树化、fflags/dynamic rounding 全矩阵或综合/STA/PPA signoff 已完成。

