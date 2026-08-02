#!/usr/bin/env python3
"""Audit current queue-head and pending-SYSTEM SERIALIZE-G1 evidence."""

from __future__ import annotations

import argparse
import hashlib
import importlib.util
import json
import pathlib
import sys
from typing import Any


HERE = pathlib.Path(__file__).resolve().parent
ROOT = HERE.parents[2]
DESIGN_ID = "sha256:093c2380b997029944aa4462015d83711d7c5f1d52b15b4803c4515a581a7488"
WARNING_AUDIT = ROOT / (
    ".github/task-runs/2026-08-02-rv64-v14d-p1-direct-current-rebind-v1/"
    "warning_audit.py"
)
QH_PRODUCTION = {
    "typed-apply-c2-replay",
    "rob-queue-head-selection-disabled",
}
QH_VERIFICATION = {"csrfile-request-c2-replay"}


def digest(path: pathlib.Path) -> str:
    value = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            value.update(chunk)
    return value.hexdigest()


def load(path: pathlib.Path) -> dict[str, Any]:
    value = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(value, dict):
        raise ValueError(f"JSON root is not an object: {path}")
    return value


def artifact(path: pathlib.Path) -> dict[str, object]:
    resolved = path.resolve(strict=True)
    resolved.relative_to(ROOT)
    return {
        "path": resolved.relative_to(ROOT).as_posix(),
        "sha256": digest(resolved),
        "size_bytes": resolved.stat().st_size,
    }


def warning_audit(logs: list[pathlib.Path]) -> dict[str, Any]:
    spec = importlib.util.spec_from_file_location("v14e_serialize_warning_audit", WARNING_AUDIT)
    if spec is None or spec.loader is None:
        raise ValueError("cannot load current warning audit")
    module = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    result = module.audit(logs)
    result["checker"] = artifact(WARNING_AUDIT)
    return result


def validate_profiles(
    summary: dict[str, Any], expected_profiles: int, expected_positive: int
) -> tuple[list[pathlib.Path], int]:
    rows = summary.get("profiles")
    if not isinstance(rows, list) or len(rows) != expected_profiles:
        raise ValueError("SERIALIZE profile count drift")
    positive_logs: list[pathlib.Path] = []
    negative = 0
    for row in rows:
        if row.get("passed") is not True or row.get("assertions") not in (True, False):
            raise ValueError("SERIALIZE runner profile did not pass its contract")
        log_record = row.get("result_log")
        if not isinstance(log_record, dict):
            raise ValueError("SERIALIZE profile log record is absent")
        path = (ROOT / str(log_record.get("path"))).resolve(strict=True)
        path.relative_to(HERE / "evidence")
        if digest(path) != log_record.get("sha256"):
            raise ValueError("SERIALIZE profile log hash drift")
        text = path.read_text(encoding="utf-8")
        if row.get("expect_pass") is True:
            if (
                row.get("make_returncode") != 0
                or text.count("[RESULT] PASS") != 1
                or "[RESULT] FAIL" in text
                or "[CHECK-FAIL]" in text
                or "FATAL:" in text
            ):
                raise ValueError("SERIALIZE positive profile terminal drift")
            positive_logs.append(path)
        else:
            markers = row.get("markers")
            if (
                not isinstance(row.get("make_returncode"), int)
                or row.get("make_returncode") == 0
                or row.get("mutation") is None
                or not isinstance(markers, dict)
                or not markers
                or any(text.count(str(marker)) != int(count) or int(count) <= 0 for marker, count in markers.items())
                or text.count("[RESULT] FAIL") != 1
                or "[RESULT] PASS" in text
            ):
                raise ValueError("SERIALIZE counterexample rejection drift")
            negative += 1
    if len(positive_logs) != expected_positive:
        raise ValueError("SERIALIZE positive profile count drift")
    return positive_logs, negative


