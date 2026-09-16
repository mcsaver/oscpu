#!/usr/bin/env python3
"""Build fail-closed local RV64 FDG-G1 architectural-trap evidence."""

from __future__ import annotations

import argparse
import hashlib
import importlib.util
import json
import pathlib
import re
import sys
from typing import Any, Sequence


SCHEMA = "npc-rv64-fdg-arch-trap-evidence-v1"
MUTATION_SCHEMA = "npc-rv64-fdg-rtl-mutations-v1"
RUN_ID = "2026-07-21-rv64-v9d-fdg-arch-trap"
CANONICAL_COMMAND = "make -C npc/rv64 check-fdg-arch-trap"
REPO = pathlib.Path(__file__).resolve().parents[5]

ARCH_TOOL = pathlib.Path(__file__).with_name("architecture_hard_gates.py")
ARCH_SPEC = importlib.util.spec_from_file_location(
    "architecture_hard_gates_fdg", ARCH_TOOL)
assert ARCH_SPEC is not None and ARCH_SPEC.loader is not None
arch = importlib.util.module_from_spec(ARCH_SPEC)
sys.modules[ARCH_SPEC.name] = arch
ARCH_SPEC.loader.exec_module(arch)

MUTATION_RUNNER = REPO / f".github/task-runs/{RUN_ID}/run-fdg-mutations.py"
MUTATION_SPEC = importlib.util.spec_from_file_location(
    "fdg_rtl_mutations", MUTATION_RUNNER)
assert MUTATION_SPEC is not None and MUTATION_SPEC.loader is not None
mutation_model = importlib.util.module_from_spec(MUTATION_SPEC)
sys.modules[MUTATION_SPEC.name] = mutation_model
MUTATION_SPEC.loader.exec_module(mutation_model)

FOCUSED_RE = re.compile(
    r"^\[FDG-G1-FOCUSED\] illegal_fp_cases=(\d+) "
    r"illegal_classified=(\d+) arch_trap=(\d+) fp_disabled=(\d+) "
    r"backend_blocked=(\d+) legal_fp_cases=(\d+) "
    r"legal_backend_present=(\d+) PASS$",
    re.MULTILINE,
)
PROGRAM_RE = re.compile(
    r"^\[FDG-G1-PROGRAM\] arch_trap_capture=(\d+) "
    r"capture_pc_match=(\d+) capture_tval_match=(\d+) "
    r"ordinary_backend_present=(\d+) core_backend_present=(\d+) "
    r"commit_oracle_hits=(\d+) illegal_fp_commit=(\d+) "
    r"handler=(\d+) mret=(\d+) cause=(\d+) "
    r"csr_mepc_match=(\d+) csr_mtval_match=(\d+) PASS$",
    re.MULTILINE,
)


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


def parse_focused_log(path: pathlib.Path) -> dict[str, int]:
    text = path.read_text(encoding="utf-8")
    require_pass_log(text, "tb_ooo_fp_legality_dispatch_path", "focused log")
    matches = list(FOCUSED_RE.finditer(text))
    if len(matches) != 1:
        raise ValueError("focused log: expected one FDG-G1 focused marker")
    names = (
        "illegal_fp_cases", "illegal_classified", "arch_trap",
        "fp_disabled", "backend_blocked", "legal_fp_cases",
        "legal_backend_present",
    )
    metrics = dict(zip(names, (int(value) for value in matches[0].groups()), strict=True))
    expected = {
        "illegal_fp_cases": 4,
        "illegal_classified": 4,
        "arch_trap": 4,
        "fp_disabled": 4,
        "backend_blocked": 4,
        "legal_fp_cases": 1,
        "legal_backend_present": 1,
    }
    if metrics != expected:
        raise ValueError(f"focused log: matrix inventory drifted: {metrics}")
    return metrics


