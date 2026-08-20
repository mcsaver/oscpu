#!/usr/bin/env python3
"""Build and verify the current-design RV64 ACT4 L1 subcohort receipt."""

from __future__ import annotations

import argparse
import copy
import hashlib
import json
import os
import pathlib
import re
import sys
from typing import Any

import jsonschema


ROOT = pathlib.Path(__file__).resolve().parents[5]
TOOLS_DIR = ROOT / "npc/rv64/eval/ppa/tools"
if str(TOOLS_DIR) not in sys.path:
    sys.path.insert(0, str(TOOLS_DIR))

import architecture_hard_gates as architecture  # noqa: E402
import full_core_functional_evidence as full_core  # noqa: E402


SCHEMA = "npc-rv64-act4-current-v1"
INPUT_SCHEMA = "npc-rv64-act4-current-input-binding-v1"
POLICY_PATH = pathlib.Path(
    "npc/rv64/design/arch/act4-default-signoff-policy-v1.json"
)
SCHEMA_PATH = pathlib.Path(
    "npc/rv64/eval/ppa/schemas/act4-current-v1.schema.json"
)
CURRENT_RUNNER_PATH = pathlib.Path("npc/rv64/eval/ppa/run-act4-current.sh")
BACKEND_RUNNER_PATH = pathlib.Path(
    "am-kernels/arch-test/scripts/act4-npc-run.sh"
)
EXPECTED_CONFIG_FILES = (
    "link.ld",
    "run_cmd.txt",
    "rvmodel_macros.h",
    "sail-RVA22S64.yaml",
    "sail.json",
    "test_config.yaml",
)
EXPECTED_CONFIG_NAME = "npc-rv64-ooo-current"
EXPECTED_CASE_COUNT = 100
EXPECTED_GENERATED_CASE_COUNT = 101
EXPECTED_EXCLUDED_CASE = "priv/Sv/sv39_svnapot_not_supported_Smode"
ASSERTION_RE = re.compile(
    r"\[(V[0-9]+[A-Z]?-[^\]]*(DISJOINT|HANDOFF|INGRESS-DUP|"
    r"ASSERT[^\]]*FAIL)|S2-G1-TCOLL-INGRESS-DUP)\]|%Error:|"
    r"Assertion failed|RTL assertion|\[[^\]]*ASSERT[^\]]*FAIL"
)
RUN_RESULT_RE = re.compile(
    r"exit via tohost, value=0x[0-9A-Fa-f]+, code=0, "
    r"cycles=([0-9]+), commits=([0-9]+)"
)


class Act4Error(RuntimeError):
    """ACT4 evidence cannot support the current-design L1 claim."""


def reject_duplicate_keys(pairs: list[tuple[str, Any]]) -> dict[str, Any]:
    value: dict[str, Any] = {}
    for key, item in pairs:
        if key in value:
            raise Act4Error(f"duplicate JSON key: {key}")
        value[key] = item
    return value


def load_json(path: pathlib.Path) -> dict[str, Any]:
    path = repo_file(path)
    try:
        value = json.loads(
            path.read_text(encoding="utf-8"),
            object_pairs_hook=reject_duplicate_keys,
        )
    except (json.JSONDecodeError, UnicodeDecodeError) as exc:
        raise Act4Error(f"invalid JSON: {relative(path)}: {exc}") from exc
    if not isinstance(value, dict):
        raise Act4Error(f"expected JSON object: {relative(path)}")
    return value


def lexical_path(raw: pathlib.Path) -> pathlib.Path:
    candidate = raw if raw.is_absolute() else ROOT / raw
    lexical = pathlib.Path(os.path.abspath(os.fspath(candidate)))
    root = ROOT.resolve(strict=True)
    try:
        parts = lexical.relative_to(root).parts
    except ValueError as exc:
        raise Act4Error(f"path escapes workspace: {raw}") from exc
    cursor = root
    for part in parts:
        cursor = cursor / part
        if cursor.is_symlink():
            raise Act4Error(f"path uses a symlink: {raw}")
    return lexical


def repo_file(raw: pathlib.Path) -> pathlib.Path:
    path = lexical_path(raw)
    if not path.is_file():
        raise Act4Error(f"not a regular file: {raw}")
    return path


def repo_dir(raw: pathlib.Path) -> pathlib.Path:
    path = lexical_path(raw)
    if not path.is_dir():
        raise Act4Error(f"not a directory: {raw}")
    return path


