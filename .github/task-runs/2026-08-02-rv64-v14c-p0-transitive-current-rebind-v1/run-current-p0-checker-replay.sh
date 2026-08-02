#!/usr/bin/env bash

set -uo pipefail

repo_root=/home/lyg/PA/ysyx-workbench
run_dir="${repo_root}/.github/task-runs/2026-08-02-rv64-v14c-p0-transitive-current-rebind-v1"
source_evidence="${run_dir}/evidence/current-bind-1"
replay_dir="${run_dir}/evidence/current-bind-checker-replay-2"
status_path="${run_dir}/current-bind-checker-replay-2.status"
positive_dir="${replay_dir}/dynamic/positive"
result_dir="${replay_dir}/results"
raw_dir="${replay_dir}/raw"
module_summary="${repo_root}/.github/task-runs/2026-08-02-rv64-v14b-architecture-current-freeze-audit-v1/evidence/p0-direct-rebind-1/module-aggregate/summary.txt"
v9g_dir="${repo_root}/.github/task-runs/2026-07-22-rv64-v9g-ifu-axi-current-design/evidence"
v9h_dir="${repo_root}/.github/task-runs/2026-07-22-rv64-v9h-ifu-fetch-provenance-current-design/evidence"
finalized=0
cleanup_rc=0

if [[ -e "${replay_dir}" || -e "${status_path}" ]]; then
  printf '%s\n' "[V14C-P0-CHECKER-REPLAY][FAIL] output already exists" >&2
  exit 2
fi
mkdir -p "${replay_dir}"
exec > >(tee -a "${replay_dir}/driver.log") 2>&1

source "${repo_root}/scripts/task-run-status.sh"
source "${run_dir}/driver-lib.sh"
task_run_status_init "${status_path}"
task_run_status_install_signal_traps

run_logged() { v14c_run_logged "$@"; }

finalize_on_exit() {
  local command_rc=$?
  if [[ "${finalized}" -eq 0 ]]; then
    task_run_status_stage "exit-trap"
    task_run_status_finalize "${command_rc}" "${cleanup_rc}" || true
  fi
}
trap finalize_on_exit EXIT

copy_frozen_positive_inputs() {
  mkdir -p "${positive_dir}" "${result_dir}" "${raw_dir}"
  cp -a "${source_evidence}/dynamic/positive/logs" "${positive_dir}/logs"
  cp -a "${source_evidence}/dynamic/positive/summary.txt" \
    "${positive_dir}/summary.txt"
  cp -a "${source_evidence}/dynamic/positive/axi-dpi-sized.log" \
    "${positive_dir}/axi-dpi-sized.log"
}

