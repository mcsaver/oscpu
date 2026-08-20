#!/usr/bin/env python3
"""Build and verify a fail-closed architecture-debt RTL delta receipt.

Historical V14C/V14D/V14E executions remain immutable and retain their old
design identity.  An old negative observation is reusable only when its
production RTL source has the same exact hash in the current RTL
manifest.  Every observation in a changed RTL source requires a
compile-success rejected variant whose source hash is exact-current.  The
current L0 result and its manifest are discovered through the canonical
L0/L1/L2/L3 receipt instead of a versioned task-run name.  Changed RTL files
which are outside every historical negative cone remain explicit and are
covered by the current positive conjunction; they are not silently added to
the historical mutation inventory.
"""

from __future__ import annotations

import argparse
import functools
import hashlib
import importlib.util
import json
import pathlib
import re
import sys
from typing import Any, Iterable, Sequence


SCHEMA = "npc-rv64-architecture-debt-delta-rebind-v2"
BASELINE_DESIGN_ID = (
    "sha256:093c2380b997029944aa4462015d83711d7c5f1d52b15b4803c4515a581a7488"
)
P0_DEBTS = {
    "FDG-G1", "XRET-G1", "MEM-ISSUE-G1", "IFU-AXI-G1",
    "IFU-FETCH-G2", "IFU-ACCESS-G1", "IFU-TVAL-G1", "PTW-PMP-G1",
    "INSTRET-G1",
}

RECEIPT_PATH = pathlib.PurePosixPath(
    "npc/rv64/eval/ppa/evidence/architecture-debt-delta-rebind-current.json"
)
BASELINE_MANIFEST = pathlib.PurePosixPath(
    ".github/task-runs/2026-08-02-rv64-v14d-p1-direct-current-rebind-v1/"
    "evidence/p1-direct-1/source-before.json"
)
V14C_INVENTORY = pathlib.PurePosixPath(
    ".github/task-runs/2026-08-02-rv64-v14c-p0-transitive-current-rebind-v1/"
    "evidence/counterexample-inventory-1/inventory.json"
)
V14D_RECEIPT = pathlib.PurePosixPath(
    ".github/task-runs/2026-08-02-rv64-v14d-p1-direct-current-rebind-v1/"
    "evidence/p1-direct-1/receipt.json"
)
V14E_ROOT = pathlib.PurePosixPath(
    ".github/task-runs/2026-08-02-rv64-v14e-p1-remaining-current-rebind-v1/"
    "evidence"
)
F0_SUMMARY = V14E_ROOT / "f0-run-6/summary.json"
F0_MUTATIONS = V14E_ROOT / "f0-run-2/rtl-counterexamples/summary.json"
FENCE_SUMMARY = V14E_ROOT / "fence-run-1/summary.json"
FENCE_MUTATIONS = V14E_ROOT / "fence-run-1/mutations/summary.json"
SERIALIZE_SUMMARY = V14E_ROOT / "serialize-fast-run-1/summary.json"
SERIALIZE_QH = V14E_ROOT / "serialize-fast-run-1/qh/summary.json"
SERIALIZE_SYSTEM = V14E_ROOT / "serialize-fast-run-1/system/summary.json"
VECTORED_SUMMARY = V14E_ROOT / "vectored-run-1/summary.json"
VECTORED_MUTATIONS = V14E_ROOT / "vectored-run-1/mutations/summary.json"

CURRENT_RUN_ROOT = pathlib.PurePosixPath(
    ".github/task-runs/2026-08-07-rv64-v15w-ca37-current-reconciliation-a1/"
    "evidence"
)
CURRENT_V9F = CURRENT_RUN_ROOT / "memory-lifecycle-mutations-ca37-v1/summary.json"
CURRENT_SUPPLEMENTAL = pathlib.PurePosixPath(
    ".github/task-runs/2026-08-08-rv64-v15x-f72e-state-reconciliation-a1/"
    "evidence/architecture-delta-mutations-f72e-v1/summary.json"
)
CURRENT_D3F3_FENCE = pathlib.PurePosixPath(
    ".github/task-runs/2026-08-09-rv64-bpu-inline-ppa-d3f3-a1/"
    "evidence/architecture-delta-mutations-d3f3-fence-v2/summary.json"
)
LAYERED_SIGNOFF = pathlib.PurePosixPath(
    "npc/rv64/eval/ppa/evidence/layered-system-signoff-current.json"
)
SELECTED_BINDING_RECEIPT = pathlib.PurePosixPath(
    "npc/rv64/eval/ppa/evidence/"
    "selected-binding-rtl-delta-projection-current.json"
)
SELECTED_BINDING_TOOL = pathlib.PurePosixPath(
    "npc/rv64/eval/ppa/tools/selected_binding_rtl_delta_projection.py"
)
ARCH_BINDING_TOOL = pathlib.PurePosixPath(
    "npc/rv64/eval/ppa/tools/architecture_hard_gates.py"
)
MUTATION_RUNNER = pathlib.PurePosixPath(
    "npc/rv64/testbench/scripts/run_architecture_delta_mutations.py"
)

