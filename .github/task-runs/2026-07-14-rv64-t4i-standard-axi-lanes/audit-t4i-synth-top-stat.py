#!/usr/bin/env python3
"""Extract the NpcTop area row without confusing it with a child module."""

from __future__ import annotations

import argparse
import json
import re
from pathlib import Path


def fail(message: str) -> None:
    raise SystemExit(f"[T4I-SYNTH-TOP-STAT] FAIL: {message}")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("synth_stat", type=Path)
    parser.add_argument("--synth-audit", type=Path, required=True)
    parser.add_argument("--json-out", type=Path, required=True)
    args = parser.parse_args()
    for path in (args.synth_stat, args.synth_audit):
        if not path.is_file() or path.is_symlink() or path.stat().st_size == 0:
            fail(f"invalid input: {path}")
    pattern = re.compile(
        r"Chip area for top module '\\NpcTop':\s*([0-9.]+)\n"
        r"\s*of which used for sequential elements:\s*([0-9.]+)\s*\(([0-9.]+)%\)"
    )
    matches = pattern.findall(args.synth_stat.read_text())
    if len(matches) != 1:
        fail(f"NpcTop area row cardinality={len(matches)}, expected 1")
    area, sequential, percent = map(float, matches[0])
    audit = json.loads(args.synth_audit.read_text())
    if float(audit.get("area", -1.0)) != area:
        fail("canonical synth audit top area disagrees with raw NpcTop row")
    result = {
        "schema": "t4i-synth-top-stat-v1",
        "top": "NpcTop",
        "area": area,
        "sequential_area": sequential,
        "sequential_percent": percent,
        "canonical_audit_area_match": True,
        "canonical_audit_sequential_fields_are_child_module_and_must_not_be_used": True,
    }
    args.json_out.parent.mkdir(parents=True, exist_ok=True)
    args.json_out.write_text(json.dumps(result, indent=2, sort_keys=True) + "\n")
    print(
        f"[T4I-SYNTH-TOP-STAT] PASS: area={area:.2f} "
        f"sequential={sequential:.2f} ({percent:.2f}%)"
    )


if __name__ == "__main__":
    main()
