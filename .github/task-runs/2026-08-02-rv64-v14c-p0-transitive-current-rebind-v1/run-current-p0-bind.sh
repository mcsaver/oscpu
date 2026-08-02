#!/usr/bin/env bash

set -uo pipefail

repo_root=/home/lyg/PA/ysyx-workbench
run_dir="${repo_root}/.github/task-runs/2026-08-02-rv64-v14c-p0-transitive-current-rebind-v1"
evidence_dir="${run_dir}/evidence/current-bind-1"
status_path="${run_dir}/current-bind-1.status"
driver_log="${evidence_dir}/driver.log"
positive_dir="${evidence_dir}/dynamic/positive"
mutation_dir="${evidence_dir}/dynamic/mutations"
result_dir="${evidence_dir}/results"
raw_dir="${evidence_dir}/raw"
module_summary="${repo_root}/.github/task-runs/2026-08-02-rv64-v14b-architecture-current-freeze-audit-v1/evidence/p0-direct-rebind-1/module-aggregate/summary.txt"
temp_dir=
finalized=0
cleanup_rc=0

fdg_runner="${repo_root}/.github/task-runs/2026-07-21-rv64-v9d-fdg-arch-trap/run-fdg-mutations.py"
xret_runner="${repo_root}/.github/task-runs/2026-07-21-rv64-v9e-xret-current-design/run-xret-mutations.py"
access_runner="${repo_root}/.github/task-runs/2026-07-22-rv64-v9i-ifu-access-current-design/run-ifu-access-variants.py"
tval_runner="${repo_root}/.github/task-runs/2026-07-22-rv64-v9j-ifu-tval-current-design/run-ifu-tval-variants.py"
instret_runner="${repo_root}/.github/task-runs/2026-07-21-rv64-v9c-instret-retirement/run-instret-mutations.py"

v9g_dir="${repo_root}/.github/task-runs/2026-07-22-rv64-v9g-ifu-axi-current-design/evidence"
v9h_dir="${repo_root}/.github/task-runs/2026-07-22-rv64-v9h-ifu-fetch-provenance-current-design/evidence"

if [[ -e "${evidence_dir}" || -e "${status_path}" ]]; then
  printf '%s\n' "[V14C-P0-CURRENT-BIND][FAIL] output already exists" >&2
  exit 2
fi
mkdir -p "${evidence_dir}"
exec > >(tee -a "${driver_log}") 2>&1

source "${repo_root}/scripts/task-run-status.sh"
source "${run_dir}/driver-lib.sh"
task_run_status_init "${status_path}"
task_run_status_install_signal_traps

cleanup_owned_temp() {
  local resolved
  [[ -n "${temp_dir}" && -e "${temp_dir}" ]] || return 0
  resolved=$(realpath -m -- "${temp_dir}") || return 1
  if [[ "${resolved}" != /tmp/rv64-v14c-p0-transitive.* ]]; then
    printf '%s\n' "refusing unexpected RV64 compile cleanup target: ${resolved}" >&2
    return 2
  fi
  rm -rf -- "${resolved}"
}

finalize_on_exit() {
  local command_rc=$?
  cleanup_owned_temp || cleanup_rc=$?
  if [[ "${finalized}" -eq 0 ]]; then
    task_run_status_stage "exit-trap"
    task_run_status_finalize "${command_rc}" "${cleanup_rc}" || true
  fi
}
trap finalize_on_exit EXIT

run_logged() { v14c_run_logged "$@"; }

