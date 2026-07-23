#!/usr/bin/env python3
"""Create one compile-success semantic mutant for the v8r/F1 leaf."""

from __future__ import annotations

import argparse
import hashlib
import json
import pathlib


WRAPPER = "npc/rv64/vsrc/memory/OooDualMemBridgeWrapper.v"
BRIDGE = "npc/rv64/vsrc/memory/OooMemAxiBridge.v"
DCACHE = "npc/rv64/vsrc/cache/OooDataWordCache.v"

MUTATIONS: dict[str, tuple[str, str, str, int, str]] = {
    "disconnect_peer_valid": (
        WRAPPER,
        ".peer_invalidate_valid_i(lane0_peer_maintenance_valid_w),",
        ".peer_invalidate_valid_i(1'b0),",
        1,
        "V8R-MUT-DISCONNECT-PEER-VALID",
    ),
    "self_only_peer": (
        WRAPPER,
        ".peer_invalidate_valid_i(lane0_peer_maintenance_valid_w),",
        ".peer_invalidate_valid_i(lane1_peer_maintenance_valid_w),",
        1,
        "V8R-MUT-SELF-ONLY-PEER",
    ),
    "swap_peer_addr": (
        WRAPPER,
        ".peer_invalidate_addr_i(lane0_peer_maintenance_addr_w),",
        ".peer_invalidate_addr_i(lane1_peer_maintenance_addr_w),",
        1,
        "V8R-MUT-SWAP-PEER-ADDR",
    ),
    "request_time_maintenance": (
        BRIDGE,
        "assign peer_maintenance_valid_o = dcache_store_commit_w;\n"
        "  assign peer_maintenance_addr_o = dcache_store_addr_w;\n"
        "  assign peer_maintenance_wstrb_o = dcache_store_wstrb_w;",
        "assign peer_maintenance_valid_o = mem0_req_fire_w && mem0_req_write_i;\n"
        "  assign peer_maintenance_addr_o = mem0_req_addr_i;\n"
        "  assign peer_maintenance_wstrb_o = mem0_req_wstrb_i;",
        1,
        "V8R-MUT-REQUEST-TIME-MAINTENANCE",
    ),
    "b_ok_only_peer": (
        BRIDGE,
        "assign peer_maintenance_valid_o = dcache_store_commit_w;",
        "assign peer_maintenance_valid_o = dcache_store_commit_w &&\n"
        "      (lsu_axi_bresp_i == 2'b00);",
        1,
        "V8R-MUT-B-OK-ONLY-PEER",
    ),
    "drop_cross_line_peer": (
        DCACHE,
        "if (peer_cross_w)\n          valid_q[peer_idx1_w] <= 1'b0;",
        "if (peer_cross_w)\n          valid_q[peer_idx1_w] <= 1'b1;",
        1,
        "V8R-MUT-DROP-CROSS-LINE-PEER",
    ),
    "remove_same_cycle_hit_block": (
        DCACHE,
        "!dma_invalidate_all_i && !peer_lookup_conflict_w;",
        "!dma_invalidate_all_i;",
        1,
        "V8R-MUT-REMOVE-SAME-CYCLE-HIT-BLOCK",
    ),
    "fill_wins_peer": (
        DCACHE,
        "if (peer_invalidate_apply_w) begin\n"
        "        valid_q[peer_idx0_w] <= 1'b0;\n"
        "        if (peer_cross_w)\n"
        "          valid_q[peer_idx1_w] <= 1'b0;\n"
        "      end",
        "if (peer_invalidate_apply_w) begin\n"
        "        valid_q[peer_idx0_w] <= 1'b0;\n"
        "        if (peer_cross_w)\n"
        "          valid_q[peer_idx1_w] <= 1'b0;\n"
        "      end\n"
        "      if (fill_we_w)\n"
        "        valid_q[fill_idx_w] <= 1'b1;",
        1,
        "V8R-MUT-FILL-WINS-PEER",
    ),
    "gate_lane1_ready_on_arbiter_idle": (
        WRAPPER,
        "assign lane1_req_ready_o = lane1_req_ready_w;",
        "assign lane1_req_ready_o = lane1_req_ready_w &&\n"
        "      (u_miss_arbiter.state_q == 3'd0);",
        1,
        "V8R-MUT-GATE-LANE1-READY",
    ),
    "merge_dual_response": (
        WRAPPER,
        "assign lane1_rsp_valid_o = lane1_rsp_valid_w;",
        "assign lane1_rsp_valid_o = lane1_rsp_valid_w &&\n"
        "      !lane0_rsp_valid_w;",
        1,
        "V8R-MUT-MERGE-DUAL-RESPONSE",
    ),
}


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("mutation", choices=sorted(MUTATIONS))
    parser.add_argument("repo_root", type=pathlib.Path)
    parser.add_argument("output", type=pathlib.Path)
    args = parser.parse_args()

    repo_root = args.repo_root.resolve(strict=True)
    target, old, new, expected_count, marker = MUTATIONS[args.mutation]
    source = (repo_root / target).resolve(strict=True)
    try:
        source.relative_to(repo_root)
    except ValueError as exc:
        raise SystemExit(f"target escaped repository: {source}") from exc
    text = source.read_text(encoding="utf-8")
    actual_count = text.count(old)
    if actual_count != expected_count:
        raise SystemExit(
            f"fail-closed anchor count for {args.mutation}: "
            f"expected={expected_count} actual={actual_count} target={target}"
        )
    mutated = text.replace(old, new, 1)
    if mutated == text:
        raise SystemExit(f"mutation did not change source: {args.mutation}")
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(mutated, encoding="utf-8")
    print(json.dumps({
        "mutation": args.mutation,
        "target": target,
        "anchor_count": actual_count,
        "activation": f"V8R-MUT-ACTIVE:{args.mutation}",
        "expected_rejection": marker,
        "source_sha256": hashlib.sha256(text.encode()).hexdigest(),
        "mutant_sha256": hashlib.sha256(mutated.encode()).hexdigest(),
    }, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
