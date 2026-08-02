#!/usr/bin/env python3
"""Build and verify compact current-design CONTROL-EVENT/V9R evidence.

The compiled ``.vvp`` images are deliberately transient.  The retained
evidence is limited to normalized simulator logs, source-changing RTL
variants, status receipts, exact source snapshots and this result payload.
"""

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


SCHEMA = "npc-rv64-control-event-sq-retry-current-evidence-v2"
SNAPSHOT_SCHEMA = "npc-rv64-full-rtl-source-snapshot-v1"
RUN_ID = "2026-08-01-rv64-v11x-control-event-v9r-compact-rebind"
EVIDENCE_ROOT = f".github/task-runs/{RUN_ID}/evidence"
RESULT_PATH = "npc/rv64/eval/ppa/evidence/control-event-sq-retry-current.json"
DISPATCH_FILE = "npc/rv64/eval/ppa/control-event-evidence.mk"
CANONICAL_TARGET = "check-control-event-sq-retry"
CANONICAL_RUNNER = f".github/task-runs/{RUN_ID}/run-focused.sh"
CANONICAL_DISPATCH_BLOCK = (
    ".PHONY: check-control-event-sq-retry\n"
    "check-control-event-sq-retry:\n"
    "\t@bash ../../.github/task-runs/"
    f"{RUN_ID}/run-focused.sh\n"
)
CANONICAL_COMMAND = (
    "/usr/bin/env -u MAKEFLAGS -u MFLAGS -u MAKELEVEL -u GNUMAKEFLAGS "
    "-u MAKEFILES /usr/bin/make -rR --no-print-directory -C npc/rv64 "
    "-f eval/ppa/control-event-evidence.mk check-control-event-sq-retry"
)
TEMP_MARKER = "<CONTROL_EVENT_V11X_TEMP>"

BASELINE_TESTS = {
    "tb_ooo_int_backend_v9r_sq_retry_c0": (
        "[V9R-SQ-RETRY-C0-HANDOFF-PASS] "
        "banks=2 forced=2 natural_trap=1 PASS",
        "[V9R-SQ-RETRY-NATURAL-TRAP] rob_head=1 bank1=1 PASS",
    ),
    "tb_ooo_mem_axi_bridge_v9r_sq_retry_c0": (
        "[V9R-MEM-SQ-RETRY-C0-HANDOFF-PASS] "
        "state=S_SQ_QUERY held=1 release=1 PASS",
    ),
    "tb_ooo_int_backend_v11l_memory_retry_holder": (
        "[V11L-C0-HOLDER-PAUSE][PASS] cycles=2",
        "[V11L-RETRY-HOLDER-MATRIX][PASS] "
        "capture=2 hold=2 c0=2 transfer=2 response=2 cancel=2",
    ),
}

