# 2026-06-03 RV64 CLMUL Iter Unit Task Report

## Summary

本轮把 RV64 OoO 后端中的 Zbc `clmul/clmulh/clmulr` 从 `bitmanip_result()` 的一拍 64 次组合循环，拆成独立 `OooClmulUnit` 64-cycle shift/xor 迭代单元。这样牺牲单条 CLMUL latency，换取更清楚的面积/时序边界和更容易审查的 RTL 结构。

## Changed Files

- `npc/rv64/vsrc/ooo/backend/OooClmulUnit.v`
- `npc/rv64/vsrc/ooo/backend/OooIntBackend.v`
- `npc/rv64/vsrc/ooo/issue/OooIntIssueQueue.v`
- `npc/rv64/vsrc/filelist.mk`
- `npc/rv64/testbench/Makefile`
- `npc/rv64/testbench/tests/tb_ooo_clmul_unit.sv`
- `npc/rv64/testbench/tests/tb_ooo_int_backend.sv`
- `npc/rv64/testbench/tests/tb_ooo_int_issue_queue.sv`
- `.github/memory/project-status.md`
- `.github/memory/modules/npc.md`
- `.github/memory/known-issues.md`

## Root Cause Found During Regression

AM `bitmanip` 首轮失败不是 CLMUL 算法本身，而是 issue queue 仍把 `CTRL_BITMANIP_BIT` 下的 CLMUL 当作普通 ALU 结果 forwardable。真实程序中 CLMUL 后面隔着若干独立指令，消费者可能在 CLMUL response 前读取旧物理寄存器值。修复后 `CTRL_MULDIV_BIT` 与 Zbc CLMUL 都不能被 `ctrl_can_forward()` 视为同拍可 forward。

## Validation Evidence

- CLMUL unit focused TB：PASS。
- Issue queue CLMUL non-forward focused TB：PASS。
- 后端/解码/核心集成 TB：5/5 PASS。
- Verilator lint：PASS。
- RV64 Verilator build：PASS。
- AM `bitmanip`：PASS，GOOD TRAP，`cycles=815/commits=358`。
- Linux smoke：`jal-link/branch-raw/muldiv/sret-user-sv39-halfword` 全部 GOOD TRAP。

## Boundaries

- 本轮不声明高吞吐 CLMUL pipeline，也没有做综合/STA/PPA signoff。
- Rotate/shift 等其它 bitmanip 组合路径保留既有实现；本轮只关闭 Zbb count 和 Zbc CLMUL 两类先前已识别的大组合写法。

