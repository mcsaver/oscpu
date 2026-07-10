# E2E Resolved Profile

- `source`: live-or-stored
- `profile`: yosys-sta
- `ok`: True
- `expanded_node_count`: 6
- `profile_order`: yosys-sta, npc-single, npc-sim, discovery
- `modules`: agent-system, hardware-flow, npc, toolchain, yosys-sta
- `owners`: agent-system, hardware-flow, npc, yosys-sta
- `command`: scripts/agent-e2e.sh --profile yosys-sta
- `validate_command`: scripts/agent-e2e.sh --validate-profile --profile yosys-sta

## Include Edges
- `yosys-sta` -> `npc-single`
- `npc-single` -> `npc-sim`
- `npc-sim` -> `discovery`

## Nodes
1. `recall-discovery` source=`discovery` module=`agent-system` owner=`agent-system` function=`e2e_agent_system_discovery`
2. `tool-env-check` source=`discovery` module=`toolchain` owner=`agent-system` function=`e2e_toolchain_check`
3. `npc-sim-status` source=`discovery` module=`hardware-flow` owner=`hardware-flow` function=`e2e_hardware_flow_npc_sim_status`
4. `npc-sim-contract` source=`npc-sim` module=`npc` owner=`npc` function=`e2e_npc_sim_contract`
5. `npc-single-contract` source=`npc-single` module=`npc` owner=`npc` function=`e2e_npc_single_contract`
6. `yosys-sta-contract` source=`yosys-sta` module=`yosys-sta` owner=`yosys-sta` function=`e2e_yosys_sta_contract`

