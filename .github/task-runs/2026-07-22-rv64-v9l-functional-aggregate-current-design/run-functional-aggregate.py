#!/usr/bin/env python3
"""Run the F0-G1 same-design local RV64 functional cohort."""

from __future__ import annotations

import hashlib
import importlib.util
import json
import os
import pathlib
import re
import shlex
import shutil
import subprocess
import sys
from typing import Any


RUN_ID = "2026-07-22-rv64-v9l-functional-aggregate-current-design"
COHORT_ID = "full-core-single-hart-rv64-dual-issue-ooo-v1"
ROOT = pathlib.Path(__file__).resolve().parents[3]
TASK = ROOT / ".github/task-runs" / RUN_ID
EVIDENCE = TASK / "evidence"
CACHE = ROOT / ".github/cache/rv64-functional-v9l"
NPC = ROOT / "npc/rv64"
CPU_TESTS = ROOT / "am-kernels/tests/cpu-tests"
COREMARK = ROOT / "am-kernels/benchmarks/coremark"
DHRYSTONE = ROOT / "am-kernels/benchmarks/dhrystone"
AM_HOME = ROOT / "abstract-machine"
NEMU = ROOT / "nemu"
OFFICIAL_TREE = NPC / "testsuites/core-tests/src/riscv-tests"
SIM_BUILD = CACHE / "npc-build"
SIMULATOR = SIM_BUILD / "NpcSimTop"
REFERENCE_LIVE = NEMU / "build/riscv64-nemu-interpreter-so"
REFERENCE_FROZEN = EVIDENCE / "frozen/riscv64-nemu-interpreter-so"
CONFIG_FROZEN = EVIDENCE / "frozen/npc.config"
SIMULATOR_FROZEN = EVIDENCE / "frozen/NpcSimTop"

TOOL_PATH = ROOT / "npc/rv64/eval/ppa/tools/functional_aggregate.py"
TOOL_SPEC = importlib.util.spec_from_file_location(
    "f0_functional_aggregate_tool", TOOL_PATH)
assert TOOL_SPEC is not None and TOOL_SPEC.loader is not None
functional = importlib.util.module_from_spec(TOOL_SPEC)
sys.modules[TOOL_SPEC.name] = functional
TOOL_SPEC.loader.exec_module(functional)


def rel(path: pathlib.Path) -> str:
    return path.resolve().relative_to(ROOT.resolve()).as_posix()


