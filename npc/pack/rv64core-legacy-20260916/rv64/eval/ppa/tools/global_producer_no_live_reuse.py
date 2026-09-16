#!/usr/bin/env python3
"""Capture and verify the current RV64 global ProducerId owner closure.

The receipt deliberately separates an infrequent V14G simulation refresh from
the normal deterministic check.  It promotes only the bounded
``global_no_live_reuse`` claim; whole-core architecture, system
recertification and PPA remain outside this result.
"""

from __future__ import annotations

import argparse
import functools
import gzip
import hashlib
import importlib.util
import json
import pathlib
import re
import shutil
import sys
from typing import Any, Iterable


SCHEMA = "npc-rv64-global-producer-no-live-reuse-receipt-v2"
V14G_SCHEMA = "npc-rv64-v14g-global-producer-owner-fence-v1"
YOSYS_RECEIPT_SCHEMA = "rv64-producer-holder-instance-graph-receipt-v1"
DESIGN_ID_RE = re.compile(r"^sha256:[0-9a-f]{64}$")
SHA256_RE = re.compile(r"^[0-9a-f]{64}$")

ORACLE_FAIL = "[V14G-GLOBAL-OWNER-ORACLE][FAIL]"
TB_PASS = "[PASS] tb_ooo_int_backend_v14g_global_owner_fence"
GLOBAL_PASS = "[V14G-GLOBAL-PRODUCER-OWNER][PASS]"
BASELINE_MARKERS = (
    "[V14G-BIRTH-EDGE-OLD][PASS]",
    "[V14G-OWNER-BIRTH][PASS]",
    "[V14G-UNION-ISOLATION][PASS]",
    "[V14G-DISPATCH-LANE-MATRIX][PASS]",
    "[V14G-OWNER-ONLY-LIVE][PASS]",
    "[V14G-DEATH-EDGE-OLD][PASS]",
    "[V14G-PENDING-SYSTEM-UNION][PASS]",
    GLOBAL_PASS,
    TB_PASS,
)
EXPECTED_MUTATIONS = {
    "int-iq-mask-drops-on-fire": "memory-capture-int-iq-holder",
    "dispatch-drops-external-union": "birth-owner-only",
    "backend-drops-load-queue-union": "load-queue-union",
    "backend-drops-reservation-union": "reservation-union",
    "backend-drops-memory-owner-union": "collector-pending-owner-only",
    "backend-lane6-corrupts-reservation-token": "terminal-lane6-ingress",
    "backend-drops-pending-system-union": "pending-system-union",
    "dispatch-lane0-truncates-generation": "birth-edge-old",
    "dispatch-mandatory-lane1-truncates-generation": "lane1-mandatory",
    "dispatch-optional-lane1-truncates-generation": "lane1-optional",
    "tracker-clears-producer-on-death-edge": "death-edge-old",
}
EXPECTED_PROMOTION = {
    "global_no_live_reuse": "GREEN",
    "whole_architecture": "RED",
    "system_recertification": "REQUIRED",
    "ppa": "UNPROMOTED",
}
CLAIM_BOUNDARY = (
    "Current RV64 product configuration only: 46/46 local holder semantics, "
    "the V14R bank-local request-hold contract, the V14G full-ProducerId "
    "birth/hold/death fence, and the elaborated dispatch1_optional "
    "constant-low chain promote global_no_live_reuse only. Whole "
    "architecture, system recertification and PPA remain unpromoted."
)

DEFAULT_V14G_RESULT = (
    ".github/task-runs/2026-08-06-rv64-v15h-architecture-debt-current-f7a/"
    "evidence/v14g-current-f7a-a2"
)
DEFAULT_LEDGER = (
    "npc/rv64/design/arch/producer-holder-semantic-coverage.json"
)
DEFAULT_RECEIPT = (
    "npc/rv64/eval/ppa/evidence/"
    "global-producer-no-live-reuse-current.json"
)
DEFAULT_YOSYS_JSON = (
    ".github/task-runs/2026-08-06-rv64-v15h-architecture-debt-current-f7a/"
    "evidence/current-holder-instance-graph/"
    "yosys-instance-graph.full.json.gz"
)
DEFAULT_YOSYS_RECEIPT = (
    ".github/task-runs/2026-08-06-rv64-v15h-architecture-debt-current-f7a/"
    "evidence/current-holder-instance-graph/"
    "yosys-instance-graph-receipt.json"
)

OPTIONAL_SOURCE_PATHS = (
    "npc/rv64/vsrc/frontend/OooBranchAppendDispatchGate.v",
    "npc/rv64/vsrc/frontend/OooFrontend.v",
    "npc/rv64/vsrc/core/OooCoreTopGlue.v",
    "npc/rv64/vsrc/execute/OooExecuteBackend.v",
    "npc/rv64/vsrc/execute/OooAluCoreSlice.v",
    "npc/rv64/vsrc/decode/OooAluDecodeBackend.v",
    "npc/rv64/vsrc/execute/OooIntBackend.v",
    "npc/rv64/vsrc/rename_allocate/OooDispatchBackend.v",
    "npc/rv64/vsrc/scheduling/OooIntIssueQueue.v",
)

SUPPORT_REQUIREMENTS: dict[str, dict[str, Any]] = {
    "v11b-terminal-collector-current-closure": {
        "binding_state": "CURRENT_SELECTED_SOURCE_DELTA_PROJECTION_BOUND",
        "detail": {
            "positive_profiles": 2,
            "compile_success_mutations_rejected": 3,
            "ingress_lanes": 12,
            "tracker_free_lanes": 2,
            "compiled_images_retained": 0,
        },
    },
    "v11c-memory-tracker-current-closure": {
        "binding_state": "CURRENT_SELECTED_SOURCE_AND_TB_BOUND",
        "detail": {
            "positive_profiles": 2,
            "compile_success_mutations_rejected": 9,
            "unknown_negatives_rejected": 4,
            "next_token_cursor_closed": False,
        },
    },
    "v11d-memory-tracker-cursor-current-closure": {
        "binding_state": "CURRENT_SELECTED_SOURCE_AND_TB_BOUND",
        "detail": {
            "positive_profiles": 4,
            "compile_success_mutations_rejected": 9,
            "token_counts": [4, 32],
            "next_token_cursor_closed": True,
        },
    },
    "v11e-rob-slot-generation-current-closure": {
        "binding_state": "CURRENT_SELECTED_MACRO_PROJECTION_BOUND",
        "detail": {
            "positive_profiles": 4,
            "compile_success_mutation_cases_rejected": 17,
            "mutation_simulations_rejected": 34,
            "generation_widths": [1, 4],
            "rob_slot_generation_closed": True,
        },
    },
    "v11m-memory-reservation-holder-current-closure": {
        "binding_state": "CURRENT_SELECTED_SOURCE_DELTA_PROJECTION_BOUND",
        "detail": {
            "positive_profiles": 2,
            "compile_success_mutation_cases_rejected": 37,
            "mutation_simulations_rejected": 37,
            "ordinary_regressions_passed": 3,
            "raw_producer_and_token_xz_knownness_closed": True,
            "pair_credit_and_turnover_atomicity_closed": True,
            "capture_hold_request_terminal_death_closed": True,
            "lane6_lane7_accepted_terminal_closed": True,
            "selective_and_global_recovery_closed": True,
            "production_design_id_current": False,
            "a3_frozen_evidence_unchanged": True,
        },
    },
    "v14r-memory-request-hold-current-closure": {
        "binding_state": "CURRENT_SELECTED_SOURCE_AND_TB_BOUND",
        "detail": {
            "positive_profiles": 7,
            "compile_success_mutations_rejected": 6,
            "holder_flip_flops": 29,
            "assertion_only_payload_shadow_bits": 217,
            "ready_low_valid_payload_stability_closed": True,
            "nonflush_cancel_priority_closed": True,
            "bank_local_exact_source_and_token_hold_closed": True,
            "sq_and_amo_held_launch_lease_closed": True,
            "single_bank_older_probe_order_closed": True,
        },
    },
}


