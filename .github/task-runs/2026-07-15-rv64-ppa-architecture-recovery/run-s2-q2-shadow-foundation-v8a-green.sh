#!/usr/bin/env bash
set -euo pipefail

RUN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${RUN_DIR}/../../.." && pwd)"
EVIDENCE_DIR="${1:-${RUN_DIR}/evidence/r5-s2-q2-shadow-foundation-v8a-green}"
CHECKER="${RUN_DIR}/check-s2-q2-shadow-foundation-v8a.py"
IMPLEMENTATION_CHECKER="${RUN_DIR}/check-s2-q2-shadow-foundation-v8a-implementation.py"
MANIFEST="${RUN_DIR}/s2-q2-shadow-foundation-interface-v8a.json"
PRE_BUNDLE="${RUN_DIR}/artifacts/v8a-pre-rtl-vsrc.tar.gz"
PRE_BUNDLE_SHA256="812fa351bfed9ab9f4a6125cece5b840d1b0135c6105b7fa8f2ccd788c9ab9a5"
COMPLETE_MARKER="${EVIDENCE_DIR}/complete.marker"
NPC_HOME="${REPO_ROOT}/npc/rv64"
TB_DIR="${NPC_HOME}/testbench"

mkdir -p "${EVIDENCE_DIR}"
rm -f -- "${COMPLETE_MARKER}" \
  "${EVIDENCE_DIR}/evidence.sha256" \
  "${EVIDENCE_DIR}/evidence-check.log" \
  "${EVIDENCE_DIR}/implementation-checker-self-test.log" \
  "${EVIDENCE_DIR}/implementation-readiness.log" \
  "${EVIDENCE_DIR}/lint.log"
work_dir="$(mktemp -d /tmp/ysyx-v8a-green.XXXXXX)"
cleanup() {
  if [[ -n "${work_dir:-}" && -d "${work_dir}" &&
        "${work_dir}" == /tmp/ysyx-v8a-green.* ]]; then
    rm -rf -- "${work_dir}"
  fi
}
trap cleanup EXIT
cd "${REPO_ROOT}"

fail() {
  printf '[S2-Q2-V8A-GREEN][FAIL] %s\n' "$*" >&2
  exit 1
}

normalize_warning_log() {
  local log="$1"
  grep '^%Warning-' "${log}" |
    sed -E \
      's#/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/#VSRCDIR/#; s#:[0-9]+:[0-9]+:#:LINE:COL:#'
}

check_frozen_hash() {
  local expected="$1"
  local path="$2"
  local actual
  actual="$(sha256sum "${path}" | awk '{print $1}')"
  [[ "${actual}" == "${expected}" ]] ||
    fail "frozen artifact drift: ${path#${REPO_ROOT}/}"
  printf '%s  %s\n' "${actual}" "${path#${REPO_ROOT}/}" \
    >> "${EVIDENCE_DIR}/frozen-artifacts.sha256"
}

: > "${EVIDENCE_DIR}/frozen-artifacts.sha256"
check_frozen_hash \
  "b0da714be24441ad53fcf28931bce10d5ad702b5839722432b5cd5a06cbaaf23" \
  "${RUN_DIR}/s2-q2-shadow-foundation-v8a-contract.md"
check_frozen_hash \
  "256fabfd26d1b6b11aab8d48c4253401c71af318bec839903484e53cee4b5bd2" \
  "${MANIFEST}"
check_frozen_hash \
  "3f372e2dcde6fb4611e5c75682bdab4d1811a69aae3b13a72dc68d4a71533eb4" \
  "${CHECKER}"
check_frozen_hash \
  "2152b9194ad517ef2a8086f3f3a3102d6a40f204bcdacf5e0101d6700c30db0c" \
  "${RUN_DIR}/run-s2-q2-shadow-foundation-v8a.sh"
actual_pre_bundle_sha256="$(sha256sum "${PRE_BUNDLE}" | awk '{print $1}')"
[[ "${actual_pre_bundle_sha256}" == "${PRE_BUNDLE_SHA256}" ]] ||
  fail "pre-implementation source bundle digest drift"