def output_file(raw: pathlib.Path) -> pathlib.Path:
    path = lexical_path(raw)
    if path.exists() and not path.is_file():
        raise Act4Error(f"output is not a regular file: {raw}")
    if path.parent.exists() and not path.parent.is_dir():
        raise Act4Error(f"output parent is not a directory: {raw}")
    return path


def relative(path: pathlib.Path) -> str:
    return lexical_path(path).relative_to(ROOT.resolve(strict=True)).as_posix()


def sha256_file(path: pathlib.Path) -> str:
    digest = hashlib.sha256()
    with repo_file(path).open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def artifact(path: pathlib.Path, *, kind: str) -> dict[str, Any]:
    path = repo_file(path)
    return {
        "kind": kind,
        "path": relative(path),
        "sha256": sha256_file(path),
        "size_bytes": path.stat().st_size,
    }


def verify_artifact(value: Any, *, kind: str | None = None) -> pathlib.Path:
    if not isinstance(value, dict) or set(value) != {
        "kind", "path", "sha256", "size_bytes"
    }:
        raise Act4Error("artifact field set differs from exact contract")
    if kind is not None and value.get("kind") != kind:
        raise Act4Error(
            f"artifact kind mismatch: expected={kind} observed={value.get('kind')}"
        )
    path = repo_file(pathlib.Path(str(value.get("path", ""))))
    if sha256_file(path) != value.get("sha256"):
        raise Act4Error(f"artifact SHA-256 drifted: {value.get('path')}")
    if path.stat().st_size != value.get("size_bytes"):
        raise Act4Error(f"artifact size drifted: {value.get('path')}")
    return path


def atomic_json(path: pathlib.Path, value: dict[str, Any]) -> None:
    path = output_file(path)
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = path.with_name(path.name + ".tmp")
    if temporary.is_symlink():
        raise Act4Error(f"temporary output uses a symlink: {relative(temporary)}")
    temporary.write_text(
        json.dumps(value, indent=2, sort_keys=True, ensure_ascii=False,
                   allow_nan=False) + "\n",
        encoding="utf-8",
    )
    temporary.replace(path)


def atomic_text(path: pathlib.Path, value: str) -> None:
    path = output_file(path)
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = path.with_name(path.name + ".tmp")
    if temporary.is_symlink():
        raise Act4Error(f"temporary output uses a symlink: {relative(temporary)}")
    temporary.write_text(value, encoding="utf-8")
    temporary.replace(path)


def policy() -> dict[str, Any]:
    value = load_json(POLICY_PATH)
    if value.get("schema") != "npc-rv64-act4-default-signoff-policy-v1":
        raise Act4Error("ACT4 policy schema mismatch")
    if (
        value.get("config_name") != EXPECTED_CONFIG_NAME
        or value.get("config_profile") != EXPECTED_CONFIG_NAME
    ):
        raise Act4Error("ACT4 policy config mismatch")
    expected_suites = [
        {"id": "rv64i/I", "generated_cases": 51, "required_cases": 51},
        {"id": "rv64i/M", "generated_cases": 13, "required_cases": 13},
        {"id": "priv/Sv", "generated_cases": 33, "required_cases": 32},
        {"id": "priv/Svnapot", "generated_cases": 4, "required_cases": 4},
    ]
    if value.get("suites") != expected_suites:
        raise Act4Error("ACT4 policy suite inventory mismatch")
    if (
        value.get("generated_case_count") != EXPECTED_GENERATED_CASE_COUNT
        or value.get("required_case_count") != EXPECTED_CASE_COUNT
    ):
        raise Act4Error("ACT4 policy case count mismatch")
    excluded = value.get("excluded_cases")
    if (
        not isinstance(excluded, list)
        or len(excluded) != 1
        or not isinstance(excluded[0], dict)
        or excluded[0].get("case_id") != EXPECTED_EXCLUDED_CASE
        or not isinstance(excluded[0].get("reason"), str)
        or not excluded[0]["reason"]
    ):
        raise Act4Error("ACT4 policy exclusion contract mismatch")
    execution = value.get("execution")
    if not isinstance(execution, dict) or (
        execution.get("max_cycles_per_case") != 20_000_000
        or execution.get("host_timeout_seconds_per_case") != 60
        or execution.get("difftest") is not False
    ):
        raise Act4Error("ACT4 policy execution contract mismatch")
    return value


