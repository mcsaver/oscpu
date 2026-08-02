#!/usr/bin/env bash

set -euo pipefail
export PYTHONDONTWRITEBYTECODE=1

repo_root=/home/lyg/PA/ysyx-workbench
run_dir="${repo_root}/.github/task-runs/2026-08-02-rv64-v14d-p1-direct-current-rebind-v1"
evidence="${run_dir}/evidence/control-run-1"
status_path="${run_dir}/control-run-1.status"
snapshot_tool="${repo_root}/npc/rv64/eval/ppa/tools/control_event_sq_retry_evidence.py"
v9o_mutation_runner="${repo_root}/.github/task-runs/2026-07-23-rv64-v9o-control-event-current-design/run-control-event-rtl-mutations.py"
tb_dir="${repo_root}/npc/rv64/testbench"
temp_dir="$(mktemp -d /tmp/rv64-v14d-control.XXXXXXXX)"
finalized=0
cleaned=0
cleanup_rc=0

if [[ -e "${evidence}" || -e "${status_path}" ]]; then
  printf '%s\n' '[V14D-CONTROL-EVENT][FAIL] output already exists' >&2
  exit 2
fi
mkdir -p "${evidence}"
source "${repo_root}/scripts/task-run-status.sh"
task_run_status_init "${status_path}"
task_run_status_install_signal_traps

cleanup_temp() {
  if [[ "${cleaned}" -eq 1 ]]; then
    return
  fi
  case "${temp_dir}" in
    /tmp/rv64-v14d-control.*) rm -rf -- "${temp_dir}" || cleanup_rc=$? ;;
    *) printf '%s\n' "[V14D-CONTROL-EVENT][FAIL] unsafe temp path ${temp_dir}" >&2; cleanup_rc=1 ;;
  esac
  cleaned=1
}

finalize_on_exit() {
  local command_rc=$?
  cleanup_temp
  if [[ "${finalized}" -eq 0 ]]; then
    task_run_status_stage "exit-trap"
    task_run_status_finalize "${command_rc}" "${cleanup_rc}" || true
  fi
}
trap finalize_on_exit EXIT

cd "${repo_root}"
task_run_status_stage "source-binding-pre"
sha256sum \
  npc/rv64/eval/ppa/evidence/architecture-current.json \
  npc/rv64/design/arch/architecture-debt-ledger.json \
  npc/rv64/design/arch/historical-defect-backfill-ledger.json \
  > "${evidence}/canonical-before.sha256"
python3 -B "${snapshot_tool}" --root "${repo_root}" snapshot \
  --output "${evidence}/source-before.json"
design_id="$(python3 -B -c 'import json,sys; print(json.load(open(sys.argv[1]))["design_id"].removeprefix("sha256:"))' "${evidence}/source-before.json")"

task_run_status_stage "v9o-positive-focused"
focused_tests='tb_ooo_control_event_apply_sequencer tb_ooo_redirect_arbiter tb_ooo_frontend_action_gate tb_ooo_load_queue tb_ooo_rob tb_ooo_dispatch_backend tb_ooo_int_backend tb_ooo_mem_axi_bridge tb_ooo_dual_mem_bridge_wrapper tb_ooo_core_top_glue'
make -B -C "${tb_dir}" \
  TESTS="${focused_tests}" EXTRA_TESTS= \
  BUILD_DIR="${temp_dir}/v9o-focused-build" \
  RESULT_DIR="${temp_dir}/v9o-focused-result" \
  RTL_EVIDENCE_SHA="${design_id}" run \
  > "${evidence}/v9o-focused.driver.log" 2>&1
mkdir -p "${evidence}/v9o-focused/logs"
for test_name in ${focused_tests}; do
  test -s "${temp_dir}/v9o-focused-build/${test_name}.vvp"
  python3 -B "${snapshot_tool}" --root "${repo_root}" normalize-log \
    --input "${temp_dir}/v9o-focused-result/logs/${test_name}.log" \
    --output "${evidence}/v9o-focused/logs/${test_name}.log" \
    --temp-root "${temp_dir}"
done

task_run_status_stage "v9o-positive-config"
config_tests='tb_ooo_rob tb_ooo_core_top_glue_v9o_csr_qh tb_ooo_core_top_glue'
ivflags="-g2012 -Wall -I${repo_root}/npc/rv64/vsrc -I${repo_root}/npc/rv64/vsrc/include -I${tb_dir}/common -DOOO_ASSERT -DOOO_CSR_QUEUE_HEAD=1"
make -B -C "${tb_dir}" \
  TESTS="${config_tests}" EXTRA_TESTS= \
  BUILD_DIR="${temp_dir}/v9o-config-build" \
  RESULT_DIR="${temp_dir}/v9o-config-result" \
  IVFLAGS="${ivflags}" RTL_EVIDENCE_SHA="${design_id}" run \
  > "${evidence}/v9o-config.driver.log" 2>&1
mkdir -p "${evidence}/v9o-config/logs"
for test_name in ${config_tests}; do
  test -s "${temp_dir}/v9o-config-build/${test_name}.vvp"
  python3 -B "${snapshot_tool}" --root "${repo_root}" normalize-log \
    --input "${temp_dir}/v9o-config-result/logs/${test_name}.log" \
    --output "${evidence}/v9o-config/logs/${test_name}.log" \
    --temp-root "${temp_dir}"
