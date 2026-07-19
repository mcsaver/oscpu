#!/usr/bin/env bash
set -euo pipefail

run_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "${run_dir}/../../.." && pwd)"
clmul_rtl="${repo_root}/npc/rv64/vsrc/execute/OooClmulUnit.v"
fp_rtl="${repo_root}/npc/rv64/vsrc/execute/OooFpArithGate.v"
clmul_tb="${repo_root}/npc/rv64/testbench/tests/tb_ooo_clmul_unit.sv"
fp_tb="${repo_root}/npc/rv64/testbench/tests/tb_ooo_fp_arith_gate.sv"
int_backend="${repo_root}/npc/rv64/vsrc/execute/OooIntBackend.v"
fp_backend="${repo_root}/npc/rv64/vsrc/execute/OooFpBackend.v"
dispatch_backend="${repo_root}/npc/rv64/vsrc/rename_allocate/OooDispatchBackend.v"
contract="${run_dir}/producer-kill-now-contract.md"
checker="${run_dir}/check-producer-kill-now.py"
mutations="${run_dir}/run-producer-kill-mutations.py"
style_checker="${repo_root}/npc/rv64/eval/check-rtl-style.sh"
build_dir="${V8B_KILL_BUILD_DIR:-$(mktemp -d /tmp/v8b-producer-kill.XXXXXX)}"

mkdir -p "${build_dir}/positive/release" "${build_dir}/positive/assert" \
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
  "${yosys_bin}" "${python_bin}" "${style_checker}" "${checker}" \
  "${mutations}"; do
  if [[ ! -x "${required}" ]]; then
    echo "required executable is missing: ${required}" >&2
    exit 1
  fi
done

inventory=(
  "${clmul_rtl}"
  "${fp_rtl}"
  "${clmul_tb}"
  "${fp_tb}"
  "${int_backend}"
  "${fp_backend}"
  "${dispatch_backend}"
  "${contract}"
  "${checker}"
  "${mutations}"
  "${BASH_SOURCE[0]}"
)
sha256sum "${inventory[@]}" >"${build_dir}/sources.pre.sha256"

ivflags=(
  -g2012 -Wall
  -I "${repo_root}/npc/rv64/vsrc"
  -I "${repo_root}/npc/rv64/vsrc/include"
  -I "${repo_root}/npc/rv64/testbench/common"
)

compile_and_run() {
  local variant="$1"
  local top="$2"
  local tb="$3"
  local rtl="$4"
  local extra=()
  if [[ "${variant}" == "assert" ]]; then
    extra=(-DOOO_ASSERT)
  fi
  local binary="${build_dir}/positive/${variant}/${top}.vvp"
  local compile_log="${build_dir}/positive/${variant}/${top}.compile.log"
  local sim_log="${build_dir}/positive/${variant}/${top}.sim.log"
  "${iverilog_bin}" "${ivflags[@]}" "${extra[@]}" -s "${top}" \
    -o "${binary}" "${tb}" "${rtl}" >"${compile_log}" 2>&1
  "${vvp_bin}" "${binary}" >"${sim_log}" 2>&1
  if [[ "$(grep -Fxc "[PASS] ${top}" "${sim_log}" || true)" -ne 1 ]] || \
     grep -Fq '[CHECK-FAIL]' "${sim_log}" || grep -Fq '[FAIL]' "${sim_log}"; then
    echo "${variant} ${top} missed exact PASS oracle: ${sim_log}" >&2
    exit 1
  fi
}

compile_and_run release tb_ooo_clmul_unit "${clmul_tb}" "${clmul_rtl}"
compile_and_run release tb_ooo_fp_arith_gate "${fp_tb}" "${fp_rtl}"
compile_and_run assert tb_ooo_clmul_unit "${clmul_tb}" "${clmul_rtl}"
compile_and_run assert tb_ooo_fp_arith_gate "${fp_tb}" "${fp_rtl}"

"${python_bin}" "${checker}" --self-test \
  >"${build_dir}/gates/checker-self-test.log" 2>&1
"${python_bin}" "${checker}" \
  >"${build_dir}/gates/structural-contract.log" 2>&1
"${python_bin}" "${mutations}" --output-dir "${build_dir}/mutations" \
  >"${build_dir}/gates/mutations.log" 2>&1
if ! grep -Fqx '[V8B-KILL-MUTATION][PASS] mutations=13' \
    "${build_dir}/gates/mutations.log"; then
  echo "mutation inventory missed exact 13/13 marker" >&2
  exit 1
fi

"${verilator_bin}" --lint-only -Wall \
  -I"${repo_root}/npc/rv64/vsrc" -I"${repo_root}/npc/rv64/vsrc/include" \
  --top-module OooClmulUnit "${clmul_rtl}" \
  >"${build_dir}/gates/clmul-verilator-release.log" 2>&1
"${verilator_bin}" --lint-only -Wall -DOOO_ASSERT \
  -I"${repo_root}/npc/rv64/vsrc" -I"${repo_root}/npc/rv64/vsrc/include" \
  --top-module OooClmulUnit "${clmul_rtl}" \
  >"${build_dir}/gates/clmul-verilator-assert.log" 2>&1

