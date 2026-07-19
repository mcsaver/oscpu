#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
ROOT_DIR=$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)
TESTBENCH_DIR="$ROOT_DIR/npc/rv64/testbench"
RTL_SOURCE="$ROOT_DIR/npc/rv64/vsrc/execute/OooIntBackend.v"
TB_SOURCE="$TESTBENCH_DIR/tests/tb_ooo_int_backend.sv"
EVIDENCE_DIR="$SCRIPT_DIR/evidence/focused-replay"
TEMP_DIR=$(mktemp -d "${TMPDIR:-/tmp}/v8d-int-ex-kill.XXXXXX")
trap 'rm -rf -- "$TEMP_DIR"' EXIT
mkdir -p "$EVIDENCE_DIR"

make_mutant() {
  local name=$1
  local old=$2
  local new=$3
  local destination="$TEMP_DIR/mutant-$name/OooIntBackend.v"
  mkdir -p "$(dirname -- "$destination")"
  python3 - "$RTL_SOURCE" "$destination" "$old" "$new" <<'PY'
from pathlib import Path
import sys

source, destination, old, new = sys.argv[1:]
text = Path(source).read_text()
count = text.count(old)
if count != 1:
    raise SystemExit(f"mutation pattern count={count}, expected 1: {old!r}")
Path(destination).write_text(text.replace(old, new, 1))
PY
  printf '%s\n' "$destination"
}

