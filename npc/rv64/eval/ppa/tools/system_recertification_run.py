#!/usr/bin/env python3
"""Build and verify one current-design RV64 strict system run receipt.

The shell entry owns execution and cleanup.  This helper owns deterministic
input identity, semantic receipt construction, and post-run verification.  It
never launches NpcSimTop and never rewrites an existing execution status.
"""

from __future__ import annotations

import argparse
import hashlib
import importlib.util
import json
import pathlib
import re
import sys
from typing import Any, Iterable


INPUT_SCHEMA = "npc-rv64-system-recertification-input-v1"
SUMMARY_SCHEMA = "npc-rv64-system-recertification-execution-v1"
POLICY_SCHEMA = "npc-rv64-system-recertification-run-policy-v1"

POLICY_PATH = pathlib.PurePosixPath(
    "npc/rv64/design/arch/system-recertification-run-policy-v1.json"
)
ARCH_BINDING_PATH = pathlib.PurePosixPath(
    "npc/rv64/eval/ppa/tools/architecture_hard_gates.py"
)

INPUT_TREES = (
    pathlib.PurePosixPath("npc/rv64/configs"),
    pathlib.PurePosixPath("npc/rv64/scripts"),
    pathlib.PurePosixPath("npc/rv64/csrc"),
    pathlib.PurePosixPath("npc/rv64/vsrc"),
)

INPUT_FILES = (
    pathlib.PurePosixPath("Makefile"),
    pathlib.PurePosixPath("npc/rv64/Makefile"),
    pathlib.PurePosixPath("npc/rv64/Kconfig"),
    ARCH_BINDING_PATH,
    pathlib.PurePosixPath("npc/rv64/eval/ppa/run-system-recertification-current.sh"),
    pathlib.PurePosixPath(
        "npc/rv64/eval/ppa/tools/system_recertification_run.py"
    ),
    pathlib.PurePosixPath(
        "npc/rv64/eval/ppa/tests/test_system_recertification_runner.py"
    ),
    POLICY_PATH,
    pathlib.PurePosixPath("scripts/task-run-status.sh"),
    pathlib.PurePosixPath("scripts/tests/test-task-run-status.sh"),
    pathlib.PurePosixPath("Linux/Makefile"),
    pathlib.PurePosixPath("Linux/scripts/check-ubuntu-rootfs.sh"),
    pathlib.PurePosixPath("Linux/scripts/check-npc-systemd-guest.sh"),
    pathlib.PurePosixPath("Linux/scripts/npc-systemd-strict-check.sh"),
    pathlib.PurePosixPath("Linux/scripts/npc_systemd_transaction_evidence.py"),
    pathlib.PurePosixPath("Linux/scripts/prepare-npc-rootfs-run-image.sh"),
    pathlib.PurePosixPath("Linux/scripts/tests/test_npc_systemd_strict_check.py"),
    pathlib.PurePosixPath(
        "Linux/scripts/tests/test_check_npc_systemd_guest_contract.py"
    ),
    pathlib.PurePosixPath(
        "Linux/scripts/tests/test_npc_systemd_transaction_evidence.py"
    ),
    pathlib.PurePosixPath(
        "npc/rv64/testbench/scripts/test_debug_ooo_flags_contract.py"
    ),
    pathlib.PurePosixPath("tool/kconfig/build/conf"),
    pathlib.PurePosixPath("tool/fixdep/build/fixdep"),
    pathlib.PurePosixPath("nemu/build/riscv64-nemu-interpreter-so"),
    pathlib.PurePosixPath("nemu/tools/capstone/repo/libcapstone.so.5"),
    pathlib.PurePosixPath(
        "Linux/env/platforms/npc/build/linux/arch/riscv/boot/Image"
    ),
    pathlib.PurePosixPath(
        "Linux/env/platforms/npc/build/opensbi/rootfs/platform/generic/"
        "firmware/fw_jump.bin"
    ),
    pathlib.PurePosixPath("Linux/build/riscv64-npc/npc-rv64-rootfs.dtb"),
    pathlib.PurePosixPath(
        "Linux/env/platforms/npc/images/ubuntu2204/"
        "ubuntu-22.04-riscv64-strict.ext4"
    ),
    pathlib.PurePosixPath(
        "Linux/env/platforms/npc/images/ubuntu2204/"
        "ubuntu-22.04-riscv64-strict-rootfs.cpio"
    ),
)

