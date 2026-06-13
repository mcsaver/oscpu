# RV64 CsrFile EPC WARL Cleanup

## 背景

本轮继续按“商业 ASIC 级 RTL”目标清理活动 RV64 RTL 中的仿真式 waiver。目标文件为 `npc/rv64/vsrc/core/CsrFile.v`。

旧实现对 trap PC 写入 `mepc/sepc` 时使用 `{pc[`XLEN-1:1], 1'b0}`，CSR 写 `MEPC/SEPC` 也使用同样的分散切片。这符合 EPC bit0 恒为 0 的架构语义，但 Verilator 会认为 `trap_mem_pc_i[0]`、`trap_ex_pc_i[0]`、`trap_irq_pc_i[0]` 未使用，因此文件中保留了局部 `UNUSEDSIGNAL` waiver。

## RTL 推导

- 需求：删除 `CsrFile` 的 trap PC bit0 unused waiver，同时把 `mepc/sepc` 对齐语义从分散切片收敛为统一 WARL helper。
- 协议规则：`CsrFile` 仍是 CSR/trap/xRET 状态的单一时序 owner；trap 优先级保持 `trap_mem > trap_ex > trap_irq > xRET/CSR write`；trap delegation、`mstatus` 副作用、CSR write gating 不变。
- 状态机：不新增状态，不拆时序块；只替换 EPC 写入数据源表达式。
- 不变量：reset 后 `csr_mepc_q[0]=0`、`csr_sepc_q[0]=0`；任何 trap 写入或 CSR 写 `MEPC/SEPC` 后 bit0 仍为 0；`mepc_o` 和 `ret_target_o` 继续直接来自 EPC 寄存器。
- 数据通路约束：新增 `EPC_WARL_MASK` 与 `epc_warl_value()`，所有 `trap_mem_pc_i/trap_ex_pc_i/trap_irq_pc_i/csr_new_value_w` 写 EPC 前统一 mask bit0。

## 变更

- 在 `CsrFile.v` 中新增 `EPC_WARL_MASK = {{(`XLEN-1){1'b1}}, 1'b0}`。
- 新增 `epc_warl_value(value)` helper。
- 删除原 `trap_*_pc_align_bit_unused_w` 三根 waiver wire 与 `verilator lint_off/on UNUSEDSIGNAL`。
- 替换 6 处 trap EPC 写入和 2 处 CSR EPC 写入为 `epc_warl_value(...)`。

## 验证

- `verilator --lint-only -Wall -Wno-WIDTHEXPAND -Wno-WIDTHTRUNC +incdir+./npc/rv64/vsrc/include --top-module CsrFile npc/rv64/vsrc/core/CsrFile.v`：PASS。
- `make -C npc/rv64/testbench TESTS="tb_ooo_priv_system tb_ooo_sv39_boot tb_ooo_alu_fetch_core" RESULT_TIMESTAMP=20260603-csrfile-epc-warl-cleanup run`：3/3 PASS。
- `make -C npc/rv64 lint`：PASS。
- `make -C npc/rv64 -j2`：PASS。
- `make -C Linux/tools smoke-sret-user smoke-sret-user-sv39 smoke-sret-user-sv39-halfword smoke-sret-restore smoke-ras-trap-boundary`：全部 GOOD TRAP。
- `rg -n "lint_off|lint_on|UNUSED|UNOPT|BLKSEQ" npc/rv64/vsrc/core/CsrFile.v`：无命中。
- `git diff --check -- npc/rv64/vsrc/core/CsrFile.v`：PASS。

## 剩余边界

活动 RTL 排除 `legacy/` 后仍有以下 waiver 候选：

- `OooRvcDecompressor.v`：`UNUSEDSIGNAL`
- `OooIntBackend.v`：`UNUSEDSIGNAL`
- `OooAluDecodeBackend.v`：`UNUSEDSIGNAL`、`UNOPTFLAT`
- `OooAluFetchCore.v`：多处 `UNOPTFLAT`

这些不属于本轮 EPC WARL cleanup 的行为边界。
