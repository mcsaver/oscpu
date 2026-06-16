# 2026-06-04 RV64 FP Shift Jam Tree Dispatch Log

## Context

- 目标：继续按商业 ASIC RTL 风格收敛 RV64 `OooAluFetchCore`，本轮聚焦 FP 舍入 sticky 生成 helper。
- 旧实现：`fp_shift_right_jam_56/27/106/48` 使用函数内逐 bit `for` 扫描被右移丢弃的低位，再把 sticky OR 到 bit0。
- 约束：保持 FP add/sub/mul/div/sqrt/convert 既有功能语义，不改变 pending FP、FDIV/FSQRT long-op、short compute latch、ready/valid 或提交边界。

## Derivation

- 需求：把功能仿真式 sticky 扫描替换为固定层级、宽度明确、综合结构可审查的 barrel-jam 数据通路。
- 协议规则：四个 helper 仍是纯组合函数，同周期返回结果；所有调用点继续在原 FP helper 内使用；不新增寄存器、握手或 backpressure。
- 状态机：无新增状态机；父级 pending FP 状态、short compute latch 和 long-op done/commit 规则保持不变。
- 不变量：`shamt==0` 返回原值；`shamt>=width` 返回 `{width-1'b0, |value}`；`0<shamt<width` 时结果等价于 `value >> shamt`，bit0 OR 上所有被移出的低位；已 jam 到 bit0 的 sticky 在后续级联右移中继续参与 OR。
- 数据通路约束：使用固定 1/2/4/8/16/32/64 条件右移级联，每一级都是常量移位和固定低位 OR-reduce，避免变量 loop 展开成不透明的优先/OR 扫描网络。

## Implementation Notes

- 修改 `npc/rv64/vsrc/ooo/frontend/OooAluFetchCore.v`。
- 四个 helper 的 `sticky` 和 `integer bit_idx` 局部扫描被替换为 `stage/stage_next` 分级网络。
- 56-bit helper 覆盖 1/2/4/8/16/32 级。
- 27-bit helper 覆盖 1/2/4/8/16 级。
- 106-bit helper 覆盖 1/2/4/8/16/32/64 级。
- 48-bit helper 覆盖 1/2/4/8/16/32 级。
- 未修改 testbench；现有 `tb_ooo_alu_fetch_core` 和 Linux FP smoke 已覆盖该路径的主要消费者。

## Verification

- 静态扫描 `fp_shift_right_jam_(56|27|106|48)|for (bit_idx = 0; bit_idx < 56/27/106/48)`：仅命中 helper 定义/赋值/调用点，未命中旧循环。
- `make -C npc/rv64/testbench TESTS=tb_ooo_alu_fetch_core run`：PASS。
- `make -C npc/rv64 lint`：PASS。
- `make -C npc/rv64 -j2`：PASS。
- 新二进制 build time 确认为 `10:32:44, Jun 4 2026`。
- `make -C Linux/tools smoke-fp-addsub smoke-fp-mul smoke-fp-div smoke-fp-sqrt smoke-fp-convert`：全部 GOOD TRAP，分别为 `266/86`、`287/89`、`946/100`、`1039/94`、`192/65`。
- `git diff --check`：PASS。

