#!/usr/bin/env python3
"""Verify the frozen V9P terminal-owner counterexample and current fix.

This checker is read-only except for its compact JSON result.  It does not
launch simulation, synthesis, or an Ubuntu guest.
"""

from __future__ import annotations

import argparse
import hashlib
import importlib.util
import json
import pathlib
import re
import sys
from typing import Any


RUN_ID = "2026-08-05-rv64-v15g-v9p-terminal-root-cause-backfill"
RUN = pathlib.PurePosixPath(".github/task-runs") / RUN_ID
EVIDENCE = RUN / "evidence"
EXACT = EVIDENCE / "v9p-exact-source"
FROZEN_RUN = pathlib.PurePosixPath(
    ".github/task-runs/2026-07-23-rv64-v9p-serialize-current-design"
)
FROZEN_DESIGN_ID = (
    "sha256:9ac1ae14b18635cf25ea80efa7ce4cd85a07bdd6f0e525755658dc8dcd26207a"
)
CURRENT_DESIGN_ID = (
    "sha256:f7a6845564f2d697fca9eac8bf9424136508a62c7fcc7851ad56c688dc2053f9"
)
MARKER = "[S2-G1-TCOLL-INGRESS-DUP]"
DEFAULT_LAYERS = [
    "L0_DIRECTED_RTL",
    "L1_FULL_CORE_DIFFTEST",
    "L2_MINI_SYSTEM",
    "L3_LIGHTWEIGHT_LINUX",
]


class VerifyError(RuntimeError):
    """A bound RV64 RTL or evidence contract drifted."""


def find_root(start: pathlib.Path) -> pathlib.Path:
    for candidate in (start.resolve(), *start.resolve().parents):
        if (candidate / ".github").is_dir() and (candidate / "npc/rv64").is_dir():
            return candidate
    raise VerifyError("cannot locate repository root")


def sha256_file(path: pathlib.Path) -> str:
    value = hashlib.sha256()
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            value.update(block)
    return value.hexdigest()


def safe_file(root: pathlib.Path, relative: str | pathlib.PurePosixPath) -> pathlib.Path:
    try:
        path = (root / pathlib.PurePosixPath(relative)).resolve(strict=True)
        path.relative_to(root.resolve())
    except (OSError, ValueError) as exc:
        raise VerifyError(f"invalid repository file: {relative}") from exc
    if path.is_symlink() or not path.is_file():
        raise VerifyError(f"not a regular repository file: {relative}")
    return path


def load_json(root: pathlib.Path, relative: str | pathlib.PurePosixPath) -> dict[str, Any]:
    path = safe_file(root, relative)
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        raise VerifyError(f"cannot load JSON {relative}: {exc}") from exc
    if not isinstance(value, dict):
        raise VerifyError(f"JSON root is not an object: {relative}")
    return value


def require(condition: bool, message: str) -> None:
    if not condition:
        raise VerifyError(message)


def equal(actual: Any, expected: Any, label: str) -> None:
    if actual != expected:
        raise VerifyError(f"{label}: expected {expected!r}, got {actual!r}")


def artifact(root: pathlib.Path, relative: str | pathlib.PurePosixPath) -> dict[str, Any]:
    path = safe_file(root, relative)
    return {
        "path": path.relative_to(root.resolve()).as_posix(),
        "sha256": sha256_file(path),
        "size_bytes": path.stat().st_size,
    }


def verify_record(root: pathlib.Path, record: Any, label: str) -> str:
    require(isinstance(record, dict), f"{label}: artifact record is missing")
    path = record.get("path")
    require(isinstance(path, str) and path, f"{label}: path is missing")
    actual = artifact(root, path)
    equal(record.get("sha256"), actual["sha256"], f"{label} sha256")
    if "size_bytes" in record:
        equal(record.get("size_bytes"), actual["size_bytes"], f"{label} size")
    return safe_file(root, path).read_text(encoding="utf-8", errors="replace")


def load_module(path: pathlib.Path, name: str) -> Any:
    spec = importlib.util.spec_from_file_location(name, path)
    if spec is None or spec.loader is None:
        raise VerifyError(f"cannot import {path}")
    module = importlib.util.module_from_spec(spec)
    sys.modules[name] = module
    spec.loader.exec_module(module)
    return module


