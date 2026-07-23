#!/usr/bin/env bash
set -euo pipefail

RUN_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPO_ROOT=$(git -C "$RUN_DIR" rev-parse --show-toplevel)
NPC_HOME="$REPO_ROOT/npc/rv64"
TB_HOME="$NPC_HOME/testbench"
EVIDENCE_DIR="$RUN_DIR/evidence/focused"
MUTATOR="$RUN_DIR/mutate-v8l-global-lease.py"
CHECKER="$NPC_HOME/eval/ppa/tools/producer_holder_census.py"
MANIFEST="$NPC_HOME/design/arch/producer-holder-census.json"
TEMP_DIR=$(mktemp -d "${TMPDIR:-/tmp}/v8l-global-lease.XXXXXX")

cleanup() {
  if [[ -d "$TEMP_DIR" && "$TEMP_DIR" == "${TMPDIR:-/tmp}"/v8l-global-lease.* ]]; then
    rm -rf -- "$TEMP_DIR"
  fi
}
trap cleanup EXIT

fail() {
  printf '[V8L-RUNNER][FAIL] %s\n' "$*" >&2
  exit 1
}

case "$EVIDENCE_DIR" in
  "$RUN_DIR"/evidence/focused) rm -rf -- "$EVIDENCE_DIR" ;;
  *) fail "unsafe evidence path: $EVIDENCE_DIR" ;;
esac
mkdir -p "$EVIDENCE_DIR/static"

IQ="$NPC_HOME/vsrc/scheduling/OooIntIssueQueue.v"
DISPATCH="$NPC_HOME/vsrc/rename_allocate/OooDispatchBackend.v"
BACKEND="$NPC_HOME/vsrc/execute/OooIntBackend.v"
TRACKER="$NPC_HOME/vsrc/memory/OooMemOwnerTracker.v"
SQ="$NPC_HOME/vsrc/memory/OooStoreQueue.v"

source_paths=(
  "$RUN_DIR/contract.md"
  "$RUN_DIR/rtl-derivation.md"
  "$RUN_DIR/run-focused.sh"
  "$MUTATOR"
  "$RUN_DIR/build-current-census-evidence.py"
  "$CHECKER"
  "$MANIFEST"
  "$NPC_HOME/design/specs/ooo-global-producer-no-live-reuse.md"
  "$NPC_HOME/vsrc/include/define.v"
  "$NPC_HOME/vsrc/filelist.mk"
  "$TB_HOME/Makefile"
  "$IQ"
  "$DISPATCH"
  "$BACKEND"
  "$TRACKER"
  "$SQ"
  "$TB_HOME/tests/tb_ooo_int_issue_queue.sv"
  "$TB_HOME/tests/tb_ooo_dispatch_backend.sv"
  "$TB_HOME/tests/tb_ooo_int_backend.sv"
  "$TB_HOME/tests/tb_ooo_mem_owner_tracker.sv"
  "$TB_HOME/tests/tb_ooo_store_queue.sv"
)
sha256sum "${source_paths[@]}" > "$EVIDENCE_DIR/sources.pre.sha256"

python3 -m unittest \
  "$NPC_HOME/eval/ppa/tests/test_producer_holder_census.py" -v \
  > "$EVIDENCE_DIR/static/checker-unit.log" 2>&1
