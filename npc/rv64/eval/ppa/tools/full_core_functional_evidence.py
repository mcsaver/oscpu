#!/usr/bin/env python3
"""Build one current-design RV64 functional aggregate without module reruns.

The runner consumes a completed full module-inventory result, builds one
DiffTest-enabled simulator, and executes the exact official, AM, DiffTest,
CoreMark, and Dhrystone cohorts. Simulator build intermediates are temporary;
frozen binaries, images, logs, and aggregate JSON are durable cohort inputs.
"""

from __future__ import annotations

import argparse
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


def resolve_repo_file(raw: pathlib.Path) -> pathlib.Path:
    candidate = raw if raw.is_absolute() else ROOT / raw
    resolved = candidate.resolve(strict=True)
    resolved.relative_to(ROOT.resolve())
    if resolved.is_symlink() or not resolved.is_file():
        raise RuntimeError(f"input is not a regular repository file: {raw}")
    return resolved


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


def collect_repository_files(
    root: pathlib.Path, entries: list[pathlib.Path]
) -> list[str]:
    """Return a deterministic source/control-file set without build products."""
    root_resolved = root.resolve(strict=True)
    collected: set[str] = set()
    for raw in entries:
        candidate = raw if raw.is_absolute() else root / raw
        if candidate.is_symlink():
            raise RuntimeError(f"functional input root is a symlink: {candidate}")
        resolved = candidate.resolve(strict=True)
        resolved.relative_to(root_resolved)
        if resolved.is_file():
            if repository_input_is_generated(resolved):
                continue
            collected.add(resolved.relative_to(root_resolved).as_posix())
            continue
        if not resolved.is_dir():
            raise RuntimeError(f"functional input root is not regular: {candidate}")
        for path in resolved.rglob("*"):
            local_parts = path.relative_to(resolved).parts
            if any(part in GENERATED_INPUT_PARTS for part in local_parts):
                continue
            if path.name in GENERATED_INPUT_NAMES or path.name.startswith("Makefile."):
                continue
            if path.is_symlink() or not path.is_file():
                continue
            if repository_input_is_generated(path):
                continue
            collected.add(path.relative_to(root_resolved).as_posix())
    return sorted(collected)


def repository_input_is_generated(path: pathlib.Path) -> bool:
    """Recognize build products that may live beside official test sources."""
    if path.suffix.lower() in GENERATED_INPUT_SUFFIXES:
        return True
    try:
        with path.open("rb") as handle:
            return handle.read(4) == b"\x7fELF"
    except OSError as exc:
        raise RuntimeError(f"cannot inspect functional input candidate: {path}") from exc


