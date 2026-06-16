# Dispatch Log

- 2026-06-03: 重读 `.github/AGENTS.md`、`.github/copilot-instructions.md`、项目状态、已知问题、NPC 模块笔记和 RTL/Verilator 约束。
- 2026-06-03: 扫描活动 RV64 RTL waiver，确认 `OooRvcDecompressor` 仍有整段 `UNUSEDSIGNAL` waiver。
- 2026-06-03: 定位 root cause：RVC helper 入参过宽，B/J encoder 接收未编码的 alignment bit0。
- 2026-06-03: 按需求、协议规则、状态机、不变量、数据通路约束完成 RTL 推导。
- 2026-06-03: 修改 `OooRvcDecompressor.v`，删除 waiver，收窄 helper 入参和调用点字段。
- 2026-06-03: 完成 strict lint、focused testbench、项目级 lint/build、RVC/FP/Sv39 smoke 和 diff check。
- 2026-06-03: 更新 `.github/memory/project-status.md` 与 `.github/memory/modules/npc.md`。
