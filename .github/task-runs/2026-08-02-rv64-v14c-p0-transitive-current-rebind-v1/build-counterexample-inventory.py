#!/usr/bin/env python3
"""Audit unique RV64 debt ownership for all V14C P0 counterexamples."""

from __future__ import annotations

import argparse
import collections
import hashlib
import json
import pathlib
import sys
from typing import Any


HERE = pathlib.Path(__file__).resolve().parent
ROOT = HERE.parents[2]
P0_GATES = {
    "FDG-G1", "XRET-G1", "MEM-ISSUE-G1", "IFU-AXI-G1",
    "IFU-FETCH-G2", "IFU-ACCESS-G1", "IFU-TVAL-G1",
    "PTW-PMP-G1", "INSTRET-G1",
}
SUITES = (
    (
        ROOT / ".github/task-runs/2026-08-02-rv64-v14b-architecture-"
        "current-freeze-audit-v1/evidence/p0-direct-rebind-1/mem/"
        "mutations/summary.json",
        "MEM-ISSUE-G1",
    ),
    (
        ROOT / ".github/task-runs/2026-08-02-rv64-v14b-architecture-"
        "current-freeze-audit-v1/evidence/p0-direct-rebind-1/ptw/"
        "mutations/summary.json",
        "PTW-PMP-G1",
    ),
    (HERE / "evidence/current-bind-1/dynamic/mutations/fdg/summary.json", "FDG-G1"),
    (HERE / "evidence/current-bind-1/dynamic/mutations/xret/summary.json", "XRET-G1"),
    (
        HERE / "evidence/current-bind-1/dynamic/mutations/ifu-access/summary.json",
        "IFU-ACCESS-G1",
    ),
    (
        HERE / "evidence/current-bind-1/dynamic/mutations/ifu-tval/summary.json",
        "IFU-TVAL-G1",
    ),
    (
        HERE / "evidence/current-bind-1/dynamic/mutations/instret/summary.json",
        "INSTRET-G1",
    ),
    (
        HERE / "evidence/p0-replay-elimination-1/mutations/ifu-axi/summary.json",
        "IFU-AXI-G1",
    ),
    (
        HERE / "evidence/p0-replay-elimination-1/mutations/ifu-fetch/summary.json",
        "IFU-FETCH-G2",
    ),
)
EXPECTED_P0 = {
    "FDG-G1": 7,
    "XRET-G1": 10,
    "MEM-ISSUE-G1": 8,
    "IFU-AXI-G1": 18,
    "IFU-FETCH-G2": 16,
    "IFU-ACCESS-G1": 19,
    "IFU-TVAL-G1": 12,
    "PTW-PMP-G1": 28,
    "INSTRET-G1": 3,
}
EXPECTED_VARIANT_ALIASES = {
    frozenset(
        {
            "FDG-G1:RTL_MUTATION:trap_ex_pc_corrupted",
            "XRET-G1:RTL_MUTATION:precise_trap_pc_offset",
        }
    ),
    frozenset(
        {
            "FDG-G1:RTL_MUTATION:trap_ex_tval_forced_zero",
            "XRET-G1:RTL_MUTATION:precise_trap_tval_forced_zero",
        }
    ),
    frozenset(
        {
            "IFU-ACCESS-G1:RTL_MUTATION:pair_ignores_slot1_visibility",
            "IFU-TVAL-G1:RTL_MUTATION:pair_ignores_predicted_taken_lane_visibility",
        }
    ),
    frozenset(
        {
            "IFU-ACCESS-G1:RTL_MUTATION:decoder_starts_lane1_at_fixed_halfword",
            "IFU-FETCH-G2:RTL_MUTATION:decoder_slot1_starts_at_fixed_halfword",
        }
    ),
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


def verify_log(row: dict[str, Any], item_id: str) -> None:
    log = row.get("log", {})
    path = ROOT / str(log.get("path", ""))
    if not path.is_file() or digest(path) != log.get("sha256"):
        raise ValueError(f"{item_id}: log hash mismatch")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--output", required=True, type=pathlib.Path)
    args = parser.parse_args()
    if args.output.exists():
        raise ValueError("refusing to replace counterexample inventory")

    items: list[dict[str, Any]] = []
    seen_ids: set[str] = set()
    seen_variants: dict[tuple[str, str], str] = {}
    duplicate_ids: list[str] = []
    duplicate_variants: list[dict[str, str]] = []
    for path, default_debt in SUITES:
        payload = load(path)
        if payload.get("source_unchanged") is not True:
            raise ValueError(f"source writeback detected: {path}")
        rows = [*(payload.get("results", [])), *(payload.get("oracle_probes", []))]
        if len(rows) != payload.get("required", 0) + payload.get(
            "oracle_probes_required", 0
        ):
            raise ValueError(f"suite row count mismatch: {path}")
        for index, row in enumerate(rows):
            kind = "ORACLE_PROBE" if index >= len(payload.get("results", [])) else "RTL_MUTATION"
            debt_id = row.get("debt_id") or default_debt
            name = row.get("name")
            item_id = f"{debt_id}:{kind}:{name}"
            if item_id in seen_ids:
                duplicate_ids.append(item_id)
            seen_ids.add(item_id)
            if (
                not name
                or row.get("compile_success") is not True
                or row.get("dynamic_rejected") is not True
                or row.get("marker_observed") is not True
            ):
                raise ValueError(f"{item_id}: dynamic rejection fields incomplete")
            verify_log(row, item_id)
            variant = None
            if kind == "RTL_MUTATION":
                original = row.get("original_sha256")
                variant_sha = row.get("variant_sha256")
                legacy_mutant_sha = row.get("mutant_sha256")
                if (
                    variant_sha
                    and legacy_mutant_sha
                    and variant_sha != legacy_mutant_sha
                ):
                    raise ValueError(f"{item_id}: conflicting RTL mutation hashes")
                variant = variant_sha or legacy_mutant_sha
                source = row.get("source")
                if not original or not variant or original == variant or not source:
                    raise ValueError(f"{item_id}: RTL mutation hash binding invalid")
                fingerprint = (str(source), str(variant))
                if fingerprint in seen_variants:
                    duplicate_variants.append(
                        {
                            "first_item_id": seen_variants[fingerprint],
                            "duplicate_item_id": item_id,
                            "source": str(source),
                            "variant_sha256": str(variant),
                        }
                    )
                else:
                    seen_variants[fingerprint] = item_id
            items.append(
                {
                    "item_id": item_id,
                    "debt_id": debt_id,
                    "kind": kind,
                    "name": name,
                    "source": row.get("source"),
                    "test_name": row.get("test_name"),
                    "expected_marker": row.get("expected_marker"),
                    "variant_sha256": variant,
                    "log": row["log"],
                    "suite": path.relative_to(ROOT).as_posix(),
                }
            )

    by_debt = collections.Counter(row["debt_id"] for row in items)
    p0_counts = {gate: by_debt.get(gate, 0) for gate in sorted(P0_GATES)}
    adjacent = {
        debt: count for debt, count in sorted(by_debt.items()) if debt not in P0_GATES
    }
    if p0_counts != dict(sorted(EXPECTED_P0.items())):
        raise ValueError(f"P0 debt attribution mismatch: {p0_counts}")
    if adjacent != {"MIQ-FLUSH-G1": 3}:
        raise ValueError(f"unexpected adjacent debt attribution: {adjacent}")
    actual_variant_aliases = {
        frozenset({row["first_item_id"], row["duplicate_item_id"]})
        for row in duplicate_variants
    }
    if duplicate_ids or actual_variant_aliases != EXPECTED_VARIANT_ALIASES or len(items) != 124:
        raise ValueError(
            f"counterexample uniqueness gap ids={duplicate_ids} "
            f"variants={duplicate_variants} total={len(items)}"
        )
    p0_mutations = [
        row
        for row in items
        if row["debt_id"] in P0_GATES and row["kind"] == "RTL_MUTATION"
    ]
    p0_oracle_probes = [
        row
        for row in items
        if row["debt_id"] in P0_GATES and row["kind"] == "ORACLE_PROBE"
    ]
    p0_variant_fingerprints = {
        (str(row["source"]), str(row["variant_sha256"])) for row in p0_mutations
    }
    adjacent_mutations = [row for row in items if row["debt_id"] not in P0_GATES]
    adjacent_variant_fingerprints = {
        (str(row["source"]), str(row["variant_sha256"]))
        for row in adjacent_mutations
    }
    if (
        len(p0_mutations) != 118
        or len(p0_oracle_probes) != 3
        or len(p0_variant_fingerprints) != 114
        or len(adjacent_mutations) != 3
        or len(adjacent_variant_fingerprints) != 3
    ):
        raise ValueError("counterexample kind/fingerprint count mismatch")

    output = {
        "schema": "rv64-v14c-counterexample-inventory-v1",
        "status": "PASS",
        "total_negative_observations": len(items),
        "unique_item_ids": len(seen_ids),
        "unique_rtl_variant_fingerprints": len(seen_variants),
        "duplicate_item_ids": duplicate_ids,
        "rtl_variant_aliases": duplicate_variants,
        "p0": {
            "required": 121,
            "detected": sum(p0_counts.values()),
            "by_debt": p0_counts,
            "rtl_mutation_executions": len(p0_mutations),
            "oracle_probe_executions": len(p0_oracle_probes),
            "unique_rtl_variant_fingerprints": len(p0_variant_fingerprints),
        },
        "adjacent_non_p0": {
            "required": 3,
            "detected": sum(adjacent.values()),
            "by_debt": adjacent,
            "rtl_mutation_executions": len(adjacent_mutations),
            "oracle_probe_executions": 0,
            "unique_rtl_variant_fingerprints": len(
                adjacent_variant_fingerprints
            ),
        },
        "p0_final_1_attribution": {
            "accepted_as_final": False,
            "claimed_p0_counterexamples": 124,
            "correct_p0_negative_observations": 121,
            "correct_p0_unique_rtl_variant_fingerprints": 114,
            "reason": "three MIQ-FLUSH-G1 P1 rows were counted inside the P0 total",
            "historical_status_rewritten": False,
        },
        "items": sorted(items, key=lambda row: row["item_id"]),
    }
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(
        json.dumps(output, indent=2, sort_keys=True) + "\n", encoding="utf-8"
    )
    print(
        "[V14C-COUNTEREXAMPLE-INVENTORY][PASS] observations=124 unique_ids=124 "
        "p0=121 p0_rtl_runs=118 p0_unique_variants=114 adjacent_p1=3 "
        "overall_unique_variants=117 expected_variant_aliases=4 "
        "p0_final_1_accepted=0"
    )
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (OSError, UnicodeDecodeError, ValueError, json.JSONDecodeError) as exc:
        print(f"[V14C-COUNTEREXAMPLE-INVENTORY][FAIL] {exc}", file=sys.stderr)
        raise SystemExit(1)
