#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
task_run_dir="${repo_root}/.github/task-runs/2026-07-23-rv64-v9p-serialize-current-design"
result_name="${V9Q_ROOTFS_RESULT_NAME:-rootfs-v9q-terminal-pair-a1}"
result_dir="${task_run_dir}/${result_name}"
status_path="${task_run_dir}/${result_name}.status"
simulator="${repo_root}/npc/rv64/build-csrqh/NpcSimTop"
expected_design_sha="4655eabea13d2ecce9ac94784bbcb0a8bd2151b65bcd7325f950c6abb9b91380"
host_timeout_seconds="${V9Q_ROOTFS_HOST_TIMEOUT_SECONDS:-21600}"
commit_gap_limit_cycles="${V9Q_ROOTFS_COMMIT_GAP_LIMIT_CYCLES:-1000000}"
progress_interval="${V9Q_ROOTFS_PROGRESS_INTERVAL:-5000000}"
config_restored=0
status_written=0

mkdir -p "${result_dir}"
printf '%s\n' "RUNNING" > "${status_path}"
printf '%s\n' "$$" > "${result_dir}/runner.pid"
date -Ins > "${result_dir}/started-at.txt"

restore_npc_config() {
  if [[ "${config_restored}" -eq 0 ]]; then
    make -C "${repo_root}/npc/rv64" default_defconfig \
      > "${result_dir}/config-restore.log" 2>&1
    config_restored=1
  fi
}

