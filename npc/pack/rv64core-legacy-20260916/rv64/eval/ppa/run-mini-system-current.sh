#!/usr/bin/env bash
set -Eeuo pipefail

repo_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../../../.." && pwd)
runner=${repo_root}/npc/rv64/eval/ppa/run-mini-system-current.sh
checker=${repo_root}/npc/rv64/eval/ppa/tools/mini_system_run.py
identity_helper=${repo_root}/npc/rv64/eval/ppa/tools/architecture_hard_gates.py
simulator_source_id_tool=${repo_root}/npc/rv64/eval/ppa/rv64-simulator-source-id.sh
layer_source_id_tool=${repo_root}/npc/rv64/eval/ppa/rv64-layer-source-id.sh
build_script=${repo_root}/Linux/scripts/build-rv64-mini-system.sh
payload_source=${repo_root}/Linux/mini-system/rv64-l2-payload.S
linker_script=${repo_root}/Linux/mini-system/rv64-l2-payload.ld
policy=${repo_root}/npc/rv64/design/arch/layered-system-signoff-policy-v1.json
status_helper=${repo_root}/scripts/task-run-status.sh
lock_path=${repo_root}/.github/runtime-artifacts/rv64-engineering-single-flight.lock
runtime_root=${repo_root}/.github/runtime-artifacts/rv64-mini-system-run
artifact_cache_root=${repo_root}/.github/runtime-artifacts/rv64-mini-system-current
artifact_cache=${artifact_cache_root}/artifacts

validate_only=0
run_dir_arg=
simulator_cache_arg=
l2_case=all
max_cycles=100000000
host_timeout_seconds=600
progress_interval=1000000
jobs=4

usage() {
  cat <<'EOF'
usage:
  npc/rv64/eval/ppa/run-mini-system-current.sh --validate-only
  npc/rv64/eval/ppa/run-mini-system-current.sh \
    --run-dir .github/task-runs/<new-run-id> [options]

options:
  --case privilege|sv39|timer|interrupt|atomic-mmio|shutdown|all
  --simulator-cache PATH
  --max-cycles N
  --host-timeout-seconds N
  --progress-interval N
  --jobs N

Runs the local OpenSBI + S/U payload on the current production NpcSimTop.
Only --case all can satisfy the complete L2 conjunction. Ubuntu is never used.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --validate-only)
      validate_only=1
      shift
      ;;
    --run-dir)
      run_dir_arg=${2:?--run-dir requires a path}
      shift 2
      ;;
    --case)
      l2_case=${2:?--case requires a value}
      shift 2
      ;;
    --simulator-cache)
      simulator_cache_arg=${2:?--simulator-cache requires a path}
      shift 2
      ;;
    --max-cycles)
      max_cycles=${2:?--max-cycles requires a value}
      shift 2
      ;;
    --host-timeout-seconds)
      host_timeout_seconds=${2:?--host-timeout-seconds requires a value}
      shift 2
      ;;
    --progress-interval)
      progress_interval=${2:?--progress-interval requires a value}
      shift 2
      ;;
    --jobs)
      jobs=${2:?--jobs requires a value}
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      printf '[RV64-L2-RUN][FAIL] unknown option: %s\n' "$1" >&2
      exit 2
      ;;
  esac
done

case "${l2_case}" in
  privilege|sv39|timer|interrupt|atomic-mmio|shutdown|all) ;;
  *)
    printf '[RV64-L2-RUN][FAIL] unsupported --case: %s\n' "${l2_case}" >&2
    exit 2
    ;;
esac

