#!/usr/bin/env python3
"""闭合 serialized drain 的 owner-lifetime GAP，并定义一个有身份的可回退 RTL 实验。"""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import pathlib
import re
import sys
import tempfile
from typing import Any


TOOLS_DIR = pathlib.Path(__file__).resolve().parent
if str(TOOLS_DIR) not in sys.path:
    sys.path.insert(0, str(TOOLS_DIR))

import current_timing_path_analysis as current_timing  # noqa: E402


REPO_ROOT = pathlib.Path(__file__).resolve().parents[5]
SCHEMA = "npc-rv64-serialized-drain-owner-lifetime-analysis-v1"
STATUS = "TRACEABLE_SERIALIZED_OWNER_PERMIT_CANDIDATE_DEFINED"
CANDIDATE_ID = "serialized-owner-terminal-permit-v2"
REJECTED_CANDIDATE_ID = current_timing.REJECTED_CANDIDATE_ID
NEXT_ACTION = "experiment.serialized-owner-terminal-permit"
CLOSURE_MARKER = (
    "[V16A-SERIALIZED-DRAIN-OWNER-LIFETIME-CLOSURE]"
    "[CANDIDATE_DEFINED]"
)
REVIEW_MARKER = "SERIALIZED-DRAIN-OWNER-LIFETIME-REVIEW GAP"

SOURCE_CONTRACTS: dict[str, tuple[tuple[str, str], ...]] = {
    "npc/rv64/vsrc/frontend/OooBackendDrainTracker.v": (
        ("force_drained_clear_boundary", "if (rst || force_drained_i)"),
        ("registered_empty_without_dispatch",
         "drained_q <= backend_empty_i && !dispatch_fire_i;"),
    ),
    "npc/rv64/vsrc/control/OooControlPlane.v": (
        ("system_arch_owner_onehot", "[V10A-SERIAL-OWNER-ONEHOT]"),
        ("exit_owner_onehot", "[V10D-SERIAL-EXIT-ONEHOT]"),
        ("arch_c1_clear", "[V10A-ARCH-C1-CLEAR]"),
        ("exit_c1_clear", "[V10D-EXIT-C1-CLEAR]"),
        ("rob_head_trap_priority", "[V10A-ARCH-REQUEST-PRIORITY]"),
    ),
    "npc/rv64/vsrc/control/OooCsrTrapRequestMux.v": (
        ("rob_head_exception_priority", "!core_commit_exception_trap_o"),
        ("pending_arch_requires_drain",
         "drained_pending_control_w && pending_arch_trap_i"),
    ),
    "npc/rv64/vsrc/control/OooPendingDispatchArbiter.v": (
        ("capture_requires_can_run",
         "!csr_trap_mem_valid_i && can_run_i && fifo_has_packet_i"),
        ("system_capture_uses_capture_base",
         "capture_base_w && csr_irq_pending_i"),
    ),
    "npc/rv64/vsrc/control/OooPendingDrainResolveGate.v": (
        ("raw_backend_drain_recheck", "assign backend_drained_o ="),
        ("fence_current_idle", "!pending_system_fence_i || mem_idle_i"),
        ("current_terminal_scalar", "mem_owner_terminalized_i;"),
        ("drain_uses_raw_backend", "stop_pending_i && backend_drained_o"),
    ),
    "npc/rv64/vsrc/control/OooPendingTrapExitSequencer.v": (
        ("exit_clear", "if (clear_exit_i)"),
        ("arch_clear", "if (clear_arch_i)"),
        ("exit_holder_q", "output reg pending_exit_o"),
        ("arch_holder_q", "output reg pending_arch_trap_o"),
    ),
    "npc/rv64/vsrc/control/OooTrapExitEventMux.v": (
        ("rob_head_trap_blocks_drain", "!csr_trap_mem_valid_i"),
        ("exit_requires_drain", "pending_exit_i;"),
        ("trap_before_exit", "!terminal_trap_w"),
    ),
    "npc/rv64/vsrc/execute/OooIntBackend.v": (
        ("same_edge_memory_birth", "wire v15r_mem_birth_any_w ="),
        ("birth_inhibits_terminal", "!v15r_mem_birth_any_w &&"),
        ("collector_pending_accounted", "v9y_pending_without_live_mask_w"),
        ("unterminalized_holder_accounted",
         "v9y_unterminalized_holder_mask_w"),
    ),
    "npc/rv64/vsrc/frontend/OooFrontendRunGate.v": (
        ("serialized_owner_in_stop_owner", "pending_arch_trap_i ||"),
        ("stop_owner_includes_system", "pending_system_i ||"),
        ("stop_owner_includes_exit", "pending_exit_i ||"),
        ("live_stop_blocks_run", "!stop_pending_busy_o &&"),
    ),
}