def capture_functional_inputs(legacy: Any, tests: list[str]) -> dict[str, Any]:
    """Bind execution controls and reconstructable program/reference sources."""
    value = module_evidence.capture_inputs(tests)
    value["schema"] = "npc-rv64-full-core-functional-input-binding-v1"
    groups = value["groups"]
    seen = {
        path
        for group in groups.values()
        for path in group
    }
    source_groups = {
        "functional_workflow": [
            pathlib.Path(__file__),
            LEGACY_RUNNER,
            ROOT / "npc/rv64/eval/ppa/tools/functional_aggregate.py",
            ROOT / "npc/rv64/eval/ppa/schemas/functional-aggregate-v2.schema.json",
            ROOT / "npc/rv64/eval/ppa/schemas/functional-aggregate-result-v1.schema.json",
            ROOT / "npc/rv64/eval/ppa/schemas/difftest-reference-profile-v1.schema.json",
            legacy.NPC / "testsuites/scripts/npc-rv64-core-regress.sh",
            legacy.CPU_TESTS / "scripts/check_results.py",
        ],
        "npc_host_harness_sources": [
            legacy.NPC / "Makefile",
            legacy.NPC / "Kconfig",
            legacy.NPC / ".config",
            legacy.NPC / "configs/default_defconfig",
            legacy.NPC / "csrc",
        ],
        "official_program_sources": [legacy.OFFICIAL_TREE],
        "am_program_sources": [
            legacy.CPU_TESTS / "Makefile",
            legacy.CPU_TESTS / "tests",
            legacy.CPU_TESTS / "scripts",
            legacy.AM_HOME / "Makefile",
            legacy.AM_HOME / "am",
            legacy.AM_HOME / "klib",
            legacy.AM_HOME / "scripts",
        ],
        "benchmark_program_sources": [legacy.COREMARK, legacy.DHRYSTONE],
        "reference_model_sources": [
            legacy.NEMU / "Makefile",
            legacy.NEMU / "Kconfig",
            legacy.NEMU / ".config",
            legacy.NEMU / "configs/riscv64-npc_defconfig",
            legacy.NEMU / "src",
            legacy.NEMU / "include",
            legacy.NEMU / "scripts",
        ],
    }
    for group, roots in source_groups.items():
        records: dict[str, str] = {}
        for relative_path in collect_repository_files(ROOT, roots):
            if relative_path in seen:
                continue
            records[relative_path] = module_evidence.sha256_file(
                ROOT / relative_path)
            seen.add(relative_path)
        if not records:
            raise RuntimeError(f"functional input group is empty: {group}")
        groups[group] = records

    tools: dict[str, dict[str, str]] = {}
    for name in ("make", "verilator", "g++", "python3"):
        located = shutil.which(name)
        if located is None:
            raise RuntimeError(f"required functional tool is missing: {name}")
        resolved = pathlib.Path(located).resolve(strict=True)
        tools[name] = {
            "path": resolved.as_posix(),
            "sha256": module_evidence.sha256_file(resolved),
        }
    for name in ("riscv64-linux-gnu-gcc", "riscv64-unknown-elf-gcc"):
        located = shutil.which(name)
        if located is None:
            continue
        resolved = pathlib.Path(located).resolve(strict=True)
        tools[name] = {
            "path": resolved.as_posix(),
            "sha256": module_evidence.sha256_file(resolved),
        }
    value["toolchain"] = tools
    value["am_test_ids"] = sorted(
        path.stem for path in (legacy.CPU_TESTS / "tests").glob("*.c")
    )
    if not value["am_test_ids"]:
        raise RuntimeError("functional AM source inventory is empty")
    return value


def module_payload_contract_errors(value: Any) -> list[str]:
    errors: list[str] = []
    payload = value if isinstance(value, dict) else {}
    tests = payload.get("tests") if isinstance(payload.get("tests"), dict) else {}
    inputs = payload.get("inputs") if isinstance(payload.get("inputs"), dict) else {}
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


def validate_module_result(
    result_path: pathlib.Path, *, expected_design_id: str
) -> tuple[str, list[dict[str, Any]]]:
    value = load_json(result_path)
    errors = module_payload_contract_errors(value)
    if value.get("design_id") != expected_design_id:
        errors.append("module result design_id differs from live RTL")
    if errors:
        raise RuntimeError("; ".join(errors))
    inputs = value["inputs"]
    pre_path = verify_artifact(inputs["pre"], kind="input_binding")
    post_path = verify_artifact(inputs["post"], kind="input_binding")
    if load_json(pre_path) != load_json(post_path):
        raise RuntimeError("module input pre/post payloads differ")
    records: list[dict[str, Any]] = []
    for test_id in value["tests"]["inventory"]:
        entry = value["tests"]["logs"][test_id]
        log_path = verify_artifact(entry, kind="module_test_log")
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
    return str(value["command"]), records


