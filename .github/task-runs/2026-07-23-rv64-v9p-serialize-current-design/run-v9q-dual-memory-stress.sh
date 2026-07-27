#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
task_run_dir="${repo_root}/.github/task-runs/2026-07-23-rv64-v9p-serialize-current-design"
stress_dir="${task_run_dir}/terminal-duplicate-focused"
result_dir="${stress_dir}/dual-memory-stress"
status_path="${stress_dir}/dual-memory-stress.status"
makefile="${stress_dir}/terminal-stress.mk"
image="${stress_dir}/build/ooo-dual-memory-stress-riscv64-npc.bin"
simulator="${repo_root}/npc/rv64/build-csrqh/NpcSimTop"
expected_design_sha="4655eabea13d2ecce9ac94784bbcb0a8bd2151b65bcd7325f950c6abb9b91380"

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

AM_HOME="${repo_root}/abstract-machine" \
make -B -C "${stress_dir}" -f "${makefile}" \
  ARCH=riscv64-npc image > "${result_dir}/image-build.log" 2>&1
test -f "${image}"

make -C "${repo_root}/npc/rv64" \
  OOO_CSR_QUEUE_HEAD=1 \
  OOO_TERMINAL_HOLDER_ASSERT=1 \
  CXX=/usr/bin/clang++ \
  LINK=/usr/bin/clang++ \
  VERILATOR='verilator -Wno-fatal' \
  VERILATOR_OPT_FAST='-O3 -march=native' \
  VERILATOR_OPT_GLOBAL='-O3 -march=native' \
  > "${result_dir}/sim-build.log" 2>&1
test -x "${simulator}"

set +e
timeout 900s "${simulator}" "${image}" \
  --no-diff --no-progress --max-cycles 20000000 \
  > "${result_dir}/sim.log" 2>&1
sim_rc=$?
set -e

if [[ "${sim_rc}" -ne 0 ]]; then
  rg -n \
    '\[V9Q-(BRIDGE-HOLDER|TRANSIENT-HOLDER|TRANSIENT-BRIDGE|DUAL-REQ-TOKEN)-DISJOINT\]|\[S2-G1-TCOLL-INGRESS-DUP\]' \
    "${result_dir}/sim.log" > "${result_dir}/terminal-markers.txt" || true
  exit "${sim_rc}"
fi

grep -F "HIT GOOD TRAP" "${result_dir}/sim.log"
if rg -n \
    '\[V9Q-(BRIDGE-HOLDER|TRANSIENT-HOLDER|TRANSIENT-BRIDGE|DUAL-REQ-TOKEN)-DISJOINT\]|\[S2-G1-TCOLL-INGRESS-DUP\]' \
    "${result_dir}/sim.log" > "${result_dir}/terminal-markers.txt"; then
  printf '%s\n' \
    "[V9Q-DUAL-MEMORY-STRESS][FAIL] terminal diagnostic marker in passing run"
  exit 1
fi

{
  printf 'rtl_design_id=sha256:%s\n' "${design_sha}"
  printf 'simulator_sha256=%s\n' "$(sha256sum "${simulator}" | awk '{print $1}')"
  printf 'image_sha256=%s\n' "$(sha256sum "${image}" | awk '{print $1}')"
  printf '%s\n' "OOO_CSR_QUEUE_HEAD=1"
  printf '%s\n' "OOO_TERMINAL_HOLDER_ASSERT=1"
  printf '%s\n' "rounds=131072"
  printf '%s\n' "max_cycles=20000000"
} > "${result_dir}/binding.txt"

printf '%s\n' \
  "[V9Q-DUAL-MEMORY-STRESS] dual-bank owner-token recycling PASS"
