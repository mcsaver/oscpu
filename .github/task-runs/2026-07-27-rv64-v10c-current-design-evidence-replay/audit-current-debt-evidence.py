#!/usr/bin/env python3
"""Audit current-design bindings for closed local RV64 architecture debts."""

from __future__ import annotations

import hashlib
import importlib.util
import json
import pathlib
import subprocess
import sys
from typing import Any


RUN_DIR = pathlib.Path(__file__).resolve().parent
ROOT = RUN_DIR.parents[2]
LEDGER = ROOT / "npc/rv64/design/arch/architecture-debt-ledger.json"
OUTPUT = RUN_DIR / "closed-evidence-currentness.json"
GATE_TOOL = ROOT / "npc/rv64/eval/ppa/tools/architecture_hard_gates.py"
FREEZE_TOOL = ROOT / "npc/rv64/eval/ppa/tools/arch_stable_freeze.py"
CANDIDATE = ROOT / "npc/rv64/eval/ppa/arch-stable/full-core-current.json"
SERIALIZE_COMMAND = (
    "python3 "
    ".github/task-runs/2026-07-28-rv64-v10g-serialize-currentness-closure/"
    "verify_serialize_g1_closure.py"
)
SERIALIZE_VERIFY = (
    ROOT
    / ".github/task-runs/2026-07-28-rv64-v10g-serialize-currentness-closure"
    / "verify_serialize_g1_closure.py"
)
SERIALIZE_PASS_MARKER = "[SERIALIZE-G1-VERIFY]"
SERIALIZE_SPEC = importlib.util.spec_from_file_location(
    "v10c_serialize_evidence_contract", SERIALIZE_VERIFY
)
assert SERIALIZE_SPEC is not None and SERIALIZE_SPEC.loader is not None
serialize_contract = importlib.util.module_from_spec(SERIALIZE_SPEC)
sys.modules[SERIALIZE_SPEC.name] = serialize_contract
SERIALIZE_SPEC.loader.exec_module(serialize_contract)
SERIALIZE_EXPECTED_EVIDENCE = tuple(
    dict(item) for item in serialize_contract.EXPECTED_LEDGER_EVIDENCE
)
RAW_EVIDENCE_KINDS = {
    "raw_log",
    "irrevocable_owner_residency_raw",
}


def load_json(path: pathlib.Path) -> dict[str, Any]:
    value = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(value, dict):
        raise RuntimeError(f"expected JSON object: {path}")
    return value


