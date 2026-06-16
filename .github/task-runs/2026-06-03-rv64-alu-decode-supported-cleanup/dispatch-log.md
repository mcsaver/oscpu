# Dispatch Log

- 2026-06-03: 重读 `.github/AGENTS.md`、`.github/copilot-instructions.md`、项目状态、已知问题、NPC 模块笔记、RTL 工作流与 Verilator 真实性约束。
- 2026-06-03: 扫描活动 RV64 RTL waiver，确认 `OooAluDecodeBackend` 仍有 `UNUSEDSIGNAL` 与 `UNOPTFLAT`。
- 2026-06-03: 定位 root cause：`ctrl_supported()` helper 接收完整 `CTRL_BUS`，实际只消费支持性判定位。
- 2026-06-03: 按需求、协议规则、状态机、不变量、数据通路约束完成 RTL 推导。
- 2026-06-03: 修改 `OooAluDecodeBackend.v`，把 `ctrl_supported()` 入参收窄到 9 个判定位，并删除 `UNUSEDSIGNAL` waiver。
- 2026-06-03: 完成 focused testbench、项目级 lint/build、Linux/tools smoke、waiver 扫描和 diff check。
- 2026-06-03: 更新 `.github/memory/project-status.md` 与 `.github/memory/modules/npc.md`。
