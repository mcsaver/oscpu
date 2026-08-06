#!/usr/bin/env python3
"""Build one current-design RV64 functional aggregate without module reruns.

The runner consumes a completed full module-inventory result, builds one
DiffTest-enabled simulator, and executes the exact official, AM, DiffTest,
CoreMark, and Dhrystone cohorts. Simulator build intermediates are temporary;
frozen binaries, images, logs, and aggregate JSON are durable cohort inputs.
"""

from __future__ import annotations

import argparse
import hashlib
import importlib.util
import json
import os
import pathlib
import shlex
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
import full_core_current_evidence as module_evidence  # noqa: E402


SCHEMA = "npc-rv64-full-core-functional-current-evidence-v1"
PUBLICATION_SCHEMA = "npc-rv64-full-core-functional-current-publication-v1"
COHORT_ID = "full-core-single-hart-rv64-dual-issue-ooo-v1"
LEGACY_RUNNER = ROOT / (
    ".github/task-runs/2026-07-22-rv64-v9l-functional-aggregate-current-design/"
    "run-functional-aggregate.py"
)
CANONICAL_AGGREGATE = (
    ROOT / "npc/rv64/eval/ppa/evidence/functional-aggregate-current.json"
)
CANONICAL_RESULT = (
    ROOT / "npc/rv64/eval/ppa/evidence/functional-aggregate-result.json"
)
CANONICAL_LOG = ROOT / "npc/rv64/eval/ppa/evidence/functional-aggregate.log"
CANONICAL_BINDING = (
    ROOT
    / "npc/rv64/eval/ppa/evidence/functional-aggregate-current.binding.json"
)
GENERATED_INPUT_PARTS = frozenset({
    ".git", ".cache", "__pycache__", "build", "obj_dir",
})
GENERATED_INPUT_NAMES = frozenset({".result"})
GENERATED_INPUT_SUFFIXES = frozenset({
    ".a", ".bin", ".dump", ".elf", ".o", ".so", ".vvp",
})


def load_legacy_runner() -> Any:
    spec = importlib.util.spec_from_file_location(
        "rv64_full_core_functional_legacy_runner", LEGACY_RUNNER
    )
    if spec is None or spec.loader is None:
        raise RuntimeError(f"cannot load functional runner: {LEGACY_RUNNER}")
    module = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    return module


def load_json(path: pathlib.Path) -> dict[str, Any]:
    if path.is_symlink() or not path.is_file():
        raise RuntimeError(f"JSON input is not a regular file: {path}")
    value = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(value, dict):
        raise RuntimeError(f"expected JSON object: {path}")
    return value


def lexical_regular_file(raw: pathlib.Path) -> pathlib.Path:
    """Return a regular file while preserving and checking every path component."""
    lexical = pathlib.Path(os.path.abspath(os.fspath(raw)))
    cursor = pathlib.Path(lexical.anchor)
    for part in lexical.parts[1:]:
        cursor = cursor / part
        if cursor.is_symlink():
            raise RuntimeError(f"input path contains a symlink: {raw}")
    if not lexical.is_file():
        raise RuntimeError(f"input is not a regular file: {raw}")
    return lexical


def lexical_output_file(raw: pathlib.Path, *, root: pathlib.Path) -> pathlib.Path:
    """Validate a repository/output file path without resolving any alias."""
    root_resolved = root.resolve(strict=True)
    candidate = raw if raw.is_absolute() else root_resolved / raw
    lexical = pathlib.Path(os.path.abspath(os.fspath(candidate)))
    try:
        parts = lexical.relative_to(root_resolved).parts
    except ValueError as exc:
        raise RuntimeError(f"output escapes allowed root: {raw}") from exc
    if not parts:
        raise RuntimeError(f"output must be below allowed root: {raw}")
    cursor = root_resolved
    for index, part in enumerate(parts):
        cursor = cursor / part
        if cursor.is_symlink():
            raise RuntimeError(f"output path contains a symlink: {raw}")
        if index < len(parts) - 1 and cursor.exists() and not cursor.is_dir():
            raise RuntimeError(f"output ancestor is not a directory: {cursor}")
    if lexical.exists() and not lexical.is_file():
        raise RuntimeError(f"output is not a regular file: {raw}")
    return lexical


def resolve_repo_file(raw: pathlib.Path) -> pathlib.Path:
    candidate = raw if raw.is_absolute() else ROOT / raw
    root = ROOT.resolve(strict=True)
    lexical = lexical_regular_file(candidate)
    try:
        lexical.relative_to(root)
    except ValueError as exc:
        raise RuntimeError(f"input escapes repository root: {raw}") from exc
    return lexical


def verify_artifact(entry: Any, *, kind: str | None = None) -> pathlib.Path:
    if not isinstance(entry, dict) or not {"path", "sha256"} <= set(entry):
        raise RuntimeError("artifact entry is missing path/sha256")
    if kind is not None and entry.get("kind") != kind:
        raise RuntimeError(
            f"artifact kind mismatch: expected={kind} observed={entry.get('kind')}"
        )
    path = resolve_repo_file(pathlib.Path(str(entry["path"])))
    observed = module_evidence.sha256_file(path)
    if observed != entry.get("sha256"):
        raise RuntimeError(f"artifact hash drifted: {entry['path']}")
    if "size_bytes" in entry and path.stat().st_size != entry.get("size_bytes"):
        raise RuntimeError(f"artifact size drifted: {entry['path']}")
    return path


def verify_exact_run_artifact(
    entry: Any, *, kind: str, expected_path: pathlib.Path
) -> pathlib.Path:
    """Verify one four-field durable receipt at its canonical run-local path."""
    if not isinstance(entry, dict) or set(entry) != {
        "kind", "path", "sha256", "size_bytes"
    }:
        raise RuntimeError(f"{kind} artifact field set differs from run contract")
    path = verify_artifact(entry, kind=kind)
    expected = resolve_repo_file(expected_path)
    if path != expected:
        raise RuntimeError(
            f"{kind} artifact points outside the owning run: {entry.get('path')}"
        )
    return path


def extract_wrapped_source_bytes(path: pathlib.Path, *, label: str) -> bytes:
    """Extract one byte-exact source-log section from a canonical LF wrapper."""
    data = path.read_bytes()
    begin_token = b"[SOURCE-LOG-BEGIN]\n"
    end_token = b"[SOURCE-LOG-END]\n"
    if data.count(begin_token) != 1 or data.count(end_token) != 1:
        raise RuntimeError(f"{label} wrapper source-log markers are not exact")
    begin = data.index(begin_token) + len(begin_token)
    end = data.index(end_token, begin)
    if begin >= end:
        raise RuntimeError(f"{label} wrapper source-log markers are not ordered")
    source = data[begin:end]
    if not source:
        raise RuntimeError(f"{label} wrapper source-log section is empty")
    return source


def extract_wrapped_source_log(path: pathlib.Path, *, label: str) -> str:
    try:
        return extract_wrapped_source_bytes(path, label=label).decode("utf-8")
    except UnicodeError as exc:
        raise RuntimeError(f"{label} wrapper source-log section is not UTF-8") from exc


def verify_wrapped_source_log(
    wrapper_path: pathlib.Path,
    *,
    expected_source_path: pathlib.Path,
    label: str,
) -> str:
    """Bind a wrapper source section to its retained same-run raw log."""
    source_path = resolve_repo_file(expected_source_path)
    wrapper_bytes = wrapper_path.read_bytes()
    wrapper_lines = wrapper_bytes.splitlines()
    expected_path_marker = f"source_log_path={module_evidence.relative(source_path)}"
    expected_hash_marker = (
        f"source_log_sha256={module_evidence.sha256_file(source_path)}"
    )
    if wrapper_lines.count(expected_path_marker.encode("utf-8")) != 1:
        raise RuntimeError(f"{label} wrapper raw-log path binding is not exact")
    if wrapper_lines.count(expected_hash_marker.encode("utf-8")) != 1:
        raise RuntimeError(f"{label} wrapper raw-log hash binding is not exact")
    source_bytes = extract_wrapped_source_bytes(wrapper_path, label=label)
    retained_bytes = source_path.read_bytes()
    if source_bytes != retained_bytes:
        raise RuntimeError(
            f"{label} wrapper source bytes differ from retained raw log"
        )
    try:
        return source_bytes.decode("utf-8")
    except UnicodeError as exc:
        raise RuntimeError(f"{label} retained raw log is not UTF-8") from exc