def install_compact_io(legacy: Any, output_dir: pathlib.Path, temp_root: pathlib.Path) -> None:
    legacy.RUN_ID = output_dir.parent.parent.name
    legacy.TASK = output_dir.parent.parent
    legacy.EVIDENCE = output_dir
    legacy.CACHE = temp_root
    legacy.SIM_BUILD = temp_root / "npc-build"
    legacy.SIMULATOR = legacy.SIM_BUILD / "NpcSimTop"
    legacy.REFERENCE_FROZEN = output_dir / "frozen/riscv64-nemu-interpreter-so"
    legacy.CONFIG_FROZEN = output_dir / "frozen/npc.config"
    legacy.SIMULATOR_FROZEN = output_dir / "frozen/NpcSimTop"

    def compact_copy(
        source: pathlib.Path,
        destination: pathlib.Path,
        *,
        executable: bool = False,
    ) -> None:
        resolved = source.resolve(strict=True)
        if resolved.is_symlink() or not resolved.is_file():
            raise RuntimeError(f"source artifact is not a regular file: {source}")
        destination.resolve(strict=False).relative_to(output_dir.resolve())
        destination.parent.mkdir(parents=True, exist_ok=True)
        if destination.exists() and destination.is_symlink():
            raise RuntimeError(f"destination is a symlink: {destination}")
        shutil.copyfile(resolved, destination)
        if executable:
            destination.chmod(destination.stat().st_mode | 0o111)

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
                image = legacy.CPU_TESTS / "build" / f"{test_id}-riscv64-npc.bin"
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
    if destination.exists() and (destination.is_symlink() or not destination.is_file()):
        raise RuntimeError(f"canonical destination is not a regular file: {destination}")
    destination.parent.mkdir(parents=True, exist_ok=True)
    temporary = destination.with_name(destination.name + ".tmp-full-core-current")
    if temporary.exists():
        raise RuntimeError(f"stale publish temporary exists: {temporary}")
    try:
        shutil.copyfile(source, temporary)
        os.replace(temporary, destination)
    finally:
        if temporary.exists():
            temporary.unlink()


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
    publish_current: bool,
) -> int:
    output_dir = module_evidence.safe_output_dir(output_raw)
    output_dir.mkdir(parents=True)
    module_result_path = resolve_repo_file(module_result_raw)
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
            build_logs = output_dir / "raw/build-phases"
            stage = "npc-default-config"
            config_command = legacy.run_command(
                stage,
                ["/usr/bin/make", "-C", str(legacy.NPC), "default_defconfig"],
                build_logs / "npc-default-config.log",
            )
            stage = "nemu-reference-build"
            reference_command = legacy.run_command(
                stage,
                ["/usr/bin/make", "-C", str(legacy.NPC), "difftest-ref"],
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
                raise RuntimeError("fresh NPC configuration did not enable DiffTest")
            profile = legacy.reference_profile()
            merged_build = output_dir / "raw/build.log"
            legacy.merge_logs(
                merged_build,
                [
                    ("NPC-DEFAULT-CONFIG", build_logs / "npc-default-config.log"),
                    ("NEMU-REFERENCE-BUILD", build_logs / "nemu-reference-build.log"),
                    ("NPC-VERILATOR-BUILD", build_logs / "npc-verilator-build.log"),
                ],
            )
            build_command = " && ".join(
                (config_command, reference_command, simulator_command)
            )
            tests = module_evidence.required_tests()
            inputs_pre = capture_functional_inputs(legacy, tests)
            if inputs_pre["design_id"] != design_id:
                raise RuntimeError("RTL design changed during simulator build")
            module_evidence.write_json(output_dir / "inputs.pre.json", inputs_pre)

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
                "published_current": publish_current,
            }

        if publish_current:
            stage = "publish-current"
            publish_generated(
                output_dir / "functional-aggregate.json", CANONICAL_AGGREGATE
            )
            publish_generated(
                output_dir / "functional-aggregate-result.json", CANONICAL_RESULT
            )
            publish_generated(output_dir / "functional-aggregate.log", CANONICAL_LOG)
            run_result["canonical_artifacts"] = {
                "aggregate": module_evidence.artifact(
                    CANONICAL_AGGREGATE, kind="functional_aggregate"
                ),
                "aggregate_result": module_evidence.artifact(
                    CANONICAL_RESULT, kind="functional_aggregate_result"
                ),
                "aggregate_log": module_evidence.artifact(
                    CANONICAL_LOG, kind="functional_aggregate_log"
                ),
            }
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
    parser.add_argument("--module-result", required=True, type=pathlib.Path)
    parser.add_argument("--output-dir", required=True, type=pathlib.Path)
    parser.add_argument("--jobs", type=int, default=2)
    parser.add_argument("--publish-current", action="store_true")
    args = parser.parse_args()
    if args.jobs < 1 or args.jobs > 8:
        parser.error("--jobs must be in [1, 8]")
    return run_functional(
        args.output_dir,
        module_result_raw=args.module_result,
        jobs=args.jobs,
        publish_current=args.publish_current,
    )


if __name__ == "__main__":
    raise SystemExit(main())