ANSI_RE = re.compile(r"\x1b\[[0-9;]*[A-Za-z]")
RUN_RESULT_RE = re.compile(
    r"exit via system-reset, code=(?P<code>\d+), "
    r"cycles=(?P<cycles>\d+), commits=(?P<commits>\d+)"
)
TOTAL_INSTRUCTIONS_RE = re.compile(r"total guest instructions = (?P<value>\d+)")
TOTAL_CYCLES_RE = re.compile(r"total guest cycles = (?P<value>\d+)")
CPI_RE = re.compile(r"CPI \(cycles/instruction\) = (?P<value>[0-9.]+)")

TERMINAL_MARKERS = {
    "poweroff_begin": "__NPC_SYSTEMD_POWEROFF_BEGIN__",
    "kernel_power_down": "reboot: Power down",
    "syscon_poweroff": "syscon-reset: poweroff requested value=0x00005555",
    "system_reset": "exit via system-reset, code=0",
    "good_trap": "HIT GOOD TRAP",
    "stats_instructions": "total guest instructions = ",
    "stats_cycles": "total guest cycles = ",
}
STRICT_DONE_MARKER = "__NPC_SYSTEMD_STRICT_DONE__ rc=0"
DRIVER_PASS_MARKER = (
    "[npc-systemd-check] PASS strict guest + natural poweroff "
    "(mode=systemd-strict)"
)


class RecertificationRunError(RuntimeError):
    """The retained execution cannot support the requested RV64 claim."""


def reject_duplicate_keys(pairs: list[tuple[str, Any]]) -> dict[str, Any]:
    result: dict[str, Any] = {}
    for key, value in pairs:
        if key in result:
            raise RecertificationRunError(f"duplicate JSON key: {key}")
        result[key] = value
    return result


def load_json(path: pathlib.Path) -> dict[str, Any]:
    try:
        value = json.loads(
            path.read_text(encoding="utf-8"),
            object_pairs_hook=reject_duplicate_keys,
            parse_constant=lambda token: (_ for _ in ()).throw(
                RecertificationRunError(f"non-finite JSON value: {token}")
            ),
        )
    except (OSError, json.JSONDecodeError) as exc:
        raise RecertificationRunError(f"cannot load JSON {path}: {exc}") from exc
    if not isinstance(value, dict):
        raise RecertificationRunError(f"JSON root is not an object: {path}")
    return value