BACKEND_BANK0 = """  assign mem_sq_query_retry_ready_o = ENABLE_DUAL_MEM &&
      mem_sq_query_exact_w && !mem_retry0_valid_q &&
      !mem_sq_query_station_source_w &&
      !flush_i && !checkpoint_restore_hold_w &&
      !control_full_flush_barrier_w;
"""
BACKEND_BANK0_OPEN = """  assign mem_sq_query_retry_ready_o = ENABLE_DUAL_MEM &&
      mem_sq_query_exact_w && !mem_retry0_valid_q &&
      !mem_sq_query_station_source_w &&
      !flush_i && !checkpoint_restore_hold_w;
"""
BACKEND_BANK1 = """  assign mem1_sq_query_retry_ready_o = ENABLE_DUAL_MEM &&
      mem1_sq_query_exact_w && !mem_retry1_valid_q &&
      !mem1_sq_query_station_source_w &&
      !flush_i && !checkpoint_restore_hold_w &&
      !control_full_flush_barrier_w;
"""
BACKEND_BANK1_OPEN = """  assign mem1_sq_query_retry_ready_o = ENABLE_DUAL_MEM &&
      mem1_sq_query_exact_w && !mem_retry1_valid_q &&
      !mem1_sq_query_station_source_w &&
      !flush_i && !checkpoint_restore_hold_w;
"""
BRIDGE_FIRE = """  wire sq_query_retry_fire_w = mem0_sq_query_valid_o &&
      sq_query_decision_onehot_w && mem0_sq_query_replay_i &&
      mem0_sq_query_retry_ready_i && !control_full_flush_barrier_i;
"""
BRIDGE_FIRE_OPEN = """  wire sq_query_retry_fire_w = mem0_sq_query_valid_o &&
      sq_query_decision_onehot_w && mem0_sq_query_replay_i &&
      mem0_sq_query_retry_ready_i;
"""
BACKEND_RETRY0_REQUEST = """  wire mem_retry0_req_valid_w = mem_retry0_selected_w &&
      miq_slot_open_w && !flush_i && !checkpoint_restore_hold_w &&
      !branch_resolve_mispredict_w && !issue_block_w &&
      !mem_issue_block_w;
"""
BACKEND_RETRY0_REQUEST_OPEN = """  wire mem_retry0_req_valid_w = mem_retry0_selected_w &&
      miq_slot_open_w && !flush_i && !checkpoint_restore_hold_w &&
      !branch_resolve_mispredict_w;
"""
BACKEND_RETRY1_REQUEST = """  wire mem_retry1_req_valid_w = mem_retry1_selected_w &&
      miq1_slot_open_w && !flush_i && !checkpoint_restore_hold_w &&
      !branch_resolve_mispredict_w && !issue_block_w &&
      !mem_issue_block_w;
"""
BACKEND_RETRY1_REQUEST_OPEN = """  wire mem_retry1_req_valid_w = mem_retry1_selected_w &&
      miq1_slot_open_w && !flush_i && !checkpoint_restore_hold_w &&
      !branch_resolve_mispredict_w;
"""

VARIANTS = {
    "backend-bank0-ready-open": {
        "production_source": "npc/rv64/vsrc/execute/OooIntBackend.v",
        "test_name": "tb_ooo_int_backend_v9r_sq_retry_c0",
        "mutated_name": "OooIntBackend.v",
        "old": BACKEND_BANK0,
        "new": BACKEND_BANK0_OPEN,
        "assertion_marker": (
            "[V9R-SQ-RETRY-C0-HANDOFF] retry holder transfer exposed "
            "during full-flush barrier"
        ),
    },
    "backend-bank1-ready-open": {
        "production_source": "npc/rv64/vsrc/execute/OooIntBackend.v",
        "test_name": "tb_ooo_int_backend_v9r_sq_retry_c0",
        "mutated_name": "OooIntBackend.v",
        "old": BACKEND_BANK1,
        "new": BACKEND_BANK1_OPEN,
        "assertion_marker": (
            "[V9R-SQ-RETRY-C0-HANDOFF] retry holder transfer exposed "
            "during full-flush barrier"
        ),
    },
    "bridge-retry-fire-open": {
        "production_source": "npc/rv64/vsrc/memory/OooMemAxiBridge.v",
        "test_name": "tb_ooo_mem_axi_bridge_v9r_sq_retry_c0",
        "mutated_name": "OooMemAxiBridge.v",
        "old": BRIDGE_FIRE,
        "new": BRIDGE_FIRE_OPEN,
        "assertion_marker": (
            "[V9R-MEM-SQ-RETRY-C0-HANDOFF] bridge released SQ-query "
            "owner during full-flush barrier"
        ),
    },
    "backend-bank0-resident-fire-open": {
        "production_source": "npc/rv64/vsrc/execute/OooIntBackend.v",
        "test_name": "tb_ooo_int_backend_v11l_memory_retry_holder",
        "mutated_name": "OooIntBackend.v",
        "old": BACKEND_RETRY0_REQUEST,
        "new": BACKEND_RETRY0_REQUEST_OPEN,
        "assertion_marker": (
            "[V11L-RETRY-HOLDER-ORACLE][FAIL] "
            "stage=c0-filled-holder-pause"
        ),
    },
    "backend-bank1-resident-fire-open": {
        "production_source": "npc/rv64/vsrc/execute/OooIntBackend.v",
        "test_name": "tb_ooo_int_backend_v11l_memory_retry_holder",
        "mutated_name": "OooIntBackend.v",
        "old": BACKEND_RETRY1_REQUEST,
        "new": BACKEND_RETRY1_REQUEST_OPEN,
        "assertion_marker": (
            "[V11L-RETRY-HOLDER-ORACLE][FAIL] "
            "stage=c0-filled-holder-pause"
        ),
    },
}