def collect_repository_files(
    root: pathlib.Path, entries: list[pathlib.Path]
) -> list[str]:
    """Return a deterministic source/control-file set without build products."""
    return module_evidence.freeze.f0_collect_repository_files(root, entries)


def repository_input_is_generated(path: pathlib.Path) -> bool:
    """Recognize build products that may live beside official test sources."""
    return module_evidence.freeze.f0_repository_input_is_generated(path)


def capture_functional_inputs(legacy: Any, tests: list[str]) -> dict[str, Any]:
    """Bind execution controls and reconstructable program/reference sources."""
    del legacy  # 路径身份统一由共享采集器从工作区真源解析。
    return module_evidence.freeze.f0_capture_functional_inputs(
        ROOT, tests, architecture
    )


def module_payload_contract_errors(value: Any) -> list[str]:
    errors: list[str] = []
    payload = value if isinstance(value, dict) else {}
    tests = payload.get("tests") if isinstance(payload.get("tests"), dict) else {}
    inputs = payload.get("inputs") if isinstance(payload.get("inputs"), dict) else {}
    if set(payload) != {
        "schema", "status", "design_id", "tests", "command", "inputs",
        "artifacts", "retention",
    }:
        errors.append("module result field set differs from exact contract")
    if set(tests) != {"required", "passed", "inventory", "logs"}:
        errors.append("module tests field set differs from exact contract")
    if set(inputs) != {"pre", "post", "unchanged"}:
        errors.append("module input receipt field set differs from exact contract")
    if payload.get("schema") != module_evidence.SCHEMA:
        errors.append("module result schema mismatch")
    if payload.get("status") != "PASS":
        errors.append("module result is not PASS")
    design_id = payload.get("design_id")
    if not isinstance(design_id, str) or not design_id.startswith("sha256:"):
        errors.append("module result design_id is invalid")
    inventory = tests.get("inventory")
    logs = tests.get("logs")
    if not isinstance(inventory, list) or not inventory:
        errors.append("module test inventory is empty")
    if not isinstance(logs, dict):
        errors.append("module log map is missing")
    elif isinstance(inventory, list) and set(logs) != set(inventory):
        errors.append("module log map differs from inventory")
    required = tests.get("required")
    passed = tests.get("passed")
    if not isinstance(inventory, list) or required != len(inventory) or passed != required:
        errors.append("module required/passed counts are inconsistent")
    if inputs.get("unchanged") is not True:
        errors.append("module input binding is not unchanged")
    return errors


def module_input_binding_errors(
    value: Any, *, expected_design_id: str, expected_tests: list[str]
) -> list[str]:
    binding = value if isinstance(value, dict) else {}
    errors: list[str] = []
    if set(binding) != {"schema", "design_id", "required_tests", "groups"}:
        errors.append("module input binding field set differs from exact contract")
    if binding.get("schema") != "npc-rv64-full-core-module-input-binding-v1":
        errors.append("module input binding schema mismatch")
    if binding.get("design_id") != expected_design_id:
        errors.append("module input binding design_id mismatch")
    if binding.get("required_tests") != expected_tests:
        errors.append("module input binding required_tests mismatch")
    groups = binding.get("groups")
    expected_groups = {
        "rtl", "generated_headers", "filelists", "test_sources", "workflow"
    }
    if not isinstance(groups, dict) or set(groups) != expected_groups:
        errors.append("module input binding group inventory mismatch")
        return errors
    seen: set[str] = set()
    for group in sorted(expected_groups):
        records = groups.get(group)
        if not isinstance(records, dict) or not records:
            errors.append(f"module input binding group is empty: {group}")
            continue
        for path, digest in records.items():
            pure_path = pathlib.PurePosixPath(path) if isinstance(path, str) else None
            if (
                not isinstance(path, str)
                or not path
                or path.startswith("/")
                or "\\" in path
                or pure_path is None
                or path != pure_path.as_posix()
                or any(part in {"", ".", ".."} for part in pure_path.parts)
                or path in seen
            ):
                errors.append(f"module input binding path is invalid: {path}")
            seen.add(path)
            if (
                not isinstance(digest, str)
                or len(digest) != 64
                or any(character not in "0123456789abcdef" for character in digest)
            ):
                errors.append(f"module input binding digest is invalid: {path}")
    return errors


def validate_module_result(
    result_path: pathlib.Path,
    *,
    expected_design_id: str,
    require_current_inputs: bool = True,
) -> tuple[str, list[dict[str, Any]]]:
    value = load_json(result_path)
    errors = module_payload_contract_errors(value)
    if value.get("design_id") != expected_design_id:
        errors.append("module result design_id differs from live RTL")
    if errors:
        raise RuntimeError("; ".join(errors))
    expected_tests = module_evidence.required_tests()
    if value["tests"]["inventory"] != expected_tests:
        raise RuntimeError("module result inventory differs from current exact inventory")
    status_path = result_path.parent / "status.json"
    status = load_json(status_path)
    if (
        set(status) != {"schema", "state", "stage", "detail", "design_id"}
        or
        status.get("schema") != module_evidence.STATUS_SCHEMA
        or status.get("state") != "PASS"
        or status.get("stage") != "complete"
        or status.get("design_id") != expected_design_id
    ):
        raise RuntimeError("module stage status is not complete PASS")
    inputs = value["inputs"]
    pre_path = verify_exact_run_artifact(
        inputs["pre"], kind="input_binding",
        expected_path=result_path.parent / "inputs.pre.json",
    )
    post_path = verify_exact_run_artifact(
        inputs["post"], kind="input_binding",
        expected_path=result_path.parent / "inputs.post.json",
    )
    inputs_pre = load_json(pre_path)
    if inputs_pre != load_json(post_path):
        raise RuntimeError("module input pre/post payloads differ")
    input_errors = module_input_binding_errors(
        inputs_pre,
        expected_design_id=expected_design_id,
        expected_tests=expected_tests,
    )
    if input_errors:
        raise RuntimeError("; ".join(input_errors[:8]))
    if (
        require_current_inputs
        and inputs_pre != module_evidence.capture_inputs(expected_tests)
    ):
        raise RuntimeError("module frozen inputs differ from live module inputs")
    artifacts = value.get("artifacts")
    if not isinstance(artifacts, dict) or set(artifacts) != {"summary", "make_log"}:
        raise RuntimeError("module artifact inventory differs from exact contract")
    verify_exact_run_artifact(
        artifacts["summary"], kind="module_test_summary",
        expected_path=result_path.parent / "summary.txt",
    )
    verify_exact_run_artifact(
        artifacts["make_log"], kind="module_make_log",
        expected_path=result_path.parent / "module-make.log",
    )
    if value.get("retention") != {
        "compiled_images_retained": 0,
        "compiled_images_location": "task-owned temporary directory",
    }:
        raise RuntimeError("module retention contract drifted")
    records: list[dict[str, Any]] = []
    for test_id in value["tests"]["inventory"]:
        entry = value["tests"]["logs"][test_id]
        log_path = verify_exact_run_artifact(
            entry, kind="module_test_log",
            expected_path=result_path.parent / "logs" / f"{test_id}.log",
        )
        log_text = log_path.read_text(encoding="utf-8", errors="replace")
        log_errors = module_evidence.validate_module_log(
            log_text, test_id=test_id, design_id=expected_design_id
        )
        if log_errors:
            raise RuntimeError("; ".join(log_errors[:4]))
        records.append(
            {
                "test_id": test_id,
                "compile_rc": 0,
                "simulation_rc": 0,
                "raw_log": module_evidence.relative(log_path),
            }
        )
    for path in result_path.parent.rglob("*"):
        if path.is_dir() and path.name in {"build", "obj_dir"}:
            raise RuntimeError(f"compiled directory leaked into module evidence: {path}")
        if path.is_file() and path.suffix in {".o", ".vvp"}:
            raise RuntimeError(f"compiled intermediate leaked into module evidence: {path}")
    return str(value["command"]), records


