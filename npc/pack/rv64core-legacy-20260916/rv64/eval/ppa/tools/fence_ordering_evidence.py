#!/usr/bin/env python3
"""Build fail-closed local RV64 FENCE-G1 ordering evidence."""

from __future__ import annotations

import argparse
import hashlib
import importlib.util
import json
import pathlib
import re
import sys
from typing import Any, Sequence


SCHEMA = "npc-rv64-fence-ordering-evidence-v2"
VARIANT_SCHEMA = "npc-rv64-fence-rtl-variants-v2"
RUN_ID = "2026-07-23-rv64-v9m-fence-ordering-current-design"
CANONICAL_COMMAND = "make -C npc/rv64 check-fence-ordering"
REPO = pathlib.Path(__file__).resolve().parents[5]

ARCH_TOOL = pathlib.Path(__file__).with_name("architecture_hard_gates.py")
ARCH_SPEC = importlib.util.spec_from_file_location(
    "architecture_hard_gates", ARCH_TOOL)
assert ARCH_SPEC is not None and ARCH_SPEC.loader is not None
arch = importlib.util.module_from_spec(ARCH_SPEC)
sys.modules[ARCH_SPEC.name] = arch
ARCH_SPEC.loader.exec_module(arch)

VARIANT_RUNNER = REPO / f".github/task-runs/{RUN_ID}/run-fence-rtl-variants.py"
VARIANT_SPEC = importlib.util.spec_from_file_location(
    "fence_rtl_variants", VARIANT_RUNNER)
assert VARIANT_SPEC is not None and VARIANT_SPEC.loader is not None
variant_model = importlib.util.module_from_spec(VARIANT_SPEC)
sys.modules[VARIANT_SPEC.name] = variant_model
VARIANT_SPEC.loader.exec_module(variant_model)

PROGRAM_RE = re.compile(
    r"^\[FENCE-G1-PROGRAM\] "
    r"exit=(\d+) ebreak=(\d+) trap=(\d+) "
    r"lane1_capture=(\d+) full_memory_wait=(\d+) "
    r"mem_idle_binding=(\d+) "
    r"fence_commit=(\d+) store_probe=(\d+) store_drain=(\d+) "
    r"device_read=(\d+) fence_before_store=(\d+) "
    r"device_before_store=(\d+) device_before_fence=(\d+) "
    r"readback_match=(\d+) backend_drained=(\d+) PASS$",
    re.MULTILINE,
)

PROGRAM_METRICS = {
    "exit": 1,
    "ebreak": 1,
    "trap": 0,
    "lane1_capture": 1,
    "full_memory_wait": 1,
    "mem_idle_binding": 1,
    "fence_commit": 1,
    "store_probe": 1,
    "store_drain": 1,
    "device_read": 1,
    "fence_before_store": 0,
    "device_before_store": 0,
    "device_before_fence": 0,
    "readback_match": 1,
    "backend_drained": 1,
}

