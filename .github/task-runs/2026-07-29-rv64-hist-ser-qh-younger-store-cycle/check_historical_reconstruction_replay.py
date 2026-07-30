#!/usr/bin/env python3
"""Prove that the ledger-bound historical reconstruction is replay-stable."""

from __future__ import annotations

import argparse
import hashlib
import json
import subprocess
import sys
from pathlib import Path


def sha256_bytes(value: bytes) -> str:
    return hashlib.sha256(value).hexdigest()


def sha256_file(path: Path) -> str:
    return sha256_bytes(path.read_bytes())


def run_once(runner: Path, repo_root: Path) -> tuple[bytes, dict, dict]:
    completed = subprocess.run(
        [sys.executable, "-B", str(runner), "--refresh"],
        cwd=repo_root,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        timeout=180,
        check=False,
    )
    if completed.returncode != 0:
        raise RuntimeError(
            "historical reconstruction replay failed: "
            f"rc={completed.returncode} stderr={completed.stderr[-1200:]}"
        )
    task_dir = runner.parent
    summary_path = (
        task_dir / "evidence/historical-reconstruction/summary.json"
    )
    summary_bytes = summary_path.read_bytes()
    summary = json.loads(summary_bytes)
    cases: dict[str, dict] = {}
    for case in summary["cases"]:
        receipt_path = repo_root / case["image_receipt_path"]
        receipt = json.loads(receipt_path.read_text(encoding="utf-8"))
        if (
            receipt["normalized_sha256"]
            != case["image_normalized_sha256"]
        ):
            raise RuntimeError(
                f"{case['case']}: receipt/summary normalized SHA mismatch"
            )
        cases[case["case"]] = {
            "rtl_sha256": case["rtl_sha256"],
            "log_sha256": case["log_sha256"],
            "image_size_bytes": case["image_size_bytes"],
            "image_normalized_sha256": case["image_normalized_sha256"],
            "image_raw_sha256": receipt["raw_sha256"],
            "oracle_result": case["oracle_result"],
        }
    return summary_bytes, summary, cases


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--refresh",
        action="store_true",
        help="replace this checker's bounded replay receipt",
    )
    args = parser.parse_args()

    task_dir = Path(__file__).resolve().parent
    repo_root = task_dir.parents[2]
    runner = task_dir / "run-historical-reconstruction.py"
    evidence_dir = task_dir / "evidence/replay-identity-v2"
    json_path = evidence_dir / "stability.json"
    markdown_path = evidence_dir / "stability.md"
    if (json_path.exists() or markdown_path.exists()) and not args.refresh:
        raise RuntimeError(
            "owned replay receipt already exists; pass --refresh"
        )
    evidence_dir.mkdir(parents=True, exist_ok=True)

    first_bytes, first_summary, first_cases = run_once(
        runner, repo_root
    )
    second_bytes, second_summary, second_cases = run_once(
        runner, repo_root
    )
    if first_bytes != second_bytes:
        raise RuntimeError("ledger-bound summary is not byte-stable")
    if first_summary["status"] != "PASS" or second_summary["status"] != "PASS":
        raise RuntimeError("both reconstruction summaries must be PASS")
    if first_cases.keys() != second_cases.keys():
        raise RuntimeError("case inventory drifted across identical replays")

    case_results: list[dict[str, object]] = []
    for name in sorted(first_cases):
        first = first_cases[name]
        second = second_cases[name]
        stable_fields = (
            "rtl_sha256",
            "log_sha256",
            "image_size_bytes",
            "image_normalized_sha256",
            "oracle_result",
        )
        if any(first[field] != second[field] for field in stable_fields):
            raise RuntimeError(
                f"{name}: semantic receipt drifted across identical replays"
            )
        case_results.append(
            {
                "case": name,
                "normalized_identity_stable": True,
                "log_identity_stable": True,
                "raw_image_identity_equal": (
                    first["image_raw_sha256"]
                    == second["image_raw_sha256"]
                ),
                "image_normalized_sha256": (
                    first["image_normalized_sha256"]
                ),
                "oracle_result": first["oracle_result"],
            }
        )

    result = {
        "schema": "npc-rv64-historical-reconstruction-replay-v1",
        "status": "PASS",
        "runner_path": str(runner.relative_to(repo_root)),
        "runner_sha256": sha256_file(runner),
        "summary_path": (
            ".github/task-runs/"
            "2026-07-29-rv64-hist-ser-qh-younger-store-cycle/"
            "evidence/historical-reconstruction/summary.json"
        ),
        "first_summary_sha256": sha256_bytes(first_bytes),
        "second_summary_sha256": sha256_bytes(second_bytes),
        "summary_byte_equal": True,
        "cases": case_results,
        "totals": {
            "cases": len(case_results),
            "normalized_identity_stable": sum(
                1
                for case in case_results
                if case["normalized_identity_stable"]
            ),
            "log_identity_stable": sum(
                1 for case in case_results if case["log_identity_stable"]
            ),
            "raw_image_identity_changed": sum(
                1
                for case in case_results
                if not case["raw_image_identity_equal"]
            ),
        },
        "scope": (
            "two identical six-case Icarus replays; normalized VVP identity "
            "does not replace RTL source, compile log, raw receipt or oracle"
        ),
    }
    json_path.write_text(
        json.dumps(result, indent=2) + "\n",
        encoding="utf-8",
    )
    markdown_path.write_text(
        "\n".join(
            [
                "# Historical reconstruction replay identity",
                "",
                "- status: PASS",
                "- six-case summaries byte-equal: yes",
                "- normalized image identities stable: 6/6",
                "- compile/simulation log identities stable: 6/6",
                (
                    "- raw image identities changed: "
                    f"{result['totals']['raw_image_identity_changed']}/6"
                ),
                "- scope: two identical bounded Icarus replays",
                "",
            ]
        ),
        encoding="utf-8",
    )
    print(
        "[HIST-SER-QH-REPLAY-IDENTITY][PASS] "
        "summary_byte_equal=1 normalized=6/6 logs=6/6 "
        f"raw_changed={result['totals']['raw_image_identity_changed']}/6"
    )
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (RuntimeError, subprocess.TimeoutExpired) as error:
        print(
            f"[HIST-SER-QH-REPLAY-IDENTITY][FAIL] {error}",
            file=sys.stderr,
        )
        raise SystemExit(1)