main() {
  local transient_dir
  transient_dir=$(sed -nE \
    's@.*unexpected transient compile directory: (/tmp/rv64-v14c-p0-transitive\.[[:alnum:]]+).*@\1@p' \
    "${source_evidence}/normalize-positive.log" | head -n 1)
  if [[ "${transient_dir}" != /tmp/rv64-v14c-p0-transitive.* ]]; then
    printf '%s\n' "[V14C-P0-CHECKER-REPLAY][FAIL] source transient marker missing" >&2
    return 1
  fi

  run_logged "copy-frozen-positive-inputs" "${replay_dir}/copy-inputs.log" \
    copy_frozen_positive_inputs || return $?
  run_logged "normalize-positive-logs" "${replay_dir}/normalize-positive.log" \
    python3 -B "${run_dir}/normalize-current-logs.py" \
      --log-dir "${positive_dir}/logs" \
      --transient-dir "${transient_dir}" || return $?
  run_logged "normalize-sized-dpi-log" \
    "${replay_dir}/normalize-sized-dpi.log" \
    python3 -B "${run_dir}/normalize-current-logs.py" \
      --log "${positive_dir}/axi-dpi-sized.log" \
      --transient-dir "${transient_dir}" || return $?
  run_logged "driver-fail-closed-self-test" \
    "${replay_dir}/driver-self-test.log" \
    bash "${run_dir}/test-driver-lib.sh" || return $?

  run_logged "fdg-current-evidence" "${replay_dir}/fdg-evidence-driver.log" \
    python3 -B "${repo_root}/npc/rv64/eval/ppa/tools/fdg_arch_trap_evidence.py" \
      --root "${repo_root}" \
      --focused-log "${positive_dir}/logs/tb_ooo_fp_legality_dispatch_path.log" \
      --program-log "${positive_dir}/logs/tb_ooo_priv_system.log" \
      --module-summary "${module_summary}" \
      --mutation-summary "${source_evidence}/dynamic/mutations/fdg/summary.json" \
      --output "${result_dir}/fdg-current.json" \
      --raw-log "${raw_dir}/fdg.log" || return $?
  run_logged "xret-current-evidence" "${replay_dir}/xret-evidence-driver.log" \
    python3 -B "${repo_root}/npc/rv64/eval/ppa/tools/xret_current_mode_evidence.py" \
      --root "${repo_root}" \
      --focused-log "${positive_dir}/logs/tb_ooo_fetch_head_classify_gate.log" \
      --program-log "${positive_dir}/logs/tb_ooo_priv_system.log" \
      --module-summary "${module_summary}" \
      --mutation-summary "${source_evidence}/dynamic/mutations/xret/summary.json" \
      --output "${result_dir}/xret-current.json" \
      --raw-log "${raw_dir}/xret.log" || return $?
  run_logged "ifu-access-current-evidence" \
    "${replay_dir}/ifu-access-evidence-driver.log" \
    python3 -B "${repo_root}/npc/rv64/eval/ppa/tools/ifu_access_evidence.py" \
      --root "${repo_root}" \
      --footprint-log "${positive_dir}/logs/tb_ooo_fetch_access_footprint.log" \
      --attrs-log "${positive_dir}/logs/tb_ooo_fetch_axi_access_attrs.log" \
      --firewall-log "${positive_dir}/logs/tb_axi_exec_firewall.log" \
      --lane-log "${positive_dir}/logs/tb_ooo_ifu_lane1_fault_owner.log" \
      --dpi-log "${positive_dir}/axi-dpi-sized.log" \
      --module-summary "${module_summary}" \
      --variant-summary "${source_evidence}/dynamic/mutations/ifu-access/summary.json" \
      --output "${result_dir}/ifu-access-current.json" \
      --raw-log "${raw_dir}/ifu-access.log" || return $?
  run_logged "ifu-tval-current-evidence" \
    "${replay_dir}/ifu-tval-evidence-driver.log" \
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
      --variant-summary "${source_evidence}/dynamic/mutations/ifu-tval/summary.json" \
      --output "${result_dir}/ifu-tval-current.json" \
      --raw-log "${raw_dir}/ifu-tval.log" || return $?
  run_logged "instret-current-evidence" \
    "${replay_dir}/instret-evidence-driver.log" \
    python3 -B "${repo_root}/npc/rv64/eval/ppa/tools/instret_retirement_evidence.py" \
      --root "${repo_root}" \
      --program-log "${positive_dir}/logs/tb_ooo_sv39_boot.log" \
      --commit-output-mux-log "${positive_dir}/logs/tb_ooo_commit_output_mux.log" \
      --alu-core-slice-log "${positive_dir}/logs/tb_ooo_alu_core_slice.log" \
      --csr-file-log "${positive_dir}/logs/tb_csr_file.log" \
      --module-summary "${module_summary}" \
      --mutation-summary "${source_evidence}/dynamic/mutations/instret/summary.json" \
      --output "${result_dir}/instret-current.json" \
      --raw-log "${raw_dir}/instret.log" || return $?
  run_logged "ifu-axi-frozen-execution-replay" \
    "${replay_dir}/ifu-axi-replay-driver.log" \
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
    "${replay_dir}/ifu-fetch-replay-driver.log" \
    python3 -B "${repo_root}/npc/rv64/eval/ppa/tools/ifu_fetch_provenance_evidence.py" \
      --root "${repo_root}" \
      --decode-log "${v9h_dir}/focused/logs/tb_ooo_fetch_packet_decode.log" \
      --page-log "${v9h_dir}/focused/logs/tb_ooo_fetch_page_end_fault.log" \
      --module-summary "${module_summary}" \
      --variant-summary "${v9h_dir}/mutations/summary.json" \
      --output "${result_dir}/ifu-fetch-current.json" \
      --raw-log "${raw_dir}/ifu-fetch.log" || return $?

  run_logged "post-rtl-source-identity" \
    "${replay_dir}/source-post-checker.log" \
    python3 -B "${repo_root}/npc/rv64/eval/ppa/tools/architecture_hard_gates.py" \
      --repo-root "${repo_root}" \
      --evidence-manifest "${repo_root}/.github/task-runs/2026-08-02-rv64-v14b-architecture-current-freeze-audit-v1/evidence/replay-1/current-directed-nine-gate-replay.json" \
      --output "${replay_dir}/source-post-result.json" || return $?
  run_logged "checker-replay-receipt" "${replay_dir}/receipt-driver.log" \
    python3 -B "${run_dir}/build-current-p0-receipt.py" \
      --evidence-dir "${replay_dir}" \
      --mutation-evidence-dir "${source_evidence}" \
      --output "${replay_dir}/receipt.json" || return $?
  return 0
}

main
command_rc=$?
task_run_status_stage "evidence-complete"
if [[ "${command_rc}" -eq 0 && "${cleanup_rc}" -eq 0 && \
      -s "${replay_dir}/receipt.json" ]]; then
  task_run_status_mark_evidence_complete
fi
finalized=1
task_run_status_finalize "${command_rc}" "${cleanup_rc}"
