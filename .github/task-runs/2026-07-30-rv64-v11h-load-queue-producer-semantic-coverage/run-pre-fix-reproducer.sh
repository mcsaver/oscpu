#!/usr/bin/env bash
set -euo pipefail

run_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(git -C "${run_dir}" rev-parse --show-toplevel)"
evidence_dir="${run_dir}/evidence/pre-fix-prior-terminal-recovery"
rtl="${repo_root}/npc/rv64/vsrc/memory/OooLoadQueue.v"
tb="${repo_root}/npc/rv64/testbench/tests/tb_ooo_load_queue.sv"
image="${evidence_dir}/tb_ooo_load_queue.vvp"

fail() {
  printf '[V11H-PRE-FIX][FAIL] %s\n' "$*" >&2
  exit 1
}

if [[ -e "${evidence_dir}" ]]; then
  fail "evidence directory already exists"
fi
mkdir -p "${evidence_dir}"

(
  cd "${repo_root}"
  sha256sum \
    npc/rv64/vsrc/memory/OooLoadQueue.v \
    npc/rv64/testbench/tests/tb_ooo_load_queue.sv
) > "${evidence_dir}/sources.sha256"

set +e
iverilog \
  -g2012 \
  -Wall \
  -DOOO_PRODUCER_GEN_W=4 \
  -I"${repo_root}/npc/rv64/vsrc" \
  -I"${repo_root}/npc/rv64/vsrc/include" \
  -I"${repo_root}/npc/rv64/testbench/common" \
  -s tb_ooo_load_queue \
  -o "${image}" \
  "${tb}" \
  "${rtl}" \
  > "${evidence_dir}/compile.log" 2>&1
compile_rc=$?
set -e
printf '%s\n' "${compile_rc}" > "${evidence_dir}/compile.rc"
[[ "${compile_rc}" -eq 0 ]] ||
  fail "pre-fix discriminator did not compile"

set +e
vvp "${image}" +V11H_PRIOR_TERMINAL_REPRO_ONLY \
  > "${evidence_dir}/sim.log" 2>&1
sim_rc=$?
set -e
printf '%s\n' "${sim_rc}" > "${evidence_dir}/sim.rc"

[[ "${sim_rc}" -ne 0 ]] ||
  fail "pre-fix production RTL unexpectedly passed"
grep -q '\[V11H-LQ-PRIOR-TERMINAL-RECOVERY\]\[FAIL\]' \
  "${evidence_dir}/sim.log" ||
  fail "independent pre-fix oracle marker is missing"
grep -q '\[FAIL\] tb_ooo_load_queue_v11h_prior_terminal_recovery' \
  "${evidence_dir}/sim.log" ||
  fail "testbench final FAIL marker is missing"

printf '%s\n' \
  '[V11H-PRE-FIX][PASS] compile=0 assertion_mode=off dynamic_reproducer=rejected'
