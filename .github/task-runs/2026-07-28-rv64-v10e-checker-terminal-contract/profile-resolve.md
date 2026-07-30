# E2E Resolved Profile

- `source`: live-or-stored
- `profile`: rv64-systemd-contract
- `ok`: True
- `expanded_node_count`: 4
- `profile_order`: rv64-systemd-contract, discovery
- `modules`: agent-system, hardware-flow, npc, toolchain
- `owners`: agent-system, hardware-flow, npc
- `command`: scripts/agent-e2e.sh --profile rv64-systemd-contract
- `validate_command`: scripts/agent-e2e.sh --validate-profile --profile rv64-systemd-contract

## Include Edges
- `rv64-systemd-contract` -> `discovery`

## Nodes
1. `recall-discovery` source=`discovery` module=`agent-system` owner=`agent-system` function=`e2e_agent_system_discovery`
2. `tool-env-check` source=`discovery` module=`toolchain` owner=`agent-system` function=`e2e_toolchain_check`
3. `npc-sim-status` source=`discovery` module=`hardware-flow` owner=`hardware-flow` function=`e2e_hardware_flow_npc_sim_status`
4. `npc-rv64-systemd-guest-check-contract` source=`rv64-systemd-contract` module=`npc` owner=`npc` function=`e2e_npc_rv64_systemd_guest_check_contract`
