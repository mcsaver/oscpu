# 2026-06-04 RV64 FP Convert Tree Dispatch Log

## Context

- 目标：继续按商业 ASIC RTL 风格收敛 RV64 `OooAluFetchCore`，本轮聚焦 FP convert helper 的 MSB/sticky 组合扫描。
- 旧实现：`fp_u64_msb_index` 用 64 次 procedural loop 找最高置位；`fp_int_to_d_value` 和 `fp_d_to_int_value` 用 64/53 次 loop 扫描 guard 以下低位 sticky。
- 约束：保持 FCVT focused 行为、pending FP drain、short compute latch、GPR/FPR 写回边界和已有测试入口；不新增状态机或握手。

## Derivation

- 需求：把功能仿真式逐 bit 扫描替换成宽度固定、层级明确、便于综合审查的组合树。
- 协议规则：转换 helper 仍是纯组合函数，同周期返回；上游 pending FP 只看到原 helper 的返回值，不新增 valid/ready 或背压。
- 状态机：无新增状态；父级 `pending_fp_q`、`pending_fp_compute_done_q`、long-op 状态和 drain-complete 规则不变。
- 不变量：`fp_u64_msb_index(0)=0`；非零输入返回最高置位 bit；int->double sticky 只 OR guard 以下低位；double->int sticky 在 `shift_count<=53` 时只 OR guard 以下 `sig` 低位，在 `shift_count>53` 时保持 `sticky=|sig`；NaN/Inf/饱和、signed/unsigned、word/dword 和 rounding mode 入口语义不变。
- 数据通路约束：MSB 查找使用 64->32->16->8->4->2 优先选择树；sticky 使用 8 个 byte OR、完整 byte 前缀选择和 partial byte 选择，避免 helper 内逐 bit loop。

## Implementation Notes

- 修改 `npc/rv64/vsrc/ooo/frontend/OooAluFetchCore.v`。
- `fp_u64_msb_index` 删除 `integer bit_idx`，替换为 `stage32/stage16/stage8/stage4/stage2` 优先树。
- 新增 `fp_u64_low_or(value, bit_count)`，复用到 int->double 和 double->int sticky。
- `fp_int_to_d_value` 与 `fp_d_to_int_value` 删除局部 `integer bit_idx` 和 sticky loop，改用 `sticky_bit_count` 调用 byte 级 OR helper。

## Verification

- 静态扫描 `for (bit_idx = 0; bit_idx < 64/53)` 与 `integer bit_idx`：无输出。
- `make -C npc/rv64/testbench TESTS=tb_ooo_alu_fetch_core run`：PASS。
- `make -C npc/rv64 lint`：PASS。
- `make -C npc/rv64 -j2`：PASS。
- 新二进制 build time：`10:43:47, Jun 4 2026`。
- `make -C Linux/tools smoke-fp-convert smoke-fp-fmv-fclass smoke-fp-fcsr smoke-fp-addsub smoke-fp-mul`：全部 GOOD TRAP，分别为 `192/65`、`278/95`、`323/88`、`266/86`、`287/89`。
- `git diff --check`：PASS。

