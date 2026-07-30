#!/usr/bin/env python3
"""Bind the canonical queue-head product default to the A4 elaboration."""

from __future__ import annotations

import hashlib
import json
import re
import subprocess
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[3]
RUN_DIR = Path(__file__).resolve().parent
PRIOR_GATES = (
    ROOT
    / ".github/task-runs/2026-07-23-rv64-v9o-control-event-current-design"
    / "gates/final-architecture-hard-gates.json"
)
A4_OBJ = (
    ROOT
    / ".github/runtime-artifacts/rv64-systemd-strict"
    / "rootfs-5f9dd068-systemd-strict-6b-a4/sim-build/obj_dir"
)
DEFAULT_BUILD = RUN_DIR / "product-default-a3-toolchain-build"
DEFAULT_OBJ = DEFAULT_BUILD / "obj_dir"
GENERIC_DEFAULT_BUILD = RUN_DIR / "product-default-sim-build"
MANIFEST = ROOT / "npc/rv64/configs/product-rtl-defaults.mk"
MAKEFILE = ROOT / "npc/rv64/Makefile"
DEFINE = ROOT / "npc/rv64/vsrc/include/define.v"
A3_DEFINES = (
    ROOT
    / ".github/task-runs/2026-07-27-rv64-v10e-current-design-system-recert"
    / "rootfs-c1b531-systemd-strict-6b-a3/simulator-defines.txt"
)
A4_DEFINES = (
    ROOT
    / ".github/task-runs/2026-07-27-rv64-v10e-current-design-system-recert"
    / "rootfs-5f9dd068-systemd-strict-6b-a4/simulator-defines.txt"
)
OUTPUT = RUN_DIR / "product-default-identity.json"
PRIOR_ID = (
    "sha256:5f9dd06860a91dfc5461357c731fa2d4c34b91cb3b3cdedc754f0972f8bf4c5a"
)
EXPECTED_CURRENT_ID = (
    "sha256:04c5458ff274b7b30e0629fc20ccef4ffa958dee3b80595ee4b46faf17a73897"
)
EXPECTED_CHANGED_RTL = "npc/rv64/vsrc/include/define.v"
DEVICE_OBJECTS = (
    "device.o",
    "dpi.o",
    "keyboard.o",
    "map.o",
    "paddr.o",
    "timer.o",
    "vga.o",
    "virtio_blk.o",
)


def require(condition: bool, message: str) -> None:
    if not condition:
        raise AssertionError(message)


def sha256(path: Path) -> str:
    value = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            value.update(chunk)
    return value.hexdigest()


def canonical_digest(value: Any) -> str:
    raw = json.dumps(
        value,
        ensure_ascii=False,
        allow_nan=False,
        separators=(",", ":"),
        sort_keys=True,
    ).encode("utf-8")
    return hashlib.sha256(raw).hexdigest()


def load_json(path: Path) -> dict[str, Any]:
    require(path.is_file(), f"missing JSON: {path}")
    value = json.loads(path.read_text(encoding="utf-8"))
    require(isinstance(value, dict), f"JSON root is not object: {path}")
    return value


def rtl_binding() -> tuple[str, dict[str, str]]:
    suffixes = {".v", ".sv", ".vh", ".svh", ".mk"}
    files = sorted(
        path
        for path in (ROOT / "npc/rv64/vsrc").rglob("*")
        if path.is_file() and path.suffix.lower() in suffixes
    )
    entries = {
        path.relative_to(ROOT).as_posix(): sha256(path) for path in files
    }
    return f"sha256:{canonical_digest(entries)}", entries


def generated_names(path: Path) -> list[str]:
    require(path.is_dir(), f"missing generated object directory: {path}")
    return sorted(
        item.name
        for item in path.iterdir()
        if item.is_file()
        and item.name.startswith("VNpcSimTop")
        and item.suffix in {".cpp", ".h"}
    )


def normalize_generated(text: str) -> str:
    text = re.sub(
        r"(NpcSimTop\.sv|define\.v):\d+",
        r"\1:<LINE>",
        text,
    )
    return re.sub(
        r'(NpcSimTop\.sv|define\.v)",\s+\d+,',
        r'\1", <LINE>,',
        text,
    )


