#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd -P)
TASK_DIR="$ROOT_DIR/.github/task-runs/2026-07-15-rv64-ppa-architecture-recovery"
OUT_DIR=${1:-$TASK_DIR/evidence/r4-s0-assertion-negative}
TB="$TASK_DIR/tb-r4-s0-assertion-negative.sv"
CLASS_RTL="$ROOT_DIR/npc/rv64/vsrc/memory/OooPostTranslateMemoryClass.v"
DCACHE_RTL="$ROOT_DIR/npc/rv64/vsrc/cache/OooDataWordCache.v"
SRAM_RTL="$ROOT_DIR/npc/rv64/vsrc/sram/Sram4096x113.v"
IVERILOG=${IVERILOG:-iverilog}
VVP=${VVP:-vvp}

if [[ -e $OUT_DIR ]]; then
  printf '[R4-S0-ASSERT-NEGATIVE] refusing stale output: %s\n' "$OUT_DIR" >&2
  exit 2
fi
mkdir -p "$OUT_DIR"

tracked=("$TB" "$CLASS_RTL" "$DCACHE_RTL" "$SRAM_RTL" "$TASK_DIR/run-r4-s0-assertion-negative.sh")
sha256sum "${tracked[@]}" >"$OUT_DIR/inputs.pre.sha256"

"$IVERILOG" -g2012 -Wall -DOOO_ASSERT \
  -I"$ROOT_DIR/npc/rv64/vsrc" \
  -I"$ROOT_DIR/npc/rv64/vsrc/include" \
  -s tb_r4_s0_posttranslate_assert_negative \
  -o "$OUT_DIR/classifier.vvp" "$TB" "$CLASS_RTL" \
  >"$OUT_DIR/classifier.compile.log" 2>&1

"$IVERILOG" -g2012 -Wall -DOOO_ASSERT \
  -I"$ROOT_DIR/npc/rv64/vsrc" \
  -I"$ROOT_DIR/npc/rv64/vsrc/include" \
  -s tb_r4_s0_dcache_invalidate_assert_negative \
  -o "$OUT_DIR/dcache.vvp" "$TB" "$DCACHE_RTL" "$SRAM_RTL" \
  >"$OUT_DIR/dcache.compile.log" 2>&1

summary="$OUT_DIR/summary.tsv"
printf 'case\texpected_marker\trun_rc\tmarker_count\terror_count\tdone_count\tstatus\n' >"$summary"

run_classifier_case() {
  local id=$1 name=$2 marker=$3
  local log="$OUT_DIR/classifier-${name}.log"
  set +e
  "$VVP" "$OUT_DIR/classifier.vvp" "+CASE=$id" >"$log" 2>&1
  local rc=$?
  set -e
  local marker_count error_count done_count status
  marker_count=$(grep -F -c "[$marker]" "$log" || true)
  error_count=$(grep -c '^ERROR:' "$log" || true)
  done_count=$(grep -F -c "[R4-S0-NEGATIVE-DONE] classifier_case=$id" "$log" || true)
  status=PASS
  if [[ $rc -ne 0 || $marker_count -ne 1 || $error_count -ne 1 || $done_count -ne 1 ]]; then
    status=FAIL
  fi
  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
    "$name" "$marker" "$rc" "$marker_count" "$error_count" "$done_count" "$status" \
    >>"$summary"
  [[ $status == PASS ]]
}

run_classifier_case 1 exclusive POSTXLATE-CLASS-EXCLUSIVE
run_classifier_case 2 pbmt POSTXLATE-CLASS-PBMT
run_classifier_case 3 fault POSTXLATE-CLASS-FAULT

dcache_log="$OUT_DIR/dcache-invalidate.log"
set +e
"$VVP" "$OUT_DIR/dcache.vvp" >"$dcache_log" 2>&1
dcache_rc=$?
set -e
dcache_marker_count=$(grep -F -c '[DWC-STORE-INVALIDATE]' "$dcache_log" || true)
dcache_error_count=$(grep -c '^ERROR:' "$dcache_log" || true)
dcache_missed_count=$(grep -F -c '[R4-S0-NEGATIVE-MISSED]' "$dcache_log" || true)
dcache_status=PASS
if [[ $dcache_rc -eq 0 || $dcache_marker_count -ne 1 || $dcache_error_count -ne 1 || $dcache_missed_count -ne 0 ]]; then
  dcache_status=FAIL
fi
printf 'dcache_invalidate\tDWC-STORE-INVALIDATE\t%s\t%s\t%s\t0\t%s\n' \
  "$dcache_rc" "$dcache_marker_count" "$dcache_error_count" "$dcache_status" >>"$summary"

sha256sum "${tracked[@]}" >"$OUT_DIR/inputs.post.sha256"
cmp -s "$OUT_DIR/inputs.pre.sha256" "$OUT_DIR/inputs.post.sha256"

if grep -Fq $'\tFAIL' "$summary"; then
  cat "$summary" >&2
  exit 1
fi

sha256sum "$summary" "$OUT_DIR"/*.log >"$OUT_DIR/SHA256SUMS"
cat "$summary"
printf '[R4-S0-ASSERT-NEGATIVE] PASS cases=4 inputs_unchanged=1\n'
