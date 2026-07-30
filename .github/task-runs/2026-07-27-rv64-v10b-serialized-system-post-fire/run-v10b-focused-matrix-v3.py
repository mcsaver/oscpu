#!/usr/bin/env python3
"""V10B v3 matrix with complete RTL and testbench identity binding."""

from __future__ import annotations

import dataclasses
import importlib.util
import sys
from pathlib import Path


RUN_DIR = Path(__file__).resolve().parent
BASE = RUN_DIR / "run-v10b-focused-matrix.py"
SPEC = importlib.util.spec_from_file_location("v10b_matrix_base_v3", BASE)
if SPEC is None or SPEC.loader is None:
    raise SystemExit(f"cannot load matrix base: {BASE}")
MATRIX = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = MATRIX
SPEC.loader.exec_module(MATRIX)

MATRIX.OUT = RUN_DIR / "evidence/v10b-focused-matrix-v3"
MATRIX.SUMMARY = MATRIX.OUT / "summary.json"
MATRIX.STATUS = MATRIX.OUT / "status.json"
MATRIX.SCHEMA = "rv64-v10b-focused-matrix-v3"
MATRIX.MATRIX_TITLE = "V10B focused matrix v3"

mutations = []
for mutation in MATRIX.MUTATIONS:
    if mutation.name == "remove-fence-mem-idle":
        mutation = dataclasses.replace(
            mutation,
            test="tb_ooo_pending_drain_resolve_gate",
        )
    mutations.append(mutation)

mutations.append(
    MATRIX.Mutation(
        "disconnect-fencei-fetch-cache-clear",
        "frontend/OooFetchAxiBridge.v",
        "RTL_OOO_FETCH_AXI_BRIDGE",
        "OooFetchPacketCache u_fetch_packet_cache (\n"
        "    .clk(clk),\n"
        "    .rst(rst),\n"
        "    .clear_i(mmu_flush_i),",
        "OooFetchPacketCache u_fetch_packet_cache (\n"
        "    .clk(clk),\n"
        "    .rst(rst),\n"
        "    .clear_i(1'b0),",
        "tb_ooo_fetch_axi_bridge",
    )
)
MATRIX.MUTATIONS = tuple(mutations)


if __name__ == "__main__":
    raise SystemExit(MATRIX.main())
