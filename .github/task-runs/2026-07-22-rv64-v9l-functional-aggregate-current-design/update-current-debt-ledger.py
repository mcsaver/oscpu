#!/usr/bin/env python3
"""Bind closed local RV64 architecture debts to freshly replayed evidence."""

from __future__ import annotations

import hashlib
import importlib.util
import json
import pathlib
import sys
from typing import Any


RUN_ID = "2026-07-22-rv64-v9l-functional-aggregate-current-design"
ROOT = pathlib.Path(__file__).resolve().parents[3]
LEDGER = ROOT / "npc/rv64/design/arch/architecture-debt-ledger.json"
F0_RESULT = ROOT / "npc/rv64/eval/ppa/evidence/functional-aggregate-result.json"

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

    ledger["revision"] = "v9l-20260722"
    ledger["design_id"] = design_id
    roadmap = ledger.get("roadmap")
    if not isinstance(roadmap, dict) or not isinstance(roadmap.get("path"), str):
        raise RuntimeError("roadmap binding is missing")
    roadmap_path = ROOT / roadmap["path"]
    roadmap["sha256"] = sha256(roadmap_path)

    for entry in entries:
        if not isinstance(entry, dict) or entry.get("status") != "CLOSED":
            continue
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
            if item["kind"] not in {"raw_log"}:
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
