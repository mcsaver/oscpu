#!/usr/bin/env bash

e2e_abstract_machine_contract() {
  echo "[abstract-machine] contract"
  e2e_print_required_files \
    abstract-machine/Makefile \
    abstract-machine/am/include/am.h \
    abstract-machine/am/include/amdev.h \
    abstract-machine/scripts/riscv32-nemu.mk \
    abstract-machine/scripts/riscv32-npc.mk
}

e2e_ysyx_coordinator_contract() {
  echo "[ysyx-coordinator] contract"
  e2e_print_required_files \
    .github/agents/ysyx-coordinator.agent.md \
    .github/agentic-hardware-blueprint.md \
    .github/AGENTS.md \
    .github/e2e/profiles/discovery.tsv
}

e2e_software_flow_contract() {
  echo "[software-flow] contract"
  local rc=0
  e2e_print_required_files \
    .github/agents/software-flow.agent.md \
    .github/e2e/modules/software-flow.md \
    .github/e2e/profiles/software-flow.tsv \
    .github/AGENTS.md \
    .github/instructions/agent-lightweight-workflow.instructions.md || rc=1

  if e2e_file_contains .github/agents/software-flow.agent.md 'task-run、e2e 和 memory 是可选工具' &&
     e2e_file_contains .github/e2e/modules/software-flow.md '不作为普通软件任务的前置门' &&
     e2e_file_contains .github/AGENTS.md '不得仅因文件路径自动创造新的 permission gate'; then
    printf 'PASS software-flow is outcome-first and optional infrastructure stays optional\n'
  else
    printf 'FAIL software-flow reintroduced a process-first authorization gate\n'
    rc=1
  fi
  return "$rc"
}

e2e_am_kernels_contract() {
  echo "[am-kernels] contract"
  e2e_print_required_files \
    am-kernels/tests/cpu-tests/Makefile \
    am-kernels/tests/am-tests/Makefile \
    am-kernels/tests/klib-tests/Makefile \
    am-kernels/benchmarks/coremark/Makefile \
    scripts/am-regression.sh
}

e2e_difftest_contract() {
  echo "[difftest] contract"
  e2e_print_required_files \
    nemu/tools/spike-diff/Makefile \
    npc/sim/Makefile
}

e2e_ysyx_soc_contract() {
  echo "[ysyx-soc] contract"
  e2e_print_required_files \
    ysyxSoC/Makefile \
    ysyxSoC/spec/cpu-interface.md
}

e2e_yosys_sta_contract() {
  echo "[yosys-sta] contract"
  local rc=0
  e2e_print_required_files \
    yosys-sta/Makefile \
    yosys-sta/scripts/check_abc_delay_target_contract.py \
    yosys-sta/scripts/test_abc_delay_target_contract.py \
    npc/rv64/design/arch/rv64-architecture-ppa-contract.md \
    npc/rv64/eval/ppa/README.md || rc=1
  python3 "$E2E_ROOT_DIR/yosys-sta/scripts/test_abc_delay_target_contract.py" || rc=1
  python3 "$E2E_ROOT_DIR/yosys-sta/scripts/check_abc_delay_target_contract.py" || rc=1
  echo
  e2e_print_optional_tools yosys iEDA || rc=1
  return "$rc"
}

e2e_yosys_sta_contract_failure_propagation() {
  echo "[yosys-sta] contract failure propagation"
  local rc=0

  if (
    e2e_print_required_files() { return 1; }
    python3() { return 0; }
    e2e_print_optional_tools() { return 0; }
    e2e_yosys_sta_contract >/dev/null 2>&1
  ); then
    echo "FAIL yosys-sta required-file failure was swallowed"
    rc=1
  else
    echo "PASS yosys-sta required-file failure propagates"
  fi

  if (
    e2e_print_required_files() { return 0; }
    python3() { return 1; }
    e2e_print_optional_tools() { return 0; }
    e2e_yosys_sta_contract >/dev/null 2>&1
  ); then
    echo "FAIL yosys-sta checker failure was swallowed"
    rc=1
  else
    echo "PASS yosys-sta checker failure propagates"
  fi

  return "$rc"
}

e2e_rv64_linux_contract() {
  echo "[rv64-linux] contract"
  e2e_print_required_files \
    Linux/README.md \
    Linux/env/README.md \
    Linux/Makefile \
    Linux/scripts/platform/nemu.mk \
    Linux/scripts/platform/npc.mk \
    Linux/platform/common-rv64.yml \
    Linux/platform/npc-rv64.yml \
    Linux/platform/nemu-rv64.yml
}

e2e_linux_device_contract() {
  echo "[linux-device] contract"
  e2e_print_required_files \
    Linux/scripts/check-nemu-systemd-guest.sh \
    Linux/platform/gen_dts.py
}

e2e_display_vga_contract() {
  echo "[display-vga] contract"
  e2e_print_required_files \
    Linux/README.md
}

e2e_verilator_tapeout_contract() {
  echo "[verilator-tapeout] contract"
  e2e_print_required_files \
    npc/rv64/design/arch/rv64-architecture-ppa-contract.md \
    npc/rv64/eval/ppa/README.md \
    npc/rv64/Makefile
}

e2e_fceux_am_contract() {
  echo "[fceux-am] contract"
  e2e_print_required_files \
    fceux-am/Makefile
}

e2e_nvboard_contract() {
  echo "[nvboard] contract"
  e2e_print_required_paths \
    nvboard/scripts/nvboard.mk \
    nvboard/example/Makefile \
    nvboard/README.md
}

e2e_digital_logic_contract() {
  echo "[digital-logic] contract"
  e2e_print_required_paths \
    digital_logic_experiment
}
