#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd -P)
TASK_DIR="$ROOT_DIR/.github/task-runs/2026-07-14-rv64-t3z-fetch-context-owner"
OUT_DIR="$TASK_DIR/evidence/temporal-negative-v1"
WORK_DIR="$ROOT_DIR/tmp/2026-07-14-rv64-t3z-temporal-negative"
TB_DIR="$ROOT_DIR/npc/rv64/testbench"
VSRCDIR="$ROOT_DIR/npc/rv64/vsrc"

mkdir -p "$OUT_DIR/logs" "$WORK_DIR"

compile_bridge() {
  local bridge_src=$1
  local image=$2
  iverilog -g2012 -Wall \
    -I"$VSRCDIR" -I"$VSRCDIR/include" -I"$TB_DIR/common" \
    -DOOO_ASSERT -s tb_ooo_fetch_axi_bridge -o "$image" \
    "$VSRCDIR/memory/PmpChecker.v" \
    "$VSRCDIR/cache/OooFetchPacketCache.v" \
    "$VSRCDIR/sram/Sram4096x199.v" \
    "$VSRCDIR/memory/OooSv39Tlb.v" \
    "$bridge_src" \
    "$TB_DIR/tests/tb_ooo_fetch_axi_bridge.sv"
}

run_expect_marker() {
  local image=$1
  local marker=$2
  local log=$3
  set +e
  vvp "$image" >"$log" 2>&1
  local sim_rc=$?
  set -e
  if ! grep -Fq "$marker" "$log"; then
    echo "missing expected marker $marker (sim_rc=$sim_rc)" >&2
    return 1
  fi
}

BRIDGE_SRC="$VSRCDIR/frontend/OooFetchAxiBridge.v"

# Mutation 1: fire no longer swaps the selector.  Functional data alone can
# occasionally alias, so the independent selector/candidate shadow must fire.
MISSING_SWAP="$WORK_DIR/OooFetchAxiBridge-missing-swap.v"
cp "$BRIDGE_SRC" "$MISSING_SWAP"
perl -0pi -e \
  's/fetch_ctx_sel_q <= ~fetch_ctx_sel_q;/\/\* temporal mutation: toggle removed \*\//' \
  "$MISSING_SWAP"
compile_bridge "$MISSING_SWAP" "$WORK_DIR/missing-swap.vvp" \
  >"$OUT_DIR/logs/missing-swap-compile.log" 2>&1
run_expect_marker "$WORK_DIR/missing-swap.vvp" \
  "[T3Z-CTX-FIRE-SWAP]" "$OUT_DIR/logs/missing-swap.log"

# Mutation 2: write the active bank instead of the inactive bank.  The first
# accepted request must be rejected by the same independent swap shadow.
WRONG_BANK="$WORK_DIR/OooFetchAxiBridge-wrong-bank.v"
cp "$BRIDGE_SRC" "$WRONG_BANK"
perl -0pi -e \
  's/if \(fetch_ctx_sel_q\) begin/if (!fetch_ctx_sel_q) begin/' \
  "$WRONG_BANK"
compile_bridge "$WRONG_BANK" "$WORK_DIR/wrong-bank.vvp" \
  >"$OUT_DIR/logs/wrong-bank-compile.log" 2>&1
run_expect_marker "$WORK_DIR/wrong-bank.vvp" \
  "[T3Z-CTX-FIRE-SWAP]" "$OUT_DIR/logs/wrong-bank.log"

# Mutation 3: special prefetch adoption presents a PC different from the
# Bridge active owner.  This proves the rare-path theorem is not a tie-off-only
# assertion even though production currently disables the prefetch source.
SPECIAL_TB="$WORK_DIR/tb_ooo_fetch_pc_outstanding_sequencer-owner-mismatch.sv"
cp "$TB_DIR/tests/tb_ooo_fetch_pc_outstanding_sequencer.sv" "$SPECIAL_TB"
perl -0pi -e \
  "s/fetch_req_owner_pc = branch_prefetch_pc;/fetch_req_owner_pc = branch_prefetch_pc ^ 64'h4;/" \
  "$SPECIAL_TB"
iverilog -g2012 -Wall \
  -I"$VSRCDIR" -I"$VSRCDIR/include" -I"$TB_DIR/common" \
  -DOOO_ASSERT -s tb_ooo_fetch_pc_outstanding_sequencer \
  -o "$WORK_DIR/special-owner-mismatch.vvp" \
  "$VSRCDIR/frontend/OooFetchPcOutstandingSequencer.v" "$SPECIAL_TB" \
  >"$OUT_DIR/logs/special-owner-mismatch-compile.log" 2>&1
run_expect_marker "$WORK_DIR/special-owner-mismatch.vvp" \
  "[T3Z-SPECIAL-OWNER-PC]" "$OUT_DIR/logs/special-owner-mismatch.log"

{
  echo "status=PASS"
  echo "missing_selector_swap=REJECTED:[T3Z-CTX-FIRE-SWAP]"
  echo "wrong_bank_write=REJECTED:[T3Z-CTX-FIRE-SWAP]"
  echo "special_owner_mismatch=REJECTED:[T3Z-SPECIAL-OWNER-PC]"
} >"$OUT_DIR/summary.txt"

echo "[T3Z-TEMPORAL-NEGATIVE] PASS"
