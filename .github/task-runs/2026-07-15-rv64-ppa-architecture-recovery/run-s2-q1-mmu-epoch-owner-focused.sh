#!/usr/bin/env bash
set -euo pipefail

run_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "${run_dir}/../../.." && pwd)"
runner="${run_dir}/$(basename "${BASH_SOURCE[0]}")"
rtl="${repo_root}/npc/rv64/vsrc/memory/OooMmuEpochOwner.v"
positive_tb="${repo_root}/npc/rv64/testbench/tests/tb_ooo_mmu_epoch_owner.sv"
negative_tb="${run_dir}/tb_s2_q1_mmu_epoch_owner_assert_negative.sv"
adoption_checker="${run_dir}/check-s2-q1-adoption.py"
style_checker="${repo_root}/npc/rv64/eval/check-rtl-style.sh"
build_dir="${S2_Q1_BUILD_DIR:-$(mktemp -d /tmp/s2-q1-mmu-epoch-owner.XXXXXX)}"
mkdir -p "${build_dir}/mutations" "${build_dir}/negative" "${build_dir}/gates"

iverilog_bin="${IVERILOG:-$(command -v iverilog)}"
vvp_bin="${VVP:-$(dirname "${iverilog_bin}")/vvp}"
if [[ ! -x "${vvp_bin}" ]]; then
  vvp_bin="$(command -v vvp)"
fi
verilator_bin="${VERILATOR:-$(command -v verilator)}"
yosys_bin="${YOSYS:-${repo_root}/oss-cad-suite/bin/yosys}"
python_bin="${PYTHON:-$(command -v python3)}"

for required in "${iverilog_bin}" "${vvp_bin}" "${verilator_bin}" \
  "${yosys_bin}" "${python_bin}" "${style_checker}"; do
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
  local name="$1"
  local assert_flag="$2"
  local binary="${build_dir}/${name}.vvp"
  local compile_log="${build_dir}/${name}.compile.log"
  local sim_log="${build_dir}/${name}.sim.log"
  local extra=()
  if [[ "${assert_flag}" == "assert" ]]; then
    extra=(-DOOO_ASSERT)
  fi
  if ! "${iverilog_bin}" "${ivflags[@]}" "${extra[@]}" \
      -s tb_ooo_mmu_epoch_owner -o "${binary}" "${positive_tb}" "${rtl}" \
      >"${compile_log}" 2>&1; then
    echo "positive compile failed: ${compile_log}" >&2
    exit 1
  fi
  if ! "${vvp_bin}" "${binary}" >"${sim_log}" 2>&1; then
    echo "positive simulation failed: ${sim_log}" >&2
    exit 1
  fi
  focused_pass_count="$(grep -Fxc \
    '[MMU-EPOCH-Q1][PASS] same-cycle-block/quiet/hold/second-request/multi-cause/wrap' \
    "${sim_log}" || true)"
  shared_pass_count="$(grep -Fxc '[PASS] tb_ooo_mmu_epoch_owner' "${sim_log}" || true)"
  if [[ "${focused_pass_count}" -ne 1 ]] || [[ "${shared_pass_count}" -ne 1 ]]; then
    echo "positive simulation missed unique focused/shared PASS markers: ${sim_log}" >&2
    exit 1
  fi
  if grep -Fq '[MMU-EPOCH-Q1][FAIL]' "${sim_log}"; then
    echo "unexpected focused FAIL marker in ${sim_log}" >&2
    exit 1
  fi
}

compile_positive release-green release
compile_positive assert-green assert

negative_binary="${build_dir}/negative/assert-negative.vvp"
if ! "${iverilog_bin}" "${ivflags[@]}" -DOOO_ASSERT \
    -s tb_s2_q1_mmu_epoch_owner_assert_negative \
    -o "${negative_binary}" "${negative_tb}" "${rtl}" \
    >"${build_dir}/negative/compile.log" 2>&1; then
  echo "assertion-negative compile failed: ${build_dir}/negative/compile.log" >&2
  exit 1
fi

