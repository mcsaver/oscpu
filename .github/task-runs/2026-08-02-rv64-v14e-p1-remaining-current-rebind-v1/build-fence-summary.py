#!/usr/bin/env python3
"""Build a fail-closed current-design FENCE-G1 task-local receipt."""

from __future__ import annotations

import argparse
import hashlib
import importlib.util
import json
import pathlib
import sys
from typing import Any


HERE = pathlib.Path(__file__).resolve().parent
ROOT = HERE.parents[2]
DESIGN_ID = "sha256:093c2380b997029944aa4462015d83711d7c5f1d52b15b4803c4515a581a7488"
WARNING_AUDIT = ROOT / (
    ".github/task-runs/2026-08-02-rv64-v14d-p1-direct-current-rebind-v1/"
    "warning_audit.py"
)
POSITIVE = {
    "tb_ooo_priv_system": "[FENCE-G1-PROGRAM] exit=1 ebreak=1 trap=0 lane1_capture=1 full_memory_wait=1 mem_idle_binding=1 fence_commit=1 store_probe=1 store_drain=1 device_read=1 fence_before_store=0 device_before_store=0 device_before_fence=0 readback_match=1 backend_drained=1 PASS",
    "tb_ooo_pending_drain_resolve_gate": "[PASS] tb_ooo_pending_drain_resolve_gate",
}


def digest(path: pathlib.Path) -> str:
    value = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            value.update(chunk)
    return value.hexdigest()


def load(path: pathlib.Path) -> dict[str, Any]:
    value = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(value, dict):
        raise ValueError(f"JSON root is not an object: {path}")
    return value


def artifact(path: pathlib.Path) -> dict[str, str]:
    resolved = path.resolve(strict=True)
    resolved.relative_to(ROOT)
    return {"path": resolved.relative_to(ROOT).as_posix(), "sha256": digest(resolved)}


def warning_audit(logs: list[pathlib.Path]) -> dict[str, Any]:
    spec = importlib.util.spec_from_file_location("v14e_fence_warning_audit", WARNING_AUDIT)
    if spec is None or spec.loader is None:
        raise ValueError("cannot load current warning audit")
    module = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    result = module.audit(logs)
    result["checker"] = artifact(WARNING_AUDIT)
    return result


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--evidence", required=True, type=pathlib.Path)
    parser.add_argument("--output", required=True, type=pathlib.Path)
    args = parser.parse_args()
    evidence = args.evidence.resolve(strict=True)
    evidence.relative_to(HERE / "evidence")
    output = args.output.resolve()
    output.relative_to(evidence)
    if output.exists():
        raise ValueError("refusing to replace FENCE summary")

    before_path = evidence / "source-before.json"
    after_path = evidence / "source-after.json"
    before = load(before_path)
    after = load(after_path)
    if before != after or before.get("design_id") != DESIGN_ID or before.get("file_count") != 146:
        raise ValueError("FENCE source identity drift")

    logs: list[pathlib.Path] = []
    positive_records: list[dict[str, Any]] = []
    for test, marker in POSITIVE.items():
        path = evidence / "positive/logs" / f"{test}.log"
        text = path.read_text(encoding="utf-8")
        lines = text.splitlines()
        if (
            lines.count(marker) != 1
            or lines.count(f"[RTL-DESIGN-ID] {DESIGN_ID}") != 1
            or lines.count("[RESULT] PASS") != 1
            or "[RESULT] FAIL" in text
            or "[CHECK-FAIL]" in text
            or "FATAL:" in text
        ):
            raise ValueError(f"FENCE positive marker drift: {test}")
        logs.append(path)
        positive_records.append({"test": test, "marker": marker, "log": artifact(path)})

    mutations_path = evidence / "mutations/summary.json"
    mutations = load(mutations_path)
    if (
        mutations.get("schema") != "npc-rv64-fence-rtl-variants-v2"
        or mutations.get("required") != 2
        or mutations.get("compile_success") != 2
        or mutations.get("dynamic_rejected") != 2
        or mutations.get("source_unchanged") is not True
        or len(mutations.get("results", ())) != 2
        or any(row.get("compile_success") is not True or row.get("dynamic_rejected") is not True for row in mutations.get("results", ()))
    ):
        raise ValueError("FENCE mutation evidence drift")
    fingerprints = {
        (str(row.get("source")), str(row.get("variant_sha256")))
        for row in mutations["results"]
    }
    if len(fingerprints) != 2:
        raise ValueError("FENCE mutation fingerprints are not unique")

    warnings = warning_audit(logs)
    summary = {
        "schema": "rv64-v14e-fence-current-summary-v1",
        "status": "PASS",
        "debt_id": "FENCE-G1",
        "scope_status": "CURRENT_DYNAMIC_PASS",
        "current_design_id": DESIGN_ID,
        "positive": {"passed": 2, "required": 2, "tests": positive_records},
        "compile_success_rtl_counterexamples": {
            "detected": 2,
            "required": 2,
            "unique_rtl_variant_fingerprints": 2,
            "summary": artifact(mutations_path),
        },
        "warning_audit": warnings,
        "assertion_failure_observed": False,
        "source_identity": {
            "file_count": 146,
            "pre_post_equal": True,
            "before": artifact(before_path),
            "after": artifact(after_path),
        },
        "production_rtl_written": False,
        "transient_compiled_images_retained": 0,
        "architecture_gate_state": "RED",
        "ppa_state": "BLOCKED_BY_ARCHITECTURE",
    }
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(json.dumps(summary, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    print(
        "[V14E-FENCE][PASS] positive=2/2 mutations=2/2 unique_variants=2 "
        f"warnings={warnings['count']} source_unchanged=1"
    )
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (OSError, ValueError, json.JSONDecodeError) as exc:
        print(f"[V14E-FENCE][FAIL] {exc}", file=sys.stderr)
        raise SystemExit(1)
