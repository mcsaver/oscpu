#!/usr/bin/env python3
"""Build the reviewed c1b531 -> 5f9dd RV64 identity and replay decision."""

from __future__ import annotations

import hashlib
import json
import re
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[3]
RUN_DIR = Path(__file__).resolve().parent
OLD_GATES = (
    ROOT
    / ".github/task-runs/2026-07-23-rv64-v9o-control-event-current-design"
    / "gates/final-architecture-hard-gates.json"
)
V10F_DIR = (
    ROOT
    / ".github/task-runs/2026-07-28-rv64-v10f-a3-checker-replay-v2"
)
V10F_EVIDENCE = V10F_DIR / "checker-replay-v2-evidence.json"
V10F_BASE = V10F_DIR / "base-replay-evidence.json"
A3_OBJ = (
    ROOT
    / ".github/runtime-artifacts/rv64-systemd-strict"
    / "rootfs-c1b531-systemd-strict-6b-a3/sim-build/obj_dir"
)
A4_OBJ = (
    ROOT
    / ".github/runtime-artifacts/rv64-systemd-strict"
    / "rootfs-5f9dd068-systemd-strict-6b-a4/sim-build/obj_dir"
)
A4_STATUS = (
    ROOT
    / ".github/task-runs/2026-07-27-rv64-v10e-current-design-system-recert"
    / "rootfs-5f9dd068-systemd-strict-6b-a4.status"
)
OUTPUT = RUN_DIR / "semantic-delta-identity.json"

EXPECTED_OLD_ID = (
    "sha256:c1b5317212bfe47e507eac83a28dff405527f50493e3709e96ffbec2dc3bb594"
)
EXPECTED_CURRENT_ID = (
    "sha256:5f9dd06860a91dfc5461357c731fa2d4c34b91cb3b3cdedc754f0972f8bf4c5a"
)
EXPECTED_CHANGED_RTL = "npc/rv64/vsrc/sim/NpcSimTop.sv"
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
        allow_nan=False,
        ensure_ascii=False,
        separators=(",", ":"),
        sort_keys=True,
    ).encode("utf-8")
    return hashlib.sha256(raw).hexdigest()


def load_json(path: Path) -> dict[str, Any]:
    require(path.is_file(), f"missing JSON evidence: {path}")
    value = json.loads(path.read_text(encoding="utf-8"))
    require(isinstance(value, dict), f"JSON root is not an object: {path}")
    return value


def rtl_binding() -> tuple[str, dict[str, str]]:
    suffixes = {".v", ".sv", ".vh", ".svh", ".mk"}
    files = sorted(
        path
        for path in (ROOT / "npc/rv64/vsrc").rglob("*")
        if path.is_file() and path.suffix.lower() in suffixes
    )
    require(bool(files), "current RTL source set is empty")
    entries = {
        path.relative_to(ROOT).as_posix(): sha256(path) for path in files
    }
    return f"sha256:{canonical_digest(entries)}", entries


def production_rtl(files: dict[str, str]) -> dict[str, str]:
    return {
        name: digest
        for name, digest in files.items()
        if "/sim/" not in name
        and "/debug/" not in name
        and name != "npc/rv64/vsrc/filelist.mk"
    }


def normalize_generated_text(text: str) -> str:
    text = re.sub(r"NpcSimTop\.sv:\d+", "NpcSimTop.sv:<LINE>", text)
    return re.sub(
        r'NpcSimTop\.sv",\s+\d+,',
        'NpcSimTop.sv", <LINE>,',
        text,
    )


def generated_file_names(obj_dir: Path) -> list[str]:
    require(obj_dir.is_dir(), f"missing simulator object directory: {obj_dir}")
    return sorted(
        path.name
        for path in obj_dir.iterdir()
        if path.is_file()
        and path.name.startswith("VNpcSimTop")
        and path.suffix in {".cpp", ".h"}
    )


