#!/usr/bin/env python3
"""Normalize one independent OpenSTA setup probe into an exact member manifest."""

from __future__ import annotations

import argparse
import hashlib
import json
import re
from pathlib import Path


CLASSES = (
    ("missing_input_delay", "input ports missing set_input_delay"),
    ("missing_output_delay", "output ports missing set_output_delay"),
    ("unconstrained_endpoints", "unconstrained endpoints"),
)


def fail(message: str) -> None:
    raise SystemExit(f"[T4Q-SETUP-MEMBERS] FAIL: {message}")


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    digest.update(path.read_bytes())
    return digest.hexdigest()


def parse_setup(text: str) -> dict[str, dict[str, object]]:
    lines = text.splitlines()
    cursor = 0
    result: dict[str, dict[str, object]] = {}
    for key, label in CLASSES:
        if cursor >= len(lines):
            fail(f"setup probe ended before {label}")
        match = re.fullmatch(r"Warning: There are ([1-9][0-9]*) (.+)\.", lines[cursor])
        if match is None or match.group(2) != label:
            fail(f"malformed/out-of-order setup warning: {lines[cursor]!r}")
        count = int(match.group(1))
        cursor += 1
        raw_members = lines[cursor : cursor + count]
        if len(raw_members) != count:
            fail(f"truncated setup member list: {label}")
        members: list[str] = []
        for member in raw_members:
            if not member.startswith("  ") or member[2:] != member[2:].strip():
                fail(f"malformed setup member: {member!r}")
            members.append(member[2:])
        if len(members) != len(set(members)):
            fail(f"duplicate setup member: {label}")
        result[key] = {"label": label, "count": count, "members": sorted(members)}
        cursor += count
    if cursor != len(lines):
        fail(f"unexpected fourth warning/trailing diagnostic: {lines[cursor]!r}")
    return result


def parse_npc_top_scalar_ports(text: str) -> dict[str, set[str]]:
    starts = [match.start() for match in re.finditer(r"^module NpcTop\(", text, re.MULTILINE)]
    if len(starts) != 1:
        fail(f"NpcTop module cardinality={len(starts)}, expected 1")
    end = text.find("\nendmodule", starts[0])
    if end < 0:
        fail("NpcTop module lacks endmodule")
    body = text[starts[0] : end]
    result: dict[str, set[str]] = {}
    for direction in ("input", "output"):
        names = set(re.findall(rf"^\s{{2}}{direction} ([A-Za-z_][A-Za-z0-9_$]*);$", body, re.MULTILINE))
        if not names:
            fail(f"NpcTop has no scalar {direction} declarations")
        result[direction] = names
    return result


def validate_port_relationships(classes: dict[str, dict[str, object]], ports: dict[str, set[str]]) -> None:
    missing_inputs = set(classes["missing_input_delay"]["members"])
    expected_inputs = ports["input"] - {"clk"}
    if missing_inputs != expected_inputs:
        fail(
            "missing-input members disagree with NpcTop scalar inputs minus clk: "
            f"missing={sorted(expected_inputs - missing_inputs)[:4]} "
            f"extra={sorted(missing_inputs - expected_inputs)[:4]}"
        )
    missing_outputs = set(classes["missing_output_delay"]["members"])
    if not missing_outputs <= ports["output"]:
        fail(
            "missing-output members outside NpcTop scalar outputs: "
            f"{sorted(missing_outputs - ports['output'])[:4]}"
        )
    unconstrained = set(classes["unconstrained_endpoints"]["members"])
    if not missing_outputs <= unconstrained:
        fail(
            "unconstrained endpoints do not contain every missing-output member: "
            f"{sorted(missing_outputs - unconstrained)[:4]}"
        )


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("setup_probe", type=Path)
    parser.add_argument("--netlist", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    for path in (args.setup_probe, args.netlist):
        if not path.is_file() or path.is_symlink() or path.stat().st_size == 0:
            fail(f"invalid input: {path}")
    if args.output.exists():
        fail(f"refusing existing output: {args.output}")
    classes = parse_setup(args.setup_probe.read_text())
    ports = parse_npc_top_scalar_ports(args.netlist.read_text())
    validate_port_relationships(classes, ports)
    result = {
        "schema": "t4q-opensta-setup-members-v1",
        "derivation": "independent frozen OpenSTA setup probe plus NpcTop port cross-check",
        "setup_probe_sha256": sha256(args.setup_probe),
        "netlist": str(args.netlist.resolve()),
        "netlist_sha256": sha256(args.netlist),
        "port_counts": {key: len(value) for key, value in ports.items()},
        "classes": classes,
    }
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(result, indent=2, sort_keys=True) + "\n")
    print(
        "[T4Q-SETUP-MEMBERS] PASS: "
        + " ".join(f"{key}={value['count']}" for key, value in classes.items())
    )


if __name__ == "__main__":
    main()
