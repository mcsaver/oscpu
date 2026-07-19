#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
ROOT_DIR=$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)
VSRCDIR="$ROOT_DIR/npc/rv64/vsrc"
RTL_SOURCE="$VSRCDIR/execute/OooFpBackend.v"
TB_SOURCE="$SCRIPT_DIR/tb_ooo_fp_backend_completion_kill.sv"
EVIDENCE_DIR="$SCRIPT_DIR/evidence"
EXPECTED_CHECKS=170
BUILD_DIR=$(mktemp -d "${TMPDIR:-/tmp}/v8c-fp-completion-kill.XXXXXX")
trap 'rm -rf -- "$BUILD_DIR"' EXIT
mkdir -p "$EVIDENCE_DIR"

# 冻结本刀开工时 production OooFpBackend 的 Git blob。该对象只用于重放
# current TB 下的真实 pre-fix RED；hash 不匹配即 fail closed。
PRE_FIX_BLOB=7fc8e14154c260ba9b1e737d6180975aa063234d
PRE_FIX_SHA256=00e64e4851995789d9deb73b47f171b3fb8a499396e6b2b889a106ea0a9ba6f0

IVERILOG_BIN=${IVERILOG:-$(command -v iverilog)}
VVP_BIN=${VVP:-"$(dirname -- "$IVERILOG_BIN")/vvp"}
if [[ ! -x "$VVP_BIN" ]]; then
  VVP_BIN=$(command -v vvp)
fi
VERILATOR_BIN=${VERILATOR:-$(command -v verilator)}

DEPS=(
  "$VSRCDIR/pipeline/PipeStageReg.v"
  "$VSRCDIR/rename_allocate/OooFreeList.v"
  "$VSRCDIR/regread_bypass/OooFpRegFile.v"
  "$VSRCDIR/regread_bypass/OooFpPhysRegFile.v"
  "$VSRCDIR/scheduling/OooFpIssueQueue.v"
  "$VSRCDIR/execute/OooFpArithGate.v"
  "$VSRCDIR/execute/OooFpLongOpGate.v"
  "$VSRCDIR/execute/OooFpDivIter.v"
  "$VSRCDIR/execute/OooFpSqrtIter.v"
  "$VSRCDIR/execute/OooFpClassifyGate.v"
  "$VSRCDIR/execute/OooFpSgnjGate.v"
  "$VSRCDIR/execute/OooFpCompareGate.v"
  "$VSRCDIR/execute/OooFpConvertGate.v"
)

compile_and_run() {
  local source=$1
  local label=$2
  local compile_log="$EVIDENCE_DIR/${label}.compile.log"
  local sim_log="$EVIDENCE_DIR/${label}.sim.log"
  local vvp_out="$BUILD_DIR/${label}.vvp"

  set +e
  "$IVERILOG_BIN" -g2012 -Wall -DOOO_ASSERT \
    -I"$VSRCDIR" -I"$VSRCDIR/include" \
    -s tb_ooo_fp_backend_completion_kill \
    -o "$vvp_out" \
    "$source" "${DEPS[@]}" "$TB_SOURCE" \
    >"$compile_log" 2>&1
  local compile_rc=$?
  set -e
  printf '[COMPILE-RC] %d\n' "$compile_rc" >>"$compile_log"
  if [[ "$compile_rc" -ne 0 ]]; then
    return 125
  fi

  set +e
  "$VVP_BIN" "$vvp_out" >"$sim_log" 2>&1
  local sim_rc=$?
  set -e
  printf '[SIM-RC] %d\n' "$sim_rc" >>"$sim_log"
  return "$sim_rc"
}

run_baseline() {
  local label=$1
  if compile_and_run "$RTL_SOURCE" "$label"; then
    if [[ "$(grep -Fxc "PASS tb_ooo_fp_backend_completion_kill checks=$EXPECTED_CHECKS" \
        "$EVIDENCE_DIR/${label}.sim.log" || true)" -ne 1 ]] || \
       grep -Fq '[FAIL]' "$EVIDENCE_DIR/${label}.sim.log"; then
      printf '[FAIL] baseline %s did not produce the exact %s-check marker\n' \
        "$label" "$EXPECTED_CHECKS" >&2
      return 1
    fi
    printf '[PASS] baseline %s\n' "$label"
    return 0
  fi
  printf '[FAIL] baseline %s (see %s/%s.sim.log)\n' \
    "$label" "$EVIDENCE_DIR" "$label" >&2
  return 1
}