class EvidenceError(ValueError):
    """输入证据或候选边界不可信。"""


def require(condition: bool, message: str) -> None:
    if not condition:
        raise EvidenceError(message)


def relative(path: pathlib.Path) -> str:
    try:
        return path.resolve().relative_to(REPO_ROOT).as_posix()
    except ValueError:
        return str(path.resolve())


def resolve_workspace(raw: str | pathlib.Path) -> pathlib.Path:
    path = pathlib.Path(raw)
    if not path.is_absolute():
        path = REPO_ROOT / path
    resolved = path.resolve()
    try:
        resolved.relative_to(REPO_ROOT)
    except ValueError as error:
        raise EvidenceError(f"workspace path escapes repository: {raw}") from error
    require(resolved.is_file() and not resolved.is_symlink(),
            f"missing or symlink artifact: {raw}")
    return resolved


def sha256(path: pathlib.Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def file_ref(path: pathlib.Path) -> dict[str, Any]:
    path = resolve_workspace(path)
    return {
        "path": relative(path),
        "sha256": sha256(path),
        "size_bytes": path.stat().st_size,
    }


def load_json(path: pathlib.Path) -> dict[str, Any]:
    def pairs(values: list[tuple[str, Any]]) -> dict[str, Any]:
        result: dict[str, Any] = {}
        for key, value in values:
            require(key not in result,
                    f"duplicate JSON key in {relative(path)}: {key}")
            result[key] = value
        return result

    try:
        value = json.loads(path.read_text(encoding="utf-8"),
                           object_pairs_hook=pairs)
    except (OSError, UnicodeError, json.JSONDecodeError) as error:
        raise EvidenceError(f"cannot read JSON {relative(path)}: {error}") from error
    require(isinstance(value, dict), f"JSON root is not an object: {relative(path)}")
    return value


def verify_ref(value: Any, label: str) -> pathlib.Path:
    require(isinstance(value, dict), f"{label} reference is not an object")
    require(set(value) == {"path", "sha256", "size_bytes"},
            f"{label} reference key set mismatch")
    path = resolve_workspace(value.get("path", ""))
    require(value.get("sha256") == sha256(path), f"{label} SHA-256 drift")
    require(value.get("size_bytes") == path.stat().st_size,
            f"{label} size drift")
    return path


def parse_manifest(path: pathlib.Path) -> dict[str, str]:
    entries: dict[str, str] = {}
    try:
        lines = path.read_text(encoding="utf-8").splitlines()
    except (OSError, UnicodeError) as error:
        raise EvidenceError(f"cannot read production manifest: {error}") from error
    for line in lines:
        parts = line.split(None, 1)
        require(len(parts) == 2 and re.fullmatch(r"[0-9a-f]{64}", parts[0]) is not None,
                "production manifest line is malformed")
        raw_path = parts[1].strip()
        marker = "/npc/"
        if marker not in raw_path:
            continue
        workspace_relative = "npc/" + raw_path.split(marker, 1)[1]
        if workspace_relative in entries:
            require(entries[workspace_relative] == parts[0],
                    f"conflicting production manifest path: {workspace_relative}")
        else:
            entries[workspace_relative] = parts[0]
    return entries


def verify_current_timing(
    path: pathlib.Path,
) -> tuple[dict[str, Any], pathlib.Path, dict[str, str]]:
    receipt = load_json(path)
    try:
        rebuilt = current_timing.rebuild_receipt(receipt)
    except (current_timing.EvidenceError, OSError, UnicodeError, KeyError,
            TypeError, ValueError) as error:
        raise EvidenceError(
            f"current timing-path receipt is not canonical: {error}") from error
    require(receipt == rebuilt,
            "current timing-path receipt differs from rebuilt evidence")
    candidate = receipt.get("candidate_decision", {})
    require(
        receipt.get("schema") == current_timing.SCHEMA
        and receipt.get("status") == current_timing.STATUS
        and receipt.get("next_action") == current_timing.NEXT_ACTION
        and candidate.get("status") == "GAP"
        and candidate.get("id") == current_timing.CANDIDATE_ID
        and candidate.get("rejected_candidate_id") == REJECTED_CANDIDATE_ID
        and candidate.get("production_rtl_change_authorized") is False
        and candidate.get("promotion_eligible") is False
        and candidate.get("ppa") == "UNQUALIFIED",
        "current timing-path receipt exceeds its owner-lifetime GAP boundary",
    )
    reference_path = verify_ref(
        receipt.get("inputs", {}).get("current_reference"),
        "current timing current-reference")
    reference = load_json(reference_path)
    manifest_path = verify_ref(
        reference.get("inputs", {}).get("run2_production_manifest_after"),
        "current-reference production manifest")
    return receipt, manifest_path, parse_manifest(manifest_path)


def verify_text_contracts(
    review_path: pathlib.Path,
    closure_path: pathlib.Path,
    spec_path: pathlib.Path,
    design_id: str,
) -> None:
    review = review_path.read_text(encoding="utf-8")
    require(
        REVIEW_MARKER in review
        and design_id in review
        and f"reviewed_candidate: `{REJECTED_CANDIDATE_ID}`" in review
        and "production_rtl_change_authorized: `false`" in review
        and "Scope extension requested by reviewer" in review,
        "independent review marker or GAP boundary mismatch",
    )
    closure = closure_path.read_text(encoding="utf-8")
    required_closure = (
        CLOSURE_MARKER,
        f"design_id={design_id}",
        f"rejected_candidate={REJECTED_CANDIDATE_ID}",
        f"candidate={CANDIDATE_ID}",
        "bare_one_bit_rejected=true",
        "owner_identity_required=true",
        "clear_dominant_required=true",
        "raw_backend_drain_rechecked=true",
        "fence_mem_idle_rechecked=true",
        "production_rtl_experiment_authorized=true",
        "production_rtl_implemented=false",
        "promotion_eligible=false",
        "PPA=UNQUALIFIED",
        f"next_action={NEXT_ACTION}",
    )
    require(all(marker in closure for marker in required_closure),
            "owner-lifetime closure marker or claim boundary mismatch")
    spec = spec_path.read_text(encoding="utf-8")
    required_spec = (
        "serialized control 的 owner-bound memory-terminal permit",
        "状态：V16A 可回退时序实验定义",
        "OooSerializedMemTerminalPermit",
        "owner_i",
        "permit_owner_q",
        "owner_i==permit_owner_q",
        "backend_drained_o",
        "mem_idle_i",
        REJECTED_CANDIDATE_ID,
        "尚未获得 PPA/promotion 资格",
    )
    require(all(marker in spec for marker in required_spec),
            "candidate specification is incomplete or overclaims qualification")


def source_snapshot(
    manifest: dict[str, str], *, verify_live: bool,
) -> list[dict[str, Any]]:
    snapshot: list[dict[str, Any]] = []
    for source_path, anchors in sorted(SOURCE_CONTRACTS.items()):
        require(source_path in manifest,
                f"source missing from production manifest: {source_path}")
        if verify_live:
            path = resolve_workspace(source_path)
            require(sha256(path) == manifest[source_path],
                    f"live source differs from timing design: {source_path}")
            text = path.read_text(encoding="utf-8")
            for anchor_id, anchor in anchors:
                require(anchor in text,
                        f"source contract anchor missing: {source_path}:{anchor_id}")
        snapshot.append({
            "path": source_path,
            "sha256": manifest[source_path],
            "anchors": [anchor_id for anchor_id, _ in anchors],
        })
    return snapshot


def build_payload(
    current_timing_path: pathlib.Path,
    independent_review_path: pathlib.Path,
    owner_lifetime_closure_path: pathlib.Path,
    candidate_spec_path: pathlib.Path,
    *,
    verify_live_sources: bool,
) -> dict[str, Any]:
    current_timing_path = resolve_workspace(current_timing_path)
    independent_review_path = resolve_workspace(independent_review_path)
    owner_lifetime_closure_path = resolve_workspace(owner_lifetime_closure_path)
    candidate_spec_path = resolve_workspace(candidate_spec_path)
    timing, manifest_path, manifest = verify_current_timing(current_timing_path)
    design_id = timing.get("design_id")
    require(isinstance(design_id, str) and design_id.startswith("sha256:"),
            "current timing design-id is invalid")
    verify_text_contracts(
        independent_review_path, owner_lifetime_closure_path,
        candidate_spec_path, design_id)
    snapshot = source_snapshot(manifest, verify_live=verify_live_sources)
    return {
        "schema": SCHEMA,
        "status": STATUS,
        "design_id": design_id,
        "inputs": {
            "current_timing_path_analysis": file_ref(current_timing_path),
            "independent_review": file_ref(independent_review_path),
            "owner_lifetime_closure": file_ref(owner_lifetime_closure_path),
            "candidate_spec": file_ref(candidate_spec_path),
            "production_manifest": file_ref(manifest_path),
            "builder": file_ref(pathlib.Path(__file__)),
        },
        "source_snapshot": snapshot,
        "counterexample_closure": {
            "memory_birth_after_capture": {
                "status": "CLOSED_BY_RUN_GATE_BIRTH_INHIBIT_AND_RAW_DRAIN_RECHECK",
                "candidate_obligation": "directed illegal-birth tuple remains required",
            },
            "owner_a_to_b_handoff": {
                "status": "CLOSED_BY_EXACT_ONE_OWNER_CAPTURE_AND_CURRENT_OWNER_COMPARE",
                "candidate_obligation": "A-to-B mismatch must invalidate before consume",
            },
            "flush_colliding_with_arm": {
                "status": "CLOSED_BY_REQUIRED_CLEAR_DOMINANT_FSM",
                "candidate_obligation": "all reset/cancel collisions require clocked TB coverage",
            },
            "collector_pending_accounting": {
                "status": "PRESERVED_BY_NO_COLLECTOR_OR_TRACKER_SIDE_EFFECT",
                "candidate_obligation": "pending token reuse must remain exactly-once",
            },
            "fence_trap_exit_priority": {
                "status": "PRESERVED_BY_CURRENT_RAW_DRAIN_IDLE_AND_PRIORITY_RECHECK",
                "candidate_obligation": "FENCE and ROB-head trap mutations must fail",
            },
        },
        "candidate_decision": {
            "status": "CANDIDATE_DEFINED",
            "id": CANDIDATE_ID,
            "rejected_candidate_id": REJECTED_CANDIDATE_ID,
            "mapped_control_cone_resolved": True,
            "cross_cycle_owner_lifetime_resolved_for_candidate": True,
            "bounded_production_rtl_experiment_authorized": True,
            "production_rtl_implemented": False,
            "promotion_eligible": False,
            "accepted_ppa_reference_available": False,
            "ppa": "UNQUALIFIED",
        },
        "candidate_definition": {
            "id": CANDIDATE_ID,
            "state": "AUTHORIZED_REVERSIBLE_EXPERIMENT",
            "owner_encoding": {
                "width": 3,
                "bit0": "pending_system && !pending_system_csr",
                "bit1": "pending_arch_trap",
                "bit2": "pending_exit",
                "valid_shape": "exact_one",
            },
            "registered_state_bits": 4,
            "arm_requires": [
                "stop_pending",
                "backend_drained_q",
                "current mem_owner_terminalized",
                "exact-one current owner",
            ],
            "clear_priority": [
                "reset/global-local flush",
                "architectural cancel",
                "accepted drain consume",
                "stop drop or owner mismatch",
                "arm",
                "hold",
            ],
            "consume_rechecks": [
                "current raw backend_drained",
                "current FENCE mem_idle",
                "current owner identity",
                "existing trap/exit/CSR priority",
            ],
            "reversible": True,
        },
        "required_experiment_evidence": [
            "helper arm/hold/consume and C1 no-repeat",
            "owner A-to-B mismatch and non-onehot rejection",
            "same-edge arm plus every architectural cancel",
            "new memory birth and active-holder fail-loud tuple",
            "collector-pending exact token accounting",
            "FENCE current mem_idle and ROB-head trap priority",
            "compile-success owner-compare clear-priority raw-drain and FENCE mutations",
            "same-design CoreMark Dhrystone and two-run mapped timing if functional gates pass",
        ],
        "authorization": {
            "bounded_production_rtl_experiment_authorized": True,
            "accepted_ppa_reference_available": False,
            "promotion_eligible": False,
            "same_design_measurement_required": True,
        },
        "claim_boundary": {
            "bare_one_bit_readiness_remains_rejected": True,
            "candidate_only": True,
            "production_rtl_unchanged": True,
            "functional_architecture_cpi_ppa_not_measured": True,
            "timing_hard_gate_not_claimed": True,
            "power_unqualified": True,
        },
        "next_action": NEXT_ACTION,
    }


def atomic_write_json(path: pathlib.Path, value: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    data = json.dumps(value, indent=2, sort_keys=True) + "\n"
    with tempfile.NamedTemporaryFile(
            mode="w", encoding="utf-8", dir=path.parent,
            prefix=f".{path.name}.", delete=False) as stream:
        temporary = pathlib.Path(stream.name)
        stream.write(data)
        stream.flush()
        os.fsync(stream.fileno())
    temporary.replace(path)


def rebuild_receipt(actual: dict[str, Any]) -> dict[str, Any]:
    require(actual.get("schema") == SCHEMA,
            "owner-lifetime receipt schema mismatch")
    inputs = actual.get("inputs", {})
    require(set(inputs) == {
        "current_timing_path_analysis", "independent_review",
        "owner_lifetime_closure", "candidate_spec", "production_manifest",
        "builder",
    }, "owner-lifetime input set mismatch")
    for label, value in inputs.items():
        verify_ref(value, label)
    expected = build_payload(
        pathlib.Path(inputs["current_timing_path_analysis"]["path"]),
        pathlib.Path(inputs["independent_review"]["path"]),
        pathlib.Path(inputs["owner_lifetime_closure"]["path"]),
        pathlib.Path(inputs["candidate_spec"]["path"]),
        verify_live_sources=False,
    )
    require(expected["inputs"]["production_manifest"]
            == inputs["production_manifest"],
            "production manifest binding mismatch")
    return expected


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    subparsers = parser.add_subparsers(dest="command", required=True)
    build = subparsers.add_parser("build")
    build.add_argument("--current-timing-path-analysis", required=True)
    build.add_argument("--independent-review", required=True)
    build.add_argument("--owner-lifetime-closure", required=True)
    build.add_argument("--candidate-spec", required=True)
    build.add_argument("--output", required=True)
    verify = subparsers.add_parser("verify")
    verify.add_argument("--input", required=True)
    return parser


def main() -> int:
    args = build_parser().parse_args()
    try:
        if args.command == "build":
            output = pathlib.Path(args.output)
            if not output.is_absolute():
                output = REPO_ROOT / output
            output = output.resolve()
            try:
                output.relative_to(REPO_ROOT)
            except ValueError as error:
                raise EvidenceError("output path escapes repository") from error
            value = build_payload(
                pathlib.Path(args.current_timing_path_analysis),
                pathlib.Path(args.independent_review),
                pathlib.Path(args.owner_lifetime_closure),
                pathlib.Path(args.candidate_spec),
                verify_live_sources=True,
            )
            atomic_write_json(output, value)
        else:
            input_path = resolve_workspace(args.input)
            actual = load_json(input_path)
            expected = rebuild_receipt(actual)
            require(actual == expected,
                    "owner-lifetime receipt differs from rebuilt evidence")
            value = actual
        print(
            "[SERIALIZED-DRAIN-OWNER-LIFETIME][PASS_CANDIDATE_DEFINED] "
            f"design_id={value['design_id']} candidate={CANDIDATE_ID} "
            "production_rtl_experiment_authorized=true promotion_eligible=false"
        )
        return 0
    except (EvidenceError, OSError, UnicodeError, KeyError, TypeError) as error:
        print(f"[SERIALIZED-DRAIN-OWNER-LIFETIME][FAIL] {error}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
