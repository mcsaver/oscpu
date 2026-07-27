#!/usr/bin/env python3
from __future__ import annotations

import copy
import importlib.util
import json
import pathlib
import sys
from typing import Any, Callable

sys.dont_write_bytecode = True
ROOT = pathlib.Path(__file__).resolve().parents[4]
RUN_REL = ".github/task-runs/2026-07-23-rv64-v9o-control-event-current-design"
OUT_REL = f"{RUN_REL}/validator-review-v2"
OUT = ROOT / OUT_REL
TOOL = ROOT / "npc/rv64/eval/ppa/tools/arch_stable_freeze.py"
SPEC = importlib.util.spec_from_file_location("validator_review_v2_freeze", TOOL)
assert SPEC is not None and SPEC.loader is not None
freeze = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = freeze
SPEC.loader.exec_module(freeze)

INDEX_REL = freeze.CONTROL_EVENT_INDEX_PATH
MUTATION_REL = freeze.CONTROL_EVENT_MUTATION_PATH
INDEX = freeze.load_json(ROOT / INDEX_REL)
MUTATIONS = freeze.load_json(ROOT / MUTATION_REL)


def file_record(relative: str) -> dict[str, Any]:
    path = ROOT / relative
    return {
        "path": relative,
        "sha256": freeze.sha256_file(path),
        "size_bytes": path.stat().st_size,
    }


def collect_artifacts(value: Any, paths: set[str]) -> None:
    if isinstance(value, dict):
        if set(value) == {"path", "sha256", "size_bytes"}:
            path = value.get("path")
            if isinstance(path, str):
                paths.add(path)
        for child in value.values():
            collect_artifacts(child, paths)
    elif isinstance(value, list):
        for child in value:
            collect_artifacts(child, paths)