main() {
  temp_dir=$(mktemp -d /tmp/rv64-v14c-p0-transitive.XXXXXXXX) || return $?
  mkdir -p \
    "${positive_dir}" \
    "${mutation_dir}/fdg" \
    "${mutation_dir}/xret" \
    "${mutation_dir}/ifu-access" \
    "${mutation_dir}/ifu-tval" \
    "${mutation_dir}/instret" \
    "${result_dir}" \
    "${raw_dir}"

  local tests
  tests="tb_ooo_fp_legality_dispatch_path tb_ooo_priv_system"
  tests+=" tb_ooo_fetch_head_classify_gate"
  tests+=" tb_ooo_fetch_access_footprint tb_ooo_fetch_axi_access_attrs"
  tests+=" tb_ooo_ifu_lane1_fault_owner tb_axi_exec_firewall"
  tests+=" tb_ooo_fetch_packet_decode tb_ooo_fetch_page_end_fault"
  tests+=" tb_ooo_fetch_packet_fifo tb_ooo_pending_lane1_capture_gate"
  tests+=" tb_ooo_pending_dispatch_arbiter"
  tests+=" tb_ooo_pending_trap_exit_sequencer tb_ooo_csr_trap_request_mux"
  tests+=" tb_ooo_sv39_boot tb_ooo_commit_output_mux"
  tests+=" tb_ooo_alu_core_slice tb_csr_file"

  run_logged "dynamic-positive-rtl" "${evidence_dir}/positive-driver.log" \
    make -B -C "${repo_root}/npc/rv64/testbench" \
      "TESTS=${tests}" \
      "RESULT_DIR=${positive_dir}" \
      "BUILD_DIR=${temp_dir}/positive-build" run || return $?

  task_run_status_stage "dynamic-sized-dpi"
  if AXI_DPI_SIZED_BUILD_DIR="${temp_dir}/axi-dpi-sized" \
    make -B -C "${repo_root}/npc/rv64/testbench" \
      "BUILD_DIR=${temp_dir}" axi-dpi-sized \
      >"${positive_dir}/axi-dpi-sized.log" 2>&1; then
    printf '%s\n' "[V14C-P0-CURRENT-BIND] stage=dynamic-sized-dpi status=PASS"
  else
    local rc=$?
    tail -n 80 "${positive_dir}/axi-dpi-sized.log" >&2 || true
    return "${rc}"
  fi

  run_logged "normalize-positive-logs" \
    "${evidence_dir}/normalize-positive.log" \
    python3 -B "${run_dir}/normalize-current-logs.py" \
      --log-dir "${positive_dir}/logs" \
      --transient-dir "${temp_dir}" || return $?
  run_logged "normalize-sized-dpi-log" \
    "${evidence_dir}/normalize-sized-dpi.log" \
    python3 -B "${run_dir}/normalize-current-logs.py" \
      --log "${positive_dir}/axi-dpi-sized.log" \
      --transient-dir "${temp_dir}" || return $?

  run_logged "fdg-rtl-counterexamples" "${evidence_dir}/fdg-mutations.log" \
    python3 -B "${fdg_runner}" --root "${repo_root}" \
      --output "${mutation_dir}/fdg/summary.json" || return $?
  run_logged "xret-rtl-counterexamples" "${evidence_dir}/xret-mutations.log" \
    python3 -B "${xret_runner}" --root "${repo_root}" \
      --output "${mutation_dir}/xret/summary.json" || return $?
  run_logged "ifu-access-rtl-counterexamples" \
    "${evidence_dir}/ifu-access-mutations.log" \
    python3 -B "${access_runner}" --root "${repo_root}" \
      --output "${mutation_dir}/ifu-access/summary.json" || return $?
  run_logged "ifu-tval-rtl-counterexamples" \
    "${evidence_dir}/ifu-tval-mutations.log" \
    python3 -B "${tval_runner}" --root "${repo_root}" \
      --output "${mutation_dir}/ifu-tval/summary.json" || return $?
  run_logged "instret-rtl-counterexamples" \
    "${evidence_dir}/instret-mutations.log" \
    python3 -B "${instret_runner}" --root "${repo_root}" \
      --output "${mutation_dir}/instret/summary.json" || return $?

  run_logged "fdg-current-evidence" "${evidence_dir}/fdg-evidence-driver.log" \
    python3 -B "${repo_root}/npc/rv64/eval/ppa/tools/fdg_arch_trap_evidence.py" \
      --root "${repo_root}" \
      --focused-log "${positive_dir}/logs/tb_ooo_fp_legality_dispatch_path.log" \
      --program-log "${positive_dir}/logs/tb_ooo_priv_system.log" \
      --module-summary "${module_summary}" \
      --mutation-summary "${mutation_dir}/fdg/summary.json" \
      --output "${result_dir}/fdg-current.json" \
      --raw-log "${raw_dir}/fdg.log" || return $?

  run_logged "xret-current-evidence" "${evidence_dir}/xret-evidence-driver.log" \
    python3 -B "${repo_root}/npc/rv64/eval/ppa/tools/xret_current_mode_evidence.py" \
      --root "${repo_root}" \
      --focused-log "${positive_dir}/logs/tb_ooo_fetch_head_classify_gate.log" \
      --program-log "${positive_dir}/logs/tb_ooo_priv_system.log" \
      --module-summary "${module_summary}" \
      --mutation-summary "${mutation_dir}/xret/summary.json" \
      --output "${result_dir}/xret-current.json" \
      --raw-log "${raw_dir}/xret.log" || return $?

  run_logged "ifu-access-current-evidence" \
    "${evidence_dir}/ifu-access-evidence-driver.log" \
    python3 -B "${repo_root}/npc/rv64/eval/ppa/tools/ifu_access_evidence.py" \
      --root "${repo_root}" \
      --footprint-log "${positive_dir}/logs/tb_ooo_fetch_access_footprint.log" \
      --attrs-log "${positive_dir}/logs/tb_ooo_fetch_axi_access_attrs.log" \
      --firewall-log "${positive_dir}/logs/tb_axi_exec_firewall.log" \
      --lane-log "${positive_dir}/logs/tb_ooo_ifu_lane1_fault_owner.log" \
      --dpi-log "${positive_dir}/axi-dpi-sized.log" \
      --module-summary "${module_summary}" \
      --variant-summary "${mutation_dir}/ifu-access/summary.json" \
      --output "${result_dir}/ifu-access-current.json" \
      --raw-log "${raw_dir}/ifu-access.log" || return $?

  run_logged "ifu-tval-current-evidence" \
    "${evidence_dir}/ifu-tval-evidence-driver.log" \
    python3 -B "${repo_root}/npc/rv64/eval/ppa/tools/ifu_tval_evidence.py" \
      --root "${repo_root}" \
      --decoder-log "${positive_dir}/logs/tb_ooo_fetch_packet_decode.log" \
      --page-end-log "${positive_dir}/logs/tb_ooo_fetch_page_end_fault.log" \
      --fifo-log "${positive_dir}/logs/tb_ooo_fetch_packet_fifo.log" \
      --capture-log "${positive_dir}/logs/tb_ooo_pending_lane1_capture_gate.log" \
      --arbiter-log "${positive_dir}/logs/tb_ooo_pending_dispatch_arbiter.log" \
      --pending-log "${positive_dir}/logs/tb_ooo_pending_trap_exit_sequencer.log" \
      --csr-log "${positive_dir}/logs/tb_ooo_csr_trap_request_mux.log" \
      --lifecycle-log "${positive_dir}/logs/tb_ooo_ifu_lane1_fault_owner.log" \
      --module-summary "${module_summary}" \
      --variant-summary "${mutation_dir}/ifu-tval/summary.json" \
      --output "${result_dir}/ifu-tval-current.json" \
      --raw-log "${raw_dir}/ifu-tval.log" || return $?

  run_logged "instret-current-evidence" \
    "${evidence_dir}/instret-evidence-driver.log" \
    python3 -B "${repo_root}/npc/rv64/eval/ppa/tools/instret_retirement_evidence.py" \
      --root "${repo_root}" \
      --program-log "${positive_dir}/logs/tb_ooo_sv39_boot.log" \
      --commit-output-mux-log "${positive_dir}/logs/tb_ooo_commit_output_mux.log" \
      --alu-core-slice-log "${positive_dir}/logs/tb_ooo_alu_core_slice.log" \
      --csr-file-log "${positive_dir}/logs/tb_csr_file.log" \
      --module-summary "${module_summary}" \
      --mutation-summary "${mutation_dir}/instret/summary.json" \
      --output "${result_dir}/instret-current.json" \
      --raw-log "${raw_dir}/instret.log" || return $?

  run_logged "ifu-axi-frozen-execution-replay" \
    "${evidence_dir}/ifu-axi-replay-driver.log" \
    python3 -B "${repo_root}/npc/rv64/eval/ppa/tools/ifu_axi_flush_drain_evidence.py" \
      --root "${repo_root}" \
      --bridge-log "${v9g_dir}/focused/logs/tb_ooo_fetch_axi_bridge.log" \
      --xbar-log "${v9g_dir}/focused/logs/tb_ooo_fetch_axi_bridge_xbar.log" \
      --generic-xbar-log "${v9g_dir}/focused/logs/tb_axi_xbar.log" \
      --module-summary "${module_summary}" \
      --variant-summary "${v9g_dir}/mutations/summary.json" \
      --output "${result_dir}/ifu-axi-current.json" \
      --raw-log "${raw_dir}/ifu-axi.log" || return $?

  run_logged "ifu-fetch-frozen-execution-replay" \
    "${evidence_dir}/ifu-fetch-replay-driver.log" \
    python3 -B "${repo_root}/npc/rv64/eval/ppa/tools/ifu_fetch_provenance_evidence.py" \
      --root "${repo_root}" \
      --decode-log "${v9h_dir}/focused/logs/tb_ooo_fetch_packet_decode.log" \
      --page-log "${v9h_dir}/focused/logs/tb_ooo_fetch_page_end_fault.log" \
      --module-summary "${module_summary}" \
      --variant-summary "${v9h_dir}/mutations/summary.json" \
      --output "${result_dir}/ifu-fetch-current.json" \
      --raw-log "${raw_dir}/ifu-fetch.log" || return $?

  run_logged "post-rtl-source-identity" \
    "${evidence_dir}/source-post-checker.log" \
    python3 -B "${repo_root}/npc/rv64/eval/ppa/tools/architecture_hard_gates.py" \
      --repo-root "${repo_root}" \
      --evidence-manifest "${repo_root}/.github/task-runs/2026-08-02-rv64-v14b-architecture-current-freeze-audit-v1/evidence/replay-1/current-directed-nine-gate-replay.json" \
      --output "${evidence_dir}/source-post-result.json" || return $?

  run_logged "current-p0-receipt" "${evidence_dir}/receipt-driver.log" \
    python3 -B "${run_dir}/build-current-p0-receipt.py" \
      --evidence-dir "${evidence_dir}" \
      --output "${evidence_dir}/receipt.json" || return $?
  return 0
}

main
command_rc=$?
task_run_status_stage "cleanup-rtl-build-products"
cleanup_owned_temp || cleanup_rc=$?
if [[ -n "${temp_dir}" && -e "${temp_dir}" ]]; then
  cleanup_rc=1
fi

task_run_status_stage "evidence-complete"
if [[ "${command_rc}" -eq 0 && "${cleanup_rc}" -eq 0 && \
      -s "${evidence_dir}/receipt.json" ]]; then
  task_run_status_mark_evidence_complete
fi
finalized=1
task_run_status_finalize "${command_rc}" "${cleanup_rc}"
