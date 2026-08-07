#!/usr/bin/env python3
"""Audit memory-terminal ingress wiring and every source-lane pair."""

from __future__ import annotations

import argparse
import hashlib
import json
import pathlib
import re
import sys
from typing import Any


SCHEMA = "rv64-terminal-collector-lane-contract-v2"
PAIR_SCHEMA = "rv64-terminal-collector-source-pair-matrix-v1"
BACKEND = "npc/rv64/vsrc/execute/OooIntBackend.v"
COLLECTOR = "npc/rv64/vsrc/memory/OooMemOwnerTerminalCollector.v"
TOOL = "npc/rv64/eval/ppa/tools/terminal_collector_lane_contract.py"

LANES = [
    {
        "lane": 0,
        "source": "miq0-response",
        "valid": "mem_terminal_rsp_valid_w",
        "kind": "miq_head_owner_kind_w",
        "token": "miq_head_owner_token_w",
        "epoch": "miq_head_mmu_epoch_w",
    },
    {
        "lane": 1,
        "source": "miq1-response",
        "valid": "mem1_terminal_rsp_valid_w",
        "kind": "miq1_head_owner_kind_w",
        "token": "miq1_head_owner_token_w",
        "epoch": "miq1_head_mmu_epoch_w",
    },
    {
        "lane": 2,
        "source": "bridge0-active-drop",
        "valid": "mem_drop0_valid_i",
        "kind": "mem_drop0_owner_kind_i",
        "token": "mem_drop0_owner_token_i",
        "epoch": "mem_drop0_mmu_epoch_i",
    },
    {
        "lane": 3,
        "source": "bridge0-station-drop",
        "valid": "mem_drop1_valid_i",
        "kind": "mem_drop1_owner_kind_i",
        "token": "mem_drop1_owner_token_i",
        "epoch": "mem_drop1_mmu_epoch_i",
    },
    {
        "lane": 4,
        "source": "bridge1-active-drop",
        "valid": "mem1_drop0_valid_i",
        "kind": "mem1_drop0_owner_kind_i",
        "token": "mem1_drop0_owner_token_i",
        "epoch": "mem1_drop0_mmu_epoch_i",
    },
    {
        "lane": 5,
        "source": "bridge1-station-drop",
        "valid": "mem1_drop1_valid_i",
        "kind": "mem1_drop1_owner_kind_i",
        "token": "mem1_drop1_owner_token_i",
        "epoch": "mem1_drop1_mmu_epoch_i",
    },
    {
        "lane": 6,
        "source": "reservation0-terminal",
        "valid": "mem_issue_res_tagged_terminal_w",
        "kind": "mem_issue_res_owner_kind_q",
        "token": "mem_issue_res_owner_token_q",
        "epoch": "mem_issue_res_mmu_epoch_q",
    },
    {
        "lane": 7,
        "source": "reservation1-terminal",
        "valid": "mem_issue1_res_tagged_terminal_w",
        "kind": "mem_issue1_res_owner_kind_q",
        "token": "mem_issue1_res_owner_token_q",
        "epoch": "mem_issue1_res_mmu_epoch_q",
    },
    {
        "lane": 8,
        "source": "legacy-buffer-terminal",
        "valid": "mem_buffer_tagged_terminal_w",
        "kind": "mem_buffer_owner_kind_q",
        "token": "mem_buffer_owner_token_q",
        "epoch": "mem_buffer_mmu_epoch_q",
    },
    {
        "lane": 9,
        "source": "amo-interphase-terminal",
        "valid": "mem_amo_interphase_cancel_w",
        "kind": "mem_owner_kind_q",
        "token": "mem_owner_token_q",
        "epoch": "mem_mmu_epoch_q",
    },
    {
        "lane": 10,
        "source": "retry0-terminal",
        "valid": "mem_retry0_tagged_terminal_w",
        "kind": "mem_retry0_owner_kind_q",
        "token": "mem_retry0_owner_token_q",
        "epoch": "mem_retry0_mmu_epoch_q",
    },
    {
        "lane": 11,
        "source": "retry1-terminal",
        "valid": "mem_retry1_tagged_terminal_w",
        "kind": "mem_retry1_owner_kind_q",
        "token": "mem_retry1_owner_token_q",
        "epoch": "mem_retry1_mmu_epoch_q",
    },
]

