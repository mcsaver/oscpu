# E2E Resolved Profile

- `source`: live-or-stored
- `profile`: agent-system
- `ok`: True
- `expanded_node_count`: 10
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
4. `three-layer-contract` source=`agent-system` module=`agent-system` owner=`agent-system` function=`e2e_agent_system_three_layer_contract`
5. `runtime-artifact-boundary` source=`agent-system` module=`agent-system` owner=`agent-system` function=`e2e_agent_system_runtime_artifact_boundary`
6. `state-machine-traceback` source=`agent-system` module=`agent-system` owner=`agent-system` function=`e2e_agent_system_state_traceback`
7. `reviewer-inspector-gate` source=`agent-system` module=`agent-system` owner=`agent-system` function=`e2e_agent_system_reviewer_inspector_gate`
8. `rtl-task-contract` source=`agent-system` module=`agent-system` owner=`agent-system` function=`e2e_agent_system_rtl_task_contract`
9. `commercial-delivery-readiness` source=`agent-system` module=`agent-system` owner=`agent-system` function=`e2e_agent_system_commercial_delivery_readiness`
10. `profile-index` source=`agent-system` module=`agent-system` owner=`agent-system` function=`e2e_agent_system_profile_index`
