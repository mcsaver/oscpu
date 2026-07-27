#!/usr/bin/env bash
set -euo pipefail

RUN_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPO_ROOT=$(git -C "$RUN_DIR" rev-parse --show-toplevel)
NPC_HOME="$REPO_ROOT/npc/rv64"
TB_HOME="$NPC_HOME/testbench"
EVIDENCE_DIR="$RUN_DIR/evidence/focused"
MUTATOR="$RUN_DIR/mutate-v8p-pair-matrix.py"
BUILDER="$NPC_HOME/eval/ppa/tools/pair_matrix_evidence.py"
ARCH_TOOL="$NPC_HOME/eval/ppa/tools/architecture_hard_gates.py"
ARCH_MANIFEST="$NPC_HOME/eval/ppa/evidence/architecture-current.json"
ARCH_LOG="$NPC_HOME/eval/ppa/evidence/pair-matrix.log"
BACKEND="$NPC_HOME/vsrc/execute/OooIntBackend.v"
SELECTOR="$NPC_HOME/vsrc/scheduling/OooIntIssueSelect8.v"
QUEUE="$NPC_HOME/vsrc/scheduling/OooIntIssueQueue.v"
TRACKER="$NPC_HOME/vsrc/memory/OooMemOwnerTracker.v"
COLLECTOR="$NPC_HOME/vsrc/memory/OooMemOwnerTerminalCollector.v"
STORE_QUEUE="$NPC_HOME/vsrc/memory/OooStoreQueue.v"
TEMP_DIR=$(mktemp -d "${TMPDIR:-/tmp}/v8p-pair-matrix.XXXXXX")

cleanup() {
  if [[ -d "$TEMP_DIR" && "$TEMP_DIR" == "${TMPDIR:-/tmp}"/v8p-pair-matrix.* ]]; then
    rm -rf -- "$TEMP_DIR"
  fi
}
trap cleanup EXIT

fail() {
  printf '[V8P-RUNNER][FAIL] %s\n' "$*" >&2
  exit 1
}

case "$EVIDENCE_DIR" in
  "$RUN_DIR"/evidence/focused) rm -rf -- "$EVIDENCE_DIR" ;;
  *) fail "unsafe evidence path: $EVIDENCE_DIR" ;;
esac
mkdir -p "$EVIDENCE_DIR/static"

source_paths=(
  "$RUN_DIR/contract.md"
  "$RUN_DIR/rtl-derivation.md"
  "$RUN_DIR/run-focused.sh"
  "$MUTATOR"
  "$NPC_HOME/Makefile"
  "$NPC_HOME/design/arch/rv64-architecture-ppa-contract.md"
  "$NPC_HOME/design/specs/ooo-dual-memory-terminal-owners.md"
  "$NPC_HOME/eval/ppa/tests/test_architecture_hard_gates.py"
  "$NPC_HOME/eval/ppa/tests/test_directed_evidence_manifest.py"
  "$ARCH_TOOL"
  "$NPC_HOME/eval/ppa/tools/directed_evidence_manifest.py"
  "$BUILDER"
  "$TB_HOME/Makefile"
  "$TB_HOME/tests/tb_ooo_int_backend.sv"
  "$TB_HOME/tests/tb_ooo_mem_owner_tracker.sv"
  "$TB_HOME/tests/tb_ooo_mem_owner_terminal_collector.sv"
  "$TB_HOME/tests/tb_ooo_store_queue.sv"
  "$BACKEND"
  "$SELECTOR"
  "$QUEUE"
  "$TRACKER"
  "$COLLECTOR"
  "$STORE_QUEUE"
)
sha256sum "${source_paths[@]}" > "$EVIDENCE_DIR/sources.pre.sha256"

base_flags='-g2012 -Wall -I../vsrc -I../vsrc/include -Icommon'

