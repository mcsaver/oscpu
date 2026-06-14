# Dispatch Log

- 2026-06-03: 复核 `CsrFile.v` 中 `UNUSEDSIGNAL` waiver，确认 root cause 是 EPC bit0 被分散切片强制为 0，导致 trap PC 输入 bit0 只能通过 dummy wire 消耗。
- 2026-06-03: 按需求、协议规则、状态机、不变量和数据通路约束推导，决定将 EPC bit0 对齐收敛为 `epc_warl_value()` helper。
- 2026-06-03: 修改 `CsrFile.v`，删除局部 waiver wire，所有 trap/CSR EPC 写入统一走 `EPC_WARL_MASK`。
- 2026-06-03: 完成 focused lint、focused testbench、项目级 lint/build、SRET/半字边界 smoke 与 diff check。
- 2026-06-03: 更新 `.github/memory/project-status.md` 与 `.github/memory/modules/npc.md`。
