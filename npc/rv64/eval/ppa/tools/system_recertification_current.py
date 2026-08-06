#!/usr/bin/env python3
"""Capture and verify the current default RV64 layered-system signoff.

The default conjunction is L0 directed RTL, L1 full-core DiffTest, L2
mini-system, and L3 lightweight Linux.  The verifier recomputes the retained
layered receipt from its sealed inputs and never launches a DUT simulator.
Ubuntu 22.04 remains an explicit-request-only, non-blocking optional layer.
"""

from __future__ import annotations

import argparse
import functools
import hashlib
import importlib.util
import json
import pathlib
import sys
from typing import Any


SCHEMA = "npc-rv64-system-recertification-current-v2"
LAYERED_SCHEMA = "npc-rv64-layered-system-signoff-current-v1"
LAYERED_CLAIM = "LAYERED_SYSTEM_SIGNOFF_PASS_CURRENT_IDENTITY"
LAYERED_RECEIPT_PATH = pathlib.PurePosixPath(
    "npc/rv64/eval/ppa/evidence/layered-system-signoff-current.json"
)
LAYERED_TOOL_PATH = pathlib.PurePosixPath(
    "npc/rv64/eval/ppa/tools/layered_system_signoff.py"
)
DEFAULT_CONJUNCTION = [
    "L0_DIRECTED_RTL",
    "L1_FULL_CORE_DIFFTEST",
    "L2_MINI_SYSTEM",
    "L3_LIGHTWEIGHT_LINUX",
]
LAYER_KEYS = {
    "L0_DIRECTED_RTL",
    "L1_FULL_CORE_DIFFTEST",
    "L2_MINI_SYSTEM",
    "L3_LIGHTWEIGHT_LINUX",
}


class RecertificationError(RuntimeError):
    """The retained layered evidence cannot support the declared receipt."""


def find_repo_root(start: pathlib.Path) -> pathlib.Path:
    for candidate in (start.resolve(), *start.resolve().parents):
        if (candidate / ".github").is_dir() and (candidate / "npc/rv64").is_dir():
            return candidate
    raise RecertificationError("cannot locate repository root")


