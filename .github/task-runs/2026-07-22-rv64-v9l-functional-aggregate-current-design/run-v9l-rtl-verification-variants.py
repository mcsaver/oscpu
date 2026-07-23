#!/usr/bin/env python3
"""Run compile-success local RV64 RTL assertion verification variants for V9L."""

from __future__ import annotations

import hashlib
import importlib.util
import json
import pathlib
import shlex
import shutil
import subprocess
import sys
from typing import Any


RUN_ID = "2026-07-22-rv64-v9l-functional-aggregate-current-design"
ROOT = pathlib.Path(__file__).resolve().parents[3]
TASK = ROOT / ".github/task-runs" / RUN_ID
OUTPUT = TASK / "rtl-verification-variants"
TESTBENCH = ROOT / "npc/rv64/testbench"
SQ_RTL = ROOT / "npc/rv64/vsrc/memory/OooStoreQueue.v"
BRIDGE_RTL = ROOT / "npc/rv64/vsrc/memory/OooMemAxiBridge.v"
BACKEND_RTL = ROOT / "npc/rv64/vsrc/execute/OooIntBackend.v"
SQ_TB = ROOT / "npc/rv64/testbench/tests/tb_ooo_store_queue.sv"

TOOL_PATH = ROOT / "npc/rv64/eval/ppa/tools/functional_aggregate.py"
TOOL_SPEC = importlib.util.spec_from_file_location(
    "v9l_verification_variant_functional_tool", TOOL_PATH)
assert TOOL_SPEC is not None and TOOL_SPEC.loader is not None
functional = importlib.util.module_from_spec(TOOL_SPEC)
sys.modules[TOOL_SPEC.name] = functional
TOOL_SPEC.loader.exec_module(functional)


SQ_OWNER_CURRENT = """            ((!rob_head_valid_i) || (!rob_head_owner_open_i) ||
"""
SQ_OWNER_VARIANT = """            ((!rob_head_valid_i) || (!rob_head_launch_open_i) ||
"""

BRIDGE_CURRENT = """        if (station_sq_lookahead_query_w &&
            (mem0_sq_query_retry_ready_i ||
             ((mem0_sq_query_forward_i || mem0_sq_query_replay_i) &&
              dcache_lookup_en_w) ||
             (mem0_sq_query_allow_i &&
              (dcache_lookup_en_w !== rsp_ready_w)))) begin
"""
BRIDGE_VARIANT = """        if (station_sq_lookahead_query_w &&
            (mem0_sq_query_retry_ready_i ||
             ((mem0_sq_query_forward_i || mem0_sq_query_replay_i) &&
              dcache_lookup_en_w) ||
             (mem0_sq_query_allow_i &&
              !dcache_lookup_en_w))) begin
"""

BACKEND_CURRENT = """      if ((mem_retry0_valid_q &&
           ((mem_bridge_active_load_w &&
             (mem_owner_query_token_i == mem_retry0_owner_token_q)) ||
            (mem_bridge_station_load_w &&
             (mem_station_query_token_i == mem_retry0_owner_token_q)))) ||
          (mem_retry1_valid_q &&
           ((mem1_bridge_active_load_w &&
             (mem1_owner_query_token_i == mem_retry1_owner_token_q)) ||
            (mem1_bridge_station_load_w &&
             (mem1_station_query_token_i == mem_retry1_owner_token_q))))) begin
"""
BACKEND_VARIANT = """      if ((mem_retry0_valid_q &&
           (mem_bridge_active_load_w || mem_bridge_station_load_w)) ||
          (mem_retry1_valid_q &&
           (mem1_bridge_active_load_w || mem1_bridge_station_load_w))) begin
"""