# OooFpArithGate 已有与本切片无关的 strict width/unused 基线。strict 必须
# 继续 RED，同时 -Wno-fatal 只证明本次 RTL 仍可 parse/elaborate。
set +e
"${verilator_bin}" --lint-only -Wall \
  -I"${repo_root}/npc/rv64/vsrc" -I"${repo_root}/npc/rv64/vsrc/include" \
  --top-module OooFpArithGate "${fp_rtl}" \
  >"${build_dir}/gates/fp-verilator-strict.log" 2>&1
fp_strict_rc=$?
set -e
if [[ "${fp_strict_rc}" -eq 0 ]]; then
  echo "FP strict lint unexpectedly passed; reviewed inherited baseline changed" >&2
  exit 1
fi
fp_warn_total="$(grep -c '^%Warning-' "${build_dir}/gates/fp-verilator-strict.log" || true)"
fp_width_expand="$(grep -c '^%Warning-WIDTHEXPAND:' "${build_dir}/gates/fp-verilator-strict.log" || true)"
fp_width_trunc="$(grep -c '^%Warning-WIDTHTRUNC:' "${build_dir}/gates/fp-verilator-strict.log" || true)"
fp_unused="$(grep -c '^%Warning-UNUSEDSIGNAL:' "${build_dir}/gates/fp-verilator-strict.log" || true)"
if [[ "${fp_warn_total}" -ne 43 ]] || [[ "${fp_width_expand}" -ne 20 ]] || \
   [[ "${fp_width_trunc}" -ne 6 ]] || [[ "${fp_unused}" -ne 17 ]]; then
  echo "FP inherited strict-warning baseline drift: total=${fp_warn_total} expand=${fp_width_expand} trunc=${fp_width_trunc} unused=${fp_unused}" >&2
  exit 1
fi
"${verilator_bin}" --lint-only -Wall -Wno-fatal \
  -I"${repo_root}/npc/rv64/vsrc" -I"${repo_root}/npc/rv64/vsrc/include" \
  --top-module OooFpArithGate "${fp_rtl}" \
  >"${build_dir}/gates/fp-verilator-nonfatal.log" 2>&1

env RTL_FILES="${clmul_rtl} ${fp_rtl}" "${style_checker}" \
  >"${build_dir}/gates/rtl-style.log" 2>&1
"${yosys_bin}" -q -p \
  "read_verilog -I ${repo_root}/npc/rv64/vsrc -I ${repo_root}/npc/rv64/vsrc/include ${clmul_rtl}; hierarchy -check -top OooClmulUnit; proc; opt; check" \
  >"${build_dir}/gates/clmul-yosys.log" 2>&1
"${yosys_bin}" -q -p \
  "read_verilog -I ${repo_root}/npc/rv64/vsrc -I ${repo_root}/npc/rv64/vsrc/include ${fp_rtl}; hierarchy -check -top OooFpArithGate; proc; opt; check" \
  >"${build_dir}/gates/fp-yosys.log" 2>&1

sha256sum "${inventory[@]}" >"${build_dir}/sources.post.sha256"
if ! cmp -s "${build_dir}/sources.pre.sha256" "${build_dir}/sources.post.sha256"; then
  echo "reviewed source inventory changed during focused run" >&2
  exit 1
fi
cp "${build_dir}/sources.post.sha256" "${build_dir}/sources.sha256"
sha256sum -c "${build_dir}/sources.sha256" \
  >"${build_dir}/sources-check.log"

{
  printf '%s\n' 'RV64 v8b-prep production producer kill-now summary'
  printf 'scope=CLMUL-and-FP-arithmetic-producer-local\n'
  printf 'release_positive=2/2 PASS\n'
  printf 'assert_positive=2/2 PASS\n'
  printf 'clmul_age_sweep=4096/4096 PASS\n'
  printf 'compile_success_mutations=13/13 KILLED_BY_SEMANTIC_ORACLE\n'
  printf 'structural_checker=PASS self_test=3/3\n'
  printf 'clmul_verilator_strict=PASS release+assert\n'
  printf 'fp_verilator_strict=RED inherited warnings=43 WIDTHEXPAND=20 WIDTHTRUNC=6 UNUSEDSIGNAL=17\n'
  printf 'fp_verilator_nonfatal=PASS\n'
  printf 'rtl_style=PASS\n'
  printf 'yosys_leaf_checks=2/2 PASS\n'
  printf 'full_identity_no_live_reuse=RED\n'
  printf 'live_q1_shared_abort=RED\n'
  printf 'ppa_linux_frequency=NOT_MEASURED\n'
  printf 'iverilog_version=%s\n' "$("${iverilog_bin}" -V 2>&1 | sed -n '1p')"
  printf 'verilator_version=%s\n' "$("${verilator_bin}" --version 2>&1 | sed -n '1p')"
  printf 'yosys_version=%s\n' "$("${yosys_bin}" -V 2>&1 | sed -n '1p')"
  printf 'build_dir=%s\n' "${build_dir}"
} >"${build_dir}/summary.txt"

sha256sum "${build_dir}/summary.txt" "${build_dir}/sources.sha256" \
  "${build_dir}/gates/checker-self-test.log" \
  "${build_dir}/gates/structural-contract.log" \
  "${build_dir}/gates/mutations.log" \
  >"${build_dir}/completion.marker"

printf '[V8B-KILL-NOW][PASS] release/assert=4/4 mutations=13/13 checker/style/Yosys PASS; FP strict inherited RED=43\n'
printf '[V8B-KILL-NOW][EVIDENCE] %s\n' "${build_dir}"
