#!/usr/bin/env python3
"""Build and verify the current-design RV64 historical-defect receipt.

The receipt composes immutable historical counterexamples with current-design
directed/mutation evidence.  It never rewrites an original execution status
and never launches RTL simulation.
"""

from __future__ import annotations

import argparse
import functools
import hashlib
import importlib.util
import json
import pathlib
import re
import shlex
import shutil
import subprocess
import sys
from typing import Any

import jsonschema


SCHEMA = "npc-rv64-historical-defect-current-v1"
LEDGER_SCHEMA = "npc-rv64-historical-defect-backfill-ledger-v1"
RTL_FILE_COUNT = 146
DESIGN_ID_RE = re.compile(r"^sha256:[0-9a-f]{64}$")
SHA256_RE = re.compile(r"^[0-9a-f]{64}$")
ZERO_RETURN_CODE_SHA256 = hashlib.sha256(b"0\n").hexdigest()
V9P_FROZEN_DESIGN_ID = (
    "sha256:9ac1ae14b18635cf25ea80efa7ce4cd85a07bdd6f0e525755658dc8dcd26207a"
)
V15G_FIX_DESIGN_ID = (
    "sha256:f7a6845564f2d697fca9eac8bf9424136508a62c7fcc7851ad56c688dc2053f9"
)

DEFECT_IDS = (
    "HIST-A3-DMESG-DEBUG-TOKEN",
    "HIST-EXIT-ACTIVE-MEM-EARLY-TERMINAL",
    "HIST-SER-QH-STOP-HOLD-DROP",
    "HIST-SER-QH-YOUNGER-STORE-CYCLE",
    "HIST-V8L-FORCE-RELEASE-SHADOW",
    "HIST-V9P-TERMINAL-COLLECTOR-INGRESS-DUP",
)
DEPTHS = {
    "HIST-SER-QH-YOUNGER-STORE-CYCLE": "VD3",
    "HIST-SER-QH-STOP-HOLD-DROP": "VD3",
    "HIST-EXIT-ACTIVE-MEM-EARLY-TERMINAL": "VD4",
    "HIST-A3-DMESG-DEBUG-TOKEN": "VD4",
    "HIST-V8L-FORCE-RELEASE-SHADOW": "VD3",
    "HIST-V9P-TERMINAL-COLLECTOR-INGRESS-DUP": "VD4",
}
SUPPORT = {
    "HIST-SER-QH-YOUNGER-STORE-CYCLE": [
        "historical_qh_reconstruction",
        "v15g_serialize_qh_current",
    ],
    "HIST-SER-QH-STOP-HOLD-DROP": [
        "historical_stop_hold_matrix",
        "v15g_serialize_system_current",
    ],
    "HIST-EXIT-ACTIVE-MEM-EARLY-TERMINAL": [
        "v15g_exit_current",
        "layered_system_current",
    ],
    "HIST-A3-DMESG-DEBUG-TOKEN": [
        "historical_a3_checker_replay",
        "layered_system_current",
    ],
    "HIST-V8L-FORCE-RELEASE-SHADOW": [
        "historical_v8l_matrix",
        "v15g_v8l_current",
    ],
    "HIST-V9P-TERMINAL-COLLECTOR-INGRESS-DUP": [
        "historical_v9p_root_cause",
        "v9r_current",
        "layered_system_current",
        "v15g_independent_review",
        "v15p_adapter_review_closure",
        "v15q_v9p_current_rebind_review",
    ],
}

RECEIPT_PATH = pathlib.PurePosixPath(
    "npc/rv64/eval/ppa/evidence/historical-defect-current.json"
)
LEDGER_PATH = pathlib.PurePosixPath(
    "npc/rv64/design/arch/historical-defect-backfill-ledger.json"
)
SCHEMA_PATH = pathlib.PurePosixPath(
    "npc/rv64/eval/ppa/schemas/historical-defect-current-v1.schema.json"
)
ARCH_BINDING_TOOL_PATH = pathlib.PurePosixPath(
    "npc/rv64/eval/ppa/tools/architecture_hard_gates.py"
)
CURRENT_TOOL_PATH = pathlib.PurePosixPath(
    "npc/rv64/eval/ppa/tools/historical_defect_current.py"
)
BACKFILL_SCHEMA_PATH = pathlib.PurePosixPath(
    "npc/rv64/eval/ppa/schemas/historical-defect-backfill-ledger-v1.schema.json"
)
HOLDER_CURRENT_TOOL_PATH = pathlib.PurePosixPath(
    "npc/rv64/eval/ppa/tools/global_producer_no_live_reuse.py"
)
EXIT_RUNNER_PATH = pathlib.PurePosixPath(
    "npc/rv64/testbench/scripts/run_historical_exit_current.py"
)
HISTORICAL_QH_PATH = pathlib.PurePosixPath(
    ".github/task-runs/2026-07-29-rv64-hist-ser-qh-younger-store-cycle/"
    "evidence/historical-reconstruction/summary.json"
)
HISTORICAL_STOP_PATH = pathlib.PurePosixPath(
    ".github/task-runs/2026-07-29-rv64-hist-ser-qh-stop-hold-drop/"
    "evidence/stop-hold-matrix/summary.json"
)
V14E_QH_PATH = pathlib.PurePosixPath(
    ".github/task-runs/2026-08-07-rv64-v15q-selector-state-reconciliation-337de8bf/"
    "evidence/historical-current-v1/qh/summary.json"
)
V14E_SYSTEM_PATH = pathlib.PurePosixPath(
    ".github/task-runs/2026-08-07-rv64-v15q-selector-state-reconciliation-337de8bf/"
    "evidence/historical-current-v1/system/summary.json"
)
HISTORICAL_A3_PATH = pathlib.PurePosixPath(
    ".github/task-runs/2026-07-28-rv64-v10f-a3-checker-replay-v2/"
    "checker-replay-v2-evidence.json"
)
HISTORICAL_A3_STATUS_PATH = pathlib.PurePosixPath(
    ".github/task-runs/2026-07-27-rv64-v10e-current-design-system-recert/"
    "rootfs-c1b531-systemd-strict-6b-a3.status"
)
CURRENT_CHECKER_PATH = pathlib.PurePosixPath(
    "Linux/scripts/npc-systemd-strict-check.sh"
)
CURRENT_CHECKER_TEST_PATH = pathlib.PurePosixPath(
    "Linux/scripts/tests/test_npc_systemd_strict_check.py"
)
HISTORICAL_V8L_PATH = pathlib.PurePosixPath(
    ".github/task-runs/2026-07-20-rv64-v8l-global-producer-no-live-reuse/"
    "evidence/focused/mutation-summary.json"
)
HOLDER_CURRENT_PATH = pathlib.PurePosixPath(
    "npc/rv64/eval/ppa/evidence/"
    "global-producer-no-live-reuse-current.json"
)
V8L_TB_PATH = pathlib.PurePosixPath(
    "npc/rv64/testbench/tests/tb_ooo_int_backend.sv"
)
V15G_RUN_PATH = pathlib.PurePosixPath(
    ".github/task-runs/2026-08-05-rv64-v15g-v9p-terminal-root-cause-backfill"
)
HISTORICAL_V9P_ROOT_CAUSE_PATH = (
    V15G_RUN_PATH / "evidence/v9p-root-cause-summary.json"
)
V15Q_RUN_PATH = pathlib.PurePosixPath(
    ".github/task-runs/2026-08-07-rv64-v15q-selector-state-reconciliation-337de8bf"
)
V9R_CURRENT_PATH = V15Q_RUN_PATH / "evidence/v9r-current-v1/summary.json"
V9R_CURRENT_RUNNER_PATH = pathlib.PurePosixPath(
    "npc/rv64/eval/ppa/run-v9r-sq-retry-current.sh"
)
LAYERED_SYSTEM_CURRENT_PATH = pathlib.PurePosixPath(
    "npc/rv64/eval/ppa/evidence/layered-system-signoff-current.json"
)
V15G_INDEPENDENT_REVIEW_PATH = (
    V15G_RUN_PATH / "evidence/independent-review.json"
)
V15G_VERIFIER_PATH = V15G_RUN_PATH / "verify-v9p-root-cause.py"
V15P_ADAPTER_RUN_PATH = pathlib.PurePosixPath(
    ".github/task-runs/2026-08-06-rv64-v15p-adapter-final-b-fallthrough-f7a"
)
V15P_ADAPTER_REVIEW_CLOSURE_PATH = (
    V15P_ADAPTER_RUN_PATH / "evidence/independent-review-closure-v2.txt"
)
V15P_ADAPTER_REVIEW_RESULT_PATH = (
    V15P_ADAPTER_RUN_PATH
    / "subagent-contracts/v15p-loop-adapter-evidence-closure-review-v2.result.md"
)
V15P_ADAPTER_MUTATION_RESULT_PATH = (
    V15P_ADAPTER_RUN_PATH
    / "evidence/l0/v15p-adapter-final-b-mutation/result.txt"
)
V15P_ADAPTER_MUTATION_LOG_PATH = (
    V15P_ADAPTER_RUN_PATH
    / "evidence/l0/v15p-adapter-final-b-mutation/mutation/logs/"
    "tb_ooo_owner_timing_causal_probe.log"
)
V15P_CURRENT_MODULE_RESULT_PATH = pathlib.PurePosixPath(
    ".github/task-runs/2026-08-07-rv64-v15p-control-loop-current-f7a/"
    "evidence/module/result.json"
)
V15P_CURRENT_ADAPTER_LOG_PATH = pathlib.PurePosixPath(
    ".github/task-runs/2026-08-07-rv64-v15p-control-loop-current-f7a/"
    "evidence/module/logs/tb_ooo_lsu_axi_lane_adapter.log"
)
V9P_CURRENT_REBIND_REVIEW_PATH = (
    V15Q_RUN_PATH / "evidence/v9p-current-rebind-review-v1.json"
)
V9P_CURRENT_REBIND_CONTRACT_PATH = (
    V15Q_RUN_PATH / "subagent-contracts/v15q-v9p-current-rebind-review-v1.json"
)
V9P_CURRENT_REBIND_RESULT_PATH = (
    V15Q_RUN_PATH / "subagent-contracts/v15q-v9p-current-rebind-review-v1.result.md"
)
V9P_BACKEND_PATH = pathlib.PurePosixPath(
    "npc/rv64/vsrc/execute/OooIntBackend.v"
)
V9P_BRIDGE_PATH = pathlib.PurePosixPath(
    "npc/rv64/vsrc/memory/OooMemAxiBridge.v"
)
V15P_ADAPTER_PATH = pathlib.PurePosixPath(
    "npc/rv64/vsrc/memory/OooLsuAxiLaneAdapter.v"
)
V15P_ADAPTER_TB_PATH = pathlib.PurePosixPath(
    "npc/rv64/testbench/tests/tb_ooo_lsu_axi_lane_adapter.sv"
)
V15P_OWNER_TIMING_TB_PATH = pathlib.PurePosixPath(
    "npc/rv64/testbench/tests/tb_ooo_owner_timing_causal_probe.sv"
)
EXIT_CURRENT_PATH = pathlib.PurePosixPath(
    ".github/task-runs/2026-08-07-rv64-v15q-selector-state-reconciliation-337de8bf/"
    "evidence/historical-current-v1/exit/summary.json"
)

INPUT_PATHS = {
    "architecture_binding_tool": ARCH_BINDING_TOOL_PATH,
    "backfill_ledger_schema": BACKFILL_SCHEMA_PATH,
    "current_checker": CURRENT_CHECKER_PATH,
    "current_checker_test": CURRENT_CHECKER_TEST_PATH,
    "exit_current_runner": EXIT_RUNNER_PATH,
    "historical_a3_checker_replay": HISTORICAL_A3_PATH,
    "historical_a3_original_status": HISTORICAL_A3_STATUS_PATH,
    "historical_qh_reconstruction": HISTORICAL_QH_PATH,
    "historical_stop_hold_matrix": HISTORICAL_STOP_PATH,
    "historical_v8l_matrix": HISTORICAL_V8L_PATH,
    "historical_v9p_root_cause": HISTORICAL_V9P_ROOT_CAUSE_PATH,
    "layered_system_current": LAYERED_SYSTEM_CURRENT_PATH,
    "receipt_schema": SCHEMA_PATH,
    "receipt_tool": CURRENT_TOOL_PATH,
    "v15g_serialize_qh_current": V14E_QH_PATH,
    "v15g_serialize_system_current": V14E_SYSTEM_PATH,
    "v15g_v8l_current": HOLDER_CURRENT_PATH,
    "v15g_exit_current": EXIT_CURRENT_PATH,
    "v15g_independent_review": V15G_INDEPENDENT_REVIEW_PATH,
    "v15g_root_cause_verifier": V15G_VERIFIER_PATH,
    "v15p_adapter_review_closure": V15P_ADAPTER_REVIEW_CLOSURE_PATH,
    "v15p_adapter_review_result": V15P_ADAPTER_REVIEW_RESULT_PATH,
    "v15p_adapter_mutation_result": V15P_ADAPTER_MUTATION_RESULT_PATH,
    "v15p_adapter_mutation_log": V15P_ADAPTER_MUTATION_LOG_PATH,
    "v15p_current_module_result": V15P_CURRENT_MODULE_RESULT_PATH,
    "v15p_current_adapter_log": V15P_CURRENT_ADAPTER_LOG_PATH,
    "v15q_v9p_current_rebind_review": V9P_CURRENT_REBIND_REVIEW_PATH,
    "v15q_v9p_current_rebind_contract": V9P_CURRENT_REBIND_CONTRACT_PATH,
    "v15q_v9p_current_rebind_result": V9P_CURRENT_REBIND_RESULT_PATH,
    "v9p_current_backend": V9P_BACKEND_PATH,
    "v9p_current_bridge": V9P_BRIDGE_PATH,
    "v15p_current_adapter": V15P_ADAPTER_PATH,
    "v15p_adapter_testbench": V15P_ADAPTER_TB_PATH,
    "v15p_owner_timing_testbench": V15P_OWNER_TIMING_TB_PATH,
    "v8l_testbench": V8L_TB_PATH,
    "v9r_current": V9R_CURRENT_PATH,
    "v9r_current_runner": V9R_CURRENT_RUNNER_PATH,
}

