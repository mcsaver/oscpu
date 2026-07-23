#!/usr/bin/env bash
set -euo pipefail

# Local RV64 Verilog/SystemVerilog verification only.  This runner binds the
# real OooIntBackend + OooDualMemBridgeWrapper recovery trace, its two
# compile-success RTL verification mutations, adjacent regressions and the
# repository assertion contract into one reproducible evidence entry point.

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd -- "${SCRIPT_DIR}/../../.." && pwd)
TB_DIR="${REPO_ROOT}/npc/rv64/testbench"
EVIDENCE_DIR="${SCRIPT_DIR}/evidence"
BUILD_DIR="/tmp/rv64-v8x-backend-bridge-recovery"

mkdir -p "${EVIDENCE_DIR}/focused" "${EVIDENCE_DIR}/regressions"

make -C "${TB_DIR}" \
  RESULT_DIR="${EVIDENCE_DIR}/focused" \
  BUILD_DIR="${BUILD_DIR}/focused" \
  v8x-backend-bridge-recovery

python3 "${SCRIPT_DIR}/run-v8x-mutations.py"

make -C "${TB_DIR}" \
  RESULT_DIR="${EVIDENCE_DIR}/regressions" \
  BUILD_DIR="${BUILD_DIR}/regressions" \
  v8x-backend-bridge-regressions

make -C "${TB_DIR}" \
  RESULT_DIR="${EVIDENCE_DIR}/regressions" \
  BUILD_DIR="${BUILD_DIR}/regressions" \
  "${EVIDENCE_DIR}/regressions/logs/tb_ooo_int_backend.log" \
  "${EVIDENCE_DIR}/regressions/logs/tb_ooo_core_top_glue.log"

make -C "${REPO_ROOT}/npc/rv64" check-contract \
  2>&1 | tee "${EVIDENCE_DIR}/check-contract.log"

git -C "${REPO_ROOT}" diff --check -- \
  npc/rv64/testbench/Makefile \
  npc/rv64/testbench/tests/tb_ooo_int_backend.sv \
  npc/rv64/testbench/tests/tb_ooo_int_backend_v8x_bridge.svh \
  .github/task-runs/2026-07-21-rv64-v8x-backend-bridge-recovery \
  2>&1 | tee "${EVIDENCE_DIR}/diff-check.log"

sha256sum \
  "${REPO_ROOT}/npc/rv64/vsrc/execute/OooIntBackend.v" \
  "${REPO_ROOT}/npc/rv64/vsrc/memory/OooMemAxiBridge.v" \
  "${REPO_ROOT}/npc/rv64/vsrc/memory/OooDualMemBridgeWrapper.v" \
  "${REPO_ROOT}/npc/rv64/vsrc/memory/OooDualMemAxiArbiter.v" \
  "${REPO_ROOT}/npc/rv64/testbench/tests/tb_ooo_int_backend.sv" \
  "${REPO_ROOT}/npc/rv64/testbench/tests/tb_ooo_int_backend_v8x_bridge.svh" \
  "${REPO_ROOT}/npc/rv64/testbench/Makefile" \
  "${REPO_ROOT}/npc/rv64/Makefile" \
  "${SCRIPT_DIR}/run-focused.sh" \
  "${SCRIPT_DIR}/run-v8x-mutations.py" \
  "${SCRIPT_DIR}/subagent-contracts/v8x-backend-bridge-recovery-contract-review.json" \
  "${SCRIPT_DIR}/subagent-contracts/v8x-backend-bridge-recovery-final-review.json" \
  "${SCRIPT_DIR}/subagent-contracts/v8x-backend-bridge-recovery-evidence-review-v2.json" \
  "${SCRIPT_DIR}/final-review-result.json" \
  > "${EVIDENCE_DIR}/sha256-manifest.txt"

rg -q '\[V8X-BACKEND-BRIDGE-RECOVERY\].*PASS' \
  "${EVIDENCE_DIR}/focused/logs/tb_ooo_int_backend_v8x_backend_bridge_recovery.log"
rg -q '\[RESULT\] PASS' \
  "${EVIDENCE_DIR}/focused/logs/tb_ooo_int_backend_v8x_backend_bridge_recovery.log"
rg -q 'compile-success: 2/2' "${SCRIPT_DIR}/mutations/summary.md"
rg -q 'rejected: 2/2' "${SCRIPT_DIR}/mutations/summary.md"
rg -q '\[RESULT\] PASS' \
  "${EVIDENCE_DIR}/regressions/logs/tb_ooo_int_backend_v8w_memory_recovery.log" \
  "${EVIDENCE_DIR}/regressions/logs/tb_ooo_mem_axi_bridge.log" \
  "${EVIDENCE_DIR}/regressions/logs/tb_ooo_dual_mem_bridge_wrapper.log" \
  "${EVIDENCE_DIR}/regressions/logs/tb_ooo_int_backend.log" \
  "${EVIDENCE_DIR}/regressions/logs/tb_ooo_core_top_glue.log"
rg -q 'check-contract: PASS' "${EVIDENCE_DIR}/check-contract.log"

printf '[V8X-RUNNER] baseline=1 mutations=2/2 regressions=5/5 contract=PASS\n'
