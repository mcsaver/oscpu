#!/usr/bin/env python3
"""Build fail-closed local RV64 INSTRET-G1 retirement evidence."""

from __future__ import annotations

import argparse
import hashlib
import importlib.util
import json
import pathlib
import re
import sys
from typing import Any, Sequence


SCHEMA = "npc-rv64-instret-retirement-evidence-v1"
MUTATION_SCHEMA = "npc-rv64-instret-rtl-mutations-v1"
RUN_ID = "2026-07-21-rv64-v9c-instret-retirement"
CANONICAL_COMMAND = "make -C npc/rv64 check-instret-retirement"
REPO = pathlib.Path(__file__).resolve().parents[5]

ARCH_TOOL = pathlib.Path(__file__).with_name("architecture_hard_gates.py")
ARCH_SPEC = importlib.util.spec_from_file_location(
    "architecture_hard_gates", ARCH_TOOL)
assert ARCH_SPEC is not None and ARCH_SPEC.loader is not None
arch = importlib.util.module_from_spec(ARCH_SPEC)
sys.modules[ARCH_SPEC.name] = arch
ARCH_SPEC.loader.exec_module(arch)

MUTATION_RUNNER = (
    REPO / f".github/task-runs/{RUN_ID}/run-instret-mutations.py")
MUTATION_SPEC = importlib.util.spec_from_file_location(
    "instret_rtl_mutations", MUTATION_RUNNER)
assert MUTATION_SPEC is not None and MUTATION_SPEC.loader is not None
mutation_model = importlib.util.module_from_spec(MUTATION_SPEC)
sys.modules[MUTATION_SPEC.name] = mutation_model
MUTATION_SPEC.loader.exec_module(mutation_model)

PROGRAM_RE = re.compile(
    r"^\[INSTRET-G1-PROGRAM\] "
    r"exception_lanes=(\d+) exception_zero_delta=(\d+) "
    r"mret=(\d+) sret=(\d+) sfence_vma=(\d+) "
    r"control_exact=(\d+) control_total=(\d+) "
    r"csr_delta_checks=(\d+) PASS$",
    re.MULTILINE,
)

FOCUSED_TESTS = {
    "commit_output_mux": "tb_ooo_commit_output_mux",
    "alu_core_slice": "tb_ooo_alu_core_slice",
    "csr_file": "tb_csr_file",
}


