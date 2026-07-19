#!/usr/bin/env bash
set -euo pipefail

run_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "${run_dir}/../../.." && pwd)"
npc_home="${repo_root}/npc/rv64"
tb_home="${npc_home}/testbench"
evidence_dir="${run_dir}/evidence"
focused_dir="${evidence_dir}/focused-r2"
module_dir="${Q1A_MODULE_RESULT_DIR:-${evidence_dir}/module-r3}"
baseline="${repo_root}/.github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/evidence/r5-s2-q2-shadow-foundation-v8a-green/lint-pre-snapshot.normalized"
baseline_sha256="414dbc3972c90b93acdc05dbebd3d637dd6b3dbb067b22ede9fdb9e320b06e2b"
completion_marker="${evidence_dir}/broad-gates-r2.complete"
work_dir="$(mktemp -d /tmp/ysyx-q1a-broad.XXXXXX)"

cleanup() {
  if [[ -n "${work_dir:-}" && -d "${work_dir}" &&
        "${work_dir}" == /tmp/ysyx-q1a-broad.* ]]; then
    rm -rf -- "${work_dir}"
  fi
}
trap cleanup EXIT

fail() {
  printf '[S2-Q1A-BROAD][FAIL] %s\n' "$*" >&2
  exit 1
}

normalize_warning_log() {
  local log="$1"
  grep '^%Warning-' "${log}" |
    sed -E \
      's#/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/#VSRCDIR/#; s#:[0-9]+:[0-9]+:#:LINE:COL:#'
}

mkdir -p "${evidence_dir}"
rm -f -- "${completion_marker}"
cd "${repo_root}"

actual_baseline_sha256="$(sha256sum "${baseline}" | awk '{print $1}')"
[[ "${actual_baseline_sha256}" == "${baseline_sha256}" ]] ||
  fail "frozen pre-v8a warning baseline hash drift"

S2_Q1A_BUILD_DIR="${focused_dir}" \
  "${run_dir}/run-q1a-abort-priority.sh" \
  > "${evidence_dir}/focused-canonical-r2.log" 2>&1
sha256sum -c "${focused_dir}/sources.sha256" \
  > "${evidence_dir}/focused-sources-check-r2.log"
sha256sum -c "${focused_dir}/completion.marker" \
  > "${evidence_dir}/focused-completion-check-r2.log"

make -C "${tb_home}" \
  BUILD_DIR="${work_dir}/module-build" \
  RESULT_DIR="${module_dir}" run \
  > "${evidence_dir}/module-aggregate-r3.log" 2>&1
module_summary="${module_dir}/summary.txt"
grep -Fqx -- '- total: 104' "${module_summary}" ||
  fail "module aggregate total drift"
grep -Fqx -- '- passed: 104' "${module_summary}" ||
  fail "module aggregate did not pass 104/104"
grep -Fqx -- '- failed: 0' "${module_summary}" ||
  fail "module aggregate contains failures"
find "${module_dir}" -type f -print0 | sort -z | xargs -0 sha256sum \
  > "${evidence_dir}/module-r3.sha256"

make -C "${npc_home}" check-rtl-style \
  > "${evidence_dir}/rtl-style-full-r2.log" 2>&1
grep -Fq '[check-rtl-style] PASS:' \
  "${evidence_dir}/rtl-style-full-r2.log" ||
  fail "full RTL style gate did not report PASS"

make -C "${npc_home}" check-contract \
  > "${evidence_dir}/check-contract-r2.log" 2>&1
grep -Fq 'check-contract: PASS' "${evidence_dir}/check-contract-r2.log" ||
  fail "full contract gate did not report PASS"

python3 "${run_dir}/check_q1a_abort_contract.py" \
  > "${evidence_dir}/q1a-contract-r2.log" 2>&1

set +e
make -C "${npc_home}" lint \
  > "${evidence_dir}/strict-lint-r2.log" 2>&1
strict_lint_rc=$?
make -B -C "${npc_home}" BUILD_DIR="${work_dir}/full-build" default \
  > "${evidence_dir}/full-build-r2.log" 2>&1
full_build_rc=$?
set -e
[[ "${strict_lint_rc}" -ne 0 ]] ||
  fail "strict lint unexpectedly passed; baseline disposition needs review"
[[ "${full_build_rc}" -ne 0 ]] ||
  fail "full default build unexpectedly passed; baseline disposition needs review"
grep -Fq '%Error: Exiting due to 115 warning(s)' \
  "${evidence_dir}/strict-lint-r2.log" ||
  fail "strict lint did not fail on the locked 115-warning baseline"
grep -Fq '%Error: Exiting due to 115 warning(s)' \
  "${evidence_dir}/full-build-r2.log" ||
  fail "full build did not fail on the locked 115-warning baseline"

make -C "${npc_home}" VERILATOR='verilator -Wno-fatal' lint \
  > "${evidence_dir}/lint-nonfatal-r2.log" 2>&1
if grep -q '^%Error:' "${evidence_dir}/lint-nonfatal-r2.log"; then
  fail "nonfatal lint contains a parse/elaboration error"
