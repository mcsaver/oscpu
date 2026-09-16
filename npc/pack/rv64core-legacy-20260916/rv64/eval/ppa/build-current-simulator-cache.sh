#!/usr/bin/env bash
set -Eeuo pipefail

repo_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../../../.." && pwd)
runner=${repo_root}/npc/rv64/eval/ppa/build-current-simulator-cache.sh
identity_checker=${repo_root}/npc/rv64/eval/ppa/tools/mini_system_run.py
identity_helper=${repo_root}/npc/rv64/eval/ppa/tools/architecture_hard_gates.py
source_id_tool=${repo_root}/npc/rv64/eval/ppa/rv64-simulator-source-id.sh
status_helper=${repo_root}/scripts/task-run-status.sh
lock_path=${repo_root}/.github/runtime-artifacts/rv64-engineering-single-flight.lock
runtime_root=${repo_root}/.github/runtime-artifacts/rv64-current-simulator-build
cache_root=${repo_root}/.github/runtime-artifacts/rv64-current-simulator

validate_only=0
run_dir_arg=
jobs=4

usage() {
  printf '%s\n' \
    'usage: build-current-simulator-cache.sh --validate-only' \
    '   or: build-current-simulator-cache.sh --run-dir .github/task-runs/<id> [--jobs N]'
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --validate-only) validate_only=1; shift ;;
    --run-dir) run_dir_arg=${2:?--run-dir requires a path}; shift 2 ;;
    --jobs) jobs=${2:?--jobs requires a value}; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) printf '[RV64-SIM-CACHE][FAIL] unknown option: %s\n' "$1" >&2; exit 2 ;;
  esac
done

for input in "${runner}" "${identity_checker}" "${identity_helper}" \
  "${source_id_tool}" "${status_helper}"; do
  [[ -s "${input}" && ! -L "${input}" ]]
done
for command_name in awk bash clang++ cmp find flock grep make mv python3 \
  realpath rm sha256sum sort tail verilator xargs; do
  command -v "${command_name}" >/dev/null
done

if [[ "${validate_only}" -eq 1 ]]; then
  [[ -z "${run_dir_arg}" ]]
  bash -n "${runner}" "${source_id_tool}"
  [[ "$(bash "${source_id_tool}")" =~ ^[0-9a-f]{64}$ ]]
  printf '%s\n' '[RV64-SIM-CACHE-CONTRACT][PASS] source-content-bound=1 single-flight=1 fail-closed=1'
  exit 0
fi

[[ "${jobs}" =~ ^[0-9]+$ ]] && (( jobs > 0 && jobs <= 64 ))
if [[ ! "${run_dir_arg}" =~ ^\.github/task-runs/[A-Za-z0-9][A-Za-z0-9._-]*$ ]]; then
  printf '%s\n' '[RV64-SIM-CACHE][FAIL] --run-dir must be one new direct task-runs child' >&2
  exit 2
fi

