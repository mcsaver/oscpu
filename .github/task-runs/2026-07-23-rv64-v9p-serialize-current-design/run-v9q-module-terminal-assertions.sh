#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
task_run_dir="${repo_root}/.github/task-runs/2026-07-23-rv64-v9p-serialize-current-design"
testbench_dir="${repo_root}/npc/rv64/testbench"
result_dir="${task_run_dir}/module-v9q-terminal-assertions"
status_path="${task_run_dir}/module-v9q-terminal-assertions.status"
expected_design_sha="4655eabea13d2ecce9ac94784bbcb0a8bd2151b65bcd7325f950c6abb9b91380"
ivflags="-g2012 -Wall -I${repo_root}/npc/rv64/vsrc -I${repo_root}/npc/rv64/vsrc/include -I${testbench_dir}/common -DOOO_ASSERT -DOOO_CSR_QUEUE_HEAD=1"

mkdir -p "${result_dir}"
printf '%s\n' "RUNNING" > "${status_path}"
finish() {
  local rc=$?
  if [[ "${rc}" -eq 0 ]]; then
    printf '%s\n' "PASS" > "${status_path}"
  else
    printf 'FAIL rc=%s\n' "${rc}" > "${status_path}"
  fi
  exit "${rc}"
}
trap finish EXIT

design_sha="$(
  python3 - "${repo_root}" <<'PY'
import pathlib
import sys

root = pathlib.Path(sys.argv[1]).resolve()
sys.path.insert(0, str(root / "npc/rv64/eval/ppa/tools"))
import architecture_hard_gates as arch

print(arch.rtl_binding(root)[0])
PY
)"
[[ "${design_sha}" == "${expected_design_sha}" ]]

make -B -C "${testbench_dir}" \
  "BUILD_DIR=build-v9q-terminal-assertions" \
  "RESULT_DIR=${result_dir}" \
  "IVFLAGS=${ivflags}" \
  "RTL_EVIDENCE_SHA=${design_sha}" \
  summary > "${result_dir}/driver.log" 2>&1

grep -F -- "- failed: 0" "${result_dir}/summary.txt"
grep -F -- "[RTL-DESIGN-ID] sha256:${design_sha}" \
  "${result_dir}/logs/tb_ooo_core_top_glue.log"
if rg -n \
    '\[V9Q-(BRIDGE-HOLDER|TRANSIENT-HOLDER|TRANSIENT-BRIDGE|DUAL-REQ-TOKEN)-DISJOINT\]' \
    "${result_dir}/logs" > "${result_dir}/unexpected-v9q-markers.txt"; then
  printf '%s\n' \
    "[V9Q-MODULE-TERMINAL-ASSERTIONS][FAIL] holder marker in positive aggregate"
  exit 1
fi

{
  printf 'rtl_design_id=sha256:%s\n' "${design_sha}"
  printf '%s\n' "OOO_CSR_QUEUE_HEAD=1"
  printf '%s\n' "OOO_ASSERT=1"
  printf '%s\n' "module_aggregate=110/110"
} > "${result_dir}/binding.txt"

printf '%s\n' \
  "[V9Q-MODULE-TERMINAL-ASSERTIONS] design-bound module aggregate PASS"
