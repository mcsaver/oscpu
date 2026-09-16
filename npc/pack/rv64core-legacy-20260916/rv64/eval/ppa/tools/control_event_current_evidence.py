#!/usr/bin/env python3
"""Build and verify compact current-design V9O CONTROL-EVENT evidence."""

from __future__ import annotations

import argparse
import difflib
import hashlib
import importlib.util
import json
import os
import pathlib
import re
import shlex
import subprocess
import sys
from typing import Any


SCHEMA = "npc-rv64-control-event-current-evidence-v1"
RUN_ID = "2026-08-01-rv64-v11x-control-event-v9r-compact-rebind"
EVIDENCE_ROOT = f".github/task-runs/{RUN_ID}/evidence"
RESULT_PATH = "npc/rv64/eval/ppa/evidence/control-event-current.json"
DISPATCH_FILE = "npc/rv64/eval/ppa/control-event-evidence.mk"
CANONICAL_TARGET = "check-control-event-current"
CANONICAL_RUNNER = f".github/task-runs/{RUN_ID}/run-control-event-current.sh"
CANONICAL_DISPATCH_BLOCK = (
    ".PHONY: check-control-event-current\n"
    "check-control-event-current:\n"
    "\t@bash ../../.github/task-runs/"
    f"{RUN_ID}/run-control-event-current.sh\n"
)
CANONICAL_COMMAND = (
    "/usr/bin/env -u MAKEFLAGS -u MFLAGS -u MAKELEVEL -u GNUMAKEFLAGS "
    "-u MAKEFILES /usr/bin/make -rR --no-print-directory -C npc/rv64 "
    "-f eval/ppa/control-event-evidence.mk check-control-event-current"
)
TEMP_MARKER = "<CONTROL_EVENT_V11X_TEMP>"
LEGACY_RUN_ID = "2026-07-23-rv64-v9o-control-event-current-design"
LEGACY_ROOT = f".github/task-runs/{LEGACY_RUN_ID}"
MUTATION_ROOT = f"{EVIDENCE_ROOT}/v9o-mutations"

TOP_LEVEL_MUTATION_KEYS = {
    "schema", "suite_run_id", "required", "compile_success",
    "dynamic_rejected", "lint_rejected", "rejected",
    "baseline_unoptflat", "baseline_lint", "design_id", "rtl_source_set",
    "full_rtl_source_unchanged", "verification_source_set",
    "verification_source_unchanged", "source_unchanged",
    "source_sha256_before", "source_sha256_after", "results",
}
MUTATION_RESULT_KEYS = {
    "compile_success", "dynamic_rejected", "expected_markers",
    "extra_ivflags", "lint_rejected", "lint_returncode", "log",
    "make_returncode", "make_variable", "mutation_sha256", "name",
    "observed_markers", "oracle_family", "original_sha256", "purpose",
    "rejected", "rejection_mode", "source", "test_name",
}
FAIL_MARKERS = ("[RESULT] FAIL", "[CHECK-FAIL]", "[TIMEOUT]", "FATAL:")

BASE_SOURCE_PATHS = {
    "npc/rv64/testbench/Makefile",
    "npc/rv64/testbench/scripts/check_tb_result.py",
    "npc/rv64/testbench/common/tb_common.svh",
    "npc/rv64/testbench/common/rv32_encode.svh",
    "npc/rv64/vsrc/include/define.v",
    "npc/rv64/design/specs/ooo-control-event-apply-sequencer.md",
    "npc/rv64/design/specs/ooo-core-top-glue.md",
    "npc/rv64/design/specs/ooo-flush-redirect-contract.md",
    "npc/rv64/design/specs/ooo-frontend-action-gate.md",
    "npc/rv64/design/specs/ooo-load-queue.md",
    "npc/rv64/design/specs/ooo-mem-axi-bridge-fsm.md",
    "npc/rv64/design/specs/ooo-redirect-arbiter.md",
    "npc/rv64/design/specs/ooo-rob.md",
    "npc/rv64/eval/ppa/tools/architecture_hard_gates.py",
    "npc/rv64/eval/ppa/tools/control_event_current_evidence.py",
    "npc/rv64/eval/ppa/tools/control_event_sq_retry_evidence.py",
    "npc/rv64/eval/ppa/tests/test_control_event_current_evidence.py",
    DISPATCH_FILE,
    CANONICAL_RUNNER,
    f".github/task-runs/{RUN_ID}/contract.md",
    f"{LEGACY_ROOT}/build-evidence-index.py",
    f"{LEGACY_ROOT}/evidence_source_set.py",
    f"{LEGACY_ROOT}/run-control-event-rtl-mutations.py",
}