def install_compact_io(legacy: Any, output_dir: pathlib.Path, temp_root: pathlib.Path) -> None:
    legacy.RUN_ID = output_dir.parent.parent.name
    legacy.TASK = output_dir.parent.parent
    legacy.EVIDENCE = output_dir
    legacy.CACHE = temp_root
    legacy.SIM_BUILD = temp_root / "npc-build"
    legacy.SIMULATOR = legacy.SIM_BUILD / "NpcSimTop"
    legacy.AM_BUILD_ROOT = temp_root / "am-build"
    legacy.REFERENCE_LIVE = (
        temp_root / "nemu-work/build/riscv64-nemu-interpreter-so"
    )
    legacy.REFERENCE_FROZEN = output_dir / "frozen/riscv64-nemu-interpreter-so"
    legacy.CONFIG_FROZEN = output_dir / "frozen/npc.config"
    legacy.SIMULATOR_FROZEN = output_dir / "frozen/NpcSimTop"

    def compact_copy(
        source: pathlib.Path,
        destination: pathlib.Path,
        *,
        executable: bool = False,
    ) -> None:
        resolved = lexical_regular_file(source)
        destination_lexical = lexical_output_file(
            destination, root=output_dir
        )
        destination_lexical.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(resolved, destination_lexical)
        if executable:
            destination_lexical.chmod(destination_lexical.stat().st_mode | 0o111)

    def compact_run_command(
        phase: str,
        args: list[str],
        log_path: pathlib.Path,
        *,
        cwd: pathlib.Path = ROOT,
        env: dict[str, str] | None = None,
    ) -> str:
        actual = list(args)
        if actual and actual[0] == "make":
            actual[0] = "/usr/bin/make"
        display = module_evidence.normalize_text(
            shlex.join(actual), temporary_root=temp_root
        )
        merged_env = module_evidence.sanitized_environment()
        if env:
            merged_env.update(env)
        log_path.parent.mkdir(parents=True, exist_ok=True)
        print(f"[FULL-CORE-FUNCTIONAL] START {phase}: {display}", flush=True)
        with log_path.open("w", encoding="utf-8") as handle:
            handle.write(f"phase={phase}\ncommand={display}\n")
            handle.flush()
            completed = subprocess.run(
                actual,
                cwd=cwd,
                env=merged_env,
                stdout=handle,
                stderr=subprocess.STDOUT,
                check=False,
                text=True,
            )
            handle.write(f"phase_return_code={completed.returncode}\n")
        if completed.returncode != 0:
            raise RuntimeError(
                f"{phase} failed with return code {completed.returncode}; "
                f"log={module_evidence.relative(log_path)}"
            )
        print(f"[FULL-CORE-FUNCTIONAL] PASS {phase}", flush=True)
        return display

    legacy.copy_regular = compact_copy
    legacy.run_command = compact_run_command

    def compact_am_phase() -> tuple[str, list[dict[str, Any]]]:
        raw_dir = temp_root / "am-raw"
        tests = sorted(
            path.stem for path in (legacy.CPU_TESTS / "tests").glob("*.c")
        )
        if not tests or len(tests) != len(set(tests)):
            raise RuntimeError(
                f"AM exact inventory must be nonempty and unique, got {len(tests)}"
            )
        args = legacy.am_make_args(
            "-C", str(legacy.CPU_TESTS), f"RAW_LOG_DIR={raw_dir}", "run"
        )
        try:
            command = compact_run_command(
                f"am-{len(tests)}-difftest", args, output_dir / "raw/am-run.log"
            )
            legacy.assert_simulator_binding()
            raw_map = {path.stem: path for path in raw_dir.glob("*.log")}
            if set(raw_map) != set(tests):
                raise RuntimeError(
                    "AM raw-log inventory mismatch: "
                    f"missing={sorted(set(tests) - set(raw_map))[:8]} "
                    f"extra={sorted(set(raw_map) - set(tests))[:8]}"
                )
            records: list[dict[str, Any]] = []
            for test_id in tests:
                image = legacy.am_image_path(legacy.CPU_TESTS, test_id)
                if not image.is_file():
                    raise RuntimeError(f"AM program image is missing: {image}")
                log_destination = output_dir / "raw/am" / f"{test_id}.log"
                image_destination = output_dir / "images/am" / f"{test_id}.bin"
                compact_copy(raw_map[test_id], log_destination)
                compact_copy(image, image_destination)
                records.append(
                    {
                        "test_id": test_id,
                        "return_code": 0,
                        "image": legacy.rel(image_destination),
                        "raw_log": legacy.rel(log_destination),
                    }
                )
            return command, records
        except Exception as phase_error:
            try:
                retain_failed_am_logs(
                    raw_dir, output_dir / "raw/am-failed"
                )
            except Exception as retention_error:
                raise RuntimeError(
                    f"{phase_error}; failed to retain AM logs: {retention_error}"
                ) from phase_error
            raise

    legacy.am_phase = compact_am_phase


def reference_build_args(legacy: Any, temp_root: pathlib.Path) -> list[str]:
    return [
        "/usr/bin/make",
        "-C",
        str(legacy.NEMU),
        f"NEMU_HOME={legacy.NEMU}",
        f"AM_HOME={legacy.AM_HOME}",
        "GUEST_ISA=riscv64",
        "SHARE=1",
        "ENGINE=interpreter",
        f"BUILD_DIR={temp_root / 'nemu-work/build'}",
    ]


def path_fingerprint(path: pathlib.Path, *, root: pathlib.Path = ROOT) -> str:
    digest = hashlib.sha256()
    if not path.exists() and not path.is_symlink():
        return "MISSING"
    if path.is_symlink():
        raise RuntimeError(f"isolation watch path is a symlink: {path}")
    entries = [path] if path.is_file() else sorted(path.rglob("*"))
    for entry in entries:
        if entry.is_symlink():
            raise RuntimeError(f"isolation watch entry is a symlink: {entry}")
        relative_entry = entry.relative_to(root).as_posix().encode("utf-8")
        digest.update(relative_entry)
        digest.update(b"\0")
        if entry.is_file():
            digest.update(module_evidence.sha256_file(entry).encode("ascii"))
        elif entry.is_dir():
            digest.update(b"DIR")
        digest.update(b"\0")
    return digest.hexdigest()


def secondary_product_fingerprints(
    root: pathlib.Path = ROOT,
) -> dict[str, str]:
    """Snapshot AM/benchmark side products that a Makefile may create in-tree."""
    bases = (
        root / "am-kernels/tests/cpu-tests",
        root / "am-kernels/benchmarks/coremark",
        root / "am-kernels/benchmarks/dhrystone",
        root / "abstract-machine/am",
        root / "abstract-machine/klib",
    )
    candidates: set[pathlib.Path] = set()
    for base in bases:
        if not base.exists():
            continue
        candidates.update(base.rglob(".result"))
        candidates.update(base.rglob("Makefile.*"))
        candidates.update(base.rglob("build"))
        candidates.update(base.rglob("obj_dir"))
    return {
        path.resolve(strict=False).relative_to(root.resolve()).as_posix():
        path_fingerprint(path, root=root)
        for path in sorted(candidates)
    }


def require_no_secondary_products(root: pathlib.Path = ROOT) -> None:
    """Reject stale AM/benchmark products before an isolated build starts."""
    products = secondary_product_fingerprints(root)
    if products:
        raise RuntimeError(
            "pre-existing source-tree secondary products must be removed: "
            f"{sorted(products)}"
        )