RESPONSE_LANES = {0, 1}
BRIDGE_LANES = {2, 3, 4, 5}
TRANSIENT_LANES = {6, 7, 8, 10, 11}
AMO_LANE = 9

# These expressions classify protection before the collector.  They are kept
# separate from the collector's exact-tuple rejection: rejecting two terminals
# is fail-closed, but it is not evidence that the producer transition is legal.
SOURCE_GUARD_PATTERNS = {
    "response-credit": (
        r"wire\s+\[31:0\]\s+mem_terminal_nonresponse_raw_mask_w\s*=\s*"
        r"mem_terminal_ingress2_mask_w\s*\|\s*"
        r"mem_terminal_ingress3_mask_w\s*\|\s*"
        r"mem_terminal_ingress4_mask_w\s*\|\s*"
        r"mem_terminal_ingress5_mask_w\s*\|\s*"
        r"mem_terminal_ingress6_mask_w\s*\|\s*"
        r"mem_terminal_ingress7_mask_w\s*\|\s*"
        r"mem_terminal_ingress8_mask_w\s*\|\s*"
        r"mem_terminal_ingress9_mask_w\s*\|\s*"
        r"mem_terminal_ingress10_mask_w\s*\|\s*"
        r"mem_terminal_ingress11_mask_w\s*;",
        r"wire\s+\[31:0\]\s+mem_response_other_raw_mask_w\s*=\s*"
        r"mem_terminal_nonresponse_raw_mask_w\s*\|\s*"
        r"\(mem1_response_terminal_raw_w\s*\?\s*"
        r"\(32'b1\s*<<\s*miq1_head_owner_token_w\)\s*:\s*32'b0\)\s*;",
        r"wire\s+\[31:0\]\s+mem1_response_other_raw_mask_w\s*=\s*"
        r"mem_terminal_nonresponse_raw_mask_w\s*\|\s*"
        r"\(mem_response_terminal_raw_w\s*\?\s*"
        r"\(32'b1\s*<<\s*miq_head_owner_token_w\)\s*:\s*32'b0\)\s*;",
        r"wire\s+mem_response_terminal_credit_w\s*=\s*"
        r"!mem_terminal_pending_mask_w\[miq_head_owner_token_w\]\s*&&\s*"
        r"!mem_response_other_raw_mask_w\[miq_head_owner_token_w\]\s*;",
        r"wire\s+mem1_response_terminal_credit_w\s*=\s*"
        r"!mem_terminal_pending_mask_w\[miq1_head_owner_token_w\]\s*&&\s*"
        r"!mem1_response_other_raw_mask_w\[miq1_head_owner_token_w\]\s*;",
    ),
    "bridge-holder-assertion": (
        r"wire\s+\[31:0\]\s+v9q_bridge_pair_overlap_mask_w\s*=",
        r"if\s*\(v9q_bridge_pair_overlap_mask_w\s*!=\s*32'b0\).*?"
        r"\[V9Q-BRIDGE-HOLDER-DISJOINT\]",
    ),
    "transient-holder-assertion": (
        r"wire\s+\[31:0\]\s+v9q_transient_holder_duplicate_mask_w\s*=",
        r"if\s*\(v9q_transient_holder_duplicate_mask_w\s*!=\s*32'b0\).*?"
        r"\[V9Q-TRANSIENT-HOLDER-DISJOINT\]",
    ),
    "transient-bridge-assertion": (
        r"wire\s+\[31:0\]\s+v9q_transient_bridge_overlap_mask_w\s*=",
        r"if\s*\(v9q_transient_bridge_overlap_mask_w\s*!=\s*32'b0\).*?"
        r"\[V9Q-TRANSIENT-BRIDGE-DISJOINT\]",
    ),
    "amo-interphase-assertion": (
        r"if\s*\(mem_amo_interphase_cancel_w\s*&&\s*"
        r"\(\(mem_terminal_ingress9_mask_w\s*&.*?"
        r"mem_terminal_ingress5_mask_w\)\)\s*!=\s*32'b0\)\).*?"
        r"\[S2-G1-AMO-INTERPHASE-DUP\]",
    ),
    "amo-transient-holder-assertion": (
        r"wire\s+\[31:0\]\s+v14u_amo_pending_owner_mask_w\s*=\s*"
        r"\(mem_pending_q\s*&&\s*mem_amo_q\)\s*\?\s*"
        r"\(32'b1\s*<<\s*mem_owner_token_q\)\s*:\s*32'b0\s*;",
        r"wire\s+\[31:0\]\s+v14u_amo_transient_overlap_mask_w\s*=\s*"
        r"v14u_amo_pending_owner_mask_w\s*&\s*"
        r"\(mem_issue_res_owner_mask_w\s*\|\s*"
        r"mem_issue1_res_owner_mask_w\s*\|\s*"
        r"mem_buffer_owner_mask_w\)\s*;",
        r"if\s*\(v14u_amo_transient_overlap_mask_w\s*!==\s*32'b0\).*?"
        r"\[V14U-AMO-TRANSIENT-HOLDER-DISJOINT\]",
    ),
    "retry-cancel-assertion": (
        r"mem_terminal_ingress10_mask_w\s*&.*?"
        r"mem_terminal_ingress11_mask_w.*?"
        r"\[V8T-RETRY-CANCEL-TERMINAL\]",
    ),
}