run_case() {
  local source=$1
  local label=$2
  local assert_define=$3
  local result_dir="$EVIDENCE_DIR/$label"
  local build_dir="$TEMP_DIR/build-$label"
  local make_log="$EVIDENCE_DIR/$label.make.log"
  local ivflags="-g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DINT_EX_KILL_CUT_FOCUSED"
  if [[ "$assert_define" == 1 ]]; then
    ivflags="$ivflags -DOOO_ASSERT"
  fi
  case "$result_dir" in
    "$EVIDENCE_DIR"/*) rm -rf -- "$result_dir" ;;
    *) printf '[FAIL] unsafe result path: %s\n' "$result_dir" >&2; return 2 ;;
  esac

  set +e
  make -C "$TESTBENCH_DIR" \
    TESTS=tb_ooo_int_backend \
    BUILD_DIR="$build_dir" \
    RESULT_DIR="$result_dir" \
    RTL_OOO_INT_BACKEND="$source" \
    IVFLAGS="$ivflags" run >"$make_log" 2>&1
  local rc=$?
  set -e
  printf '[MAKE-RC] %d\n' "$rc" >>"$make_log"
  return "$rc"
}

require_green() {
  local label=$1
  local sim_log="$EVIDENCE_DIR/$label/logs/tb_ooo_int_backend.log"
  if ! grep -Fqx '[RESULT] PASS' "$sim_log" ||
     [[ "$(grep -Fxc '[V8D-INT-EX-KILL-AGE] checks=8192 failures=0' "$sim_log" || true)" -ne 1 ]] ||
     [[ "$(grep -Fc '[V8D-INT-EX-KILL-CUT]' "$sim_log" || true)" -ne 1 ]] ||
     grep -Fq '[FAIL]' "$sim_log"; then
    printf '[FAIL] %s lacked exact focused GREEN markers\n' "$label" >&2
    return 1
  fi
  printf '[PASS] %s exact focused GREEN\n' "$label"
}

run_baseline() {
  local label=$1
  local assert_define=$2
  if ! run_case "$RTL_SOURCE" "$label" "$assert_define"; then
    printf '[FAIL] current baseline %s\n' "$label" >&2
    return 1
  fi
  require_green "$label"
}

run_mutation() {
  local name=$1
  local old=$2
  local new=$3
  local mutant
  mutant=$(make_mutant "$name" "$old" "$new")
  if run_case "$mutant" "mutation-$name" 1; then
    printf '[FAIL] compile-success semantic mutation survived: %s\n' "$name" >&2
    return 1
  fi
  local sim_log="$EVIDENCE_DIR/mutation-$name/logs/tb_ooo_int_backend.log"
  if [[ ! -f "$sim_log" ]] ||
     ! grep -Fq '[RESULT] FAIL' "$sim_log" ||
     ! grep -Eq '\[(CHECK-)?FAIL\]' "$sim_log" ||
     ! grep -Fq '[COMPILE]' "$sim_log"; then
    printf '[FAIL] mutation did not reach a targeted simulation RED: %s\n' "$name" >&2
    return 1
  fi
  printf '[PASS] compile-success semantic mutation detected: %s\n' "$name"
}

summary="$EVIDENCE_DIR/green-summary.txt"
: >"$summary"
run_baseline release 0 | tee -a "$summary"
run_baseline assert 1 | tee -a "$summary"
run_mutation ex1-mask-removed \
  'assign ex1_wb_valid_w = ex1_valid_q && !ex1_kill_now_w;' \
  'assign ex1_wb_valid_w = ex1_valid_q;' | tee -a "$summary"
run_mutation ex0-equal-killed \
  '(ex0_completion_age_w > ex_kill_boundary_age_w);' \
  '(ex0_completion_age_w >= ex_kill_boundary_age_w);' | tee -a "$summary"
run_mutation ex0-global-mispredict-mask \
  'assign ex0_wb_valid_w = ex0_valid_q && !ex0_kill_now_w;' \
  'assign ex0_wb_valid_w = ex0_valid_q && !branch_resolve_mispredict_w;' | tee -a "$summary"
run_mutation ex1-raw-index-compare \
  '(ex1_completion_age_w > ex_kill_boundary_age_w);' \
  '(ex1_rob_idx_q > branch_resolve_rob_idx_o);' | tee -a "$summary"
run_mutation ex1-wrong-owner \
  'assign ex1_wb_valid_w = ex1_valid_q && !ex1_kill_now_w;' \
  'assign ex1_wb_valid_w = ex1_valid_q && !ex0_kill_now_w;' | tee -a "$summary"
run_mutation killed-ex0-blocks-muldiv \
  'muldiv_resp_valid_w && !ex0_wb_valid_w && !mem_rsp_to_wb0_w;' \
  'muldiv_resp_valid_w && !ex0_valid_q && !mem_rsp_to_wb0_w;' | tee -a "$summary"
run_mutation killed-ex1-blocks-muldiv \
  'muldiv_resp_valid_w && !muldiv_rsp_to_wb0_w && !ex1_wb_valid_w &&' \
  'muldiv_resp_valid_w && !muldiv_rsp_to_wb0_w && !ex1_valid_q &&' | tee -a "$summary"
run_mutation ex1-forward-mask-removed \
  'ex1_wb_valid_w && ex1_down_payload_w[144];' \
  'ex1_valid_q && ex1_down_payload_w[144];' | tee -a "$summary"
run_mutation ex1-prf-mask-removed \
  '(ex1_wb_valid_w && ex1_wb_pdest_nonzero_w) ||' \
  '(ex1_valid_q && ex1_wb_pdest_nonzero_w) ||' | tee -a "$summary"
run_mutation dispatch-wb1-fanout-raw \
  '.wb1_valid_i(wb1_valid_w),' \
  '.wb1_valid_i(ex1_valid_q),' | tee -a "$summary"
run_mutation fp-iq-wake1-fanout-raw \
  '.int_wake1_valid_i(gpr_wb1_write_valid_w),' \
  '.int_wake1_valid_i(ex1_valid_q),' | tee -a "$summary"
sha256sum "$RTL_SOURCE" "$TB_SOURCE" "$0" \
  "$TESTBENCH_DIR/Makefile" "$ROOT_DIR/npc/rv64/vsrc/filelist.mk" \
  >"$EVIDENCE_DIR/current-sources.sha256"
printf '[PASS] release + assert baselines + 11 compile-success semantic mutations\n' \
  | tee -a "$summary"
