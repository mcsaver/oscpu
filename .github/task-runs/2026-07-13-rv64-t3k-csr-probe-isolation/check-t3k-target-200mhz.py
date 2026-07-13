#!/usr/bin/env python3
"""Fail-closed 200 MHz target decision for a validated T3K STA summary."""

from __future__ import annotations

import argparse
import json
import math
import sys
from pathlib import Path


def fail(message: str) -> None:
    print(f"[T3K-200MHZ] FAIL: {message}", file=sys.stderr)
    raise SystemExit(1)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("summary", type=Path)
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
        "path_count",
        "combinational_loops",
        "target_200mhz_met",
    }
    if set(summary) < required:
        fail(f"summary lacks keys: {sorted(required - set(summary))}")
    period = summary["period_ns"]
    wns = summary["wns_ns"]
    tns = summary["tns_ns"]
    if not all(isinstance(value, (int, float)) for value in (period, wns, tns)):
        fail("period/WNS/TNS must be numeric")
    if not all(math.isfinite(float(value)) for value in (period, wns, tns)):
        fail("period/WNS/TNS must be finite")
    if abs(float(period) - 5.0) > 1.0e-12:
        fail(f"target decision is not based on exact 5.0 ns: {period}")
    if summary["path_count"] != 40 or summary["combinational_loops"] != 0:
        fail(
            "target evidence is incomplete: "
            f"paths={summary['path_count']} loops={summary['combinational_loops']}"
        )
    computed_met = float(wns) >= 0.0 and float(tns) >= 0.0
    if summary["target_200mhz_met"] is not computed_met:
        fail(
            "target boolean disagrees with WNS/TNS: "
            f"reported={summary['target_200mhz_met']} computed={computed_met}"
        )
    expected_met = args.expect == "met"
    if computed_met is not expected_met:
        fail(
            f"expected target={args.expect}, got WNS={float(wns):.3f}ns "
            f"TNS={float(tns):.2f}ns"
        )
    print(
        f"[T3K-200MHZ] PASS: expect={args.expect} "
        f"WNS={float(wns):.3f}ns TNS={float(tns):.2f}ns"
    )


if __name__ == "__main__":
    main()
