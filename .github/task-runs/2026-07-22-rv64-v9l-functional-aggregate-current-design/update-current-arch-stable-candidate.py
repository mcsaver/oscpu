#!/usr/bin/env python3
"""Rebind the honest-GAP architecture candidate to current RV64 evidence."""

from __future__ import annotations

import hashlib
import importlib.util
import json
import pathlib
import sys
from typing import Any


ROOT = pathlib.Path(__file__).resolve().parents[3]
CANDIDATE = ROOT / "npc/rv64/eval/ppa/arch-stable/full-core-current.json"
CENSUS = ROOT / "npc/rv64/design/arch/producer-holder-census.json"
ARCH_EVIDENCE = ROOT / "npc/rv64/eval/ppa/evidence/architecture-current.json"
ARCH_RESULT = ROOT / (
    ".github/task-runs/2026-07-21-rv64-v9a-width-continuity/"
    "evidence/final-run/static/architecture-result.json")
FUNCTIONAL = ROOT / "npc/rv64/eval/ppa/evidence/functional-aggregate-current.json"
FUNCTIONAL_RESULT = ROOT / "npc/rv64/eval/ppa/evidence/functional-aggregate-result.json"
V8L_EVIDENCE = ROOT / (
    ".github/task-runs/2026-07-20-rv64-v8l-global-producer-no-live-reuse/"
    "evidence/focused")
V8L_LIFECYCLE = V8L_EVIDENCE / "holder-lifecycle.log"
V8L_MUTATIONS = V8L_EVIDENCE / "mutation-summary.json"


def load_module(name: str, path: pathlib.Path) -> Any:
    spec = importlib.util.spec_from_file_location(name, path)
    assert spec is not None and spec.loader is not None
    module = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    return module


gate = load_module(
    "v9l_candidate_architecture_gate",
    ROOT / "npc/rv64/eval/ppa/tools/architecture_hard_gates.py",
)
census_checker = load_module(
    "v9l_candidate_census_checker",
    ROOT / "npc/rv64/eval/ppa/tools/producer_holder_census.py",
)