def config_manifest(config_dir: pathlib.Path) -> list[dict[str, Any]]:
    config_dir = repo_dir(config_dir)
    observed = sorted(
        path.name for path in config_dir.iterdir()
        if path.is_file() and not path.is_symlink()
    )
    if observed != list(EXPECTED_CONFIG_FILES):
        raise Act4Error(
            f"ACT4 config file set differs: expected={list(EXPECTED_CONFIG_FILES)} "
            f"observed={observed}"
        )
    test_config = (config_dir / "test_config.yaml").read_text(encoding="utf-8")
    if f"name: {EXPECTED_CONFIG_NAME}" not in test_config:
        raise Act4Error(
            f"ACT4 test_config does not name {EXPECTED_CONFIG_NAME}"
        )
    return [
        artifact(config_dir / name, kind="act4_config_file")
        for name in EXPECTED_CONFIG_FILES
    ]


def selected_elfs(
    elf_root: pathlib.Path, policy_value: dict[str, Any]
) -> tuple[list[dict[str, Any]], list[dict[str, Any]]]:
    elf_root = repo_dir(elf_root)
    records: list[dict[str, Any]] = []
    excluded_records: list[dict[str, Any]] = []
    excluded_by_id = {
        item["case_id"]: item["reason"]
        for item in policy_value["excluded_cases"]
    }
    for suite in policy_value["suites"]:
        suite_id = suite["id"]
        suite_dir = repo_dir(elf_root / suite_id)
        paths = sorted(suite_dir.glob("*.elf"), key=lambda path: path.name)
        if any(path.is_symlink() or not path.is_file() for path in paths):
            raise Act4Error(f"unsafe ACT4 ELF entry in suite {suite_id}")
        if len(paths) != suite["generated_cases"]:
            raise Act4Error(
                f"ACT4 suite count mismatch: {suite_id} "
                f"expected={suite['generated_cases']} observed={len(paths)}"
            )
        selected_in_suite = 0
        for path in paths:
            record = {
                "case_id": f"{suite_id}/{path.stem}",
                "suite": suite_id,
                "name": path.stem,
                "artifact": artifact(path, kind="act4_self_checking_elf"),
            }
            if record["case_id"] in excluded_by_id:
                excluded_records.append({
                    **record,
                    "reason": excluded_by_id[record["case_id"]],
                })
            else:
                records.append(record)
                selected_in_suite += 1
        if selected_in_suite != suite["required_cases"]:
            raise Act4Error(
                f"ACT4 selected suite count mismatch: {suite_id} "
                f"expected={suite['required_cases']} observed={selected_in_suite}"
            )
    if len(records) != policy_value["required_case_count"]:
        raise Act4Error("ACT4 selected ELF total differs from policy")
    if (
        len(records) + len(excluded_records)
        != policy_value["generated_case_count"]
        or [record["case_id"] for record in excluded_records]
        != [EXPECTED_EXCLUDED_CASE]
    ):
        raise Act4Error("ACT4 generated/excluded ELF inventory differs from policy")
    case_ids = [record["case_id"] for record in records]
    if len(set(case_ids)) != len(case_ids):
        raise Act4Error("ACT4 case identifiers are not unique")
    return records, excluded_records


def validate_l1_toolchain_binding(
    frozen_tools: Any,
    live_tools: Any,
) -> None:
    if not isinstance(frozen_tools, dict) or not isinstance(live_tools, dict):
        raise Act4Error("L1 frozen/live toolchain binding is malformed")
    optional_tools = {"riscv64-unknown-elf-gcc"}
    missing_tools = set(frozen_tools) - set(live_tools)
    extra_tools = set(live_tools) - set(frozen_tools)
    if (missing_tools | extra_tools) - optional_tools:
        raise Act4Error(
            "L1 frozen/live toolchain inventory drift: "
            f"missing={sorted(missing_tools)} extra={sorted(extra_tools)}"
        )
    for tool in sorted(set(frozen_tools) & set(live_tools)):
        if frozen_tools[tool] != live_tools[tool]:
            raise Act4Error(f"L1 frozen/live tool identity drift: {tool}")


