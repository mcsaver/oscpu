#!/usr/bin/env bash

e2e_abstract_machine_contract() {
  echo "[abstract-machine] contract"
  e2e_print_required_files \
    abstract-machine/Makefile \
    abstract-machine/am/include/am.h \
    abstract-machine/am/include/amdev.h \
    abstract-machine/scripts/riscv32-nemu.mk \
    abstract-machine/scripts/riscv32-npc.mk \
    .github/memory/modules/abstract-machine.md
}

e2e_ysyx_coordinator_contract() {
  echo "[ysyx-coordinator] contract"
  e2e_print_required_files \
    .github/agents/ysyx-coordinator.agent.md \
    .github/agentic-hardware-blueprint.md \
    .github/AGENTS.md \
    .github/e2e/profiles/discovery.tsv
}

e2e_am_kernels_contract() {
  echo "[am-kernels] contract"
  e2e_print_required_files \
    am-kernels/tests/cpu-tests/Makefile \
    am-kernels/tests/am-tests/Makefile \
    am-kernels/tests/klib-tests/Makefile \
    am-kernels/benchmarks/coremark/Makefile \
    scripts/am-regression.sh \
    .github/memory/modules/am-kernels.md
}

e2e_difftest_contract() {
  echo "[difftest] contract"
  e2e_print_required_files \
    nemu/tools/spike-diff/Makefile \
    npc/sim/Makefile \
    .github/memory/modules/difftest.md \
    .github/agents/difftest.agent.md
}

e2e_ysyx_soc_contract() {
  echo "[ysyx-soc] contract"
  e2e_print_required_files \
    ysyxSoC/Makefile \
    ysyxSoC/spec/cpu-interface.md \
    .github/agents/ysyx-soc.agent.md \
    .github/memory/modules/ysyx-soc.md
}

e2e_yosys_sta_contract() {
  echo "[yosys-sta] contract"
  e2e_print_required_files \
    yosys-sta/Makefile \
    .github/agents/yosys-sta.agent.md \
    .github/memory/modules/yosys-sta.md
  echo
  e2e_print_optional_tools yosys iEDA
}

e2e_rv64_linux_contract() {
  echo "[rv64-linux] contract"
  e2e_print_required_files \
    Linux/README.md \
    Linux/env/README.md \
    Linux/Makefile \
    Linux/platform/npc-rv64.yml \
    .github/agents/rv64-linux.agent.md \
    .github/instructions/rv64-linux-bringup.instructions.md
}

e2e_linux_device_contract() {
  echo "[linux-device] contract"
  e2e_print_required_files \
    .github/agents/linux-device.agent.md \
    .github/instructions/virtio-rootfs.instructions.md \
    Linux/scripts/check-nemu-systemd-guest.sh \
    Linux/platform/gen_dts.py
}

e2e_display_vga_contract() {
  echo "[display-vga] contract"
  e2e_print_required_files \
    .github/agents/display-vga.agent.md \
    .github/instructions/linux-framebuffer-vga.instructions.md \
    Linux/README.md
}

e2e_verilator_tapeout_contract() {
  echo "[verilator-tapeout] contract"
  e2e_print_required_files \
    .github/agents/verilator-tapeout.agent.md \
    .github/instructions/verilator-tapeout-realism.instructions.md \
    npc/rv64/Makefile
}

e2e_fceux_am_contract() {
  echo "[fceux-am] contract"
  e2e_print_required_files \
    fceux-am/Makefile \
    .github/agents/fceux-am.agent.md \
    .github/memory/modules/fceux-am.md
}

e2e_nvboard_contract() {
  echo "[nvboard] contract"
  e2e_print_required_paths \
    nvboard/scripts/nvboard.mk \
    nvboard/example/Makefile \
    nvboard/README.md \
    .github/agents/nvboard.agent.md
}

e2e_digital_logic_contract() {
  echo "[digital-logic] contract"
  e2e_print_required_paths \
    digital_logic_experiment \
    .github/agents/digital-logic.agent.md
}
