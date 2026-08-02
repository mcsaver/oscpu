#!/usr/bin/env python3
"""Build the compact current-design F0-G1 receipt after functional compaction."""

from __future__ import annotations

import argparse
import hashlib
import importlib.util
import json
import pathlib
import re
import sys
from typing import Any


HERE = pathlib.Path(__file__).resolve().parent
ROOT = HERE.parents[2]
DESIGN_ID = "sha256:093c2380b997029944aa4462015d83711d7c5f1d52b15b4803c4515a581a7488"
WARNING_AUDIT = HERE / "f0-warning-audit.py"
MODULE_TOOL = ROOT / "npc/rv64/eval/ppa/tools/full_core_current_evidence.py"
ZERO_MISMATCH_LINE = "difftest_mismatches=0"
FUNCTIONAL_DIAGNOSTIC_PATTERNS = (
    re.compile(r"^\s*(?:%Error(?:-[A-Za-z0-9_-]+)?|%Warning(?:-[A-Za-z0-9_-]+)?|FATAL:|\[CHECK-FAIL\])"),
    re.compile(r"(?:^|:\d+:\s)(?:warning|error|fatal):", re.IGNORECASE),
    re.compile(r"^\s*difftest(?:\s+|[-_]).*mismatch", re.IGNORECASE),
)
HOST_PATH_WARNING = re.compile(
    r"^<REPO>/npc/rv64/csrc/monitor/disasm\.c:40:43: warning: "
    r"‘/nemu/tools/capstone/repo/li\.\.\.’ directive output may be truncated "
    r"writing 42 bytes into a region of size between 1 and 4096 "
    r"\[-Wformat-truncation=\]$"
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


def artifact(path: pathlib.Path) -> dict[str, object]:
    resolved = path.resolve(strict=True)
    resolved.relative_to(ROOT)
    return {
        "path": resolved.relative_to(ROOT).as_posix(),
        "sha256": digest(resolved),
        "size_bytes": resolved.stat().st_size,
    }


def verify_artifact(record: Any, scope: pathlib.Path) -> pathlib.Path:
    if not isinstance(record, dict) or not {"path", "sha256"} <= set(record):
        raise ValueError("artifact record is incomplete")
    path = (ROOT / str(record["path"])).resolve(strict=True)
    path.relative_to(scope)
    if digest(path) != record["sha256"]:
        raise ValueError(f"artifact hash drift: {path}")
    return path


def load_module_tool() -> Any:
    spec = importlib.util.spec_from_file_location("v14e_f0_module_tool", MODULE_TOOL)
    if spec is None or spec.loader is None:
        raise ValueError("cannot load current module evidence tool")
    module = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    return module


def warning_audit(logs: list[pathlib.Path]) -> dict[str, Any]:
    spec = importlib.util.spec_from_file_location("v14e_f0_warning_audit", WARNING_AUDIT)
    if spec is None or spec.loader is None:
        raise ValueError("cannot load current warning audit")
    module = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    result = module.audit(logs)
    result["checker"] = artifact(WARNING_AUDIT)
    return result


def classify_functional_line(line: str) -> str:
    """Classify an EDA/runtime line without matching command-line spellings."""
    if line.strip() == ZERO_MISMATCH_LINE:
        return "ZERO_MISMATCH"
    if HOST_PATH_WARNING.fullmatch(line):
        return "KNOWN_HOST_PATH_FORMAT_TRUNCATION"
    if any(pattern.search(line) for pattern in FUNCTIONAL_DIAGNOSTIC_PATTERNS):
        return "DIAGNOSTIC"
    return "NONE"


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--evidence", required=True, type=pathlib.Path)
    parser.add_argument("--module-dir", required=True, type=pathlib.Path)
    parser.add_argument("--functional-dir", required=True, type=pathlib.Path)
    parser.add_argument("--rtl-summary", required=True, type=pathlib.Path)
    parser.add_argument("--source-before", required=True, type=pathlib.Path)
    parser.add_argument("--source-after", required=True, type=pathlib.Path)
    parser.add_argument(
        "--evidence-mode",
        choices=("CURRENT_EXECUTION", "CHECKER_REPLAY"),
        default="CURRENT_EXECUTION",
    )
    parser.add_argument("--replay-source-status", type=pathlib.Path)
    parser.add_argument("--output", required=True, type=pathlib.Path)
    args = parser.parse_args()
    evidence = args.evidence.resolve(strict=True)
    evidence.relative_to(HERE / "evidence")
    output = args.output.resolve()
    output.relative_to(evidence)
    if output.exists():
        raise ValueError("refusing to replace F0 receipt")

    before_path = args.source_before.resolve(strict=True)
    after_path = args.source_after.resolve(strict=True)
    before_path.relative_to(HERE / "evidence")
    after_path.relative_to(HERE / "evidence")
    before = load(before_path)
    after = load(after_path)
    if before != after or before.get("design_id") != DESIGN_ID or before.get("file_count") != 146:
        raise ValueError("F0 source identity drift")

    module_dir = args.module_dir.resolve(strict=True)
    module_dir.relative_to(HERE / "evidence")
    module_result_path = module_dir / "result.json"
    module_result = load(module_result_path)
    tests = module_result.get("tests")
    if (
        module_result.get("schema") != "npc-rv64-full-core-module-current-evidence-v1"
        or module_result.get("status") != "PASS"
        or module_result.get("design_id") != DESIGN_ID
        or not isinstance(tests, dict)
        or tests.get("required") != tests.get("passed")
        or int(tests.get("required", 0)) < 113
        or len(tests.get("inventory", ())) != tests.get("required")
        or set(tests.get("logs", {})) != set(tests.get("inventory", ()))
        or module_result.get("inputs", {}).get("unchanged") is not True
    ):
        raise ValueError("F0 module aggregate contract drift")
    module_pre = verify_artifact(module_result["inputs"]["pre"], module_dir)
    module_post = verify_artifact(module_result["inputs"]["post"], module_dir)
    if load(module_pre) != load(module_post):
        raise ValueError("F0 module input binding changed")
    module_tool = load_module_tool()
    module_logs: list[pathlib.Path] = []
    for test_id in tests["inventory"]:
        log = verify_artifact(tests["logs"][test_id], module_dir)
        errors = module_tool.validate_module_log(
            log.read_text(encoding="utf-8", errors="replace"),
            test_id=test_id,
            design_id=DESIGN_ID,
        )
        if errors:
            raise ValueError(f"F0 module log drift {test_id}: {errors[:2]}")
        module_logs.append(log)

    functional_dir = args.functional_dir.resolve(strict=True)
    functional_dir.relative_to(HERE / "evidence")
    run_result_path = functional_dir / "run-result.json"
    aggregate_result_path = functional_dir / "functional-aggregate-result.json"
    descriptor_path = functional_dir / "functional-run-descriptor.json"
    post_compaction_path = functional_dir / "post-compaction.json"
    run_result = load(run_result_path)
    aggregate_result = load(aggregate_result_path)
    descriptor = load(descriptor_path)
    post_compaction = load(post_compaction_path)
    counts = run_result.get("counts")
    if (
        run_result.get("schema") != "npc-rv64-full-core-functional-current-evidence-v1"
        or run_result.get("status") != "PASS"
        or run_result.get("design_id") != DESIGN_ID
        or run_result.get("inputs_unchanged") is not True
        or not isinstance(counts, dict)
        or aggregate_result.get("status") != "PASS"
        or aggregate_result.get("exit_code") != 0
        or aggregate_result.get("design_id") != DESIGN_ID
        or aggregate_result.get("counts") != counts
        or counts.get("module_required") != tests.get("required")
        or counts.get("module_passed") != tests.get("passed")
        or counts.get("official_required") != 177
        or counts.get("official_passed") != 177
        or counts.get("am_required") != 61
        or counts.get("am_passed") != 61
        or counts.get("difftest_mismatches") != 0
        or counts.get("evidence_mutations_compiled") != counts.get("evidence_mutations_rejected")
        or int(counts.get("evidence_mutations_compiled", 0)) < 11
        or post_compaction.get("schema") != "rv64-v14e-f0-functional-post-compaction-v1"
        or post_compaction.get("status") != "PASS"
        or post_compaction.get("current_design_id") != DESIGN_ID
        or post_compaction.get("removed_counts") != {
            "program_images": 240,
            "reference": 1,
            "simulator": 1,
        }
        or post_compaction.get("reproducible_binary_products_retained") != 0
        or post_compaction.get("standalone_binary_replay_available") is not False
        or post_compaction.get("rebuild_binding_available") is not True
    ):
        raise ValueError("F0 full-functional or compaction contract drift")
    benchmarks = descriptor.get("benchmarks")
    if (
        not isinstance(benchmarks, dict)
        or benchmarks.get("coremark", {}).get("return_code") != 0
        or benchmarks.get("coremark", {}).get("iterations") != 10
        or benchmarks.get("coremark", {}).get("crc") != "0xfcaf"
        or benchmarks.get("coremark", {}).get("good_traps") != 1
        or benchmarks.get("dhrystone", {}).get("return_code") != 0
        or benchmarks.get("dhrystone", {}).get("runs") != 10000
        or benchmarks.get("dhrystone", {}).get("good_traps") != 1
    ):
        raise ValueError("F0 benchmark marker drift")
    diagnostic_lines: list[dict[str, object]] = []
    known_host_warnings: list[dict[str, object]] = []
    skipped_module_duplicate_logs = 0
    for log in sorted(functional_dir.rglob("*.log")):
        relative_log = log.relative_to(functional_dir)
        if relative_log.parts[:2] == ("wrapped", "module"):
            skipped_module_duplicate_logs += 1
            continue
        for number, line in enumerate(log.read_text(encoding="utf-8", errors="replace").splitlines(), 1):
            classification = classify_functional_line(line)
            if classification == "DIAGNOSTIC":
                raise ValueError(f"unexpected full-functional diagnostic {log}:{number}: {line}")
            if classification == "ZERO_MISMATCH":
                diagnostic_lines.append(
                    {"log": log.relative_to(ROOT).as_posix(), "line": number, "text": line}
                )
            if classification == "KNOWN_HOST_PATH_FORMAT_TRUNCATION":
                known_host_warnings.append(
                    {"log": log.relative_to(ROOT).as_posix(), "line": number, "text": line}
                )
    if (
        len(diagnostic_lines) != 1
        or len(known_host_warnings) != 3
        or skipped_module_duplicate_logs != tests["required"]
    ):
        raise ValueError(
            "full-functional diagnostic classification count drift: "
            f"zero={len(diagnostic_lines)} host={len(known_host_warnings)} "
            f"module_duplicates={skipped_module_duplicate_logs}"
        )
    host_source = ROOT / "npc/rv64/csrc/monitor/disasm.c"

    rtl_path = args.rtl_summary.resolve(strict=True)
    rtl_path.relative_to(HERE / "evidence")
    rtl = load(rtl_path)
    release_log = verify_artifact(
        rtl.get("focused_release", {}).get("log"), HERE / "evidence"
    )
    production = rtl.get("production_rtl")
    if (
        rtl.get("schema") != "rv64-v14e-f0-production-rtl-counterexamples-v1"
        or rtl.get("status") != "PASS"
        or rtl.get("current_design_id") != DESIGN_ID
        or rtl.get("source_unchanged") is not True
        or rtl.get("focused_release", {}).get("passed") is not True
        or rtl.get("focused_release", {}).get("compile_succeeded") is not True
        or not isinstance(production, dict)
        or production.get("required") != 3
        or production.get("compile_success") != 3
        or production.get("dynamic_rejected") != 3
        or production.get("unique_rtl_variant_fingerprints") != 3
        or rtl.get("verification_only_mutations_executed") != 0
        or rtl.get("task_output_compiled_images_retained") != 0
    ):
        raise ValueError("F0 production RTL counterexample receipt drift")

    warnings = warning_audit([*module_logs, release_log])
    forbidden: list[str] = []
    for scope in {evidence, module_dir, functional_dir, rtl_path.parent}:
        for path in scope.rglob("*"):
            if path.is_file() and (
                path.suffix.lower() in {".bin", ".so", ".o", ".a", ".vvp", ".pyc"}
                or path.name == "NpcSimTop"
            ):
                forbidden.append(path.relative_to(ROOT).as_posix())
    if forbidden:
        raise ValueError(f"F0 task evidence retains reproducible products: {forbidden[:3]}")

    replay: dict[str, Any] | None = None
    if args.evidence_mode == "CHECKER_REPLAY":
        if args.replay_source_status is None:
            raise ValueError("checker replay requires the original status path")
        replay_status_path = args.replay_source_status.resolve(strict=True)
        replay_status_path.relative_to(HERE)
        replay_status = replay_status_path.read_text(encoding="utf-8").strip()
        if replay_status != "FAIL rc=1 stage=evidence-complete evidence_complete=0 cleanup_rc=0":
            raise ValueError(f"original F0 replay status drift: {replay_status}")
        replay = {
            "mode": "CHECKER_REPLAY",
            "source_status": artifact(replay_status_path),
            "source_status_text": replay_status,
            "workload_rerun": False,
            "reason": "the old log classifier matched the -Wno-fatal command argument as a fatal diagnostic",
        }
    elif args.replay_source_status is not None:
        raise ValueError("CURRENT_EXECUTION must not bind a replay source status")

    receipt = {
        "schema": "rv64-v14e-f0-current-summary-v1",
        "status": "PASS",
        "evidence_mode": args.evidence_mode,
        "checker_replay": replay,
        "debt_id": "F0-G1",
        "scope_status": "CURRENT_DYNAMIC_PASS",
        "current_design_id": DESIGN_ID,
        "module": {
            "passed": tests["passed"],
            "required": tests["required"],
            "result": artifact(module_result_path),
        },
        "functional": {
            "official_passed": 177,
            "official_required": 177,
            "am_passed": 61,
            "am_required": 61,
            "difftest_mismatches": 0,
            "coremark_iterations": 10,
            "coremark_crc": "0xfcaf",
            "dhrystone_runs": 10000,
            "evidence_oracle_mutations_compiled": counts["evidence_mutations_compiled"],
            "evidence_oracle_mutations_rejected": counts["evidence_mutations_rejected"],
            "run_result": artifact(run_result_path),
            "aggregate_result": artifact(aggregate_result_path),
            "post_compaction": artifact(post_compaction_path),
            "diagnostic_audit": {
                "status": "EXPLAINED",
                "zero_mismatch_markers": diagnostic_lines,
                "known_host_path_format_truncation": {
                    "count": 3,
                    "source": artifact(host_source),
                    "lines": known_host_warnings,
                },
                "module_duplicate_logs_skipped": skipped_module_duplicate_logs,
                "module_duplicate_reason": "the same 113 module executions are validated and warning-audited through the canonical module result",
                "unexplained_diagnostics": 0,
            },
        },
        "focused_release": {"passed": 1, "required": 1},
        "compile_success_rtl_counterexamples": {
            "production_rtl_detected": 3,
            "production_rtl_required": 3,
            "unique_production_rtl_variant_fingerprints": 3,
            "summary": artifact(rtl_path),
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
        "standalone_binary_replay_available": False,
        "rebuild_binding_available": True,
        "architecture_gate_state": "RED",
        "ppa_state": "BLOCKED_BY_ARCHITECTURE",
    }
    output.write_text(json.dumps(receipt, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    print(
        f"[V14E-F0][PASS] module={tests['passed']}/{tests['required']} "
        "official=177/177 am=61/61 difftest=0 coremark_crc=0xfcaf "
        "dhrystone_runs=10000 production_rtl_mutations=3/3 "
        f"warnings={warnings['count']} binary_products_retained=0"
    )
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (OSError, ValueError, json.JSONDecodeError) as exc:
        print(f"[V14E-F0][FAIL] {exc}", file=sys.stderr)
        raise SystemExit(1)