def sha256(path: pathlib.Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def verify_serialize_entry(entry: dict[str, Any]) -> str | None:
    if entry.get("canonical_command") != SERIALIZE_COMMAND:
        return "serialize_canonical_command_not_exact"
    if serialize_contract.validate_ledger_evidence(entry.get("evidence")):
        return "serialize_evidence_tuple_not_exact"
    completed = subprocess.run(
        ["python3", str(SERIALIZE_VERIFY)],
        cwd=ROOT,
        text=True,
        capture_output=True,
        check=False,
    )
    if completed.returncode != 0:
        return "serialize_canonical_verifier_failed"
    if (
        SERIALIZE_PASS_MARKER not in completed.stdout
        or not completed.stdout.rstrip().endswith("PASS")
    ):
        return "serialize_canonical_pass_marker_missing"
    print(completed.stdout.rstrip())
    return None


def requires_generic_json(
    entry_id: str,
    kind: object,
    path: pathlib.Path,
) -> bool:
    if kind in RAW_EVIDENCE_KINDS:
        return False
    if entry_id == "SERIALIZE-G1":
        # This tuple mixes a pre-review candidate JSON, a read-only review
        # contract JSON and the final Markdown report.  Its canonical verifier
        # validates the tuple and current design before per-file hash checks.
        return False
    if path.suffix != ".json":
        raise RuntimeError(
            f"unexpected non-JSON structured evidence: {path}"
        )
    return True


def closed_semantic_failures(
    closed_ids: list[str],
    checks: dict[str, dict[str, Any]],
) -> list[dict[str, str]]:
    failures: list[dict[str, str]] = []
    for entry_id in closed_ids:
        for suffix in ("closed_binding", "semantic_evidence"):
            check_id = f"debt.{entry_id}.{suffix}"
            check = checks.get(check_id)
            if not isinstance(check, dict):
                failures.append({
                    "entry": entry_id,
                    "reason": f"canonical_check_missing:{check_id}",
                })
                continue
            status = check.get("status")
            if status != "PASS":
                failures.append({
                    "entry": entry_id,
                    "reason": (
                        f"canonical_check_not_pass:{check_id}:"
                        f"{status}"
                    ),
                })
    return failures


def main() -> int:
    spec = importlib.util.spec_from_file_location("v10c_gate", GATE_TOOL)
    if spec is None or spec.loader is None:
        raise RuntimeError("cannot load architecture_hard_gates.py")
    gate = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = gate
    spec.loader.exec_module(gate)
    rtl_sha, _ = gate.rtl_binding(ROOT)
    design_id = f"sha256:{rtl_sha}"

    freeze_spec = importlib.util.spec_from_file_location(
        "v10c_freeze", FREEZE_TOOL
    )
    if freeze_spec is None or freeze_spec.loader is None:
        raise RuntimeError("cannot load arch_stable_freeze.py")
    freeze = importlib.util.module_from_spec(freeze_spec)
    sys.modules[freeze_spec.name] = freeze
    freeze_spec.loader.exec_module(freeze)

    ledger = load_json(LEDGER)
    entries = ledger.get("entries")
    if not isinstance(entries, list):
        raise RuntimeError("architecture debt entries are missing")

    failures: list[dict[str, str]] = []
    closed: list[str] = []
    open_entries: list[dict[str, str]] = []
    artifact_count = 0
    for entry in entries:
        if not isinstance(entry, dict):
            failures.append({"entry": "<malformed>", "reason": "entry_not_object"})
            continue
        entry_id = str(entry.get("id"))
        if entry.get("status") != "CLOSED":
            open_entries.append({
                "id": entry_id,
                "priority": str(entry.get("priority")),
                "status": str(entry.get("status")),
            })
            continue
        closed.append(entry_id)
        if entry.get("current_design_bound") is not True:
            failures.append({
                "entry": entry_id,
                "reason": "current_design_bound_not_true",
            })
        if entry.get("design_id") != design_id:
            failures.append({
                "entry": entry_id,
                "reason": "entry_design_id_mismatch",
            })
        if entry_id == "SERIALIZE-G1":
            serialize_failure = verify_serialize_entry(entry)
            if serialize_failure is not None:
                failures.append({
                    "entry": entry_id,
                    "reason": serialize_failure,
                })
        evidence = entry.get("evidence")
        if not isinstance(evidence, list) or not evidence:
            failures.append({"entry": entry_id, "reason": "evidence_missing"})
            continue
        for artifact in evidence:
            artifact_count += 1
            if not isinstance(artifact, dict):
                failures.append({
                    "entry": entry_id,
                    "reason": "artifact_not_object",
                })
                continue
            path_value = artifact.get("path")
            if not isinstance(path_value, str):
                failures.append({
                    "entry": entry_id,
                    "reason": "artifact_path_missing",
                })
                continue
            path = (ROOT / path_value).resolve()
            try:
                path.relative_to(ROOT.resolve())
            except ValueError:
                failures.append({
                    "entry": entry_id,
                    "reason": f"artifact_outside_root:{path_value}",
                })
                continue
            if not path.is_file() or path.is_symlink():
                failures.append({
                    "entry": entry_id,
                    "reason": f"artifact_not_regular:{path_value}",
                })
                continue
            if artifact.get("sha256") != sha256(path):
                failures.append({
                    "entry": entry_id,
                    "reason": f"artifact_sha_mismatch:{path_value}",
                })
            try:
                require_json = requires_generic_json(
                    entry_id, artifact.get("kind"), path
                )
            except RuntimeError:
                failures.append({
                    "entry": entry_id,
                    "reason": f"artifact_non_json_unexpected:{path_value}",
                })
                continue
            if not require_json:
                continue
            structured = load_json(path)
            if structured.get("design_id") != design_id:
                failures.append({
                    "entry": entry_id,
                    "reason": f"artifact_design_id_mismatch:{path_value}",
                })
            if "status" in structured and structured.get("status") != "PASS":
                failures.append({
                    "entry": entry_id,
                    "reason": f"artifact_status_not_pass:{path_value}",
                })

    if ledger.get("design_id") != design_id:
        failures.append({
            "entry": "<ledger>",
            "reason": "ledger_design_id_mismatch",
        })

    candidate_result = freeze.evaluate_candidate(
        root=ROOT,
        candidate_path=CANDIDATE,
        generated_at_utc="currentness-audit",
    )
    canonical_checks = {
        item.get("check_id"): item
        for item in candidate_result.get("checks", [])
        if isinstance(item, dict) and isinstance(item.get("check_id"), str)
    }
    failures.extend(closed_semantic_failures(closed, canonical_checks))

    result = {
        "schema": "npc-rv64-closed-debt-currentness-audit-v1",
        "status": "PASS" if not failures else "FAIL",
        "design_id": design_id,
        "closed_entries": closed,
        "closed_count": len(closed),
        "artifact_count": artifact_count,
        "open_entries": open_entries,
        "canonical_semantic_check_count": sum(
            1
            for entry_id in closed
            for suffix in ("closed_binding", "semantic_evidence")
            if f"debt.{entry_id}.{suffix}" in canonical_checks
        ),
        "failures": failures,
    }
    OUTPUT.write_text(
        json.dumps(result, ensure_ascii=False, allow_nan=False, indent=2) + "\n",
        encoding="utf-8",
    )
    print(
        f"[V10C-CURRENTNESS][{result['status']}] "
        f"design_id={design_id} closed={len(closed)} "
        f"artifacts={artifact_count} failures={len(failures)}"
    )
    return 0 if not failures else 1


if __name__ == "__main__":
    raise SystemExit(main())