def parse_program_log(path: pathlib.Path) -> dict[str, int]:
    text = path.read_text(encoding="utf-8")
    require_pass_log(text, "tb_ooo_priv_system", "program log")
    matches = list(PROGRAM_RE.finditer(text))
    if len(matches) != 1:
        raise ValueError("program log: expected one FDG-G1 program marker")
    names = (
        "arch_trap_capture", "capture_pc_match", "capture_tval_match",
        "ordinary_backend_present", "core_backend_present",
        "commit_oracle_hits", "illegal_fp_commit", "handler", "mret",
        "cause", "csr_mepc_match", "csr_mtval_match",
    )
    metrics = dict(zip(names, (int(value) for value in matches[0].groups()), strict=True))
    expected = {
        "arch_trap_capture": 1,
        "capture_pc_match": 1,
        "capture_tval_match": 1,
        "ordinary_backend_present": 0,
        "core_backend_present": 0,
        "commit_oracle_hits": 1,
        "illegal_fp_commit": 0,
        "handler": 1,
        "mret": 1,
        "cause": 2,
        "csr_mepc_match": 1,
        "csr_mtval_match": 1,
    }
    if metrics != expected:
        raise ValueError(f"program log: event inventory drifted: {metrics}")
    return metrics


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
    actual_logs = {path.stem for path in log_dir.glob("*.log") if path.is_file()}
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
    oracle_specs = {
        spec.name: spec for spec in mutation_model.ORACLE_PROBES
    }
    rows = payload.get("results")
    by_name = {
        row.get("name"): row
        for row in rows if isinstance(row, dict) and isinstance(row.get("name"), str)
    } if isinstance(rows, list) else {}
    expected = len(specs)
    oracle_rows = payload.get("oracle_probes")
    oracle_by_name = {
        row.get("name"): row
        for row in oracle_rows
        if isinstance(row, dict) and isinstance(row.get("name"), str)
    } if isinstance(oracle_rows, list) else {}
    oracle_expected = len(oracle_specs)
    if (
        payload.get("schema") != MUTATION_SCHEMA
        or payload.get("suite_run_id") != RUN_ID
        or payload.get("required") != expected
        or payload.get("compile_success") != expected
        or payload.get("dynamic_rejected") != expected
        or payload.get("source_unchanged") is not True
        or payload.get("source_sha256_before") != payload.get("source_sha256_after")
        or set(by_name) != set(specs)
        or payload.get("oracle_probes_required") != oracle_expected
        or payload.get("oracle_probes_compile_success") != oracle_expected
        or payload.get("oracle_probes_dynamic_rejected") != oracle_expected
        or set(oracle_by_name) != set(oracle_specs)
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
            or row.get("test_name") != spec.test_name
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
    verified_oracles: list[dict[str, str]] = []
    for name, spec in oracle_specs.items():
        row = oracle_by_name[name]
        log = row.get("log")
        if not isinstance(log, dict):
            raise ValueError(f"{name}: missing oracle-probe log")
        log_path = safe_file(root, root / str(log.get("path")))
        log_text = log_path.read_text(encoding="utf-8")
        if (
            row.get("test_name") != spec.test_name
            or row.get("ivflags") != spec.ivflags
            or row.get("expected_marker") != spec.expected_marker
            or row.get("marker_observed") is not True
            or row.get("compile_success") is not True
            or row.get("dynamic_rejected") is not True
            or log.get("sha256") != sha256_file(log_path)
            or spec.expected_marker not in log_text
            or "[RESULT] FAIL status=" not in log_text
            or "[RESULT] PASS" in log_text
        ):
            raise ValueError(f"{name}: oracle-probe evidence is stale or incomplete")
        verified_oracles.append({
            "name": name,
            "ivflags": spec.ivflags,
            "log_sha256": sha256_file(log_path),
        })
    return {
        "required": expected,
        "compile_success": expected,
        "dynamic_rejected": expected,
        "source_unchanged": True,
        "variants": sorted(verified, key=lambda item: item["name"]),
        "oracle_probes_required": oracle_expected,
        "oracle_probes_compile_success": oracle_expected,
        "oracle_probes_dynamic_rejected": oracle_expected,
        "oracle_probes": sorted(
            verified_oracles, key=lambda item: item["name"]),
    }


SOURCE_BINDING_PATHS = (
    "npc/rv64/vsrc/frontend/OooFetchHeadClassifyGate.v",
    "npc/rv64/vsrc/frontend/OooFetchHeadPairGate.v",
    "npc/rv64/vsrc/frontend/OooFrontendDispatchGate.v",
    "npc/rv64/vsrc/frontend/OooFrontendBackendDispatchMux.v",
    "npc/rv64/vsrc/frontend/OooFrontend.v",
    "npc/rv64/vsrc/control/OooPendingDispatchArbiter.v",
    "npc/rv64/vsrc/control/OooPendingTrapExitSequencer.v",
    "npc/rv64/vsrc/control/OooControlPlane.v",
    "npc/rv64/vsrc/core/OooCoreTopGlue.v",
    "npc/rv64/testbench/tests/tb_ooo_fp_legality_dispatch_path.sv",
    "npc/rv64/testbench/tests/tb_ooo_priv_system.sv",
    "npc/rv64/testbench/Makefile",
    "npc/rv64/testbench/scripts/check_tb_result.py",
    "npc/rv64/Makefile",
    ".github/task-runs/2026-07-21-rv64-v9d-fdg-arch-trap/contract.md",
    ".github/task-runs/2026-07-21-rv64-v9d-fdg-arch-trap/rtl-derivation.md",
    ".github/task-runs/2026-07-21-rv64-v9d-fdg-arch-trap/run-focused.sh",
    ".github/task-runs/2026-07-21-rv64-v9d-fdg-arch-trap/run-fdg-mutations.py",
    "npc/rv64/eval/ppa/tools/fdg_arch_trap_evidence.py",
    "npc/rv64/eval/ppa/tools/arch_stable_freeze.py",
    "npc/rv64/eval/ppa/tests/test_fdg_arch_trap_evidence.py",
)


def build(
    *,
    root: pathlib.Path,
    focused_log: pathlib.Path,
    program_log: pathlib.Path,
    module_summary: pathlib.Path,
    mutation_summary: pathlib.Path,
) -> dict[str, Any]:
    focused = parse_focused_log(focused_log)
    program = parse_program_log(program_log)
    module_aggregate = parse_module_aggregate(root, module_summary)
    mutations = validate_mutations(root, mutation_summary)
    rtl_sha, rtl_files = arch.rtl_binding(root)
    source_bindings = {
        rel: sha256_file(safe_file(root, root / rel))
        for rel in SOURCE_BINDING_PATHS
    }
    return {
        "schema": SCHEMA,
        "suite_run_id": RUN_ID,
        "status": "PASS",
        "design_id": f"sha256:{rtl_sha}",
        "canonical_command": CANONICAL_COMMAND,
        "scope": (
            "local RV64 Verilog/SystemVerilog head0 architectural-trap "
            "classification, ordinary backend admission, final backend mux, "
            "precise-trap owner and commit boundary"),
        "metrics": {"focused": focused, "program": program},
        "invariants": {
            "illegal_fp_never_reaches_ordinary_admission": True,
            "illegal_fp_never_reaches_final_backend_dispatch": True,
            "illegal_fp_never_commits": True,
            "commit_observer_is_nonvacuous": True,
            "precise_trap_pc_tval_are_exact": True,
            "precise_trap_capture_and_return": True,
            "legal_fp_reaches_backend": True,
            "classification_source_is_not_redecoded_in_dispatch_gate": True,
        },
        "focused_tests": {
            "legality_dispatch": {
                "status": "PASS",
                "log_sha256": sha256_file(focused_log),
            },
            "privileged_program": {
                "status": "PASS",
                "log_sha256": sha256_file(program_log),
            },
        },
        "module_aggregate": module_aggregate,
        "mutation_audit": mutations,
        "provenance": {
            "rtl_sha256": rtl_sha,
            "files": rtl_files,
            "source_bindings": source_bindings,
        },
        "artifacts": [
            artifact(root, focused_log, "focused_legality_dispatch_log"),
            artifact(root, program_log, "program_log"),
            artifact(root, module_summary, "module_aggregate_summary"),
            artifact(root, mutation_summary, "rtl_mutation_summary"),
        ],
        "claim": {
            "architecture_debt": "CLOSED_ELIGIBLE",
            "ppa": "UNQUALIFIED",
            "promotion_eligible": False,
        },
    }


def raw_summary(result: dict[str, Any]) -> str:
    focused = result["metrics"]["focused"]
    program = result["metrics"]["program"]
    mutation = result["mutation_audit"]
    aggregate = result["module_aggregate"]
    return "\n".join((
        f"schema={result['schema']}",
        f"design_id={result['design_id']}",
        f"canonical_command={result['canonical_command']}",
        f"focused_illegal_fp_cases={focused['illegal_fp_cases']}",
        f"focused_backend_blocked={focused['backend_blocked']}",
        f"focused_legal_backend_present={focused['legal_backend_present']}",
        f"program_arch_trap_capture={program['arch_trap_capture']}",
        f"program_capture_pc_match={program['capture_pc_match']}",
        f"program_capture_tval_match={program['capture_tval_match']}",
        f"program_ordinary_backend_present={program['ordinary_backend_present']}",
        f"program_core_backend_present={program['core_backend_present']}",
        f"program_commit_oracle_hits={program['commit_oracle_hits']}",
        f"program_illegal_fp_commit={program['illegal_fp_commit']}",
        f"program_csr_mepc_match={program['csr_mepc_match']}",
        f"program_csr_mtval_match={program['csr_mtval_match']}",
        f"compile_success_rtl_variants={mutation['compile_success']}",
        f"dynamic_rejected_rtl_variants={mutation['dynamic_rejected']}",
        f"compile_success_oracle_probes={mutation['oracle_probes_compile_success']}",
        f"dynamic_rejected_oracle_probes={mutation['oracle_probes_dynamic_rejected']}",
        "focused_tests=2/2",
        f"module_aggregate={aggregate['passed']}/{aggregate['required']}",
        "ppa=UNQUALIFIED",
        "promotion_eligible=false",
        "[FDG-G1-GATE] PASS",
        "",
    ))


def main(argv: Sequence[str] | None = None) -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", type=pathlib.Path, required=True)
    parser.add_argument("--focused-log", type=pathlib.Path, required=True)
    parser.add_argument("--program-log", type=pathlib.Path, required=True)
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
    result = build(
        root=root,
        focused_log=safe_file(root, args.focused_log),
        program_log=safe_file(root, args.program_log),
        module_summary=safe_file(root, args.module_summary),
        mutation_summary=safe_file(root, args.mutation_summary),
    )
    output.write_text(
        json.dumps(result, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )
    raw_log.write_text(raw_summary(result), encoding="utf-8")
    print(
        f"[FDG-G1-EVIDENCE] design_id={result['design_id']} "
        f"focused=2/2 variants={result['mutation_audit']['dynamic_rejected']}/"
        f"{result['mutation_audit']['required']} "
        f"oracle_probes={result['mutation_audit']['oracle_probes_dynamic_rejected']}/"
        f"{result['mutation_audit']['oracle_probes_required']} status=PASS")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