fi

normalize_warning_log "${evidence_dir}/strict-lint-r2.log" \
  > "${evidence_dir}/strict-lint-r2.normalized"
normalize_warning_log "${evidence_dir}/full-build-r2.log" \
  > "${evidence_dir}/full-build-r2.normalized"
normalize_warning_log "${evidence_dir}/lint-nonfatal-r2.log" \
  > "${evidence_dir}/lint-nonfatal-r2.normalized"
for normalized in \
    "${evidence_dir}/strict-lint-r2.normalized" \
    "${evidence_dir}/full-build-r2.normalized" \
    "${evidence_dir}/lint-nonfatal-r2.normalized"; do
  cmp -s "${normalized}" "${baseline}" ||
    fail "normalized warning signature differs from pre-v8a: ${normalized}"
done

warning_count="$(wc -l < "${evidence_dir}/strict-lint-r2.normalized")"
timescale_count="$(grep -c '^%Warning-TIMESCALEMOD:' \
  "${evidence_dir}/strict-lint-r2.normalized")"
empty_pin_count="$(grep -c '^%Warning-PINCONNECTEMPTY:' \
  "${evidence_dir}/strict-lint-r2.normalized")"
latch_count="$(grep -c '^%Warning-LATCH:' \
  "${evidence_dir}/strict-lint-r2.normalized")"
unoptflat_count="$(grep -c '^%Warning-UNOPTFLAT:' \
  "${evidence_dir}/strict-lint-r2.normalized")"
[[ "${warning_count}" -eq 115 && "${timescale_count}" -eq 108 &&
   "${empty_pin_count}" -eq 2 && "${latch_count}" -eq 4 &&
   "${unoptflat_count}" -eq 1 ]] ||
  fail "warning category inventory drift"

git diff --check > "${evidence_dir}/git-diff-check-r2.log"

{
  printf 'S2-Q1A broad gate summary r2\n'
  printf 'module_aggregate=PASS 104/104\n'
  printf 'focused=PASS release/assert,5/5-negative,13/13-mutation\n'
  printf 'rtl_style_full=PASS\n'
  printf 'contract=PASS\n'
  printf 'q1a_static_contract=PASS\n'
  printf 'global_strict_lint=RED inherited rc=%s warning_count=115\n' \
    "${strict_lint_rc}"
  printf 'global_full_default_build=RED inherited rc=%s warning_count=115\n' \
    "${full_build_rc}"
  printf 'warning_signature=PRE_V8A_SNAPSHOT_BYTE_MATCH_AFTER_NORMALIZATION\n'
  printf 'warning_breakdown=TIMESCALEMOD:108,PINCONNECTEMPTY:2,LATCH:4,UNOPTFLAT:1\n'
  printf 'nonfatal_parse_elaboration=PASS\n'
  printf 'live_instantiation=ABSENT\n'
  printf 'scope=Q1A abort-priority source-catalog GREEN; live integration RED\n'
  printf 'ppa_claim=none\n'
} > "${evidence_dir}/broad-gates-summary-r2.txt"

evidence_paths=(
  "${run_dir}/run-q1a-broad-gates.sh"
  "${focused_dir}/summary.txt"
  "${focused_dir}/sources.sha256"
  "${focused_dir}/completion.marker"
  "${module_summary}"
  "${evidence_dir}/module-r3.sha256"
  "${evidence_dir}/focused-canonical-r2.log"
  "${evidence_dir}/focused-sources-check-r2.log"
  "${evidence_dir}/focused-completion-check-r2.log"
  "${evidence_dir}/module-aggregate-r3.log"
  "${evidence_dir}/rtl-style-full-r2.log"
  "${evidence_dir}/check-contract-r2.log"
  "${evidence_dir}/q1a-contract-r2.log"
  "${evidence_dir}/strict-lint-r2.log"
  "${evidence_dir}/strict-lint-r2.normalized"
  "${evidence_dir}/full-build-r2.log"
  "${evidence_dir}/full-build-r2.normalized"
  "${evidence_dir}/lint-nonfatal-r2.log"
  "${evidence_dir}/lint-nonfatal-r2.normalized"
  "${evidence_dir}/git-diff-check-r2.log"
  "${evidence_dir}/broad-gates-summary-r2.txt"
)
sha256sum "${evidence_paths[@]}" > "${evidence_dir}/broad-gates-r2.sha256"
sha256sum -c "${evidence_dir}/broad-gates-r2.sha256" \
  > "${evidence_dir}/broad-gates-hash-check-r2.log"
sha256sum "${evidence_dir}/broad-gates-summary-r2.txt" \
  "${evidence_dir}/broad-gates-r2.sha256" \
  > "${completion_marker}"

printf '[S2-Q1A-BROAD][PASS] focused + module 104/104 + style/contract; strict/default inherited RED 115/115 exact-match\n'
printf '[S2-Q1A-BROAD][EVIDENCE] %s\n' "${evidence_dir}"