def sha256_file(path: pathlib.Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def ensure_within(path: pathlib.Path, parent: pathlib.Path) -> None:
    try:
        path.resolve().relative_to(parent.resolve())
    except ValueError as exc:
        raise RuntimeError(f"generated path escapes expected local root: {path}") from exc


def reset_generated_dir(path: pathlib.Path, parent: pathlib.Path) -> None:
    ensure_within(path, parent)
    if path.exists():
        if path.is_symlink() or not path.is_dir():
            raise RuntimeError(f"generated directory is not a regular directory: {path}")
        shutil.rmtree(path)
    path.mkdir(parents=True)


def invalidate_current_outputs() -> None:
    expected_parent = ROOT / "npc/rv64/eval/ppa/evidence"
    for path in (
        expected_parent / "functional-aggregate-current.json",
        expected_parent / "functional-aggregate-result.json",
        expected_parent / "functional-aggregate.log",
    ):
        ensure_within(path, expected_parent)
        if path.exists():
            if path.is_symlink() or not path.is_file():
                raise RuntimeError(f"current evidence output is not a regular file: {path}")
            path.unlink()


def command_text(args: list[str]) -> str:
    return shlex.join(args).replace(str(ROOT), "<REPO>")


def run_command(
    phase: str,
    args: list[str],
    log_path: pathlib.Path,
    *,
    cwd: pathlib.Path = ROOT,
    env: dict[str, str] | None = None,
) -> str:
    log_path.parent.mkdir(parents=True, exist_ok=True)
    display = command_text(args)
    print(f"[F0-G1] START {phase}: {display}", flush=True)
    merged_env = os.environ.copy()
    if env:
        merged_env.update(env)
    with log_path.open("w", encoding="utf-8") as handle:
        handle.write(f"phase={phase}\ncommand={display}\n")
        handle.flush()
        completed = subprocess.run(
            args, cwd=cwd, env=merged_env,
            stdout=handle, stderr=subprocess.STDOUT,
            check=False, text=True)
        # Keep the raw phase footer distinct from the canonical wrapper marker.
        # The arch-stable functional contract requires exactly one standalone
        # `return_code=0` line in each wrapped evidence log; embedding the same
        # generic marker in source logs makes an otherwise valid run ambiguous.
        handle.write(f"phase_return_code={completed.returncode}\n")
    if completed.returncode != 0:
        raise RuntimeError(
            f"{phase} failed with return code {completed.returncode}; log={rel(log_path)}")
    print(f"[F0-G1] PASS {phase}", flush=True)
    return display


def copy_regular(source: pathlib.Path, destination: pathlib.Path, *, executable: bool = False) -> None:
    source = source.resolve(strict=True)
    ensure_within(source, ROOT)
    if source.is_symlink() or not source.is_file():
        raise RuntimeError(f"source artifact is not a regular file: {source}")
    destination.parent.mkdir(parents=True, exist_ok=True)
    if destination.exists() and destination.is_symlink():
        raise RuntimeError(f"destination is a symlink: {destination}")
    shutil.copyfile(source, destination)
    if executable:
        destination.chmod(destination.stat().st_mode | 0o111)


def write_json(path: pathlib.Path, value: Any) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(
        json.dumps(value, allow_nan=False, ensure_ascii=False,
                   indent=2, sort_keys=True) + "\n",
        encoding="utf-8")


def current_design_id() -> str:
    evaluator = functional.freeze.load_workspace_module(
        ROOT,
        "npc/rv64/eval/ppa/tools/architecture_hard_gates.py",
        "f0_runner_current_design")
    design_hex, _ = evaluator.rtl_binding(ROOT)
    return f"sha256:{design_hex}"


def merge_logs(destination: pathlib.Path, sources: list[tuple[str, pathlib.Path]]) -> None:
    lines: list[str] = []
    for label, path in sources:
        lines.extend((f"[{label}-BEGIN]", path.read_text(encoding="utf-8").rstrip("\n"),
                      f"[{label}-END]"))
    destination.parent.mkdir(parents=True, exist_ok=True)
    destination.write_text("\n".join(lines) + "\n", encoding="utf-8")


def reference_profile() -> pathlib.Path:
    config_text = (NEMU / ".config").read_text(encoding="utf-8")
    match = re.search(r"(?m)^CONFIG_MSIZE=(0x[0-9A-Fa-f]+)$", config_text)
    if match is None:
        raise RuntimeError("NEMU reference configuration has no CONFIG_MSIZE")
    pmem_size = f"0x{int(match.group(1), 16):016x}"
    extensions = "rv64i"
    for symbol, letter in (
        ("CONFIG_RISCV_EXT_M=y", "m"),
        ("CONFIG_RISCV_EXT_A=y", "a"),
        ("CONFIG_RISCV_EXT_F=y", "f"),
        ("CONFIG_RISCV_EXT_D=y", "d"),
        ("CONFIG_RISCV_EXT_C=y", "c"),
    ):
        if symbol in config_text:
            extensions += letter
    extensions += "_zicsr_zifencei"
    if "CONFIG_RISCV_EXT_B=y" in config_text:
        extensions += "_zba_zbb_zbc_zbs"
    source_specs = (
        ("reference_config", NEMU / ".config"),
        ("reference_model_source", NEMU / "src/isa/riscv64/difftest/dut.c"),
        ("reference_model_source", NEMU / "src/cpu/difftest/ref.c"),
        ("comparison_policy_source", NPC / "csrc/cpu/difftest.cpp"),
        ("comparison_policy_source", NPC / "csrc/cpu/cpu-exec.cpp"),
    )
    artifacts = []
    for kind, path in source_specs:
        if not path.is_file() or path.is_symlink():
            raise RuntimeError(f"reference profile source is missing: {path}")
        artifacts.append({
            "kind": kind,
            "path": rel(path),
            "sha256": sha256_file(path),
        })
    value = {
        "schema": functional.freeze.DIFFTEST_PROFILE_SCHEMA,
        "reference_sha256": sha256_file(REFERENCE_FROZEN),
        "isa": extensions,
        "reset_pc": functional.LOAD_ADDRESS,
        "program_load_address": functional.LOAD_ADDRESS,
        "memory_map": {
            "pmem_base": functional.LOAD_ADDRESS,
            "pmem_size": pmem_size,
            "mmio_model": "local NPC UART/RTC/keyboard/VGA/virtio MMIO model",
        },
        "comparison_policy": [
            "retired instruction program counter and next program counter",
            "integer and floating-point architectural register state",
            "architectural control and status register state at retirement",
            "documented local device and timer synchronization policy",
        ],
        "source_artifacts": artifacts,
    }
    path = EVIDENCE / "frozen/difftest-reference-profile.json"
    write_json(path, value)
    issues = functional.freeze.schema_errors(
        ROOT, value, functional.freeze.DIFFTEST_PROFILE_SCHEMA)
    if issues:
        raise RuntimeError("reference profile schema failed: " + "; ".join(issues[:4]))
    return path


def module_phase() -> tuple[str, list[dict[str, Any]]]:
    result_dir = CACHE / "module-result"
    build_dir = CACHE / "module-build"
    args = [
        "make", "-B", "-C", str(NPC / "testbench"),
        f"RESULT_DIR={result_dir}", f"BUILD_DIR={build_dir}", "run",
    ]
    command = run_command(
        "module-current-inventory", args, EVIDENCE / "raw/module-run.log")
    logs = sorted((result_dir / "logs").glob("tb_*.log"))
    required = functional.module_inventory(ROOT)
    by_name = {path.stem: path for path in logs}
    if set(by_name) != set(required):
        raise RuntimeError(
            "module result inventory mismatch: "
            f"missing={sorted(set(required) - set(by_name))[:8]} "
            f"extra={sorted(set(by_name) - set(required))[:8]}")
    copy_regular(result_dir / "summary.txt", EVIDENCE / "raw/module-summary.txt")
    records = []
    for test_id in sorted(required):
        destination = EVIDENCE / "raw/module" / f"{test_id}.log"
        copy_regular(by_name[test_id], destination)
        records.append({
            "test_id": test_id,
            "compile_rc": 0,
            "simulation_rc": 0,
            "raw_log": rel(destination),
        })
    return command, records


def official_phase() -> tuple[str, list[dict[str, Any]]]:
    log_base = CACHE / "official-runs"
    args = [
        str(NPC / "testsuites/scripts/npc-rv64-core-regress.sh"),
        "--riscv-tests", "--riscv-privileged",
        "--riscv-tests-dir", str(OFFICIAL_TREE),
        "--skip-module", "--skip-lint", "--skip-build", "--skip-am",
        "--riscv-max-cycles", "2000000",
        "--log-base", str(log_base),
    ]
    command = run_command(
        "official-177", args, EVIDENCE / "raw/official-run.log",
        env={
            "NPC_RV64_BIN": str(SIMULATOR_FROZEN),
            "AM_HOME": str(AM_HOME),
            "NEMU_HOME": str(NEMU),
        })
    latest = log_base / "latest"
    if not latest.is_symlink():
        raise RuntimeError("official runner did not publish its local latest pointer")
    run_dir = latest.resolve(strict=True)
    ensure_within(run_dir, log_base)
    logs = sorted((run_dir / "riscv-log").glob("*.log"))
    bins = sorted((run_dir / "riscv-bin").glob("*.bin"))
    log_map = {path.name.removesuffix(".log"): path for path in logs}
    bin_map = {path.name.removesuffix(".bin"): path for path in bins}
    if len(log_map) != 177 or set(log_map) != set(bin_map):
        raise RuntimeError(
            f"official exact inventory requires 177 log/image pairs; "
            f"logs={len(log_map)} images={len(bin_map)}")
    status = (run_dir / "status.txt").read_text(encoding="utf-8")
    if "riscv-tests-count            INFO       177 tests attempted" not in status:
        raise RuntimeError("official status does not report exactly 177 attempted tests")
    copy_regular(run_dir / "status.txt", EVIDENCE / "raw/official-status.txt")
    copy_regular(run_dir / "summary.txt", EVIDENCE / "raw/official-summary.txt")
    records = []
    for test_id in sorted(log_map):
        if not re.search(rf"(?m)^{re.escape(test_id)}\s+PASS(?:\s|$)", status):
            raise RuntimeError(f"official status does not report PASS for {test_id}")
        log_destination = EVIDENCE / "raw/official" / f"{test_id}.log"
        image_destination = EVIDENCE / "images/official" / f"{test_id}.bin"
        copy_regular(log_map[test_id], log_destination)
        copy_regular(bin_map[test_id], image_destination)
        records.append({
            "test_id": test_id,
            "return_code": 0,
            "image": rel(image_destination),
            "raw_log": rel(log_destination),
        })
    return command, records


def am_make_args(*extra: str, max_cycles: int = 2_000_000) -> list[str]:
    diff_args = (
        f"-b --no-progress --max-cycles {max_cycles} "
        f"--diff={REFERENCE_FROZEN}")
    return [
        "make", *extra,
        f"AM_HOME={AM_HOME}", f"NEMU_HOME={NEMU}",
        f"NPC_HOME={ROOT / 'npc'}", "ARCH=riscv64-npc",
        "NPC_SIM_BACKEND=rv64", f"BUILD_DIR={SIM_BUILD}",
        "VERILATOR=verilator -Wno-fatal",
        f"NPC_RUN_ARGS={diff_args}",
    ]


def assert_simulator_binding() -> None:
    if not SIMULATOR.is_file() or not SIMULATOR_FROZEN.is_file():
        raise RuntimeError("runtime or frozen NPC simulator artifact is missing")
    if sha256_file(SIMULATOR) != sha256_file(SIMULATOR_FROZEN):
        raise RuntimeError(
            "runtime NPC simulator changed after the frozen same-design snapshot")


def am_phase() -> tuple[str, list[dict[str, Any]]]:
    raw_dir = CACHE / "am-raw"
    tests = sorted(path.stem for path in (CPU_TESTS / "tests").glob("*.c"))
    if len(tests) != 59 or len(tests) != len(set(tests)):
        raise RuntimeError(f"AM exact inventory requires 59 unique C tests, got {len(tests)}")
    args = am_make_args(
        "-C", str(CPU_TESTS), f"RAW_LOG_DIR={raw_dir}", "run")
    command = run_command("am-59-difftest", args, EVIDENCE / "raw/am-run.log")
    assert_simulator_binding()
    raw_map = {path.stem: path for path in raw_dir.glob("*.log")}
    if set(raw_map) != set(tests):
        raise RuntimeError(
            "AM raw-log inventory mismatch: "
            f"missing={sorted(set(tests) - set(raw_map))[:8]} "
            f"extra={sorted(set(raw_map) - set(tests))[:8]}")
    records = []
    for test_id in tests:
        image = CPU_TESTS / "build" / f"{test_id}-riscv64-npc.bin"
        if not image.is_file():
            raise RuntimeError(f"AM program image is missing: {image}")
        log_destination = EVIDENCE / "raw/am" / f"{test_id}.log"
        image_destination = EVIDENCE / "images/am" / f"{test_id}.bin"
        copy_regular(raw_map[test_id], log_destination)
        copy_regular(image, image_destination)
        records.append({
            "test_id": test_id,
            "return_code": 0,
            "image": rel(image_destination),
            "raw_log": rel(log_destination),
        })
    return command, records


def benchmark_phase(
    name: str,
    directory: pathlib.Path,
    extra: list[str],
    metrics: dict[str, Any],
    *,
    max_cycles: int,
) -> dict[str, Any]:
    raw = EVIDENCE / "raw" / f"{name}.log"
    # Benchmark Makefiles include $(AM_HOME)/Makefile even for clean, so the
    # standalone preparation step must carry the same local AM root binding as
    # the subsequent image build/run.
    clean_args = [
        "make", "-C", str(directory), f"AM_HOME={AM_HOME}", "clean"]
    clean_command = run_command(
        f"benchmark-{name}-image-clean", clean_args,
        EVIDENCE / "raw" / f"{name}-clean.log")
    args = am_make_args(
        "-C", str(directory), *extra, "run", max_cycles=max_cycles)
    run_display = run_command(f"benchmark-{name}", args, raw)
    command = f"{clean_command} && {run_display}"
    assert_simulator_binding()
    image = directory / "build" / f"{name}-riscv64-npc.bin"
    destination = EVIDENCE / "images/benchmarks" / f"{name}.bin"
    copy_regular(image, destination)
    return {
        "command": command,
        "return_code": 0,
        "image": rel(destination),
        "raw_log": rel(raw),
        **metrics,
    }


def main() -> int:
    try:
        reset_generated_dir(EVIDENCE, TASK)
        reset_generated_dir(CACHE, ROOT / ".github/cache")
        invalidate_current_outputs()
        build_logs = EVIDENCE / "raw/build-phases"
        config_command = run_command(
            "npc-default-config",
            ["make", "-C", str(NPC), "default_defconfig"],
            build_logs / "npc-default-config.log")
        reference_command = run_command(
            "nemu-reference-build",
            ["make", "-C", str(NPC), "difftest-ref"],
            build_logs / "nemu-reference-build.log")
        simulator_command = run_command(
            "npc-verilator-build",
            [
                "make", "-C", str(NPC), f"BUILD_DIR={SIM_BUILD}",
                "VERILATOR=verilator -Wno-fatal", "-j2", "default",
            ],
            build_logs / "npc-verilator-build.log")
        for path, label in (
            (NPC / ".config", "NPC configuration"),
            (SIMULATOR, "NPC simulator"),
            (REFERENCE_LIVE, "NEMU reference model"),
        ):
            if not path.is_file():
                raise RuntimeError(f"{label} artifact is missing: {path}")
        copy_regular(NPC / ".config", CONFIG_FROZEN)
        copy_regular(SIMULATOR, SIMULATOR_FROZEN, executable=True)
        copy_regular(REFERENCE_LIVE, REFERENCE_FROZEN, executable=True)
        if "CONFIG_NPC_DIFFTEST=y" not in CONFIG_FROZEN.read_text(encoding="utf-8"):
            raise RuntimeError("fresh NPC simulator configuration did not enable DiffTest")
        profile = reference_profile()
        merged_build = EVIDENCE / "raw/build.log"
        merge_logs(merged_build, [
            ("NPC-DEFAULT-CONFIG", build_logs / "npc-default-config.log"),
            ("NEMU-REFERENCE-BUILD", build_logs / "nemu-reference-build.log"),
            ("NPC-VERILATOR-BUILD", build_logs / "npc-verilator-build.log"),
        ])
        build_command = " && ".join(
            (config_command, reference_command, simulator_command))

        design_id = current_design_id()
        print(f"[F0-G1] current local RV64 design_id={design_id}", flush=True)
        module_command, module_records = module_phase()
        official_command, official_records = official_phase()
        am_command, am_records = am_phase()
        coremark = benchmark_phase(
            "coremark", COREMARK, ["ITERATIONS=10"],
            {"iterations": 10, "crc": "0xfcaf", "good_traps": 1},
            max_cycles=20_000_000)
        dhrystone = benchmark_phase(
            "dhrystone", DHRYSTONE, ["mainargs=10000"],
            {"runs": 10000, "good_traps": 1},
            max_cycles=20_000_000)

        descriptor = {
            "schema": functional.DESCRIPTOR_SCHEMA,
            "design_id": design_id,
            "cohort_id": COHORT_ID,
            "simulator": rel(SIMULATOR_FROZEN),
            "configuration": rel(CONFIG_FROZEN),
            "build": {
                "command": build_command,
                "return_code": 0,
                "raw_log": rel(merged_build),
            },
            "module": {"command": module_command, "tests": module_records},
            "official": {"command": official_command, "tests": official_records},
            "am": {"command": am_command, "tests": am_records},
            "difftest": {
                "command": am_command,
                "mismatches": 0,
                "reference": rel(REFERENCE_FROZEN),
                "reference_profile": rel(profile),
            },
            "benchmarks": {
                "coremark": coremark,
                "dhrystone": dhrystone,
            },
        }
        descriptor_path = EVIDENCE / "functional-run-descriptor.json"
        write_json(descriptor_path, descriptor)
        result = functional.assemble(
            root=ROOT,
            descriptor_path=descriptor_path,
            wrapper_dir=EVIDENCE / "wrapped",
            aggregate_path=ROOT / functional.freeze.F0_AGGREGATE_PATH
            if hasattr(functional.freeze, "F0_AGGREGATE_PATH")
            else ROOT / "npc/rv64/eval/ppa/evidence/functional-aggregate-current.json",
            mutation_summary_path=EVIDENCE / "mutations/summary.json",
            raw_log_path=ROOT / "npc/rv64/eval/ppa/evidence/functional-aggregate.log",
            result_path=ROOT / "npc/rv64/eval/ppa/evidence/functional-aggregate-result.json",
            check_current_design=True,
        )
        print(
            f"[F0-G1] PASS module={result['counts']['module_passed']}/"
            f"{result['counts']['module_required']} official=177/177 "
            f"am=59/59 difftest_mismatches=0",
            flush=True)
        return 0
    except (OSError, RuntimeError, ValueError, json.JSONDecodeError) as exc:
        print(f"[F0-G1] FAIL {exc}", file=sys.stderr, flush=True)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
