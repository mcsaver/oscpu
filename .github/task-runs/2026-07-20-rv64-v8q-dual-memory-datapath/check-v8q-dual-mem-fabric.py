#!/usr/bin/env python3
"""Fail-closed structural and claim checker for the v8q/F0 AXI leaf."""

from __future__ import annotations

import argparse
import json
import pathlib
import re
import sys
from dataclasses import dataclass


@dataclass(frozen=True)
class Check:
    check_id: str
    passed: bool
    detail: str


def strip_comments(text: str) -> str:
    text = re.sub(r"/\*.*?\*/", "", text, flags=re.S)
    return re.sub(r"//[^\n]*", "", text)


def exact_count(text: str, pattern: str) -> int:
    return len(re.findall(pattern, text, flags=re.S | re.M))


def structural_checks(rtl_text: str) -> list[Check]:
    text = strip_comments(rtl_text)
    checks: list[Check] = []

    def add(check_id: str, passed: bool, detail: str) -> None:
        checks.append(Check(check_id, bool(passed), detail))

    module_count = exact_count(
        text, r"\bmodule\s+OooDualMemAxiArbiter\s*\("
    )
    add("source.one_nonempty_module", module_count == 1 and len(text.strip()) > 800,
        f"module_count={module_count} stripped_bytes={len(text.strip())}")

    for name, value in (
        ("S_IDLE", "3'd0"),
        ("S_READ_ADDR", "3'd1"),
        ("S_READ_RESP", "3'd2"),
        ("S_WRITE_DATA", "3'd3"),
        ("S_WRITE_RESP", "3'd4"),
    ):
        count = exact_count(
            text,
            rf"\blocalparam\s+\[2:0\]\s+{name}\s*=\s*{re.escape(value)}\s*;",
        )
        add(f"source.state.{name.lower()}", count == 1, f"count={count}")

    for reg_name in (
        "state_q", "owner_q", "is_write_q", "rr_q", "aw_seen_q", "w_seen_q"
    ):
        count = exact_count(text, rf"\breg(?:\s+\[2:0\])?\s+{reg_name}\s*;")
        add(f"source.register.{reg_name}", count == 1, f"count={count}")

    registered_capture = exact_count(
        text,
        r"S_IDLE\s*:\s*begin.*?if\s*\(capture_valid_w\)\s*begin.*?"
        r"owner_q\s*<=\s*capture_owner_w\s*;.*?"
        r"is_write_q\s*<=\s*capture_write_w\s*;.*?"
        r"state_q\s*<=\s*capture_write_w\s*\?\s*S_WRITE_DATA\s*:\s*S_READ_ADDR\s*;",
    )
    add("source.registered_capture", registered_capture == 1,
        f"count={registered_capture}")

    for channel in ("ar", "aw", "w", "r", "b"):
        count = exact_count(
            text,
            rf"\bwire\s+{channel}_fire_w\s*=\s*d_axi_{channel}valid_[oi]\s*&&\s*"
            rf"d_axi_{channel}(?:ready_[io])\s*;",
        )
        add(f"source.fire.{channel}", count == 1, f"count={count}")

    aw_next = exact_count(
        text, r"wire\s+aw_seen_next_w\s*=\s*aw_seen_q\s*\|\|\s*aw_fire_w\s*;"
    )
    w_next = exact_count(
        text, r"wire\s+w_seen_next_w\s*=\s*w_seen_q\s*\|\|\s*w_fire_w\s*;"
    )
    add("source.aw_seen_aggregation", aw_next == 1, f"count={aw_next}")
    add("source.w_seen_aggregation", w_next == 1, f"count={w_next}")

    write_gate = exact_count(
        text,
        r"if\s*\(aw_seen_next_w\s*&&\s*w_seen_next_w\)\s*"
        r"state_q\s*<=\s*S_WRITE_RESP\s*;",
    )
    add("source.write_requires_aw_and_w", write_gate == 1, f"count={write_gate}")

    read_terminal = exact_count(
        text,
        r"S_READ_RESP\s*:\s*begin.*?if\s*\(r_fire_w\)\s*begin.*?"
        r"state_q\s*<=\s*S_IDLE\s*;.*?rr_q\s*<=\s*~owner_q\s*;",
    )
    write_terminal = exact_count(
        text,
        r"S_WRITE_RESP\s*:\s*begin.*?if\s*\(b_fire_w\)\s*begin.*?"
        r"state_q\s*<=\s*S_IDLE\s*;.*?rr_q\s*<=\s*~owner_q\s*;",
    )
    add("source.read_terminal_unlock", read_terminal == 1,
        f"count={read_terminal}")
    add("source.write_terminal_unlock", write_terminal == 1,
        f"count={write_terminal}")

    reset_cold = exact_count(
        text,
        r"if\s*\(rst\)\s*begin\s*state_q\s*<=\s*S_IDLE\s*;\s*"
        r"owner_q\s*<=\s*1'b0\s*;\s*is_write_q\s*<=\s*1'b0\s*;\s*"
        r"rr_q\s*<=\s*1'b0\s*;\s*aw_seen_q\s*<=\s*1'b0\s*;\s*"
        r"w_seen_q\s*<=\s*1'b0\s*;",
    )
    add("source.reset_cold_start", reset_cold == 1, f"count={reset_cold}")

    reset_gate = exact_count(text, r"if\s*\(!rst\)\s*begin\s*case\s*\(state_q\)")
    add("source.reset_output_gate", reset_gate == 1, f"count={reset_gate}")

    illegal_gate = exact_count(
        text,
        r"wire\s+capture_valid_w\s*=\s*!request_illegal_w\s*&&\s*"
        r"\(lane0_request_w\s*\|\|\s*lane1_request_w\)\s*;",
    )
    add("source.illegal_global_fail_closed", illegal_gate == 1,
        f"count={illegal_gate}")

    idle_quiet = exact_count(text, r"default\s*:\s*begin\s*end")
    add("source.idle_no_fallthrough", idle_quiet == 1, f"count={idle_quiet}")

    rr_write_count = exact_count(text, r"\brr_q\s*<=")
    add("source.rr_only_reset_and_terminals", rr_write_count == 3,
        f"count={rr_write_count}")

    isolation_patterns = {
        "lane0_arready_default": r"lane0_axi_arready_o\s*=\s*1'b0\s*;",
        "lane1_arready_default": r"lane1_axi_arready_o\s*=\s*1'b0\s*;",
        "lane0_awready_default": r"lane0_axi_awready_o\s*=\s*1'b0\s*;",
        "lane1_awready_default": r"lane1_axi_awready_o\s*=\s*1'b0\s*;",
        "lane0_wready_default": r"lane0_axi_wready_o\s*=\s*1'b0\s*;",
        "lane1_wready_default": r"lane1_axi_wready_o\s*=\s*1'b0\s*;",
        "rready_exact_owner": (
            r"d_axi_rready_o\s*=\s*owner_q\s*\?\s*lane1_axi_rready_i\s*:\s*"
            r"lane0_axi_rready_i\s*;"
        ),
        "bready_exact_owner": (
            r"d_axi_bready_o\s*=\s*owner_q\s*\?\s*lane1_axi_bready_i\s*:\s*"
            r"lane0_axi_bready_i\s*;"
        ),
    }
    isolation_counts = {
        name: exact_count(text, pattern)
        for name, pattern in isolation_patterns.items()
    }
    response_assignment_counts = {
        "lane0_rvalid": exact_count(text, r"lane0_axi_rvalid_o\s*="),
        "lane1_rvalid": exact_count(text, r"lane1_axi_rvalid_o\s*="),
        "lane0_bvalid": exact_count(text, r"lane0_axi_bvalid_o\s*="),
        "lane1_bvalid": exact_count(text, r"lane1_axi_bvalid_o\s*="),
    }
    isolation_ok = all(count == 1 for count in isolation_counts.values()) and \
        all(count == 2 for count in response_assignment_counts.values())
    add("source.nonowner_exact_isolation", isolation_ok,
        f"defaults={isolation_counts} responses={response_assignment_counts}")

    # Marker strings are searched only after comment removal; a comment cannot
    # manufacture assertion coverage.
    assertion_markers = set(re.findall(r"\[(ARB-[A-Z0-9-]+)\]", text))
    required_markers = {
        "ARB-REQ-CLASS-ONEHOT", "ARB-OWNER-HOLD",
        "ARB-NONOWNER-ISOLATION", "ARB-AW-ONCE", "ARB-W-ONCE",
        "ARB-WRITE-TERMINAL", "ARB-READ-TERMINAL", "ARB-RSP-ONEHOT",
        "ARB-IDLE-QUIET", "ARB-RESET-QUIET", "ARB-AR-HOLD",
        "ARB-AW-HOLD", "ARB-W-HOLD", "ARB-R-HOLD", "ARB-B-HOLD",
    }
    missing = sorted(required_markers - assertion_markers)
    add("source.assertion_marker_set", not missing,
        "missing=" + (",".join(missing) if missing else "none"))
    return checks


