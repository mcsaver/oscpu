#!/usr/bin/env python3
"""Fail-closed exact-5ns decision using path state as well as WNS/TNS."""

from __future__ import annotations

import argparse
import hashlib
import json
import math
from pathlib import Path


def fail(message: str) -> None:
    raise SystemExit(f"[T4I-200MHZ] FAIL: {message}")


def compute_met(summary: dict[str, object]) -> bool:
    return (
        summary["violated_path_count"] == 0
        and float(summary["worst_path_slack_ns"]) >= 0.0
        and float(summary["wns_ns"]) == 0.0
        and float(summary["tns_ns"]) == 0.0
        and summary["setup_member_set_match"] is True
        and summary["synth_binding_match"] is True
        and summary["opensta_freeze_match"] is True
        and summary["setup_derivation_match"] is True
    )


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    digest.update(path.read_bytes())
    return digest.hexdigest()


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("summary", type=Path)
    parser.add_argument("--attestation", type=Path, required=True)
    parser.add_argument("--expect", choices=("met", "miss"), required=True)
    args = parser.parse_args()
    if not args.summary.is_file() or args.summary.is_symlink():
        fail(f"missing or non-regular summary: {args.summary}")
    try:
        summary = json.loads(args.summary.read_text())
    except (json.JSONDecodeError, OSError) as error:
        fail(f"cannot parse summary: {error}")
    required = {
        "period_ns",
        "wns_ns",
        "tns_ns",
        "worst_path_slack_ns",
        "violated_path_count",
        "path_count",
        "combinational_loops",
        "setup_member_set_match",
        "synth_binding_match",
        "opensta_freeze_match",
        "setup_derivation_match",
        "target_200mhz_met",
    }
    if set(summary) < required:
        fail(f"summary lacks keys: {sorted(required - set(summary))}")
    numeric = (
        summary["period_ns"],
        summary["wns_ns"],
        summary["tns_ns"],
        summary["worst_path_slack_ns"],
    )
    if not all(isinstance(value, (int, float)) for value in numeric):
        fail("period/WNS/TNS/worst slack must be numeric")
    if not all(math.isfinite(float(value)) for value in numeric):
        fail("period/WNS/TNS/worst slack must be finite")
    if abs(float(summary["period_ns"]) - 5.0) > 1.0e-12:
        fail(f"target decision is not based on exact 5.0 ns: {summary['period_ns']}")
    if summary["path_count"] != 40 or summary["combinational_loops"] != 0:
        fail("target evidence lacks exactly 40 paths or has a combinational loop")
    if not isinstance(summary["violated_path_count"], int):
        fail("violated_path_count must be an integer")
    computed_met = compute_met(summary)
    if summary["target_200mhz_met"] is not computed_met:
        fail("reported target boolean disagrees with hardened recomputation")
    if not args.attestation.is_file() or args.attestation.is_symlink():
        fail(f"missing or non-regular final attestation: {args.attestation}")
    try:
        attestation = json.loads(args.attestation.read_text())
    except (json.JSONDecodeError, OSError) as error:
        fail(f"cannot parse final attestation: {error}")
    if attestation.get("schema") != "t4i-final-sta-attestation-v1":
        fail("final attestation schema drifted")
    if attestation.get("summary_sha256") != sha256(args.summary):
        fail("final attestation does not bind the current summary")
    if attestation.get("target_200mhz_met") is not computed_met:
        fail("final attestation target disagrees with hardened recomputation")
    expected_met = args.expect == "met"
    if computed_met is not expected_met:
        fail(
            f"expected target={args.expect}, got worst={float(summary['worst_path_slack_ns']):.9f}ns "
            f"violated={summary['violated_path_count']} WNS={float(summary['wns_ns']):.9f}ns "
            f"TNS={float(summary['tns_ns']):.9f}ns"
        )
    print(
        f"[T4I-200MHZ] PASS: expect={args.expect} "
        f"worst={float(summary['worst_path_slack_ns']):.9f}ns "
        f"violated={summary['violated_path_count']}"
    )


if __name__ == "__main__":
    main()
