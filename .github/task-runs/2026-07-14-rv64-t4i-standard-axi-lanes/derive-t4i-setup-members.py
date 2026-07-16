#!/usr/bin/env python3
"""Derive the reviewed T4I setup closure from frozen T4D plus AWSIZE ports."""

from __future__ import annotations

import argparse
import hashlib
import json
import re
from pathlib import Path


BASE_COUNTS = (303, 1861, 1863)
TARGET_COUNTS = (303, 1873, 1875)
CLASSES = (
    ("missing_input_delay", "input ports missing set_input_delay"),
    ("missing_output_delay", "output ports missing set_output_delay"),
    ("unconstrained_endpoints", "unconstrained endpoints"),
)
AWSIZE_OUTPUTS = sorted(
    f"{slave}_axi_awsize_o_{bit}_"
    for slave in ("psram", "sdram", "legacy_mmio", "virtio_blk")
    for bit in range(3)
)
REPO_ROOT = Path(__file__).resolve().parents[3]


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    digest.update(path.read_bytes())
    return digest.hexdigest()


def parse_setup(path: Path) -> dict[str, dict[str, object]]:
    lines = path.read_text().splitlines()
    cursor = 0
    result: dict[str, dict[str, object]] = {}
    for (key, label), count in zip(CLASSES, BASE_COUNTS, strict=True):
        match = re.fullmatch(r"Warning: There are (\d+) (.+)\.", lines[cursor])
        if match is None or (int(match.group(1)), match.group(2)) != (count, label):
            raise SystemExit(f"unexpected frozen T4D class at line {cursor + 1}")
        cursor += 1
        members = []
        for line in lines[cursor : cursor + count]:
            if not line.startswith("  ") or line[2:] != line[2:].strip():
                raise SystemExit(f"malformed frozen member: {line!r}")
            members.append(line[2:])
        if len(members) != len(set(members)):
            raise SystemExit(f"duplicate frozen member in {key}")
        result[key] = {"label": label, "members": sorted(members)}
        cursor += count
    if cursor != len(lines):
        raise SystemExit("unexpected trailing setup diagnostics in frozen T4D evidence")
    return result


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("base_setup", type=Path)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    base = args.base_setup.resolve()
    if not base.is_file() or base.is_symlink():
        raise SystemExit(f"invalid base setup evidence: {base}")
    if args.output.exists():
        raise SystemExit(f"refusing existing output: {args.output}")
    classes = parse_setup(base)
    additions = {
        "missing_input_delay": [],
        "missing_output_delay": AWSIZE_OUTPUTS,
        "unconstrained_endpoints": AWSIZE_OUTPUTS,
    }
    for (key, _), target_count in zip(CLASSES, TARGET_COUNTS, strict=True):
        members = classes[key]["members"]
        assert isinstance(members, list)
        overlap = set(members) & set(additions[key])
        if overlap:
            raise SystemExit(f"AWSIZE delta already existed in T4D {key}: {sorted(overlap)}")
        merged = sorted(members + additions[key])
        if len(merged) != target_count or len(merged) != len(set(merged)):
            raise SystemExit(f"bad derived member count for {key}: {len(merged)}")
        classes[key]["members"] = merged
    result = {
        "schema": "t4i-opensta-setup-members-v1",
        "derivation": "frozen T4D exact members plus four 3-bit top-level AWSIZE outputs",
        "base_setup": str(base.relative_to(REPO_ROOT)),
        "base_setup_sha256": sha256(base),
        "additions": additions,
        "classes": classes,
    }
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(result, indent=2, sort_keys=True) + "\n")
    print(
        "[T4I-SETUP-MEMBERS] PASS: "
        + " ".join(
            f"{key}={len(classes[key]['members'])}" for key, _ in CLASSES
        )
    )


if __name__ == "__main__":
    main()