CONFIG_PATHS = {
    "npc_config": pathlib.PurePosixPath("npc/rv64/.config"),
    "npc_auto_conf": pathlib.PurePosixPath("npc/rv64/include/config/auto.conf"),
    "npc_autoconf_header": pathlib.PurePosixPath(
        "npc/rv64/include/generated/autoconf.h"
    ),
}


class HistoricalCurrentError(RuntimeError):
    """The current historical-defect receipt or ledger is invalid."""


def find_repo_root(start: pathlib.Path) -> pathlib.Path:
    for candidate in (start.resolve(), *start.resolve().parents):
        if (candidate / ".github").is_dir() and (candidate / "npc/rv64").is_dir():
            return candidate
    raise HistoricalCurrentError("cannot locate repository root")


@functools.lru_cache(maxsize=2048)
def sha256_file(path: pathlib.Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def safe_file(root: pathlib.Path, relative: str | pathlib.PurePosixPath) -> pathlib.Path:
    root = root.resolve()
    try:
        path = (root / pathlib.PurePosixPath(relative)).resolve(strict=True)
        path.relative_to(root)
    except (OSError, ValueError) as exc:
        raise HistoricalCurrentError(f"invalid repository file: {relative}") from exc
    if path.is_symlink() or not path.is_file():
        raise HistoricalCurrentError(f"not a regular repository file: {relative}")
    return path


def artifact(root: pathlib.Path, relative: str | pathlib.PurePosixPath) -> dict[str, Any]:
    path = safe_file(root, relative)
    return {
        "path": path.relative_to(root.resolve()).as_posix(),
        "sha256": sha256_file(path),
        "size_bytes": path.stat().st_size,
    }


def load_json(root: pathlib.Path, relative: str | pathlib.PurePosixPath) -> dict[str, Any]:
    path = safe_file(root, relative)
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        raise HistoricalCurrentError(f"cannot load JSON {relative}: {exc}") from exc
    if not isinstance(value, dict):
        raise HistoricalCurrentError(f"JSON root must be an object: {relative}")
    return value


def load_module(path: pathlib.Path, name: str) -> Any:
    spec = importlib.util.spec_from_file_location(name, path)
    if spec is None or spec.loader is None:
        raise HistoricalCurrentError(f"cannot import helper: {path}")
    module = importlib.util.module_from_spec(spec)
    sys.modules[name] = module
    spec.loader.exec_module(module)
    return module


def require(condition: bool, message: str) -> None:
    if not condition:
        raise HistoricalCurrentError(message)


def require_equal(actual: Any, expected: Any, label: str) -> None:
    if actual != expected:
        raise HistoricalCurrentError(f"{label}: expected {expected!r}, got {actual!r}")


def nested_hashes(payload: Any, source_path: str) -> list[str]:
    result: list[str] = []
    if isinstance(payload, dict):
        if payload.get("path") == source_path and isinstance(payload.get("sha256"), str):
            result.append(payload["sha256"])
        for child in payload.values():
            result.extend(nested_hashes(child, source_path))
    elif isinstance(payload, list):
        for child in payload:
            result.extend(nested_hashes(child, source_path))
    return result


def require_current_source(root: pathlib.Path, payload: Any, source_path: str, label: str) -> str:
    live = sha256_file(safe_file(root, source_path))
    hashes = nested_hashes(payload, source_path)
    require(live in hashes, f"{label}: no current hash binding for {source_path}")
    return live


def validate_artifact_record(
    root: pathlib.Path,
    record: Any,
    label: str,
    *,
    path_key: str = "path",
    require_size: bool = False,
) -> pathlib.Path:
    require(isinstance(record, dict), f"{label}: artifact record is missing")
    relative = record.get(path_key)
    digest = record.get("sha256")
    require(isinstance(relative, str) and relative, f"{label}: artifact path is missing")
    require(isinstance(digest, str) and SHA256_RE.fullmatch(digest) is not None,
            f"{label}: artifact SHA-256 is malformed")
    path = safe_file(root, relative)
    require_equal(sha256_file(path), digest, f"{label} SHA-256")
    if require_size or "size_bytes" in record:
        require_equal(record.get("size_bytes"), path.stat().st_size, f"{label} size")
    return path


def validate_retained_log(
    root: pathlib.Path,
    record: Any,
    label: str,
    *,
    path_key: str = "path",
) -> str:
    path = validate_artifact_record(
        root,
        record,
        label,
        path_key=path_key,
        require_size="size_bytes" in record if isinstance(record, dict) else False,
    )
    return path.read_text(encoding="utf-8", errors="replace")


def require_log_markers(text: str, markers: Any, label: str) -> None:
    require(isinstance(markers, dict) and markers, f"{label}: marker map is missing")
    for marker, expected in markers.items():
        require(isinstance(marker, str) and isinstance(expected, int),
                f"{label}: malformed marker count")
        require_equal(text.count(marker), expected, f"{label} marker {marker}")


def validate_removed_artifacts(
    root: pathlib.Path,
    payload: dict[str, Any],
    label: str,
) -> dict[str, dict[str, Any]]:
    cleanup = payload.get("cleanup")
    require(isinstance(cleanup, dict), f"{label}: cleanup receipt is missing")
    require_equal(cleanup.get("status"), "PASS", f"{label} cleanup status")
    require_equal(
        cleanup.get("retained_temporary_artifacts"),
        0,
        f"{label} retained temporary artifacts",
    )
    records = cleanup.get("artifacts")
    require(isinstance(records, list) and records, f"{label}: cleanup manifest is empty")
    require_equal(cleanup.get("removed"), len(records), f"{label} cleanup count")
    by_path: dict[str, dict[str, Any]] = {}
    resolved_root = root.resolve()
    for index, record in enumerate(records):
        require(isinstance(record, dict), f"{label} cleanup[{index}] is malformed")
        path_text = record.get("path")
        require(
            isinstance(path_text, str)
            and path_text
            and isinstance(record.get("kind"), str)
            and SHA256_RE.fullmatch(str(record.get("sha256", ""))) is not None
            and isinstance(record.get("size_bytes"), int)
            and record["size_bytes"] > 0,
            f"{label} cleanup[{index}] is malformed",
        )
        relative = pathlib.PurePosixPath(path_text)
        require(not relative.is_absolute() and ".." not in relative.parts,
                f"{label} cleanup path escapes repository: {path_text}")
        candidate = (resolved_root / relative).resolve()
        try:
            candidate.relative_to(resolved_root)
        except ValueError as exc:
            raise HistoricalCurrentError(
                f"{label} cleanup path escapes repository: {path_text}"
            ) from exc
        require(path_text not in by_path, f"{label} duplicate cleanup path: {path_text}")
        require(not candidate.exists(), f"{label} temporary artifact was retained: {path_text}")
        by_path[path_text] = record
    return by_path


def validate_removed_sidefile(
    cleanup: dict[str, dict[str, Any]],
    record: Any,
    *,
    kind: str,
    label: str,
) -> None:
    require(isinstance(record, dict), f"{label}: sidefile receipt is missing")
    path_text = record.get("path")
    require(isinstance(path_text, str) and path_text, f"{label}: sidefile path is missing")
    expected = cleanup.get(path_text)
    require(isinstance(expected, dict), f"{label}: sidefile is absent from cleanup manifest")
    require_equal(expected.get("kind"), kind, f"{label} cleanup kind")
    require_equal(
        {key: expected.get(key) for key in ("path", "sha256", "size_bytes")},
        {key: record.get(key) for key in ("path", "sha256", "size_bytes")},
        f"{label} cleanup binding",
    )


def require_log_header(text: str, fields: dict[str, str], label: str) -> None:
    for key, expected in fields.items():
        matches = re.findall(rf"(?m)^{re.escape(key)}=(.*)$", text)
        require_equal(matches, [expected], f"{label} header {key}")


def validate_v14e_build_controls(
    root: pathlib.Path,
    payload: dict[str, Any],
    expected_paths: set[str],
    label: str,
) -> None:
    controls = payload.get("build_controls")
    require(isinstance(controls, dict), f"{label}: build controls are missing")
    require_equal(set(controls), expected_paths, f"{label} build-control paths")
    for path, record in controls.items():
        require_equal(record.get("path"), path, f"{label} build-control key")
        validate_artifact_record(root, record, f"{label} build control {path}", require_size=True)


def validate_v14e_profile(
    root: pathlib.Path,
    row: dict[str, Any],
    *,
    cleanup_artifacts: dict[str, dict[str, Any]],
    label: str,
    assertions: bool,
    expect_pass: bool,
    make_returncode: int,
    mutation: str | None,
    markers: dict[str, int],
    log_markers: dict[str, int],
) -> None:
    require_equal(row.get("assertions"), assertions, f"{label} assertions")
    require_equal(row.get("expect_pass"), expect_pass, f"{label} expectation")
    require_equal(row.get("make_returncode"), make_returncode, f"{label} make return code")
    require_equal(row.get("mutation"), mutation, f"{label} mutation")
    require_equal(row.get("passed"), True, f"{label} result")
    require_equal(row.get("markers"), markers, f"{label} markers")
    validate_retained_log(root, row.get("make_log"), f"{label} make log")
    result_text = validate_retained_log(root, row.get("result_log"), f"{label} result log")
    require_log_markers(result_text, log_markers, label)
    require_equal(result_text.count("[COMPILE]"), 1, f"{label} compile command marker")
    require_equal(
        result_text.count("[RESULT] PASS"),
        1 if expect_pass else 0,
        f"{label} PASS terminal marker",
    )
    require_equal(
        result_text.count("[RESULT] FAIL"),
        0 if expect_pass else 1,
        f"{label} FAIL terminal marker",
    )

    compile_input = row.get("compile_input")
    require(isinstance(compile_input, dict), f"{label}: compile-input closure is missing")
    require_equal(
        set(compile_input),
        {
            "compile_returncode_file",
            "compiler_argv",
            "compiler_argv_file",
            "dependencies",
            "dependency_file",
            "make_compile_argv",
        },
        f"{label} compile-input fields",
    )
    compile_rc = compile_input.get("compile_returncode_file")
    require(isinstance(compile_rc, dict)
            and isinstance(compile_rc.get("path"), str)
            and SHA256_RE.fullmatch(str(compile_rc.get("sha256", ""))) is not None
            and compile_rc.get("size_bytes") == 2,
            f"{label}: compile-success receipt is malformed")
    require_equal(
        compile_rc.get("sha256"),
        ZERO_RETURN_CODE_SHA256,
        f"{label} compile-success return-code hash",
    )
    validate_removed_sidefile(
        cleanup_artifacts,
        compile_rc,
        kind="compiler-return-code",
        label=f"{label} compile return code",
    )
    validate_removed_sidefile(
        cleanup_artifacts,
        compile_input.get("compiler_argv_file"),
        kind="compiler-argv",
        label=f"{label} compiler argv",
    )
    validate_removed_sidefile(
        cleanup_artifacts,
        compile_input.get("dependency_file"),
        kind="compiler-dependencies",
        label=f"{label} compiler dependencies",
    )
    compiler_argv = compile_input.get("compiler_argv")
    make_compile_argv = compile_input.get("make_compile_argv")
    require(
        isinstance(compiler_argv, list)
        and compiler_argv
        and str(compiler_argv[0]).endswith("/iverilog")
        and "-g2012" in compiler_argv,
        f"{label}: compiler argv is malformed",
    )
    require(
        isinstance(make_compile_argv, list)
        and make_compile_argv
        and "-g2012" in make_compile_argv,
        f"{label}: make compile argv is malformed",
    )
    require_equal("-DOOO_ASSERT" in compiler_argv, assertions,
                  f"{label} compiler assertion mode")
    dependencies = compile_input.get("dependencies")
    require(isinstance(dependencies, list) and dependencies,
            f"{label}: compiler dependency closure is empty")
    for index, dependency in enumerate(dependencies):
        if isinstance(dependency, dict) and str(dependency.get("path", "")).startswith("npc/rv64/"):
            validate_artifact_record(
                root,
                dependency,
                f"{label} dependency[{index}]",
                require_size=True,
            )


def current_rtl_binding(root: pathlib.Path) -> tuple[str, int]:
    module = load_module(
        safe_file(root, ARCH_BINDING_TOOL_PATH),
        "historical_defect_current_rtl_binding",
    )
    digest, files = module.rtl_binding(root)
    return f"sha256:{digest}", len(files)


def validate_qh_younger_store(
    root: pathlib.Path,
    historical: dict[str, Any],
    current: dict[str, Any],
    design_id: str,
) -> dict[str, Any]:
    require_equal(
        historical.get("schema"),
        "npc-rv64-historical-qh-younger-store-reconstruction-v2",
        "younger-store historical schema",
    )
    require_equal(historical.get("status"), "PASS", "younger-store historical status")
    require_equal(
        historical.get("historical_defect_id"),
        "HIST-SER-QH-YOUNGER-STORE-CYCLE",
        "younger-store defect id",
    )
    require_equal(
        historical.get("totals"),
        {"cases": 6, "compile_success": 6, "positive_pass": 4, "expected_rejection": 2},
        "younger-store historical totals",
    )
    historical_cases = historical.get("cases", [])
    require_equal(len(historical_cases), 6, "younger-store historical case rows")
    for row in historical_cases:
        expected_pass = row.get("expected_pass")
        require(expected_pass in {True, False}, "younger-store historical expectation is malformed")
        require_equal(row.get("compile_success"), True, f"{row.get('case')} compile success")
        require_equal(row.get("driver_rc"), 0 if expected_pass else 2, f"{row.get('case')} driver rc")
        require_equal(row.get("oracle_result"), "PASS" if expected_pass else "EXPECTED_REJECTION",
                      f"{row.get('case')} oracle result")
        log_text = validate_retained_log(
            root,
            {"path": row.get("log_path"), "sha256": row.get("log_sha256")},
            f"{row.get('case')} historical log",
        )
        require_equal(log_text.count(str(row.get("root_marker"))), 1,
                      f"{row.get('case')} root marker")
        require_equal(log_text.count(str(row.get("terminal_marker"))), 1,
                      f"{row.get('case')} terminal marker")
        safe_file(root, str(row.get("image_receipt_path")))
    production = historical.get("production_source", {})
    require_equal(production.get("path"), "npc/rv64/vsrc/execute/OooIntBackend.v", "younger-store owner")
    require_equal(production.get("no_drift"), True, "younger-store historical source stability")
    require_equal(production.get("sha256_before"), production.get("sha256_after"), "younger-store historical hashes")
    require(
        SHA256_RE.fullmatch(str(production.get("sha256_after", ""))) is not None,
        "younger-store historical owner hash is malformed",
    )

    require_equal(current.get("schema"), "npc-rv64-v12c-serialize-qh-current-evidence-v1", "current QH schema")
    require_equal(current.get("status"), "PASS", "current QH status")
    require_equal(current.get("design_id"), design_id, "current QH design-id")
    validate_v14e_build_controls(
        root,
        current,
        {
            "npc/rv64/configs/product-rtl-defaults.mk",
            "npc/rv64/testbench/Makefile",
            "npc/rv64/testbench/common/rv32_encode.svh",
            "npc/rv64/testbench/common/tb_common.svh",
            "npc/rv64/testbench/common/tb_ooo_core_top_glue_csr.svh",
            "npc/rv64/testbench/scripts/check_tb_result.py",
            "npc/rv64/testbench/tests/tb_ooo_core_top_glue.sv",
            "npc/rv64/vsrc/control/OooControlEventApplySequencer.v",
            "npc/rv64/vsrc/filelist.mk",
            "npc/rv64/vsrc/include/define.v",
        },
        "current QH",
    )
    require_equal(
        current.get("counts"),
        {
            "committed_transactions": 6,
            "compilations": 5,
            "compile_success_mutations": 3,
            "positive_profiles": 2,
            "selectively_killed_transactions": 4,
        },
        "current QH counts",
    )
    profiles = current.get("profiles", [])
    profile_map = {row.get("name"): row for row in profiles if isinstance(row, dict)}
    require_equal(set(profile_map), {
        "assert", "release", "mutation-typed-apply-c2-replay",
        "mutation-csrfile-request-c2-replay",
        "mutation-rob-queue-head-selection-disabled",
    }, "current QH profiles")
    cleanup_artifacts = validate_removed_artifacts(root, current, "current QH")
    qh_positive_log_markers = {
        "[V10G-QH-CSR-RAW]": 3,
        "[V10G-QH-CSR-KILL]": 2,
        "[PASS] tb_ooo_core_top_glue_v9o_csr_qh": 1,
        "[CHECK-FAIL]": 0,
    }
    qh_profile_contracts = {
        "assert": (
            True, True, 0, None,
            {"committed": 3, "selectively_killed": 2},
            qh_positive_log_markers,
        ),
        "release": (
            False, True, 0, None,
            {"committed": 3, "selectively_killed": 2},
            qh_positive_log_markers,
        ),
        "mutation-typed-apply-c2-replay": (
            True,
            False,
            2,
            "typed-apply-c2-replay",
            {
                "[CHECK-FAIL] V10G C2 repeated queue-head CSR request/apply": 3,
                "[CHECK-FAIL] V10G unowned/repeated queue-head CSR apply": 3,
            },
            {
                "[CHECK-FAIL] V10G C2 repeated queue-head CSR request/apply": 3,
                "[CHECK-FAIL] V10G unowned/repeated queue-head CSR apply": 3,
            },
        ),
        "mutation-csrfile-request-c2-replay": (
            True,
            False,
            2,
            "csrfile-request-c2-replay",
            {
                "[CHECK-FAIL] V10G C2 repeated queue-head CSR request/apply": 3,
                "[CHECK-FAIL] V10G unowned/repeated CsrFile CSR request": 3,
            },
            {
                "[CHECK-FAIL] V10G C2 repeated queue-head CSR request/apply": 3,
                "[CHECK-FAIL] V10G unowned/repeated CsrFile CSR request": 3,
            },
        ),
        "mutation-rob-queue-head-selection-disabled": (
            True,
            False,
            2,
            "rob-queue-head-selection-disabled",
            {"[CHECK-FAIL] V10G queue-head CSR C0 commit/barrier diverged": 1},
            {"[CHECK-FAIL] V10G queue-head CSR C0 commit/barrier diverged": 1},
        ),
    }
    for name, contract in qh_profile_contracts.items():
        validate_v14e_profile(
            root,
            profile_map[name],
            cleanup_artifacts=cleanup_artifacts,
            label=f"current QH {name}",
            assertions=contract[0],
            expect_pass=contract[1],
            make_returncode=contract[2],
            mutation=contract[3],
            markers=contract[4],
            log_markers=contract[5],
        )
    require_equal(
        set(current.get("mutations", {})),
        {"typed-apply-c2-replay", "csrfile-request-c2-replay", "rob-queue-head-selection-disabled"},
        "current QH mutations",
    )
    for name, mutation in current["mutations"].items():
        require_equal(mutation.get("compile_success_required"), True,
                      f"current QH {name} compile-success contract")
        validate_artifact_record(
            root,
            mutation.get("source"),
            f"current QH {name} source",
            require_size=True,
        )
        mutated = mutation.get("mutated")
        require(isinstance(mutated, dict)
                and isinstance(mutated.get("path"), str)
                and SHA256_RE.fullmatch(str(mutated.get("sha256", ""))) is not None
                and isinstance(mutated.get("size_bytes"), int)
                and mutated["size_bytes"] > 0,
                f"current QH {name} mutation artifact is malformed")
    require_equal(current.get("compile_input_closure"), {
        "actual_compiler_argv_bound": True,
        "icarus_dependency_bound": True,
        "make_source_selection_bound": True,
        "status": "PASS",
    }, "current QH compile-input closure")
    require_current_source(root, current, "npc/rv64/vsrc/execute/OooIntBackend.v", "current QH")
    return {
        "historical_compile_success": "6/6",
        "historical_negative_rejection": "2/2",
        "current_positive_profiles": "2/2",
        "current_compile_success_mutations": "3/3",
        "compile_success_evidence": "RETAINED_TB_LOG_PLUS_REMOVED_ZERO_RC_RECEIPT",
        "current_design_bound": True,
    }


def validate_qh_stop_hold(
    root: pathlib.Path,
    historical: dict[str, Any],
    current: dict[str, Any],
    design_id: str,
) -> dict[str, Any]:
    require_equal(historical.get("schema"), "npc-rv64-hist-ser-qh-stop-hold-matrix/v1", "stop-hold historical schema")
    require_equal(historical.get("status"), "PASS", "stop-hold historical status")
    cases = historical.get("cases", [])
    require_equal(len(cases), 8, "stop-hold historical case count")
    require(all(row.get("compile_success") is True and row.get("passed") is True for row in cases), "stop-hold historical case failed")
    for row in cases:
        expected = row.get("expected")
        expected_rc = 0 if expected in {"pass", "pass_successor_owner"} else 2
        require_equal(row.get("driver_returncode"), expected_rc,
                      f"{row.get('case')} historical driver rc")
        require_equal(row.get("errors"), [], f"{row.get('case')} historical errors")
        validate_retained_log(
            root,
            {"path": row.get("log_path"), "sha256": row.get("log_sha256")},
            f"{row.get('case')} historical log",
        )
        safe_file(root, str(row.get("image_receipt")))
    coverage = historical.get("coverage", {})
    require_equal(coverage.get("compile_success"), "8/8", "stop-hold compile-success coverage")
    require_equal(coverage.get("event_deduplication"), False, "stop-hold event deduplication")
    require_equal(coverage.get("historical_pre_t3u_root_rejected"), True, "stop-hold historical root")
    for path in (
        "npc/rv64/vsrc/control/OooStopPendingSequencer.v",
        "npc/rv64/vsrc/frontend/OooFrontendRunGate.v",
        "npc/rv64/testbench/tests/tb_ooo_core_top_glue.sv",
    ):
        expected = historical.get("production_sources", {}).get(path)
        require_equal(sha256_file(safe_file(root, path)), expected, f"stop-hold current hash {path}")

    require_equal(current.get("schema"), "npc-rv64-v12c-serialize-system-current-evidence-v1", "current system schema")
    require_equal(current.get("status"), "PASS", "current system status")
    require_equal(current.get("design_id"), design_id, "current system design-id")
    validate_v14e_build_controls(
        root,
        current,
        {
            "npc/rv64/configs/product-rtl-defaults.mk",
            "npc/rv64/testbench/Makefile",
            "npc/rv64/testbench/common/tb_common.svh",
            "npc/rv64/testbench/scripts/check_tb_result.py",
            "npc/rv64/testbench/tests/tb_ooo_csr_access_request_mux.sv",
            "npc/rv64/testbench/tests/tb_ooo_fetch_axi_bridge.sv",
            "npc/rv64/testbench/tests/tb_ooo_pending_drain_resolve_gate.sv",
            "npc/rv64/testbench/tests/tb_ooo_priv_system.sv",
            "npc/rv64/vsrc/filelist.mk",
            "npc/rv64/vsrc/include/define.v",
        },
        "current system",
    )
    profile_map = {
        row.get("name"): row
        for row in current.get("profiles", [])
        if isinstance(row, dict)
    }
    cleanup_artifacts = validate_removed_artifacts(root, current, "current stop-hold")
    for name in ("priv-system-assert", "priv-system-release", "retain-noncsr-holder-after-terminal", "retain-stop-after-drain-terminal"):
        require(name in profile_map and profile_map[name].get("passed") is True, f"current stop-hold profile missing: {name}")
    positive_markers = {
        "[PASS] tb_ooo_priv_system": 1,
        "[V10B-FENCE-POST-FIRE]": 1,
        "[V10B-SATP-MMU]": 1,
        "[V10B-SYSTEM-MIXED]": 1,
        "[V10G-PRODUCT-QH-SATP]": 1,
    }
    validate_v14e_profile(
        root,
        profile_map["priv-system-assert"],
        cleanup_artifacts=cleanup_artifacts,
        label="current stop-hold priv-system-assert",
        assertions=True,
        expect_pass=True,
        make_returncode=0,
        mutation=None,
        markers=positive_markers,
        log_markers=positive_markers,
    )
    validate_v14e_profile(
        root,
        profile_map["priv-system-release"],
        cleanup_artifacts=cleanup_artifacts,
        label="current stop-hold priv-system-release",
        assertions=False,
        expect_pass=True,
        make_returncode=0,
        mutation=None,
        markers=positive_markers,
        log_markers=positive_markers,
    )
    for name in (
        "retain-noncsr-holder-after-terminal",
        "retain-stop-after-drain-terminal",
    ):
        validate_v14e_profile(
            root,
            profile_map[name],
            cleanup_artifacts=cleanup_artifacts,
            label=f"current stop-hold {name}",
            assertions=True,
            expect_pass=False,
            make_returncode=2,
            mutation=name,
            markers={"V10B C1 owner/stop not clear kind=2": 1},
            log_markers={"V10B C1 owner/stop not clear kind=2": 1},
        )
    for path in (
        "npc/rv64/vsrc/control/OooStopPendingSequencer.v",
        "npc/rv64/vsrc/frontend/OooFrontendRunGate.v",
    ):
        require_current_source(root, current, path, "current stop-hold")
    return {
        "historical_compile_success_cases": "8/8",
        "historical_root_rejected_assert_on_off": True,
        "current_positive_profiles": "2/2",
        "current_compile_success_mutations": "2/2",
        "compile_success_evidence": "RETAINED_TB_LOG_PLUS_REMOVED_ZERO_RC_RECEIPT",
        "event_deduplication": False,
    }


def expected_exit_mutations(root: pathlib.Path) -> dict[str, dict[str, Any]]:
    runner = load_module(
        safe_file(root, EXIT_RUNNER_PATH),
        "historical_defect_current_exit_runner",
    )
    expected: dict[str, dict[str, Any]] = {}
    for mutation in runner.MUTATIONS:
        mutated_text: dict[pathlib.Path, str] = {}
        for target, old, new in mutation["edits"]:
            source = mutated_text.get(target, target.read_text(encoding="utf-8"))
            require_equal(source.count(old), 1,
                          f"{mutation['name']} current mutation anchor count")
            mutated_text[target] = source.replace(old, new, 1)
        expected[mutation["name"]] = {
            "assertions": bool(mutation["assertions"]),
            "marker": mutation["marker"],
            "mutated_sources": {
                target.relative_to(root).as_posix(): hashlib.sha256(
                    text.encode("utf-8")
                ).hexdigest()
                for target, text in sorted(
                    mutated_text.items(), key=lambda item: item[0].as_posix()
                )
            },
        }
    return expected


def validate_external_tool_record(record: Any, name: str) -> None:
    require(isinstance(record, dict), f"exit {name} tool record is missing")
    require_equal(set(record), {"path", "sha256", "version"},
                  f"exit {name} tool fields")
    raw_path = pathlib.Path(str(record.get("path", "")))
    discovered = shutil.which(name)
    require(raw_path.is_absolute() and discovered is not None,
            f"exit {name} tool path is unavailable")
    try:
        recorded_path = raw_path.resolve(strict=True)
        discovered_path = pathlib.Path(discovered).resolve(strict=True)
    except OSError as exc:
        raise HistoricalCurrentError(f"exit {name} tool path is unavailable") from exc
    require(recorded_path.is_file(), f"exit {name} tool is not a regular file")
    require_equal(recorded_path, discovered_path, f"exit {name} selected tool")
    require_equal(sha256_file(recorded_path), record.get("sha256"),
                  f"exit {name} tool hash")
    try:
        version = subprocess.run(
            [str(recorded_path), "-V"],
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            check=False,
            timeout=10,
        )
    except (OSError, subprocess.SubprocessError) as exc:
        raise HistoricalCurrentError(f"exit {name} version query failed") from exc
    require_equal(version.returncode, 0, f"exit {name} version return code")
    require_equal(version.stdout.strip(), record.get("version"),
                  f"exit {name} version")


def validate_exit_compile_log(
    text: str,
    *,
    runner: Any,
    configuration: dict[str, Any],
    assertions: bool,
    label: str,
    mutation_name: str | None = None,
    mutated_sources: dict[str, str] | None = None,
) -> str:
    first_line = text.splitlines()[0] if text.splitlines() else ""
    require(first_line.startswith("$ "), f"{label}: compile command is missing")
    try:
        argv = shlex.split(first_line[2:])
    except ValueError as exc:
        raise HistoricalCurrentError(f"{label}: compile command is malformed") from exc
    prefix = [
        configuration["iverilog"]["path"],
        "-g2012",
        "-Wall",
        f"-I{runner.VSRCDIR}",
        f"-I{runner.VSRCDIR / 'include'}",
        f"-I{runner.COMMON}",
    ]
    if assertions:
        prefix.append("-DOOO_ASSERT")
    prefix.extend(["-s", "tb_ooo_serialized_owner_exactly_once", "-o"])
    require_equal(argv[:len(prefix)], prefix, f"{label} compile option prefix")
    require(len(argv) == len(prefix) + 1 + len(runner.RTL_SOURCES) + 1,
            f"{label}: compile source argv count drifted")
    image_path = argv[len(prefix)]
    image = pathlib.PurePosixPath(image_path)
    require(image.is_absolute(), f"{label}: compile image path is not absolute")
    require_equal(image.name, f"{label}.vvp",
                  f"{label} compile image")
    require(
        image.parent.parent == pathlib.PurePosixPath("/tmp")
        and image.parent.name.startswith("rv64-historical-exit-current-"),
            f"{label}: compile image is outside the isolated scratch")
    source_argv = argv[len(prefix) + 1:]
    mutated = set((mutated_sources or {}).keys())
    for actual, expected in zip(source_argv[:-1], runner.RTL_SOURCES):
        relative = expected.relative_to(runner.ROOT).as_posix()
        if relative in mutated:
            expected_mutation_path = image.parent / str(mutation_name) / expected.name
            require(
                mutation_name is not None
                and actual != str(expected)
                and pathlib.PurePosixPath(actual) == expected_mutation_path,
                f"{label}: mutated source argv drifted for {relative}",
            )
        else:
            require_equal(actual, str(expected), f"{label} source argv {relative}")
    require_equal(source_argv[-1], str(runner.TB), f"{label} testbench argv")
    return image_path


def validate_exit_simulation_log(
    text: str,
    *,
    runner: Any,
    configuration: dict[str, Any],
    image_path: str,
    label: str,
) -> None:
    first_line = text.splitlines()[0] if text.splitlines() else ""
    require(first_line.startswith("$ "), f"{label}: simulation command is missing")
    try:
        argv = shlex.split(first_line[2:])
    except ValueError as exc:
        raise HistoricalCurrentError(f"{label}: simulation command is malformed") from exc
    require_equal(
        argv,
        [configuration["vvp"]["path"], image_path, runner.PLUSARG],
        f"{label} simulation argv",
    )


def validate_exit_current(root: pathlib.Path, payload: dict[str, Any], design_id: str) -> dict[str, Any]:
    require_equal(payload.get("schema"), "npc-rv64-historical-exit-current-v1", "exit current schema")
    require_equal(payload.get("status"), "PASS", "exit current status")
    require_equal(payload.get("design_id"), design_id, "exit current design-id")
    require_equal(payload.get("rtl_file_count"), RTL_FILE_COUNT, "exit current RTL count")
    runner = load_module(
        safe_file(root, EXIT_RUNNER_PATH),
        "historical_defect_current_exit_contract",
    )
    configuration = payload.get("configuration")
    require(isinstance(configuration, dict), "exit current configuration is missing")
    require_equal(set(configuration), {"systemverilog", "plusarg", "iverilog", "vvp"},
                  "exit current configuration fields")
    require_equal(configuration.get("systemverilog"), "2012",
                  "exit current SystemVerilog mode")
    require_equal(configuration.get("plusarg"), runner.PLUSARG,
                  "exit current focused plusarg")
    require_equal(runner.PLUSARG, "+V10D_ONLY", "exit runner focused plusarg")
    validate_external_tool_record(configuration.get("iverilog"), "iverilog")
    validate_external_tool_record(configuration.get("vvp"), "vvp")
    require_equal(
        payload.get("counts"),
        {
            "baseline_profiles_pass": 2,
            "baseline_profiles_required": 2,
            "compile_success_mutations": 7,
            "dynamically_rejected_mutations": 7,
            "mutations_required": 7,
        },
        "exit current counts",
    )
    baselines = payload.get("baselines", [])
    require_equal({row.get("profile") for row in baselines}, {"assert", "release"}, "exit baseline profiles")
    expected_baseline_markers = {
        "[V10D-EXIT-EXACTLY-ONCE-PASS]": 2,
        "[V10D-EXIT-LOCAL-FLUSH-PASS]": 1,
        "[V10D-EXIT-RECOVERY-PRIORITY-PASS]": 1,
        "[CHECK-FAIL]": 0,
    }
    for row in baselines:
        profile = row.get("profile")
        require_equal(row.get("assertions"), profile == "assert",
                      f"exit {profile} assertions")
        require_equal(row.get("compile_rc"), 0, f"exit {profile} compile rc")
        require_equal(row.get("simulation_rc"), 0, f"exit {profile} simulation rc")
        require_equal(row.get("passed"), True, f"exit {profile} result")
        require_equal(row.get("marker_counts"), expected_baseline_markers,
                      f"exit {profile} markers")
        compile_text = validate_retained_log(
            root, row.get("compile_log"), f"exit {profile} compile log"
        )
        image_path = validate_exit_compile_log(
            compile_text,
            runner=runner,
            configuration=configuration,
            assertions=profile == "assert",
            label=f"baseline-{profile}",
        )
        simulation_text = validate_retained_log(
            root, row.get("simulation_log"), f"exit {profile} simulation log"
        )
        validate_exit_simulation_log(
            simulation_text,
            runner=runner,
            configuration=configuration,
            image_path=image_path,
            label=f"exit {profile}",
        )
        require_log_markers(simulation_text, expected_baseline_markers,
                            f"exit {profile}")
    expected_specs = expected_exit_mutations(root)
    expected_mutations = set(expected_specs)
    mutations = payload.get("mutations", [])
    require_equal({row.get("name") for row in mutations}, expected_mutations, "exit current mutations")
    for row in mutations:
        name = row.get("name")
        spec = expected_specs[name]
        require_equal(row.get("assertions"), spec["assertions"], f"exit {name} assertions")
        require_equal(row.get("compile_rc"), 0, f"exit {name} compile rc")
        require_equal(row.get("compile_success"), True, f"exit {name} compile success")
        require_equal(row.get("simulation_rc"), 1, f"exit {name} simulation rc")
        require_equal(row.get("rejected"), True, f"exit {name} rejection")
        require_equal(row.get("expected_rejection_marker"), spec["marker"],
                      f"exit {name} rejection marker")
        require_equal(row.get("mutated_sources"), spec["mutated_sources"],
                      f"exit {name} mutation source hash")
        compile_text = validate_retained_log(
            root, row.get("compile_log"), f"exit {name} compile log"
        )
        image_path = validate_exit_compile_log(
            compile_text,
            runner=runner,
            configuration=configuration,
            assertions=bool(spec["assertions"]),
            label=f"mutation-{name}",
            mutation_name=name,
            mutated_sources=spec["mutated_sources"],
        )
        simulation_text = validate_retained_log(
            root, row.get("simulation_log"), f"exit {name} simulation log"
        )
        validate_exit_simulation_log(
            simulation_text,
            runner=runner,
            configuration=configuration,
            image_path=image_path,
            label=f"exit {name}",
        )
        require_equal(simulation_text.count(spec["marker"]), row.get("marker_count"),
                      f"exit {name} marker count")
        require(isinstance(row.get("marker_count"), int) and row["marker_count"] > 0,
                f"exit {name}: rejection marker is absent")
    bindings = payload.get("source_bindings", [])
    expected_bindings = {
        path.resolve().relative_to(root.resolve()).as_posix():
        ("testbench" if path == runner.TB else "rtl")
        for path in (*runner.RTL_SOURCES, runner.TB)
    }
    require(isinstance(bindings, list), "exit source bindings are missing")
    binding_map = {
        binding.get("path"): binding
        for binding in bindings
        if isinstance(binding, dict) and isinstance(binding.get("path"), str)
    }
    require_equal(len(binding_map), len(bindings),
                  "exit source binding uniqueness")
    require_equal(set(binding_map), set(expected_bindings),
                  "exit source binding paths")
    for binding in bindings:
        require_equal(set(binding), {"path", "role", "sha256"},
                      f"exit source fields {binding.get('path')}")
        require_equal(binding.get("role"), expected_bindings[binding["path"]],
                      f"exit source role {binding.get('path')}")
        require_equal(
            sha256_file(safe_file(root, binding.get("path", ""))),
            binding.get("sha256"),
            f"exit current source {binding.get('path')}",
        )
    require_equal(payload.get("production_rtl_change"), False, "exit production RTL change")
    require_equal(payload.get("intermediate_products_retained"), 0, "exit intermediate products")
    require_equal(payload.get("promotion"), {"whole_architecture": "RED", "ppa": "UNPROMOTED"}, "exit promotion boundary")
    return {
        "baseline_profiles": "2/2",
        "compile_success_mutations": "7/7",
        "current_csrfile_hash": sha256_file(safe_file(root, "npc/rv64/vsrc/core/CsrFile.v")),
        "source_bindings": "12/12_EXACT_ROLE_BOUND",
        "tool_configuration_bound": True,
        "intermediate_products_retained": 0,
    }


def validate_layered_system_current(
    root: pathlib.Path,
    payload: dict[str, Any],
    design_id: str,
) -> dict[str, Any]:
    require_equal(
        payload.get("schema"),
        "npc-rv64-layered-system-signoff-current-v1",
        "layered current schema",
    )
    require_equal(payload.get("status"), "PASS", "layered current status")
    require_equal(payload.get("rtl_design_id"), design_id, "layered current design-id")
    require_equal(payload.get("production_rtl_file_count"), RTL_FILE_COUNT, "layered current RTL count")
    expected_layers = [
        "L0_DIRECTED_RTL",
        "L1_FULL_CORE_DIFFTEST",
        "L2_MINI_SYSTEM",
        "L3_LIGHTWEIGHT_LINUX",
    ]
    require_equal(
        payload.get("default_signoff_conjunction"),
        expected_layers,
        "layered default conjunction",
    )
    layers = payload.get("layers", {})
    assertion_failures = 0
    for name in expected_layers:
        row = layers.get(name, {})
        require_equal(row.get("status"), "PASS", f"{name} status")
        require_equal(row.get("design_id"), design_id, f"{name} design-id")
        assertions = row.get("rtl_assertions")
        if assertions is not None:
            require_equal(
                assertions,
                {"enabled": True, "failures": 0},
                f"{name} RTL assertions",
            )
            assertion_failures += assertions["failures"]
    ubuntu = payload.get("optional_full_ubuntu", {})
    require_equal(ubuntu.get("status"), "NOT_RUN", "optional Ubuntu status")
    require_equal(ubuntu.get("blocks_default_signoff"), False, "optional Ubuntu gate")
    require_equal(
        ubuntu.get("launch_policy"),
        "explicit-user-request-only",
        "optional Ubuntu launch policy",
    )
    validate_artifact_record(root, payload.get("checker"), "layered checker", require_size=True)
    validate_artifact_record(root, payload.get("policy"), "layered policy", require_size=True)
    return {
        "default_signoff": "L0+L1+L2+L3",
        "layer_status": {name: "PASS" for name in expected_layers},
        "rtl_assertion_failures": assertion_failures,
        "optional_ubuntu": "NOT_RUN_EXPLICIT_REQUEST_ONLY",
    }


def validate_a3_checker_contract(root: pathlib.Path) -> dict[str, Any]:
    """Run only the checker tests that distinguish ``printk: debug:`` from BUG."""

    test_path = safe_file(root, CURRENT_CHECKER_TEST_PATH)
    command = [
        sys.executable,
        "-B",
        "-m",
        "unittest",
        "-q",
        test_path.relative_to(root.resolve()).as_posix(),
    ]
    completed = subprocess.run(
        command,
        cwd=root,
        text=True,
        capture_output=True,
        timeout=30,
        check=False,
    )
    output = completed.stdout + completed.stderr
    match = re.search(r"Ran ([0-9]+) tests", output)
    observed = int(match.group(1)) if match else -1
    require_equal(completed.returncode, 0, "A3 checker focused test rc")
    require_equal(observed, 3, "A3 checker focused test count")
    require("\nOK\n" in output, "A3 checker focused test PASS marker is absent")
    return {
        "status": "PASS",
        "tests_run": observed,
        "command": " ".join(command),
    }


def validate_a3(
    root: pathlib.Path,
    historical: dict[str, Any],
    checker_contract: dict[str, Any],
    layered_metrics: dict[str, Any],
) -> dict[str, Any]:
    require_equal(historical.get("schema"), "npc-rv64-a3-checker-replay/v2", "A3 replay schema")
    require_equal(historical.get("status"), "PASS", "A3 replay status")
    require_equal(historical.get("classification"), "verification-checker-replay", "A3 replay class")
    require_equal(historical.get("conclusion"), "A3_SYSTEM_TRANSACTION_COMPLETE_LEGACY_ORACLE_FALSE_POSITIVE", "A3 conclusion")
    source = historical.get("source_run", {})
    original_status = safe_file(root, HISTORICAL_A3_STATUS_PATH).read_text(encoding="utf-8").strip()
    require(original_status.startswith("FAIL rc=1"), "A3 original status no longer FAIL")
    require_equal(source.get("original_status"), original_status, "A3 original status binding")
    require_equal(source.get("original_status_preserved"), True, "A3 status preservation")
    validate_artifact_record(
        root,
        {
            "path": source.get("rootfs_binding_path"),
            "sha256": source.get("rootfs_binding_sha256"),
        },
        "A3 rootfs binding",
    )
    base_replay = historical.get("base_replay", {})
    validate_artifact_record(
        root,
        {"path": base_replay.get("evidence"), "sha256": base_replay.get("evidence_sha256")},
        "A3 base replay evidence",
    )
    validate_artifact_record(
        root,
        {"path": base_replay.get("script"), "sha256": base_replay.get("script_sha256")},
        "A3 base replay script",
    )
    replay = historical.get("oracle_replay", {})
    require_equal(replay.get("printk_debug_fixture", {}).get("current_match"), False, "A3 printk debug fixture")
    require_equal(replay.get("real_bug_fixture", {}).get("current_match"), True, "A3 real BUG fixture")
    require_equal(replay.get("current_a3_match_count"), 0, "A3 current match count")
    require_equal(replay.get("legacy_a3_match_count"), 2, "A3 legacy match count")
    require_equal(replay.get("current_checker"), CURRENT_CHECKER_PATH.as_posix(),
                  "A3 current checker path")
    require_equal(
        replay.get("current_checker_sha256"),
        sha256_file(safe_file(root, CURRENT_CHECKER_PATH)),
        "A3 current checker hash",
    )
    require_equal(checker_contract.get("tests_run"), 3, "current checker tests")
    require_equal(checker_contract.get("status"), "PASS", "current checker test status")
    checker_text = safe_file(root, CURRENT_CHECKER_PATH).read_text(encoding="utf-8")
    require("(^|[^[:alnum:]_])BUG:" in checker_text, "current bounded BUG token is missing")
    test_text = safe_file(root, CURRENT_CHECKER_TEST_PATH).read_text(encoding="utf-8")
    require("printk: debug:" in test_text and "BUG: unable to handle page fault" in test_text, "current checker positive/negative fixtures are missing")
    return {
        "original_status": original_status,
        "original_status_preserved": True,
        "legacy_matches": 2,
        "current_matches": 0,
        "printk_debug_accepted": True,
        "real_bug_rejected": True,
        "current_checker_tests": "3/3_FOCUSED",
        "layered_current": layered_metrics,
    }


def validate_v8l(
    root: pathlib.Path,
    historical: dict[str, Any],
    current: dict[str, Any],
    design_id: str,
) -> dict[str, Any]:
    require_equal(historical.get("schema"), "npc-rv64-holder-lifecycle-mutations-v1", "V8L historical schema")
    require_equal(historical.get("compile_success"), 9, "V8L historical compile count")
    require_equal(historical.get("rejected"), 9, "V8L historical rejection count")
    mutations = historical.get("mutations", [])
    require_equal(len(mutations), 9, "V8L historical mutation rows")
    require(all(row.get("compiled") is True and row.get("rejected") is True for row in mutations), "V8L historical mutation survived")
    for row in mutations:
        mutator_text = validate_retained_log(
            root,
            row.get("mutator_log"),
            f"V8L historical {row.get('name')} mutator log",
        )
        simulation_text = validate_retained_log(
            root,
            row.get("simulation_log"),
            f"V8L historical {row.get('name')} simulation log",
        )
        require(f"[V8L-MUTATOR][PASS] {row.get('name')}" in mutator_text,
                f"V8L historical {row.get('name')} mutator marker is absent")
        require("[MAKE-RC] 2" in simulation_text,
                f"V8L historical {row.get('name')} rejection return code is absent")
    binding = historical.get("source_binding", {})
    require_equal(
        binding.get("rtl_pre", {}).get("sha256"),
        binding.get("rtl_post", {}).get("sha256"),
        "V8L historical RTL pre/post",
    )
    require_equal(
        binding.get("runner_sources_pre", {}).get("sha256"),
        binding.get("runner_sources_post", {}).get("sha256"),
        "V8L historical runner pre/post",
    )

    if current.get("schema") == "npc-rv64-v8l-current-focused-v1":
        require_equal(current.get("status"), "PASS", "V15G V8L current status")
        require_equal(current.get("design_id"), design_id, "V15G V8L current design-id")
        require_equal(current.get("rtl_file_count"), RTL_FILE_COUNT, "V15G V8L RTL count")
        require_equal(
            current.get("counts"),
            {
                "baselines_passed": 4,
                "baselines_required": 4,
                "mutations_rejected": 9,
                "mutations_required": 9,
            },
            "V15G V8L counts",
        )
        require_equal(current.get("assertion_modes"), ["assert", "release"], "V15G V8L assertion modes")
        for name, record in current.get("production_sources", {}).items():
            validate_artifact_record(
                root,
                record,
                f"V15G V8L production source {name}",
                require_size=True,
            )
        baselines = current.get("baselines", [])
        require_equal(
            [row.get("name") for row in baselines],
            ["dispatch-assert", "dispatch-release", "backend-assert", "backend-release"],
            "V15G V8L baseline inventory",
        )
        for row in baselines:
            require_equal(row.get("result"), "PASS", f"V15G V8L {row.get('name')} result")
            log = validate_retained_log(root, row.get("log"), f"V15G V8L {row.get('name')} log")
            require_equal(log.count("[RESULT] PASS"), 1, f"V15G V8L {row.get('name')} PASS marker")
            require("[RESULT] FAIL" not in log, f"V15G V8L {row.get('name')} contains FAIL")
        expected_mutations = [
            "dispatch-drop-int-iq-union",
            "dispatch-lane0-raw-index",
            "int-iq-fire-dies-early",
            "backend-drop-mem-res-holder",
            "backend-drop-ex0-holder",
            "backend-drop-ex1-holder",
            "backend-drop-branch-holder",
            "backend-capture-ignores-tracker-ready",
            "backend-iq-pop-ignores-tracker-ready",
        ]
        mutations = current.get("compile_success_mutations", [])
        require_equal(
            [row.get("name") for row in mutations],
            expected_mutations,
            "V15G V8L mutation inventory",
        )
        for row in mutations:
            name = row.get("name")
            require_equal(row.get("result"), "REJECTED_COMPILE_SUCCESS_VARIANT", f"V15G V8L {name} result")
            require(
                isinstance(row.get("make_return_code"), int)
                and row["make_return_code"] != 0,
                f"V15G V8L {name} return code is not a rejection",
            )
            require_equal(row.get("compiled_image", {}).get("retained"), False, f"V15G V8L {name} image retention")
            validate_artifact_record(root, row.get("mutated_rtl"), f"V15G V8L {name} RTL", require_size=True)
            validate_artifact_record(root, row.get("make_log"), f"V15G V8L {name} make log", require_size=True)
            log = validate_retained_log(root, row.get("log"), f"V15G V8L {name} simulation log")
            expected_marker = row.get("expected_marker")
            require(
                isinstance(expected_marker, str) and expected_marker in log,
                f"V15G V8L {name} expected marker is absent",
            )
            require("[RESULT] FAIL" in log, f"V15G V8L {name} FAIL marker is absent")
        require_equal(current.get("cleanup", {}).get("compiled_images_retained"), 0, "V15G V8L retained images")
        retained_images = list(
            (root / HOLDER_CURRENT_PATH.parent).rglob("*.vvp")
        )
        require_equal(retained_images, [], "V15G V8L on-disk images")

        text = safe_file(root, V8L_TB_PATH).read_text(encoding="utf-8")
        for value in ("4'h6", "4'h7", "4'h8", "4'h9"):
            require_equal(text.count(f"v8l_force_pid[ROB_INDEX_W-1:0] = {value};"), 1, f"V8L distinct ProducerId {value}")
        reset_snippets = (
            "release dut.mem_issue_res_producer_id_q;\n      reset_dut();",
            "release dut.ex0_producer_id_q;\n      reset_dut();",
            "release dut.ex1_producer_id_q;\n      reset_dut();",
            "release dut.branch_resolve_payload_producer_id_w;\n      reset_dut();",
        )
        for snippet in reset_snippets:
            require_equal(text.count(snippet), 1, "V8L release/reset boundary")
        return {
            "historical_compile_success_mutations": "9/9",
            "current_baseline_profiles": "4/4",
            "current_compile_success_mutations": "9/9",
            "assertion_modes": ["assert", "release"],
            "distinct_forced_producer_ids": 4,
            "release_reset_boundaries": 4,
            "intermediate_products_retained": 0,
            "scope": "FOCUSED_V8L_CURRENT_DESIGN",
        }

    require(
        current.get("schema_version") in {
            "npc-rv64-global-producer-no-live-reuse-receipt-v1",
            "npc-rv64-global-producer-no-live-reuse-receipt-v2",
        },
        "global holder schema is unsupported",
    )
    require_equal(current.get("status"), "PASS", "V14H holder status")
    require_equal(current.get("design_id"), design_id, "V14H holder design-id")
    fence = current.get("v14g_dynamic_fence", {})
    require_equal(fence.get("schema"), "npc-rv64-v14g-global-producer-owner-fence-v1", "V14G fence schema")
    require_equal(fence.get("status"), "PASS", "V14G fence status")
    require_equal(fence.get("design_id"), design_id, "V14G fence design-id")
    require_equal(fence.get("baseline_profiles_pass"), 4, "V14G baseline count")
    require_equal(fence.get("compile_success_mutations_rejected"), 22, "V14G mutation count")
    require_equal(fence.get("generation_widths"), [1, 4], "V14G generation widths")
    require_equal(fence.get("intermediate_products_retained"), 0, "V14G retained intermediates")
    try:
        holder_tool = load_module(
            safe_file(root, HOLDER_CURRENT_TOOL_PATH),
            "historical_defect_current_holder_verifier",
        )
        holder_tool.validate_v14g_snapshot(root, fence, design_id)
    except Exception as exc:
        raise HistoricalCurrentError(
            f"V14G current upstream verifier failed: {exc}"
        ) from exc
    for row in [*fence.get("baselines", []), *fence.get("mutations", [])]:
        log_text = validate_retained_log(
            root,
            row.get("log"),
            f"V14G {row.get('name')} log",
            path_key="origin_path",
        )
        require_log_header(
            log_text,
            {
                "PROFILE": str(row.get("name")),
                "KIND": str(row.get("kind")),
                "GENERATION_WIDTH": str(row.get("generation_width")),
                "ASSERTIONS": "1" if row.get("assertions") is True else "0",
                "COMPILE_RC": "0",
                "COMPILE_TIMEOUT": "0",
                "SIM_RC": str(row.get("sim_rc")),
                "SIM_TIMEOUT": "0",
            },
            f"V14G {row.get('name')}",
        )
        require_log_markers(
            log_text,
            row.get("marker_counts"),
            f"V14G {row.get('name')}",
        )
    for record in fence.get("source_bindings", []):
        if record.get("current_required") is True:
            require_equal(
                sha256_file(safe_file(root, record.get("path", ""))),
                record.get("sha256"),
                f"V14G current source {record.get('path')}",
            )

    text = safe_file(root, V8L_TB_PATH).read_text(encoding="utf-8")
    for value in ("4'h6", "4'h7", "4'h8", "4'h9"):
        require_equal(text.count(f"v8l_force_pid[ROB_INDEX_W-1:0] = {value};"), 1, f"V8L distinct ProducerId {value}")
    reset_snippets = (
        "release dut.mem_issue_res_producer_id_q;\n      reset_dut();",
        "release dut.ex0_producer_id_q;\n      reset_dut();",
        "release dut.ex1_producer_id_q;\n      reset_dut();",
        "release dut.branch_resolve_payload_producer_id_w;\n      reset_dut();",
    )
    for snippet in reset_snippets:
        require_equal(text.count(snippet), 1, "V8L release/reset boundary")
    return {
        "historical_compile_success_mutations": "9/9",
        "current_baseline_profiles": "4/4",
        "current_compile_success_mutations": "22/22",
        "retained_log_return_code_crosscheck": "26/26",
        "generation_widths": [1, 4],
        "distinct_forced_producer_ids": 4,
        "release_reset_boundaries": 4,
    }


def load_key_value_evidence(
    root: pathlib.Path,
    relative: str | pathlib.PurePosixPath,
    label: str,
) -> tuple[dict[str, str], str]:
    text = safe_file(root, relative).read_text(encoding="utf-8", errors="replace")
    values: dict[str, str] = {}
    for line in text.splitlines():
        if not line.strip():
            continue
        require("=" in line, f"{label}: malformed key/value line {line!r}")
        key, value = line.split("=", 1)
        require(key and key not in values, f"{label}: duplicate or empty key {key!r}")
        values[key] = value
    return values, text


def validate_v15p_adapter_current(
    root: pathlib.Path,
    design_id: str,
) -> dict[str, Any]:
    closure, _ = load_key_value_evidence(
        root, V15P_ADAPTER_REVIEW_CLOSURE_PATH, "V15P adapter review closure"
    )
    expected_fields = {
        "SCHEMA": "rv64-v15p-independent-review-closure-v2",
        "RESULT": "PASS",
        "SCOPE": "REVERSIBLE_INTERMEDIATE_CHECKPOINT_ONLY",
        "DESIGN_ID": design_id,
        "V1_ORIGINAL_RESULT": "GAP",
        "V1_HISTORY_REWRITTEN": "0",
        "V2_RESULT": "PASS",
        "MUTATION": "NO_FINAL_B_FALLTHROUGH",
        "MUTATION_COMPILE_SUCCESS": "1",
        "MUTATION_EXPECTED_TEST_FAILURE": "1",
        "MUTATION_MAKE_RC": "2",
        "MUTATION_PRODUCTION_SHA_UNCHANGED": "1",
        "POSITIVE_STORE_TERMINAL_CYCLES": "2,4,7",
        "MUTATED_STORE_TERMINAL_CYCLES": "3,5,8",
        "MUTATION_ORACLE": "adapter final-B fall-through absolute latency mismatch",
        "TIMING_HARD_GATE": "FAIL",
        "PROMOTION_STATE": "NOT_PROMOTABLE",
    }
    for key, expected in expected_fields.items():
        require_equal(closure.get(key), expected, f"V15P adapter closure {key}")

    closure_artifacts = {
        "V2_RESULT": ("V2_RESULT_PATH", "V2_RESULT_SHA256", V15P_ADAPTER_REVIEW_RESULT_PATH),
        "ADAPTER": ("ADAPTER_PATH", "ADAPTER_SHA256", V15P_ADAPTER_PATH),
        "ADAPTER_TB": ("ADAPTER_TB_PATH", "ADAPTER_TB_SHA256", V15P_ADAPTER_TB_PATH),
        "OWNER_TIMING_TB": (
            "OWNER_TIMING_TB_PATH",
            "OWNER_TIMING_TB_SHA256",
            V15P_OWNER_TIMING_TB_PATH,
        ),
        "MODULE_RESULT": (
            "MODULE_RESULT_PATH",
            "MODULE_RESULT_SHA256",
            V15P_CURRENT_MODULE_RESULT_PATH,
        ),
        "ADAPTER_MODULE_LOG": (
            "ADAPTER_MODULE_LOG_PATH",
            "ADAPTER_MODULE_LOG_SHA256",
            V15P_CURRENT_ADAPTER_LOG_PATH,
        ),
        "MUTATION_RESULT": (
            "MUTATION_RESULT_PATH",
            "MUTATION_RESULT_SHA256",
            V15P_ADAPTER_MUTATION_RESULT_PATH,
        ),
    }
    for name, (path_key, hash_key, expected_path) in closure_artifacts.items():
        require_equal(closure.get(path_key), expected_path.as_posix(), f"V15P {name} path")
        require_equal(
            closure.get(hash_key),
            sha256_file(safe_file(root, expected_path)),
            f"V15P {name} SHA-256",
        )

    review_text = safe_file(root, V15P_ADAPTER_REVIEW_RESULT_PATH).read_text(
        encoding="utf-8", errors="replace"
    )
    for marker in (
        "`PASS`",
        "5 ns timing hard gate 仍为 `FAIL`",
        "Store terminal cycles move from the required `2/4/7` to `3/5/8`",
        "promotion_state=NOT_PROMOTABLE",
    ):
        require(marker in review_text, f"V15P adapter review marker is absent: {marker}")

    module = load_json(root, V15P_CURRENT_MODULE_RESULT_PATH)
    require_equal(module.get("schema"), "npc-rv64-full-core-module-current-evidence-v1", "V15P module schema")
    require_equal(module.get("status"), "PASS", "V15P module status")
    require_equal(module.get("design_id"), design_id, "V15P module design-id")
    require_equal(module.get("inputs", {}).get("unchanged"), True, "V15P module input stability")
    require_equal(module.get("tests", {}).get("passed"), 113, "V15P module passed tests")
    require_equal(module.get("tests", {}).get("required"), 113, "V15P module required tests")
    adapter_log_record = module.get("tests", {}).get("logs", {}).get(
        "tb_ooo_lsu_axi_lane_adapter"
    )
    validate_artifact_record(root, adapter_log_record, "V15P adapter module log", require_size=True)
    require_equal(
        adapter_log_record.get("path") if isinstance(adapter_log_record, dict) else None,
        V15P_CURRENT_ADAPTER_LOG_PATH.as_posix(),
        "V15P adapter module log path",
    )
    adapter_log = safe_file(root, V15P_CURRENT_ADAPTER_LOG_PATH).read_text(
        encoding="utf-8", errors="replace"
    )
    for marker in ("[PASS] tb_ooo_lsu_axi_lane_adapter", design_id, "[RESULT] PASS"):
        require(marker in adapter_log, f"V15P adapter module marker is absent: {marker}")

    mutation, _ = load_key_value_evidence(
        root, V15P_ADAPTER_MUTATION_RESULT_PATH, "V15P adapter mutation"
    )
    for key, expected in {
        "RESULT": "PASS",
        "MUTATION": "no-final-b-fallthrough",
        "COMPILE_SUCCESS": "1",
        "MUTATION_DETECTED": "1",
        "EXPECTED_TEST_FAILURE": "1",
        "MAKE_RC": "2",
        "PRODUCTION_SHA_BEFORE": closure["ADAPTER_SHA256"],
        "PRODUCTION_SHA_AFTER": closure["ADAPTER_SHA256"],
    }.items():
        require_equal(mutation.get(key), expected, f"V15P adapter mutation {key}")
    mutation_log = safe_file(root, V15P_ADAPTER_MUTATION_LOG_PATH).read_text(
        encoding="utf-8", errors="replace"
    )
    for marker in (
        "store_terminal_cycles=3",
        "store_terminal_cycles=5",
        "store_terminal_cycles=8",
        "[OWNER-TIMING-CAUSAL-PROBE][FAIL] adapter final-B fall-through absolute latency mismatch",
        "[RESULT] FAIL status=1",
    ):
        require(marker in mutation_log, f"V15P adapter mutation marker is absent: {marker}")
    return {
        "design_id": design_id,
        "module_tests": "113/113",
        "directed_adapter": "PASS",
        "compile_success_mutation": "1/1_REJECTED",
        "positive_store_terminal_cycles": [2, 4, 7],
        "mutated_store_terminal_cycles": [3, 5, 8],
        "timing_hard_gate": "FAIL_NOT_PROMOTABLE",
    }


def validate_v9p_current_rebind_review(
    root: pathlib.Path,
    review: dict[str, Any],
    design_id: str,
) -> None:
    require_equal(
        review.get("schema"),
        "npc-rv64-v15q-v9p-current-rebind-independent-review-v1",
        "V15Q V9P current rebind review schema",
    )
    require_equal(review.get("status"), "PASS", "V15Q V9P current rebind review status")
    require_equal(review.get("reviewed_design_id"), design_id, "V15Q V9P reviewed design-id")
    reviewer = review.get("reviewer", {})
    require_equal(reviewer.get("mode"), "isolated-read-only-review", "V15Q V9P review mode")
    expected_review_artifacts = {
        "contract": V9P_CURRENT_REBIND_CONTRACT_PATH,
        "result": V9P_CURRENT_REBIND_RESULT_PATH,
        "historical_summary": HISTORICAL_V9P_ROOT_CAUSE_PATH,
        "legacy_review": V15G_INDEPENDENT_REVIEW_PATH,
        "current_v9r": V9R_CURRENT_PATH,
        "layered_current": LAYERED_SYSTEM_CURRENT_PATH,
        "adapter_closure": V15P_ADAPTER_REVIEW_CLOSURE_PATH,
        "adapter_review_result": V15P_ADAPTER_REVIEW_RESULT_PATH,
        "current_module": V15P_CURRENT_MODULE_RESULT_PATH,
        "adapter_mutation": V15P_ADAPTER_MUTATION_RESULT_PATH,
        "backend": V9P_BACKEND_PATH,
        "bridge": V9P_BRIDGE_PATH,
        "adapter": V15P_ADAPTER_PATH,
    }
    reviewed_inputs = review.get("reviewed_inputs")
    require(isinstance(reviewed_inputs, dict), "V15Q V9P reviewed inputs are missing")
    require_equal(set(reviewed_inputs), set(expected_review_artifacts), "V15Q V9P reviewed input inventory")
    for name, expected_path in expected_review_artifacts.items():
        record = reviewed_inputs[name]
        validate_artifact_record(root, record, f"V15Q V9P reviewed {name}", require_size=True)
        require_equal(record.get("path"), expected_path.as_posix(), f"V15Q V9P reviewed {name} path")

    conclusions = review.get("conclusions", {})
    expected_conclusions = {
        "historical_root_cause": "PASS_IMMUTABLE_9AC1",
        "legacy_independent_review": "PASS_VD4_F7A",
        "current_fix_source_binding": "PASS_BACKEND_BRIDGE_BYTE_IDENTICAL_TO_F7A",
        "current_v9r": "PASS_2_BASELINES_3_MUTATIONS",
        "adapter_terminal_path": "PASS_DIRECTED_AND_MUTATION_TIMING_GATE_FAIL",
        "layered_signoff": "PASS_L0_L1_L2_L3",
        "frozen_lane_claim": "UNKNOWN_PRESERVED",
        "assertion_policy": "PRESERVED_FAIL_LOUD_NO_DEDUP",
        "optional_ubuntu": "NOT_RUN_EXPLICIT_REQUEST_ONLY",
        "validation_depth": "VD4_REBOUND_CURRENT_DESIGN",
    }
    require_equal(conclusions, expected_conclusions, "V15Q V9P review conclusions")
    require_equal(
        review.get("review_boundary"),
        {
            "production_rtl_modified_by_review": False,
            "simulation_launched_by_review": False,
            "full_ubuntu_launched": False,
            "architecture_stable_claim": False,
            "ppa_claim": False,
            "timing_hard_gate": "FAIL_NOT_PROMOTABLE",
        },
        "V15Q V9P review boundary",
    )
    require_equal(
        review.get("unknowns"),
        [
            "immutable V9P instance bank is not retained",
            "immutable V9P kind/token/epoch owner tuple is not retained",
        ],
        "V15Q V9P review unknowns",
    )
    require_equal(review.get("counterexamples"), [], "V15Q V9P review counterexamples")
    require_equal(
        review.get("alternative_hypotheses"),
        [
            "a future Backend, Bridge or lane-adapter source-byte change requires a new current-design directed rebind"
        ],
        "V15Q V9P review alternatives",
    )
    require_equal(review.get("scope_extension_request"), None, "V15Q V9P scope extension")
    require_equal(review.get("gaps"), [], "V15Q V9P review gaps")
    result_text = safe_file(root, V9P_CURRENT_REBIND_RESULT_PATH).read_text(
        encoding="utf-8", errors="replace"
    )
    for marker in (
        "[V15Q-V9P-CURRENT-REBIND] PASS",
        "FROZEN_INSTANCE_LANE_PAIR=UNKNOWN",
        "FROZEN_INSTANCE_OWNER_TUPLE=UNKNOWN",
        "CURRENT_V9R=PASS_2_BASELINES_3_MUTATIONS",
        "ADAPTER_TIMING_HARD_GATE=FAIL_NOT_PROMOTABLE",
        "ASSERTION_POLICY=PRESERVED_FAIL_LOUD_NO_DEDUP",
        "GAPS=NONE",
    ):
        require(marker in result_text, f"V15Q V9P review result marker is absent: {marker}")


def validate_v9p_terminal_duplicate(
    root: pathlib.Path,
    historical: dict[str, Any],
    current: dict[str, Any],
    layered: dict[str, Any],
    legacy_review: dict[str, Any],
    current_rebind_review: dict[str, Any],
    design_id: str,
) -> dict[str, Any]:
    """Bind the immutable V9P C0/C1 counterexample to current RTL evidence."""
    try:
        verifier = load_module(
            safe_file(root, V15G_VERIFIER_PATH),
            "historical_defect_current_v9p_verifier",
        )
        frozen_expected = verifier.verify_frozen_failure(root)
        exact_expected = verifier.verify_exact_source(root)
        counterexamples = verifier.verify_counterexamples(root)
        legacy_fix = verifier.verify_current_fix(root, V15G_FIX_DESIGN_ID)
    except Exception as exc:
        raise HistoricalCurrentError(
            f"V9P immutable/root-cone verifier failed: {exc}"
        ) from exc

    historical_aggregate = historical.get("current_aggregate")
    require(isinstance(historical_aggregate, dict), "V9P layered aggregate snapshot is missing")
    historical_layered_artifact = historical_aggregate.get("receipt")
    require(
        isinstance(historical_layered_artifact, dict)
        and historical_layered_artifact.get("path") == LAYERED_SYSTEM_CURRENT_PATH.as_posix()
        and SHA256_RE.fullmatch(str(historical_layered_artifact.get("sha256", ""))) is not None
        and isinstance(historical_layered_artifact.get("size_bytes"), int)
        and historical_layered_artifact["size_bytes"] > 0,
        "V9P reviewed layered aggregate snapshot is malformed",
    )
    expected_historical = {
        "schema": "npc-rv64-v9p-terminal-root-cause-backfill-v1",
        "status": "PASS",
        "historical_failure": {
            "design_id": V9P_FROZEN_DESIGN_ID,
            "run_id": "2026-07-23-rv64-v9p-serialize-current-design/rootfs-flag-on-full",
            "marker": "[S2-G1-TCOLL-INGRESS-DUP]",
            **frozen_expected,
            "original_status_preserved": True,
        },
        "exact_source": exact_expected,
        "root_cause": {
            "classification": "C0_RETRY_HANDOFF_SPLIT_OWNERSHIP_THEN_C1_DUPLICATE_TERMINAL",
            "cycle_sequence": [
                "C0 full-flush barrier: V9P backend exposes retry credit, captures the MIQ owner into the bank-local retry holder and pops the MIQ",
                "C0 full-flush barrier: V9P bridge gives barrier retention priority and keeps the same S_SQ_QUERY owner",
                "C1 flush: retained bridge emits drop0 while the captured retry holder emits cancel for the same owner tuple",
            ],
            "exact_reproducible_pair_family": counterexamples["reproducible_lane_pairs"],
            "frozen_instance_lane_pair": "UNKNOWN_NOT_RETAINED_IN_IMMUTABLE_LOG",
            "frozen_instance_owner_tuple": "UNKNOWN_NOT_RETAINED_IN_IMMUTABLE_LOG",
            "pair_scope": "both symmetric banks are dynamically reproduced; the immutable run does not identify which bank fired",
            "counterexample_evidence": counterexamples,
        },
        "current_fix": {
            "design_id": V15G_FIX_DESIGN_ID,
            "rtl_file_count": 146,
            "contract": "C0 barrier suppresses both backend retry credit/capture and bridge retry fire; the bridge alone retains the owner until C1 flush",
            "mechanism": [
                "barrier gate on backend bank0 retry-ready",
                "barrier gate on backend bank1 retry-ready",
                "barrier gate on bridge SQ-query retry-fire",
            ],
            "assertion_policy": "fail-loud; no terminal deduplication, merge, waiver or assertion weakening",
            "focused_evidence": legacy_fix,
        },
        "current_aggregate": historical_aggregate,
        "cleanup": {
            "compiled_images_retained": 0,
            "retained": "bounded logs, negative RTL variants, source/hash receipts and result JSON",
        },
        "validation_depth_candidate": "VD4_PENDING_INDEPENDENT_REVIEW",
        "non_claims": [
            "the exact bank or owner tuple of the immutable V9P failure is known",
            "Ubuntu 22.04 or systemd full-rootfs recertification was run",
            "ARCH_STABLE, synthesis, STA, power, area, CPI or PPA promotion",
        ],
    }
    require_equal(historical, expected_historical, "V9P immutable root-cause summary")

    frozen = historical["historical_failure"]
    cause = historical["root_cause"]
    require_equal(legacy_review.get("schema"), "npc-rv64-v15g-independent-review-v1", "V15G review schema")
    require_equal(legacy_review.get("status"), "PASS", "V15G review status")
    require_equal(legacy_review.get("reviewed_design_id"), V15G_FIX_DESIGN_ID, "V15G reviewed design-id")
    validate_artifact_record(root, legacy_review.get("reviewed_summary"), "V15G reviewed summary", require_size=True)
    require_equal(
        legacy_review.get("reviewed_summary", {}).get("path"),
        HISTORICAL_V9P_ROOT_CAUSE_PATH.as_posix(),
        "V15G reviewed summary path",
    )
    legacy_conclusions = legacy_review.get("conclusions", {})
    require_equal(legacy_conclusions.get("exact_source_binding"), "PASS", "V15G exact-source review")
    require_equal(legacy_conclusions.get("root_cause"), "PASS", "V15G root-cause review")
    require_equal(legacy_conclusions.get("frozen_lane_claim"), "UNKNOWN_PRESERVED", "V15G frozen-lane review")
    require_equal(legacy_conclusions.get("current_fix"), "PASS", "V15G current-fix review")
    require_equal(legacy_conclusions.get("mutation_sensitivity"), "PASS", "V15G mutation review")
    require_equal(legacy_conclusions.get("layered_signoff"), "PASS_L0_L1_L2_L3", "V15G layered review")
    require_equal(legacy_conclusions.get("optional_ubuntu"), "NOT_RUN_EXPLICIT_REQUEST_ONLY", "V15G Ubuntu review")
    require_equal(legacy_conclusions.get("assertion_policy"), "PRESERVED_FAIL_LOUD", "V15G assertion review")
    require_equal(legacy_conclusions.get("validation_depth"), "VD4", "V15G validation-depth review")
    require_equal(legacy_review.get("gaps"), [], "V15G review gaps")

    require_equal(current.get("schema"), "npc-rv64-v9r-sq-retry-c0-current-v1", "V9R current schema")
    require_equal(current.get("status"), "PASS", "V9R current status")
    require_equal(current.get("design_id"), design_id, "V9R current design-id")
    # V9R stores path/hash only; validate exact live bytes without inventing size fields.
    for name, path in (("backend", V9P_BACKEND_PATH), ("bridge", V9P_BRIDGE_PATH)):
        record = current.get("production_sources", {}).get(name, {})
        require_equal(record.get("path"), path.as_posix(), f"V9R {name} source path")
        require_equal(record.get("sha256"), sha256_file(safe_file(root, path)), f"V9R {name} source SHA-256")
    baseline = current.get("baseline", {})
    require_equal(baseline.get("status"), "PASS", "V9R baseline")
    require_equal(baseline.get("backend_banks"), 2, "V9R backend banks")
    require_equal(baseline.get("forced_barrier_cases"), 2, "V9R forced barrier cases")
    for name, record in baseline.get("logs", {}).items():
        text = validate_retained_log(root, record, f"V9R baseline {name}")
        require("[PASS]" in text, f"V9R baseline {name} PASS marker is absent")
    variants = current.get("compile_success_rtl_variants", [])
    require_equal(
        [row.get("id") for row in variants],
        ["backend-bank0-ready-open", "backend-bank1-ready-open", "bridge-retry-fire-open"],
        "V9R current mutation inventory",
    )
    for row in variants:
        name = row.get("id")
        require_equal(row.get("result"), "REJECTED_COMPILE_SUCCESS_VARIANT", f"V9R {name} result")
        require_equal(row.get("make_return_code"), 2, f"V9R {name} return code")
        require_equal(row.get("compiled_image", {}).get("retained"), False, f"V9R {name} image retention")
        validate_artifact_record(root, row.get("mutated_rtl"), f"V9R {name} RTL")
        log = validate_retained_log(root, row.get("log"), f"V9R {name} log")
        marker = "[V9R-MEM-SQ-RETRY-C0-HANDOFF]" if name == "bridge-retry-fire-open" else "[V9R-SQ-RETRY-C0-HANDOFF]"
        require(marker in log, f"V9R {name} rejection marker is absent")
    require_equal(current.get("cleanup", {}).get("compiled_images_retained"), 0, "V9R retained images")

    require_equal(layered.get("schema"), "npc-rv64-layered-system-signoff-current-v1", "layered current schema")
    require_equal(layered.get("status"), "PASS", "layered current status")
    require_equal(layered.get("rtl_design_id"), design_id, "layered current design-id")
    expected_layers = ["L0_DIRECTED_RTL", "L1_FULL_CORE_DIFFTEST", "L2_MINI_SYSTEM", "L3_LIGHTWEIGHT_LINUX"]
    require_equal(layered.get("default_signoff_conjunction"), expected_layers, "layered default conjunction")
    for name in expected_layers:
        row = layered.get("layers", {}).get(name, {})
        require_equal(row.get("status"), "PASS", f"{name} status")
        require_equal(row.get("design_id"), design_id, f"{name} design-id")
    ubuntu = layered.get("optional_full_ubuntu", {})
    require_equal(ubuntu.get("status"), "NOT_RUN", "optional Ubuntu status")
    require_equal(ubuntu.get("blocks_default_signoff"), False, "optional Ubuntu gate")
    require_equal(ubuntu.get("launch_policy"), "explicit-user-request-only", "optional Ubuntu policy")

    adapter_metrics = validate_v15p_adapter_current(root, design_id)
    validate_v9p_current_rebind_review(root, current_rebind_review, design_id)
    return {
        "historical_design_id": frozen.get("design_id"),
        "legacy_fixed_design_id": V15G_FIX_DESIGN_ID,
        "historical_physical_assertion_events": 1,
        "immutable_frozen_lane_pair": "UNKNOWN",
        "immutable_frozen_owner_tuple": "UNKNOWN",
        "exact_reproducible_lane_pairs": {"bank0": [2, 10], "bank1": [4, 11]},
        "root_cause": cause.get("classification"),
        "current_design_id": design_id,
        "current_fix_sources": "BACKEND_BRIDGE_BYTE_IDENTICAL_TO_F7A",
        "current_baseline_profiles": "2/2",
        "current_compile_success_mutations": "3/3",
        "current_adapter_terminal_path": adapter_metrics,
        "current_default_signoff": "L0+L1+L2+L3",
        "optional_ubuntu": "NOT_RUN_EXPLICIT_REQUEST_ONLY",
        "compiled_images_retained": 0,
        "independent_review": "PASS_VD4_REBOUND_CURRENT_DESIGN",
    }


def build_receipt(root: pathlib.Path) -> dict[str, Any]:
    root = root.resolve()
    ledger = load_json(root, LEDGER_PATH)
    selected_id = ledger.get("selected_id")
    require_equal(
        selected_id,
        "NONE",
        "historical ledger selected blocker",
    )
    entries = ledger.get("entries")
    require(isinstance(entries, list), "historical ledger entries are missing")
    ledger_ids = {
        row.get("id")
        for row in entries
        if isinstance(row, dict) and isinstance(row.get("id"), str)
    }
    require_equal(
        ledger_ids,
        set(DEFECT_IDS),
        "current receipt tool defect inventory",
    )
    for row in entries:
        require_equal(
            row.get("status"),
            "BACKFILLED",
            f"{row.get('id')} ledger status before current receipt",
        )
    design_id, file_count = current_rtl_binding(root)
    require(DESIGN_ID_RE.fullmatch(design_id) is not None, "current RTL design-id is malformed")
    require_equal(file_count, RTL_FILE_COUNT, "current RTL file count")

    payloads = {
        name: load_json(root, path)
        for name, path in {
            "historical_qh": HISTORICAL_QH_PATH,
            "historical_stop": HISTORICAL_STOP_PATH,
            "v14e_qh": V14E_QH_PATH,
            "v14e_system": V14E_SYSTEM_PATH,
            "exit_current": EXIT_CURRENT_PATH,
            "historical_a3": HISTORICAL_A3_PATH,
            "historical_v8l": HISTORICAL_V8L_PATH,
            "holder_current": HOLDER_CURRENT_PATH,
            "historical_v9p": HISTORICAL_V9P_ROOT_CAUSE_PATH,
            "v9r_current": V9R_CURRENT_PATH,
            "layered_current": LAYERED_SYSTEM_CURRENT_PATH,
            "v15g_review": V15G_INDEPENDENT_REVIEW_PATH,
            "v15q_v9p_review": V9P_CURRENT_REBIND_REVIEW_PATH,
        }.items()
    }
    system_metrics = validate_layered_system_current(
        root, payloads["layered_current"], design_id
    )
    a3_checker_contract = validate_a3_checker_contract(root)
    metrics = {
        "HIST-SER-QH-YOUNGER-STORE-CYCLE": validate_qh_younger_store(
            root, payloads["historical_qh"], payloads["v14e_qh"], design_id
        ),
        "HIST-SER-QH-STOP-HOLD-DROP": validate_qh_stop_hold(
            root, payloads["historical_stop"], payloads["v14e_system"], design_id
        ),
        "HIST-EXIT-ACTIVE-MEM-EARLY-TERMINAL": {
            **validate_exit_current(root, payloads["exit_current"], design_id),
            "system_current": system_metrics,
        },
        "HIST-A3-DMESG-DEBUG-TOKEN": {
            **validate_a3(
                root,
                payloads["historical_a3"],
                a3_checker_contract,
                system_metrics,
            ),
        },
        "HIST-V8L-FORCE-RELEASE-SHADOW": validate_v8l(
            root, payloads["historical_v8l"], payloads["holder_current"], design_id
        ),
        "HIST-V9P-TERMINAL-COLLECTOR-INGRESS-DUP": validate_v9p_terminal_duplicate(
            root,
            payloads["historical_v9p"],
            payloads["v9r_current"],
            payloads["layered_current"],
            payloads["v15g_review"],
            payloads["v15q_v9p_review"],
            design_id,
        ),
    }

    schema = load_json(root, SCHEMA_PATH)
    require_equal(schema.get("$id"), "npc-rv64-historical-defect-current-v1.schema.json", "receipt schema id")
    require_equal(schema.get("properties", {}).get("schema", {}).get("const"), SCHEMA, "receipt schema const")
    receipt = {
        "schema": SCHEMA,
        "status": "PASS",
        "design_id": design_id,
        "rtl_file_count": file_count,
        "config_identity": {
            name: artifact(root, path)
            for name, path in sorted(CONFIG_PATHS.items())
        },
        "defect_ids": list(DEFECT_IDS),
        "defect_status": {defect_id: "BACKFILLED_CURRENT_DESIGN" for defect_id in DEFECT_IDS},
        "validation_depth": {defect_id: DEPTHS[defect_id] for defect_id in DEFECT_IDS},
        "support": {defect_id: SUPPORT[defect_id] for defect_id in DEFECT_IDS},
        "inputs": {name: artifact(root, path) for name, path in sorted(INPUT_PATHS.items())},
        "metrics": {defect_id: metrics[defect_id] for defect_id in DEFECT_IDS},
        "evidence_reuse_contract": {
            "execution_state": "ORIGINAL_STATUS_IMMUTABLE",
            "artifact_state": "TOP_LEVEL_RECEIPTS_PATH_SHA256_SIZE_BOUND_AND_RETAINED_LOGS_SHA256_BOUND",
            "build_product_state": "REGENERABLE_SIMULATOR_IMAGES_REMOVED_AFTER_HASH_RECEIPT",
            "compile_sidefile_state": "REMOVED_ZERO_RC_HASH_RECEIPT_CROSSCHECKED_WITH_RETAINED_TB_LOG",
            "shared_system_dependency": "LAYERED_SIGNOFF_AND_CURRENT_CHECKER_CONTRACT_REQUIRED",
            "assertion_state": "POSITIVE_ZERO_FAILURE_AND_COMPILE_SUCCESS_NEGATIVE_REJECTION_REQUIRED",
            "oracle_state": "VERSIONED_REPLAY_WITH_KNOWN_GOOD_AND_EXPECTED_FAIL_FIXTURES",
            "replay_state": "ONLY_TARGETED_HISTORICAL_RTL_AND_ORACLE_REPLAYS",
            "full_system_rerun": False,
            "rerun_on": [
                "production_or_elaborated_rtl_change_in_the_bound_owner_cone",
                "active_device_model_host_harness_or_simulator_semantics_change",
                "configuration_workload_or_frozen_input_identity_change",
                "missing_raw_terminal_assertion_or_post_hash_evidence",
                "mutation_anchor_or_expected_rejection_marker_drift",
            ],
        },
        "promotion": {
            "historical_defect_ledger": "BACKFILLED_CURRENT_DESIGN",
            "whole_architecture": "RED",
            "ppa": "UNPROMOTED",
        },
    }
    jsonschema.Draft202012Validator(schema).validate(receipt)
    return receipt


def receipt_ledger_artifact(root: pathlib.Path) -> dict[str, str]:
    record = artifact(root, RECEIPT_PATH)
    return {"path": record["path"], "sha256": record["sha256"]}


def validate_ledger_payload(
    root: pathlib.Path,
    ledger: dict[str, Any],
    receipt: dict[str, Any],
) -> None:
    require_equal(ledger.get("schema"), LEDGER_SCHEMA, "historical ledger schema")
    require_equal(ledger.get("design_id"), receipt.get("design_id"), "historical ledger design-id")
    expected_revision = (
        f"v15q-current-{receipt['design_id'].removeprefix('sha256:')[:8]}-"
        "historical-defect-vd4-rebind"
    )
    require_equal(ledger.get("revision"), expected_revision, "historical ledger revision")
    require_equal(ledger.get("selected_id"), "NONE", "historical ledger selected id")
    entries = ledger.get("entries")
    require(isinstance(entries, list), "historical ledger entries are missing")
    entry_map = {
        row.get("id"): row
        for row in entries
        if isinstance(row, dict) and isinstance(row.get("id"), str)
    }
    require_equal(len(entry_map), len(entries), "historical ledger duplicate or malformed entry")
    require_equal(set(entry_map), set(DEFECT_IDS), "historical ledger membership")
    pointer = receipt_ledger_artifact(root)
    for defect_id in DEFECT_IDS:
        entry = entry_map[defect_id]
        require_equal(entry.get("status"), "BACKFILLED", f"{defect_id} ledger status")
        require_equal(entry.get("validation_depth"), DEPTHS[defect_id], f"{defect_id} validation depth")
        require_equal(entry.get("current_evidence"), [pointer], f"{defect_id} current receipt pointer")
        require_equal(receipt.get("defect_status", {}).get(defect_id), "BACKFILLED_CURRENT_DESIGN", f"{defect_id} receipt status")
        require_equal(receipt.get("support", {}).get(defect_id), SUPPORT[defect_id], f"{defect_id} support")
        require(any(receipt["design_id"] in text for text in entry.get("depth_basis", []) if isinstance(text, str)), f"{defect_id} current design-id depth basis is missing")
        for owner in entry.get("owner_paths", []):
            safe_file(root, owner)
        for record in entry.get("source_artifacts", []):
            require_equal(
                sha256_file(safe_file(root, record.get("path", ""))),
                record.get("sha256"),
                f"{defect_id} source artifact",
            )
    require_equal(receipt.get("promotion"), {
        "historical_defect_ledger": "BACKFILLED_CURRENT_DESIGN",
        "whole_architecture": "RED",
        "ppa": "UNPROMOTED",
    }, "historical receipt promotion boundary")


def validate_receipt_payload(actual: dict[str, Any], expected: dict[str, Any]) -> None:
    require_equal(actual, expected, "current historical-defect receipt")


def write_json(path: pathlib.Path, payload: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = path.with_suffix(path.suffix + ".tmp")
    temporary.write_text(
        json.dumps(payload, ensure_ascii=False, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )
    temporary.replace(path)


def rebind_ledger_receipt(
    root: pathlib.Path, ledger_path: pathlib.Path,
) -> dict[str, Any]:
    try:
        ledger_relative = ledger_path.resolve().relative_to(root.resolve()).as_posix()
    except (OSError, ValueError) as exc:
        raise HistoricalCurrentError(
            "historical defect ledger escapes repository") from exc
    ledger = load_json(root, ledger_relative)
    entries = ledger.get("entries")
    require(isinstance(entries, list), "historical ledger entries are missing")
    entry_map = {
        row.get("id"): row
        for row in entries
        if isinstance(row, dict) and isinstance(row.get("id"), str)
    }
    require_equal(set(entry_map), set(DEFECT_IDS), "historical ledger membership")
    receipt = load_json(root, RECEIPT_PATH)
    design_id = receipt.get("design_id")
    require(
        isinstance(design_id, str) and DESIGN_ID_RE.fullmatch(design_id) is not None,
        "historical receipt design-id is malformed",
    )
    ledger["design_id"] = design_id
    ledger["revision"] = (
        f"v15q-current-{design_id.removeprefix('sha256:')[:8]}-"
        "historical-defect-vd4-rebind"
    )
    pointer = receipt_ledger_artifact(root)
    layered_pointer = {
        "path": LAYERED_SYSTEM_CURRENT_PATH.as_posix(),
        "sha256": sha256_file(safe_file(root, LAYERED_SYSTEM_CURRENT_PATH)),
    }
    for defect_id in DEFECT_IDS:
        entry_map[defect_id]["current_evidence"] = [dict(pointer)]
        depth_basis = entry_map[defect_id].get("depth_basis")
        require(isinstance(depth_basis, list), f"{defect_id} depth basis is missing")
        if not any(design_id in text for text in depth_basis if isinstance(text, str)):
            if defect_id == "HIST-V9P-TERMINAL-COLLECTOR-INGRESS-DUP":
                depth_basis.append(
                    "The V15Q current-design receipt binds unchanged OooIntBackend/OooMemAxiBridge "
                    "fix bytes, the current V9R 2/2 baseline and 3/3 compile-success negative RTL "
                    "versions, the independently reviewed adapter terminal path and L0-L3 evidence "
                    f"to {design_id}; the immutable bank and kind/token/epoch tuple remain UNKNOWN, "
                    "the 5 ns timing hard gate remains FAIL_NOT_PROMOTABLE, and no terminal-event "
                    "deduplication or assertion weakening is permitted."
                )
            else:
                depth_basis.append(
                    "The V15Q six-defect current receipt revalidates the directed positive, "
                    "compile-success negative and layered-system evidence on "
                    f"{design_id} without rewriting historical execution status or claiming "
                    "ARCH_STABLE or PPA promotion."
                )
        source_artifacts = entry_map[defect_id].get("source_artifacts", [])
        for index, record in enumerate(source_artifacts):
            if (
                isinstance(record, dict)
                and record.get("path") == LAYERED_SYSTEM_CURRENT_PATH.as_posix()
            ):
                source_artifacts[index] = dict(layered_pointer)
    write_json(ledger_path, ledger)
    return ledger


@functools.lru_cache(maxsize=4)
def _cached_expected(root_text: str) -> dict[str, Any]:
    return build_receipt(pathlib.Path(root_text))


def validate_current_contract(
    root: pathlib.Path,
    ledger: dict[str, Any] | None = None,
    expected_design_id: str | None = None,
) -> dict[str, Any]:
    root = root.resolve()
    actual = load_json(root, RECEIPT_PATH)
    expected = _cached_expected(str(root))
    validate_receipt_payload(actual, expected)
    if expected_design_id is not None:
        require_equal(actual.get("design_id"), expected_design_id, "caller design-id")
    if ledger is None:
        ledger = load_json(root, LEDGER_PATH)
    validate_ledger_payload(root, ledger, actual)
    return actual


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", type=pathlib.Path, default=pathlib.Path(__file__).resolve().parents[5])
    subparsers = parser.add_subparsers(dest="command", required=True)
    build = subparsers.add_parser("build")
    build.add_argument("--output", type=pathlib.Path, default=pathlib.Path(RECEIPT_PATH))
    refresh = subparsers.add_parser(
        "refresh",
        help="atomically rebuild the receipt and rebind all historical ledger pointers",
    )
    refresh.add_argument(
        "--output", type=pathlib.Path, default=pathlib.Path(RECEIPT_PATH))
    refresh.add_argument(
        "--ledger", type=pathlib.Path, default=pathlib.Path(LEDGER_PATH))
    verify = subparsers.add_parser("verify")
    verify.add_argument("--input", type=pathlib.Path, default=pathlib.Path(RECEIPT_PATH))
    verify.add_argument("--ledger", type=pathlib.Path, default=pathlib.Path(LEDGER_PATH))
    verify.add_argument("--expected-design-id")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    root = args.root.resolve()
    try:
        if args.command in {"build", "refresh"}:
            output = args.output if args.output.is_absolute() else root / args.output
            payload = build_receipt(root)
            write_json(output, payload)
            if args.command == "refresh":
                ledger_path = (
                    args.ledger if args.ledger.is_absolute()
                    else root / args.ledger)
                ledger = rebind_ledger_receipt(root, ledger_path.resolve())
                validate_receipt_payload(payload, build_receipt(root))
                validate_ledger_payload(root, ledger, payload)
        else:
            input_path = args.input if args.input.is_absolute() else root / args.input
            ledger_path = args.ledger if args.ledger.is_absolute() else root / args.ledger
            actual = load_json(root, input_path.relative_to(root).as_posix())
            expected = build_receipt(root)
            validate_receipt_payload(actual, expected)
            if args.expected_design_id is not None:
                require_equal(actual.get("design_id"), args.expected_design_id, "caller design-id")
            ledger = load_json(root, ledger_path.relative_to(root).as_posix())
            validate_ledger_payload(root, ledger, actual)
            payload = actual
    except (HistoricalCurrentError, OSError, ValueError, jsonschema.ValidationError) as exc:
        print(f"[HISTORICAL-DEFECT-CURRENT][FAIL] {exc}", file=sys.stderr)
        return 2
    print(
        "[HISTORICAL-DEFECT-CURRENT] "
        f"status={payload['status']} defects={len(payload['defect_ids'])}/{len(DEFECT_IDS)} "
        f"design_id={payload['design_id']} whole_architecture=RED ppa=UNPROMOTED"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
