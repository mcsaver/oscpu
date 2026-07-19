#!/usr/bin/env python3
"""把 R4-S0 综合审计严格绑定到本次 STA 使用的冻结网表。"""

from __future__ import annotations

import argparse
import hashlib
import json
import math
import re
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
    raise SystemExit(f"[R4-S0-SYNTH-BINDING] FAIL: {message}")


def require_regular(path: Path) -> None:
    if not path.is_file() or path.is_symlink() or path.stat().st_size == 0:
        fail(f"invalid input: {path}")


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def validate_audit(audit: object, netlist: Path) -> dict[str, object]:
    if not isinstance(audit, dict):
        fail("synthesis audit root is not an object")
    if audit.get("schema") != "t4q-synthesis-audit-v1":
        fail(f"synthesis audit schema drifted: {audit.get('schema')!r}")
    if audit.get("top") != "NpcTop" or audit.get("top_stat_row_cardinality") != 1:
        fail("synthesis audit lacks a unique NpcTop top-stat row")
    if audit.get("module_count") != 119:
        fail(f"mapped module_count={audit.get('module_count')!r}, expected 119")
    if audit.get("netlist_bytes") != netlist.stat().st_size:
        fail("audit netlist_bytes disagrees with the live frozen netlist")
    live_sha = sha256(netlist)
    if audit.get("netlist_sha256") != live_sha:
        fail("audit netlist SHA does not match the live frozen netlist")

    numeric = (
        audit.get("area"),
        audit.get("sequential_area"),
        audit.get("sequential_percent"),
        audit.get("sequential_percent_derived"),
        audit.get("top_stat_percent_tolerance"),
    )
    try:
        area, sequential, reported, derived, tolerance = map(float, numeric)
    except (TypeError, ValueError):
        fail("NpcTop top-stat fields are not numeric")
    if not all(math.isfinite(value) for value in (area, sequential, reported, derived, tolerance)):
        fail("NpcTop top-stat fields are not finite")
    if area <= 0.0 or sequential < 0.0 or sequential > area:
        fail("NpcTop area/sequential bounds are invalid")
    if tolerance <= 0.0 or tolerance > 0.01:
        fail("top-stat percent tolerance is outside the accepted bound")
    if abs(reported - derived) > tolerance:
        fail("NpcTop sequential percent exceeds its recorded rounding tolerance")
    if not isinstance(audit.get("abc_done"), int) or int(audit["abc_done"]) <= 0:
        fail("synthesis audit lacks a positive ABC completion count")
    if not isinstance(audit.get("vsrc_count"), int) or int(audit["vsrc_count"]) <= 0:
        fail("synthesis audit lacks a positive source count")
    if re.fullmatch(r"[0-9a-f]{40}", str(audit.get("provenance_head", ""))) is None:
        fail("synthesis audit provenance_head is not a full Git object id")
    return audit


def build_binding(
    audit_summary: Path,
    netlist: Path,
    freeze_status: Path,
    exit_status: Path,
) -> dict[str, object]:
    for path in (audit_summary, netlist, freeze_status, exit_status):
        require_regular(path)
    try:
        audit = json.loads(audit_summary.read_text())
    except json.JSONDecodeError as error:
        fail(f"invalid synthesis audit JSON: {error}")
    validate_audit(audit, netlist)
    if tuple(freeze_status.read_text().splitlines()) != EXPECTED_FREEZE:
        fail("synthesis freeze status is not the exact eight-line PASS closure")
    if tuple(exit_status.read_text().splitlines()) != ("0",):
        fail("synthesis exit status is not exactly zero")
    return {
        "schema": "ppa-r4-s0-synth-binding-v1",
        "audit_summary": str(audit_summary.resolve()),
        "audit_summary_sha256": sha256(audit_summary),
        "netlist": str(netlist.resolve()),
        "netlist_sha256": sha256(netlist),
        "netlist_bytes": netlist.stat().st_size,
        "freeze_status": str(freeze_status.resolve()),
        "freeze_status_sha256": sha256(freeze_status),
        "freeze_check_count": len(EXPECTED_FREEZE),
        "exit_status": str(exit_status.resolve()),
        "exit_status_sha256": sha256(exit_status),
        "synthesis_exit_zero": True,
        "module_count": 119,
        "top": "NpcTop",
        "top_stat_match": True,
    }


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--audit-summary", type=Path, required=True)
    parser.add_argument("--netlist", type=Path, required=True)
    parser.add_argument("--freeze-status", type=Path, required=True)
    parser.add_argument("--exit-status", type=Path, required=True)
    parser.add_argument("--json-out", type=Path, required=True)
    args = parser.parse_args()
    if args.json_out.exists():
        fail(f"refusing existing output: {args.json_out}")
    result = build_binding(
        args.audit_summary.resolve(),
        args.netlist.resolve(),
        args.freeze_status.resolve(),
        args.exit_status.resolve(),
    )
    args.json_out.parent.mkdir(parents=True, exist_ok=True)
    args.json_out.write_text(json.dumps(result, indent=2, sort_keys=True) + "\n")
    print(
        "[R4-S0-SYNTH-BINDING] PASS: "
        f"modules=119 netlist_sha256={result['netlist_sha256']} freeze=8/8 exit=0"
    )


if __name__ == "__main__":
    main()