negative_messages=(
  '[MMU-EPOCH-REQ-CAUSE] valid request carried no cause bit'
  '[MMU-EPOCH-REQ-HOLD] stalled request bundle changed or withdrew'
  '[MMU-EPOCH-GRANT-QUIET] quiet/live-empty dropped while grant was pending'
  '[MMU-EPOCH-STATE] illegal FSM encoding 11'
)
negative_pass=0
for case_id in 1 2 3 4; do
  log="${build_dir}/negative/case-${case_id}.sim.log"
  set +e
  "${vvp_bin}" "${negative_binary}" "+CASE=${case_id}" >"${log}" 2>&1
  rc=$?
  set -e
  expected_message="${negative_messages[$((case_id - 1))]}"
  expected_count="$(grep -Fxc "${expected_message}" "${log}" || true)"
  named_line_count="$(grep -Ec '^\[MMU-EPOCH-[^]]+\]' "${log}" || true)"
  if [[ "${rc}" -eq 0 ]] || [[ "${expected_count}" -ne 1 ]] || \
      [[ "${named_line_count}" -ne 1 ]]; then
    echo "negative CASE=${case_id} missed its unique full message; rc=${rc} expected_count=${expected_count} named_line_count=${named_line_count}" >&2
    exit 1
  fi
  negative_pass=$((negative_pass + 1))
done

make_mutant() {
  local name="$1"
  local out="${build_dir}/mutations/${name}.v"
  case "${name}" in
    no-lookahead)
      sed 's/(state_q != ST_UNLOCKED) || request_valid_i/(state_q != ST_UNLOCKED)/' \
        "${rtl}" >"${out}"
      ;;
    no-quiet)
      sed 's/if (full_quiet_w)/if (owner_live_empty_i)/' "${rtl}" >"${out}"
      ;;
    no-live-empty)
      sed 's/if (full_quiet_w)/if (mem_context_quiet_i)/' "${rtl}" >"${out}"
      ;;
    ready-dependent-grant)
      sed 's/assign grant_valid_o = (state_q == ST_COMMIT);/assign grant_valid_o = (state_q == ST_COMMIT) \&\& grant_ready_i;/' \
        "${rtl}" >"${out}"
      ;;
    live-input-payload)
      sed 's/assign grant_payload_o = held_payload_q;/assign grant_payload_o = request_payload_i;/' \
        "${rtl}" >"${out}"
      ;;
    advance-before-consume)
      sed '/ST_COMMIT:/,/default:/ s/if (grant_fire_w) begin/if (grant_valid_o) begin/' \
        "${rtl}" >"${out}"
      ;;
    saturating-epoch)
      sed "s/mmu_epoch_q <= mmu_epoch_q + 2'b01;/mmu_epoch_q <= (\\&mmu_epoch_q) ? mmu_epoch_q : (mmu_epoch_q + 2'b01);/" \
        "${rtl}" >"${out}"
      ;;
    *)
      echo "unknown mutant ${name}" >&2
      return 1
      ;;
  esac
  if cmp -s "${rtl}" "${out}"; then
    echo "mutation ${name} did not change the RTL" >&2
    return 1
  fi
  printf '%s\n' "${out}"
}

mutants=(
  no-lookahead
  no-quiet
  no-live-empty
  ready-dependent-grant
  live-input-payload
  advance-before-consume
  saturating-epoch
)
mutation_markers=(
  '[MMU-EPOCH-Q1][FAIL] first request did not block capture in its presentation cycle'
  '[MMU-EPOCH-Q1][FAIL] quiet-low request advanced to grant'
  '[MMU-EPOCH-Q1][FAIL] live token did not block epoch grant'
  '[MMU-EPOCH-Q1][FAIL] full quiet did not expose the held grant before epoch advance'
  '[MMU-EPOCH-Q1][FAIL] second request overwrote or bypassed backpressured grant A'
  '[MMU-EPOCH-Q1][FAIL] grant A did not hold for first backpressure cycle'
  '[MMU-EPOCH-Q1][FAIL] quiet helper grant did not consume exactly once and advance epoch'
)
mutation_pass=0
for index in "${!mutants[@]}"; do
  mutant="${mutants[$index]}"
  expected_marker="${mutation_markers[$index]}"
  mutant_rtl="$(make_mutant "${mutant}")"
  binary="${build_dir}/mutations/${mutant}.vvp"
  compile_log="${build_dir}/mutations/${mutant}.compile.log"
  sim_log="${build_dir}/mutations/${mutant}.sim.log"
  if ! "${iverilog_bin}" "${ivflags[@]}" -s tb_ooo_mmu_epoch_owner \
      -o "${binary}" "${positive_tb}" "${mutant_rtl}" >"${compile_log}" 2>&1; then
    echo "mutation ${mutant} failed to compile: ${compile_log}" >&2
    exit 1
  fi
  set +e
  "${vvp_bin}" "${binary}" >"${sim_log}" 2>&1
  rc=$?
  set -e
  fail_count="$(grep -Fc '[MMU-EPOCH-Q1][FAIL]' "${sim_log}" || true)"
  if [[ "${rc}" -eq 0 ]] || [[ "${fail_count}" -ne 1 ]] || \
      ! grep -Fqx "${expected_marker}" "${sim_log}"; then
    echo "mutation ${mutant} missed its unique oracle; rc=${rc} fail_count=${fail_count}" >&2
    exit 1
  fi
  mutation_pass=$((mutation_pass + 1))
