#!/usr/bin/env bash
set -euo pipefail

RUN_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPO_ROOT=$(git -C "$RUN_DIR" rev-parse --show-toplevel)
NPC_HOME="$REPO_ROOT/npc/rv64"
TB_HOME="$NPC_HOME/testbench"
EVIDENCE_DIR="$RUN_DIR/evidence/focused"
AUDIT="$RUN_DIR/audit-v8g-memory-lease.py"
MUTATOR="$RUN_DIR/mutate-v8g-memory-lease.py"
TRACKER="$NPC_HOME/vsrc/memory/OooMemOwnerTracker.v"
ROB="$NPC_HOME/vsrc/writeback/OooRob.v"
DISPATCH="$NPC_HOME/vsrc/rename_allocate/OooDispatchBackend.v"
SQ="$NPC_HOME/vsrc/memory/OooStoreQueue.v"
BACKEND="$NPC_HOME/vsrc/execute/OooIntBackend.v"
BRIDGE="$NPC_HOME/vsrc/memory/OooMemAxiBridge.v"
TEMP_DIR=$(mktemp -d "${TMPDIR:-/tmp}/v8g-memory-lease.XXXXXX")

cleanup() {
  if [[ -d "$TEMP_DIR" && "$TEMP_DIR" == "${TMPDIR:-/tmp}"/v8g-memory-lease.* ]]; then
    rm -rf -- "$TEMP_DIR"
  fi
}
trap cleanup EXIT

case "$EVIDENCE_DIR" in
  "$RUN_DIR"/evidence/focused) rm -rf -- "$EVIDENCE_DIR" ;;
  *) printf '[V8G-RUNNER][FAIL] unsafe evidence path: %s\n' "$EVIDENCE_DIR" >&2; exit 2 ;;
esac
mkdir -p "$EVIDENCE_DIR"

fail() {
  printf '[V8G-RUNNER][FAIL] %s\n' "$*" >&2
  exit 1
}

source_paths=(
  "$RUN_DIR/contract.md"
  "$RUN_DIR/contract-amendment-v8g1.md"
  "$RUN_DIR/contract-amendment-v8g2.md"
  "$RUN_DIR/contract-amendment-v8g3.md"
  "$RUN_DIR/subagent-contracts/v8g-memory-lease-contract-review.json"
  "$RUN_DIR/run-focused.sh"
  "$AUDIT"
  "$MUTATOR"
  "$NPC_HOME/vsrc/include/define.v"
  "$NPC_HOME/vsrc/filelist.mk"
  "$TB_HOME/Makefile"
  "$TRACKER"
  "$ROB"
  "$DISPATCH"
  "$SQ"
  "$BACKEND"
  "$BRIDGE"
  "$TB_HOME/tests/tb_ooo_mem_owner_tracker.sv"
  "$TB_HOME/tests/tb_ooo_rob.sv"
  "$TB_HOME/tests/tb_ooo_dispatch_backend.sv"
  "$TB_HOME/tests/tb_ooo_store_queue.sv"
  "$TB_HOME/tests/tb_ooo_int_backend.sv"
  "$TB_HOME/tests/tb_ooo_mem_axi_bridge.sv"
)
sha256sum "${source_paths[@]}" > "$EVIDENCE_DIR/sources.pre.sha256"

