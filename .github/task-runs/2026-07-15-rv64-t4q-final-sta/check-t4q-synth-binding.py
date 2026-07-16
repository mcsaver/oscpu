#!/usr/bin/env python3
"""Bind the corrected T4Q synthesis audit to the frozen live netlist."""

from __future__ import annotations

import argparse
import hashlib
import json
import math
from pathlib import Path


EXPECTED_FREEZE = (
    "rtl_inputs=PASS",
    "vsrc_tree=PASS",
    "flow_inputs=PASS",
    "liberty_inputs=PASS",
    "evidence_inputs=PASS",
    "tool_binaries=PASS",
    "parameters=PASS",
    "tool_versions=PASS",
)


def fail(message: str) -> None:
    raise SystemExit(f"[T4Q-SYNTH-BINDING] FAIL: {message}")


def require_regular(path: Path) -> None:
    if not path.is_file() or path.is_symlink() or path.stat().st_size == 0:
        fail(f"invalid input: {path}")


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--audit-summary", type=Path, required=True)
    parser.add_argument("--netlist", type=Path, required=True)
    parser.add_argument("--freeze-status", type=Path, required=True)
    parser.add_argument("--exit-status", type=Path, required=True)
    parser.add_argument("--json-out", type=Path, required=True)
    args = parser.parse_args()
    for path in (args.audit_summary, args.netlist, args.freeze_status, args.exit_status):
        require_regular(path)
    if args.json_out.exists():
        fail(f"refusing existing output: {args.json_out}")
    try:
        audit = json.loads(args.audit_summary.read_text())
    except json.JSONDecodeError as error:
        fail(f"invalid audit summary: {error}")
    if audit.get("schema") != "t4q-synthesis-audit-v1":
        fail("synthesis audit schema drifted")
    if audit.get("module_count") != 117:
        fail(f"mapped module_count={audit.get('module_count')!r}, expected 117")
    if audit.get("top") != "NpcTop" or audit.get("top_stat_row_cardinality") != 1:
        fail("synthesis audit lacks unique NpcTop row closure")
    numeric = [
        float(audit.get("area", -1.0)),
        float(audit.get("sequential_area", -1.0)),
        float(audit.get("sequential_percent", -1.0)),
        float(audit.get("sequential_percent_derived", -1.0)),
    ]
    area, sequential, reported, derived = numeric
    if not all(math.isfinite(value) for value in numeric):
        fail("NpcTop top-stat fields are not finite")
    if area <= 0.0 or sequential < 0.0 or sequential > area:
        fail("NpcTop area/sequential bounds are invalid")
    if abs(reported - derived) > 0.0051:
        fail("NpcTop sequential percent exceeds rounding tolerance")
    netlist_sha = sha256(args.netlist)
    if audit.get("netlist_sha256") != netlist_sha:
        fail("audit netlist SHA does not match live frozen netlist")
    if tuple(args.freeze_status.read_text().splitlines()) != EXPECTED_FREEZE:
        fail("synthesis freeze status is not the exact eight-line PASS closure")
    if args.exit_status.read_text().strip() != "0":
        fail("synthesis exit status is not zero")
    result = {
        "schema": "t4q-synth-binding-v1",
        "audit_summary": str(args.audit_summary.resolve()),
        "audit_summary_sha256": sha256(args.audit_summary),
        "netlist": str(args.netlist.resolve()),
        "netlist_sha256": netlist_sha,
        "freeze_status_sha256": sha256(args.freeze_status),
        "exit_status_sha256": sha256(args.exit_status),
        "module_count": 117,
        "top_stat_match": True,
    }
    args.json_out.parent.mkdir(parents=True, exist_ok=True)
    args.json_out.write_text(json.dumps(result, indent=2, sort_keys=True) + "\n")
    print(f"[T4Q-SYNTH-BINDING] PASS: netlist_sha256={netlist_sha}")


if __name__ == "__main__":
    main()
