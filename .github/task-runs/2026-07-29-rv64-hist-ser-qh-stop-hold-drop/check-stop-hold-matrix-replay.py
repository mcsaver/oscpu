#!/usr/bin/env python3
"""Replay the eight-case matrix and attest stable semantic evidence."""

from __future__ import annotations

import hashlib
import json
import subprocess
import sys
from pathlib import Path


RUN_DIR = Path(__file__).resolve().parent
ROOT = RUN_DIR.parents[2]
MATRIX_DIR = RUN_DIR / "evidence/stop-hold-matrix"
SUMMARY = MATRIX_DIR / "summary.json"
RUNNER = RUN_DIR / "run-stop-hold-matrix.py"
OUT = RUN_DIR / "evidence/replay-stability.json"


def sha256_bytes(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def load_receipts(summary: dict[str, object]) -> dict[str, dict[str, object]]:
    receipts: dict[str, dict[str, object]] = {}
    for case in summary["cases"]:
        assert isinstance(case, dict)
        receipt_path = ROOT / str(case["image_receipt"])
        receipts[str(case["case"])] = json.loads(
            receipt_path.read_text(encoding="utf-8")
        )
    return receipts


def semantic_snapshot() -> dict[str, object]:
    summary_bytes = SUMMARY.read_bytes()
    summary = json.loads(summary_bytes)
    receipts = load_receipts(summary)
    return {
        "summary_sha256": sha256_bytes(summary_bytes),
        "summary_status": summary["status"],
        "case_log_sha256": {
            str(case["case"]): case["log_sha256"]
            for case in summary["cases"]
        },
        "normalized_image_sha256": {
            name: receipt["normalized_sha256"]
            for name, receipt in receipts.items()
        },
        "raw_image_sha256": {
            name: receipt["raw_sha256"]
            for name, receipt in receipts.items()
        },
    }


def main() -> int:
    if not SUMMARY.exists():
        raise RuntimeError(f"matrix summary missing: {SUMMARY}")
    before = semantic_snapshot()
    completed = subprocess.run(
        [sys.executable, str(RUNNER), "--refresh"],
        cwd=ROOT,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        check=False,
        timeout=240,
    )
    after = semantic_snapshot()
    checks = {
        "runner_returncode_zero": completed.returncode == 0,
        "summary_pass_before": before["summary_status"] == "PASS",
        "summary_pass_after": after["summary_status"] == "PASS",
        "summary_bytes_stable":
            before["summary_sha256"] == after["summary_sha256"],
        "case_logs_stable":
            before["case_log_sha256"] == after["case_log_sha256"],
        "normalized_images_stable":
            before["normalized_image_sha256"]
            == after["normalized_image_sha256"],
    }
    passed = all(checks.values())
    result = {
        "schema": "npc-rv64-hist-ser-qh-stop-hold-replay/v1",
        "status": "PASS" if passed else "GAP",
        "checks": checks,
        "before": before,
        "after": after,
        "raw_images_stable":
            before["raw_image_sha256"] == after["raw_image_sha256"],
        "runner_stdout": completed.stdout,
        "runner_stderr": completed.stderr,
        "runner_returncode": completed.returncode,
    }
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(
        json.dumps(result, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )
    print(
        "[HIST-SER-QH-STOP-HOLD-REPLAY] "
        f"summary={checks['summary_bytes_stable']} "
        f"logs={checks['case_logs_stable']} "
        f"images={checks['normalized_images_stable']} "
        f"{result['status']}"
    )
    return 0 if passed else 1


if __name__ == "__main__":
    raise SystemExit(main())