BASE_SOURCE_PATHS = {
    "npc/rv64/testbench/Makefile",
    "npc/rv64/testbench/scripts/check_tb_result.py",
    "npc/rv64/testbench/common/tb_common.svh",
    "npc/rv64/testbench/common/rv32_encode.svh",
    "npc/rv64/vsrc/include/define.v",
    "npc/rv64/design/specs/ooo-mem-axi-bridge-fsm.md",
    "npc/rv64/design/specs/ooo-memory-producer-lease.md",
    "npc/rv64/design/specs/ooo-dual-memory-datapath.md",
    "npc/rv64/eval/ppa/tools/architecture_hard_gates.py",
    "npc/rv64/eval/ppa/tools/control_event_sq_retry_evidence.py",
    DISPATCH_FILE,
    CANONICAL_RUNNER,
    f".github/task-runs/{RUN_ID}/contract.md",
}


def find_repo_root(start: pathlib.Path) -> pathlib.Path:
    for candidate in (start.resolve(), *start.resolve().parents):
        if (candidate / ".github").is_dir() and (candidate / "npc/rv64").is_dir():
            return candidate
    raise ValueError("cannot locate repository root")


def sha256_bytes(value: bytes) -> str:
    return hashlib.sha256(value).hexdigest()


def sha256_file(path: pathlib.Path) -> str:
    return sha256_bytes(path.read_bytes())


def canonical_sha256(value: Any) -> str:
    return sha256_bytes(
        json.dumps(value, sort_keys=True, separators=(",", ":")).encode("utf-8")
    )


def safe_file(root: pathlib.Path, value: str | pathlib.Path) -> pathlib.Path:
    path = pathlib.Path(value)
    if not path.is_absolute():
        path = root / path
    try:
        resolved = path.resolve(strict=True)
        resolved.relative_to(root.resolve())
    except (OSError, ValueError) as exc:
        raise ValueError(f"path is missing or escapes workspace: {value}") from exc
    if resolved.is_symlink() or not resolved.is_file():
        raise ValueError(f"path is not a regular evidence file: {value}")
    return resolved


def relative_path(root: pathlib.Path, path: pathlib.Path) -> str:
    return path.resolve(strict=True).relative_to(root.resolve()).as_posix()


def artifact(root: pathlib.Path, relative: str) -> dict[str, object]:
    path = safe_file(root, relative)
    return {
        "path": relative,
        "sha256": sha256_file(path),
        "size_bytes": path.stat().st_size,
    }


def validate_artifact(
    root: pathlib.Path,
    record: Any,
    expected_path: str,
    label: str,
) -> tuple[pathlib.Path | None, str | None]:
    if not isinstance(record, dict) or set(record) != {
        "path", "sha256", "size_bytes",
    }:
        return None, f"malformed artifact record: {label}"
    if record.get("path") != expected_path:
        return None, f"artifact path drifted: {label}"
    try:
        path = safe_file(root, expected_path)
    except ValueError as exc:
        return None, str(exc)
    if (
        record.get("sha256") != sha256_file(path)
        or record.get("size_bytes") != path.stat().st_size
    ):
        return None, f"artifact hash/size drifted: {label}"
    return path, None


