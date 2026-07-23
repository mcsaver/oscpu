#!/usr/bin/env python3
"""Fail-closed structural and claim checker for v8s/F2 canonical integration."""

from __future__ import annotations

import argparse
import json
import pathlib
import re
import sys
from dataclasses import asdict, dataclass


@dataclass(frozen=True)
class Check:
    check_id: str
    passed: bool
    detail: str


def strip_comments(text: str) -> str:
    text = re.sub(r"/\*.*?\*/", "", text, flags=re.S)
    return re.sub(r"//[^\n]*", "", text)


def count(text: str, pattern: str) -> int:
    return len(re.findall(pattern, text, flags=re.S | re.M))


def extract_balanced(text: str, anchor: str) -> str:
    start = text.find(anchor)
    if start < 0:
        return ""
    open_pos = text.find("(", start + len(anchor))
    if open_pos < 0:
        return ""
    depth = 0
    for pos in range(open_pos, len(text)):
        char = text[pos]
        if char == "(":
            depth += 1
        elif char == ")":
            depth -= 1
            if depth == 0:
                semi = text.find(";", pos)
                return text[start:semi + 1] if semi >= 0 else text[start:pos + 1]
    return ""


def load_sources(repo_root: pathlib.Path) -> dict[str, str]:
    paths = {
        "backend": "npc/rv64/vsrc/execute/OooIntBackend.v",
        "rob": "npc/rv64/vsrc/writeback/OooRob.v",
        "dispatch": "npc/rv64/vsrc/rename_allocate/OooDispatchBackend.v",
        "decode": "npc/rv64/vsrc/decode/OooAluDecodeBackend.v",
        "slice": "npc/rv64/vsrc/execute/OooAluCoreSlice.v",
        "execute": "npc/rv64/vsrc/execute/OooExecuteBackend.v",
        "glue": "npc/rv64/vsrc/core/OooCoreTopGlue.v",
        "core": "npc/rv64/vsrc/core/NpcCoreTop.v",
        "sim": "npc/rv64/vsrc/sim/NpcSimTop.sv",
        "wrapper": "npc/rv64/vsrc/memory/OooDualMemBridgeWrapper.v",
        "tracker": "npc/rv64/vsrc/memory/OooMemOwnerTracker.v",
        "collector": "npc/rv64/vsrc/memory/OooMemOwnerTerminalCollector.v",
        "tb": "npc/rv64/testbench/tests/tb_ooo_int_backend.sv",
        "spec": "npc/rv64/design/specs/ooo-dual-memory-datapath.md",
        "contract": (
            ".github/task-runs/2026-07-20-rv64-v8s-dual-memory-"
            "core-integration/contract.md"
        ),
    }
    result: dict[str, str] = {}
    root = repo_root.resolve(strict=True)
    for key, relative in paths.items():
        path = (root / relative).resolve(strict=True)
        try:
            path.relative_to(root)
        except ValueError as exc:
            raise SystemExit(f"source escaped repository: {path}") from exc
        result[key] = path.read_text(encoding="utf-8")
    return result


