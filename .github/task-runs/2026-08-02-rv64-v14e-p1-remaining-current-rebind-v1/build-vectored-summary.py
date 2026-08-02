#!/usr/bin/env python3
"""Build a compact, fail-closed current-design VECTORED-TRAP-G1 receipt."""

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
SOURCE = "npc/rv64/vsrc/core/CsrFile.v"
RUNNER = ROOT / "npc/rv64/testbench/scripts/run_csr_vectored_trap_mutations.py"
WARNING_AUDIT = ROOT / (
    ".github/task-runs/2026-08-02-rv64-v14d-p1-direct-current-rebind-v1/"
    "warning_audit.py"
)
POSITIVE = {
    "tb_csr_file": ("[PASS] tb_csr_file",),
    "tb_csr_file_vectored_trap": (
        "[VECTORED-TRAP-G1-CSR-FILE] cases=13 warl=3 irq_routing=3 m_irq=2 m_sync=1 source_priority=2 s_irq=1 s_sync=1 PASS",
        "[PASS] tb_csr_file_vectored_trap",
    ),
    "tb_ooo_priv_system": (
        "[VECTORED-TRAP-G2-M-IRQ] trap_mem=0 trap_ex=0 trap_irq=1 target_match=1 target_mismatch=0 exact_handler_fetch=1 wrong_base_fetch=0 xret_request=1 xret_commit=1 return_commit=1 cause=7 handler_body=1 backend_drained=1 PASS",
        "[VECTORED-TRAP-G3-S-IRQ] trap_mem=0 trap_ex=0 trap_irq=1 target_match=1 target_mismatch=0 exact_handler_fetch=1 wrong_base_fetch=0 xret_request=1 xret_commit=1 return_commit=1 cause=9 handler_body=1 backend_drained=1 PASS",
        "[VECTORED-TRAP-G4-M-SYNC] trap_mem=0 trap_ex=1 trap_irq=0 target_match=1 target_mismatch=0 exact_handler_fetch=1 wrong_vector_fetch=0 xret_request=1 xret_commit=1 return_commit=1 cause=11 handler_body=1 backend_drained=1 PASS",
        "[PASS] tb_ooo_priv_system",
    ),
}
MUTATION_IDS = (
    "direct_only_target",
    "vector_sync_exception",
    "force_machine_tvec",
    "reserved_mode_passthrough",
    "exception_over_memory_priority",
    "vector_offset_plus_four",
    "drop_nondelegated_supervisor_irq",
)


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
    spec = importlib.util.spec_from_file_location("v14e_vectored_warning_audit", WARNING_AUDIT)
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
    parser.add_argument("--raw-mutation-manifest", required=True, type=pathlib.Path)
    parser.add_argument("--mutation-output", required=True, type=pathlib.Path)
    parser.add_argument("--output", required=True, type=pathlib.Path)
    args = parser.parse_args()

    evidence = args.evidence.resolve(strict=True)
    evidence.relative_to(HERE / "evidence")
    raw_manifest_path = args.raw_mutation_manifest.resolve(strict=True)
    raw_manifest_path.relative_to(ROOT)
    mutation_output = args.mutation_output.resolve()
    output = args.output.resolve()
    mutation_output.relative_to(evidence)
    output.relative_to(evidence)
    if mutation_output.exists() or output.exists():
        raise ValueError("refusing to replace VECTORED-TRAP receipt")

    before_path = evidence / "source-before.json"
    after_path = evidence / "source-after.json"
    before = load(before_path)
    after = load(after_path)
    if before != after or before.get("design_id") != DESIGN_ID or before.get("file_count") != 146:
        raise ValueError("VECTORED-TRAP source identity drift")

    positive_logs: list[pathlib.Path] = []
    positive_records: list[dict[str, Any]] = []
    contract_marker_count = 0
    for test, markers in POSITIVE.items():
        path = evidence / "positive/logs" / f"{test}.log"
        text = path.read_text(encoding="utf-8")
        lines = text.splitlines()
        if (
            any(lines.count(marker) != 1 for marker in markers)
            or lines.count(f"[RTL-DESIGN-ID] {DESIGN_ID}") != 1
            or lines.count("[RESULT] PASS") != 1
            or "[RESULT] FAIL" in text
            or "[CHECK-FAIL]" in text
            or "FATAL:" in text
            or "[VECTORED-TRAP-A" in text
        ):
            raise ValueError(f"VECTORED-TRAP positive marker drift: {test}")
        positive_logs.append(path)
        contract_marker_count += len(markers)
        positive_records.append(
            {"test": test, "required_markers": list(markers), "log": artifact(path)}
        )

    raw = load(raw_manifest_path)
    rows = raw.get("mutations")
    summary = raw.get("summary")
    if (
        raw.get("schema_version") != 1
        or raw.get("rtl_design_id_before") != DESIGN_ID
        or raw.get("rtl_design_id_after") != DESIGN_ID
        or raw.get("source_unchanged") is not True
        or raw.get("rtl_source_set_unchanged") is not True
        or raw.get("rtl_source_set", {}).get("file_count") != 146
        or not isinstance(rows, list)
        or not isinstance(summary, dict)
        or summary.get("total") != 7
        or summary.get("compile_succeeded") != 7
        or summary.get("rejected") != 7
        or summary.get("all_rejected") is not True
    ):
        raise ValueError("VECTORED-TRAP raw mutation manifest drift")
    by_id = {str(row.get("mutation_id")): row for row in rows}
    if set(by_id) != set(MUTATION_IDS) or len(rows) != len(MUTATION_IDS):
        raise ValueError("VECTORED-TRAP mutation set drift")

    compact_rows: list[dict[str, Any]] = []
    fingerprints: set[tuple[str, str]] = set()
    for mutation_id in MUTATION_IDS:
        row = by_id[mutation_id]
        log_path = evidence / "mutations/logs" / f"{mutation_id}.log"
        log_text = log_path.read_text(encoding="utf-8")
        assertions = row.get("required_assertion_counts")
        if not isinstance(assertions, dict) or not assertions:
            raise ValueError(f"missing assertion contract: {mutation_id}")
        assertion_counts = {str(marker): log_text.count(str(marker)) for marker in assertions}
        if (
            row.get("compile_succeeded") is not True
            or row.get("rejected") is not True
            or not isinstance(row.get("driver_rc"), int)
            or row.get("driver_rc") == 0
            or any(assertion_counts[marker] != int(expected) or int(expected) <= 0 for marker, expected in assertions.items())
            or log_text.count("[VECTORED-TRAP-G1-CSR-FILE]") != 1
            or not any(line.startswith("[VECTORED-TRAP-G1-CSR-FILE] ") and line.endswith(" FAIL") for line in log_text.splitlines())
            or log_text.count("[CHECK-FAIL]") != int(row.get("functional_check_fail_count", -1))
            or log_text.count("[RESULT] FAIL") != 1
            or "[RESULT] PASS" in log_text
            or "[PASS] tb_csr_file_vectored_trap" in log_text
        ):
            raise ValueError(f"VECTORED-TRAP mutation rejection drift: {mutation_id}")
        variant_sha = str(row.get("mutant_sha256"))
        if len(variant_sha) != 64:
            raise ValueError(f"invalid mutation fingerprint: {mutation_id}")
        fingerprints.add((SOURCE, variant_sha))
        compact_rows.append(
            {
                "mutation_id": mutation_id,
                "production_rtl_source": SOURCE,
                "variant_sha256": variant_sha,
                "compile_artifact_sha256_before_cleanup": row.get("compile_artifact_sha256"),
                "compile_succeeded": True,
                "dynamic_rejected": True,
                "driver_rc": row["driver_rc"],
                "required_assertion_counts": assertion_counts,
                "functional_check_fail_count": row["functional_check_fail_count"],
                "log": artifact(log_path),
            }
        )
    if len(fingerprints) != 7:
        raise ValueError("VECTORED-TRAP mutation fingerprints are not unique")

    compact = {
        "schema": "rv64-v14e-vectored-trap-mutations-v1",
        "status": "PASS",
        "current_design_id": DESIGN_ID,
        "source": SOURCE,
        "source_sha256_before": raw.get("source_sha256_before"),
        "source_sha256_after": raw.get("source_sha256_after"),
        "runner": artifact(RUNNER),
        "raw_manifest_sha256_before_cleanup": digest(raw_manifest_path),
        "required": 7,
        "compile_success": 7,
        "dynamic_rejected": 7,
        "unique_rtl_variant_fingerprints": 7,
        "source_unchanged": True,
        "results": compact_rows,
        "transient_compiled_images_retained": 0,
    }
    mutation_output.parent.mkdir(parents=True, exist_ok=True)
    mutation_output.write_text(json.dumps(compact, indent=2, sort_keys=True) + "\n", encoding="utf-8")

    warnings = warning_audit(positive_logs)
    receipt = {
        "schema": "rv64-v14e-vectored-trap-current-summary-v1",
        "status": "PASS",
        "debt_id": "VECTORED-TRAP-G1",
        "scope_status": "CURRENT_DYNAMIC_PASS",
        "current_design_id": DESIGN_ID,
        "positive": {
            "passed_tests": 3,
            "required_tests": 3,
            "contract_markers": contract_marker_count,
            "tests": positive_records,
        },
        "compile_success_rtl_counterexamples": {
            "detected": 7,
            "required": 7,
            "unique_rtl_variant_fingerprints": 7,
            "summary": artifact(mutation_output),
        },
        "warning_audit": warnings,
        "positive_assertion_failure_observed": False,
        "counterexample_assertion_rejection_observed": True,
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
    output.write_text(json.dumps(receipt, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    print(
        "[V14E-VECTORED-TRAP][PASS] positive=3/3 contract_markers="
        f"{contract_marker_count} mutations=7/7 unique_variants=7 "
        f"warnings={warnings['count']} source_unchanged=1"
    )
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (OSError, ValueError, json.JSONDecodeError) as exc:
        print(f"[V14E-VECTORED-TRAP][FAIL] {exc}", file=sys.stderr)
        raise SystemExit(1)