printf '%s  %s\n' "${actual_pre_bundle_sha256}" \
  "${PRE_BUNDLE#${REPO_ROOT}/}" >> "${EVIDENCE_DIR}/frozen-artifacts.sha256"
check_frozen_hash \
  "1d4ea938c1ad0988fd92d6d78a73ec50a944a0c035d7a6ae2dc03ce3027a9706" \
  "${EVIDENCE_DIR}/lint-pre-snapshot.log"
check_frozen_hash \
  "414dbc3972c90b93acdc05dbebd3d637dd6b3dbb067b22ede9fdb9e320b06e2b" \
  "${EVIDENCE_DIR}/lint-pre-snapshot.normalized"

source_paths=(
  "${RUN_DIR}/run-s2-q2-shadow-foundation-v8a-green.sh"
  "${IMPLEMENTATION_CHECKER}"
  "${RUN_DIR}/s2-q2-shadow-foundation-v8a-rtl-derivation.md"
  "${REPO_ROOT}/npc/rv64/design/specs/ooo-rob.md"
  "${REPO_ROOT}/npc/rv64/design/specs/ooo-execute-backend.md"
  "${REPO_ROOT}/npc/rv64/design/specs/ooo-core-top-glue.md"
  "${REPO_ROOT}/npc/rv64/vsrc/include/define.v"
  "${REPO_ROOT}/npc/rv64/vsrc/core/NpcCoreTop.v"
  "${REPO_ROOT}/npc/rv64/vsrc/core/OooCoreTopGlue.v"
  "${REPO_ROOT}/npc/rv64/vsrc/execute/OooExecuteBackend.v"
  "${REPO_ROOT}/npc/rv64/vsrc/execute/OooAluCoreSlice.v"
  "${REPO_ROOT}/npc/rv64/vsrc/decode/OooAluDecodeBackend.v"
  "${REPO_ROOT}/npc/rv64/vsrc/execute/OooIntBackend.v"
  "${REPO_ROOT}/npc/rv64/vsrc/rename_allocate/OooDispatchBackend.v"
  "${REPO_ROOT}/npc/rv64/vsrc/writeback/OooRob.v"
  "${REPO_ROOT}/npc/rv64/testbench/tests/tb_ooo_rob.sv"
  "${REPO_ROOT}/npc/rv64/testbench/tests/tb_ooo_dispatch_backend.sv"
  "${REPO_ROOT}/npc/rv64/testbench/tests/tb_ooo_int_backend.sv"
  "${REPO_ROOT}/npc/rv64/testbench/tests/tb_ooo_alu_decode_backend.sv"
  "${REPO_ROOT}/npc/rv64/testbench/tests/tb_ooo_alu_core_slice.sv"
  "${REPO_ROOT}/npc/rv64/testbench/tests/tb_ooo_core_top_glue.sv"
  "${REPO_ROOT}/npc/rv64/testbench/tests/tb_ooo_fetch_trap_gate.sv"
  "${REPO_ROOT}/npc/rv64/testbench/tests/tb_ooo_priv_system.sv"
  "${REPO_ROOT}/npc/rv64/testbench/tests/tb_ooo_sv39_boot.sv"
)
sha256sum "${source_paths[@]}" > "${EVIDENCE_DIR}/sources.pre.sha256"

python3 "${CHECKER}" --self-test > "${EVIDENCE_DIR}/checker-self-test.log"
grep -Fqx '[S2-Q2-V8A-SELFTEST][PASS] mutations=17' \
  "${EVIDENCE_DIR}/checker-self-test.log" || fail "checker self-test count drift"
if [[ "$(grep -c '^\[S2-Q2-V8A-SELFTEST\]\[PASS\]' \
      "${EVIDENCE_DIR}/checker-self-test.log")" -ne 18 ]]; then
  fail "checker self-test marker inventory is incomplete"
fi
python3 "${CHECKER}" > "${EVIDENCE_DIR}/readiness.log"
grep -Fqx \
  '[S2-Q2-V8A-READINESS][PASS] neutral shadow foundation is structurally ready; deferred v8b P0 blockers and RTL behavior gates remain' \
  "${EVIDENCE_DIR}/readiness.log" || fail "structural readiness PASS missing"
