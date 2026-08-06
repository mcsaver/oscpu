#!/usr/bin/env python3
"""Build fail-closed same-design local RV64 functional evidence.

The input descriptor names only local simulator, configuration, program-image
and raw simulation artifacts.  This tool preserves each raw log inside a
provenance wrapper, assembles the v2 aggregate, validates it with the
architecture-freeze checker, and exercises schema-valid evidence mutations.
The AM inventory is an exact set supplied by the current source-derived runner;
its size is intentionally not a historical fixed constant.
"""

from __future__ import annotations

import argparse
import copy
import hashlib
import importlib.util
import json
import os
import pathlib
import re
import stat
import sys
from typing import Any, Callable


DESCRIPTOR_SCHEMA = "npc-rv64-functional-run-descriptor-v1"
MUTATION_SCHEMA = "npc-rv64-functional-evidence-mutations-v1"
CANONICAL_COMMAND = "make -C npc/rv64 check-functional-aggregate"
RUN_ID = "2026-07-22-rv64-v9l-functional-aggregate-current-design"
LOAD_ADDRESS = "0x0000000080000000"
ANSI_RE = re.compile(r"\x1b\[[0-?]*[ -/]*[@-~]")
GOOD_TRAP_LINE_RE = re.compile(
    r"^(?:HIT GOOD TRAP|(?:\[[^]\r\n]+\]\s+)?npc:\s+HIT GOOD TRAP\s+"
    r"at pc = 0x[0-9a-fA-F]+)$"
)

TOOL_PATH = pathlib.Path(__file__).resolve()
FREEZE_PATH = TOOL_PATH.with_name("arch_stable_freeze.py")
FREEZE_SPEC = importlib.util.spec_from_file_location(
    "functional_aggregate_arch_stable_freeze", FREEZE_PATH)
assert FREEZE_SPEC is not None and FREEZE_SPEC.loader is not None
freeze = importlib.util.module_from_spec(FREEZE_SPEC)
sys.modules[FREEZE_SPEC.name] = freeze
FREEZE_SPEC.loader.exec_module(freeze)
SCHEMA_VALID_MUTATION_IDS = freeze.F0_SCHEMA_VALID_MUTATION_IDS
SCHEMA_INVALID_MUTATION_IDS = freeze.F0_SCHEMA_INVALID_MUTATION_IDS
CANONICAL_MUTATION_IDS = freeze.F0_CANONICAL_MUTATION_IDS


