#!/usr/bin/env python3
"""Build the three-gate current-dynamic P1 direct RTL receipt."""

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
CURRENT_DESIGN_ID = (
    "sha256:093c2380b997029944aa4462015d83711d7c5f1d52b15b4803c4515a581a7488"
)
V14B = ROOT / ".github/task-runs/2026-08-02-rv64-v14b-architecture-current-freeze-audit-v1"
MIQ_RECEIPT = (
    V14B / "evidence/p0-direct-rebind-1/memory-issue-lifecycle-current.json"
)
MIQ_REBIND_RECEIPT = (
    V14B / "evidence/p0-direct-rebind-checker-replay-1/rebind-receipt.json"
)
MIQ_SUMMARY = V14B / "evidence/p0-direct-rebind-1/mem/mutations/summary.json"
MIQ_LOG = (
    V14B
    / "evidence/p0-direct-rebind-1/mem/focused/miq-flush/logs/"
    "tb_ooo_mem_inflight_queue.log"
)
MIQ_RUNNER = (
    ROOT
    / ".github/task-runs/2026-07-22-rv64-v9f-memory-issue-lifecycle/"
    "run-memory-lifecycle-variants.py"
)
CONTROL_SUMMARY = HERE / "evidence/control-run-3/summary.json"
STORE_SUMMARY = HERE / "evidence/store-run-3/summary.json"


def load_module(path: pathlib.Path, name: str) -> Any:
    spec = importlib.util.spec_from_file_location(name, path)
    if spec is None or spec.loader is None:
        raise ValueError(f"cannot load module: {path}")
    module = importlib.util.module_from_spec(spec)
    sys.modules[name] = module
    spec.loader.exec_module(module)
    return module


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
        raise ValueError(f"invalid P1 direct artifact: {path}")
    return {
        "path": resolved.relative_to(ROOT).as_posix(),
        "sha256": digest(resolved),
    }


def validate_artifact(record: dict[str, Any]) -> pathlib.Path:
    path = ROOT / str(record.get("path", ""))
    if not path.is_file() or digest(path) != record.get("sha256"):
        raise ValueError(f"artifact hash drift: {record.get('path')}")
    return path


def validate_status(path: pathlib.Path, expected: str) -> dict[str, str]:
    if path.read_text(encoding="utf-8").strip() != expected:
        raise ValueError(f"task-run status drift: {path.name}")
    return artifact(path)