if grep -q '^\[S2-Q2-V8A-READINESS\]\[RED\]' \
    "${EVIDENCE_DIR}/readiness.log"; then
  fail "structural readiness still contains RED items"
fi
python3 "${IMPLEMENTATION_CHECKER}" --self-test \
  > "${EVIDENCE_DIR}/implementation-checker-self-test.log"
grep -Fqx '[S2-Q2-V8A-IMPL-SELFTEST][PASS] mutations=4' \
  "${EVIDENCE_DIR}/implementation-checker-self-test.log" ||
  fail "implementation checker self-test baseline mismatch"
python3 "${IMPLEMENTATION_CHECKER}" \
  > "${EVIDENCE_DIR}/implementation-readiness.log"
grep -Fqx \
  '[S2-Q2-V8A-IMPL][PASS] commit prefix, identity encoding, scalar ABI, base-ready confinement, and instance census=15' \
  "${EVIDENCE_DIR}/implementation-readiness.log" ||
  fail "supplemental implementation readiness PASS missing"

focused_tbs=(
  tb_ooo_rob
  tb_ooo_dispatch_backend
  tb_ooo_int_backend
  tb_ooo_alu_decode_backend
  tb_ooo_alu_core_slice
  tb_ooo_core_top_glue
  tb_ooo_fetch_trap_gate
  tb_ooo_priv_system
)

run_focused_variant() {
  local variant="$1"
  local define_flags="$2"
  local variant_dir="${work_dir}/focused-${variant}"
  local ivflags="-g2012 -Wall -I${NPC_HOME}/vsrc -I${NPC_HOME}/vsrc/include -Icommon ${define_flags}"
  local tb target log
  for tb in "${focused_tbs[@]}"; do
    target="${variant_dir}/result/logs/${tb}.log"
    make -C "${TB_DIR}" \
      NPC_SINGLE_HOME="${NPC_HOME}" \
      BUILD_DIR="${variant_dir}/build" \
      RESULT_DIR="${variant_dir}/result" \
      IVFLAGS="${ivflags}" \
      "${target}" > "${EVIDENCE_DIR}/focused-${variant}-${tb}.make.log" 2>&1
    log="${variant_dir}/result/logs/${tb}.log"
    cp -- "${log}" "${EVIDENCE_DIR}/focused-${variant}-${tb}.log"
    grep -Fqx '[RESULT] PASS' "${log}" ||
      fail "${variant} focused test failed: ${tb}"
  done
}

run_focused_variant release ''
run_focused_variant ooo_assert '-DOOO_ASSERT'
grep -Fq '[S2-Q2-V8A-DYNAMIC-PASS]' \
  "${EVIDENCE_DIR}/focused-ooo_assert-tb_ooo_rob.log" ||
  fail "non-vacuous v8a dynamic coverage marker missing"
grep -Fq '[S2-Q2-V8A-WRAPPER-PASS]' \
  "${EVIDENCE_DIR}/focused-ooo_assert-tb_ooo_core_top_glue.log" ||
  fail "public wrapper observation coverage marker missing"

iverilog_bin_dir="$(dirname "$(command -v iverilog)")"
if [[ -x "${iverilog_bin_dir}/vvp" ]]; then
  vvp_bin="${iverilog_bin_dir}/vvp"
else
  vvp_bin="$(command -v vvp)"
fi
set +e
"${vvp_bin}" "${work_dir}/focused-ooo_assert/build/tb_ooo_rob.vvp" \
  +S2_Q2_V8A_CANDIDATE_LIVE_NEGATIVE \
  > "${EVIDENCE_DIR}/candidate-live-negative.log" 2>&1
negative_rc=$?
set -e
printf '%s\n' "${negative_rc}" > "${EVIDENCE_DIR}/candidate-live-negative.rc"
[[ "${negative_rc}" -ne 0 ]] || fail "candidate-live negative returned success"
grep -Fq '[S2-Q2-V8A-CANDIDATE-LIVE]' \
  "${EVIDENCE_DIR}/candidate-live-negative.log" ||
  fail "candidate-live negative missed the target assertion"
grep -Fq 'v8a negative setup never reached a live candidate' \
  "${EVIDENCE_DIR}/candidate-live-negative.log" &&
  fail "candidate-live negative was vacuous"