EXPECTED_COUNTS = {
    "historical_total": 175,
    "historical_rtl": 171,
    "historical_verification": 4,
}
CLAIM_BOUNDARY = (
    "This receipt rebinds the 16 architecture-debt closures from immutable "
    "093c historical executions to the exact live RTL identity by per-file "
    "hash projection plus exact-current-source changed-cone counterexamples "
    "and current L0+L1+L2+L3 positives. Changed files outside the historical "
    "negative cones are listed as positive-only coverage. It does not promote "
    "whole-architecture, synthesis, STA, power, CPI, or PPA state."
)


class DeltaRebindError(RuntimeError):
    """The RTL delta, historical item, or current replacement is incomplete."""


def require(condition: bool, message: str) -> None:
    if not condition:
        raise DeltaRebindError(message)


def require_equal(actual: Any, expected: Any, label: str) -> None:
    if actual != expected:
        raise DeltaRebindError(
            f"{label}: expected {expected!r}, got {actual!r}"
        )


def sha_file(path: pathlib.Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def canonical_sha(value: Any) -> str:
    return hashlib.sha256(
        json.dumps(value, sort_keys=True, separators=(",", ":")).encode()
    ).hexdigest()


def safe_file(root: pathlib.Path, relative: str | pathlib.PurePosixPath) -> pathlib.Path:
    try:
        path = (root / pathlib.PurePosixPath(relative)).resolve(strict=True)
        path.relative_to(root.resolve())
    except (OSError, ValueError) as exc:
        raise DeltaRebindError(f"invalid repository file: {relative}") from exc
    if path.is_symlink() or not path.is_file():
        raise DeltaRebindError(f"not a regular repository file: {relative}")
    return path


def load_json(root: pathlib.Path, relative: str | pathlib.PurePosixPath) -> dict[str, Any]:
    try:
        value = json.loads(safe_file(root, relative).read_text(encoding="utf-8"))
    except json.JSONDecodeError as exc:
        raise DeltaRebindError(f"invalid JSON: {relative}") from exc
    if not isinstance(value, dict):
        raise DeltaRebindError(f"JSON object required: {relative}")
    return value


def artifact(root: pathlib.Path, relative: str | pathlib.PurePosixPath) -> dict[str, Any]:
    path = safe_file(root, relative)
    return {
        "path": path.relative_to(root.resolve()).as_posix(),
        "sha256": sha_file(path),
        "size_bytes": path.stat().st_size,
    }


def validate_artifact(root: pathlib.Path, value: dict[str, Any], label: str) -> dict[str, Any]:
    require(isinstance(value.get("path"), str), f"{label} path is missing")
    require(isinstance(value.get("sha256"), str), f"{label} sha256 is missing")
    path = safe_file(root, value["path"])
    require_equal(sha_file(path), value["sha256"], f"{label} hash")
    if "size_bytes" in value:
        require_equal(path.stat().st_size, value["size_bytes"], f"{label} size")
    return {
        "path": value["path"],
        "sha256": value["sha256"],
        **({"size_bytes": value["size_bytes"]} if "size_bytes" in value else {}),
    }


def validate_hash_records(root: pathlib.Path, value: Any, label: str) -> int:
    count = 0
    if isinstance(value, dict):
        if isinstance(value.get("path"), str) and isinstance(value.get("sha256"), str):
            validate_artifact(root, value, label)
            count += 1
        for key, child in value.items():
            count += validate_hash_records(root, child, f"{label}.{key}")
    elif isinstance(value, list):
        for index, child in enumerate(value):
            count += validate_hash_records(root, child, f"{label}[{index}]")
    return count


def validate_supplemental_inputs(
    root: pathlib.Path, value: Any
) -> dict[str, Any]:
    require(isinstance(value, dict), "supplemental.inputs must be an object")
    require_equal(
        set(value),
        {"architecture_binding", "control_variant_definitions", "runner"},
        "supplemental input set",
    )
    identity = value["architecture_binding"]
    require(isinstance(identity, dict), "supplemental architecture binding missing")
    require_equal(
        identity.get("path"),
        ARCH_BINDING_TOOL.as_posix(),
        "supplemental architecture binding path",
    )
    recorded_sha = identity.get("sha256")
    require(
        isinstance(recorded_sha, str) and re.fullmatch(r"[0-9a-f]{64}", recorded_sha),
        "supplemental architecture binding sha256 is malformed",
    )
    current_path = safe_file(root, ARCH_BINDING_TOOL)
    current_sha = sha_file(current_path)
    for key in ("control_variant_definitions", "runner"):
        validate_hash_records(root, value[key], f"supplemental.inputs.{key}")
    return {
        "path": ARCH_BINDING_TOOL.as_posix(),
        "recorded_sha256": recorded_sha,
        "current_sha256": current_sha,
        "classification": (
            "rtl_identity_helper_only"
            if recorded_sha != current_sha
            else "exact_current_input"
        ),
        "production_rtl_reexecuted": False,
    }


def load_module(path: pathlib.Path, name: str) -> Any:
    spec = importlib.util.spec_from_file_location(name, path)
    if spec is None or spec.loader is None:
        raise DeltaRebindError(f"cannot import helper: {path}")
    module = importlib.util.module_from_spec(spec)
    sys.modules[name] = module
    spec.loader.exec_module(module)
    return module


def current_l0_inputs(
    root: pathlib.Path, layered: dict[str, Any]
) -> tuple[pathlib.PurePosixPath, pathlib.PurePosixPath, dict[str, Any], dict[str, Any]]:
    """Resolve the exact current L0 result and RTL manifest from L0-L3 authority."""

    l0_layer = layered.get("layers", {}).get("L0_DIRECTED_RTL")
    require(isinstance(l0_layer, dict), "layered L0 record is missing")
    result_record = l0_layer.get("result")
    require(isinstance(result_record, dict), "layered L0 result is missing")
    validated_result = validate_artifact(root, result_record, "layered L0 result")
    result_path = pathlib.PurePosixPath(validated_result["path"])
    result = load_json(root, result_path)

    pre_record = result.get("inputs", {}).get("pre")
    require(isinstance(pre_record, dict), "current L0 input manifest is missing")
    validated_pre = validate_artifact(root, pre_record, "current L0 input manifest")
    manifest_path = pathlib.PurePosixPath(validated_pre["path"])
    manifest = load_json(root, manifest_path)
    return result_path, manifest_path, result, manifest


def manifests(
    root: pathlib.Path, current: dict[str, Any]
) -> tuple[dict[str, Any], dict[str, Any]]:
    baseline = load_json(root, BASELINE_MANIFEST)
    require_equal(baseline.get("design_id"), BASELINE_DESIGN_ID, "baseline design-id")
    baseline_files = baseline.get("files")
    current_files = current.get("groups", {}).get("rtl")
    require(isinstance(baseline_files, dict), "baseline RTL manifest is missing")
    require(isinstance(current_files, dict), "current RTL manifest is missing")
    require_equal(
        baseline.get("file_count"), len(baseline_files), "baseline file count")
    require(len(current_files) > 0, "current RTL manifest is empty")
    for relative, expected in current_files.items():
        require_equal(
            sha_file(safe_file(root, relative)), expected, f"live RTL hash {relative}"
        )
    architecture = load_module(
        safe_file(root, ARCH_BINDING_TOOL), "architecture_delta_rebind_binding"
    )
    live_sha, live_files = architecture.rtl_binding(root)
    require_equal(current.get("design_id"), f"sha256:{live_sha}", "current design-id")
    require_equal(set(current_files), set(live_files), "live RTL membership")
    return baseline, current


def compare_manifests(
    baseline_files: dict[str, str], current_files: dict[str, str]
) -> dict[str, Any]:
    removed = sorted(set(baseline_files) - set(current_files))
    require(not removed, f"baseline RTL files were removed: {removed}")
    added = sorted(set(current_files) - set(baseline_files))
    changed = sorted(
        path for path in set(baseline_files) & set(current_files)
        if baseline_files[path] != current_files[path]
    )
    return {
        "baseline_membership_preserved": True,
        "membership_equal": not added,
        "baseline_file_count": len(baseline_files),
        "file_count": len(current_files),
        "unchanged_file_count": len(baseline_files) - len(changed),
        "changed_file_count": len(changed),
        "added_file_count": len(added),
        "added_files": [
            {"path": path, "current_sha256": current_files[path]}
            for path in added
        ],
        "removed_file_count": 0,
        "removed_files": [],
        "changed_files": [
            {
                "path": path,
                "baseline_sha256": baseline_files[path],
                "current_sha256": current_files[path],
            }
            for path in changed
        ],
    }


def _item(
    *,
    item_id: str,
    debt_id: str,
    source: str | None,
    variant_sha256: str | None,
    evidence: dict[str, Any],
    source_sha256: str | None = None,
) -> dict[str, Any]:
    return {
        "item_id": item_id,
        "debt_id": debt_id,
        "source": source,
        "source_sha256": source_sha256,
        "variant_sha256": variant_sha256,
        "evidence": evidence,
    }


def historical_items(root: pathlib.Path) -> list[dict[str, Any]]:
    result: list[dict[str, Any]] = []
    baseline = load_json(root, BASELINE_MANIFEST)["files"]

    v14c = load_json(root, V14C_INVENTORY)
    require_equal(v14c.get("status"), "PASS", "V14C inventory status")
    v14c_rows = [
        row for row in v14c.get("items", [])
        if isinstance(row, dict) and row.get("debt_id") in P0_DEBTS
    ]
    require_equal(len(v14c_rows), 121, "V14C P0 negative item count")
    for row in v14c_rows:
        evidence = validate_artifact(root, row.get("log", {}), row["item_id"])
        source = row.get("source")
        result.append(_item(
            item_id=row["item_id"], debt_id=row["debt_id"], source=source,
            source_sha256=baseline.get(source) if isinstance(source, str) else None,
            variant_sha256=row.get("variant_sha256"), evidence=evidence,
        ))

    v14d = load_json(root, V14D_RECEIPT)
    v14d_rows = v14d.get("compile_success_rtl_counterexamples", {}).get(
        "inventory", []
    )
    require_equal(len(v14d_rows), 24, "V14D negative item count")
    for row in v14d_rows:
        evidence = validate_artifact(root, row.get("log", {}), row["item_id"])
        source = row.get("source")
        result.append(_item(
            item_id=row["item_id"], debt_id=row["debt_id"], source=source,
            source_sha256=baseline.get(source),
            variant_sha256=row.get("variant_sha256"), evidence=evidence,
        ))

    f0 = load_json(root, F0_MUTATIONS)
    f0_rows = f0.get("production_rtl", {}).get("results", [])
    require_equal(len(f0_rows), 3, "F0 negative item count")
    for row in f0_rows:
        source = row.get("source", {}).get("path")
        require_equal(row.get("source", {}).get("sha256"), baseline.get(source),
                      f"F0 baseline source {row.get('name')}")
        result.append(_item(
            item_id=f"F0-G1:RTL_MUTATION:{row['name']}", debt_id="F0-G1",
            source=source, source_sha256=baseline.get(source),
            variant_sha256=row.get("variant_sha256"),
            evidence=validate_artifact(root, row.get("log", {}), row["name"]),
        ))

    fence = load_json(root, FENCE_MUTATIONS)
    fence_rows = fence.get("results", [])
    require_equal(len(fence_rows), 2, "FENCE negative item count")
    for row in fence_rows:
        source = row.get("source")
        require_equal(row.get("original_sha256"), baseline.get(source),
                      f"FENCE baseline source {row.get('name')}")
        result.append(_item(
            item_id=f"FENCE-G1:RTL_MUTATION:{row['name']}", debt_id="FENCE-G1",
            source=source, source_sha256=baseline.get(source),
            variant_sha256=row.get("variant_sha256"),
            evidence=validate_artifact(root, row.get("log", {}), row["name"]),
        ))

    qh = load_json(root, SERIALIZE_QH)
    qh_evidence = artifact(root, SERIALIZE_QH)
    require_equal(qh.get("counts", {}).get("compile_success_mutations"), 3,
                  "SERIALIZE queue-head mutation count")
    for name, row in qh.get("mutations", {}).items():
        source_record = row.get("source", {})
        source = source_record.get("path")
        result.append(_item(
            item_id=f"SERIALIZE-G1:RTL_MUTATION:{name}",
            debt_id="SERIALIZE-G1", source=source,
            source_sha256=source_record.get("sha256"),
            variant_sha256=row.get("mutated", {}).get("sha256"),
            evidence=qh_evidence,
        ))
    system = load_json(root, SERIALIZE_SYSTEM)
    system_evidence = artifact(root, SERIALIZE_SYSTEM)
    system_rows = system.get("mutations", [])
    require_equal(len(system_rows), 15, "SERIALIZE system mutation count")
    for row in system_rows:
        source_record = row.get("module", {})
        source = source_record.get("path")
        result.append(_item(
            item_id=f"SERIALIZE-G1:RTL_MUTATION:{row['name']}",
            debt_id="SERIALIZE-G1", source=source,
            source_sha256=source_record.get("sha256"),
            variant_sha256=row.get("mutated", {}).get("sha256"),
            evidence=system_evidence,
        ))

    vectored = load_json(root, VECTORED_MUTATIONS)
    vectored_rows = vectored.get("results", [])
    require_equal(len(vectored_rows), 7, "VECTORED negative item count")
    for row in vectored_rows:
        source = row.get("production_rtl_source")
        result.append(_item(
            item_id=f"VECTORED-TRAP-G1:RTL_MUTATION:{row['mutation_id']}",
            debt_id="VECTORED-TRAP-G1", source=source,
            source_sha256=baseline.get(source),
            variant_sha256=row.get("variant_sha256"),
            evidence=validate_artifact(
                root, row.get("log", {}), row["mutation_id"]
            ),
        ))

    ids = [row["item_id"] for row in result]
    require_equal(len(ids), len(set(ids)), "historical negative item uniqueness")
    require_equal(len(result), EXPECTED_COUNTS["historical_total"],
                  "historical negative total")
    return sorted(result, key=lambda row: row["item_id"])


def classify_historical(
    root: pathlib.Path,
    items: Sequence[dict[str, Any]],
    baseline_files: dict[str, str],
    current_files: dict[str, str],
    changed_paths: set[str],
) -> list[dict[str, Any]]:
    result: list[dict[str, Any]] = []
    for row in items:
        source = row.get("source")
        source_sha = row.get("source_sha256")
        classified = dict(row)
        if source is None:
            classified["projection_mode"] = "CHECKER_ONLY_REUSED"
        elif source in baseline_files:
            require_equal(source_sha, baseline_files[source],
                          f"historical source binding {row['item_id']}")
            if source in changed_paths:
                classified["projection_mode"] = "CHANGED_RTL_REPLAY_REQUIRED"
            else:
                require_equal(current_files[source], baseline_files[source],
                              f"unchanged RTL projection {row['item_id']}")
                classified["projection_mode"] = "UNCHANGED_RTL_REUSED"
        else:
            require(isinstance(source, str) and isinstance(source_sha, str),
                    f"verification source binding missing {row['item_id']}")
            require_equal(sha_file(safe_file(root, source)), source_sha,
                          f"verification source projection {row['item_id']}")
            classified["projection_mode"] = "VERIFICATION_SOURCE_REUSED"
        result.append(classified)
    counts = {
        "historical_rtl": sum(row["source"] in baseline_files for row in result),
        "historical_verification": sum(row["source"] not in baseline_files for row in result),
        "unchanged_rtl_reused": sum(
            row["projection_mode"] == "UNCHANGED_RTL_REUSED" for row in result
        ),
        "changed_rtl_replayed": sum(
            row["projection_mode"] == "CHANGED_RTL_REPLAY_REQUIRED"
            for row in result
        ),
    }
    for label in ("historical_rtl", "historical_verification"):
        require_equal(counts[label], EXPECTED_COUNTS[label], label)
    require_equal(
        counts["unchanged_rtl_reused"] + counts["changed_rtl_replayed"],
        EXPECTED_COUNTS["historical_rtl"],
        "historical RTL projection partition",
    )
    return result


def _current_row(
    root: pathlib.Path,
    row: dict[str, Any],
    current_files: dict[str, str],
    evidence_name: str,
) -> dict[str, Any]:
    source = row.get("source")
    require(isinstance(source, str) and source in current_files,
            f"{evidence_name} current RTL source is missing")
    source_sha = row.get("source_sha256", row.get("original_sha256"))
    require_equal(source_sha, current_files[source],
                  f"{evidence_name} current RTL hash")
    require_equal(row.get("compile_success"), True,
                  f"{evidence_name} compile-success")
    rejected = row.get("dynamic_rejected", row.get("rejected"))
    require_equal(rejected, True, f"{evidence_name} dynamic rejection")
    log = validate_artifact(root, row.get("log", {}), f"{evidence_name} log")
    return {
        "name": row.get("name"),
        "source": source,
        "source_sha256": source_sha,
        "variant_sha256": row.get("variant_sha256", row.get("mutation_sha256")),
        "test_name": row.get("test_name"),
        "compile_success": True,
        "dynamic_rejected": True,
        "log": log,
    }


def source_design_projection(
    recorded_design_id: Any, current_design_id: str, label: str
) -> dict[str, Any]:
    """Classify retained negative evidence without claiming whole-design reuse."""

    if recorded_design_id is None:
        return {
            "mode": "EXACT_CURRENT_SOURCE_WITHOUT_RECORDED_WHOLE_DESIGN_ID",
            "recorded_design_id": None,
            "current_design_id": current_design_id,
            "whole_design_reexecuted": False,
        }
    require(
        isinstance(recorded_design_id, str)
        and re.fullmatch(r"sha256:[0-9a-f]{64}", recorded_design_id) is not None,
        f"{label} design-id is malformed",
    )
    return {
        "mode": (
            "EXACT_CURRENT_DESIGN"
            if recorded_design_id == current_design_id
            else "EXACT_CURRENT_SOURCE_PROJECTED_FROM_PRIOR_DESIGN"
        ),
        "recorded_design_id": recorded_design_id,
        "current_design_id": current_design_id,
        "whole_design_reexecuted": recorded_design_id == current_design_id,
    }


def current_replacements(
    root: pathlib.Path,
    classified: Sequence[dict[str, Any]],
    current_files: dict[str, str],
    current_design_id: str,
) -> tuple[dict[str, dict[str, Any]], dict[str, Any]]:
    affected = {
        row["item_id"]: row
        for row in classified
        if row["projection_mode"] == "CHANGED_RTL_REPLAY_REQUIRED"
    }
    replacements: dict[str, dict[str, Any]] = {}

    v9f = load_json(root, CURRENT_V9F)
    require_equal(v9f.get("required"), 11, "current V9F required")
    require_equal(v9f.get("compile_success"), 11, "current V9F compile-success")
    require_equal(v9f.get("dynamic_rejected"), 11, "current V9F rejection")
    require_equal(v9f.get("source_unchanged"), True, "current V9F source stability")
    v9f_projection = source_design_projection(
        v9f.get("design_id"), current_design_id, "retained V9F"
    )
    for row in v9f.get("results", []):
        item_id = f"{row.get('debt_id')}:RTL_MUTATION:{row.get('name')}"
        if item_id in affected:
            replacements[item_id] = {
                **_current_row(root, row, current_files, item_id),
                "evidence_set": "current_v9f",
                "replacement_kind": "EXACT_MUTATION_REPLAY",
                "evidence_design_projection": v9f_projection,
            }

    supplemental = load_json(root, CURRENT_SUPPLEMENTAL)
    require_equal(supplemental.get("schema"),
                  "npc-rv64-architecture-delta-mutations-v1",
                  "supplemental schema")
    require_equal(supplemental.get("status"), "PASS", "supplemental status")
    supplemental_projection = source_design_projection(
        supplemental.get("design_id"), current_design_id,
        "retained supplemental",
    )
    require_equal(supplemental.get("counts", {}).get("required"), 22,
                  "supplemental required")
    require_equal(supplemental.get("counts", {}).get("passed"), 22,
                  "supplemental passed")
    require_equal(
        supplemental.get("counts", {}).get("transient_compiled_images_retained"),
        0, "supplemental retained images",
    )
    supplemental_input_replay = validate_supplemental_inputs(
        root, supplemental.get("inputs", {})
    )
    for row in supplemental.get("results", []):
        for item_id in row.get("replaces_historical_items", []):
            if item_id not in affected:
                continue
            require(item_id not in replacements, f"duplicate replacement {item_id}")
            historical_source = affected[item_id]["source"]
            require_equal(row.get("source"), historical_source,
                          f"semantic replacement source {item_id}")
            replacements[item_id] = {
                **_current_row(root, row, current_files, item_id),
                "evidence_set": "current_supplemental",
                "replacement_kind": (
                    "CURRENT_CONTRACT_SEMANTIC_REPLACEMENT"
                    if row.get("name") ==
                    "sq-clear-owner-valid-on-authorized-request-fire"
                    else "EXACT_MUTATION_REPLAY"
                ),
                "evidence_design_projection": supplemental_projection,
            }

    relocated = load_json(root, CURRENT_D3F3_FENCE)
    require_equal(relocated.get("schema"),
                  "npc-rv64-architecture-delta-mutations-v1",
                  "relocated FENCE schema")
    require_equal(relocated.get("status"), "PASS", "relocated FENCE status")
    require_equal(relocated.get("design_id"), current_design_id,
                  "relocated FENCE design-id")
    require_equal(relocated.get("counts", {}).get("required"), 1,
                  "relocated FENCE required")
    require_equal(relocated.get("counts", {}).get("passed"), 1,
                  "relocated FENCE passed")
    validate_supplemental_inputs(root, relocated.get("inputs", {}))
    for row in relocated.get("results", []):
        require_equal(row.get("name"), "pending-fence-mem-idle-removed",
                      "relocated FENCE mutation")
        for item_id in row.get("replaces_historical_items", []):
            if item_id not in affected:
                continue
            require(item_id not in replacements, f"duplicate replacement {item_id}")
            historical_source = affected[item_id].get("source")
            relocation = historical_source != row.get("source")
            if relocation:
                require_equal(
                    historical_source,
                    "npc/rv64/vsrc/control/OooControlPlane.v",
                    f"relocated historical source {item_id}",
                )
            replacement = _current_row(root, row, current_files, item_id)
            replacements[item_id] = {
                **replacement,
                "historical_source": historical_source,
                "evidence_set": "current_d3f3_fence_relocation",
                "replacement_kind": (
                    "CURRENT_CONTRACT_SEMANTIC_RELOCATION"
                    if relocation else "EXACT_MUTATION_REPLAY"
                ),
                "evidence_design_projection": source_design_projection(
                    relocated.get("design_id"), current_design_id,
                    "relocated FENCE",
                ),
            }

    validate_affected_replacements(affected, replacements)
    supplemental_input_replay["evidence_design_projection"] = (
        supplemental_projection
    )
    return dict(sorted(replacements.items())), supplemental_input_replay


def validate_affected_replacements(
    affected: dict[str, dict[str, Any]],
    replacements: dict[str, dict[str, Any]],
) -> None:
    require_equal(set(replacements), set(affected), "changed-source replacement set")
    for item_id, replacement in replacements.items():
        if replacement.get("replacement_kind") == "CURRENT_CONTRACT_SEMANTIC_RELOCATION":
            require_equal(
                replacement.get("historical_source"),
                affected[item_id].get("source"),
                f"changed-source relocation binding {item_id}",
            )
        else:
            require_equal(
                replacement.get("source"), affected[item_id].get("source"),
                f"changed-source replacement binding {item_id}",
            )
        require_equal(replacement.get("compile_success"), True,
                      f"changed-source compile-success {item_id}")
        require_equal(replacement.get("dynamic_rejected"), True,
                      f"changed-source rejection {item_id}")


def current_positive(
    root: pathlib.Path,
    current_design_id: str,
    l0: dict[str, Any],
    layered: dict[str, Any],
) -> dict[str, Any]:
    require_equal(l0.get("status"), "PASS", "current L0 status")
    require_equal(l0.get("design_id"), current_design_id, "current L0 design-id")
    inventory = l0.get("tests", {}).get("inventory", [])
    logs = l0.get("tests", {}).get("logs", {})
    require(len(inventory) > 0, "current L0 test inventory is empty")
    require_equal(set(logs), set(inventory), "current L0 log inventory")
    l0_artifacts = validate_hash_records(root, l0, "current_l0")

    require_equal(layered.get("schema"),
                  "npc-rv64-layered-system-signoff-current-v1",
                  "layered signoff schema")
    require_equal(layered.get("status"), "PASS", "layered signoff status")
    require_equal(
        layered.get("default_signoff_conjunction"),
        ["L0_DIRECTED_RTL", "L1_FULL_CORE_DIFFTEST", "L2_MINI_SYSTEM",
         "L3_LIGHTWEIGHT_LINUX"],
        "layered signoff conjunction",
    )
    layers = layered.get("layers", {})
    require_equal(set(layers), {
        "L0_DIRECTED_RTL", "L1_FULL_CORE_DIFFTEST", "L2_MINI_SYSTEM",
        "L3_LIGHTWEIGHT_LINUX",
    }, "layered signoff membership")
    for name, layer in layers.items():
        require_equal(layer.get("status"), "PASS", f"{name} status")
        require_equal(layer.get("design_id"), current_design_id,
                      f"{name} design-id")
    l0_count = len(inventory)
    require_equal(layers["L0_DIRECTED_RTL"].get("tests"),
                  {"passed": l0_count, "required": l0_count},
                  "layered L0 counts")
    l1 = layers["L1_FULL_CORE_DIFFTEST"].get("counts", {})
    require_equal((l1.get("official_passed"), l1.get("official_required")),
                  (177, 177), "layered L1 official")
    require_equal((l1.get("am_passed"), l1.get("am_required")),
                  (61, 61), "layered L1 AM")
    require_equal(l1.get("difftest_mismatches"), 0, "layered L1 DiffTest")
    require_equal(layers["L2_MINI_SYSTEM"].get("case"), "all", "layered L2 case")
    require_equal(layers["L3_LIGHTWEIGHT_LINUX"].get("case"), "all", "layered L3 case")
    layered_artifacts = validate_hash_records(root, layered, "layered")
    return {
        "l0": {"tests": f"{l0_count}/{l0_count}", "rtl_assertion_failures": 0,
               "artifact_records": l0_artifacts},
        "l1": {"official": "177/177", "am": "61/61",
               "difftest_mismatches": 0, "guest_rerun": False},
        "l2": {"case": "all", "status": "PASS"},
        "l3": {"case": "all", "status": "PASS"},
        "optional_ubuntu": "NOT_RUN_OPTIONAL",
        "artifact_records": layered_artifacts,
    }


def selected_binding_projection(
    root: pathlib.Path, current_design_id: str
) -> dict[str, Any]:
    module = load_module(
        safe_file(root, SELECTED_BINDING_TOOL),
        "architecture_debt_delta_selected_binding",
    )
    try:
        receipt = module.verify_receipt(argparse.Namespace(
            root=root, receipt=safe_file(root, SELECTED_BINDING_RECEIPT)
        ))
    except module.ProjectionGap as exc:
        raise DeltaRebindError(f"selected-binding RTL delta is GAP: {exc}") from exc
    require_equal(receipt.get("current_design_id"), current_design_id,
                  "selected-binding current design-id")
    require_equal(receipt.get("status"), "PASS", "selected-binding status")
    return {
        "status": "PASS",
        "rtl_delta_files": len(receipt.get("rtl_delta", [])),
        "new_holder_units": receipt.get("holder_write_projection", {}).get(
            "new_unit_ids", []
        ),
        "v14r_mutations": len(receipt.get("v14r_evidence", {}).get("mutations", [])),
        "claim_boundary": receipt.get("claim_boundary"),
    }


def build_receipt(root: pathlib.Path) -> dict[str, Any]:
    root = root.resolve()
    layered = load_json(root, LAYERED_SIGNOFF)
    current_l0_path, current_manifest_path, current_l0, current_manifest = (
        current_l0_inputs(root, layered)
    )
    baseline, current = manifests(root, current_manifest)
    baseline_files = baseline["files"]
    current_files = current["groups"]["rtl"]
    delta = compare_manifests(baseline_files, current_files)
    changed_existing_paths = {row["path"] for row in delta["changed_files"]}
    added_paths = {row["path"] for row in delta["added_files"]}
    changed_paths = changed_existing_paths | added_paths
    items = historical_items(root)
    classified = classify_historical(
        root, items, baseline_files, current_files, changed_existing_paths
    )
    current_design_id = current["design_id"]
    replacements, supplemental_input_replay = current_replacements(
        root, classified, current_files, current_design_id
    )
    positives = current_positive(
        root, current_design_id, current_l0, layered
    )
    selected = selected_binding_projection(root, current_design_id)
    mode_counts = {
        mode: sum(row["projection_mode"] == mode for row in classified)
        for mode in (
            "UNCHANGED_RTL_REUSED", "CHANGED_RTL_REPLAY_REQUIRED",
            "CHECKER_ONLY_REUSED", "VERIFICATION_SOURCE_REUSED",
        )
    }
    per_debt = {
        debt: sum(row["debt_id"] == debt for row in classified)
        for debt in sorted({row["debt_id"] for row in classified})
    }
    historical_changed_sources = sorted({
        row["source"]
        for row in classified
        if row["projection_mode"] == "CHANGED_RTL_REPLAY_REQUIRED"
    })
    positive_only_changed_files = sorted(
        changed_paths - set(historical_changed_sources)
    )
    inputs = {
        "architecture_binding_tool": artifact(root, ARCH_BINDING_TOOL),
        "baseline_manifest": artifact(root, BASELINE_MANIFEST),
        "current_l0": artifact(root, current_l0_path),
        "current_manifest": artifact(root, current_manifest_path),
        "current_supplemental": artifact(root, CURRENT_SUPPLEMENTAL),
        "current_d3f3_fence": artifact(root, CURRENT_D3F3_FENCE),
        "current_v9f": artifact(root, CURRENT_V9F),
        "delta_mutation_runner": artifact(root, MUTATION_RUNNER),
        "f0_mutations": artifact(root, F0_MUTATIONS),
        "f0_summary": artifact(root, F0_SUMMARY),
        "fence_mutations": artifact(root, FENCE_MUTATIONS),
        "fence_summary": artifact(root, FENCE_SUMMARY),
        "layered_signoff": artifact(root, LAYERED_SIGNOFF),
        "receipt_tool": artifact(
            root, pathlib.Path(__file__).resolve().relative_to(root).as_posix()
        ),
        "selected_binding_receipt": artifact(root, SELECTED_BINDING_RECEIPT),
        "selected_binding_tool": artifact(root, SELECTED_BINDING_TOOL),
        "serialize_qh": artifact(root, SERIALIZE_QH),
        "serialize_summary": artifact(root, SERIALIZE_SUMMARY),
        "serialize_system": artifact(root, SERIALIZE_SYSTEM),
        "v14c_inventory": artifact(root, V14C_INVENTORY),
        "v14d_receipt": artifact(root, V14D_RECEIPT),
        "vectored_mutations": artifact(root, VECTORED_MUTATIONS),
        "vectored_summary": artifact(root, VECTORED_SUMMARY),
    }
    return {
        "schema": SCHEMA,
        "status": "PASS",
        "baseline_design_id": BASELINE_DESIGN_ID,
        "current_design_id": current_design_id,
        "rtl_delta": delta,
        "historical_negative": {
            "total": len(classified),
            "mode_counts": mode_counts,
            "per_debt": per_debt,
            "classification_sha256": canonical_sha(classified),
            "items": classified,
        },
        "current_changed_cone": {
            "required": len(replacements),
            "passed": len(replacements),
            "replacement_sha256": canonical_sha(replacements),
            "replacements": replacements,
            "supplemental_input_replay": supplemental_input_replay,
        },
        "changed_source_coverage": {
            "historical_negative_sources": historical_changed_sources,
            "positive_only_changed_files": positive_only_changed_files,
            "positive_only_coverage": "CURRENT_L0_L1_L2_L3",
        },
        "current_positive": positives,
        "selected_binding_projection": selected,
        "inputs": dict(sorted(inputs.items())),
        "evidence_contract": {
            "historical_status": "IMMUTABLE",
            "unchanged_rtl": "EXACT_PER_FILE_SHA_REUSE",
            "changed_rtl": "CURRENT_COMPILE_SUCCESS_REJECTED_VARIANT_REQUIRED",
            "added_rtl": "CURRENT_L0_L1_L2_L3_POSITIVE_COVERAGE_REQUIRED",
            "retained_negative_projection": (
                "EXACT_CURRENT_SOURCE_HASH_WITH_EXPLICIT_PRIOR_DESIGN_ID"
            ),
            "supplemental_input_replay": "EXACT_CURRENT_INPUTS",
            "system_delta": "CURRENT_L0_L1_L2_L3_REQUIRED",
            "simulator_launched_by_receipt_builder": False,
        },
        "claim_boundary": CLAIM_BOUNDARY,
        "promotion": {
            "architecture_debt_evidence": "CURRENT_DELTA_REBOUND",
            "whole_architecture": "RED",
            "system_recertification": "PASS_CURRENT_CONFIG",
            "ppa": "UNPROMOTED",
        },
    }


@functools.lru_cache(maxsize=4)
def cached_expected(root_text: str) -> dict[str, Any]:
    return build_receipt(pathlib.Path(root_text))


def validate_receipt(
    root: pathlib.Path,
    input_path: pathlib.Path,
    expected_design_id: str | None = None,
) -> dict[str, Any]:
    actual = load_json(
        root, input_path.resolve().relative_to(root.resolve()).as_posix()
    )
    expected = cached_expected(str(root.resolve()))
    require_equal(actual, expected, "architecture-debt delta receipt")
    if expected_design_id is not None:
        require_equal(actual.get("current_design_id"), expected_design_id,
                      "caller current design-id")
    return actual


def write_json(path: pathlib.Path, value: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = path.with_suffix(path.suffix + ".tmp")
    temporary.write_text(
        json.dumps(value, indent=2, sort_keys=True) + "\n", encoding="utf-8"
    )
    temporary.replace(path)


def parser() -> argparse.ArgumentParser:
    result = argparse.ArgumentParser(description=__doc__)
    result.add_argument(
        "--root", type=pathlib.Path,
        default=pathlib.Path(__file__).resolve().parents[5],
    )
    sub = result.add_subparsers(dest="command", required=True)
    build = sub.add_parser("build")
    build.add_argument("--output", type=pathlib.Path, required=True)
    verify = sub.add_parser("verify")
    verify.add_argument("--input", type=pathlib.Path, required=True)
    return result


def main(argv: Sequence[str] | None = None) -> int:
    args = parser().parse_args(argv)
    root = args.root.resolve()
    try:
        expected = build_receipt(root)
        if args.command == "build":
            output = args.output if args.output.is_absolute() else root / args.output
            write_json(output.resolve(), expected)
            receipt = expected
        else:
            input_path = args.input if args.input.is_absolute() else root / args.input
            receipt = validate_receipt(root, input_path.resolve())
    except (DeltaRebindError, OSError, ValueError, json.JSONDecodeError) as exc:
        print(f"[ARCHITECTURE-DEBT-DELTA-REBIND][GAP] {exc}", file=sys.stderr)
        return 1
    print(
        "[ARCHITECTURE-DEBT-DELTA-REBIND][PASS] "
        f"baseline={receipt['baseline_design_id']} "
        f"current={receipt['current_design_id']} "
        f"rtl_files={receipt['rtl_delta']['file_count']} "
        f"changed={receipt['rtl_delta']['changed_file_count']} "
        f"historical={receipt['historical_negative']['total']} "
        f"replayed={receipt['current_changed_cone']['passed']} "
        "whole_architecture=RED ppa=UNPROMOTED"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
