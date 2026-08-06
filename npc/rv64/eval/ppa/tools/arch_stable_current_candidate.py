#!/usr/bin/env python3
"""Build one exact-input RV64 ARCH_STABLE candidate declaration.

This is an inventory builder, not a promotion authority.  It freezes the
current RTL/configuration/test/tool/constraint cohort and emits a candidate
whose claim is GAP unless the caller explicitly requests ARCH_STABLE.  The
independent ``arch_stable_freeze.py`` audit remains authoritative.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import pathlib
import shutil
import subprocess
import sys
from typing import Any, Iterable


COHORT_PRODUCT = "local NpcTop RV64 dual-issue out-of-order processor RTL"
STANDARD_CELL_LIBERTY = (
    "yosys-sta/pdk/icsprout55/IP/STD_cell/"
    "ics55_LLSC_H7C_V1p10C100/ics55_LLSC_H7CL/liberty/"
    "ics55_LLSC_H7CL_typ_tt_1p2_25_nldm.lib"
)
MACRO_LIBERTIES = (
    ("Sram4096x199", "npc/rv64/syn/macro-lib/Sram4096x199.lib"),
    ("Sram4096x113", "npc/rv64/syn/macro-lib/Sram4096x113.lib"),
    ("OooFpArithGate", "npc/rv64/syn/macro-lib/OooFpArithGate.lib"),
    (
        "OooBranchDirectionPredictor",
        "npc/rv64/syn/macro-lib/OooBranchDirectionPredictor.lib",
    ),
)
RUN_PARAMETERS = {
    "top": "NpcTop",
    "clock_port": "clk",
    "period_ns": 5.0,
    "synthesis_seed": 0,
    "threads": 1,
}


class CandidateError(RuntimeError):
    """The current cohort cannot be inventoried exactly."""


def sha256_file(path: pathlib.Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def sha256_bytes(value: bytes) -> str:
    return hashlib.sha256(value).hexdigest()


def canonical_sha256(value: Any) -> str:
    encoded = json.dumps(
        value, allow_nan=False, ensure_ascii=False,
        separators=(",", ":"), sort_keys=True,
    ).encode("utf-8")
    return sha256_bytes(encoded)


def load_json(path: pathlib.Path) -> dict[str, Any]:
    with path.open("r", encoding="utf-8") as handle:
        value = json.load(handle, parse_constant=lambda raw: (_ for _ in ()).throw(
            ValueError(f"non-finite JSON constant: {raw}")))
    if not isinstance(value, dict):
        raise CandidateError(f"JSON root is not an object: {path}")
    return value


def write_json(path: pathlib.Path, value: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = path.with_name(path.name + ".tmp")
    try:
        temporary.write_text(
            json.dumps(
                value, allow_nan=False, ensure_ascii=False,
                indent=2, sort_keys=True,
            ) + "\n",
            encoding="utf-8",
        )
        load_json(temporary)
        os.replace(temporary, path)
    finally:
        temporary.unlink(missing_ok=True)


def find_repo_root(start: pathlib.Path) -> pathlib.Path:
    for candidate in (start.resolve(), *start.resolve().parents):
        if (candidate / "npc/rv64/vsrc").is_dir() and (
            candidate / ".github/AGENTS.md").is_file():
            return candidate
    raise CandidateError("repository root was not found")


def repo_file(root: pathlib.Path, raw: pathlib.Path | str) -> pathlib.Path:
    path = pathlib.Path(raw)
    candidate = path if path.is_absolute() else root / path
    resolved = candidate.resolve(strict=True)
    resolved.relative_to(root.resolve())
    if candidate.is_symlink() or not resolved.is_file():
        raise CandidateError(f"not a regular repository file: {raw}")
    return resolved


def relative(root: pathlib.Path, path: pathlib.Path) -> str:
    return path.resolve().relative_to(root.resolve()).as_posix()


def artifact(
    root: pathlib.Path, raw: pathlib.Path | str, kind: str,
) -> dict[str, str]:
    path = repo_file(root, raw)
    return {
        "kind": kind,
        "path": relative(root, path),
        "sha256": sha256_file(path),
    }


def write_text(path: pathlib.Path, value: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = path.with_name(path.name + ".tmp")
    try:
        temporary.write_text(value, encoding="utf-8")
        os.replace(temporary, path)
    finally:
        temporary.unlink(missing_ok=True)


def build_tool_manifest(
    root: pathlib.Path, output_path: pathlib.Path, version_args: dict[str, tuple[str, ...]],
) -> dict[str, Any]:
    tools: dict[str, Any] = {}
    for name, args in sorted(version_args.items()):
        located = shutil.which(name)
        if located is None:
            raise CandidateError(f"required tool is not on PATH: {name}")
        executable = pathlib.Path(located).resolve(strict=True)
        completed = subprocess.run(
            [str(executable), *args], check=False, capture_output=True, timeout=10)
        output = completed.stdout + completed.stderr
        text = output.decode("utf-8", errors="replace").strip()
        if completed.returncode != 0 or not text:
            raise CandidateError(
                f"{name} version command failed rc={completed.returncode}")
        version = next((line.strip() for line in text.splitlines() if line.strip()), "")
        if not version:
            raise CandidateError(f"{name} version output is empty")
        tools[name] = {
            "path": executable.as_posix(),
            "version": version,
            "version_output_sha256": sha256_bytes(output),
            "executable_sha256": sha256_file(executable),
        }
    manifest = {"schema": "npc-rv64-tool-versions-v1", "tools": tools}
    write_json(output_path, manifest)
    return manifest


def workflow_kind(path: str) -> str:
    if path == "scripts/task-run-status.sh":
        return "task_run_status_helper"
    if path == "scripts/tests/test-task-run-status.sh":
        return "task_run_status_test"
    if path.endswith("run-arch-stable-audit.sh"):
        return "audit_runner"
    if "/schemas/arch-stable-candidate-" in path or (
        "/schemas/" in path
    ):
        return "json_schema"
    if path.endswith("producer-holder-semantic-coverage-policy.json"):
        return "holder_semantic_policy"
    if path.endswith("tools/architecture_hard_gates.py") or path.endswith(
        "tools/architecture_provenance_replay.py"
    ):
        return "canonical_architecture_checker"
    if path.endswith("tools/producer_holder_census.py"):
        return "holder_census_checker"
    if path.endswith("tools/producer_holder_instance_graph.py"):
        return "holder_instance_graph_checker"
    if path.endswith("tools/producer_holder_semantic_coverage.py"):
        return "holder_semantic_checker"
    if path.endswith("tools/terminal_collector_lane_contract.py"):
        return "holder_lane_contract_checker"
    if path.endswith("tools/memory_tracker_semantic_evidence.py"):
        return "memory_tracker_semantic_checker"
    if path.endswith("tools/memory_tracker_cursor_semantic_evidence.py"):
        return "memory_tracker_cursor_semantic_checker"
    if "/tests/" in path or path.endswith(".mk"):
        return "audit_test"
    if path.endswith(".py"):
        return "audit_checker"
    return "audit_test"


def test_source_kind(path: str) -> str:
    if path.startswith("npc/rv64/testbench/tests/"):
        return "module_test_source"
    if path.startswith("npc/rv64/testbench/common/"):
        return "test_common"
    return "test_runner"


def collect_functional_artifacts(
    functional: dict[str, Any],
) -> tuple[list[dict[str, str]], list[dict[str, str]]]:
    images: list[dict[str, str]] = []
    for suite_name in ("official", "am"):
        suite = functional.get(suite_name)
        rows = suite.get("images") if isinstance(suite, dict) else None
        if not isinstance(rows, list):
            raise CandidateError(f"{suite_name} image inventory is absent")
        for row in rows:
            image = row.get("image") if isinstance(row, dict) else None
            if not isinstance(image, dict):
                raise CandidateError(f"{suite_name} image record is invalid")
            images.append(dict(image))
    benchmarks = functional.get("benchmarks")
    if not isinstance(benchmarks, dict):
        raise CandidateError("benchmark inventory is absent")
    for name in ("coremark", "dhrystone"):
        row = benchmarks.get(name)
        image = row.get("image") if isinstance(row, dict) else None
        if not isinstance(image, dict):
            raise CandidateError(f"{name} image record is invalid")
        images.append(dict(image))
    difftest = functional.get("difftest")
    reference = difftest.get("reference") if isinstance(difftest, dict) else None
    simulator = functional.get("simulator")
    if not isinstance(simulator, dict) or not isinstance(reference, dict):
        raise CandidateError("simulator/reference artifacts are absent")
    binaries = [dict(simulator), dict(reference)]
    if len(images) != 240 or len({item.get("path") for item in images}) != 240:
        raise CandidateError("functional image inventory is not exact 240 unique paths")
    if {item.get("kind") for item in images} != {"program_image"}:
        raise CandidateError("functional image kind is not program_image")
    if {item.get("kind") for item in binaries} != {
        "simulator_binary", "reference_model_binary",
    }:
        raise CandidateError("functional binary kinds are incomplete")
    return sorted(images, key=lambda item: item["path"]), sorted(
        binaries, key=lambda item: item["path"])


def build_candidate(
    *,
    root: pathlib.Path,
    output_dir: pathlib.Path,
    architecture_evidence_path: pathlib.Path,
    architecture_result_path: pathlib.Path,
    functional_path: pathlib.Path,
    debt_ledger_path: pathlib.Path,
    holder_census_path: pathlib.Path,
    system_recertification_path: pathlib.Path,
    claim: str,
) -> dict[str, Any]:
    root = root.resolve(strict=True)
    output_dir = output_dir.resolve()
    output_dir.relative_to(root)
    output_dir.mkdir(parents=True, exist_ok=True)

    tools_dir = root / "npc/rv64/eval/ppa/tools"
    if str(tools_dir) not in sys.path:
        sys.path.insert(0, str(tools_dir))
    import arch_stable_freeze as freeze  # pylint: disable=import-outside-toplevel
    import architecture_hard_gates as architecture  # pylint: disable=import-outside-toplevel

    architecture_evidence = load_json(architecture_evidence_path)
    architecture_result = load_json(architecture_result_path)
    functional = load_json(functional_path)
    debt = load_json(debt_ledger_path)
    census = load_json(holder_census_path)
    system_recertification = load_json(system_recertification_path)
    design_hex, rtl_files = architecture.rtl_binding(root)
    design_id = f"sha256:{design_hex}"
    identities = {
        "architecture_evidence": architecture_evidence.get("design_id"),
        "architecture_result": architecture_result.get(
            "rtl_source_set", {}).get("design_id"),
        "functional": functional.get("design_id"),
        "debt_ledger": debt.get("design_id"),
        "holder_census": census.get("design_id"),
        "system_recertification": system_recertification.get("design_id"),
    }
    drift = {name: value for name, value in identities.items() if value != design_id}
    if drift:
        raise CandidateError(f"current design identity drift: {drift}")
    if architecture_result.get("overall_status") != "GREEN" or (
        set(architecture_result.get("gates", {})) != freeze.GATE_IDS
    ):
        raise CandidateError("architecture result is not exact 9/9 GREEN")
    if not (
        system_recertification.get("schema_version")
        == freeze.SYSTEM_RECERTIFICATION_SCHEMA
        and system_recertification.get("status") == "PASS"
        and system_recertification.get("default_signoff_conjunction") == [
            "L0_DIRECTED_RTL",
            "L1_FULL_CORE_DIFFTEST",
            "L2_MINI_SYSTEM",
            "L3_LIGHTWEIGHT_LINUX",
        ]
        and system_recertification.get("optional_full_ubuntu", {}).get(
            "status") == "NOT_RUN"
    ):
        raise CandidateError(
            "system recertification is not exact L0+L1+L2+L3 PASS with "
            "optional Ubuntu NOT_RUN")
    cohort_id = functional.get("cohort_id")
    if not isinstance(cohort_id, str) or not cohort_id:
        raise CandidateError("functional cohort_id is absent")
    entries = debt.get("entries")
    if not isinstance(entries, list):
        raise CandidateError("architecture debt entries are absent")
    excluded = sorted(
        entry["id"] for entry in entries
        if isinstance(entry, dict) and entry.get("status") == "EXCLUDED_BY_COHORT"
    )
    unresolved = [
        entry.get("id") for entry in entries
        if isinstance(entry, dict)
        and entry.get("status") not in {"CLOSED", "EXCLUDED_BY_COHORT"}
    ]
    if unresolved or len(excluded) != 4:
        raise CandidateError(
            f"architecture debt status is not 16 CLOSED + 4 excluded: "
            f"unresolved={unresolved} excluded={excluded}")

    makefile = root / "npc/rv64/testbench/Makefile"
    required_tests, inventory_errors = freeze.parse_required_tests(
        makefile.read_text(encoding="utf-8"))
    if inventory_errors:
        raise CandidateError("; ".join(inventory_errors))
    expected = freeze.expected_input_sets(root, required_tests)
    configuration = functional.get("configuration")
    if not isinstance(configuration, dict):
        raise CandidateError("functional execution configuration is absent")
    expected["config"] = set(expected["config"]) | {configuration["path"]}

    tool_manifest_path = output_dir / "tool-versions.json"
    build_tool_manifest(root, tool_manifest_path, freeze.TOOL_VERSION_ARGS)
    macro_manifest_path = output_dir / "macro-inventory.json"
    macro_manifest = {
        "schema": "npc-rv64-macro-inventory-v1",
        "macros": [
            {
                "name": name,
                "liberty_path": liberty,
                "qualification": "placeholder",
            }
            for name, liberty in MACRO_LIBERTIES
        ],
    }
    write_json(macro_manifest_path, macro_manifest)
    constraint_path = output_dir / "primary-clock-5ns.sdc"
    write_text(
        constraint_path,
        "create_clock -name core_clock -period 5 [get_ports clk]\n",
    )

    images, binaries = collect_functional_artifacts(functional)
    freeze_inputs: dict[str, list[dict[str, str]]] = {
        "config": [artifact(root, path, "kconfig") for path in sorted(expected["config"])],
        "generated_headers": [
            artifact(root, path, "generated_header")
            for path in sorted(expected["generated_headers"])
        ],
        "filelists": [
            artifact(
                root, path,
                "rtl_filelist" if path.endswith("vsrc/filelist.mk")
                else "test_inventory",
            )
            for path in sorted(expected["filelists"])
        ],
        "specifications": [
            artifact(
                root, path,
                "architecture_spec" if path.startswith("npc/rv64/design/arch/")
                else "module_spec",
            )
            for path in sorted(expected["specifications"])
        ],
        "test_sources": [
            artifact(root, path, test_source_kind(path))
            for path in sorted(expected["test_sources"])
        ],
        "tool_versions": [
            artifact(root, tool_manifest_path, "tool_version_manifest")
        ],
        "liberty": [
            artifact(root, STANDARD_CELL_LIBERTY, "standard_cell_liberty"),
            *[
                artifact(root, liberty, "macro_liberty")
                for _, liberty in MACRO_LIBERTIES
            ],
        ],
        "macros": [artifact(root, macro_manifest_path, "macro_inventory")],
        "constraints": [artifact(root, constraint_path, "primary_sdc")],
        "images": images,
        "binaries": binaries,
        "workflow": [
            artifact(root, path, workflow_kind(path))
            for path in freeze.WORKFLOW_BINDING_PATHS
        ],
    }
    for group in freeze_inputs:
        freeze_inputs[group] = sorted(
            freeze_inputs[group], key=lambda item: item["path"])

    cohort = {
        "schema": freeze.COHORT_SCHEMA,
        "design_id": design_id,
        "cohort_id": cohort_id,
        "freeze_inputs": freeze_inputs,
        "run_parameters": dict(RUN_PARAMETERS),
    }
    cohort_path = output_dir / "cohort-inventory.json"
    write_json(cohort_path, cohort)
    candidate = {
        "schema": freeze.CANDIDATE_SCHEMA,
        "design_id": design_id,
        "scope": {
            "cohort_id": cohort_id,
            "product": COHORT_PRODUCT,
            "excluded_debt_ids": excluded,
        },
        "artifacts": {
            "debt_ledger": relative(root, debt_ledger_path),
            "architecture_evidence": relative(root, architecture_evidence_path),
            "architecture_result": relative(root, architecture_result_path),
            "holder_census": relative(root, holder_census_path),
            "functional_aggregate": relative(root, functional_path),
            "cohort_inventory": relative(root, cohort_path),
            "system_recertification": relative(
                root, system_recertification_path),
        },
        "freeze_inputs": freeze_inputs,
        "run_parameters": dict(RUN_PARAMETERS),
        "claim": {
            "architecture_freeze": claim,
            "ppa": "UNQUALIFIED",
            "promotion_eligible": False,
            "canonical": None,
            "architecture_feasible_seed": None,
        },
    }
    candidate_path = output_dir / "candidate.json"
    write_json(candidate_path, candidate)
    receipt_core = {
        "schema": "npc-rv64-arch-stable-current-candidate-build-v1",
        "status": "PASS",
        "design_id": design_id,
        "cohort_id": cohort_id,
        "rtl_file_count": len(rtl_files),
        "required_module_tests": len(required_tests),
        "functional_images": len(images),
        "functional_binaries": len(binaries),
        "workflow_artifacts": len(freeze_inputs["workflow"]),
        "excluded_debt_ids": excluded,
        "claim": candidate["claim"],
        "outputs": {
            "candidate": artifact(root, candidate_path, "arch_stable_candidate"),
            "cohort_inventory": artifact(
                root, cohort_path, "arch_stable_cohort_inventory"),
            "tool_versions": artifact(
                root, tool_manifest_path, "tool_version_manifest"),
            "macro_inventory": artifact(
                root, macro_manifest_path, "macro_inventory"),
            "primary_sdc": artifact(root, constraint_path, "primary_sdc"),
        },
        "claim_boundary": {
            "ppa": "UNQUALIFIED",
            "promotion_eligible": False,
            "candidate_builder_is_promotion_authority": False,
        },
    }
    receipt_core["receipt_sha256"] = canonical_sha256(receipt_core)
    write_json(output_dir / "candidate-build-receipt.json", receipt_core)
    return receipt_core


def parse_args(argv: Iterable[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=pathlib.Path, default=pathlib.Path.cwd())
    parser.add_argument("--output-dir", type=pathlib.Path, required=True)
    parser.add_argument("--architecture-evidence", type=pathlib.Path, required=True)
    parser.add_argument("--architecture-result", type=pathlib.Path, required=True)
    parser.add_argument("--functional-aggregate", type=pathlib.Path, required=True)
    parser.add_argument(
        "--debt-ledger", type=pathlib.Path,
        default=pathlib.Path("npc/rv64/design/arch/architecture-debt-ledger.json"))
    parser.add_argument(
        "--holder-census", type=pathlib.Path,
        default=pathlib.Path("npc/rv64/design/arch/producer-holder-census.json"))
    parser.add_argument(
        "--system-recertification", type=pathlib.Path,
        default=pathlib.Path(
            "npc/rv64/eval/ppa/evidence/system-recertification-current.json"))
    parser.add_argument(
        "--claim", choices=("GAP", "ARCH_STABLE"), default="GAP")
    return parser.parse_args(list(argv) if argv is not None else None)


def main(argv: Iterable[str] | None = None) -> int:
    args = parse_args(argv)
    try:
        root = find_repo_root(args.root)
        output_dir = (
            args.output_dir if args.output_dir.is_absolute()
            else root / args.output_dir)
        receipt = build_candidate(
            root=root,
            output_dir=output_dir,
            architecture_evidence_path=repo_file(root, args.architecture_evidence),
            architecture_result_path=repo_file(root, args.architecture_result),
            functional_path=repo_file(root, args.functional_aggregate),
            debt_ledger_path=repo_file(root, args.debt_ledger),
            holder_census_path=repo_file(root, args.holder_census),
            system_recertification_path=repo_file(
                root, args.system_recertification),
            claim=args.claim,
        )
    except (OSError, ValueError, CandidateError, json.JSONDecodeError,
            subprocess.SubprocessError) as exc:
        print(f"[ARCH-STABLE-CANDIDATE][FAIL] {exc}", file=sys.stderr)
        return 1
    print(
        "[ARCH-STABLE-CANDIDATE][PASS] "
        f"design_id={receipt['design_id']} claim={receipt['claim']['architecture_freeze']} "
        f"rtl={receipt['rtl_file_count']} module_tests={receipt['required_module_tests']} "
        f"images={receipt['functional_images']}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