def run_isolation_smoke() -> int:
    """Build the reference, AM image and both benchmarks in temporary roots."""
    require_no_secondary_products()
    watched = (
        ROOT / "npc/rv64/.config",
        ROOT / "nemu/.config",
        ROOT / "nemu/include/config",
        ROOT / "nemu/build",
        ROOT / "am-kernels/tests/cpu-tests/build",
        ROOT / "am-kernels/benchmarks/coremark/build",
        ROOT / "am-kernels/benchmarks/coremark/Makefile.html",
        ROOT / "am-kernels/benchmarks/dhrystone/build",
        ROOT / "am-kernels/benchmarks/dhrystone/Makefile.html",
        ROOT / "abstract-machine/am/build",
        ROOT / "abstract-machine/klib/build",
    )
    before = {path: path_fingerprint(path) for path in watched}
    secondary_before = secondary_product_fingerprints()
    legacy = load_legacy_runner()
    with tempfile.TemporaryDirectory(prefix="rv64-full-core-isolation-smoke-") as raw:
        temp_root = pathlib.Path(raw)
        legacy.AM_BUILD_ROOT = temp_root / "am-build"
        reference = temp_root / "nemu-work/build/riscv64-nemu-interpreter-so"
        print("[FULL-CORE-ISOLATION] START NEMU reference", flush=True)
        reference_run = subprocess.run(
            reference_build_args(legacy, temp_root),
            cwd=ROOT,
            env=module_evidence.sanitized_environment(),
            check=False,
        )
        if reference_run.returncode != 0 or not reference.is_file():
            raise RuntimeError(
                f"isolated NEMU reference build failed rc={reference_run.returncode}"
            )
        print("[FULL-CORE-ISOLATION] START AM dummy image", flush=True)
        image_run = subprocess.run(
            [
                "/usr/bin/make",
                "-C",
                str(legacy.CPU_TESTS),
                "-f",
                str(legacy.AM_HOME / "Makefile"),
                "NAME=dummy",
                "SRCS=tests/dummy.c",
                f"AM_HOME={legacy.AM_HOME}",
                f"NEMU_HOME={legacy.NEMU}",
                f"NPC_HOME={ROOT / 'npc'}",
                "ARCH=riscv64-npc",
                f"AM_BUILD_ROOT={legacy.AM_BUILD_ROOT}",
                "image",
            ],
            cwd=ROOT,
            env=module_evidence.sanitized_environment(),
            check=False,
        )
        image = legacy.am_image_path(legacy.CPU_TESTS, "dummy")
        if image_run.returncode != 0 or not image.is_file():
            raise RuntimeError(
                f"isolated AM image build failed rc={image_run.returncode}"
            )
        for library in ("am", "klib"):
            archive = legacy.AM_BUILD_ROOT / f"{library}-riscv64-npc.a"
            if not archive.is_file():
                raise RuntimeError(
                    f"isolated AM library archive is missing: {archive}"
                )
        benchmark_builds = (
            (legacy.COREMARK, "coremark", "ITERATIONS=10"),
            (legacy.DHRYSTONE, "dhrystone", "mainargs=10000"),
        )
        for benchmark, name, parameter in benchmark_builds:
            clean_run = subprocess.run(
                [
                    "/usr/bin/make",
                    "-C",
                    str(benchmark),
                    f"AM_HOME={legacy.AM_HOME}",
                    f"AM_BUILD_ROOT={legacy.AM_BUILD_ROOT}",
                    "clean",
                ],
                cwd=ROOT,
                env=module_evidence.sanitized_environment(),
                check=False,
            )
            if clean_run.returncode != 0:
                raise RuntimeError(
                    f"isolated benchmark clean failed rc={clean_run.returncode}"
                )
            image_run = subprocess.run(
                [
                    "/usr/bin/make",
                    "-C",
                    str(benchmark),
                    f"AM_HOME={legacy.AM_HOME}",
                    f"NEMU_HOME={legacy.NEMU}",
                    f"NPC_HOME={ROOT / 'npc'}",
                    "ARCH=riscv64-npc",
                    f"AM_BUILD_ROOT={legacy.AM_BUILD_ROOT}",
                    parameter,
                    "image",
                ],
                cwd=ROOT,
                env=module_evidence.sanitized_environment(),
                check=False,
            )
            benchmark_image = legacy.am_image_path(benchmark, name)
            if image_run.returncode != 0 or not benchmark_image.is_file():
                raise RuntimeError(
                    f"isolated {name} image build failed rc={image_run.returncode}"
                )
    after = {path: path_fingerprint(path) for path in watched}
    drift = [path.relative_to(ROOT).as_posix() for path in watched if before[path] != after[path]]
    secondary_after = secondary_product_fingerprints()
    if secondary_before != secondary_after:
        drift.extend(sorted(set(secondary_before) ^ set(secondary_after)))
        drift.extend(sorted(
            path for path in set(secondary_before) & set(secondary_after)
            if secondary_before[path] != secondary_after[path]
        ))
    if drift:
        raise RuntimeError(
            f"isolated build changed source-tree products: {sorted(set(drift))}"
        )
    require_no_secondary_products()
    print(
        "[FULL-CORE-ISOLATION][PASS] reference=1 am_image=1 am_archive=1 "
        "klib_archive=1 benchmark_images=2 benchmark_clean_source_drift=0 "
        "source_tree_drift=0 retained_temp_products=0"
    )
    return 0


def normalize_output_logs(output_dir: pathlib.Path, temp_root: pathlib.Path) -> None:
    for path in sorted(output_dir.rglob("*.log")):
        if path.is_symlink() or not path.is_file():
            raise RuntimeError(f"functional log is not a regular file: {path}")
        text = path.read_text(encoding="utf-8", errors="replace")
        path.write_text(
            module_evidence.normalize_text(text, temporary_root=temp_root),
            encoding="utf-8",
        )


def publish_generated(source: pathlib.Path, destination: pathlib.Path) -> None:
    source_file = lexical_regular_file(source)
    destination_file = lexical_output_file(destination, root=ROOT)
    destination_file.parent.mkdir(parents=True, exist_ok=True)
    temporary = destination_file.with_name(
        destination_file.name + ".tmp-full-core-current"
    )
    temporary_file = lexical_output_file(temporary, root=ROOT)
    if temporary_file.exists():
        raise RuntimeError(f"stale publish temporary exists: {temporary}")
    try:
        flags = os.O_WRONLY | os.O_CREAT | os.O_EXCL
        if hasattr(os, "O_NOFOLLOW"):
            flags |= os.O_NOFOLLOW
        descriptor = os.open(temporary_file, flags, 0o600)
        with source_file.open("rb") as source_handle, os.fdopen(
            descriptor, "wb"
        ) as destination_handle:
            shutil.copyfileobj(source_handle, destination_handle)
        os.replace(temporary_file, destination_file)
    finally:
        if temporary_file.exists() and not temporary_file.is_symlink():
            temporary_file.unlink()


def full_core_run_dir(result_path: pathlib.Path) -> pathlib.Path:
    """Return the immutable task-run owning a canonical runner result."""
    relative = result_path.resolve(strict=True).relative_to(ROOT.resolve(strict=True))
    parts = relative.parts
    if (
        len(parts) != 6
        or parts[0:2] != (".github", "task-runs")
        or parts[3:] != ("evidence", "functional", "run-result.json")
    ):
        raise RuntimeError(
            "functional result is not at "
            ".github/task-runs/<run-id>/evidence/functional/run-result.json"
        )
    return ROOT.joinpath(*parts[:3]).resolve(strict=True)


def require_status_line(path: pathlib.Path, expected: str) -> None:
    if path.is_symlink() or not path.is_file():
        raise RuntimeError(f"status input is not a regular file: {path}")
    observed = path.read_text(encoding="utf-8")
    if observed != expected + "\n":
        raise RuntimeError(
            f"status is not {expected}: {module_evidence.relative(path)}"
        )


def aggregate_counts(aggregate: dict[str, Any]) -> dict[str, int]:
    return {
        "module_required": aggregate["module"]["required"],
        "module_passed": aggregate["module"]["passed"],
        "official_required": aggregate["official"]["required"],
        "official_passed": aggregate["official"]["passed"],
        "am_required": aggregate["am"]["required"],
        "am_passed": aggregate["am"]["passed"],
        "difftest_mismatches": aggregate["difftest"]["mismatches"],
    }


def validate_mutation_summary(
    value: dict[str, Any], *, design_id: str, counts: dict[str, Any], legacy: Any
) -> None:
    errors = legacy.functional.freeze.f0_mutation_summary_errors(
        value,
        expected_design_id=design_id,
        cohort_id=COHORT_ID,
        counts=counts,
    )
    if errors:
        raise RuntimeError("functional mutation summary: " + "; ".join(errors[:8]))


def validate_aggregate_log(
    path: pathlib.Path,
    *,
    aggregate: dict[str, Any],
    counts: dict[str, Any],
    checks: list[dict[str, Any]],
    legacy: Any,
) -> None:
    observed = path.read_text(encoding="utf-8")
    expected = legacy.functional.aggregate_log_text(aggregate, counts, checks)
    if observed != expected:
        raise RuntimeError("functional aggregate terminal log semantics mismatch")


