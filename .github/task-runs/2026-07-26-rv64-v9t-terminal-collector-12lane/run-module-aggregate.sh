#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
testbench_dir="${repo_root}/npc/rv64/testbench"
result_root="${repo_root}/.github/task-runs/2026-07-26-rv64-v9t-terminal-collector-12lane/module-aggregate"
build_dir="${testbench_dir}/build-v9t-terminal-collector-12lane-module-aggregate"
run_log="${result_root}/run.log"
source_id_tool="${repo_root}/.github/task-runs/2026-07-23-rv64-v9o-control-event-current-design/evidence_source_set.py"

rtl_design_sha() {
  python3 - "${repo_root}" <<'PY'
import pathlib
import sys

root = pathlib.Path(sys.argv[1]).resolve()
sys.path.insert(0, str(root / "npc/rv64/eval/ppa/tools"))
import architecture_hard_gates as arch

source_sha, _ = arch.rtl_binding(root)
print(source_sha)
PY
}

design_sha_pre="$(rtl_design_sha)"
verification_sha_pre="$(
  python3 "${source_id_tool}" --root "${repo_root}" --kind verification
)"
mapfile -t required_tests < <(
  make --no-print-directory -s -C "${testbench_dir}" print-tests
)
module_count="${#required_tests[@]}"
(( module_count > 0 )) || {
  printf '%s\n' "[V9T-MODULE-AGGREGATE][FAIL] empty TESTS inventory" >&2
  exit 1
}

mkdir -p "${result_root}"
exec > >(tee "${run_log}") 2>&1

make -B -C "${testbench_dir}" \
  "BUILD_DIR=${build_dir}" \
  "RESULT_DIR=${result_root}" \
  "RTL_EVIDENCE_SHA=${design_sha_pre}" \
  run

grep -F -- "- total: ${module_count}" "${result_root}/summary.txt"
grep -F -- "- passed: ${module_count}" "${result_root}/summary.txt"
grep -F -- "- failed: 0" "${result_root}/summary.txt"

design_sha_post="$(rtl_design_sha)"
[[ "${design_sha_post}" == "${design_sha_pre}" ]] || {
  printf '%s\n' \
    "[V9T-MODULE-AGGREGATE][FAIL] live RTL changed during aggregate" >&2
  exit 1
}
verification_sha_post="$(
  python3 "${source_id_tool}" --root "${repo_root}" --kind verification
)"
[[ "${verification_sha_post}" == "${verification_sha_pre}" ]] || {
  printf '%s\n' \
    "[V9T-MODULE-AGGREGATE][FAIL] verification sources changed during aggregate" >&2
  exit 1
}

for log_path in "${result_root}"/logs/*.log; do
  printf '[V9T-VERIFICATION-SOURCE-ID] sha256:%s\n' \
    "${verification_sha_pre}" >> "${log_path}"
done
module_logs=("${result_root}"/logs/*.log)
[[ "${#module_logs[@]}" -eq "${module_count}" ]] || {
  printf '[V9T-MODULE-AGGREGATE][FAIL] logs=%s tests=%s\n' \
    "${#module_logs[@]}" "${module_count}" >&2
  exit 1
}
grep -F -l "[RTL-DESIGN-ID] sha256:${design_sha_pre}" \
  "${result_root}"/logs/*.log |
  wc -l |
  grep -Fx "${module_count}"
grep -F -l "[V9T-VERIFICATION-SOURCE-ID] sha256:${verification_sha_pre}" \
  "${result_root}"/logs/*.log |
  wc -l |
  grep -Fx "${module_count}"

printf '%s\n' \
  "[V9T-MODULE-AGGREGATE] tests=${module_count} design_id=sha256:${design_sha_pre} verification_id=sha256:${verification_sha_pre} source_stable=true status=PASS"