csr_qh_dir="${work_dir}/csr-qh-enabled"
csr_qh_target="${csr_qh_dir}/result/logs/tb_ooo_rob.log"
make -C "${TB_DIR}" \
  NPC_SINGLE_HOME="${NPC_HOME}" \
  BUILD_DIR="${csr_qh_dir}/build" \
  RESULT_DIR="${csr_qh_dir}/result" \
  IVFLAGS="-g2012 -Wall -I${NPC_HOME}/vsrc -I${NPC_HOME}/vsrc/include -Icommon -DOOO_ASSERT -DOOO_CSR_QUEUE_HEAD=1" \
  "${csr_qh_target}" > "${EVIDENCE_DIR}/csr-qh-enabled.make.log" 2>&1
cp -- "${csr_qh_target}" "${EVIDENCE_DIR}/csr-qh-enabled.base.log"
grep -Fqx '[RESULT] PASS' "${csr_qh_target}" ||
  fail "explicit OOO_CSR_QUEUE_HEAD build failed its base ROB test"
"${vvp_bin}" "${csr_qh_dir}/build/tb_ooo_rob.vvp" \
  +S2_Q2_V8A_CSR_QH_ENABLED > "${EVIDENCE_DIR}/csr-qh-enabled.log" 2>&1
grep -Fq '[S2-Q2-V8A-CSR-QH-PASS]' \
  "${EVIDENCE_DIR}/csr-qh-enabled.log" ||
  fail "explicit OOO_CSR_QUEUE_HEAD behavior was not preserved"
grep -Fq '[PASS] tb_ooo_rob' "${EVIDENCE_DIR}/csr-qh-enabled.log" ||
  fail "explicit OOO_CSR_QUEUE_HEAD focused simulation did not pass"

csr_qh_zero_dir="${work_dir}/csr-qh-explicit-zero"
csr_qh_zero_target="${csr_qh_zero_dir}/result/logs/tb_ooo_rob.log"
make -C "${TB_DIR}" \
  NPC_SINGLE_HOME="${NPC_HOME}" \
  BUILD_DIR="${csr_qh_zero_dir}/build" \
  RESULT_DIR="${csr_qh_zero_dir}/result" \
  IVFLAGS="-g2012 -Wall -I${NPC_HOME}/vsrc -I${NPC_HOME}/vsrc/include -Icommon -DOOO_ASSERT -DOOO_CSR_QUEUE_HEAD=0" \
  "${csr_qh_zero_target}" > "${EVIDENCE_DIR}/csr-qh-explicit-zero.make.log" 2>&1
cp -- "${csr_qh_zero_target}" "${EVIDENCE_DIR}/csr-qh-explicit-zero.base.log"
grep -Fqx '[RESULT] PASS' "${csr_qh_zero_target}" ||
  fail "explicit OOO_CSR_QUEUE_HEAD=0 build failed its base ROB test"
"${vvp_bin}" "${csr_qh_zero_dir}/build/tb_ooo_rob.vvp" \
  +S2_Q2_V8A_CSR_QH_EXPLICIT_ZERO \
  > "${EVIDENCE_DIR}/csr-qh-explicit-zero.log" 2>&1
grep -Fq '[S2-Q2-V8A-CSR-QH-ZERO-PASS]' \
  "${EVIDENCE_DIR}/csr-qh-explicit-zero.log" ||
  fail "explicit OOO_CSR_QUEUE_HEAD=0 was misread as enabled"
grep -Fq '[PASS] tb_ooo_rob' \
  "${EVIDENCE_DIR}/csr-qh-explicit-zero.log" ||
  fail "explicit OOO_CSR_QUEUE_HEAD=0 focused simulation did not pass"

mkdir -p "${work_dir}/reference"
tar -xzf "${PRE_BUNDLE}" -C "${work_dir}/reference"
REF_NPC_HOME="${work_dir}/reference/npc/rv64"
: > "${EVIDENCE_DIR}/equivalence-summary.txt"