run_pre_fix_red() {
  local source="$BUILD_DIR/pre-fix/OooFpBackend.v"
  local actual_sha
  mkdir -p "$(dirname -- "$source")"
  git -C "$ROOT_DIR" cat-file blob "$PRE_FIX_BLOB" >"$source"
  actual_sha=$(sha256sum "$source" | awk '{print $1}')
  if [[ "$actual_sha" != "$PRE_FIX_SHA256" ]]; then
    printf '[FAIL] frozen pre-fix source hash mismatch: %s\n' "$actual_sha" >&2
    return 1
  fi
  printf '%s  git-blob:%s\n' "$actual_sha" "$PRE_FIX_BLOB" \
    >"$EVIDENCE_DIR/pre-fix-source.sha256"

  if compile_and_run "$source" pre-fix-current-tb; then
    printf '[FAIL] frozen pre-fix unexpectedly passed current TB\n' >&2
    return 1
  else
    local case_rc=$?
    if [[ "$case_rc" -eq 125 ]]; then
      printf '[FAIL] frozen pre-fix did not compile\n' >&2
      return 1
    fi
  fi
  local sim_log="$EVIDENCE_DIR/pre-fix-current-tb.sim.log"
  if ! grep -Fq '[FAIL] exec1 wrap-younger take blocked' "$sim_log" || \
     ! grep -Fq '[FAIL] long wrap-younger take blocked' "$sim_log" || \
     ! grep -Fq '[FAIL] mixed killed exec1 not selected' "$sim_log" || \
     ! grep -Eq "FATAL: .*FAIL tb_ooo_fp_backend_completion_kill failures=[1-9][0-9]* checks=$EXPECTED_CHECKS" "$sim_log" || \
     [[ "$(grep -Fxc '[SIM-RC] 1' "$sim_log" || true)" -ne 1 ]]; then
    printf '[FAIL] frozen pre-fix RED did not reach all required oracles\n' >&2
    return 1
  fi
  printf '[PASS] frozen pre-fix blob reproduces exec1/long/mixed RED\n'
}

run_scoped_verilator_lint() {
  "$VERILATOR_BIN" --lint-only -Wall \
    -Wno-WIDTHEXPAND -Wno-WIDTHTRUNC -Wno-UNUSEDSIGNAL \
    -Wno-UNUSEDPARAM -Wno-PINCONNECTEMPTY -Wno-TIMESCALEMOD \
    -I"$VSRCDIR" -I"$VSRCDIR/include" +define+OOO_ASSERT \
    --top-module OooFpBackend "$RTL_SOURCE" "${DEPS[@]}" \
    >"$EVIDENCE_DIR/scoped-verilator-lint.log" 2>&1
  printf '[LINT-RC] 0\n' >>"$EVIDENCE_DIR/scoped-verilator-lint.log"
  printf '[PASS] scoped Verilator lint\n'
}