base_flags='-g2012 -Wall -I../vsrc -I../vsrc/include -Icommon'
focused_define='-DV8G_MEMORY_PRODUCER_LEASE_FOCUSED'

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
    tracker) overrides+=("RTL_OOO_MEM_OWNER_TRACKER=$source") ;;
    rob) overrides+=("RTL_OOO_ROB=$source") ;;
    dispatch) overrides+=("RTL_OOO_DISPATCH_BACKEND=$source") ;;
    sq) overrides+=("RTL_OOO_STORE_QUEUE=$source") ;;
    backend) overrides+=("RTL_OOO_INT_BACKEND=$source") ;;
    bridge) overrides+=("RTL_OOO_MEM_AXI_BRIDGE=$source") ;;
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
  [[ "$count" -eq 1 ]] ||
    fail "expected exactly one marker in ${log#$REPO_ROOT/}: $marker"
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
    'tb_ooo_mem_owner_tracker tb_ooo_rob tb_ooo_dispatch_backend tb_ooo_store_queue tb_ooo_int_backend tb_ooo_mem_axi_bridge' \
    "$flags" || fail "baseline $label failed"

  local result_dir="$EVIDENCE_DIR/baseline-$label"
  local tracker_log="$result_dir/logs/tb_ooo_mem_owner_tracker.log"
  local rob_log="$result_dir/logs/tb_ooo_rob.log"
  local dispatch_log="$result_dir/logs/tb_ooo_dispatch_backend.log"
  local sq_log="$result_dir/logs/tb_ooo_store_queue.log"
  local backend_log="$result_dir/logs/tb_ooo_int_backend.log"
  local bridge_log="$result_dir/logs/tb_ooo_mem_axi_bridge.log"
  require_exact_marker '[V8G-TRACKER-LEASE][PASS] Q-only PID mask/table, unique birth, edge-old death, next-cycle reuse' "$tracker_log"
  require_exact_marker '[V8G-ROB-MEMORY-QUERY] query2 generation/done and pair/head Q-only contract PASS' "$rob_log"
  require_exact_marker '[V8G-DISPATCH-MEMORY-LEASE] lane0/mandatory/optional collision gates PASS' "$dispatch_log"
  require_exact_marker '[V8G-SQ-FULL-PID] bind/request/release full generation contract PASS' "$sq_log"
  require_exact_marker '[V8G-SQ-POST-LAUNCH] request_sent retains live nonterminal full-PID owner until exact B PASS' "$sq_log"
  require_exact_marker '[V8G-MEM-CREDIT-BOUND] stable exact-open response completes on the cycle after both WB ports were occupied PASS' "$backend_log"
  require_exact_marker '[V8G-MEM-BUFFER-KILL-READY-CUT] open slot and ready cannot launch a younger-killed buffer PASS' "$backend_log"
  require_exact_marker '[V8G-BRG-DROP-READY-CUT] S_RESP kill terminal is independent of response credit and station advance PASS' "$bridge_log"
  for log in "$tracker_log" "$rob_log" "$dispatch_log" "$sq_log" "$backend_log" "$bridge_log"; do
    require_exact_marker '[RESULT] PASS' "$log"
    reject_unexpected_failure "$log"
  done

  run_make "baseline-$label-backend-focused" tb_ooo_int_backend \
    "$flags $focused_define" || fail "focused backend baseline $label failed"
  local focused_log="$EVIDENCE_DIR/baseline-$label-backend-focused/logs/tb_ooo_int_backend.log"
  require_exact_marker '[V8G-MEM-INGRESS-LEASE] stale full-ID IQ entry drops without token/reservation/request/completion PASS' "$focused_log"
  require_exact_marker '[V8G-MEM-TRACKER-QUARANTINE] kind/epoch mismatch drains transport with zero ROB/WB/death/final trust PASS' "$focused_log"
  require_exact_marker '[V8G-MEM-CONTINUOUS-WB-COMPETITION] resident issue0/lane1 pair leaves WB1 for exact response at N+1 PASS' "$focused_log"
  require_exact_marker '[T4S-EFFKILL-RSP] LOAD+PROBE exact-pop/terminal once, WB/SQ side effects zero PASS' "$focused_log"
  require_exact_marker '[V8G-AMO-POST-LAUNCH] write_sent keeps exact-open unfinished ROB/PID lease until final response PASS' "$focused_log"
  require_exact_marker '[RESULT] PASS' "$focused_log"
  reject_unexpected_failure "$focused_log"
  printf '[V8G-BASELINE][PASS] %s standard=6/6 backend-focused=1/1\n' "$label"
}