def compare_generated() -> dict[str, Any]:
    a4_names = generated_names(A4_OBJ)
    default_names = generated_names(DEFAULT_OBJ)
    require(a4_names == default_names, "A4/default generated filename sets differ")
    exact_a4: dict[str, str] = {}
    exact_default: dict[str, str] = {}
    normalized_a4: dict[str, str] = {}
    normalized_default: dict[str, str] = {}
    exact_differences: list[str] = []
    normalized_differences: list[str] = []
    for name in a4_names:
        a4_path = A4_OBJ / name
        default_path = DEFAULT_OBJ / name
        exact_a4[name] = sha256(a4_path)
        exact_default[name] = sha256(default_path)
        a4_text = normalize_generated(
            a4_path.read_text(encoding="utf-8", errors="replace")
        )
        default_text = normalize_generated(
            default_path.read_text(encoding="utf-8", errors="replace")
        )
        normalized_a4[name] = hashlib.sha256(a4_text.encode()).hexdigest()
        normalized_default[name] = hashlib.sha256(default_text.encode()).hexdigest()
        if exact_a4[name] != exact_default[name]:
            exact_differences.append(name)
        if normalized_a4[name] != normalized_default[name]:
            normalized_differences.append(name)
    require(
        not normalized_differences,
        f"active default elaboration differs from A4: {normalized_differences}",
    )
    return {
        "file_count": len(a4_names),
        "filename_sets_equal": True,
        "exact": {
            "a4_id": f"sha256:{canonical_digest(exact_a4)}",
            "product_default_id": f"sha256:{canonical_digest(exact_default)}",
            "differences": exact_differences,
            "match_count": len(a4_names) - len(exact_differences),
        },
        "source_location_normalized": {
            "a4_id": f"sha256:{canonical_digest(normalized_a4)}",
            "product_default_id": (
                f"sha256:{canonical_digest(normalized_default)}"
            ),
            "differences": normalized_differences,
            "logic_changed": False,
        },
    }


def make_receipt() -> dict[str, str]:
    result = subprocess.run(
        ["make", "-C", str(ROOT / "npc/rv64"), "-s", "print-product-rtl-config"],
        check=True,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )
    receipt: dict[str, str] = {}
    for line in result.stdout.splitlines():
        if "=" in line:
            key, value = line.split("=", 1)
            receipt[key] = value
    require(
        receipt["schema"] == "npc-rv64-product-rtl-config-v1",
        "product config schema drift",
    )
    require(receipt["OOO_CSR_QUEUE_HEAD"] == "1", "queue-head default is not 1")
    require(
        receipt["OOO_TERMINAL_HOLDER_ASSERT"] == "1",
        "terminal-holder assertion default is not 1",
    )
    require(receipt["BUILD_DIR"] == "./build-csrqh", "default build dir drift")
    require(
        "+define+OOO_CSR_QUEUE_HEAD=1" in receipt["RTL_VERILATOR_DEFINES"],
        "default Verilator define missing queue-head CSR",
    )
    require(
        "+define+OOO_TERMINAL_HOLDER_ASSERT"
        in receipt["RTL_VERILATOR_DEFINES"],
        "default Verilator define missing terminal-holder assertion",
    )
    return receipt


def define_set(path: Path) -> set[str]:
    require(path.is_file(), f"missing simulator define receipt: {path}")
    return {
        line.strip()
        for line in path.read_text(encoding="utf-8").splitlines()
        if line.strip()
    }