def sha256_bytes(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def sha256_file(path: pathlib.Path) -> str:
    return sha256_bytes(path.read_bytes())


def safe_file(root: pathlib.Path, path: pathlib.Path) -> pathlib.Path:
    resolved = path.resolve(strict=True)
    if not resolved.is_relative_to(root):
        raise ValueError(f"artifact escapes repository: {resolved}")
    if path.is_symlink() or not resolved.is_file():
        raise ValueError(f"artifact is not a regular non-symlink file: {path}")
    return resolved


def artifact(root: pathlib.Path, path: pathlib.Path, kind: str) -> dict[str, str]:
    resolved = safe_file(root, path)
    return {
        "kind": kind,
        "path": resolved.relative_to(root).as_posix(),
        "sha256": sha256_file(resolved),
    }


def require_pass_log(text: str, test_name: str, label: str) -> None:
    accepted_pass_lines = {f"[PASS] {test_name}", f"PASS {test_name}"}
    pass_lines = [line for line in text.splitlines() if line in accepted_pass_lines]
    if len(pass_lines) != 1:
        raise ValueError(f"{label}: expected one exact test PASS line")
    if text.count("[RESULT] PASS") != 1:
        raise ValueError(f"{label}: expected one exact marker [RESULT] PASS")
    for marker in ("[RESULT] FAIL", "[CHECK-FAIL]", "FATAL:"):
        if marker in text:
            raise ValueError(f"{label}: unexpected failure marker {marker}")


def parse_program_log(path: pathlib.Path) -> dict[str, int]:
    text = path.read_text(encoding="utf-8")
    require_pass_log(text, "tb_ooo_sv39_boot", "program log")
    matches = list(PROGRAM_RE.finditer(text))
    if len(matches) != 1:
        raise ValueError("program log: expected one INSTRET-G1 marker")
    values = tuple(int(value, 10) for value in matches[0].groups())
    names = (
        "exception_lanes", "exception_zero_delta", "mret", "sret",
        "sfence_vma", "control_exact", "control_total",
        "csr_delta_checks",
    )
    metrics = dict(zip(names, values, strict=True))
    exact = {
        "exception_lanes": 2,
        "exception_zero_delta": 2,
        "mret": 1,
        "sret": 6,
        "sfence_vma": 1,
        "control_exact": 8,
        "control_total": 8,
    }
    if any(metrics[name] != value for name, value in exact.items()):
        raise ValueError(f"program log: event inventory drifted: {metrics}")
    if metrics["csr_delta_checks"] < 1000:
        raise ValueError("program log: CsrFile edge-delta checker is too shallow")
    return metrics


def parse_focused_logs(paths: dict[str, pathlib.Path]) -> dict[str, str]:
    if set(paths) != set(FOCUSED_TESTS):
        raise ValueError("focused log inventory mismatch")
    result: dict[str, str] = {}
    for name, test_name in FOCUSED_TESTS.items():
        path = paths[name]
        text = path.read_text(encoding="utf-8")
        require_pass_log(text, test_name, f"focused {name}")
        result[name] = sha256_file(path)
    return result


def required_module_tests(makefile: pathlib.Path) -> list[str]:
    lines = makefile.read_text(encoding="utf-8").splitlines()
    tests: list[str] = []
    collecting = False
    for line in lines:
        stripped = line.strip()
        if not collecting:
            if not stripped.startswith("TESTS :="):
                continue
            collecting = True
            stripped = stripped.removeprefix("TESTS :=").strip()
        continued = stripped.endswith("\\")
        payload = stripped[:-1].strip() if continued else stripped
        if payload:
            tests.extend(payload.split())
        if not continued:
            break
    if not tests or len(tests) != len(set(tests)):
        raise ValueError("module TESTS inventory is empty or duplicated")
    if any(not re.fullmatch(r"tb_[a-z0-9_]+", name) for name in tests):
        raise ValueError("module TESTS inventory contains a malformed name")
    return tests


def parse_module_aggregate(
    root: pathlib.Path,
    summary: pathlib.Path,
) -> dict[str, Any]:
    tests = required_module_tests(root / "npc/rv64/testbench/Makefile")
    text = summary.read_text(encoding="utf-8")
    expected_count = len(tests)
    markers = (
        "# NPC single module testbench summary",
        f"- total: {expected_count}",
        f"- passed: {expected_count}",
        "- failed: 0",
    )
    if any(text.count(marker) != 1 for marker in markers):
        raise ValueError("module aggregate summary counts are incomplete")
    log_dir = summary.parent / "logs"
    actual_logs = {
        path.stem for path in log_dir.glob("*.log") if path.is_file()
    }
    if actual_logs != set(tests):
        raise ValueError("module aggregate log inventory is not exact")
    records: dict[str, dict[str, str]] = {}
    summary_lines = text.splitlines()
    for test_name in tests:
        if summary_lines.count(f"- PASS {test_name}") != 1:
            raise ValueError(f"module aggregate summary missing {test_name}")
        log_path = safe_file(root, log_dir / f"{test_name}.log")
        log_text = log_path.read_text(encoding="utf-8")
        require_pass_log(log_text, test_name, f"module aggregate {test_name}")
        records[test_name] = {
            "path": log_path.relative_to(root).as_posix(),
            "sha256": sha256_file(log_path),
        }
    return {
        "required": expected_count,
        "passed": expected_count,
        "failed": 0,
        "tests": records,
    }


def reconstruct_mutant(root: pathlib.Path, spec: Any) -> tuple[str, str]:
    source = safe_file(root, root / spec.source_rel)
    text = source.read_text(encoding="utf-8")
    if text.count(spec.old) != 1 or spec.old == spec.new:
        raise ValueError(f"{spec.name}: live RTL variant anchor is not unique")
    mutant = text.replace(spec.old, spec.new, 1)
    return sha256_bytes(text.encode("utf-8")), sha256_bytes(mutant.encode("utf-8"))


def validate_mutations(root: pathlib.Path, path: pathlib.Path) -> dict[str, Any]:
    payload = json.loads(path.read_text(encoding="utf-8"))
    specs = {spec.name: spec for spec in mutation_model.MUTATIONS}
    rows = payload.get("results")
    by_name = {
        row.get("name"): row
        for row in rows if isinstance(row, dict) and isinstance(row.get("name"), str)
    } if isinstance(rows, list) else {}
    expected = len(specs)
    if (
        payload.get("schema") != MUTATION_SCHEMA
        or payload.get("suite_run_id") != RUN_ID
        or payload.get("required") != expected
        or payload.get("compile_success") != expected
        or payload.get("dynamic_rejected") != expected
        or payload.get("source_unchanged") is not True
        or payload.get("source_sha256_before")
            != payload.get("source_sha256_after")
        or set(by_name) != set(specs)
    ):
        raise ValueError("RTL source variant aggregate is incomplete")

    verified: list[dict[str, str]] = []
    for name, spec in specs.items():
        row = by_name[name]
        live_sha, mutant_sha = reconstruct_mutant(root, spec)
        log = row.get("log")
        if not isinstance(log, dict):
            raise ValueError(f"{name}: missing variant log")
        log_path = safe_file(root, root / str(log.get("path")))
        log_text = log_path.read_text(encoding="utf-8")
        if (
            row.get("source") != spec.source_rel
            or row.get("make_variable") != spec.make_variable
            or row.get("original_sha256") != live_sha
            or row.get("mutant_sha256") != mutant_sha
            or row.get("expected_marker") != spec.expected_marker
            or row.get("marker_observed") is not True
            or row.get("compile_success") is not True
            or row.get("dynamic_rejected") is not True
            or log.get("sha256") != sha256_file(log_path)
            or spec.expected_marker not in log_text
            or "[RESULT] FAIL status=" not in log_text
            or "[RESULT] PASS" in log_text
        ):
            raise ValueError(f"{name}: variant evidence is stale or incomplete")
        verified.append({
            "name": name,
            "source": spec.source_rel,
            "mutant_sha256": mutant_sha,
            "log_sha256": sha256_file(log_path),
        })
    return {
        "required": expected,
        "compile_success": expected,
        "dynamic_rejected": expected,
        "source_unchanged": True,
        "variants": sorted(verified, key=lambda item: item["name"]),
    }


def build(
    *,
    root: pathlib.Path,
    program_log: pathlib.Path,
    focused_logs: dict[str, pathlib.Path],
    module_summary: pathlib.Path,
    mutation_summary: pathlib.Path,
) -> dict[str, Any]:
    metrics = parse_program_log(program_log)
    focused = parse_focused_logs(focused_logs)
    module_aggregate = parse_module_aggregate(root, module_summary)
    mutations = validate_mutations(root, mutation_summary)
    rtl_sha, rtl_files = arch.rtl_binding(root)

    source_paths = (
        "npc/rv64/vsrc/writeback/OooCommitOutputMux.v",
        "npc/rv64/vsrc/writeback/OooWriteback.v",
        "npc/rv64/vsrc/core/NpcCoreTop.v",
        "npc/rv64/vsrc/core/CsrFile.v",
        "npc/rv64/testbench/tests/tb_ooo_sv39_boot.sv",
        "npc/rv64/testbench/tests/tb_ooo_commit_output_mux.sv",
        "npc/rv64/testbench/tests/tb_ooo_alu_core_slice.sv",
        "npc/rv64/testbench/tests/tb_csr_file.sv",
        "npc/rv64/Makefile",
        "npc/rv64/testbench/Makefile",
        "npc/rv64/testbench/scripts/check_tb_result.py",
        "npc/rv64/testbench/scripts/check_ifu_icache_coherence_contract.py",
        ".github/task-runs/2026-07-21-rv64-v9c-instret-retirement/contract.md",
        ".github/task-runs/2026-07-21-rv64-v9c-instret-retirement/rtl-derivation.md",
        ".github/task-runs/2026-07-21-rv64-v9c-instret-retirement/run-focused.sh",
        ".github/task-runs/2026-07-21-rv64-v9c-instret-retirement/run-instret-mutations.py",
        "npc/rv64/eval/ppa/tools/instret_retirement_evidence.py",
    )
    source_bindings = {
        rel: sha256_file(safe_file(root, root / rel)) for rel in source_paths
    }
    artifacts = [
        artifact(root, program_log, "program_log"),
        artifact(root, module_summary, "module_aggregate_summary"),
        artifact(root, mutation_summary, "rtl_mutation_summary"),
    ]
    artifacts.extend(
        artifact(root, focused_logs[name], f"focused_{name}_log")
        for name in sorted(focused_logs)
    )
    return {
        "schema": SCHEMA,
        "suite_run_id": RUN_ID,
        "status": "PASS",
        "design_id": f"sha256:{rtl_sha}",
        "canonical_command": CANONICAL_COMMAND,
        "scope": (
            "local RV64 Verilog/SystemVerilog final commit retirement count "
            "and CsrFile minstret state"),
        "metrics": metrics,
        "invariants": {
            "exception_lane_delta_zero": True,
            "control_pseudo_commit_delta_one": True,
            "control_lane1_suppressed": True,
            "csr_uses_final_retire_count": True,
            "final_count_range_zero_to_two": True,
        },
        "focused_tests": {
            name: {"status": "PASS", "log_sha256": digest}
            for name, digest in sorted(focused.items())
        },
        "module_aggregate": module_aggregate,
        "mutation_audit": mutations,
        "provenance": {
            "rtl_sha256": rtl_sha,
            "files": rtl_files,
            "source_bindings": source_bindings,
        },
        "artifacts": artifacts,
        "claim": {
            "architecture_debt": "CLOSED_ELIGIBLE",
            "ppa": "UNQUALIFIED",
            "promotion_eligible": False,
        },
    }


def raw_summary(result: dict[str, Any]) -> str:
    metrics = result["metrics"]
    mutation = result["mutation_audit"]
    return "\n".join((
        f"schema={result['schema']}",
        f"design_id={result['design_id']}",
        f"canonical_command={result['canonical_command']}",
        "metric exception_lanes 2",
        "metric exception_zero_delta 2",
        "metric mret_control_delta_one 1",
        "metric sret_control_delta_one 6",
        "metric sfence_vma_control_delta_one 1",
        "metric control_exact 8",
        f"metric csr_delta_checks {metrics['csr_delta_checks']}",
        f"compile_success_rtl_mutations={mutation['compile_success']}",
        f"dynamic_rejected_rtl_mutations={mutation['dynamic_rejected']}",
        "focused_tests=3/3",
        f"module_aggregate={result['module_aggregate']['passed']}/"
        f"{result['module_aggregate']['required']}",
        "ppa=UNQUALIFIED",
        "promotion_eligible=false",
        "[INSTRET-G1-GATE] PASS",
        "",
    ))


def main(argv: Sequence[str] | None = None) -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", type=pathlib.Path, required=True)
    parser.add_argument("--program-log", type=pathlib.Path, required=True)
    for name in FOCUSED_TESTS:
        parser.add_argument(f"--{name.replace('_', '-')}-log", type=pathlib.Path, required=True)
    parser.add_argument("--mutation-summary", type=pathlib.Path, required=True)
    parser.add_argument("--module-summary", type=pathlib.Path, required=True)
    parser.add_argument("--output", type=pathlib.Path, required=True)
    parser.add_argument("--raw-log", type=pathlib.Path, required=True)
    args = parser.parse_args(argv)

    root = args.root.resolve(strict=True)
    output = args.output.resolve()
    raw_log = args.raw_log.resolve()
    for path in (output, raw_log):
        if not path.is_relative_to(root):
            raise ValueError(f"output escapes repository: {path}")
        path.parent.mkdir(parents=True, exist_ok=True)
    focused_logs = {
        name: safe_file(root, getattr(args, f"{name}_log"))
        for name in FOCUSED_TESTS
    }
    result = build(
        root=root,
        program_log=safe_file(root, args.program_log),
        focused_logs=focused_logs,
        module_summary=safe_file(root, args.module_summary),
        mutation_summary=safe_file(root, args.mutation_summary),
    )
    output.write_text(
        json.dumps(result, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )
    raw_log.write_text(raw_summary(result), encoding="utf-8")
    print(
        f"[INSTRET-G1-EVIDENCE] design_id={result['design_id']} "
        f"program=PASS focused=3/3 mutations=3/3 status=PASS")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
