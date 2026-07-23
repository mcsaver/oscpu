#!/usr/bin/env python3
"""Build fail-closed evidence for local RV64 physical-write owner residency."""

from __future__ import annotations

import argparse
import datetime
import hashlib
import importlib.util
import json
import pathlib
import re
import sys
from typing import Any, Sequence


ARCH_TOOL = pathlib.Path(__file__).with_name("architecture_hard_gates.py")
ARCH_SPEC = importlib.util.spec_from_file_location(
    "architecture_hard_gates_owner_residency", ARCH_TOOL)
assert ARCH_SPEC is not None and ARCH_SPEC.loader is not None
arch = importlib.util.module_from_spec(ARCH_SPEC)
sys.modules[ARCH_SPEC.name] = arch
ARCH_SPEC.loader.exec_module(arch)

SCHEMA = "npc-rv64-irrevocable-owner-residency-evidence-v1"
RUN_ID = "2026-07-23-rv64-v9n-irrevocable-write-owner-residency"
CANONICAL_COMMAND = "make -C npc/rv64 check-memory-ordering"
VARIANT_SCHEMA = "npc-rv64-irrevocable-owner-residency-rtl-variants-v1"
VARIANT_RUNNER = pathlib.Path(
    ".github/task-runs/2026-07-23-rv64-v9n-irrevocable-write-owner-residency/"
    "run-owner-residency-rtl-variants.py"
)
TOP_FLUSH_BINDING = (
    "  ) u_ooo_core (\n"
    "    .clk(clk),\n"
    "    .rst(rst),\n"
    "    .flush_i(1'b0),"
)
POSITIVE = {
    "store": {
        "test": "tb_v9n_sq_owner_residency",
        "marker": (
            "[V9N-SQ-NEXT-EDGE-OWNER] "
            "launch=1 preserved=1 exact_terminal=1 PASS"
        ),
    },
    "amo": {
        "test": "tb_v9n_amo_owner_residency",
        "marker": (
            "[V9N-AMO-NEXT-EDGE-OWNER] "
            "launch=1 preserved=1 exact_terminal=1 PASS"
        ),
    },
}
SOURCE_PATHS = (
    ".github/task-runs/2026-07-23-rv64-v9n-irrevocable-write-owner-residency/contract.md",
    ".github/task-runs/2026-07-23-rv64-v9n-irrevocable-write-owner-residency/completion-definition.md",
    ".github/task-runs/2026-07-23-rv64-v9n-irrevocable-write-owner-residency/rtl-derivation.md",
    ".github/task-runs/2026-07-23-rv64-v9n-irrevocable-write-owner-residency/dispatch-log.md",
    ".github/task-runs/2026-07-23-rv64-v9n-irrevocable-write-owner-residency/subagent-contracts/owner-residency-review-v1.json",
    ".github/task-runs/2026-07-23-rv64-v9n-irrevocable-write-owner-residency/tb_v9n_sq_owner_residency.sv",
    ".github/task-runs/2026-07-23-rv64-v9n-irrevocable-write-owner-residency/tb_v9n_amo_owner_residency.sv",
    ".github/task-runs/2026-07-23-rv64-v9n-irrevocable-write-owner-residency/run-owner-residency-rtl-variants.py",
    ".github/task-runs/2026-07-23-rv64-v9n-irrevocable-write-owner-residency/run-focused.sh",
    "npc/rv64/Makefile",
    "npc/rv64/design/specs/ooo-memory-producer-lease.md",
    "npc/rv64/design/specs/ooo-store-bresp-precise-terminal.md",
    "npc/rv64/eval/ppa/tests/test_irrevocable_owner_residency_evidence.py",
    "npc/rv64/eval/ppa/tools/architecture_hard_gates.py",
    "npc/rv64/eval/ppa/tools/irrevocable_owner_residency_evidence.py",
    "npc/rv64/testbench/Makefile",
    "npc/rv64/testbench/scripts/check_tb_result.py",
    "npc/rv64/testbench/tests/tb_ooo_store_queue.sv",
    "npc/rv64/testbench/tests/tb_ooo_int_backend.sv",
    "npc/rv64/vsrc/core/NpcCoreTop.v",
    "npc/rv64/vsrc/memory/OooStoreQueue.v",
    "npc/rv64/vsrc/execute/OooIntBackend.v",
    "npc/rv64/vsrc/memory/OooMemOwnerTracker.v",
    "npc/rv64/vsrc/writeback/OooRob.v",
)


