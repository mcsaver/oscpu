#!/usr/bin/env bash

set -uo pipefail
export PYTHONDONTWRITEBYTECODE=1

repo_root=$(pwd -P)
run_dir=${repo_root}/.github/task-runs/2026-08-05-rv64-v15g-v9p-terminal-root-cause-backfill
evidence=${run_dir}/evidence/v8l-current-f7a-run-1
status_path=${run_dir}/v8l-current-f7a-run-1.status
runtime=${repo_root}/.github/runtime-artifacts/v15g-v8l-current-f7a-run-1
tb_home=${repo_root}/npc/rv64/testbench
mutator=${repo_root}/.github/task-runs/2026-07-20-rv64-v8l-global-producer-no-live-reuse/mutate-v8l-global-lease.py
command_rc=0
cleanup_rc=0
finalized=0

case $(realpath -m "${runtime}") in
  "${repo_root}/.github/runtime-artifacts/"*) ;;
  *) exit 2 ;;
esac
if [[ -e ${evidence} || -e ${status_path} || -e ${runtime} ]]; then
  printf '%s\n' '[RV64-V8L-CURRENT][FAIL] output already exists' >&2
  exit 2
fi
mkdir -p "${evidence}/baselines" "${evidence}/mutations" "${runtime}"
source "${repo_root}/scripts/task-run-status.sh"
task_run_status_init "${status_path}"
task_run_status_install_signal_traps

cleanup_runtime() {
  case $(realpath -m "${runtime}") in
    "${repo_root}/.github/runtime-artifacts/"*)
      rm -rf -- "${runtime}" || cleanup_rc=$?
      ;;
    *) cleanup_rc=1 ;;
  esac
}

finalize_on_exit() {
  local exit_rc=$?
  if [[ ${command_rc} -eq 0 && ${exit_rc} -ne 0 ]]; then
    command_rc=${exit_rc}
  fi
  cleanup_runtime
  if [[ ${finalized} -eq 0 ]]; then
    task_run_status_stage exit-trap
    task_run_status_finalize "${command_rc}" "${cleanup_rc}" || true
  fi
}
trap finalize_on_exit EXIT

base_flags='-g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DV8L_GLOBAL_LEASE_FOCUSED'

run_make() {
  local result_dir=$1
  local build_dir=$2
  local test_name=$3
  local flags=$4
  local override_name=${5:-}
  local override_value=${6:-}
  local make_log=${result_dir}/make.log
  local -a override=()
  mkdir -p "${result_dir}" "${build_dir}"
  if [[ -n ${override_name} ]]; then
    override+=("${override_name}=${override_value}")
  fi
  set +e
  make -B -C "${tb_home}" -j1 TESTS="${test_name}" EXTRA_TESTS= \
    BUILD_DIR="${build_dir}" RESULT_DIR="${result_dir}" IVFLAGS="${flags}" \
    "${override[@]}" run >"${make_log}" 2>&1
  local rc=$?
  set -e
  printf '[MAKE-RC] %d\n' "${rc}" >>"${make_log}"
  return "${rc}"
}

task_run_status_stage baseline-current
for unit in dispatch backend; do
  for mode in assert release; do
    flags=${base_flags}
    test_name=tb_ooo_int_backend
    if [[ ${unit} == dispatch ]]; then
      flags="${flags} -DOOO_PRODUCER_GEN_W=1"
      test_name=tb_ooo_dispatch_backend
    fi
    if [[ ${mode} == assert ]]; then
      flags="${flags} -DOOO_ASSERT"
    fi
    result_dir=${evidence}/baselines/${unit}-${mode}
    build_dir=${runtime}/baseline-${unit}-${mode}
    run_make "${result_dir}" "${build_dir}" "${test_name}" "${flags}" || command_rc=$?
    if [[ ${command_rc} -ne 0 ]]; then break 2; fi
    grep -Fq '[RESULT] PASS' "${result_dir}/logs/${test_name}.log" || { command_rc=1; break 2; }
  done
done

run_mutation() {
  local external_name=$1
  local mutator_name=$2
  local source=$3
  local target_file=$4
  local test_name=$5
  local override_name=$6
  local override_prefix=${7:-}
  local marker=$8
  local result_dir=${evidence}/mutations/${external_name}
  local build_dir=${runtime}/${external_name}
  local mutant=${result_dir}/${target_file}
  local override_value=${mutant}
  mkdir -p "${result_dir}"
  python3 -B "${mutator}" "${mutator_name}" "${source}" "${mutant}" \
    >"${result_dir}/mutator.log" 2>&1 || return $?
  if [[ -n ${override_prefix} ]]; then
    override_value="${override_prefix} ${mutant}"
  fi
  if run_make "${result_dir}" "${build_dir}" "${test_name}" \
      "${base_flags} -DOOO_PRODUCER_GEN_W=1" "${override_name}" "${override_value}"; then
    return 1
  fi
  [[ -s ${build_dir}/${test_name}.vvp ]] || return 1
  grep -Fq "${marker}" "${result_dir}/logs/${test_name}.log" || return 1
  grep -Fq '[RESULT] FAIL' "${result_dir}/logs/${test_name}.log" || return 1
}

