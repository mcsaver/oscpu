#!/usr/bin/env python3
"""Fail-closed final audit for the V14D RV64 P1 direct evidence package."""

from __future__ import annotations

import argparse
import hashlib
import json
import pathlib
import sys
from typing import Any


HERE = pathlib.Path(__file__).resolve().parent
ROOT = HERE.parents[2]
DESIGN_ID = "sha256:093c2380b997029944aa4462015d83711d7c5f1d52b15b4803c4515a581a7488"
CONTRACT_SHA256 = "3ae3ecca7e708d7384a15fab2c0f3aae5350f5c6e7354e171f2937b51694790f"
EXPECTED_STATUS = {
    "control-run-1.status": "FAIL rc=1 stage=exit-trap evidence_complete=0 cleanup_rc=0",
    "control-run-2.status": "FAIL rc=1 stage=exit-trap evidence_complete=0 cleanup_rc=0",
    "control-run-3.status": "PASS",
    "store-run-1.status": "FAIL rc=1 stage=exit-trap evidence_complete=0 cleanup_rc=0",
    "store-run-2.status": "FAIL rc=1 stage=exit-trap evidence_complete=0 cleanup_rc=0",
    "store-run-3.status": "PASS",
    "p1-direct-1.status": "PASS",
}
EXPECTED_SCOPE = ["CONTROL-EVENT-G1", "MIQ-FLUSH-G1", "STORE-BRESP-G1"]
EXPECTED_BY_GATE = {
    "CONTROL-EVENT-G1": 16,
    "MIQ-FLUSH-G1": 3,
    "STORE-BRESP-G1": 5,
}
EXPECTED_STALE = ["F0-G1", "FENCE-G1", "SERIALIZE-G1", "VECTORED-TRAP-G1"]
FORBIDDEN_FILE_SUFFIXES = {".vvp", ".o", ".a", ".so", ".pyc"}
FORBIDDEN_DIRECTORY_NAMES = {
    "__pycache__",
    "generated",
    "memory-staging",
    "obj_dir",
    "variants",
}


def load(path: pathlib.Path) -> dict[str, Any]:
    payload = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(payload, dict):
        raise ValueError(f"JSON root is not an object: {path}")
    return payload


def digest(path: pathlib.Path) -> str:
    value = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            value.update(chunk)
    return value.hexdigest()


