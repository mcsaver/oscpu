#!/usr/bin/env bash

set -uo pipefail

repo_root=/home/lyg/PA/ysyx-workbench
run_dir="${repo_root}/.github/task-runs/2026-08-02-rv64-v14c-p0-transitive-current-rebind-v1"
evidence_dir="${run_dir}/evidence/p0-replay-elimination-2"
status_path="${run_dir}/p0-replay-elimination-2.status"
module_dir="${repo_root}/.github/task-runs/2026-08-02-rv64-v14b-architecture-current-freeze-audit-v1/evidence/p0-direct-rebind-1/module-aggregate"
axi_runner="${repo_root}/.github/task-runs/2026-07-22-rv64-v9g-ifu-axi-current-design/run-ifu-axi-variants.py"
fetch_runner="${repo_root}/.github/task-runs/2026-07-22-rv64-v9h-ifu-fetch-provenance-current-design/run-ifu-fetch-variants.py"
finalized=0
cleanup_rc=0

if [[ -e "${evidence_dir}" || -e "${status_path}" ]]; then
  printf '%s\n' "[V14C-P0-REPLAY-ELIMINATION][FAIL] output already exists" >&2
  exit 2
fi
mkdir -p "${evidence_dir}/mutations/ifu-axi" \
  "${evidence_dir}/mutations/ifu-fetch" \
  "${evidence_dir}/results" "${evidence_dir}/raw"
exec > >(tee -a "${evidence_dir}/driver.log") 2>&1

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

main() {
  run_logged "ifu-axi-current-rtl-counterexamples" \
    "${evidence_dir}/ifu-axi-mutations.log" \
    python3 -B "${axi_runner}" --root "${repo_root}" \
      --output "${evidence_dir}/mutations/ifu-axi/summary.json" || return $?
  run_logged "ifu-fetch-current-rtl-counterexamples" \
    "${evidence_dir}/ifu-fetch-mutations.log" \
    python3 -B "${fetch_runner}" --root "${repo_root}" \
      --output "${evidence_dir}/mutations/ifu-fetch/summary.json" || return $?

  run_logged "ifu-axi-current-dynamic-evidence" \
    "${evidence_dir}/ifu-axi-evidence-driver.log" \
    python3 -B "${repo_root}/npc/rv64/eval/ppa/tools/ifu_axi_flush_drain_evidence.py" \
      --root "${repo_root}" \
      --bridge-log "${module_dir}/logs/tb_ooo_fetch_axi_bridge.log" \
      --xbar-log "${module_dir}/logs/tb_ooo_fetch_axi_bridge_xbar.log" \
      --generic-xbar-log "${module_dir}/logs/tb_axi_xbar.log" \
      --module-summary "${module_dir}/summary.txt" \
      --variant-summary "${evidence_dir}/mutations/ifu-axi/summary.json" \
      --output "${evidence_dir}/results/ifu-axi-current.json" \
      --raw-log "${evidence_dir}/raw/ifu-axi.log" || return $?
  run_logged "ifu-fetch-current-dynamic-evidence" \
    "${evidence_dir}/ifu-fetch-evidence-driver.log" \
    python3 -B "${repo_root}/npc/rv64/eval/ppa/tools/ifu_fetch_provenance_evidence.py" \
      --root "${repo_root}" \
      --decode-log "${module_dir}/logs/tb_ooo_fetch_packet_decode.log" \
      --page-log "${module_dir}/logs/tb_ooo_fetch_page_end_fault.log" \
      --module-summary "${module_dir}/summary.txt" \
      --variant-summary "${evidence_dir}/mutations/ifu-fetch/summary.json" \
      --output "${evidence_dir}/results/ifu-fetch-current.json" \
      --raw-log "${evidence_dir}/raw/ifu-fetch.log" || return $?
  run_logged "post-rtl-source-identity" \
    "${evidence_dir}/source-post-checker.log" \
    python3 -B "${repo_root}/npc/rv64/eval/ppa/tools/architecture_hard_gates.py" \
      --repo-root "${repo_root}" \
      --evidence-manifest "${repo_root}/.github/task-runs/2026-08-02-rv64-v14b-architecture-current-freeze-audit-v1/evidence/replay-1/current-directed-nine-gate-replay.json" \
      --output "${evidence_dir}/source-post-result.json" || return $?
  run_logged "replay-elimination-receipt" \
    "${evidence_dir}/receipt-driver.log" \
    python3 -B "${run_dir}/build-replay-elimination-receipt.py" \
      --evidence-dir "${evidence_dir}" \
      --output "${evidence_dir}/receipt.json" || return $?
  return 0
}

main
command_rc=$?
task_run_status_stage "evidence-complete"
if [[ "${command_rc}" -eq 0 && "${cleanup_rc}" -eq 0 && \
      -s "${evidence_dir}/receipt.json" ]]; then
  task_run_status_mark_evidence_complete
fi
finalized=1
task_run_status_finalize "${command_rc}" "${cleanup_rc}"