def terminal_topology(text: str) -> tuple[str, dict[str, int]]:
    """Classify only exact, mutually exclusive F2/F3 collector shapes."""
    backend = strip_comments(text)
    fragments = {
        "collector10": count(
            backend, r"OooMemOwnerTerminalCollector\s*#\s*\(\s*"
            r"\.INGRESS_N\s*\(\s*10\s*\)",
        ),
        "collector12": count(
            backend, r"OooMemOwnerTerminalCollector\s*#\s*\(\s*"
            r"\.INGRESS_N\s*\(\s*12\s*\)",
        ),
        "valid10": count(
            backend, r"wire\s*\[9:0\]\s+mem_terminal_ingress_valid_w"
        ),
        "valid12": count(
            backend, r"wire\s*\[11:0\]\s+mem_terminal_ingress_valid_w"
        ),
        "kind10": count(
            backend, r"wire\s*\[19:0\]\s+mem_terminal_ingress_kind_w"
        ),
        "kind12": count(
            backend, r"wire\s*\[23:0\]\s+mem_terminal_ingress_kind_w"
        ),
        "token10": count(
            backend, r"wire\s*\[49:0\]\s+mem_terminal_ingress_token_w"
        ),
        "token12": count(
            backend, r"wire\s*\[59:0\]\s+mem_terminal_ingress_token_w"
        ),
        "epoch10": count(
            backend, r"wire\s*\[19:0\]\s+mem_terminal_ingress_epoch_w"
        ),
        "epoch12": count(
            backend, r"wire\s*\[23:0\]\s+mem_terminal_ingress_epoch_w"
        ),
        "mask10_decl": count(
            backend, r"wire\s*\[31:0\]\s+mem_terminal_ingress10_mask_w"
        ),
        "mask11_decl": count(
            backend, r"wire\s*\[31:0\]\s+mem_terminal_ingress11_mask_w"
        ),
        "retry0_terminal": count(
            backend,
            r"wire\s+mem_retry0_tagged_terminal_w\s*=\s*"
            r"mem_retry0_cancel_w\s*;",
        ),
        "retry1_terminal": count(
            backend,
            r"wire\s+mem_retry1_tagged_terminal_w\s*=\s*"
            r"mem_retry1_cancel_w\s*;",
        ),
        "valid_retry_head": count(
            backend,
            r"assign\s+mem_terminal_ingress_valid_w\s*=\s*\{\s*"
            r"mem_retry1_tagged_terminal_w\s*,\s*"
            r"mem_retry0_tagged_terminal_w\s*,\s*"
            r"mem_amo_interphase_cancel_w",
        ),
        "kind_retry_head": count(
            backend,
            r"assign\s+mem_terminal_ingress_kind_w\s*=\s*\{\s*"
            r"mem_retry1_owner_kind_q\s*,\s*mem_retry0_owner_kind_q",
        ),
        "token_retry_head": count(
            backend,
            r"assign\s+mem_terminal_ingress_token_w\s*=\s*\{\s*"
            r"mem_retry1_owner_token_q\s*,\s*mem_retry0_owner_token_q",
        ),
        "epoch_retry_head": count(
            backend,
            r"assign\s+mem_terminal_ingress_epoch_w\s*=\s*\{\s*"
            r"mem_retry1_mmu_epoch_q\s*,\s*mem_retry0_mmu_epoch_q",
        ),
        "mask10_assign": count(
            backend,
            r"assign\s+mem_terminal_ingress10_mask_w\s*=\s*"
            r"mem_retry0_tagged_terminal_w\s*\?\s*"
            r"\(32'b1\s*<<\s*mem_retry0_owner_token_q\)\s*:\s*32'b0\s*;",
        ),
        "mask11_assign": count(
            backend,
            r"assign\s+mem_terminal_ingress11_mask_w\s*=\s*"
            r"mem_retry1_tagged_terminal_w\s*\?\s*"
            r"\(32'b1\s*<<\s*mem_retry1_owner_token_q\)\s*:\s*32'b0\s*;",
        ),
    }
    f2_shape = (
        all(fragments[key] == 1 for key in (
            "collector10", "valid10", "kind10", "token10", "epoch10",
        ))
        and all(fragments[key] == 0 for key in (
            "collector12", "valid12", "kind12", "token12", "epoch12",
            "mask10_decl", "mask11_decl", "retry0_terminal",
            "retry1_terminal", "valid_retry_head", "kind_retry_head",
            "token_retry_head", "epoch_retry_head", "mask10_assign",
            "mask11_assign",
        ))
    )
    f3_shape = (
        all(fragments[key] == 1 for key in (
            "collector12", "valid12", "kind12", "token12", "epoch12",
            "mask10_decl", "mask11_decl", "retry0_terminal",
            "retry1_terminal", "valid_retry_head", "kind_retry_head",
            "token_retry_head", "epoch_retry_head", "mask10_assign",
            "mask11_assign",
        ))
        and all(fragments[key] == 0 for key in (
            "collector10", "valid10", "kind10", "token10", "epoch10",
        ))
    )
    if f2_shape == f3_shape:
        return "INVALID", fragments
    return ("F2_BASE" if f2_shape else "F3_EXTENDED"), fragments


