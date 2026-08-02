#!/usr/bin/env python3
"""Aggregate all nine P0 gates without promoting the RV64 architecture state."""

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
V14B = (
    ROOT
    / ".github/task-runs/2026-08-02-rv64-v14b-architecture-current-"
    "freeze-audit-v1"
)
BASE_AUDIT = V14B / "evidence/section13-audit-1/section13-audit.json"
DIRECT_RECEIPT = (
    V14B / "evidence/p0-direct-rebind-checker-replay-1/rebind-receipt.json"
)
FINAL_P0_RECEIPT = HERE / "evidence/p0-final-2/receipt.json"


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
    parser.add_argument("--matrix", required=True, type=pathlib.Path)
    args = parser.parse_args()
    if args.output.exists() or args.matrix.exists():
        raise ValueError("refusing to replace Section13 current audit")

    base = load(BASE_AUDIT)
    final_p0 = load(FINAL_P0_RECEIPT)
    if (
        final_p0.get("status") != "PASS"
        or final_p0.get("current_design_id") != CURRENT_DESIGN_ID
        or final_p0.get("current_dynamic_gate_count") != 9
        or final_p0.get("replay_dependency_for_delivery") is not False
        or final_p0.get("p0_negative_observations", {}).get("detected") != 121
        or final_p0.get("p0_negative_observations", {}).get(
            "unique_rtl_variant_fingerprints"
        )
        != 114
        or final_p0.get("adjacent_non_p0_negative_observations", {}).get(
            "detected"
        )
        != 3
    ):
        raise ValueError("final P0 receipt is not nine-gate current-dynamic PASS")
    final_scope = set(final_p0.get("scope", ()))
    expected = set(base["architecture_debt"]["p0_current_stale"])
    if final_scope != expected:
        raise ValueError("final P0 receipt does not cover the nine stale entries")

    updated = copy.deepcopy(base)
    updated["schema"] = "rv64-v14c-section13-current-audit-v3"
    updated["generated_at_utc"] = datetime.datetime.now(
        datetime.timezone.utc
    ).isoformat()
    updated["audit_execution_status"] = "PASS"
    updated["current_design_id"] = CURRENT_DESIGN_ID
    debt = updated["architecture_debt"]
    for row in debt["entries"]:
        gate_id = row["id"]
        if gate_id in final_scope:
            row["effective_current_status"] = final_p0["scope_status"][gate_id]
            row["current_evidence_receipt"] = artifact(FINAL_P0_RECEIPT)
    debt["p0_current_stale"] = []
    debt["p0_current_bound"] = sorted(expected)
    debt["p0_current_bound_count"] = len(expected)
    debt["current_stale_count"] = len(debt["p1_current_stale"])
    debt["task_local_receipts"] = {
        "p0_final_current_dynamic": artifact(FINAL_P0_RECEIPT),
    }
    updated["p0_current_evidence_summary"] = {
        "gate_count": 9,
        "negative_observations": 121,
        "rtl_mutation_executions": 118,
        "oracle_probe_executions": 3,
        "unique_rtl_variant_fingerprints": 114,
        "rtl_variant_alias_pair_count": 4,
        "adjacent_p1_miq_flush_negative_observations": 3,
        "adjacent_p1_counted_in_p0": False,
        "replay_dependency_for_delivery": False,
    }

    updated["blockers"] = [
        blocker
        for blocker in updated["blockers"]
        if blocker["blocker_id"] != "SECTION13-P0-CURRENT-BINDING"
    ]
    updated["resolved_in_task_scope"] = [
        {
            "item_id": "SECTION13-P0-CURRENT-BINDING",
            "status": "GREEN_TASK_LOCAL",
            "current_bound": len(expected),
            "required": len(expected),
            "canonical_ledger_written": False,
        }
    ]
    updated["architecture_gate_state"] = "RED"
    updated["arch_stable"] = False
    updated["ppa_state"] = "BLOCKED_BY_ARCHITECTURE"
    updated["promotion_eligible"] = False
    updated["next_action"] = {
        "action_id": "P1-DIRECT-ACTIVE-CONE-REBIND",
        "debt_ids": ["CONTROL-EVENT-G1", "MIQ-FLUSH-G1", "STORE-BRESP-G1"],
        "reason": (
            "These P1 entries directly elaborate OooLoadQueue, OooStoreQueue, "
            "or OooMemAxiBridge from the current five-file RTL delta."
        ),
        "required_claims": [
            "current design-id",
            "positive directed RTL observation",
            "compile-success RTL counterexample rejection",
            "assertion-clean terminal marker",
            "source pre/post identity",
        ],
        "reusable_partial_evidence": {
            "MIQ-FLUSH-G1": {
                "negative_observations": 3,
                "classification": "PARTIAL_ONLY",
                "current_positive_and_full_receipt_still_required": True,
            }
        },
    }
    updated["write_boundary"]["canonical_architecture_written"] = False
    updated["write_boundary"]["canonical_debt_ledger_written"] = False

    if not updated["blockers"]:
        raise ValueError("Section13 audit unexpectedly has no remaining blockers")
    if any(blocker.get("status") != "RED" for blocker in updated["blockers"]):
        raise ValueError("remaining Section13 blocker lost fail-closed RED status")

    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(
        json.dumps(updated, indent=2, sort_keys=True) + "\n", encoding="utf-8"
    )
    lines = [
        "RV64 V14C Section13 blocker matrix",
        f"design-id: {CURRENT_DESIGN_ID}",
        "P0 current binding: GREEN_TASK_LOCAL 9/9",
        f"P1 current binding: RED stale={len(debt['p1_current_stale'])}",
        "historical defect backfill: RED current-bound=false",
        f"producer/holder semantic coverage: RED status={updated['holder_contract']['semantic_status']}",
        "functional aggregate: RED current-bound=false",
        f"freeze input inventory: RED empty-groups={len(updated['freeze']['empty_input_groups'])}",
        "architecture gate: RED",
        "arch-stable: false",
        "PPA: BLOCKED_BY_ARCHITECTURE",
        "canonical writes: 0",
    ]
    args.matrix.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(
        "[V14C-SECTION13][PASS] p0_current=9/9 p1_stale="
        f"{len(debt['p1_current_stale'])} blockers={len(updated['blockers'])} "
        "architecture=RED arch_stable=0 ppa=BLOCKED canonical_write=0"
    )
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (OSError, UnicodeDecodeError, ValueError, json.JSONDecodeError) as exc:
        print(f"[V14C-SECTION13][FAIL] {exc}", file=sys.stderr)
        raise SystemExit(1)
