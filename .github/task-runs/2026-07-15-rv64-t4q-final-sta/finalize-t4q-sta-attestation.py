#!/usr/bin/env python3
"""Finalize T4Q only after every independent post-run closure is exact PASS."""

from __future__ import annotations

import argparse
import hashlib
import json
import math
from pathlib import Path


EXPECTED_SYNTH_BINDING = (
    "canonical_vs_pre_audit=PASS",
    "canonical_vs_post_audit=PASS",
    "pre_vs_post_binding=PASS",
)
EXPECTED_OPENSTA_FREEZE = (
    "inputs=PASS",
    "parameters=PASS",
    "tool_version=PASS",
)
EXPECTED_SETUP_PROBE = (
    "pre_vs_post_probe=PASS",
    "pre_vs_post_manifest=PASS",
)
EXPECTED_HARDENING = ("mutations=PASS",)


def fail(message: str) -> None:
    raise SystemExit(f"[T4Q-FINAL-ATTESTATION] FAIL: {message}")


def require_regular(path: Path) -> None:
    if not path.is_file() or path.is_symlink() or path.stat().st_size == 0:
        fail(f"invalid input: {path}")


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    digest.update(path.read_bytes())
    return digest.hexdigest()


def require_status(path: Path, expected: tuple[str, ...]) -> None:
    require_regular(path)
    if tuple(path.read_text().splitlines()) != expected:
        fail(f"status closure drifted: {path}")


def positive_zero(value: object) -> bool:
    number = float(value)
    return number == 0.0 and math.copysign(1.0, number) > 0.0


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--summary", type=Path, required=True)
    parser.add_argument("--synth-binding-status", type=Path, required=True)
    parser.add_argument("--opensta-freeze-status", type=Path, required=True)
    parser.add_argument("--setup-probe-status", type=Path, required=True)
    parser.add_argument("--hardening-status", type=Path, required=True)
    parser.add_argument("--json-out", type=Path, required=True)
    args = parser.parse_args()
    require_regular(args.summary)
    require_status(args.synth_binding_status, EXPECTED_SYNTH_BINDING)
    require_status(args.opensta_freeze_status, EXPECTED_OPENSTA_FREEZE)
    require_status(args.setup_probe_status, EXPECTED_SETUP_PROBE)
    require_status(args.hardening_status, EXPECTED_HARDENING)
    if args.json_out.exists():
        fail(f"refusing existing attestation: {args.json_out}")
    try:
        summary = json.loads(args.summary.read_text())
    except json.JSONDecodeError as error:
        fail(f"invalid preliminary summary: {error}")
    expected_false = (
        "synth_binding_match",
        "opensta_freeze_match",
        "setup_probe_match",
        "hardening_mutations_passed",
    )
    if summary.get("synth_pre_binding_match") is not True:
        fail("preliminary synthesis binding was not validated")
    for key in expected_false:
        if summary.get(key) is not False:
            fail(f"summary was already finalized or forged: {key}")
    timing_paths_met = (
        summary.get("violated_path_count") == 0
        and float(summary.get("worst_path_slack_ns", -1.0)) >= 0.0
        and positive_zero(summary.get("wns_ns", float("nan")))
        and positive_zero(summary.get("tns_ns", float("nan")))
    )
    if summary.get("timing_paths_met") is not timing_paths_met:
        fail("preliminary timing_paths_met disagrees with recomputation")
    target_met = timing_paths_met and summary.get("setup_member_set_match") is True
    summary.update({
        "synth_binding_match": True,
        "opensta_freeze_match": True,
        "setup_probe_match": True,
        "hardening_mutations_passed": True,
        "target_200mhz_met": target_met,
    })
    temporary = args.summary.with_suffix(args.summary.suffix + ".tmp")
    temporary.write_text(json.dumps(summary, indent=2, sort_keys=True) + "\n")
    temporary.replace(args.summary)
    result = {
        "schema": "t4q-final-sta-attestation-v1",
        "summary": str(args.summary.resolve()),
        "summary_sha256": sha256(args.summary),
        "synth_binding_status_sha256": sha256(args.synth_binding_status),
        "opensta_freeze_status_sha256": sha256(args.opensta_freeze_status),
        "setup_probe_status_sha256": sha256(args.setup_probe_status),
        "hardening_status_sha256": sha256(args.hardening_status),
        "target_200mhz_met": target_met,
    }
    args.json_out.parent.mkdir(parents=True, exist_ok=True)
    args.json_out.write_text(json.dumps(result, indent=2, sort_keys=True) + "\n")
    print(
        f"[T4Q-FINAL-ATTESTATION] PASS: target_met={target_met} "
        f"summary_sha256={result['summary_sha256']}"
    )


if __name__ == "__main__":
    main()
