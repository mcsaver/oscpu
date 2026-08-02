#!/usr/bin/env python3
"""Classify seven RV64 P0 gates by their elaborated testbench source cone."""

from __future__ import annotations

import argparse
import hashlib
import importlib.util
import json
import pathlib
import re
import subprocess
import sys
from dataclasses import dataclass
from typing import Any


HERE = pathlib.Path(__file__).resolve().parent
ROOT = HERE.parents[2]
TB_DIR = ROOT / "npc/rv64/testbench"
V14B_RECEIPT = (
    ROOT
    / ".github/task-runs/2026-08-02-rv64-v14b-architecture-current-"
    "freeze-audit-v1/evidence/p0-direct-rebind-checker-replay-1/"
    "rebind-receipt.json"
)


@dataclass(frozen=True)
class Gate:
    result: str
    runner: str
    positive_tests: tuple[str, ...]
    expected_class: str
    extra_sources: tuple[str, ...] = ()


GATES: dict[str, Gate] = {
    "FDG-G1": Gate(
        "npc/rv64/eval/ppa/evidence/fdg-arch-trap-current.json",
        ".github/task-runs/2026-07-21-rv64-v9d-fdg-arch-trap/"
        "run-fdg-mutations.py",
        ("tb_ooo_fp_legality_dispatch_path", "tb_ooo_priv_system"),
        "DYNAMIC_RERUN_REQUIRED",
    ),
    "XRET-G1": Gate(
        "npc/rv64/eval/ppa/evidence/xret-current-mode-current.json",
        ".github/task-runs/2026-07-21-rv64-v9e-xret-current-design/"
        "run-xret-mutations.py",
        ("tb_ooo_fetch_head_classify_gate", "tb_ooo_priv_system"),
        "DYNAMIC_RERUN_REQUIRED",
    ),
    "IFU-AXI-G1": Gate(
        "npc/rv64/eval/ppa/evidence/ifu-axi-flush-drain-current.json",
        ".github/task-runs/2026-07-22-rv64-v9g-ifu-axi-current-design/"
        "run-ifu-axi-variants.py",
        (
            "tb_ooo_fetch_axi_bridge",
            "tb_ooo_fetch_axi_bridge_xbar",
            "tb_axi_xbar",
        ),
        "FROZEN_EXECUTION_REPLAY_ELIGIBLE",
    ),
    "IFU-FETCH-G2": Gate(
        "npc/rv64/eval/ppa/evidence/ifu-fetch-provenance-current.json",
        ".github/task-runs/2026-07-22-rv64-v9h-ifu-fetch-provenance-"
        "current-design/run-ifu-fetch-variants.py",
        ("tb_ooo_fetch_packet_decode", "tb_ooo_fetch_page_end_fault"),
        "FROZEN_EXECUTION_REPLAY_ELIGIBLE",
    ),
    "IFU-ACCESS-G1": Gate(
        "npc/rv64/eval/ppa/evidence/ifu-access-current.json",
        ".github/task-runs/2026-07-22-rv64-v9i-ifu-access-current-design/"
        "run-ifu-access-variants.py",
        (
            "tb_ooo_fetch_access_footprint",
            "tb_ooo_fetch_axi_access_attrs",
            "tb_ooo_ifu_lane1_fault_owner",
            "tb_axi_exec_firewall",
        ),
        "DYNAMIC_RERUN_REQUIRED",
        (
            "npc/rv64/testbench/scripts/run_axi_dpi_sized.sh",
            "npc/rv64/testbench/cpp/axi_dpi_slave_sized_tb.cpp",
            "npc/rv64/testbench/cpp/sized_dpi_guard_tb.cpp",
            "npc/rv64/csrc/dpi.c",
            "npc/rv64/csrc/memory/paddr.c",
            "npc/rv64/vsrc/sim/AxiDpiSlave.sv",
        ),
    ),
    "IFU-TVAL-G1": Gate(
        "npc/rv64/eval/ppa/evidence/ifu-tval-current.json",
        ".github/task-runs/2026-07-22-rv64-v9j-ifu-tval-current-design/"
        "run-ifu-tval-variants.py",
        (
            "tb_ooo_fetch_packet_decode",
            "tb_ooo_fetch_page_end_fault",
            "tb_ooo_fetch_packet_fifo",
            "tb_ooo_pending_lane1_capture_gate",
            "tb_ooo_pending_dispatch_arbiter",
            "tb_ooo_pending_trap_exit_sequencer",
            "tb_ooo_csr_trap_request_mux",
            "tb_ooo_ifu_lane1_fault_owner",
        ),
        "DYNAMIC_RERUN_REQUIRED",
    ),
    "INSTRET-G1": Gate(
        "npc/rv64/eval/ppa/evidence/instret-retirement-current.json",
        ".github/task-runs/2026-07-21-rv64-v9c-instret-retirement/"
        "run-instret-mutations.py",
        (
            "tb_ooo_sv39_boot",
            "tb_ooo_commit_output_mux",
            "tb_ooo_alu_core_slice",
            "tb_csr_file",
        ),
        "DYNAMIC_RERUN_REQUIRED",
    ),
}

