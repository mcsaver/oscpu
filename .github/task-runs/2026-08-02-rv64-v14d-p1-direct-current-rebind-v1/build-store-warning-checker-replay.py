#!/usr/bin/env python3
"""Replay STORE-BRESP positive-log warnings with the exact V13R TB port."""

from __future__ import annotations

import argparse
import hashlib
import json
import pathlib
import sys
from typing import Any


HERE = pathlib.Path(__file__).resolve().parent
ROOT = HERE.parents[2]
LOGS = (
    "v9n-focused/logs/tb_v9n_sq_owner_residency.log",
    "v9n-focused/logs/tb_v9n_amo_owner_residency.log",
    "v13r-focused/logs/tb_ooo_mem_axi_bridge_v13r_store_b_multicycle_hold.log",
    "v13r-focused/logs/tb_ooo_int_backend_v13r_store_b_multicycle_retire_hold.log",
)


def digest(path: pathlib.Path) -> str:
    value = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            value.update(chunk)
    return value.hexdigest()


def artifact(path: pathlib.Path) -> dict[str, str]:
    resolved = path.resolve(strict=True)
    if not resolved.is_relative_to(ROOT) or not resolved.is_file():
        raise ValueError(f"invalid STORE warning replay artifact: {path}")
    return {
        "path": resolved.relative_to(ROOT).as_posix(),
        "sha256": digest(resolved),
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--test-evidence", required=True, type=pathlib.Path)
    parser.add_argument("--attempt-status", required=True, type=pathlib.Path)
    parser.add_argument("--attempt-summary-log", required=True, type=pathlib.Path)
    parser.add_argument("--output", required=True, type=pathlib.Path)
    args = parser.parse_args()
    evidence_root = HERE / "evidence"
    test_evidence = args.test_evidence.resolve(strict=True)
    attempt_status = args.attempt_status.resolve(strict=True)
    attempt_summary_log = args.attempt_summary_log.resolve(strict=True)
    output = args.output.resolve()
    for path in (test_evidence, attempt_summary_log, output):
        if not path.is_relative_to(evidence_root):
            raise ValueError("STORE warning replay path escaped V14D evidence")
    if attempt_status != HERE / "store-run-2.status":
        raise ValueError("STORE warning status input is not store-run-2.status")
    if output.exists():
        raise ValueError("refusing to replace STORE warning replay")
    output.parent.mkdir(parents=True, exist_ok=True)
    logs = [test_evidence / rel for rel in LOGS]
    if any(not path.is_file() for path in logs):
        raise ValueError("STORE positive warning-log inventory drift")

    sys.path.insert(0, str(HERE))
    import store_warning_audit

    audit_result = store_warning_audit.audit(logs)
    if not (
        audit_result.get("status") == "EXPLAINED"
        and audit_result.get("unexplained_warning_count") == 0
        and audit_result.get("assertion_failure_observed") is False
        and audit_result.get("category_counts", {}).get(
            "ICARUS_EXACT_V13R_OPTIONAL_IFU_AD_INPUT"
        )
        == 1
    ):
        raise ValueError("STORE warning audit result drift")
    exact = store_warning_audit.V13R_OPTIONAL_IFU_AD
    if store_warning_audit.classify_warning_line(exact) is None:
        raise ValueError("exact V13R optional port warning was rejected")
    if store_warning_audit.classify_warning_line(
        exact.replace("port 7", "port 8")
    ) is not None:
        raise ValueError("wrong V13R port negative fixture escaped")
    if store_warning_audit.classify_warning_line(
        exact.replace("ifu_ad_update_invalidate_all_i", "fabricated_i")
    ) is not None:
        raise ValueError("wrong V13R signal negative fixture escaped")
    if store_warning_audit.classify_warning_line(
        "warning: fabricated diagnostic"
    ) is not None:
        raise ValueError("unknown warning negative fixture escaped")

    status_text = attempt_status.read_text(encoding="utf-8").strip()
    summary_text = attempt_summary_log.read_text(encoding="utf-8").strip()
    if status_text != "FAIL rc=1 stage=exit-trap evidence_complete=0 cleanup_rc=0":
        raise ValueError("store-run-2 historical FAIL status drift")
    if not summary_text.startswith(
        "[V14D-STORE-BRESP][FAIL] unexplained current RTL compile warning:"
    ):
        raise ValueError("store-run-2 warning failure marker drift")
    result: dict[str, Any] = {
        "schema": "rv64-v14d-store-warning-checker-replay-v1",
        "status": "PASS",
        "debt_id": "STORE-BRESP-G1",
        "raw_attempt": {
            "status": status_text,
            "status_artifact": artifact(attempt_status),
            "summary_log": artifact(attempt_summary_log),
            "historical_status_rewritten": False,
        },
        "warning_audit": audit_result,
        "positive_logs": [artifact(path) for path in logs],
        "checker": artifact(HERE / "store_warning_audit.py"),
        "checker_self_test": {
            "accept_exact_optional_ifu_ad_input": "PASS",
            "reject_wrong_port": "PASS",
            "reject_wrong_signal": "PASS",
            "reject_unknown_warning": "PASS",
        },
        "assertion_weakened": False,
        "canonical_evidence_rewritten": False,
    }
    output.write_text(
        json.dumps(result, indent=2, sort_keys=True) + "\n", encoding="utf-8"
    )
    print(
        "[V14D-STORE-WARNING-REPLAY][PASS] positive_logs=4 unexplained=0 "
        "negative_fixtures=3/3 historical_fail=preserved"
    )
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (OSError, UnicodeDecodeError, ValueError, json.JSONDecodeError) as exc:
        print(f"[V14D-STORE-WARNING-REPLAY][FAIL] {exc}", file=sys.stderr)
        raise SystemExit(1)