validate_contract() {
  bash -n "${runner}" "${build_script}" "${simulator_source_id_tool}" \
    "${layer_source_id_tool}"
  grep -Fq 'seal_evidence()' "${runner}"
  grep -Fq 'task_run_status_stage evidence-seal' "${runner}"
  python3 -B "${checker}" self-test
  python3 -B -m unittest -q npc.rv64.eval.ppa.tests.test_mini_system_run
  python3 -B - "${policy}" <<'PY'
import json
import sys

policy = json.load(open(sys.argv[1], encoding="utf-8"))
assert policy["default_signoff_conjunction"] == [
    "L0_DIRECTED_RTL", "L1_FULL_CORE_DIFFTEST", "L2_MINI_SYSTEM",
    "L3_LIGHTWEIGHT_LINUX",
]
assert policy["layers"]["L2_MINI_SYSTEM"]["entrypoint"] == (
    "npc/rv64/eval/ppa/run-mini-system-current.sh"
)
assert policy["optional_full_ubuntu"]["launch_policy"] == "explicit-user-request-only"
print("[RV64-L2-POLICY][PASS] default=L0+L1+L2+L3 ubuntu=explicit-only")
PY
  printf '%s\n' '[RV64-L2-RUNNER-CONTRACT][PASS] cases=7 checker-positive=7 mutations=10 status=fail-closed evidence-seal=1 source-post-bind=1'
}

for command_name in awk bash cmp find flock git grep make python3 realpath rg \
  sha256sum sort stat tail timeout; do
  command -v "${command_name}" >/dev/null
done
for input in "${runner}" "${checker}" "${build_script}" "${payload_source}" \
  "${linker_script}" "${identity_helper}" "${simulator_source_id_tool}" \
  "${layer_source_id_tool}" "${policy}" "${status_helper}"; do
  [[ -s "${input}" && ! -L "${input}" ]]
done

if [[ "${validate_only}" -eq 1 ]]; then
  [[ -z "${run_dir_arg}" ]]
  validate_contract
  exit 0
fi

for value in "${max_cycles}" "${host_timeout_seconds}" \
  "${progress_interval}" "${jobs}"; do
  [[ "${value}" =~ ^[0-9]+$ ]]
done
(( max_cycles >= 1000000 ))
(( host_timeout_seconds >= 60 ))
(( progress_interval > 0 ))
(( jobs > 0 && jobs <= 64 ))
if [[ ! "${run_dir_arg}" =~ ^\.github/task-runs/[A-Za-z0-9][A-Za-z0-9._-]*$ ]]; then
  printf '%s\n' '[RV64-L2-RUN][FAIL] --run-dir must be one new direct task-runs child' >&2
  exit 2
fi

