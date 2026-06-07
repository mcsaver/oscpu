#!/usr/bin/env bash

e2e_npc_sim_contract() {
  echo "[npc] sim contract"
  e2e_print_required_files \
    npc/sim/Makefile \
    npc/sim/backends/single.mk \
    npc/sim/backends/rv64.mk \
    npc/sim/backends/soc.mk \
    npc/single/Makefile \
    npc/soc/Makefile \
    npc/rv64/Makefile
}

e2e_npc_single_contract() {
  echo "[npc-single] contract"
  e2e_print_required_files \
    npc/single/Makefile \
    npc/single/Kconfig \
    npc/single/vsrc/filelist.mk \
    npc/single/csrc/cpu/cpu-exec.cpp
}

e2e_npc_soc_contract() {
  echo "[npc-soc] contract"
  e2e_print_required_files \
    npc/soc/Makefile \
    npc/soc/Kconfig \
    ysyxSoC/spec/cpu-interface.md \
    .github/memory/modules/ysyx-soc.md
}

e2e_npc_rv64_contract() {
  echo "[npc-rv64] contract"
  e2e_print_required_files \
    npc/rv64/Makefile \
    npc/rv64/Kconfig \
    npc/rv64/README.md \
    npc/rv64/design/study/README.md \
    Linux/README.md
}

e2e_npc_add_smoke() {
  echo "[npc] command: cpu-tests add ARCH=riscv32-npc via npc/sim"
  local log_tmp run_args
  run_args=${AGENT_E2E_NPC_RUN_ARGS:-$(e2e_npc_default_run_args)}
  log_tmp=$(mktemp)
  echo "[npc] run_args=$run_args"
  timeout "${AGENT_E2E_NPC_TIMEOUT:-900}s" \
    env AM_HOME="$E2E_ROOT_DIR/abstract-machine" NEMU_HOME="$E2E_ROOT_DIR/nemu" NPC_HOME="$E2E_ROOT_DIR/npc" \
    make -C "$E2E_ROOT_DIR/am-kernels/tests/cpu-tests" ARCH=riscv32-npc ALL=add run NPC_RUN_ARGS="$run_args" \
    | tee "$log_tmp"
  local pipe_rc=${PIPESTATUS[0]}
  if [[ $pipe_rc -ne 0 ]]; then
    rm -f "$log_tmp"
    return "$pipe_rc"
  fi
  e2e_validate_cpu_test_log "$log_tmp"
  local rc=$?
  rm -f "$log_tmp"
  return "$rc"
}

e2e_npc_selected_backend() {
  local selected
  selected=${NPC_SIM_BACKEND:-${BACKEND:-${PLATFORM:-${NPC_PLATFORM:-}}}}
  if [[ -z "$selected" ]]; then
    selected=$(sed -n 's/^CONFIG_NPC_SIM_BACKEND="\([^"]*\)"/\1/p' "$E2E_ROOT_DIR/npc/sim/include/config/auto.conf" 2>/dev/null | head -n 1)
  fi
  case "$selected" in
    "") echo "single" ;;
    am) echo "single" ;;
    ysyx-soc | ysyxSoC) echo "soc" ;;
    *) echo "$selected" ;;
  esac
}

e2e_npc_default_run_args() {
  local backend config_file
  backend=$(e2e_npc_selected_backend)
  config_file="$E2E_ROOT_DIR/npc/$backend/.config"
  if [[ -f "$config_file" ]] && grep -q '^CONFIG_NPC_DIFFTEST=y' "$config_file"; then
    echo "--diff=default --no-progress -m 0"
  else
    echo "--no-progress -m 0"
  fi
}

e2e_npc_cpu_tests_full() {
  echo "[npc] command: full cpu-tests ARCH=riscv32-npc via npc/sim"
  echo "[npc] backend follows npc/sim current configuration; override with NPC_SIM_BACKEND only when the task explicitly asks for it."

  local tests_dir expected log_tmp run_args selected_backend
  tests_dir="$E2E_ROOT_DIR/am-kernels/tests/cpu-tests/tests"
  expected=$(find "$tests_dir" -name '*.c' | wc -l)
  selected_backend=$(e2e_npc_selected_backend)
  run_args=${AGENT_E2E_NPC_RUN_ARGS:-$(e2e_npc_default_run_args)}
  log_tmp=$(mktemp)

  echo "[npc] selected_backend=$selected_backend"
  echo "[npc] run_args=$run_args"

  echo "[npc] clean stale AM/cpu-tests artifacts before full run"
  if ! env AM_HOME="$E2E_ROOT_DIR/abstract-machine" make -C "$E2E_ROOT_DIR/am-kernels/tests/cpu-tests" clean; then
    rm -f "$log_tmp"
    return 1
  fi
  if ! env AM_HOME="$E2E_ROOT_DIR/abstract-machine" make -C "$E2E_ROOT_DIR/abstract-machine/am" clean; then
    rm -f "$log_tmp"
    return 1
  fi
  if ! env AM_HOME="$E2E_ROOT_DIR/abstract-machine" make -C "$E2E_ROOT_DIR/abstract-machine/klib" clean; then
    rm -f "$log_tmp"
    return 1
  fi

  timeout "${AGENT_E2E_NPC_FULL_TIMEOUT:-3600}s" \
    env AM_HOME="$E2E_ROOT_DIR/abstract-machine" NEMU_HOME="$E2E_ROOT_DIR/nemu" NPC_HOME="$E2E_ROOT_DIR/npc" \
    make -C "$E2E_ROOT_DIR/am-kernels/tests/cpu-tests" ARCH=riscv32-npc run NPC_RUN_ARGS="$run_args" \
    | tee "$log_tmp"
  local pipe_rc=${PIPESTATUS[0]}
  if [[ $pipe_rc -ne 0 ]]; then
    rm -f "$log_tmp"
    return "$pipe_rc"
  fi

  if grep -Eq '\*\*\*FAIL\*\*\*|HIT BAD TRAP|Assertion .*failed|address .*out of bound|ABORT|TIMEOUT' "$log_tmp"; then
    rm -f "$log_tmp"
    return 1
  fi

  local pass_count
  pass_count=$(grep -Ec '^\[[^]]+\].*PASS' "$log_tmp" || true)
  echo "[npc] cpu-tests pass_count=$pass_count expected=$expected"
  if [[ $pass_count -lt $expected ]]; then
    rm -f "$log_tmp"
    return 1
  fi

  rm -f "$log_tmp"
  return 0
}
