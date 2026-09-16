#!/usr/bin/env python3
"""Build fail-closed local RV64 XRET-G1 current-mode evidence."""

from __future__ import annotations

import argparse
import hashlib
import importlib.util
import json
import pathlib
import re
import sys
from typing import Any, Sequence


SCHEMA = "npc-rv64-xret-current-mode-evidence-v1"
MUTATION_SCHEMA = "npc-rv64-xret-rtl-mutations-v1"
RUN_ID = "2026-07-21-rv64-v9e-xret-current-design"
CANONICAL_COMMAND = "make -C npc/rv64 check-xret-current-mode"
REPO = pathlib.Path(__file__).resolve().parents[5]

ARCH_TOOL = pathlib.Path(__file__).with_name("architecture_hard_gates.py")
ARCH_SPEC = importlib.util.spec_from_file_location(
    "architecture_hard_gates_xret", ARCH_TOOL)
assert ARCH_SPEC is not None and ARCH_SPEC.loader is not None
arch = importlib.util.module_from_spec(ARCH_SPEC)
sys.modules[ARCH_SPEC.name] = arch
ARCH_SPEC.loader.exec_module(arch)

MUTATION_RUNNER = REPO / f".github/task-runs/{RUN_ID}/run-xret-mutations.py"
MUTATION_SPEC = importlib.util.spec_from_file_location(
    "xret_rtl_mutations", MUTATION_RUNNER)
assert MUTATION_SPEC is not None and MUTATION_SPEC.loader is not None
mutation_model = importlib.util.module_from_spec(MUTATION_SPEC)
sys.modules[MUTATION_SPEC.name] = mutation_model
MUTATION_SPEC.loader.exec_module(mutation_model)