run_label=${run_dir_arg##*/}
run_dir=${repo_root}/${run_dir_arg}
result_dir=${run_dir}/mini-system
status_path=${run_dir}/mini-system.status
runtime_dir=${runtime_root}/${run_label}
runtime_owned=0

[[ -d "${repo_root}/.github/task-runs" && ! -L "${repo_root}/.github/task-runs" ]]
[[ ! -e "${run_dir}" && ! -L "${run_dir}" ]]
[[ ! -e "${runtime_dir}" && ! -L "${runtime_dir}" ]]
mkdir -p -- "$(dirname -- "${lock_path}")" "${runtime_root}"
exec 9>"${lock_path}"
if ! flock -n 9; then
  printf '%s\n' '[RV64-L2-RUN][FAIL] RV64 engineering lane is occupied' >&2
  exit 3
fi
mkdir -p -- "${result_dir}" "${runtime_dir}"
runtime_owned=1

source "${status_helper}"
task_run_status_init "${status_path}"

capture_bounded_evidence() {
  local terminal_pattern assertion_pattern
  local -a logs=()
  terminal_pattern='__RV64_L2_|OpenSBI v|syscon-reset: poweroff requested|exit via system-reset|HIT (GOOD|BAD) TRAP|total guest (instructions|cycles)|uart-rx.*pop=|irq-trace|progress.*(commit|pc)'
  assertion_pattern='\[(V[0-9]+[A-Z]?-[^]]*(DISJOINT|HANDOFF|INGRESS-DUP|ASSERT[^]]*FAIL)|S2-G1-TCOLL-INGRESS-DUP)\]|%Error:|Assertion failed|RTL assertion|\[[^]]*ASSERT[^]]*FAIL'
  [[ -f "${result_dir}/console.log" ]] && logs+=("${result_dir}/console.log")
  [[ -f "${result_dir}/npc.log" ]] && logs+=("${result_dir}/npc.log")
  : >"${result_dir}/terminal-and-phase-markers.txt"
  : >"${result_dir}/rtl-assertion-failures.txt"
  if [[ "${#logs[@]}" -gt 0 ]]; then
    rg -a -n "${terminal_pattern}" "${logs[@]}" 2>/dev/null | tail -n 400 \
      >"${result_dir}/terminal-and-phase-markers.txt" || true
    rg -a -n "${assertion_pattern}" "${logs[@]}" 2>/dev/null | tail -n 400 \
      >"${result_dir}/rtl-assertion-failures.txt" || true
  fi
  return 0
}

seal_evidence() {
  local path name manifest_sha verify_sha
  local -a evidence_files=()
  for name in console.log npc.log binding.txt summary.json checker.log \
    input-hashes-before.sha256 input-hashes-after.sha256 \
    rtl-identity-before.json rtl-identity-after.json artifact-binding.txt \
    simulator-binding.txt terminal-and-phase-markers.txt \
    rtl-assertion-failures.txt runtime-cleanup.txt artifact-cache-state.txt \
    simulator-source-before.txt simulator-source-after.txt \
    layer-source-before.txt layer-source-after.txt; do
    [[ -f "${result_dir}/${name}" && ! -L "${result_dir}/${name}" ]] || return 1
  done
  while IFS= read -r -d '' path; do
    name=${path##*/}
    case "${name}" in
      evidence-files.sha256|evidence-files.verify.log|evidence-seal.txt) continue ;;
    esac
    [[ -f "${path}" && ! -L "${path}" ]] || return 1
    evidence_files+=("${name}")
  done < <(find "${result_dir}" -mindepth 1 -maxdepth 1 -type f -print0 | \
    LC_ALL=C sort -z)
  (( ${#evidence_files[@]} >= 15 )) || return 1
  (
    cd -- "${result_dir}"
    sha256sum -- "${evidence_files[@]}" >evidence-files.sha256
    sha256sum -c -- evidence-files.sha256 >evidence-files.verify.log
  ) || return 1
  manifest_sha=$(sha256sum "${result_dir}/evidence-files.sha256" | awk '{print $1}')
  verify_sha=$(sha256sum "${result_dir}/evidence-files.verify.log" | awk '{print $1}')
  {
    printf '%s\n' 'schema=npc-rv64-final-evidence-seal-v1'
    printf 'file_count=%s\n' "${#evidence_files[@]}"
    printf 'manifest_sha256=%s\n' "${manifest_sha}"
    printf 'verification_log_sha256=%s\n' "${verify_sha}"
    printf '%s\n' 'verification=PASS'
  } >"${result_dir}/evidence-seal.txt"
  (cd -- "${result_dir}" && sha256sum -c -- evidence-files.sha256 >/dev/null)
}

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
    printf 'runtime_owned=%s\n' "${runtime_owned}"
    printf 'runtime_removed=%s\n' "$([[ ! -e "${resolved_target}" ]] && printf 1 || printf 0)"
    printf 'remove_rc=%s\n' "${remove_rc}"
  } >"${result_dir}/runtime-cleanup.txt"
  return "${remove_rc}"
}

finish() {
  local command_rc=$?
  local cleanup_rc=0
  local capture_rc=0
  local seal_rc=0
  local final_rc=0
  trap - EXIT
  set +e
  capture_bounded_evidence
  capture_rc=$?
  if [[ "${command_rc}" -eq 0 && "${capture_rc}" -ne 0 ]]; then
    command_rc=${capture_rc}
  fi
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
    printf '[RV64-L2-RUN][PASS] case=%s mini-system transaction complete; Ubuntu not launched\n' \
      "${l2_case}"
  fi
  set -e
  exit "${final_rc}"
}
trap finish EXIT
task_run_status_install_signal_traps

binding_value() {
  local key=$1
  local path=$2
  awk -F= -v key="${key}" '$1 == key { count++; value=substr($0, length($1)+2) }
    END { if (count != 1) exit 1; print value }' "${path}"
}

run_bounded_log() {
  local full_log=$1
  local retained_log=$2
  shift 2
  local rc=0
  set +e
  "$@" >"${full_log}" 2>&1
  rc=$?
  set -e
  tail -n 400 "${full_log}" >"${retained_log}" 2>/dev/null || true
  return "${rc}"
}

artifact_cache_valid() {
  local binding=${artifact_cache}/artifact-binding.txt
  local current_opensbi_commit current_opensbi_diff
  [[ -d "${artifact_cache}" && ! -L "${artifact_cache}" ]] || return 1
  [[ -s "${binding}" && ! -L "${binding}" ]] || return 1
  for name in mini-system.elf mini-system.bin mini-system.dtb fw_jump.bin \
    mini-system-readelf.txt mini-system-objdump.txt artifact-binding.txt; do
    [[ -s "${artifact_cache}/${name}" && ! -L "${artifact_cache}/${name}" ]] || return 1
  done
  [[ "$(binding_value build_script_sha256 "${binding}")" == \
     "$(sha256sum "${build_script}" | awk '{print $1}')" ]] || return 1
  [[ "$(binding_value payload_source_sha256 "${binding}")" == \
     "$(sha256sum "${payload_source}" | awk '{print $1}')" ]] || return 1
  [[ "$(binding_value linker_script_sha256 "${binding}")" == \
     "$(sha256sum "${linker_script}" | awk '{print $1}')" ]] || return 1
  [[ "$(binding_value gen_dts_sha256 "${binding}")" == \
     "$(sha256sum "${repo_root}/Linux/platform/gen_dts.py" | awk '{print $1}')" ]] || return 1
  [[ "$(binding_value common_platform_sha256 "${binding}")" == \
     "$(sha256sum "${repo_root}/Linux/platform/common-rv64.yml" | awk '{print $1}')" ]] || return 1
  [[ "$(binding_value npc_platform_sha256 "${binding}")" == \
     "$(sha256sum "${repo_root}/Linux/platform/npc-rv64.yml" | awk '{print $1}')" ]] || return 1
  current_opensbi_commit=$(git -C "${repo_root}/Linux/env/src/opensbi" rev-parse HEAD)
  current_opensbi_diff=$(git -C "${repo_root}/Linux/env/src/opensbi" \
    diff --no-ext-diff --binary HEAD | sha256sum | awk '{print $1}')
  [[ "$(binding_value opensbi_commit "${binding}")" == "${current_opensbi_commit}" ]] || return 1
  [[ "$(binding_value opensbi_diff_sha256 "${binding}")" == "${current_opensbi_diff}" ]] || return 1
  for pair in \
    "payload_elf_sha256:mini-system.elf" \
    "payload_bin_sha256:mini-system.bin" \
    "effective_dtb_sha256:mini-system.dtb" \
    "opensbi_fw_sha256:fw_jump.bin"; do
    [[ "$(binding_value "${pair%%:*}" "${binding}")" == \
       "$(sha256sum "${artifact_cache}/${pair#*:}" | awk '{print $1}')" ]] || return 1
  done
  [[ "$(binding_value effective_dtb_syscon "${binding}")" == 1 ]] || return 1
  [[ "$(binding_value case_set "${binding}")" == \
     privilege,sv39,timer,interrupt,atomic-mmio,shutdown,all ]] || return 1
}

task_run_status_stage artifact-cache
artifact_cache_state=reused
if ! artifact_cache_valid; then
  artifact_cache_state=built
  run_bounded_log "${runtime_dir}/build.full.log" "${result_dir}/build-tail.log" \
    "${build_script}" --output-dir "${runtime_dir}/artifact-candidate" \
    --work-dir "${runtime_dir}/build-work" --jobs "${jobs}"
  candidate=${runtime_dir}/artifact-candidate
  [[ -s "${candidate}/artifact-binding.txt" ]]
  mkdir -p -- "${artifact_cache_root}"
  [[ ! -L "${artifact_cache_root}" ]]
  if [[ -e "${artifact_cache}" ]]; then
    [[ "$(realpath -m -- "${artifact_cache}")" == \
       "$(realpath -m -- "${artifact_cache_root}")/artifacts" ]]
    rm -rf -- "${artifact_cache}"
  fi
  mv -- "${candidate}" "${artifact_cache}"
  artifact_cache_valid
fi
printf 'artifact_cache_state=%s\nartifact_cache=%s\n' \
  "${artifact_cache_state}" "${artifact_cache}" \
  >"${result_dir}/artifact-cache-state.txt"
cp -- "${artifact_cache}/artifact-binding.txt" "${result_dir}/artifact-binding.txt"

task_run_status_stage rtl-identity
python3 -B "${checker}" rtl-identity --repo-root "${repo_root}" \
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
if [[ -n "${simulator_cache_arg}" ]]; then
  simulator_cache=${simulator_cache_arg}
else
  simulator_cache=${repo_root}/.github/runtime-artifacts/rv64-current-simulator/${rtl_design_id#sha256:}
fi
simulator=${simulator_cache}/NpcSimTop
simulator_binding=${simulator_cache}/source-binding.txt
simulator_manifest=${simulator_cache}/simulator-verFiles.dat
for input in "${simulator}" "${simulator_binding}" "${simulator_manifest}"; do
  [[ -s "${input}" && ! -L "${input}" ]]
done
[[ -x "${simulator}" ]]
grep -Fqx "rtl_design_id=${rtl_design_id}" "${simulator_binding}"
grep -Fqx "production_rtl_file_count=${rtl_file_count}" "${simulator_binding}"
grep -Fqx 'OOO_CSR_QUEUE_HEAD=1' "${simulator_binding}"
grep -Fqx 'OOO_ASSERT=1' "${simulator_binding}"
grep -Fqx 'OOO_TERMINAL_HOLDER_ASSERT=1' "${simulator_binding}"
grep -Fq -- '--assert' "${simulator_manifest}"
current_simulator_source_sha=$(bash "${simulator_source_id_tool}")
grep -Fqx "simulator_source_sha256=${current_simulator_source_sha}" \
  "${simulator_binding}"
printf '%s\n' "${current_simulator_source_sha}" \
  >"${result_dir}/simulator-source-before.txt"
current_layer_source_sha=$(bash "${layer_source_id_tool}" --layer l2)
printf '%s\n' "${current_layer_source_sha}" \
  >"${result_dir}/layer-source-before.txt"
simulator_sha=$(sha256sum "${simulator}" | awk '{print $1}')
grep -Fqx "simulator_sha256=${simulator_sha}" "${simulator_binding}"
cp -- "${simulator_binding}" "${result_dir}/simulator-binding.txt"

task_run_status_stage run-binding
{
  printf '%s\n' 'schema=npc-rv64-l2-mini-system-run-binding-v1'
  printf 'rtl_design_id=%s\n' "${rtl_design_id}"
  printf 'production_rtl_file_count=%s\n' "${rtl_file_count}"
  printf 'simulator_sha256=%s\n' "${simulator_sha}"
  printf 'simulator_source_sha256=%s\n' "${current_simulator_source_sha}"
  printf 'layer_source_sha256=%s\n' "${current_layer_source_sha}"
  printf 'l2_case=%s\n' "${l2_case}"
  sed -n '2,$p' "${artifact_cache}/artifact-binding.txt"
  printf 'max_cycles=%s\n' "${max_cycles}"
  printf 'host_timeout_seconds=%s\n' "${host_timeout_seconds}"
  printf 'progress_interval=%s\n' "${progress_interval}"
  printf '%s\n' 'OOO_ASSERT=1'
  printf '%s\n' 'OOO_CSR_QUEUE_HEAD=1'
  printf '%s\n' 'OOO_TERMINAL_HOLDER_ASSERT=1'
  printf '%s\n' 'ubuntu2204_full_simulation=not_launched'
} >"${result_dir}/binding.txt"

case "${l2_case}" in
  privilege) selector=p ;;
  sv39) selector=v ;;
  timer) selector=t ;;
  interrupt) selector=i ;;
  atomic-mmio) selector=a ;;
  shutdown) selector=d ;;
  all) selector=x ;;
