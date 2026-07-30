#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
task_run_dir="${repo_root}/.github/task-runs/2026-07-27-rv64-v10e-current-design-system-recert"
status_path="${task_run_dir}/debug-valid-enabled-smoke-v2.status"
opensbi_fw="${repo_root}/Linux/env/platforms/npc/build/opensbi/rootfs/platform/generic/firmware/fw_jump.bin"
config_path="${repo_root}/npc/rv64/.config"
auto_conf_path="${repo_root}/npc/rv64/include/config/auto.conf"
autoconf_header_path="${repo_root}/npc/rv64/include/generated/autoconf.h"
sim_top_path="${repo_root}/npc/rv64/vsrc/sim/NpcSimTop.sv"
cpu_exec_path="${repo_root}/npc/rv64/csrc/cpu/cpu-exec.cpp"

compute_design_sha() {
  PYTHONPATH="${repo_root}/npc/rv64/eval/ppa/tools" \
    python3 - "${repo_root}" <<'PY'
import pathlib
import sys

import architecture_hard_gates as arch

print(arch.rtl_binding(pathlib.Path(sys.argv[1]))[0])
PY
}

design_sha_pre="$(compute_design_sha)"
design_prefix="${design_sha_pre:0:8}"
config_sha_pre="$(sha256sum "${config_path}" | awk '{print $1}')"
auto_conf_sha_pre="$(sha256sum "${auto_conf_path}" | awk '{print $1}')"
autoconf_header_sha_pre="$(
  sha256sum "${autoconf_header_path}" | awk '{print $1}'
)"
sim_top_sha_pre="$(sha256sum "${sim_top_path}" | awk '{print $1}')"
cpu_exec_sha_pre="$(sha256sum "${cpu_exec_path}" | awk '{print $1}')"
runtime_dir="${repo_root}/.github/runtime-artifacts/rv64-systemd-strict/prelaunch-${design_prefix}-debug-valid-enabled-v2"
build_dir="${runtime_dir}/sim-build"
simulator="${build_dir}/NpcSimTop"
verilator_manifest="${build_dir}/obj_dir/VNpcSimTop__verFiles.dat"
build_log="${runtime_dir}/build.log"
console_log="${runtime_dir}/console.log"
npc_log="${runtime_dir}/npc.log"
validation_log="${runtime_dir}/validation.log"

test ! -e "${status_path}"
test ! -e "${runtime_dir}"
mkdir -p "${runtime_dir}"
printf 'RUNNING design_sha_pre=%s\n' "${design_sha_pre}" >"${status_path}"

verify_unchanged() {
  local label="${1:?binding label is required}"
  local path="${2:?binding path is required}"
  local expected="${3:?binding pre-hash is required}"
  local actual=""

  actual="$(sha256sum "${path}" | awk '{print $1}')" || return 1
  printf '%s_pre_sha256=%s\n%s_post_sha256=%s\n' \
    "${label}" "${expected}" "${label}" "${actual}" >>"${validation_log}"
  [[ "${actual}" == "${expected}" ]]
}

finalize() {
  local rc=$?
  local design_sha_post=""
  local simulator_sha=""

  design_sha_post="$(compute_design_sha)" || rc=1
  printf 'design_sha_pre=%s\ndesign_sha_post=%s\n' \
    "${design_sha_pre}" "${design_sha_post:-HASH_FAILED}" >>"${validation_log}"
  if [[ "${design_sha_post}" != "${design_sha_pre}" ]]; then
    rc=1
  fi
  verify_unchanged "npc_config" "${config_path}" "${config_sha_pre}" || rc=1
  verify_unchanged \
    "npc_auto_conf" "${auto_conf_path}" "${auto_conf_sha_pre}" || rc=1
  verify_unchanged \
    "npc_autoconf_header" "${autoconf_header_path}" \
    "${autoconf_header_sha_pre}" || rc=1
  verify_unchanged \
    "npc_sim_top" "${sim_top_path}" "${sim_top_sha_pre}" || rc=1
  verify_unchanged \
    "npc_cpu_exec" "${cpu_exec_path}" "${cpu_exec_sha_pre}" || rc=1
  if [[ "${rc}" -eq 0 ]]; then
    simulator_sha="$(sha256sum "${simulator}" | awk '{print $1}')" || rc=1
  fi
  if [[ "${rc}" -eq 0 ]]; then
    printf 'PASS design_sha_pre=%s design_sha_post=%s simulator_sha=%s config_unchanged=1 source_unchanged=1\n' \
      "${design_sha_pre}" "${design_sha_post}" "${simulator_sha}" \
      >"${status_path}"
  else
    printf 'FAIL rc=%s design_sha_pre=%s design_sha_post=%s\n' \
      "${rc}" "${design_sha_pre}" "${design_sha_post:-HASH_FAILED}" \
      >"${status_path}"
  fi
}
trap finalize EXIT

make -C "${repo_root}/npc/rv64" \
  BUILD_DIR="${build_dir}" \
  CONFIG_NPC_DEBUG_PORTS=y \
  OOO_CSR_QUEUE_HEAD=1 \
  OOO_TERMINAL_HOLDER_ASSERT=1 \
  VERILATOR_BUILD_JOBS=2 \
  -j2 >"${build_log}" 2>&1

test -x "${simulator}"
test -f "${verilator_manifest}"
grep -Fq '+define+CONFIG_NPC_DEBUG_PORTS' "${verilator_manifest}"

set +e
"${simulator}" \
  -b \
  --no-diff \
  --no-vga \
  --max-cycles=64 \
  --log="${npc_log}" \
  -i "${opensbi_fw}" >"${console_log}" 2>&1
sim_rc=$?
set -e

python3 - "${console_log}" "${sim_rc}" >"${validation_log}" <<'PY'
import pathlib
import re
import sys

console_path = pathlib.Path(sys.argv[1])
sim_rc = int(sys.argv[2])
text = console_path.read_text(encoding="utf-8", errors="replace")
if sim_rc != 1:
    raise SystemExit(f"unexpected simulator rc={sim_rc}, expected=1")
match = re.search(
    r"ooo flags=0x([0-9a-fA-F]{16}) valid=([01])"
    r".*?\bstop=([01])\b",
    text,
)
if match is None:
    raise SystemExit("missing debug flags observation")
flags = int(match.group(1), 16)
valid = int(match.group(2))
stop = int(match.group(3))
if valid != 1:
    raise SystemExit(f"debug valid mismatch: {valid}")
if ((flags >> 63) & 1) != 1:
    raise SystemExit(f"bit63 is clear: 0x{flags:016x}")
if ((flags >> 46) & 0x1FFFF) != 0:
    raise SystemExit(f"reserved bits[62:46] are nonzero: 0x{flags:016x}")
if "cycles=64, commits=6" not in text:
    raise SystemExit("64-cycle OpenSBI smoke marker missing")
print(
    "[V10E-DEBUG-VALID-ENABLED] "
    f"flags=0x{flags:016x} valid={valid} reserved_62_46=0 "
    f"stop={stop} cycles=64 commits=6 sim_rc={sim_rc} PASS"
)
PY