def current_design_id(root: pathlib.Path) -> tuple[str, int]:
    tool = safe_file(root, "npc/rv64/eval/ppa/tools/architecture_hard_gates.py")
    module = load_module(tool, "v15g_architecture_rtl_binding")
    digest, entries = module.rtl_binding(root)
    return f"sha256:{digest}", len(entries)


def assignment(text: str, name: str) -> str:
    match = re.search(
        rf"\b(?:assign|wire(?:\s+\[[^\]]+\])?)\s+{re.escape(name)}\s*=.*?;",
        text,
        re.S,
    )
    if match is None:
        raise VerifyError(f"assignment is absent: {name}")
    return re.sub(r"\s+", " ", match.group(0)).strip()


def concat_members(text: str, name: str) -> list[str]:
    match = re.search(
        rf"\bassign\s+{re.escape(name)}\s*=\s*\{{(.*?)\}}\s*;", text, re.S
    )
    if match is None:
        raise VerifyError(f"concatenation is absent: {name}")
    return [re.sub(r"\s+", "", item) for item in match.group(1).split(",")]


def verify_exact_source(root: pathlib.Path) -> dict[str, Any]:
    receipt_path = EXACT / "reconstruction-receipt.json"
    receipt = load_json(root, receipt_path)
    equal(receipt.get("schema"), "npc-rv64-v9p-exact-source-reconstruction-v1", "reconstruction schema")
    equal(receipt.get("status"), "PASS", "reconstruction status")
    frozen = receipt.get("frozen_binding", {})
    equal(frozen.get("design_id"), FROZEN_DESIGN_ID, "frozen design-id")
    equal(frozen.get("file_count"), 146, "frozen RTL file count")
    equal(frozen.get("recomputed_source_set_sha256"), FROZEN_DESIGN_ID.removeprefix("sha256:"), "recomputed frozen source set")
    reconstruction = receipt.get("reconstruction", {})
    equal(reconstruction.get("artifact_count"), 6, "reconstructed source count")
    sources = reconstruction.get("artifacts", [])
    equal(len(sources), 6, "reconstructed source rows")
    for row in sources:
        source_path = EXACT / "sources" / pathlib.PurePosixPath(row.get("path", ""))
        equal(sha256_file(safe_file(root, source_path)), row.get("sha256"), f"exact source {row.get('path')}")

    dependency_path = EXACT / "diagnostic-dependency-receipt.json"
    dependency = load_json(root, dependency_path)
    equal(dependency.get("schema"), "npc-rv64-v9p-exact-bridge-diagnostic-dependencies-v1", "diagnostic dependency schema")
    equal(dependency.get("status"), "PASS", "diagnostic dependency status")
    equal(dependency.get("design_id"), FROZEN_DESIGN_ID, "diagnostic dependency design-id")
    equal(dependency.get("artifact_count"), 8, "diagnostic dependency count")
    for row in dependency.get("artifacts", []):
        source_path = EXACT / "sources" / pathlib.PurePosixPath(row.get("path", ""))
        equal(sha256_file(safe_file(root, source_path)), row.get("sha256"), f"diagnostic dependency {row.get('path')}")

    testbench_path = EXACT / "diagnostic-testbench-receipt.json"
    testbench = load_json(root, testbench_path)
    equal(testbench.get("schema"), "npc-rv64-v9p-terminal-diagnostic-testbench-v1", "diagnostic testbench schema")
    equal(testbench.get("status"), "PASS", "diagnostic testbench status")
    testbench_row = testbench.get("testbench", {})
    extracted_tb = EXACT / "testbench" / pathlib.PurePosixPath(testbench_row.get("path", ""))
    equal(sha256_file(safe_file(root, extracted_tb)), testbench_row.get("sha256"), "diagnostic testbench hash")

    old_backend_path = EXACT / "sources/npc/rv64/vsrc/execute/OooIntBackend.v"
    old_bridge_path = EXACT / "sources/npc/rv64/vsrc/memory/OooMemAxiBridge.v"
    old_backend = safe_file(root, old_backend_path).read_text(encoding="utf-8")
    old_bridge = safe_file(root, old_bridge_path).read_text(encoding="utf-8")
    for name in ("mem_sq_query_retry_ready_o", "mem1_sq_query_retry_ready_o"):
        ready = assignment(old_backend, name)
        require("!flush_i" in ready and "!checkpoint_restore_hold_w" in ready, f"V9P {name} cancel gates drifted")
        require("control_full_flush_barrier_w" not in ready, f"V9P {name} unexpectedly contains the current barrier fix")
    retry_fire = assignment(old_bridge, "sq_query_retry_fire_w")
    require("mem0_sq_query_retry_ready_i" in retry_fire, "V9P retry fire lacks backend credit")
    require("control_full_flush_barrier_i" not in retry_fire, "V9P bridge unexpectedly contains the current barrier fix")
    sq_state = old_bridge[old_bridge.index("S_SQ_QUERY: begin", old_bridge.index("always @(posedge clk)")):]
    barrier_index = sq_state.index("if (control_full_flush_barrier_i)")
    retry_index = sq_state.index("else if (sq_query_retry_fire_w)")
    require(barrier_index < retry_index, "V9P bridge no longer retains S_SQ_QUERY before retry release")
    equal(
        concat_members(old_backend, "mem_terminal_ingress_valid_w"),
        [
            "mem_retry1_tagged_terminal_w",
            "mem_retry0_tagged_terminal_w",
            "mem_amo_interphase_cancel_w",
            "mem_buffer_tagged_terminal_w",
            "mem_issue1_res_tagged_terminal_w",
            "mem_issue_res_tagged_terminal_w",
            "mem1_drop1_valid_i",
            "mem1_drop0_valid_i",
            "mem_drop1_valid_i",
            "mem_drop0_valid_i",
            "mem1_terminal_rsp_valid_w",
            "mem_terminal_rsp_valid_w",
        ],
        "V9P terminal ingress lane order",
    )
    return {
        "reconstruction": artifact(root, receipt_path),
        "diagnostic_dependencies": artifact(root, dependency_path),
        "diagnostic_testbench": artifact(root, testbench_path),
        "backend": artifact(root, old_backend_path),
        "bridge": artifact(root, old_bridge_path),
    }