def sha256_file(path: pathlib.Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(4 * 1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def lexical_regular_file(root: pathlib.Path, relative: pathlib.PurePosixPath) -> pathlib.Path:
    if relative.is_absolute() or not relative.parts or any(
        part in {"", ".", ".."} for part in relative.parts
    ):
        raise RecertificationRunError(f"invalid repository-relative path: {relative}")
    root = root.resolve()
    cursor = root
    for part in relative.parts:
        cursor = cursor / part
        if cursor.is_symlink():
            raise RecertificationRunError(f"symlink input is forbidden: {relative}")
    try:
        resolved = cursor.resolve(strict=True)
        resolved.relative_to(root)
    except (OSError, ValueError) as exc:
        raise RecertificationRunError(f"input escapes or is missing: {relative}") from exc
    if not resolved.is_file():
        raise RecertificationRunError(f"input is not a regular file: {relative}")
    return resolved


def lexical_directory(root: pathlib.Path, relative: pathlib.PurePosixPath) -> pathlib.Path:
    if relative.is_absolute() or not relative.parts or any(
        part in {"", ".", ".."} for part in relative.parts
    ):
        raise RecertificationRunError(f"invalid repository-relative directory: {relative}")
    root = root.resolve()
    cursor = root
    for part in relative.parts:
        cursor = cursor / part
        if cursor.is_symlink():
            raise RecertificationRunError(f"symlink directory is forbidden: {relative}")
    try:
        resolved = cursor.resolve(strict=True)
        resolved.relative_to(root)
    except (OSError, ValueError) as exc:
        raise RecertificationRunError(
            f"directory escapes or is missing: {relative}"
        ) from exc
    if not resolved.is_dir():
        raise RecertificationRunError(f"input is not a directory: {relative}")
    return resolved


def artifact(root: pathlib.Path, path: pathlib.Path) -> dict[str, Any]:
    root = root.resolve()
    candidate = path if path.is_absolute() else root / path
    try:
        relative = pathlib.PurePosixPath(candidate.absolute().relative_to(root).as_posix())
    except ValueError as exc:
        raise RecertificationRunError(f"artifact is outside repository: {path}") from exc
    regular = lexical_regular_file(root, relative)
    return {
        "path": relative.as_posix(),
        "sha256": sha256_file(regular),
        "size_bytes": regular.stat().st_size,
    }


def load_module(path: pathlib.Path, name: str) -> Any:
    spec = importlib.util.spec_from_file_location(name, path)
    if spec is None or spec.loader is None:
        raise RecertificationRunError(f"cannot import helper: {path}")
    module = importlib.util.module_from_spec(spec)
    sys.modules[name] = module
    spec.loader.exec_module(module)
    return module


def iter_tree_files(root: pathlib.Path, relative: pathlib.PurePosixPath) -> Iterable[pathlib.Path]:
    directory = lexical_directory(root, relative)
    for entry in sorted(directory.rglob("*")):
        entry_relative = pathlib.PurePosixPath(entry.relative_to(root.resolve()).as_posix())
        if entry.is_symlink():
            raise RecertificationRunError(f"symlink tree entry is forbidden: {entry_relative}")
        if entry.is_file():
            yield lexical_regular_file(root, entry_relative)
        elif not entry.is_dir():
            raise RecertificationRunError(f"unsupported input node: {entry_relative}")


def current_rtl_binding(root: pathlib.Path) -> tuple[str, int]:
    module = load_module(
        lexical_regular_file(root, ARCH_BINDING_PATH),
        "system_recertification_run_arch_binding",
    )
    digest, files = module.rtl_binding(root.resolve())
    return f"sha256:{digest}", len(files)


def build_input_snapshot(root: pathlib.Path) -> dict[str, Any]:
    root = root.resolve()
    records: dict[str, dict[str, Any]] = {}
    paths: list[pathlib.Path] = []
    for relative in INPUT_FILES:
        paths.append(lexical_regular_file(root, relative))
    for relative in INPUT_TREES:
        paths.extend(iter_tree_files(root, relative))
    for path in sorted(set(paths)):
        relative = path.relative_to(root).as_posix()
        records[relative] = {
            "sha256": sha256_file(path),
            "size_bytes": path.stat().st_size,
        }
    design_id, file_count = current_rtl_binding(root)
    return {
        "schema": INPUT_SCHEMA,
        "design_id": design_id,
        "production_rtl_file_count": file_count,
        "input_file_count": len(records),
        "files": records,
    }


def verify_source_sandbox(
    root: pathlib.Path, snapshot_path: pathlib.Path, sandbox_root: pathlib.Path
) -> dict[str, int]:
    snapshot = load_json(snapshot_path)
    if snapshot.get("schema") != INPUT_SCHEMA:
        raise RecertificationRunError("sandbox source snapshot schema mismatch")
    root = root.resolve()
    sandbox_root = sandbox_root.resolve(strict=True)
    expected: dict[str, dict[str, Any]] = {}
    prefixes = (
        "npc/rv64/configs/",
        "npc/rv64/scripts/",
        "npc/rv64/csrc/",
        "npc/rv64/vsrc/",
    )
    for relative, record in snapshot.get("files", {}).items():
        if relative in {"npc/rv64/Makefile", "npc/rv64/Kconfig"}:
            expected[relative.removeprefix("npc/rv64/")] = record
        elif relative.startswith(prefixes):
            expected[relative.removeprefix("npc/rv64/")] = record
    if not expected:
        raise RecertificationRunError("sandbox source closure is empty")
    observed: dict[str, dict[str, Any]] = {}
    for entry in sorted(sandbox_root.rglob("*")):
        relative = entry.relative_to(sandbox_root).as_posix()
        if entry.is_symlink():
            raise RecertificationRunError(f"sandbox source is a symlink: {relative}")
        if entry.is_file():
            observed[relative] = {
                "sha256": sha256_file(entry),
                "size_bytes": entry.stat().st_size,
            }
        elif not entry.is_dir():
            raise RecertificationRunError(f"unsupported sandbox node: {relative}")
    if observed != expected:
        missing = sorted(set(expected) - set(observed))
        extra = sorted(set(observed) - set(expected))
        drifted = sorted(
            key for key in set(expected) & set(observed) if expected[key] != observed[key]
        )
        raise RecertificationRunError(
            "sandbox source closure mismatch: "
            f"missing={missing[:8]} extra={extra[:8]} drifted={drifted[:8]}"
        )
    return {"expected_files": len(expected), "observed_files": len(observed)}


def atomic_write_json(path: pathlib.Path, value: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = path.with_name(path.name + ".tmp")
    temporary.write_text(
        json.dumps(value, indent=2, sort_keys=True) + "\n", encoding="utf-8"
    )
    temporary.replace(path)


def parse_kv(path: pathlib.Path) -> dict[str, str]:
    values: dict[str, str] = {}
    for line_number, raw in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
        line = raw.strip()
        if not line:
            continue
        if "=" not in line:
            raise RecertificationRunError(f"{path}:{line_number}: malformed binding")
        key, value = line.split("=", 1)
        if not key or key in values:
            raise RecertificationRunError(
                f"{path}:{line_number}: duplicate or empty binding key"
            )
        values[key] = value
    return values


def clean_text(path: pathlib.Path) -> str:
    return ANSI_RE.sub("", path.read_text(encoding="utf-8", errors="replace"))


def final_pc(text: str) -> str | None:
    matches = re.findall(r"HIT GOOD TRAP.*?pc = (0x[0-9a-fA-F]+)", text)
    return matches[-1].lower() if matches else None


def parse_execution(text: str) -> dict[str, Any]:
    clean = ANSI_RE.sub("", text)
    results = list(RUN_RESULT_RE.finditer(clean))
    if len(results) != 1:
        raise RecertificationRunError(
            f"expected one system-reset result, observed {len(results)}"
        )
    result = results[0].groupdict()
    instruction_matches = TOTAL_INSTRUCTIONS_RE.findall(clean)
    cycle_matches = TOTAL_CYCLES_RE.findall(clean)
    cpi_matches = CPI_RE.findall(clean)
    if len(instruction_matches) != 1 or len(cycle_matches) != 1:
        raise RecertificationRunError(
            "expected one final instruction statistic and one final cycle statistic"
        )
    if int(result["code"]) != 0:
        raise RecertificationRunError(f"system-reset exit code is {result['code']}")
    commits = int(result["commits"])
    cycles = int(result["cycles"])
    if int(instruction_matches[0]) != commits or int(cycle_matches[0]) != cycles:
        raise RecertificationRunError("terminal counters disagree with final statistics")
    return {
        "commits": commits,
        "cycles": cycles,
        "cpi_reported": float(cpi_matches[-1]) if cpi_matches else None,
        "final_pc": final_pc(clean),
        "system_reset_code": 0,
    }


def validate_transaction(transaction: dict[str, Any]) -> dict[str, int]:
    if transaction.get("status") != "PASS":
        raise RecertificationRunError("transaction parser status is not PASS")
    expected = {"preflight": 6, "autocheck": 6, "strict": 17}
    stages = transaction.get("stages")
    if not isinstance(stages, list) or [stage.get("name") for stage in stages] != list(expected):
        raise RecertificationRunError("transaction stage order is incomplete")
    for stage in stages:
        name = stage["name"]
        required = expected[name]
        if (
            stage.get("status") != "PASS"
            or stage.get("done_rc") != 0
            or stage.get("errors") != []
            or stage.get("fail_markers") != []
            or stage.get("pass_observation_count") != required
            or len(stage.get("expected_pass_labels", [])) != required
        ):
            raise RecertificationRunError(f"transaction stage did not close: {name}")
    return expected


def exact_terminal_counts(console_text: str) -> dict[str, int]:
    counts = {name: console_text.count(marker) for name, marker in TERMINAL_MARKERS.items()}
    if any(count != 1 for count in counts.values()):
        raise RecertificationRunError(f"terminal transaction count mismatch: {counts}")
    if console_text.count(STRICT_DONE_MARKER) != 1:
        raise RecertificationRunError("strict done marker count is not one")
    return counts


def require_policy(root: pathlib.Path) -> dict[str, Any]:
    policy = load_json(lexical_regular_file(root, POLICY_PATH))
    if policy.get("schema") != POLICY_SCHEMA:
        raise RecertificationRunError("system recertification policy schema mismatch")
    required = policy.get("required_states")
    if required != {
        "artifact_state": "CLEANED",
        "assertion_state": "PASS_ZERO_FAILURES",
        "execution_state": "PASS",
        "oracle_state": "PASS",
        "terminal_state": "PASS_EXACT_ONCE",
    }:
        raise RecertificationRunError("system recertification state vector drifted")
    if policy.get("promotion_boundary") != {
        "architecture": "NOT_IMPLIED",
        "default_system_signoff": "NOT_REQUIRED_BY_THIS_OPTIONAL_RUN",
        "ppa": "NOT_IMPLIED",
        "system_transaction": "PASS_CURRENT_IDENTITY",
    }:
        raise RecertificationRunError("system recertification promotion boundary drifted")
    return policy


def required_result_paths(result: pathlib.Path) -> dict[str, pathlib.Path]:
    return {
        "binding": result / "binding.txt",
        "post_binding": result / "post-binding.txt",
        "cleanup": result / "runtime-cleanup.txt",
        "input_before": result / "input-manifest-before.json",
        "input_after": result / "input-manifest-after.json",
        "transaction": result / "systemd-transaction-evidence.json",
        "driver": result / "driver.log",
        "console": result / "guest/console.log",
        "npc": result / "guest/npc.log",
        "terminal": result / "terminal-markers.txt",
        "assertions": result / "rtl-assertion-failures.txt",
        "progress_tail": result / "progress-tail.txt",
        "system_stats": result / "system-stats.txt",
        "simulator_manifest": result / "simulator-verFiles.dat",
        "simulator_defines": result / "simulator-defines.txt",
        "tool_versions": result / "tool-versions.txt",
    }


def build_summary(
    root: pathlib.Path,
    result: pathlib.Path,
    expected_design_id: str,
    expected_file_count: int,
    max_cycles: int,
) -> dict[str, Any]:
    root = root.resolve()
    result = result.resolve()
    try:
        result.relative_to(root)
    except ValueError as exc:
        raise RecertificationRunError("result directory is outside repository") from exc
    require_policy(root)
    paths = required_result_paths(result)
    for label, path in paths.items():
        if not path.is_file() or path.is_symlink():
            raise RecertificationRunError(f"missing or aliased result {label}: {path}")

    before = load_json(paths["input_before"])
    after = load_json(paths["input_after"])
    if before != after:
        raise RecertificationRunError("execution input identity drifted during run")
    if before.get("schema") != INPUT_SCHEMA:
        raise RecertificationRunError("input manifest schema mismatch")
    if before.get("design_id") != expected_design_id:
        raise RecertificationRunError("unexpected RTL design-id")
    if before.get("production_rtl_file_count") != expected_file_count:
        raise RecertificationRunError("unexpected production RTL file count")

    binding = parse_kv(paths["binding"])
    post = parse_kv(paths["post_binding"])
    cleanup = parse_kv(paths["cleanup"])
    if binding.get("schema") != "npc-rv64-system-recertification-binding-v1":
        raise RecertificationRunError("execution binding schema mismatch")
    if binding.get("rtl_design_id") != expected_design_id:
        raise RecertificationRunError("execution binding design-id mismatch")
    if binding.get("production_rtl_file_count") != str(expected_file_count):
        raise RecertificationRunError("execution binding file count mismatch")
    for key, expected_value in {
        "OOO_CSR_QUEUE_HEAD": "1",
        "OOO_ASSERT": "1",
        "OOO_TERMINAL_HOLDER_ASSERT": "1",
        "NPC_SYSTEMD_GUEST_COMMAND_MODE": "systemd-strict",
        "uart_rx_bytes": "0",
    }.items():
        if binding.get(key) != expected_value:
            raise RecertificationRunError(f"execution configuration mismatch: {key}")
    if post.get("binding_status") != "PASS":
        raise RecertificationRunError("post binding did not pass")
    hash_pairs = 0
    for key, value in sorted(post.items()):
        if not key.endswith("_pre_sha256"):
            continue
        hash_pairs += 1
        post_key = key.removesuffix("_pre_sha256") + "_post_sha256"
        if not value or value != post.get(post_key):
            raise RecertificationRunError(f"pre/post hash mismatch: {key}")
    if hash_pairs < 14:
        raise RecertificationRunError(f"only {hash_pairs} pre/post hash pairs were retained")
    if (
        cleanup.get("runtime_path_validated") != "1"
        or cleanup.get("runtime_owned") != "1"
        or cleanup.get("runtime_removed") != "1"
        or cleanup.get("remove_rc") != "0"
    ):
        raise RecertificationRunError("runtime products were not safely removed")

    transaction = load_json(paths["transaction"])
    stage_counts = validate_transaction(transaction)
    console_text = clean_text(paths["console"])
    npc_text = clean_text(paths["npc"])
    driver_text = clean_text(paths["driver"])
    terminal_counts = exact_terminal_counts(console_text)
    if driver_text.count(DRIVER_PASS_MARKER) != 1:
        raise RecertificationRunError("driver PASS marker count is not one")
    if "loaded bytes=0 file_bytes=0 text_bytes=0" not in console_text:
        raise RecertificationRunError("zero-byte UART source binding is missing")
    if re.search(r"uart-rx\]\s+pop=", console_text + "\n" + npc_text):
        raise RecertificationRunError("UART RX byte was observed")
    if paths["assertions"].stat().st_size != 0:
        raise RecertificationRunError("RTL assertion failure file is non-empty")

    execution = parse_execution(console_text)
    if execution["cycles"] > max_cycles or execution["commits"] <= 0:
        raise RecertificationRunError("system execution exceeded budget or retired nothing")

    forbidden_suffixes = {".a", ".bin", ".o", ".pyc", ".so", ".vvp"}
    forbidden_names = {"NpcSimTop"}
    retained_products = sorted(
        path.relative_to(result).as_posix()
        for path in result.rglob("*")
        if path.is_file()
        and (path.suffix in forbidden_suffixes or path.name in forbidden_names)
    )
    if retained_products:
        raise RecertificationRunError(
            f"compiled products retained in task-run: {retained_products}"
        )

    return {
        "schema": SUMMARY_SCHEMA,
        "status": "PASS",
        "design_id": expected_design_id,
        "production_rtl_file_count": expected_file_count,
        "execution_identity": {
            "input_manifest_before": artifact(root, paths["input_before"]),
            "input_manifest_after": artifact(root, paths["input_after"]),
            "pre_post_equal": True,
            "input_file_count": before["input_file_count"],
        },
        "system_transaction": {
            "status": "PASS_CURRENT_IDENTITY",
            "protocol": "strict-v2",
            "terminal_contract": "natural-poweroff",
            "stage_counts": stage_counts,
            "terminal_counts": terminal_counts,
            "strict_done_count": 1,
            "rtl_assertion_failures": 0,
            "uart_rx_bytes": 0,
            "max_cycles": max_cycles,
            **execution,
        },
        "state_vector": {
            "execution_state": "PASS",
            "terminal_state": "PASS_EXACT_ONCE",
            "artifact_state": "CLEANED",
            "assertion_state": "PASS_ZERO_FAILURES",
            "oracle_state": "PASS",
            "replay_state": "NOT_APPLICABLE_FRESH_EXECUTION",
        },
        "promotion_boundary": {
            "system_transaction": "PASS_CURRENT_IDENTITY",
            "architecture": "NOT_IMPLIED",
            "ppa": "NOT_IMPLIED",
        },
        "binding": {
            "simulator_sha256": binding.get("simulator_sha256"),
            "verilator_manifest_sha256": binding.get("verilator_manifest_sha256"),
            "nemu_reference_sha256": binding.get("nemu_reference_sha256"),
            "npc_config_sha256": binding.get("npc_config_sha256"),
            "rootfs_template_sha256": binding.get("rootfs_template_sha256"),
            "linux_image_sha256": binding.get("linux_image_sha256"),
            "opensbi_fw_sha256": binding.get("opensbi_fw_sha256"),
            "run_dtb_sha256": binding.get("run_dtb_sha256"),
            "post_binding_status": "PASS",
        },
        "retention": {
            "runtime_products_retained": 0,
            "compiled_products_in_task_run": retained_products,
            "full_system_logs_retained": [
                paths["driver"].relative_to(root).as_posix(),
                paths["console"].relative_to(root).as_posix(),
                paths["npc"].relative_to(root).as_posix(),
            ],
            "build_logs": "bounded-tail-only",
        },
        "evidence": {label: artifact(root, path) for label, path in paths.items()},
    }


def result_directory(root: pathlib.Path, run_dir: pathlib.Path) -> pathlib.Path:
    root = root.resolve()
    candidate = run_dir if run_dir.is_absolute() else root / run_dir
    try:
        relative = candidate.absolute().relative_to(root)
    except ValueError as exc:
        raise RecertificationRunError("run directory is outside repository") from exc
    try:
        candidate.resolve(strict=True).relative_to(root)
    except (OSError, ValueError) as exc:
        raise RecertificationRunError("run directory is missing or outside repository") from exc
    if len(relative.parts) != 3 or relative.parts[:2] != (".github", "task-runs"):
        raise RecertificationRunError("run directory must be a direct task-runs child")
    cursor = root
    for part in relative.parts:
        cursor = cursor / part
        if cursor.is_symlink():
            raise RecertificationRunError("run directory contains a symlink component")
    result = cursor / "system"
    if not result.is_dir() or result.is_symlink():
        raise RecertificationRunError("system result directory is missing or aliased")
    return result


def verify_run(
    root: pathlib.Path,
    run_dir: pathlib.Path,
    expected_design_id: str | None,
    require_live_inputs: bool,
) -> dict[str, Any]:
    result = result_directory(root, run_dir)
    status = result.parent / "system.status"
    if status.is_symlink() or status.read_text(encoding="utf-8") != "PASS\n":
        raise RecertificationRunError("outer system execution status is not exact PASS")
    summary_path = result / "system-recertification-summary.json"
    stored = load_json(summary_path)
    if stored.get("schema") != SUMMARY_SCHEMA or stored.get("status") != "PASS":
        raise RecertificationRunError("stored execution summary is not PASS")
    if expected_design_id is not None and stored.get("design_id") != expected_design_id:
        raise RecertificationRunError("caller design-id does not match execution summary")
    rebuilt = build_summary(
        root,
        result,
        stored["design_id"],
        int(stored["production_rtl_file_count"]),
        int(stored["system_transaction"]["max_cycles"]),
    )
    if rebuilt != stored:
        raise RecertificationRunError("stored execution summary differs from retained logs")
    if require_live_inputs:
        live = build_input_snapshot(root)
        before = load_json(result / "input-manifest-before.json")
        if live != before:
            raise RecertificationRunError("live execution inputs no longer match the run")
    return stored


def self_test() -> int:
    sample = (
        "\x1b[1;34mHIT GOOD TRAP at pc = 0x00000000800237ae\x1b[0m\n"
        "exit via system-reset, code=0, cycles=5071521696, commits=1223536213\n"
        "total guest instructions = 1223536213\n"
        "total guest cycles = 5071521696\n"
        "CPI (cycles/instruction) = 4.145\n"
    )
    parsed = parse_execution(sample)
    if (
        parsed["commits"] != 1_223_536_213
        or parsed["cycles"] != 5_071_521_696
        or parsed["final_pc"] != "0x00000000800237ae"
    ):
        raise RecertificationRunError("execution parser self-test mismatch")
    print("[RV64-SYSTEM-RECERT-SUMMARY-SELFTEST] PASS")
    return 0


def parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=pathlib.Path, default=pathlib.Path(__file__).resolve().parents[5])
    sub = parser.add_subparsers(dest="command", required=True)
    snapshot = sub.add_parser("snapshot")
    snapshot.add_argument("--output", type=pathlib.Path, required=True)
    sandbox = sub.add_parser("verify-sandbox")
    sandbox.add_argument("--snapshot", type=pathlib.Path, required=True)
    sandbox.add_argument("--sandbox-root", type=pathlib.Path, required=True)
    summary = sub.add_parser("summary")
    summary.add_argument("--result-dir", type=pathlib.Path, required=True)
    summary.add_argument("--expected-design-id", required=True)
    summary.add_argument("--expected-file-count", type=int, required=True)
    summary.add_argument("--max-cycles", type=int, required=True)
    summary.add_argument("--output", type=pathlib.Path, required=True)
    verify = sub.add_parser("verify")
    verify.add_argument("--run-dir", type=pathlib.Path, required=True)
    verify.add_argument("--expected-design-id")
    verify.add_argument("--no-live-input-check", action="store_true")
    sub.add_parser("self-test")
    return parser.parse_args(argv)


def main(argv: list[str] | None = None) -> int:
    args = parse_args(list(sys.argv[1:] if argv is None else argv))
    root = args.root.resolve()
    try:
        if args.command == "snapshot":
            output = args.output if args.output.is_absolute() else root / args.output
            atomic_write_json(output, build_input_snapshot(root))
            payload = load_json(output)
            print(
                "[RV64-SYSTEM-RECERT-INPUT] "
                f"design_id={payload['design_id']} "
                f"rtl_files={payload['production_rtl_file_count']} "
                f"input_files={payload['input_file_count']}"
            )
        elif args.command == "verify-sandbox":
            snapshot = args.snapshot if args.snapshot.is_absolute() else root / args.snapshot
            sandbox_root = (
                args.sandbox_root
                if args.sandbox_root.is_absolute()
                else root / args.sandbox_root
            )
            counts = verify_source_sandbox(root, snapshot, sandbox_root)
            print(
                "[RV64-SYSTEM-RECERT-SANDBOX] PASS "
                f"files={counts['observed_files']}"
            )
        elif args.command == "summary":
            result = args.result_dir if args.result_dir.is_absolute() else root / args.result_dir
            output = args.output if args.output.is_absolute() else root / args.output
            receipt = build_summary(
                root,
                result,
                args.expected_design_id,
                args.expected_file_count,
                args.max_cycles,
            )
            atomic_write_json(output, receipt)
            transaction = receipt["system_transaction"]
            print(
                "[RV64-SYSTEM-RECERT][PASS] "
                f"design_id={receipt['design_id']} strict=17/17 terminals=7/7 "
                f"commits={transaction['commits']} cycles={transaction['cycles']} "
                "assertions=0 runtime_products_retained=0"
            )
        elif args.command == "verify":
            receipt = verify_run(
                root,
                args.run_dir,
                args.expected_design_id,
                not args.no_live_input_check,
            )
            transaction = receipt["system_transaction"]
            print(
                "[RV64-SYSTEM-RECERT-VERIFY][PASS] "
                f"design_id={receipt['design_id']} commits={transaction['commits']} "
                f"cycles={transaction['cycles']} assertions=0"
            )
        else:
            return self_test()
    except (RecertificationRunError, OSError, ValueError, KeyError) as exc:
        print(f"[RV64-SYSTEM-RECERT][FAIL] {exc}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