FOCUSED_RE = re.compile(
    r"^\[XRET-G1-FOCUSED\] cases=(\d+) legal=(\d+) illegal=(\d+) "
    r"raw_preserved=(\d+) legal_system=(\d+) "
    r"illegal_arch_trap=(\d+) PASS$",
    re.MULTILINE,
)
LEGAL_MRET_RE = re.compile(
    r"^\[XRET-G1-PROGRAM-LEGAL-MRET\] csr_request=(\d+) "
    r"commit=(\d+) return=(\d+) backend_drained=(\d+) PASS$",
    re.MULTILINE,
)
LEGAL_SRET_RE = re.compile(
    r"^\[XRET-G1-PROGRAM-LEGAL-SRET\] csr_request=(\d+) "
    r"commit=(\d+) return=(\d+) backend_drained=(\d+) PASS$",
    re.MULTILINE,
)
ILLEGAL_MRET_RE = re.compile(
    r"^\[XRET-G1-PROGRAM-ILLEGAL-MRET\] arch_trap_capture=(\d+) "
    r"capture_pc_match=(\d+) capture_tval_match=(\d+) "
    r"request_oracle_hits=(\d+) csr_request=(\d+) "
    r"commit_oracle_hits=(\d+) commit=(\d+) handler=(\d+) cause=(\d+) "
    r"csr_mepc_match=(\d+) csr_mtval_match=(\d+) return=(\d+) "
    r"backend_drained=(\d+) PASS$",
    re.MULTILINE,
)
ILLEGAL_SRET_RE = re.compile(
    r"^\[XRET-G1-PROGRAM-ILLEGAL-SRET\] arch_trap_capture=(\d+) "
    r"capture_pc_match=(\d+) capture_tval_match=(\d+) "
    r"request_oracle_hits=(\d+) csr_request=(\d+) "
    r"commit_oracle_hits=(\d+) commit=(\d+) handler=(\d+) cause=(\d+) "
    r"csr_mepc_match=(\d+) csr_mtval_match=(\d+) older_lane0=(\d+) "
    r"return=(\d+) backend_drained=(\d+) PASS$",
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
    accepted = {f"[PASS] {test_name}", f"PASS {test_name}"}
    if len([line for line in text.splitlines() if line in accepted]) != 1:
        raise ValueError(f"{label}: expected one exact test PASS line")
    if text.count("[RESULT] PASS") != 1:
        raise ValueError(f"{label}: expected one exact marker [RESULT] PASS")
    for marker in ("[RESULT] FAIL", "[CHECK-FAIL]", "FATAL:"):
        if marker in text:
            raise ValueError(f"{label}: unexpected failure marker {marker}")


def parse_one_marker(
    regex: re.Pattern[str],
    text: str,
    names: tuple[str, ...],
    expected: dict[str, int],
    label: str,
) -> dict[str, int]:
    matches = list(regex.finditer(text))
    if len(matches) != 1:
        raise ValueError(f"{label}: expected one exact semantic marker")
    metrics = dict(zip(
        names, (int(value) for value in matches[0].groups()), strict=True))
    if metrics != expected:
        raise ValueError(f"{label}: event inventory drifted: {metrics}")
    return metrics


def parse_focused_log(path: pathlib.Path) -> dict[str, int]:
    text = path.read_text(encoding="utf-8")
    require_pass_log(text, "tb_ooo_fetch_head_classify_gate", "focused log")
    names = (
        "cases", "legal", "illegal", "raw_preserved", "legal_system",
        "illegal_arch_trap",
    )
    expected = {
        "cases": 7,
        "legal": 3,
        "illegal": 4,
        "raw_preserved": 7,
        "legal_system": 3,
        "illegal_arch_trap": 4,
    }
    return parse_one_marker(
        FOCUSED_RE, text, names, expected, "focused log")


def parse_program_log(path: pathlib.Path) -> dict[str, dict[str, int]]:
    text = path.read_text(encoding="utf-8")
    require_pass_log(text, "tb_ooo_priv_system", "program log")
    legal_names = ("csr_request", "commit", "return", "backend_drained")
    legal_expected = {
        "csr_request": 1, "commit": 1, "return": 1, "backend_drained": 1,
    }
    illegal_names = (
        "arch_trap_capture", "capture_pc_match", "capture_tval_match",
        "request_oracle_hits", "csr_request", "commit_oracle_hits",
        "commit", "handler", "cause", "csr_mepc_match",
        "csr_mtval_match", "return", "backend_drained",
    )
    illegal_expected = {
        "arch_trap_capture": 1,
        "capture_pc_match": 1,
        "capture_tval_match": 1,
        "request_oracle_hits": 1,
        "csr_request": 0,
        "commit_oracle_hits": 1,
        "commit": 0,
        "handler": 1,
        "cause": 2,
        "csr_mepc_match": 1,
        "csr_mtval_match": 1,
        "return": 1,
        "backend_drained": 1,
    }
    illegal_sret_names = illegal_names[:-2] + (
        "older_lane0", "return", "backend_drained")
    illegal_sret_expected = dict(illegal_expected)
    illegal_sret_expected["older_lane0"] = 1
    return {
        "legal_mret": parse_one_marker(
            LEGAL_MRET_RE, text, legal_names, legal_expected,
            "program legal MRET"),
        "legal_sret": parse_one_marker(
            LEGAL_SRET_RE, text, legal_names, legal_expected,
            "program legal SRET"),
        "illegal_mret": parse_one_marker(
            ILLEGAL_MRET_RE, text, illegal_names, illegal_expected,
            "program illegal MRET"),
        "illegal_sret": parse_one_marker(
            ILLEGAL_SRET_RE, text, illegal_sret_names,
            illegal_sret_expected, "program illegal SRET"),
    }


def required_module_tests(makefile: pathlib.Path) -> list[str]:
    tests: list[str] = []
    collecting = False
    for line in makefile.read_text(encoding="utf-8").splitlines():
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
    count = len(tests)
    markers = (
        "# NPC single module testbench summary",
        f"- total: {count}", f"- passed: {count}", "- failed: 0",
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
        require_pass_log(
            log_path.read_text(encoding="utf-8"), test_name,
            f"module aggregate {test_name}")
        records[test_name] = {
            "path": log_path.relative_to(root).as_posix(),
            "sha256": sha256_file(log_path),
        }
    return {
        "required": count,
        "passed": count,
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
    oracle_specs = {spec.name: spec for spec in mutation_model.ORACLE_PROBES}
    rows = payload.get("results")
    by_name = {
        row.get("name"): row for row in rows
        if isinstance(row, dict) and isinstance(row.get("name"), str)
    } if isinstance(rows, list) else {}
    oracle_rows = payload.get("oracle_probes")
    oracle_by_name = {
        row.get("name"): row for row in oracle_rows
        if isinstance(row, dict) and isinstance(row.get("name"), str)
    } if isinstance(oracle_rows, list) else {}
    if not (
        payload.get("schema") == MUTATION_SCHEMA
        and payload.get("suite_run_id") == RUN_ID
        and payload.get("required") == len(specs)
        and payload.get("compile_success") == len(specs)
        and payload.get("dynamic_rejected") == len(specs)
        and payload.get("source_unchanged") is True
        and payload.get("source_sha256_before")
        == payload.get("source_sha256_after")
        and set(by_name) == set(specs)
        and payload.get("oracle_probes_required") == len(oracle_specs)
        and payload.get("oracle_probes_compile_success") == len(oracle_specs)
        and payload.get("oracle_probes_dynamic_rejected") == len(oracle_specs)
        and set(oracle_by_name) == set(oracle_specs)
    ):
        raise ValueError("RTL verification-variant aggregate is incomplete")

    verified: list[dict[str, str]] = []
    for name, spec in specs.items():
        row = by_name[name]
        live_sha, mutant_sha = reconstruct_mutant(root, spec)
        log = row.get("log")
        if not isinstance(log, dict):
            raise ValueError(f"{name}: missing variant log")
        log_path = safe_file(root, root / str(log.get("path")))
        log_text = log_path.read_text(encoding="utf-8")
        if not (
            row.get("source") == spec.source_rel
            and row.get("make_variable") == spec.make_variable
            and row.get("test_name") == spec.test_name
            and row.get("original_sha256") == live_sha
            and row.get("mutant_sha256") == mutant_sha
            and row.get("expected_marker") == spec.expected_marker
            and row.get("marker_observed") is True
            and row.get("compile_success") is True
            and row.get("dynamic_rejected") is True
            and log.get("sha256") == sha256_file(log_path)
            and spec.expected_marker in log_text
            and "[RESULT] FAIL status=" in log_text
            and "[RESULT] PASS" not in log_text
        ):
            raise ValueError(f"{name}: RTL verification-variant evidence is stale")
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
        if not (
            row.get("test_name") == spec.test_name
            and row.get("ivflags") == spec.ivflags
            and row.get("expected_marker") == spec.expected_marker
            and row.get("marker_observed") is True
            and row.get("compile_success") is True
            and row.get("dynamic_rejected") is True
            and log.get("sha256") == sha256_file(log_path)
            and spec.expected_marker in log_text
            and "[RESULT] FAIL status=" in log_text
            and "[RESULT] PASS" not in log_text
        ):
            raise ValueError(f"{name}: oracle-probe evidence is stale")
        verified_oracles.append({
            "name": name,
            "ivflags": spec.ivflags,
            "log_sha256": sha256_file(log_path),
        })
    return {
        "required": len(specs),
        "compile_success": len(specs),
        "dynamic_rejected": len(specs),
        "source_unchanged": True,
        "variants": sorted(verified, key=lambda item: item["name"]),
        "oracle_probes_required": len(oracle_specs),
        "oracle_probes_compile_success": len(oracle_specs),
        "oracle_probes_dynamic_rejected": len(oracle_specs),
        "oracle_probes": sorted(
            verified_oracles, key=lambda item: item["name"]),
    }


SOURCE_BINDING_PATHS = (
    "npc/rv64/vsrc/common/OooSlotFacts.v",
    "npc/rv64/vsrc/frontend/OooFetchHeadClassifyGate.v",
    "npc/rv64/vsrc/frontend/OooFetchHeadPairGate.v",
    "npc/rv64/vsrc/frontend/OooFrontend.v",
    "npc/rv64/vsrc/control/OooPendingLane1CaptureGate.v",
    "npc/rv64/vsrc/control/OooPendingDispatchArbiter.v",
    "npc/rv64/vsrc/control/OooPendingTrapExitSequencer.v",
    "npc/rv64/vsrc/control/OooPendingSystemSequencer.v",
    "npc/rv64/vsrc/control/OooCsrTrapRequestMux.v",
    "npc/rv64/vsrc/control/OooControlPlane.v",
    "npc/rv64/vsrc/core/OooCoreTopGlue.v",
    "npc/rv64/vsrc/core/CsrFile.v",
    "npc/rv64/testbench/tests/tb_ooo_fetch_head_classify_gate.sv",
    "npc/rv64/testbench/tests/tb_ooo_priv_system.sv",
    "npc/rv64/testbench/Makefile",
    "npc/rv64/testbench/scripts/check_tb_result.py",
    "npc/rv64/Makefile",
    f".github/task-runs/{RUN_ID}/contract.md",
    f".github/task-runs/{RUN_ID}/rtl-derivation.md",
    f".github/task-runs/{RUN_ID}/run-focused.sh",
    f".github/task-runs/{RUN_ID}/run-xret-mutations.py",
    "npc/rv64/eval/ppa/tools/xret_current_mode_evidence.py",
    "npc/rv64/eval/ppa/tools/arch_stable_freeze.py",
    "npc/rv64/eval/ppa/tests/test_xret_current_mode_evidence.py",
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
    module = parse_module_aggregate(root, module_summary)
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
            "local RV64 Verilog/SystemVerilog MRET/SRET current-mode "
            "classification, head0/lane1 precise-exception ownership, "
            "CsrFile request boundary and architectural commit"),
        "metrics": {"focused": focused, "program": program},
        "invariants": {
            "mret_only_legal_in_m_mode": True,
            "sret_illegal_in_u_mode": True,
            "sret_tsr_only_blocks_s_mode": True,
            "illegal_xret_selects_precise_trap_owner": True,
            "illegal_xret_never_requests_csr_return": True,
            "illegal_xret_never_commits": True,
            "zero_oracles_are_nonvacuous": True,
            "precise_trap_pc_tval_are_exact": True,
            "lane1_older_instruction_retires": True,
            "legal_mret_sret_request_commit_return": True,
            "legality_source_not_redecoded_in_csr_file": True,
        },
        "focused_tests": {
            "current_mode_matrix": {
                "status": "PASS", "log_sha256": sha256_file(focused_log)},
            "privileged_programs": {
                "status": "PASS", "log_sha256": sha256_file(program_log)},
        },
        "module_aggregate": module,
        "mutation_audit": mutations,
        "provenance": {
            "rtl_sha256": rtl_sha,
            "files": rtl_files,
            "source_bindings": source_bindings,
        },
        "artifacts": [
            artifact(root, focused_log, "focused_current_mode_log"),
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
    mutations = result["mutation_audit"]
    module = result["module_aggregate"]
    return "\n".join((
        f"schema={result['schema']}",
        f"design_id={result['design_id']}",
        f"canonical_command={result['canonical_command']}",
        f"focused_cases={focused['cases']}",
        f"focused_legal={focused['legal']}",
        f"focused_illegal={focused['illegal']}",
        f"focused_raw_preserved={focused['raw_preserved']}",
        f"focused_legal_system={focused['legal_system']}",
        f"focused_illegal_arch_trap={focused['illegal_arch_trap']}",
        f"legal_mret_csr_request={program['legal_mret']['csr_request']}",
        f"legal_mret_commit={program['legal_mret']['commit']}",
        f"legal_sret_csr_request={program['legal_sret']['csr_request']}",
        f"legal_sret_commit={program['legal_sret']['commit']}",
        f"illegal_mret_arch_trap_capture={program['illegal_mret']['arch_trap_capture']}",
        f"illegal_mret_csr_request={program['illegal_mret']['csr_request']}",
        f"illegal_mret_commit={program['illegal_mret']['commit']}",
        f"illegal_sret_arch_trap_capture={program['illegal_sret']['arch_trap_capture']}",
        f"illegal_sret_csr_request={program['illegal_sret']['csr_request']}",
        f"illegal_sret_commit={program['illegal_sret']['commit']}",
        f"compile_success_rtl_variants={mutations['compile_success']}",
        f"dynamic_rejected_rtl_variants={mutations['dynamic_rejected']}",
        f"compile_success_oracle_probes={mutations['oracle_probes_compile_success']}",
        f"dynamic_rejected_oracle_probes={mutations['oracle_probes_dynamic_rejected']}",
        "focused_tests=2/2",
        f"module_aggregate={module['passed']}/{module['required']}",
        "ppa=UNQUALIFIED",
        "promotion_eligible=false",
        "[XRET-G1-GATE] PASS",
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
        encoding="utf-8")
    raw_log.write_text(raw_summary(result), encoding="utf-8")
    print(
        f"[XRET-G1-EVIDENCE] design_id={result['design_id']} focused=2/2 "
        f"variants={result['mutation_audit']['dynamic_rejected']}/"
        f"{result['mutation_audit']['required']} oracle_probes="
        f"{result['mutation_audit']['oracle_probes_dynamic_rejected']}/"
        f"{result['mutation_audit']['oracle_probes_required']} status=PASS")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