make_mutant() {
  local name=$1
  local old=$2
  local new=$3
  local destination="$BUILD_DIR/mutant-${name}/OooFpBackend.v"
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

run_mutation() {
  local name=$1
  local old=$2
  local new=$3
  local mutant
  mutant=$(make_mutant "$name" "$old" "$new")
  if compile_and_run "$mutant" "mutation-${name}"; then
    printf '[FAIL] semantic mutation survived: %s\n' "$name" >&2
    return 1
  else
    local case_rc=$?
    if [[ "$case_rc" -eq 125 ]]; then
      printf '[FAIL] semantic mutation did not compile: %s\n' "$name" >&2
      return 1
    fi
  fi
  local sim_log="$EVIDENCE_DIR/mutation-${name}.sim.log"
  if ! grep -Eq "FATAL: .*FAIL tb_ooo_fp_backend_completion_kill failures=[1-9][0-9]* checks=$EXPECTED_CHECKS" "$sim_log" || \
     [[ "$(grep -Fxc '[SIM-RC] 1' "$sim_log" || true)" -ne 1 ]] || \
     ! grep -Fq '[FAIL]' "$sim_log"; then
    printf '[FAIL] semantic mutation lacked a complete targeted TB failure: %s\n' \
      "$name" >&2
    return 1
  fi
  printf '[PASS] semantic mutation compiled and was detected: %s\n' "$name"
}

mode=${1:---all}
case "$mode" in
  --baseline-only)
    run_baseline "${2:-baseline}"
    ;;
  --pre-fix-red)
    run_pre_fix_red
    ;;
  --all)
    summary="$EVIDENCE_DIR/green-summary.txt"
    : >"$summary"
    run_pre_fix_red | tee -a "$summary"
    run_scoped_verilator_lint | tee -a "$summary"
    run_baseline green | tee -a "$summary"
    run_mutation exec1-mask-removed \
      'wire exec1_take_w = exec1_take_candidate_w && !exec1_kill_w;' \
      'wire exec1_take_w = exec1_take_candidate_w;' | tee -a "$summary"
    run_mutation long-mask-removed \
      'wire long_take_w = long_take_candidate_w && !long_kill_w;' \
      'wire long_take_w = long_take_candidate_w;' | tee -a "$summary"
    run_mutation exec1-equal-killed \
      '(exec1_age_w > kill_age_w);' \
      '(exec1_age_w >= kill_age_w);' | tee -a "$summary"
    run_mutation long-equal-killed \
      '(long_age_w > kill_age_w);' \
      '(long_age_w >= kill_age_w);' | tee -a "$summary"
    run_mutation exec1-wrong-owner \
      'wire exec1_take_w = exec1_take_candidate_w && !exec1_kill_w;' \
      'wire exec1_take_w = exec1_take_candidate_w && !long_kill_w;' | tee -a "$summary"
    run_mutation long-wrong-owner \
      'wire long_take_w = long_take_candidate_w && !long_kill_w;' \
      'wire long_take_w = long_take_candidate_w && !exec1_kill_w;' | tee -a "$summary"
    run_mutation killed-exec1-blocks-long \
      '!arith_out_valid_w && !exec1_take_w;' \
      '!arith_out_valid_w && !exec1_take_candidate_w;' | tee -a "$summary"
    run_mutation long-raw-index-compare \
      '(long_age_w > kill_age_w);' \
      '(long_rob_q > kill_rob_idx_i);' | tee -a "$summary"
    run_mutation gpr-misclassified-fpr \
      "exec1_take_w ? (exec1_dst_en_q && !exec1_dst_gpr_q) : 1'b1;" \
      "exec1_take_w ? exec1_dst_en_q : 1'b1;" | tee -a "$summary"
    run_mutation gpr-rd-en-lost \
      'wire done_in_rd_en_w = exec1_take_w && exec1_dst_gpr_q && exec1_dst_en_q;' \
      "wire done_in_rd_en_w = 1'b0;" | tee -a "$summary"
    run_mutation exec1-ignores-arith \
      'wire exec1_take_candidate_w = exec1_valid_q && !arith_out_valid_w;' \
      'wire exec1_take_candidate_w = exec1_valid_q;' | tee -a "$summary"
    run_mutation long-ignores-arith \
      '!arith_out_valid_w && !exec1_take_w;' \
      '!exec1_take_w;' | tee -a "$summary"
    run_mutation fifo-ready-ignored \
      'wire df_pop_w = !df_empty_w && (df_head_killed_w || fpwb_ready_i);' \
      'wire df_pop_w = !df_empty_w && df_head_killed_w;' | tee -a "$summary"
    run_mutation long-fifo-rob-corrupt \
      'exec1_take_w ? exec1_rob_q : long_rob_q;' \
      'exec1_take_w ? exec1_rob_q : arith_out_rob_w;' | tee -a "$summary"
    sha256sum "$RTL_SOURCE" "$TB_SOURCE" "$0" \
      "$VSRCDIR/include/define.v" "${DEPS[@]}" \
      >"$EVIDENCE_DIR/current-sources.sha256"
    printf '[PASS] frozen pre-fix RED + focused baseline + 14 compile-success semantic mutations\n' \
      | tee -a "$summary"
    ;;
  *)
    printf 'usage: %s [--all | --baseline-only [label] | --pre-fix-red]\n' "$0" >&2
    exit 2
    ;;
esac