run_make() {
  local label=$1
  local test=$2
  local flags=$3
  local kind=${4:-current}
  local source=${5:-}
  local result_dir="$EVIDENCE_DIR/$label"
  local build_dir="$TEMP_DIR/build-$label"
  local make_log="$EVIDENCE_DIR/$label.make.log"
  local issue_sources
  local -a overrides=()

  case "$result_dir" in
    "$EVIDENCE_DIR"/*) ;;
    *) fail "unsafe result path: $result_dir" ;;
  esac
  case "$kind" in
    current) ;;
    backend) overrides+=("RTL_OOO_INT_BACKEND=$source") ;;
    selector)
      issue_sources="$source $QUEUE"
      overrides+=("RTL_OOO_INT_ISSUE_QUEUE=$issue_sources")
      ;;
    queue)
      issue_sources="$SELECTOR $source"
      overrides+=("RTL_OOO_INT_ISSUE_QUEUE=$issue_sources")
      ;;
    tracker) overrides+=("RTL_OOO_MEM_OWNER_TRACKER=$source") ;;
    *) fail "unknown mutation source kind: $kind" ;;
  esac

  set +e
  make -C "$TB_HOME" \
    "TESTS=$test" \
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
  if grep -Eq '\[CHECK-FAIL\]|\[RESULT\] FAIL|(^|[[:space:]])FATAL:' "$log"; then
    fail "unexpected failure marker in ${log#$REPO_ROOT/}"
  fi
}

python3 -m unittest -q \
  "$NPC_HOME/eval/ppa/tests/test_architecture_hard_gates.py" \
  "$NPC_HOME/eval/ppa/tests/test_directed_evidence_manifest.py" \
  > "$EVIDENCE_DIR/static/checker-unit.log" 2>&1

baseline_tests='tb_ooo_int_backend tb_ooo_mem_owner_tracker tb_ooo_mem_owner_terminal_collector tb_ooo_store_queue'
: > "$EVIDENCE_DIR/baseline-summary.log"
for profile in release assert; do
  flags="$base_flags -DV8P_PAIR_MATRIX_FOCUSED"
  if [[ "$profile" == assert ]]; then
    flags="$flags -DOOO_ASSERT -DV8P_MODE_ASSERT"
  fi
  run_make "baseline-$profile" "$baseline_tests" "$flags" ||
    fail "focused baseline failed: $profile"
  backend_log="$EVIDENCE_DIR/baseline-$profile/logs/tb_ooo_int_backend.log"
  tracker_log="$EVIDENCE_DIR/baseline-$profile/logs/tb_ooo_mem_owner_tracker.log"
  collector_log="$EVIDENCE_DIR/baseline-$profile/logs/tb_ooo_mem_owner_terminal_collector.log"
  sq_log="$EVIDENCE_DIR/baseline-$profile/logs/tb_ooo_store_queue.log"
  require_marker '[V8P-PAIR-MATRIX] mask=7fff memory_pids=8 PASS' "$backend_log"
  require_marker "[V8P-PAIR-METRICS] mode=$profile pair_fires=15 memory_pair_fires=4" "$backend_log"
  [[ "$(grep -c '^PAIR_MATRIX [a-z_]*=1$' "$backend_log")" -eq 15 ]] ||
    fail "$profile did not emit exactly fifteen true pair keys"
  [[ "$(grep -c '^\[V8P-SPECIAL-MEMORY-EXCLUSION\].* PASS$' "$backend_log")" -eq 10 ]] ||
    fail "$profile did not emit ten special-memory exclusions"
  require_marker '[V8P-TRACKER-ATOMIC-SCARCITY] split ready causes zero owner births PASS' "$tracker_log"
  require_marker '[V8P-TCOLL-12INGRESS-CAPTURE] pending=12' "$collector_log"
  require_marker '[V8P-TCOLL-12INGRESS-DRAIN] seen=12' "$collector_log"
  require_marker '[V8P-SQ-DUAL-BIND] two exact STORE owners bound on one edge PASS' "$sq_log"
  require_clean_pass "$backend_log"
  require_clean_pass "$tracker_log"
  require_clean_pass "$collector_log"
  require_clean_pass "$sq_log"
  printf '[V8P-BASELINE][PASS] profile=%s pair_keys=15 memory_pairs=4 special_exclusions=10 tracker_atomic=1 collector_peak=12 sq_binds=2\n' \
    "$profile" >> "$EVIDENCE_DIR/baseline-summary.log"
done

mutation_rows=(
  'serialize_memory_pair|selector|OooIntIssueSelect8.v|tb_ooo_int_backend|V8P_MUTATE_SERIALIZE_MEMORY_PAIR|serialize_memory_pair|[CHECK-FAIL] V8P memory pair terminal1 select'
  'split_pair_ready|backend|OooIntBackend.v|tb_ooo_int_backend|V8P_MUTATE_SPLIT_PAIR_READY|split_pair_ready|[CHECK-FAIL] V8P memory pair canonical fire1'
  'bank1_tieoff|backend|OooIntBackend.v|tb_ooo_int_backend|V8P_MUTATE_BANK1_TIEOFF|bank1_tieoff|[CHECK-FAIL] V8P bank1 next-Q valid'
  'owner1_tieoff|backend|OooIntBackend.v|tb_ooo_int_backend|V8P_MUTATE_OWNER1_TIEOFF|owner1_tieoff|[CHECK-FAIL] V8P tracker atomic alloc1 fire'
  'alloc0_only_birth|tracker|OooMemOwnerTracker.v|tb_ooo_mem_owner_tracker|V8P_MUTATE_ALLOC0_ONLY_BIRTH|alloc0_only_birth|[CHECK-FAIL] V8P tracker atomic scarcity zero births'
  'token_alias|tracker|OooMemOwnerTracker.v|tb_ooo_int_backend|V8P_MUTATE_TOKEN_ALIAS|token_alias|[CHECK-FAIL] V8P dual tokens differ before capture'
  'bank1_raw_fallthrough|backend|OooIntBackend.v|tb_ooo_int_backend|V8P_MUTATE_BANK1_RAW_FALLTHROUGH|bank1_raw_fallthrough|[CHECK-FAIL] V8P AGU1 ignores raw source perturbation'
  'agu1_bank0_copy|backend|OooIntBackend.v|tb_ooo_int_backend|V8P_MUTATE_AGU1_BANK0_COPY|agu1_bank0_copy|[CHECK-FAIL] V8P AGU1 captured address'
  'sq_bind1_lost|backend|OooIntBackend.v|tb_ooo_int_backend|V8P_MUTATE_SQ_BIND1_LOST|sq_bind1_lost|[CHECK-FAIL] V8P store-store exact dual SQ owner binds'
  'sq_bind1_cross|backend|OooIntBackend.v|tb_ooo_int_backend|V8P_MUTATE_SQ_BIND1_CROSS|sq_bind1_cross|[CHECK-FAIL] V8P store-store SQ token1'
  'special_misadmission|queue|OooIntIssueQueue.v|tb_ooo_int_backend|V8P_MUTATE_SPECIAL_MISADMISSION|special_misadmission|[CHECK-FAIL] V8P excluded class cannot select terminal1'
  'bank1_age_bypass|backend|OooIntBackend.v|tb_ooo_int_backend|V8P_MUTATE_BANK1_AGE_BYPASS|bank1_age_bypass|[CHECK-FAIL] V8P bank1 cannot pass edge-old bank0'
  'pid1_truncation|backend|OooIntBackend.v|tb_ooo_int_backend|V8P_MUTATE_PID1_TRUNCATION|pid1_truncation|[CHECK-FAIL] V8P memory PID1 generation nonzero'
  'bank1_cancel_leak|backend|OooIntBackend.v|tb_ooo_int_backend|V8P_MUTATE_BANK1_CANCEL_LEAK|bank1_cancel_leak|[CHECK-FAIL] V8P cancel drains all owner tokens'
)

source_for_kind() {
  case "$1" in
    selector) printf '%s\n' "$SELECTOR" ;;
    queue) printf '%s\n' "$QUEUE" ;;
    backend) printf '%s\n' "$BACKEND" ;;
    tracker) printf '%s\n' "$TRACKER" ;;
    *) return 1 ;;
  esac
}

: > "$EVIDENCE_DIR/mutation-summary.log"
for row in "${mutation_rows[@]}"; do
  IFS='|' read -r name kind basename test macro activation failure <<< "$row"
  source=$(source_for_kind "$kind")
  mutant="$TEMP_DIR/mutants/$name/$basename"
  python3 "$MUTATOR" "$name" "$source" "$mutant" \
    > "$EVIDENCE_DIR/mutation-$name.mutator.log" 2>&1

  flags="$base_flags -DV8P_PAIR_MATRIX_FOCUSED -D$macro"
  if run_make "mutation-$name" "$test" "$flags" "$kind" "$mutant"; then
    fail "mutation survived focused semantic test: $name"
  fi
  image="$TEMP_DIR/build-mutation-$name/$test.vvp"
  [[ -s "$image" ]] || fail "mutation did not elaborate successfully: $name"
  log="$EVIDENCE_DIR/mutation-$name/logs/$test.log"
  require_marker "[V8P-MUTATION-ACTIVATED] $activation" "$log"
  require_marker "$failure" "$log"
  require_marker '[RESULT] FAIL' "$log"
  fatal_count=$(grep -c '^FATAL:' "$log" || true)
  expected_fatal_count=$(grep -c '^FATAL: common/tb_common.svh:35:' "$log" || true)
  if [[ "$name" == alloc0_only_birth ]]; then
    expected_fatal_count=$(( expected_fatal_count + $(
      grep -Ec '^FATAL: tests/tb_ooo_mem_owner_tracker.sv:[0-9]+:' "$log" || true
    ) ))
  fi
  [[ "$fatal_count" -eq "$expected_fatal_count" ]] ||
    fail "mutation hit an unrelated fatal marker: $name"
  source_sha=$(sha256sum "$mutant" | awk '{print $1}')
  image_sha=$(sha256sum "$image" | awk '{print $1}')
  printf '[V8P-MUTATION][PASS] name=%s source_sha256=%s image_sha256=%s compile=PASS elaboration=PASS activation=PASS rejection=PASS oracle=simulation\n' \
    "$name" "$source_sha" "$image_sha" >> "$EVIDENCE_DIR/mutation-summary.log"
done

# Vacuity mutation: behavior remains correct and compiles, but the exact second
# AGU instance identity is renamed.  Simulation must stay green while the
# fail-closed DI-3 source checker rejects the broken proof binding.
checker_name=checker_vacuity
checker_mutant="$TEMP_DIR/mutants/$checker_name/OooIntBackend.v"
python3 "$MUTATOR" "$checker_name" "$BACKEND" "$checker_mutant" \
  > "$EVIDENCE_DIR/mutation-$checker_name.mutator.log" 2>&1
run_make "mutation-$checker_name" tb_ooo_int_backend \
  "$base_flags -DV8P_PAIR_MATRIX_FOCUSED" backend "$checker_mutant" ||
  fail "checker-vacuity mutation changed simulation behavior"
checker_image="$TEMP_DIR/build-mutation-$checker_name/tb_ooo_int_backend.vvp"
checker_log="$EVIDENCE_DIR/mutation-$checker_name/logs/tb_ooo_int_backend.log"
[[ -s "$checker_image" ]] || fail "checker-vacuity mutation did not elaborate"
require_clean_pass "$checker_log"
python3 - "$REPO_ROOT" "$checker_mutant" "$ARCH_TOOL" \
  > "$EVIDENCE_DIR/mutation-$checker_name.checker.log" <<'PY'
import importlib.util
import pathlib
import sys

root = pathlib.Path(sys.argv[1]).resolve(strict=True)
mutant = pathlib.Path(sys.argv[2]).resolve(strict=True)
tool = pathlib.Path(sys.argv[3]).resolve(strict=True)
spec = importlib.util.spec_from_file_location("v8p_arch", tool)
assert spec is not None and spec.loader is not None
arch = importlib.util.module_from_spec(spec)
sys.modules[spec.name] = arch
spec.loader.exec_module(arch)
sources = arch.live_sources(root)
text = arch.strip_comments(mutant.read_text(encoding="utf-8"))
if text.count("u_issue1_lsu_hidden") != 1:
    raise SystemExit("checker-vacuity source mutation was not activated")
sources["execute/OooIntBackend.v"] = text
checks = {item.check_id: item for item in arch.di3_checks(sources)}
if checks["source.two_captured_data_agus"].passed:
    raise SystemExit("source checker accepted renamed second AGU")
if checks["source.memory_pairs_two_terminals"].passed:
    raise SystemExit("aggregate DI-3 source check stayed green")
print("[V8P-MUTATION-ACTIVATED] checker_vacuity")
print("[V8P-SOURCE-CHECK-REJECTION] two_captured_data_agus RED PASS")
PY
require_marker '[V8P-MUTATION-ACTIVATED] checker_vacuity' \
  "$EVIDENCE_DIR/mutation-$checker_name.checker.log"
require_marker '[V8P-SOURCE-CHECK-REJECTION] two_captured_data_agus RED PASS' \
  "$EVIDENCE_DIR/mutation-$checker_name.checker.log"
checker_source_sha=$(sha256sum "$checker_mutant" | awk '{print $1}')
checker_image_sha=$(sha256sum "$checker_image" | awk '{print $1}')
printf '[V8P-MUTATION][PASS] name=%s source_sha256=%s image_sha256=%s compile=PASS elaboration=PASS activation=PASS rejection=PASS oracle=source_checker\n' \
  "$checker_name" "$checker_source_sha" "$checker_image_sha" \
  >> "$EVIDENCE_DIR/mutation-summary.log"

sha256sum "${source_paths[@]}" > "$EVIDENCE_DIR/sources.post.sha256"
cmp "$EVIDENCE_DIR/sources.pre.sha256" "$EVIDENCE_DIR/sources.post.sha256" ||
  fail "canonical proof sources changed while running mutations"

# Refresh previously proven siblings under this exact full RTL digest.  A
# refusal or failure in one bounded refresh is evidence for that sibling only;
# this orchestrator keeps the architecture RED and aborts publication rather
# than changing any long-running goal status.
ARCH_REFRESH_MODE=1 bash \
  "$REPO_ROOT/.github/task-runs/2026-07-20-rv64-v8n-true-ooo-long-latency/run-focused.sh" \
  > "$EVIDENCE_DIR/sibling-refresh-ooo1.log" 2>&1 ||
  fail "same-design OOO-1 refresh failed"
ARCH_REFRESH_MODE=1 bash \
  "$REPO_ROOT/.github/task-runs/2026-07-20-rv64-v8m-selective-scheduling/run-focused.sh" \
  > "$EVIDENCE_DIR/sibling-refresh-ooo2.log" 2>&1 ||
  fail "same-design OOO-2 refresh failed"
ARCH_REFRESH_MODE=1 bash \
  "$REPO_ROOT/.github/task-runs/2026-07-20-rv64-v8o-no-static-lane-semantics/run-focused.sh" \
  > "$EVIDENCE_DIR/sibling-refresh-di4.log" 2>&1 ||
  fail "same-design DI-4 refresh failed"

cp -- "$ARCH_MANIFEST" "$EVIDENCE_DIR/static/manifest-before-pair.json"
python3 "$BUILDER" \
  --repo-root "$REPO_ROOT" \
  --backend-release-log "$EVIDENCE_DIR/baseline-release/logs/tb_ooo_int_backend.log" \
  --backend-assert-log "$EVIDENCE_DIR/baseline-assert/logs/tb_ooo_int_backend.log" \
  --tracker-release-log "$EVIDENCE_DIR/baseline-release/logs/tb_ooo_mem_owner_tracker.log" \
  --tracker-assert-log "$EVIDENCE_DIR/baseline-assert/logs/tb_ooo_mem_owner_tracker.log" \
  --collector-release-log "$EVIDENCE_DIR/baseline-release/logs/tb_ooo_mem_owner_terminal_collector.log" \
  --collector-assert-log "$EVIDENCE_DIR/baseline-assert/logs/tb_ooo_mem_owner_terminal_collector.log" \
  --sq-release-log "$EVIDENCE_DIR/baseline-release/logs/tb_ooo_store_queue.log" \
  --sq-assert-log "$EVIDENCE_DIR/baseline-assert/logs/tb_ooo_store_queue.log" \
  --mutation-summary "$EVIDENCE_DIR/mutation-summary.log" \
  --sources-pre "$EVIDENCE_DIR/sources.pre.sha256" \
  --sources-post "$EVIDENCE_DIR/sources.post.sha256" \
  --gate-log "$ARCH_LOG" \
  --manifest "$ARCH_MANIFEST" \
  > "$EVIDENCE_DIR/evidence-builder.log" 2>&1

python3 - "$EVIDENCE_DIR/static/manifest-before-pair.json" "$ARCH_MANIFEST" <<'PY'
import json
import pathlib
import sys

before = json.loads(pathlib.Path(sys.argv[1]).read_text(encoding="utf-8"))
after = json.loads(pathlib.Path(sys.argv[2]).read_text(encoding="utf-8"))
if before.get("design_id") != after.get("design_id"):
    raise SystemExit("pair publication changed the refreshed design binding")
before_tests = before.get("tests", {})
after_tests = after.get("tests", {})
expected_siblings = {
    "true_ooo_long_latency", "selective_scheduling",
    "no_static_lane_semantics",
}
if not expected_siblings.issubset(before_tests):
    raise SystemExit(f"sibling refresh inventory mismatch: {sorted(before_tests)}")
expected_after = set(before_tests) | expected_siblings | {"pair_matrix"}
if set(after_tests) != expected_after:
    raise SystemExit(f"pair publication inventory mismatch: {sorted(after_tests)}")
for name, record in before_tests.items():
    if name == "pair_matrix":
        continue
    if after_tests.get(name) != record:
        raise SystemExit(f"pair publication changed sibling evidence: {name}")
PY

set +e
make -C "$TB_HOME" \
  "ARCH_GATE_EVIDENCE=$ARCH_MANIFEST" \
  "ARCH_GATE_RESULT=$EVIDENCE_DIR/static/architecture-result.json" \
  arch-gates > "$EVIDENCE_DIR/static/architecture-gates.log" 2>&1
arch_rc=$?
set -e
[[ "$arch_rc" -ne 0 ]] || fail "architecture inventory unexpectedly became overall GREEN"
require_marker 'DI-3: GREEN (0 red checks)' "$EVIDENCE_DIR/static/architecture-gates.log"
require_marker 'DI-4: GREEN (0 red checks)' "$EVIDENCE_DIR/static/architecture-gates.log"
require_marker 'OOO-1: GREEN (0 red checks)' "$EVIDENCE_DIR/static/architecture-gates.log"
require_marker 'OOO-2: GREEN (0 red checks)' "$EVIDENCE_DIR/static/architecture-gates.log"
require_marker 'OOO-3: RED' "$EVIDENCE_DIR/static/architecture-gates.log"
require_marker 'OVERALL: RED' "$EVIDENCE_DIR/static/architecture-gates.log"

python3 - "$EVIDENCE_DIR/static/architecture-result.json" <<'PY'
import json
import pathlib
import sys

result = json.loads(pathlib.Path(sys.argv[1]).read_text(encoding="utf-8"))
green = {gate for gate, value in result["gates"].items()
         if value["status"] == "GREEN"}
required_green = {"DI-3", "DI-4", "OOO-1", "OOO-2"}
missing_green = required_green - green
if missing_green:
    raise SystemExit(f"required gates are not GREEN: {sorted(missing_green)}")
if result["gates"]["OOO-3"]["status"] != "RED":
    raise SystemExit("OOO-3 unexpectedly became GREEN")
if result["overall_status"] != "RED":
    raise SystemExit("architecture inventory is not RED")
PY

di5_status=$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1], encoding="utf-8"))["gates"]["DI-5"]["status"])' \
  "$EVIDENCE_DIR/static/architecture-result.json")
printf '[V8P-RUNNER][PASS] baselines=8/8 pair_keys=15/15 memory_pairs=4/4 exclusions=10/10 mutations=%d/%d siblings=3/3 DI-3=GREEN DI-4=GREEN OOO-1=GREEN OOO-2=GREEN DI-5=%s OOO-3=RED overall=RED\n' \
  "$(( ${#mutation_rows[@]} + 1 ))" "$(( ${#mutation_rows[@]} + 1 ))" \
  "$di5_status" |
  tee "$EVIDENCE_DIR/runner-summary.log"