done

task_run_status_stage "v9o-compile-success-mutations"
python3 -B "${v9o_mutation_runner}" --root "${repo_root}" \
  --output "${evidence}/v9o-mutations/summary.json" \
  > "${evidence}/v9o-mutations.driver.log" 2>&1

task_run_status_stage "v9r-positive"
v9r_tests='tb_ooo_int_backend_v9r_sq_retry_c0 tb_ooo_mem_axi_bridge_v9r_sq_retry_c0 tb_ooo_int_backend_v11l_memory_retry_holder'
make -B -C "${tb_dir}" \
  TESTS="${v9r_tests}" EXTRA_TESTS= \
  BUILD_DIR="${temp_dir}/v9r-baseline-build" \
  RESULT_DIR="${temp_dir}/v9r-baseline-result" \
  RTL_EVIDENCE_SHA="${design_id}" run \
  > "${evidence}/v9r-baseline.driver.log" 2>&1
mkdir -p "${evidence}/v9r-baseline/logs"
for test_name in ${v9r_tests}; do
  test -s "${temp_dir}/v9r-baseline-build/${test_name}.vvp"
  python3 -B "${snapshot_tool}" --root "${repo_root}" normalize-log \
    --input "${temp_dir}/v9r-baseline-result/logs/${test_name}.log" \
    --output "${evidence}/v9r-baseline/logs/${test_name}.log" \
    --temp-root "${temp_dir}"
done

run_v9r_variant() {
  local case_name="$1"
  local test_name="$2"
  local rtl_variable="$3"
  local rtl_name="$4"
  local variant_dir="${evidence}/v9r-mutations/${case_name}"
  local variant_rtl="${temp_dir}/v9r-mutations/${case_name}/${rtl_name}"
  local result_dir="${temp_dir}/${case_name}-result"
  local build_dir="${temp_dir}/${case_name}-build"
  local variant_sha
  local rc

  mkdir -p "${variant_dir}/logs" "$(dirname "${variant_rtl}")"
  python3 -B "${snapshot_tool}" --root "${repo_root}" mutate \
    --case "${case_name}" --output "${variant_rtl}"
  variant_sha="$(sha256sum "${variant_rtl}" | cut -d ' ' -f 1)"
  set +e
  make -B -C "${tb_dir}" \
    TESTS="${test_name}" EXTRA_TESTS= \
    "${rtl_variable}=${variant_rtl}" \
    BUILD_DIR="${build_dir}" RESULT_DIR="${result_dir}" \
    RTL_EVIDENCE_SHA="${design_id}" run \
    > "${variant_dir}/driver.log" 2>&1
  rc=$?
  set -e
  test "${rc}" -eq 2
  test -s "${build_dir}/${test_name}.vvp"
  python3 -B "${snapshot_tool}" --root "${repo_root}" normalize-log \
    --input "${result_dir}/logs/${test_name}.log" \
    --output "${variant_dir}/logs/${test_name}.log" \
    --temp-root "${temp_dir}"
  printf 'REJECTED_COMPILE_SUCCESS_VARIANT rc=2 variant_sha256=%s TRANSIENT_COMPILED_IMAGE=1\n' \
    "${variant_sha}" > "${variant_dir}/status"
}

task_run_status_stage "v9r-compile-success-mutations"
run_v9r_variant backend-bank0-ready-open tb_ooo_int_backend_v9r_sq_retry_c0 RTL_OOO_INT_BACKEND OooIntBackend.v
run_v9r_variant backend-bank1-ready-open tb_ooo_int_backend_v9r_sq_retry_c0 RTL_OOO_INT_BACKEND OooIntBackend.v
run_v9r_variant bridge-retry-fire-open tb_ooo_mem_axi_bridge_v9r_sq_retry_c0 RTL_OOO_MEM_AXI_BRIDGE OooMemAxiBridge.v
run_v9r_variant backend-bank0-resident-fire-open tb_ooo_int_backend_v11l_memory_retry_holder RTL_OOO_INT_BACKEND OooIntBackend.v
run_v9r_variant backend-bank1-resident-fire-open tb_ooo_int_backend_v11l_memory_retry_holder RTL_OOO_INT_BACKEND OooIntBackend.v

task_run_status_stage "source-binding-post"
python3 -B "${snapshot_tool}" --root "${repo_root}" snapshot \
  --output "${evidence}/source-after.json"
cmp "${evidence}/source-before.json" "${evidence}/source-after.json"
sha256sum \
  npc/rv64/eval/ppa/evidence/architecture-current.json \
  npc/rv64/design/arch/architecture-debt-ledger.json \
  npc/rv64/design/arch/historical-defect-backfill-ledger.json \
  > "${evidence}/canonical-after.sha256"
cmp "${evidence}/canonical-before.sha256" "${evidence}/canonical-after.sha256"

task_run_status_stage "summary-audit"
python3 -B "${run_dir}/build-control-summary.py" \
  --evidence "${evidence}" --output "${evidence}/summary.json" \
  > "${evidence}/summary.driver.log" 2>&1

cleanup_temp
task_run_status_stage "evidence-complete"
if [[ "${cleanup_rc}" -eq 0 && -s "${evidence}/summary.json" ]]; then
  task_run_status_mark_evidence_complete
fi
finalized=1
task_run_status_finalize 0 "${cleanup_rc}"
