#!/usr/bin/env python3
"""Close CONTROL-EVENT-G1 only after V9O and V9R current-design replay."""

from __future__ import annotations

import hashlib
import importlib.util
import json
import pathlib
import sys
from typing import Any


ROOT = pathlib.Path(__file__).resolve().parents[3]
LEDGER = ROOT / "npc/rv64/design/arch/architecture-debt-ledger.json"
FREEZE_PATH = ROOT / "npc/rv64/eval/ppa/tools/arch_stable_freeze.py"
ARCH_PATH = ROOT / "npc/rv64/eval/ppa/tools/architecture_hard_gates.py"


def load_module(path: pathlib.Path, name: str) -> Any:
    spec = importlib.util.spec_from_file_location(name, path)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"cannot load module: {path}")
    module = importlib.util.module_from_spec(spec)
    sys.modules[name] = module
    spec.loader.exec_module(module)
    return module


def sha256(path: pathlib.Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def load_json(path: pathlib.Path) -> dict[str, Any]:
    value = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(value, dict):
        raise RuntimeError(f"expected JSON object: {path}")
    return value


def evidence(kind: str, relative: str) -> dict[str, str]:
    path = (ROOT / relative).resolve(strict=True)
    path.relative_to(ROOT.resolve())
    if path.is_symlink() or not path.is_file():
        raise RuntimeError(f"evidence is not a regular file: {relative}")
    return {"kind": kind, "path": relative, "sha256": sha256(path)}


def main() -> int:
    arch = load_module(ARCH_PATH, "v9r_close_architecture")
    freeze = load_module(FREEZE_PATH, "v9r_close_freeze")
    rtl_sha, _ = arch.rtl_binding(ROOT)
    design_id = f"sha256:{rtl_sha}"

    entry_evidence = [
        evidence(
            "control_event_evidence_index",
            freeze.CONTROL_EVENT_INDEX_PATH,
        ),
        evidence(
            "control_event_rtl_mutations",
            freeze.CONTROL_EVENT_MUTATION_PATH,
        ),
        evidence(
            "v9r_sq_retry_c0_evidence",
            freeze.V9R_SQ_RETRY_SUMMARY_PATH,
        ),
    ]
    candidate = {
        "id": "CONTROL-EVENT-G1",
        "status": "CLOSED",
        "current_design_bound": True,
        "design_id": design_id,
        "canonical_command": freeze.CONTROL_EVENT_COMMAND,
        "coverage": {
            "positive": True,
            "counterexample": True,
            "compile_success_rtl_mutation": True,
        },
        "evidence": entry_evidence,
    }
    errors = freeze.validate_control_event_debt(
        ROOT, candidate, design_id)
    if errors:
        raise RuntimeError(
            "CONTROL-EVENT-G1 evidence is not closable: "
            + "; ".join(errors[:6])
        )

    ledger = load_json(LEDGER)
    entries = ledger.get("entries")
    if not isinstance(entries, list):
        raise RuntimeError("architecture debt entries are missing")
    matches = [
        entry for entry in entries
        if isinstance(entry, dict) and entry.get("id") == "CONTROL-EVENT-G1"
    ]
    if len(matches) != 1:
        raise RuntimeError("CONTROL-EVENT-G1 ledger entry is not unique")
    target = matches[0]
    if target.get("status") not in {"STALE_EVIDENCE", "CLOSED"}:
        raise RuntimeError("CONTROL-EVENT-G1 is not in a closable state")
    target.update({
        "status": "CLOSED",
        "current_design_bound": True,
        "design_id": design_id,
        "canonical_command": freeze.CONTROL_EVENT_COMMAND,
        "scope_rationale": (
            "V9O C0-to-C1 control ownership and V9R bank0/bank1 SQ-query "
            "retry handoff now share the exact current RTL design identity; "
            "focused, macro-on, module, nine-gate architecture and "
            "compile-success source variants were replayed before closure."
        ),
        "coverage": candidate["coverage"],
        "evidence": entry_evidence,
    })
    ledger["design_id"] = design_id
    roadmap = ledger.get("roadmap")
    if not isinstance(roadmap, dict) or not isinstance(
        roadmap.get("path"), str
    ):
        raise RuntimeError("roadmap binding is missing")
    roadmap["sha256"] = sha256(ROOT / roadmap["path"])
    LEDGER.write_text(
        json.dumps(
            ledger,
            allow_nan=False,
            ensure_ascii=False,
            indent=2,
        ) + "\n",
        encoding="utf-8",
    )
    print(
        "[V9R-CONTROL-EVENT-CLOSE][PASS] "
        f"design_id={design_id} evidence=V9O+V9R"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