FOCUSED_TESTS = {
    "program": "tb_ooo_priv_system",
    "drain_gate": "tb_ooo_pending_drain_resolve_gate",
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


def require_pass_log(
    text: str,
    test_name: str,
    label: str,
    *,
    require_compile: bool = False,
) -> None:
    lines = text.splitlines()
    accepted = {f"[PASS] {test_name}", f"PASS {test_name}"}
    pass_lines = [line for line in lines if line in accepted]
    if len(pass_lines) != 1:
        raise ValueError(f"{label}: expected one exact test PASS line")
    result_lines = [line for line in lines if line.startswith("[RESULT] ")]
    if result_lines != ["[RESULT] PASS"]:
        raise ValueError(f"{label}: expected one exact marker [RESULT] PASS")
    compile_lines = [
        line for line in lines if line.startswith("[COMPILE] ")]
    if require_compile and len(compile_lines) != 1:
        raise ValueError(f"{label}: expected one exact [COMPILE] line")
    if "compile returned nonzero status" in text:
        raise ValueError(f"{label}: compile failure text is not permitted")
    for marker in ("[RESULT] FAIL", "[CHECK-FAIL]", "FATAL:"):
        if marker in text:
            raise ValueError(f"{label}: unexpected failure marker {marker}")
    if any(line.startswith("ERROR:") for line in lines):
        raise ValueError(f"{label}: unexpected failure marker ERROR:")


def require_design_marker(text: str, design_id: str, label: str) -> None:
    marker = f"[RTL-DESIGN-ID] {design_id}"
    if text.splitlines().count(marker) != 1:
        raise ValueError(f"{label}: runtime RTL design-id marker is missing")


def parse_program_log(
    path: pathlib.Path,
    expected_design_id: str | None = None,
) -> dict[str, int]:
    text = path.read_text(encoding="utf-8")
    require_pass_log(text, FOCUSED_TESTS["program"], "FENCE program log")
    if expected_design_id is not None:
        require_design_marker(text, expected_design_id, "FENCE program log")
    matches = list(PROGRAM_RE.finditer(text))
    if len(matches) != 1:
        raise ValueError("FENCE program log: expected one exact FENCE-G1 marker")
    metrics = dict(zip(
        PROGRAM_METRICS,
        (int(value, 10) for value in matches[0].groups()),
        strict=True,
    ))
    if metrics != PROGRAM_METRICS:
        raise ValueError(f"FENCE program log: ordering inventory drifted: {metrics}")
    if text.count("[FENCE-G1-PROGRAM]") != 1 or "[FENCE-G1-PROGRAM] " not in text:
        raise ValueError("FENCE program log: marker inventory is ambiguous")
    return metrics


def parse_focused_logs(
    paths: dict[str, pathlib.Path],
    expected_design_id: str,
) -> dict[str, str]:
    if set(paths) != set(FOCUSED_TESTS):
        raise ValueError("FENCE focused log inventory mismatch")
    result: dict[str, str] = {}
    for name, test_name in FOCUSED_TESTS.items():
        path = paths[name]
        text = path.read_text(encoding="utf-8")
        require_pass_log(
            text, test_name, f"FENCE focused {name}", require_compile=True)
        require_design_marker(
            text, expected_design_id, f"FENCE focused {name}")
        if name == "program":
            parse_program_log(path, expected_design_id)
        result[name] = sha256_file(path)
    return result


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
    expected_design_id: str | None = None,
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
        require_pass_log(
            log_text, test_name, f"module aggregate {test_name}",
            require_compile=True)
        if expected_design_id is not None:
            require_design_marker(
                log_text, expected_design_id,
                f"module aggregate {test_name}")
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


def reconstruct_variant(root: pathlib.Path, spec: Any) -> tuple[str, str]:
    source = safe_file(root, root / spec.source_rel)
    text = source.read_text(encoding="utf-8")
    if text.count(spec.old) != 1 or spec.old == spec.new:
        raise ValueError(f"{spec.name}: live RTL variant anchor is not unique")
    variant = text.replace(spec.old, spec.new, 1)
    return sha256_bytes(text.encode("utf-8")), sha256_bytes(variant.encode("utf-8"))


def validate_variants(root: pathlib.Path, path: pathlib.Path) -> dict[str, Any]:
    payload = json.loads(path.read_text(encoding="utf-8"))
    specs = {spec.name: spec for spec in variant_model.VARIANTS}
    rows = payload.get("results")
    row_list = rows if isinstance(rows, list) else []
    by_name = {
        row.get("name"): row
        for row in row_list
        if isinstance(row, dict) and isinstance(row.get("name"), str)
    }
    expected = len(specs)
    source_before = payload.get("source_sha256_before")
    source_after = payload.get("source_sha256_after")
    if (
        payload.get("schema") != VARIANT_SCHEMA
        or payload.get("suite_run_id") != RUN_ID
        or payload.get("required") != expected
        or payload.get("compile_success") != expected
        or payload.get("dynamic_rejected") != expected
        or payload.get("source_unchanged") is not True
        or not isinstance(source_before, dict)
        or source_before != source_after
        or set(source_before) != {spec.source_rel for spec in specs.values()}
        or len(row_list) != expected
        or set(by_name) != set(specs)
    ):
        raise ValueError("FENCE RTL source variant aggregate is incomplete")

    verified: list[dict[str, str]] = []
    for name, spec in specs.items():
        row = by_name[name]
        live_sha, variant_sha = reconstruct_variant(root, spec)
        log = row.get("log")
        if not isinstance(log, dict):
            raise ValueError(f"{name}: missing RTL variant log")
        log_path = safe_file(root, root / str(log.get("path")))
        log_text = log_path.read_text(encoding="utf-8")
        log_lines = log_text.splitlines()
        compile_lines = [
            line for line in log_lines if line.startswith("[COMPILE] ")]
        check_fail_lines = [
            line for line in log_lines if line.startswith("[CHECK-FAIL] ")]
        fail_lines = [
            line for line in log_lines if line.startswith("[FAIL] ")]
        result_lines = [
            line for line in log_lines if line.startswith("[RESULT] ")]
        if (
            source_before.get(spec.source_rel) != live_sha
            or row.get("source") != spec.source_rel
            or row.get("make_variable") != spec.make_variable
            or row.get("test_name") != spec.test_name
            or row.get("original_sha256") != live_sha
            or row.get("variant_sha256") != variant_sha
            or row.get("expected_marker") != spec.expected_marker
            or row.get("marker_observed") is not True
            or row.get("compile_success") is not True
            or row.get("dynamic_rejected") is not True
            or log.get("sha256") != sha256_file(log_path)
            or len(compile_lines) != 1
            or "compile returned nonzero status" in log_text
            or check_fail_lines != [spec.expected_marker]
            or fail_lines != [f"[FAIL] {spec.test_name} errors=1"]
            or result_lines != ["[RESULT] FAIL status=1"]
            or any(line.startswith("ERROR:") for line in log_lines)
            or "[RESULT] PASS" in log_text
        ):
            raise ValueError(f"{name}: RTL variant evidence is stale or incomplete")
        verified.append({
            "name": name,
            "source": spec.source_rel,
            "test_name": spec.test_name,
            "variant_sha256": variant_sha,
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
    drain_gate_log: pathlib.Path,
    module_summary: pathlib.Path,
    variant_summary: pathlib.Path,
) -> dict[str, Any]:
    rtl_sha, rtl_files = arch.rtl_binding(root)
    design_id = f"sha256:{rtl_sha}"
    metrics = parse_program_log(program_log, design_id)
    focused_logs = {
        "program": program_log,
        "drain_gate": drain_gate_log,
    }
    focused = parse_focused_logs(focused_logs, design_id)
    module_aggregate = parse_module_aggregate(
        root, module_summary, design_id)
    variants = validate_variants(root, variant_summary)

    source_paths = (
        "npc/rv64/vsrc/frontend/OooFetchHeadClassifyGate.v",
        "npc/rv64/vsrc/control/OooPendingDrainResolveGate.v",
        "npc/rv64/vsrc/control/OooPendingSystemSequencer.v",
        "npc/rv64/vsrc/control/OooControlPlane.v",
        "npc/rv64/vsrc/execute/OooIntBackend.v",
        "npc/rv64/vsrc/execute/OooAluCoreSlice.v",
        "npc/rv64/vsrc/decode/OooAluDecodeBackend.v",
        "npc/rv64/vsrc/execute/OooExecuteBackend.v",
        "npc/rv64/vsrc/core/OooCoreTopGlue.v",
        "npc/rv64/vsrc/memory/OooMemInflightQueue.v",
        "npc/rv64/vsrc/memory/OooMemAxiBridge.v",
        "npc/rv64/vsrc/sim/NpcSimTop.sv",
        "npc/rv64/testbench/tests/tb_ooo_priv_system.sv",
        "npc/rv64/testbench/tests/tb_ooo_pending_drain_resolve_gate.sv",
        "npc/rv64/testbench/common/tb_common.svh",
        "npc/rv64/Makefile",
        "npc/rv64/testbench/Makefile",
        "npc/rv64/testbench/scripts/check_tb_result.py",
        f".github/task-runs/{RUN_ID}/completion-definition.md",
        f".github/task-runs/{RUN_ID}/contract.md",
        f".github/task-runs/{RUN_ID}/rtl-derivation.md",
        f".github/task-runs/{RUN_ID}/run-focused.sh",
        f".github/task-runs/{RUN_ID}/run-fence-rtl-variants.py",
        "npc/rv64/eval/ppa/tools/fence_ordering_evidence.py",
        "npc/rv64/eval/ppa/tools/arch_stable_freeze.py",
        "npc/rv64/eval/ppa/tools/architecture_hard_gates.py",
        "npc/rv64/eval/ppa/tests/test_fence_ordering_evidence.py",
    )
    source_bindings = {
        rel: sha256_file(safe_file(root, root / rel)) for rel in source_paths
    }
    return {
        "schema": SCHEMA,
        "suite_run_id": RUN_ID,
        "status": "PASS",
        "design_id": design_id,
        "canonical_command": CANONICAL_COMMAND,
        "scope": (
            "local RV64 Verilog/SystemVerilog ordinary-FENCE pending-system "
            "retirement and complete memory-owner drain ordering"),
        "metrics": metrics,
        "invariants": {
            "ordinary_fence_requires_full_memory_idle": True,
            "older_store_probe_and_drain_exact_once": True,
            "ordinary_fence_retirement_exact_once": True,
            "younger_device_read_after_store_drain": True,
            "younger_device_read_after_fence_retirement": True,
            "non_fence_pending_system_contract_preserved": True,
        },
        "focused_tests": {
            name: {"status": "PASS", "log_sha256": digest}
            for name, digest in sorted(focused.items())
        },
        "module_aggregate": module_aggregate,
        "variant_audit": variants,
        "provenance": {
            "rtl_sha256": rtl_sha,
            "runtime_log_design_id": design_id,
            "files": rtl_files,
            "source_bindings": source_bindings,
        },
        "artifacts": [
            artifact(root, program_log, "program_log"),
            artifact(root, drain_gate_log, "drain_gate_log"),
            artifact(root, module_summary, "module_aggregate_summary"),
            artifact(root, variant_summary, "rtl_variant_summary"),
        ],
        "claim": {
            "architecture_debt": "CLOSED_ELIGIBLE",
            "ppa": "UNQUALIFIED",
            "promotion_eligible": False,
        },
    }


def raw_summary(result: dict[str, Any]) -> str:
    metrics = result["metrics"]
    variants = result["variant_audit"]
    return "\n".join((
        f"schema={result['schema']}",
        f"design_id={result['design_id']}",
        f"runtime_log_design_id={result['provenance']['runtime_log_design_id']}",
        f"canonical_command={result['canonical_command']}",
        f"program_exit={metrics['exit']}",
        f"lane1_fence_capture={metrics['lane1_capture']}",
        f"full_memory_wait_observed={metrics['full_memory_wait']}",
        f"mem_idle_binding_observed={metrics['mem_idle_binding']}",
        f"fence_commit_exact={metrics['fence_commit']}",
        f"store_probe_exact={metrics['store_probe']}",
        f"store_drain_exact={metrics['store_drain']}",
        f"device_read_exact={metrics['device_read']}",
        f"early_fence_before_store={metrics['fence_before_store']}",
        f"early_device_before_store={metrics['device_before_store']}",
        f"early_device_before_fence={metrics['device_before_fence']}",
        f"compile_success_rtl_variants={variants['compile_success']}",
        f"dynamic_rejected_rtl_variants={variants['dynamic_rejected']}",
        "focused_tests=2/2",
        f"module_aggregate={result['module_aggregate']['passed']}/"
        f"{result['module_aggregate']['required']}",
        "ppa=UNQUALIFIED",
        "promotion_eligible=false",
        "[FENCE-G1-GATE] PASS",
        "",
    ))


def main(argv: Sequence[str] | None = None) -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", type=pathlib.Path, required=True)
    parser.add_argument("--print-design-id", action="store_true")
    parser.add_argument("--program-log", type=pathlib.Path)
    parser.add_argument("--drain-gate-log", type=pathlib.Path)
    parser.add_argument("--module-summary", type=pathlib.Path)
    parser.add_argument("--variant-summary", type=pathlib.Path)
    parser.add_argument("--output", type=pathlib.Path)
    parser.add_argument("--raw-log", type=pathlib.Path)
    args = parser.parse_args(argv)

    root = args.root.resolve(strict=True)
    if args.print_design_id:
        rtl_sha, _ = arch.rtl_binding(root)
        print(f"sha256:{rtl_sha}")
        return 0
    required_args = {
        "program-log": args.program_log,
        "drain-gate-log": args.drain_gate_log,
        "module-summary": args.module_summary,
        "variant-summary": args.variant_summary,
        "output": args.output,
        "raw-log": args.raw_log,
    }
    missing = [name for name, value in required_args.items() if value is None]
    if missing:
        parser.error(f"missing required evidence arguments: {', '.join(missing)}")
    assert args.output is not None and args.raw_log is not None
    assert args.program_log is not None and args.drain_gate_log is not None
    assert args.module_summary is not None and args.variant_summary is not None
    output = args.output.resolve()
    raw_log = args.raw_log.resolve()
    for path in (output, raw_log):
        if not path.is_relative_to(root):
            raise ValueError(f"output escapes repository: {path}")
        path.parent.mkdir(parents=True, exist_ok=True)
    result = build(
        root=root,
        program_log=safe_file(root, args.program_log),
        drain_gate_log=safe_file(root, args.drain_gate_log),
        module_summary=safe_file(root, args.module_summary),
        variant_summary=safe_file(root, args.variant_summary),
    )
    output.write_text(
        json.dumps(result, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )
    raw_log.write_text(raw_summary(result), encoding="utf-8")
    variant_count = result["variant_audit"]["dynamic_rejected"]
    print(
        f"[FENCE-G1-EVIDENCE] design_id={result['design_id']} "
        f"program=PASS focused=2/2 variants={variant_count}/{variant_count} "
        "status=PASS"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
