#!/usr/bin/env python3
"""Build and verify the V9P direct-review to current full-core projection.

The original independent review remains bound to its immutable L0 aggregate.
This receipt proves only that the current full-core aggregate has the same
design/test inventory and target V9P log bytes, and that the live layered and
system receipts point at that current aggregate.  It never retags the original
review as a direct review of the new aggregate and never launches simulation.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import pathlib
import re
import sys
from typing import Any


SCHEMA = "npc-rv64-v9p-current-path-projection-v1"
DESIGN_ID = (
    "sha256:d3f3e7ffd6a3ca9f5e4249b945f74b935cd45182f97e0e6dd3e6377eca4f52af"
)
DIRECT_REVIEW_SHA256 = (
    "f44a75d2ab9c34514cb2542d32e853be9c53b4e4d5e930ce6a4553d28fb55ed9"
)
PROJECTION_CONTRACT_SHA256 = (
    "71b0d1619d4af6349eeb195d71a9e494ca03c434bfd700f5bf343c0394f54c89"
)
PROJECTION_REPORT_SHA256 = (
    "35aac097b5332bef9d0a335aa70c5e42ca1e24e8b1db7e3ccec0ed90cc602903"
)
SHA256_RE = re.compile(r"^[0-9a-f]{64}$")

RUN = pathlib.PurePosixPath(
    ".github/task-runs/2026-08-09-rv64-bpu-inline-ppa-d3f3-a1"
)
DIRECT_REVIEW_PATH = RUN / "evidence/v9p-current-rebind-independent-review-v1.json"
DIRECT_REVIEW_MODULE_PATH = pathlib.PurePosixPath(
    ".github/task-runs/2026-08-09-rv64-v16b-cancel-cycle-d3f3-l1-a1/"
    "evidence/module/result.json"
)
CURRENT_MODULE_PATH = pathlib.PurePosixPath(
    ".github/task-runs/2026-08-09-rv64-bpu-inline-ppa-d3f3-full-core-a1/"
    "evidence/module/result.json"
)
LAYERED_PATH = pathlib.PurePosixPath(
    "npc/rv64/eval/ppa/evidence/layered-system-signoff-current.json"
)
SYSTEM_PATH = pathlib.PurePosixPath(
    "npc/rv64/eval/ppa/evidence/system-recertification-current.json"
)
ACT4_PATH = pathlib.PurePosixPath(
    "npc/rv64/eval/ppa/evidence/act4-current.json"
)
PROJECTION_CONTRACT_PATH = (
    RUN / "subagent-contracts/v9p-current-full-core-path-rebind-review-v3.json"
)
PROJECTION_REPORT_PATH = (
    RUN / "subagent-contracts/v9p-current-full-core-path-rebind-review-v3.result.md"
)
DEFAULT_RECEIPT_PATH = RUN / "evidence/v9p-current-full-core-path-projection-v1.json"
RTL_PATHS = {
    "backend": pathlib.PurePosixPath("npc/rv64/vsrc/execute/OooIntBackend.v"),
    "bridge": pathlib.PurePosixPath("npc/rv64/vsrc/memory/OooMemAxiBridge.v"),
    "adapter": pathlib.PurePosixPath(
        "npc/rv64/vsrc/memory/OooLsuAxiLaneAdapter.v"
    ),
    "collector": pathlib.PurePosixPath(
        "npc/rv64/vsrc/memory/OooMemOwnerTerminalCollector.v"
    ),
}
TARGET_TESTS = {
    "adapter": "tb_ooo_lsu_axi_lane_adapter",
    "collector": "tb_ooo_mem_owner_terminal_collector",
}
TARGET_MARKERS = {
    "adapter": (
        "[PASS] tb_ooo_lsu_axi_lane_adapter",
        DESIGN_ID,
        "[RESULT] PASS",
    ),
    "collector": (
        "[V12A-TCOLL-LANE-PAIR-MATRIX] duplicate=66 distinct=66 PASS",
        "[V8P-TCOLL-12INGRESS-CAPTURE]",
        "[V8P-TCOLL-12INGRESS-DRAIN]",
        "[PASS] tb_ooo_mem_owner_terminal_collector",
        DESIGN_ID,
        "[RESULT] PASS",
    ),
}
UNKNOWN_BOUNDARY = [
    "immutable V9P instance bank is not retained",
    "immutable V9P kind/token/epoch owner tuple is not retained",
    "no fresh d3f3 collector fatal-removal RTL mutation was run",
    "current d3f3 mapped PPA has not yet been measured",
    "no L2/L3 guest, Ubuntu, synthesis, or STA run was launched by the path review",
]


class ProjectionError(RuntimeError):
    """A declared current-path projection is not supported by live evidence."""


def require(condition: bool, message: str) -> None:
    if not condition:
        raise ProjectionError(message)


def require_equal(value: Any, expected: Any, label: str) -> None:
    if value != expected:
        raise ProjectionError(
            f"{label}: expected {expected!r}, observed {value!r}"
        )


def find_repo_root(start: pathlib.Path) -> pathlib.Path:
    for candidate in (start.resolve(), *start.resolve().parents):
        if (candidate / ".github").is_dir() and (candidate / "npc/rv64").is_dir():
            return candidate
    raise ProjectionError("cannot locate repository root")


def safe_file(
    root: pathlib.Path, relative: str | pathlib.PurePosixPath
) -> pathlib.Path:
    raw = root / pathlib.PurePosixPath(relative)
    require(not raw.is_symlink(), f"refuse symlink evidence: {relative}")
    path = raw.resolve(strict=True)
    try:
        path.relative_to(root.resolve())
    except ValueError as exc:
        raise ProjectionError(f"path escapes repository: {relative}") from exc
    require(path.is_file(), f"not a regular file: {relative}")
    return path


def sha256_file(path: pathlib.Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def canonical_sha256(value: dict[str, Any]) -> str:
    return hashlib.sha256(
        json.dumps(
            value, allow_nan=False, ensure_ascii=False, sort_keys=True,
            separators=(",", ":"),
        ).encode("utf-8")
    ).hexdigest()


def load_json(
    root: pathlib.Path, relative: str | pathlib.PurePosixPath
) -> dict[str, Any]:
    path = safe_file(root, relative)
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as exc:
        raise ProjectionError(f"invalid JSON {relative}: {exc}") from exc
    require(isinstance(value, dict), f"JSON root is not an object: {relative}")
    return value


def artifact(
    root: pathlib.Path, relative: str | pathlib.PurePosixPath
) -> dict[str, Any]:
    path = safe_file(root, relative)
    return {
        "path": path.relative_to(root.resolve()).as_posix(),
        "sha256": sha256_file(path),
        "size_bytes": path.stat().st_size,
    }


def validate_record(
    root: pathlib.Path, record: Any, label: str,
) -> dict[str, Any]:
    require(isinstance(record, dict), f"{label} record is missing")
    require(isinstance(record.get("path"), str), f"{label} path is missing")
    require(
        SHA256_RE.fullmatch(str(record.get("sha256", ""))) is not None,
        f"{label} SHA-256 is malformed",
    )
    require(
        isinstance(record.get("size_bytes"), int)
        and not isinstance(record.get("size_bytes"), bool)
        and record["size_bytes"] > 0,
        f"{label} size is malformed",
    )
    observed = artifact(root, record["path"])
    require_equal(record["sha256"], observed["sha256"], f"{label} SHA-256")
    require_equal(record["size_bytes"], observed["size_bytes"], f"{label} size")
    return observed


def record_identity(record: dict[str, Any]) -> dict[str, Any]:
    return {
        "path": record["path"],
        "sha256": record["sha256"],
        "size_bytes": record["size_bytes"],
    }


def validate_module(
    root: pathlib.Path,
    payload: dict[str, Any],
    relative: pathlib.PurePosixPath,
    label: str,
) -> dict[str, Any]:
    require_equal(
        payload.get("schema"),
        "npc-rv64-full-core-module-current-evidence-v1",
        f"{label} schema",
    )
    require_equal(payload.get("status"), "PASS", f"{label} status")
    require_equal(payload.get("design_id"), DESIGN_ID, f"{label} design-id")
    inputs = payload.get("inputs", {})
    require_equal(inputs.get("unchanged"), True, f"{label} input stability")
    pre = validate_record(root, inputs.get("pre"), f"{label} pre inputs")
    post = validate_record(root, inputs.get("post"), f"{label} post inputs")
    require_equal(pre["sha256"], post["sha256"], f"{label} pre/post inputs")

    tests = payload.get("tests", {})
    inventory = tests.get("inventory")
    logs = tests.get("logs")
    require(
        isinstance(inventory, list)
        and all(isinstance(item, str) and item for item in inventory),
        f"{label} test inventory is malformed",
    )
    require_equal(len(inventory), 114, f"{label} test inventory count")
    require_equal(len(set(inventory)), 114, f"{label} test inventory uniqueness")
    require(isinstance(logs, dict), f"{label} test logs are missing")
    require_equal(set(logs), set(inventory), f"{label} log inventory")
    require_equal(tests.get("passed"), 114, f"{label} passed tests")
    require_equal(tests.get("required"), 114, f"{label} required tests")

    artifacts = payload.get("artifacts", {})
    summary = validate_record(root, artifacts.get("summary"), f"{label} summary")
    make_log = validate_record(root, artifacts.get("make_log"), f"{label} make log")
    targets: dict[str, dict[str, Any]] = {}
    for role, test_name in TARGET_TESTS.items():
        observed = validate_record(
            root, logs.get(test_name), f"{label} {role} test log"
        )
        text = safe_file(root, observed["path"]).read_text(
            encoding="utf-8", errors="replace"
        )
        for marker in TARGET_MARKERS[role]:
            require(marker in text, f"{label} {role} marker is absent: {marker}")
        targets[role] = observed

    command = payload.get("command")
    require(isinstance(command, str) and command, f"{label} command is missing")
    return {
        "module": artifact(root, relative),
        "input_manifest": pre,
        "inventory": list(inventory),
        "log_index": {
            name: {
                "sha256": record.get("sha256"),
                "size_bytes": record.get("size_bytes"),
            }
            for name, record in sorted(logs.items())
        },
        "summary": summary,
        "make_log": make_log,
        "targets": targets,
        "command": command,
    }


def normalize_parallelism(command: str) -> str:
    return re.sub(r"(?<!\S)-j[0-9]+(?!\S)", "-j<N>", command)


def validate_direct_review(
    root: pathlib.Path, direct_review: dict[str, Any]
) -> dict[str, Any]:
    direct_path = safe_file(root, DIRECT_REVIEW_PATH)
    require_equal(
        sha256_file(direct_path), DIRECT_REVIEW_SHA256,
        "immutable direct-review file SHA-256",
    )
    require_equal(
        direct_review,
        load_json(root, DIRECT_REVIEW_PATH),
        "immutable direct-review content",
    )
    require_equal(
        direct_review.get("schema"),
        "npc-rv64-v9p-current-rebind-independent-review-v4",
        "direct-review schema",
    )
    require_equal(direct_review.get("status"), "PASS", "direct-review status")
    require_equal(
        direct_review.get("reviewed_design_id"), DESIGN_ID,
        "direct-review design-id",
    )
    inputs = direct_review.get("reviewed_inputs")
    require(isinstance(inputs, dict), "direct-review input inventory is missing")

    stale_aggregate_names = {"layered_current", "system_current", "act4_current"}
    for name, record in inputs.items():
        if name in stale_aggregate_names:
            require(isinstance(record, dict), f"direct-review {name} is malformed")
            require(
                SHA256_RE.fullmatch(str(record.get("sha256", ""))) is not None,
                f"direct-review {name} SHA-256 is malformed",
            )
            require(
                isinstance(record.get("size_bytes"), int)
                and record["size_bytes"] > 0,
                f"direct-review {name} size is malformed",
            )
        else:
            validate_record(root, record, f"direct-review {name}")

    require_equal(
        inputs.get("current_module", {}).get("path"),
        DIRECT_REVIEW_MODULE_PATH.as_posix(),
        "direct-review module path",
    )
    for name, path in RTL_PATHS.items():
        require_equal(
            inputs.get(name, {}).get("path"), path.as_posix(),
            f"direct-review {name} RTL path",
        )
    require_equal(
        direct_review.get("review_boundary", {}).get("architecture_stable_claim"),
        False,
        "direct-review ARCH_STABLE boundary",
    )
    require_equal(
        direct_review.get("review_boundary", {}).get("ppa_claim"),
        False,
        "direct-review PPA boundary",
    )
    return inputs


def validate_current_chain(
    root: pathlib.Path,
    layered: dict[str, Any],
    system: dict[str, Any],
    act4: dict[str, Any],
    current_module: dict[str, Any],
) -> dict[str, Any]:
    current_module_artifact = current_module["module"]
    require_equal(
        layered.get("schema"),
        "npc-rv64-layered-system-signoff-current-v1",
        "current layered schema",
    )
    require_equal(layered.get("status"), "PASS", "current layered status")
    require_equal(layered.get("rtl_design_id"), DESIGN_ID, "current layered design-id")
    require_equal(layered.get("production_rtl_file_count"), 147, "current layered RTL count")
    module_dir = CURRENT_MODULE_PATH.parent.as_posix()
    require_equal(
        layered.get("source_directories", {}).get("l0_module"),
        module_dir,
        "current layered L0 source directory",
    )
    expected_module_record = current_module_artifact
    for label, record in (
        ("L0 result", layered.get("layers", {}).get("L0_DIRECTED_RTL", {}).get("result")),
        ("L1 module result", layered.get("layers", {}).get("L1_FULL_CORE_DIFFTEST", {}).get("module_result")),
    ):
        observed = validate_record(root, record, f"current layered {label}")
        require_equal(observed, expected_module_record, f"current layered {label} binding")
    require_equal(
        layered.get("layers", {}).get("L0_DIRECTED_RTL", {}).get("tests"),
        {"passed": 114, "required": 114},
        "current layered L0 tests",
    )

    require_equal(
        system.get("schema_version"),
        "npc-rv64-system-recertification-current-v2",
        "current system schema",
    )
    require_equal(system.get("status"), "PASS", "current system status")
    require_equal(system.get("design_id"), DESIGN_ID, "current system design-id")
    layered_artifact = artifact(root, LAYERED_PATH)
    system_layered = system.get("layered_signoff_receipt")
    validate_record(root, system_layered, "current system layered receipt")
    require_equal(
        record_identity(system_layered), layered_artifact,
        "current system layered binding",
    )
    require_equal(
        system.get("layers", {}).get("L0_DIRECTED_RTL", {}).get("tests"),
        {"passed": 114, "required": 114},
        "current system L0 tests",
    )
    boundary = system.get("reuse_boundary", {})
    require_equal(boundary.get("dut_rerun_performed"), False, "system DUT rerun boundary")
    require_equal(
        boundary.get("sealed_layered_evidence_recomputed"), True,
        "system sealed layered replay",
    )

    require_equal(act4.get("schema"), "npc-rv64-act4-current-v1", "current ACT4 schema")
    require_equal(act4.get("status"), "PASS", "current ACT4 status")
    require_equal(act4.get("design_id"), DESIGN_ID, "current ACT4 design-id")
    require_equal(
        act4.get("counts"),
        {
            "attempted": 100,
            "failed": 0,
            "passed": 100,
            "required": 100,
            "rtl_assertion_failures": 0,
            "skipped": 0,
            "terminal_fail_markers": 0,
            "terminal_pass_markers": 100,
        },
        "current ACT4 counts",
    )
    require_equal(
        {row.get("status") for row in act4.get("cases", [])},
        {"PASS"},
        "current ACT4 case statuses",
    )
    require_equal(len(act4.get("cases", [])), 100, "current ACT4 case count")
    return {
        "layered": artifact(root, LAYERED_PATH),
        "system": artifact(root, SYSTEM_PATH),
        "act4": artifact(root, ACT4_PATH),
        "l0_module": current_module_artifact,
        "dut_rerun_performed": False,
        "sealed_layered_evidence_recomputed": True,
    }


def build_receipt(
    root: pathlib.Path,
    overrides: dict[str, Any] | None = None,
) -> dict[str, Any]:
    root = root.resolve()
    values = {
        "direct_review": load_json(root, DIRECT_REVIEW_PATH),
        "direct_module": load_json(root, DIRECT_REVIEW_MODULE_PATH),
        "current_module": load_json(root, CURRENT_MODULE_PATH),
        "layered": load_json(root, LAYERED_PATH),
        "system": load_json(root, SYSTEM_PATH),
        "act4": load_json(root, ACT4_PATH),
        "report_text": safe_file(root, PROJECTION_REPORT_PATH).read_text(
            encoding="utf-8", errors="replace"
        ),
    }
    if overrides:
        values.update(overrides)

    require_equal(
        sha256_file(safe_file(root, PROJECTION_CONTRACT_PATH)),
        PROJECTION_CONTRACT_SHA256,
        "projection review contract SHA-256",
    )
    require_equal(
        sha256_file(safe_file(root, PROJECTION_REPORT_PATH)),
        PROJECTION_REPORT_SHA256,
        "projection review report SHA-256",
    )
    approval = (
        "[V9P-CURRENT-PATH-PROJECTION][APPROVE] "
        f"design_id={DESIGN_ID} contract_sha256={PROJECTION_CONTRACT_SHA256}"
    )
    require_equal(
        values["report_text"].count(approval), 1,
        "projection review approval marker count",
    )

    reviewed_inputs = validate_direct_review(root, values["direct_review"])
    direct_module = validate_module(
        root, values["direct_module"], DIRECT_REVIEW_MODULE_PATH, "direct-review module"
    )
    current_module = validate_module(
        root, values["current_module"], CURRENT_MODULE_PATH, "current full-core module"
    )
    require_equal(
        direct_module["inventory"], current_module["inventory"],
        "direct/current module test inventory",
    )
    require_equal(
        direct_module["log_index"], current_module["log_index"],
        "direct/current module log hash inventory",
    )
    for name in ("summary", "make_log"):
        require_equal(
            {
                "sha256": direct_module[name]["sha256"],
                "size_bytes": direct_module[name]["size_bytes"],
            },
            {
                "sha256": current_module[name]["sha256"],
                "size_bytes": current_module[name]["size_bytes"],
            },
            f"direct/current module {name}",
        )
    require(
        direct_module["module"]["sha256"] != current_module["module"]["sha256"],
        "module projection must not masquerade as byte-identical aggregate receipts",
    )
    require_equal(
        normalize_parallelism(direct_module["command"]),
        normalize_parallelism(current_module["command"]),
        "direct/current module command apart from parallelism",
    )

    target_equivalence: dict[str, Any] = {}
    for role in TARGET_TESTS:
        direct_target = direct_module["targets"][role]
        current_target = current_module["targets"][role]
        require_equal(
            {
                "sha256": direct_target["sha256"],
                "size_bytes": direct_target["size_bytes"],
            },
            {
                "sha256": current_target["sha256"],
                "size_bytes": current_target["size_bytes"],
            },
            f"direct/current {role} log bytes",
        )
        require_equal(
            record_identity(reviewed_inputs[f"current_{role}_log"]),
            direct_target,
            f"direct-review {role} log binding",
        )
        target_equivalence[role] = {
            "direct_review": direct_target,
            "current_full_core": current_target,
            "byte_identical": True,
            "markers": list(TARGET_MARKERS[role]),
        }

    live_rtl = {}
    for name, path in RTL_PATHS.items():
        observed = artifact(root, path)
        require_equal(
            record_identity(reviewed_inputs[name]), observed,
            f"direct-review/live {name} RTL",
        )
        live_rtl[name] = observed

    current_chain = validate_current_chain(
        root,
        values["layered"],
        values["system"],
        values["act4"],
        current_module,
    )
    receipt_core = {
        "schema": SCHEMA,
        "status": "PASS",
        "design_id": DESIGN_ID,
        "projection_kind": "DIRECT_REVIEW_TO_CURRENT_AGGREGATE_WITH_BYTE_IDENTICAL_LOGS",
        "direct_review": artifact(root, DIRECT_REVIEW_PATH),
        "path_review": {
            "contract": artifact(root, PROJECTION_CONTRACT_PATH),
            "report": artifact(root, PROJECTION_REPORT_PATH),
            "decision": "APPROVE_PROJECTED_AGGREGATE",
        },
        "direct_review_aggregate_provenance": {
            name: record_identity(reviewed_inputs[name])
            for name in ("layered_current", "system_current", "act4_current")
        },
        "aggregates": {
            "direct_reviewed_module": direct_module["module"],
            "current_full_core_module": current_module["module"],
            "module_receipts_byte_identical": False,
            "direct_input_manifest": direct_module["input_manifest"],
            "current_input_manifest": current_module["input_manifest"],
            "test_inventory_equal": True,
            "test_count": 114,
            "all_log_records_equal": True,
            "summary_bytes_equal": True,
            "make_log_bytes_equal": True,
            "command_difference": "PARALLELISM_ONLY_J2_TO_J4",
        },
        "target_logs": target_equivalence,
        "live_rtl": live_rtl,
        "current_chain": current_chain,
        "claim_boundary": {
            "direct_review_retagged": False,
            "simulation_launched_for_projection": False,
            "synthesis_launched_for_projection": False,
            "sta_launched_for_projection": False,
            "architecture_stable_claim": False,
            "ppa_claim": False,
            "mapped_ppa": "UNMEASURED_UNPROMOTED",
        },
        "unknowns": list(UNKNOWN_BOUNDARY),
    }
    receipt_core["receipt_sha256"] = canonical_sha256(receipt_core)
    return receipt_core


def write_json(path: pathlib.Path, value: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = path.with_suffix(path.suffix + ".tmp")
    try:
        temporary.write_text(
            json.dumps(value, allow_nan=False, indent=2, sort_keys=True) + "\n",
            encoding="utf-8",
        )
        json.loads(temporary.read_text(encoding="utf-8"))
        temporary.replace(path)
    finally:
        if temporary.exists():
            temporary.unlink()


def validate_receipt(root: pathlib.Path, path: pathlib.Path) -> dict[str, Any]:
    try:
        relative = path.resolve().relative_to(root.resolve()).as_posix()
    except ValueError as exc:
        raise ProjectionError("projection receipt escapes repository") from exc
    actual = load_json(root, relative)
    expected = build_receipt(root)
    require_equal(actual, expected, "stored V9P path projection receipt")
    return actual


def parser() -> argparse.ArgumentParser:
    result = argparse.ArgumentParser(description=__doc__)
    result.add_argument(
        "--root", type=pathlib.Path,
        default=pathlib.Path(__file__).resolve().parents[5],
    )
    commands = result.add_subparsers(dest="command", required=True)
    build = commands.add_parser("build")
    build.add_argument("--output", type=pathlib.Path, default=DEFAULT_RECEIPT_PATH)
    verify = commands.add_parser("verify")
    verify.add_argument("--input", type=pathlib.Path, default=DEFAULT_RECEIPT_PATH)
    return result


def main(argv: list[str] | None = None) -> int:
    args = parser().parse_args(argv)
    root = find_repo_root(args.root)
    try:
        path = args.output if args.command == "build" else args.input
        path = path if path.is_absolute() else root / path
        if args.command == "build":
            receipt = build_receipt(root)
            write_json(path, receipt)
        else:
            receipt = validate_receipt(root, path)
    except (OSError, ValueError, ProjectionError, json.JSONDecodeError) as exc:
        print(f"[V9P-CURRENT-PATH-PROJECTION][FAIL] {exc}", file=sys.stderr)
        return 1
    print(
        "[V9P-CURRENT-PATH-PROJECTION][PASS] "
        f"design_id={receipt['design_id']} tests=114/114 "
        "adapter=byte-identical collector=byte-identical "
        "aggregate=projected-not-direct simulation=not-run ppa=unmeasured"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