run_equivalence_variant() {
  local variant="$1"
  local define_flags="$2"
  local side home side_dir ivflags target raw trace trace_sha lines
  for side in reference candidate; do
    if [[ "${side}" == reference ]]; then
      home="${REF_NPC_HOME}"
    else
      home="${NPC_HOME}"
    fi
    side_dir="${work_dir}/equivalence-${variant}-${side}"
    ivflags="-g2012 -Wall -I${home}/vsrc -I${home}/vsrc/include -Icommon ${define_flags}"
    target="${side_dir}/result/logs/tb_ooo_sv39_boot.log"
    make -C "${TB_DIR}" \
      NPC_SINGLE_HOME="${home}" \
      BUILD_DIR="${side_dir}/build" \
      RESULT_DIR="${side_dir}/result" \
      IVFLAGS="${ivflags}" \
      "${target}" > "${EVIDENCE_DIR}/equivalence-${variant}-${side}.make.log" 2>&1
    cp -- "${target}" \
      "${EVIDENCE_DIR}/equivalence-${variant}-${side}.base.log"
    grep -Fqx '[RESULT] PASS' "${target}" ||
      fail "${variant} ${side} equivalence base test failed"
    raw="${side_dir}/raw.log"
    trace="${side_dir}/old-abi.trace"
    "${vvp_bin}" "${side_dir}/build/tb_ooo_sv39_boot.vvp" \
      +S2_Q2_V8A_EQ_TRACE > "${raw}" 2>&1
    grep -Fq '[PASS] tb_ooo_sv39_boot' "${raw}" ||
      fail "${variant} ${side} trace simulation did not pass"
    if grep -Fq '[CHECK-FAIL]' "${raw}"; then
      fail "${variant} ${side} trace simulation contains CHECK-FAIL"
    fi
    grep '^\[S2-Q2-V8A-OLD-ABI-TRACE\]' "${raw}" > "${trace}"
    lines="$(wc -l < "${trace}")"
    [[ "${lines}" -ge 100 ]] ||
      fail "${variant} ${side} trace is vacuous (${lines} lines)"
    trace_sha="$(sha256sum "${trace}" | awk '{print $1}')"
    printf '%s_%s_lines=%s\n%s_%s_sha256=%s\n' \
      "${variant}" "${side}" "${lines}" \
      "${variant}" "${side}" "${trace_sha}" \
      >> "${EVIDENCE_DIR}/equivalence-summary.txt"
    gzip -n -c "${trace}" > \
      "${EVIDENCE_DIR}/equivalence-${variant}-${side}.trace.gz"
  done
  if ! cmp -s \
      "${work_dir}/equivalence-${variant}-reference/old-abi.trace" \
      "${work_dir}/equivalence-${variant}-candidate/old-abi.trace"; then
    diff -u \
      "${work_dir}/equivalence-${variant}-reference/old-abi.trace" \
      "${work_dir}/equivalence-${variant}-candidate/old-abi.trace" \
      > "${EVIDENCE_DIR}/equivalence-${variant}.diff" || true
    fail "${variant} candidate old ABI differs from the pre-source snapshot"
  fi
  printf '%s_equivalence=PASS\n' "${variant}" \
    >> "${EVIDENCE_DIR}/equivalence-summary.txt"
}

run_equivalence_variant release ''
run_equivalence_variant ooo_assert '-DOOO_ASSERT'

module_result_dir="${work_dir}/module-aggregate-result"
make -C "${TB_DIR}" \
  NPC_SINGLE_HOME="${NPC_HOME}" \
  BUILD_DIR="${work_dir}/module-aggregate-build" \
  RESULT_DIR="${module_result_dir}" \
  run > "${EVIDENCE_DIR}/module-aggregate.log" 2>&1
module_summary="${module_result_dir}/summary.txt"
grep -Fqx -- '- total: 104' "${module_summary}" ||
  fail "module aggregate total drift"
grep -Fqx -- '- passed: 104' "${module_summary}" ||
  fail "module aggregate did not pass 104/104"
grep -Fqx -- '- failed: 0' "${module_summary}" ||
  fail "module aggregate contains failures"
cp -- "${module_summary}" "${EVIDENCE_DIR}/module-aggregate-summary.txt"

make -C "${NPC_HOME}" check-rtl-style \
  > "${EVIDENCE_DIR}/check-rtl-style.log" 2>&1
