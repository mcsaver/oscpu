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

e2e_software_flow_contract() {
  echo "[software-flow] contract"
  local rc=0
  local software_agent=".github/agents/software-flow.agent.md"
  e2e_print_required_files \
    .github/agents/software-flow.agent.md \
    .github/e2e/modules/software-flow.md \
    .github/e2e/profiles/software-flow.tsv \
    .github/memory/modules/software-flow.md \
    .github/agents/nemu.agent.md \
    .github/agents/abstract-machine.agent.md \
    .github/agents/am-kernels.agent.md || rc=1

  echo "[software-flow] production integration hooks"
  if e2e_file_contains .github/agents/software-flow.agent.md 'hardware-aware-software-loop' &&
     e2e_file_contains .github/agents/software-flow.agent.md 'system-or-hardware-gate'; then
    printf 'PASS software-flow defines hardware-aware software loop\n'
  else
    printf 'FAIL software-flow defines hardware-aware software loop\n'
    rc=1
  fi
  if e2e_file_contains .github/agents/hardware-flow.agent.md 'software-flow' &&
     e2e_file_contains .github/agents/hardware-flow.agent.md 'hardware-aware-software-loop'; then
    printf 'PASS hardware-flow consumes software-flow for software artifacts\n'
  else
    printf 'FAIL hardware-flow consumes software-flow for software artifacts\n'
    rc=1
  fi
  if e2e_file_contains .github/agents/nemu.agent.md 'software-flow' &&
     e2e_file_contains .github/agents/nemu.agent.md 'hardware-aware-software-loop'; then
    printf 'PASS nemu agent requires software-flow for C-side model work\n'
  else
    printf 'FAIL nemu agent requires software-flow for C-side model work\n'
    rc=1
  fi
  if e2e_file_contains .github/agents/ysyx-coordinator.agent.md 'hardware-aware-software-loop' &&
     e2e_file_contains .github/agents/ysyx-coordinator.agent.md '软件实现硬件或系统语义'; then
    printf 'PASS coordinator routes hardware-aware software work\n'
  else
    printf 'FAIL coordinator routes hardware-aware software work\n'
    rc=1
  fi
  if e2e_file_contains .github/agentic-hardware-blueprint.md 'hardware-aware-software-loop' &&
     e2e_file_contains .github/agentic-hardware-blueprint.md 'NEMU 这类'; then
    printf 'PASS blueprint documents combined software/hardware flow\n'
  else
    printf 'FAIL blueprint documents combined software/hardware flow\n'
    rc=1
  fi
  if e2e_file_contains .github/instructions/agent-e2e-workflow.instructions.md 'hardware-aware-software-loop' &&
     e2e_file_contains .github/instructions/agent-e2e-workflow.instructions.md 'nemu-dev' &&
     e2e_file_contains .github/instructions/agent-e2e-workflow.instructions.md 'nemu-ubuntu'; then
    printf 'PASS e2e workflow documents software-flow plus system profile layering\n'
  else
    printf 'FAIL e2e workflow documents software-flow plus system profile layering\n'
    rc=1
  fi

  echo "[software-flow] methodology guard hooks"
  local required_methodology_patterns=(
    'software-dev-loop'
    'scope-contract -> design-plan -> implement -> unit-or-contract-test -> integration-smoke -> regression-or-e2e -> review-record'
    'software-bugfix-loop'
    'reproduce -> collect-log -> localize-root-cause -> fix -> focused-test -> regression -> record'
    'software-refactor-loop'
    'inventory-callers -> preserve-contract -> mechanical-change -> focused-test -> consumer-regression -> record'
    'hardware-aware-software-loop'
    'scope-contract -> hardware-semantic-contract -> design-plan -> implement -> software-focused-test -> system-or-hardware-gate -> review-record'
    '`scope-contract`'
    '`design-plan`'
    '`unit-or-contract-test`'
    '`integration-smoke`'
    '`regression-or-e2e`'
    '`hardware-semantic-contract`'
    '`system-or-hardware-gate`'
    '`review-record`'
    '不把“构建通过”单独当成软件任务完成'
    '不把脚本外层退出码当作唯一证据'
    '必须扫描 FAIL marker'
    '完成后必须更新 `.github/memory/modules/software-flow.md`'
  )
  local pattern
  for pattern in "${required_methodology_patterns[@]}"; do
    if e2e_file_contains "$software_agent" "$pattern"; then
      printf 'PASS software-flow methodology hook %s\n' "$pattern"
    else
      printf 'FAIL software-flow methodology hook %s\n' "$pattern"
      rc=1
    fi
  done
  if e2e_file_contains .github/AGENTS.md '完成判定钩子' &&
     e2e_file_contains .github/AGENTS.md '重新展开用户原始请求'; then
    printf 'PASS global completion hook guards original request checklist\n'
  else
    printf 'FAIL global completion hook guards original request checklist\n'
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
  local rc=0
  e2e_print_required_files \
    yosys-sta/Makefile \
    yosys-sta/scripts/check_abc_delay_target_contract.py \
    yosys-sta/scripts/test_abc_delay_target_contract.py \
    .github/agents/yosys-sta.agent.md \
    .github/instructions/rv64-ppa-optimization-workflow.instructions.md \
    npc/rv64/design/arch/rv64-architecture-ppa-contract.md \
    npc/rv64/eval/ppa/README.md \
    .github/memory/modules/yosys-sta.md || rc=1
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
    Linux/platform/nemu-rv64.yml \
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
    .github/instructions/rv64-ppa-optimization-workflow.instructions.md \
    npc/rv64/design/arch/rv64-architecture-ppa-contract.md \
    npc/rv64/eval/ppa/README.md \
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