def validate_l1_input_binding(
    frozen_inputs: dict[str, Any],
    live_inputs: dict[str, Any],
) -> None:
    """Bind ACT4 to the L1 DUT-execution closure, not replayed checkers.

    ``verify_functional_result`` already re-executes the current downstream
    checkers and freezes them in the ARCH_STABLE workflow inventory.  Requiring
    their historical bytes again here would turn checker maintenance into a
    second DUT run.  The shared projection removes only those named checker
    paths; RTL, testbench, runner, toolchain, configuration and workload inputs
    stay byte-exact.
    """

    frozen_execution = full_core.execution_relevant_inputs(frozen_inputs)
    live_execution = full_core.execution_relevant_inputs(live_inputs)
    for field in (
        "schema", "design_id", "required_tests", "official_test_ids",
        "am_test_ids", "groups",
    ):
        if frozen_execution.get(field) != live_execution.get(field):
            raise Act4Error(f"L1 frozen/live input drift: {field}")


def act4_execution_relevant_snapshot(value: dict[str, Any]) -> dict[str, Any]:
    """Project an ACT4 snapshot onto inputs that can affect guest execution.

    The checker is replayed against every retained ELF/log when a receipt is
    rebuilt.  Its old byte identity is execution provenance, not a reason to
    rerun unchanged guests.  Policy, runners, schema, RTL, L1 simulator,
    configuration and ELF identities remain exact.
    """

    projected = copy.deepcopy(value)
    workflow = projected.get("workflow_artifacts")
    if isinstance(workflow, dict):
        workflow.pop("checker", None)
    return projected


def current_l1_binding(
    l1_result_path: pathlib.Path, *, design_id: str
) -> dict[str, Any]:
    l1_result_path = repo_file(l1_result_path)
    try:
        value = full_core.verify_functional_result(
            l1_result_path,
            require_current_design=False,
            require_canonical_current=False,
        )
    except (OSError, RuntimeError, ValueError, json.JSONDecodeError) as exc:
        raise Act4Error(f"L1 functional result verification failed: {exc}") from exc
    if (
        value.get("schema")
        != "npc-rv64-full-core-functional-current-evidence-v1"
        or value.get("status") != "PASS"
        or value.get("design_id") != design_id
        or value.get("inputs_unchanged") is not True
    ):
        raise Act4Error("L1 functional result is not a current-design PASS")

    # Revalidate every frozen L1 source/control group against the live tree.
    # The historical L1 receipt also records workload compilers found through
    # PATH.  ACT4 reuses the already-frozen NpcSimTop binary and separately
    # binds its own ELF inventory, so an unavailable unknown-elf compiler is
    # not an execution-semantic drift.  No other input or tool identity may
    # differ.
    frozen_inputs_path = repo_file(
        pathlib.Path(str(value["inputs"]["pre"]["path"]))
    )
    frozen_inputs = load_json(frozen_inputs_path)
    live_inputs = full_core.capture_functional_inputs(
        full_core.load_legacy_runner(), full_core.module_evidence.required_tests()
    )
    validate_l1_input_binding(frozen_inputs, live_inputs)
    frozen_tools = frozen_inputs.get("toolchain")
    live_tools = live_inputs.get("toolchain")
    validate_l1_toolchain_binding(frozen_tools, live_tools)
    simulator = verify_artifact(
        value.get("artifacts", {}).get("simulator"), kind="simulator_binary"
    )
    configuration = verify_artifact(
        value.get("artifacts", {}).get("configuration"), kind="kconfig"
    )
    build_log = repo_file(l1_result_path.parent / "raw/build.log")
    build_text = build_log.read_text(encoding="utf-8", errors="replace")
    if "+define+OOO_ASSERT" not in build_text or "--assert" not in build_text:
        raise Act4Error("L1 NpcSimTop build is not assertion-enabled")
    return {
        "result": artifact(l1_result_path, kind="full_core_functional_current_result"),
        "simulator": artifact(simulator, kind="simulator_binary"),
        "configuration": artifact(configuration, kind="kconfig"),
        "build_log": artifact(build_log, kind="l1_simulator_build_log"),
        "ooo_assert_define": True,
    }


