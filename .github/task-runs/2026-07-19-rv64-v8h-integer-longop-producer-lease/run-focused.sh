#!/usr/bin/env bash
set -euo pipefail

RUN_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPO_ROOT=$(git -C "$RUN_DIR" rev-parse --show-toplevel)
NPC_HOME="$REPO_ROOT/npc/rv64"
TB_HOME="$NPC_HOME/testbench"
EVIDENCE_DIR="$RUN_DIR/evidence/focused"
AUDIT="$RUN_DIR/audit-v8h-longop-lease.py"
MUTATOR="$RUN_DIR/mutate-v8h-longop-lease.py"
TEMP_DIR=$(mktemp -d "${TMPDIR:-/tmp}/v8h-longop-lease.XXXXXX")

cleanup() {
  if [[ -d "$TEMP_DIR" && "$TEMP_DIR" == "${TMPDIR:-/tmp}"/v8h-longop-lease.* ]]; then
    rm -rf -- "$TEMP_DIR"
  fi
}
trap cleanup EXIT

case "$EVIDENCE_DIR" in
  "$RUN_DIR"/evidence/focused) rm -rf -- "$EVIDENCE_DIR" ;;
  *) printf '[V8H-RUNNER][FAIL] unsafe evidence path: %s\n' "$EVIDENCE_DIR" >&2; exit 2 ;;
esac
mkdir -p "$EVIDENCE_DIR"

fail() {
  printf '[V8H-RUNNER][FAIL] %s\n' "$*" >&2
  exit 1
}

source_paths=(
  "$RUN_DIR/contract.md"
  "$RUN_DIR/contract-amendment-v8h1.md"
  "$RUN_DIR/rtl-derivation.md"
  "$RUN_DIR/holder-census-delta.md"
  "$RUN_DIR/run-focused.sh"
  "$AUDIT"
  "$MUTATOR"
  "$NPC_HOME/design/specs/ooo-integer-longop-producer-lease.md"
  "$NPC_HOME/vsrc/execute/OooMulDivUnit.v"
  "$NPC_HOME/vsrc/execute/OooClmulUnit.v"
  "$NPC_HOME/vsrc/execute/OooIntBackend.v"
  "$NPC_HOME/vsrc/rename_allocate/OooDispatchBackend.v"
  "$NPC_HOME/vsrc/writeback/OooRob.v"
  "$TB_HOME/tests/tb_ooo_muldiv_unit.sv"
  "$TB_HOME/tests/tb_ooo_clmul_unit.sv"
  "$TB_HOME/tests/tb_ooo_int_backend.sv"
  "$TB_HOME/tests/tb_ooo_dispatch_backend.sv"
  "$TB_HOME/tests/tb_ooo_rob.sv"
)
sha256sum "${source_paths[@]}" > "$EVIDENCE_DIR/sources.pre.sha256"

base_flags='-g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DV8H_LONGOP_PRODUCER_LEASE_FOCUSED'

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
    muldiv) overrides+=("RTL_OOO_MULDIV_UNIT=$source") ;;
    clmul) overrides+=("RTL_OOO_CLMUL_UNIT=$source") ;;
    backend) overrides+=("RTL_OOO_INT_BACKEND=$source") ;;
    rob) overrides+=("RTL_OOO_ROB=$source") ;;
    dispatch) overrides+=("RTL_OOO_DISPATCH_BACKEND=$source") ;;
    *) fail "unknown source kind: $kind" ;;
  esac

  set +e
  make -C "$TB_HOME" \
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
  grep -Fq -- '- failed: 0' "$EVIDENCE_DIR/$label.make.log" || \
    fail "$label lacks zero-failure summary"
}

expect_compile_success_failure() {
  local case_name=$1
  local kind=$2
  local test_name=$3
  local source=$4
  local label="mutation-$case_name"
  local log="$EVIDENCE_DIR/$label/logs/$test_name.log"
  if run_make "$label" "$test_name" "$base_flags -DOOO_ASSERT" "$kind" "$source"; then
    fail "$case_name unexpectedly passed"
  fi
  [[ -f "$log" ]] || fail "$case_name did not produce a per-test log"
  grep -Fq '[COMPILE]' "$log" || fail "$case_name never reached compilation"
  if grep -Eq 'compile returned nonzero|syntax error|error\(s\) during elaboration|Unable to open input file' "$log"; then
    fail "$case_name failed compilation instead of semantic validation"
  fi
  grep -Eq '\[CHECK-FAIL\]|\[FAIL\]|ERROR:|FATAL:' "$log" || \
    fail "$case_name lacks a semantic failure marker"
  printf '%s\t%s\t%s\tcompile-success-semantic-failure\n' \
    "$case_name" "$kind" "$test_name" >> "$EVIDENCE_DIR/mutation-summary.tsv"
}

