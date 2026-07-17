# E2E Resolved Profile

- `source`: live-or-stored
- `profile`: verilator-tapeout
- `ok`: True
- `expanded_node_count`: 11
- `profile_order`: verilator-tapeout, rv64-linux, discovery
- `modules`: agent-system, hardware-flow, npc, rv64-linux, toolchain, verilator-tapeout
- `owners`: agent-system, hardware-flow, npc, rv64-linux, verilator-tapeout
- `command`: scripts/agent-e2e.sh --profile verilator-tapeout
- `validate_command`: scripts/agent-e2e.sh --validate-profile --profile verilator-tapeout

## Include Edges
- `verilator-tapeout` -> `rv64-linux`
- `rv64-linux` -> `discovery`

## Nodes
1. `recall-discovery` source=`discovery` module=`agent-system` owner=`agent-system` function=`e2e_agent_system_discovery`
2. `tool-env-check` source=`discovery` module=`toolchain` owner=`agent-system` function=`e2e_toolchain_check`
3. `npc-sim-status` source=`discovery` module=`hardware-flow` owner=`hardware-flow` function=`e2e_hardware_flow_npc_sim_status`
4. `npc-rv64-contract` source=`rv64-linux` module=`npc` owner=`npc` function=`e2e_npc_rv64_contract`
5. `npc-rv64-sv39-sret-u-mode` source=`rv64-linux` module=`npc` owner=`npc` function=`e2e_npc_rv64_sv39_sret_u_mode`
6. `npc-rv64-linux-focused-smokes` source=`rv64-linux` module=`npc` owner=`npc` function=`e2e_npc_rv64_linux_focused_smokes`
7. `npc-rv64-uart-rx-smoke` source=`rv64-linux` module=`npc` owner=`npc` function=`e2e_npc_rv64_uart_rx_smoke`
8. `npc-rv64-linux-rootfs-mount-smoke` source=`rv64-linux` module=`npc` owner=`npc` function=`e2e_npc_rv64_linux_rootfs_mount_smoke`
9. `npc-rv64-systemd-guest-check-contract` source=`rv64-linux` module=`npc` owner=`npc` function=`e2e_npc_rv64_systemd_guest_check_contract`
10. `rv64-linux-contract` source=`rv64-linux` module=`rv64-linux` owner=`rv64-linux` function=`e2e_rv64_linux_contract`
11. `verilator-tapeout-contract` source=`verilator-tapeout` module=`verilator-tapeout` owner=`verilator-tapeout` function=`e2e_verilator_tapeout_contract`