def verify_publication_binding(
    result_path: pathlib.Path,
    run_result: dict[str, Any],
    *,
    require_publication_pass: bool,
) -> dict[str, Any]:
    """Verify the binding committed after the three canonical data files."""
    run_dir = full_core_run_dir(result_path)
    require_status_line(run_dir / "full-core-current.status", "PASS")
    if require_publication_pass:
        require_status_line(run_dir / "full-core-publication.status", "PASS")

    binding = load_json(CANONICAL_BINDING)
    design_id = run_result.get("design_id")
    if (
        binding.get("schema") != PUBLICATION_SCHEMA
        or binding.get("status") != "PASS"
        or binding.get("design_id") != design_id
        or binding.get("cohort_id") != COHORT_ID
    ):
        raise RuntimeError("canonical functional publication binding mismatch")
    source_result = verify_artifact(
        binding.get("source_run_result"), kind="functional_run_result"
    )
    if source_result != result_path.resolve(strict=True):
        raise RuntimeError("canonical publication points to another run result")
    execution_status = verify_artifact(
        binding.get("execution_status"), kind="full_core_execution_status"
    )
    if execution_status != (run_dir / "full-core-current.status").resolve(strict=True):
        raise RuntimeError("canonical publication points to another execution status")

    artifacts = run_result.get("artifacts")
    canonical_artifacts = binding.get("artifacts")
    if not isinstance(artifacts, dict) or not isinstance(canonical_artifacts, dict):
        raise RuntimeError("canonical publication artifact map is missing")
    expected_destinations = {
        "aggregate": CANONICAL_AGGREGATE,
        "aggregate_result": CANONICAL_RESULT,
        "aggregate_log": CANONICAL_LOG,
    }
    expected_kinds = {
        "aggregate": "functional_aggregate",
        "aggregate_result": "functional_aggregate_result",
        "aggregate_log": "functional_aggregate_log",
    }
    if set(canonical_artifacts) != set(expected_destinations):
        raise RuntimeError("canonical publication artifact inventory mismatch")
    for name, destination in expected_destinations.items():
        entry = canonical_artifacts.get(name)
        canonical_path = verify_artifact(entry, kind=expected_kinds[name])
        if canonical_path != destination.resolve(strict=True):
            raise RuntimeError(f"canonical publication path mismatch for {name}")
        source_entry = artifacts.get(name)
        if not isinstance(source_entry, dict) or entry.get("sha256") != source_entry.get(
            "sha256"
        ):
            raise RuntimeError(f"canonical publication hash mismatch for {name}")
    return binding


