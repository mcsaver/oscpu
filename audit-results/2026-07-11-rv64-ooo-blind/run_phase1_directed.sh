#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
OUT="$ROOT/audit-results/2026-07-11-rv64-ooo-blind"
RTL="$ROOT/npc/rv64/vsrc"
mkdir -p "$OUT/build"

iverilog -g2012 -I "$RTL/include" -s tb_miq_full_pop \
  -o "$OUT/build/tb_miq_full_pop" \
  "$OUT/tb_miq_full_pop.v" \
  "$RTL/memory/OooMemInflightQueue.v"
vvp "$OUT/build/tb_miq_full_pop"

iverilog -g2012 -I "$RTL/include" -s tb_miq_flush_drain_pop \
  -o "$OUT/build/tb_miq_flush_drain_pop" \
  "$OUT/tb_miq_flush_drain_pop.v" \
  "$RTL/memory/OooMemInflightQueue.v"
vvp "$OUT/build/tb_miq_flush_drain_pop"

iverilog -g2012 -I "$RTL/include" -I "$RTL/common" \
  -s tb_fetch_page_end_c_fault \
  -o "$OUT/build/tb_fetch_page_end_c_fault" \
  "$OUT/tb_fetch_page_end_c_fault.sv" \
  "$RTL/frontend/OooFetchAxiBridge.v" \
  "$RTL/frontend/OooFetchPacketDecode.v" \
  "$RTL/decode/OooRvcDecompressor.v" \
  "$RTL/cache/OooFetchPacketCache.v" \
  "$RTL/memory/OooSv39Tlb.v" \
  "$RTL/memory/PmpChecker.v" \
  "$RTL/sram/Sram4096x199.v"
vvp "$OUT/build/tb_fetch_page_end_c_fault"

iverilog -g2012 -I "$RTL/include" -I "$RTL/common" \
  -s tb_fetch_ad_flush_partial \
  -o "$OUT/build/tb_fetch_ad_flush_partial" \
  "$OUT/tb_fetch_ad_flush_partial.sv" \
  "$RTL/frontend/OooFetchAxiBridge.v" \
  "$RTL/cache/OooFetchPacketCache.v" \
  "$RTL/memory/OooSv39Tlb.v" \
  "$RTL/memory/PmpChecker.v" \
  "$RTL/sram/Sram4096x199.v"
vvp "$OUT/build/tb_fetch_ad_flush_partial"

iverilog -g2012 -I "$RTL/include" -I "$RTL" \
  -s tb_xret_privilege_classify \
  -o "$OUT/build/tb_xret_privilege_classify" \
  "$OUT/tb_xret_privilege_classify.sv" \
  "$RTL/decode/DecodeUnit.v" \
  "$RTL/decode/OooFpDecode.v" \
  "$RTL/frontend/OooFetchHeadClassifyGate.v"
vvp "$OUT/build/tb_xret_privilege_classify"

iverilog -g2012 -I "$RTL/include" -I "$RTL" \
  -s tb_fp_legality_classify \
  -o "$OUT/build/tb_fp_legality_classify" \
  "$OUT/tb_fp_legality_classify.sv" \
  "$RTL/decode/DecodeUnit.v" \
  "$RTL/decode/OooFpDecode.v" \
  "$RTL/frontend/OooFetchHeadClassifyGate.v" \
  "$RTL/frontend/OooFrontendDispatchGate.v"
vvp "$OUT/build/tb_fp_legality_classify"