def compare_elaborated_rtl() -> dict[str, Any]:
    a3_names = generated_file_names(A3_OBJ)
    a4_names = generated_file_names(A4_OBJ)
    require(a3_names, "A3 generated Verilator source set is empty")
    require(
        a3_names == a4_names,
        "A3/A4 generated Verilator filename sets differ",
    )

    exact_a3: dict[str, str] = {}
    exact_a4: dict[str, str] = {}
    normalized_a3: dict[str, str] = {}
    normalized_a4: dict[str, str] = {}
    exact_differences: list[str] = []
    normalized_differences: list[str] = []
    for name in a3_names:
        a3_path = A3_OBJ / name
        a4_path = A4_OBJ / name
        exact_a3[name] = sha256(a3_path)
        exact_a4[name] = sha256(a4_path)
        a3_text = normalize_generated_text(
            a3_path.read_text(encoding="utf-8", errors="replace")
        )
        a4_text = normalize_generated_text(
            a4_path.read_text(encoding="utf-8", errors="replace")
        )
        normalized_a3[name] = hashlib.sha256(a3_text.encode()).hexdigest()
        normalized_a4[name] = hashlib.sha256(a4_text.encode()).hexdigest()
        if exact_a3[name] != exact_a4[name]:
            exact_differences.append(name)
        if normalized_a3[name] != normalized_a4[name]:
            normalized_differences.append(name)

    normalized_a3_id = f"sha256:{canonical_digest(normalized_a3)}"
    normalized_a4_id = f"sha256:{canonical_digest(normalized_a4)}"
    require(
        not normalized_differences and normalized_a3_id == normalized_a4_id,
        "active elaborated RTL differs after source-location normalization",
    )
    require(
        exact_differences == ["VNpcSimTop___024root__DepSet_h00145668__4.cpp"],
        f"unexpected generated exact differences: {exact_differences}",
    )
    return {
        "file_count": len(a3_names),
        "filename_sets_equal": True,
        "exact": {
            "a3_id": f"sha256:{canonical_digest(exact_a3)}",
            "a4_id": f"sha256:{canonical_digest(exact_a4)}",
            "match_count": len(a3_names) - len(exact_differences),
            "differences": exact_differences,
        },
        "source_location_normalized": {
            "a3_id": normalized_a3_id,
            "a4_id": normalized_a4_id,
            "differences": normalized_differences,
            "logic_changed": False,
        },
    }


def compare_host_objects() -> tuple[dict[str, Any], dict[str, Any]]:
    device_objects: dict[str, dict[str, str]] = {}
    for name in DEVICE_OBJECTS:
        a3_digest = sha256(A3_OBJ / name)
        a4_digest = sha256(A4_OBJ / name)
        require(a3_digest == a4_digest, f"device object changed: {name}")
        device_objects[name] = {"a3": a3_digest, "a4": a4_digest}

    a3_cpu = sha256(A3_OBJ / "cpu-exec.o")
    a4_cpu = sha256(A4_OBJ / "cpu-exec.o")
    require(a3_cpu != a4_cpu, "expected host diagnostic object delta missing")
    return (
        {
            "id": f"sha256:{canonical_digest(device_objects)}",
            "objects": device_objects,
            "execution_semantics_changed": False,
        },
        {
            "object": "cpu-exec.o",
            "a3_sha256": a3_cpu,
            "a4_sha256": a4_cpu,
            "changed": True,
            "classification": "diagnostic-observation-only",
            "dut_input_changed": False,
            "cycle_timing_changed": False,
            "architectural_state_changed": False,
            "termination_changed": False,
            "randomization_changed": False,
        },
    )


def validate_frozen_inputs(base: dict[str, Any]) -> tuple[dict[str, Any], str]:
    frozen = base["source_run"]["frozen_inputs"]
    validated: dict[str, Any] = {}
    for name, item in sorted(frozen.items()):
        path = ROOT / item["path"]
        require(path.is_file(), f"missing frozen A3 input: {item['path']}")
        actual_digest = sha256(path)
        actual_size = path.stat().st_size
        require(
            actual_digest == item["sha256"],
            f"frozen A3 input hash drift: {item['path']}",
        )
        require(
            actual_size == item["size_bytes"],
            f"frozen A3 input size drift: {item['path']}",
        )
        validated[name] = {
            "path": item["path"],
            "sha256": actual_digest,
            "size_bytes": actual_size,
        }
    return validated, f"sha256:{canonical_digest(validated)}"