def structural_checks(sources: dict[str, str]) -> list[Check]:
    code = {key: strip_comments(value) for key, value in sources.items()
            if key not in {"spec", "contract"}}
    backend = code["backend"]
    core = code["core"]
    tb = code["tb"]
    checks: list[Check] = []

    def add(check_id: str, passed: bool, detail: str) -> None:
        checks.append(Check(check_id, bool(passed), detail))

    chain = ["backend", "decode", "slice", "execute", "glue"]
    default_counts = {
        key: count(code[key], r"parameter\s+ENABLE_DUAL_MEM\s*=\s*0")
        for key in chain
    }
    add(
        "hierarchy.default_off_reusable_chain",
        all(value == 1 for value in default_counts.values()),
        f"counts={default_counts}",
    )

    handoff_counts = {
        key: count(
            code[key],
            r"\.ENABLE_DUAL_MEM\s*\(\s*ENABLE_DUAL_MEM\s*\)",
        )
        for key in ["decode", "slice", "execute", "glue"]
    }
    add(
        "hierarchy.explicit_parameter_handoff",
        all(value == 1 for value in handoff_counts.values()),
        f"counts={handoff_counts}",
    )

    canonical_enable = count(
        core, r"\.ENABLE_DUAL_MEM\s*\(\s*1\s*\)"
    )
    add(
        "hierarchy.canonical_enable_exactly_once",
        canonical_enable == 1,
        f"count={canonical_enable}",
    )

    topology = {
        "dual_wrapper": count(
            core,
            r"\bOooDualMemBridgeWrapper\s+u_ooo_dual_mem_bridge\s*\(",
        ),
        "legacy_bridge": count(
            core, r"\bOooMemAxiBridge\s+u_ooo_mem_bridge\s*\("
        ),
        "core_glue": count(core, r"\bOooCoreTopGlue\s*#\s*\("),
    }
    add(
        "hierarchy.canonical_dual_wrapper_topology",
        topology == {"dual_wrapper": 1, "legacy_bridge": 0, "core_glue": 1},
        f"counts={topology}",
    )

    wrapper_block = extract_balanced(
        core, "OooDualMemBridgeWrapper u_ooo_dual_mem_bridge"
    )
    lane_connections = re.findall(
        r"\.lane([01])_[A-Za-z0-9_]+\s*\(\s*([^()]+?)\s*\)",
        wrapper_block,
        flags=re.S,
    )
    lane0 = [expr for lane, expr in lane_connections if lane == "0"]
    lane1 = [expr for lane, expr in lane_connections if lane == "1"]
    lane0_exact = len(lane0) >= 55 and all(
        (("ooo_mem0_" in expr and "ooo_mem1_" not in expr)
         or expr.strip() == "ooo_mem_translate_active_w")
        for expr in lane0
    )
    lane1_exact = len(lane1) >= 55 and all(
        "ooo_mem1_" in expr and "ooo_mem0_" not in expr for expr in lane1
    )
    add(
        "hierarchy.wrapper_lane_faces_not_crossed",
        lane0_exact and lane1_exact,
        f"lane0={len(lane0)} exact={lane0_exact} "
        f"lane1={len(lane1)} exact={lane1_exact}",
    )

    core_block = extract_balanced(core, ") u_ooo_core")
    # extract_balanced starts at the parameter close anchor only when present;
    # fall back to the unique instance name for formatting changes.
    if not core_block:
        core_block = extract_balanced(core, "u_ooo_core")
    mem1_ports = re.findall(
        r"\.mem1_[A-Za-z0-9_]+\s*\(\s*([^()]+?)\s*\)",
        core,
        flags=re.S,
    )
    add(
        "hierarchy.core_mem1_face_not_tied_or_crossed",
        len(mem1_ports) >= 55 and all(
            "ooo_mem1_" in expr and "ooo_mem0_" not in expr
            for expr in mem1_ports
        ),
        f"port_count={len(mem1_ports)}",
    )

    miq_topology = {
        "instances": count(backend, r"\bOooMemInflightQueue\s*#\s*\("),
        "bank0": count(backend, r"\bu_mem_inflight_queue\s*\("),
        "bank1": count(backend, r"\bu_mem1_inflight_queue\s*\("),
    }
    add(
        "backend.two_independent_miq_instances",
        miq_topology == {"instances": 2, "bank0": 1, "bank1": 1},
        f"counts={miq_topology}",
    )

    query_fragments = {
        "rob_port": count(
            code["rob"], r"completion7_query_producer_id_i"
        ),
        "dispatch_pass": count(
            code["dispatch"],
            r"\.completion7_query_producer_id_i\s*\(\s*"
            r"completion7_query_producer_id_i\s*\)",
        ),
        "mem1_query": count(
            backend,
            r"\.completion7_query_producer_id_i\s*\(\s*"
            r"mem1_completion_producer_id_w\s*\)",
        ),
        "mem1_match": count(
            backend,
            r"\.completion7_query_match_o\s*\(\s*"
            r"mem1_completion_rob_open_w\s*\)",
        ),
    }
    add(
        "backend.independent_mem1_rob_open_query",
        query_fragments["rob_port"] >= 3
        and all(query_fragments[key] == 1
                for key in ("dispatch_pass", "mem1_query", "mem1_match")),
        f"counts={query_fragments}",
    )

    allocator_fragments = {
        "bank0_bit": count(
            backend,
            r"wire\s+issue0_dual_bank1_w\s*=\s*issue0_mem_addr_w\[3\]\s*;",
        ),
        "bank1_bit": count(
            backend,
            r"wire\s+issue1_dual_bank1_w\s*=\s*issue1_mem_addr_w\[3\]\s*;",
        ),
        "same_bank": count(backend, r"wire\s+dual_ordinary_same_bank_w"),
        "rob_age": count(backend, r"rob_idx_older_than\s*\("),
        "mem1_valid": count(
            backend,
            r"assign\s+mem1_req_valid_o\s*=\s*ENABLE_DUAL_MEM\s*&&",
        ),
        "fire0": count(backend, r"wire\s+mem_req_fire_any_w"),
        "fire1": count(backend, r"wire\s+mem1_req_fire_any_w"),
    }
    add(
        "backend.captured_bit3_age_request_allocator",
        allocator_fragments["bank0_bit"] == 1
        and allocator_fragments["bank1_bit"] == 1
        and allocator_fragments["same_bank"] == 1
        and allocator_fragments["rob_age"] >= 2
        and allocator_fragments["mem1_valid"] == 1
        and allocator_fragments["fire0"] == 1
        and allocator_fragments["fire1"] == 1,
        f"counts={allocator_fragments}",
    )

    response_fragments = {
        "mem0_slot0": count(backend, r"wire\s+mem_wb_slot0_grant_w"),
        "mem0_slot1": count(backend, r"wire\s+mem_wb_slot1_grant_w"),
        "mem1_slot0": count(backend, r"wire\s+mem1_wb_slot0_grant_w"),
        "mem1_slot1": count(backend, r"wire\s+mem1_wb_slot1_grant_w"),
        "mem1_ready": count(backend, r"assign\s+mem1_rsp_ready_o\s*="),
        "wb0_mem1": count(backend, r"mem1_wb0_valid_w"),
        "wb1_mem1": count(backend, r"mem1_wb1_valid_w"),
    }
    add(
        "backend.one_global_two_slot_response_allocator",
        all(response_fragments[key] == 1 for key in (
            "mem0_slot0", "mem0_slot1", "mem1_slot0", "mem1_slot1",
            "mem1_ready",
        ))
        and response_fragments["wb0_mem1"] >= 3
        and response_fragments["wb1_mem1"] >= 3,
        f"counts={response_fragments}",
    )

    terminal_stage, terminal_fragments = terminal_topology(backend)
    shared_terminal_fragments = {
        "drop0": count(backend, r"mem_drop0_valid_i"),
        "drop1": count(backend, r"mem_drop1_valid_i"),
        "drop10": count(backend, r"mem1_drop0_valid_i"),
        "drop11": count(backend, r"mem1_drop1_valid_i"),
    }
    add(
        "backend.lossless_stage_terminal_set",
        terminal_stage in {"F2_BASE", "F3_EXTENDED"}
        and all(shared_terminal_fragments[key] >= 3 for key in (
            "drop0", "drop1", "drop10", "drop11"
        )),
        f"stage={terminal_stage} topology={terminal_fragments} "
        f"shared={shared_terminal_fragments}",
    )

    sq_singleton_fragments = {
        "fill1": count(backend, r"\.fill1_valid_i\s*\(\s*sq_fill1_valid_w\s*\)"),
        "terminal1": count(
            backend,
            r"\.terminal1_valid_i\s*\(\s*sq_terminal1_valid_w\s*\)",
        ),
        "both_miq_empty": count(
            backend,
            r"mem_legacy_slot_open_w\s*&&\s*miq_empty_w\s*&&\s*miq1_empty_w",
        ),
        "dual_release_no_lookthrough": count(
            backend,
            r"wire\s+mem_legacy_slot_open_w\s*=\s*ENABLE_DUAL_MEM\s*\?\s*"
            r"!mem_pending_q\s*:",
        ),
        "singleton_priority": count(
            backend,
            r"!grant_sq_w\s*&&\s*!grant_amo_write_w\s*&&\s*!grant_buffer_w",
        ),
    }
    add(
        "backend.dual_sq_ports_and_singleton_exclusion",
        sq_singleton_fragments["fill1"] == 1
        and sq_singleton_fragments["terminal1"] == 1
        and sq_singleton_fragments["both_miq_empty"] == 1
        and sq_singleton_fragments["dual_release_no_lookthrough"] == 1
        and sq_singleton_fragments["singleton_priority"] >= 4,
        f"counts={sq_singleton_fragments}",
    )

    holder_fragments = {
        "miq_union": count(
            backend,
            r"miq_occupancy_token_mask_w\s*\|\s*miq1_occupancy_token_mask_w",
        ),
        "bridge0": count(backend, r"mem_bridge_owner_residency_mask_i"),
        "bridge1": count(backend, r"mem1_bridge_owner_residency_mask_i"),
        "disjoint_marker": count(backend, r"V8S-DUAL-MIQ-TOKEN-DISJOINT"),
    }
    add(
        "backend.cross_bank_holder_census_and_disjoint_assert",
        holder_fragments["miq_union"] >= 1
        and holder_fragments["bridge0"] >= 3
        and holder_fragments["bridge1"] >= 3
        and holder_fragments["disjoint_marker"] == 1,
        f"counts={holder_fragments}",
    )

    sim_fragments = {
        "bridge0": count(code["sim"], r"u_ooo_dual_mem_bridge\.u_bridge0"),
        "bridge1": count(code["sim"], r"u_ooo_dual_mem_bridge\.u_bridge1"),
        "req0": count(code["sim"], r"u_bridge0\.mem0_req_fire_w"),
        "req1": count(code["sim"], r"u_bridge1\.mem0_req_fire_w"),
        "rsp0": count(code["sim"], r"ooo_mem0_rsp_valid_w"),
        "rsp1": count(code["sim"], r"ooo_mem1_rsp_valid_w"),
    }
    add(
        "hierarchy.sim_observability_covers_both_banks",
        sim_fragments["bridge0"] >= 2
        and sim_fragments["bridge1"] >= 2
        and all(sim_fragments[key] >= 1 for key in (
            "req0", "req1", "rsp0", "rsp1"
        )),
        f"counts={sim_fragments}",
    )

    tb_required = {
        token: token in tb
        for token in (
            "V8S_DUAL_MEMORY_FOCUSED",
            ".ENABLE_DUAL_MEM(TB_ENABLE_DUAL_MEM)",
            "[V8S-REVERSE-BACKPRESSURE]",
            "[V8S-ROB-WRAP-AGE]",
            "[V8S-DUAL-EX-WB-HOLD]",
            "[V8S-DUAL-STORE-PROBE]",
            "[V8S-SINGLETON-EXCLUSION]",
            "[V8S-SELECTIVE-KILL-RACE]",
            "[V8S-DUAL-MEMORY-CORE]",
        )
    }
    add(
        "tb.focused_parameter_and_behavior_oracles",
        all(tb_required.values()),
        f"tokens={tb_required}",
    )

    return checks


