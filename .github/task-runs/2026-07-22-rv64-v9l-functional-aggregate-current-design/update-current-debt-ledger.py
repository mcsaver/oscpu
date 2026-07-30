#!/usr/bin/env python3
"""Bind closed local RV64 architecture debts to freshly replayed evidence."""

from __future__ import annotations

import hashlib
import importlib.util
import json
import pathlib
import subprocess
import sys
from typing import Any


RUN_ID = "2026-07-22-rv64-v9l-functional-aggregate-current-design"
ROOT = pathlib.Path(__file__).resolve().parents[3]
LEDGER = ROOT / "npc/rv64/design/arch/architecture-debt-ledger.json"
F0_RESULT = ROOT / "npc/rv64/eval/ppa/evidence/functional-aggregate-result.json"
SERIALIZE_VERIFY = (
    ROOT
    / ".github/task-runs/2026-07-28-rv64-v10g-serialize-currentness-closure"
    / "verify_serialize_g1_closure.py"
)
SERIALIZE_COMMAND = (
    "python3 "
    ".github/task-runs/2026-07-28-rv64-v10g-serialize-currentness-closure/"
    "verify_serialize_g1_closure.py"
)
SERIALIZE_PASS_MARKER = "[SERIALIZE-G1-VERIFY]"
SERIALIZE_SPEC = importlib.util.spec_from_file_location(
    "v9l_serialize_evidence_contract", SERIALIZE_VERIFY
)
assert SERIALIZE_SPEC is not None and SERIALIZE_SPEC.loader is not None
serialize_contract = importlib.util.module_from_spec(SERIALIZE_SPEC)
sys.modules[SERIALIZE_SPEC.name] = serialize_contract
SERIALIZE_SPEC.loader.exec_module(serialize_contract)
SERIALIZE_EXPECTED_EVIDENCE = tuple(
    dict(item) for item in serialize_contract.EXPECTED_LEDGER_EVIDENCE
)

TOOL = ROOT / "npc/rv64/eval/ppa/tools/architecture_hard_gates.py"
SPEC = importlib.util.spec_from_file_location("v9l_debt_binding_gate", TOOL)
assert SPEC is not None and SPEC.loader is not None
gate = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = gate
SPEC.loader.exec_module(gate)


