#!/usr/bin/env python3
"""Check the drain-gate ABI directly in a synthesized hierarchical netlist."""

from __future__ import annotations

import argparse
import sys
from pathlib import Path


def fail(message: str) -> None:
    print(f"[T3I-NETLIST-STRUCTURE] FAIL: {message}", file=sys.stderr)
    raise SystemExit(1)


def module_blocks(path: Path, needle: str) -> list[str]:
    blocks: list[str] = []
    selected = False
    lines: list[str] = []
    with path.open(encoding="utf-8") as stream:
        for line in stream:
            if line.startswith("module "):
                selected = needle in line
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
    parser.add_argument("--expect", choices=("present", "absent"), required=True)
    parser.add_argument("netlist", type=Path)
    args = parser.parse_args()

    gate_blocks = module_blocks(args.netlist, "OooPendingDrainResolveGate")
    plane_blocks = module_blocks(args.netlist, "OooControlPlane")
    if len(gate_blocks) != 1 or len(plane_blocks) != 1:
        fail(
            f"module counts gate={len(gate_blocks)} control_plane={len(plane_blocks)}"
        )
    gate = gate_blocks[0]
    plane = plane_blocks[0]
    for fragment in (
        "rob_count_i_0_",
        "issue_count_i_0_",
        "synth_lane1_ret_pending_i",
        "synth_lane1_branch_drop_pending_i",
        "mem_retire_quiet_i",
        "backend_drained_o",
    ):
        if fragment not in gate:
            fail(f"drain gate safety ABI missing: {fragment}")
    if "u_pending_drain_resolve_gate" not in plane:
        fail("control plane no longer instantiates the drain gate")

    gate_inputs = sum(
        f"input core_retire_count_i_{bit}_;" in gate for bit in range(2)
    )
    plane_inputs = sum(
        f"input core_retire_count_w_{bit}_;" in plane for bit in range(2)
    )
    gate_connections = sum(
        f".core_retire_count_i_{bit}_(core_retire_count_w_{bit}_)," in plane
        for bit in range(2)
    )
    if args.expect == "present":
        if (gate_inputs, plane_inputs, gate_connections) != (2, 2, 2):
            fail(
                "legacy retire ABI width/connectivity mismatch: "
                f"gate_inputs={gate_inputs} plane_inputs={plane_inputs} "
                f"connections={gate_connections}"
            )
    elif (
        gate_inputs != 0
        or plane_inputs != 0
        or gate_connections != 0
        or "core_retire_count_i" in gate
        or "core_retire_count_w" in plane
        or "core_retire_count_i" in plane
    ):
        fail(
            "retire-count ABI remains in synthesized drain domain: "
            f"gate_inputs={gate_inputs} plane_inputs={plane_inputs} "
            f"connections={gate_connections}"
        )

    print(
        "[T3I-NETLIST-STRUCTURE] PASS: "
        f"expect={args.expect} gate_inputs={gate_inputs} "
        f"plane_inputs={plane_inputs} connections={gate_connections}"
    )


if __name__ == "__main__":
    main()
