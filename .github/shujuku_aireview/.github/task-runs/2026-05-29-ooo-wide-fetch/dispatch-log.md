# OoO wide fetch 派发日志

| 时间 | 节点 | 动作 | 证据 |
| --- | --- | --- | --- |
| 2026-05-29 | recall | 读取 AGENTS、Copilot 指令、memory、NPC study 与 RTL 工作流，确认上一阶段瓶颈是串行 `PC/PC+4` 取指。 | `.github/memory/project-status.md`、`.github/memory/modules/npc.md` |
| 2026-05-29 | plan | 选择实验 OoO 前端 wide packet fetch + fetch FIFO，默认 `NpcCore` 主线保持不变。 | 本任务记录 RTL 推导摘要 |
| 2026-05-29 | implement | 将 `OooAluFetchCore` 改为 packet fetch + 4-entry FIFO，并在实验 `NpcSimTop` 中用双 DPI ifetch 喂入 packet。 | `npc/single/vsrc/ooo/OooAluFetchCore.v`、`npc/single/vsrc/sim/NpcSimTop.sv` |
| 2026-05-29 | adapt | 宽取指 smoke 暴露前端过早 `ebreak` exit，改为 pending stop 等待 ROB/issue drain 后再上报。 | 短 smoke 从 `commits=3` 修复为 `commits=6` |
| 2026-05-29 | verify | 跑 OoO testbench、实验 lint/build、短/长 raw smoke、默认 lint/回归/build/AM smoke。 | `CPI=0.502` on 4096 独立 ALU；默认 `add` PASS |