COHORT_SHARED_SUPPORT = {
    "npc/rv64/testbench/common/tb_common.svh",
}


def load_json(path: pathlib.Path) -> dict[str, Any]:
    payload = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(payload, dict):
        raise ValueError(f"JSON root is not an object: {path}")
    return payload


def digest(path: pathlib.Path) -> str:
    value = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            value.update(chunk)
    return value.hexdigest()


def canonical_digest(entries: dict[str, str]) -> str:
    encoded = json.dumps(
        entries, sort_keys=True, separators=(",", ":")
    ).encode("utf-8")
    return hashlib.sha256(encoded).hexdigest()


def rtl_binding() -> tuple[str, dict[str, str]]:
    suffixes = {".v", ".sv", ".vh", ".svh", ".mk"}
    files = sorted(
        path
        for path in (ROOT / "npc/rv64/vsrc").rglob("*")
        if path.is_file() and path.suffix.lower() in suffixes
    )
    entries = {
        path.relative_to(ROOT).as_posix(): digest(path) for path in files
    }
    return "sha256:" + canonical_digest(entries), entries


def load_runner_tests(relative: str) -> set[str]:
    runner = ROOT / relative
    spec = importlib.util.spec_from_file_location(
        "v14c_" + runner.stem.replace("-", "_"), runner
    )
    if spec is None or spec.loader is None:
        raise ValueError(f"cannot load RTL variant runner: {relative}")
    module = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    tests: set[str] = set()
    for name in ("MUTATIONS", "VARIANTS", "ORACLE_PROBES"):
        for row in getattr(module, name, ()):
            test_name = getattr(row, "test_name", None)
            if isinstance(test_name, str) and test_name:
                tests.add(test_name)
    return tests


def make_database(test_names: set[str]) -> str:
    completed = subprocess.run(
        [
            "make",
            "-C",
            str(TB_DIR),
            "-pn",
            "TESTS=" + " ".join(sorted(test_names)),
        ],
        cwd=ROOT,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        check=False,
    )
    if not completed.stdout or completed.returncode not in (0, 1):
        raise ValueError(
            "cannot expand testbench source variables: "
            + completed.stderr[-400:]
        )
    return completed.stdout


def variable_tokens(database: str, variable: str) -> list[str]:
    match = re.search(
        rf"^{re.escape(variable)}\s*[:+?]?=\s*(.*)$",
        database,
        flags=re.MULTILINE,
    )
    if match is None:
        return []
    return match.group(1).split()


def resolve_source(token: str) -> pathlib.Path:
    path = pathlib.Path(token)
    if not path.is_absolute():
        path = TB_DIR / path
    return path.resolve()


def relative_source(path: pathlib.Path) -> str:
    try:
        return path.relative_to(ROOT).as_posix()
    except ValueError as exc:
        raise ValueError(f"source escaped local RV64 workspace: {path}") from exc


def closure_for_gate(
    gate: Gate, database: str
) -> tuple[list[str], list[str], list[str]]:
    positive = set(gate.positive_tests)
    mutation = load_runner_tests(gate.runner)
    all_tests = positive | mutation
    sources: set[str] = {
        "npc/rv64/testbench/common/tb_common.svh",
        "npc/rv64/testbench/scripts/check_tb_result.py",
        *gate.extra_sources,
    }
    missing_variables: list[str] = []
    for test in sorted(all_tests):
        tokens = variable_tokens(database, f"TB_SRCS_{test}")
        if not tokens:
            missing_variables.append(f"TB_SRCS_{test}")
            continue
        tokens.extend(variable_tokens(database, f"TB_DEPS_{test}"))
        for token in tokens:
            sources.add(relative_source(resolve_source(token)))
    return sorted(sources), sorted(positive), sorted(mutation)


