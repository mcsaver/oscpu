#!/usr/bin/env python3
"""Independently close the exact-5ns T3J target from summary.json.

Exit status is intentionally semantic: 0 means the 200 MHz target is met,
1 means a self-consistent summary misses it, and 2 means malformed evidence or
an expectation mismatch.  Thus an expected RED is recorded with --expect miss
and still returns 1 instead of being converted into a false green.
"""

from __future__ import annotations

import argparse
import json
import math
import sys
from pathlib import Path
from typing import Any


MARKER = "[T3J-200MHZ-TARGET]"


class EvidenceError(RuntimeError):
    pass


def require(condition: bool, message: str) -> None:
    if not condition:
        raise EvidenceError(message)


def finite_number(value: Any, label: str) -> float:
    require(type(value) in (int, float), f"{label} is not a JSON number")
    result = float(value)
    require(math.isfinite(result), f"{label} is not finite")
    return result


def exact_int(value: Any, label: str, minimum: int = 0) -> int:
    require(type(value) is int, f"{label} is not a JSON integer")
    require(value >= minimum, f"{label} is below {minimum}")
    return value


def unique_object(pairs: list[tuple[str, Any]]) -> dict[str, Any]:
    result: dict[str, Any] = {}
    for key, value in pairs:
        if key in result:
            raise EvidenceError(f"duplicate JSON key: {key}")
        result[key] = value
    return result


def validate(summary: dict[str, Any]) -> tuple[float, float, bool]:
    expected_keys = {
        "combinational_loops",
        "endpoint_classes",
        "fetch_payload_addr_path_blocks",
        "fetch_payload_en_path_blocks",
        "path_count",
        "period_ns",
        "physical_read_window_tokens_in_top40",
        "semantic_accept_tokens_in_top40",
        "setup_warning_counts",
        "target_200mhz_met",
        "tns_ns",
        "total_power_w",
        "wns_ns",
    }
    require(
        set(summary) == expected_keys,
        "summary key set drifted: "
        f"missing={sorted(expected_keys - set(summary))} "
        f"extra={sorted(set(summary) - expected_keys)}",
    )
    period = finite_number(summary["period_ns"], "period_ns")
    require(period == 5.0, f"period_ns is {period}, expected exact 5.0")
    require(exact_int(summary["path_count"], "path_count") == 40, "path_count is not 40")
    require(
        exact_int(summary["combinational_loops"], "combinational_loops") == 0,
        "combinational_loops is not zero",
    )

    wns = finite_number(summary["wns_ns"], "wns_ns")
    tns = finite_number(summary["tns_ns"], "tns_ns")
    power = finite_number(summary["total_power_w"], "total_power_w")
    require(tns <= 0.0, f"TNS must be non-positive, got {tns}")
    require(power > 0.0, f"total power must be positive, got {power}")
    computed_met = wns >= 0.0
    require(
        type(summary["target_200mhz_met"]) is bool,
        "target_200mhz_met is not a JSON boolean",
    )
    require(
        summary["target_200mhz_met"] == computed_met,
        "target_200mhz_met disagrees with WNS sign",
    )
    if computed_met:
        require(tns == 0.0, f"non-negative WNS requires zero TNS, got {tns}")

    expected_endpoint_keys = {
        "csr_file",
        "fetch_outstanding",
        "fetch_payload_sram",
        "other",
        "pending_trap_exit",
    }
    endpoint_classes = summary["endpoint_classes"]
    require(type(endpoint_classes) is dict, "endpoint_classes is not an object")
    require(set(endpoint_classes) == expected_endpoint_keys, "endpoint class key set drifted")
    endpoint_total = sum(
        exact_int(endpoint_classes[key], f"endpoint_classes.{key}")
        for key in expected_endpoint_keys
    )
    require(endpoint_total == 40, f"endpoint class total is {endpoint_total}, expected 40")

    warning_counts = summary["setup_warning_counts"]
    require(type(warning_counts) is dict, "setup_warning_counts is not an object")
    expected_warning_counts = {
        "missing_input_delay": 303,
        "missing_output_delay": 1861,
        "unconstrained_endpoints": 1863,
    }
    require(warning_counts == expected_warning_counts, "check_setup warning closure drifted")

    for key in (
        "fetch_payload_addr_path_blocks",
        "fetch_payload_en_path_blocks",
    ):
        require(exact_int(summary[key], key) <= 40, f"{key} exceeds top40 cardinality")
    for key in (
        "physical_read_window_tokens_in_top40",
        "semantic_accept_tokens_in_top40",
    ):
        exact_int(summary[key], key)
    return wns, tns, computed_met


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("summary", type=Path)
    parser.add_argument("--expect", choices=("met", "miss"), required=True)
    args = parser.parse_args()
    try:
        raw = args.summary.read_text(encoding="utf-8")
        parsed = json.loads(raw, object_pairs_hook=unique_object)
        require(type(parsed) is dict, "summary root is not an object")
        wns, tns, met = validate(parsed)
    except (EvidenceError, OSError, UnicodeError, json.JSONDecodeError) as error:
        print(f"{MARKER} FAIL: {error}", file=sys.stderr)
        raise SystemExit(2)

    if met and args.expect == "miss":
        print(
            f"{MARKER} FAIL: expected miss but target is met WNS={wns:.3f}ns",
            file=sys.stderr,
        )
        raise SystemExit(2)
    if not met:
        disposition = "EXPECTED-RED" if args.expect == "miss" else "MISS"
        print(f"{MARKER} {disposition}: WNS={wns:.3f}ns TNS={tns:.2f}ns")
        raise SystemExit(1)
    print(f"{MARKER} PASS: period=5.0ns frequency=200.0MHz WNS={wns:.3f}ns")


if __name__ == "__main__":
    main()
