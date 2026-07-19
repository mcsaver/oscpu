#!/usr/bin/env bash
set -euo pipefail

run_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "${run_dir}/../../.." && pwd)"
rtl="${repo_root}/npc/rv64/vsrc/memory/OooMmuEpochOwner.v"
positive_tb="${repo_root}/npc/rv64/testbench/tests/tb_ooo_mmu_epoch_owner.sv"
negative_tb="${run_dir}/tb_q1a_abort_assert_negative.sv"
mutator="${run_dir}/mutate_q1a.py"
contract_checker="${run_dir}/check_q1a_abort_contract.py"
style_checker="${repo_root}/npc/rv64/eval/check-rtl-style.sh"
spec="${repo_root}/npc/rv64/design/specs/ooo-mmu-epoch-owner.md"
makefile="${repo_root}/npc/rv64/Makefile"
contract="${run_dir}/q1a-abort-priority-contract.md"
identity_review="${run_dir}/full-identity-reuse-counterexample-review.md"
build_dir="${S2_Q1A_BUILD_DIR:-$(mktemp -d /tmp/s2-q1a-abort.XXXXXX)}"

mkdir -p "${build_dir}/positive" "${build_dir}/negative" \
  "${build_dir}/mutations" "${build_dir}/gates"
rm -f "${build_dir}/completion.marker"

iverilog_bin="${IVERILOG:-$(command -v iverilog)}"
vvp_bin="${VVP:-$(dirname "${iverilog_bin}")/vvp}"
if [[ ! -x "${vvp_bin}" ]]; then
  vvp_bin="$(command -v vvp)"
fi
verilator_bin="${VERILATOR:-$(command -v verilator)}"
yosys_bin="${YOSYS:-${repo_root}/oss-cad-suite/bin/yosys}"
python_bin="${PYTHON:-$(command -v python3)}"

for required in "${iverilog_bin}" "${vvp_bin}" "${verilator_bin}" \
  "${yosys_bin}" "${python_bin}" "${style_checker}" "${mutator}" \
  "${contract_checker}"; do
  if [[ ! -x "${required}" ]]; then
    echo "required executable is missing: ${required}" >&2
    exit 1
  fi
done

ivflags=(
  -g2012 -Wall
  -I "${repo_root}/npc/rv64/vsrc"
  -I "${repo_root}/npc/rv64/vsrc/include"
  -I "${repo_root}/npc/rv64/testbench/common"
)

compile_positive() {
  local variant="$1"
  local define_flag="$2"
  local binary="${build_dir}/positive/${variant}.vvp"
  local compile_log="${build_dir}/positive/${variant}.compile.log"
  local sim_log="${build_dir}/positive/${variant}.sim.log"
  local extra=()
  if [[ "${define_flag}" == "assert" ]]; then
    extra=(-DOOO_ASSERT)
  fi
  if ! "${iverilog_bin}" "${ivflags[@]}" "${extra[@]}" \
      -s tb_ooo_mmu_epoch_owner -o "${binary}" "${positive_tb}" "${rtl}" \
      >"${compile_log}" 2>&1; then
    echo "positive ${variant} compile failed: ${compile_log}" >&2
    exit 1
  fi
  if ! "${vvp_bin}" "${binary}" >"${sim_log}" 2>&1; then
    echo "positive ${variant} simulation failed: ${sim_log}" >&2
    exit 1
  fi
  if [[ "$(grep -Fxc '[MMU-EPOCH-Q1][PASS] same-cycle-block/quiet/hold/second-request/multi-cause/wrap' "${sim_log}" || true)" -ne 1 ]] || \
     [[ "$(grep -Fxc '[MMU-EPOCH-Q1A][PASS] abort-idle/drain/commit/backpressure/epoch-stable' "${sim_log}" || true)" -ne 1 ]] || \
     [[ "$(grep -Fxc '[MMU-EPOCH-Q1A-REARM][PASS] continuous-valid-blocked-until-valid-low' "${sim_log}" || true)" -ne 1 ]] || \
     [[ "$(grep -Fxc '[PASS] tb_ooo_mmu_epoch_owner' "${sim_log}" || true)" -ne 1 ]] || \
     grep -Fq '[MMU-EPOCH-Q1][FAIL]' "${sim_log}"; then
    echo "positive ${variant} missed exact non-vacuous markers: ${sim_log}" >&2
    exit 1
  fi
}

compile_positive release release
compile_positive assert assert