class ClosureError(RuntimeError):
    """The bounded global owner closure is incomplete or stale."""


def require(condition: bool, message: str) -> None:
    if not condition:
        raise ClosureError(message)


def valid_sha256(value: Any) -> bool:
    return isinstance(value, str) and SHA256_RE.fullmatch(value) is not None


def sha256_bytes(payload: bytes) -> str:
    return hashlib.sha256(payload).hexdigest()


def sha256_file(path: pathlib.Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def load_json(path: pathlib.Path) -> Any:
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except (OSError, UnicodeError, json.JSONDecodeError) as exc:
        raise ClosureError(f"cannot read JSON {path}: {exc}") from exc


def resolve_repo_path(root: pathlib.Path, value: str | pathlib.Path) -> pathlib.Path:
    candidate = pathlib.Path(value)
    if not candidate.is_absolute():
        candidate = root / candidate
    candidate = candidate.resolve()
    try:
        candidate.relative_to(root.resolve())
    except ValueError as exc:
        raise ClosureError(f"path escapes repository: {value}") from exc
    return candidate


def display_path(root: pathlib.Path, path: pathlib.Path) -> str:
    return path.resolve().relative_to(root.resolve()).as_posix()


def artifact(root: pathlib.Path, path: pathlib.Path, kind: str) -> dict[str, Any]:
    require(path.is_file(), f"missing {kind}: {display_path(root, path)}")
    return {
        "kind": kind,
        "path": display_path(root, path),
        "sha256": sha256_file(path),
        "size_bytes": path.stat().st_size,
    }


def manifest_digest(manifest: dict[str, str]) -> str:
    payload = "".join(
        f"{name}\0{digest}\n" for name, digest in sorted(manifest.items())
    )
    return sha256_bytes(payload.encode("utf-8"))


def current_design_id(root: pathlib.Path) -> str:
    tool_path = root / "npc/rv64/eval/ppa/tools/architecture_hard_gates.py"
    spec = importlib.util.spec_from_file_location(
        "_rv64_global_owner_architecture", tool_path
    )
    require(spec is not None and spec.loader is not None,
            "architecture identity tool cannot be loaded")
    module = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = module
    try:
        spec.loader.exec_module(module)
        digest, _ = module.rtl_binding(root)
    finally:
        sys.modules.pop(spec.name, None)
    return f"sha256:{digest}"


def source_role(path: str) -> tuple[str, bool]:
    if path.endswith("/Makefile") or path == "npc/rv64/Makefile":
        return "orchestration_snapshot", False
    if path.endswith("ooo-global-producer-no-live-reuse.md"):
        return "specification_snapshot", False
    if "/testbench/scripts/" in path:
        return "runner", True
    if "/testbench/" in path:
        return "testbench", True
    if "/vsrc/" in path:
        return "rtl", True
    return "captured_input", True


def normalize_source_bindings(
    root: pathlib.Path, manifest: dict[str, Any]
) -> list[dict[str, Any]]:
    require(manifest and all(isinstance(k, str) for k in manifest),
            "V14G source manifest is empty or malformed")
    result: list[dict[str, Any]] = []
    for path, digest in sorted(manifest.items()):
        require(valid_sha256(digest), f"invalid V14G source digest: {path}")
        role, current_required = source_role(path)
        source = resolve_repo_path(root, path)
        if current_required:
            require(source.is_file(), f"current V14G input is missing: {path}")
            require(sha256_file(source) == digest,
                    f"current V14G input drifted: {path}")
        result.append({
            "path": path,
            "sha256": digest,
            "role": role,
            "current_required": current_required,
        })
    return result


def profile_log(
    root: pathlib.Path,
    record: dict[str, Any],
    archive_dir: pathlib.Path | None = None,
) -> dict[str, Any]:
    path_value = record.get("log")
    require(isinstance(path_value, str), "V14G profile log path is absent")
    path = resolve_repo_path(root, path_value)
    require(path.is_file(), f"V14G profile log is missing: {path_value}")
    digest = sha256_file(path)
    require(digest == record.get("log_sha256"),
            f"V14G profile log digest drifted: {path_value}")
    if archive_dir is not None:
        archive_dir = archive_dir.resolve()
        try:
            archive_dir.relative_to(root.resolve())
        except ValueError as exc:
            raise ClosureError(
                f"V14G log archive escapes repository: {archive_dir}") from exc
        archive_dir.mkdir(parents=True, exist_ok=True)
        archived = archive_dir / path.name
        if archived.exists():
            require(archived.is_file() and sha256_file(archived) == digest,
                    f"V14G archived log conflicts: {display_path(root, archived)}")
        else:
            temporary = archived.with_name(archived.name + ".tmp")
            try:
                shutil.copyfile(path, temporary)
                require(sha256_file(temporary) == digest,
                        f"V14G archived log copy drifted: {path_value}")
                temporary.replace(archived)
            finally:
                temporary.unlink(missing_ok=True)
        path = archived
        path_value = display_path(root, archived)
    return {
        "origin_path": path_value,
        "sha256": digest,
        "size_bytes": path.stat().st_size,
    }


def normalized_profile(
    root: pathlib.Path,
    record: dict[str, Any],
    archive_dir: pathlib.Path | None = None,
) -> dict[str, Any]:
    for key in ("artifact_sha256", "compile_command_sha256", "log_sha256"):
        require(valid_sha256(record.get(key)),
                f"V14G profile has invalid {key}: {record.get('name')}")
    require(record.get("pass") is True,
            f"V14G profile is not PASS: {record.get('name')}")
    require(record.get("compile_rc") == 0,
            f"V14G profile did not compile: {record.get('name')}")
    require(record.get("compile_timeout") is False,
            f"V14G profile compile timed out: {record.get('name')}")
    require(record.get("sim_timeout") is False,
            f"V14G profile simulation timed out: {record.get('name')}")
    require(record.get("artifact_generated") is True,
            f"V14G profile lacks a compile image: {record.get('name')}")
    markers = record.get("marker_counts")
    require(isinstance(markers, dict),
            f"V14G profile markers are absent: {record.get('name')}")
    require(set(markers) == set(BASELINE_MARKERS) | {ORACLE_FAIL},
            f"V14G marker inventory drifted: {record.get('name')}")
    kind = record.get("kind")
    generation_width = record.get("generation_width")
    require(generation_width in {1, 4},
            f"V14G generation width is invalid: {record.get('name')}")
    if kind == "baseline":
        require(record.get("mutation") is None, "baseline names a mutation")
        require(record.get("expected_stage") is None,
                "baseline names a failure stage")
        require(record.get("oracle_stages") == [],
                "baseline reported an oracle failure stage")
        require(record.get("sim_rc") == 0,
                f"V14G baseline simulation failed: {record.get('name')}")
        require(markers.get(ORACLE_FAIL) == 0,
                f"V14G baseline hit the oracle: {record.get('name')}")
        require(all(markers.get(marker) == 1 for marker in BASELINE_MARKERS),
                f"V14G baseline markers are incomplete: {record.get('name')}")
        expected_name = (
            f"gen{generation_width}-production-"
            f"{'assert' if record.get('assertions') is True else 'release'}"
        )
        require(record.get("assertions") in {True, False},
                "baseline assertion mode is invalid")
    elif kind == "mutation":
        mutation = record.get("mutation")
        stage = EXPECTED_MUTATIONS.get(mutation)
        require(stage is not None, f"unknown V14G mutation: {mutation}")
        require(record.get("assertions") is False,
                f"V14G mutation is not release-mode: {mutation}")
        require(record.get("expected_stage") == stage,
                f"V14G expected stage drifted: {mutation}")
        require(record.get("oracle_stages") == [stage],
                f"V14G observed stage drifted: {mutation}")
        require(isinstance(record.get("sim_rc"), int)
                and record["sim_rc"] != 0,
                f"V14G mutation was not rejected: {mutation}")
        require(markers.get(ORACLE_FAIL) == 1,
                f"V14G mutation lacks the exact oracle marker: {mutation}")
        require(markers.get(GLOBAL_PASS) == 0 and markers.get(TB_PASS) == 0,
                f"V14G mutation leaked a PASS marker: {mutation}")
        expected_name = f"gen{generation_width}-{mutation}-release"
    else:
        raise ClosureError(f"unknown V14G profile kind: {kind}")
    require(record.get("name") == expected_name,
            f"V14G profile name drifted: {record.get('name')}")
    return {
        "name": record["name"],
        "kind": kind,
        "generation_width": generation_width,
        "assertions": record["assertions"],
        "mutation": record.get("mutation"),
        "expected_stage": record.get("expected_stage"),
        "oracle_stages": record.get("oracle_stages"),
        "compile_command_sha256": record["compile_command_sha256"],
        "artifact_sha256": record["artifact_sha256"],
        "sim_rc": record["sim_rc"],
        "marker_counts": markers,
        "log": profile_log(root, record, archive_dir),
    }


def capture_v14g(
    root: pathlib.Path,
    result_dir: pathlib.Path,
    expected_design_id: str,
    log_archive_dir: pathlib.Path | None = None,
) -> dict[str, Any]:
    summary_path = result_dir / "summary.json"
    source_path = result_dir / "source-manifest.json"
    overlay_path = result_dir / "overlay-manifest.json"
    mutation_path = result_dir / "mutation-manifest.json"
    status_path = result_dir / "status"
    summary = load_json(summary_path)
    source_manifest = load_json(source_path)
    overlay = load_json(overlay_path)
    mutation_manifest = load_json(mutation_path)
    require(status_path.read_text(encoding="utf-8").strip() == "PASS",
            "V14G terminal status is not PASS")
    require(summary.get("schema") == V14G_SCHEMA,
            "V14G summary schema mismatch")
    require(summary.get("result") == "PASS", "V14G result is not PASS")
    require(summary.get("design_id_pre") == expected_design_id
            and summary.get("design_id_post") == expected_design_id,
            "V14G design identity is not current")
    source_digest = manifest_digest(source_manifest)
    require(summary.get("source_manifest_sha256_pre") == source_digest
            and summary.get("source_manifest_sha256_post") == source_digest,
            "V14G source manifest pre/post binding drifted")
    require(summary.get("generation_widths") == [4, 1],
            "V14G generation-width inventory drifted")
    require(summary.get("baseline_profiles_pass") == 4
            and summary.get("baseline_profiles_total") == 4,
            "V14G baseline count is not 4/4")
    require(summary.get("compile_success_mutations_rejected") == 22
            and summary.get("compile_success_mutations_total") == 22,
            "V14G mutation count is not 22/22")
    require(summary.get("intermediate_products_retained") == 0,
            "V14G retained a regenerable compile product")
    semantic = summary.get("semantic_coverage")
    require(isinstance(semantic, dict)
            and semantic.get("rc") == 0
            and semantic.get("timeout") is False
            and valid_sha256(semantic.get("log_sha256"))
            and valid_sha256(semantic.get("ledger_sha256")),
            "V14G semantic-ledger preflight did not complete")
    semantic_log = resolve_repo_path(root, semantic["log"])
    require(semantic_log.is_file()
            and sha256_file(semantic_log) == semantic["log_sha256"],
            "V14G semantic-ledger preflight log drifted")
    semantic_ledger_path = resolve_repo_path(root, semantic["ledger"])
    require(semantic_ledger_path.is_file()
            and sha256_file(semantic_ledger_path)
            == semantic["ledger_sha256"],
            "V14G local semantic-ledger artifact drifted")
    semantic_ledger = load_json(semantic_ledger_path)
    semantic_counts = semantic_ledger.get("counts")
    require(semantic_ledger.get("status") == "LOCAL_PASS"
            and semantic_ledger.get("design_id") == expected_design_id
            and isinstance(semantic_counts, dict)
            and semantic_counts.get("semantic_units") == 46
            and semantic_counts.get("unit_instance_bindings") == 52
            and semantic_counts.get("units_semantic_pass") == 46
            and semantic_counts.get("units_semantic_gap") == 0,
            "V14G local semantic-ledger preflight is incomplete")

    profiles = summary.get("profiles")
    require(isinstance(profiles, list) and len(profiles) == 26,
            "V14G profile inventory is not 26")
    normalized = [
        normalized_profile(root, item, log_archive_dir) for item in profiles
    ]
    baselines = [item for item in normalized if item["kind"] == "baseline"]
    mutations = [item for item in normalized if item["kind"] == "mutation"]
    require(
        {(item["generation_width"], item["assertions"])
         for item in baselines} == {(1, False), (1, True), (4, False), (4, True)},
        "V14G baseline matrix is incomplete",
    )
    require(
        {(item["generation_width"], item["mutation"])
         for item in mutations}
        == {(width, name) for width in (1, 4) for name in EXPECTED_MUTATIONS},
        "V14G mutation matrix is incomplete",
    )

    bindings = normalize_source_bindings(root, source_manifest)
    binding_map = {item["path"]: item["sha256"] for item in bindings}
    require(overlay.get("base") in binding_map
            and overlay.get("base_sha256") == binding_map[overlay["base"]],
            "V14G base testbench overlay binding drifted")
    require(overlay.get("overlay") in binding_map
            and overlay.get("overlay_sha256")
            == binding_map[overlay["overlay"]],
            "V14G overlay source binding drifted")
    require(overlay.get("generated_is_intermediate") is True,
            "V14G generated testbench retention class drifted")
    receipts = overlay.get("receipts")
    require(isinstance(receipts, list) and len(receipts) == 3,
            "V14G overlay anchor receipt count drifted")
    for record in receipts:
        require(record.get("anchor_count") == 1
                and valid_sha256(record.get("anchor_sha256"))
                and valid_sha256(record.get("replacement_sha256")),
                "V14G overlay anchor receipt is invalid")
    require(isinstance(mutation_manifest, list)
            and len(mutation_manifest) == len(EXPECTED_MUTATIONS),
            "V14G mutation manifest count drifted")
    manifest_names = {item.get("name") for item in mutation_manifest}
    require(manifest_names == set(EXPECTED_MUTATIONS),
            "V14G mutation manifest names drifted")
    for record in mutation_manifest:
        name = record["name"]
        target = record.get("target")
        require(record.get("expected_stage") == EXPECTED_MUTATIONS[name],
                f"V14G mutation manifest stage drifted: {name}")
        require(record.get("compile_success_required") is True
                and record.get("anchor_count") == 1,
                f"V14G mutation manifest contract weakened: {name}")
        require(isinstance(target, str) and target in binding_map,
                f"V14G mutation target is outside the source binding: {name}")
        require(record.get("production_sha256") == binding_map[target],
                f"V14G mutation production binding drifted: {name}")
        for key in (
            "anchor_sha256", "replacement_sha256", "variant_sha256",
            "mutated_source_sha256",
        ):
            require(valid_sha256(record.get(key)),
                    f"V14G mutation {key} is invalid: {name}")
        require(record.get("variant_sha256")
                == record.get("mutated_source_sha256"),
                f"V14G mutation variant digest drifted: {name}")

    tools = summary.get("tools")
    require(isinstance(tools, dict) and set(tools) == {"iverilog", "vvp"},
            "V14G simulator inventory drifted")
    normalized_tools: dict[str, Any] = {}
    for name, record in tools.items():
        require(isinstance(record, dict) and valid_sha256(record.get("sha256")),
                f"V14G simulator record is invalid: {name}")
        path = pathlib.Path(record.get("path", ""))
        require(path.is_absolute() and path.is_file(),
                f"V14G simulator is unavailable: {name}")
        require(sha256_file(path) == record["sha256"],
                f"V14G simulator binary drifted: {name}")
        normalized_tools[name] = {
            "path": str(path),
            "sha256": record["sha256"],
            "version": record.get("version"),
        }

    return {
        "schema": V14G_SCHEMA,
        "status": "PASS",
        "design_id": expected_design_id,
        "generation_widths": [1, 4],
        "baseline_profiles_pass": 4,
        "compile_success_mutations_rejected": 22,
        "intermediate_products_retained": 0,
        "source_manifest_digest": source_digest,
        "source_bindings": bindings,
        "overlay": overlay,
        "mutation_manifest": sorted(
            mutation_manifest, key=lambda item: item["name"]
        ),
        "baselines": sorted(baselines, key=lambda item: item["name"]),
        "mutations": sorted(mutations, key=lambda item: item["name"]),
        "semantic_preflight": {
            "rc": 0,
            "timeout": False,
            "log": artifact(root, semantic_log, "semantic-local-preflight-log"),
            "ledger": artifact(
                root,
                semantic_ledger_path,
                "semantic-local-preflight-ledger",
            ),
        },
        "tools": normalized_tools,
        "origin": {
            "result_dir": display_path(root, result_dir),
            "artifacts": [
                artifact(root, summary_path, "v14g-summary"),
                artifact(root, source_path, "v14g-source-manifest"),
                artifact(root, overlay_path, "v14g-overlay-manifest"),
                artifact(root, mutation_path, "v14g-mutation-manifest"),
                artifact(root, status_path, "v14g-terminal-status"),
            ],
        },
    }


def module_matches(name: str, base: str) -> bool:
    return name == base or re.search(
        rf"(?:^|\\){re.escape(base)}(?:\\|$)", name
    ) is not None


def unique_module(modules: dict[str, Any], base: str) -> tuple[str, dict[str, Any]]:
    matches = [(name, value) for name, value in modules.items()
               if module_matches(name, base)]
    require(len(matches) == 1,
            f"expected one elaborated {base}, found {len(matches)}")
    return matches[0]


def port_bits(module: dict[str, Any], port: str, direction: str) -> list[Any]:
    record = module.get("ports", {}).get(port)
    require(isinstance(record, dict) and record.get("direction") == direction,
            f"elaborated port missing or wrong direction: {port}")
    bits = record.get("bits")
    require(isinstance(bits, list) and len(bits) == 1,
            f"elaborated port is not one bit: {port}")
    return bits


def cell_port(
    module: dict[str, Any], cell: str, port: str, child: str
) -> tuple[str, list[Any]]:
    record = module.get("cells", {}).get(cell)
    require(isinstance(record, dict), f"elaborated cell is missing: {cell}")
    child_type = record.get("type")
    require(isinstance(child_type, str) and module_matches(child_type, child),
            f"elaborated child type drifted: {cell}")
    bits = record.get("connections", {}).get(port)
    require(isinstance(bits, list) and len(bits) == 1,
            f"elaborated child port is not one bit: {cell}.{port}")
    return child_type, bits


@functools.lru_cache(maxsize=2)
def load_yosys_json_cached(
    path_text: str, size_bytes: int, mtime_ns: int
) -> tuple[dict[str, Any], str]:
    del size_bytes, mtime_ns
    path = pathlib.Path(path_text)
    digest = hashlib.sha256()
    payload = bytearray()
    with gzip.open(path, "rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
            payload.extend(chunk)
    try:
        value = json.loads(payload.decode("utf-8"))
    except (UnicodeError, json.JSONDecodeError) as exc:
        raise ClosureError(f"invalid full Yosys JSON: {exc}") from exc
    require(isinstance(value, dict), "full Yosys JSON is not an object")
    return value, digest.hexdigest()


def load_yosys_json(path: pathlib.Path) -> tuple[dict[str, Any], str]:
    stat = path.stat()
    return load_yosys_json_cached(str(path), stat.st_size, stat.st_mtime_ns)


def optional_chain_from_yosys(payload: dict[str, Any]) -> list[dict[str, Any]]:
    modules = payload.get("modules")
    require(isinstance(modules, dict), "full Yosys JSON lacks modules")
    names: dict[str, str] = {}
    values: dict[str, dict[str, Any]] = {}
    for base in (
        "OooBranchAppendDispatchGate", "OooFrontend", "OooCoreTopGlue",
        "OooExecuteBackend", "OooAluCoreSlice", "OooAluDecodeBackend",
        "OooIntBackend", "OooDispatchBackend", "OooIntIssueQueue",
    ):
        names[base], values[base] = unique_module(modules, base)

    branch_bits = port_bits(
        values["OooBranchAppendDispatchGate"],
        "dispatch1_optional_o", "output",
    )
    require(branch_bits == ["0"],
            "dispatch1_optional_o is not elaborated constant zero")
    rows: list[dict[str, Any]] = [{
        "module": "OooBranchAppendDispatchGate",
        "elaborated_type": names["OooBranchAppendDispatchGate"],
        "port": "dispatch1_optional_o",
        "bits": branch_bits,
        "role": "constant_source",
    }]

    def through(
        parent: str,
        parent_port: str | None,
        parent_direction: str | None,
        cell: str,
        child: str,
        child_port_name: str,
    ) -> list[Any]:
        child_type, bits = cell_port(
            values[parent], cell, child_port_name, child
        )
        if parent_port is not None and parent_direction is not None:
            require(port_bits(values[parent], parent_port, parent_direction) == bits,
                    f"{parent} does not forward {parent_port} to {cell}")
        rows.append({
            "module": parent,
            "elaborated_type": names[parent],
            "port": parent_port,
            "cell": cell,
            "child_module": child,
            "child_elaborated_type": child_type,
            "child_port": child_port_name,
            "bits": bits,
            "role": "hierarchical_forward",
        })
        return bits

    through("OooFrontend", "dispatch1_optional_w", "output",
            "u_branch_append_dispatch_gate", "OooBranchAppendDispatchGate",
            "dispatch1_optional_o")
    frontend_type, frontend_bits = cell_port(
        values["OooCoreTopGlue"], "u_frontend",
        "dispatch1_optional_w", "OooFrontend"
    )
    execute_type, execute_bits = cell_port(
        values["OooCoreTopGlue"], "u_execute_backend",
        "dispatch1_optional_w", "OooExecuteBackend"
    )
    require(frontend_bits == execute_bits,
            "OooCoreTopGlue optional lane1 connection is not point-to-point")
    rows.append({
        "module": "OooCoreTopGlue",
        "elaborated_type": names["OooCoreTopGlue"],
        "producer_cell": "u_frontend",
        "producer_child_elaborated_type": frontend_type,
        "consumer_cell": "u_execute_backend",
        "consumer_child_elaborated_type": execute_type,
        "port": "dispatch1_optional_w",
        "bits": frontend_bits,
        "role": "product_top_connection",
    })
    through("OooExecuteBackend", "dispatch1_optional_w", "input",
            "u_core_slice", "OooAluCoreSlice", "dispatch1_optional_i")
    through("OooAluCoreSlice", "dispatch1_optional_i", "input",
            "u_decode_backend", "OooAluDecodeBackend",
            "dispatch1_optional_i")
    through("OooAluDecodeBackend", "dispatch1_optional_i", "input",
            "u_int_backend", "OooIntBackend", "dispatch1_optional_i")
    through("OooIntBackend", "dispatch1_optional_i", "input",
            "u_dispatch_backend", "OooDispatchBackend",
            "dispatch1_optional_i")
    through("OooDispatchBackend", "dispatch1_optional_i", "input",
            "u_issue_queue", "OooIntIssueQueue", "dispatch1_optional_i")
    port_bits(values["OooIntIssueQueue"], "dispatch1_optional_i", "input")
    rows.append({
        "module": "OooIntIssueQueue",
        "elaborated_type": names["OooIntIssueQueue"],
        "port": "dispatch1_optional_i",
        "bits": port_bits(
            values["OooIntIssueQueue"], "dispatch1_optional_i", "input"
        ),
        "role": "terminal_consumer",
    })
    return rows


def capture_optional_product(
    root: pathlib.Path,
    yosys_json_path: pathlib.Path,
    yosys_receipt_path: pathlib.Path,
    expected_design_id: str,
) -> dict[str, Any]:
    require(yosys_json_path.is_file(), "full product Yosys JSON is missing")
    receipt = load_json(yosys_receipt_path)
    require(receipt.get("schema_version") == YOSYS_RECEIPT_SCHEMA,
            "product Yosys receipt schema mismatch")
    require(receipt.get("status") == "PASS"
            and receipt.get("top_module") == "NpcTop",
            "product Yosys receipt is not NpcTop PASS")
    require(receipt.get("design_id") == expected_design_id,
            "product Yosys receipt design identity is stale")
    payload, decompressed_sha = load_yosys_json(yosys_json_path)
    require(receipt.get("full_yosys_json_sha256") == decompressed_sha,
            "full product Yosys JSON digest drifted")
    source_list = receipt.get("source_list")
    require(isinstance(source_list, list),
            "product Yosys receipt source list is absent")
    sources = {item.get("path"): item.get("sha256") for item in source_list
               if isinstance(item, dict)}
    selected_sources: list[dict[str, str]] = []
    for path in OPTIONAL_SOURCE_PATHS:
        source = resolve_repo_path(root, path)
        digest = sha256_file(source)
        require(sources.get(path) == digest,
                f"optional lane1 product source drifted: {path}")
        selected_sources.append({"path": path, "sha256": digest})
    return {
        "status": "PASS",
        "design_id": expected_design_id,
        "configuration": "PRODUCT_INACTIVE_CONSTANT_LOW",
        "constant_value": 0,
        "source_bindings": selected_sources,
        "yosys_json": {
            **artifact(root, yosys_json_path, "full-yosys-json-gzip"),
            "decompressed_sha256": decompressed_sha,
        },
        "yosys_receipt": artifact(
            root, yosys_receipt_path, "yosys-instance-graph-receipt"
        ),
        "chain": optional_chain_from_yosys(payload),
    }


def stable_digest(values: Iterable[str]) -> str:
    return sha256_bytes("\n".join(sorted(values)).encode("utf-8"))


def normalize_selected_bindings(
    bindings: Any, evidence_id: str
) -> list[dict[str, Any]]:
    require(isinstance(bindings, list) and bindings,
            f"support evidence has no source bindings: {evidence_id}")
    result: list[dict[str, Any]] = []
    for record in bindings:
        require(isinstance(record, dict),
                f"support source binding is malformed: {evidence_id}")
        exact = record.get("matches_live") is True
        macro_projected = record.get("semantic_projection_match") is True
        rtl_delta_projected = (
            record.get("rtl_delta_projection_match") is True
        )
        require(exact or macro_projected or rtl_delta_projected,
                f"support source binding is stale: {evidence_id}")
        require(valid_sha256(record.get("evidence_sha256"))
                and valid_sha256(record.get("live_sha256")),
                f"support source digest is invalid: {evidence_id}")
        binding = "EXACT"
        if macro_projected:
            binding = "SEMANTIC_MACRO_PROJECTION"
        elif rtl_delta_projected:
            binding = "REVERSIBLE_RTL_DELTA_PROJECTION"
        result.append({
            "path": record.get("path"),
            "role": record.get("role"),
            "evidence_sha256": record["evidence_sha256"],
            "live_sha256": record["live_sha256"],
            "binding": binding,
        })
    return sorted(result, key=lambda item: (str(item["path"]), str(item["role"])))


def normalize_semantic_support(
    ledger: dict[str, Any], expected_design_id: str
) -> dict[str, Any]:
    counts = ledger.get("counts")
    require(isinstance(counts, dict), "semantic ledger counts are absent")
    expected_counts = {
        "semantic_units": 46,
        "holder_instances": 17,
        "unit_instance_bindings": 52,
        "units_semantic_pass": 46,
        "units_semantic_gap": 0,
        "ledger_only_units": 0,
    }
    for key, expected in expected_counts.items():
        require(counts.get(key) == expected,
                f"semantic ledger count drifted: {key}")
    units = ledger.get("units")
    require(isinstance(units, list) and len(units) == 46,
            "semantic unit inventory is not 46")
    unit_ids: list[str] = []
    for unit in units:
        require(isinstance(unit, dict)
                and unit.get("semantic_status") == "PASS"
                and unit.get("gap_classifications") == [],
                f"semantic unit is not closed: {unit.get('id') if isinstance(unit, dict) else '?'}")
        require(isinstance(unit.get("id"), str), "semantic unit id is invalid")
        unit_ids.append(unit["id"])
    require(len(set(unit_ids)) == 46, "semantic unit IDs are not unique")

    evidence_sets = ledger.get("evidence_sets")
    require(isinstance(evidence_sets, list), "semantic evidence inventory is absent")
    by_id = {item.get("id"): item for item in evidence_sets
             if isinstance(item, dict)}
    require(set(SUPPORT_REQUIREMENTS).issubset(by_id),
            "required global support evidence is missing")
    normalized: list[dict[str, Any]] = []
    for evidence_id, requirement in SUPPORT_REQUIREMENTS.items():
        record = by_id[evidence_id]
        require(record.get("scope") == "COMPLETE"
                and record.get("semantic_closure") is True
                and record.get("gap_classifications") == [],
                f"support evidence is not complete: {evidence_id}")
        require(record.get("binding_state") == requirement["binding_state"],
                f"support evidence binding state drifted: {evidence_id}")
        detail = record.get("detail")
        require(isinstance(detail, dict),
                f"support evidence detail is absent: {evidence_id}")
        require(detail.get("current_design_id") == expected_design_id,
                f"support evidence current design drifted: {evidence_id}")
        selected: dict[str, Any] = {}
        for key, expected in requirement["detail"].items():
            require(detail.get(key) == expected,
                    f"support evidence field drifted: {evidence_id}.{key}")
            selected[key] = expected
        if evidence_id == "v14r-memory-request-hold-current-closure":
            require(detail.get("evidence_design_id") == expected_design_id,
                    "V14R product evidence is not current-design bound")
        normalized.append({
            "id": evidence_id,
            "binding_state": record["binding_state"],
            "instance_paths": record.get("instance_paths"),
            "detail": selected,
            "source_bindings": normalize_selected_bindings(
                detail.get("selected_bindings"), evidence_id
            ),
        })
    return {
        "status": "PASS",
        "design_id": expected_design_id,
        "counts": expected_counts,
        "unit_ids_sha256": stable_digest(unit_ids),
        "required_evidence": sorted(normalized, key=lambda item: item["id"]),
    }


def validate_v14g_snapshot(
    root: pathlib.Path, snapshot: dict[str, Any], expected_design_id: str
) -> None:
    require(snapshot.get("schema") == V14G_SCHEMA
            and snapshot.get("status") == "PASS",
            "V14G compact snapshot schema/status mismatch")
    require(snapshot.get("design_id") == expected_design_id,
            "V14G compact snapshot design identity drifted")
    require(snapshot.get("generation_widths") == [1, 4]
            and snapshot.get("baseline_profiles_pass") == 4
            and snapshot.get("compile_success_mutations_rejected") == 22
            and snapshot.get("intermediate_products_retained") == 0,
            "V14G compact snapshot counts drifted")
    preflight = snapshot.get("semantic_preflight")
    require(isinstance(preflight, dict)
            and set(preflight) == {"rc", "timeout", "log", "ledger"}
            and preflight.get("rc") == 0
            and preflight.get("timeout") is False,
            "V14G local semantic preflight receipt is invalid")
    for key, kind in (
        ("log", "semantic-local-preflight-log"),
        ("ledger", "semantic-local-preflight-ledger"),
    ):
        record = preflight.get(key)
        require(isinstance(record, dict)
                and record.get("kind") == kind,
                f"V14G {key} artifact record is invalid")
        path = resolve_repo_path(root, record.get("path", ""))
        require(record == artifact(root, path, kind),
                f"V14G {key} artifact drifted")
    preflight_ledger = load_json(
        resolve_repo_path(root, preflight["ledger"]["path"])
    )
    preflight_counts = preflight_ledger.get("counts")
    require(preflight_ledger.get("status") == "LOCAL_PASS"
            and preflight_ledger.get("design_id") == expected_design_id
            and isinstance(preflight_counts, dict)
            and preflight_counts.get("semantic_units") == 46
            and preflight_counts.get("unit_instance_bindings") == 52
            and preflight_counts.get("units_semantic_pass") == 46
            and preflight_counts.get("units_semantic_gap") == 0,
            "V14G local semantic preflight ledger drifted")
    bindings = snapshot.get("source_bindings")
    require(isinstance(bindings, list) and bindings,
            "V14G compact source bindings are absent")
    for record in bindings:
        require(isinstance(record, dict)
                and valid_sha256(record.get("sha256"))
                and isinstance(record.get("current_required"), bool),
                "V14G compact source binding is malformed")
        if record["current_required"]:
            path = resolve_repo_path(root, record["path"])
            require(path.is_file() and sha256_file(path) == record["sha256"],
                    f"V14G current source binding drifted: {record['path']}")
    manifest_map = {item["path"]: item["sha256"] for item in bindings}
    require(manifest_digest(manifest_map) == snapshot.get("source_manifest_digest"),
            "V14G compact source manifest digest drifted")
    baselines = snapshot.get("baselines")
    mutations = snapshot.get("mutations")
    require(isinstance(baselines, list) and len(baselines) == 4,
            "V14G compact baseline matrix is incomplete")
    require(isinstance(mutations, list) and len(mutations) == 22,
            "V14G compact mutation matrix is incomplete")
    require({(item.get("generation_width"), item.get("assertions"))
             for item in baselines}
            == {(1, False), (1, True), (4, False), (4, True)},
            "V14G compact baseline modes drifted")
    for item in [*baselines, *mutations]:
        log = item.get("log")
        require(valid_sha256(item.get("compile_command_sha256"))
                and valid_sha256(item.get("artifact_sha256")),
                f"V14G compact compile artifact binding drifted: {item.get('name')}")
        require(isinstance(log, dict)
                and isinstance(log.get("origin_path"), str)
                and valid_sha256(log.get("sha256"))
                and isinstance(log.get("size_bytes"), int)
                and log["size_bytes"] > 0,
                f"V14G compact log binding drifted: {item.get('name')}")
        log_path = resolve_repo_path(root, log["origin_path"])
        require(log_path.is_file(),
                f"V14G compact log is missing: {log['origin_path']}")
        require(log_path.stat().st_size == log["size_bytes"],
                f"V14G compact log size drifted: {log['origin_path']}")
        require(sha256_file(log_path) == log["sha256"],
                f"V14G compact log digest drifted: {log['origin_path']}")
    for item in baselines:
        markers = item.get("marker_counts")
        require(item.get("kind") == "baseline"
                and item.get("sim_rc") == 0
                and item.get("oracle_stages") == [],
                "V14G compact baseline result drifted")
        require(isinstance(markers, dict)
                and markers.get(ORACLE_FAIL) == 0
                and all(markers.get(marker) == 1
                        for marker in BASELINE_MARKERS),
                "V14G compact baseline markers drifted")
    require({(item.get("generation_width"), item.get("mutation"))
             for item in mutations}
            == {(width, name) for width in (1, 4)
                for name in EXPECTED_MUTATIONS},
            "V14G compact mutation modes drifted")
    for item in mutations:
        mutation = item.get("mutation")
        markers = item.get("marker_counts")
        stage = EXPECTED_MUTATIONS.get(mutation)
        require(item.get("kind") == "mutation"
                and item.get("assertions") is False
                and item.get("expected_stage") == stage
                and item.get("oracle_stages") == [stage]
                and isinstance(item.get("sim_rc"), int)
                and item["sim_rc"] != 0,
                f"V14G compact mutation result drifted: {mutation}")
        require(isinstance(markers, dict)
                and markers.get(ORACLE_FAIL) == 1
                and markers.get(GLOBAL_PASS) == 0
                and markers.get(TB_PASS) == 0,
                f"V14G compact mutation markers drifted: {mutation}")
    mutation_manifest = snapshot.get("mutation_manifest")
    require(isinstance(mutation_manifest, list)
            and {item.get("name") for item in mutation_manifest}
            == set(EXPECTED_MUTATIONS),
            "V14G compact mutation manifest drifted")
    for item in mutation_manifest:
        name = item["name"]
        require(item.get("expected_stage") == EXPECTED_MUTATIONS[name]
                and item.get("compile_success_required") is True
                and item.get("anchor_count") == 1
                and manifest_map.get(item.get("target"))
                == item.get("production_sha256"),
                f"V14G compact mutation contract drifted: {name}")
    tools = snapshot.get("tools")
    require(isinstance(tools, dict) and set(tools) == {"iverilog", "vvp"},
            "V14G compact simulator inventory drifted")
    for name, record in tools.items():
        path = pathlib.Path(record.get("path", ""))
        require(path.is_absolute() and path.is_file()
                and valid_sha256(record.get("sha256"))
                and sha256_file(path) == record["sha256"],
                f"V14G current simulator identity drifted: {name}")


def build_receipt(
    root: pathlib.Path,
    v14g_result: pathlib.Path,
    semantic_ledger: dict[str, Any],
    yosys_json: pathlib.Path,
    yosys_receipt: pathlib.Path,
    log_archive_dir: pathlib.Path | None = None,
) -> dict[str, Any]:
    design_id = current_design_id(root)
    require(DESIGN_ID_RE.fullmatch(design_id) is not None,
            "current RTL design identity is invalid")
    require(semantic_ledger.get("design_id") == design_id,
            "semantic ledger is not current-design bound")
    return {
        "schema_version": SCHEMA,
        "status": "PASS",
        "classification": "architecture",
        "design_id": design_id,
        "production_rtl_change": True,
        "claim_boundary": CLAIM_BOUNDARY,
        "promotion": EXPECTED_PROMOTION,
        "semantic_support": normalize_semantic_support(
            semantic_ledger, design_id
        ),
        "v14g_dynamic_fence": capture_v14g(
            root, v14g_result, design_id, log_archive_dir
        ),
        "optional_lane1_product_binding": capture_optional_product(
            root, yosys_json, yosys_receipt, design_id
        ),
        "reuse_boundary": {
            "requires_current_rtl_design_id": True,
            "requires_current_v14g_executable_inputs": True,
            "requires_current_simulator_binaries": True,
            "requires_current_product_elaboration_artifact": True,
            "documentation_or_make_orchestration_drift_requires_rerun": False,
            "system_rerun_required_before_system_promotion": True,
        },
    }


def validate_receipt_data(
    root: pathlib.Path,
    receipt: dict[str, Any],
    semantic_ledger: dict[str, Any],
    expected_design_id: str,
) -> dict[str, Any]:
    require(set(receipt) == {
        "schema_version", "status", "classification", "design_id",
        "production_rtl_change", "claim_boundary", "promotion",
        "semantic_support", "v14g_dynamic_fence",
        "optional_lane1_product_binding", "reuse_boundary",
    }, "global owner receipt field inventory drifted")
    require(receipt.get("schema_version") == SCHEMA,
            "global owner receipt schema mismatch")
    require(receipt.get("status") == "PASS"
            and receipt.get("classification") == "architecture",
            "global owner receipt is not an architecture PASS")
    require(receipt.get("design_id") == expected_design_id,
            "global owner receipt design identity drifted")
    require(receipt.get("production_rtl_change") is True,
            "global owner receipt misclassifies production RTL change")
    require(receipt.get("claim_boundary") == CLAIM_BOUNDARY,
            "global owner receipt claim boundary drifted")
    require(receipt.get("promotion") == EXPECTED_PROMOTION,
            "global owner receipt promotion boundary drifted")
    expected_reuse = {
        "requires_current_rtl_design_id": True,
        "requires_current_v14g_executable_inputs": True,
        "requires_current_simulator_binaries": True,
        "requires_current_product_elaboration_artifact": True,
        "documentation_or_make_orchestration_drift_requires_rerun": False,
        "system_rerun_required_before_system_promotion": True,
    }
    require(receipt.get("reuse_boundary") == expected_reuse,
            "global owner evidence reuse boundary drifted")
    expected_support = normalize_semantic_support(
        semantic_ledger, expected_design_id
    )
    require(receipt.get("semantic_support") == expected_support,
            "global owner semantic support snapshot drifted")
    dynamic = receipt.get("v14g_dynamic_fence")
    require(isinstance(dynamic, dict), "V14G compact snapshot is absent")
    validate_v14g_snapshot(root, dynamic, expected_design_id)
    product = receipt.get("optional_lane1_product_binding")
    require(isinstance(product, dict),
            "optional lane1 product binding is absent")
    json_record = product.get("yosys_json")
    receipt_record = product.get("yosys_receipt")
    require(isinstance(json_record, dict) and isinstance(receipt_record, dict),
            "optional lane1 Yosys artifact binding is malformed")
    expected_product = capture_optional_product(
        root,
        resolve_repo_path(root, json_record.get("path", "")),
        resolve_repo_path(root, receipt_record.get("path", "")),
        expected_design_id,
    )
    require(product == expected_product,
            "optional lane1 product binding drifted")
    return {
        "status": "PASS",
        "design_id": expected_design_id,
        "semantic_units": 46,
        "unit_instance_bindings": 52,
        "v14g_baselines": 4,
        "v14g_compile_success_mutations_rejected": 22,
        "optional_lane1_product_configuration":
            "PRODUCT_INACTIVE_CONSTANT_LOW",
        "global_no_live_reuse": "GREEN",
        "whole_architecture": "RED",
        "system_recertification": "REQUIRED",
        "ppa": "UNPROMOTED",
    }


def validate_receipt(
    root: pathlib.Path,
    receipt_path: pathlib.Path,
    semantic_ledger: dict[str, Any],
    expected_design_id: str,
) -> dict[str, Any]:
    receipt = load_json(receipt_path)
    require(isinstance(receipt, dict), "global owner receipt is not an object")
    result = validate_receipt_data(
        root, receipt, semantic_ledger, expected_design_id
    )
    result["receipt"] = artifact(
        root, receipt_path, "global-producer-no-live-reuse-receipt"
    )
    return result


def write_json(path: pathlib.Path, payload: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(
        json.dumps(payload, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )


def parser() -> argparse.ArgumentParser:
    result = argparse.ArgumentParser(description=__doc__)
    result.add_argument(
        "--root", type=pathlib.Path,
        default=pathlib.Path(__file__).resolve().parents[5],
    )
    result.add_argument("--semantic-ledger", default=DEFAULT_LEDGER)
    sub = result.add_subparsers(dest="command", required=True)
    capture = sub.add_parser("capture")
    capture.add_argument("--v14g-result", default=DEFAULT_V14G_RESULT)
    capture.add_argument("--yosys-json", default=DEFAULT_YOSYS_JSON)
    capture.add_argument("--yosys-receipt", default=DEFAULT_YOSYS_RECEIPT)
    capture.add_argument("--output", default=DEFAULT_RECEIPT)
    capture.add_argument(
        "--log-archive-dir",
        help="copy retained baseline/mutation transcripts into this task-run directory",
    )
    verify = sub.add_parser("verify")
    verify.add_argument("--input", default=DEFAULT_RECEIPT)
    return result


def main(argv: list[str] | None = None) -> int:
    args = parser().parse_args(argv)
    root = args.root.resolve()
    ledger_path = resolve_repo_path(root, args.semantic_ledger)
    ledger = load_json(ledger_path)
    require(isinstance(ledger, dict), "semantic ledger is not an object")
    design_id = current_design_id(root)
    require(ledger.get("design_id") == design_id,
            "semantic ledger is not current-design bound")
    if args.command == "capture":
        output = resolve_repo_path(root, args.output)
        receipt = build_receipt(
            root,
            resolve_repo_path(root, args.v14g_result),
            ledger,
            resolve_repo_path(root, args.yosys_json),
            resolve_repo_path(root, args.yosys_receipt),
            resolve_repo_path(root, args.log_archive_dir)
            if args.log_archive_dir else None,
        )
        write_json(output, receipt)
        result = validate_receipt_data(root, receipt, ledger, design_id)
    else:
        result = validate_receipt(
            root, resolve_repo_path(root, args.input), ledger, design_id
        )
    print(
        "[GLOBAL-PRODUCER-NO-LIVE-REUSE][PASS] "
        f"design_id={design_id} units={result['semantic_units']} "
        f"bindings={result['unit_instance_bindings']} "
        f"v14g={result['v14g_baselines']}/4 "
        "mutations=22/22 optional_lane1=product-constant-0 "
        "whole_architecture=RED system=REQUIRED ppa=UNPROMOTED"
    )
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except ClosureError as exc:
        print(f"[GLOBAL-PRODUCER-NO-LIVE-REUSE][FAIL] {exc}", file=sys.stderr)
        raise SystemExit(1)
