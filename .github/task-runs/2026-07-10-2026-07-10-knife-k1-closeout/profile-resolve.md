# E2E Resolved Profile

- `source`: live-or-stored
- `profile`: npc-dev
- `ok`: True
- `expanded_node_count`: 5
- `profile_order`: npc-dev, software-flow
- `modules`: npc, software-flow
- `owners`: npc, software-flow
- `command`: scripts/agent-e2e.sh --profile npc-dev
- `validate_command`: scripts/agent-e2e.sh --validate-profile --profile npc-dev

## Include Edges
- `npc-dev` -> `software-flow`

## Nodes
1. `software-flow-contract` source=`software-flow` module=`software-flow` owner=`software-flow` function=`e2e_software_flow_contract`
2. `npc-sim-contract` source=`npc-dev` module=`npc` owner=`npc` function=`e2e_npc_sim_contract`
3. `npc-single-contract` source=`npc-dev` module=`npc` owner=`npc` function=`e2e_npc_single_contract`
4. `npc-soc-contract` source=`npc-dev` module=`npc` owner=`npc` function=`e2e_npc_soc_contract`
5. `npc-rv64-contract` source=`npc-dev` module=`npc` owner=`npc` function=`e2e_npc_rv64_contract`