mutation_rows=(
  'tracker_alloc0_ignore_live_pid|tracker|standard|tb_ooo_mem_owner_tracker|[V8G-TRACKER-LEASE][FAIL] live lane0 PID either reallocated or blocked independent lane1'
  'tracker_dual_duplicate_pid|tracker|standard|tb_ooo_mem_owner_tracker|[V8G-TRACKER-LEASE][FAIL] duplicate dual ProducerId did not select exactly one birth'
  'rob_query2_ignore_generation|rob|standard|tb_ooo_rob|[CHECK-FAIL] v8g memory wrong generation completion is closed'
  'rob_query2_ignore_done|rob|standard|tb_ooo_rob|[CHECK-FAIL] v8g memory done slot completion closes'
  'rob_head_launch_ignore_done|rob|standard|tb_ooo_rob|[CHECK-FAIL] v8g done head is not launch-open'
  'dispatch_lane0_ignore_memory_lease|dispatch|standard|tb_ooo_dispatch_backend|[CHECK-FAIL] v8g lane0 live PID stalls dispatch0'
  'dispatch_pair_ignore_memory_lease|dispatch|standard|tb_ooo_dispatch_backend|[CHECK-FAIL] v8g mandatory lane1 collision stalls lane0'
  'dispatch_lane1_ignore_memory_lease|dispatch|standard|tb_ooo_dispatch_backend|[CHECK-FAIL] v8g optional lane1 collision drops lane1'
  'sq_request_ignore_full_pid|sq|standard|tb_ooo_store_queue|[CHECK-FAIL] same ROB slot wrong generation blocks request'
  'sq_release_ignore_full_pid|sq|standard|tb_ooo_store_queue|[CHECK-FAIL] same ROB slot wrong generation blocks release'
  'sq_release_after_request_sent|sq|standard|tb_ooo_store_queue|[CHECK-FAIL] pre-B release blocked'
  'sq_request_marks_terminal|sq|standard|tb_ooo_store_queue|[CHECK-FAIL] request-sent is not terminal'
  'backend_ingress_ignore_current|backend|focused|tb_ooo_int_backend|[CHECK-FAIL] v8g stale ingress cannot capture reservation'
  'backend_tracker_ignore_kind|backend|focused|tb_ooo_int_backend|[CHECK-FAIL] v8g kind mismatch rejects tracker tag'
  'backend_tracker_ignore_epoch|backend|focused|tb_ooo_int_backend|[CHECK-FAIL] v8g epoch mismatch rejects tracker tag'
  'backend_query_ignore_tracker_exact|backend|focused|tb_ooo_int_backend|[CHECK-FAIL] v8g kind mismatch blocks ROB completion query'
  'backend_amo_read_ignore_owner_open|backend|focused|tb_ooo_int_backend|[CHECK-FAIL] S2-G1 AMO read+restore cannot enter write phase'
  'backend_fatal_enters_normal_final|backend|focused|tb_ooo_int_backend|[CHECK-FAIL] v8g AMO closed-final cannot normal-final'
  'backend_load_wb_ignore_owner_open|backend|focused|tb_ooo_int_backend|[CHECK-FAIL] v8g kind mismatch has no WB'
  'backend_issue1_ignore_response_wait|backend|focused|tb_ooo_int_backend|[CHECK-FAIL] v8g continuous WB lane1 is suppressed while response waits'
  'backend_memory_loses_wb1|backend|focused|tb_ooo_int_backend|[CHECK-FAIL] v8g continuous WB response owns freed WB1'
  'backend_amo_write_launch_completes_early|backend|focused|tb_ooo_int_backend|[V8G-MEM-COMPLETION-AUTH]'
  'backend_store_request_terminals_early|backend|default|tb_ooo_int_backend|[S2-G1-TCOLL-TUPLE-MISMATCH]'
  'backend_buffer_kill_handoff_ready_loop|backend|standard|tb_ooo_int_backend|[CHECK-FAIL] T3V buffer-kill open-slot cannot fire'
  'bridge_station_query_reads_advance|bridge|standard|tb_ooo_mem_axi_bridge|[CHECK-FAIL] S2-G1 replace stalled station still queries tracker'
)

source_for_kind() {
  case "$1" in
    tracker) printf '%s\n' "$TRACKER" ;;
    rob) printf '%s\n' "$ROB" ;;
    dispatch) printf '%s\n' "$DISPATCH" ;;
    sq) printf '%s\n' "$SQ" ;;
    backend) printf '%s\n' "$BACKEND" ;;
    bridge) printf '%s\n' "$BRIDGE" ;;
    *) return 1 ;;
  esac
}

