#!/usr/bin/env python3
"""Fail-closed mapped-netlist contract for the T3L branch-target split."""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path


PREFIX = "T3L-NETLIST-STRUCTURE"


def fail(message: str) -> None:
    print(f"[{PREFIX}] FAIL: {message}", file=sys.stderr)
    raise SystemExit(1)


def require_regular(path: Path) -> None:
    if not path.is_file() or path.is_symlink() or path.stat().st_size == 0:
        fail(f"missing, empty, symlink, or non-regular input: {path}")


def identifier_matches(identifier: str, logical_name: str) -> bool:
    if identifier == logical_name:
        return True
    return re.fullmatch(
        rf"\\\$paramod\$[0-9a-f]{{40}}\\{re.escape(logical_name)}",
        identifier,
    ) is not None


def module_blocks(path: Path, logical_name: str) -> list[str]:
    blocks: list[str] = []
    selected = False
    lines: list[str] = []
    with path.open(encoding="utf-8", errors="strict") as stream:
        for line in stream:
            if line.startswith("module "):
                match = re.match(r"^module\s+(?P<name>\\\S+|[^\s(]+)\s*\(", line)
                selected = bool(
                    match and identifier_matches(match.group("name"), logical_name)
                )
                lines = [line] if selected else []
                continue
            if selected:
                lines.append(line)
                if line.startswith("endmodule"):
                    blocks.append("".join(lines))
                    selected = False
                    lines = []
    return blocks


def one_block(path: Path, logical_name: str) -> str:
    blocks = module_blocks(path, logical_name)
    if len(blocks) != 1:
        fail(f"expected exactly one {logical_name} module, got {len(blocks)}")
    return blocks[0]


def declared_bits(block: str, direction: str, stem: str) -> set[int]:
    return {
        int(bit)
        for bit in re.findall(
            rf"^  {direction} {re.escape(stem)}_(\d+)_;$", block, re.MULTILINE
        )
    }


def instance_blocks(block: str, logical_type: str) -> dict[str, str]:
    result: dict[str, str] = {}
    lines = block.splitlines()
    index = 0
    while index < len(lines):
        match = re.fullmatch(r"  (\S+) (\S+) \(", lines[index])
        if match is None or not identifier_matches(match.group(1), logical_type):
            index += 1
            continue
        name = match.group(2)
        if name in result:
            fail(f"duplicate instance name: {logical_type} {name}")
        body = [lines[index]]
        index += 1
        while index < len(lines):
            body.append(lines[index])
            if lines[index] == "  );":
                break
            index += 1
        else:
            fail(f"unterminated instance: {logical_type} {name}")
        result[name] = "\n".join(body) + "\n"
        index += 1
    return result


def connected_bits(instance: str, port_stem: str) -> set[int]:
    return {
        int(bit)
        for bit in re.findall(rf"\.{re.escape(port_stem)}_(\d+)_\(", instance)
    }


def require_bits(actual: set[int], width: int, label: str) -> None:
    expected = set(range(width))
    if actual != expected:
        missing = sorted(expected - actual)
        extra = sorted(actual - expected)
        fail(f"{label} bit contract mismatch: missing={missing} extra={extra}")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--expect", choices=("old", "fresh"), required=True)
    parser.add_argument("--std-lib", type=Path, required=True)
    parser.add_argument("netlist", type=Path)
    args = parser.parse_args()
    require_regular(args.std_lib)
    require_regular(args.netlist)

    decoder = one_block(args.netlist, "OooFetchPacketDecode")
    frontend = one_block(args.netlist, "OooFrontend")
    decoder_instances = instance_blocks(frontend, "OooFetchPacketDecode")
    if set(decoder_instances) != {"u_fetch_packet_decode"}:
        fail(f"frontend decoder instance mismatch: {sorted(decoder_instances)}")
    decoder_instance = decoder_instances["u_fetch_packet_decode"]

    decoder_width = 64 if args.expect == "old" else 13
    for lane in (0, 1):
        stem = f"dec{lane}_bimm_o"
        require_bits(
            declared_bits(decoder, "output", stem),
            decoder_width,
            f"decoder lane{lane} output",
        )
        require_bits(
            connected_bits(decoder_instance, stem),
            decoder_width,
            f"frontend decoder lane{lane} binding",
        )

    target_modules = module_blocks(args.netlist, "OooFetchBranchTarget")
    target_instances = instance_blocks(frontend, "OooFetchBranchTarget")
    if args.expect == "old":
        if target_modules or target_instances:
            fail(
                "old netlist unexpectedly contains branch-target split: "
                f"modules={len(target_modules)} instances={sorted(target_instances)}"
            )
    else:
        if len(target_modules) != 1:
            fail(f"fresh netlist target module count is {len(target_modules)}, expected 1")
        expected_instances = {
            "u_fetch_dec0_branch_target",
            "u_fetch_dec1_branch_target",
        }
        if set(target_instances) != expected_instances:
            fail(
                "fresh frontend target instances mismatch: "
                f"{sorted(target_instances)}"
            )
        target = target_modules[0]
        require_bits(declared_bits(target, "input", "pc_i"), 64, "target pc input")
        require_bits(declared_bits(target, "input", "bimm_i"), 13, "target bimm input")
        require_bits(declared_bits(target, "output", "target_o"), 64, "target output")
        if declared_bits(target, "input", "bimm_i") & set(range(13, 64)):
            fail("fresh target module exposes a sign-extended B-immediate input")
        for name, instance in sorted(target_instances.items()):
            require_bits(connected_bits(instance, "pc_i"), 64, f"{name} pc binding")
            require_bits(connected_bits(instance, "bimm_i"), 13, f"{name} bimm binding")
            require_bits(connected_bits(instance, "target_o"), 64, f"{name} target binding")

    print(
        f"[{PREFIX}] PASS expect={args.expect} "
        f"decoder_bimm_width={decoder_width} "
        f"target_modules={len(target_modules)} "
        f"target_instances={len(target_instances)}"
    )


if __name__ == "__main__":
    main()