def verify_frozen_failure(root: pathlib.Path) -> dict[str, Any]:
    classification_path = FROZEN_RUN / "rootfs-flag-on-full.classification.json"
    classification = load_json(root, classification_path)
    equal(classification.get("binding", {}).get("rtl_design_id"), FROZEN_DESIGN_ID, "frozen failure design-id")
    failure = classification.get("failure", {})
    equal(failure.get("marker"), MARKER, "frozen failure marker")
    equal(failure.get("duplicate_ingress_lanes"), "UNKNOWN", "immutable frozen lane observation")
    equal(failure.get("root_cause_status"), "OPEN", "immutable frozen classification")
    terminal = classification.get("terminal_state", {})
    equal(terminal.get("last_progress_commit"), 340000000, "frozen commit marker")
    equal(terminal.get("last_progress_pc"), "0xffffffff80426c9c", "frozen PC marker")
    equal(terminal.get("runner_status"), "FAIL rc=2", "frozen runner status")
    driver_path = FROZEN_RUN / "rootfs-flag-on-full/driver.log"
    driver = safe_file(root, driver_path).read_text(encoding="utf-8", errors="replace")
    # The driver keeps the live console and then prints its bounded console
    # tail after the simulator aborts.  The same assertion line is therefore
    # present twice, while the identical commit/PC/fatal sequence identifies
    # one physical assertion event rather than two DUT events.
    equal(driver.count(MARKER), 2, "frozen collector marker line count")
    equal(driver.count("[npc-systemd-check] ---- console tail ----"), 1, "frozen console-tail replay boundary")
    equal(driver.count("[progress] 340000000 insts, pc=0xffffffff80426c9c"), 2, "frozen terminal progress line count")
    return {
        "classification": artifact(root, classification_path),
        "driver": artifact(root, driver_path),
        "driver_marker_lines": 2,
        "physical_assertion_events": 1,
        "marker_line_explanation": "the bounded console tail repeats the same commit/PC/fatal sequence once",
        "observed_duplicate_ingress_lanes": "UNKNOWN",
        "observed_owner_tuple": "UNKNOWN",
    }


