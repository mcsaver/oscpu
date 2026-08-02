#!/usr/bin/env python3
"""Validate task-local MEM-ISSUE-G1/PTW-PMP-G1 current-design evidence."""

from __future__ import annotations

import argparse
import copy
import datetime
import hashlib
import json
import pathlib
import sys
from typing import Any


HERE = pathlib.Path(__file__).resolve().parent
ROOT = HERE.parents[2]
CURRENT_DESIGN_ID = (
    "sha256:093c2380b997029944aa4462015d83711d7c5f1d52b15b4803c4515a581a7488"
)
SECTION13_AUDIT = (
    HERE / "evidence/section13-audit-1/section13-audit.json"
)


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


def workspace_path(relative: str) -> pathlib.Path:
    path = (ROOT / relative).resolve(strict=True)
    if not path.is_relative_to(ROOT) or not path.is_file():
        raise ValueError(f"invalid workspace file: {relative}")
    return path


def artifact(path: pathlib.Path) -> dict[str, str]:
    resolved = path.resolve(strict=True)
    if not resolved.is_relative_to(ROOT) or not resolved.is_file():
        raise ValueError(f"invalid result artifact: {path}")
    return {
        "path": resolved.relative_to(ROOT).as_posix(),
        "sha256": digest(resolved),
    }


def verify_result(
    payload: dict[str, Any], schema: str, label: str
) -> None:
    if payload.get("schema") != schema:
        raise ValueError(f"{label}: result schema mismatch")
    if payload.get("status") != "PASS":
        raise ValueError(f"{label}: result status is not PASS")
    if payload.get("design_id") != CURRENT_DESIGN_ID:
        raise ValueError(f"{label}: current design-id mismatch")


def verify_mutations(payload: dict[str, Any], label: str) -> None:
    required = payload.get("required")
    if (
        not isinstance(required, int)
        or required <= 0
        or payload.get("compile_success") != required
        or payload.get("dynamic_rejected") != required
        or payload.get("source_unchanged") is not True
    ):
        raise ValueError(f"{label}: compile-success RTL mutation closure failed")