def capture_snapshot(
    *, l1_result: pathlib.Path, config_dir: pathlib.Path, elf_root: pathlib.Path
) -> dict[str, Any]:
    policy_value = policy()
    design_hex, rtl_files = architecture.rtl_binding(ROOT)
    design_id = f"sha256:{design_hex}"
    l1 = current_l1_binding(l1_result, design_id=design_id)
    elfs, excluded_elfs = selected_elfs(elf_root, policy_value)
    return {
        "schema": INPUT_SCHEMA,
        "design_id": design_id,
        "production_rtl_file_count": len(rtl_files),
        "production_rtl_manifest": dict(sorted(rtl_files.items())),
        "config_name": policy_value["config_name"],
        "config_directory": relative(repo_dir(config_dir)),
        "config_files": config_manifest(config_dir),
        "elf_root": relative(repo_dir(elf_root)),
        "elfs": elfs,
        "excluded_elfs": excluded_elfs,
        "l1": l1,
        "execution": {
            "target": "npc",
            "suites": [suite["id"] for suite in policy_value["suites"]],
            "generated_case_count": policy_value["generated_case_count"],
            "required_case_count": policy_value["required_case_count"],
            "max_cycles_per_case": 20_000_000,
            "host_timeout_seconds_per_case": 60,
            "difftest": False,
        },
        "workflow_artifacts": {
            "policy": artifact(POLICY_PATH, kind="act4_signoff_policy"),
            "backend_runner": artifact(
                BACKEND_RUNNER_PATH, kind="act4_backend_runner"
            ),
            "current_runner": artifact(
                CURRENT_RUNNER_PATH, kind="act4_current_runner"
            ),
            "checker": artifact(pathlib.Path(__file__), kind="act4_current_checker"),
            "schema": artifact(SCHEMA_PATH, kind="act4_current_schema"),
        },
    }


def write_execution_manifest(
    *, snapshot_path: pathlib.Path, output_path: pathlib.Path
) -> None:
    snapshot = load_json(snapshot_path)
    if snapshot.get("schema") != INPUT_SCHEMA:
        raise Act4Error("ACT4 execution manifest snapshot schema mismatch")
    live = capture_snapshot(
        l1_result=pathlib.Path(snapshot["l1"]["result"]["path"]),
        config_dir=pathlib.Path(snapshot["config_directory"]),
        elf_root=pathlib.Path(snapshot["elf_root"]),
    )
    if (
        act4_execution_relevant_snapshot(live)
        != act4_execution_relevant_snapshot(snapshot)
    ):
        raise Act4Error("ACT4 execution manifest snapshot differs from live inputs")
    lines = [str(ROOT / record["artifact"]["path"]) for record in snapshot["elfs"]]
    if len(lines) != EXPECTED_CASE_COUNT or len(set(lines)) != len(lines):
        raise Act4Error("ACT4 execution manifest cardinality differs")
    atomic_text(output_path, "\n".join(lines) + "\n")


def parse_case_status(path: pathlib.Path) -> tuple[dict[str, list[str]], list[str]]:
    lines = repo_file(path).read_text(encoding="utf-8").splitlines()
    cases: dict[str, list[str]] = {}
    count_lines: list[str] = []
    for line in lines:
        fields = line.split()
        if len(fields) < 2:
            raise Act4Error(f"malformed ACT4 status line: {line!r}")
        if fields[0] == "act4-count":
            count_lines.append(line)
            continue
        if fields[0] in cases:
            raise Act4Error(f"duplicate ACT4 status case: {fields[0]}")
        cases[fields[0]] = fields
    return cases, count_lines


def validate_cleanup(path: pathlib.Path, *, raw_dir: pathlib.Path) -> dict[str, Any]:
    value = load_json(path)
    if (
        value.get("schema") != "npc-rv64-act4-runtime-cleanup-v1"
        or value.get("status") != "PASS"
        or value.get("binary_tree_removed") is not True
        or value.get("objcopy_logs_removed") is not True
        or not isinstance(value.get("deleted_bytes"), int)
        or value["deleted_bytes"] < 0
    ):
        raise Act4Error("ACT4 cleanup receipt is not complete PASS")
    if (raw_dir / "act4-bin").exists():
        raise Act4Error("ACT4 runtime binary tree remains after cleanup")
    if list((raw_dir / "act4-log").glob("*.objcopy.log")):
        raise Act4Error("ACT4 objcopy logs remain after cleanup")
    return value