REQUIRED_CURRENT_SOURCE_GUARDS = tuple(SOURCE_GUARD_PATTERNS)

GUARD_ENFORCEMENT = {
    "response-credit": "production-rtl-gate",
    "bridge-holder-assertion": "rtl-assertion",
    "transient-holder-assertion": "rtl-assertion",
    "transient-bridge-assertion": "rtl-assertion",
    "amo-interphase-assertion": "rtl-assertion",
    "amo-transient-holder-assertion": "rtl-assertion",
    "retry-cancel-assertion": "rtl-assertion",
    "collector-exact-tuple-reject": "collector-fail-closed",
}


class ContractError(RuntimeError):
    """Raised when a lane or owner-transfer mapping is no longer exact."""


def sha256_file(path: pathlib.Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def rtl_design_id(root: pathlib.Path) -> str:
    sys.path.insert(0, str(root / "npc/rv64/eval/ppa/tools"))
    try:
        import architecture_hard_gates as architecture
    finally:
        sys.path.pop(0)
    digest, _ = architecture.rtl_binding(root)
    return f"sha256:{digest}"


def extract_concat(text: str, signal: str) -> list[str]:
    match = re.search(
        rf"assign\s+{re.escape(signal)}\s*=\s*\{{(?P<body>.*?)\}}\s*;",
        text,
        re.DOTALL,
    )
    if not match:
        raise ContractError(f"missing concatenation assignment: {signal}")
    values = [
        re.sub(r"\s+", "", value)
        for value in match.group("body").split(",")
        if value.strip()
    ]
    if len(values) != 12:
        raise ContractError(
            f"{signal} must contain exactly twelve scalar/tuple fields"
        )
    return list(reversed(values))


def require_pattern(text: str, pattern: str, label: str) -> None:
    if not re.search(pattern, text, re.DOTALL):
        raise ContractError(f"missing exact contract: {label}")


def reject_indexed_birth_production_flow(backend: str) -> None:
    anchor = backend.find("wire [31:0] v9y_mem_birth_token_mask_w")
    if anchor < 0:
        raise ContractError("missing indexed birth observability decode")
    assertion_boundary = backend.find("`ifdef OOO_ASSERT", anchor)
    if assertion_boundary < 0:
        raise ContractError("missing post-terminal assertion boundary")
    production = backend[:assertion_boundary]
    production = re.sub(r"/\*.*?\*/", "", production, flags=re.DOTALL)
    production = re.sub(r"//[^\n]*", "", production)
    assignments: dict[str, list[str]] = {}
    for match in re.finditer(
        r"\b(?P<lhs>[A-Za-z_][A-Za-z0-9_]*)\s*=\s*(?!=)"
        r"(?P<rhs>.*?)\s*;",
        production,
        re.DOTALL,
    ):
        assignments.setdefault(match.group("lhs"), []).append(
            match.group("rhs")
        )

    indexed_decode = re.compile(
        r"(?:32'b0*1|32'h0*1|32'd0*1|1'b1|1)\s*<<\s*"
        r"mem_owner_alloc[01]_token_w"
    )
    tainted = {
        lhs for lhs, expressions in assignments.items()
        if any(indexed_decode.search(rhs) for rhs in expressions)
    }
    if "v9y_mem_birth_token_mask_w" not in tainted:
        raise ContractError("missing indexed birth observability decode")
    identifiers = {
        lhs: {
            identifier
            for rhs in expressions
            for identifier in re.findall(r"[A-Za-z_][A-Za-z0-9_]*", rhs)
        }
        for lhs, expressions in assignments.items()
    }
    changed = True
    while changed:
        changed = False
        for lhs, dependencies in identifiers.items():
            if lhs not in tainted and dependencies & tainted:
                tainted.add(lhs)
                changed = True

    sinks = {
        "v9y_active_holder_mask_w",
        "v9y_unterminalized_holder_mask_w",
        "v9y_terminal_without_holder_mask_w",
        "v9y_unaccounted_live_mask_w",
        "v9y_pending_without_live_mask_w",
        "mem_owner_terminalized_o",
    }
    leaked = sorted(sinks & tainted)
    if leaked:
        raise ContractError(
            "indexed birth decode reaches production terminal cone: "
            + ",".join(leaked)
        )


def detect_source_guards(backend: str) -> dict[str, bool]:
    return {
        guard: all(re.search(pattern, backend, re.DOTALL) is not None
                   for pattern in patterns)
        for guard, patterns in SOURCE_GUARD_PATTERNS.items()
    }


def pair_guard(lane_a: int, lane_b: int) -> str:
    lanes = {lane_a, lane_b}
    if lanes & RESPONSE_LANES:
        return "response-credit"
    if lanes <= BRIDGE_LANES:
        return "bridge-holder-assertion"
    if lanes <= TRANSIENT_LANES:
        return "transient-holder-assertion"
    if lanes & BRIDGE_LANES and lanes & TRANSIENT_LANES:
        return "transient-bridge-assertion"
    if AMO_LANE in lanes and lanes & BRIDGE_LANES:
        return "amo-interphase-assertion"
    if AMO_LANE in lanes and lanes & {10, 11}:
        return "retry-cancel-assertion"
    if AMO_LANE in lanes and lanes & {6, 7, 8}:
        return "amo-transient-holder-assertion"
    raise ContractError(f"unclassified terminal source pair: {lane_a}/{lane_b}")


def build_pair_matrix(backend: str) -> dict[str, Any]:
    presence = detect_source_guards(backend)
    rows: list[dict[str, Any]] = []
    guard_counts = {
        guard: 0
        for guard in (*SOURCE_GUARD_PATTERNS,
                      "collector-exact-tuple-reject")
    }
    collector_only: list[str] = []
    for lane_a in range(len(LANES)):
        for lane_b in range(lane_a + 1, len(LANES)):
            required_guard = pair_guard(lane_a, lane_b)
            observed_guard = required_guard
            if (required_guard != "collector-exact-tuple-reject" and
                    not presence[required_guard]):
                observed_guard = "collector-exact-tuple-reject"
            pair_id = f"lane{lane_a}-lane{lane_b}"
            source_covered = observed_guard != "collector-exact-tuple-reject"
            if not source_covered:
                collector_only.append(pair_id)
            guard_counts[observed_guard] += 1
            rows.append(
                {
                    "pair_id": pair_id,
                    "lane_a": lane_a,
                    "source_a": LANES[lane_a]["source"],
                    "lane_b": lane_b,
                    "source_b": LANES[lane_b]["source"],
                    "guard": observed_guard,
                    "enforcement": GUARD_ENFORCEMENT[observed_guard],
                    "precollector_duplicate_status": (
                        "PROTECTED"
                        if source_covered else "COLLECTOR_ONLY_GAP"
                    ),
                    "duplicate_policy": (
                        "suppress-response-terminal-credit"
                        if observed_guard == "response-credit"
                        else (
                            "fail-at-source-assertion"
                            if source_covered else "reject-without-merge"
                        )
                    ),
                }
            )
    if len(rows) != 66:
        raise ContractError(f"terminal source-pair inventory is {len(rows)}, not 66")
    return {
        "source_guard_presence": presence,
        "precollector_pair_status": (
            "GAP" if collector_only else "CLOSED"
        ),
        "source_guarded_or_asserted_pairs": len(rows) - len(collector_only),
        "collector_only_pairs": len(collector_only),
        "collector_only_pair_ids": collector_only,
        "guard_counts": guard_counts,
        "pairs": rows,
    }


def audit_text(backend: str, collector: str) -> dict[str, Any]:
    vectors = {
        field: extract_concat(backend, signal)
        for field, signal in (
            ("valid", "mem_terminal_ingress_valid_w"),
            ("kind", "mem_terminal_ingress_kind_w"),
            ("token", "mem_terminal_ingress_token_w"),
            ("epoch", "mem_terminal_ingress_epoch_w"),
        )
    }
    rows: list[dict[str, Any]] = []
    for expected in LANES:
        lane = expected["lane"]
        observed = {
            field: vectors[field][lane]
            for field in ("valid", "kind", "token", "epoch")
        }
        for field, value in observed.items():
            if value != expected[field]:
                raise ContractError(
                    f"lane{lane} {field} mismatch: "
                    f"expected={expected[field]} observed={value}"
                )
        require_pattern(
            backend,
            rf"\{{32\{{mem_terminal_ingress_accept_w\[{lane}\]\}}\}}\s*&"
            rf"\s*mem_terminal_ingress{lane}_mask_w",
            f"lane{lane} collector acceptance to transfer mask",
        )
        require_pattern(
            backend,
            rf"assign\s+mem_terminal_ingress{lane}_mask_w\s*=.*?"
            rf"32'b1\s*<<\s*{re.escape(expected['token'])}",
            f"lane{lane} token to raw observation mask",
        )
        rows.append(
            {
                **expected,
                "accept": f"mem_terminal_ingress_accept_w[{lane}]",
                "observation_mask":
                    f"mem_terminal_ingress{lane}_mask_w",
            }
        )

    require_pattern(
        backend,
        r"OooMemOwnerTerminalCollector\s*#\s*\(\s*"
        r"\.INGRESS_N\s*\(\s*12\s*\)\s*\)",
        "collector product ingress width",
    )
    for port, signal in (
        ("ingress_valid_i", "mem_terminal_ingress_valid_w"),
        ("ingress_kind_i", "mem_terminal_ingress_kind_w"),
        ("ingress_token_i", "mem_terminal_ingress_token_w"),
        ("ingress_epoch_i", "mem_terminal_ingress_epoch_w"),
        ("ingress_accept_o", "mem_terminal_ingress_accept_w"),
        ("deq0_valid_o", "mem_terminal_deq0_valid_w"),
        ("deq0_kind_o", "mem_terminal_deq0_kind_w"),
        ("deq0_token_o", "mem_terminal_deq0_token_w"),
        ("deq0_epoch_o", "mem_terminal_deq0_epoch_w"),
        ("deq0_ready_i", "mem_terminal_deq0_ready_w"),
        ("deq1_valid_o", "mem_terminal_deq1_valid_w"),
        ("deq1_kind_o", "mem_terminal_deq1_kind_w"),
        ("deq1_token_o", "mem_terminal_deq1_token_w"),
        ("deq1_epoch_o", "mem_terminal_deq1_epoch_w"),
        ("deq1_ready_i", "mem_terminal_deq1_ready_w"),
        ("pending_mask_o", "mem_terminal_pending_mask_w"),
    ):
        require_pattern(
            backend,
            rf"\.{port}\s*\(\s*{signal}\s*\)",
            f"collector port {port}",
        )

    for lane in (0, 1):
        for stem in ("valid", "kind", "token", "epoch"):
            require_pattern(
                backend,
                rf"\.free{lane}_{stem}_i\s*\(\s*"
                rf"mem_terminal_deq{lane}_{stem}_w\s*\)",
                f"tracker free{lane} {stem}",
            )
        require_pattern(
            backend,
            rf"\.free{lane}_ready_o\s*\(\s*"
            rf"mem_terminal_deq{lane}_ready_w\s*\)",
            f"tracker free{lane} ready",
        )

    transfer = re.search(
        r"wire\s+\[31:0\]\s+v9y_terminal_transfer_mask_w\s*=\s*"
        r"(?P<body>.*?)\s*;",
        backend,
        re.DOTALL,
    )
    if not transfer:
        raise ContractError("missing terminal transfer authority")
    transfer_body = re.sub(r"\s+", "", transfer.group("body"))
    if transfer_body != (
        "mem_terminal_accept_mask_w|sq_owner_release_effective_mask_w"
    ):
        raise ContractError(
            "terminal transfer authority must use collector acceptance "
            "plus exact SQ release only"
        )
    require_pattern(
        backend,
        r"wire\s+v15r_mem_birth_any_w\s*=\s*"
        r"mem_issue_res_capture_w\s*\|\|\s*"
        r"mem_issue1_res_capture_w\s*;",
        "scalar memory-birth predicate",
    )
    active_holder = re.search(
        r"wire\s+\[31:0\]\s+v9y_active_holder_mask_w\s*=\s*"
        r"(?P<body>.*?)\s*;",
        backend,
        re.DOTALL,
    )
    if not active_holder:
        raise ContractError("missing active holder mask")
    if "v9y_mem_birth_token_mask_w" in active_holder.group("body"):
        raise ContractError("birth mask must not feed active holder reduction")
    reject_indexed_birth_production_flow(backend)
    require_pattern(
        backend,
        r"assign\s+mem_owner_terminalized_o\s*=\s*"
        r"!v15r_mem_birth_any_w\s*&&\s*"
        r"\(v9y_unterminalized_holder_mask_w\s*==\s*32'b0\)\s*&&\s*"
        r"\(v9y_terminal_without_holder_mask_w\s*==\s*32'b0\)\s*&&\s*"
        r"\(v9y_unaccounted_live_mask_w\s*==\s*32'b0\)\s*&&\s*"
        r"\(v9y_pending_without_live_mask_w\s*==\s*32'b0\)\s*;",
        "reduced exact owner-terminal predicate",
    )
    for label in (
        "V11B-TCOLL-INGRESS-TUPLE-KNOWN",
        "V11B-TCOLL-TRACKER-TUPLE-KNOWN",
        "V11B-TCOLL-OUT0-TUPLE-KNOWN",
        "V11B-TCOLL-OUT1-TUPLE-KNOWN",
        "S2-G1-TCOLL-INGRESS-DUP",
        "S2-G1-TCOLL-SAME-EDGE-REENQUEUE",
        "S2-G1-TCOLL-OUT-DUP",
    ):
        if label not in collector:
            raise ContractError(f"collector assertion label is missing: {label}")
    pair_matrix = build_pair_matrix(backend)
    for guard in REQUIRED_CURRENT_SOURCE_GUARDS:
        if not pair_matrix["source_guard_presence"][guard]:
            raise ContractError(f"missing source-pair guard: {guard}")
    return {
        "lanes": rows,
        "tracker_free_lanes": [
            {
                "lane": lane,
                "tuple": (
                    f"mem_terminal_deq{lane}_kind_w/"
                    f"mem_terminal_deq{lane}_token_w/"
                    f"mem_terminal_deq{lane}_epoch_w"
                ),
                "ready": f"mem_terminal_deq{lane}_ready_w",
            }
            for lane in (0, 1)
        ],
        "transfer_authority": [
            "mem_terminal_accept_mask_w",
            "sq_owner_release_effective_mask_w",
        ],
        "raw_ingress_is_transfer_authority": False,
        "duplicate_ingress_is_merged": False,
        "assertion_labels_checked": 7,
        "source_pair_matrix": pair_matrix,
    }


def build(root: pathlib.Path) -> dict[str, Any]:
    backend_path = root / BACKEND
    collector_path = root / COLLECTOR
    audit = audit_text(
        backend_path.read_text(encoding="utf-8"),
        collector_path.read_text(encoding="utf-8"),
    )
    return {
        "schema_version": SCHEMA,
        "status": "PASS",
        "design_id": rtl_design_id(root),
        "sources": {
            BACKEND: sha256_file(backend_path),
            COLLECTOR: sha256_file(collector_path),
            TOOL: sha256_file(root / TOOL),
        },
        **audit,
        "claim_boundary": (
            "Static current-source lane/tuple/accept/free wiring and all "
            "66 lane-pair protection classes only. Collector-only pairs "
            "remain source-contract gaps; dynamic lifecycle, historical "
            "root cause, whole architecture and PPA remain separately gated."
        ),
    }


def build_snapshot_pair_matrix(
    root: pathlib.Path,
    backend_path: pathlib.Path,
) -> dict[str, Any]:
    backend_path = backend_path.resolve()
    try:
        relative = backend_path.relative_to(root.resolve()).as_posix()
    except ValueError as exc:
        raise ContractError("backend snapshot escapes workspace") from exc
    if not backend_path.is_file():
        raise ContractError(f"backend snapshot is missing: {relative}")
    matrix = build_pair_matrix(backend_path.read_text(encoding="utf-8"))
    return {
        "schema_version": PAIR_SCHEMA,
        "status": "PASS",
        "source": {
            "path": relative,
            "sha256": sha256_file(backend_path),
        },
        "classifier": {
            "path": TOOL,
            "sha256": sha256_file(root / TOOL),
        },
        **matrix,
        "claim_boundary": (
            "Static source snapshot only. A collector-only pair is a bounded "
            "candidate, not identification of the historical dynamic pair."
        ),
    }


def write_json(path: pathlib.Path, payload: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(
        json.dumps(payload, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--root", type=pathlib.Path, default=pathlib.Path.cwd()
    )
    sub = parser.add_subparsers(dest="command", required=True)
    build_parser = sub.add_parser("build")
    build_parser.add_argument("--output", type=pathlib.Path, required=True)
    verify_parser = sub.add_parser("verify")
    verify_parser.add_argument("--input", type=pathlib.Path, required=True)
    matrix_parser = sub.add_parser("classify-backend")
    matrix_parser.add_argument("--backend", type=pathlib.Path, required=True)
    matrix_parser.add_argument("--output", type=pathlib.Path, required=True)
    args = parser.parse_args(argv)
    root = args.root.resolve()
    if args.command == "classify-backend":
        backend_path = args.backend
        if not backend_path.is_absolute():
            backend_path = root / backend_path
        expected = build_snapshot_pair_matrix(root, backend_path)
        output = args.output
        if not output.is_absolute():
            output = root / output
        write_json(output, expected)
        print(
            "[V14T-TERMINAL-SOURCE-PAIR-MATRIX][PASS] "
            f"source={expected['source']['path']} pairs=66 "
            "source_guarded="
            f"{expected['source_guarded_or_asserted_pairs']} "
            f"collector_only={expected['collector_only_pairs']}"
        )
        return 0

    expected = build(root)
    if args.command == "build":
        output = args.output
        if not output.is_absolute():
            output = root / output
        write_json(output, expected)
    else:
        input_path = args.input
        if not input_path.is_absolute():
            input_path = root / input_path
        actual = json.loads(input_path.read_text(encoding="utf-8"))
        if actual != expected:
            raise ContractError(
                "terminal collector lane evidence differs from current RTL"
            )
    print(
        "[V11B-TERMINAL-COLLECTOR-LANE-CONTRACT][PASS] "
        f"design_id={expected['design_id']} ingress=12 free=2 "
        "transfer=accepted-only duplicate_merge=false"
    )
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except ContractError as exc:
        print(
            f"[V11B-TERMINAL-COLLECTOR-LANE-CONTRACT][FAIL] {exc}",
            file=sys.stderr,
        )
        raise SystemExit(1)