run_label=${run_dir_arg##*/}
run_dir=${repo_root}/${run_dir_arg}
result_dir=${run_dir}/simulator-cache
status_path=${run_dir}/simulator-cache.status
runtime_dir=${runtime_root}/${run_label}
build_dir=${runtime_dir}/build
runtime_owned=0

[[ ! -e "${run_dir}" && ! -L "${run_dir}" ]]
[[ ! -e "${runtime_dir}" && ! -L "${runtime_dir}" ]]
mkdir -p -- "$(dirname -- "${lock_path}")" "${runtime_root}" "${cache_root}"
exec 9>"${lock_path}"
flock -n 9 || { printf '%s\n' '[RV64-SIM-CACHE][FAIL] RV64 engineering lane is occupied' >&2; exit 3; }
mkdir -p -- "${result_dir}" "${runtime_dir}"
runtime_owned=1

source "${status_helper}"
task_run_status_init "${status_path}"

remove_runtime() {
  local resolved_root resolved_target expected remove_rc=0
  resolved_root=$(realpath -m -- "${runtime_root}") || remove_rc=$?
  resolved_target=$(realpath -m -- "${runtime_dir}") || remove_rc=$?
  expected=${resolved_root}/${run_label}
  if [[ "${remove_rc}" -ne 0 || "${resolved_target}" != "${expected}" ||
        "${resolved_target}" == "${resolved_root}" ]]; then
    remove_rc=2
  elif [[ "${runtime_owned}" -eq 1 ]]; then
    rm -rf -- "${resolved_target}" || remove_rc=$?
  fi
  {
    printf 'runtime_path=%s\n' "${resolved_target:-UNRESOLVED}"
    printf 'runtime_removed=%s\n' "$([[ ! -e "${resolved_target}" ]] && printf 1 || printf 0)"
    printf 'remove_rc=%s\n' "${remove_rc}"
  } >"${result_dir}/runtime-cleanup.txt"
  return "${remove_rc}"
}

seal_evidence() {
  local path name manifest_sha verify_sha
  local -a files=()
  for name in rtl-identity-before.json rtl-identity-after.json \
    simulator-source-before.txt simulator-source-after.txt cache-state.txt \
    source-binding.txt build-tail.log runtime-cleanup.txt; do
    [[ -f "${result_dir}/${name}" && ! -L "${result_dir}/${name}" ]] || return 1
  done
  while IFS= read -r -d '' path; do
    name=${path##*/}
    case "${name}" in evidence-files.sha256|evidence-files.verify.log|evidence-seal.txt) continue ;; esac
    files+=("${name}")
  done < <(find "${result_dir}" -mindepth 1 -maxdepth 1 -type f -print0 | LC_ALL=C sort -z)
  (
    cd -- "${result_dir}"
    sha256sum -- "${files[@]}" >evidence-files.sha256
    sha256sum -c -- evidence-files.sha256 >evidence-files.verify.log
  ) || return 1
  manifest_sha=$(sha256sum "${result_dir}/evidence-files.sha256" | awk '{print $1}')
  verify_sha=$(sha256sum "${result_dir}/evidence-files.verify.log" | awk '{print $1}')
  {
    printf '%s\n' 'schema=npc-rv64-final-evidence-seal-v1'
    printf 'file_count=%s\n' "${#files[@]}"
    printf 'manifest_sha256=%s\n' "${manifest_sha}"
    printf 'verification_log_sha256=%s\n' "${verify_sha}"
    printf '%s\n' 'verification=PASS'
  } >"${result_dir}/evidence-seal.txt"
}

finish() {
  local command_rc=$? cleanup_rc=0 seal_rc=0 final_rc=0
  trap - EXIT
  set +e
  remove_runtime
  cleanup_rc=$?
  if [[ "${command_rc}" -eq 0 && "${cleanup_rc}" -eq 0 ]]; then
    task_run_status_stage evidence-seal
    seal_evidence
    seal_rc=$?
    if [[ "${seal_rc}" -eq 0 ]]; then
      task_run_status_mark_evidence_complete
    else
      command_rc=${seal_rc}
    fi
  fi
  task_run_status_finalize "${command_rc}" "${cleanup_rc}"
  final_rc=$?
  if [[ "${final_rc}" -eq 0 ]]; then
    printf '%s\n' '[RV64-SIM-CACHE][PASS] current simulator cache published and sealed'
  fi
  exit "${final_rc}"
}
trap finish EXIT
task_run_status_install_signal_traps

run_bounded_log() {
  local full_log=$1 retained_log=$2 rc=0
  shift 2
  set +e
  "$@" >"${full_log}" 2>&1
  rc=$?
  set -e
  tail -n 400 "${full_log}" >"${retained_log}" 2>/dev/null || true
  return "${rc}"
}

task_run_status_stage rtl-identity-before
python3 -B "${identity_checker}" rtl-identity --repo-root "${repo_root}" \
  --output "${result_dir}/rtl-identity-before.json" \
  >"${result_dir}/rtl-identity-before.log"
readarray -t rtl_identity < <(
  python3 -B - "${result_dir}/rtl-identity-before.json" <<'PY'
import json
import sys
data = json.load(open(sys.argv[1], encoding="utf-8"))
print(data["rtl_design_id"])
print(data["production_rtl_file_count"])
PY
)
rtl_design_id=${rtl_identity[0]}
rtl_file_count=${rtl_identity[1]}
simulator_source_sha=$(bash "${source_id_tool}")
printf '%s\n' "${simulator_source_sha}" >"${result_dir}/simulator-source-before.txt"
cache_dir=${cache_root}/${rtl_design_id#sha256:}

task_run_status_stage simulator-build
run_bounded_log "${runtime_dir}/build.full.log" "${result_dir}/build-tail.log" \
  env NEMU_HOME="${repo_root}/nemu" YSYX_HOME="${repo_root}" \
    make -C "${repo_root}/npc/rv64" BUILD_DIR="${build_dir}" \
      OOO_CSR_QUEUE_HEAD=1 OOO_ASSERT=1 OOO_TERMINAL_HOLDER_ASSERT=1 \
      CXX=/usr/bin/clang++ LINK=/usr/bin/clang++ \
      'VERILATOR=verilator -Wno-fatal' \
      'VERILATOR_OPT_FAST=-O3 -march=native' \
      'VERILATOR_OPT_GLOBAL=-O3 -march=native' -j"${jobs}"

simulator=${build_dir}/NpcSimTop
manifest=${build_dir}/obj_dir/VNpcSimTop__verFiles.dat
[[ -x "${simulator}" && -s "${manifest}" && ! -L "${simulator}" && ! -L "${manifest}" ]]
grep -Fq -- '--assert' "${manifest}"
grep -Fq -- '+define+OOO_CSR_QUEUE_HEAD=1 ' "${manifest}"
grep -Fq -- '+define+OOO_ASSERT ' "${manifest}"
grep -Fq -- '+define+OOO_TERMINAL_HOLDER_ASSERT ' "${manifest}"

task_run_status_stage publish-cache
candidate=${runtime_dir}/cache-candidate
mkdir -p -- "${candidate}"
cp -- "${simulator}" "${candidate}/NpcSimTop"
cp -- "${manifest}" "${candidate}/simulator-verFiles.dat"
simulator_sha=$(sha256sum "${candidate}/NpcSimTop" | awk '{print $1}')
manifest_sha=$(sha256sum "${candidate}/simulator-verFiles.dat" | awk '{print $1}')
{
  printf '%s\n' 'schema=npc-rv64-current-simulator-binding-v1'
  printf 'rtl_design_id=%s\n' "${rtl_design_id}"
  printf 'production_rtl_file_count=%s\n' "${rtl_file_count}"
  printf 'simulator_source_sha256=%s\n' "${simulator_source_sha}"
  printf 'simulator_sha256=%s\n' "${simulator_sha}"
  printf 'verilator_manifest_sha256=%s\n' "${manifest_sha}"
  printf 'npc_config_sha256=%s\n' "$(sha256sum "${repo_root}/npc/rv64/.config" | awk '{print $1}')"
  printf 'npc_auto_conf_sha256=%s\n' "$(sha256sum "${repo_root}/npc/rv64/include/config/auto.conf" | awk '{print $1}')"
  printf 'npc_autoconf_header_sha256=%s\n' "$(sha256sum "${repo_root}/npc/rv64/include/generated/autoconf.h" | awk '{print $1}')"
  printf '%s\n' 'OOO_CSR_QUEUE_HEAD=1' 'OOO_ASSERT=1' 'OOO_TERMINAL_HOLDER_ASSERT=1'
} >"${candidate}/source-binding.txt"
if [[ -e "${cache_dir}" ]]; then
  [[ ! -L "${cache_dir}" ]]
  [[ "$(dirname -- "$(realpath -m -- "${cache_dir}")")" == "$(realpath -m -- "${cache_root}")" ]]
  rm -rf -- "${cache_dir}"
fi
mv -- "${candidate}" "${cache_dir}"
cp -- "${cache_dir}/source-binding.txt" "${result_dir}/source-binding.txt"
printf 'cache_state=built\ncache_dir=%s\n' "${cache_dir}" >"${result_dir}/cache-state.txt"

task_run_status_stage post-binding
printf '%s\n' "$(bash "${source_id_tool}")" >"${result_dir}/simulator-source-after.txt"
cmp -s "${result_dir}/simulator-source-before.txt" "${result_dir}/simulator-source-after.txt"
python3 -B "${identity_checker}" rtl-identity --repo-root "${repo_root}" \
  --output "${result_dir}/rtl-identity-after.json" \
  >"${result_dir}/rtl-identity-after.log"
cmp -s "${result_dir}/rtl-identity-before.json" "${result_dir}/rtl-identity-after.json"
[[ "$(sha256sum "${cache_dir}/NpcSimTop" | awk '{print $1}')" == "${simulator_sha}" ]]
[[ "$(sha256sum "${cache_dir}/simulator-verFiles.dat" | awk '{print $1}')" == "${manifest_sha}" ]]
task_run_status_stage evidence-ready