def full_variant(
    name: str,
    mutate: Callable[[dict[str, Any], dict[str, Any]], None],
) -> list[str]:
    index = copy.deepcopy(INDEX)
    mutations = copy.deepcopy(MUTATIONS)
    mutate(index, mutations)
    fixture_dir = OUT / "fixtures"
    fixture_dir.mkdir(parents=True, exist_ok=True)
    mutation_rel = f"{OUT_REL}/fixtures/{name}-mutations.json"
    mutation_path = ROOT / mutation_rel
    mutation_path.write_text(
        json.dumps(mutations, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )
    index["rtl_mutations"]["summary"] = file_record(mutation_rel)
    index_rel = f"{OUT_REL}/fixtures/{name}-index.json"
    canonical = dict(index)
    canonical.pop("provenance_sha256", None)
    index["provenance_sha256"] = freeze.canonical_sha256(canonical)
    index_path = ROOT / index_rel
    index_path.write_text(
        json.dumps(index, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )
    old_index = freeze.CONTROL_EVENT_INDEX_PATH
    old_mutation = freeze.CONTROL_EVENT_MUTATION_PATH
    freeze.CONTROL_EVENT_INDEX_PATH = index_rel
    freeze.CONTROL_EVENT_MUTATION_PATH = mutation_rel
    try:
        entry = {
            "canonical_command": freeze.CONTROL_EVENT_COMMAND,
            "design_id": index["design_id"],
            "evidence": [
                {
                    "kind": "control_event_evidence_index",
                    "path": index_rel,
                    "sha256": freeze.sha256_file(index_path),
                },
                {
                    "kind": "control_event_rtl_mutations",
                    "path": mutation_rel,
                    "sha256": freeze.sha256_file(mutation_path),
                },
            ],
        }
        return freeze.validate_control_event_debt(
            ROOT, entry, "sha256:" + "0" * 64)
    finally:
        freeze.CONTROL_EVENT_INDEX_PATH = old_index
        freeze.CONTROL_EVENT_MUTATION_PATH = old_mutation


source_helper = freeze.load_workspace_module(
    ROOT, freeze.CONTROL_EVENT_SOURCE_HELPER, "review_v2_sources")
rtl_sha, rtl_files = source_helper.rtl_binding(ROOT)
verification_sha, verification_files = source_helper.verification_binding(ROOT)
live_inventory, inventory_errors = freeze.parse_required_tests(
    (ROOT / "npc/rv64/testbench/Makefile").read_text(encoding="utf-8")
)
mutation_rows = {row["name"]: row for row in MUTATIONS["results"]}
mutation_mapping_ok = set(mutation_rows) == freeze.CONTROL_EVENT_MUTATIONS
if mutation_mapping_ok:
    for name, contract in freeze.CONTROL_EVENT_MUTATION_CONTRACTS.items():
        row = mutation_rows[name]
        expected = {
            "source": contract["source"],
            "test_name": contract["test_name"],
            "make_variable": contract["make_variable"],
            "rejection_mode": contract["rejection_mode"],
            "make_returncode": contract["make_returncode"],
            "lint_returncode": contract["lint_returncode"],
            "expected_markers": list(contract["expected_markers"]),
        }
        mutation_mapping_ok = mutation_mapping_ok and all(
            row.get(key) == value for key, value in expected.items()
        )

artifact_paths: set[str] = set()
collect_artifacts(INDEX, artifact_paths)
candidate = freeze.load_json(
    ROOT / "npc/rv64/eval/ppa/arch-stable/full-core-current.json"
)
evaluated = freeze.evaluate_candidate(
    root=ROOT,
    candidate_path=ROOT / "npc/rv64/eval/ppa/arch-stable/full-core-current.json",
    generated_at_utc="2026-07-23T00:00:00+00:00",
)
checks = {row["check_id"]: row["status"] for row in evaluated["checks"]}


def add_index_downstream(index: dict[str, Any], _: dict[str, Any]) -> None:
    relative = f"{RUN_REL}/gates/arch-stable-audit.json"
    index["architecture_hard_gates"]["downstream_probe"] = file_record(relative)


def add_mutation_downstream(_: dict[str, Any], mutations: dict[str, Any]) -> None:
    relative = f"{RUN_REL}/gates/arch-stable-audit.json"
    mutations["downstream_probe"] = file_record(relative)


def remap_mutation(_: dict[str, Any], mutations: dict[str, Any]) -> None:
    mutations["results"][0]["source"] = "npc/rv64/vsrc/core/OooCoreTopGlue.v"


index_downstream_errors = full_variant("index-downstream", add_index_downstream)
mutation_downstream_errors = full_variant(
    "mutation-downstream", add_mutation_downstream)
remap_errors = full_variant("mutation-remap", remap_mutation)
result = {
    "schema": "npc-rv64-control-event-validator-review-v2-probes-v1",
    "current": {
        "design_id": INDEX["design_id"],
        "rtl_recomputed": f"sha256:{rtl_sha}",
        "rtl_file_count": len(rtl_files),
        "verification_recomputed": f"sha256:{verification_sha}",
        "verification_file_count": len(verification_files),
        "provenance_exact": set(INDEX["provenance"]) == freeze.CONTROL_EVENT_PROVENANCE_PATHS,
        "indexed_artifact_count": len(artifact_paths),
        "forbidden_indexed_artifacts": sorted(
            artifact_paths & freeze.CONTROL_EVENT_FORBIDDEN_ARTIFACT_PATHS),
        "make_inventory_count": len(live_inventory),
        "make_inventory_errors": inventory_errors,
        "make_inventory_exact": live_inventory == INDEX["module_aggregate"]["inventory"],
        "mutation_mapping_exact": mutation_mapping_ok,
        "candidate_design_id": candidate.get("design_id"),
        "candidate_schema": candidate.get("schema"),
        "boundary_candidate_match": INDEX["full_core_boundary"]["candidate_design_id"] == candidate.get("design_id"),
        "candidate_differs_from_local_design": candidate.get("design_id") != INDEX["design_id"],
        "evaluated_architecture_freeze": evaluated["architecture_freeze"],
        "evaluated_ppa": evaluated["ppa"],
        "evaluated_promotion_eligible": evaluated["promotion_eligible"],
        "control_event_semantic_evidence": checks.get("debt.CONTROL-EVENT-G1.semantic_evidence"),
        "control_event_closed_binding": checks.get("debt.CONTROL-EVENT-G1.closed_binding"),
    },
    "negative_probes": {
        "index_embeds_downstream_artifact": {
            "accepted": not index_downstream_errors,
            "errors": index_downstream_errors,
        },
        "mutation_summary_embeds_downstream_artifact": {
            "accepted": not mutation_downstream_errors,
            "errors": mutation_downstream_errors,
        },
        "mutation_source_remap": {
            "accepted": not remap_errors,
            "errors": remap_errors,
        },
    },
}
(OUT / "replay-probes.json").write_text(
    json.dumps(result, indent=2, sort_keys=True) + "\n",
    encoding="utf-8",
)
print(json.dumps(result, indent=2, sort_keys=True))