grep -Fq '[check-rtl-style] PASS:' \
  "${EVIDENCE_DIR}/check-rtl-style.log" ||
  fail "RTL style gate did not pass"
make -C "${NPC_HOME}" check-contract \
  > "${EVIDENCE_DIR}/check-contract.log" 2>&1
grep -Fq '契约立即断言（$error）计数：当前=289 基线=89' \
  "${EVIDENCE_DIR}/check-contract.log" ||
  fail "contract assertion inventory drift"
grep -Fq 'check-contract: PASS' "${EVIDENCE_DIR}/check-contract.log" ||
  fail "contract gate did not pass"

set +e
make -C "${NPC_HOME}" lint > "${EVIDENCE_DIR}/strict-lint.log" 2>&1
strict_lint_rc=$?
make -B -C "${NPC_HOME}" default > "${EVIDENCE_DIR}/full-build.log" 2>&1
full_build_rc=$?
set -e
[[ "${strict_lint_rc}" -ne 0 ]] ||
  fail "strict lint unexpectedly passed; baseline disposition requires review"
[[ "${full_build_rc}" -ne 0 ]] ||
  fail "full default build unexpectedly passed; baseline disposition requires review"
grep -Fq '%Error: Exiting due to 115 warning(s)' \
  "${EVIDENCE_DIR}/strict-lint.log" ||
  fail "strict lint did not fail on the locked 115-warning baseline"
grep -Fq '%Error: Exiting due to 115 warning(s)' \
  "${EVIDENCE_DIR}/full-build.log" ||
  fail "full default build did not fail on the locked 115-warning baseline"

normalize_warning_log "${EVIDENCE_DIR}/strict-lint.log" \
  > "${EVIDENCE_DIR}/lint-candidate.normalized"
normalize_warning_log "${EVIDENCE_DIR}/full-build.log" \
  > "${work_dir}/full-build.normalized"
cmp -s "${EVIDENCE_DIR}/lint-candidate.normalized" \
       "${EVIDENCE_DIR}/lint-pre-snapshot.normalized" ||
  fail "strict lint normalized signature differs from pre-snapshot"
cmp -s "${work_dir}/full-build.normalized" \
       "${EVIDENCE_DIR}/lint-pre-snapshot.normalized" ||
  fail "full build normalized signature differs from pre-snapshot"
[[ "$(wc -l < "${EVIDENCE_DIR}/lint-candidate.normalized")" -eq 115 ]] ||
  fail "normalized strict warning count drift"
[[ "$(grep -c '^%Warning-TIMESCALEMOD:' \
      "${EVIDENCE_DIR}/lint-candidate.normalized")" -eq 108 ]] ||
  fail "TIMESCALEMOD warning inventory drift"
[[ "$(grep -c '^%Warning-PINCONNECTEMPTY:' \
      "${EVIDENCE_DIR}/lint-candidate.normalized")" -eq 2 ]] ||
  fail "PINCONNECTEMPTY warning inventory drift"
[[ "$(grep -c '^%Warning-LATCH:' \
      "${EVIDENCE_DIR}/lint-candidate.normalized")" -eq 4 ]] ||
  fail "LATCH warning inventory drift"
[[ "$(grep -c '^%Warning-UNOPTFLAT:' \
      "${EVIDENCE_DIR}/lint-candidate.normalized")" -eq 1 ]] ||
  fail "UNOPTFLAT warning inventory drift"

make -C "${NPC_HOME}" VERILATOR='verilator -Wno-fatal' lint \
  > "${EVIDENCE_DIR}/lint-nonfatal-diagnostic.log" 2>&1
if grep -q '^%Error:' "${EVIDENCE_DIR}/lint-nonfatal-diagnostic.log"; then
  fail "nonfatal lint parse/elaboration contains an error"
fi
normalize_warning_log "${EVIDENCE_DIR}/lint-nonfatal-diagnostic.log" \
  > "${work_dir}/lint-nonfatal.normalized"
cmp -s "${work_dir}/lint-nonfatal.normalized" \
       "${EVIDENCE_DIR}/lint-pre-snapshot.normalized" ||
  fail "nonfatal lint signature differs from pre-snapshot"