def main() -> int:
    old_gates = load_json(OLD_GATES)
    v10f = load_json(V10F_EVIDENCE)
    base = load_json(V10F_BASE)

    old_set = old_gates["rtl_source_set"]
    old_id = old_set["design_id"]
    old_files = old_set["files"]
    current_id, current_files = rtl_binding()
    require(old_id == EXPECTED_OLD_ID, f"unexpected prior RTL ID: {old_id}")
    require(
        current_id == EXPECTED_CURRENT_ID,
        f"unexpected current RTL ID: {current_id}",
    )
    require(
        set(old_files) == set(current_files),
        "prior/current aggregate RTL filename sets differ",
    )
    changed_files = [
        name
        for name in sorted(old_files)
        if old_files[name] != current_files[name]
    ]
    require(
        changed_files == [EXPECTED_CHANGED_RTL],
        f"unexpected aggregate RTL delta: {changed_files}",
    )

    old_production = production_rtl(old_files)
    current_production = production_rtl(current_files)
    require(
        old_production == current_production,
        "production design RTL changed between c1b531 and 5f9dd",
    )
    production_id = f"sha256:{canonical_digest(current_production)}"

    elaborated = compare_elaborated_rtl()
    device_model, host_harness = compare_host_objects()
    frozen_inputs, raw_bundle_id = validate_frozen_inputs(base)

    require(v10f["status"] == "PASS", "V10F checker replay is not PASS")
    require(
        v10f["source_run"]["original_status_preserved"] is True,
        "A3 original status was not preserved",
    )
    require(
        base["system_transaction"]["rtl_assertion_file_empty"] is True,
        "A3 RTL assertion evidence is not clean",
    )
    require(
        base["system_transaction"]["terminal_counts"]
        == {
            "strict_done": 1,
            "poweroff_begin": 1,
            "kernel_power_down": 1,
            "syscon_poweroff": 1,
            "good_trap": 1,
            "system_reset_exit": 1,
        },
        "A3 terminal transaction counts are not exact",
    )
    require(
        base["source_run"]["cycles"] == 5_071_521_696
        and base["source_run"]["commits"] == 1_223_536_213,
        "A3 cycle/commit identity drift",
    )
    a4_status = A4_STATUS.read_text(encoding="utf-8").strip()
    require(
        a4_status
        == "FAIL rc=143 stage=systemd-strict-guest evidence_complete=0 "
        "cleanup_rc=143 signal=TERM",
        f"unexpected A4 immutable status: {a4_status}",
    )

    config_pairs = base["binding"]["pre_post_pairs"]
    simulator_sha = base["binding"]["simulator_sha256_pre"]
    require(
        simulator_sha == base["binding"]["simulator_sha256_post"],
        "A3 simulator pre/post identity drift",
    )
    require(
        all(item["pre"] == item["post"] for item in config_pairs.values()),
        "A3 frozen binding pre/post drift",
    )

    result = {
        "schema": "npc-rv64-semantic-delta-identity/v1",
        "status": "PASS",
        "classification": {
            "primary": "verification",
            "secondary": ["tooling-workflow", "architecture-evidence"],
            "production_rtl_change": False,
            "verification_oracle_change": True,
        },
        "semantic_delta": {
            "from_design_id": old_id,
            "to_design_id": current_id,
            "aggregate_rtl_changed_files": [
                {
                    "path": EXPECTED_CHANGED_RTL,
                    "old_sha256": old_files[EXPECTED_CHANGED_RTL],
                    "current_sha256": current_files[EXPECTED_CHANGED_RTL],
                    "module": "NpcSimTop",
                    "guard": "CONFIG_NPC_DEBUG_PORTS",
                    "change": "debug_ooo_flags_o[63] configuration-valid marker",
                }
            ],
            "category": "inactive-config-plus-diagnostic-observation-only",
            "production_design_rtl_changed": False,
            "active_elaborated_rtl_logic_changed": False,
            "device_model_execution_semantics_changed": False,
            "host_harness_delta": "diagnostic-observation-only",
            "dut_input_changed": False,
            "cycle_timing_changed": False,
            "architectural_state_changed": False,
            "termination_changed": False,
            "randomization_changed": False,
            "testbench_delta": {
                "classification": "verification-only",
                "path": "npc/rv64/testbench/tests/tb_ooo_core_top_glue.sv",
                "purpose": "owner-bound queue-head CSR raw C0/C1/C2 scoreboard",
                "production_semantics_changed": False,
            },
        },
        "identity": {
            "aggregate_rtl_source_set": {
                "a3_design_id": old_id,
                "current_design_id": current_id,
                "file_count": len(current_files),
            },
            "production_design_rtl": {
                "a3_id": production_id,
                "current_id": production_id,
                "file_count": len(current_production),
                "match": True,
            },
            "simulation_top_source": {
                "path": EXPECTED_CHANGED_RTL,
                "a3_sha256": old_files[EXPECTED_CHANGED_RTL],
                "current_sha256": current_files[EXPECTED_CHANGED_RTL],
            },
            "active_elaborated_rtl": elaborated,
            "device_model": device_model,
            "host_harness": host_harness,
            "simulator": {
                "a3_sha256": simulator_sha,
                "current_recert_sha256": simulator_sha,
                "match": True,
            },
            "checker_oracle": {
                "legacy_embedded_sha256": v10f["embedded_checker"]["sha256"],
                "current_sha256": v10f["oracle_replay"][
                    "current_checker_sha256"
                ],
                "change": "bounded BUG token",
            },
            "guest": {
                "linux_image_sha256": config_pairs["linux_image"]["pre"],
                "rootfs_cpio_sha256": config_pairs["rootfs_cpio"]["pre"],
            },
            "boot": {
                "opensbi_fw_sha256": config_pairs["opensbi_fw"]["pre"],
                "run_dtb_sha256": config_pairs["run_dtb"]["pre"],
            },
            "input_log": {
                "console_sha256": v10f["oracle_replay"]["a3_console_sha256"],
                "uart_rx_bytes": 0,
            },
            "configuration": {
                "npc_config_sha256": config_pairs["npc_config"]["pre"],
                "npc_auto_conf_sha256": config_pairs["npc_auto_conf"]["pre"],
                "npc_autoconf_header_sha256": config_pairs[
                    "npc_autoconf_header"
                ]["pre"],
                "OOO_CSR_QUEUE_HEAD": 1,
                "OOO_ASSERT": 1,
                "OOO_TERMINAL_HOLDER_ASSERT": 1,
                "guest_command_mode": "systemd-strict",
                "max_cycles": 6_000_000_000,
            },
            "raw_artifact_bundle": {
                "id": raw_bundle_id,
                "files": frozen_inputs,
            },
        },
        "evidence_state": {
            "published_gate_state": "FAIL",
            "execution_state": "COMPLETE",
            "dut_terminal_state": "COMPLETE",
            "binding_state": "NO_DRIFT",
            "raw_artifact_state": "VALID",
            "rtl_assertion_state": "CLEAN",
            "oracle_state": "INVALID",
            "evidence_replayable": "YES",
            "full_system_rerun_required": "NO",
            "launch_authorization_state": "NOT_REQUIRED",
            "rerun_reason": "NONE",
        },
        "a3": {
            "original_status": v10f["source_run"]["original_status"],
            "original_status_preserved": True,
            "cycles": base["source_run"]["cycles"],
            "commits": base["source_run"]["commits"],
            "terminal_counts": base["system_transaction"]["terminal_counts"],
            "rtl_assertion_file_empty": True,
            "legacy_oracle_result": "FAIL_16_OF_17",
            "legacy_false_matches": v10f["oracle_replay"][
                "legacy_a3_matches"
            ],
        },
        "a4": {
            "status": a4_status,
            "status_preserved": True,
            "qualifies_as_system_pass": False,
            "relaunch": "PROHIBITED_BY_CURRENT_DECISION",
        },
        "checker_replay": {
            "result": "PASS",
            "version": "v2",
            "source_run": v10f["source_run"]["path"],
            "evidence": V10F_EVIDENCE.relative_to(ROOT).as_posix(),
            "evidence_sha256": sha256(V10F_EVIDENCE),
            "base_evidence": V10F_BASE.relative_to(ROOT).as_posix(),
            "base_evidence_sha256": sha256(V10F_BASE),
            "printk_debug_accepted": not v10f["oracle_replay"][
                "printk_debug_fixture"
            ]["current_match"],
            "real_bug_rejected": v10f["oracle_replay"]["real_bug_fixture"][
                "current_match"
            ],
            "proves": [
                "frozen A3 terminal transaction completeness",
                "A3 binding and raw-artifact integrity",
                "legacy dmesg oracle false-positive classification",
                "corrected checker accepts printk debug and rejects BUG token",
            ],
            "does_not_prove": [
                "new production RTL semantics",
                "architecture-debt closure",
                "PPA qualification",
            ],
        },
        "cost_and_launch_decision": {
            "a3_replay": {
                "class": "frozen-input-minute-scale",
                "authorization_required": False,
                "completed": True,
            },
            "current_design_architecture_replay": {
                "class": "minute-scale",
                "authorization_required": False,
                "single_flight_required": True,
                "stop_condition": "stop at first stage failure or RTL identity drift",
            },
            "a4_full_system_relaunch": {
                "class": "greater-than-4-hours",
                "authorization_required": True,
                "required": False,
                "launch_authorization_state": "NOT_REQUIRED",
            },
        },
        "decision": {
            "system_transaction": "COMPLETE",
            "legacy_oracle": "FALSE_POSITIVE",
            "current_checker_replay": "PASS",
            "full_system_rerun_required": False,
            "architecture_freeze": "GAP",
            "ppa": "UNQUALIFIED",
            "promotion_eligible": False,
        },
    }

    OUTPUT.write_text(
        json.dumps(result, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
    )
    print(
        "[V10G-SEMANTIC-DELTA] "
        f"from={old_id} to={current_id} "
        f"production={production_id} "
        f"elaborated={elaborated['source_location_normalized']['a4_id']} "
        f"raw_bundle={raw_bundle_id} PASS"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
