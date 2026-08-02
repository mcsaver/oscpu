#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../.." && pwd)"
output_dir="${1:-}"
legacy_runner="${repo_root}/.github/task-runs/2026-07-23-rv64-v9p-serialize-current-design/run-terminal-duplicate-diagnostic.sh"
snapshot_tool="${repo_root}/.github/task-runs/2026-07-20-rv64-v8l-global-producer-no-live-reuse/build-current-census-evidence.py"

fail() {
  printf '[V12A-TERMINAL-DUPLICATE-CURRENT][FAIL] %s\n' "$*" >&2
  exit 1
}

if [[ -z "${output_dir}" || "${output_dir}" != /* ]]; then
  fail "usage: $0 /absolute/repo/.github/task-runs/<run>/evidence/<attempt>"
fi
case "${output_dir}" in
  "${repo_root}"/.github/task-runs/*/evidence/*) ;;
  *) fail "output must be a task-run evidence directory below the repository" ;;
esac
if [[ -e "${output_dir}" ]]; then
  fail "refusing to overwrite existing evidence: ${output_dir#${repo_root}/}"
fi
mkdir -p "${output_dir}"

source_paths=(
  "npc/rv64/testbench/scripts/run_terminal_duplicate_current.sh"
  ".github/task-runs/2026-07-23-rv64-v9p-serialize-current-design/run-terminal-duplicate-diagnostic.sh"
  ".github/task-runs/2026-07-23-rv64-v9p-serialize-current-design/mutate-terminal-holder-identity.py"
  ".github/task-runs/2026-07-20-rv64-v8s-dual-memory-core-integration/mutate-v8s-dual-memory-core.py"
  "npc/rv64/vsrc/execute/OooIntBackend.v"
  "npc/rv64/vsrc/memory/OooMemAxiBridge.v"
  "npc/rv64/vsrc/memory/OooMemOwnerTerminalCollector.v"
  "npc/rv64/testbench/Makefile"
  "npc/rv64/testbench/scripts/check_tb_result.py"
  "npc/rv64/testbench/tests/tb_ooo_int_backend.sv"
  "npc/rv64/testbench/tests/tb_ooo_int_backend_v8x_bridge.svh"
)

(
  cd "${repo_root}"
  sha256sum "${source_paths[@]}"
) > "${output_dir}/sources.pre.sha256"
python3 "${snapshot_tool}" \
  --snapshot-out "${output_dir}/rtl-source-binding.pre.json"

RV64_TERMINAL_DIAGNOSTIC_RESULT_DIR="${output_dir}" \
  bash "${legacy_runner}"

(
  cd "${repo_root}"
  sha256sum "${source_paths[@]}"
) > "${output_dir}/sources.post.sha256"
cmp -s "${output_dir}/sources.pre.sha256" \
  "${output_dir}/sources.post.sha256" ||
  fail "focused source set changed during execution"
python3 "${snapshot_tool}" \
  --snapshot-out "${output_dir}/rtl-source-binding.post.json"
cmp -s "${output_dir}/rtl-source-binding.pre.json" \
  "${output_dir}/rtl-source-binding.post.json" ||
  fail "full RTL source set changed during execution"

design_id="$(jq -r '.design_id' "${output_dir}/rtl-source-binding.pre.json")"
[[ "${design_id}" =~ ^sha256:[0-9a-f]{64}$ ]] ||
  fail "snapshot did not provide a valid design id"
grep -Fq "${repo_root}/npc/rv64/vsrc/execute/OooIntBackend.v" \
  "${output_dir}/positive.log" ||
  fail "positive.log did not compile the live OooIntBackend source"
grep -Fq "${repo_root}/npc/rv64/vsrc/memory/OooMemOwnerTerminalCollector.v" \
  "${output_dir}/positive.log" ||
  fail "positive.log did not compile the live terminal collector source"
grep -Fq "${repo_root}/npc/rv64/vsrc/execute/OooIntBackend.v" \
  "${output_dir}/bridge-positive.log" ||
  fail "bridge-positive.log did not compile the live OooIntBackend source"
grep -Fq "${repo_root}/npc/rv64/vsrc/memory/OooMemAxiBridge.v" \
  "${output_dir}/bridge-positive.log" ||
  fail "bridge-positive.log did not compile the live bridge source"

retained_vvp="$(find "${output_dir}" -type f -name '*.vvp' -print -quit)"
[[ -z "${retained_vvp}" ]] ||
  fail "transient compiled image leaked into evidence"
printf '%s\n' \
  "design_id=${design_id}" \
  "source_binding=PASS_PRE_POST_AND_COMPILE_PATH" \
  "retained_vvp=0" \
  >> "${output_dir}/summary.txt"
printf '%s\n' \
  "[V12A-TERMINAL-DUPLICATE-CURRENT][PASS] design_id=${design_id} pair=2,4 mutations=3/3 retained_vvp=0"
