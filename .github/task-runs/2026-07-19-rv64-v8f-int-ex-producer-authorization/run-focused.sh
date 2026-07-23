#!/usr/bin/env bash
set -euo pipefail

RUN_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPO_ROOT=$(git -C "$RUN_DIR" rev-parse --show-toplevel)
NPC_HOME="$REPO_ROOT/npc/rv64"
TB_HOME="$NPC_HOME/testbench"
EVIDENCE_DIR="$RUN_DIR/evidence/focused"
MUTATOR="$RUN_DIR/mutate-v8f-producer-auth.py"
CREDIT_AUDIT="$RUN_DIR/audit-v8f-wb-credit-cut.py"
ROB="$NPC_HOME/vsrc/writeback/OooRob.v"
DISPATCH="$NPC_HOME/vsrc/rename_allocate/OooDispatchBackend.v"
IQ="$NPC_HOME/vsrc/scheduling/OooIntIssueQueue.v"
IQ_SELECT="$NPC_HOME/vsrc/scheduling/OooIntIssueSelect8.v"
BACKEND="$NPC_HOME/vsrc/execute/OooIntBackend.v"
TEMP_DIR=$(mktemp -d "${TMPDIR:-/tmp}/v8f-producer-auth.XXXXXX")

cleanup() {
  if [[ -d "$TEMP_DIR" && "$TEMP_DIR" == "${TMPDIR:-/tmp}"/v8f-producer-auth.* ]]; then
    rm -rf -- "$TEMP_DIR"
  fi
}
trap cleanup EXIT

case "$EVIDENCE_DIR" in
  "$RUN_DIR"/evidence/focused) rm -rf -- "$EVIDENCE_DIR" ;;
  *) printf '[V8F-RUNNER][FAIL] unsafe evidence path: %s\n' "$EVIDENCE_DIR" >&2; exit 2 ;;
esac
mkdir -p "$EVIDENCE_DIR"

fail() {
  printf '[V8F-RUNNER][FAIL] %s\n' "$*" >&2
  exit 1
}

source_paths=(
  "$RUN_DIR/contract.md"
  "$RUN_DIR/contract-amendment-v8f1.md"
  "$RUN_DIR/rtl-derivation.md"
  "$RUN_DIR/holder-census-delta.md"
  "$RUN_DIR/run-focused.sh"
  "$MUTATOR"
  "$CREDIT_AUDIT"
  "$NPC_HOME/vsrc/include/define.v"
  "$NPC_HOME/vsrc/filelist.mk"
  "$TB_HOME/Makefile"
  "$ROB"
  "$DISPATCH"
  "$IQ"
  "$BACKEND"
  "$TB_HOME/tests/tb_ooo_rob.sv"
  "$TB_HOME/tests/tb_ooo_dispatch_backend.sv"
  "$TB_HOME/tests/tb_ooo_int_issue_queue.sv"
  "$TB_HOME/tests/tb_ooo_int_backend.sv"
)
sha256sum "${source_paths[@]}" > "$EVIDENCE_DIR/sources.pre.sha256"