done

if ! "${verilator_bin}" --lint-only -Wall --top-module OooMmuEpochOwner "${rtl}" \
    >"${build_dir}/gates/verilator-release.log" 2>&1; then
  echo "release Verilator lint failed: ${build_dir}/gates/verilator-release.log" >&2
  exit 1
fi
if ! "${verilator_bin}" --lint-only -Wall -DOOO_ASSERT \
    --top-module OooMmuEpochOwner "${rtl}" \
    >"${build_dir}/gates/verilator-assert.log" 2>&1; then
  echo "assert Verilator lint failed: ${build_dir}/gates/verilator-assert.log" >&2
  exit 1
fi
if ! env RTL_FILES="${rtl}" "${style_checker}" \
    >"${build_dir}/gates/rtl-style.log" 2>&1; then
  echo "RTL style gate failed: ${build_dir}/gates/rtl-style.log" >&2
  exit 1
fi
if ! "${yosys_bin}" -q -p \
    "read_verilog ${rtl}; hierarchy -check -top OooMmuEpochOwner; proc; opt; check" \
    >"${build_dir}/gates/yosys-check.log" 2>&1; then
  echo "Yosys leaf check failed: ${build_dir}/gates/yosys-check.log" >&2
  exit 1
fi
if ! "${python_bin}" "${adoption_checker}" \
    >"${build_dir}/gates/adoption-contract.log" 2>&1; then
  echo "Q1 adoption contract failed: ${build_dir}/gates/adoption-contract.log" >&2
  exit 1
fi

sha256sum "${rtl}" "${positive_tb}" "${negative_tb}" "${runner}" \
  >"${build_dir}/sources.sha256"
iverilog_version="$("${iverilog_bin}" -V 2>&1 | sed -n '1p')"
vvp_version="$("${vvp_bin}" -V 2>&1 | sed -n '1p')"
verilator_version="$("${verilator_bin}" --version 2>&1 | sed -n '1p')"
yosys_version="$("${yosys_bin}" -V 2>&1 | sed -n '1p')"

{
  printf '%s\n' 'S2-Q1 OooMmuEpochOwner focused + adoption summary'
  printf 'release_positive=PASS\n'
  printf 'assert_positive=PASS\n'
  printf 'assert_negative=%d/4 PASS\n' "${negative_pass}"
  printf 'source_mutations=%d/7 KILLED_BY_EXACT_ORACLE\n' "${mutation_pass}"
  printf 'verilator_release_lint=PASS\n'
  printf 'verilator_assert_lint=PASS\n'
  printf 'rtl_style=PASS\n'
  printf 'yosys_check=PASS\n'
  printf 'adoption_contract=PASS\n'
  printf 'rtl_sha256=%s\n' "$(sha256sum "${rtl}" | awk '{print $1}')"
  printf 'tb_sha256=%s\n' "$(sha256sum "${positive_tb}" | awk '{print $1}')"
  printf 'negative_tb_sha256=%s\n' "$(sha256sum "${negative_tb}" | awk '{print $1}')"
  printf 'runner_sha256=%s\n' "$(sha256sum "${runner}" | awk '{print $1}')"
  printf 'iverilog_version=%s\n' "${iverilog_version}"
  printf 'vvp_version=%s\n' "${vvp_version}"
  printf 'verilator_version=%s\n' "${verilator_version}"
  printf 'yosys_version=%s\n' "${yosys_version}"
  printf 'build_dir=%s\n' "${build_dir}"
} >"${build_dir}/summary.txt"

printf '[S2-Q1][PASS] release/assert, %d negatives, %d exact mutations, lint/style/Yosys/adoption\n' \
  "${negative_pass}" "${mutation_pass}"
printf '[S2-Q1][EVIDENCE] %s\n' "${build_dir}"