def cleanup_is_closed(summary: dict[str, Any]) -> bool:
    cleanup = summary.get("cleanup")
    return (
        isinstance(cleanup, dict)
        and cleanup.get("status") == "PASS"
        and cleanup.get("retained_temporary_artifacts") == 0
        and isinstance(cleanup.get("removed"), int)
        and cleanup.get("removed") > 0
    )


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--evidence", required=True, type=pathlib.Path)
    parser.add_argument("--output", required=True, type=pathlib.Path)
    args = parser.parse_args()
    evidence = args.evidence.resolve(strict=True)
    evidence.relative_to(HERE / "evidence")
    output = args.output.resolve()
    output.relative_to(evidence)
    if output.exists():
        raise ValueError("refusing to replace SERIALIZE fast receipt")

    before_path = evidence / "source-before.json"
    after_path = evidence / "source-after.json"
    before = load(before_path)
    after = load(after_path)
    if before != after or before.get("design_id") != DESIGN_ID or before.get("file_count") != 146:
        raise ValueError("SERIALIZE source identity drift")

    qh_path = evidence / "qh/summary.json"
    system_path = evidence / "system/summary.json"
    qh = load(qh_path)
    system = load(system_path)
    if (
        qh.get("schema") != "npc-rv64-v12c-serialize-qh-current-evidence-v1"
        or qh.get("status") != "PASS"
        or qh.get("design_id") != DESIGN_ID
        or qh.get("counts") != {
            "committed_transactions": 6,
            "compilations": 5,
            "compile_success_mutations": 3,
            "positive_profiles": 2,
            "selectively_killed_transactions": 4,
        }
        or qh.get("compile_input_closure", {}).get("status") != "PASS"
        or not cleanup_is_closed(qh)
    ):
        raise ValueError("queue-head SERIALIZE evidence drift")
    if (
        system.get("schema") != "npc-rv64-v12c-serialize-system-current-evidence-v1"
        or system.get("status") != "PASS"
        or system.get("design_id") != DESIGN_ID
        or system.get("counts") != {
            "baseline_profiles": 3,
            "compilations": 18,
            "compile_success_mutations": 15,
            "dynamically_rejected_mutations": 15,
        }
        or system.get("compile_input_closure", {}).get("status") != "PASS"
        or not cleanup_is_closed(system)
    ):
        raise ValueError("pending-SYSTEM SERIALIZE evidence drift")

    qh_positive, qh_negative = validate_profiles(qh, 5, 2)
    system_positive, system_negative = validate_profiles(system, 18, 3)
    if qh_negative != 3 or system_negative != 15:
        raise ValueError("SERIALIZE counterexample count drift")

    qh_mutations = qh.get("mutations")
    if not isinstance(qh_mutations, dict) or set(qh_mutations) != QH_PRODUCTION | QH_VERIFICATION:
        raise ValueError("queue-head mutation classification drift")
    production_fingerprints: set[tuple[str, str]] = set()
    verification_fingerprints: set[tuple[str, str]] = set()
    for name, row in qh_mutations.items():
        source = str(row.get("source", {}).get("path"))
        variant = str(row.get("mutated", {}).get("sha256"))
        if row.get("compile_success_required") is not True or len(variant) != 64:
            raise ValueError(f"queue-head mutation receipt drift: {name}")
        if name in QH_PRODUCTION:
            if not source.startswith("npc/rv64/vsrc/"):
                raise ValueError(f"production RTL mutation source drift: {name}")
            production_fingerprints.add((source, variant))
        else:
            if not source.startswith("npc/rv64/testbench/"):
                raise ValueError(f"verification-only mutation source drift: {name}")
            verification_fingerprints.add((source, variant))

    system_mutations = system.get("mutations")
    if not isinstance(system_mutations, list) or len(system_mutations) != 15:
        raise ValueError("pending-SYSTEM mutation inventory drift")
    for row in system_mutations:
        source = str(row.get("module", {}).get("path"))
        variant = str(row.get("mutated", {}).get("sha256"))
        if (
            row.get("compile_success_required") is not True
            or not source.startswith("npc/rv64/vsrc/")
            or len(variant) != 64
        ):
            raise ValueError("pending-SYSTEM production RTL mutation drift")
        production_fingerprints.add((source, variant))
    if len(production_fingerprints) != 17 or len(verification_fingerprints) != 1:
        raise ValueError("SERIALIZE mutation fingerprints are not unique")

    warnings = warning_audit([*qh_positive, *system_positive])
    receipt = {
        "schema": "rv64-v14e-serialize-fast-current-summary-v1",
        "status": "PASS",
        "debt_id": "SERIALIZE-G1",
        "scope_status": "CURRENT_FAST_DYNAMIC_PASS",
        "debt_current_status": "STALE_PENDING_FULL_SYSTEM",
        "current_design_id": DESIGN_ID,
        "positive_profiles": {"passed": 5, "required": 5},
        "compile_success_rtl_counterexamples": {
            "production_rtl_detected": 17,
            "production_rtl_required": 17,
            "unique_production_rtl_variant_fingerprints": 17,
            "verification_only_detected": 1,
            "verification_only_required": 1,
            "unique_verification_variant_fingerprints": 1,
        },
        "queue_head": artifact(qh_path),
        "pending_system": artifact(system_path),
        "warning_audit": warnings,
        "positive_assertion_failure_observed": False,
        "counterexample_rejection_observed": True,
        "source_identity": {
            "file_count": 146,
            "pre_post_equal": True,
            "before": artifact(before_path),
            "after": artifact(after_path),
        },
        "production_rtl_written": False,
        "transient_compiled_images_retained": 0,
        "full_system_recertification": {
            "required": True,
            "reason": "production RTL and actual elaborated RTL changed after the frozen A3 system transaction",
            "status": "NOT_RUN_IN_FAST_LAYER",
        },
        "architecture_gate_state": "RED",
        "ppa_state": "BLOCKED_BY_ARCHITECTURE",
    }
    output.write_text(json.dumps(receipt, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    print(
        "[V14E-SERIALIZE-FAST][PASS] positive=5/5 production_rtl_mutations=17/17 "
        "verification_only=1/1 unique_production_variants=17 "
        f"warnings={warnings['count']} source_unchanged=1 full_system=REQUIRED"
    )
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (OSError, ValueError, json.JSONDecodeError) as exc:
        print(f"[V14E-SERIALIZE-FAST][FAIL] {exc}", file=sys.stderr)
        raise SystemExit(1)