def verify_functional_result(
    result_raw: pathlib.Path,
    *,
    require_current_design: bool,
    require_canonical_current: bool,
) -> dict[str, Any]:
    """Verify one durable functional result and, optionally, its publication."""
    result_path = resolve_repo_file(result_raw)
    output_dir = result_path.parent.resolve(strict=True)
    value = load_json(result_path)
    if set(value) != {
        "schema", "status", "design_id", "counts", "module_result",
        "artifacts", "inputs", "inputs_unchanged", "retention",
        "published_current",
    }:
        raise RuntimeError("functional result field set differs from exact contract")
    if value.get("schema") != SCHEMA:
        raise RuntimeError("functional result schema mismatch")
    if value.get("status") != "PASS":
        raise RuntimeError("functional result is not PASS")

    design_id = value.get("design_id")
    if not isinstance(design_id, str):
        raise RuntimeError("functional result design_id is missing")
    if require_current_design:
        design_hex, _ = architecture.rtl_binding(ROOT)
        if design_id != f"sha256:{design_hex}":
            raise RuntimeError("functional result design_id differs from live RTL")

    status = load_json(output_dir / "status.json")
    if (
        set(status) != {"schema", "state", "stage", "detail", "design_id"}
        or
        status.get("schema") != module_evidence.STATUS_SCHEMA
        or status.get("state") != "PASS"
        or status.get("stage") != "complete"
        or status.get("design_id") != design_id
    ):
        raise RuntimeError("functional stage status is not complete PASS")

    counts = value.get("counts")
    if not isinstance(counts, dict):
        raise RuntimeError("functional result counts are missing")
    if set(counts) != {
        "module_required", "module_passed", "official_required",
        "official_passed", "am_required", "am_passed",
        "difftest_mismatches", "evidence_mutations_compiled",
        "evidence_mutations_rejected",
    }:
        raise RuntimeError("functional count field set differs from exact contract")
    for passed_key, required_key in (
        ("module_passed", "module_required"),
        ("official_passed", "official_required"),
        ("am_passed", "am_required"),
        ("evidence_mutations_rejected", "evidence_mutations_compiled"),
    ):
        passed = counts.get(passed_key)
        required = counts.get(required_key)
        if (
            not isinstance(passed, int)
            or isinstance(passed, bool)
            or not isinstance(required, int)
            or isinstance(required, bool)
            or required <= 0
            or passed != required
        ):
            raise RuntimeError(
                f"functional count mismatch: {passed_key}={passed} "
                f"{required_key}={required}"
            )
    if counts.get("official_required") != 177:
        raise RuntimeError("functional official inventory is not exactly 177")
    if counts.get("difftest_mismatches") != 0:
        raise RuntimeError("functional DiffTest mismatch count is not zero")

    expected_artifacts = {
        "aggregate": ("functional_aggregate", output_dir / "functional-aggregate.json"),
        "aggregate_result": (
            "functional_aggregate_result", output_dir / "functional-aggregate-result.json"
        ),
        "aggregate_log": (
            "functional_aggregate_log", output_dir / "functional-aggregate.log"
        ),
        "simulator": ("simulator_binary", output_dir / "frozen/NpcSimTop"),
        "reference": (
            "reference_model_binary",
            output_dir / "frozen/riscv64-nemu-interpreter-so",
        ),
        "configuration": ("kconfig", output_dir / "frozen/npc.config"),
    }
    artifacts = value.get("artifacts")
    if not isinstance(artifacts, dict) or set(artifacts) != set(expected_artifacts):
        raise RuntimeError("functional artifact map differs from exact contract")
    verified_artifacts: dict[str, pathlib.Path] = {}
    for name, (kind, expected_path) in expected_artifacts.items():
        path = verify_exact_run_artifact(
            artifacts.get(name), kind=kind, expected_path=expected_path
        )
        verified_artifacts[name] = path

    module_result_path = verify_exact_run_artifact(
        value.get("module_result"), kind="module_current_result",
        expected_path=output_dir.parent / "module/result.json",
    )
    validate_module_result(module_result_path, expected_design_id=design_id)
    inputs = value.get("inputs")
    if (
        not isinstance(inputs, dict)
        or set(inputs) != {"pre", "post", "unchanged"}
        or inputs.get("unchanged") is not True
    ):
        raise RuntimeError("functional input binding is not unchanged")
    pre_path = verify_exact_run_artifact(
        inputs.get("pre"), kind="functional_input_binding",
        expected_path=output_dir / "inputs.pre.json",
    )
    post_path = verify_exact_run_artifact(
        inputs.get("post"), kind="functional_input_binding",
        expected_path=output_dir / "inputs.post.json",
    )
    inputs_pre = load_json(pre_path)
    if inputs_pre != load_json(post_path):
        raise RuntimeError("functional input pre/post payloads differ")
    if value.get("inputs_unchanged") is not True:
        raise RuntimeError("functional inputs_unchanged is not true")
    retention = value.get("retention")
    expected_retention = {
        "module_simulation_reused": True,
        "compiled_intermediates_retained": 0,
        "frozen_simulator_retained": 1,
        "frozen_reference_retained": 1,
        "program_images_retained": 177 + counts["am_required"] + 2,
    }
    if retention != expected_retention:
        raise RuntimeError("functional retention contract drifted")
    if value.get("published_current") is not False:
        raise RuntimeError("immutable functional run result was rewritten by publication")
    for path in output_dir.rglob("*"):
        if path.is_dir() and path.name in {"build", "obj_dir"}:
            raise RuntimeError(f"compiled directory leaked into evidence: {path}")
        if path.is_file() and path.suffix in {".o", ".vvp"}:
            raise RuntimeError(f"compiled intermediate leaked into evidence: {path}")

    legacy = load_legacy_runner()
    required_tests = module_evidence.required_tests()
    aggregate = load_json(verified_artifacts["aggregate"])
    schema_issues = legacy.functional.freeze.schema_errors(
        ROOT, aggregate, legacy.functional.freeze.FUNCTIONAL_SCHEMA
    )
    if schema_issues:
        raise RuntimeError(
            "functional aggregate schema: " + "; ".join(schema_issues[:8])
        )
    checks, blockers, _ = legacy.functional.validate_aggregate(
        ROOT, aggregate, required_tests
    )
    if blockers:
        raise RuntimeError(
            "functional aggregate validation: " + "; ".join(blockers[:8])
        )
    if aggregate.get("design_id") != design_id:
        raise RuntimeError("functional aggregate design binding mismatch")
    if aggregate.get("cohort_id") != COHORT_ID:
        raise RuntimeError("functional aggregate cohort binding mismatch")
    if inputs_pre.get("design_id") != design_id:
        raise RuntimeError("functional input design binding mismatch")
    if aggregate.get("am", {}).get("inventory") != inputs_pre.get("am_test_ids"):
        raise RuntimeError("functional AM inventory differs from frozen source input")
    if (
        aggregate.get("official", {}).get("inventory")
        != inputs_pre.get("official_test_ids")
    ):
        raise RuntimeError(
            "functional official inventory differs from frozen source input"
        )

    aggregate_receipts = {
        "simulator": aggregate.get("simulator"),
        "configuration": aggregate.get("configuration"),
        "reference": (
            aggregate.get("difftest", {}).get("reference")
            if isinstance(aggregate.get("difftest"), dict)
            else None
        ),
    }
    for name, aggregate_receipt in aggregate_receipts.items():
        run_receipt = artifacts[name]
        expected_receipt = {
            key: run_receipt[key] for key in ("kind", "path", "sha256")
        }
        if aggregate_receipt != expected_receipt:
            raise RuntimeError(
                f"functional aggregate {name} differs from run artifact receipt"
            )

    build_record = aggregate.get("build")
    if not isinstance(build_record, dict):
        raise RuntimeError("functional simulator build record is missing")
    build_wrapper = verify_artifact(
        build_record.get("log"), kind="simulator_build_log"
    )
    expected_build_wrapper = resolve_repo_file(output_dir / "wrapped/build.log")
    if build_wrapper != expected_build_wrapper:
        raise RuntimeError("functional build wrapper points outside run")
    build_source_text = verify_wrapped_source_log(
        build_wrapper,
        expected_source_path=output_dir / "raw/build.log",
        label="simulator-build",
    )
    if "[RESULT] FAIL" in build_source_text:
        raise RuntimeError("functional retained simulator build log contains FAIL")

    for suite_name, log_kind in (
        ("official", "official_test_log"),
        ("am", "am_test_log"),
    ):
        suite = aggregate.get(suite_name)
        if not isinstance(suite, dict):
            raise RuntimeError(f"functional suite is missing: {suite_name}")
        inventory = suite.get("inventory")
        records = suite.get("images")
        if not isinstance(inventory, list) or not isinstance(records, list):
            raise RuntimeError(
                f"functional suite inventory/log map is missing: {suite_name}"
            )
        if len(records) != len(inventory):
            raise RuntimeError(
                f"functional suite log cardinality differs: {suite_name}"
            )
        for test_id, record in zip(inventory, records, strict=True):
            if not isinstance(record, dict) or record.get("test_id") != test_id:
                raise RuntimeError(
                    f"functional suite log ordering differs: {suite_name}:{test_id}"
                )
            wrapper_path = verify_artifact(record.get("log"), kind=log_kind)
            expected_wrapper = resolve_repo_file(
                output_dir / "wrapped" / suite_name / f"{test_id}.log"
            )
            if wrapper_path != expected_wrapper:
                raise RuntimeError(
                    "functional suite wrapper points outside run: "
                    f"{suite_name}:{test_id}"
                )
            source_text = verify_wrapped_source_log(
                wrapper_path,
                expected_source_path=(
                    output_dir / "raw" / suite_name / f"{test_id}.log"
                ),
                label=f"{suite_name}:{test_id}",
            )
            legacy.functional.validate_suite_raw_output(
                suite_name, source_text, test_id=test_id
            )

    benchmark_map = aggregate.get("benchmarks")
    if not isinstance(benchmark_map, dict):
        raise RuntimeError("functional benchmark inventory is missing")
    for name in ("coremark", "dhrystone"):
        record = benchmark_map.get(name)
        if not isinstance(record, dict):
            raise RuntimeError(f"functional benchmark record is missing: {name}")
        wrapper_path = verify_artifact(record.get("log"), kind="benchmark_log")
        if wrapper_path != (output_dir / "wrapped" / f"{name}.log").resolve(
            strict=True
        ):
            raise RuntimeError(f"functional benchmark wrapper points outside run: {name}")
        source_text = verify_wrapped_source_log(
            wrapper_path,
            expected_source_path=output_dir / "raw" / f"{name}.log",
            label=f"benchmark:{name}",
        )
        legacy.functional.validate_benchmark_raw_output(name, source_text)

    aggregate_result = load_json(verified_artifacts["aggregate_result"])
    result_schema_issues = legacy.functional.freeze.schema_errors(
        ROOT,
        aggregate_result,
        legacy.functional.freeze.FUNCTIONAL_RESULT_SCHEMA,
    )
    if result_schema_issues:
        raise RuntimeError(
            "functional aggregate result schema: "
            + "; ".join(result_schema_issues[:8])
        )
    if (
        aggregate_result.get("design_id") != design_id
        or aggregate_result.get("cohort_id") != COHORT_ID
        or aggregate_result.get("status") != "PASS"
        or aggregate_result.get("exit_code") != 0
        or aggregate_result.get("canonical_command")
        != legacy.functional.CANONICAL_COMMAND
    ):
        raise RuntimeError("functional aggregate result contract mismatch")
    result_aggregate_path = verify_artifact(
        aggregate_result.get("aggregate"), kind="functional_aggregate"
    )
    result_log_path = verify_artifact(
        aggregate_result.get("raw_log"), kind="raw_log"
    )
    mutation_path = verify_artifact(
        aggregate_result.get("mutation_summary"), kind="mutation_summary"
    )
    if result_aggregate_path != verified_artifacts["aggregate"]:
        raise RuntimeError("functional aggregate result points to another aggregate")
    if result_log_path != verified_artifacts["aggregate_log"]:
        raise RuntimeError("functional aggregate result points to another log")
    if mutation_path != (output_dir / "mutations/summary.json").resolve(strict=True):
        raise RuntimeError("functional mutation summary points outside the owning run")
    if aggregate_result.get("counts") != counts:
        raise RuntimeError("functional run/result counts differ")
    expected_counts = aggregate_counts(aggregate)
    for key, expected_value in expected_counts.items():
        if counts.get(key) != expected_value:
            raise RuntimeError(
                f"functional aggregate count mismatch: {key}="
                f"{counts.get(key)} expected={expected_value}"
            )
    if aggregate_result.get("checks") != checks:
        raise RuntimeError("functional aggregate checks differ from revalidation")
    validate_aggregate_log(
        verified_artifacts["aggregate_log"],
        aggregate=aggregate,
        counts=counts,
        checks=checks,
        legacy=legacy,
    )
    mutation_summary = load_json(mutation_path)
    validate_mutation_summary(
        mutation_summary, design_id=design_id, counts=counts, legacy=legacy
    )
    replayed_mutations = legacy.functional.run_mutations(
        ROOT,
        aggregate,
        required_tests,
        output_dir / "wrapped/mutation-inputs",
        prepare_inputs=False,
    )
    if replayed_mutations != mutation_summary:
        raise RuntimeError("functional mutation replay differs from frozen summary")

    if require_current_design:
        current_inputs = capture_functional_inputs(legacy, required_tests)
        if current_inputs != inputs_pre:
            raise RuntimeError("functional frozen inputs differ from live execution inputs")

    if require_canonical_current:
        verify_publication_binding(
            result_path, value, require_publication_pass=True
        )
    return value