python3 "$CHECKER" --manifest "$MANIFEST" \
  --json-out "$EVIDENCE_DIR/static/producer-holder-census-result.json" \
  > "$EVIDENCE_DIR/static/producer-holder-census.log" 2>&1

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

  case "$result_dir" in
    "$EVIDENCE_DIR"/*) ;;
    *) fail "unsafe result path: $result_dir" ;;
  esac
  case "$kind" in
    current) ;;
    iq) overrides+=("RTL_OOO_INT_ISSUE_QUEUE=$NPC_HOME/vsrc/scheduling/OooIntIssueSelect8.v $source") ;;
    dispatch) overrides+=("RTL_OOO_DISPATCH_BACKEND=$source") ;;
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

require_marker() {
  local marker=$1
  local log=$2
  grep -Fq "$marker" "$log" ||
    fail "missing marker in ${log#$REPO_ROOT/}: $marker"
}

require_clean_pass() {
  local log=$1
  require_marker '[RESULT] PASS' "$log"
  if grep -Eq '\[CHECK-FAIL\]|\[RESULT\] FAIL|(^|[[:space:]])ERROR:|(^|[[:space:]])FATAL:' "$log"; then
    fail "unexpected failure marker in ${log#$REPO_ROOT/}"
  fi
}

run_common_baseline() {
  local profile=$1
  local flags=$base_flags
  if [[ "$profile" == assert ]]; then
    flags="$flags -DOOO_ASSERT"
  fi
  run_make "baseline-$profile-common" \
    'tb_ooo_int_issue_queue tb_ooo_mem_owner_tracker tb_ooo_store_queue' \
    "$flags" || fail "common baseline failed: $profile"
  local dir="$EVIDENCE_DIR/baseline-$profile-common/logs"
  require_marker '[V8F-INTIQ-PRODUCER-CARRIER] dual/hold/compact/replace/kill PASS' \
    "$dir/tb_ooo_int_issue_queue.log"
  require_marker '[V8L-TRACKER-BACKPRESSURE] full token set blocks a distinct legal ProducerId PASS' \
    "$dir/tb_ooo_mem_owner_tracker.log"
  require_clean_pass "$dir/tb_ooo_int_issue_queue.log"
  require_clean_pass "$dir/tb_ooo_mem_owner_tracker.log"
  require_clean_pass "$dir/tb_ooo_store_queue.log"
  printf '[V8L-BASELINE][PASS] profile=%s common=3/3\n' "$profile" \
    >> "$EVIDENCE_DIR/baseline-summary.log"
}

run_dispatch_baseline() {
  local profile=$1
  local flags="$base_flags -DOOO_PRODUCER_GEN_W=1 -DV8L_GLOBAL_LEASE_FOCUSED"
  if [[ "$profile" == assert ]]; then
    flags="$flags -DOOO_ASSERT"
  fi
  run_make "baseline-$profile-dispatch-focus" tb_ooo_dispatch_backend \
    "$flags" || fail "dispatch focused baseline failed: $profile"
  local log="$EVIDENCE_DIR/baseline-$profile-dispatch-focus/logs/tb_ooo_dispatch_backend.log"
  require_marker '[V8L-INTIQ-DEATH-EDGE] raw-Q holder blocks edge-old reuse and releases next cycle PASS' "$log"
  require_marker '[V8L-FINITE-GENERATION-WRAP] allocate/WB/commit wrap and death-edge lease PASS transactions=32' "$log"
  require_clean_pass "$log"
  printf '[V8L-BASELINE][PASS] profile=%s dispatch-focus=1/1 GEN_W=1\n' "$profile" \
    >> "$EVIDENCE_DIR/baseline-summary.log"
}

run_backend_baseline() {
  local profile=$1
  local macro=$2
  local suffix=$3
  local flags="$base_flags -D$macro"
  if [[ "$profile" == assert ]]; then
    flags="$flags -DOOO_ASSERT"
  fi
  run_make "baseline-$profile-$suffix" tb_ooo_int_backend "$flags" ||
    fail "backend baseline failed: $profile/$suffix"
  local log="$EVIDENCE_DIR/baseline-$profile-$suffix/logs/tb_ooo_int_backend.log"
  if [[ "$macro" == V8L_GLOBAL_LEASE_FOCUSED ]]; then
    require_marker '[V8L-TRACKER-BACKPRESSURE] old-IQ hold/no-capture then atomic reservation+token handoff PASS' "$log"
    require_marker '[V8L-TRANSIENT-HOLDER-CENSUS] mem-res/EX0/EX1/branch plus real IQ->EX0 handoff PASS' "$log"
  else
    require_marker '[V8G-MEM-INGRESS-LEASE] stale full-ID IQ entry drops without token/reservation/request/completion PASS' "$log"
    require_marker '[V8G-MEM-TRACKER-QUARANTINE] kind/epoch mismatch drains transport with zero ROB/WB/death/final trust PASS' "$log"
    require_marker '[T4S-EFFKILL-RSP] LOAD+PROBE exact-pop/terminal once, WB/SQ side effects zero PASS' "$log"
    require_marker '[V8G-AMO-POST-LAUNCH] write_sent keeps exact-open unfinished ROB/PID lease until final response PASS' "$log"
  fi
  require_clean_pass "$log"
  printf '[V8L-BASELINE][PASS] profile=%s %s=1/1\n' "$profile" "$suffix" \
    >> "$EVIDENCE_DIR/baseline-summary.log"
}

for profile in assert release; do
  run_common_baseline "$profile"
  run_dispatch_baseline "$profile"
  run_backend_baseline "$profile" V8L_GLOBAL_LEASE_FOCUSED backend-focus
  run_backend_baseline "$profile" V8G_MEMORY_PRODUCER_LEASE_FOCUSED legacy-v8g
done

mutation_rows=(
  'dispatch_drop_int_iq_union|dispatch|OooDispatchBackend.v|tb_ooo_dispatch_backend|dispatch|FAIL v8l complete mask differs from independent raw IQ scan'
  'dispatch_lane0_raw_index|dispatch|OooDispatchBackend.v|tb_ooo_dispatch_backend|dispatch|[CHECK-FAIL] v8g lane0 live PID stalls dispatch0'
  'int_iq_fire_dies_early|iq|OooIntIssueQueue.v|tb_ooo_dispatch_backend|dispatch|[CHECK-FAIL] v8l resident IQ P blocks exact candidate'
  'backend_drop_mem_res_holder|backend|OooIntBackend.v|tb_ooo_int_backend|backend|[CHECK-FAIL] v8l memory reservation reaches complete mask'
  'backend_drop_ex0_holder|backend|OooIntBackend.v|tb_ooo_int_backend|backend|[CHECK-FAIL] v8l EX0 handoff keeps complete lease'
  'backend_drop_ex1_holder|backend|OooIntBackend.v|tb_ooo_int_backend|backend|[CHECK-FAIL] v8l EX1 reaches complete mask'
  'backend_drop_branch_holder|backend|OooIntBackend.v|tb_ooo_int_backend|backend|[CHECK-FAIL] v8l branch packet reaches complete mask'
  'backend_capture_ignores_tracker_ready|backend|OooIntBackend.v|tb_ooo_int_backend|backend|[CHECK-FAIL] v8l tracker-backpressure blocks capture'
  'backend_iq_pop_ignores_tracker_ready|backend|OooIntBackend.v|tb_ooo_int_backend|backend|[CHECK-FAIL] v8l tracker-backpressure blocks IQ pop'
)

source_for_kind() {
  case "$1" in
    iq) printf '%s\n' "$IQ" ;;
    dispatch) printf '%s\n' "$DISPATCH" ;;
    backend) printf '%s\n' "$BACKEND" ;;
    *) return 1 ;;
  esac
}

: > "$EVIDENCE_DIR/mutation-summary.log"
for row in "${mutation_rows[@]}"; do
  IFS='|' read -r name kind basename test profile marker <<< "$row"
  source=$(source_for_kind "$kind")
  mutant="$TEMP_DIR/mutants/$name/$basename"
  python3 "$MUTATOR" "$name" "$source" "$mutant" \
    > "$EVIDENCE_DIR/mutation-$name.mutator.log" 2>&1

  flags="$base_flags -DV8L_GLOBAL_LEASE_FOCUSED"
  if [[ "$profile" == dispatch ]]; then
    flags="$flags -DOOO_PRODUCER_GEN_W=1"
  fi
  if run_make "mutation-$name" "$test" "$flags" "$kind" "$mutant"; then
    fail "mutation survived focused test: $name"
  fi
  vvp="$TEMP_DIR/build-mutation-$name/$test.vvp"
  [[ -s "$vvp" ]] || fail "mutation did not compile successfully: $name"
  log="$EVIDENCE_DIR/mutation-$name/logs/$test.log"
  require_marker "$marker" "$log"
  printf '[V8L-MUTATION][PASS] name=%s compile=PASS consequence=%s\n' \
    "$name" "$marker" >> "$EVIDENCE_DIR/mutation-summary.log"
done

python3 "$CHECKER" --manifest "$MANIFEST" \
  --json-out "$EVIDENCE_DIR/static/producer-holder-census-result.post.json" \
  > "$EVIDENCE_DIR/static/producer-holder-census.post.log" 2>&1
sha256sum "${source_paths[@]}" > "$EVIDENCE_DIR/sources.post.sha256"
cmp "$EVIDENCE_DIR/sources.pre.sha256" "$EVIDENCE_DIR/sources.post.sha256" ||
  fail "canonical sources changed while running mutations"

python3 "$RUN_DIR/build-current-census-evidence.py"

printf '[V8L-RUNNER][PASS] baselines=8/8 mutations=%d/%d static=PASS canonical-hash=stable\n' \
  "${#mutation_rows[@]}" "${#mutation_rows[@]}" | tee "$EVIDENCE_DIR/runner-summary.log"
