# E2E Resolved Profile

- `source`: live-or-stored
- `profile`: npc-dev
- `ok`: true
- `expanded_node_count`: 5
- `profile_order`: npc-dev, software-flow
- `modules`: npc, software-flow
- `owners`: npc, software-flow
- `command`: `scripts/agent-e2e.sh --profile npc-dev`
- `validate_command`: `scripts/agent-e2e.sh --validate-profile --profile npc-dev`

## Include Edges

- `npc-dev` -> `software-flow`

## Nodes

1. `software-flow-contract` -> `e2e_software_flow_contract`
2. `npc-sim-contract` -> `e2e_npc_sim_contract`
3. `npc-single-contract` -> `e2e_npc_single_contract`
4. `npc-soc-contract` -> `e2e_npc_soc_contract`
5. `npc-rv64-contract` -> `e2e_npc_rv64_contract`

## Fresh execution

- `--validate-profile --profile npc-dev`: PASS，5/5 nodes OK。
- `--profile npc-dev`: exit 0；生成 `.github/task-runs/2026-07-11-agent-e2e-npc-dev/`。
- DB `runs --profile npc-dev` readback：该 run status=`completed`，evidence assets=7。
- 边界：该 profile 只证明 NPC 开发环境/入口合同，不证明本次 RTL 功能回归；本任务没有修改 RTL 行为。
