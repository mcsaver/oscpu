# E2E Resolved Profile

- `source`: live-or-stored
- `profile`: am-kernels
- `ok`: True
- `expanded_node_count`: 5
- `profile_order`: am-kernels, abstract-machine, discovery
- `modules`: abstract-machine, agent-system, am-kernels, hardware-flow, toolchain
- `owners`: abstract-machine, agent-system, am-kernels, hardware-flow
- `command`: scripts/agent-e2e.sh --profile am-kernels
- `validate_command`: scripts/agent-e2e.sh --validate-profile --profile am-kernels

## Include Edges
- `am-kernels` -> `abstract-machine`
- `abstract-machine` -> `discovery`

## Nodes
1. `recall-discovery` source=`discovery` module=`agent-system` owner=`agent-system` function=`e2e_agent_system_discovery`
2. `tool-env-check` source=`discovery` module=`toolchain` owner=`agent-system` function=`e2e_toolchain_check`
3. `npc-sim-status` source=`discovery` module=`hardware-flow` owner=`hardware-flow` function=`e2e_hardware_flow_npc_sim_status`
4. `abstract-machine-contract` source=`abstract-machine` module=`abstract-machine` owner=`abstract-machine` function=`e2e_abstract_machine_contract`
5. `am-kernels-contract` source=`am-kernels` module=`am-kernels` owner=`am-kernels` function=`e2e_am_kernels_contract`
