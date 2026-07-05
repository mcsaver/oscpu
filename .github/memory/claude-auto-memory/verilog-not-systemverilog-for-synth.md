---
name: verilog-not-systemverilog-for-synth
description: Synthesizable RTL must be .v with Verilog-2001 always keywords; .sv only for verification; iverilog rejects always_comb constant-selects
metadata: 
  node_type: memory
  type: project
  originSessionId: 0353a89c-6ba9-4a48-b7b5-b2e6baab6210
---

本仓库(ysyx-workbench npc/rv64)RTL 文件/关键字约束(用户明确要求 + 工具链实测,2026-06-29):

- **真实可综合硬件一律写 `.v`;`.sv` 只用于验证**(testbench/DPI/仿真顶层如 `vsrc/sim/*.sv`/断言)。不要用 `.sv` 描述会进综合网表的硬件。
- **可综合 .v 用 Verilog-2001 always 关键字,不用 SV 的 `always_comb`/`always_ff`**:时序写 `always @(posedge clk)`,组合写 `always @(*)`。`always_comb`/`always_ff`/`logic` 只允许在 `.sv` 验证代码。

**关键根因(实测 iverilog 12.0):** 模块 testbench gate 用 Icarus iverilog 12.0,它对 **`always_comb` 关键字**内的变量常量位选(如 `magn[127:75]`)报 `sorry: constant selects in always_* processes ... all bits will be included`——**静默错仿真 + 全核 build Error 10**。而 **`always @(*)` 和 `always @(posedge clk)`** 对同样的位选完全正确(已逐例验证)。Verilator/Vivado(`read_verilog -sv`)两者都吃,但 iverilog 是最易被忽视的 gate。

**验证回环:** 可综合 RTL 改动后必须同时过 ① **`make -C npc/rv64 check-rtl-style`**(风格 gate,`eval/check-rtl-style.sh`:可综合文件须 .v、禁 always_comb/always_ff/logic)② Verilator(`make lint`+sim)③ **iverilog 模块 TB**(`npc/rv64/testbench/`)④ 适用时 Vivado OOC。只过 Verilator 会漏掉 iverilog 的 always_comb 静默错。检查器已接入 `make check-rtl-style` + `print-synth-rtl`(扫描 RTL_CORE_SRCS)。

曾踩坑:把 FMA 写成 `always_comb` 命名块,Verilator/Vivado 全过、rv64ud+difftest 全过,但 `tb_ooo_core_top_glue` iverilog 编译 Error 10;改 `always @(*)` 后全绿。详见 [[rtl-coding-standard]]、[[fp2-fma-fused-fix]]。
