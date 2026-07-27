#!/usr/bin/env bash
set -euo pipefail

run_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(git -C "${run_dir}" rev-parse --show-toplevel)"
status_path="${run_dir}/current-design-refresh.status"
log_path="${run_dir}/current-design-refresh.log"
v9o_dir="${repo_root}/.github/task-runs/2026-07-23-rv64-v9o-control-event-current-design"
v9r_dir="${repo_root}/.github/task-runs/2026-07-24-rv64-v9r-sq-retry-c0-handoff"
v9l_dir="${repo_root}/.github/task-runs/2026-07-22-rv64-v9l-functional-aggregate-current-design"
v9v_dir="${repo_root}/.github/task-runs/2026-07-26-rv64-v9v-full-core-cohort-scope"
candidate="${repo_root}/npc/rv64/eval/ppa/arch-stable/full-core-current.json"
checker="${repo_root}/npc/rv64/eval/ppa/tools/arch_stable_freeze.py"

write_status() {
  local state="$1"
  local stage="$2"
  local detail="$3"
  printf 'state=%s\nstage=%s\ndetail=%s\n' \
    "${state}" "${stage}" "${detail}" > "${status_path}"
}

on_exit() {
  local rc=$?
  if [[ ${rc} -ne 0 ]]; then
    write_status "FAIL" "${active_stage:-initialization}" "rc=${rc}"
  fi
}
trap on_exit EXIT

run_stage() {
  active_stage="$1"
  shift
  write_status "RUNNING" "${active_stage}" "command-start"
  printf '[V9W-CURRENT-REFRESH] stage=%s state=START\n' "${active_stage}"
  "$@"
  printf '[V9W-CURRENT-REFRESH] stage=%s state=PASS\n' "${active_stage}"
}

rtl_sha() {
  python3 - "${repo_root}" <<'PY'
import pathlib
import sys

root = pathlib.Path(sys.argv[1]).resolve()
sys.path.insert(0, str(root / "npc/rv64/eval/ppa/tools"))
import architecture_hard_gates as architecture

print(architecture.rtl_binding(root)[0])
PY
}

exec > >(tee "${log_path}") 2>&1
design_sha_before="$(rtl_sha)"
printf '[V9W-CURRENT-REFRESH] design_id=sha256:%s state=START\n' \
  "${design_sha_before}"

run_stage holder-lifecycle \
  make -C "${repo_root}/npc/rv64" check-global-producer-no-live-reuse
run_stage functional-aggregate \
  make -C "${repo_root}/npc/rv64" check-functional-aggregate
run_stage candidate-and-census \
  python3 "${v9l_dir}/update-current-arch-stable-candidate.py"

run_stage fdg-arch-trap \
  make -C "${repo_root}/npc/rv64" check-fdg-arch-trap
run_stage xret-current-mode \
  make -C "${repo_root}/npc/rv64" check-xret-current-mode
run_stage memory-issue-lifecycle \
  make -C "${repo_root}/npc/rv64" check-memory-issue-lifecycle
run_stage ifu-axi-flush-drain \
  make -C "${repo_root}/npc/rv64" check-ifu-axi-flush-drain
run_stage ifu-fetch-provenance \
  make -C "${repo_root}/npc/rv64" check-ifu-fetch-provenance
run_stage ifu-access \
  make -C "${repo_root}/npc/rv64" check-ifu-access
run_stage ifu-tval \
  make -C "${repo_root}/npc/rv64" check-ifu-tval
run_stage ptw-pmp \
  make -C "${repo_root}/npc/rv64" check-ptw-pmp
run_stage instret-retirement \
  make -C "${repo_root}/npc/rv64" check-instret-retirement
run_stage fence-ordering \
  make -C "${repo_root}/npc/rv64" check-fence-ordering
run_stage vectored-trap \
  make -C "${repo_root}/npc/rv64" check-vectored-trap

run_stage sq-retry-c0 \
  bash "${v9r_dir}/run-v9r-evidence.sh"
run_stage control-event-focused \
  bash "${v9o_dir}/run-focused.sh"
run_stage control-event-config \
  bash "${v9o_dir}/run-v9o-config-variants.sh"
run_stage control-event-mutations \
  python3 "${v9o_dir}/run-control-event-rtl-mutations.py" \
    --root "${repo_root}" \
    --output "${v9o_dir}/mutations/summary.json"
run_stage control-event-module-aggregate \
  bash "${v9o_dir}/run-module-aggregate.sh"
run_stage control-event-architecture \
  bash "${v9o_dir}/refresh-architecture-evidence.sh"
run_stage control-event-gap-boundary \
  bash "${v9o_dir}/run-arch-stable-boundary.sh"
run_stage control-event-index \
  python3 "${v9o_dir}/build-evidence-index.py"
run_stage control-event-index-verify \
  python3 "${v9o_dir}/build-evidence-index.py" --verify

run_stage debt-ledger-current \
  python3 "${v9l_dir}/update-current-debt-ledger.py"
run_stage cohort-exclusions-current \
  python3 "${run_dir}/rebind-cohort-exclusions.py"
run_stage full-core-cohort-audit \
  bash "${v9v_dir}/run-focused.sh"
run_stage final-arch-stable-audit \
  python3 "${checker}" audit "${candidate}" \
    --output "${run_dir}/evidence/final-arch-stable-audit.json"
run_stage final-arch-stable-verify \
  python3 "${checker}" verify \
    "${run_dir}/evidence/final-arch-stable-audit.json"

design_sha_after="$(rtl_sha)"
if [[ "${design_sha_after}" != "${design_sha_before}" ]]; then
  printf '[V9W-CURRENT-REFRESH] RTL changed before=%s after=%s\n' \
    "${design_sha_before}" "${design_sha_after}" >&2
  exit 1
fi
write_status "PASS" "complete" "design_id=sha256:${design_sha_after}"
printf '[V9W-CURRENT-REFRESH] design_id=sha256:%s state=PASS\n' \
  "${design_sha_after}"
trap - EXIT
