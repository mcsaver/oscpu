# E2E Resolved Profile

- `source`: live-or-stored
- `profile`: difftest
- `ok`: True
- `expanded_node_count`: 7
- `profile_order`: difftest, nemu, abstract-machine, discovery
- `modules`: abstract-machine, agent-system, difftest, hardware-flow, nemu, toolchain
- `owners`: abstract-machine, agent-system, difftest, hardware-flow, nemu
- `command`: scripts/agent-e2e.sh --profile difftest
- `validate_command`: scripts/agent-e2e.sh --validate-profile --profile difftest

## Include Edges
- `difftest` -> `nemu`
- `nemu` -> `abstract-machine`
- `abstract-machine` -> `discovery`

## Nodes
1. `recall-discovery` source=`discovery` module=`agent-system` owner=`agent-system` function=`e2e_agent_system_discovery`
2. `tool-env-check` source=`discovery` module=`toolchain` owner=`agent-system` function=`e2e_toolchain_check`
3. `npc-sim-status` source=`discovery` module=`hardware-flow` owner=`hardware-flow` function=`e2e_hardware_flow_npc_sim_status`
4. `abstract-machine-contract` source=`abstract-machine` module=`abstract-machine` owner=`abstract-machine` function=`e2e_abstract_machine_contract`
5. `nemu-config-probe` source=`nemu` module=`nemu` owner=`nemu` function=`e2e_nemu_config_probe`
6. `nemu-add-smoke` source=`nemu` module=`nemu` owner=`nemu` function=`e2e_nemu_native_add_smoke`
7. `difftest-contract` source=`difftest` module=`difftest` owner=`difftest` function=`e2e_difftest_contract`
