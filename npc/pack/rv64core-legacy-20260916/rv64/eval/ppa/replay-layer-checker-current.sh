#!/usr/bin/env bash
set -Eeuo pipefail

repo_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../../../.." && pwd)
runner=${repo_root}/npc/rv64/eval/ppa/replay-layer-checker-current.sh
status_helper=${repo_root}/scripts/task-run-status.sh
identity_helper=${repo_root}/npc/rv64/eval/ppa/tools/architecture_hard_gates.py
policy=${repo_root}/npc/rv64/design/arch/layered-system-signoff-policy-v1.json
simulator_source_id_tool=${repo_root}/npc/rv64/eval/ppa/rv64-simulator-source-id.sh
layer_source_id_tool=${repo_root}/npc/rv64/eval/ppa/rv64-layer-source-id.sh
layer=
source_run_arg=
run_dir_arg=

usage() {
  cat <<'EOF'
usage: replay-layer-checker-current.sh --layer l2|l3 \
  --source-run .github/task-runs/<failed-run> \
  --run-dir .github/task-runs/<new-replay-run>

Replays the current layer checker against frozen logs from one immutable FAIL
run. It creates a new fail-closed checker-only receipt and never starts a guest.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --layer)
      layer=${2:?--layer requires l2 or l3}
      shift 2
      ;;
    --source-run)
      source_run_arg=${2:?--source-run requires a path}
      shift 2
      ;;
    --run-dir)
      run_dir_arg=${2:?--run-dir requires a path}
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      printf '[RV64-LAYER-CHECKER-REPLAY][FAIL] unknown option: %s\n' "$1" >&2
      exit 2
      ;;
  esac
done

case "${layer}" in
  l2)
    source_subdir=mini-system
    source_status_name=mini-system.status
    checker=${repo_root}/npc/rv64/eval/ppa/tools/mini_system_run.py
    checker_test=${repo_root}/npc/rv64/eval/ppa/tests/test_mini_system_run.py
    checker_module=npc.rv64.eval.ppa.tests.test_mini_system_run
    layer_runner=${repo_root}/npc/rv64/eval/ppa/run-mini-system-current.sh
    artifact_cache=${repo_root}/.github/runtime-artifacts/rv64-mini-system-current/artifacts
    artifact_pairs=(
      payload_elf_sha256:mini-system.elf
      payload_bin_sha256:mini-system.bin
      effective_dtb_sha256:mini-system.dtb
      opensbi_fw_sha256:fw_jump.bin
    )
    ;;
  l3)
    source_subdir=lightweight-linux
    source_status_name=lightweight-linux.status
    checker=${repo_root}/npc/rv64/eval/ppa/tools/lightweight_linux_run.py
    checker_test=${repo_root}/npc/rv64/eval/ppa/tests/test_lightweight_linux_run.py
    checker_module=npc.rv64.eval.ppa.tests.test_lightweight_linux_run
    layer_runner=${repo_root}/npc/rv64/eval/ppa/run-lightweight-linux-current.sh
    artifact_cache=${repo_root}/.github/runtime-artifacts/rv64-lightweight-linux-current/artifacts
    artifact_pairs=(
      linux_image_sha256:Image
      pid1_sha256:init
      initramfs_sha256:initramfs.cpio
      guest_dtb_sha256:guest.dtb
      opensbi_platform_dtb_sha256:opensbi-platform.dtb
      opensbi_fw_sha256:fw_jump.bin
      kernel_effective_config_sha256:linux.config
    )
    ;;
  *)
    printf '%s\n' '[RV64-LAYER-CHECKER-REPLAY][FAIL] --layer must be l2 or l3' >&2
    exit 2
    ;;
esac

for value in "${source_run_arg}" "${run_dir_arg}"; do
  if [[ ! "${value}" =~ ^\.github/task-runs/[A-Za-z0-9][A-Za-z0-9._-]*$ ]]; then
    printf '[RV64-LAYER-CHECKER-REPLAY][FAIL] not a direct task-run child: %s\n' \
      "${value}" >&2
    exit 2
  fi
done
[[ "${source_run_arg}" != "${run_dir_arg}" ]]

task_runs_root=${repo_root}/.github/task-runs
source_run=${repo_root}/${source_run_arg}
run_dir=${repo_root}/${run_dir_arg}
source_result=${source_run}/${source_subdir}
source_status=${source_run}/${source_status_name}
result_dir=${run_dir}/checker-replay
status_path=${run_dir}/checker-replay.status

[[ -d "${task_runs_root}" && ! -L "${task_runs_root}" ]]
[[ -d "${source_run}" && ! -L "${source_run}" ]]
[[ "$(dirname -- "$(realpath -e -- "${source_run}")")" == \
   "$(realpath -e -- "${task_runs_root}")" ]]
[[ ! -e "${run_dir}" && ! -L "${run_dir}" ]]
for input in "${source_status}" "${source_result}/console.log" \
  "${source_result}/npc.log" "${source_result}/binding.txt" \
  "${checker}" "${checker_test}" "${identity_helper}" "${status_helper}" \
  "${runner}" "${layer_runner}" "${policy}" "${simulator_source_id_tool}" \
  "${layer_source_id_tool}" "${artifact_cache}/artifact-binding.txt"; do
  [[ -s "${input}" && ! -L "${input}" ]]