def verify_counterexamples(root: pathlib.Path) -> dict[str, Any]:
    lane_path = EVIDENCE / "v9p-lane-pairs/summary.json"
    lane = load_json(root, lane_path)
    equal(lane.get("schema"), "npc-rv64-v9p-terminal-lane-pair-negative-v1", "lane-pair schema")
    equal(lane.get("status"), "PASS", "lane-pair status")
    equal(lane.get("assertion_policy"), "fail-loud; no merge, deduplication, waiver or weakening", "collector assertion policy")
    expected_pairs = {
        "bank0": ([2, 10], ["mem_drop0", "mem_retry0_cancel"]),
        "bank1": ([4, 11], ["mem1_drop0", "mem_retry1_cancel"]),
    }
    for bank, (lanes, sources) in expected_pairs.items():
        row = lane.get("cases", {}).get(bank, {})
        equal(row.get("lanes"), lanes, f"{bank} lane pair")
        equal(row.get("sources"), sources, f"{bank} terminal sources")
        equal(row.get("result"), "REJECTED", f"{bank} collector result")
        text = verify_record(root, row.get("log"), f"{bank} collector log")
        equal(text.count(MARKER), 1, f"{bank} collector rejection marker")

    bridge_path = EVIDENCE / "v9p-bridge-counterexample/summary.json"
    bridge = load_json(root, bridge_path)
    equal(bridge.get("schema"), "npc-rv64-v9p-bridge-counterexample-v1", "bridge counterexample schema")
    equal(bridge.get("status"), "PASS", "bridge counterexample status")
    equal(bridge.get("cleanup", {}).get("compiled_images_retained"), 0, "bridge retained images")
    negative = bridge.get("v9p_rtl", {}).get("focused_negative", {})
    equal(negative.get("result"), "REJECTED", "V9P focused negative")
    negative_log = verify_record(root, negative.get("log"), "V9P focused negative log")
    require("V9R bridge C0 forbids retry fire got=1 expected=0" in negative_log, "V9P C0 retry-fire counterexample marker is absent")
    natural = bridge.get("v9p_rtl", {}).get("c0_c1_counterexample", {})
    equal(natural.get("bank0_collector_lanes"), [2, 10], "V9P natural bank0 lanes")
    equal(natural.get("result"), "PASS", "V9P natural counterexample")
    natural_log = verify_record(root, natural.get("log"), "V9P C0-C1 log")
    require("[V15G-V9P-C0-C1-HANDOFF][PASS] bank0_lanes=2,10" in natural_log, "V9P natural C0-C1 marker is absent")
    control = bridge.get("current_rtl", {}).get("focused_control", {})
    equal(control.get("result"), "PASS", "current bridge control")
    control_log = verify_record(root, control.get("log"), "current bridge control log")
    require("[PASS] tb_ooo_mem_axi_bridge_v9r_sq_retry_c0" in control_log, "current bridge control PASS marker is absent")
    return {
        "lane_pair_summary": artifact(root, lane_path),
        "bridge_counterexample_summary": artifact(root, bridge_path),
        "reproducible_lane_pairs": {
            "bank0": [2, 10],
            "bank1": [4, 11],
        },
    }