def sha256_file(path: pathlib.Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def safe_file(
    root: pathlib.Path, relative: str | pathlib.PurePosixPath
) -> pathlib.Path:
    raw = root / pathlib.PurePosixPath(relative)
    if raw.is_symlink():
        raise RecertificationError(f"refuse symlink evidence file: {relative}")
    candidate = raw.resolve(strict=True)
    try:
        candidate.relative_to(root.resolve())
    except ValueError as exc:
        raise RecertificationError(f"path escapes repository: {relative}") from exc
    if not candidate.is_file():
        raise RecertificationError(f"not a regular evidence file: {relative}")
    return candidate


def artifact(
    root: pathlib.Path, relative: str | pathlib.PurePosixPath
) -> dict[str, Any]:
    path = safe_file(root, relative)
    return {
        "path": path.relative_to(root.resolve()).as_posix(),
        "sha256": sha256_file(path),
        "size_bytes": path.stat().st_size,
    }


def load_json(path: pathlib.Path) -> dict[str, Any]:
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        raise RecertificationError(f"cannot load JSON {path}: {exc}") from exc
    if not isinstance(value, dict):
        raise RecertificationError(f"JSON root is not an object: {path}")
    return value


def require_equal(value: Any, expected: Any, label: str) -> None:
    if value != expected:
        raise RecertificationError(
            f"{label}: expected {expected!r}, observed {value!r}"
        )


@functools.lru_cache(maxsize=2)
def load_layered_tool(root_text: str) -> Any:
    root = pathlib.Path(root_text)
    path = safe_file(root, LAYERED_TOOL_PATH)
    module_name = "_rv64_layered_system_signoff_current"
    spec = importlib.util.spec_from_file_location(module_name, path)
    if spec is None or spec.loader is None:
        raise RecertificationError("layered-system signoff tool cannot be loaded")
    module = importlib.util.module_from_spec(spec)
    sys.modules[module_name] = module
    try:
        spec.loader.exec_module(module)
    except Exception as exc:
        raise RecertificationError(
            f"layered-system signoff tool cannot be loaded: {exc}"
        ) from exc
    finally:
        sys.modules.pop(module_name, None)
    return module


def recompute_layered_receipt(root: pathlib.Path) -> dict[str, Any]:
    receipt_path = safe_file(root, LAYERED_RECEIPT_PATH)
    stored = load_json(receipt_path)
    directories = stored.get("source_directories")
    expected_directory_keys = {
        "l0_module",
        "l1_checker_replay",
        "l2_mini_system",
        "l3_lightweight_linux",
    }
    if not isinstance(directories, dict) or set(directories) != expected_directory_keys:
        raise RecertificationError("layered receipt source directory set differs")
    tool = load_layered_tool(str(root.resolve()))
    try:
        rebuilt = tool.evaluate(
            l0_module_dir=pathlib.Path(directories["l0_module"]),
            l1_replay_dir=pathlib.Path(directories["l1_checker_replay"]),
            l2_result_dir=pathlib.Path(directories["l2_mini_system"]),
            l3_result_dir=pathlib.Path(directories["l3_lightweight_linux"]),
            root=root,
        )
    except (OSError, ValueError, KeyError, tool.SignoffError) as exc:
        raise RecertificationError(
            f"cannot recompute layered-system receipt: {exc}"
        ) from exc
    if rebuilt != stored:
        raise RecertificationError(
            "stored layered-system receipt differs from sealed-input replay"
        )
    return stored


def validate_layer_contract(receipt: dict[str, Any]) -> None:
    require_equal(receipt.get("schema"), LAYERED_SCHEMA, "layered schema")
    require_equal(receipt.get("status"), "PASS", "layered status")
    require_equal(receipt.get("claim"), LAYERED_CLAIM, "layered claim")
    require_equal(
        receipt.get("default_signoff_conjunction"),
        DEFAULT_CONJUNCTION,
        "default signoff conjunction",
    )
    require_equal(
        receipt.get("production_rtl_file_count"), 146, "production RTL file count"
    )
    design_id = receipt.get("rtl_design_id")
    if not isinstance(design_id, str) or not design_id.startswith("sha256:"):
        raise RecertificationError("layered RTL design-id is malformed")
    layers = receipt.get("layers")
    if not isinstance(layers, dict) or set(layers) != LAYER_KEYS:
        raise RecertificationError("layered receipt has an incomplete layer set")
    for name, layer in layers.items():
        if not isinstance(layer, dict):
            raise RecertificationError(f"{name} layer record is malformed")
        require_equal(layer.get("status"), "PASS", f"{name} status")
        require_equal(layer.get("design_id"), design_id, f"{name} design-id")

    l0 = layers["L0_DIRECTED_RTL"]
    require_equal(l0.get("tests"), {"passed": 113, "required": 113}, "L0 tests")
    require_equal(
        l0.get("rtl_assertions"),
        {"enabled": True, "failures": 0},
        "L0 RTL assertions",
    )

    l1 = layers["L1_FULL_CORE_DIFFTEST"]
    counts = l1.get("counts")
    if not isinstance(counts, dict):
        raise RecertificationError("L1 count record is missing")
    for key, expected in {
        "official_passed": 177,
        "official_required": 177,
        "am_passed": 61,
        "am_required": 61,
        "difftest_mismatches": 0,
    }.items():
        require_equal(counts.get(key), expected, f"L1 {key}")
    require_equal(l1.get("signoff_scope"), "full-l1-checker-replay", "L1 scope")

    l2 = layers["L2_MINI_SYSTEM"]
    l3 = layers["L3_LIGHTWEIGHT_LINUX"]
    for name, layer, scope in (
        ("L2", l2, "full-l2"),
        ("L3", l3, "full-l3"),
    ):
        require_equal(layer.get("case"), "all", f"{name} case")
        require_equal(layer.get("signoff_scope"), scope, f"{name} scope")
        require_equal(
            layer.get("rtl_assertions"),
            {"enabled": True, "failures": 0},
            f"{name} RTL assertions",
        )

    optional = receipt.get("optional_full_ubuntu")
    require_equal(
        optional,
        {
            "status": "NOT_RUN",
            "launch_policy": "explicit-user-request-only",
            "blocks_default_signoff": False,
            "claim": "OPTIONAL_NOT_IMPLIED",
        },
        "optional Ubuntu boundary",
    )


def build_core_receipt(root: pathlib.Path) -> dict[str, Any]:
    layered = recompute_layered_receipt(root)
    validate_layer_contract(layered)
    layers = layered["layers"]
    l0 = layers["L0_DIRECTED_RTL"]
    l1 = layers["L1_FULL_CORE_DIFFTEST"]
    l2 = layers["L2_MINI_SYSTEM"]
    l3 = layers["L3_LIGHTWEIGHT_LINUX"]
    return {
        "schema_version": SCHEMA,
        "status": "PASS",
        "classification": "architecture",
        "claim": "DEFAULT_LAYERED_SYSTEM_SIGNOFF_PASS_CURRENT_IDENTITY",
        "design_id": layered["rtl_design_id"],
        "default_signoff_conjunction": list(DEFAULT_CONJUNCTION),
        "layered_signoff_receipt": artifact(root, LAYERED_RECEIPT_PATH),
        "layers": {
            "L0_DIRECTED_RTL": {
                "status": "PASS",
                "tests": l0["tests"],
                "rtl_assertion_failures": l0["rtl_assertions"]["failures"],
            },
            "L1_FULL_CORE_DIFFTEST": {
                "status": "PASS",
                "official_passed": l1["counts"]["official_passed"],
                "official_required": l1["counts"]["official_required"],
                "am_passed": l1["counts"]["am_passed"],
                "am_required": l1["counts"]["am_required"],
                "difftest_mismatches": l1["counts"]["difftest_mismatches"],
                "guest_rerun": l1["guest_rerun"],
            },
            "L2_MINI_SYSTEM": {
                "status": "PASS",
                "case": l2["case"],
                "commits": l2["commits"],
                "cycles": l2["cycles"],
                "rtl_assertion_failures": l2["rtl_assertions"]["failures"],
                "terminal_counts": l2["terminal_counts"],
            },
            "L3_LIGHTWEIGHT_LINUX": {
                "status": "PASS",
                "case": l3["case"],
                "commits": l3["commits"],
                "cycles": l3["cycles"],
                "rtl_assertion_failures": l3["rtl_assertions"]["failures"],
                "terminal_counts": l3["terminal_counts"],
            },
        },
        "optional_full_ubuntu": layered["optional_full_ubuntu"],
        "promotion": {
            "system_recertification": "PASS_CURRENT_CONFIG",
            "default_layered_signoff": "PASS",
            "whole_architecture": "RED",
            "ppa": "UNPROMOTED",
        },
        "reuse_boundary": {
            "dut_rerun_performed": False,
            "sealed_layered_evidence_recomputed": True,
            "current_rtl_design_id_required": True,
            "ubuntu_full_run_performed": False,
            "ubuntu_full_run_required_for_default_signoff": False,
            "ubuntu_launch_requires_explicit_user_request": True,
        },
        "claim_boundary": (
            "PASS_CURRENT_CONFIG covers the same-design L0 directed RTL, L1 "
            "full-core DiffTest, L2 mini-system, and L3 lightweight-Linux "
            "conjunction. Ubuntu 22.04 is not run and does not block this "
            "default signoff. Whole architecture remains RED and PPA remains "
            "unpromoted."
        ),
    }


def capture_receipt(root: pathlib.Path, output: pathlib.Path) -> dict[str, Any]:
    receipt = build_core_receipt(root)
    output.parent.mkdir(parents=True, exist_ok=True)
    temporary = output.with_suffix(output.suffix + ".tmp")
    temporary.write_text(
        json.dumps(receipt, indent=2, sort_keys=True) + "\n", encoding="utf-8"
    )
    temporary.replace(output)
    return receipt


def validate_receipt(
    root: pathlib.Path,
    input_path: pathlib.Path,
    expected_design_id: str | None = None,
) -> dict[str, Any]:
    payload = load_json(input_path)
    expected = build_core_receipt(root)
    require_equal(payload, expected, "system recertification receipt")
    if expected_design_id is not None:
        require_equal(payload.get("design_id"), expected_design_id, "caller design-id")
    layers = payload["layers"]
    return {
        "status": "PASS",
        "design_id": payload["design_id"],
        "system_recertification": "PASS_CURRENT_CONFIG",
        "default_signoff_conjunction": payload["default_signoff_conjunction"],
        "l0_passed": layers["L0_DIRECTED_RTL"]["tests"]["passed"],
        "l0_required": layers["L0_DIRECTED_RTL"]["tests"]["required"],
        "l1_official_passed": layers["L1_FULL_CORE_DIFFTEST"]["official_passed"],
        "l1_official_required": layers["L1_FULL_CORE_DIFFTEST"]["official_required"],
        "l1_am_passed": layers["L1_FULL_CORE_DIFFTEST"]["am_passed"],
        "l1_am_required": layers["L1_FULL_CORE_DIFFTEST"]["am_required"],
        "l2_case": layers["L2_MINI_SYSTEM"]["case"],
        "l3_case": layers["L3_LIGHTWEIGHT_LINUX"]["case"],
        "rtl_assertion_failures": sum(
            layers[name].get("rtl_assertion_failures", 0)
            for name in (
                "L0_DIRECTED_RTL",
                "L2_MINI_SYSTEM",
                "L3_LIGHTWEIGHT_LINUX",
            )
        ),
        "optional_ubuntu": "NOT_RUN_OPTIONAL",
        "whole_architecture": "RED",
        "ppa": "UNPROMOTED",
    }


def parser() -> argparse.ArgumentParser:
    result = argparse.ArgumentParser(description=__doc__)
    result.add_argument(
        "--root",
        type=pathlib.Path,
        default=pathlib.Path(__file__).resolve().parents[5],
    )
    commands = result.add_subparsers(dest="command", required=True)
    capture = commands.add_parser("capture")
    capture.add_argument("--output", type=pathlib.Path, required=True)
    verify = commands.add_parser("verify")
    verify.add_argument("--input", type=pathlib.Path, required=True)
    return result


def main(argv: list[str] | None = None) -> int:
    args = parser().parse_args(argv)
    root = args.root.resolve()
    try:
        if args.command == "capture":
            output = args.output if args.output.is_absolute() else root / args.output
            capture_receipt(root, output)
            result = validate_receipt(root, output)
        else:
            input_path = args.input if args.input.is_absolute() else root / args.input
            result = validate_receipt(root, input_path)
    except (RecertificationError, OSError, ValueError) as exc:
        print(f"[SYSTEM-RECERTIFICATION-CURRENT][FAIL] {exc}", file=sys.stderr)
        return 1
    print(
        "[SYSTEM-RECERTIFICATION-CURRENT][PASS] "
        f"design_id={result['design_id']} L0=113/113 L1=177+61 "
        "L2=all L3=all Ubuntu=not-run-optional assertions=0 "
        "system=PASS_CURRENT_CONFIG whole_architecture=RED ppa=UNPROMOTED"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
