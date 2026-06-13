# E2E Resolved Profile

- `source`: stored
- `profile`: agent-system
- `ok`: True
- `expanded_node_count`: 4
- `profile_order`: agent-system, discovery
- `modules`: agent-system, hardware-flow, toolchain
- `owners`: agent-system, hardware-flow
- `command`: scripts/agent-e2e.sh --profile agent-system
- `validate_command`: scripts/agent-e2e.sh --validate-profile --profile agent-system

## Include Edges
- `agent-system` -> `discovery`

## Nodes
1. `recall-discovery` source=`discovery` module=`agent-system` owner=`agent-system` function=`e2e_agent_system_discovery`
2. `tool-env-check` source=`discovery` module=`toolchain` owner=`agent-system` function=`e2e_toolchain_check`
3. `npc-sim-status` source=`discovery` module=`hardware-flow` owner=`hardware-flow` function=`e2e_hardware_flow_npc_sim_status`
4. `profile-index` source=`agent-system` module=`agent-system` owner=`agent-system` function=`e2e_agent_system_profile_index`