def validate_miq(
    source_snapshot: dict[str, Any],
) -> tuple[dict[str, Any], list[dict[str, Any]], dict[str, Any]]:
    receipt = load(MIQ_RECEIPT)
    rebind = load(MIQ_REBIND_RECEIPT)
    summary = load(MIQ_SUMMARY)
    if not (
        receipt.get("status") == "PASS"
        and receipt.get("design_id") == CURRENT_DESIGN_ID
        and receipt.get("claim", {}).get("architecture_debts", {}).get(
            "MIQ-FLUSH-G1"
        )
        == "CLOSED_ELIGIBLE"
        and receipt.get("focused_tests", {}).get("miq_flush_lifecycle", {}).get(
            "status"
        )
        == "PASS"
        and receipt.get("provenance", {}).get("rtl_sha256")
        == CURRENT_DESIGN_ID.removeprefix("sha256:")
        and receipt.get("provenance", {}).get("files")
        == source_snapshot.get("files")
        and receipt.get("invariants", {}).get(
            "flush_compaction_preserves_fifo_order"
        )
        is True
        and receipt.get("invariants", {}).get(
            "flush_preserves_unconsumed_drain_identity"
        )
        is True
        and receipt.get("invariants", {}).get(
            "flush_preserves_valid_drain_head_without_pop_fire"
        )
        is True
        and receipt.get("invariants", {}).get(
            "flush_subtracts_exact_fired_drain_head"
        )
        is True
        and rebind.get("status") == "PASS"
        and rebind.get("current_design_id") == CURRENT_DESIGN_ID
        and rebind.get("positive_rtl", {}).get("memory_issue_lifecycle")
        == artifact(MIQ_RECEIPT)
        and rebind.get("compile_success_rtl_counterexamples", {}).get(
            "memory_issue_lifecycle", {}
        ).get("summary")
        == artifact(MIQ_SUMMARY)
        and rebind.get("source_identity", {}).get("file_count") == 146
        and rebind.get("source_identity", {}).get("pre_post_equal") is True
        and rebind.get("publication", {}).get("architecture_gate_state") == "RED"
    ):
        raise ValueError("MIQ-FLUSH current receipt chain drift")
    validate_status(
        V14B / "p0-direct-rebind-1.status",
        "FAIL rc=1 stage=evidence-complete evidence_complete=0 cleanup_rc=0",
    )
    validate_status(V14B / "p0-direct-rebind-checker-replay-1.status", "PASS")

    text = MIQ_LOG.read_text(encoding="utf-8")
    miq_marker = (
        "[MIQ-FLUSH-G1-FOCUSED] consumed_drain_removed=1 "
        "stalled_head_no_pop_preserved=1 unconsumed_drain_preserved=1 "
        "survivor_identity_match=1 wrapped_order=1 PASS"
    )
    if not (
        text.count("[COMPILE] ") == 1
        and text.count(miq_marker) == 1
        and text.count("[PASS] tb_ooo_mem_inflight_queue") == 1
        and text.count("[RESULT] PASS") == 1
        and not any(
            marker in text
            for marker in ("[RESULT] FAIL", "[CHECK-FAIL]", "[TIMEOUT]", "FATAL:")
        )
        and digest(MIQ_LOG)
        == receipt["focused_tests"]["miq_flush_lifecycle"]["log_sha256"]
    ):
        raise ValueError("MIQ-FLUSH positive RTL log drift")

    runner = load_module(MIQ_RUNNER, "v14d_p1_miq_runner")
    specs = {
        spec.name: spec
        for spec in runner.VARIANTS
        if spec.debt_id == "MIQ-FLUSH-G1"
    }
    rows = [
        row
        for row in summary.get("results", [])
        if row.get("debt_id") == "MIQ-FLUSH-G1"
    ]
    by_name = {row.get("name"): row for row in rows}
    if not (
        summary.get("schema") == runner.SCHEMA
        and summary.get("by_debt", {}).get("MIQ-FLUSH-G1")
        == {"required": 3, "compile_success": 3, "dynamic_rejected": 3}
        and summary.get("source_unchanged") is True
        and set(by_name) == set(specs)
    ):
        raise ValueError("MIQ-FLUSH mutation inventory drift")
    inventory: list[dict[str, Any]] = []
    for name, spec in specs.items():
        row = by_name[name]
        original, mutated = runner.reconstruct_variant(ROOT, spec)
        original_sha = hashlib.sha256(original.encode("utf-8")).hexdigest()
        variant_sha = hashlib.sha256(mutated.encode("utf-8")).hexdigest()
        log_path = validate_artifact(row.get("log", {}))
        mutation_text = log_path.read_text(encoding="utf-8")
        if not (
            row.get("source") == spec.source_rel
            and row.get("test_name") == spec.test_name
            and row.get("original_sha256") == original_sha
            and row.get("variant_sha256") == variant_sha
            and row.get("compile_success") is True
            and row.get("dynamic_rejected") is True
            and row.get("marker_observed") is True
            and spec.expected_marker in mutation_text
            and "[RESULT] FAIL status=" in mutation_text
            and "[RESULT] PASS" not in mutation_text
        ):
            raise ValueError(f"MIQ-FLUSH mutation drift: {name}")
        inventory.append(
            {
                "item_id": f"MIQ-FLUSH-G1:RTL_MUTATION:{name}",
                "debt_id": "MIQ-FLUSH-G1",
                "name": name,
                "source": spec.source_rel,
                "variant_sha256": variant_sha,
                "log": artifact(log_path),
            }
        )
    sys.path.insert(0, str(HERE))
    from warning_audit import audit

    warning = audit([MIQ_LOG])
    return (
        {
            "required": 1,
            "passed": 1,
            "log": artifact(MIQ_LOG),
            "receipt": artifact(MIQ_RECEIPT),
            "rebind_receipt": artifact(MIQ_REBIND_RECEIPT),
        },
        inventory,
        warning,
    )