basename_for_kind() {
  case "$1" in
    tracker) printf 'OooMemOwnerTracker.v\n' ;;
    rob) printf 'OooRob.v\n' ;;
    dispatch) printf 'OooDispatchBackend.v\n' ;;
    sq) printf 'OooStoreQueue.v\n' ;;
    backend) printf 'OooIntBackend.v\n' ;;
    bridge) printf 'OooMemAxiBridge.v\n' ;;
    *) return 1 ;;
  esac
}

run_bridge_structural_mutation() {
  local name=bridge_drop_reads_stage_advance
  local mutant="$TEMP_DIR/mutants/$name/OooMemAxiBridge.v"
  local mutator_log="$EVIDENCE_DIR/mutation-$name.mutator.log"
  local result_dir="$EVIDENCE_DIR/mutation-$name"
  local sim_log="$result_dir/logs/tb_ooo_mem_axi_bridge.log"
  local audit_log="$EVIDENCE_DIR/mutation-$name.audit.log"

  python3 "$MUTATOR" "$name" "$BRIDGE" "$mutant" > "$mutator_log"
  run_make "mutation-$name" tb_ooo_mem_axi_bridge \
    "$base_flags -DOOO_ASSERT" bridge "$mutant" ||
    fail "structural mutation changed bridge simulation behavior: $name"
  [[ -s "$TEMP_DIR/build-mutation-$name/tb_ooo_mem_axi_bridge.vvp" ]] ||
    fail "structural mutation did not compile successfully: $name"
  require_exact_marker '[V8G-BRG-DROP-READY-CUT] S_RESP kill terminal is independent of response credit and station advance PASS' "$sim_log"
  require_exact_marker '[RESULT] PASS' "$sim_log"
  reject_unexpected_failure "$sim_log"

  if python3 "$AUDIT" --bridge "$mutant" > "$audit_log" 2>&1; then
    fail "compile-success structural mutation survived audit: $name"
  fi
  grep -Fq '[V8G-MEMORY-LEASE-AUDIT][FAIL] bridge raw drop terminal reads ready/advance: stage_advance_w' \
    "$audit_log" || fail "structural mutation missed forbidden-edge consequence: $name"
  printf '[V8G-MUTATION][PASS] %s kind=bridge profile=structural test=tb_ooo_mem_axi_bridge target=forbidden-ready/advance-edge\n' \
    "$name" >> "$EVIDENCE_DIR/mutation-summary.log"
}

run_bridge_station_drop_structural_mutation() {
  local name=bridge_station_drop_reads_advance
  local mutant="$TEMP_DIR/mutants/$name/OooMemAxiBridge.v"
  local mutator_log="$EVIDENCE_DIR/mutation-$name.mutator.log"
  local result_dir="$EVIDENCE_DIR/mutation-$name"
  local sim_log="$result_dir/logs/tb_ooo_mem_axi_bridge.log"
  local audit_log="$EVIDENCE_DIR/mutation-$name.audit.log"

  python3 "$MUTATOR" "$name" "$BRIDGE" "$mutant" > "$mutator_log"
  run_make "mutation-$name" tb_ooo_mem_axi_bridge \
    "$base_flags -DOOO_ASSERT" bridge "$mutant" ||
    fail "structural mutation changed bridge simulation behavior: $name"
  [[ -s "$TEMP_DIR/build-mutation-$name/tb_ooo_mem_axi_bridge.vvp" ]] ||
    fail "structural mutation did not compile successfully: $name"
  require_exact_marker '[RESULT] PASS' "$sim_log"
  reject_unexpected_failure "$sim_log"

  if python3 "$AUDIT" --bridge "$mutant" > "$audit_log" 2>&1; then
    fail "compile-success structural mutation survived audit: $name"
  fi
  grep -Fq '[V8G-MEMORY-LEASE-AUDIT][FAIL] bridge station drop reads ready/advance: stage_advance_w' \
    "$audit_log" || fail "structural mutation missed station-drop consequence: $name"
  printf '[V8G-MUTATION][PASS] %s kind=bridge profile=structural test=tb_ooo_mem_axi_bridge target=forbidden-station-drop-ready-edge\n' \
    "$name" >> "$EVIDENCE_DIR/mutation-summary.log"
}

