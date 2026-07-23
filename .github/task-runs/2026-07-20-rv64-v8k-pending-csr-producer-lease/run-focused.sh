#!/usr/bin/env bash
set -euo pipefail

RUN_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)
REPO_ROOT=$(git -C "$RUN_DIR" rev-parse --show-toplevel)
NPC_HOME="$REPO_ROOT/npc/rv64"
TB_HOME="$NPC_HOME/testbench"
EVIDENCE_DIR="$RUN_DIR/evidence/focused-run"
AUDIT="$RUN_DIR/audit-v8k-pending-csr.py"
MUTATOR="$RUN_DIR/mutate-v8k-pending-csr.py"
TEMP_DIR=$(mktemp -d "${TMPDIR:-/tmp}/v8k-pending-csr.XXXXXX")

cleanup() {
  if [[ -d "$TEMP_DIR" && "$TEMP_DIR" == "${TMPDIR:-/tmp}"/v8k-pending-csr.* ]]; then
    rm -rf -- "$TEMP_DIR"
  fi
}
trap cleanup EXIT

case "$EVIDENCE_DIR" in
  "$RUN_DIR"/evidence/focused-run) rm -rf -- "$EVIDENCE_DIR" ;;
  *) printf '[V8K-RUNNER][FAIL] unsafe evidence path: %s\n' "$EVIDENCE_DIR" >&2; exit 2 ;;
esac
mkdir -p "$EVIDENCE_DIR"

fail() {
  printf '[V8K-RUNNER][FAIL] %s\n' "$*" >&2
  exit 1
}

source_paths=(
  "$RUN_DIR/contract.md"
  "$RUN_DIR/rtl-derivation.md"
  "$RUN_DIR/holder-census-delta.md"
  "$RUN_DIR/dispatch-log.md"
  "$RUN_DIR/run-focused.sh"
  "$AUDIT"
  "$MUTATOR"
  "$NPC_HOME/design/specs/ooo-pending-system-csr-producer-lease.md"
  "$NPC_HOME/vsrc/control/OooPendingSystemSequencer.v"
  "$NPC_HOME/vsrc/control/OooCsrAccessRequestMux.v"
  "$NPC_HOME/vsrc/control/OooPendingDrainResolveGate.v"
  "$NPC_HOME/vsrc/control/OooPendingSystemAdmissionCancelGate.v"
  "$NPC_HOME/vsrc/control/OooControlPlane.v"
  "$NPC_HOME/vsrc/execute/OooIntBackend.v"
  "$NPC_HOME/vsrc/decode/OooAluDecodeBackend.v"
  "$NPC_HOME/vsrc/execute/OooAluCoreSlice.v"
  "$NPC_HOME/vsrc/execute/OooExecuteBackend.v"
  "$NPC_HOME/vsrc/core/OooCoreTopGlue.v"
  "$TB_HOME/tests/tb_ooo_pending_system_sequencer.sv"
  "$TB_HOME/tests/tb_ooo_pending_system_lease_probe.sv"
  "$TB_HOME/tests/tb_ooo_csr_access_request_mux.sv"
  "$TB_HOME/tests/tb_ooo_pending_drain_resolve_gate.sv"
  "$TB_HOME/tests/tb_ooo_pending_system_admission_cancel_gate.sv"
  "$TB_HOME/tests/tb_ooo_int_backend.sv"
  "$TB_HOME/tests/tb_ooo_priv_system.sv"
  "$TB_HOME/Makefile"
)
sha256sum "${source_paths[@]}" > "$EVIDENCE_DIR/sources.pre.sha256"

base_flags='-g2012 -Wall -I../vsrc -I../vsrc/include -Icommon'