base_flags='-g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DINT_EX_PRODUCER_AUTH_FOCUSED'

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

  case "$result_dir" in
    "$EVIDENCE_DIR"/*) ;;
    *) fail "unsafe result path: $result_dir" ;;
  esac

  case "$kind" in
    current) ;;
    rob) overrides+=("RTL_OOO_ROB=$source") ;;
    dispatch) overrides+=("RTL_OOO_DISPATCH_BACKEND=$source") ;;
    iq) overrides+=("RTL_OOO_INT_ISSUE_QUEUE=$IQ_SELECT $source") ;;
    backend) overrides+=("RTL_OOO_INT_BACKEND=$source") ;;
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

require_exact_marker() {
  local marker=$1
  local log=$2
  local count
  count=$(grep -Fxc "$marker" "$log" || true)
  [[ "$count" -eq 1 ]] || fail "expected exactly one marker in ${log#$REPO_ROOT/}: $marker"
}

reject_unexpected_failure() {
  local log=$1
  if grep -Eq '\[CHECK-FAIL\]|\[RESULT\] FAIL|(^|[[:space:]])ERROR:|(^|[[:space:]])FATAL:' "$log"; then
    fail "unexpected failure marker in ${log#$REPO_ROOT/}"
  fi
}

run_baseline() {
  local label=$1
  local flags=$base_flags
  if [[ "$label" == assert ]]; then
    flags="$flags -DOOO_ASSERT"
  fi
  run_make "baseline-$label" \
    'tb_ooo_rob tb_ooo_dispatch_backend tb_ooo_int_issue_queue tb_ooo_int_backend' \
    "$flags" || fail "baseline $label failed"

  local result_dir="$EVIDENCE_DIR/baseline-$label"
  local rob_log="$result_dir/logs/tb_ooo_rob.log"
  local dispatch_log="$result_dir/logs/tb_ooo_dispatch_backend.log"
  local iq_log="$result_dir/logs/tb_ooo_int_issue_queue.log"
  local backend_log="$result_dir/logs/tb_ooo_int_backend.log"
  require_exact_marker '[V8F-ROB-PRODUCER-QUERY] vacant/exact/current/open/done/kill/recovery/flush PASS' "$rob_log"
  require_exact_marker '[V8F-DISPATCH-QUERY-BRIDGE] carrier/current/open/wrong-gen/done/flush PASS' "$dispatch_log"
  require_exact_marker '[V8F-INTIQ-PRODUCER-CARRIER] dual/hold/compact/replace/kill PASS' "$iq_log"
  require_exact_marker '[V8F-EARLY-WAKE-GENERATION-MISMATCH] raw=1 current=0 effective=0 dependent-sticky=0 PASS' "$backend_log"
  require_exact_marker '[V8F-EARLY1-WAKE-GENERATION-MISMATCH] raw=1 current=0 effective=0 sticky=0 N+1-issue=0 PASS' "$backend_log"
  require_exact_marker '[V8F-EX0-PRODUCER-AUTH] stale generation dropped; pre-auth reserves WB0; lower source uses WB1 PASS' "$backend_log"
  require_exact_marker '[V8F-EX1-PRODUCER-AUTH] stale generation dropped; pre-auth backpressure then exactly-once readiness PASS' "$backend_log"
  require_exact_marker '[V8F-MEM-RES-PRODUCER-AUTH] nonzero capture/hold/flush/local-terminal/stale-drain PASS' "$backend_log"
  require_exact_marker '[V8D-INT-EX-KILL-AGE] checks=8192 failures=0' "$backend_log"
  for log in "$rob_log" "$dispatch_log" "$iq_log" "$backend_log"; do
    require_exact_marker '[RESULT] PASS' "$log"
    reject_unexpected_failure "$log"
  done
  printf '[V8F-BASELINE][PASS] %s modules=4/4\n' "$label"
}

mutation_rows=(
  'rob_current0_ignore_generation|rob|tb_ooo_rob|v8f wrong generation is not current'
  'rob_completion0_ignore_generation|rob|tb_ooo_rob|v8f wrong generation completion is closed'
  'rob_current0_ignore_valid|rob|tb_ooo_rob|v8f vacant slot is not current'
  'rob_completion0_ignore_done|rob|tb_ooo_rob|v8f done slot completion closes'
  'rob_current0_ignore_kill|rob|tb_ooo_rob|v8f kill-start masks younger current query'
  'rob_completion0_ignore_kill|rob|tb_ooo_rob|v8f kill-start masks younger completion query'
  'rob_current1_lane_alias|rob|tb_ooo_rob|v8f live id1 is current'
  'iq_dispatch0_drop_generation|iq|tb_ooo_int_issue_queue|v8f lane0 full producer id'
  'iq_dispatch1_drop_generation|iq|tb_ooo_int_issue_queue|v8f lane1 full producer id'
  'iq_compaction_drop_generation|iq|tb_ooo_int_issue_queue|v8f survivor compacts with full id'
  'iq_issue1_alias_issue0|iq|tb_ooo_int_issue_queue|v8f lane1 full producer id'
  'dispatch_current1_query_alias0|dispatch|tb_ooo_int_backend|v8f early1 mismatch cuts effective wake'
  'dispatch_completion1_query_alias0|dispatch|tb_ooo_dispatch_backend|v8f bridge query1 wrong generation closed'
  'backend_early0_raw_authority|backend|tb_ooo_int_backend|v8f early mismatch cuts effective wake'
  'backend_early1_raw_authority|backend|tb_ooo_int_backend|v8f early1 mismatch cuts effective wake'
  'backend_ex0_no_open_gate|backend|tb_ooo_int_backend|v8f stale EX0 formal WB is cut'
  'backend_ex1_no_open_gate|backend|tb_ooo_int_backend|v8f stale EX1 formal WB is cut'
  'backend_mem_capture_drop_generation|backend|tb_ooo_int_backend|v8f mem hold reservation captured full producer id'
  'backend_mem_terminal_use_iq_pid|backend|tb_ooo_int_backend|v8f mem terminal exact full id reaches EX0 up'
  'backend_ex0_payload_drop_generation|backend|tb_ooo_int_backend|v8f mem terminal registers full reservation id'
  'backend_ex0_forward_raw|backend|tb_ooo_int_backend|v8f stale EX0 registered forward is cut'
  'backend_gpr0_raw|backend|tb_ooo_int_backend|v8f stale EX0 PRF write is cut'
  'backend_dispatch_wb0_raw|backend|tb_ooo_int_backend|v8f stale EX0 ROB write is cut'
  'backend_fp_iq_wake1_raw|backend|tb_ooo_int_backend|v8f stale EX1 FP-IQ wake is cut'
  'backend_execute0_raw|backend|tb_ooo_int_backend|v8f stale EX0 public completion is cut'
  'backend_slot0_uses_exact_valid|backend|tb_ooo_int_backend|v8f stale EX0 reserves WB0'
  'backend_slot1_uses_exact_valid|backend|tb_ooo_int_backend|v8f stale EX1 reserves WB1'
  'backend_slot0_uses_raw_valid|backend|tb_ooo_int_backend|v8d older MulDiv takes freed WB0'
  'backend_slot1_uses_raw_valid|backend|tb_ooo_int_backend|v8d killed EX1 frees WB1'
)

source_for_kind() {
  case "$1" in
    rob) printf '%s\n' "$ROB" ;;
    dispatch) printf '%s\n' "$DISPATCH" ;;
    iq) printf '%s\n' "$IQ" ;;
    backend) printf '%s\n' "$BACKEND" ;;
    *) return 1 ;;
  esac
}

basename_for_kind() {
  case "$1" in
    rob) printf 'OooRob.v\n' ;;
    dispatch) printf 'OooDispatchBackend.v\n' ;;
    iq) printf 'OooIntIssueQueue.v\n' ;;
    backend) printf 'OooIntBackend.v\n' ;;
    *) return 1 ;;
  esac
}

run_mutation() {
  local row=$1
  IFS='|' read -r name kind test target <<< "$row"
  local source
  source=$(source_for_kind "$kind")
  local basename
  basename=$(basename_for_kind "$kind")
  local mutant="$TEMP_DIR/mutants/$name/$basename"
  local mutator_log="$EVIDENCE_DIR/mutation-$name.mutator.log"
  local result_dir="$EVIDENCE_DIR/mutation-$name"
  local sim_log="$result_dir/logs/$test.log"

  python3 "$MUTATOR" "$name" "$source" "$mutant" > "$mutator_log"
  if run_make "mutation-$name" "$test" "$base_flags -DOOO_ASSERT" "$kind" "$mutant"; then
    fail "compile-success mutation survived: $name"
  fi
  [[ -s "$TEMP_DIR/build-mutation-$name/$test.vvp" ]] ||
    fail "mutation did not compile successfully: $name"
  [[ -f "$sim_log" ]] || fail "mutation has no simulation log: $name"
  grep -Fq '[COMPILE]' "$sim_log" || fail "mutation missed compile record: $name"
  grep -Fq '[RESULT] FAIL' "$sim_log" || fail "mutation did not finish RED: $name"
  grep -Fq "[CHECK-FAIL] $target" "$sim_log" ||
    fail "mutation missed target consequence: $name -> $target"
  printf '[V8F-MUTATION][PASS] %s kind=%s test=%s target=%s\n' \
    "$name" "$kind" "$test" "$target" >> "$EVIDENCE_DIR/mutation-summary.log"
}

summary_log="$EVIDENCE_DIR/runner-summary.log"
: > "$summary_log"
python3 "$CREDIT_AUDIT" "$BACKEND" |
  tee "$EVIDENCE_DIR/wb-credit-cut-audit.log" | tee -a "$summary_log"
run_baseline release | tee -a "$summary_log"
run_baseline assert | tee -a "$summary_log"
: > "$EVIDENCE_DIR/mutation-summary.log"
for row in "${mutation_rows[@]}"; do
  run_mutation "$row"
done

mutation_count=$(grep -c '^\[V8F-MUTATION\]\[PASS\]' "$EVIDENCE_DIR/mutation-summary.log" || true)
[[ "$mutation_count" -eq "${#mutation_rows[@]}" ]] ||
  fail "mutation inventory incomplete: $mutation_count/${#mutation_rows[@]}"
cat "$EVIDENCE_DIR/mutation-summary.log" >> "$summary_log"

sha256sum "${source_paths[@]}" > "$EVIDENCE_DIR/sources.post.sha256"
cmp -s "$EVIDENCE_DIR/sources.pre.sha256" "$EVIDENCE_DIR/sources.post.sha256" ||
  fail 'workspace source drifted during runner'

cat > "$EVIDENCE_DIR/summary.txt" <<EOF
V8F_INTEGER_PRODUCER_AUTH=SCOPED_GREEN
RELEASE_BASELINE=4/4
ASSERT_BASELINE=4/4
COMPILE_SUCCESS_MUTATIONS=${mutation_count}/${#mutation_rows[@]}
ASYNC_MEMORY_PRODUCER_AUTH=RED
MULDIV_PRODUCER_AUTH=RED
CLMUL_PRODUCER_AUTH=RED
FP_PRODUCER_AUTH=RED
BRANCH_PRODUCER_AUTH=RED
GLOBAL_NO_LIVE_REUSE=RED
EOF

find "$EVIDENCE_DIR" -type f ! -name complete.marker -print0 |
  sort -z | xargs -0 sha256sum > "$EVIDENCE_DIR/complete.marker"
printf '# [V8F-RUNNER][PASS] release=4/4 assert=4/4 compile_success_mutations=%d/%d scoped_green=1 parent_red=1\n' \
  "$mutation_count" "${#mutation_rows[@]}" >> "$EVIDENCE_DIR/complete.marker"
printf '[V8F-RUNNER][PASS] evidence=%s mutations=%d/%d\n' \
  "${EVIDENCE_DIR#$REPO_ROOT/}" "$mutation_count" "${#mutation_rows[@]}" |
  tee -a "$summary_log"