def case_records(
    *, raw_dir: pathlib.Path, snapshot: dict[str, Any]
) -> tuple[list[dict[str, Any]], dict[str, int]]:
    status_path = repo_file(raw_dir / "status.txt")
    statuses, count_lines = parse_case_status(status_path)
    expected_count_text = (
        f"attempted={EXPECTED_CASE_COUNT} pass={EXPECTED_CASE_COUNT} "
        "fail=0 skip=0"
    )
    if len(count_lines) != 1 or expected_count_text not in count_lines[0]:
        raise Act4Error("ACT4 aggregate status count differs from exact cohort")
    expected_ids = [record["case_id"] for record in snapshot["elfs"]]
    if (
        set(statuses) != set(expected_ids)
        or len(statuses) != EXPECTED_CASE_COUNT
    ):
        raise Act4Error("ACT4 case status membership differs from ELF inventory")

    records: list[dict[str, Any]] = []
    total_pass = 0
    total_fail = 0
    total_assertions = 0
    for elf_record in snapshot["elfs"]:
        case_id = elf_record["case_id"]
        fields = statuses[case_id]
        if fields[1] != "PASS":
            raise Act4Error(f"ACT4 case is not PASS: {case_id}")
        status_text = " ".join(fields[2:])
        tohost_match = re.search(r"\btohost=(0x[0-9A-Fa-f]+)\b", status_text)
        if (
            tohost_match is None
            or "pass_markers=1" not in status_text
            or "assertions=0" not in status_text
        ):
            raise Act4Error(f"ACT4 case status contract differs: {case_id}")
        artifact_id = case_id.replace("/", "__")
        log_path = repo_file(raw_dir / "act4-log" / f"{artifact_id}.log")
        text = log_path.read_text(encoding="utf-8", errors="replace")
        pass_markers = text.count("TOHOST PASS")
        fail_markers = text.count("TOHOST FAIL")
        assertions = len(ASSERTION_RE.findall(text))
        if (
            pass_markers != 1
            or fail_markers != 0
            or text.count("BAD TRAP") != 0
            or assertions != 0
        ):
            raise Act4Error(f"ACT4 terminal/assertion contract failed: {case_id}")
        reports = RUN_RESULT_RE.findall(text)
        if len(reports) != 1:
            raise Act4Error(f"ACT4 run-result marker count differs: {case_id}")
        cycles, commits = (int(value) for value in reports[0])
        if cycles < 1 or commits < 1:
            raise Act4Error(f"ACT4 cycle/commit count is empty: {case_id}")
        tohost = tohost_match.group(1)
        if text.count(f"watching word at {tohost}") != 1:
            raise Act4Error(f"ACT4 tohost watch binding differs: {case_id}")
        records.append({
            "case_id": case_id,
            "suite": elf_record["suite"],
            "name": elf_record["name"],
            "status": "PASS",
            "return_code": 0,
            "tohost_address": tohost,
            "terminal_pass_markers": pass_markers,
            "terminal_fail_markers": fail_markers,
            "rtl_assertion_failures": assertions,
            "cycles": cycles,
            "commits": commits,
            "elf": elf_record["artifact"],
            "log": artifact(log_path, kind="act4_case_log"),
        })
        total_pass += pass_markers
        total_fail += fail_markers
        total_assertions += assertions
    return records, {
        "terminal_pass_markers": total_pass,
        "terminal_fail_markers": total_fail,
        "rtl_assertion_failures": total_assertions,
    }