{
  printf 'lint_gate=RED\n'
  printf 'full_default_build_gate=RED\n'
  printf 'warning_count_candidate=115\n'
  printf 'warning_count_pre_snapshot=115\n'
  printf 'warning_signature_breakdown=TIMESCALEMOD:108,PINCONNECTEMPTY:2,LATCH:4,UNOPTFLAT:1\n'
  printf 'normalized_warning_signature=MATCH\n'
  printf 'nonfatal_parse_elaboration=PASS\n'
  printf 'disposition=inherited baseline; not waived; no v8a-specific warning introduced\n'
} > "${EVIDENCE_DIR}/lint-baseline-comparison.txt"

git diff --check > "${EVIDENCE_DIR}/git-diff-check.log"
sha256sum "${source_paths[@]}" > "${EVIDENCE_DIR}/sources.post.sha256"
cmp -s "${EVIDENCE_DIR}/sources.pre.sha256" \
       "${EVIDENCE_DIR}/sources.post.sha256" ||
  fail "source inventory changed while the GREEN runner was active"
cp -- "${EVIDENCE_DIR}/sources.post.sha256" \
  "${EVIDENCE_DIR}/sources.sha256"
sha256sum -c "${EVIDENCE_DIR}/sources.sha256" \
  > "${EVIDENCE_DIR}/sources-check.log"

{
  printf 'contract_schema=s2-q2-shadow-foundation-interface-v8a\n'
  printf 'status=GREEN\n'
  printf 'checker_self_test=PASS mutations=17\n'
  printf 'structural_readiness=PASS release+ooo_assert\n'
  printf 'implementation_readiness=PASS commit-prefix,identity,scalar-ABI,census\n'
  printf 'focused_tests=PASS variants=2 tests_per_variant=%s\n' \
    "${#focused_tbs[@]}"
  printf 'candidate_live_negative=PASS expected_nonzero_rc=%s\n' \
    "${negative_rc}"
  printf 'csr_queue_head_explicit_enable=PASS\n'
  printf 'csr_queue_head_explicit_zero=PASS\n'
  printf 'old_abi_equivalence=PASS variants=release,ooo_assert reference=pre-source-bundle\n'
  printf 'module_aggregate=PASS 104/104\n'
  printf 'rtl_style=PASS\n'
  printf 'contract=PASS assertions=289 baseline=89\n'
  printf 'global_strict_lint=RED inherited_warning_signature_match=PASS count=115\n'
  printf 'global_full_default_build=RED inherited_warning_signature_match=PASS count=115\n'
  printf 'nonfatal_parse_elaboration=PASS\n'
  printf 'pre_source_bundle_sha256=%s\n' "${actual_pre_bundle_sha256}"
  printf 'scope=v8a tie-high scoped neutral shadow foundation only\n'
  printf 'deferred=v8b P0 blockers,active permits,Q1,payload,FENCE.I transaction,squash,generation,full identity safety\n'
  printf 'ppa_claim=none\n'
} > "${EVIDENCE_DIR}/summary.txt"

(
  cd "${EVIDENCE_DIR}"
  find . -maxdepth 1 -type f \
    ! -name complete.marker ! -name evidence.sha256 -print0 |
    sort -z | xargs -0 sha256sum
) > "${EVIDENCE_DIR}/evidence.sha256"
(
  cd "${EVIDENCE_DIR}"
  sha256sum -c evidence.sha256
) > "${EVIDENCE_DIR}/evidence-check.log"

{
  printf 'status=complete\n'
  printf 'contract_schema=s2-q2-shadow-foundation-interface-v8a\n'
  printf 'summary_sha256=%s\n' \
    "$(sha256sum "${EVIDENCE_DIR}/summary.txt" | awk '{print $1}')"
  printf 'evidence_inventory_sha256=%s\n' \
    "$(sha256sum "${EVIDENCE_DIR}/evidence.sha256" | awk '{print $1}')"
  printf 'source_inventory_sha256=%s\n' \
    "$(sha256sum "${EVIDENCE_DIR}/sources.sha256" | awk '{print $1}')"
} > "${COMPLETE_MARKER}"

printf '[S2-Q2-V8A-GREEN][PASS] structural, dynamic, negative, and pre-snapshot equivalence gates passed\n'