run_backend_structural_mutation() {
  local name=backend_local_terminal_reads_consume
  local mutant="$TEMP_DIR/mutants/$name/OooIntBackend.v"
  local mutator_log="$EVIDENCE_DIR/mutation-$name.mutator.log"
  local result_dir="$EVIDENCE_DIR/mutation-$name"
  local sim_log="$result_dir/logs/tb_ooo_int_backend.log"
  local audit_log="$EVIDENCE_DIR/mutation-$name.audit.log"

  python3 "$MUTATOR" "$name" "$BACKEND" "$mutant" > "$mutator_log"
  run_make "mutation-$name" tb_ooo_int_backend \
    "$base_flags -DOOO_ASSERT $focused_define" backend "$mutant" ||
    fail "structural mutation changed backend simulation behavior: $name"
  [[ -s "$TEMP_DIR/build-mutation-$name/tb_ooo_int_backend.vvp" ]] ||
    fail "structural mutation did not compile successfully: $name"
  require_exact_marker '[V8G-MEM-CONTINUOUS-WB-COMPETITION] resident issue0/lane1 pair leaves WB1 for exact response at N+1 PASS' "$sim_log"
  require_exact_marker '[RESULT] PASS' "$sim_log"
  reject_unexpected_failure "$sim_log"

  if python3 "$AUDIT" --backend "$mutant" > "$audit_log" 2>&1; then
    fail "compile-success structural mutation survived audit: $name"
  fi
  grep -Fq '[V8G-MEMORY-LEASE-AUDIT][FAIL] local terminal re-entered request-ready cone: mem_issue_res_consume_fire_w' \
    "$audit_log" || fail "structural mutation missed local-ready consequence: $name"
  printf '[V8G-MUTATION][PASS] %s kind=backend profile=structural test=tb_ooo_int_backend target=forbidden-request-ready-edge\n' \
    "$name" >> "$EVIDENCE_DIR/mutation-summary.log"
}

run_backend_packed_mask_structural_mutation() {
  local name=backend_raw_mask_reads_packed_vector
  local mutant="$TEMP_DIR/mutants/$name/OooIntBackend.v"
  local mutator_log="$EVIDENCE_DIR/mutation-$name.mutator.log"
  local result_dir="$EVIDENCE_DIR/mutation-$name"
  local sim_log="$result_dir/logs/tb_ooo_int_backend.log"
  local audit_log="$EVIDENCE_DIR/mutation-$name.audit.log"

  python3 "$MUTATOR" "$name" "$BACKEND" "$mutant" > "$mutator_log"
  run_make "mutation-$name" tb_ooo_int_backend \
    "$base_flags -DOOO_ASSERT $focused_define" backend "$mutant" ||
    fail "structural mutation changed backend simulation behavior: $name"
  [[ -s "$TEMP_DIR/build-mutation-$name/tb_ooo_int_backend.vvp" ]] ||
    fail "structural mutation did not compile successfully: $name"
  require_exact_marker '[RESULT] PASS' "$sim_log"
  reject_unexpected_failure "$sim_log"

  if python3 "$AUDIT" --backend "$mutant" > "$audit_log" 2>&1; then
    fail "compile-success structural mutation survived audit: $name"
  fi
  grep -Fq '[V8G-MEMORY-LEASE-AUDIT][FAIL] terminal mask lane1 reads packed vector: mem_terminal_ingress_valid_w' \
    "$audit_log" || fail "structural mutation missed packed-mask consequence: $name"
  printf '[V8G-MUTATION][PASS] %s kind=backend profile=structural test=tb_ooo_int_backend target=forbidden-packed-terminal-mask\n' \
    "$name" >> "$EVIDENCE_DIR/mutation-summary.log"
}

