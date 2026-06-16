# E2E Resolved Profile

- `source`: stored
- `profile`: quick
- `ok`: True
- `expanded_node_count`: 4
- `profile_order`: quick, discovery
- `modules`: agent-system, hardware-flow, nemu, toolchain
- `owners`: agent-system, hardware-flow, nemu
- `command`: scripts/agent-e2e.sh --profile quick
- `validate_command`: scripts/agent-e2e.sh --validate-profile --profile quick

## Include Edges
- `quick` -> `discovery`

## Nodes
1. `recall-discovery` source=`discovery` module=`agent-system` owner=`agent-system` function=`e2e_agent_system_discovery`
2. `tool-env-check` source=`discovery` module=`toolchain` owner=`agent-system` function=`e2e_toolchain_check`
3. `npc-sim-status` source=`discovery` module=`hardware-flow` owner=`hardware-flow` function=`e2e_hardware_flow_npc_sim_status`
4. `nemu-add-smoke` source=`quick` module=`nemu` owner=`nemu` function=`e2e_nemu_am_add_smoke`