def build_receipt(
    *, raw_dir: pathlib.Path, before_path: pathlib.Path,
    after_path: pathlib.Path, cleanup_path: pathlib.Path,
    execution_manifest_path: pathlib.Path,
) -> dict[str, Any]:
    raw_dir = repo_dir(raw_dir)
    before_path = repo_file(before_path)
    after_path = repo_file(after_path)
    before = load_json(before_path)
    after = load_json(after_path)
    if before.get("schema") != INPUT_SCHEMA or before != after:
        raise Act4Error("ACT4 before/after input binding differs")
    live = capture_snapshot(
        l1_result=pathlib.Path(before["l1"]["result"]["path"]),
        config_dir=pathlib.Path(before["config_directory"]),
        elf_root=pathlib.Path(before["elf_root"]),
    )
    if (
        act4_execution_relevant_snapshot(live)
        != act4_execution_relevant_snapshot(before)
    ):
        raise Act4Error("ACT4 stored input binding differs from live inputs")
    if repo_file(raw_dir / "overall.status").read_text(encoding="utf-8") != "PASS\n":
        raise Act4Error("ACT4 backend top status is not exact PASS")
    expected_elf_lines = [
        str(ROOT / record["artifact"]["path"]) for record in before["elfs"]
    ]
    execution_manifest_path = repo_file(execution_manifest_path)
    manifest_elf_lines = execution_manifest_path.read_text(
        encoding="utf-8"
    ).splitlines()
    if manifest_elf_lines != expected_elf_lines:
        raise Act4Error("ACT4 execution manifest differs from frozen inventory")
    observed_elf_lines = repo_file(raw_dir / "elf-list.txt").read_text(
        encoding="utf-8"
    ).splitlines()
    if observed_elf_lines != expected_elf_lines:
        raise Act4Error("ACT4 executed ELF list differs from frozen inventory")
    summary_path = repo_file(raw_dir / "summary.txt")
    summary = summary_path.read_text(encoding="utf-8", errors="replace")
    if (
        summary.count(
            f"attempted={EXPECTED_CASE_COUNT} pass={EXPECTED_CASE_COUNT} "
            "fail=0 skip=0"
        ) != 1
        or not re.search(r"done overall_rc=0$", summary, re.MULTILINE)
    ):
        raise Act4Error("ACT4 runner summary is not complete PASS")
    cleanup_value = validate_cleanup(cleanup_path, raw_dir=raw_dir)
    records, totals = case_records(raw_dir=raw_dir, snapshot=before)
    suite_counts = []
    for suite in policy()["suites"]:
        passed = sum(record["suite"] == suite["id"] for record in records)
        suite_counts.append({
            "id": suite["id"],
            "passed": passed,
            "required": suite["required_cases"],
        })
    if any(item["passed"] != item["required"] for item in suite_counts):
        raise Act4Error("ACT4 suite PASS counts differ")
    workflow = before["workflow_artifacts"]
    live_workflow = live["workflow_artifacts"]
    l1 = before["l1"]
    receipt = {
        "schema": SCHEMA,
        "status": "PASS",
        "claim": "ACT4_ARCH_TEST_PASS_CURRENT_IDENTITY",
        "design_id": before["design_id"],
        "production_rtl_file_count": before["production_rtl_file_count"],
        "source_directory": relative(raw_dir),
        "config_name": before["config_name"],
        "selection": {
            "generated": EXPECTED_GENERATED_CASE_COUNT,
            "required": EXPECTED_CASE_COUNT,
            "excluded": before["excluded_elfs"],
        },
        "suites": suite_counts,
        "counts": {
            "attempted": EXPECTED_CASE_COUNT,
            "failed": 0,
            "passed": EXPECTED_CASE_COUNT,
            "required": EXPECTED_CASE_COUNT,
            "skipped": 0,
            **totals,
        },
        "rtl_assertions": {"enabled": True, "failures": 0},
        "inputs": {
            "before": artifact(before_path, kind="act4_input_binding_before"),
            "after": artifact(after_path, kind="act4_input_binding_after"),
            "unchanged": True,
        },
        "simulator": {
            "binary": l1["simulator"],
            "l1_result": l1["result"],
            "l1_build_log": l1["build_log"],
            "reused": True,
            "ooo_assert_define": True,
        },
        "cases": records,
        "cleanup": artifact(cleanup_path, kind="act4_runtime_cleanup"),
        "runner_status": artifact(
            raw_dir / "overall.status", kind="act4_backend_status"
        ),
        "case_status": artifact(
            raw_dir / "status.txt", kind="act4_case_status"
        ),
        "execution_manifest": artifact(
            execution_manifest_path, kind="act4_execution_manifest"
        ),
        "runner_summary": artifact(
            summary_path, kind="act4_backend_summary"
        ),
        "policy": workflow["policy"],
        "runner": workflow["current_runner"],
        "checker": live_workflow["checker"],
        "schema_contract": workflow["schema"],
        "non_claims": policy()["non_claims"],
    }
    validate_schema(receipt)
    if cleanup_value.get("status") != "PASS":
        raise Act4Error("ACT4 cleanup authorization is absent")
    return receipt


def validate_schema(value: dict[str, Any]) -> None:
    schema = load_json(SCHEMA_PATH)
    try:
        jsonschema.Draft202012Validator(schema).validate(value)
    except jsonschema.ValidationError as exc:
        raise Act4Error(f"ACT4 receipt violates schema: {exc.message}") from exc


