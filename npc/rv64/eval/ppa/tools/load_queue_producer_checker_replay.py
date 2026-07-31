#!/usr/bin/env python3
"""Build and verify the V11H attempt-4 frozen-input checker replay."""

from __future__ import annotations

import argparse
import hashlib
import json
import pathlib
import sys
from typing import Any


SCHEMA = "rv64-v11h-load-queue-attempt4-checker-replay-v2"
RUN_ID = "2026-07-30-rv64-v11h-load-queue-producer-semantic-coverage"
RUN_ROOT = pathlib.Path(".github/task-runs") / RUN_ID
ATTEMPT_ROOT = RUN_ROOT / "evidence/load-queue-producer-attempt-4"
ORIGINAL_STATUS = RUN_ROOT / "load-queue-producer-attempt-4.status"
EXPECTED_STATUS = (
    "FAIL rc=1 stage=semantic-ledger-unit "
    "evidence_complete=0 cleanup_rc=0"
)
CURRENT_FILES = {
    "semantic_checker":
        pathlib.Path(
            "npc/rv64/eval/ppa/tools/"
            "producer_holder_semantic_coverage.py"
        ),
    "semantic_checker_tests":
        pathlib.Path(
            "npc/rv64/eval/ppa/tests/"
            "test_producer_holder_semantic_coverage.py"
        ),
    "semantic_policy":
        pathlib.Path(
            "npc/rv64/design/arch/"
            "producer-holder-semantic-coverage-policy.json"
        ),
    "load_queue_evidence_checker":
        pathlib.Path(
            "npc/rv64/eval/ppa/tools/"
            "load_queue_producer_semantic_evidence.py"
        ),
    "load_queue_evidence_checker_tests":
        pathlib.Path(
            "npc/rv64/eval/ppa/tests/"
            "test_load_queue_producer_semantic_evidence.py"
        ),
    "checker_replay_builder":
        pathlib.Path(
            "npc/rv64/eval/ppa/tools/"
            "load_queue_producer_checker_replay.py"
        ),
    "checker_replay_builder_tests":
        pathlib.Path(
            "npc/rv64/eval/ppa/tests/"
            "test_load_queue_producer_checker_replay.py"
        ),
    "producer_holder_census":
        pathlib.Path(
            "npc/rv64/design/arch/producer-holder-census.json"
        ),
    "current_instance_graph_result": pathlib.Path(
        ".github/task-runs/2026-07-31-rv64-"
        "axi-xbar-naming-refresh/evidence/"
        "current-holder-instance-graph/"
        "holder-instance-graph.json"
    ),
    "current_instance_graph_receipt": pathlib.Path(
        ".github/task-runs/2026-07-31-rv64-"
        "axi-xbar-naming-refresh/evidence/"
        "current-holder-instance-graph/"
        "yosys-instance-graph-receipt.json"
    ),
    "current_instance_graph_audit": pathlib.Path(
        ".github/task-runs/2026-07-31-rv64-v11t-"
        "clmul-producer-semantic/evidence/"
        "current-instance-graph-audit/"
        "instance-graph-frozen-audit.json"
    ),
    "producer_holder_instance_graph_tool": pathlib.Path(
        "npc/rv64/eval/ppa/tools/producer_holder_instance_graph.py"
    ),
    "producer_holder_instance_graph_tests": pathlib.Path(
        "npc/rv64/eval/ppa/tests/test_producer_holder_instance_graph.py"
    ),
    "producer_holder_census_tool": pathlib.Path(
        "npc/rv64/eval/ppa/tools/producer_holder_census.py"
    ),
    "producer_holder_census_tests": pathlib.Path(
        "npc/rv64/eval/ppa/tests/test_producer_holder_census.py"
    ),
}
SELECTED_BINDINGS = {
    (
        pathlib.Path("npc/rv64/vsrc/memory/OooLoadQueue.v"),
        "rtl",
    ),
    (
        pathlib.Path(
            "npc/rv64/testbench/tests/"
            "tb_ooo_load_queue_producer_semantic.sv"
        ),
        "testbench",
    ),
    (
        pathlib.Path(
            "npc/rv64/testbench/tests/tb_ooo_load_queue.sv"
        ),
        "testbench",
    ),
}
CLAIM_BOUNDARY = (
    "This receipt proves that the frozen V11H positive/mutation inputs were "
    "complete before attempt 4 stopped at semantic-ledger-unit, and binds the "
    "corrected checker, unchanged LoadQueue RTL/testbench subset, exact "
    "system-rerun scope, and current instance graph. It does not rewrite the "
    "original FAIL, claim that the historical full-RTL snapshot is current, "
    "rerun RTL simulation, promote whole-architecture GREEN, satisfy the "
    "required full-system rerun, or authorize PPA."
)


