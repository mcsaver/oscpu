#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd -P)
TASK_DIR="$ROOT_DIR/.github/task-runs/2026-07-14-rv64-t3w-retire-static-cache-owner"
RESULT_DIR="$TASK_DIR/evidence/focused"

cd "$ROOT_DIR"
make -C npc/rv64/testbench \
  TESTS='tb_ooo_fetch_static_classify tb_ooo_fetch_head_classify_gate tb_ooo_fetch_head_pair_gate tb_ooo_fetch_packet_fifo tb_ooo_fetch_packet_head_mux tb_ooo_fp_legality_dispatch_path tb_ooo_ifu_lane1_fault_owner tb_ooo_fetch_trap_gate tb_ooo_rob tb_ooo_mem_axi_bridge tb_ooo_alu_decode_backend tb_ooo_dispatch_backend tb_ooo_int_backend tb_ooo_core_top_glue' \
  RESULT_DIR="$RESULT_DIR" run

