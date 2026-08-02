#!/usr/bin/env bash

set -euo pipefail
export PYTHONDONTWRITEBYTECODE=1

repo_root=/home/lyg/PA/ysyx-workbench
run_dir="${repo_root}/.github/task-runs/2026-08-02-rv64-v14d-p1-direct-current-rebind-v1"
evidence="${run_dir}/evidence/store-run-1"
status_path="${run_dir}/store-run-1.status"
snapshot_tool="${repo_root}/npc/rv64/eval/ppa/tools/control_event_sq_retry_evidence.py"
owner_builder="${repo_root}/npc/rv64/eval/ppa/tools/irrevocable_owner_residency_evidence.py"
v9n_runner="${repo_root}/.github/task-runs/2026-07-23-rv64-v9n-irrevocable-write-owner-residency/run-owner-residency-rtl-variants.py"
tb_dir="${repo_root}/npc/rv64/testbench"
temp_dir=
finalized=0
cleaned=0
cleanup_rc=0

if [[ -e "${evidence}" || -e "${status_path}" ]]; then
  printf '%s\n' '[V14D-STORE-BRESP][FAIL] output already exists' >&2
  exit 2
fi
mkdir -p "${evidence}"
temp_dir="$(mktemp -d /tmp/rv64-v14d-store.XXXXXXXX)"
source "${repo_root}/scripts/task-run-status.sh"
task_run_status_init "${status_path}"
task_run_status_install_signal_traps

cleanup_temp() {
  if [[ "${cleaned}" -eq 1 ]]; then
    return
  fi
  case "${temp_dir}" in
    /tmp/rv64-v14d-store.*) rm -rf -- "${temp_dir}" || cleanup_rc=$? ;;
    *) printf '%s\n' "[V14D-STORE-BRESP][FAIL] unsafe temp path ${temp_dir}" >&2; cleanup_rc=1 ;;
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

task_run_status_stage "v9n-owner-positive"
v9n_tests='tb_v9n_sq_owner_residency tb_v9n_amo_owner_residency'
make -B -C "${tb_dir}" \
  TESTS="${v9n_tests}" EXTRA_TESTS= \
  BUILD_DIR="${temp_dir}/v9n-focused-build" \
  RESULT_DIR="${temp_dir}/v9n-focused-result" \
  RTL_EVIDENCE_SHA="${design_id}" run \
  > "${evidence}/v9n-focused.driver.log" 2>&1
mkdir -p "${evidence}/v9n-focused/logs"
for test_name in ${v9n_tests}; do
  test -s "${temp_dir}/v9n-focused-build/${test_name}.vvp"
  python3 -B "${snapshot_tool}" --root "${repo_root}" normalize-log \
    --input "${temp_dir}/v9n-focused-result/logs/${test_name}.log" \
    --output "${evidence}/v9n-focused/logs/${test_name}.log" \
    --temp-root "${temp_dir}"
done

task_run_status_stage "v9n-owner-mutations"
python3 -B "${v9n_runner}" --root "${repo_root}" \
  --output "${evidence}/v9n-mutations/summary.json" \
  > "${evidence}/v9n-mutations.driver.log" 2>&1

task_run_status_stage "v9n-owner-receipt"
python3 -B "${owner_builder}" --root "${repo_root}" \
  --store-log "${evidence}/v9n-focused/logs/tb_v9n_sq_owner_residency.log" \
  --amo-log "${evidence}/v9n-focused/logs/tb_v9n_amo_owner_residency.log" \
  --variant-summary "${evidence}/v9n-mutations/summary.json" \
  --output "${evidence}/v9n-owner/receipt.json" \
  --raw-log "${evidence}/v9n-owner/receipt.log" \
  > "${evidence}/v9n-owner.driver.log" 2>&1

task_run_status_stage "v13r-holder-positive"
v13r_tests='tb_ooo_mem_axi_bridge_v13r_store_b_multicycle_hold tb_ooo_int_backend_v13r_store_b_multicycle_retire_hold'
make -B -C "${tb_dir}" \
  TESTS="${v13r_tests}" EXTRA_TESTS= \
  BUILD_DIR="${temp_dir}/v13r-focused-build" \
  RESULT_DIR="${temp_dir}/v13r-focused-result" \
  RTL_EVIDENCE_SHA="${design_id}" run \
  > "${evidence}/v13r-focused.driver.log" 2>&1
mkdir -p "${evidence}/v13r-focused/logs"
for test_name in ${v13r_tests}; do
  test -s "${temp_dir}/v13r-focused-build/${test_name}.vvp"
  python3 -B "${snapshot_tool}" --root "${repo_root}" normalize-log \
    --input "${temp_dir}/v13r-focused-result/logs/${test_name}.log" \
    --output "${evidence}/v13r-focused/logs/${test_name}.log" \
    --temp-root "${temp_dir}"
done

task_run_status_stage "v13r-holder-mutations"
python3 -B "${run_dir}/run-v13r-store-mutations.py" \
  --root "${repo_root}" \
  --output "${evidence}/v13r-mutations/summary.json" \
  > "${evidence}/v13r-mutations.driver.log" 2>&1

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
python3 -B "${run_dir}/build-store-summary.py" \
  --evidence "${evidence}" --output "${evidence}/summary.json" \
  > "${evidence}/summary.driver.log" 2>&1

cleanup_temp
test ! -e "${temp_dir}"
if find "${run_dir}" -type f \( -name '*.vvp' -o -name '*.o' -o -name '*.pyc' \) -print -quit | grep -q .; then
  printf '%s\n' '[V14D-STORE-BRESP][FAIL] transient compiled product retained' >&2
  exit 3
fi
task_run_status_stage "evidence-complete"
if [[ "${cleanup_rc}" -eq 0 && -s "${evidence}/summary.json" ]]; then
  task_run_status_mark_evidence_complete
fi
finalized=1
task_run_status_finalize 0 "${cleanup_rc}"