def verify_current_fix(root: pathlib.Path, design_id: str) -> dict[str, Any]:
    backend_path = pathlib.PurePosixPath("npc/rv64/vsrc/execute/OooIntBackend.v")
    bridge_path = pathlib.PurePosixPath("npc/rv64/vsrc/memory/OooMemAxiBridge.v")
    backend = safe_file(root, backend_path).read_text(encoding="utf-8")
    bridge = safe_file(root, bridge_path).read_text(encoding="utf-8")
    for name in ("mem_sq_query_retry_ready_o", "mem1_sq_query_retry_ready_o"):
        require("!control_full_flush_barrier_w" in assignment(backend, name), f"current {name} barrier gate is absent")
    require("!control_full_flush_barrier_i" in assignment(bridge, "sq_query_retry_fire_w"), "current bridge retry-fire barrier gate is absent")
    require("[V9R-SQ-RETRY-C0-HANDOFF]" in backend, "current backend C0 assertion is absent")
    require("[V9R-MEM-SQ-RETRY-C0-HANDOFF]" in bridge, "current bridge C0 assertion is absent")

    current_path = EVIDENCE / "v9r-current/summary.json"
    current = load_json(root, current_path)
    equal(current.get("schema"), "npc-rv64-v9r-sq-retry-c0-current-v1", "current V9R schema")
    equal(current.get("status"), "PASS", "current V9R status")
    equal(current.get("design_id"), design_id, "current V9R design-id")
    equal(current.get("baseline", {}).get("status"), "PASS", "current V9R baseline")
    equal(current.get("baseline", {}).get("backend_banks"), 2, "current V9R backend banks")
    equal(current.get("baseline", {}).get("forced_barrier_cases"), 2, "current V9R forced barrier cases")
    for name, record in current.get("baseline", {}).get("logs", {}).items():
        text = verify_record(root, record, f"current baseline {name} log")
        require("[PASS]" in text, f"current baseline {name} PASS marker is absent")
    variants = current.get("compile_success_rtl_variants", [])
    equal(
        [row.get("id") for row in variants],
        ["backend-bank0-ready-open", "backend-bank1-ready-open", "bridge-retry-fire-open"],
        "current V9R mutation inventory",
    )
    for row in variants:
        name = row.get("id")
        equal(row.get("result"), "REJECTED_COMPILE_SUCCESS_VARIANT", f"{name} result")
        equal(row.get("make_return_code"), 2, f"{name} make return code")
        equal(row.get("compiled_image", {}).get("retained"), False, f"{name} image retention")
        verify_record(root, row.get("mutated_rtl"), f"{name} RTL")
        log = verify_record(root, row.get("log"), f"{name} log")
        marker = "[V9R-MEM-SQ-RETRY-C0-HANDOFF]" if name == "bridge-retry-fire-open" else "[V9R-SQ-RETRY-C0-HANDOFF]"
        require(marker in log, f"{name} rejection marker is absent")
    cleanup = current.get("cleanup", {})
    equal(cleanup.get("compiled_images_retained"), 0, "current V9R retained images")
    evidence_dir = root / EVIDENCE
    retained_images = [path for path in evidence_dir.rglob("*.vvp") if path.is_file()]
    equal(retained_images, [], "task-run compiled images")
    return {
        "summary": artifact(root, current_path),
        "backend": artifact(root, backend_path),
        "bridge": artifact(root, bridge_path),
        "baseline_profiles": "2/2",
        "compile_success_mutations_rejected": "3/3",
        "compiled_images_retained": 0,
    }


def verify_layered_signoff(root: pathlib.Path, design_id: str) -> dict[str, Any]:
    receipt_path = pathlib.PurePosixPath(
        "npc/rv64/eval/ppa/evidence/layered-system-signoff-current.json"
    )
    receipt = load_json(root, receipt_path)
    equal(receipt.get("schema"), "npc-rv64-layered-system-signoff-current-v1", "layered signoff schema")
    equal(receipt.get("status"), "PASS", "layered signoff status")
    equal(receipt.get("rtl_design_id"), design_id, "layered signoff design-id")
    equal(receipt.get("production_rtl_file_count"), 146, "layered signoff RTL file count")
    equal(receipt.get("default_signoff_conjunction"), DEFAULT_LAYERS, "default signoff conjunction")
    layers = receipt.get("layers", {})
    for layer in DEFAULT_LAYERS:
        row = layers.get(layer, {})
        equal(row.get("status"), "PASS", f"{layer} status")
        equal(row.get("design_id"), design_id, f"{layer} design-id")
        if "rtl_assertions" in row:
            equal(row.get("rtl_assertions"), {"enabled": True, "failures": 0}, f"{layer} RTL assertions")
    ubuntu = receipt.get("optional_full_ubuntu", {})
    equal(ubuntu.get("status"), "NOT_RUN", "optional Ubuntu status")
    equal(ubuntu.get("blocks_default_signoff"), False, "optional Ubuntu gate")
    equal(ubuntu.get("launch_policy"), "explicit-user-request-only", "optional Ubuntu launch policy")
    return {
        "receipt": artifact(root, receipt_path),
        "default_conjunction": DEFAULT_LAYERS,
        "optional_ubuntu": "NOT_RUN_EXPLICIT_REQUEST_ONLY",
    }


