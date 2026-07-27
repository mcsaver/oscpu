#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
task_run_dir="${repo_root}/.github/task-runs/2026-07-23-rv64-v9p-serialize-current-design"
log_dir="${task_run_dir}/flag-on-build"
status_path="${task_run_dir}/flag-on-build.status"
simulator="${repo_root}/npc/rv64/build-csrqh/NpcSimTop"
expected_design_sha="9ac1ae14b18635cf25ea80efa7ce4cd85a07bdd6f0e525755658dc8dcd26207a"

mkdir -p "${log_dir}"
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

design_sha_pre="$(
  python3 - "${repo_root}" <<'PY'
import pathlib
import sys

root = pathlib.Path(sys.argv[1]).resolve()
sys.path.insert(0, str(root / "npc/rv64/eval/ppa/tools"))
import architecture_hard_gates as arch

print(arch.rtl_binding(root)[0])
PY
)"
[[ "${design_sha_pre}" == "${expected_design_sha}" ]]

# This evidence runner must not inherit the Linux/perf profile left in the
# shared NPC .config.  Full-state DiffTest requires the repository default
# profile and binds the regenerated config below.
make -C "${repo_root}/npc/rv64" default_defconfig \
  > "${log_dir}/config.log" 2>&1
grep -Fq "CONFIG_NPC_DIFFTEST=y" "${repo_root}/npc/rv64/.config"

make -C "${repo_root}/npc/rv64" \
  BUILD_DIR=build-csrqh \
  OOO_CSR_QUEUE_HEAD=1 \
  "VERILATOR=verilator -Wno-fatal" \
  -j2 default \
  > "${log_dir}/build.log" 2>&1

test -x "${simulator}"
"${simulator}" --help > "${log_dir}/help.log" 2>&1 || true
grep -F -- "--diff=SO" "${log_dir}/help.log"
if grep -Fq -- "unavailable: rebuild with CONFIG_NPC_DIFFTEST=y" \
    "${log_dir}/help.log"; then
  printf '%s\n' "[V9P-FLAG-ON-BUILD][FAIL] DiffTest is unavailable" >&2
  exit 1
fi

sha256sum "${repo_root}/npc/rv64/.config" "${simulator}" \
  > "${log_dir}/artifact-sha256.txt"
printf 'rtl_design_id=sha256:%s\n' "${design_sha_pre}" \
  > "${log_dir}/binding.txt"
printf '%s\n' "OOO_CSR_QUEUE_HEAD=1" >> "${log_dir}/binding.txt"

design_sha_post="$(
  python3 - "${repo_root}" <<'PY'
import pathlib
import sys

root = pathlib.Path(sys.argv[1]).resolve()
sys.path.insert(0, str(root / "npc/rv64/eval/ppa/tools"))
import architecture_hard_gates as arch

print(arch.rtl_binding(root)[0])
PY
)"
[[ "${design_sha_post}" == "${design_sha_pre}" ]]

printf '%s\n' \
  "[V9P-FLAG-ON-BUILD] OOO_CSR_QUEUE_HEAD=1 DiffTest-enabled simulator PASS"