def load_module(path: pathlib.Path, name: str) -> Any:
    spec = importlib.util.spec_from_file_location(name, path)
    if spec is None or spec.loader is None:
        raise ValueError(f"cannot load module: {path}")
    module = importlib.util.module_from_spec(spec)
    sys.modules[name] = module
    spec.loader.exec_module(module)
    return module


def current_snapshot(root: pathlib.Path) -> dict[str, Any]:
    module = load_module(
        safe_file(root, "npc/rv64/eval/ppa/tools/architecture_hard_gates.py"),
        "control_event_architecture_hard_gates",
    )
    digest, files = module.rtl_binding(root)
    return {
        "schema": SNAPSHOT_SCHEMA,
        "design_id": f"sha256:{digest}",
        "file_count": len(files),
        "files": files,
    }


def write_json(path: pathlib.Path, value: Any) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(
        json.dumps(value, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )


def normalize_log(input_path: pathlib.Path, output_path: pathlib.Path,
                  temp_root: pathlib.Path) -> None:
    text = input_path.read_text(encoding="utf-8")
    temp_text = str(temp_root.resolve())
    if temp_text not in text:
        raise ValueError("transient build root is absent from raw compile log")
    normalized = text.replace(temp_text, TEMP_MARKER)
    if re.search(r"/tmp/rv64-control-event-v11x\.[A-Za-z0-9]+", normalized):
        raise ValueError("unnormalized CONTROL-EVENT transient path remains")
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(normalized, encoding="utf-8")


def mutated_bytes(root: pathlib.Path, case_id: str) -> tuple[bytes, dict[str, Any]]:
    spec = VARIANTS[case_id]
    source = safe_file(root, spec["production_source"])
    original = source.read_text(encoding="utf-8")
    old = spec["old"]
    new = spec["new"]
    if original.count(old) != 1 or old == new:
        raise ValueError(f"{case_id}: exact non-noop mutation anchor drifted")
    mutated = original.replace(old, new, 1)
    if mutated == original or old in mutated or mutated.count(new) != 1:
        raise ValueError(f"{case_id}: mutation postcondition failed")
    encoded = mutated.encode("utf-8")
    return encoded, {
        "anchor_count": 1,
        "old_anchor_sha256": sha256_bytes(old.encode("utf-8")),
        "replacement_sha256": sha256_bytes(new.encode("utf-8")),
        "production_sha256": sha256_file(source),
        "variant_sha256": sha256_bytes(encoded),
    }


def write_mutation(root: pathlib.Path, case_id: str, output: pathlib.Path) -> None:
    encoded, _ = mutated_bytes(root, case_id)
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_bytes(encoded)


def mutation_patch_bytes(root: pathlib.Path, case_id: str) -> bytes:
    spec = VARIANTS[case_id]
    source = safe_file(root, spec["production_source"])
    original = source.read_text(encoding="utf-8")
    mutated, _ = mutated_bytes(root, case_id)
    patch = "".join(difflib.unified_diff(
        original.splitlines(keepends=True),
        mutated.decode("utf-8").splitlines(keepends=True),
        fromfile=spec["production_source"],
        tofile=f"{spec['production_source']}::{case_id}",
    )).encode("utf-8")
    if not patch:
        raise ValueError(f"{case_id}: reconstructed patch is empty")
    return patch


def materialize_patches(root: pathlib.Path) -> None:
    output = root / EVIDENCE_ROOT / "patches"
    output.mkdir(parents=True, exist_ok=True)
    for case_id in VARIANTS:
        (output / f"{case_id}.patch").write_bytes(
            mutation_patch_bytes(root, case_id)
        )


def compile_sources(root: pathlib.Path, log_path: pathlib.Path) -> set[str]:
    text = log_path.read_text(encoding="utf-8")
    lines = [line.removeprefix("[COMPILE] ") for line in text.splitlines()
             if line.startswith("[COMPILE] ")]
    if len(lines) != 1:
        raise ValueError(f"expected one compile command: {log_path}")
    tokens = shlex.split(lines[0])
    if not tokens or pathlib.Path(tokens[0]).name != "iverilog":
        raise ValueError(f"compile command is not iverilog: {log_path}")
    if "-o" not in tokens:
        raise ValueError(f"compile command lacks output: {log_path}")
    output = tokens[tokens.index("-o") + 1]
    if not output.startswith(f"{TEMP_MARKER}/") or not output.endswith(".vvp"):
        raise ValueError(f"compiled image is not transient: {log_path}")
    result: set[str] = set()
    testbench_root = root / "npc/rv64/testbench"
    for token in tokens:
        if not token.endswith((".v", ".sv")):
            continue
        if token.startswith(f"{TEMP_MARKER}/"):
            result.add(token)
            continue
        path = pathlib.Path(token)
        if not path.is_absolute():
            path = testbench_root / path
        result.add(relative_path(root, safe_file(root, path)))
    if not result:
        raise ValueError(f"compile source set is empty: {log_path}")
    return result


def source_binding_paths(root: pathlib.Path) -> set[str]:
    paths = set(BASE_SOURCE_PATHS)
    for test_name in BASELINE_TESTS:
        paths.update(compile_sources(
            root,
            safe_file(root, f"{EVIDENCE_ROOT}/baseline/logs/{test_name}.log"),
        ))
    for relative in paths:
        safe_file(root, relative)
    return paths


def source_binding(root: pathlib.Path) -> dict[str, Any]:
    records = {
        relative: artifact(root, relative)
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
        raise ValueError("canonical CONTROL-EVENT Make dispatch drifted")


def validate_dispatch(root: pathlib.Path) -> None:
    text = safe_file(root, DISPATCH_FILE).read_text(encoding="utf-8")
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
        raise ValueError("effective CONTROL-EVENT Make recipe drifted")


def build_payload(root: pathlib.Path) -> dict[str, Any]:
    before_rel = f"{EVIDENCE_ROOT}/source-before.json"
    after_rel = f"{EVIDENCE_ROOT}/source-after.json"
    before = json.loads(safe_file(root, before_rel).read_text(encoding="utf-8"))
    after = json.loads(safe_file(root, after_rel).read_text(encoding="utf-8"))
    if before != after or before != current_snapshot(root):
        raise ValueError("full RTL source snapshot changed during focused replay")
    design_id = before["design_id"]

    tests: dict[str, Any] = {}
    for test_name in BASELINE_TESTS:
        relative = f"{EVIDENCE_ROOT}/baseline/logs/{test_name}.log"
        tests[test_name] = {"log": artifact(root, relative)}

    variants: list[dict[str, Any]] = []
    for case_id, spec in VARIANTS.items():
        prefix = f"{EVIDENCE_ROOT}/{case_id}"
        status_rel = f"{prefix}/status"
        status_text = safe_file(root, status_rel).read_text(encoding="utf-8")
        match = re.fullmatch(
            r"REJECTED_COMPILE_SUCCESS_VARIANT rc=([0-9]+) "
            r"variant_sha256=([0-9a-f]{64}) "
            r"TRANSIENT_COMPILED_IMAGE=1\n",
            status_text,
        )
        if match is None:
            raise ValueError(f"{case_id}: malformed status receipt")
        _, receipt = mutated_bytes(root, case_id)
        if match.group(2) != receipt["variant_sha256"]:
            raise ValueError(f"{case_id}: runtime mutation hash drifted")
        variants.append({
            "id": case_id,
            "production_source": spec["production_source"],
            "test_name": spec["test_name"],
            "result": "REJECTED",
            "make_returncode": int(match.group(1)),
            "assertion_marker": spec["assertion_marker"],
            "mutation_receipt": receipt,
            "compiled_source": (
                f"{TEMP_MARKER}/mutations/{case_id}/"
                f"{spec['mutated_name']}"
            ),
            "mutation_patch": artifact(
                root, f"{EVIDENCE_ROOT}/patches/{case_id}.patch"
            ),
            "log": artifact(root, f"{prefix}/logs/{spec['test_name']}.log"),
            "status": artifact(root, status_rel),
        })

    return {
        "schema": SCHEMA,
        "result": "PASS",
        "design_id": design_id,
        "canonical_command": CANONICAL_COMMAND,
        "source_unchanged": True,
        "source_before": artifact(root, before_rel),
        "source_after": artifact(root, after_rel),
        "source_binding": source_binding(root),
        "positive": {
            "backend_banks": 2,
            "forced_barrier_cases": 2,
            "natural_trap_head_cases": 1,
            "bridge_query_hold_cases": 1,
            "barrier_release_cases": 1,
            "resident_holder_banks": 2,
            "resident_holder_barrier_cycles": 2,
        },
        "baseline": {
            "required": 3,
            "passed": 3,
            "tests": tests,
            "status": artifact(root, f"{EVIDENCE_ROOT}/baseline/status"),
        },
        "compile_success_rtl_variants": variants,
        "retention": {
            "build_root": "TRANSIENT_TMP",
            "compiled_images_retained": 0,
            "normalized_logs_retained": 8,
            "negative_rtl_patches_retained": 5,
        },
        "promotion_eligible": False,
        "ppa_status": "diagnostic_unqualified",
    }


def validate_payload(
    root: pathlib.Path,
    payload: dict[str, Any],
    bound_design_id: str,
) -> list[str]:
    errors: list[str] = []
    expected_keys = {
        "schema", "result", "design_id", "canonical_command",
        "source_unchanged", "source_before", "source_after",
        "source_binding", "positive", "baseline",
        "compile_success_rtl_variants", "retention",
        "promotion_eligible", "ppa_status",
    }
    if set(payload) != expected_keys:
        errors.append("summary field set drifted")
    if not (
        payload.get("schema") == SCHEMA
        and payload.get("result") == "PASS"
        and payload.get("design_id") == bound_design_id
        and payload.get("canonical_command") == CANONICAL_COMMAND
        and payload.get("source_unchanged") is True
        and payload.get("promotion_eligible") is False
        and payload.get("ppa_status") == "diagnostic_unqualified"
    ):
        errors.append("identity/status boundary drifted")

    try:
        validate_dispatch(root)
    except (OSError, ValueError, subprocess.SubprocessError) as exc:
        errors.append(str(exc))

    snapshots: list[dict[str, Any]] = []
    for label in ("source_before", "source_after"):
        relative = f"{EVIDENCE_ROOT}/source-{label.removeprefix('source_')}.json"
        path, error = validate_artifact(root, payload.get(label), relative, label)
        if error:
            errors.append(error)
        elif path is not None:
            try:
                snapshots.append(json.loads(path.read_text(encoding="utf-8")))
            except (OSError, json.JSONDecodeError) as exc:
                errors.append(f"cannot load {label}: {exc}")
    try:
        current = current_snapshot(root)
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

    declared_binding = payload.get("source_binding")
    try:
        expected_binding = source_binding(root)
    except (OSError, ValueError) as exc:
        errors.append(f"cannot reconstruct source binding: {exc}")
        expected_binding = None
    if declared_binding != expected_binding:
        errors.append("selected source/TB/workflow binding drifted")

    if payload.get("positive") != {
        "backend_banks": 2,
        "forced_barrier_cases": 2,
        "natural_trap_head_cases": 1,
        "bridge_query_hold_cases": 1,
        "barrier_release_cases": 1,
        "resident_holder_banks": 2,
        "resident_holder_barrier_cycles": 2,
    }:
        errors.append("positive coverage drifted")

    baseline = payload.get("baseline")
    tests = baseline.get("tests") if isinstance(baseline, dict) else None
    if not (
        isinstance(baseline, dict)
        and set(baseline) == {"required", "passed", "tests", "status"}
        and baseline.get("required") == 3
        and baseline.get("passed") == 3
        and isinstance(tests, dict)
        and set(tests) == set(BASELINE_TESTS)
    ):
        errors.append("baseline inventory drifted")
    else:
        status_path, error = validate_artifact(
            root,
            baseline.get("status"),
            f"{EVIDENCE_ROOT}/baseline/status",
            "baseline-status",
        )
        if error:
            errors.append(error)
        elif status_path is not None and status_path.read_text(
            encoding="utf-8"
        ) != "PASS TRANSIENT_COMPILED_IMAGES=3\n":
            errors.append("baseline status receipt drifted")
        for test_name, markers in BASELINE_TESTS.items():
            record = tests.get(test_name)
            relative = f"{EVIDENCE_ROOT}/baseline/logs/{test_name}.log"
            log_path, error = validate_artifact(
                root,
                record.get("log") if isinstance(record, dict) else None,
                relative,
                f"baseline-log:{test_name}",
            )
            if error:
                errors.append(error)
                continue
            assert log_path is not None
            text = log_path.read_text(encoding="utf-8")
            required = ("[COMPILE] ", "[RESULT] PASS", *markers)
            if (
                any(text.count(marker) != 1 for marker in required)
                or text.count(f"[RTL-DESIGN-ID] {bound_design_id}") != 1
                or any(marker in text for marker in (
                    "[RESULT] FAIL", "[CHECK-FAIL]", "[TIMEOUT]", "FATAL:",
                ))
            ):
                errors.append(f"baseline markers drifted: {test_name}")
            try:
                compile_sources(root, log_path)
            except ValueError as exc:
                errors.append(str(exc))

    variants = payload.get("compile_success_rtl_variants")
    by_id = {
        item.get("id"): item for item in variants
        if isinstance(item, dict) and isinstance(item.get("id"), str)
    } if isinstance(variants, list) else {}
    if not (
        isinstance(variants, list)
        and len(variants) == len(VARIANTS)
        and set(by_id) == set(VARIANTS)
    ):
        errors.append("compile-success RTL variant inventory drifted")
    else:
        expected_variant_keys = {
            "id", "production_source", "test_name", "result",
            "make_returncode", "assertion_marker", "mutation_receipt",
            "compiled_source", "mutation_patch", "log", "status",
        }
        for case_id, spec in VARIANTS.items():
            item = by_id[case_id]
            prefix = f"{EVIDENCE_ROOT}/{case_id}"
            try:
                expected_bytes, expected_receipt = mutated_bytes(root, case_id)
            except (OSError, ValueError) as exc:
                errors.append(str(exc))
                continue
            if not (
                set(item) == expected_variant_keys
                and item.get("production_source") == spec["production_source"]
                and item.get("test_name") == spec["test_name"]
                and item.get("result") == "REJECTED"
                and item.get("make_returncode") == 2
                and item.get("assertion_marker") == spec["assertion_marker"]
                and item.get("mutation_receipt") == expected_receipt
                and item.get("compiled_source") == (
                    f"{TEMP_MARKER}/mutations/{case_id}/"
                    f"{spec['mutated_name']}"
                )
            ):
                errors.append(f"variant contract drifted: {case_id}")
            patch_rel = f"{EVIDENCE_ROOT}/patches/{case_id}.patch"
            patch_path, error = validate_artifact(
                root, item.get("mutation_patch"), patch_rel,
                f"variant-patch:{case_id}",
            )
            if error:
                errors.append(error)
            elif (
                patch_path is not None
                and patch_path.read_bytes() != mutation_patch_bytes(root, case_id)
            ):
                errors.append(
                    f"variant patch is not reconstructed non-noop RTL: {case_id}"
                )
            log_rel = f"{prefix}/logs/{spec['test_name']}.log"
            log_path, error = validate_artifact(
                root, item.get("log"), log_rel, f"variant-log:{case_id}",
            )
            if error:
                errors.append(error)
            elif log_path is not None:
                text = log_path.read_text(encoding="utf-8")
                if (
                    text.count("[COMPILE] ") != 1
                    or text.count(spec["assertion_marker"]) != 1
                    or text.count("[RESULT] FAIL") != 1
                    or "[RESULT] PASS" in text
                ):
                    errors.append(f"variant rejection markers drifted: {case_id}")
                try:
                    sources = compile_sources(root, log_path)
                    if (
                        item.get("compiled_source") not in sources
                        or spec["production_source"] in sources
                    ):
                        errors.append(f"variant compile source selection drifted: {case_id}")
                except ValueError as exc:
                    errors.append(str(exc))
            status_path, error = validate_artifact(
                root, item.get("status"), f"{prefix}/status",
                f"variant-status:{case_id}",
            )
            if error:
                errors.append(error)
            elif status_path is not None and status_path.read_text(
                encoding="utf-8"
            ) != (
                "REJECTED_COMPILE_SUCCESS_VARIANT rc=2 "
                f"variant_sha256={expected_receipt['variant_sha256']} "
                "TRANSIENT_COMPILED_IMAGE=1\n"
            ):
                errors.append(f"variant status receipt drifted: {case_id}")

    if payload.get("retention") != {
        "build_root": "TRANSIENT_TMP",
        "compiled_images_retained": 0,
        "normalized_logs_retained": 8,
        "negative_rtl_patches_retained": 5,
    }:
        errors.append("retention boundary drifted")
    evidence_dir = root / EVIDENCE_ROOT
    if evidence_dir.exists() and any(evidence_dir.rglob("*.vvp")):
        errors.append("task-run retains transient compiled images")
    for case_id, spec in VARIANTS.items():
        if (evidence_dir / case_id / spec["mutated_name"]).exists():
            errors.append(f"task-run retains full mutated RTL: {case_id}")
    return errors


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", type=pathlib.Path)
    sub = parser.add_subparsers(dest="command", required=True)

    snapshot_parser = sub.add_parser("snapshot")
    snapshot_parser.add_argument("--output", required=True, type=pathlib.Path)

    normalize_parser = sub.add_parser("normalize-log")
    normalize_parser.add_argument("--input", required=True, type=pathlib.Path)
    normalize_parser.add_argument("--output", required=True, type=pathlib.Path)
    normalize_parser.add_argument("--temp-root", required=True, type=pathlib.Path)

    mutate_parser = sub.add_parser("mutate")
    mutate_parser.add_argument("--case", required=True, choices=sorted(VARIANTS))
    mutate_parser.add_argument("--output", required=True, type=pathlib.Path)

    sub.add_parser("materialize-patches")

    build_parser = sub.add_parser("build")
    build_parser.add_argument("--output", type=pathlib.Path)

    verify_parser = sub.add_parser("verify")
    verify_parser.add_argument("--input", type=pathlib.Path)

    args = parser.parse_args()
    root = (args.root or find_repo_root(pathlib.Path(__file__))).resolve()
    if args.command == "snapshot":
        write_json(args.output, current_snapshot(root))
        return 0
    if args.command == "normalize-log":
        normalize_log(args.input, args.output, args.temp_root)
        return 0
    if args.command == "mutate":
        write_mutation(root, args.case, args.output)
        return 0
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
            "[CONTROL-EVENT-V9R-EVIDENCE] "
            f"design_id={payload['design_id']} baseline=3/3 "
            "variants=5/5-rejected retained_vvp=0 PASS"
        )
        return 0
    input_path = args.input or (root / RESULT_PATH)
    payload = json.loads(input_path.read_text(encoding="utf-8"))
    errors = validate_payload(root, payload, payload.get("design_id", ""))
    if errors:
        print(*errors, sep="\n", file=sys.stderr)
        return 1
    print(
        "[CONTROL-EVENT-V9R-VERIFY] "
        f"design_id={payload['design_id']} baseline=3/3 "
        "variants=5/5-rejected retained_vvp=0 PASS"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