def verify_receipt(path: pathlib.Path) -> dict[str, Any]:
    path = repo_file(path)
    stored = load_json(path)
    validate_schema(stored)
    for field, kind in (
        ("cleanup", "act4_runtime_cleanup"),
        ("runner_status", "act4_backend_status"),
        ("case_status", "act4_case_status"),
        ("execution_manifest", "act4_execution_manifest"),
        ("runner_summary", "act4_backend_summary"),
        ("policy", "act4_signoff_policy"),
        ("runner", "act4_current_runner"),
        ("checker", "act4_current_checker"),
        ("schema_contract", "act4_current_schema"),
    ):
        verify_artifact(stored[field], kind=kind)
    before_path = verify_artifact(
        stored["inputs"]["before"], kind="act4_input_binding_before"
    )
    after_path = verify_artifact(
        stored["inputs"]["after"], kind="act4_input_binding_after"
    )
    for case in stored["cases"]:
        verify_artifact(case["elf"], kind="act4_self_checking_elf")
        verify_artifact(case["log"], kind="act4_case_log")
    for case in stored["selection"]["excluded"]:
        verify_artifact(case["artifact"], kind="act4_self_checking_elf")
    raw_dir = repo_dir(pathlib.Path(stored["source_directory"]))
    rebuilt = build_receipt(
        raw_dir=raw_dir,
        before_path=before_path,
        after_path=after_path,
        cleanup_path=pathlib.Path(stored["cleanup"]["path"]),
        execution_manifest_path=pathlib.Path(
            stored["execution_manifest"]["path"]
        ),
    )
    if rebuilt != stored:
        raise Act4Error("ACT4 receipt differs from recomputed current evidence")
    return stored


def parser() -> argparse.ArgumentParser:
    value = argparse.ArgumentParser(description=__doc__)
    commands = value.add_subparsers(dest="command", required=True)
    snapshot = commands.add_parser("snapshot")
    snapshot.add_argument("--l1-result", type=pathlib.Path, required=True)
    snapshot.add_argument("--config-dir", type=pathlib.Path, required=True)
    snapshot.add_argument("--elf-root", type=pathlib.Path, required=True)
    snapshot.add_argument("--output", type=pathlib.Path, required=True)
    manifest = commands.add_parser("manifest")
    manifest.add_argument("--snapshot", type=pathlib.Path, required=True)
    manifest.add_argument("--output", type=pathlib.Path, required=True)
    build = commands.add_parser("build")
    build.add_argument("--run-dir", type=pathlib.Path, required=True)
    build.add_argument("--input-before", type=pathlib.Path, required=True)
    build.add_argument("--input-after", type=pathlib.Path, required=True)
    build.add_argument("--cleanup", type=pathlib.Path, required=True)
    build.add_argument("--execution-manifest", type=pathlib.Path, required=True)
    build.add_argument("--output", type=pathlib.Path, required=True)
    verify = commands.add_parser("verify")
    verify.add_argument("--receipt", type=pathlib.Path, required=True)
    publish = commands.add_parser("publish")
    publish.add_argument("--receipt", type=pathlib.Path, required=True)
    publish.add_argument("--output", type=pathlib.Path, required=True)
    return value


def main(arguments: list[str] | None = None) -> int:
    args = parser().parse_args(arguments)
    try:
        if args.command == "snapshot":
            value = capture_snapshot(
                l1_result=args.l1_result,
                config_dir=args.config_dir,
                elf_root=args.elf_root,
            )
            atomic_json(args.output, value)
            print(
                "[RV64-ACT4-CURRENT][SNAPSHOT] "
                f"design_id={value['design_id']} cases={len(value['elfs'])}"
            )
        elif args.command == "manifest":
            write_execution_manifest(
                snapshot_path=args.snapshot, output_path=args.output
            )
            print(
                "[RV64-ACT4-CURRENT][MANIFEST] "
                f"cases={EXPECTED_CASE_COUNT} config={EXPECTED_CONFIG_NAME}"
            )
        elif args.command == "build":
            value = build_receipt(
                raw_dir=args.run_dir,
                before_path=args.input_before,
                after_path=args.input_after,
                cleanup_path=args.cleanup,
                execution_manifest_path=args.execution_manifest,
            )
            atomic_json(args.output, value)
            print(
                "[RV64-ACT4-CURRENT][PASS] "
                f"design_id={value['design_id']} "
                f"cases={EXPECTED_CASE_COUNT} assertions=0"
            )
        elif args.command == "verify":
            value = verify_receipt(args.receipt)
            print(
                "[RV64-ACT4-CURRENT][PASS] "
                f"design_id={value['design_id']} "
                f"cases={EXPECTED_CASE_COUNT} assertions=0"
            )
        else:
            value = verify_receipt(args.receipt)
            atomic_json(args.output, value)
            published = verify_receipt(args.output)
            print(
                "[RV64-ACT4-CURRENT][PUBLISH_PASS] "
                f"design_id={published['design_id']} "
                f"cases={EXPECTED_CASE_COUNT} assertions=0"
            )
        return 0
    except (Act4Error, OSError, KeyError, TypeError, ValueError) as exc:
        print(f"[RV64-ACT4-CURRENT][FAIL] {exc}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