esac

hash_inputs() {
  sha256sum "${simulator}" "${simulator_manifest}" "${simulator_binding}" \
    "${artifact_cache}/mini-system.elf" "${artifact_cache}/mini-system.bin" \
    "${artifact_cache}/mini-system.dtb" "${artifact_cache}/fw_jump.bin" \
    "${runner}" "${checker}" "${build_script}" "${payload_source}" \
    "${linker_script}" "${identity_helper}" "${simulator_source_id_tool}" \
    "${layer_source_id_tool}" "${policy}" "${status_helper}"
}
hash_inputs >"${result_dir}/input-hashes-before.sha256"

task_run_status_stage mini-system-guest
set +e
NPC_OOO_WINDOW=0 \
NPC_UART_RX_TEXT="${selector}" \
NPC_UART_RX_WAIT=__RV64_L2_CASE_SELECT__ \
NPC_UART_RX_TRACE=1 \
NPC_UART_RX_TRACE_LIMIT=1 \
NPC_UART_RX_RELEASE_DELAY_CYCLES=1000 \
NPC_UART_TX_TRACE=1 \
NPC_UART_TX_TRACE_LIMIT=20000 \
NPC_IRQ_TRACE=1 \
NPC_IRQ_TRACE_LIMIT=256 \
  timeout --foreground --signal=TERM --kill-after=10s "${host_timeout_seconds}" \
  "${simulator}" -b --progress="${progress_interval}" --no-diff \
    --max="${max_cycles}" --log="${result_dir}/npc.log" \
    -i "${artifact_cache}/fw_jump.bin" \
    --load=0x80400000:"${artifact_cache}/mini-system.bin" \
    --load=0x82300000:"${artifact_cache}/mini-system.dtb" \
    >"${result_dir}/console.log" 2>&1