def artifact(path: pathlib.Path) -> dict[str, str]:
    resolved = path.resolve(strict=True)
    if not resolved.is_relative_to(ROOT) or not resolved.is_file():
        raise ValueError(f"invalid RV64 evidence artifact: {path}")
    return {
        "path": resolved.relative_to(ROOT).as_posix(),
        "sha256": digest(resolved),
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--output", required=True, type=pathlib.Path)
    args = parser.parse_args()
    output = args.output.resolve()
    if not output.parent.is_relative_to(HERE / "evidence"):
        raise ValueError("final audit output escaped V14D evidence")
    if output.exists():
        raise ValueError("refusing to replace final audit")

    observed_status = {
        name: (HERE / name).read_text(encoding="utf-8").strip()
        for name in EXPECTED_STATUS
    }
    if observed_status != EXPECTED_STATUS:
        raise ValueError(f"historical status drift: {observed_status}")

    receipt_path = HERE / "evidence/p1-direct-1/receipt.json"
    section13_path = HERE / "evidence/section13-current-1/section13-current-audit.json"
    control_path = HERE / "evidence/control-run-3/summary.json"
    store_path = HERE / "evidence/store-run-3/summary.json"
    contract_path = HERE / "subagent-contracts/v14d-p1-direct-final-review-v1.json"
    reviewer_path = HERE / "reviewer-result.md"
    receipt = load(receipt_path)
    section13 = load(section13_path)
    control = load(control_path)
    store = load(store_path)

    positives = receipt.get("positive_rtl", {})
    negatives = receipt.get("compile_success_rtl_counterexamples", {})
    warnings = receipt.get("warning_audit", {})
    source_identity = receipt.get("source_identity", {})
    if (
        receipt.get("schema") != "rv64-v14d-p1-direct-current-receipt-v1"
        or receipt.get("status") != "PASS"
        or receipt.get("scope") != EXPECTED_SCOPE
        or receipt.get("current_design_id") != DESIGN_ID
        or receipt.get("current_dynamic_gate_count") != 3
        or set(receipt.get("scope_status", {}).values()) != {"CURRENT_DYNAMIC_PASS"}
        or positives.get("passed") != 21
        or positives.get("required") != 21
        or negatives.get("detected") != 24
        or negatives.get("required") != 24
        or negatives.get("by_gate") != EXPECTED_BY_GATE
        or negatives.get("unique_rtl_variant_fingerprints") != 24
        or negatives.get("alias_count") != 0
        or len(negatives.get("inventory", ())) != 24
        or len({(item.get("source"), item.get("variant_sha256")) for item in negatives.get("inventory", ())}) != 24
        or warnings.get("unexplained_warning_count") != 0
        or warnings.get("assertion_failure_observed") is not False
        or source_identity.get("file_count") != 146
        or source_identity.get("pre_post_equal") is not True
        or receipt.get("architecture_gate_state") != "RED"
        or receipt.get("arch_stable") is not False
        or receipt.get("ppa_state") != "BLOCKED_BY_ARCHITECTURE"
        or receipt.get("promotion_eligible") is not False
        or receipt.get("historical_status_rewritten") is not False
        or receipt.get("canonical_ledger_unchanged") is not True
        or receipt.get("production_rtl_written") is not False
        or receipt.get("transient_compiled_images_retained") != 0
    ):
        raise ValueError("P1 direct receipt drift")

    if (
        control.get("status") != "PASS"
        or control.get("positive", {}).get("passed") != 16
        or control.get("compile_success_rtl_counterexamples", {}).get("detected") != 16
        or control.get("assertion_failure_observed") is not False
        or control.get("warning_audit", {}).get("unexplained_warning_count") != 0
        or store.get("status") != "PASS"
        or store.get("positive", {}).get("passed") != 4
        or store.get("compile_success_rtl_counterexamples", {}).get("detected") != 5
        or store.get("assertion_failure_observed") is not False
        or store.get("warning_audit", {}).get("unexplained_warning_count") != 0
    ):
        raise ValueError("CONTROL/STORE summary drift")

    debt = section13.get("architecture_debt", {})
    if (
        section13.get("architecture_gate_state") != "RED"
        or section13.get("arch_stable") is not False
        or section13.get("ppa_state") != "BLOCKED_BY_ARCHITECTURE"
        or section13.get("promotion_eligible") is not False
        or debt.get("p1_current_bound") != EXPECTED_SCOPE
        or debt.get("p1_current_bound_count") != 3
        or debt.get("p1_current_stale") != EXPECTED_STALE
        or debt.get("current_stale_count") != 4
        or len(section13.get("blockers", ())) != 6
    ):
        raise ValueError("Section13 fail-closed boundary drift")
    if digest(contract_path) != CONTRACT_SHA256:
        raise ValueError("review contract hash drift")
    reviewer_text = reviewer_path.read_text(encoding="utf-8")
    if (
        "范围=PASS" not in reviewer_text
        or "ppa_state=BLOCKED_BY_ARCHITECTURE" not in reviewer_text
    ):
        raise ValueError("independent reviewer result is missing")

    forbidden_files: list[str] = []
    forbidden_directories: list[str] = []
    file_count = 0
    byte_count = 0
    for path in HERE.rglob("*"):
        relative = path.relative_to(HERE).as_posix()
        if path.is_dir():
            if path.name in FORBIDDEN_DIRECTORY_NAMES:
                forbidden_directories.append(relative)
            continue
        if path.is_file():
            file_count += 1
            byte_count += path.stat().st_size
            if path.suffix in FORBIDDEN_FILE_SUFFIXES or path.name == "NpcSimTop":
                forbidden_files.append(relative)
    if forbidden_files or forbidden_directories:
        raise ValueError(
            f"regenerable artifacts remain files={forbidden_files} "
            f"directories={forbidden_directories}"
        )

    audit = {
        "schema": "rv64-v14d-final-audit-v1",
        "status": "PASS",
        "scope": "P1_DIRECT_TASK_LOCAL_CURRENT_DYNAMIC",
        "current_design_id": DESIGN_ID,
        "statuses": observed_status,
        "p1_direct": {
            "current_dynamic_gates": 3,
            "positive_rtl": 21,
            "compile_success_rtl_counterexamples": 24,
            "unique_rtl_variant_fingerprints": 24,
            "variant_aliases": 0,
        },
        "warnings": {"unexplained": 0, "assertion_failure_observed": False},
        "architecture": "RED",
        "arch_stable": False,
        "ppa": "BLOCKED_BY_ARCHITECTURE",
        "p1_current_stale": EXPECTED_STALE,
        "review": "PASS_TASK_LOCAL_CURRENT_SCOPE",
        "historical_status_rewritten": False,
        "regenerable_artifacts": {
            "forbidden_files": forbidden_files,
            "forbidden_directories": forbidden_directories,
        },
        "package_inventory": {
            "file_count_before_final_audit": file_count,
            "bytes_before_final_audit": byte_count,
        },
        "artifacts": {
            "p1_direct_receipt": artifact(receipt_path),
            "control_summary": artifact(control_path),
            "store_summary": artifact(store_path),
            "section13_current_audit": artifact(section13_path),
            "review_contract": artifact(contract_path),
            "reviewer_result": artifact(reviewer_path),
        },
        "next_action": section13["next_action"],
    }
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(
        json.dumps(audit, indent=2, sort_keys=True) + "\n", encoding="utf-8"
    )
    print(
        "[V14D-FINAL-AUDIT][PASS] p1_current=3/3 positive=21/21 "
        "mutations=24/24 unique_variants=24 aliases=0 stale=4 "
        "architecture=RED ppa=BLOCKED artifacts=0"
    )
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (OSError, UnicodeDecodeError, ValueError, json.JSONDecodeError) as exc:
        print(f"[V14D-FINAL-AUDIT][FAIL] {exc}", file=sys.stderr)
        raise SystemExit(1)