def compare_closure(
    sources: list[str], old_files: dict[str, str], old_bindings: dict[str, str]
) -> tuple[list[dict[str, str]], list[str], list[str]]:
    drift: list[dict[str, str]] = []
    unbound: list[str] = []
    missing: list[str] = []
    historical = {**old_bindings, **old_files}
    for relative in sources:
        path = ROOT / relative
        if not path.is_file():
            missing.append(relative)
            continue
        before = historical.get(relative)
        if before is None:
            unbound.append(relative)
            continue
        after = digest(path)
        if after != before:
            drift.append(
                {"path": relative, "historical_sha256": before,
                 "current_sha256": after}
            )
    return drift, unbound, missing


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--output", required=True, type=pathlib.Path)
    args = parser.parse_args()
    if args.output.exists():
        raise ValueError(f"refusing to replace active-cone audit: {args.output}")

    design_id, current_files = rtl_binding()
    v14b = load_json(V14B_RECEIPT)
    if (
        v14b.get("status") != "PASS"
        or v14b.get("current_design_id") != design_id
        or v14b.get("source_identity", {}).get("file_count") != len(current_files)
        or v14b.get("source_identity", {}).get("pre_post_equal") is not True
    ):
        raise ValueError("V14B current module aggregate is not live-design bound")

    all_tests: set[str] = set()
    for gate in GATES.values():
        all_tests.update(gate.positive_tests)
        all_tests.update(load_runner_tests(gate.runner))
    database = make_database(all_tests)

    historical_results = {
        gate_id: load_json(ROOT / gate.result) for gate_id, gate in GATES.items()
    }
    first_result = next(iter(historical_results.values()))
    old_files = first_result["provenance"]["files"]
    old_design_id = first_result["design_id"]
    shared_support: dict[str, str] = {}
    for relative in sorted(COHORT_SHARED_SUPPORT):
        hashes = {
            result["provenance"]["source_bindings"][relative]
            for result in historical_results.values()
            if relative in result["provenance"]["source_bindings"]
        }
        if len(hashes) != 1:
            raise ValueError(
                f"shared cohort support lacks a unique binding: {relative}"
            )
        shared_support[relative] = next(iter(hashes))
    full_rtl_drift = [
        {
            "path": path,
            "historical_sha256": old_files.get(path, "<unbound>"),
            "current_sha256": current_files.get(path, "<missing>"),
        }
        for path in sorted(set(old_files) | set(current_files))
        if old_files.get(path) != current_files.get(path)
    ]

    gate_rows: dict[str, Any] = {}
    expectations_match = True
    for gate_id, gate in GATES.items():
        historical = historical_results[gate_id]
        if historical.get("status") != "PASS":
            raise ValueError(f"{gate_id}: historical evidence is not PASS")
        if historical.get("design_id") != old_design_id:
            raise ValueError(f"{gate_id}: historical design cohort mismatch")
        sources, positive, mutation = closure_for_gate(gate, database)
        drift, unbound, missing = compare_closure(
            sources,
            historical["provenance"]["files"],
            {
                **shared_support,
                **historical["provenance"]["source_bindings"],
            },
        )
        classification = (
            "DYNAMIC_RERUN_REQUIRED"
            if drift or unbound or missing
            else "FROZEN_EXECUTION_REPLAY_ELIGIBLE"
        )
        if classification != gate.expected_class:
            expectations_match = False
        gate_rows[gate_id] = {
            "historical_result": gate.result,
            "historical_design_id": historical["design_id"],
            "positive_tests": positive,
            "variant_or_mutation_tests": mutation,
            "resolved_source_count": len(sources),
            "resolved_sources": sources,
            "source_drift": drift,
            "unbound_sources": unbound,
            "missing_sources": missing,
            "classification": classification,
            "expected_classification": gate.expected_class,
            "expectation_match": classification == gate.expected_class,
        }

    output = {
        "schema": "rv64-v14c-p0-active-cone-audit-v1",
        "status": "PASS" if expectations_match else "FAIL",
        "current_design_id": design_id,
        "current_rtl_file_count": len(current_files),
        "historical_design_id": old_design_id,
        "full_rtl_drift": full_rtl_drift,
        "makefile_policy": {
            "whole_file_hash_is_not_a_gate": True,
            "current_tb_source_variables_expanded": True,
            "resolved_sources_compared_to_historical_per_file_bindings": True,
            "same_design_cohort_shared_support": shared_support,
        },
        "shared_current_module_aggregate": {
            "receipt": V14B_RECEIPT.relative_to(ROOT).as_posix(),
            "status": "PASS",
            "required": 113,
            "passed": 113,
        },
        "gates": gate_rows,
        "summary": {
            "gate_count": len(gate_rows),
            "dynamic_rerun_required": sum(
                row["classification"] == "DYNAMIC_RERUN_REQUIRED"
                for row in gate_rows.values()
            ),
            "frozen_execution_replay_eligible": sum(
                row["classification"]
                == "FROZEN_EXECUTION_REPLAY_ELIGIBLE"
                for row in gate_rows.values()
            ),
            "expectations_match": expectations_match,
        },
    }
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(
        json.dumps(output, indent=2, sort_keys=True) + "\n", encoding="utf-8"
    )
    print(
        "[V14C-P0-ACTIVE-CONE] "
        f"status={output['status']} design_id={design_id} "
        f"rtl_drift={len(full_rtl_drift)} rerun="
        f"{output['summary']['dynamic_rerun_required']} replay="
        f"{output['summary']['frozen_execution_replay_eligible']}"
    )
    for gate_id, row in gate_rows.items():
        print(
            f"[V14C-P0-ACTIVE-CONE] gate={gate_id} "
            f"class={row['classification']} drift={len(row['source_drift'])} "
            f"unbound={len(row['unbound_sources'])} missing="
            f"{len(row['missing_sources'])}"
        )
    return 0 if expectations_match else 1


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (OSError, ValueError, json.JSONDecodeError) as exc:
        print(f"[V14C-P0-ACTIVE-CONE][FAIL] {exc}", file=sys.stderr)
        raise SystemExit(1)
