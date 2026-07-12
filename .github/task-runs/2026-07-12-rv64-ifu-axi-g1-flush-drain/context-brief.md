# IFU-AXI-G1 bounded context brief

- `generated_at`: 2026-07-12 22:10:00 +0800
- `command`: `python3 scripts/github_index_db.py brief IFU-AXI-G1 A-update flush drain OooFetchAxiBridge --profile npc-dev --max-tokens 1200`
- `source`: live-or-stored
- `profile`: `npc-dev`
- `token_estimate`: 1061 / 1200
- `profile_suggestion`: `npc-dev`（requested-profile，score 8）

## Selected task context

- 工作流真源：根 `AGENTS.md`、`.github/AGENTS.md`、`.github/copilot-instructions.md`。
- DB-backed 记忆：`.github/memory/project-status.md`、`.github/memory/known-issues.md`、
  `.github/memory/modules/npc.md`。
- 合同规则：`.github/instructions/interface-contract-first.instructions.md`、
  `.github/instructions/npc-optimization-workflow.instructions.md`、
  `.github/instructions/agent-e2e-workflow.instructions.md`。
- 当前设计真源：`npc/rv64/design/specs/ooo-fetch-axi-bridge.md`、
  `npc/rv64/design/specs/ooo-flush-redirect-contract.md`、
  `npc/rv64/design/arch/rtl-ground-truth-2026-07-11.md`、
  `npc/rv64/design/arch/rv64-200mhz-completion-design.md`。
- 实现/集成链：`OooFetchAxiBridge.v -> AxiXbar.v -> slave B -> next master grant`。

## Bounded decisions

- 本切片只关闭 `IFU-AXI-G1`；`IFU-FETCH-G2` 与 `PTW-PMP-G1` 保持开放。
- flush 可以丢旧 fetch 语义，不能撤销已经呈现的 AXI AW/W/B owner。
- 必须同时有 old-RTL RED、bridge+xbar 系统进展 GREEN、非真空断言、模块/核心回归和
  DB/profile/strict-guard 证据；不以该 correctness slice 声称 200 MHz。