python3 "$AUDIT" > "$EVIDENCE_DIR/static-audit.log"
grep -Fq '[V8H-LONGOP-LEASE-AUDIT] PASS' "$EVIDENCE_DIR/static-audit.log" || \
  fail 'static audit did not emit PASS'

require_pass baseline-assert-leaves \
  'tb_ooo_muldiv_unit tb_ooo_clmul_unit' "$base_flags -DOOO_ASSERT"
require_pass baseline-assert-backend tb_ooo_int_backend "$base_flags -DOOO_ASSERT"
require_pass baseline-assert-rob-dispatch \
  'tb_ooo_rob tb_ooo_dispatch_backend' "$base_flags -DOOO_ASSERT"
require_pass baseline-release-leaves \
  'tb_ooo_muldiv_unit tb_ooo_clmul_unit' "$base_flags"
require_pass baseline-release-backend tb_ooo_int_backend "$base_flags"
require_pass baseline-release-rob-dispatch \
  'tb_ooo_rob tb_ooo_dispatch_backend' "$base_flags"

printf 'case\tkind\ttest\tresult\n' > "$EVIDENCE_DIR/mutation-summary.tsv"

mutation_rows=(
  'muldiv_drop_generation|muldiv|tb_ooo_muldiv_unit'
  'clmul_drop_generation|clmul|tb_ooo_clmul_unit'
  'muldiv_resp_only_lease|muldiv|tb_ooo_muldiv_unit'
  'clmul_resp_only_lease|clmul|tb_ooo_clmul_unit'
  'muldiv_early_terminal_release|muldiv|tb_ooo_muldiv_unit'
  'clmul_early_terminal_release|clmul|tb_ooo_clmul_unit'
  'muldiv_ready_ignores_kill|muldiv|tb_ooo_muldiv_unit'
  'clmul_ready_ignores_kill|clmul|tb_ooo_clmul_unit'
  'backend_union_omits_muldiv|backend|tb_ooo_int_backend'
  'backend_union_omits_clmul|backend|tb_ooo_int_backend'
  'backend_ex1_ignores_ex0_claim|backend|tb_ooo_int_backend'
  'backend_muldiv_ignores_ex0_claim|backend|tb_ooo_int_backend'
  'backend_clmul_ignores_ex1_claim|backend|tb_ooo_int_backend'
  'backend_muldiv_ignores_memory_claim|backend|tb_ooo_int_backend'
  'backend_clmul_ignores_memory_claim|backend|tb_ooo_int_backend'
  'backend_clmul_ignores_muldiv_claim|backend|tb_ooo_int_backend'
  'backend_muldiv_ignores_open|backend|tb_ooo_int_backend'
  'backend_clmul_ignores_open|backend|tb_ooo_int_backend'
  'backend_muldiv_ready_reads_authority|backend|tb_ooo_int_backend'
  'rob_query3_ignores_generation|rob|tb_ooo_rob'
  'rob_query4_ignores_done|rob|tb_ooo_rob'
  'rob_pair_candidate_aliases_lane0|rob|tb_ooo_rob'
  'dispatch_lane0_truncates_pid|dispatch|tb_ooo_dispatch_backend'
)

for row in "${mutation_rows[@]}"; do
  IFS='|' read -r case_name kind test_name <<< "$row"
  source="$TEMP_DIR/$case_name.v"
  python3 "$MUTATOR" --case "$case_name" --out "$source" \
    > "$EVIDENCE_DIR/mutator-$case_name.json"
  expect_compile_success_failure "$case_name" "$kind" "$test_name" "$source"
done

python3 "$AUDIT" > "$EVIDENCE_DIR/static-audit.post.log"
sha256sum "${source_paths[@]}" > "$EVIDENCE_DIR/sources.post.sha256"
cmp -s "$EVIDENCE_DIR/sources.pre.sha256" "$EVIDENCE_DIR/sources.post.sha256" || \
  fail 'canonical sources changed while running isolated mutations'

mutation_count=$(($(wc -l < "$EVIDENCE_DIR/mutation-summary.tsv") - 1))
[[ "$mutation_count" -eq "${#mutation_rows[@]}" ]] || \
  fail "mutation count mismatch: $mutation_count/${#mutation_rows[@]}"

{
  printf '# v8h focused verification summary\n\n'
  printf -- '- static audit: PASS\n'
  printf -- '- assert baselines: 5/5 modules PASS\n'
  printf -- '- release baselines: 5/5 modules PASS\n'
  printf -- '- compile-success semantic mutations: %d/%d rejected\n' \
    "$mutation_count" "${#mutation_rows[@]}"
  printf -- '- canonical source hash stability: PASS\n'
} > "$EVIDENCE_DIR/summary.md"

printf '[V8H-RUNNER] PASS: %d compile-success semantic mutations rejected\n' \
  "$mutation_count"