run_make() {
  local label=$1
  local tests=$2
  local flags=$3
  local kind=${4:-current}
  local source=${5:-}
  local result_dir="$EVIDENCE_DIR/$label"
  local build_dir="$TEMP_DIR/build-$label"
  local make_log="$EVIDENCE_DIR/$label.make.log"
  local -a overrides=()

  case "$result_dir" in "$EVIDENCE_DIR"/*) ;; *) fail "unsafe result path: $result_dir" ;; esac
  case "$kind" in
    current) ;;
    sequencer) overrides+=("RTL_OOO_PENDING_SYSTEM_SEQUENCER=$source") ;;
    mux) overrides+=("RTL_OOO_CSR_ACCESS_REQUEST_MUX=$source") ;;
    drain) overrides+=("RTL_OOO_PENDING_DRAIN_RESOLVE_GATE=$source") ;;
    admission) overrides+=("RTL_OOO_PENDING_SYSTEM_ADMISSION_CANCEL_GATE=$source") ;;
    backend) overrides+=("RTL_OOO_INT_BACKEND=$source") ;;
    *) fail "unknown source kind: $kind" ;;
  esac

  set +e
  make -B -C "$TB_HOME" \
    "TESTS=$tests" \
    "BUILD_DIR=$build_dir" \
    "RESULT_DIR=$result_dir" \
    "IVFLAGS=$flags" \
    "${overrides[@]}" run > "$make_log" 2>&1
  local rc=$?
  set -e
  printf '[MAKE-RC] %d\n' "$rc" >> "$make_log"
  return "$rc"
}

require_pass() {
  local label=$1
  local tests=$2
  local flags=$3
  run_make "$label" "$tests" "$flags" || fail "$label did not pass"
  grep -Fq -- '- failed: 0' "$EVIDENCE_DIR/$label.make.log" ||
    fail "$label lacks zero-failure summary"
}

expect_compile_success_failure() {
  local label=$1
  local test_name=$2
  local flags=$3
  local kind=${4:-current}
  local source=${5:-}
  local marker=${6:-}
  local log="$EVIDENCE_DIR/$label/logs/$test_name.log"

  if run_make "$label" "$test_name" "$flags" "$kind" "$source"; then
    fail "$label unexpectedly passed"
  fi
  [[ -f "$log" ]] || fail "$label did not produce a per-test log"
  grep -Fq '[COMPILE]' "$log" || fail "$label never reached compilation"
  if grep -Eq 'compile returned nonzero|syntax error|error\(s\) during elaboration|Unable to open input file' "$log"; then
    fail "$label failed compilation instead of semantic validation"
  fi
  grep -Eq '^FAIL |\[CHECK-FAIL\]|\[FAIL\]|ERROR:|FATAL:|fatal' "$log" ||
    fail "$label lacks a semantic failure marker"
  if [[ -n "$marker" ]]; then
    grep -Fq "$marker" "$log" || fail "$label lacks expected marker $marker"
  fi
}

python3 "$AUDIT" > "$EVIDENCE_DIR/static-audit.log"
grep -Fq '[V8K-PENDING-CSR-AUDIT] PASS' "$EVIDENCE_DIR/static-audit.log" ||
  fail 'static audit did not emit PASS'

require_pass baseline-leaf-assert \
  'tb_ooo_pending_system_sequencer tb_ooo_csr_access_request_mux tb_ooo_pending_drain_resolve_gate tb_ooo_pending_system_admission_cancel_gate' \
  "$base_flags -DOOO_ASSERT"
require_pass baseline-csr-mux-qh-assert \
  'tb_ooo_csr_access_request_mux' \
  "$base_flags -DOOO_ASSERT -DOOO_CSR_QUEUE_HEAD=1"
require_pass baseline-int-assert \
  'tb_ooo_int_backend' \
  "$base_flags -DOOO_ASSERT -DV8K_PENDING_CSR_LEASE_FOCUSED"
require_pass baseline-int-release \
  'tb_ooo_int_backend' \
  "$base_flags -DV8K_PENDING_CSR_LEASE_FOCUSED"
require_pass baseline-priv-forward \
  'tb_ooo_priv_system' \
  "$base_flags -DOOO_ASSERT"
require_pass probe-partial-release \
  'tb_ooo_pending_system_lease_probe' \
  "$base_flags -DV8K_PROBE_PARTIAL_METADATA"
require_pass probe-live-clear-release \
  'tb_ooo_pending_system_lease_probe' \
  "$base_flags -DV8K_PROBE_LIVE_CLEAR"
require_pass probe-live-cdisp-release \
  'tb_ooo_pending_system_lease_probe' \
  "$base_flags -DV8K_PROBE_LIVE_CLEAR_DISPATCHED"

expect_compile_success_failure assertion-partial-metadata \
  tb_ooo_pending_system_lease_probe \
  "$base_flags -DOOO_ASSERT -DV8K_ASSERT_PARTIAL_METADATA" \
  current '' '[V8K-PENDING-CSR-LEASE-SHAPE]'
expect_compile_success_failure assertion-live-clear \
  tb_ooo_pending_system_lease_probe \
  "$base_flags -DOOO_ASSERT -DV8K_ASSERT_LIVE_CLEAR" \
  current '' '[V8K-PENDING-CSR-NO-RECAPTURE]'

printf 'case\tkind\ttest\tresult\n' > "$EVIDENCE_DIR/mutation-summary.tsv"
mutation_rows=(
  'lease_output_metadata_gated|sequencer|tb_ooo_pending_system_lease_probe|-DV8K_PROBE_PARTIAL_METADATA'
  'ordinary_clear_kills_live|sequencer|tb_ooo_pending_system_lease_probe|-DV8K_PROBE_LIVE_CLEAR'
  'clear_dispatched_kills_live|sequencer|tb_ooo_pending_system_lease_probe|-DV8K_PROBE_LIVE_CLEAR_DISPATCHED'
  'birth_drops_generation|sequencer|tb_ooo_pending_system_sequencer|-DOOO_ASSERT'
  'claim_seal_ignores_raw|mux|tb_ooo_csr_access_request_mux|-DOOO_ASSERT -DOOO_CSR_QUEUE_HEAD=1'
  'pid_match_ignores_generation|mux|tb_ooo_csr_access_request_mux|-DOOO_ASSERT'
  'pc_match_removed|mux|tb_ooo_csr_access_request_mux|-DOOO_ASSERT'
  'dispatch_cancel_removed|drain|tb_ooo_pending_drain_resolve_gate|-DOOO_ASSERT'
  'pending_jump_ready_overcancels|admission|tb_ooo_pending_system_admission_cancel_gate|-DOOO_ASSERT'
  'pending_mask_removed|backend|tb_ooo_int_backend|-DOOO_ASSERT -DV8K_PENDING_CSR_LEASE_FOCUSED'
)

for row in "${mutation_rows[@]}"; do
  IFS='|' read -r case_name kind test_name extra_flags <<< "$row"
  source="$TEMP_DIR/$case_name.v"
  python3 "$MUTATOR" --case "$case_name" --out "$source" \
    > "$EVIDENCE_DIR/mutator-$case_name.json"
  expect_compile_success_failure "mutation-$case_name" "$test_name" \
    "$base_flags $extra_flags" "$kind" "$source"
  printf '%s\t%s\t%s\tcompile-success-semantic-failure\n' \
    "$case_name" "$kind" "$test_name" >> "$EVIDENCE_DIR/mutation-summary.tsv"
done

python3 "$AUDIT" > "$EVIDENCE_DIR/static-audit.post.log"
sha256sum "${source_paths[@]}" > "$EVIDENCE_DIR/sources.post.sha256"
cmp -s "$EVIDENCE_DIR/sources.pre.sha256" "$EVIDENCE_DIR/sources.post.sha256" ||
  fail 'canonical sources changed while running isolated mutations'

mutation_count=$(($(wc -l < "$EVIDENCE_DIR/mutation-summary.tsv") - 1))
[[ "$mutation_count" -eq "${#mutation_rows[@]}" ]] ||
  fail "mutation count mismatch: $mutation_count/${#mutation_rows[@]}"

{
  printf '# v8k focused verification summary\n\n'
  printf -- '- source-bound audit: 14/14 PASS\n'
  printf -- '- assert baseline: leaf 4/4 + IntBackend 1/1 + real priv 1/1 PASS\n'
  printf -- '- release baseline: IntBackend 1/1 + malformed-state probes 3/3 PASS\n'
  printf -- '- expected-fail assertion probes: 2/2 rejected\n'
  printf -- '- compile-success semantic mutations: %d/%d rejected\n' \
    "$mutation_count" "${#mutation_rows[@]}"
  printf -- '- canonical source hash stability: PASS\n'
  printf -- '- claim level: dispatched pending CSR scoped architecture evidence only; promotion_eligible=false\n'
} > "$EVIDENCE_DIR/summary.md"

find "$EVIDENCE_DIR" -type f ! -name complete.marker -print0 |
  sort -z | xargs -0 sha256sum > "$EVIDENCE_DIR/complete.marker"
printf '# [V8K-RUNNER][PASS] mutations=%d assertions=2\n' \
  "$mutation_count" >> "$EVIDENCE_DIR/complete.marker"
printf '[V8K-RUNNER] PASS: %d compile-success semantic mutations rejected\n' \
  "$mutation_count"
