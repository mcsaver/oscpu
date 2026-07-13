#!/usr/bin/env python3
"""Check the T3J semantic-accept/physical-read ABI in a hierarchical netlist."""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path


def fail(message: str) -> None:
    print(f"[T3J-NETLIST-STRUCTURE] FAIL: {message}", file=sys.stderr)
    raise SystemExit(1)


def module_blocks(path: Path, exact_name: str) -> list[str]:
    blocks: list[str] = []
    selected = False
    lines: list[str] = []
    prefix = f"module {exact_name}("
    with path.open(encoding="utf-8") as stream:
        for line in stream:
            if line.startswith("module "):
                selected = line.startswith(prefix)
                lines = [line] if selected else []
                continue
            if selected:
                lines.append(line)
                if line.startswith("endmodule"):
                    blocks.append("".join(lines))
                    selected = False
                    lines = []
    return blocks


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--expect", choices=("old", "fresh"), required=True)
    parser.add_argument("netlist", type=Path)
    args = parser.parse_args()
    if not args.netlist.is_file() or args.netlist.stat().st_size == 0:
        fail(f"missing or empty netlist: {args.netlist}")

    bridge_blocks = module_blocks(args.netlist, "OooFetchAxiBridge")
    fpc_blocks = module_blocks(args.netlist, "OooFetchPacketCache")
    if len(bridge_blocks) != 1 or len(fpc_blocks) != 1:
        fail(f"module counts bridge={len(bridge_blocks)} fpc={len(fpc_blocks)}")
    bridge = bridge_blocks[0]
    fpc = fpc_blocks[0]

    if bridge.count("OooFetchPacketCache u_fetch_packet_cache (") != 1:
        fail("bridge does not contain exactly one FPC instance")
    if fpc.count("Sram4096x199 u_payload_sram (") != 1:
        fail("FPC does not contain exactly one payload SRAM instance")
    if fpc.count("input lookup_en_i;") != 1:
        fail("FPC semantic accept port count drifted")
    if bridge.count(".lookup_en_i(fetch_req_fire_w),") != 1:
        fail("FPC semantic accept is no longer bound exactly to bridge fetch_req_fire_w")
    if fpc.count(".en_i(sram_en_w),") != 1:
        fail("payload SRAM enable is no longer bound to the FPC enable net")

    read_inputs = fpc.count("input lookup_read_en_i;")
    read_connections = re.findall(r"\.lookup_read_en_i\(([^)]+)\),", bridge)
    if args.expect == "old":
        if (
            read_inputs != 0
            or read_connections
            or "lookup_read_en_i" in fpc
            or "lookup_read_en_i" in bridge
        ):
            fail(
                "old netlist unexpectedly contains the physical read-window ABI: "
                f"inputs={read_inputs} connections={read_connections}"
            )
    else:
        if read_inputs != 1 or len(read_connections) != 1:
            fail(
                "fresh physical read-window ABI width/connectivity mismatch: "
                f"inputs={read_inputs} connections={read_connections}"
            )
        read_driver = read_connections[0]
        if read_driver != "fetch_cache_read_window_w":
            fail(f"fresh read-window driver drifted: {read_driver}")
        if read_driver == "fetch_req_fire_w":
            fail("physical read-window aliases the semantic accept/fire net")
        if fpc.count("wire lookup_read_en_i;") != 1:
            fail("fresh physical read-window port lacks its unique wire declaration")

    print(
        "[T3J-NETLIST-STRUCTURE] PASS: "
        f"expect={args.expect} read_inputs={read_inputs} "
        f"read_connections={len(read_connections)} semantic_accept=fetch_req_fire_w"
    )


if __name__ == "__main__":
    main()