finish() {
  local rc=$?
  set +e
  restore_npc_config
  if [[ "${status_written}" -eq 0 ]]; then
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

rm -f "${simulator}"
make -C "${repo_root}/Linux" \
  ARCH=riscv64-npc \
  BOOT=ubuntu-rootfs \
  NPC_OOO_CSR_QUEUE_HEAD=1 \
  NPC_OOO_TERMINAL_HOLDER_ASSERT=1 \
  NPC_FAST_SIM=1 \
  VERILATOR='verilator -Wno-fatal' \
  sim > "${result_dir}/sim-build.log" 2>&1
test -x "${simulator}"
simulator_sha_pre="$(sha256sum "${simulator}" | awk '{print $1}')"

set +e
ulimit -c 0
NPC_COMMIT_GAP_LIMIT_CYCLES="${commit_gap_limit_cycles}" \
NPC_USER_PROGRESS_INTERVAL="${progress_interval}" \
NPC_USER_PROGRESS_LIMIT=256 \
NPC_SYSTEMD_HOST_TIMEOUT="${host_timeout_seconds}" \
make -C "${repo_root}/Linux" \
  ARCH=riscv64-npc \
  BOOT=ubuntu-rootfs \
  NPC_OOO_CSR_QUEUE_HEAD=1 \
  NPC_OOO_TERMINAL_HOLDER_ASSERT=1 \
  NPC_FAST_SIM=1 \
  VERILATOR='verilator -Wno-fatal' \
  NPC_SYSTEMD_CHECK_LOG_DIR="${result_dir}/guest" \
  NPC_SYSTEMD_PROGRESS="${progress_interval}" \
  check-npc-systemd-guest-full \
  > "${result_dir}/driver.log" 2>&1
run_rc=$?
set -e

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
simulator_sha_post="$(sha256sum "${simulator}" | awk '{print $1}')"
[[ "${design_sha_post}" == "${design_sha_pre}" ]]
[[ "${simulator_sha_post}" == "${simulator_sha_pre}" ]]

{
  printf 'rtl_design_id=sha256:%s\n' "${design_sha_pre}"
  printf 'simulator_sha256=%s\n' "${simulator_sha_pre}"
  printf '%s\n' "OOO_CSR_QUEUE_HEAD=1"
  printf '%s\n' "OOO_TERMINAL_HOLDER_ASSERT=1"
  printf 'host_timeout_seconds=%s\n' "${host_timeout_seconds}"
  printf 'NPC_COMMIT_GAP_LIMIT_CYCLES=%s\n' "${commit_gap_limit_cycles}"
  printf 'progress_interval=%s\n' "${progress_interval}"
  printf 'guest_driver_rc=%s\n' "${run_rc}"
  sha256sum \
    "${repo_root}/Linux/env/platforms/npc/build/linux/arch/riscv/boot/Image" \
    "${repo_root}/Linux/env/platforms/npc/build/opensbi/rootfs/platform/generic/firmware/fw_jump.bin" \
    "${repo_root}/Linux/build/riscv64-npc/npc-rv64-rootfs.dtb" \
    "${repo_root}/Linux/env/platforms/npc/images/ubuntu2204/ubuntu-22.04-riscv64.ext4"
} > "${result_dir}/binding.txt"

if [[ "${run_rc}" -eq 0 ]]; then
  grep -F "[npc-systemd-check] PASS strict guest + natural poweroff" \
    "${result_dir}/driver.log"
  printf '%s\n' "PASS" > "${status_path}"
  status_written=1
  printf '%s\n' \
    "[V9Q-ROOTFS-TERMINAL-PAIR] strict guest + natural poweroff PASS"
  exit 0
fi

marker_pattern='\[V9Q-(BRIDGE-HOLDER|TRANSIENT-HOLDER|TRANSIENT-BRIDGE|DUAL-REQ-TOKEN)-DISJOINT\]|\[S2-G1-TCOLL-INGRESS-DUP\]'
if rg -n "${marker_pattern}" \
    "${result_dir}/driver.log" "${result_dir}/guest" \
    > "${result_dir}/terminal-markers.txt"; then
  python3 - "${result_dir}" "${design_sha_pre}" \
    "${simulator_sha_pre}" "${run_rc}" <<'PY'
import json
import pathlib
import re
import sys

result_dir = pathlib.Path(sys.argv[1])
texts = []
for path in [result_dir / "driver.log", result_dir / "guest" / "npc.log"]:
    if path.is_file():
        texts.append(path.read_text(encoding="utf-8", errors="replace"))
text = "\n".join(texts)

lanes = []
for match in re.finditer(
    r"\[S2-G1-TCOLL-INGRESS\] lane=(\d+) kind=([01]+) "
    r"token=(\d+) epoch=([01]+) duplicate=([01]) pending=([01]) live=([01])",
    text,
):
    lanes.append(
        {
            "lane": int(match.group(1)),
            "kind": match.group(2),
            "token": int(match.group(3)),
            "epoch": match.group(4),
            "duplicate": int(match.group(5)),
            "pending": int(match.group(6)),
            "live": int(match.group(7)),
        }
    )

holder_markers = re.findall(
    r"\[(V9Q-(?:BRIDGE-HOLDER|TRANSIENT-HOLDER|TRANSIENT-BRIDGE|"
    r"DUAL-REQ-TOKEN)-DISJOINT)\][^\n]*",
    text,
)
classification = {
    "diagnostic_status": "CAPTURED",
    "rootfs_gate_status": "FAIL",
    "promotion_eligible": False,
    "rtl_design_id": f"sha256:{sys.argv[2]}",
    "simulator_sha256": sys.argv[3],
    "guest_driver_rc": int(sys.argv[4]),
    "collector_duplicate_lanes": lanes,
    "holder_markers": sorted(set(holder_markers)),
    "root_cause_status": "GAP",
}
(result_dir / "classification.json").write_text(
    json.dumps(classification, indent=2, sort_keys=True) + "\n",
    encoding="utf-8",
)
PY
  printf 'DIAGNOSTIC_CAPTURED rc=%s\n' "${run_rc}" > "${status_path}"
  status_written=1
  printf '%s\n' \
    "[V9Q-ROOTFS-TERMINAL-PAIR] terminal lane/holder evidence captured"
  exit 0
fi

printf 'FAIL rc=%s\n' "${run_rc}" > "${status_path}"
status_written=1
exit "${run_rc}"