def validate_gate_summary(
    gate_id: str,
    summary_path: pathlib.Path,
    expected_schema: str,
    expected_positive: int,
    expected_negative: int,
    status_path: pathlib.Path,
    source_snapshot: dict[str, Any],
) -> tuple[list[dict[str, Any]], list[dict[str, Any]], dict[str, Any]]:
    summary = load(summary_path)
    if not (
        summary.get("schema") == expected_schema
        and summary.get("status") == "PASS"
        and summary.get("debt_id") == gate_id
        and summary.get("current_design_id") == CURRENT_DESIGN_ID
        and summary.get("scope_status") == "CURRENT_DYNAMIC_PASS"
        and summary.get("positive", {}).get("required") == expected_positive
        and summary.get("positive", {}).get("passed") == expected_positive
        and summary.get("compile_success_rtl_counterexamples", {}).get(
            "required"
        )
        == expected_negative
        and summary.get("compile_success_rtl_counterexamples", {}).get(
            "detected"
        )
        == expected_negative
        and summary.get("source_identity", {}).get("file_count") == 146
        and summary.get("source_identity", {}).get("pre_post_equal") is True
        and summary.get("canonical_ledger_unchanged") is True
        and summary.get("assertion_failure_observed") is False
        and summary.get("transient_compiled_images_retained") == 0
        and summary.get("promotion_eligible") is False
        and summary.get("ppa") == "BLOCKED_BY_ARCHITECTURE"
        and summary.get("warning_audit", {}).get("unexplained_warning_count") == 0
        and summary.get("warning_audit", {}).get("assertion_failure_observed")
        is False
    ):
        raise ValueError(f"{gate_id} final summary drift")
    before_path = validate_artifact(summary["source_identity"]["before"])
    after_path = validate_artifact(summary["source_identity"]["after"])
    if load(before_path) != source_snapshot or load(after_path) != source_snapshot:
        raise ValueError(f"{gate_id} source snapshot cohort drift")
    validate_status(status_path, "PASS")

    positive_rows: list[dict[str, Any]] = []
    for key, value in summary["positive"].items():
        if key in {"required", "passed"}:
            continue
        for row in value:
            validate_artifact(row["log"])
            positive_rows.append(
                {
                    "debt_id": gate_id,
                    "test": row["test"],
                    "log": row["log"],
                }
            )
    negative_rows: list[dict[str, Any]] = []
    negatives = summary["compile_success_rtl_counterexamples"]
    for key, value in negatives.items():
        if key in {
            "required",
            "detected",
            "v9o_raw_summary",
            "v9o_checker_replay",
            "v9n_receipt",
            "v13r_summary",
            "v13r_checker_replay",
        }:
            continue
        if not isinstance(value, list):
            continue
        for row in value:
            validate_artifact(row["log"])
            negative_rows.append(
                {
                    "item_id": f"{gate_id}:RTL_MUTATION:{row['name']}",
                    "debt_id": gate_id,
                    "name": row["name"],
                    "source": row["source"],
                    "variant_sha256": row["variant_sha256"],
                    "log": row["log"],
                }
            )
    if len(positive_rows) != expected_positive or len(negative_rows) != expected_negative:
        raise ValueError(f"{gate_id} expanded row count drift")
    return positive_rows, negative_rows, summary["warning_audit"]


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--evidence", required=True, type=pathlib.Path)
    parser.add_argument("--output", required=True, type=pathlib.Path)
    args = parser.parse_args()
    evidence = args.evidence.resolve(strict=True)
    output = args.output.resolve()
    if not evidence.is_relative_to(HERE / "evidence") or not output.is_relative_to(evidence):
        raise ValueError("P1 direct receipt path escaped V14D evidence")
    if output.exists():
        raise ValueError("refusing to replace P1 direct receipt")
    before = load(evidence / "source-before.json")
    after = load(evidence / "source-after.json")
    if not (
        before == after
        and before.get("design_id") == CURRENT_DESIGN_ID
        and before.get("file_count") == 146
    ):
        raise ValueError("P1 direct final source identity drift")
    if (evidence / "canonical-before.sha256").read_bytes() != (
        evidence / "canonical-after.sha256"
    ).read_bytes():
        raise ValueError("P1 direct canonical ledger write detected")

    miq_positive, miq_negative, miq_warning = validate_miq(before)
    control_positive, control_negative, control_warning = validate_gate_summary(
        "CONTROL-EVENT-G1",
        CONTROL_SUMMARY,
        "rv64-v14d-control-event-current-summary-v1",
        16,
        16,
        HERE / "control-run-3.status",
        before,
    )
    store_positive, store_negative, store_warning = validate_gate_summary(
        "STORE-BRESP-G1",
        STORE_SUMMARY,
        "rv64-v14d-store-bresp-current-summary-v1",
        4,
        5,
        HERE / "store-run-3.status",
        before,
    )
    inventory = [*miq_negative, *control_negative, *store_negative]
    fingerprints = {(row["source"], row["variant_sha256"]) for row in inventory}
    item_ids = {row["item_id"] for row in inventory}
    if len(inventory) != 24 or len(fingerprints) != 24 or len(item_ids) != 24:
        raise ValueError("P1 direct counterexample uniqueness drift")

    result = {
        "schema": "rv64-v14d-p1-direct-current-receipt-v1",
        "status": "PASS",
        "current_design_id": CURRENT_DESIGN_ID,
        "scope": ["CONTROL-EVENT-G1", "MIQ-FLUSH-G1", "STORE-BRESP-G1"],
        "scope_status": {
            "CONTROL-EVENT-G1": "CURRENT_DYNAMIC_PASS",
            "MIQ-FLUSH-G1": "CURRENT_DYNAMIC_PASS",
            "STORE-BRESP-G1": "CURRENT_DYNAMIC_PASS",
        },
        "current_dynamic_gate_count": 3,
        "positive_rtl": {
            "required": 21,
            "passed": 1 + len(control_positive) + len(store_positive),
            "by_gate": {
                "MIQ-FLUSH-G1": miq_positive,
                "CONTROL-EVENT-G1": {
                    "required": 16,
                    "passed": len(control_positive),
                    "summary": artifact(CONTROL_SUMMARY),
                },
                "STORE-BRESP-G1": {
                    "required": 4,
                    "passed": len(store_positive),
                    "summary": artifact(STORE_SUMMARY),
                },
            },
        },
        "compile_success_rtl_counterexamples": {
            "required": 24,
            "detected": len(inventory),
            "unique_rtl_variant_fingerprints": len(fingerprints),
            "alias_count": len(inventory) - len(fingerprints),
            "by_gate": {
                "MIQ-FLUSH-G1": 3,
                "CONTROL-EVENT-G1": 16,
                "STORE-BRESP-G1": 5,
            },
            "inventory": inventory,
        },
        "source_identity": {
            "file_count": 146,
            "pre_post_equal": True,
            "before": artifact(evidence / "source-before.json"),
            "after": artifact(evidence / "source-after.json"),
        },
        "warning_audit": {
            "unexplained_warning_count": 0,
            "assertion_failure_observed": False,
            "by_gate": {
                "MIQ-FLUSH-G1": miq_warning,
                "CONTROL-EVENT-G1": control_warning,
                "STORE-BRESP-G1": store_warning,
            },
        },
        "historical_status_rewritten": False,
        "canonical_ledger_unchanged": True,
        "production_rtl_written": False,
        "transient_compiled_images_retained": 0,
        "architecture_gate_state": "RED",
        "arch_stable": False,
        "ppa_state": "BLOCKED_BY_ARCHITECTURE",
        "promotion_eligible": False,
    }
    if result["positive_rtl"]["passed"] != 21:
        raise ValueError("P1 direct positive count drift")
    output.write_text(
        json.dumps(result, indent=2, sort_keys=True) + "\n", encoding="utf-8"
    )
    print(
        "[V14D-P1-DIRECT][PASS] gates=3/3 positive=21/21 "
        "mutations=24/24 unique_variants=24 aliases=0 source_unchanged=1 "
        "architecture=RED ppa=BLOCKED"
    )
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (OSError, UnicodeDecodeError, ValueError, json.JSONDecodeError) as exc:
        print(f"[V14D-P1-DIRECT][FAIL] {exc}", file=sys.stderr)
        raise SystemExit(1)