def sha256(path: pathlib.Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def relative(path: pathlib.Path) -> str:
    return path.resolve().relative_to(ROOT.resolve()).as_posix()


def artifact(kind: str, path: pathlib.Path) -> dict[str, str]:
    resolved = path.resolve(strict=True)
    resolved.relative_to(ROOT.resolve())
    if resolved.is_symlink() or not resolved.is_file():
        raise RuntimeError(f"evidence is not a regular file: {resolved}")
    return {"kind": kind, "path": relative(resolved), "sha256": sha256(resolved)}


def load_json(path: pathlib.Path) -> dict[str, Any]:
    value = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(value, dict):
        raise RuntimeError(f"expected JSON object: {path}")
    return value


def require_current_json(path: pathlib.Path, design_id: str) -> None:
    value = load_json(path)
    if value.get("design_id") != design_id:
        raise RuntimeError(
            f"structured evidence is not current-design bound: {relative(path)}")
    if "status" in value and value.get("status") != "PASS":
        raise RuntimeError(f"structured evidence is not PASS: {relative(path)}")


def verify_serialize_entry(entry: dict[str, Any]) -> None:
    if entry.get("canonical_command") != SERIALIZE_COMMAND:
        raise RuntimeError(
            "SERIALIZE-G1 canonical verifier command is not exact"
        )
    tuple_errors = serialize_contract.validate_ledger_evidence(
        entry.get("evidence")
    )
    if tuple_errors:
        raise RuntimeError(
            "SERIALIZE-G1 evidence tuple is not exact: "
            + "; ".join(tuple_errors)
        )
    completed = subprocess.run(
        ["python3", str(SERIALIZE_VERIFY)],
        cwd=ROOT,
        text=True,
        capture_output=True,
        check=False,
    )
    if completed.returncode != 0:
        detail = (completed.stderr or completed.stdout).strip()
        raise RuntimeError(
            "SERIALIZE-G1 canonical verifier failed"
            + (f": {detail}" if detail else "")
        )
    if (
        SERIALIZE_PASS_MARKER not in completed.stdout
        or not completed.stdout.rstrip().endswith("PASS")
    ):
        raise RuntimeError(
            "SERIALIZE-G1 canonical verifier lacks the exact PASS marker"
        )
    print(completed.stdout.rstrip())


def main() -> int:
    rtl_sha, _ = gate.rtl_binding(ROOT)
    design_id = f"sha256:{rtl_sha}"
    ledger = load_json(LEDGER)
    if ledger.get("schema") != "npc-rv64-architecture-debt-ledger-v2":
        raise RuntimeError("unexpected architecture debt ledger schema")

    entries = ledger.get("entries")
    if not isinstance(entries, list):
        raise RuntimeError("architecture debt entries are missing")
    by_id = {
        entry.get("id"): entry for entry in entries if isinstance(entry, dict)
    }
    if set(by_id) != {entry.get("id") for entry in entries}:
        raise RuntimeError("architecture debt ids are not unique strings")

    result = load_json(F0_RESULT)
    if not (
        result.get("schema") == "npc-rv64-functional-aggregate-result-v1"
        and result.get("status") == "PASS"
        and result.get("exit_code") == 0
        and result.get("design_id") == design_id
    ):
        raise RuntimeError("F0 functional result is not a current-design PASS")
    result_artifacts = {
        key: result.get(key) for key in ("aggregate", "raw_log", "mutation_summary")
    }
    for key, item in result_artifacts.items():
        if not isinstance(item, dict) or not isinstance(item.get("path"), str):
            raise RuntimeError(f"F0 result has no {key} artifact")

    f0 = by_id.get("F0-G1")
    if not isinstance(f0, dict) or f0.get("status") not in {"STALE_EVIDENCE", "CLOSED"}:
        raise RuntimeError("F0-G1 is not in a closable state")
    f0.update({
        "status": "CLOSED",
        "current_design_bound": True,
        "design_id": design_id,
        "canonical_command": "make -C npc/rv64 check-functional-aggregate",
        "coverage": {
            "positive": True,
            "counterexample": True,
            "compile_success_evidence_mutation": True,
        },
        "evidence": [
            artifact("functional_aggregate_result", F0_RESULT),
            artifact("functional_aggregate", ROOT / result_artifacts["aggregate"]["path"]),
            artifact("raw_log", ROOT / result_artifacts["raw_log"]["path"]),
            artifact("mutation_summary", ROOT / result_artifacts["mutation_summary"]["path"]),
        ],
    })

    ledger["design_id"] = design_id
    roadmap = ledger.get("roadmap")
    if not isinstance(roadmap, dict) or not isinstance(roadmap.get("path"), str):
        raise RuntimeError("roadmap binding is missing")
    roadmap_path = ROOT / roadmap["path"]
    roadmap["sha256"] = sha256(roadmap_path)

    for entry in entries:
        if not isinstance(entry, dict) or entry.get("status") != "CLOSED":
            continue
        serialize_entry = entry.get("id") == "SERIALIZE-G1"
        if serialize_entry:
            # SERIALIZE-G1 intentionally binds a pre-review candidate JSON,
            # the read-only reviewer contract and the final reviewer report.
            # Their individual top-level status fields are not generic PASS
            # records.  The canonical verifier validates the complete tuple
            # and the current design before the publisher refreshes hashes.
            verify_serialize_entry(entry)
        entry["current_design_bound"] = True
        entry["design_id"] = design_id
        evidence = entry.get("evidence")
        if not isinstance(evidence, list) or not evidence:
            raise RuntimeError(f"{entry.get('id')}: CLOSED evidence is missing")
        for item in evidence:
            if not isinstance(item, dict) or set(item) != {"kind", "path", "sha256"}:
                raise RuntimeError(f"{entry.get('id')}: malformed evidence artifact")
            path = ROOT / item["path"]
            item["sha256"] = sha256(path)
            if not serialize_entry and item["kind"] not in {
                "raw_log",
                "irrevocable_owner_residency_raw",
            }:
                require_current_json(path, design_id)

    LEDGER.write_text(
        json.dumps(ledger, allow_nan=False, ensure_ascii=False,
                   indent=2) + "\n",
        encoding="utf-8",
    )
    print(
        f"[V9L-DEBT-LEDGER][PASS] design_id={design_id} "
        f"closed={sum(e.get('status') == 'CLOSED' for e in entries)} "
        "F0-G1=CLOSED"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