def sha256_bytes(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def sha256_file(path: pathlib.Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def canonical_sha256(value: Any) -> str:
    encoded = json.dumps(
        value, allow_nan=False, ensure_ascii=False, sort_keys=True,
        separators=(",", ":"),
    ).encode("utf-8")
    return sha256_bytes(encoded)


def load_json(path: pathlib.Path) -> dict[str, Any]:
    with path.open("r", encoding="utf-8") as handle:
        value = json.load(handle, parse_constant=freeze.reject_json_constant)
    if not isinstance(value, dict):
        raise ValueError(f"{path}: top-level JSON must be an object")
    return value


def safe_file(root: pathlib.Path, relative: Any) -> pathlib.Path:
    path, error = freeze.safe_regular_file(root, relative)
    if error or path is None:
        raise ValueError(error or f"invalid artifact path: {relative!r}")
    return path


def artifact(root: pathlib.Path, relative: str, kind: str) -> dict[str, str]:
    path = safe_file(root, relative)
    return {
        "kind": kind,
        "path": relative,
        "sha256": sha256_file(path),
    }


def lexical_output_path(
    root: pathlib.Path, path: pathlib.Path
) -> tuple[pathlib.Path, pathlib.PurePosixPath]:
    root_resolved = root.resolve(strict=True)
    candidate = path if path.is_absolute() else root_resolved / path
    lexical = pathlib.Path(os.path.abspath(os.fspath(candidate)))
    try:
        relative = lexical.relative_to(root_resolved)
    except ValueError as exc:
        raise ValueError(f"output escapes repository: {path}") from exc
    if any(part in {"", ".", ".."} for part in relative.parts):
        raise ValueError(f"output path is not canonical: {path}")
    cursor = root_resolved
    for part in relative.parts:
        cursor = cursor / part
        if cursor.is_symlink():
            raise ValueError(f"output path contains symlink: {cursor}")
    return lexical, pathlib.PurePosixPath(*relative.parts)


def relative_path(root: pathlib.Path, path: pathlib.Path) -> str:
    _lexical, relative = lexical_output_path(root, path)
    return relative.as_posix()


def prepare_output(root: pathlib.Path, path: pathlib.Path) -> pathlib.Path:
    lexical, _relative = lexical_output_path(root, path)
    lexical.parent.mkdir(parents=True, exist_ok=True)
    if lexical.is_symlink():
        raise ValueError(f"refusing symlink output: {lexical}")
    return lexical


def write_text(root: pathlib.Path, path: pathlib.Path, text: str) -> pathlib.Path:
    target = prepare_output(root, path)
    target.write_text(text, encoding="utf-8")
    return target


def write_json(root: pathlib.Path, path: pathlib.Path, value: Any) -> pathlib.Path:
    return write_text(
        root, path,
        json.dumps(value, allow_nan=False, ensure_ascii=False,
                   indent=2, sort_keys=True) + "\n",
    )


def exact_keys(value: Any, expected: set[str], label: str) -> dict[str, Any]:
    if not isinstance(value, dict) or set(value) != expected:
        actual = sorted(value) if isinstance(value, dict) else type(value).__name__
        raise ValueError(
            f"{label}: exact fields required={sorted(expected)} actual={actual}")
    return value


def nonempty_string(value: Any, label: str) -> str:
    if not isinstance(value, str) or not value.strip():
        raise ValueError(f"{label}: expected a non-empty string")
    return value


def strip_ansi(text: str) -> str:
    return ANSI_RE.sub("", text)


def raw_text(root: pathlib.Path, relative: Any, label: str) -> tuple[str, str]:
    relative_value = nonempty_string(relative, f"{label}.raw_log")
    path = safe_file(root, relative_value)
    try:
        text = path.read_text(encoding="utf-8")
    except UnicodeError as exc:
        raise ValueError(f"{label}: raw log is not UTF-8: {exc}") from exc
    return relative_value, text


def source_markers(root: pathlib.Path, relative: str) -> list[str]:
    path = safe_file(root, relative)
    return [
        f"source_log_path={relative}",
        f"source_log_sha256={sha256_file(path)}",
    ]


def validate_benchmark_raw_output(name: str, text: str) -> None:
    """Bind benchmark claims to guest-emitted result lines, not argv text."""
    lines = [line.strip() for line in strip_ansi(text).splitlines()]
    if name == "coremark":
        requirements = (
            re.compile(r"^Running CoreMark for 10 iterations$"),
            re.compile(r"^Iterations\s*:\s*10$"),
            re.compile(r"^\[0\]crcfinal\s*:\s*0xfcaf$", re.IGNORECASE),
            re.compile(r"^CoreMark PASS\s+[0-9]+ Marks$"),
        )
        forbidden = ("Errors detected", "CoreMark FAIL")
        semantic_lines = (
            re.compile(r"^Running CoreMark for .* iterations$"),
            re.compile(r"^Iterations\s*:.*$"),
            re.compile(r"^\[0\]crcfinal\s*:.*$", re.IGNORECASE),
            re.compile(r"^CoreMark PASS.*$"),
        )
    elif name == "dhrystone":
        requirements = (
            re.compile(r"^Trying 10000 runs through Dhrystone\.$"),
            re.compile(r"^Dhrystone PASS\s+[0-9]+ Marks$"),
        )
        forbidden = ("Dhrystone FAIL",)
        semantic_lines = (
            re.compile(r"^Trying .* runs through Dhrystone\.$"),
            re.compile(r"^Dhrystone PASS.*$"),
        )
    else:
        raise ValueError(f"unknown benchmark oracle: {name}")
    match_counts = {
        pattern.pattern: sum(pattern.fullmatch(line) is not None for line in lines)
        for pattern in requirements
    }
    missing = [pattern for pattern, count in match_counts.items() if count == 0]
    duplicate = [pattern for pattern, count in match_counts.items() if count > 1]
    contradictory_values = [
        line
        for line in lines
        if any(pattern.fullmatch(line) for pattern in semantic_lines)
        and not any(pattern.fullmatch(line) for pattern in requirements)
    ]
    contradictory = [marker for marker in forbidden if any(
        marker in line for line in lines
    )]
    trap_count = sum(
        GOOD_TRAP_LINE_RE.fullmatch(line) is not None for line in lines
    )
    if missing or duplicate or contradictory_values or contradictory or trap_count != 1:
        raise ValueError(
            f"benchmark:{name}: guest result markers drifted: "
            f"missing={missing} duplicate={duplicate} "
            f"contradictory_values={contradictory_values} "
            f"contradictory={contradictory} good_traps={trap_count}"
        )


def common_markers(
    descriptor: dict[str, Any], command: str,
) -> list[str]:
    return [
        f"design_id={descriptor['design_id']}",
        f"cohort_id={descriptor['cohort_id']}",
        f"program_image_canonicalization={freeze.PROGRAM_IMAGE_CANONICALIZATION}",
        f"simulator_sha256={descriptor['_simulator_artifact']['sha256']}",
        f"config_sha256={descriptor['_configuration_artifact']['sha256']}",
        f"command_sha256={sha256_bytes(command.encode('utf-8'))}",
    ]


def wrapper_text(markers: list[str], source: str = "", result: str | None = None) -> str:
    parts = ["\n".join(markers), ""]
    if source:
        parts.extend(("[SOURCE-LOG-BEGIN]", source.rstrip("\n"), "[SOURCE-LOG-END]"))
    if result is not None:
        parts.append(result)
    return "\n".join(parts) + "\n"


def module_inventory(root: pathlib.Path) -> list[str]:
    makefile = safe_file(root, "npc/rv64/testbench/Makefile")
    tests, errors = freeze.parse_required_tests(
        makefile.read_text(encoding="utf-8"))
    if errors:
        raise ValueError("module inventory: " + "; ".join(errors))
    return tests


def inventory_sha(suite: str, test_ids: list[str]) -> str:
    return canonical_sha256({
        "schema": "npc-rv64-test-inventory-v1",
        "suite": suite,
        "test_ids": sorted(test_ids),
    })


def image_set_sha(suite: str, images: list[dict[str, Any]]) -> str:
    records = [{
        "suite": suite,
        "test_id": item["test_id"],
        "image_sha256": item["image"]["sha256"],
        "load_address": item["load_address"],
        "entry_pc": item["entry_pc"],
    } for item in images]
    return canonical_sha256({
        "schema": freeze.PROGRAM_IMAGE_CANONICALIZATION,
        "suite": suite,
        "images": sorted(records, key=lambda item: item["test_id"]),
    })


def minimal_freeze_groups(aggregate: dict[str, Any]) -> dict[str, list[dict[str, str]]]:
    images: list[dict[str, str]] = []
    for suite in ("official", "am"):
        for item in aggregate[suite]["images"]:
            images.append(item["image"])
    images.extend(
        aggregate["benchmarks"][name]["image"]
        for name in ("coremark", "dhrystone")
    )
    return {
        "config": [aggregate["configuration"]],
        "binaries": [
            aggregate["simulator"], aggregate["difftest"]["reference"],
        ],
        "images": images,
    }


def validate_aggregate(
    root: pathlib.Path, aggregate: dict[str, Any], required_tests: list[str],
) -> tuple[list[dict[str, Any]], list[str], dict[str, Any]]:
    return freeze.validate_functional(
        root=root,
        functional=aggregate,
        expected_design_id=aggregate.get("design_id", ""),
        cohort_id=aggregate.get("cohort_id", ""),
        required_tests=required_tests,
        freeze_groups=minimal_freeze_groups(aggregate),
    )


def validate_descriptor(root: pathlib.Path, value: dict[str, Any]) -> None:
    exact_keys(value, {
        "schema", "design_id", "cohort_id", "simulator", "configuration",
        "build", "module", "official", "am", "difftest", "benchmarks",
    }, "descriptor")
    if value["schema"] != DESCRIPTOR_SCHEMA:
        raise ValueError(f"descriptor.schema must equal {DESCRIPTOR_SCHEMA}")
    if not freeze.DESIGN_ID_RE.fullmatch(str(value["design_id"])):
        raise ValueError("descriptor.design_id is not a sha256 design identifier")
    nonempty_string(value["cohort_id"], "descriptor.cohort_id")
    safe_file(root, value["simulator"])
    safe_file(root, value["configuration"])

    build = exact_keys(value["build"], {"command", "return_code", "raw_log"}, "build")
    nonempty_string(build["command"], "build.command")
    if build["return_code"] != 0:
        raise ValueError("build.return_code must equal zero")
    raw_text(root, build["raw_log"], "build")

    module = exact_keys(value["module"], {"command", "tests"}, "module")
    nonempty_string(module["command"], "module.command")
    if not isinstance(module["tests"], list):
        raise ValueError("module.tests must be an array")
    for index, record in enumerate(module["tests"]):
        item = exact_keys(record, {
            "test_id", "compile_rc", "simulation_rc", "raw_log",
        }, f"module.tests[{index}]")
        if item["compile_rc"] != 0 or item["simulation_rc"] != 0:
            raise ValueError(f"module test {item['test_id']} did not pass")
        raw_text(root, item["raw_log"], f"module:{item['test_id']}")

    for suite_name in ("official", "am"):
        suite = exact_keys(value[suite_name], {"command", "tests"}, suite_name)
        nonempty_string(suite["command"], f"{suite_name}.command")
        if not isinstance(suite["tests"], list):
            raise ValueError(f"{suite_name}.tests must be an array")
        for index, record in enumerate(suite["tests"]):
            item = exact_keys(record, {
                "test_id", "return_code", "image", "raw_log",
            }, f"{suite_name}.tests[{index}]")
            if item["return_code"] != 0:
                raise ValueError(f"{suite_name} test {item['test_id']} did not pass")
            safe_file(root, item["image"])
            raw_text(root, item["raw_log"], f"{suite_name}:{item['test_id']}")

    difftest = exact_keys(value["difftest"], {
        "command", "mismatches", "reference", "reference_profile",
    }, "difftest")
    nonempty_string(difftest["command"], "difftest.command")
    if difftest["mismatches"] != 0:
        raise ValueError("difftest.mismatches must equal zero")
    safe_file(root, difftest["reference"])
    safe_file(root, difftest["reference_profile"])

    benchmarks = exact_keys(value["benchmarks"], {"coremark", "dhrystone"}, "benchmarks")
    expected = {
        "coremark": {"iterations", "crc", "good_traps"},
        "dhrystone": {"runs", "good_traps"},
    }
    for name, metrics in expected.items():
        record = exact_keys(
            benchmarks[name],
            {"command", "return_code", "image", "raw_log", *metrics},
            f"benchmarks.{name}",
        )
        nonempty_string(record["command"], f"benchmarks.{name}.command")
        if record["return_code"] != 0:
            raise ValueError(f"benchmark {name} did not pass")
        safe_file(root, record["image"])
        raw_text(root, record["raw_log"], f"benchmark:{name}")


def require_raw_markers(text: str, required: list[str], forbidden: list[str], label: str) -> None:
    clean = strip_ansi(text)
    missing = [marker for marker in required if marker not in clean]
    present = [marker for marker in forbidden if marker in clean]
    if missing or present:
        raise ValueError(f"{label}: raw evidence missing={missing} forbidden={present}")


def validate_suite_raw_output(name: str, text: str, *, test_id: str) -> None:
    """Reconstruct official/AM architectural terminal semantics from guest output."""
    clean = strip_ansi(text)
    if name == "official":
        require_raw_markers(
            clean,
            [],
            ["[RESULT] FAIL", "ABORT at pc", "TOHOST FAIL", "HIT BAD TRAP"],
            f"official:{test_id}",
        )
        terminal_count = sum(
            "TOHOST PASS" in line or "HIT GOOD TRAP" in line
            for line in clean.splitlines()
        )
        if terminal_count != 1:
            raise ValueError(
                f"official:{test_id}: architectural terminal count is "
                f"{terminal_count}, expected 1"
            )
        return
    if name != "am":
        raise ValueError(f"unknown functional suite oracle: {name}")
    require_raw_markers(
        clean,
        ["HIT GOOD TRAP", "Difftest:"],
        [
            "[RESULT] FAIL", "ABORT at pc", "difftest mismatch",
            "TOHOST FAIL", "HIT BAD TRAP",
        ],
        f"am:{test_id}",
    )
    states = re.findall(r"Difftest:\s*(ON|OFF)", clean)
    if states != ["ON"]:
        raise ValueError(
            f"am:{test_id}: DiffTest is not ON exclusively: {states}"
        )
    terminal_count = sum(
        "HIT GOOD TRAP" in line for line in clean.splitlines()
    )
    if terminal_count != 1:
        raise ValueError(
            f"am:{test_id}: architectural terminal count is "
            f"{terminal_count}, expected 1"
        )


def build_aggregate(
    root: pathlib.Path,
    descriptor: dict[str, Any],
    wrapper_dir: pathlib.Path,
) -> tuple[dict[str, Any], list[str]]:
    validate_descriptor(root, descriptor)
    required_tests = module_inventory(root)
    descriptor = copy.deepcopy(descriptor)
    descriptor["_simulator_artifact"] = artifact(
        root, descriptor["simulator"], "simulator_binary")
    descriptor["_configuration_artifact"] = artifact(
        root, descriptor["configuration"], "kconfig")
    wrapper_dir.mkdir(parents=True, exist_ok=True)

    build = descriptor["build"]
    build_raw_path, build_raw = raw_text(root, build["raw_log"], "build")
    if "[RESULT] FAIL" in build_raw:
        raise ValueError("build raw log contains a failed result marker")
    build_log_path = wrapper_dir / "build.log"
    write_text(root, build_log_path, wrapper_text([
        *common_markers(descriptor, build["command"]),
        *source_markers(root, build_raw_path),
        "return_code=0",
    ], build_raw, "[RESULT] PASS"))
    build_value = {
        "command": build["command"],
        "return_code": 0,
        "log": artifact(root, relative_path(root, build_log_path), "simulator_build_log"),
    }

    module_command = descriptor["module"]["command"]
    module_records = sorted(descriptor["module"]["tests"], key=lambda item: item["test_id"])
    module_ids = [item["test_id"] for item in module_records]
    if len(module_ids) != len(set(module_ids)) or set(module_ids) != set(required_tests):
        raise ValueError(
            "module exact inventory mismatch: "
            f"missing={sorted(set(required_tests) - set(module_ids))[:8]} "
            f"extra={sorted(set(module_ids) - set(required_tests))[:8]}")
    module_values: list[dict[str, Any]] = []
    for record in module_records:
        test_id = record["test_id"]
        source_path, source = raw_text(root, record["raw_log"], f"module:{test_id}")
        clean = strip_ansi(source)
        if clean.splitlines().count("[RESULT] PASS") != 1 \
                or "[RESULT] FAIL" in clean:
            raise ValueError(f"module:{test_id}: expected one raw PASS and no raw FAIL")
        log_path = wrapper_dir / "module" / f"{test_id}.log"
        write_text(root, log_path, wrapper_text([
            *common_markers(descriptor, module_command),
            f"test_id={test_id}",
            "compile_rc=0",
            "simulation_rc=0",
            *source_markers(root, source_path),
        ], source))
        wrapped = log_path.read_text(encoding="utf-8")
        module_values.append({
            "test_id": test_id,
            "compile_rc": 0,
            "simulation_rc": 0,
            "pass_markers": wrapped.splitlines().count("[RESULT] PASS"),
            "fail_markers": wrapped.splitlines().count("[RESULT] FAIL"),
            "log": artifact(root, relative_path(root, log_path), "module_test_log"),
        })
    module_value = {
        "command": module_command,
        "required": len(required_tests),
        "passed": len(required_tests),
        "failed": 0,
        "tests": module_values,
    }

    reference = artifact(
        root, descriptor["difftest"]["reference"], "reference_model_binary")
    reference_profile = artifact(
        root, descriptor["difftest"]["reference_profile"],
        "reference_model_profile")

    suite_sources: dict[str, list[dict[str, str]]] = {}

    def build_suite(name: str, expected_count: int, difftest_enabled: bool) -> dict[str, Any]:
        source_records = sorted(
            descriptor[name]["tests"], key=lambda item: item["test_id"])
        ids = [item["test_id"] for item in source_records]
        if len(ids) != expected_count or len(ids) != len(set(ids)):
            raise ValueError(
                f"{name}: expected {expected_count} unique tests, got {len(ids)}")
        command = descriptor[name]["command"]
        images: list[dict[str, Any]] = []
        source_bindings: list[dict[str, str]] = []
        for record in source_records:
            test_id = record["test_id"]
            source_path, source = raw_text(root, record["raw_log"], f"{name}:{test_id}")
            validate_suite_raw_output(name, source, test_id=test_id)
            image = artifact(root, record["image"], "program_image")
            log_path = wrapper_dir / name / f"{test_id}.log"
            markers = [
                *common_markers(descriptor, command),
                f"suite={name}",
                f"test_id={test_id}",
                f"image_sha256={image['sha256']}",
                f"load_address={LOAD_ADDRESS}",
                f"entry_pc={LOAD_ADDRESS}",
                *source_markers(root, source_path),
            ]
            if difftest_enabled:
                markers.extend((
                    f"difftest_reference_sha256={reference['sha256']}",
                    f"difftest_reference_profile_sha256={reference_profile['sha256']}",
                ))
            write_text(root, log_path, wrapper_text(markers, source, "[RESULT] PASS"))
            images.append({
                "test_id": test_id,
                "load_address": LOAD_ADDRESS,
                "entry_pc": LOAD_ADDRESS,
                "image": image,
                "log": artifact(
                    root, relative_path(root, log_path),
                    "am_test_log" if difftest_enabled else "official_test_log"),
            })
            source_bindings.append({
                "test_id": test_id,
                "raw_log_path": source_path,
                "raw_log_sha256": sha256_file(safe_file(root, source_path)),
            })
        inv_sha = inventory_sha(name, ids)
        images_sha = image_set_sha(name, images)
        suite_log_path = wrapper_dir / f"{name}.log"
        suite_markers = [
            *common_markers(descriptor, command),
            f"suite={name}",
            f"inventory_sha256={inv_sha}",
            f"image_set_sha256={images_sha}",
        ]
        if difftest_enabled:
            suite_markers.extend((
                f"difftest_reference_sha256={reference['sha256']}",
                f"difftest_reference_profile_sha256={reference_profile['sha256']}",
            ))
        suite_markers.extend(f"[TEST] {test_id} PASS" for test_id in ids)
        suite_markers.append("[SUITE] PASS")
        write_text(root, suite_log_path, "\n".join(suite_markers) + "\n")
        suite_sources[name] = source_bindings
        value: dict[str, Any] = {
            "command": command,
            "required": expected_count,
            "passed": expected_count,
            "failed": 0,
            "inventory": ids,
            "inventory_sha256": inv_sha,
            "image_set_sha256": images_sha,
            "images": images,
            "log": artifact(
                root, relative_path(root, suite_log_path),
                "am_suite_log" if difftest_enabled else "official_suite_log"),
        }
        if difftest_enabled:
            value["difftest_enabled"] = True
        return value

    official_value = build_suite("official", 177, False)
    am_descriptor = descriptor.get("am")
    am_records = am_descriptor.get("tests") if isinstance(am_descriptor, dict) else None
    if not isinstance(am_records, list) or not am_records:
        raise ValueError("am: current exact test inventory is empty")
    am_value = build_suite("am", len(am_records), True)

    diff_command = descriptor["difftest"]["command"]
    diff_log_path = wrapper_dir / "difftest.log"
    diff_lines = [
        *common_markers(descriptor, diff_command),
        "suite=am",
        f"image_set_sha256={am_value['image_set_sha256']}",
        f"difftest_reference_sha256={reference['sha256']}",
        f"difftest_reference_profile_sha256={reference_profile['sha256']}",
        "mismatches=0",
    ]
    diff_lines.extend(
        f"am_source_log_sha256[{item['test_id']}]={item['raw_log_sha256']}"
        for item in suite_sources["am"]
    )
    diff_lines.append("[RESULT] PASS")
    write_text(root, diff_log_path, "\n".join(diff_lines) + "\n")
    difftest_value = {
        "command": diff_command,
        "applicable": True,
        "mismatches": 0,
        "suite": "am",
        "image_set_sha256": am_value["image_set_sha256"],
        "reference": reference,
        "reference_profile": reference_profile,
        "log": artifact(root, relative_path(root, diff_log_path), "difftest_log"),
    }

    benchmark_requirements = {
        "coremark": {"iterations": 10, "crc": "0xfcaf", "good_traps": 1},
        "dhrystone": {"runs": 10000, "good_traps": 1},
    }
    benchmark_values: dict[str, Any] = {}
    for name, expected in benchmark_requirements.items():
        record = descriptor["benchmarks"][name]
        if any(record.get(key) != value for key, value in expected.items()):
            raise ValueError(f"benchmark:{name}: metrics differ from {expected}")
        source_path, source = raw_text(root, record["raw_log"], f"benchmark:{name}")
        clean = strip_ansi(source)
        require_raw_markers(
            clean, ["HIT GOOD TRAP"], ["ABORT at pc", "[RESULT] FAIL"],
            f"benchmark:{name}")
        if clean.count("HIT GOOD TRAP") != expected["good_traps"]:
            raise ValueError(f"benchmark:{name}: GOOD TRAP count drifted")
        validate_benchmark_raw_output(name, clean)
        image = artifact(root, record["image"], "program_image")
        command = record["command"]
        log_path = wrapper_dir / f"{name}.log"
        markers = [
            *common_markers(descriptor, command),
            f"image_sha256={image['sha256']}",
            *source_markers(root, source_path),
            "return_code=0",
            *(f"{key}={value}" for key, value in expected.items()),
        ]
        write_text(root, log_path, wrapper_text(markers, source, "[RESULT] PASS"))
        benchmark_values[name] = {
            "command": command,
            "return_code": 0,
            "image": image,
            "log": artifact(root, relative_path(root, log_path), "benchmark_log"),
            **expected,
        }

    aggregate = {
        "schema": freeze.FUNCTIONAL_SCHEMA,
        "design_id": descriptor["design_id"],
        "cohort_id": descriptor["cohort_id"],
        "program_image_canonicalization": freeze.PROGRAM_IMAGE_CANONICALIZATION,
        "simulator": descriptor["_simulator_artifact"],
        "configuration": descriptor["_configuration_artifact"],
        "build": build_value,
        "module": module_value,
        "official": official_value,
        "am": am_value,
        "difftest": difftest_value,
        "benchmarks": benchmark_values,
    }
    schema_issues = freeze.schema_errors(root, aggregate, freeze.FUNCTIONAL_SCHEMA)
    if schema_issues:
        raise ValueError("functional aggregate schema: " + "; ".join(schema_issues[:8]))
    checks, blockers, _ = validate_aggregate(root, aggregate, required_tests)
    if blockers:
        raise ValueError("functional aggregate validation: " + "; ".join(blockers[:8]))
    return aggregate, required_tests


def run_mutations(
    root: pathlib.Path,
    aggregate: dict[str, Any],
    required_tests: list[str],
    mutation_dir: pathlib.Path,
    *,
    prepare_inputs: bool = True,
) -> dict[str, Any]:
    if prepare_inputs:
        mutation_dir.mkdir(parents=True, exist_ok=True)
    elif not mutation_dir.is_dir() or mutation_dir.is_symlink():
        raise ValueError("functional mutation replay input directory is missing")
    cases: list[tuple[str, Callable[[dict[str, Any]], None], bool]] = []

    def add(name: str, mutate: Callable[[dict[str, Any]], None], schema_valid: bool) -> None:
        cases.append((name, mutate, schema_valid))

    def swap_official_images(value: dict[str, Any]) -> None:
        first, second = value["official"]["images"][:2]
        first["image"], second["image"] = second["image"], first["image"]
        value["official"]["image_set_sha256"] = image_set_sha(
            "official", value["official"]["images"])

    def duplicate_official_image(value: dict[str, Any]) -> None:
        value["official"]["images"][1]["image"] = copy.deepcopy(
            value["official"]["images"][0]["image"])
        value["official"]["image_set_sha256"] = image_set_sha(
            "official", value["official"]["images"])

    def reuse_module_log(value: dict[str, Any]) -> None:
        value["module"]["tests"][1]["log"] = copy.deepcopy(
            value["module"]["tests"][0]["log"])

    duplicate_marker_path = mutation_dir / "module-duplicate-result.log"
    first_module_log = safe_file(root, aggregate["module"]["tests"][0]["log"]["path"])
    duplicate_marker_text = (
        first_module_log.read_text(encoding="utf-8") + "[RESULT] PASS\n"
    )
    if prepare_inputs:
        write_text(root, duplicate_marker_path, duplicate_marker_text)
    else:
        existing_duplicate = safe_file(root, relative_path(root, duplicate_marker_path))
        if existing_duplicate.read_text(encoding="utf-8") != duplicate_marker_text:
            raise ValueError("functional duplicate-marker replay input drifted")

    def duplicate_module_marker(value: dict[str, Any]) -> None:
        value["module"]["tests"][0]["log"] = artifact(
            root, relative_path(root, duplicate_marker_path), "module_test_log")
        value["module"]["tests"][0]["pass_markers"] = 2

    def stale_hash(path: tuple[str, ...], fill: str) -> Callable[[dict[str, Any]], None]:
        def mutate(value: dict[str, Any]) -> None:
            node: Any = value
            for key in path[:-1]:
                node = node[key]
            node[path[-1]] = fill * 64
        return mutate

    def changed_official_membership(value: dict[str, Any]) -> None:
        value["official"]["inventory"][0] += "_changed"
        value["official"]["inventory_sha256"] = inventory_sha(
            "official", value["official"]["inventory"])

    add("official_test_to_image_swap", swap_official_images, True)
    add("official_duplicate_image_file_identity", duplicate_official_image, True)
    add("official_stale_image_set_digest", stale_hash(("official", "image_set_sha256"), "0"), True)
    add("difftest_am_map_mismatch", stale_hash(("difftest", "image_set_sha256"), "1"), True)
    add("stale_simulator_digest", stale_hash(("simulator", "sha256"), "2"), True)
    add("stale_configuration_digest", stale_hash(("configuration", "sha256"), "3"), True)
    add("stale_reference_digest", stale_hash(("difftest", "reference", "sha256"), "4"), True)
    add("stale_reference_profile_digest", stale_hash(("difftest", "reference_profile", "sha256"), "5"), True)
    add("module_log_file_reuse", reuse_module_log, True)
    add("module_duplicate_pass_marker", duplicate_module_marker, True)
    add("official_membership_substitution", changed_official_membership, True)

    def remove_official_image(value: dict[str, Any]) -> None:
        value["official"]["images"].pop()

    def duplicate_inventory_id(value: dict[str, Any]) -> None:
        value["am"]["inventory"][1] = value["am"]["inventory"][0]

    def alter_coremark_crc(value: dict[str, Any]) -> None:
        value["benchmarks"]["coremark"]["crc"] = "0x0000"

    add("official_missing_image_record", remove_official_image, False)
    add("am_duplicate_inventory_id", duplicate_inventory_id, False)
    add("coremark_crc_change", alter_coremark_crc, False)

    observed_ids = tuple(name for name, _, _ in cases)
    if observed_ids != CANONICAL_MUTATION_IDS:
        raise ValueError(
            "functional mutation implementation inventory drift: "
            f"observed={observed_ids} expected={CANONICAL_MUTATION_IDS}"
        )

    records: list[dict[str, Any]] = []
    schema_valid_count = 0
    schema_valid_rejected = 0
    for name, mutator, expected_schema_valid in cases:
        # Canonicalize mapping order before mutation so schema rejection
        # reasons are byte-stable when the frozen aggregate is reloaded.
        mutant = json.loads(json.dumps(
            aggregate,
            allow_nan=False,
            ensure_ascii=False,
            sort_keys=True,
        ))
        mutator(mutant)
        schema_issues = freeze.schema_errors(root, mutant, freeze.FUNCTIONAL_SCHEMA)
        schema_valid = not schema_issues
        if schema_valid != expected_schema_valid:
            raise ValueError(
                f"mutation {name}: schema_valid={schema_valid} expected={expected_schema_valid}; "
                + "; ".join(schema_issues[:4]))
        blockers: list[str] = []
        if schema_valid:
            schema_valid_count += 1
            _, blockers, _ = validate_aggregate(root, mutant, required_tests)
            if blockers:
                schema_valid_rejected += 1
        rejected = bool(schema_issues or blockers)
        if not rejected:
            raise ValueError(f"mutation {name}: changed evidence was accepted")
        records.append({
            "mutation_id": name,
            "schema_valid": schema_valid,
            "rejected": rejected,
            "mutant_canonical_sha256": canonical_sha256(mutant),
            "reasons": (schema_issues or blockers)[:4],
        })
    return {
        "schema": MUTATION_SCHEMA,
        "design_id": aggregate["design_id"],
        "cohort_id": aggregate["cohort_id"],
        "aggregate_schema": freeze.FUNCTIONAL_SCHEMA,
        "total": len(records),
        "schema_valid": schema_valid_count,
        "schema_invalid": len(records) - schema_valid_count,
        "schema_valid_rejected": schema_valid_rejected,
        "all_rejected": all(item["rejected"] for item in records),
        "mutations": records,
    }


def aggregate_log_text(
    aggregate: dict[str, Any], counts: dict[str, int], checks: list[dict[str, Any]]
) -> str:
    """Return the exact terminal summary consumed by current publication."""
    return freeze.f0_aggregate_log_text(aggregate, counts, checks)


def verify_current_design(root: pathlib.Path, expected: str) -> None:
    evaluator = freeze.load_workspace_module(
        root, "npc/rv64/eval/ppa/tools/architecture_hard_gates.py",
        "functional_aggregate_design_binding")
    design_hex, _ = evaluator.rtl_binding(root)
    current = f"sha256:{design_hex}"
    if current != expected:
        raise ValueError(
            f"descriptor design_id={expected} differs from current RTL design_id={current}")


def assemble(
    *,
    root: pathlib.Path,
    descriptor_path: pathlib.Path,
    wrapper_dir: pathlib.Path,
    aggregate_path: pathlib.Path,
    mutation_summary_path: pathlib.Path,
    raw_log_path: pathlib.Path,
    result_path: pathlib.Path,
    check_current_design: bool,
) -> dict[str, Any]:
    root = root.resolve()
    descriptor = load_json(safe_file(root, relative_path(root, descriptor_path)))
    if check_current_design:
        verify_current_design(root, descriptor.get("design_id", ""))
    aggregate, required_tests = build_aggregate(root, descriptor, wrapper_dir)
    write_json(root, aggregate_path, aggregate)
    mutations = run_mutations(root, aggregate, required_tests, wrapper_dir / "mutation-inputs")
    write_json(root, mutation_summary_path, mutations)
    checks, blockers, _ = validate_aggregate(root, aggregate, required_tests)
    if blockers:
        raise ValueError("published aggregate revalidation failed: " + "; ".join(blockers[:8]))

    counts = {
        "module_required": aggregate["module"]["required"],
        "module_passed": aggregate["module"]["passed"],
        "official_required": aggregate["official"]["required"],
        "official_passed": aggregate["official"]["passed"],
        "am_required": aggregate["am"]["required"],
        "am_passed": aggregate["am"]["passed"],
        "difftest_mismatches": aggregate["difftest"]["mismatches"],
        "evidence_mutations_compiled": mutations["schema_valid"],
        "evidence_mutations_rejected": mutations["schema_valid_rejected"],
    }
    write_text(root, raw_log_path, aggregate_log_text(aggregate, counts, checks))

    result = {
        "schema": freeze.FUNCTIONAL_RESULT_SCHEMA,
        "design_id": aggregate["design_id"],
        "cohort_id": aggregate["cohort_id"],
        "status": "PASS",
        "exit_code": 0,
        "canonical_command": CANONICAL_COMMAND,
        "aggregate": artifact(
            root, relative_path(root, aggregate_path), "functional_aggregate"),
        "raw_log": artifact(
            root, relative_path(root, raw_log_path), "raw_log"),
        "mutation_summary": artifact(
            root, relative_path(root, mutation_summary_path), "mutation_summary"),
        "counts": counts,
        "checks": checks,
    }
    result_schema_issues = freeze.schema_errors(
        root, result, freeze.FUNCTIONAL_RESULT_SCHEMA)
    if result_schema_issues:
        raise ValueError(
            "functional result schema: " + "; ".join(result_schema_issues[:8]))
    write_json(root, result_path, result)
    return result


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Assemble local RV64 same-design functional evidence")
    parser.add_argument("--root", type=pathlib.Path, required=True)
    parser.add_argument("--descriptor", type=pathlib.Path, required=True)
    parser.add_argument("--wrapper-dir", type=pathlib.Path, required=True)
    parser.add_argument("--aggregate", type=pathlib.Path, required=True)
    parser.add_argument("--mutation-summary", type=pathlib.Path, required=True)
    parser.add_argument("--raw-log", type=pathlib.Path, required=True)
    parser.add_argument("--result", type=pathlib.Path, required=True)
    parser.add_argument("--verify-current-design", action="store_true")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    try:
        result = assemble(
            root=args.root,
            descriptor_path=args.descriptor,
            wrapper_dir=args.wrapper_dir,
            aggregate_path=args.aggregate,
            mutation_summary_path=args.mutation_summary,
            raw_log_path=args.raw_log,
            result_path=args.result,
            check_current_design=args.verify_current_design,
        )
    except (OSError, ValueError, json.JSONDecodeError) as exc:
        print(f"[F0-G1-GATE] FAIL: {exc}", file=sys.stderr)
        return 1
    print(
        f"[F0-G1-GATE] PASS design_id={result['design_id']} "
        f"module={result['counts']['module_passed']}/"
        f"{result['counts']['module_required']} official=177/177 "
        f"am={result['counts']['am_passed']}/{result['counts']['am_required']}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