def negative_self_test(
    mem_result: dict[str, Any], mem_mutation: dict[str, Any]
) -> dict[str, Any]:
    cases: list[dict[str, str]] = []

    def expect_reject(case_id: str, action: Any) -> None:
        try:
            action()
        except ValueError as exc:
            cases.append({"case_id": case_id, "status": "REJECTED",
                          "reason": str(exc)})
            return
        raise ValueError(f"negative fixture was accepted: {case_id}")

    wrong_design = copy.deepcopy(mem_result)
    wrong_design["design_id"] = "sha256:" + "0" * 64
    expect_reject(
        "result-design-id-drift",
        lambda: verify_result(
            wrong_design, "npc-rv64-memory-issue-lifecycle-evidence-v1",
            "MEM-ISSUE-G1",
        ),
    )
    fail_status = copy.deepcopy(mem_result)
    fail_status["status"] = "FAIL"
    expect_reject(
        "result-status-fail",
        lambda: verify_result(
            fail_status, "npc-rv64-memory-issue-lifecycle-evidence-v1",
            "MEM-ISSUE-G1",
        ),
    )
    missing_kill = copy.deepcopy(mem_mutation)
    missing_kill["dynamic_rejected"] = missing_kill["required"] - 1
    expect_reject(
        "mutation-not-rejected",
        lambda: verify_mutations(missing_kill, "MEM-ISSUE-G1"),
    )
    source_changed = copy.deepcopy(mem_mutation)
    source_changed["source_unchanged"] = False
    expect_reject(
        "mutation-source-writeback",
        lambda: verify_mutations(source_changed, "MEM-ISSUE-G1"),
    )
    return {"required": 4, "detected": len(cases), "cases": cases}


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--evidence-dir", required=True, type=pathlib.Path)
    parser.add_argument("--output", required=True, type=pathlib.Path)
    args = parser.parse_args()
    evidence_dir = args.evidence_dir.resolve(strict=True)
    output = args.output.resolve()
    evidence_root = (HERE / "evidence").resolve()
    if (
        not evidence_dir.is_relative_to(evidence_root)
        or evidence_dir.name != "p0-direct-rebind-1"
        or not output.parent.is_relative_to(evidence_root)
        or not output.parent.name.startswith(
            "p0-direct-rebind-checker-replay-"
        )
        or not output.parent.name[len("p0-direct-rebind-checker-replay-"):].isdigit()
        or output.name != "rebind-receipt.json"
    ):
        raise ValueError("receipt must bind p0-direct-rebind-1 into a task-local checker replay")
    if output.exists():
        raise ValueError("receipt already exists")

    mem_result_path = evidence_dir / "memory-issue-lifecycle-current.json"
    ptw_result_path = evidence_dir / "ptw-pmp-current.json"
    mem_mutation_path = evidence_dir / "mem/mutations/summary.json"
    ptw_mutation_path = evidence_dir / "ptw/mutations/summary.json"
    post_result_path = output.parent / "source-post-result.json"
    mem_raw_path = evidence_dir / "memory-issue-lifecycle.log"
    ptw_raw_path = evidence_dir / "ptw-pmp.log"

    mem_result = load(mem_result_path)
    ptw_result = load(ptw_result_path)
    mem_mutation = load(mem_mutation_path)
    ptw_mutation = load(ptw_mutation_path)
    post_result = load(post_result_path)
    audit = load(SECTION13_AUDIT)
    verify_result(
        mem_result, "npc-rv64-memory-issue-lifecycle-evidence-v1",
        "MEM-ISSUE-G1",
    )
    verify_result(ptw_result, "npc-rv64-ptw-pmp-evidence-v4", "PTW-PMP-G1")
    verify_mutations(mem_mutation, "MEM-ISSUE-G1")
    verify_mutations(ptw_mutation, "PTW-PMP-G1")
    negative_fixtures = negative_self_test(mem_result, mem_mutation)

    source_set = post_result.get("rtl_source_set", {})
    if (
        post_result.get("overall_status") != "GREEN"
        or post_result.get("exit_code") != 0
        or source_set.get("design_id") != CURRENT_DESIGN_ID
        or source_set.get("file_count") != 146
    ):
        raise ValueError("post-run full RTL identity or directed checker drift")
    before_files = load(
        workspace_path(
            ".github/task-runs/2026-08-02-rv64-v14a-di2-current-rebind-v1/"
            "evidence/di2-current/static/architecture-result.json"
        )
    )["rtl_source_set"]["files"]
    if source_set.get("files") != before_files:
        raise ValueError("production RTL source map changed during P0 rebind")

    canonical_checks = {
        "architecture": (
            "npc/rv64/eval/ppa/evidence/architecture-current.json",
            audit["write_boundary"]["canonical_architecture"]["sha256"],
        ),
        "architecture_debt": (
            "npc/rv64/design/arch/architecture-debt-ledger.json",
            audit["architecture_debt"]["ledger"]["sha256"],
        ),
        "historical_defect": (
            "npc/rv64/design/arch/historical-defect-backfill-ledger.json",
            audit["historical_defect_backfill"]["ledger"]["sha256"],
        ),
    }
    canonical_unchanged: dict[str, dict[str, Any]] = {}
    for label, (relative, expected) in canonical_checks.items():
        path = workspace_path(relative)
        actual = digest(path)
        canonical_unchanged[label] = {
            "path": relative,
            "sha256_before": expected,
            "sha256_after": actual,
            "unchanged": actual == expected,
        }
        if actual != expected:
            raise ValueError(f"canonical {label} changed during task-local rebind")

    mem_raw = mem_raw_path.read_text(encoding="utf-8")
    ptw_raw = ptw_raw_path.read_text(encoding="utf-8")
    for label, text in (("MEM-ISSUE-G1", mem_raw), ("PTW-PMP-G1", ptw_raw)):
        if "[RESULT] FAIL" in text or "[CHECK-FAIL]" in text or "FATAL:" in text:
            raise ValueError(f"{label}: positive raw log contains failure marker")

    result = {
        "schema": "rv64-v14b-p0-direct-rebind-receipt-v1",
        "generated_at_utc": datetime.datetime.now(
            datetime.timezone.utc
        ).isoformat(),
        "status": "PASS",
        "current_design_id": CURRENT_DESIGN_ID,
        "scope": ["MEM-ISSUE-G1", "PTW-PMP-G1"],
        "scope_status": {
            "MEM-ISSUE-G1": "CURRENT_DYNAMIC_PASS",
            "PTW-PMP-G1": "CURRENT_DYNAMIC_PASS",
        },
        "positive_rtl": {
            "memory_issue_lifecycle": artifact(mem_result_path),
            "ptw_pmp": artifact(ptw_result_path),
            "memory_issue_raw": artifact(mem_raw_path),
            "ptw_pmp_raw": artifact(ptw_raw_path),
        },
        "compile_success_rtl_counterexamples": {
            "memory_issue_lifecycle": {
                "detected": mem_mutation["dynamic_rejected"],
                "required": mem_mutation["required"],
                "summary": artifact(mem_mutation_path),
            },
            "ptw_pmp": {
                "detected": ptw_mutation["dynamic_rejected"],
                "required": ptw_mutation["required"],
                "summary": artifact(ptw_mutation_path),
            },
        },
        "checker_negative_fixtures": negative_fixtures,
        "source_run": {
            "status": "FAIL",
            "status_path": (
                ".github/task-runs/2026-08-02-rv64-v14b-architecture-"
                "current-freeze-audit-v1/p0-direct-rebind-1.status"
            ),
            "failure_classification": (
                "LEGACY_CANONICAL_UNIT_TEST_SCOPE_MISMATCH_AFTER_CURRENT_"
                "TASK_LOCAL_RTL_PASS"
            ),
            "historical_status_rewritten": False,
        },
        "source_identity": {
            "file_count": 146,
            "pre_post_equal": True,
            "post_checker": artifact(post_result_path),
        },
        "canonical_unchanged": canonical_unchanged,
        "publication": {
            "task_local_only": True,
            "architecture_debt_ledger_written": False,
            "canonical_architecture_written": False,
            "architecture_gate_state": "RED",
            "arch_stable": False,
            "ppa_state": "BLOCKED_BY_ARCHITECTURE",
            "promotion_eligible": False,
        },
        "remaining_scope": {
            "p0_not_current_bound": [
                item for item in audit["architecture_debt"]["p0_current_stale"]
                if item not in {"MEM-ISSUE-G1", "PTW-PMP-G1"}
            ],
            "p1_not_current_bound": audit["architecture_debt"][
                "p1_current_stale"
            ],
            "holder_semantic_status": audit["holder_contract"][
                "semantic_status"
            ],
            "functional_current_bound": audit["functional_aggregate"][
                "current_bound"
            ],
            "freeze_empty_input_groups": audit["freeze"][
                "empty_input_groups"
            ],
        },
    }
    output.write_text(
        json.dumps(result, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )
    print(
        "[V14B-P0-DIRECT-REBIND][PASS] "
        f"design_id={CURRENT_DESIGN_ID} mem_mutations="
        f"{mem_mutation['dynamic_rejected']}/{mem_mutation['required']} "
        f"ptw_mutations={ptw_mutation['dynamic_rejected']}/"
        f"{ptw_mutation['required']} negative=4/4 source_pre_post=equal "
        "canonical_write=0 architecture=RED arch_stable=0 ppa=BLOCKED"
    )
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (OSError, UnicodeDecodeError, ValueError, json.JSONDecodeError) as exc:
        print(f"[V14B-P0-DIRECT-REBIND][FAIL] {exc}", file=sys.stderr)
        raise SystemExit(1)
