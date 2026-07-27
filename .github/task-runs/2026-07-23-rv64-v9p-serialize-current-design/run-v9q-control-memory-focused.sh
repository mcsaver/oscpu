#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
task_run_dir="${repo_root}/.github/task-runs/2026-07-23-rv64-v9p-serialize-current-design"
result_dir="${task_run_dir}/terminal-duplicate-focused/control-memory-focused"
status_path="${task_run_dir}/terminal-duplicate-focused/control-memory-focused.status"
simulator="${repo_root}/npc/rv64/build-csrqh/NpcSimTop"
expected_design_sha="4655eabea13d2ecce9ac94784bbcb0a8bd2151b65bcd7325f950c6abb9b91380"
tests="branch-resolve-loop fence-i linux-mini-boot load-store mem-test ooo-mem-order plic-sirq sbi-ipi-reset-hsm sbi-timer sv39-ad-bits sv39-ras-relocate uart-plic-sirq unalign"

mkdir -p "${result_dir}/raw"
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
test -x "${simulator}"
simulator_sha_pre="$(sha256sum "${simulator}" | awk '{print $1}')"

set +e
timeout 1800s env AM_HOME="${repo_root}/abstract-machine" \
  make -C "${repo_root}/am-kernels/tests/cpu-tests" \
  ARCH=riscv64-npc \
  NPC_SIM_BACKEND=rv64 \
  OOO_CSR_QUEUE_HEAD=1 \
  OOO_TERMINAL_HOLDER_ASSERT=1 \
  ALL="${tests}" \
  RAW_LOG_DIR="${result_dir}/raw" \
  NPC_RUN_ARGS='--no-diff --no-progress --max-cycles 20000000' \
  run > "${result_dir}/driver.log" 2>&1
run_rc=$?
set -e

if [[ "${run_rc}" -ne 0 ]]; then
  rg -n \
    '\[V9Q-(BRIDGE-HOLDER|TRANSIENT-HOLDER|TRANSIENT-BRIDGE|DUAL-REQ-TOKEN)-DISJOINT\]|\[S2-G1-TCOLL-INGRESS-DUP\]' \
    "${result_dir}/raw" "${result_dir}/driver.log" \
    > "${result_dir}/terminal-markers.txt" || true
  exit "${run_rc}"
fi

test "$(find "${result_dir}/raw" -maxdepth 1 -type f -name '*.log' | wc -l)" \
  -eq 13
if rg -n \
    '\[V9Q-(BRIDGE-HOLDER|TRANSIENT-HOLDER|TRANSIENT-BRIDGE|DUAL-REQ-TOKEN)-DISJOINT\]|\[S2-G1-TCOLL-INGRESS-DUP\]' \
    "${result_dir}/raw" "${result_dir}/driver.log" \
    > "${result_dir}/terminal-markers.txt"; then
  printf '%s\n' \
    "[V9Q-CONTROL-MEMORY-FOCUSED][FAIL] terminal marker in passing run"
  exit 1
fi

simulator_sha_post="$(sha256sum "${simulator}" | awk '{print $1}')"
[[ "${simulator_sha_post}" == "${simulator_sha_pre}" ]]

{
  printf 'rtl_design_id=sha256:%s\n' "${design_sha}"
  printf 'simulator_sha256=%s\n' "${simulator_sha_pre}"
  printf '%s\n' "OOO_CSR_QUEUE_HEAD=1"
  printf '%s\n' "OOO_TERMINAL_HOLDER_ASSERT=1"
  printf 'tests=%s\n' "${tests}"
} > "${result_dir}/binding.txt"

printf '%s\n' \
  "[V9Q-CONTROL-MEMORY-FOCUSED] 13/13 privilege/control/memory images PASS"
