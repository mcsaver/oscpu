# E2E Resolved Profile

- `source`: live-or-stored
- `profile`: contracts
- `ok`: True
- `expanded_node_count`: 25
- `profile_order`: contracts, discovery
- `modules`: abstract-machine, agent-system, am-kernels, difftest, digital-logic, display-vga, fceux-am, github-index, hardware-flow, linux-device, nemu, npc, nvboard, rv64-linux, software-flow, toolchain, verilator-tapeout, yosys-sta, ysyx-coordinator, ysyx-soc
- `owners`: abstract-machine, agent-system, am-kernels, difftest, digital-logic, display-vga, fceux-am, hardware-flow, linux-device, nemu, npc, nvboard, rv64-linux, software-flow, verilator-tapeout, yosys-sta, ysyx-coordinator, ysyx-soc
- `command`: scripts/agent-e2e.sh --profile contracts
- `validate_command`: scripts/agent-e2e.sh --validate-profile --profile contracts

## Include Edges
- `contracts` -> `discovery`

## Nodes
1. `recall-discovery` source=`discovery` module=`agent-system` owner=`agent-system` function=`e2e_agent_system_discovery`
2. `tool-env-check` source=`discovery` module=`toolchain` owner=`agent-system` function=`e2e_toolchain_check`
3. `npc-sim-status` source=`discovery` module=`hardware-flow` owner=`hardware-flow` function=`e2e_hardware_flow_npc_sim_status`
4. `profile-index` source=`contracts` module=`agent-system` owner=`agent-system` function=`e2e_agent_system_profile_index`
5. `ysyx-coordinator-contract` source=`contracts` module=`ysyx-coordinator` owner=`ysyx-coordinator` function=`e2e_ysyx_coordinator_contract`
6. `hardware-flow-contract` source=`contracts` module=`hardware-flow` owner=`hardware-flow` function=`e2e_hardware_flow_contract`
7. `software-flow-contract` source=`contracts` module=`software-flow` owner=`software-flow` function=`e2e_software_flow_contract`
8. `github-index-contract` source=`contracts` module=`github-index` owner=`agent-system` function=`e2e_github_index_contract`
9. `abstract-machine-contract` source=`contracts` module=`abstract-machine` owner=`abstract-machine` function=`e2e_abstract_machine_contract`
10. `am-kernels-contract` source=`contracts` module=`am-kernels` owner=`am-kernels` function=`e2e_am_kernels_contract`
11. `nemu-config-probe` source=`contracts` module=`nemu` owner=`nemu` function=`e2e_nemu_config_probe`
12. `npc-sim-contract` source=`contracts` module=`npc` owner=`npc` function=`e2e_npc_sim_contract`
13. `npc-single-contract` source=`contracts` module=`npc` owner=`npc` function=`e2e_npc_single_contract`
14. `npc-soc-contract` source=`contracts` module=`npc` owner=`npc` function=`e2e_npc_soc_contract`
15. `npc-rv64-contract` source=`contracts` module=`npc` owner=`npc` function=`e2e_npc_rv64_contract`
16. `ysyx-soc-contract` source=`contracts` module=`ysyx-soc` owner=`ysyx-soc` function=`e2e_ysyx_soc_contract`
17. `difftest-contract` source=`contracts` module=`difftest` owner=`difftest` function=`e2e_difftest_contract`
18. `yosys-sta-contract` source=`contracts` module=`yosys-sta` owner=`yosys-sta` function=`e2e_yosys_sta_contract`
19. `rv64-linux-contract` source=`contracts` module=`rv64-linux` owner=`rv64-linux` function=`e2e_rv64_linux_contract`
20. `linux-device-contract` source=`contracts` module=`linux-device` owner=`linux-device` function=`e2e_linux_device_contract`
21. `display-vga-contract` source=`contracts` module=`display-vga` owner=`display-vga` function=`e2e_display_vga_contract`
22. `verilator-tapeout-contract` source=`contracts` module=`verilator-tapeout` owner=`verilator-tapeout` function=`e2e_verilator_tapeout_contract`
23. `fceux-am-contract` source=`contracts` module=`fceux-am` owner=`fceux-am` function=`e2e_fceux_am_contract`
24. `nvboard-contract` source=`contracts` module=`nvboard` owner=`nvboard` function=`e2e_nvboard_contract`
25. `digital-logic-contract` source=`contracts` module=`digital-logic` owner=`digital-logic` function=`e2e_digital_logic_contract`

