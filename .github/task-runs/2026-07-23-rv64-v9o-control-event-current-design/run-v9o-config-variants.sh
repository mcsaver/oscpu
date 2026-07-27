#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
testbench_dir="${repo_root}/npc/rv64/testbench"
result_root="${repo_root}/.github/task-runs/2026-07-23-rv64-v9o-control-event-current-design/config-variants"
ivflags="-g2012 -Wall -I${repo_root}/npc/rv64/vsrc -I${repo_root}/npc/rv64/vsrc/include -I${testbench_dir}/common -DOOO_ASSERT -DOOO_CSR_QUEUE_HEAD=1"
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

run_variant() {
  local test_name="$1"
  local build_dir="$2"
  local log_path="${result_root}/logs/${test_name}.log"

  make -B -C "${testbench_dir}" \
    "BUILD_DIR=${build_dir}" \
    "RESULT_DIR=${result_root}" \
    "IVFLAGS=${ivflags}" \
    "RTL_EVIDENCE_SHA=${design_sha_pre}" \
    "${log_path}"
  grep -F "[RTL-DESIGN-ID] sha256:${design_sha_pre}" "${log_path}"
}

run_variant tb_ooo_rob build-v9o-csr-qh-on
run_variant tb_ooo_core_top_glue_v9o_csr_qh build-v9o-core-csr-qh-on
run_variant tb_ooo_core_top_glue build-v9o-core-csr-qh-on

grep -F "[S2-Q2-V8A-CSR-QH-PASS]" "${result_root}/logs/tb_ooo_rob.log"
grep -F "[V9O-CSR-OWNER-CLASS-PASS]" "${result_root}/logs/tb_ooo_rob.log"
grep -F "[PASS] tb_ooo_rob" "${result_root}/logs/tb_ooo_rob.log"
grep -F "[V9O-CSR-QH-CORE-INTEGRATION]" \
  "${result_root}/logs/tb_ooo_core_top_glue_v9o_csr_qh.log"
grep -F "[V9O-PENDING-CSR-OWNER-INTEGRATION]" \
  "${result_root}/logs/tb_ooo_core_top_glue_v9o_csr_qh.log"
grep -F "[V9O-CSR-MEMORY-ORDER-INTEGRATION]" \
  "${result_root}/logs/tb_ooo_core_top_glue_v9o_csr_qh.log"
grep -F "[PASS] tb_ooo_core_top_glue_v9o_csr_qh" \
  "${result_root}/logs/tb_ooo_core_top_glue_v9o_csr_qh.log"
grep -F "[PASS] tb_ooo_core_top_glue" \
  "${result_root}/logs/tb_ooo_core_top_glue.log"

design_sha_post="$(rtl_design_sha)"
[[ "${design_sha_post}" == "${design_sha_pre}" ]] || {
  printf '%s\n' \
    "[V9O-CONFIG-VARIANTS][FAIL] live RTL changed during macro-on run" >&2
  exit 1
}
verification_sha_post="$(
  python3 "${source_id_tool}" --root "${repo_root}" --kind verification
)"
[[ "${verification_sha_post}" == "${verification_sha_pre}" ]] || {
  printf '%s\n' \
    "[V9O-CONFIG-VARIANTS][FAIL] verification sources changed during macro-on run" >&2
  exit 1
}
for test_name in \
  tb_ooo_rob \
  tb_ooo_core_top_glue_v9o_csr_qh \
  tb_ooo_core_top_glue; do
  printf '[V9O-VERIFICATION-SOURCE-ID] sha256:%s\n' \
    "${verification_sha_pre}" \
    >> "${result_root}/logs/${test_name}.log"
done

printf '%s\n' \
  "[V9O-CONFIG-VARIANTS] OOO_CSR_QUEUE_HEAD=1 design_id=sha256:${design_sha_pre} verification_id=sha256:${verification_sha_pre} source_stable=true ROB/focused/core aggregate PASS"