def publish_current_result(
    result_path: pathlib.Path,
    run_result: dict[str, Any],
    execution_status_path: pathlib.Path,
) -> dict[str, Any]:
    """Publish three files, then atomically commit their immutable binding."""
    output_dir = result_path.parent
    run_dir = full_core_run_dir(result_path)
    expected_execution_status = (run_dir / "full-core-current.status").resolve(
        strict=True
    )
    if execution_status_path.resolve(strict=True) != expected_execution_status:
        raise RuntimeError("functional publication received another execution status")
    require_status_line(expected_execution_status, "PASS")
    sources = {
        "aggregate": output_dir / "functional-aggregate.json",
        "aggregate_result": output_dir / "functional-aggregate-result.json",
        "aggregate_log": output_dir / "functional-aggregate.log",
    }
    destinations = {
        "aggregate": CANONICAL_AGGREGATE,
        "aggregate_result": CANONICAL_RESULT,
        "aggregate_log": CANONICAL_LOG,
    }
    kinds = {
        "aggregate": "functional_aggregate",
        "aggregate_result": "functional_aggregate_result",
        "aggregate_log": "functional_aggregate_log",
    }
    artifacts = run_result.get("artifacts")
    if not isinstance(artifacts, dict):
        raise RuntimeError("functional result artifact map is missing")
    for name, source in sources.items():
        verified_source = verify_artifact(artifacts.get(name), kind=kinds[name])
        if verified_source != source.resolve(strict=True):
            raise RuntimeError(f"functional publication source mismatch for {name}")
        publish_generated(source, destinations[name])
    canonical_artifacts = {
        name: module_evidence.artifact(destinations[name], kind=kinds[name])
        for name in sources
    }
    binding = {
        "schema": PUBLICATION_SCHEMA,
        "status": "PASS",
        "design_id": run_result["design_id"],
        "cohort_id": COHORT_ID,
        "source_run_result": module_evidence.artifact(
            result_path, kind="functional_run_result"
        ),
        "execution_status": module_evidence.artifact(
            execution_status_path, kind="full_core_execution_status"
        ),
        "artifacts": canonical_artifacts,
    }
    local_binding = output_dir / "publication-binding.json"
    module_evidence.write_json(local_binding, binding)
    publish_generated(local_binding, CANONICAL_BINDING)
    return binding


def retain_failed_am_logs(
    raw_dir: pathlib.Path, destination_dir: pathlib.Path
) -> list[str]:
    """Copy every regular per-test AM log that exists at a failed boundary."""
    copied: list[str] = []
    if not raw_dir.exists():
        return copied
    for source in sorted(raw_dir.glob("*.log")):
        if source.is_symlink() or not source.is_file():
            raise RuntimeError(f"failed AM log is not a regular file: {source}")
        destination_dir.mkdir(parents=True, exist_ok=True)
        destination = destination_dir / source.name
        if destination.exists() and (destination.is_symlink() or not destination.is_file()):
            raise RuntimeError(f"failed AM log destination is unsafe: {destination}")
        shutil.copyfile(source, destination)
        copied.append(source.name)
    return copied


