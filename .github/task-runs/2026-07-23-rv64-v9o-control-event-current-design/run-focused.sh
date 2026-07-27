#!/usr/bin/env bash
set -euo pipefail

# Canonical local RV64/SystemVerilog V9O focused verification.  Every target
# is rebuilt so the logs are fresh against the live RTL source tree.

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
testbench_dir="${repo_root}/npc/rv64/testbench"
result_root="${repo_root}/.github/task-runs/2026-07-23-rv64-v9o-control-event-current-design/focused"
build_dir="${testbench_dir}/build-v9o-control"
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

tests=(
  tb_ooo_control_event_apply_sequencer
  tb_ooo_redirect_arbiter
  tb_ooo_frontend_action_gate
  tb_ooo_load_queue
  tb_ooo_rob
  tb_ooo_dispatch_backend
  tb_ooo_int_backend
  tb_ooo_mem_axi_bridge
  tb_ooo_dual_mem_bridge_wrapper
  tb_ooo_core_top_glue
)

for test_name in "${tests[@]}"; do
  log_path="${result_root}/logs/${test_name}.log"
  make -B -C "${testbench_dir}" \
    "BUILD_DIR=${build_dir}" \
    "RESULT_DIR=${result_root}" \
    "RTL_EVIDENCE_SHA=${design_sha_pre}" \
    "${log_path}"
  grep -F "[RTL-DESIGN-ID] sha256:${design_sha_pre}" "${log_path}"
  grep -F "[RESULT] PASS" "${log_path}"
done

design_sha_post="$(rtl_design_sha)"
[[ "${design_sha_post}" == "${design_sha_pre}" ]] || {
  printf '%s\n' "[V9O-FOCUSED][FAIL] live RTL changed during focused run" >&2
  exit 1
}
verification_sha_post="$(
  python3 "${source_id_tool}" --root "${repo_root}" --kind verification
)"
[[ "${verification_sha_post}" == "${verification_sha_pre}" ]] || {
  printf '%s\n' \
    "[V9O-FOCUSED][FAIL] verification sources changed during focused run" >&2
  exit 1
}
for test_name in "${tests[@]}"; do
  printf '[V9O-VERIFICATION-SOURCE-ID] sha256:%s\n' \
    "${verification_sha_pre}" \
    >> "${result_root}/logs/${test_name}.log"
done

printf '%s\n' \
  "[V9O-FOCUSED] tests=${#tests[@]} design_id=sha256:${design_sha_pre} verification_id=sha256:${verification_sha_pre} source_stable=true status=PASS"
