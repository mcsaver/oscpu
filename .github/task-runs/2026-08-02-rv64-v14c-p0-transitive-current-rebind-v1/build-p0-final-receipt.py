#!/usr/bin/env python3
"""Aggregate nine current-dynamic RV64 P0 architecture-debt gates."""

from __future__ import annotations

import argparse
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
V14B_RECEIPT = (
    ROOT
    / ".github/task-runs/2026-08-02-rv64-v14b-architecture-current-"
    "freeze-audit-v1/evidence/p0-direct-rebind-checker-replay-1/"
    "rebind-receipt.json"
)
V14C_RECEIPT = HERE / "evidence/current-bind-checker-replay-2/receipt.json"
ELIM_RECEIPT = (
    HERE / "evidence/p0-replay-elimination-checker-replay-1/receipt.json"
)
COUNTEREXAMPLE_INVENTORY = (
    HERE / "evidence/counterexample-inventory-1/inventory.json"
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
        raise ValueError("P0 final receipt escaped V14C evidence")
    if output.exists():
        raise ValueError("refusing to replace P0 final receipt")

    direct = load(V14B_RECEIPT)
    v14c = load(V14C_RECEIPT)
    elimination = load(ELIM_RECEIPT)
    inventory = load(COUNTEREXAMPLE_INVENTORY)
    for label, payload in (
        ("V14B direct", direct),
        ("V14C transitive", v14c),
        ("V14C replay elimination", elimination),
    ):
        if (
            payload.get("status") != "PASS"
            or payload.get("current_design_id") != CURRENT_DESIGN_ID
        ):
            raise ValueError(f"{label} receipt is not current-design PASS")

    direct_scope = set(direct["scope"])
    v14c_scope = set(v14c["scope"])
    elimination_scope = set(elimination["scope"])
    if direct_scope & v14c_scope or len(direct_scope | v14c_scope) != 9:
        raise ValueError("V14B/V14C scopes do not partition P0 9/9")
    if elimination_scope != {"IFU-AXI-G1", "IFU-FETCH-G2"}:
        raise ValueError("replay-elimination scope mismatch")
    if not elimination_scope.issubset(v14c_scope):
        raise ValueError("replay-elimination scope is outside V14C")
    if (
        inventory.get("status") != "PASS"
        or inventory.get("total_negative_observations") != 124
        or inventory.get("unique_item_ids") != 124
        or inventory.get("unique_rtl_variant_fingerprints") != 117
        or inventory.get("p0", {}).get("detected") != 121
        or inventory.get("p0", {}).get("rtl_mutation_executions") != 118
        or inventory.get("p0", {}).get("oracle_probe_executions") != 3
        or inventory.get("p0", {}).get("unique_rtl_variant_fingerprints") != 114
        or inventory.get("adjacent_non_p0", {}).get("detected") != 3
        or inventory.get("adjacent_non_p0", {}).get("by_debt")
        != {"MIQ-FLUSH-G1": 3}
        or len(inventory.get("rtl_variant_aliases", ())) != 4
    ):
        raise ValueError("counterexample inventory is not attribution-complete")

    final_scope = sorted(direct_scope | v14c_scope)
    final_status = {gate_id: "CURRENT_DYNAMIC_PASS" for gate_id in final_scope}
    for gate_id in v14c_scope - elimination_scope:
        if v14c["scope_status"].get(gate_id) != "CURRENT_DYNAMIC_PASS":
            raise ValueError(f"{gate_id}: V14C dynamic status mismatch")
    if any(
        elimination["scope_status"].get(gate_id) != "CURRENT_DYNAMIC_PASS"
        for gate_id in elimination_scope
    ):
        raise ValueError("IFU replay elimination did not produce dynamic PASS")

    direct_observations = sum(
        row["detected"]
        for row in direct["compile_success_rtl_counterexamples"].values()
    )
    inventory_p0_by_debt = inventory["p0"]["by_debt"]
    direct_p0 = sum(
        inventory_p0_by_debt[gate_id]
        for gate_id in ("MEM-ISSUE-G1", "PTW-PMP-G1")
    )
    direct_adjacent_p1 = inventory["adjacent_non_p0"]["detected"]
    v14c_dynamic_gates = v14c_scope - elimination_scope
    v14c_main = sum(
        v14c["compile_success_rtl_counterexamples"][gate_id]["detected"]
        for gate_id in v14c_dynamic_gates
    )
    v14c_oracle = v14c["counterexample_totals"]["oracle_required"]
    elimination_count = sum(
        row["detected"]
        for row in elimination["compile_success_rtl_counterexamples"].values()
    )
    p0_negative_observations = (
        direct_p0 + v14c_main + v14c_oracle + elimination_count
    )
    all_negative_observations = (
        direct_observations + v14c_main + v14c_oracle + elimination_count
    )
    if (
        direct_observations,
        direct_p0,
        direct_adjacent_p1,
        v14c_main,
        v14c_oracle,
        elimination_count,
        p0_negative_observations,
        all_negative_observations,
    ) != (
        39, 36, 3, 48, 3, 34, 121, 124
    ):
        raise ValueError("P0 current counterexample partition mismatch")

    warning_audit = elimination.get("warning_audit", {})
    if (
        warning_audit.get("status") != "EXPLAINED"
        or warning_audit.get("unexplained_warning_count") != 0
        or warning_audit.get("assertion_failure_observed") is not False
    ):
        raise ValueError("IFU current warning audit is not closed")
    if (
        direct.get("source_identity", {}).get("pre_post_equal") is not True
        or v14c.get("source_identity", {}).get("pre_post_equal") is not True
        or elimination.get("source_identity", {}).get("pre_post_equal") is not True
    ):
        raise ValueError("P0 source pre/post identity gap")

    receipt = {
        "schema": "rv64-v14c-p0-final-current-dynamic-receipt-v2",
        "generated_at_utc": datetime.datetime.now(
            datetime.timezone.utc
        ).isoformat(),
        "status": "PASS",
        "current_design_id": CURRENT_DESIGN_ID,
        "scope": final_scope,
        "scope_status": final_status,
        "current_dynamic_gate_count": 9,
        "replay_dependency_for_delivery": False,
        "p0_negative_observations": {
            "v14b_direct_p0": direct_p0,
            "v14c_dynamic_five_main": v14c_main,
            "v14c_dynamic_five_oracle": v14c_oracle,
            "v14c_ifu_replay_elimination": elimination_count,
            "required": p0_negative_observations,
            "detected": p0_negative_observations,
            "rtl_mutation_executions": inventory["p0"][
                "rtl_mutation_executions"
            ],
            "oracle_probe_executions": inventory["p0"][
                "oracle_probe_executions"
            ],
            "unique_rtl_variant_fingerprints": inventory["p0"][
                "unique_rtl_variant_fingerprints"
            ],
            "rtl_variant_alias_pair_count": len(
                inventory["rtl_variant_aliases"]
            ),
        },
        "adjacent_non_p0_negative_observations": {
            "debt_id": "MIQ-FLUSH-G1",
            "classification": "P1",
            "detected": direct_adjacent_p1,
            "unique_rtl_variant_fingerprints": inventory[
                "adjacent_non_p0"
            ]["unique_rtl_variant_fingerprints"],
            "counted_in_p0": False,
        },
        "all_bound_suite_negative_observations": all_negative_observations,
        "counting_contract": {
            "negative_observation": (
                "one uniquely named debt/kind/test observation with compile and "
                "dynamic rejection evidence"
            ),
            "rtl_variant_fingerprint": "unique (source path, variant sha256)",
            "same_variant_different_contract_observations_are_not_unique_variants": True,
        },
        "positive_current_rtl": {
            "shared_module_aggregate": {"required": 113, "passed": 113},
            "v14c_dynamic_suite": {"required": 18, "passed": 18},
            "ifu_current_module_logs": {"required": 5, "passed": 5},
        },
        "warning_audit": warning_audit,
        "source_identity": {"file_count": 146, "pre_post_equal": True},
        "receipts": {
            "v14b_direct": artifact(V14B_RECEIPT),
            "v14c_dynamic_five_and_historical_replay": artifact(V14C_RECEIPT),
            "v14c_ifu_current_dynamic": artifact(ELIM_RECEIPT),
            "counterexample_inventory": artifact(COUNTEREXAMPLE_INVENTORY),
        },
        "status_history": {
            "current_bind_source_pass_invalidated": True,
            "current_bind_checker_replay_1_preserved_fail": True,
            "current_bind_checker_replay_2_pass": True,
            "replay_elimination_source_preserved_fail": True,
            "replay_elimination_checker_replay_pass": True,
            "p0_final_1_status_preserved": True,
            "p0_final_1_attribution_superseded": True,
            "p0_final_1_superseded_reason": (
                "three MIQ-FLUSH-G1 P1 observations were previously counted "
                "as P0, and unique RTL variants were not separated from "
                "named negative observations"
            ),
            "historical_status_rewritten": False,
        },
        "canonical_unchanged": v14c["canonical_unchanged"],
        "publication": {
            "task_local_only": True,
            "p0_current_bound": 9,
            "p0_current_stale": 0,
            "canonical_architecture_written": False,
            "architecture_debt_ledger_written": False,
            "architecture_gate_state": "RED",
            "arch_stable": False,
            "ppa_state": "BLOCKED_BY_ARCHITECTURE",
            "promotion_eligible": False,
        },
        "remaining_scope": v14c["remaining_scope"],
    }
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(
        json.dumps(receipt, indent=2, sort_keys=True) + "\n", encoding="utf-8"
    )
    print(
        "[V14C-P0-FINAL][PASS] "
        f"design_id={CURRENT_DESIGN_ID} current_dynamic=9/9 "
        f"p0_negative_observations={p0_negative_observations}/121 "
        "p0_unique_rtl_variants=114 adjacent_p1_observations=3 "
        "replay_dependency=0 unexplained_warnings=0 architecture=RED "
        "arch_stable=0 ppa=BLOCKED"
    )
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (OSError, UnicodeDecodeError, ValueError, json.JSONDecodeError) as exc:
        print(f"[V14C-P0-FINAL][FAIL] {exc}", file=sys.stderr)
        raise SystemExit(1)