def canonical_instantiations(vsrc: pathlib.Path, target: pathlib.Path) -> list[str]:
    hits: list[str] = []
    pattern = re.compile(
        r"\bOooDualMemAxiArbiter\s+(?:#\s*\(.*?\)\s*)?"
        r"([A-Za-z_][A-Za-z0-9_$]*)\s*\(",
        flags=re.S,
    )
    for path in sorted(list(vsrc.rglob("*.v")) + list(vsrc.rglob("*.sv"))):
        if path.resolve() == target.resolve():
            continue
        text = strip_comments(path.read_text(encoding="utf-8"))
        for match in pattern.finditer(text):
            hits.append(f"{path.relative_to(vsrc)}:{match.group(1)}")
    return hits


def claim_checks(spec_text: str, canonical_hits: list[str]) -> list[Check]:
    normalized = " ".join(spec_text.split())
    explicit_red = all(token in normalized for token in (
        "DI-5 RED", "OOO-3", "overall architecture", "PPA promotion"
    ))
    scoped = "dual_axi_miss_fabric_leaf_verified" in spec_text
    # F1 可以在未接 canonical core 的叶级 wrapper 中复用 F0；这里精确放行该
    # 单一结构实例，同时继续拒绝 core/top 或任何其它位置的提前集成。
    allowed_leaf_hits = {
        "memory/OooDualMemBridgeWrapper.v:u_miss_arbiter",
    }
    forbidden_hits = [hit for hit in canonical_hits if hit not in allowed_leaf_hits]
    allowed_hits = [hit for hit in canonical_hits if hit in allowed_leaf_hits]
    integration_ok = not forbidden_hits and len(allowed_hits) <= 1
    return [
        Check("claim.no_canonical_core_integration", integration_ok,
              "allowed_leaf_hits=" + (",".join(allowed_hits) if allowed_hits else "none")
              + ";forbidden_hits="
              + (",".join(forbidden_hits) if forbidden_hits else "none")),
        Check("claim.explicit_architecture_red", explicit_red,
              f"explicit_red={str(explicit_red).lower()}"),
        Check("claim.scoped_leaf_name", scoped,
              f"scoped_leaf_name={str(scoped).lower()}"),
    ]


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--rtl", type=pathlib.Path, required=True)
    parser.add_argument("--vsrc", type=pathlib.Path, required=True)
    parser.add_argument("--spec", type=pathlib.Path, required=True)
    parser.add_argument("--json-out", type=pathlib.Path)
    args = parser.parse_args(argv)

    rtl = args.rtl.resolve(strict=True)
    vsrc = args.vsrc.resolve(strict=True)
    spec = args.spec.resolve(strict=True)
    checks = structural_checks(rtl.read_text(encoding="utf-8"))
    checks.extend(claim_checks(
        spec.read_text(encoding="utf-8"), canonical_instantiations(vsrc, rtl)
    ))
    passed = all(check.passed for check in checks)
    payload = {
        "schema": "v8q-dual-mem-fabric-check/v1",
        "ok": passed,
        "claim": "dual_axi_miss_fabric_leaf_verified" if passed else "none",
        "architecture": {
            "DI-5": "RED",
            "OOO-3": "RED",
            "overall": "RED",
            "ppa_promotion": "forbidden",
        },
        "checks": [check.__dict__ for check in checks],
    }
    rendered = json.dumps(payload, indent=2, sort_keys=True) + "\n"
    if args.json_out:
        args.json_out.parent.mkdir(parents=True, exist_ok=True)
        args.json_out.write_text(rendered, encoding="utf-8")
    sys.stdout.write(rendered)
    return 0 if passed else 1


if __name__ == "__main__":
    raise SystemExit(main())