if [[ ${command_rc} -eq 0 ]]; then
  task_run_status_stage mutation-current
  iq=${repo_root}/npc/rv64/vsrc/scheduling/OooIntIssueQueue.v
  iq_select=${repo_root}/npc/rv64/vsrc/scheduling/OooIntIssueSelect8.v
  dispatch=${repo_root}/npc/rv64/vsrc/rename_allocate/OooDispatchBackend.v
  backend=${repo_root}/npc/rv64/vsrc/execute/OooIntBackend.v
  run_mutation dispatch-drop-int-iq-union dispatch_drop_int_iq_union "${dispatch}" OooDispatchBackend.v tb_ooo_dispatch_backend RTL_OOO_DISPATCH_BACKEND '' 'FAIL v8l complete mask differs from independent raw IQ scan' || command_rc=$?
  [[ ${command_rc} -ne 0 ]] || run_mutation dispatch-lane0-raw-index dispatch_lane0_raw_index "${dispatch}" OooDispatchBackend.v tb_ooo_dispatch_backend RTL_OOO_DISPATCH_BACKEND '' '[CHECK-FAIL] v8g lane0 live PID stalls dispatch0' || command_rc=$?
  [[ ${command_rc} -ne 0 ]] || run_mutation int-iq-fire-dies-early int_iq_fire_dies_early "${iq}" OooIntIssueQueue.v tb_ooo_dispatch_backend RTL_OOO_INT_ISSUE_QUEUE "${iq_select}" '[CHECK-FAIL] v8l resident IQ P blocks exact candidate' || command_rc=$?
  [[ ${command_rc} -ne 0 ]] || run_mutation backend-drop-mem-res-holder backend_drop_mem_res_holder "${backend}" OooIntBackend.v tb_ooo_int_backend RTL_OOO_INT_BACKEND '' '[CHECK-FAIL] v8l memory reservation reaches complete mask' || command_rc=$?
  [[ ${command_rc} -ne 0 ]] || run_mutation backend-drop-ex0-holder backend_drop_ex0_holder "${backend}" OooIntBackend.v tb_ooo_int_backend RTL_OOO_INT_BACKEND '' '[CHECK-FAIL] v8l EX0 handoff keeps complete lease' || command_rc=$?
  [[ ${command_rc} -ne 0 ]] || run_mutation backend-drop-ex1-holder backend_drop_ex1_holder "${backend}" OooIntBackend.v tb_ooo_int_backend RTL_OOO_INT_BACKEND '' '[CHECK-FAIL] v8l EX1 reaches complete mask' || command_rc=$?
  [[ ${command_rc} -ne 0 ]] || run_mutation backend-drop-branch-holder backend_drop_branch_holder "${backend}" OooIntBackend.v tb_ooo_int_backend RTL_OOO_INT_BACKEND '' '[CHECK-FAIL] v8l branch packet reaches complete mask' || command_rc=$?
  [[ ${command_rc} -ne 0 ]] || run_mutation backend-capture-ignores-tracker-ready backend_capture_ignores_tracker_ready "${backend}" OooIntBackend.v tb_ooo_int_backend RTL_OOO_INT_BACKEND '' '[CHECK-FAIL] v8l tracker-backpressure blocks capture' || command_rc=$?
  [[ ${command_rc} -ne 0 ]] || run_mutation backend-iq-pop-ignores-tracker-ready backend_iq_pop_ignores_tracker_ready "${backend}" OooIntBackend.v tb_ooo_int_backend RTL_OOO_INT_BACKEND '' '[CHECK-FAIL] v8l tracker-backpressure blocks IQ pop' || command_rc=$?
fi

if [[ ${command_rc} -eq 0 ]]; then
  task_run_status_stage summary
  python3 -B "${run_dir}/build-v8l-current-summary.py" \
    --root "${repo_root}" --evidence "${evidence}" --runtime "${runtime}" \
    --output "${evidence}/summary.json" \
    >"${evidence}/summary.log" 2>&1 || command_rc=$?
fi

if [[ ${command_rc} -eq 0 ]]; then
  task_run_status_stage evidence-complete
  task_run_status_mark_evidence_complete
fi
cleanup_runtime
task_run_status_finalize "${command_rc}" "${cleanup_rc}" || command_rc=$?
finalized=1
if [[ ${command_rc} -eq 0 ]]; then
  printf '%s\n' '[RV64-V8L-CURRENT][PASS] baselines=4/4 mutations=9/9 compiled-images=0'
fi
exit "${command_rc}"