done
grep -Eq '^FAIL rc=[0-9]+ stage=' "${source_status}"

mkdir -p -- "${result_dir}"
source "${status_helper}"
task_run_status_init "${status_path}"

seal_evidence() {
  local path name manifest_sha verify_sha
  local -a evidence_files=()
  for name in original-status.txt input-hashes-before.sha256 \
    input-hashes-after.sha256 checker-tests.log checker.log summary.json \
    current-rtl-identity.json current-rtl-identity.log replay-binding.txt \
    evidence-hashes.sha256 current-simulator-binding.txt \
    current-artifact-binding.txt simulator-source-before.txt \
    simulator-source-after.txt layer-source-before.txt layer-source-after.txt; do
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
  (( ${#evidence_files[@]} >= 10 )) || return 1
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

finish() {
  local command_rc=$?
  local seal_rc=0
  local final_rc=0
  trap - EXIT
  set +e
  if [[ "${command_rc}" -eq 0 ]]; then
    task_run_status_stage evidence-seal
    seal_evidence
    seal_rc=$?
    if [[ "${seal_rc}" -eq 0 ]]; then
      task_run_status_mark_evidence_complete
    else
      command_rc=${seal_rc}
    fi
  fi
  task_run_status_finalize "${command_rc}" 0
  final_rc=$?
  if [[ "${final_rc}" -eq 0 ]]; then
    printf '[RV64-LAYER-CHECKER-REPLAY][PASS] layer=%s source=%s guest-rerun=0\n' \
      "${layer}" "${source_run_arg}"
  fi
  set -e
  exit "${final_rc}"
}
trap finish EXIT
task_run_status_install_signal_traps

hash_inputs() {
  sha256sum "${source_status}" "${source_result}/console.log" \
    "${source_result}/npc.log" "${source_result}/binding.txt" \
    "${checker}" "${checker_test}" "${identity_helper}" "${status_helper}" \
    "${runner}" "${layer_runner}" "${policy}" "${simulator_source_id_tool}" \
    "${layer_source_id_tool}" "${simulator}" "${simulator_manifest}" \
    "${simulator_binding}" "${artifact_binding}" "${artifact_files[@]}"
}

binding_value() {
  local key=$1
  local path=$2
  awk -F= -v key="${key}" '$1 == key { count++; value=substr($0, length($1)+2) }
    END { if (count != 1) exit 1; print value }' "${path}"
}

task_run_status_stage source-binding
cp -- "${source_status}" "${result_dir}/original-status.txt"

task_run_status_stage current-rtl-identity
python3 -B "${checker}" rtl-identity --repo-root "${repo_root}" \
  --output "${result_dir}/current-rtl-identity.json" \
  >"${result_dir}/current-rtl-identity.log"
readarray -t current_identity < <(
  python3 -B - "${result_dir}/current-rtl-identity.json" <<'PY'
import json
import sys
data = json.load(open(sys.argv[1], encoding="utf-8"))
print(data["rtl_design_id"])
print(data["production_rtl_file_count"])
PY
)
source_design_id=$(binding_value rtl_design_id "${source_result}/binding.txt")
source_rtl_file_count=$(
  binding_value production_rtl_file_count "${source_result}/binding.txt"
)
[[ "${source_design_id}" == "${current_identity[0]}" ]]
[[ "${source_rtl_file_count}" == "${current_identity[1]}" ]]
simulator_cache=${repo_root}/.github/runtime-artifacts/rv64-current-simulator/${current_identity[0]#sha256:}
simulator=${simulator_cache}/NpcSimTop
simulator_manifest=${simulator_cache}/simulator-verFiles.dat
simulator_binding=${simulator_cache}/source-binding.txt
artifact_binding=${artifact_cache}/artifact-binding.txt
for input in "${simulator}" "${simulator_manifest}" "${simulator_binding}" \
  "${artifact_binding}"; do
  [[ -s "${input}" && ! -L "${input}" ]]
done
[[ -x "${simulator}" ]]
grep -Fq -- '--assert' "${simulator_manifest}"
grep -Fqx "rtl_design_id=${current_identity[0]}" "${simulator_binding}"
grep -Fqx "production_rtl_file_count=${current_identity[1]}" "${simulator_binding}"
current_simulator_sha=$(sha256sum "${simulator}" | awk '{print $1}')
[[ "$(binding_value simulator_sha256 "${source_result}/binding.txt")" == \
   "${current_simulator_sha}" ]]
grep -Fqx "simulator_sha256=${current_simulator_sha}" "${simulator_binding}"
current_simulator_source_sha=$(bash "${simulator_source_id_tool}")
[[ "$(binding_value simulator_source_sha256 "${source_result}/binding.txt")" == \
   "${current_simulator_source_sha}" ]]
grep -Fqx "simulator_source_sha256=${current_simulator_source_sha}" \
  "${simulator_binding}"
current_layer_source_sha=$(bash "${layer_source_id_tool}" --layer "${layer}")
[[ "$(binding_value layer_source_sha256 "${source_result}/binding.txt")" == \
   "${current_layer_source_sha}" ]]
printf '%s\n' "${current_simulator_source_sha}" \
  >"${result_dir}/simulator-source-before.txt"
printf '%s\n' "${current_layer_source_sha}" \
  >"${result_dir}/layer-source-before.txt"
cp -- "${simulator_binding}" "${result_dir}/current-simulator-binding.txt"
cp -- "${artifact_binding}" "${result_dir}/current-artifact-binding.txt"
artifact_files=()
for pair in "${artifact_pairs[@]}"; do
  field=${pair%%:*}
  artifact=${artifact_cache}/${pair#*:}
  [[ -s "${artifact}" && ! -L "${artifact}" ]]
  artifact_sha=$(sha256sum "${artifact}" | awk '{print $1}')
  [[ "$(binding_value "${field}" "${source_result}/binding.txt")" == \
     "${artifact_sha}" ]]
  [[ "$(binding_value "${field}" "${artifact_binding}")" == \
     "${artifact_sha}" ]]
  artifact_files+=("${artifact}")
done
hash_inputs >"${result_dir}/input-hashes-before.sha256"

task_run_status_stage checker-tests
python3 -B -m unittest -q "${checker_module}" \
  >"${result_dir}/checker-tests.log" 2>&1

task_run_status_stage checker-replay
python3 -B "${checker}" check \
  --console "${source_result}/console.log" \
  --npc-log "${source_result}/npc.log" \
  --binding "${source_result}/binding.txt" \
  --output "${result_dir}/summary.json" \
  >"${result_dir}/checker.log"
readarray -t summary_identity < <(
  python3 -B - "${result_dir}/summary.json" <<'PY'
import json
import sys
data = json.load(open(sys.argv[1], encoding="utf-8"))
print(data["rtl_design_id"])
print(data["production_rtl_file_count"])
PY
)
[[ "${summary_identity[0]}" == "${current_identity[0]}" ]]
[[ "${summary_identity[1]}" == "${current_identity[1]}" ]]

task_run_status_stage source-post-hash
hash_inputs >"${result_dir}/input-hashes-after.sha256"
cmp -s "${result_dir}/input-hashes-before.sha256" \
  "${result_dir}/input-hashes-after.sha256"
bash "${simulator_source_id_tool}" >"${result_dir}/simulator-source-after.txt"
cmp -s "${result_dir}/simulator-source-before.txt" \
  "${result_dir}/simulator-source-after.txt"
bash "${layer_source_id_tool}" --layer "${layer}" \
  >"${result_dir}/layer-source-after.txt"
cmp -s "${result_dir}/layer-source-before.txt" \
  "${result_dir}/layer-source-after.txt"

task_run_status_stage replay-binding
{
  printf '%s\n' 'schema=npc-rv64-layer-checker-replay-v2'
  printf 'layer=%s\n' "${layer}"
  printf 'source_run=%s\n' "${source_run_arg}"
  printf 'source_status_sha256=%s\n' \
    "$(sha256sum "${source_status}" | awk '{print $1}')"
  printf 'checker_sha256=%s\n' "$(sha256sum "${checker}" | awk '{print $1}')"
  printf 'checker_test_sha256=%s\n' \
    "$(sha256sum "${checker_test}" | awk '{print $1}')"
  printf 'identity_helper_sha256=%s\n' \
    "$(sha256sum "${identity_helper}" | awk '{print $1}')"
  printf 'layer_runner_sha256=%s\n' \
    "$(sha256sum "${layer_runner}" | awk '{print $1}')"
  printf 'policy_sha256=%s\n' "$(sha256sum "${policy}" | awk '{print $1}')"
  printf 'simulator_source_sha256=%s\n' "${current_simulator_source_sha}"
  printf 'layer_source_sha256=%s\n' "${current_layer_source_sha}"
  printf 'current_simulator_sha256=%s\n' "${current_simulator_sha}"
  printf 'source_rtl_design_id=%s\n' "${source_design_id}"
  printf 'current_rtl_design_id=%s\n' "${current_identity[0]}"
  printf 'current_production_rtl_file_count=%s\n' "${current_identity[1]}"
  printf '%s\n' 'current_identity_recomputed=1'
  printf '%s\n' 'source_status=FAIL'
  printf '%s\n' 'original_status_unchanged=1'
  printf '%s\n' 'claim_scope=checker-replay-only'
  printf '%s\n' 'guest_rerun=0'
  printf '%s\n' 'ubuntu2204_full_simulation=not_launched'
} >"${result_dir}/replay-binding.txt"
sha256sum "${result_dir}/summary.json" "${result_dir}/checker.log" \
  "${result_dir}/checker-tests.log" "${result_dir}/replay-binding.txt" \
  "${result_dir}/current-rtl-identity.json" \
  "${result_dir}/current-simulator-binding.txt" \
  "${result_dir}/current-artifact-binding.txt" \
  >"${result_dir}/evidence-hashes.sha256"

task_run_status_stage evidence-ready