run_mutation() {
  local row=$1
  IFS='|' read -r name kind profile test target <<< "$row"
  local source
  source=$(source_for_kind "$kind")
  local basename
  basename=$(basename_for_kind "$kind")
  local mutant="$TEMP_DIR/mutants/$name/$basename"
  local mutator_log="$EVIDENCE_DIR/mutation-$name.mutator.log"
  local result_dir="$EVIDENCE_DIR/mutation-$name"
  local sim_log="$result_dir/logs/$test.log"
  local flags="$base_flags -DOOO_ASSERT"
  if [[ "$profile" == focused ]]; then
    flags="$flags $focused_define"
  elif [[ "$profile" != standard && "$profile" != default ]]; then
    fail "unknown mutation profile: $profile"
  fi

  python3 "$MUTATOR" "$name" "$source" "$mutant" > "$mutator_log"
  if run_make "mutation-$name" "$test" "$flags" "$kind" "$mutant"; then
    fail "compile-success mutation survived: $name"
  fi
  [[ -s "$TEMP_DIR/build-mutation-$name/$test.vvp" ]] ||
    fail "mutation did not compile successfully: $name"
  [[ -f "$sim_log" ]] || fail "mutation has no simulation log: $name"
  grep -Fq '[COMPILE]' "$sim_log" || fail "mutation missed compile record: $name"
  grep -Fq '[RESULT] FAIL' "$sim_log" || fail "mutation did not finish RED: $name"
  grep -Fq "$target" "$sim_log" ||
    fail "mutation missed target consequence: $name -> $target"
  printf '[V8G-MUTATION][PASS] %s kind=%s profile=%s test=%s target=%s\n' \
    "$name" "$kind" "$profile" "$test" "$target" >> "$EVIDENCE_DIR/mutation-summary.log"
}

summary_log="$EVIDENCE_DIR/runner-summary.log"
: > "$summary_log"
python3 "$AUDIT" | tee "$EVIDENCE_DIR/structural-audit.log" | tee -a "$summary_log"
run_baseline release | tee -a "$summary_log"
run_baseline assert | tee -a "$summary_log"
: > "$EVIDENCE_DIR/mutation-summary.log"
for row in "${mutation_rows[@]}"; do
  run_mutation "$row"
done
run_bridge_structural_mutation
run_bridge_station_drop_structural_mutation
run_backend_structural_mutation
run_backend_packed_mask_structural_mutation

mutation_count=$(grep -c '^\[V8G-MUTATION\]\[PASS\]' "$EVIDENCE_DIR/mutation-summary.log" || true)
expected_mutation_count=$((${#mutation_rows[@]} + 4))
[[ "$mutation_count" -eq "$expected_mutation_count" ]] ||
  fail "mutation inventory incomplete: $mutation_count/$expected_mutation_count"
cat "$EVIDENCE_DIR/mutation-summary.log" >> "$summary_log"

sha256sum "${source_paths[@]}" > "$EVIDENCE_DIR/sources.post.sha256"
cmp -s "$EVIDENCE_DIR/sources.pre.sha256" "$EVIDENCE_DIR/sources.post.sha256" ||
  fail 'workspace source drifted during runner'

cat > "$EVIDENCE_DIR/summary.txt" <<EOF
V8G_ASYNC_MEMORY_PRODUCER_LEASE=SCOPED_GREEN
RELEASE_STANDARD_BASELINE=6/6
RELEASE_BACKEND_FOCUSED=1/1
ASSERT_STANDARD_BASELINE=6/6
ASSERT_BACKEND_FOCUSED=1/1
STRUCTURAL_AUDIT=PASS
COMPILE_SUCCESS_MUTATIONS=${mutation_count}/${expected_mutation_count}
POST_LAUNCH_STORE_AMO=PASS
CONTINUOUS_WB_COMPETITION=PASS
GLOBAL_NO_LIVE_REUSE=RED
MULDIV_PRODUCER_AUTH=RED
CLMUL_PRODUCER_AUTH=RED
FP_PRODUCER_AUTH=RED
BRANCH_PRODUCER_AUTH=RED
PPA_PROMOTION=NOT_AUTHORIZED
EOF

find "$EVIDENCE_DIR" -type f ! -name complete.marker -print0 |
  sort -z | xargs -0 sha256sum > "$EVIDENCE_DIR/complete.marker"
printf '# [V8G-RUNNER][PASS] release=7/7 assert=7/7 structural=1 mutations=%d/%d scoped_green=1 parent_red=1\n' \
  "$mutation_count" "$expected_mutation_count" >> "$EVIDENCE_DIR/complete.marker"
printf '[V8G-RUNNER][PASS] evidence=%s mutations=%d/%d\n' \
  "${EVIDENCE_DIR#$REPO_ROOT/}" "$mutation_count" "$expected_mutation_count" |
  tee -a "$summary_log"