def sha256(path: pathlib.Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def relative(path: pathlib.Path) -> str:
    return path.resolve(strict=True).relative_to(ROOT.resolve()).as_posix()


def artifact(kind: str, path: pathlib.Path) -> dict[str, str]:
    resolved = path.resolve(strict=True)
    resolved.relative_to(ROOT.resolve())
    if resolved.is_symlink() or not resolved.is_file():
        raise RuntimeError(f"evidence is not a regular file: {resolved}")
    return {"kind": kind, "path": relative(resolved), "sha256": sha256(resolved)}


def load_json(path: pathlib.Path) -> dict[str, Any]:
    value = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(value, dict):
        raise RuntimeError(f"expected JSON object: {relative(path)}")
    return value


def write_json(path: pathlib.Path, value: dict[str, Any]) -> None:
    path.write_text(
        json.dumps(value, ensure_ascii=False, allow_nan=False, indent=2) + "\n",
        encoding="utf-8",
    )


def verify_architecture(design_id: str) -> None:
    evidence = load_json(ARCH_EVIDENCE)
    expected_tests = {
        "frontend_ii1", "width_continuity", "pair_matrix",
        "no_static_lane_semantics", "dual_memory_issue",
        "true_ooo_long_latency", "selective_scheduling",
        "memory_ordering", "speculation_recovery",
    }
    tests = evidence.get("tests")
    if not (
        evidence.get("schema") == "npc-rv64-architecture-directed-suite-v2"
        and evidence.get("design_id") == design_id
        and isinstance(tests, dict)
        and set(tests) == expected_tests
        and all(isinstance(item, dict) and item.get("status") == "PASS"
                for item in tests.values())
    ):
        raise RuntimeError("nine-gate architecture evidence is not current-design PASS")

    result = load_json(ARCH_RESULT)
    source_set = result.get("rtl_source_set")
    gates = result.get("gates")
    if not (
        result.get("schema") == "npc-rv64-architecture-hard-gates-result-v2"
        and result.get("overall_status") == "GREEN"
        and result.get("exit_code") == 0
        and isinstance(source_set, dict)
        and source_set.get("design_id") == design_id
        and isinstance(gates, dict)
        and len(gates) == 9
        and all(isinstance(item, dict) and item.get("status") == "GREEN"
                for item in gates.values())
    ):
        raise RuntimeError("architecture hard-gate result is not current-design 9/9 GREEN")


def verify_functional(design_id: str) -> None:
    aggregate = load_json(FUNCTIONAL)
    result = load_json(FUNCTIONAL_RESULT)
    if not (
        aggregate.get("schema") == "npc-rv64-functional-aggregate-v2"
        and aggregate.get("design_id") == design_id
        and result.get("schema") == "npc-rv64-functional-aggregate-result-v1"
        and result.get("design_id") == design_id
        and result.get("status") == "PASS"
        and result.get("exit_code") == 0
    ):
        raise RuntimeError("functional aggregate is not current-design PASS")


def bind_census(design_id: str) -> None:
    lifecycle_text = V8L_LIFECYCLE.read_text(encoding="utf-8")
    required = {
        "V8L-INTIQ-DEATH-EDGE",
        "V8L-FINITE-GENERATION-WRAP",
        "V8L-TRANSIENT-HOLDER-CENSUS",
        "V8L-MEM-HANDOFF-BACKPRESSURE",
        "V8L-MEM-INDIRECT-TRACKER",
    }
    if f"design_id={design_id}" not in lifecycle_text:
        raise RuntimeError("V8L lifecycle log is not current-design bound")
    missing = sorted(marker for marker in required if marker not in lifecycle_text)
    if missing:
        raise RuntimeError(f"V8L lifecycle log is missing markers: {missing}")
    mutations = load_json(V8L_MUTATIONS)
    if not (
        mutations.get("schema") == "npc-rv64-holder-lifecycle-mutations-v1"
        and mutations.get("design_id") == design_id
        and mutations.get("compile_success") == 9
        and mutations.get("rejected") == 9
    ):
        raise RuntimeError("V8L mutation summary is not current-design 9/9")

    census = load_json(CENSUS)
    scope = census.get("scope")
    ledger = census.get("status_ledger")
    if not (
        census.get("schema_version") == "rv64-producer-holder-census-v1"
        and isinstance(scope, dict)
        and scope.get("field_level_complete") is True
        and scope.get("instance_graph_complete") is True
        and scope.get("semantic_complete") is False
        and isinstance(ledger, dict)
        and ledger.get("current_production_holder_census")
        == "ELABORATED_INSTANCE_COMPLETE"
        and ledger.get("global_no_live_reuse") == "SEMANTIC_COVERAGE_REQUIRED"
        and ledger.get("whole_architecture") == "RED"
        and ledger.get("ppa_promotion") == "UNPROMOTED"
    ):
        raise RuntimeError(
            "bounded field/instance census scope changed or overclaims "
            "semantic closure"
        )
    census["design_id"] = design_id
    census["freeze_evidence"] = {
        "canonical_command":
            "make -C npc/rv64 check-global-producer-no-live-reuse",
        "dynamic_log": artifact("holder_lifecycle_log", V8L_LIFECYCLE),
        "mutation_summary": artifact("mutation_summary", V8L_MUTATIONS),
    }
    write_json(CENSUS, census)
    static_result = census_checker.audit(
        ROOT, CENSUS, ROOT / "npc/rv64/vsrc")
    if static_result.get("status") != "PASS":
        raise RuntimeError(
            "canonical producer-holder static audit failed after evidence binding: "
            + "; ".join(static_result.get("errors", [])[:4]))


def bind_candidate(design_id: str) -> None:
    candidate = load_json(CANDIDATE)
    claim = candidate.get("claim")
    if not (
        candidate.get("schema") == "npc-rv64-arch-stable-candidate-v1"
        and isinstance(claim, dict)
        and claim.get("architecture_freeze") == "GAP"
        and claim.get("ppa") == "UNQUALIFIED"
        and claim.get("promotion_eligible") is False
        and claim.get("canonical") is None
        and claim.get("architecture_feasible_seed") is None
    ):
        raise RuntimeError("candidate must remain honest GAP / PPA UNQUALIFIED")
    if any(candidate.get("freeze_inputs", {}).values()):
        raise RuntimeError("candidate freeze inputs must remain empty until explicitly closed")
    candidate["design_id"] = design_id
    artifacts = candidate.get("artifacts")
    if not isinstance(artifacts, dict):
        raise RuntimeError("candidate artifact map is missing")
    artifacts.update({
        "debt_ledger": "npc/rv64/design/arch/architecture-debt-ledger.json",
        "architecture_evidence": relative(ARCH_EVIDENCE),
        "architecture_result": relative(ARCH_RESULT),
        "holder_census": relative(CENSUS),
        "functional_aggregate": relative(FUNCTIONAL),
        "cohort_inventory": None,
    })
    write_json(CANDIDATE, candidate)


def main() -> int:
    rtl_sha, rtl_files = gate.rtl_binding(ROOT)
    if not rtl_files:
        raise RuntimeError("canonical RTL source set is empty")
    design_id = f"sha256:{rtl_sha}"
    verify_architecture(design_id)
    verify_functional(design_id)
    bind_census(design_id)
    bind_candidate(design_id)
    print(
        "[V9L-ARCH-CANDIDATE][PASS] "
        f"design_id={design_id} directed_gates=9/9 holder_mutations=9/9 "
        "architecture_freeze=GAP ppa=UNQUALIFIED"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
