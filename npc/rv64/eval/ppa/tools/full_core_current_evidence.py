#!/usr/bin/env python3
"""Build compact, current-design RV64 full-core evidence slices.

The first slice is the complete module-test inventory.  Compiled images live
only in a task-owned temporary directory; the durable surface contains
normalized logs, exact input snapshots, a result JSON, and a fail-closed
status receipt.  Later cohort stages can consume the same module result
without recompiling all testbenches for every architecture debt checker.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import pathlib
import re
import shutil
import signal
import subprocess
import sys
import tempfile
from typing import Any


ROOT = pathlib.Path(__file__).resolve().parents[5]
TOOLS_DIR = ROOT / "npc/rv64/eval/ppa/tools"
if str(TOOLS_DIR) not in sys.path:
    sys.path.insert(0, str(TOOLS_DIR))

import architecture_hard_gates as architecture  # noqa: E402
import arch_stable_freeze as freeze  # noqa: E402


SCHEMA = "npc-rv64-full-core-module-current-evidence-v1"
STATUS_SCHEMA = "npc-rv64-evidence-stage-status-v1"
TASK_RUN_ROOT = ROOT / ".github/task-runs"
MAKE_ENV_KEYS = (
    "MAKEFLAGS",
    "MFLAGS",
    "MAKELEVEL",
    "GNUMAKEFLAGS",
    "MAKEFILES",
)


def sha256_file(path: pathlib.Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def lexical_repo_file(path: pathlib.Path) -> pathlib.Path:
    """Return one regular repository file without dereferencing path aliases."""
    candidate = path if path.is_absolute() else ROOT / path
    root = ROOT.resolve(strict=True)
    lexical = pathlib.Path(os.path.abspath(os.fspath(candidate)))
    try:
        parts = lexical.relative_to(root).parts
    except ValueError as exc:
        raise RuntimeError(f"path escapes repository root: {path}") from exc
    cursor = root
    for part in parts:
        cursor = cursor / part
        if cursor.is_symlink():
            raise RuntimeError(f"path contains a symlink: {path}")
    if not lexical.is_file():
        raise RuntimeError(f"path is not a regular repository file: {path}")
    return lexical


def relative(path: pathlib.Path) -> str:
    return lexical_repo_file(path).relative_to(ROOT.resolve(strict=True)).as_posix()


def write_json(path: pathlib.Path, value: Any) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(
        json.dumps(
            value,
            ensure_ascii=False,
            allow_nan=False,
            indent=2,
            sort_keys=True,
        )
        + "\n",
        encoding="utf-8",
    )


def normalize_text(text: str, *, temporary_root: pathlib.Path) -> str:
    normalized = text.replace(str(ROOT), "<REPO>")
    normalized = normalized.replace(str(temporary_root), "<FULL_CORE_CURRENT_TEMP>")
    return normalized


def artifact(path: pathlib.Path, *, kind: str) -> dict[str, Any]:
    resolved = lexical_repo_file(path)
    return {
        "kind": kind,
        "path": relative(resolved),
        "sha256": sha256_file(resolved),
        "size_bytes": resolved.stat().st_size,
    }


def safe_output_dir(raw: pathlib.Path) -> pathlib.Path:
    candidate = raw if raw.is_absolute() else ROOT / raw
    task_root = TASK_RUN_ROOT.resolve(strict=True)
    lexical = pathlib.Path(os.path.abspath(os.fspath(candidate)))
    try:
        parts = lexical.relative_to(task_root).parts
    except ValueError as exc:
        raise RuntimeError(f"output escapes task-run root: {raw}") from exc
    if not parts:
        raise RuntimeError("output must be a task-run subdirectory")
    cursor = task_root
    for index, part in enumerate(parts):
        cursor = cursor / part
        if cursor.is_symlink():
            raise RuntimeError(f"output path contains a symlink: {cursor}")
        if index < len(parts) - 1 and cursor.exists() and not cursor.is_dir():
            raise RuntimeError(f"output ancestor is not a directory: {cursor}")
    if lexical.exists():
        raise RuntimeError(
            f"output already exists; use a new attempt directory: {lexical}"
        )
    return lexical


def required_tests() -> list[str]:
    makefile = ROOT / "npc/rv64/testbench/Makefile"
    tests, errors = freeze.parse_required_tests(
        makefile.read_text(encoding="utf-8")
    )
    if errors:
        raise RuntimeError("module TESTS inventory is invalid: " + "; ".join(errors))
    return tests


def capture_inputs(tests: list[str]) -> dict[str, Any]:
    # producer 与 ARCH_STABLE consumer 共用同一闭包定义，避免清单静默漂移。
    return freeze.f0_capture_module_inputs(ROOT, tests, architecture)


def validate_module_log(text: str, *, test_id: str, design_id: str) -> list[str]:
    lines = text.splitlines()
    accepted_native_pass = (f"PASS {test_id}", f"[PASS] {test_id}")
    native_pass_count = sum(lines.count(marker) for marker in accepted_native_pass)
    required_exact = (f"[RTL-DESIGN-ID] {design_id}", "[RESULT] PASS")
    errors = [
        f"{test_id}: marker count for {marker!r} is {lines.count(marker)}"
        for marker in required_exact
        if lines.count(marker) != 1
    ]
    if native_pass_count != 1:
        errors.append(
            f"{test_id}: accepted native PASS line count is {native_pass_count}"
        )
    if any(line.startswith("[RESULT] FAIL") for line in lines):
        errors.append(f"{test_id}: contains [RESULT] FAIL")
    return errors


def write_status(
    output_dir: pathlib.Path,
    *,
    state: str,
    stage: str,
    detail: str,
    design_id: str | None = None,
) -> None:
    value = {
        "schema": STATUS_SCHEMA,
        "state": state,
        "stage": stage,
        "detail": detail,
        "design_id": design_id,
    }
    write_json(output_dir / "status.json", value)


def sanitized_environment() -> dict[str, str]:
    env = os.environ.copy()
    for key in MAKE_ENV_KEYS:
        env.pop(key, None)
    env["PYTHONDONTWRITEBYTECODE"] = "1"
    return env


def run_module(output_raw: pathlib.Path, *, jobs: int) -> int:
    output_dir = safe_output_dir(output_raw)
    output_dir.mkdir(parents=True)
    stage = "input-binding"
    design_id: str | None = None
    interrupted_signal: int | None = None

    def on_signal(signum: int, _frame: Any) -> None:
        nonlocal interrupted_signal
        interrupted_signal = signum
        write_status(
            output_dir,
            state="FAIL",
            stage=stage,
            detail=f"signal={signum}",
            design_id=design_id,
        )
        raise SystemExit(128 + signum)

    previous_handlers = {
        signum: signal.getsignal(signum)
        for signum in (signal.SIGHUP, signal.SIGINT, signal.SIGTERM)
    }
    for signum in previous_handlers:
        signal.signal(signum, on_signal)

    try:
        tests = required_tests()
        pre = capture_inputs(tests)
        design_id = pre["design_id"]
        write_json(output_dir / "inputs.pre.json", pre)
        write_status(
            output_dir,
            state="RUNNING",
            stage=stage,
            detail=f"tests={len(tests)}",
            design_id=design_id,
        )

        payload: dict[str, Any]
        with tempfile.TemporaryDirectory(prefix="rv64-full-core-current-") as raw_temp:
            temporary_root = pathlib.Path(raw_temp)
            build_dir = temporary_root / "build"
            result_dir = temporary_root / "result"
            raw_make_log = temporary_root / "module-make.log"
            stage = "module-simulation"
            write_status(
                output_dir,
                state="RUNNING",
                stage=stage,
                detail=f"tests={len(tests)} jobs={jobs}",
                design_id=design_id,
            )
            command = [
                "/usr/bin/make",
                "--no-print-directory",
                "-B",
                f"-j{jobs}",
                "-C",
                str(ROOT / "npc/rv64/testbench"),
                f"BUILD_DIR={build_dir}",
                f"RESULT_DIR={result_dir}",
                f"RTL_EVIDENCE_SHA={design_id.removeprefix('sha256:')}",
                "run",
            ]
            with raw_make_log.open("w", encoding="utf-8") as handle:
                completed = subprocess.run(
                    command,
                    cwd=ROOT,
                    env=sanitized_environment(),
                    stdout=handle,
                    stderr=subprocess.STDOUT,
                    check=False,
                    text=True,
                )
            (output_dir / "module-make.log").write_text(
                normalize_text(
                    raw_make_log.read_text(encoding="utf-8", errors="replace"),
                    temporary_root=temporary_root,
                ),
                encoding="utf-8",
            )
            if completed.returncode != 0:
                raise RuntimeError(
                    f"module make returned {completed.returncode}; "
                    "see module-make.log"
                )

            stage = "module-log-validation"
            raw_logs = sorted((result_dir / "logs").glob("tb_*.log"))
            by_name = {path.stem: path for path in raw_logs}
            if set(by_name) != set(tests):
                raise RuntimeError(
                    "module log inventory mismatch: "
                    f"missing={sorted(set(tests) - set(by_name))[:8]} "
                    f"extra={sorted(set(by_name) - set(tests))[:8]}"
                )
            durable_logs = output_dir / "logs"
            durable_logs.mkdir()
            log_artifacts: dict[str, dict[str, Any]] = {}
            validation_errors: list[str] = []
            for test_id in tests:
                text = by_name[test_id].read_text(
                    encoding="utf-8", errors="replace"
                )
                validation_errors.extend(
                    validate_module_log(text, test_id=test_id, design_id=design_id)
                )
                destination = durable_logs / f"{test_id}.log"
                destination.write_text(
                    normalize_text(text, temporary_root=temporary_root),
                    encoding="utf-8",
                )
                log_artifacts[test_id] = artifact(
                    destination, kind="module_test_log"
                )
            if validation_errors:
                raise RuntimeError("; ".join(validation_errors[:6]))

            summary_source = result_dir / "summary.txt"
            summary_destination = output_dir / "summary.txt"
            summary_destination.write_text(
                normalize_text(
                    summary_source.read_text(encoding="utf-8"),
                    temporary_root=temporary_root,
                ),
                encoding="utf-8",
            )
            post = capture_inputs(tests)
            write_json(output_dir / "inputs.post.json", post)
            if post != pre:
                raise RuntimeError("RTL/test/workflow inputs drifted during module run")
            if list(output_dir.rglob("*.vvp")):
                raise RuntimeError("compiled image leaked into durable output")
            payload = {
                "schema": SCHEMA,
                "status": "PASS",
                "design_id": design_id,
                "tests": {
                    "required": len(tests),
                    "passed": len(log_artifacts),
                    "inventory": tests,
                    "logs": log_artifacts,
                },
                "command": normalize_text(
                    " ".join(command), temporary_root=temporary_root
                ),
                "inputs": {
                    "pre": artifact(
                        output_dir / "inputs.pre.json", kind="input_binding"
                    ),
                    "post": artifact(
                        output_dir / "inputs.post.json", kind="input_binding"
                    ),
                    "unchanged": True,
                },
                "artifacts": {
                    "summary": artifact(
                        summary_destination, kind="module_test_summary"
                    ),
                    "make_log": artifact(
                        output_dir / "module-make.log", kind="module_make_log"
                    ),
                },
                "retention": {
                    "compiled_images_retained": 0,
                    "compiled_images_location": "task-owned temporary directory",
                },
            }

        stage = "publish-result"
        write_json(output_dir / "result.json", payload)
        write_status(
            output_dir,
            state="PASS",
            stage="complete",
            detail=f"tests={payload['tests']['passed']}/{payload['tests']['required']}",
            design_id=design_id,
        )
        print(
            "[FULL-CORE-MODULE-CURRENT][PASS] "
            f"design_id={design_id} "
            f"tests={payload['tests']['passed']}/{payload['tests']['required']} "
            "retained_vvp=0"
        )
        return 0
    except (OSError, RuntimeError, ValueError, json.JSONDecodeError) as exc:
        if interrupted_signal is None:
            write_status(
                output_dir,
                state="FAIL",
                stage=stage,
                detail=str(exc),
                design_id=design_id,
            )
            print(f"[FULL-CORE-MODULE-CURRENT][FAIL] {exc}", file=sys.stderr)
        return 1
    finally:
        for signum, handler in previous_handlers.items():
            signal.signal(signum, handler)


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Build compact current-design RV64 full-core evidence"
    )
    subparsers = parser.add_subparsers(dest="command", required=True)
    module = subparsers.add_parser("module", help="run the complete module inventory")
    module.add_argument("--output-dir", required=True, type=pathlib.Path)
    module.add_argument("--jobs", type=int, default=2)
    args = parser.parse_args()
    if args.command == "module":
        if args.jobs < 1 or args.jobs > 8:
            parser.error("--jobs must be in [1, 8]")
        return run_module(args.output_dir, jobs=args.jobs)
    parser.error(f"unknown command: {args.command}")
    return 2


if __name__ == "__main__":
    raise SystemExit(main())
