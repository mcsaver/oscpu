#!/usr/bin/env python3
"""Fail-closed final audit for the V14C RV64 P0 evidence package."""

from __future__ import annotations

import argparse
import hashlib
import json
import pathlib
import sys
from typing import Any


HERE = pathlib.Path(__file__).resolve().parent
ROOT = HERE.parents[2]
CONTRACT_SHA256 = "1731a6622dc65d618e8fae1aa15f0107a12f0685de2513cd5a3a86ba52983646"
EXPECTED_STATUS = {
    "current-bind-1.status": "PASS",
    "current-bind-checker-replay-1.status": (
        "FAIL rc=1 stage=evidence-complete evidence_complete=0 cleanup_rc=0"
    ),
    "current-bind-checker-replay-2.status": "PASS",
    "p0-replay-elimination-1.status": (
        "FAIL rc=1 stage=evidence-complete evidence_complete=0 cleanup_rc=0"
    ),
    "p0-replay-elimination-checker-replay-1.status": "PASS",
    "p0-final-1.status": "PASS",
    "p0-final-2.status": "PASS",
}
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
        raise ValueError("final audit output escaped V14C evidence")
    if output.exists():
        raise ValueError("refusing to replace final audit")

    observed_status = {
        name: (HERE / name).read_text(encoding="utf-8").strip()
        for name in EXPECTED_STATUS
    }
    if observed_status != EXPECTED_STATUS:
        raise ValueError(f"historical status drift: {observed_status}")

    inventory_path = HERE / "evidence/counterexample-inventory-1/inventory.json"
    final_path = HERE / "evidence/p0-final-2/receipt.json"
    section13_path = (
        HERE / "evidence/section13-current-3/section13-current-audit.json"
    )
    contract_path = (
        HERE / "subagent-contracts/v14c-p0-current-review-v3.json"
    )
    reviewer_path = HERE / "reviewer-result-v3.md"
    inventory = load(inventory_path)
    final = load(final_path)
    section13 = load(section13_path)

    if (
        inventory.get("status") != "PASS"
        or inventory.get("total_negative_observations") != 124
        or inventory.get("unique_item_ids") != 124
        or inventory.get("unique_rtl_variant_fingerprints") != 117
        or inventory.get("p0", {}).get("detected") != 121
        or inventory.get("p0", {}).get("rtl_mutation_executions") != 118
        or inventory.get("p0", {}).get("oracle_probe_executions") != 3
        or inventory.get("p0", {}).get("unique_rtl_variant_fingerprints") != 114
        or len(inventory.get("rtl_variant_aliases", ())) != 4
        or inventory.get("adjacent_non_p0", {}).get("by_debt")
        != {"MIQ-FLUSH-G1": 3}
    ):
        raise ValueError("counterexample inventory drift")
    if (
        final.get("status") != "PASS"
        or final.get("current_dynamic_gate_count") != 9
        or final.get("p0_negative_observations", {}).get("detected") != 121
        or final.get("adjacent_non_p0_negative_observations", {}).get(
            "counted_in_p0"
        )
        is not False
        or final.get("status_history", {}).get(
            "p0_final_1_attribution_superseded"
        )
        is not True
        or final.get("status_history", {}).get("historical_status_rewritten")
        is not False
        or final.get("replay_dependency_for_delivery") is not False
        or final.get("source_identity", {}).get("pre_post_equal") is not True
    ):
        raise ValueError("P0 final receipt drift")
    if (
        section13.get("architecture_gate_state") != "RED"
        or section13.get("arch_stable") is not False
        or section13.get("ppa_state") != "BLOCKED_BY_ARCHITECTURE"
        or section13.get("promotion_eligible") is not False
        or section13.get("architecture_debt", {}).get("p0_current_bound_count")
        != 9
        or len(section13.get("architecture_debt", {}).get("p1_current_stale", ()))
        != 7
        or len(section13.get("blockers", ())) != 6
    ):
        raise ValueError("Section13 fail-closed boundary drift")
    if digest(contract_path) != CONTRACT_SHA256:
        raise ValueError("review contract hash drift")
    if "APPROVED_CURRENT_SCOPE" not in reviewer_path.read_text(encoding="utf-8"):
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
        "schema": "rv64-v14c-final-audit-v1",
        "status": "PASS",
        "scope": "P0_TASK_LOCAL_CURRENT_DYNAMIC",
        "statuses": observed_status,
        "p0": {
            "current_dynamic_gates": 9,
            "negative_observations": 121,
            "rtl_mutation_executions": 118,
            "oracle_probe_executions": 3,
            "unique_rtl_variant_fingerprints": 114,
            "variant_alias_pairs": 4,
        },
        "adjacent_p1": {"MIQ-FLUSH-G1": 3, "counted_in_p0": False},
        "architecture": "RED",
        "arch_stable": False,
        "ppa": "BLOCKED_BY_ARCHITECTURE",
        "review": "APPROVED_CURRENT_SCOPE",
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
            "counterexample_inventory": artifact(inventory_path),
            "p0_final_receipt": artifact(final_path),
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
        "[V14C-FINAL-AUDIT][PASS] p0_current=9/9 observations=121 "
        "rtl_runs=118 oracle=3 unique_variants=114 aliases=4 "
        "adjacent_p1=3 architecture=RED ppa=BLOCKED artifacts=0"
    )
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (OSError, UnicodeDecodeError, ValueError, json.JSONDecodeError) as exc:
        print(f"[V14C-FINAL-AUDIT][FAIL] {exc}", file=sys.stderr)
        raise SystemExit(1)
