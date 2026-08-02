#!/usr/bin/env python3
"""Bind three P1 direct gates while keeping Section 13 fail-closed."""

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
V14C = ROOT / ".github/task-runs/2026-08-02-rv64-v14c-p0-transitive-current-rebind-v1"
BASE_AUDIT = V14C / "evidence/section13-current-3/section13-current-audit.json"
P0_RECEIPT = V14C / "evidence/p0-final-2/receipt.json"
P1_RECEIPT = HERE / "evidence/p1-direct-1/receipt.json"
DIRECT_SCOPE = {"CONTROL-EVENT-G1", "MIQ-FLUSH-G1", "STORE-BRESP-G1"}
REMAINING_P1 = {"F0-G1", "FENCE-G1", "SERIALIZE-G1", "VECTORED-TRAP-G1"}


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
        raise ValueError(f"invalid Section13 artifact: {path}")
    return {
        "path": resolved.relative_to(ROOT).as_posix(),
        "sha256": digest(resolved),
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--output", required=True, type=pathlib.Path)
    parser.add_argument("--matrix", required=True, type=pathlib.Path)
    args = parser.parse_args()
    if args.output.exists() or args.matrix.exists():
        raise ValueError("refusing to replace V14D Section13 audit")

    base = load(BASE_AUDIT)
    p0 = load(P0_RECEIPT)
    p1 = load(P1_RECEIPT)
    debt_base = base.get("architecture_debt", {})
    if not (
        base.get("current_design_id") == CURRENT_DESIGN_ID
        and base.get("architecture_gate_state") == "RED"
        and base.get("arch_stable") is False
        and base.get("ppa_state") == "BLOCKED_BY_ARCHITECTURE"
        and set(debt_base.get("p0_current_bound", [])) == set(p0.get("scope", []))
        and len(debt_base.get("p0_current_bound", [])) == 9
        and set(debt_base.get("p1_current_stale", []))
        == DIRECT_SCOPE | REMAINING_P1
        and p1.get("schema") == "rv64-v14d-p1-direct-current-receipt-v1"
        and p1.get("status") == "PASS"
        and p1.get("current_design_id") == CURRENT_DESIGN_ID
        and set(p1.get("scope", [])) == DIRECT_SCOPE
        and p1.get("current_dynamic_gate_count") == 3
        and p1.get("positive_rtl", {}).get("passed") == 21
        and p1.get("compile_success_rtl_counterexamples", {}).get("detected")
        == 24
        and p1.get("compile_success_rtl_counterexamples", {}).get(
            "unique_rtl_variant_fingerprints"
        )
        == 24
        and p1.get("compile_success_rtl_counterexamples", {}).get("alias_count")
        == 0
        and p1.get("architecture_gate_state") == "RED"
        and p1.get("arch_stable") is False
        and p1.get("ppa_state") == "BLOCKED_BY_ARCHITECTURE"
    ):
        raise ValueError("Section13 P0/P1 input receipt drift")

    updated = copy.deepcopy(base)
    updated["schema"] = "rv64-v14d-section13-current-audit-v1"
    updated["generated_at_utc"] = datetime.datetime.now(
        datetime.timezone.utc
    ).isoformat()
    updated["audit_execution_status"] = "PASS"
    debt = updated["architecture_debt"]
    for row in debt["entries"]:
        if row["id"] in DIRECT_SCOPE:
            row["effective_current_status"] = p1["scope_status"][row["id"]]
            row["current_evidence_receipt"] = artifact(P1_RECEIPT)
    debt["p1_current_stale"] = sorted(REMAINING_P1)
    debt["p1_current_bound"] = sorted(DIRECT_SCOPE)
    debt["p1_current_bound_count"] = len(DIRECT_SCOPE)
    debt["current_stale_count"] = len(REMAINING_P1)
    debt.setdefault("task_local_receipts", {})["p1_direct_current_dynamic"] = artifact(
        P1_RECEIPT
    )
    updated["p1_direct_current_evidence_summary"] = {
        "gate_count": 3,
        "positive_rtl_observations": 21,
        "rtl_mutation_executions": 24,
        "unique_rtl_variant_fingerprints": 24,
        "rtl_variant_alias_count": 0,
        "replay_dependency_for_delivery": False,
        "historical_status_rewritten": False,
    }

    p1_blocker = None
    for blocker in updated["blockers"]:
        if blocker["blocker_id"] == "SECTION13-P1-CURRENT-BINDING":
            p1_blocker = blocker
            blocker["detail"] = "4 in-cohort P1 entries are not current-bound"
            blocker["items"] = sorted(REMAINING_P1)
            blocker["status"] = "RED"
    if p1_blocker is None:
        raise ValueError("Section13 P1 blocker is missing")
    updated.setdefault("resolved_in_task_scope", []).append(
        {
            "item_id": "SECTION13-P1-DIRECT-CURRENT-BINDING",
            "status": "GREEN_TASK_LOCAL",
            "current_bound": 3,
            "required": 3,
            "canonical_ledger_written": False,
        }
    )
    updated["architecture_gate_state"] = "RED"
    updated["arch_stable"] = False
    updated["ppa_state"] = "BLOCKED_BY_ARCHITECTURE"
    updated["promotion_eligible"] = False
    updated["next_action"] = {
        "action_id": "P1-REMAINING-CURRENT-REBIND",
        "debt_ids": sorted(REMAINING_P1),
        "reason": (
            "The three direct active-cone P1 gates are current-dynamic PASS; "
            "four in-cohort P1 gates still require current binding."
        ),
        "required_claims": [
            "current design-id",
            "gate-specific positive RTL observation",
            "compile-success RTL counterexample rejection",
            "assertion-clean terminal marker",
            "source pre/post identity",
        ],
    }
    updated["write_boundary"]["canonical_architecture_written"] = False
    updated["write_boundary"]["canonical_debt_ledger_written"] = False
    updated["write_boundary"]["canonical_historical_ledger_written"] = False
    updated["write_boundary"]["production_rtl_written"] = False

    if len(updated["blockers"]) != 6:
        raise ValueError("Section13 blocker count drift")
    if any(blocker.get("status") != "RED" for blocker in updated["blockers"]):
        raise ValueError("remaining Section13 blocker lost RED status")
    if not (
        updated["holder_contract"]["semantic_status"] == "GAP"
        and updated["functional_aggregate"]["current_bound"] is False
        and len(updated["freeze"]["empty_input_groups"]) == 12
    ):
        raise ValueError("Section13 non-P1 blocker drift")

    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(
        json.dumps(updated, indent=2, sort_keys=True) + "\n", encoding="utf-8"
    )
    lines = [
        "RV64 V14D Section13 blocker matrix",
        f"design-id: {CURRENT_DESIGN_ID}",
        "P0 current binding: GREEN_TASK_LOCAL 9/9",
        "P1 direct current binding: GREEN_TASK_LOCAL 3/3",
        "P1 remaining current binding: RED stale=4",
        "historical defect backfill: RED current-bound=false",
        "producer/holder semantic coverage: RED status=GAP",
        "functional aggregate: RED current-bound=false",
        "freeze input inventory: RED empty-groups=12",
        "architecture gate: RED",
        "arch-stable: false",
        "PPA: BLOCKED_BY_ARCHITECTURE",
        "canonical writes: 0",
    ]
    args.matrix.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(
        "[V14D-SECTION13][PASS] p0_current=9/9 p1_direct=3/3 "
        "p1_stale=4 blockers=6 architecture=RED arch_stable=0 "
        "ppa=BLOCKED canonical_write=0"
    )
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (OSError, UnicodeDecodeError, ValueError, json.JSONDecodeError) as exc:
        print(f"[V14D-SECTION13][FAIL] {exc}", file=sys.stderr)
        raise SystemExit(1)