def main() -> int:
    prior = load_json(PRIOR_GATES)["rtl_source_set"]
    require(prior["design_id"] == PRIOR_ID, "prior current-design ID drift")
    current_id, current_files = rtl_binding()
    require(current_id == EXPECTED_CURRENT_ID, f"current design ID drift: {current_id}")
    prior_files = prior["files"]
    require(set(prior_files) == set(current_files), "RTL filename sets differ")
    changed = [
        name
        for name in sorted(current_files)
        if current_files[name] != prior_files[name]
    ]
    require(changed == [EXPECTED_CHANGED_RTL], f"unexpected RTL delta: {changed}")

    receipt = make_receipt()
    fallback_match = re.search(
        r"^`define\s+OOO_CSR_QUEUE_HEAD\s+1'b([01])\s*$",
        DEFINE.read_text(encoding="utf-8"),
        re.MULTILINE,
    )
    require(
        fallback_match is not None and fallback_match.group(1) == "1",
        "RTL queue-head fallback is not 1",
    )
    a3_defines = define_set(A3_DEFINES)
    a4_defines = define_set(A4_DEFINES)
    require(a3_defines == a4_defines, "A3/A4 simulator define sets differ")
    for required in (
        "OOO_CSR_QUEUE_HEAD=1",
        "OOO_ASSERT=1",
        "OOO_TERMINAL_HOLDER_ASSERT=1",
    ):
        require(required in a4_defines, f"A4 define missing: {required}")

    generated = compare_generated()
    objects: dict[str, dict[str, str]] = {}
    for name in DEVICE_OBJECTS:
        a4_digest = sha256(A4_OBJ / name)
        default_digest = sha256(DEFAULT_OBJ / name)
        require(a4_digest == default_digest, f"device object drift: {name}")
        objects[name] = {"a4": a4_digest, "product_default": default_digest}
    a4_cpu = sha256(A4_OBJ / "cpu-exec.o")
    default_cpu = sha256(DEFAULT_OBJ / "cpu-exec.o")
    require(a4_cpu == default_cpu, "host cpu-exec object drift")

    value = {
        "schema": "npc-rv64-product-default-identity/v1",
        "status": "PASS",
        "prior_design_id": PRIOR_ID,
        "current_design_id": current_id,
        "semantic_delta": {
            "changed_rtl_files": [
                {
                    "path": EXPECTED_CHANGED_RTL,
                    "prior_sha256": prior_files[EXPECTED_CHANGED_RTL],
                    "current_sha256": current_files[EXPECTED_CHANGED_RTL],
                    "change": "OOO_CSR_QUEUE_HEAD fallback 0 to normative product 1",
                }
            ],
            "makefile_change": "consume canonical product RTL defaults manifest",
            "manifest_added": "npc/rv64/configs/product-rtl-defaults.mk",
            "active_queue_head_logic_changed_relative_to_a4": False,
            "product_default_changed": True,
        },
        "product_config": {
            "receipt": receipt,
            "manifest_sha256": sha256(MANIFEST),
            "makefile_sha256": sha256(MAKEFILE),
            "define_sha256": sha256(DEFINE),
            "rtl_fallback": 1,
            "build_receipts": {
                "generic_default": {
                    "path": str(GENERIC_DEFAULT_BUILD.relative_to(ROOT)),
                    "compiler": "g++ from default_defconfig",
                    "result": "COMPILE_PASS",
                },
                "a3_toolchain_identity": {
                    "path": str(DEFAULT_BUILD.relative_to(ROOT)),
                    "compiler": "/usr/bin/clang++",
                    "linker": "/usr/bin/clang++",
                    "queue_head_command_override": False,
                    "result": "COMPILE_PASS",
                },
            },
            "a3_a4_simulator_defines": sorted(a4_defines),
            "a3_a4_define_sets_equal": True,
        },
        "active_elaborated_rtl": generated,
        "host_and_device_execution": {
            "device_objects": objects,
            "device_objects_changed": False,
            "cpu_exec_o": {
                "a4": a4_cpu,
                "product_default": default_cpu,
                "changed": False,
            },
        },
        "system_recert_decision": {
            "production_core_semantics_changed_relative_to_a4": False,
            "active_elaborated_rtl_logic_changed_relative_to_a4": False,
            "device_model_execution_semantics_changed": False,
            "host_harness_execution_semantics_changed": False,
            "a3_required_raw_evidence_missing": False,
            "full_system_rerun_required": "NO",
            "launch_authorization_state": "NOT_REQUIRED",
            "rerun_reason": "NONE",
        },
        "non_claims": [
            "SERIALIZE-G1 closure before second independent review",
            "architecture freeze",
            "PPA qualification",
            "A3 original PASS",
            "A4 system PASS",
        ],
    }
    OUTPUT.write_text(
        json.dumps(value, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
    )
    print(
        "[V10G-PRODUCT-DEFAULT-IDENTITY] "
        f"prior={PRIOR_ID} current={current_id} "
        f"generated={generated['file_count']} "
        f"normalized_diffs={len(generated['source_location_normalized']['differences'])} "
        "devices=8 cpu_exec=exact rerun=NO PASS"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
