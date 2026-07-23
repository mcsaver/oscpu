#!/usr/bin/env bash
set -euo pipefail

RUN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(git -C "$RUN_DIR" rev-parse --show-toplevel)"
EVIDENCE_DIR="$RUN_DIR/evidence/mutations-final"
TB_HOME="$REPO_ROOT/npc/rv64/testbench"
VSRC="$REPO_ROOT/npc/rv64/vsrc"
BACKEND="$VSRC/execute/OooIntBackend.v"
BRIDGE="$VSRC/memory/OooMemAxiBridge.v"
IQ="$VSRC/scheduling/OooIntIssueQueue.v"
SELECTOR="$VSRC/scheduling/OooIntIssueSelect8.v"
MUTATOR="$RUN_DIR/mutate-v8u-f4.py"
V8U_F4_TMP="$(mktemp -d -t v8u-f4-mutations.XXXXXX)"
trap 'rm -rf -- "$V8U_F4_TMP"' EXIT

mkdir -p "$EVIDENCE_DIR/baseline"

# Baseline full-core cone audit: warnings outside UNOPTFLAT remain visible in
# the complete log, but no combinational strongly-connected component is
# accepted for this checkpoint.
find "$VSRC" -type f -name '*.v' -print0 | sort -z |
  xargs -0 verilator --lint-only --timing -Wall -Wno-fatal -DOOO_ASSERT \
    -I"$VSRC" -I"$VSRC/include" --top-module NpcCoreTop \
    > "$EVIDENCE_DIR/baseline/verilator.log" 2>&1
if grep -Fq '%Warning-UNOPTFLAT' "$EVIDENCE_DIR/baseline/verilator.log"; then
  echo '[V8U-F4-MUTATION][FAIL] baseline contains UNOPTFLAT' >&2
  exit 1
fi
printf '%s\n' '[V8U-F4-CONE][PASS] baseline NpcCoreTop has no UNOPTFLAT' \
  > "$EVIDENCE_DIR/baseline/result.log"

rows=(
  'backend_next_requires_response_fire|backend|tb_ooo_int_backend|V8U held response keeps B next-head exact|expect_unoptflat'
  'backend_turnover_accepts_partial|backend|tb_ooo_int_backend|V8U partial consume forbids turnover|dynamic'
  'backend_peek_dequeue_without_capture|backend|tb_ooo_int_backend|V8U partial consume withholds IQ pop2 ready|dynamic'
  'bridge_station_query_requires_ready|bridge|tb_ooo_mem_axi_bridge|F4 stalled B station query remains valid|dynamic'
  'bridge_station_lookup_ignores_ready|bridge|tb_ooo_mem_axi_bridge|[V8U-SQ-LOOKAHEAD-READY] station lookup fired without current response advance|dynamic'
  'iq_pair_pop_only_entry0|iq|tb_ooo_int_issue_queue|V8U pair peek atomically drains both entries|dynamic'
  'iq_pair_exposes_regular_issue1|iq|tb_ooo_int_issue_queue|V8U pair peek suppresses regular issue1|dynamic'
)

: > "$EVIDENCE_DIR/mutation-summary.tsv"
for row in "${rows[@]}"; do
  IFS='|' read -r name role test oracle lint_mode <<< "$row"
  mutation_dir="$EVIDENCE_DIR/$name"
  build_dir="$V8U_F4_TMP/build/$name"
  mkdir -p "$mutation_dir"

  case "$role" in
    backend)
      source="$BACKEND"
      mutant="$V8U_F4_TMP/mutants/$name/OooIntBackend.v"
      make_override=(RTL_OOO_INT_BACKEND="$mutant")
      defines='-DOOO_ASSERT -DV8S_DUAL_MEMORY_FOCUSED'
      ;;
    bridge)
      source="$BRIDGE"
      mutant="$V8U_F4_TMP/mutants/$name/OooMemAxiBridge.v"
      make_override=(RTL_OOO_MEM_AXI_BRIDGE="$mutant")
      defines='-DOOO_ASSERT'
      ;;
    iq)
      source="$IQ"
      mutant="$V8U_F4_TMP/mutants/$name/OooIntIssueQueue.v"
      make_override=(RTL_OOO_INT_ISSUE_QUEUE="$SELECTOR $mutant")
      defines='-DOOO_ASSERT'
      ;;
    *)
      echo "[V8U-F4-MUTATION][FAIL] unknown RTL role $role" >&2
      exit 1
      ;;
  esac

  python3 "$MUTATOR" "$name" "$source" "$mutant" \
    --json-out "$mutation_dir/activation.json" \
    > "$mutation_dir/mutator.log" 2>&1

  target="$mutation_dir/logs/$test.log"
  ivflags="-g2012 -Wall -I../vsrc -I../vsrc/include -Icommon $defines"
  set +e
  make -B -C "$TB_HOME" BUILD_DIR="$build_dir" \
    RESULT_DIR="$mutation_dir" IVFLAGS="$ivflags" \
    "${make_override[@]}" "$target" > "$mutation_dir/make.log" 2>&1
  dynamic_rc=$?
  set -e
  if [[ ! -s "$build_dir/$test.vvp" ]]; then
    echo "[V8U-F4-MUTATION][FAIL] $name did not compile/elaborate" >&2
    exit 1
  fi
  if [[ "$dynamic_rc" -eq 0 ]] || ! grep -Fq "$oracle" "$target"; then
    echo "[V8U-F4-MUTATION][FAIL] $name escaped oracle: $oracle" >&2
    exit 1
  fi

  lint_status='not_required'
  if [[ "$lint_mode" == 'expect_unoptflat' ]]; then
    find "$VSRC" -type f -name '*.v' \
      ! -path "$VSRC/execute/OooIntBackend.v" -print0 | sort -z |
      xargs -0 verilator --lint-only --timing -Wall -Wno-fatal \
        -DOOO_ASSERT -I"$VSRC" -I"$VSRC/include" \
        --top-module NpcCoreTop "$mutant" \
        > "$mutation_dir/verilator.log" 2>&1
    if ! grep -Fq '%Warning-UNOPTFLAT' "$mutation_dir/verilator.log"; then
      echo "[V8U-F4-MUTATION][FAIL] $name did not recreate the feedback SCC" >&2
      exit 1
    fi
    lint_status='unoptflat_recreated'
  fi

  printf '%s|%s|compile_success|target_rejected|%s|%s|%s|%s\n' \
    "$name" "$role" "$lint_status" \
    "$(sha256sum "$mutant" | awk '{print $1}')" \
    "$(sha256sum "$build_dir/$test.vvp" | awk '{print $1}')" \
    "$dynamic_rc" >> "$EVIDENCE_DIR/mutation-summary.tsv"
done

if [[ "$(wc -l < "$EVIDENCE_DIR/mutation-summary.tsv")" -ne 7 ]] ||
   [[ "$(grep -c 'target_rejected' "$EVIDENCE_DIR/mutation-summary.tsv")" -ne 7 ]]; then
  echo '[V8U-F4-MUTATION][FAIL] expected seven compile-success dynamic rejections' >&2
  exit 1
fi

printf '%s\n' \
  '[V8U-F4-MUTATION][PASS] compile_success=7 dynamic_rejections=7 feedback_scc_recreated=1 baseline_unoptflat=0' \
  > "$EVIDENCE_DIR/result.log"
cat "$EVIDENCE_DIR/result.log"
