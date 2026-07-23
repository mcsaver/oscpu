#!/usr/bin/env bash
set -euo pipefail

RUN_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPO_ROOT=$(git -C "$RUN_DIR" rev-parse --show-toplevel)
NPC_HOME="$REPO_ROOT/npc/rv64"
TB_HOME="$NPC_HOME/testbench"
EVIDENCE_DIR="$RUN_DIR/evidence/focused-run"
AUDIT="$RUN_DIR/audit-v8j-branch-resolve.py"
MUTATOR="$RUN_DIR/mutate-v8j-branch-resolve.py"
TEMP_DIR=$(mktemp -d "${TMPDIR:-/tmp}/v8j-branch-resolve.XXXXXX")

cleanup() {
  if [[ -d "$TEMP_DIR" && "$TEMP_DIR" == "${TMPDIR:-/tmp}"/v8j-branch-resolve.* ]]; then
    rm -rf -- "$TEMP_DIR"
  fi
}
trap cleanup EXIT

case "$EVIDENCE_DIR" in
  "$RUN_DIR"/evidence/focused-run) rm -rf -- "$EVIDENCE_DIR" ;;
  *) printf '[V8J-RUNNER][FAIL] unsafe evidence path: %s\n' "$EVIDENCE_DIR" >&2; exit 2 ;;
esac
mkdir -p "$EVIDENCE_DIR"

fail() {
  printf '[V8J-RUNNER][FAIL] %s\n' "$*" >&2
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
  "$NPC_HOME/design/specs/ooo-branch-resolve-producer-authorization.md"
  "$NPC_HOME/vsrc/execute/OooIntBackend.v"
  "$NPC_HOME/vsrc/rename_allocate/OooDispatchBackend.v"
  "$NPC_HOME/vsrc/writeback/OooRob.v"
  "$TB_HOME/tests/tb_ooo_int_backend.sv"
  "$TB_HOME/tests/tb_ooo_dispatch_backend.sv"
  "$TB_HOME/tests/tb_ooo_rob.sv"
)
sha256sum "${source_paths[@]}" > "$EVIDENCE_DIR/sources.pre.sha256"

base_flags='-g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DV8J_BRANCH_RESOLVE_AUTH_FOCUSED'

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
    backend) overrides+=("RTL_OOO_INT_BACKEND=$source") ;;
    rob) overrides+=("RTL_OOO_ROB=$source") ;;
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
  grep -Fq -- '- failed: 0' "$EVIDENCE_DIR/$label.make.log" ||
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
  grep -Eq '\[CHECK-FAIL\]|\[FAIL\]|ERROR:|FATAL:|fatal' "$log" ||
    fail "$case_name lacks a semantic failure marker"
  printf '%s\t%s\t%s\tcompile-success-semantic-failure\n' \
    "$case_name" "$kind" "$test_name" >> "$EVIDENCE_DIR/mutation-summary.tsv"
}

python3 "$AUDIT" > "$EVIDENCE_DIR/static-audit.log"
grep -Fq '[V8J-BRANCH-RESOLVE-AUDIT] PASS' "$EVIDENCE_DIR/static-audit.log" ||
  fail 'static audit did not emit PASS'

require_pass baseline-assert \
  'tb_ooo_int_backend tb_ooo_rob tb_ooo_dispatch_backend' \
  "$base_flags -DOOO_ASSERT"
require_pass baseline-release \
  'tb_ooo_int_backend tb_ooo_rob tb_ooo_dispatch_backend' \
  "$base_flags"

printf 'case\tkind\ttest\tresult\n' > "$EVIDENCE_DIR/mutation-summary.tsv"
mutation_rows=(
  'carrier_corrupts_generation|backend|tb_ooo_int_backend'
  'auth_ignores_query|backend|tb_ooo_int_backend'
  'auth_ignores_raw_ex0|backend|tb_ooo_int_backend'
  'coherence_uses_semantic_valid|backend|tb_ooo_int_backend'
  'public_valid_uses_candidate|backend|tb_ooo_int_backend'
  'checkpoint_cancel_removed|backend|tb_ooo_int_backend'
  'projection_corrupts_index|backend|tb_ooo_int_backend'
  'rob_query_ignores_generation|rob|tb_ooo_rob'
  'rob_query_ignores_done|rob|tb_ooo_rob'
  'rob_query_ignores_recovery|rob|tb_ooo_rob'
  'rob_query_reads_current_kill|rob|tb_ooo_rob'
  'completion0_kill_dependency_sticky|rob|tb_ooo_rob'
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
cmp -s "$EVIDENCE_DIR/sources.pre.sha256" "$EVIDENCE_DIR/sources.post.sha256" ||
  fail 'canonical sources changed while running isolated mutations'

mutation_count=$(($(wc -l < "$EVIDENCE_DIR/mutation-summary.tsv") - 1))
[[ "$mutation_count" -eq "${#mutation_rows[@]}" ]] ||
  fail "mutation count mismatch: $mutation_count/${#mutation_rows[@]}"

{
  printf '# v8j focused verification summary\n\n'
  printf -- '- static source-bound audit: PASS\n'
  printf -- '- assert baseline: 3/3 modules PASS\n'
  printf -- '- release baseline: 3/3 modules PASS\n'
  printf -- '- directed cases: live/stale/raw-EX0 mismatch/death-edge/self-kill/sensitivity PASS\n'
  printf -- '- compile-success semantic mutations: %d/%d rejected\n' \
    "$mutation_count" "${#mutation_rows[@]}"
  printf -- '- canonical source hash stability: PASS\n'
} > "$EVIDENCE_DIR/summary.md"

printf '[V8J-RUNNER] PASS: %d compile-success semantic mutations rejected\n' \
  "$mutation_count"