def claim_checks(sources: dict[str, str]) -> list[Check]:
    spec = sources["spec"]
    contract = sources["contract"]
    terminal_stage, _ = terminal_topology(sources["backend"])
    f3_markers = {
        "absent": "- F3: absent" in spec,
        "candidate": "- F3: candidate" in spec,
        "checkpoint": (
            "- F3: checkpoint" in spec
            or "- F3: `final_pa_sq_ordering_checkpoint`" in spec
        ),
    }
    f3_state_consistent = (
        sum(f3_markers.values()) == 1
        and (
            (terminal_stage == "F2_BASE" and f3_markers["absent"])
            or (
                terminal_stage == "F3_EXTENDED"
                and (f3_markers["candidate"] or f3_markers["checkpoint"])
            )
        )
    )
    required = {
        "checkpoint": "Current F2 claim: `architecture_checkpoint`" in spec,
        "di5_red": "- DI-5: RED" in spec,
        "ooo3_red": "- OOO-3: RED" in spec,
        "overall_red": "- overall architecture: RED" in spec,
        "ppa_unqualified": "- PPA: unqualified" in spec,
        "promotion_false": "- promotion_eligible=false" in spec,
        "f3_state_consistent": f3_state_consistent,
        "f4_absent": "- F4: absent" in spec,
        "contract_checkpoint": "`architecture_checkpoint`" in contract,
    }
    forbidden_patterns = {
        "f2_complete": r"\bF2[- _]complete\b",
        "di5_green": r"DI-5\s*(?::|=|is)\s*GREEN",
        "ooo3_green": r"OOO-3\s*(?::|=|is)\s*GREEN",
        "ppa_green": r"PPA\s*(?::|=|is)\s*GREEN",
        "promotion_true": r"promotion_eligible\s*=\s*true",
    }
    forbidden = {
        key: bool(re.search(pattern, spec, flags=re.I))
        for key, pattern in forbidden_patterns.items()
    }
    return [
        Check(
            "claim.explicit_checkpoint_red_unqualified_boundary",
            all(required.values()),
            f"required={required}",
        ),
        Check(
            "claim.no_f2_or_promotion_overclaim",
            not any(forbidden.values()),
            f"forbidden={forbidden}",
        ),
    ]


