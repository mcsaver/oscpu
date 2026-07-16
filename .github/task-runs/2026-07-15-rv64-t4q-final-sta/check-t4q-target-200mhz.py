#!/usr/bin/env python3
"""Fail-closed exact-5ns target decision for the finalized T4Q attestation."""

from __future__ import annotations

import argparse
import hashlib
import json
import math
from pathlib import Path


def fail(message: str) -> None:
    raise SystemExit(f"[T4Q-200MHZ] FAIL: {message}")


def is_positive_zero(value: object) -> bool:
    number = float(value)
    return number == 0.0 and math.copysign(1.0, number) > 0.0


def compute_met(summary: dict[str, object]) -> bool:
    return (
        summary.get("violated_path_count") == 0
        and float(summary.get("worst_path_slack_ns", -1.0)) >= 0.0
        and is_positive_zero(summary.get("wns_ns", float("nan")))
        and is_positive_zero(summary.get("tns_ns", float("nan")))
        and summary.get("setup_member_set_match") is True
        and summary.get("synth_binding_match") is True
        and summary.get("opensta_freeze_match") is True
        and summary.get("setup_probe_match") is True
        and summary.get("hardening_mutations_passed") is True
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
    for path in (args.summary, args.attestation):
        if not path.is_file() or path.is_symlink() or path.stat().st_size == 0:
            fail(f"invalid input: {path}")
    try:
        summary = json.loads(args.summary.read_text())
        attestation = json.loads(args.attestation.read_text())
    except (OSError, json.JSONDecodeError) as error:
        fail(f"cannot parse evidence: {error}")
    numeric_keys = ("period_ns", "wns_ns", "tns_ns", "worst_path_slack_ns")
    if not all(
        isinstance(summary.get(key), (int, float)) and math.isfinite(float(summary[key]))
        for key in numeric_keys
    ):
        fail("period/WNS/TNS/worst slack must be finite numbers")
    if abs(float(summary["period_ns"]) - 5.0) > 1.0e-12:
        fail(f"target decision is not exact 5.0 ns: {summary['period_ns']}")
    if summary.get("path_count") != 40 or summary.get("combinational_loops") != 0:
        fail("target evidence lacks exactly 40 paths or has a combinational loop")
    computed = compute_met(summary)
    if summary.get("target_200mhz_met") is not computed:
        fail("reported target boolean disagrees with hardened recomputation")
    if attestation.get("schema") != "t4q-final-sta-attestation-v1":
        fail("final attestation schema drifted")
    if attestation.get("summary_sha256") != sha256(args.summary):
        fail("final attestation does not bind the current summary")
    if attestation.get("target_200mhz_met") is not computed:
        fail("attestation target disagrees with hardened recomputation")
    expected = args.expect == "met"
    if computed is not expected:
        fail(
            f"expected target={args.expect}, got worst={summary['worst_path_slack_ns']} "
            f"violated={summary.get('violated_path_count')} "
            f"WNS={summary['wns_ns']} TNS={summary['tns_ns']}"
        )
    print(
        f"[T4Q-200MHZ] PASS: expect={args.expect} "
        f"worst={float(summary['worst_path_slack_ns']):.9f}ns"
    )


if __name__ == "__main__":
    main()