negative_binary="${build_dir}/negative/assert-negative.vvp"
if ! "${iverilog_bin}" "${ivflags[@]}" -DOOO_ASSERT \
    -s tb_q1a_abort_assert_negative -o "${negative_binary}" \
    "${negative_tb}" "${rtl}" >"${build_dir}/negative/compile.log" 2>&1; then
  echo "assertion-negative compile failed: ${build_dir}/negative/compile.log" >&2
  exit 1
fi

negative_messages=(
  '[MMU-EPOCH-REQ-CAUSE] valid request carried no cause bit'
  '[MMU-EPOCH-REQ-HOLD] stalled request bundle changed or withdrew'
  '[MMU-EPOCH-GRANT-QUIET] quiet/live-empty dropped while grant was pending'
  '[MMU-EPOCH-STATE] illegal FSM encoding 11'
  '[MMU-EPOCH-ABORT-MASK] abort exposed a request/grant handshake'
)
negative_pass=0
for case_id in 1 2 3 4 5; do
  log="${build_dir}/negative/case-${case_id}.sim.log"
  set +e
  "${vvp_bin}" "${negative_binary}" "+CASE=${case_id}" >"${log}" 2>&1
  rc=$?
  set -e
  expected="${negative_messages[$((case_id - 1))]}"
  expected_count="$(grep -Fxc "${expected}" "${log}" || true)"
  named_count="$(grep -Ec '^\[MMU-EPOCH-[^]]+\]' "${log}" || true)"
  if [[ "${rc}" -eq 0 ]] || [[ "${expected_count}" -ne 1 ]] || \
     [[ "${named_count}" -ne 1 ]]; then
    echo "negative CASE=${case_id} missed unique assertion; rc=${rc} expected=${expected_count} named=${named_count}" >&2
    exit 1
  fi
  negative_pass=$((negative_pass + 1))
done

mutants=(
  no-lookahead
  no-quiet
  no-live-empty
  ready-dependent-grant
  live-input-payload
  advance-before-consume
  saturating-epoch
  no-abort-lookahead
  no-abort-ready-mask
  no-abort-grant-mask
  low-abort-priority
  abort-advances-epoch
  no-abort-rearm
)
mutation_markers=(
  '[MMU-EPOCH-Q1][FAIL] first request did not block capture in its presentation cycle'
  '[MMU-EPOCH-Q1][FAIL] quiet-low request advanced to grant'
  '[MMU-EPOCH-Q1][FAIL] live token did not block epoch grant'
  '[MMU-EPOCH-Q1][FAIL] commit-abort setup did not reach a held grant'
  '[MMU-EPOCH-Q1][FAIL] drain abort did not clear held bundle/state'
  '[MMU-EPOCH-Q1][FAIL] backpressured grant did not remain sticky before abort'
  '[MMU-EPOCH-Q1][FAIL] quiet helper grant did not consume exactly once and advance epoch'
  '[MMU-EPOCH-Q1][FAIL] idle abort did not immediately block capture'
  '[MMU-EPOCH-Q1][FAIL] idle abort did not immediately block capture'
  '[MMU-EPOCH-Q1][FAIL] abort did not suppress a ready grant in its presentation cycle'
  '[MMU-EPOCH-Q1][FAIL] aborted request was recaptured without a valid-low rearm'
  '[MMU-EPOCH-Q1][FAIL] idle abort changed epoch or failed to return unlocked'
  '[MMU-EPOCH-Q1][FAIL] aborted request was recaptured without a valid-low rearm'
)
mutation_pass=0
for index in "${!mutants[@]}"; do
  mutant="${mutants[$index]}"
  expected_marker="${mutation_markers[$index]}"
  mutant_rtl="${build_dir}/mutations/${mutant}.v"
  if ! "${python_bin}" "${mutator}" "${rtl}" "${mutant_rtl}" "${mutant}" \
      >"${build_dir}/mutations/${mutant}.mutate.log" 2>&1; then
    echo "mutation ${mutant} source rewrite failed" >&2
    exit 1
  fi
  binary="${build_dir}/mutations/${mutant}.vvp"
  compile_log="${build_dir}/mutations/${mutant}.compile.log"
  sim_log="${build_dir}/mutations/${mutant}.sim.log"
  if ! "${iverilog_bin}" "${ivflags[@]}" -s tb_ooo_mmu_epoch_owner \
      -o "${binary}" "${positive_tb}" "${mutant_rtl}" >"${compile_log}" 2>&1; then
    echo "mutation ${mutant} did not compile successfully: ${compile_log}" >&2
    exit 1
  fi
  set +e
  "${vvp_bin}" "${binary}" >"${sim_log}" 2>&1
  rc=$?
  set -e
  fail_count="$(grep -Fc '[MMU-EPOCH-Q1][FAIL]' "${sim_log}" || true)"
  if [[ "${rc}" -eq 0 ]] || [[ "${fail_count}" -ne 1 ]] || \
     ! grep -Fqx "${expected_marker}" "${sim_log}"; then
    echo "mutation ${mutant} missed its unique semantic oracle; rc=${rc} fail_count=${fail_count}" >&2
    exit 1
  fi
  mutation_pass=$((mutation_pass + 1))