def sha256(path: pathlib.Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def relative(path: pathlib.Path) -> str:
    return path.resolve().relative_to(ROOT.resolve()).as_posix()


def current_design_id() -> str:
    evaluator = functional.freeze.load_workspace_module(
        ROOT,
        "npc/rv64/eval/ppa/tools/architecture_hard_gates.py",
        "v9l_variant_current_design",
    )
    design_hex, _ = evaluator.rtl_binding(ROOT)
    return f"sha256:{design_hex}"


def reset_output() -> None:
    resolved = OUTPUT.resolve()
    resolved.relative_to(TASK.resolve())
    if OUTPUT.exists():
        if OUTPUT.is_symlink() or not OUTPUT.is_dir():
            raise RuntimeError(f"variant output is not a regular directory: {OUTPUT}")
        shutil.rmtree(OUTPUT)
    OUTPUT.mkdir(parents=True)


def make_variant(
    name: str,
    source: pathlib.Path,
    current: str,
    replacement: str,
) -> pathlib.Path:
    directory = OUTPUT / name
    directory.mkdir(parents=True)
    source_text = source.read_text(encoding="utf-8")
    if source_text.count(current) != 1:
        raise RuntimeError(f"{name}: expected exactly one production assertion anchor")
    destination = directory / source.name
    destination.write_text(
        source_text.replace(current, replacement, 1), encoding="utf-8")
    return destination


def run_case(
    *,
    name: str,
    test: str,
    expected_label: str,
    make_overrides: list[str],
    description: str,
    source_files: list[pathlib.Path],
    expected_stimulus: str | None = None,
) -> dict[str, Any]:
    directory = OUTPUT / name
    directory.mkdir(parents=True, exist_ok=True)
    build = directory / "build"
    result = directory / "result"
    command = [
        "make", "-B", "-C", str(TESTBENCH), f"TESTS={test}",
        *make_overrides, f"BUILD_DIR={build}", f"RESULT_DIR={result}", "run",
    ]
    completed = subprocess.run(
        command,
        cwd=ROOT,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        check=False,
    )
    (directory / "command.log").write_text(completed.stdout, encoding="utf-8")
    test_log = result / "logs" / f"{test}.log"
    log_text = test_log.read_text(encoding="utf-8") if test_log.is_file() else ""
    compiled_image = build / f"{test}.vvp"
    compile_succeeded = (
        compiled_image.is_file()
        and "[COMPILE]" in log_text
        and "compilation returned nonzero status" not in log_text
        and "syntax error" not in log_text.lower()
    )
    target_count = log_text.count(expected_label)
    stimulus_reached = (
        expected_stimulus is None or log_text.count(expected_stimulus) == 1)
    rejected = (
        completed.returncode != 0
        and compile_succeeded
        and target_count == 1
        and stimulus_reached
        and "simulation returned nonzero status" in log_text
        and "[RESULT] FAIL" in log_text
        and "[RESULT] PASS" not in log_text
    )
    record: dict[str, Any] = {
        "name": name,
        "scope": "local RV64 Verilog/SystemVerilog assertion verification",
        "description": description,
        "command": shlex.join(command).replace(str(ROOT), "<REPO>"),
        "return_code": completed.returncode,
        "compile_succeeded": compile_succeeded,
        "target_assertion": expected_label,
        "target_assertion_count": target_count,
        "stimulus_reached": stimulus_reached,
        "simulation_rejected_variant": rejected,
        "test_log": relative(test_log),
        "compiled_image_sha256": sha256(compiled_image) if compiled_image.is_file() else None,
        "sources": [
            {"path": relative(path), "sha256": sha256(path)} for path in source_files
        ],
    }
    (directory / "summary.json").write_text(
        json.dumps(record, allow_nan=False, ensure_ascii=False,
                   indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )
    state = "PASS" if rejected else "FAIL"
    print(f"[V9L-RTL-VARIANT][{state}] {name}", flush=True)
    return record


def run_release_case() -> dict[str, Any]:
    name = "retry-distinct-residency-release"
    test = "tb_ooo_int_backend"
    marker = "[V9L-RETRY-DISTINCT-RESIDENCY] retry0 + distinct station load PASS"
    directory = OUTPUT / name
    directory.mkdir(parents=True)
    build = directory / "build"
    result = directory / "result"
    command = [
        "make", "-B", "-C", str(TESTBENCH), f"TESTS={test}",
        "TB_IVFLAGS_tb_ooo_int_backend=-DV8S_DUAL_MEMORY_FOCUSED",
        f"BUILD_DIR={build}", f"RESULT_DIR={result}", "run",
    ]
    completed = subprocess.run(
        command,
        cwd=ROOT,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        check=False,
    )
    (directory / "command.log").write_text(completed.stdout, encoding="utf-8")
    test_log = result / "logs" / f"{test}.log"
    log_text = test_log.read_text(encoding="utf-8") if test_log.is_file() else ""
    compiled_image = build / f"{test}.vvp"
    compile_succeeded = (
        compiled_image.is_file()
        and "[COMPILE]" in log_text
        and "compilation returned nonzero status" not in log_text
        and "syntax error" not in log_text.lower()
    )
    passed = (
        completed.returncode == 0
        and compile_succeeded
        and log_text.count(marker) == 1
        and log_text.splitlines().count("[RESULT] PASS") == 1
        and "[RESULT] FAIL" not in log_text
    )
    record: dict[str, Any] = {
        "name": name,
        "scope": "local RV64 Verilog/SystemVerilog focused release test",
        "description": (
            "Production retry-holder assertion accepts a distinct station "
            "transaction while retaining the same-bank admission fence."
        ),
        "command": shlex.join(command).replace(str(ROOT), "<REPO>"),
        "return_code": completed.returncode,
        "compile_succeeded": compile_succeeded,
        "required_marker": marker,
        "required_marker_count": log_text.count(marker),
        "passed": passed,
        "test_log": relative(test_log),
        "compiled_image_sha256": sha256(compiled_image) if compiled_image.is_file() else None,
        "sources": [
            {"path": relative(path), "sha256": sha256(path)}
            for path in (BACKEND_RTL, ROOT / "npc/rv64/testbench/tests/tb_ooo_int_backend.sv")
        ],
    }
    (directory / "summary.json").write_text(
        json.dumps(record, allow_nan=False, ensure_ascii=False,
                   indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )
    state = "PASS" if passed else "FAIL"
    print(f"[V9L-RTL-RELEASE][{state}] {name}", flush=True)
    return record


def main() -> int:
    reset_output()
    design_id = current_design_id()

    sq_owner_variant = make_variant(
        "sq-launch-admission-substitution",
        SQ_RTL,
        SQ_OWNER_CURRENT,
        SQ_OWNER_VARIANT,
    )
    bridge_variant = make_variant(
        "bridge-no-credit-broad-assertion",
        BRIDGE_RTL,
        BRIDGE_CURRENT,
        BRIDGE_VARIANT,
    )
    backend_variant = make_variant(
        "retry-distinct-residency-broad-assertion",
        BACKEND_RTL,
        BACKEND_CURRENT,
        BACKEND_VARIANT,
    )

    release = run_release_case()
    records = [
        run_case(
            name="sq-launch-admission-substitution",
            test="tb_ooo_store_queue",
            expected_label="[V9L-SQ-POST-LAUNCH-OWNER]",
            make_overrides=[f"RTL_OOO_STORE_QUEUE={sq_owner_variant}"],
            description=(
                "Replace post-launch ROB owner authorization with the stricter "
                "first-launch admission signal; selective recovery must reject it."
            ),
            source_files=[SQ_RTL, sq_owner_variant, SQ_TB],
        ),
        run_case(
            name="sq-owner-authorization-negative-stimulus",
            test="tb_ooo_store_queue",
            expected_label="[V9L-SQ-POST-LAUNCH-OWNER]",
            expected_stimulus="[V9L-SQ-OWNER-OPEN-NEGATIVE-STIMULUS] nonterminal issued store owner authorization closed",
            make_overrides=[
                "TB_IVFLAGS_tb_ooo_store_queue=-DV9L_SQ_OWNER_OPEN_NEGATIVE"
            ],
            description=(
                "Withdraw exact ROB owner authorization from a live nonterminal "
                "issued store; the production assertion must reject the edge."
            ),
            source_files=[SQ_RTL, SQ_TB],
        ),
        run_case(
            name="bridge-no-credit-broad-assertion",
            test="tb_ooo_mem_axi_bridge",
            expected_label="[V9L-SQ-LOOKAHEAD-CREDIT]",
            make_overrides=[f"RTL_OOO_MEM_AXI_BRIDGE={bridge_variant}"],
            description=(
                "Restore the obsolete allow-implies-lookup assertion; a valid "
                "station decision without response credit must reject it."
            ),
            source_files=[BRIDGE_RTL, bridge_variant],
        ),
        run_case(
            name="retry-distinct-residency-broad-assertion",
            test="tb_ooo_int_backend",
            expected_label="[V9L-RETRY-OWNER-DISJOINT]",
            make_overrides=[
                f"RTL_OOO_INT_BACKEND={backend_variant}",
                "TB_IVFLAGS_tb_ooo_int_backend=-DV8S_DUAL_MEMORY_FOCUSED",
            ],
            description=(
                "Restore the obsolete any-load residency exclusion; a distinct "
                "station token beside retry0 must reject the over-constrained variant."
            ),
            source_files=[BACKEND_RTL, backend_variant],
        ),
    ]
    all_rejected = all(record["simulation_rejected_variant"] for record in records)
    passed = bool(release["passed"]) and all_rejected
    summary = {
        "schema": "rv64-v9l-rtl-verification-variants-v1",
        "design_id": design_id,
        "scope": "local RV64 Verilog/SystemVerilog assertion verification",
        "compile_success_required": True,
        "focused_release": release,
        "all_rejected": all_rejected,
        "passed": passed,
        "counts": {
            "focused_release_required": 1,
            "focused_release_passed": int(bool(release["passed"])),
            "required": len(records),
            "compile_succeeded": sum(bool(r["compile_succeeded"]) for r in records),
            "rejected": sum(bool(r["simulation_rejected_variant"]) for r in records),
        },
        "variants": records,
    }
    (OUTPUT / "summary.json").write_text(
        json.dumps(summary, allow_nan=False, ensure_ascii=False,
                   indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )
    if not passed:
        print("[V9L-RTL-VARIANTS][FAIL] release or variant contract did not pass")
        return 1
    print(
        f"[V9L-RTL-VARIANTS][PASS] compile-success={len(records)}/{len(records)} "
        f"rejected={len(records)}/{len(records)} design_id={design_id}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
