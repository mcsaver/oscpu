#!/usr/bin/env python3
"""Finalize T4I target evidence only after every post-run closure is PASS."""

from __future__ import annotations

import argparse
import hashlib
import json
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
EXPECTED_SETUP_DERIVATION = ("canonical_vs_regenerated=PASS",)


def fail(message: str) -> None:
    raise SystemExit(f"[T4I-FINAL-ATTESTATION] FAIL: {message}")


def require_regular(path: Path) -> None:
    if not path.is_file() or path.is_symlink() or path.stat().st_size == 0:
        fail(f"missing, empty, symlink, or non-regular file: {path}")


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    digest.update(path.read_bytes())
    return digest.hexdigest()


def require_status(path: Path, expected: tuple[str, ...]) -> None:
    require_regular(path)
    if tuple(path.read_text().splitlines()) != expected:
        fail(f"status closure drifted: {path}")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--summary", type=Path, required=True)
    parser.add_argument("--synth-binding-status", type=Path, required=True)
    parser.add_argument("--opensta-freeze-status", type=Path, required=True)
    parser.add_argument("--setup-derivation-status", type=Path, required=True)
    parser.add_argument("--json-out", type=Path, required=True)
    args = parser.parse_args()
    require_regular(args.summary)
    require_status(args.synth_binding_status, EXPECTED_SYNTH_BINDING)
    require_status(args.opensta_freeze_status, EXPECTED_OPENSTA_FREEZE)
    require_status(args.setup_derivation_status, EXPECTED_SETUP_DERIVATION)
    if args.json_out.exists():
        fail(f"refusing existing attestation: {args.json_out}")
    try:
        summary = json.loads(args.summary.read_text())
    except json.JSONDecodeError as error:
        fail(f"invalid preliminary summary: {error}")
    if summary.get("synth_pre_binding_match") is not True:
        fail("preliminary synthesis binding was not validated")
    if summary.get("synth_binding_match") is not False:
        fail("summary was already finalized or has a forged synthesis closure")
    if summary.get("opensta_freeze_match") is not False:
        fail("summary was already finalized or has a forged OpenSTA closure")
    if summary.get("setup_derivation_match") is not False:
        fail("summary was already finalized or has a forged setup derivation closure")
    timing_paths_met = (
        summary.get("violated_path_count") == 0
        and float(summary.get("worst_path_slack_ns")) >= 0.0
        and float(summary.get("wns_ns")) == 0.0
        and float(summary.get("tns_ns")) == 0.0
    )
    if summary.get("timing_paths_met") is not timing_paths_met:
        fail("preliminary timing_paths_met disagrees with hardened recomputation")
    target_met = timing_paths_met and summary.get("setup_member_set_match") is True
    summary.update(
        {
            "synth_binding_match": True,
            "opensta_freeze_match": True,
            "setup_derivation_match": True,
            "target_200mhz_met": target_met,
        }
    )
    temporary = args.summary.with_suffix(args.summary.suffix + ".tmp")
    temporary.write_text(json.dumps(summary, indent=2, sort_keys=True) + "\n")
    temporary.replace(args.summary)
    result = {
        "schema": "t4i-final-sta-attestation-v1",
        "summary": str(args.summary.resolve()),
        "summary_sha256": sha256(args.summary),
        "synth_binding_status_sha256": sha256(args.synth_binding_status),
        "opensta_freeze_status_sha256": sha256(args.opensta_freeze_status),
        "setup_derivation_status_sha256": sha256(args.setup_derivation_status),
        "target_200mhz_met": target_met,
    }
    args.json_out.parent.mkdir(parents=True, exist_ok=True)
    args.json_out.write_text(json.dumps(result, indent=2, sort_keys=True) + "\n")
    print(
        f"[T4I-FINAL-ATTESTATION] PASS: target_met={target_met} "
        f"summary_sha256={result['summary_sha256']}"
    )


if __name__ == "__main__":
    main()