run_rc=$?
set -e
[[ "${run_rc}" -eq 0 ]]

task_run_status_stage semantic-check
set +e
python3 -B "${checker}" check --console "${result_dir}/console.log" \
  --npc-log "${result_dir}/npc.log" --binding "${result_dir}/binding.txt" \
  --output "${result_dir}/summary.json" >"${result_dir}/checker.log"
checker_rc=$?
set -e

task_run_status_stage post-binding
hash_inputs >"${result_dir}/input-hashes-after.sha256"
cmp -s "${result_dir}/input-hashes-before.sha256" \
  "${result_dir}/input-hashes-after.sha256"
python3 -B "${checker}" rtl-identity --repo-root "${repo_root}" \
  --output "${result_dir}/rtl-identity-after.json" \
  >"${result_dir}/rtl-identity-after.log"
cmp -s "${result_dir}/rtl-identity-before.json" \
  "${result_dir}/rtl-identity-after.json"
bash "${simulator_source_id_tool}" >"${result_dir}/simulator-source-after.txt"
cmp -s "${result_dir}/simulator-source-before.txt" \
  "${result_dir}/simulator-source-after.txt"
bash "${layer_source_id_tool}" --layer l2 >"${result_dir}/layer-source-after.txt"
cmp -s "${result_dir}/layer-source-before.txt" \
  "${result_dir}/layer-source-after.txt"
capture_bounded_evidence
[[ ! -s "${result_dir}/rtl-assertion-failures.txt" ]]
if [[ "${checker_rc}" -ne 0 ]]; then
  task_run_status_stage semantic-check-failed-post-bound
  exit "${checker_rc}"
fi

task_run_status_stage evidence-ready