def load_module(path: pathlib.Path, name: str) -> Any:
    spec = importlib.util.spec_from_file_location(name, path)
    if spec is None or spec.loader is None:
        raise ValueError(f"cannot load module: {path}")
    module = importlib.util.module_from_spec(spec)
    sys.modules[name] = module
    spec.loader.exec_module(module)
    return module


def helper(root: pathlib.Path) -> Any:
    return load_module(
        root / "npc/rv64/eval/ppa/tools/control_event_sq_retry_evidence.py",
        "control_event_sq_retry_helper",
    )


def legacy_builder(root: pathlib.Path) -> Any:
    return load_module(
        root / LEGACY_ROOT / "build-evidence-index.py",
        "control_event_v9o_legacy_builder",
    )


def mutation_runner(root: pathlib.Path) -> Any:
    return load_module(
        root / LEGACY_ROOT / "run-control-event-rtl-mutations.py",
        "control_event_v9o_mutation_runner",
    )


def sha256_bytes(value: bytes) -> str:
    return hashlib.sha256(value).hexdigest()


def canonical_sha256(value: Any) -> str:
    return sha256_bytes(
        json.dumps(value, sort_keys=True, separators=(",", ":")).encode("utf-8")
    )


def write_json(path: pathlib.Path, value: Any) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(
        json.dumps(value, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )


def focused_markers(root: pathlib.Path) -> dict[str, tuple[str, ...]]:
    return dict(legacy_builder(root).FOCUSED_MARKERS)


def config_markers(root: pathlib.Path) -> dict[str, tuple[str, ...]]:
    return dict(legacy_builder(root).CONFIG_MARKERS)


def normalized_compile_sources(
    root: pathlib.Path,
    log_path: pathlib.Path,
    mutation_source: str | None = None,
) -> set[str]:
    h = helper(root)
    text = log_path.read_text(encoding="utf-8")
    lines = [line.removeprefix("[COMPILE] ") for line in text.splitlines()
             if line.startswith("[COMPILE] ")]
    if len(lines) != 1:
        raise ValueError(f"expected one compile command: {log_path}")
    tokens = shlex.split(lines[0])
    if not tokens or pathlib.Path(tokens[0]).name != "iverilog" or "-o" not in tokens:
        raise ValueError(f"malformed iverilog command: {log_path}")
    output = tokens[tokens.index("-o") + 1]
    if not output.startswith((f"{TEMP_MARKER}/", "<LOCAL-TEMP>/")):
        raise ValueError(f"compiled image is not transient: {log_path}")
    paths: set[str] = set()
    testbench_root = root / "npc/rv64/testbench"
    for token in tokens:
        if not token.endswith((".v", ".sv")):
            continue
        if token.startswith("<LOCAL-TEMP>/"):
            if mutation_source is None:
                raise ValueError(f"unexpected transient RTL input: {log_path}")
            paths.add(mutation_source)
            continue
        path = pathlib.Path(token)
        if not path.is_absolute():
            path = testbench_root / path
        paths.add(h.relative_path(root, h.safe_file(root, path)))
    if not paths:
        raise ValueError(f"compile source set is empty: {log_path}")
    return paths


def source_binding_paths(root: pathlib.Path) -> set[str]:
    h = helper(root)
    paths = set(BASE_SOURCE_PATHS)
    for test_name in focused_markers(root):
        log = h.safe_file(
            root, f"{EVIDENCE_ROOT}/v9o-focused/logs/{test_name}.log"
        )
        paths.update(normalized_compile_sources(root, log))
    for test_name in config_markers(root):
        log = h.safe_file(
            root, f"{EVIDENCE_ROOT}/v9o-config/logs/{test_name}.log"
        )
        paths.update(normalized_compile_sources(root, log))
    summary = json.loads(
        h.safe_file(root, f"{MUTATION_ROOT}/summary.json").read_text(
            encoding="utf-8"
        )
    )
    for row in summary.get("results", []):
        if not isinstance(row, dict):
            continue
        log_record = row.get("log")
        if not isinstance(log_record, dict) or not isinstance(log_record.get("path"), str):
            raise ValueError("mutation log record is malformed")
        log = h.safe_file(root, log_record["path"])
        paths.update(normalized_compile_sources(root, log, row.get("source")))
    for relative in paths:
        h.safe_file(root, relative)
    return paths


def source_binding(root: pathlib.Path) -> dict[str, Any]:
    h = helper(root)
    records = {
        relative: h.artifact(root, relative)
        for relative in sorted(source_binding_paths(root))
    }
    return {
        "sha256": canonical_sha256(records),
        "file_count": len(records),
        "files": records,
    }


def validate_dispatch_text(text: str) -> None:
    safe_target = r"[A-Za-z0-9_.-]+"
    safe_recipe = re.compile(r"^\t@?[A-Za-z0-9_./ -]+$")
    for number, line in enumerate(text.splitlines(), start=1):
        if not line or line.startswith("#"):
            continue
        if safe_recipe.fullmatch(line):
            continue
        if re.fullmatch(rf"\.PHONY:(?: {safe_target})+", line):
            continue
        if re.fullmatch(rf"{safe_target}:", line):
            continue
        raise ValueError(
            f"restricted CONTROL-EVENT Make dispatch syntax at line {number}"
        )
    if text.count(CANONICAL_DISPATCH_BLOCK) != 1:
        raise ValueError("canonical V9O CONTROL-EVENT Make dispatch drifted")


def validate_dispatch(root: pathlib.Path) -> None:
    h = helper(root)
    text = h.safe_file(root, DISPATCH_FILE).read_text(encoding="utf-8")
    validate_dispatch_text(text)
    env = os.environ.copy()
    for name in ("MAKEFLAGS", "MFLAGS", "MAKELEVEL", "GNUMAKEFLAGS", "MAKEFILES"):
        env.pop(name, None)
    env["LC_ALL"] = "C"
    completed = subprocess.run(
        [
            "/usr/bin/make", "-rR", "--no-print-directory", "-n",
            "-C", str(root / "npc/rv64"),
            "-f", "eval/ppa/control-event-evidence.mk",
            "SHELL=/bin/false", CANONICAL_TARGET,
        ],
        check=False,
        capture_output=True,
        text=True,
        timeout=5,
        env=env,
    )
    if (
        completed.returncode != 0
        or completed.stdout.splitlines() != [f"bash ../../{CANONICAL_RUNNER}"]
        or completed.stderr.strip()
    ):
        raise ValueError("effective V9O CONTROL-EVENT Make recipe drifted")


def mutation_patch(root: pathlib.Path, spec: Any) -> tuple[bytes, str, str]:
    runner = mutation_runner(root)
    original, mutated = runner.reconstruct_mutation(root, spec)
    original_sha = sha256_bytes(original.encode("utf-8"))
    mutation_sha = sha256_bytes(mutated.encode("utf-8"))
    if original_sha == mutation_sha:
        raise ValueError(f"{spec.name}: reconstructed mutation is a no-op")
    patch = "".join(difflib.unified_diff(
        original.splitlines(keepends=True),
        mutated.splitlines(keepends=True),
        fromfile=spec.source_rel,
        tofile=f"{spec.source_rel}::{spec.name}",
    )).encode("utf-8")
    if not patch:
        raise ValueError(f"{spec.name}: reconstructed patch is empty")
    return patch, original_sha, mutation_sha


def materialize_patches(root: pathlib.Path) -> None:
    runner = mutation_runner(root)
    output = root / MUTATION_ROOT / "patches"
    output.mkdir(parents=True, exist_ok=True)
    for spec in runner.MUTATIONS:
        patch, _, _ = mutation_patch(root, spec)
        (output / f"{spec.name}.patch").write_bytes(patch)


def validate_pass_log(
    root: pathlib.Path,
    relative: str,
    test_name: str,
    design_id: str,
    markers: tuple[str, ...],
) -> tuple[dict[str, Any], list[str]]:
    h = helper(root)
    errors: list[str] = []
    path = h.safe_file(root, relative)
    text = path.read_text(encoding="utf-8")
    native = [
        line for line in text.splitlines()
        if line in {f"[PASS] {test_name}", f"PASS {test_name}"}
    ]
    required = ("[COMPILE] ", "[RESULT] PASS", *markers)
    if (
        any(text.count(marker) != 1 for marker in required)
        or len(native) != 1
        or text.count(f"[RTL-DESIGN-ID] {design_id}") != 1
        or any(marker in text for marker in FAIL_MARKERS)
    ):
        errors.append(f"PASS markers drifted: {test_name}")
    try:
        normalized_compile_sources(root, path)
    except ValueError as exc:
        errors.append(str(exc))
    return h.artifact(root, relative), errors


def validate_mutations(
    root: pathlib.Path,
    summary: dict[str, Any],
    design_id: str,
    current_snapshot: dict[str, Any],
) -> list[str]:
    h = helper(root)
    runner = mutation_runner(root)
    errors: list[str] = []
    if set(summary) != TOP_LEVEL_MUTATION_KEYS:
        errors.append("mutation summary field set drifted")
    if not (
        summary.get("schema") == runner.SCHEMA
        and summary.get("suite_run_id") == runner.SUITE_RUN_ID
        and summary.get("design_id") == design_id
        and summary.get("required") == len(runner.MUTATIONS) == 11
        and summary.get("compile_success") == 11
        and summary.get("rejected") == 11
        and summary.get("dynamic_rejected") == 10
        and summary.get("lint_rejected") == 1
        and summary.get("baseline_unoptflat") is False
        and summary.get("source_unchanged") is True
        and summary.get("full_rtl_source_unchanged") is True
        and summary.get("verification_source_unchanged") is True
    ):
        errors.append("mutation summary identity/count boundary drifted")
    expected_rtl = {
        "design_id": design_id,
        "file_count": current_snapshot["file_count"],
        "files": current_snapshot["files"],
        "sha256": design_id.removeprefix("sha256:"),
    }
    if summary.get("rtl_source_set") != expected_rtl:
        errors.append("mutation full RTL source binding drifted")
    source_map = summary.get("source_sha256_before")
    if (
        not isinstance(source_map, dict)
        or summary.get("source_sha256_after") != source_map
    ):
        errors.append("mutation production source pre/post binding drifted")

    baseline = summary.get("baseline_lint")
    baseline_path = f"{MUTATION_ROOT}/baseline-verilator.log"
    if not (
        isinstance(baseline, dict)
        and set(baseline) == {"returncode", "path", "sha256"}
        and baseline.get("returncode") == 0
        and baseline.get("path") == baseline_path
    ):
        errors.append("mutation baseline lint receipt drifted")
    else:
        try:
            path = h.safe_file(root, baseline_path)
            if (
                baseline.get("sha256") != h.sha256_file(path)
                or "%Warning-UNOPTFLAT" in path.read_text(encoding="utf-8")
            ):
                errors.append("mutation baseline lint is stale or cyclic")
        except ValueError as exc:
            errors.append(str(exc))

    results = summary.get("results")
    by_name = {
        row.get("name"): row for row in results
        if isinstance(row, dict) and isinstance(row.get("name"), str)
    } if isinstance(results, list) else {}
    specs = {spec.name: spec for spec in runner.MUTATIONS}
    if not (
        isinstance(results, list)
        and len(results) == len(specs)
        and set(by_name) == set(specs)
    ):
        errors.append("mutation result inventory drifted")
        return errors
    for name, spec in specs.items():
        row = by_name[name]
        try:
            patch, original_sha, mutation_sha = mutation_patch(root, spec)
        except ValueError as exc:
            errors.append(str(exc))
            continue
        expected_dynamic = spec.rejection_mode == "dynamic"
        expected_make_rc = 2 if expected_dynamic else 0
        expected_lint_rc = None if expected_dynamic else 0
        if not (
            set(row) == MUTATION_RESULT_KEYS
            and row.get("source") == spec.source_rel
            and row.get("make_variable") == spec.make_variable
            and row.get("test_name") == spec.test_name
            and row.get("oracle_family") == spec.oracle_family
            and row.get("purpose") == spec.purpose
            and row.get("rejection_mode") == spec.rejection_mode
            and row.get("extra_ivflags") == list(spec.extra_ivflags)
            and row.get("expected_markers") == list(spec.expected_markers)
            and row.get("observed_markers") == {
                marker: True for marker in spec.expected_markers
            }
            and row.get("original_sha256") == original_sha
            and row.get("mutation_sha256") == mutation_sha
            and row.get("compile_success") is True
            and row.get("rejected") is True
            and row.get("dynamic_rejected") is expected_dynamic
            and row.get("lint_rejected") is (not expected_dynamic)
            and row.get("make_returncode") == expected_make_rc
            and row.get("lint_returncode") == expected_lint_rc
        ):
            errors.append(f"mutation contract drifted: {name}")
        if isinstance(source_map, dict) and source_map.get(spec.source_rel) != original_sha:
            errors.append(f"mutation source map drifted: {name}")
        patch_rel = f"{MUTATION_ROOT}/patches/{name}.patch"
        try:
            patch_path = h.safe_file(root, patch_rel)
            if patch_path.read_bytes() != patch:
                errors.append(f"mutation patch drifted: {name}")
        except ValueError as exc:
            errors.append(str(exc))
        log_record = row.get("log")
        log_rel = f"{MUTATION_ROOT}/logs/{name}.log"
        if not (
            isinstance(log_record, dict)
            and set(log_record) == {"path", "sha256"}
            and log_record.get("path") == log_rel
        ):
            errors.append(f"mutation log record drifted: {name}")
            continue
        try:
            log_path = h.safe_file(root, log_rel)
            text = log_path.read_text(encoding="utf-8")
            if log_record.get("sha256") != h.sha256_file(log_path):
                errors.append(f"mutation log hash drifted: {name}")
            if any(text.count(marker) != 1 for marker in spec.expected_markers):
                errors.append(f"mutation oracle markers drifted: {name}")
            if expected_dynamic and (
                text.count("[RESULT] FAIL") != 1 or "[RESULT] PASS" in text
            ):
                errors.append(f"dynamic mutation escaped: {name}")
            if not expected_dynamic and (
                text.count("[RESULT] PASS") != 1
                or "%Warning-UNOPTFLAT" not in text
            ):
                errors.append(f"lint mutation was not rejected: {name}")
            normalized_compile_sources(root, log_path, spec.source_rel)
        except ValueError as exc:
            errors.append(str(exc))
    return errors


def build_payload(root: pathlib.Path) -> dict[str, Any]:
    h = helper(root)
    before_rel = f"{EVIDENCE_ROOT}/v9o-source-before.json"
    after_rel = f"{EVIDENCE_ROOT}/v9o-source-after.json"
    before = json.loads(h.safe_file(root, before_rel).read_text(encoding="utf-8"))
    after = json.loads(h.safe_file(root, after_rel).read_text(encoding="utf-8"))
    current = h.current_snapshot(root)
    if before != after or before != current:
        raise ValueError("full RTL changed during V9O current replay")
    design_id = current["design_id"]
    builder = legacy_builder(root)

    focused_logs: dict[str, Any] = {}
    for test_name, markers in builder.FOCUSED_MARKERS.items():
        relative = f"{EVIDENCE_ROOT}/v9o-focused/logs/{test_name}.log"
        record, errors = validate_pass_log(
            root, relative, test_name, design_id, tuple(markers)
        )
        if errors:
            raise ValueError("; ".join(errors))
        focused_logs[test_name] = record
    config_logs: dict[str, Any] = {}
    for test_name, markers in builder.CONFIG_MARKERS.items():
        relative = f"{EVIDENCE_ROOT}/v9o-config/logs/{test_name}.log"
        record, errors = validate_pass_log(
            root, relative, test_name, design_id, tuple(markers)
        )
        if errors:
            raise ValueError("; ".join(errors))
        config_logs[test_name] = record

    mutation_rel = f"{MUTATION_ROOT}/summary.json"
    mutation_summary = json.loads(
        h.safe_file(root, mutation_rel).read_text(encoding="utf-8")
    )
    mutation_errors = validate_mutations(root, mutation_summary, design_id, current)
    if mutation_errors:
        raise ValueError("; ".join(mutation_errors[:4]))
    mutation_logs = {
        row["name"]: h.artifact(root, row["log"]["path"])
        for row in mutation_summary["results"]
    }
    mutation_patches = {
        row["name"]: h.artifact(
            root, f"{MUTATION_ROOT}/patches/{row['name']}.patch"
        )
        for row in mutation_summary["results"]
    }
    static_contract = builder.validate_static_contract(root)
    return {
        "schema": SCHEMA,
        "result": "PASS",
        "design_id": design_id,
        "canonical_command": CANONICAL_COMMAND,
        "source_unchanged": True,
        "source_before": h.artifact(root, before_rel),
        "source_after": h.artifact(root, after_rel),
        "source_binding": source_binding(root),
        "static_contract": static_contract,
        "focused": {
            "required": 10,
            "passed": 10,
            "logs": focused_logs,
        },
        "config_variants": {
            "configuration": "OOO_CSR_QUEUE_HEAD=1",
            "required": 3,
            "passed": 3,
            "logs": config_logs,
        },
        "rtl_mutations": {
            "required": 11,
            "compile_success": 11,
            "rejected": 11,
            "dynamic_rejected": 10,
            "lint_rejected": 1,
            "summary": h.artifact(root, mutation_rel),
            "baseline_lint": h.artifact(
                root, f"{MUTATION_ROOT}/baseline-verilator.log"
            ),
            "logs": mutation_logs,
            "patches": mutation_patches,
        },
        "retention": {
            "compiled_images_retained": 0,
            "normalized_logs_retained": 24,
            "negative_rtl_patches_retained": 11,
            "duplicated_module_aggregate": False,
            "duplicated_architecture_gate": False,
        },
        "claim_boundary": {
            "architecture_freeze": "GAP",
            "ppa": "UNQUALIFIED",
            "promotion_eligible": False,
        },
    }


def validate_payload(
    root: pathlib.Path,
    payload: dict[str, Any],
    bound_design_id: str,
) -> list[str]:
    h = helper(root)
    errors: list[str] = []
    expected_keys = {
        "schema", "result", "design_id", "canonical_command",
        "source_unchanged", "source_before", "source_after",
        "source_binding", "static_contract", "focused", "config_variants",
        "rtl_mutations", "retention", "claim_boundary",
    }
    if set(payload) != expected_keys:
        errors.append("current evidence field set drifted")
    if not (
        payload.get("schema") == SCHEMA
        and payload.get("result") == "PASS"
        and payload.get("design_id") == bound_design_id
        and payload.get("canonical_command") == CANONICAL_COMMAND
        and payload.get("source_unchanged") is True
    ):
        errors.append("current evidence identity/status drifted")
    try:
        validate_dispatch(root)
    except (OSError, ValueError, subprocess.SubprocessError) as exc:
        errors.append(str(exc))

    snapshots: list[dict[str, Any]] = []
    for label in ("source_before", "source_after"):
        suffix = label.removeprefix("source_")
        relative = f"{EVIDENCE_ROOT}/v9o-source-{suffix}.json"
        path, error = h.validate_artifact(
            root, payload.get(label), relative, label
        )
        if error:
            errors.append(error)
        elif path is not None:
            snapshots.append(json.loads(path.read_text(encoding="utf-8")))
    try:
        current = h.current_snapshot(root)
    except (OSError, ValueError, AttributeError) as exc:
        errors.append(f"cannot recompute full RTL snapshot: {exc}")
        current = None
    if (
        len(snapshots) != 2
        or snapshots[0] != snapshots[1]
        or current is None
        or snapshots[0] != current
        or current.get("design_id") != bound_design_id
    ):
        errors.append("full RTL pre/post/current binding drifted")

    try:
        expected_binding = source_binding(root)
    except (OSError, ValueError) as exc:
        errors.append(f"cannot reconstruct selected source binding: {exc}")
        expected_binding = None
    if payload.get("source_binding") != expected_binding:
        errors.append("selected source/TB/workflow binding drifted")

    try:
        expected_static = legacy_builder(root).validate_static_contract(root)
    except (OSError, ValueError) as exc:
        errors.append(f"cannot recompute static contract: {exc}")
        expected_static = None
    if payload.get("static_contract") != expected_static:
        errors.append("static control-event contract drifted")

    for kind, markers, prefix, expected_count in (
        ("focused", focused_markers(root), "v9o-focused", 10),
        ("config_variants", config_markers(root), "v9o-config", 3),
    ):
        group = payload.get(kind)
        logs = group.get("logs") if isinstance(group, dict) else None
        allowed_keys = (
            {"required", "passed", "logs"}
            if kind == "focused"
            else {"configuration", "required", "passed", "logs"}
        )
        if not (
            isinstance(group, dict)
            and set(group) == allowed_keys
            and group.get("required") == expected_count
            and group.get("passed") == expected_count
            and isinstance(logs, dict)
            and set(logs) == set(markers)
            and (
                kind == "focused"
                or group.get("configuration") == "OOO_CSR_QUEUE_HEAD=1"
            )
        ):
            errors.append(f"{kind} inventory drifted")
            continue
        for test_name, expected_markers in markers.items():
            relative = f"{EVIDENCE_ROOT}/{prefix}/logs/{test_name}.log"
            _, error = h.validate_artifact(
                root, logs.get(test_name), relative, f"{kind}:{test_name}"
            )
            if error:
                errors.append(error)
                continue
            _, log_errors = validate_pass_log(
                root, relative, test_name, bound_design_id,
                tuple(expected_markers),
            )
            errors.extend(log_errors)

    mutation_index = payload.get("rtl_mutations")
    summary_rel = f"{MUTATION_ROOT}/summary.json"
    if not isinstance(mutation_index, dict):
        errors.append("mutation index is missing")
    else:
        expected_mutation_keys = {
            "required", "compile_success", "rejected", "dynamic_rejected",
            "lint_rejected", "summary", "baseline_lint", "logs", "patches",
        }
        if not (
            set(mutation_index) == expected_mutation_keys
            and mutation_index.get("required") == 11
            and mutation_index.get("compile_success") == 11
            and mutation_index.get("rejected") == 11
            and mutation_index.get("dynamic_rejected") == 10
            and mutation_index.get("lint_rejected") == 1
        ):
            errors.append("mutation index counts drifted")
        summary_path, error = h.validate_artifact(
            root, mutation_index.get("summary"), summary_rel, "mutation-summary"
        )
        if error:
            errors.append(error)
        elif summary_path is not None and current is not None:
            summary = json.loads(summary_path.read_text(encoding="utf-8"))
            errors.extend(validate_mutations(
                root, summary, bound_design_id, current
            ))
            names = {row["name"] for row in summary.get("results", [])}
            logs = mutation_index.get("logs")
            patches = mutation_index.get("patches")
            if not (
                isinstance(logs, dict) and set(logs) == names
                and isinstance(patches, dict) and set(patches) == names
            ):
                errors.append("mutation log/patch inventory drifted")
            else:
                for name in names:
                    _, log_error = h.validate_artifact(
                        root, logs[name], f"{MUTATION_ROOT}/logs/{name}.log",
                        f"mutation-log:{name}",
                    )
                    _, patch_error = h.validate_artifact(
                        root, patches[name],
                        f"{MUTATION_ROOT}/patches/{name}.patch",
                        f"mutation-patch:{name}",
                    )
                    if log_error:
                        errors.append(log_error)
                    if patch_error:
                        errors.append(patch_error)
        _, baseline_error = h.validate_artifact(
            root,
            mutation_index.get("baseline_lint"),
            f"{MUTATION_ROOT}/baseline-verilator.log",
            "mutation-baseline-lint",
        )
        if baseline_error:
            errors.append(baseline_error)

    if payload.get("retention") != {
        "compiled_images_retained": 0,
        "normalized_logs_retained": 24,
        "negative_rtl_patches_retained": 11,
        "duplicated_module_aggregate": False,
        "duplicated_architecture_gate": False,
    }:
        errors.append("compact retention boundary drifted")
    if payload.get("claim_boundary") != {
        "architecture_freeze": "GAP",
        "ppa": "UNQUALIFIED",
        "promotion_eligible": False,
    }:
        errors.append("local claim boundary drifted")
    run_root = root / f".github/task-runs/{RUN_ID}"
    if run_root.exists() and any(run_root.rglob("*.vvp")):
        errors.append("task-run retains transient compiled images")
    return errors


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", type=pathlib.Path)
    sub = parser.add_subparsers(dest="command", required=True)
    sub.add_parser("materialize-patches")
    build_parser = sub.add_parser("build")
    build_parser.add_argument("--output", type=pathlib.Path)
    verify_parser = sub.add_parser("verify")
    verify_parser.add_argument("--input", type=pathlib.Path)
    args = parser.parse_args()
    root = (args.root or pathlib.Path(__file__).resolve().parents[5]).resolve()
    if args.command == "materialize-patches":
        materialize_patches(root)
        return 0
    if args.command == "build":
        output = args.output or (root / RESULT_PATH)
        payload = build_payload(root)
        errors = validate_payload(root, payload, payload["design_id"])
        if errors:
            raise SystemExit("\n".join(errors))
        write_json(output, payload)
        print(
            "[CONTROL-EVENT-CURRENT-EVIDENCE] "
            f"design_id={payload['design_id']} focused=10/10 config=3/3 "
            "variants=11/11-rejected retained_vvp=0 PASS"
        )
        return 0
    input_path = args.input or (root / RESULT_PATH)
    payload = json.loads(input_path.read_text(encoding="utf-8"))
    errors = validate_payload(root, payload, payload.get("design_id", ""))
    if errors:
        print(*errors, sep="\n", file=sys.stderr)
        return 1
    print(
        "[CONTROL-EVENT-CURRENT-VERIFY] "
        f"design_id={payload['design_id']} focused=10/10 config=3/3 "
        "variants=11/11-rejected retained_vvp=0 PASS"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
