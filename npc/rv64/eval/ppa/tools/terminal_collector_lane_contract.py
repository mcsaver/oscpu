#!/usr/bin/env python3
"""Audit the twelve memory-terminal ingress lanes and two tracker-free lanes."""

from __future__ import annotations

import argparse
import hashlib
import json
import pathlib
import re
import sys
from typing import Any


SCHEMA = "rv64-terminal-collector-lane-contract-v1"
BACKEND = "npc/rv64/vsrc/execute/OooIntBackend.v"
COLLECTOR = "npc/rv64/vsrc/memory/OooMemOwnerTerminalCollector.v"

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
        r"assign\s+mem_owner_terminalized_o\s*=\s*"
        r"\(v9y_unterminalized_holder_mask_w\s*==\s*32'b0\)\s*&&\s*"
        r"\(v9y_terminal_without_holder_mask_w\s*==\s*32'b0\)\s*&&\s*"
        r"\(v9y_unaccounted_live_mask_w\s*==\s*32'b0\)\s*&&\s*"
        r"\(v9y_pending_without_live_mask_w\s*==\s*32'b0\)",
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
        },
        **audit,
        "claim_boundary": (
            "Static current-source lane/tuple/accept/free wiring only. "
            "Dynamic lifecycle, full semantic census, whole architecture "
            "and PPA remain separately gated."
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
    args = parser.parse_args(argv)
    root = args.root.resolve()
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