done

if ! "${verilator_bin}" --lint-only -Wall --top-module OooMmuEpochOwner "${rtl}" \
    >"${build_dir}/gates/verilator-release.log" 2>&1; then
  echo "release Verilator lint failed" >&2
  exit 1
fi
if ! "${verilator_bin}" --lint-only -Wall -DOOO_ASSERT \
    --top-module OooMmuEpochOwner "${rtl}" \
    >"${build_dir}/gates/verilator-assert.log" 2>&1; then
  echo "assert Verilator lint failed" >&2
  exit 1
fi
if ! env RTL_FILES="${rtl}" "${style_checker}" \
    >"${build_dir}/gates/rtl-style.log" 2>&1; then
  echo "RTL style gate failed" >&2
  exit 1
fi
if ! "${yosys_bin}" -q -p \
    "read_verilog ${rtl}; hierarchy -check -top OooMmuEpochOwner; proc; opt; check" \
    >"${build_dir}/gates/yosys-check.log" 2>&1; then
  echo "Yosys leaf check failed" >&2
  exit 1
fi
if ! "${python_bin}" "${contract_checker}" \
    >"${build_dir}/gates/q1a-contract.log" 2>&1; then
  echo "Q1A structural contract failed: ${build_dir}/gates/q1a-contract.log" >&2
  exit 1
fi

sha256sum "${rtl}" "${positive_tb}" "${negative_tb}" "${mutator}" \
  "${contract_checker}" "${spec}" "${makefile}" "${contract}" \
  "${identity_review}" "${BASH_SOURCE[0]}" \
  >"${build_dir}/sources.sha256"

{
  printf '%s\n' 'S2-Q1A OooMmuEpochOwner abort-priority summary'
  printf 'scope=source-catalog-disabled-live-integration\n'
  printf 'release_positive=PASS\n'
  printf 'assert_positive=PASS\n'
  printf 'assertion_negative=5/5 PASS\n'
  printf 'compile_success_mutations=13/13 KILLED_BY_EXACT_ORACLE\n'
  printf 'verilator_release_lint=PASS\n'
  printf 'verilator_assert_lint=PASS\n'
  printf 'rtl_style=PASS\n'
  printf 'yosys_check=PASS\n'
  printf 'q1a_contract=PASS\n'
  printf 'rtl_sha256=%s\n' "$(sha256sum "${rtl}" | awk '{print $1}')"
  printf 'tb_sha256=%s\n' "$(sha256sum "${positive_tb}" | awk '{print $1}')"
  printf 'negative_tb_sha256=%s\n' "$(sha256sum "${negative_tb}" | awk '{print $1}')"
  printf 'spec_sha256=%s\n' "$(sha256sum "${spec}" | awk '{print $1}')"
  printf 'runner_sha256=%s\n' "$(sha256sum "${BASH_SOURCE[0]}" | awk '{print $1}')"
  printf 'iverilog_version=%s\n' "$("${iverilog_bin}" -V 2>&1 | sed -n '1p')"
  printf 'vvp_version=%s\n' "$("${vvp_bin}" -V 2>&1 | sed -n '1p')"
  printf 'verilator_version=%s\n' "$("${verilator_bin}" --version 2>&1 | sed -n '1p')"
  printf 'yosys_version=%s\n' "$("${yosys_bin}" -V 2>&1 | sed -n '1p')"
  printf 'build_dir=%s\n' "${build_dir}"
} >"${build_dir}/summary.txt"

sha256sum "${build_dir}/summary.txt" "${build_dir}/sources.sha256" \
  >"${build_dir}/completion.marker"
printf '[S2-Q1A][PASS] release/assert, %d negatives, %d exact compile-success mutations, lint/style/Yosys/contract\n' \
  "${negative_pass}" "${mutation_pass}"
printf '[S2-Q1A][EVIDENCE] %s\n' "${build_dir}"
