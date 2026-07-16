#!/usr/bin/env python3
"""Run the frozen T3P synthesis audit and repair its top-stat extraction.

The historical auditor deliberately remains frozen. This wrapper preserves all
of its provenance/netlist checks, then replaces the child-first sequential-area
match with a strict, unique ``NpcTop`` row parser.
"""

from __future__ import annotations

import argparse
import json
import math
import re
import subprocess
import sys
import tempfile
from pathlib import Path


TASK_RUNS = Path(__file__).resolve().parents[1]
BASE_AUDIT = TASK_RUNS / "2026-07-13-rv64-t3p-lane1-simple-owner" / "audit-t3p-synthesis.py"
PERCENT_TOLERANCE = 0.0051
NUMBER = r"(?:0|[1-9][0-9]*)(?:\.[0-9]+)?"
TOP_PATTERN = re.compile(
    rf"^\s*Chip area for top module '\\NpcTop':\s*({NUMBER})\s*$\n"
    rf"^\s*of which used for sequential elements:\s*({NUMBER})\s*"
    rf"\(({NUMBER})%\)\s*$",
    re.MULTILINE,
)


def fail(message: str) -> None:
    raise SystemExit(f"[T4Q-SYNTH-AUDIT] FAIL: {message}")


def parse_npc_top_stat(text: str) -> dict[str, float]:
    matches = TOP_PATTERN.findall(text)
    if len(matches) != 1:
        fail(f"NpcTop area row cardinality={len(matches)}, expected 1")
    area, sequential, reported_percent = map(float, matches[0])
    if not all(math.isfinite(value) for value in (area, sequential, reported_percent)):
        fail("NpcTop area fields must be finite")
    if area <= 0.0:
        fail(f"NpcTop area must be positive, got {area}")
    if sequential < 0.0 or sequential > area:
        fail(f"NpcTop sequential area {sequential} is outside [0, {area}]")
    derived_percent = 100.0 * sequential / area
    if abs(derived_percent - reported_percent) > PERCENT_TOLERANCE:
        fail(
            "NpcTop sequential percent mismatch: "
            f"reported={reported_percent:.6f} derived={derived_percent:.6f}"
        )
    return {
        "area": area,
        "sequential_area": sequential,
        "sequential_percent": reported_percent,
        "sequential_percent_derived": derived_percent,
    }


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("tmp_dir", type=Path)
    parser.add_argument("--json-out", type=Path, required=True)
    parser.add_argument("--prefix", default="T4Q-SYNTH-AUDIT")
    parser.add_argument("--expected-rtl-count", type=int, default=115)
    parser.add_argument("--expected-evidence-count", type=int, default=7)
    parser.add_argument("--expected-module-count", type=int, default=117)
    parser.add_argument("--required-pipestage-width", type=int, action="append")
    parser.add_argument("--previous-netlist", type=Path, required=True)
    args = parser.parse_args()
    if args.json_out.exists():
        fail(f"refusing existing output: {args.json_out}")
    if not BASE_AUDIT.is_file() or BASE_AUDIT.is_symlink():
        fail(f"invalid frozen base auditor: {BASE_AUDIT}")
    tmp_dir = args.tmp_dir.resolve()
    synth_stat = tmp_dir / "sta-build/NpcTop-200MHz/synth_stat.txt"
    if not synth_stat.is_file() or synth_stat.is_symlink() or synth_stat.stat().st_size == 0:
        fail(f"invalid synth_stat: {synth_stat}")

    with tempfile.TemporaryDirectory(prefix="t4q-synth-audit-") as temporary:
        base_json = Path(temporary) / "base.json"
        command = [
            sys.executable, str(BASE_AUDIT), str(tmp_dir), "--json-out", str(base_json),
            "--prefix", f"{args.prefix}-BASE",
            "--expected-rtl-count", str(args.expected_rtl_count),
            "--expected-evidence-count", str(args.expected_evidence_count),
            "--expected-module-count", str(args.expected_module_count),
            "--previous-netlist", str(args.previous_netlist.resolve()),
        ]
        widths = args.required_pipestage_width or [147]
        for width in widths:
            command.extend(("--required-pipestage-width", str(width)))
        completed = subprocess.run(command, text=True, capture_output=True, check=False)
        if completed.returncode != 0:
            sys.stderr.write(completed.stdout)
            sys.stderr.write(completed.stderr)
            fail(f"frozen base audit failed with rc={completed.returncode}")
        try:
            result = json.loads(base_json.read_text())
        except (OSError, json.JSONDecodeError) as error:
            fail(f"cannot read frozen base audit result: {error}")

    top = parse_npc_top_stat(synth_stat.read_text())
    if float(result.get("area", -1.0)) != top["area"]:
        fail("frozen base audit area disagrees with strict NpcTop area")
    result.update(top)
    result.update({
        "schema": "t4q-synthesis-audit-v1",
        "top": "NpcTop",
        "top_stat_row_cardinality": 1,
        "top_stat_percent_tolerance": PERCENT_TOLERANCE,
        "base_audit": str(BASE_AUDIT.resolve()),
    })
    args.json_out.parent.mkdir(parents=True, exist_ok=True)
    args.json_out.write_text(json.dumps(result, indent=2, sort_keys=True) + "\n")
    print(
        f"[{args.prefix}] PASS: area={top['area']:.2f} "
        f"sequential={top['sequential_area']:.2f} "
        f"({top['sequential_percent']:.2f}%) modules={result['module_count']}"
    )


if __name__ == "__main__":
    main()