def evaluate(sources: dict[str, str]) -> list[Check]:
    return structural_checks(sources) + claim_checks(sources)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--repo-root", type=pathlib.Path, required=True)
    parser.add_argument("--json-out", type=pathlib.Path)
    args = parser.parse_args()

    sources = load_sources(args.repo_root)
    checks = evaluate(sources)
    terminal_stage, terminal_fragments = terminal_topology(sources["backend"])
    payload = {
        "schema": "rv64-v8s-f2-source-check-v1",
        "passed": all(item.passed for item in checks),
        "detected_extension_stage": terminal_stage,
        "terminal_topology": terminal_fragments,
        "checks": [asdict(item) for item in checks],
    }
    if args.json_out:
        args.json_out.parent.mkdir(parents=True, exist_ok=True)
        args.json_out.write_text(
            json.dumps(payload, indent=2, sort_keys=True) + "\n",
            encoding="utf-8",
        )
    for item in checks:
        status = "PASS" if item.passed else "FAIL"
        print(f"[V8S-CHECK][{status}] {item.check_id}: {item.detail}")
    if payload["passed"]:
        print("[V8S-CHECK][PASS] architecture_checkpoint source closure")
        return 0
    print("[V8S-CHECK][FAIL] source closure rejected", file=sys.stderr)
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