def sha256_bytes(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def sha256_file(path: pathlib.Path) -> str:
    return sha256_bytes(path.read_bytes())


def canonical_digest(value: Any) -> str:
    data = json.dumps(
        value, sort_keys=True, separators=(",", ":"), ensure_ascii=False,
    ).encode("utf-8")
    return sha256_bytes(data)


def repository_artifact(
    root: pathlib.Path, value: pathlib.Path, *, must_exist: bool = True,
) -> pathlib.Path:
    path = value if value.is_absolute() else root / value
    path = path.resolve()
    if not path.is_relative_to(root):
        raise ValueError(f"artifact escapes repository: {value}")
    if must_exist and (not path.is_file() or path.is_symlink()):
        raise ValueError(f"artifact is not a regular local file: {value}")
    return path


def output_path(root: pathlib.Path, value: pathlib.Path) -> pathlib.Path:
    path = repository_artifact(root, value, must_exist=False)
    if path.exists() and (path.is_symlink() or not path.is_file()):
        raise ValueError(f"output is not a regular local file: {value}")
    path.parent.mkdir(parents=True, exist_ok=True)
    return path


def load_variant_module(root: pathlib.Path) -> Any:
    path = repository_artifact(root, VARIANT_RUNNER)
    spec = importlib.util.spec_from_file_location(
        "v9n_owner_residency_variants", path)
    if spec is None or spec.loader is None:
        raise ValueError("owner-residency variant runner cannot be loaded")
    module = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    return module


def validate_positive_text(
    text: str, *, test_name: str, marker: str, design_id: str,
) -> None:
    required_once = (
        marker,
        f"[PASS] {test_name}",
        "[RESULT] PASS",
        f"[RTL-DESIGN-ID] {design_id}",
    )
    for item in required_once:
        if text.count(item) != 1:
            raise ValueError(f"{test_name}: expected unique marker {item}")
    for item in ("[RESULT] FAIL", "[CHECK-FAIL]", "[TIMEOUT]", "FATAL:"):
        if item in text:
            raise ValueError(f"{test_name}: unexpected failure marker {item}")


def validate_variant_payload(
    root: pathlib.Path,
    payload: dict[str, Any],
    log_text_by_name: dict[str, str],
) -> list[dict[str, Any]]:
    variant_module = load_variant_module(root)
    specs = {spec.name: spec for spec in variant_module.VARIANTS}
    rows = payload.get("results")
    if (
        payload.get("schema") != VARIANT_SCHEMA
        or payload.get("suite_run_id") != RUN_ID
        or payload.get("required") != len(specs)
        or payload.get("compile_success") != len(specs)
        or payload.get("dynamic_rejected") != len(specs)
        or payload.get("source_unchanged") is not True
        or not isinstance(rows, list)
        or {row.get("name") for row in rows if isinstance(row, dict)} != set(specs)
    ):
        raise ValueError("owner-residency RTL variant aggregate is incomplete")

    before = payload.get("source_sha256_before")
    after = payload.get("source_sha256_after")
    expected_source_paths = sorted({spec.source_rel for spec in specs.values()})
    live = {name: sha256_file(root / name) for name in expected_source_paths}
    if before != live or after != live:
        raise ValueError("owner-residency variant source binding is stale")

    validated: list[dict[str, Any]] = []
    for row in rows:
        if not isinstance(row, dict):
            raise ValueError("owner-residency variant row is not an object")
        name = row.get("name")
        spec = specs[name]
        original_text, variant_text = variant_module.reconstruct_variant(root, spec)
        expected_original = sha256_bytes(original_text.encode("utf-8"))
        expected_variant = sha256_bytes(variant_text.encode("utf-8"))
        text = log_text_by_name.get(name, "")
        compile_lines = [
            line for line in text.splitlines() if line.startswith("[COMPILE] ")
        ]
        check_fail_lines = [
            line for line in text.splitlines() if line.startswith("[CHECK-FAIL] ")
        ]
        fail_lines = [
            line for line in text.splitlines() if line.startswith("[FAIL] ")
        ]
        result_lines = [
            line for line in text.splitlines() if line.startswith("[RESULT] ")
        ]
        if (
            row.get("source") != spec.source_rel
            or row.get("make_variable") != spec.make_variable
            or row.get("test_name") != spec.test_name
            or row.get("original_sha256") != expected_original
            or row.get("variant_sha256") != expected_variant
            or expected_original == expected_variant
            or row.get("expected_marker") != spec.expected_marker
            or row.get("marker_observed") is not True
            or row.get("old_same_edge_assertion_quiet") is not True
            or row.get("compile_success") is not True
            or row.get("dynamic_rejected") is not True
            or not isinstance(row.get("make_returncode"), int)
            or row.get("make_returncode") == 0
            or len(compile_lines) != 1
            or check_fail_lines != [spec.expected_marker]
            or fail_lines != [f"[FAIL] {spec.test_name} errors=1"]
            or result_lines != ["[RESULT] FAIL status=1"]
            or spec.superseded_same_edge_marker in text
            or "[RESULT] PASS" in text
            or "[TIMEOUT]" in text
            or "FATAL:" in text
        ):
            raise ValueError(f"owner-residency variant rejection is incomplete: {name}")
        validated.append(row)
    return validated


def build_evidence(
    root: pathlib.Path,
    store_log: pathlib.Path,
    amo_log: pathlib.Path,
    variant_summary: pathlib.Path,
    result_output: pathlib.Path,
    raw_output: pathlib.Path,
) -> dict[str, Any]:
    source_sha, rtl_files = arch.rtl_binding(root)
    design_id = f"sha256:{source_sha}"
    logs = {
        "store": repository_artifact(root, store_log),
        "amo": repository_artifact(root, amo_log),
    }
    for name, path in logs.items():
        spec = POSITIVE[name]
        validate_positive_text(
            path.read_text(encoding="utf-8"),
            test_name=spec["test"],
            marker=spec["marker"],
            design_id=design_id,
        )

    summary_path = repository_artifact(root, variant_summary)
    summary = json.loads(summary_path.read_text(encoding="utf-8"))
    if not isinstance(summary, dict):
        raise ValueError("owner-residency variant summary is not an object")
    variant_log_paths: dict[str, pathlib.Path] = {}
    variant_log_text: dict[str, str] = {}
    rows = summary.get("results")
    if not isinstance(rows, list):
        raise ValueError("owner-residency variant rows are missing")
    for row in rows:
        if not isinstance(row, dict) or not isinstance(row.get("log"), dict):
            raise ValueError("owner-residency variant log binding is missing")
        name = row.get("name")
        path_value = row["log"].get("path")
        if not isinstance(name, str) or not isinstance(path_value, str):
            raise ValueError("owner-residency variant log identity is invalid")
        path = repository_artifact(root, pathlib.Path(path_value))
        if row["log"].get("sha256") != sha256_file(path):
            raise ValueError(f"owner-residency variant log digest is stale: {name}")
        variant_log_paths[name] = path
        variant_log_text[name] = path.read_text(encoding="utf-8")
    validated_rows = validate_variant_payload(root, summary, variant_log_text)

    top_path = root / "npc/rv64/vsrc/core/NpcCoreTop.v"
    top_text = top_path.read_text(encoding="utf-8")
    if top_text.count(TOP_FLUSH_BINDING) != 1:
        raise ValueError("canonical NpcCoreTop global flush binding drifted")

    provenance_files = {
        rel: sha256_file(repository_artifact(root, pathlib.Path(rel)))
        for rel in SOURCE_PATHS
    }
    provenance_sha = canonical_digest(provenance_files)
    artifacts = {
        path.relative_to(root).as_posix(): sha256_file(path)
        for path in (
            *logs.values(), summary_path, *variant_log_paths.values(),
        )
    }
    generated_at = datetime.datetime.now(datetime.timezone.utc).isoformat()
    result = {
        "schema": SCHEMA,
        "run_id": RUN_ID,
        "generated_at_utc": generated_at,
        "status": "PASS",
        "design_id": design_id,
        "canonical_command": CANONICAL_COMMAND,
        "claim": {
            "store_next_edge_owner_residency": True,
            "amo_next_edge_owner_residency": True,
            "canonical_top_global_flush_static_low": True,
            "canonical_top_global_flush_binding": (
                "NpcCoreTop.u_ooo_core.flush_i=1'b0"
            ),
        },
        "focused": {
            name: {
                "test": POSITIVE[name]["test"],
                "marker": POSITIVE[name]["marker"],
                "log": {
                    "path": path.relative_to(root).as_posix(),
                    "sha256": sha256_file(path),
                },
            }
            for name, path in sorted(logs.items())
        },
        "mutation_audit": {
            "required": len(validated_rows),
            "compile_success": len(validated_rows),
            "dynamic_rejected": len(validated_rows),
            "old_same_edge_assertion_quiet": len(validated_rows),
            "identities": sorted(row["name"] for row in validated_rows),
            "summary": {
                "path": summary_path.relative_to(root).as_posix(),
                "sha256": sha256_file(summary_path),
            },
        },
        "artifacts": artifacts,
        "provenance": {
            "files": provenance_files,
            "sha256": provenance_sha,
            "rtl_sha256": source_sha,
            "rtl_file_count": len(rtl_files),
        },
        "scope": (
            "Local RV64 STORE queue and AMO singleton physical-write owner "
            "residency from request acceptance through exact terminal "
            "response; no full-core architecture or PPA promotion"
        ),
        "ppa": "UNQUALIFIED",
        "promotion_eligible": False,
    }

    raw_lines = [
        "RV64 irrevocable physical-write owner residency evidence",
        f"run_id={RUN_ID}",
        f"generated_at_utc={generated_at}",
        f"design_id={design_id}",
        f"provenance_sha256={provenance_sha}",
        "store_next_edge_owner_residency=true",
        "amo_next_edge_owner_residency=true",
        "canonical_top_global_flush_static_low=true",
        "focused_passed=2",
        f"compile_success_variants={len(validated_rows)}",
        f"dynamic_rejected_variants={len(validated_rows)}",
        f"old_same_edge_assertion_quiet={len(validated_rows)}",
    ]
    raw_lines.extend(
        f"artifact_sha256 {path} {digest}"
        for path, digest in sorted(artifacts.items())
    )
    raw_lines.append(
        "[STORE-BRESP-G1-OWNER-RESIDENCY] PASS "
        f"focused=2 variants={len(validated_rows)} "
        "ppa=UNQUALIFIED"
    )

    result_path = output_path(root, result_output)
    raw_path = output_path(root, raw_output)
    result_path.write_text(
        json.dumps(result, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )
    raw_path.write_text("\n".join(raw_lines) + "\n", encoding="utf-8")
    return result


def main(argv: Sequence[str] | None = None) -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", type=pathlib.Path, required=True)
    parser.add_argument("--print-design-id", action="store_true")
    parser.add_argument("--store-log", type=pathlib.Path)
    parser.add_argument("--amo-log", type=pathlib.Path)
    parser.add_argument("--variant-summary", type=pathlib.Path)
    parser.add_argument("--output", type=pathlib.Path)
    parser.add_argument("--raw-log", type=pathlib.Path)
    args = parser.parse_args(argv)

    root = args.root.resolve(strict=True)
    if args.print_design_id:
        source_sha, _ = arch.rtl_binding(root)
        print(f"sha256:{source_sha}")
        return 0
    required = {
        "--store-log": args.store_log,
        "--amo-log": args.amo_log,
        "--variant-summary": args.variant_summary,
        "--output": args.output,
        "--raw-log": args.raw_log,
    }
    missing = [name for name, value in required.items() if value is None]
    if missing:
        parser.error(f"missing required arguments: {', '.join(missing)}")
    result = build_evidence(
        root,
        args.store_log,
        args.amo_log,
        args.variant_summary,
        args.output,
        args.raw_log,
    )
    print(
        "[V9N-OWNER-RESIDENCY-EVIDENCE][PASS] "
        f"design_id={result['design_id']} focused=2 variants=2"
    )
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (OSError, UnicodeError, ValueError, json.JSONDecodeError) as exc:
        print(f"[V9N-OWNER-RESIDENCY-EVIDENCE][FAIL] {exc}", file=sys.stderr)
        raise SystemExit(1)
