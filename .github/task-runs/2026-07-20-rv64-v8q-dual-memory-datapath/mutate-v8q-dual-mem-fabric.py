#!/usr/bin/env python3
"""Create exactly one compile-success semantic mutant of the F0 arbiter."""

from __future__ import annotations

import argparse
import hashlib
import json
import pathlib


MUTATIONS: dict[str, tuple[str, str, int, str]] = {
    "read_release_on_ar": (
        "if (ar_fire_w)\n            state_q <= S_READ_RESP;",
        "if (ar_fire_w)\n            state_q <= S_IDLE;",
        1,
        "V8Q-MUT-READ-RELEASE-ON-AR",
    ),
    "write_release_on_aw": (
        "if (aw_fire_w)\n            aw_seen_q <= 1'b1;",
        "if (aw_fire_w) begin\n            aw_seen_q <= 1'b1;\n"
        "            state_q <= S_IDLE;\n          end",
        1,
        "V8Q-MUT-WRITE-RELEASE-ON-AW",
    ),
    "write_release_on_w": (
        "if (w_fire_w)\n            w_seen_q <= 1'b1;",
        "if (w_fire_w) begin\n            w_seen_q <= 1'b1;\n"
        "            state_q <= S_IDLE;\n          end",
        1,
        "V8Q-MUT-WRITE-RELEASE-ON-W",
    ),
    "aw_seen_tieoff": (
        "wire aw_seen_next_w = aw_seen_q || aw_fire_w;",
        "wire aw_seen_next_w = 1'b0;",
        1,
        "V8Q-MUT-AW-SEEN-TIEOFF",
    ),
    "w_seen_tieoff": (
        "wire w_seen_next_w = w_seen_q || w_fire_w;",
        "wire w_seen_next_w = 1'b0;",
        1,
        "V8Q-MUT-W-SEEN-TIEOFF",
    ),
    "broadcast_rvalid": (
        "lane1_axi_rvalid_o = d_axi_rvalid_i;",
        "lane1_axi_rvalid_o = d_axi_rvalid_i;\n"
        "            lane0_axi_rvalid_o = d_axi_rvalid_i;",
        1,
        "V8Q-MUT-BROADCAST-RVALID",
    ),
    "swap_rready": (
        "d_axi_rready_o = owner_q ? lane1_axi_rready_i :\n"
        "                                         lane0_axi_rready_i;",
        "d_axi_rready_o = owner_q ? lane0_axi_rready_i :\n"
        "                                         lane1_axi_rready_i;",
        1,
        "V8Q-MUT-SWAP-RREADY",
    ),
    "broadcast_bvalid": (
        "lane1_axi_bvalid_o = d_axi_bvalid_i;",
        "lane1_axi_bvalid_o = d_axi_bvalid_i;\n"
        "            lane0_axi_bvalid_o = d_axi_bvalid_i;",
        1,
        "V8Q-MUT-BROADCAST-BVALID",
    ),
    "fixed_lane0_priority": (
        "wire capture_owner_w = lane0_request_w && lane1_request_w ? rr_q :",
        "wire capture_owner_w = lane0_request_w && lane1_request_w ? 1'b0 :",
        1,
        "V8Q-MUT-FIXED-LANE0-PRIORITY",
    ),
    "rr_update_on_capture": (
        "owner_q <= capture_owner_w;\n            is_write_q <= capture_write_w;",
        "owner_q <= capture_owner_w;\n            is_write_q <= capture_write_w;\n"
        "            rr_q <= ~capture_owner_w;",
        1,
        "V8Q-MUT-RR-UPDATE-ON-CAPTURE",
    ),
    "idle_fallthrough": (
        "default: begin\n          // S_IDLE and illegal encodings are externally quiet.\n"
        "        end",
        "default: begin\n          d_axi_arvalid_o = lane0_axi_arvalid_i;\n"
        "          d_axi_araddr_o = lane0_axi_araddr_i;\n"
        "          lane0_axi_arready_o = d_axi_arready_i;\n        end",
        1,
        "V8Q-MUT-IDLE-FALLTHROUGH",
    ),
    "reset_owner_residue": (
        "state_q <= S_IDLE;\n      owner_q <= 1'b0;\n      is_write_q <= 1'b0;",
        "state_q <= S_IDLE;\n      owner_q <= 1'b1;\n      is_write_q <= 1'b0;",
        1,
        "V8Q-MUT-RESET-OWNER-RESIDUE",
    ),
}


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("mutation", choices=sorted(MUTATIONS))
    parser.add_argument("source", type=pathlib.Path)
    parser.add_argument("output", type=pathlib.Path)
    args = parser.parse_args()

    source = args.source.resolve(strict=True)
    text = source.read_text(encoding="utf-8")
    old, new, expected_count, marker = MUTATIONS[args.mutation]
    actual_count = text.count(old)
    if actual_count != expected_count:
        raise SystemExit(
            f"fail-closed anchor count for {args.mutation}: "
            f"expected={expected_count} actual={actual_count}"
        )
    mutated = text.replace(old, new, 1)
    if mutated == text:
        raise SystemExit(f"mutation did not change source: {args.mutation}")
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(mutated, encoding="utf-8")
    print(json.dumps({
        "mutation": args.mutation,
        "anchor_count": actual_count,
        "activation": f"V8Q-MUT-ACTIVE:{args.mutation}",
        "expected_rejection": marker,
        "source_sha256": hashlib.sha256(text.encode()).hexdigest(),
        "mutant_sha256": hashlib.sha256(mutated.encode()).hexdigest(),
    }, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