class ReplayError(RuntimeError):
    """Raised when frozen V11H checker-replay inputs are incomplete."""


def repo_path(root: pathlib.Path, relative: pathlib.Path) -> pathlib.Path:
    path = (root / relative).resolve()
    try:
        path.relative_to(root.resolve())
    except ValueError as exc:
        raise ReplayError(f"path escapes repository root: {relative}") from exc
    return path


def sha256_file(path: pathlib.Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def artifact(root: pathlib.Path, relative: pathlib.Path) -> dict[str, Any]:
    path = repo_path(root, relative)
    if not path.is_file() or path.is_symlink():
        raise ReplayError(f"replay artifact is missing or unsafe: {relative}")
    return {
        "path": relative.as_posix(),
        "sha256": sha256_file(path),
        "size_bytes": path.stat().st_size,
    }


def load_json(path: pathlib.Path) -> dict[str, Any]:
    try:
        payload = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        raise ReplayError(f"cannot read JSON {path}: {exc}") from exc
    if not isinstance(payload, dict):
        raise ReplayError(f"JSON root is not an object: {path}")
    return payload


def parse_sha_manifest(path: pathlib.Path) -> dict[str, str]:
    records: dict[str, str] = {}
    for line_number, line in enumerate(
        path.read_text(encoding="utf-8").splitlines(), start=1
    ):
        try:
            digest, relative = line.split("  ", 1)
        except ValueError as exc:
            raise ReplayError(
                f"malformed SHA-256 manifest line {line_number}: {path}"
            ) from exc
        if (
            len(digest) != 64
            or any(char not in "0123456789abcdef" for char in digest)
            or not relative
            or relative in records
        ):
            raise ReplayError(
                f"invalid SHA-256 manifest record {line_number}: {path}"
            )
        records[relative] = digest
    if not records:
        raise ReplayError(f"SHA-256 manifest is empty: {path}")
    return records


def current_selected_binding(
    root: pathlib.Path,
    manifest_path: pathlib.Path,
    evidence_design_id: str,
    live_design_id: str,
) -> dict[str, Any]:
    manifest = parse_sha_manifest(repo_path(root, manifest_path))
    records: list[dict[str, Any]] = []
    for relative, role in sorted(
        SELECTED_BINDINGS, key=lambda item: item[0].as_posix()
    ):
        relative_value = relative.as_posix()
        evidence_sha = manifest.get(relative_value)
        if evidence_sha is None:
            raise ReplayError(
                "frozen focused manifest lacks selected LoadQueue binding: "
                f"{relative_value}"
            )
        live_path = repo_path(root, relative)
        live_sha = sha256_file(live_path)
        if live_sha != evidence_sha:
            raise ReplayError(
                "selected LoadQueue RTL/testbench binding is stale: "
                f"{relative_value}"
            )
        records.append(
            {
                "path": relative_value,
                "role": role,
                "evidence_sha256": evidence_sha,
                "live_sha256": live_sha,
                "matches_live": True,
            }
        )
    return {
        "binding_state": (
            "CURRENT_FULL_RTL_BOUND"
            if evidence_design_id == live_design_id
            else "CURRENT_SELECTED_SOURCE_AND_TB_BOUND"
        ),
        "evidence_design_id": evidence_design_id,
        "current_design_id": live_design_id,
        "records": records,
    }


def current_design_id(root: pathlib.Path) -> str:
    tools_dir = root / "npc/rv64/eval/ppa/tools"
    sys.path.insert(0, str(tools_dir))
    try:
        import architecture_hard_gates as architecture
    finally:
        sys.path.pop(0)
    digest, _ = architecture.rtl_binding(root)
    return f"sha256:{digest}"


def valid_design_id(value: Any) -> bool:
    return (
        isinstance(value, str)
        and value.startswith("sha256:")
        and len(value) == 71
        and all(char in "0123456789abcdef" for char in value[7:])
    )


def validate_original_status_line(value: str) -> None:
    if value.strip() != EXPECTED_STATUS:
        raise ReplayError(
            "original attempt-3 status is not the frozen "
            "semantic-ledger-unit FAIL"
        )


def build_receipt(root: pathlib.Path) -> dict[str, Any]:
    root = root.resolve()
    status_path = repo_path(root, ORIGINAL_STATUS)
    validate_original_status_line(
        status_path.read_text(encoding="utf-8")
    )

    summary_relative = ATTEMPT_ROOT / "summary.json"
    summary = load_json(repo_path(root, summary_relative))
    positives = summary.get("positive_profiles")
    assertion_probe = summary.get("rtl_assertion_probe")
    mutations = summary.get("mutations")
    counts = summary.get("counts")
    scope = summary.get("scope")
    mutation_simulations = 0
    if isinstance(mutations, list):
        for item in mutations:
            if isinstance(item, dict) and isinstance(item.get("runs"), dict):
                mutation_simulations += len(item["runs"])
    attempt_design_id = summary.get("design_id")
    live_design_id = current_design_id(root)
    if (
        summary.get("schema")
        != "rv64-v11h-load-queue-producer-semantic-evidence-v2"
        or summary.get("status") != "PASS"
        or not valid_design_id(attempt_design_id)
        or not isinstance(positives, dict)
        or len(positives) != 4
        or not isinstance(assertion_probe, dict)
        or assertion_probe.get("assertions_enabled") is not True
        or assertion_probe.get("unknown_generation_injected") is not True
        or assertion_probe.get("compile_rc") != 0
        or not isinstance(assertion_probe.get("simulation_rc"), int)
        or assertion_probe["simulation_rc"] == 0
        or assertion_probe.get("expected_marker")
        != "[V11H-LQ-PID-KNOWN]"
        or not isinstance(mutations, list)
        or len(mutations) != 31
        or mutation_simulations != 62
        or not isinstance(counts, dict)
        or counts.get("positive_profiles") != 4
        or counts.get("raw_q_knownness_assertion_probes") != 1
        or counts.get("compile_success_mutation_cases") != 31
        or counts.get("mutation_simulations") != 62
        or counts.get("rejected_mutation_simulations") != 62
        or scope
        != {
            "semantic_unit": "load-queue-producers",
            "global_no_live_reuse": "NOT_PROVEN",
            "whole_architecture": "RED",
            "ppa": "UNPROMOTED",
            "system_rerun": {
                "required_for_local_closure": False,
                "required_before_system_promotion": True,
                "run": False,
            },
        }
    ):
        raise ReplayError(
            "attempt-4 frozen RTL summary is incomplete or not current-design"
        )

    sources_pre = ATTEMPT_ROOT / "sources.pre.sha256"
    sources_post = ATTEMPT_ROOT / "sources.post.sha256"
    rtl_pre = ATTEMPT_ROOT / "rtl-source-binding.pre.json"
    rtl_post = ATTEMPT_ROOT / "rtl-source-binding.post.json"
    if (
        repo_path(root, sources_pre).read_bytes()
        != repo_path(root, sources_post).read_bytes()
    ):
        raise ReplayError("attempt-3 focused source pre/post bindings differ")
    if (
        repo_path(root, rtl_pre).read_bytes()
        != repo_path(root, rtl_post).read_bytes()
    ):
        raise ReplayError("attempt-3 full RTL pre/post bindings differ")
    rtl_snapshot = load_json(repo_path(root, rtl_pre))
    if (
        rtl_snapshot.get("design_id") != attempt_design_id
        or len(rtl_snapshot.get("rtl_files", {})) != 146
    ):
        raise ReplayError("attempt-4 full RTL snapshot is incomplete")
    selected_binding = current_selected_binding(
        root,
        sources_pre,
        attempt_design_id,
        live_design_id,
    )

    evidence_unit_relative = ATTEMPT_ROOT / "evidence-tool-unit.log"
    evidence_unit = repo_path(root, evidence_unit_relative).read_text(
        encoding="utf-8"
    )
    if "Ran 10 tests" not in evidence_unit or "\nOK\n" not in evidence_unit:
        raise ReplayError(
            "attempt-4 evidence-checker unit log is not 10/10 PASS"
        )
    original_semantic_relative = ATTEMPT_ROOT / "semantic-ledger-unit.log"
    original_semantic = repo_path(
        root, original_semantic_relative
    ).read_text(encoding="utf-8")
    if (
        "NameError: name 'assertion_probe' is not defined"
        not in original_semantic
        or "FAILED (errors=4)" not in original_semantic
    ):
        raise ReplayError(
            "attempt-4 semantic failure no longer matches the frozen "
            "checker-local variable defect"
        )
    if repo_path(root, ATTEMPT_ROOT / "runner-summary.log").exists():
        raise ReplayError("attempt-4 unexpectedly contains a PASS summary")

    return {
        "schema": SCHEMA,
        "status": "PASS",
        "design_id": attempt_design_id,
        "current_design_id_at_replay": live_design_id,
        "original_design_is_current": attempt_design_id == live_design_id,
        "current_selected_binding": selected_binding,
        "original_attempt": 4,
        "original_failure": {
            "stage": "semantic-ledger-unit",
            "status_line": EXPECTED_STATUS,
            "status_artifact": artifact(root, ORIGINAL_STATUS),
            "semantic_log": artifact(
                root, original_semantic_relative
            ),
        },
        "frozen_simulation_evidence": {
            "summary": artifact(root, summary_relative),
            "focused_sources_pre": artifact(root, sources_pre),
            "focused_sources_post": artifact(root, sources_post),
            "full_rtl_pre": artifact(root, rtl_pre),
            "full_rtl_post": artifact(root, rtl_post),
            "evidence_checker_unit_log": artifact(
                root, evidence_unit_relative
            ),
            "positive_profiles": 4,
            "raw_q_knownness_assertion_probes": 1,
            "mutation_cases": 31,
            "mutation_simulations": 62,
        },
        "replacement_checker_sources": {
            name: artifact(root, path)
            for name, path in sorted(CURRENT_FILES.items())
        },
        "replay_contract": {
            "original_fail_preserved": True,
            "rtl_simulation_reexecuted": False,
            "full_rtl_pre_post_identical": True,
            "focused_sources_pre_post_identical": True,
            "historical_full_rtl_snapshot_is_current":
                attempt_design_id == live_design_id,
            "current_selected_source_and_tb_bound": True,
            "system_rerun_required_before_system_promotion": True,
            "system_rerun_executed": False,
            "replacement_checker_must_run_positive_and_negative_units": True,
        },
        "claim_boundary": CLAIM_BOUNDARY,
    }


def verify_payload(root: pathlib.Path, payload: dict[str, Any]) -> None:
    expected = build_receipt(root)
    if payload != expected:
        raise ReplayError(
            "checker-replay receipt differs from frozen inputs or current "
            "checker sources"
        )


def write_json(path: pathlib.Path, payload: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(
        json.dumps(payload, ensure_ascii=False, indent=2, sort_keys=True)
        + "\n",
        encoding="utf-8",
    )


def main() -> int:
    default_root = pathlib.Path(__file__).resolve().parents[5]
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", type=pathlib.Path, default=default_root)
    commands = parser.add_subparsers(dest="command", required=True)
    build = commands.add_parser("build")
    build.add_argument("--output", type=pathlib.Path, required=True)
    verify = commands.add_parser("verify")
    verify.add_argument("--input", type=pathlib.Path, required=True)
    args = parser.parse_args()

    root = args.root.resolve()
    try:
        if args.command == "build":
            output = args.output.resolve()
            try:
                output.relative_to(root)
            except ValueError as exc:
                raise ReplayError("output escapes repository root") from exc
            receipt = build_receipt(root)
            write_json(output, receipt)
        else:
            verify_payload(root, load_json(args.input.resolve()))
    except (OSError, ReplayError) as exc:
        print(
            f"[V11H-LQ-CHECKER-REPLAY][FAIL] {exc}",
            file=sys.stderr,
        )
        return 1
    print(
        "[V11H-LQ-CHECKER-REPLAY][PASS] "
        "original_attempt=4 profiles=4 assertion_probe=1 mutations=31x2"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