def run_functional(
    output_raw: pathlib.Path,
    *,
    module_result_raw: pathlib.Path,
    jobs: int,
) -> int:
    output_dir = module_evidence.safe_output_dir(output_raw)
    output_dir.mkdir(parents=True)
    module_result_path = resolve_repo_file(module_result_raw)
    expected_module_path = output_dir.parent / "module/result.json"
    design_hex, _ = architecture.rtl_binding(ROOT)
    design_id = f"sha256:{design_hex}"
    stage = "module-result-validation"
    interrupted_signal: int | None = None

    def on_signal(signum: int, _frame: Any) -> None:
        nonlocal interrupted_signal
        interrupted_signal = signum
        module_evidence.write_status(
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
        if module_result_path != expected_module_path.resolve(strict=True):
            raise RuntimeError("module result is not owned by the current full-core run")
        module_command, module_records = validate_module_result(
            module_result_path, expected_design_id=design_id
        )
        module_evidence.write_status(
            output_dir,
            state="RUNNING",
            stage=stage,
            detail=f"module_tests={len(module_records)}",
            design_id=design_id,
        )
        legacy = load_legacy_runner()
        run_result: dict[str, Any]
        with tempfile.TemporaryDirectory(prefix="rv64-full-core-functional-") as raw_temp:
            temp_root = pathlib.Path(raw_temp)
            install_compact_io(legacy, output_dir, temp_root)
            tests = module_evidence.required_tests()
            stage = "preflight-input-binding"
            inputs_pre = capture_functional_inputs(legacy, tests)
            if inputs_pre["design_id"] != design_id:
                raise RuntimeError("RTL design changed before simulator build")
            module_evidence.write_json(output_dir / "inputs.pre.json", inputs_pre)
            live_config = legacy.NPC / ".config"
            if live_config.is_symlink() or not live_config.is_file():
                raise RuntimeError("current NPC configuration is missing")
            if "CONFIG_NPC_DIFFTEST=y" not in live_config.read_text(
                encoding="utf-8"
            ):
                raise RuntimeError(
                    "current NPC configuration must enable CONFIG_NPC_DIFFTEST=y"
                )
            reference_config = legacy.NEMU / ".config"
            if reference_config.is_symlink() or not reference_config.is_file():
                raise RuntimeError("current NEMU reference configuration is missing")
            reference_config_text = reference_config.read_text(encoding="utf-8")
            for required_line in (
                'CONFIG_ISA="riscv64"',
                'CONFIG_ENGINE="interpreter"',
                "CONFIG_MODE_SYSTEM=y",
            ):
                if required_line not in reference_config_text.splitlines():
                    raise RuntimeError(
                        f"current NEMU reference configuration lacks {required_line}"
                    )

            build_logs = output_dir / "raw/build-phases"
            stage = "nemu-reference-build"
            reference_command = legacy.run_command(
                stage,
                reference_build_args(legacy, temp_root),
                build_logs / "nemu-reference-build.log",
            )
            stage = "npc-verilator-build"
            simulator_command = legacy.run_command(
                stage,
                [
                    "/usr/bin/make",
                    "-C",
                    str(legacy.NPC),
                    f"BUILD_DIR={legacy.SIM_BUILD}",
                    "VERILATOR=verilator -Wno-fatal",
                    f"-j{jobs}",
                    "default",
                ],
                build_logs / "npc-verilator-build.log",
            )
            for path, label in (
                (legacy.NPC / ".config", "NPC configuration"),
                (legacy.SIMULATOR, "NPC simulator"),
                (legacy.REFERENCE_LIVE, "NEMU reference model"),
            ):
                if not path.is_file():
                    raise RuntimeError(f"{label} artifact is missing: {path}")
            legacy.copy_regular(
                legacy.SIMULATOR, legacy.SIMULATOR_FROZEN, executable=True
            )
            legacy.copy_regular(
                legacy.REFERENCE_LIVE, legacy.REFERENCE_FROZEN, executable=True
            )
            legacy.copy_regular(legacy.NPC / ".config", legacy.CONFIG_FROZEN)
            if "CONFIG_NPC_DIFFTEST=y" not in legacy.CONFIG_FROZEN.read_text(
                encoding="utf-8"
            ):
                raise RuntimeError("current NPC configuration did not enable DiffTest")
            profile = legacy.reference_profile()
            merged_build = output_dir / "raw/build.log"
            legacy.merge_logs(
                merged_build,
                [
                    ("NEMU-REFERENCE-BUILD", build_logs / "nemu-reference-build.log"),
                    ("NPC-VERILATOR-BUILD", build_logs / "npc-verilator-build.log"),
                ],
            )
            build_command = " && ".join(
                (reference_command, simulator_command)
            )

            stage = "official-177"
            official_command, official_records = legacy.official_phase()
            stage = "am-current-difftest"
            am_command, am_records = legacy.am_phase()
            stage = "coremark"
            coremark = legacy.benchmark_phase(
                "coremark",
                legacy.COREMARK,
                ["ITERATIONS=10"],
                {"iterations": 10, "crc": "0xfcaf", "good_traps": 1},
                max_cycles=20_000_000,
            )
            stage = "dhrystone"
            dhrystone = legacy.benchmark_phase(
                "dhrystone",
                legacy.DHRYSTONE,
                ["mainargs=10000"],
                {"runs": 10000, "good_traps": 1},
                max_cycles=20_000_000,
            )
            inputs_post = capture_functional_inputs(legacy, tests)
            module_evidence.write_json(output_dir / "inputs.post.json", inputs_post)
            if inputs_post != inputs_pre:
                raise RuntimeError("RTL/config/test/workflow inputs drifted during functional run")
            normalize_output_logs(output_dir, temp_root)

            descriptor = {
                "schema": legacy.functional.DESCRIPTOR_SCHEMA,
                "design_id": design_id,
                "cohort_id": COHORT_ID,
                "simulator": legacy.rel(legacy.SIMULATOR_FROZEN),
                "configuration": legacy.rel(legacy.CONFIG_FROZEN),
                "build": {
                    "command": build_command,
                    "return_code": 0,
                    "raw_log": legacy.rel(merged_build),
                },
                "module": {"command": module_command, "tests": module_records},
                "official": {"command": official_command, "tests": official_records},
                "am": {"command": am_command, "tests": am_records},
                "difftest": {
                    "command": am_command,
                    "mismatches": 0,
                    "reference": legacy.rel(legacy.REFERENCE_FROZEN),
                    "reference_profile": legacy.rel(profile),
                },
                "benchmarks": {
                    "coremark": coremark,
                    "dhrystone": dhrystone,
                },
            }
            descriptor_path = output_dir / "functional-run-descriptor.json"
            legacy.write_json(descriptor_path, descriptor)
            stage = "functional-aggregate"
            aggregate_path = output_dir / "functional-aggregate.json"
            aggregate_result_path = output_dir / "functional-aggregate-result.json"
            aggregate_log_path = output_dir / "functional-aggregate.log"
            assembled = legacy.functional.assemble(
                root=ROOT,
                descriptor_path=descriptor_path,
                wrapper_dir=output_dir / "wrapped",
                aggregate_path=aggregate_path,
                mutation_summary_path=output_dir / "mutations/summary.json",
                raw_log_path=aggregate_log_path,
                result_path=aggregate_result_path,
                check_current_design=True,
            )
            if assembled.get("status") != "PASS" or assembled.get("exit_code") != 0:
                raise RuntimeError("functional aggregate assembler did not return PASS")
            if list(output_dir.rglob("*.vvp")) or list(output_dir.rglob("*.o")):
                raise RuntimeError("compiled intermediate leaked into functional output")
            run_result = {
                "schema": SCHEMA,
                "status": "PASS",
                "design_id": design_id,
                "counts": assembled["counts"],
                "module_result": module_evidence.artifact(
                    module_result_path, kind="module_current_result"
                ),
                "artifacts": {
                    "aggregate": module_evidence.artifact(
                        aggregate_path, kind="functional_aggregate"
                    ),
                    "aggregate_result": module_evidence.artifact(
                        aggregate_result_path, kind="functional_aggregate_result"
                    ),
                    "aggregate_log": module_evidence.artifact(
                        aggregate_log_path, kind="functional_aggregate_log"
                    ),
                    "simulator": module_evidence.artifact(
                        legacy.SIMULATOR_FROZEN, kind="simulator_binary"
                    ),
                    "reference": module_evidence.artifact(
                        legacy.REFERENCE_FROZEN, kind="reference_model_binary"
                    ),
                    "configuration": module_evidence.artifact(
                        legacy.CONFIG_FROZEN, kind="kconfig"
                    ),
                },
                "inputs": {
                    "pre": module_evidence.artifact(
                        output_dir / "inputs.pre.json",
                        kind="functional_input_binding",
                    ),
                    "post": module_evidence.artifact(
                        output_dir / "inputs.post.json",
                        kind="functional_input_binding",
                    ),
                    "unchanged": True,
                },
                "inputs_unchanged": True,
                "retention": {
                    "module_simulation_reused": True,
                    "compiled_intermediates_retained": 0,
                    "frozen_simulator_retained": 1,
                    "frozen_reference_retained": 1,
                    "program_images_retained": len(official_records)
                    + len(am_records)
                    + 2,
                },
                "published_current": False,
            }

        # Local evidence becomes complete before any canonical current files
        # are touched.  Publication is a separate promotion step whose binding
        # is committed last; an interrupted promotion therefore remains
        # detectably incomplete.
        module_evidence.write_json(output_dir / "run-result.json", run_result)
        module_evidence.write_status(
            output_dir,
            state="PASS",
            stage="complete",
            detail=(
                f"module={run_result['counts']['module_passed']}/"
                f"{run_result['counts']['module_required']} official=177/177 "
                f"am={run_result['counts']['am_passed']}/"
                f"{run_result['counts']['am_required']} difftest=0"
            ),
            design_id=design_id,
        )
        print(
            "[FULL-CORE-FUNCTIONAL-CURRENT][PASS] "
            f"design_id={design_id} "
            f"module={run_result['counts']['module_passed']}/"
            f"{run_result['counts']['module_required']} "
            f"official=177/177 am={run_result['counts']['am_passed']}/"
            f"{run_result['counts']['am_required']} difftest_mismatches=0 "
            "compiled_intermediates_retained=0"
        )
        return 0
    except (OSError, RuntimeError, ValueError, json.JSONDecodeError) as exc:
        if interrupted_signal is None:
            module_evidence.write_status(
                output_dir,
                state="FAIL",
                stage=stage,
                detail=str(exc),
                design_id=design_id,
            )
            print(f"[FULL-CORE-FUNCTIONAL-CURRENT][FAIL] {exc}", file=sys.stderr)
        return 1
    finally:
        for signum, handler in previous_handlers.items():
            signal.signal(signum, handler)


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Build current-design RV64 full functional evidence"
    )
    parser.add_argument("--module-result", type=pathlib.Path)
    parser.add_argument("--output-dir", type=pathlib.Path)
    parser.add_argument("--jobs", type=int, default=2)
    parser.add_argument("--publish-current", action="store_true", help=argparse.SUPPRESS)
    parser.add_argument("--publish-result", type=pathlib.Path)
    parser.add_argument("--verify-result", type=pathlib.Path)
    parser.add_argument("--require-current-design", action="store_true")
    parser.add_argument("--require-canonical-current", action="store_true")
    parser.add_argument("--isolation-smoke", action="store_true")
    args = parser.parse_args()
    if args.jobs < 1 or args.jobs > 8:
        parser.error("--jobs must be in [1, 8]")
    if args.isolation_smoke:
        if (
            args.module_result is not None
            or args.output_dir is not None
            or args.publish_current
            or args.publish_result is not None
            or args.verify_result is not None
            or args.require_current_design
            or args.require_canonical_current
        ):
            parser.error("--isolation-smoke cannot be combined with other modes")
        try:
            return run_isolation_smoke()
        except (OSError, RuntimeError, ValueError, json.JSONDecodeError) as exc:
            print(f"[FULL-CORE-ISOLATION][FAIL] {exc}", file=sys.stderr)
            return 1
    if args.verify_result is not None:
        if (
            args.module_result is not None
            or args.output_dir is not None
            or args.publish_current
            or args.publish_result is not None
        ):
            parser.error(
                "--verify-result cannot be combined with run/output arguments"
            )
        try:
            value = verify_functional_result(
                args.verify_result,
                require_current_design=args.require_current_design,
                require_canonical_current=args.require_canonical_current,
            )
        except (OSError, RuntimeError, ValueError, json.JSONDecodeError) as exc:
            print(
                f"[FULL-CORE-FUNCTIONAL-VERIFY][FAIL] {exc}",
                file=sys.stderr,
            )
            return 1
        print(
            "[FULL-CORE-FUNCTIONAL-VERIFY][PASS] "
            f"design_id={value['design_id']} "
            f"canonical_current_verified={args.require_canonical_current}"
        )
        return 0
    if args.publish_current:
        parser.error(
            "--publish-current is retired; use run-full-core-current.sh "
            "--publish-current so publication starts after execution PASS"
        )
    if args.publish_result is not None:
        if (
            args.module_result is not None
            or args.output_dir is not None
            or args.require_current_design
            or args.require_canonical_current
        ):
            parser.error("--publish-result cannot be combined with other modes")
        try:
            result_path = resolve_repo_file(args.publish_result)
            run_dir = full_core_run_dir(result_path)
            execution_status_path = run_dir / "full-core-current.status"
            publication_status_path = run_dir / "full-core-publication.status"
            require_status_line(execution_status_path, "PASS")
            require_status_line(publication_status_path, "RUNNING")
            value = verify_functional_result(
                result_path,
                require_current_design=True,
                require_canonical_current=False,
            )
            publish_current_result(result_path, value, execution_status_path)
            verify_publication_binding(
                result_path, value, require_publication_pass=False
            )
        except (OSError, RuntimeError, ValueError, json.JSONDecodeError) as exc:
            print(f"[FULL-CORE-FUNCTIONAL-PUBLISH][FAIL] {exc}", file=sys.stderr)
            return 1
        print(
            "[FULL-CORE-FUNCTIONAL-PUBLISH][PASS] "
            f"design_id={value['design_id']} binding_committed_last=1"
        )
        return 0
    if args.require_current_design or args.require_canonical_current:
        parser.error("verification requirements need --verify-result")
    if args.module_result is None or args.output_dir is None:
        parser.error("a run requires --module-result and --output-dir")
    return run_functional(
        args.output_dir,
        module_result_raw=args.module_result,
        jobs=args.jobs,
    )


if __name__ == "__main__":
    raise SystemExit(main())
