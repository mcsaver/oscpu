#!/usr/bin/env python3
"""Rebind unchanged RV64 product-cohort exclusions to the live RTL digest."""

from __future__ import annotations

import hashlib
import json
import pathlib
import sys


EXPECTED = {
    "A-COHERENCE-G1": "a-coherence-g1-exclusion.json",
    "DEBUG-TRIGGER-G1": "debug-trigger-g1-exclusion.json",
    "SFENCE-SINVAL-G1": "sfence-sinval-g1-exclusion.json",
    "WFI-G1": "wfi-g1-exclusion.json",
}
SCHEMA = "npc-rv64-architecture-debt-exclusion-v1"
COHORT_ID = "full-core-single-hart-rv64-dual-issue-ooo-v1"


def sha256(path: pathlib.Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def write_json(path: pathlib.Path, value: dict[str, object]) -> None:
    path.write_text(
        json.dumps(value, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )


def main() -> int:
    root = pathlib.Path(__file__).resolve().parents[3]
    sys.path.insert(0, str(root / "npc/rv64/eval/ppa/tools"))
    import architecture_hard_gates as architecture

    rtl_sha, rtl_files = architecture.rtl_binding(root)
    if not rtl_files:
        raise RuntimeError("canonical RV64 RTL source set is empty")
    design_id = f"sha256:{rtl_sha}"
    cohort_dir = root / "npc/rv64/design/arch/cohort"
    ledger_path = root / "npc/rv64/design/arch/architecture-debt-ledger.json"
    ledger = json.loads(ledger_path.read_text(encoding="utf-8"))
    entries = ledger.get("entries")
    if not isinstance(entries, list):
        raise RuntimeError("architecture debt ledger entries are missing")
    by_id = {
        row.get("id"): row for row in entries if isinstance(row, dict)
    }
    observed = {
        debt_id
        for debt_id, row in by_id.items()
        if row.get("status") == "EXCLUDED_BY_COHORT"
    }
    if observed != set(EXPECTED):
        raise RuntimeError(
            f"cohort exclusion membership changed: {sorted(observed)}"
        )

    for debt_id, filename in EXPECTED.items():
        path = cohort_dir / filename
        contract = json.loads(path.read_text(encoding="utf-8"))
        if (
            set(contract)
            != {"schema", "debt_id", "design_id", "cohort_id", "rationale"}
            or contract.get("schema") != SCHEMA
            or contract.get("debt_id") != debt_id
            or contract.get("cohort_id") != COHORT_ID
            or not isinstance(contract.get("rationale"), str)
            or not contract["rationale"].strip()
        ):
            raise RuntimeError(f"{debt_id}: exclusion contract drifted")
        contract["design_id"] = design_id
        write_json(path, contract)

        entry = by_id[debt_id]
        scope_contract = entry.get("scope_contract")
        expected_relative = path.relative_to(root).as_posix()
        if (
            not isinstance(scope_contract, dict)
            or scope_contract.get("path") != expected_relative
        ):
            raise RuntimeError(f"{debt_id}: ledger scope-contract path drifted")
        scope_contract["sha256"] = sha256(path)

    ledger["design_id"] = design_id
    write_json(ledger_path, ledger)
    print(
        "[V9W-COHORT-REBIND] "
        f"design_id={design_id} exclusions={len(EXPECTED)} "
        "membership_exact=true status=PASS"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