def build_summary(root: pathlib.Path) -> dict[str, Any]:
    design_id, file_count = current_design_id(root)
    equal(design_id, CURRENT_DESIGN_ID, "current RTL design-id")
    equal(file_count, 146, "current RTL file count")
    frozen = verify_frozen_failure(root)
    exact = verify_exact_source(root)
    counterexamples = verify_counterexamples(root)
    current = verify_current_fix(root, design_id)
    layered = verify_layered_signoff(root, design_id)
    return {
        "schema": "npc-rv64-v9p-terminal-root-cause-backfill-v1",
        "status": "PASS",
        "historical_failure": {
            "design_id": FROZEN_DESIGN_ID,
            "run_id": "2026-07-23-rv64-v9p-serialize-current-design/rootfs-flag-on-full",
            "marker": MARKER,
            **frozen,
            "original_status_preserved": True,
        },
        "exact_source": exact,
        "root_cause": {
            "classification": "C0_RETRY_HANDOFF_SPLIT_OWNERSHIP_THEN_C1_DUPLICATE_TERMINAL",
            "cycle_sequence": [
                "C0 full-flush barrier: V9P backend exposes retry credit, captures the MIQ owner into the bank-local retry holder and pops the MIQ",
                "C0 full-flush barrier: V9P bridge gives barrier retention priority and keeps the same S_SQ_QUERY owner",
                "C1 flush: retained bridge emits drop0 while the captured retry holder emits cancel for the same owner tuple",
            ],
            "exact_reproducible_pair_family": counterexamples["reproducible_lane_pairs"],
            "frozen_instance_lane_pair": "UNKNOWN_NOT_RETAINED_IN_IMMUTABLE_LOG",
            "frozen_instance_owner_tuple": "UNKNOWN_NOT_RETAINED_IN_IMMUTABLE_LOG",
            "pair_scope": "both symmetric banks are dynamically reproduced; the immutable run does not identify which bank fired",
            "counterexample_evidence": counterexamples,
        },
        "current_fix": {
            "design_id": design_id,
            "rtl_file_count": file_count,
            "contract": "C0 barrier suppresses both backend retry credit/capture and bridge retry fire; the bridge alone retains the owner until C1 flush",
            "mechanism": [
                "barrier gate on backend bank0 retry-ready",
                "barrier gate on backend bank1 retry-ready",
                "barrier gate on bridge SQ-query retry-fire",
            ],
            "assertion_policy": "fail-loud; no terminal deduplication, merge, waiver or assertion weakening",
            "focused_evidence": current,
        },
        "current_aggregate": layered,
        "cleanup": {
            "compiled_images_retained": 0,
            "retained": "bounded logs, negative RTL variants, source/hash receipts and result JSON",
        },
        "validation_depth_candidate": "VD4_PENDING_INDEPENDENT_REVIEW",
        "non_claims": [
            "the exact bank or owner tuple of the immutable V9P failure is known",
            "Ubuntu 22.04 or systemd full-rootfs recertification was run",
            "ARCH_STABLE, synthesis, STA, power, area, CPI or PPA promotion",
        ],
    }


def write_json(path: pathlib.Path, payload: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = path.with_suffix(path.suffix + ".tmp")
    temporary.write_text(
        json.dumps(payload, ensure_ascii=False, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )
    temporary.replace(path)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", type=pathlib.Path)
    parser.add_argument(
        "--output",
        type=pathlib.Path,
        default=pathlib.Path(EVIDENCE / "v9p-root-cause-summary.json"),
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    root = find_root(args.root or pathlib.Path(__file__))
    output = args.output if args.output.is_absolute() else root / args.output
    try:
        payload = build_summary(root)
        write_json(output, payload)
    except (OSError, ValueError, VerifyError) as exc:
        print(f"[RV64-V9P-ROOT-CAUSE][FAIL] {exc}", file=sys.stderr)
        return 2
    print(
        "[RV64-V9P-ROOT-CAUSE][PASS] "
        f"historical={FROZEN_DESIGN_ID} current={payload['current_fix']['design_id']} "
        "pairs=2,10|4,11 frozen-pair=UNKNOWN current-mutations=3/3 "
        "default-signoff=L0+L1+L2+L3 ubuntu=NOT_RUN compiled-images=0"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
