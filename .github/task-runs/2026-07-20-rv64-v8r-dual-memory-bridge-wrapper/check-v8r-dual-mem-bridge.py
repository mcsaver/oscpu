#!/usr/bin/env python3
"""Fail-closed structural and claim checker for the v8r/F1 leaf."""

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


def load_sources(repo_root: pathlib.Path) -> dict[str, str]:
    paths = {
        "wrapper": "npc/rv64/vsrc/memory/OooDualMemBridgeWrapper.v",
        "bridge": "npc/rv64/vsrc/memory/OooMemAxiBridge.v",
        "dcache": "npc/rv64/vsrc/cache/OooDataWordCache.v",
        "wrapper_tb": "npc/rv64/testbench/tests/tb_ooo_dual_mem_bridge_wrapper.sv",
        "dcache_tb": "npc/rv64/testbench/tests/tb_ooo_data_word_cache.sv",
        "filelist": "npc/rv64/vsrc/filelist.mk",
        "spec": "npc/rv64/design/specs/ooo-dual-memory-datapath.md",
        "core": "npc/rv64/vsrc/core/NpcCoreTop.v",
        "top": "npc/rv64/vsrc/core/NpcTop.v",
        "f2_contract": (
            ".github/task-runs/2026-07-20-rv64-v8s-dual-memory-core-"
            "integration/contract.md"
        ),
    }
    result: dict[str, str] = {}
    for key, relative in paths.items():
        path = (repo_root / relative).resolve(strict=True)
        try:
            path.relative_to(repo_root)
        except ValueError as exc:
            raise SystemExit(f"source escaped repository: {path}") from exc
        result[key] = path.read_text(encoding="utf-8")
    return result


def structural_checks(sources: dict[str, str]) -> list[Check]:
    wrapper = strip_comments(sources["wrapper"])
    bridge = strip_comments(sources["bridge"])
    dcache = strip_comments(sources["dcache"])
    wrapper_tb = strip_comments(sources["wrapper_tb"])
    dcache_tb = strip_comments(sources["dcache_tb"])
    filelist = strip_comments(sources["filelist"])
    checks: list[Check] = []

    def add(check_id: str, passed: bool, detail: str) -> None:
        checks.append(Check(check_id, bool(passed), detail))

    wrapper_modules = count(
        wrapper, r"\bmodule\s+OooDualMemBridgeWrapper\s*\("
    )
    add("wrapper.one_nonempty_module",
        wrapper_modules == 1 and len(wrapper.strip()) > 5000,
        f"module_count={wrapper_modules} stripped_bytes={len(wrapper.strip())}")

    instance_counts = {
        "bridge0": count(
            wrapper,
            r"\bOooMemAxiBridge\s*#\s*\(\s*"
            r"\.ENABLE_PEER_INVALIDATE\s*\(\s*1\s*\)\s*\)\s*"
            r"u_bridge0\s*\(",
        ),
        "bridge1": count(
            wrapper,
            r"\bOooMemAxiBridge\s*#\s*\(\s*"
            r"\.ENABLE_PEER_INVALIDATE\s*\(\s*1\s*\)\s*\)\s*"
            r"u_bridge1\s*\(",
        ),
        "arbiter": count(
            wrapper, r"\bOooDualMemAxiArbiter\s+u_miss_arbiter\s*\("
        ),
    }
    add("wrapper.fixed_instance_topology",
        all(value == 1 for value in instance_counts.values()),
        f"counts={instance_counts}")

    cross_patterns = {
        "b0_valid_from_b1":
            r"\.peer_invalidate_valid_i\(lane1_peer_maintenance_valid_w\)",
        "b0_addr_from_b1":
            r"\.peer_invalidate_addr_i\(lane1_peer_maintenance_addr_w\)",
        "b0_wstrb_from_b1":
            r"\.peer_invalidate_wstrb_i\(lane1_peer_maintenance_wstrb_w\)",
        "b1_valid_from_b0":
            r"\.peer_invalidate_valid_i\(lane0_peer_maintenance_valid_w\)",
        "b1_addr_from_b0":
            r"\.peer_invalidate_addr_i\(lane0_peer_maintenance_addr_w\)",
        "b1_wstrb_from_b0":
            r"\.peer_invalidate_wstrb_i\(lane0_peer_maintenance_wstrb_w\)",
    }
    cross_counts = {key: count(wrapper, value)
                    for key, value in cross_patterns.items()}
    add("wrapper.maintenance_exact_cross",
        all(value == 1 for value in cross_counts.values()),
        f"counts={cross_counts}")

    lane_boundary_patterns = {
        "ready0": r"assign\s+lane0_req_ready_o\s*=\s*lane0_req_ready_w\s*;",
        "ready1": r"assign\s+lane1_req_ready_o\s*=\s*lane1_req_ready_w\s*;",
        "rsp0": r"assign\s+lane0_rsp_valid_o\s*=\s*lane0_rsp_valid_w\s*;",
        "rsp1": r"assign\s+lane1_rsp_valid_o\s*=\s*lane1_rsp_valid_w\s*;",
    }
    boundary_counts = {key: count(wrapper, pattern)
                       for key, pattern in lane_boundary_patterns.items()}
    add("wrapper.independent_ready_response",
        all(value == 1 for value in boundary_counts.values()),
        f"counts={boundary_counts}")

    common_fanout = {
        "mmu_flush": count(wrapper, r"\.mmu_flush_i\(mmu_flush_i\)"),
        "dma": count(
            wrapper,
            r"\.dcache_dma_invalidate_all_i\(dcache_dma_invalidate_all_i\)",
        ),
        "flush": count(wrapper, r"\.flush_i\(flush_i\)"),
    }
    add("wrapper.common_context_dual_fanout",
        common_fanout == {"mmu_flush": 2, "dma": 2, "flush": 2},
        f"counts={common_fanout}")

    wrapper_markers = set(re.findall(r"\[(DMBW-[A-Z0-9-]+)\]", wrapper))
    required_wrapper_markers = {
        "DMBW-MMU-FLUSH-NONIDLE", "DMBW-MMU-FLUSH-READY"
    }
    add("wrapper.mmu_carrying_assertions",
        required_wrapper_markers <= wrapper_markers,
        f"missing={sorted(required_wrapper_markers - wrapper_markers)}")

    bridge_param = count(
        bridge, r"parameter\s+ENABLE_PEER_INVALIDATE\s*=\s*0"
    )
    bridge_ports = {
        name: count(bridge, rf"\b(?:input|output)\b[^;]*\b{name}\b")
        for name in (
            "peer_invalidate_valid_i", "peer_invalidate_addr_i",
            "peer_invalidate_wstrb_i", "peer_maintenance_valid_o",
            "peer_maintenance_addr_o", "peer_maintenance_wstrb_o",
        )
    }
    add("bridge.default_off_peer_boundary",
        bridge_param == 1 and all(value == 1 for value in bridge_ports.values()),
        f"parameter={bridge_param} ports={bridge_ports}")

    authority_counts = {
        "valid": count(
            bridge,
            r"assign\s+peer_maintenance_valid_o\s*=\s*"
            r"dcache_store_commit_w\s*;",
        ),
        "addr": count(
            bridge,
            r"assign\s+peer_maintenance_addr_o\s*=\s*"
            r"dcache_store_addr_w\s*;",
        ),
        "wstrb": count(
            bridge,
            r"assign\s+peer_maintenance_wstrb_o\s*=\s*"
            r"dcache_store_wstrb_w\s*;",
        ),
        "cache_parameter": count(
            bridge,
            r"\.ENABLE_PEER_INVALIDATE\(ENABLE_PEER_INVALIDATE\)",
        ),
    }
    add("bridge.direct_authorized_maintenance",
        all(value == 1 for value in authority_counts.values()),
        f"counts={authority_counts}")

    bridge_markers = set(re.findall(r"\[(BRG-PEER-[A-Z0-9-]+)\]", bridge))
    required_bridge_markers = {"BRG-PEER-MAINT-AUTH", "BRG-PEER-WSTRB"}
    add("bridge.peer_assertion_set",
        required_bridge_markers <= bridge_markers,
        f"missing={sorted(required_bridge_markers - bridge_markers)}")

    dcache_param = count(
        dcache, r"parameter\s+ENABLE_PEER_INVALIDATE\s*=\s*0"
    )
    event_gate = count(
        dcache,
        r"wire\s+peer_invalidate_event_w\s*=\s*"
        r"\(ENABLE_PEER_INVALIDATE\s*!=\s*0\)\s*&&\s*"
        r"peer_invalidate_valid_i\s*;",
    )
    add("dcache.parameter_gated_peer_event",
        dcache_param == 1 and event_gate == 1,
        f"parameter={dcache_param} event_gate={event_gate}")

    legal_masks = all(token in dcache for token in (
        "8'h01", "8'h03", "8'h0f", "8'hff"
    ))
    cross_formula = count(
        dcache,
        r"wire\s+peer_cross_w\s*=\s*"
        r"\(\{1'b0,\s*peer_invalidate_addr_i\[2:0\]\}\s*\+\s*"
        r"peer_nbytes_w\)\s*>\s*5'd8\s*;",
    )
    add("dcache.normalized_mask_span",
        legal_masks and cross_formula == 1,
        f"legal_masks={legal_masks} cross_formula={cross_formula}")

    hit_mask = count(
        dcache,
        r"!dma_invalidate_all_i\s*&&\s*!peer_lookup_conflict_w\s*;",
    )
    exact_compare = all(fragment in dcache for fragment in (
        "lookup_idx_q == peer_idx0_w", "lookup_tag_q == line_tag(peer_line0_addr_w)",
        "lookup_idx_q == peer_idx1_w", "lookup_tag_q == line_tag(peer_line1_addr_w)",
    ))
    add("dcache.same_cycle_exact_hit_block",
        hit_mask == 1 and exact_compare,
        f"hit_mask={hit_mask} exact_compare={exact_compare}")

    merge_anchor = (
        "if (peer_invalidate_apply_w) begin\n"
        "        valid_q[peer_idx0_w] <= 1'b0;\n"
        "        if (peer_cross_w)\n"
        "          valid_q[peer_idx1_w] <= 1'b0;\n"
        "      end"
    )
    fill_pos = dcache.find("if (fill_we_w)")
    last_fill_pos = dcache.rfind("if (fill_we_w)")
    peer_pos = dcache.find(merge_anchor)
    dma_outer = count(
        dcache,
        r"else\s+if\s*\(dma_invalidate_all_i\)\s*begin\s*"
        r"valid_q\s*<=\s*\{ENTRY_COUNT\{1'b0\}\}\s*;\s*end\s+else\s+begin",
    )
    add("dcache.per_entry_clear_wins_merge",
        fill_pos >= 0 and peer_pos > fill_pos and last_fill_pos < peer_pos
        and dcache.count(merge_anchor) == 1
        and dma_outer == 1,
        f"fill_pos={fill_pos} last_fill_pos={last_fill_pos} peer_pos={peer_pos} "
        f"peer_count={dcache.count(merge_anchor)} dma_outer={dma_outer}")

    sram_rhs_match = re.search(r"wire\s+sram_en_w\s*=\s*(.*?)\s*;", dcache, re.S)
    sram_rhs = sram_rhs_match.group(1) if sram_rhs_match else ""
    add("dcache.peer_not_sram_owner",
        bool(sram_rhs_match) and "peer" not in sram_rhs,
        f"sram_rhs={sram_rhs!r}")

    dcache_markers = set(re.findall(r"\[(DWC-PEER-[A-Z0-9-]+)\]", dcache))
    required_dcache_markers = {
        "DWC-PEER-WSTRB", "DWC-PEER-HIT-BLOCK",
        "DWC-PEER-NO-SRAM-OWNER", "DWC-PEER-INVALIDATE",
    }
    add("dcache.peer_assertion_set",
        required_dcache_markers <= dcache_markers,
        f"missing={sorted(required_dcache_markers - dcache_markers)}")

    parameter_instances = {
        "enabled": count(
            dcache_tb, r"\.ENABLE_PEER_INVALIDATE\s*\(\s*1\s*\)"
        ),
        "disabled": count(
            dcache_tb, r"\.ENABLE_PEER_INVALIDATE\s*\(\s*0\s*\)"
        ),
    }
    add("tb.parameter_on_off_closure",
        parameter_instances == {"enabled": 1, "disabled": 1},
        f"counts={parameter_instances}")

    required_tb_tokens = {
        "dual_hot_ready_matrix", "hit_under_peer_miss",
        "peer_store_terminal_overlap", "peer_store_error_invalidate",
        "peer_cross_line_invalidate", "dma_same_cycle_dual_lookup",
        "mmu_flush_dual_dtlb_rewalk", "sampled_reset_overlap",
        "OOO_DMBW_MMU_FLUSH_NONIDLE_NEGATIVE",
    }
    missing_tb = sorted(token for token in required_tb_tokens
                        if token not in wrapper_tb)
    add("tb.wrapper_counterexample_matrix", not missing_tb,
        f"missing={missing_tb}")

    required_dcache_tb_tokens = {
        "peer_invalidate_conflicts", "mask/offset enumeration",
        "OOO_DWC_PEER_INVALID_MASK_NEGATIVE", "parameter-off",
    }
    missing_dcache_tb = sorted(token for token in required_dcache_tb_tokens
                               if token not in sources["dcache_tb"])
    add("tb.dcache_counterexample_matrix", not missing_dcache_tb,
        f"missing={missing_dcache_tb}")

    filelist_counts = {
        "definition": count(
            filelist,
            r"RTL_OOO_DUAL_MEM_BRIDGE_WRAPPER\s*:=\s*"
            r"\$\(RTL_MEMORY_DIR\)/OooDualMemBridgeWrapper\.v",
        ),
        "catalog": count(filelist, r"\$\(RTL_OOO_DUAL_MEM_BRIDGE_WRAPPER\)"),
    }
    add("source.filelist_catalogued_once",
        filelist_counts == {"definition": 1, "catalog": 1},
        f"counts={filelist_counts}")
    return checks


def canonical_stage_facts(sources: dict[str, str]) -> dict[str, object]:
    core = strip_comments(sources["core"])
    top = strip_comments(sources["top"])
    canonical = core + "\n" + top
    wrapper_refs = count(canonical, r"\bOooDualMemBridgeWrapper\b")
    wrapper_instances = count(
        canonical,
        r"\bOooDualMemBridgeWrapper\s+u_ooo_dual_mem_bridge\s*\(",
    )
    legacy_bridge_instances = count(
        core, r"\bOooMemAxiBridge\s+u_ooo_mem_bridge\s*\("
    )
    canonical_enable_count = count(
        core, r"\.ENABLE_DUAL_MEM\s*\(\s*1\s*\)"
    )
    f1_unintegrated = (
        wrapper_refs == 0
        and wrapper_instances == 0
        and legacy_bridge_instances == 1
        and canonical_enable_count == 0
    )
    f2_promoted = (
        wrapper_refs == 1
        and wrapper_instances == 1
        and legacy_bridge_instances == 0
        and canonical_enable_count == 1
    )
    if f1_unintegrated:
        stage = "F1_UNINTEGRATED"
    elif f2_promoted:
        stage = "F2_PROMOTED"
    else:
        stage = "INVALID"
    return {
        "stage": stage,
        "wrapper_refs": wrapper_refs,
        "wrapper_instances": wrapper_instances,
        "legacy_bridge_instances": legacy_bridge_instances,
        "canonical_enable_count": canonical_enable_count,
        "f1_unintegrated": f1_unintegrated,
        "f2_promoted": f2_promoted,
    }


def claim_checks(sources: dict[str, str]) -> list[Check]:
    facts = canonical_stage_facts(sources)
    spec = " ".join(sources["spec"].split())
    f2_contract = " ".join(sources["f2_contract"].split())
    leaf_boundary_tokens = {
        "leaf": "dual_bridge_cache_hit_leaf_verified" in spec,
        "di5_red": bool(re.search(
            r"DI-5(?:/|、).*?OOO-3(?:/|、).*?overall.{0,100}?RED", spec
        )),
        "ppa": "PPA unqualified" in spec,
    }
    historical_f1_tokens = {
        "not_core": "未接入 canonical core" in spec,
        "f1_scope": "v8r/F1" in spec,
    }
    f2_handoff_tokens = {
        "contract_title": (
            "v8s/F2 canonical dual-memory integration contract" in f2_contract
        ),
        "contract_claim": "`architecture_checkpoint`" in f2_contract,
        "contract_red_unqualified": bool(re.search(
            r"DI-5.*?OOO-3.*?overall architecture.*?PPA.*?"
            r"RED/unqualified",
            f2_contract,
        )),
        "contract_missing_f3_f4": (
            "final-PA SQ" in f2_contract and "64-cycle IPC" in f2_contract
        ),
        "spec_claim": (
            "Current F2 claim: `architecture_checkpoint`." in spec
        ),
        "spec_di5_red": "DI-5: RED" in spec,
        "spec_ooo3_red": "OOO-3: RED" in spec,
        "spec_overall_red": "overall architecture: RED" in spec,
        "spec_ppa_unqualified": "PPA: unqualified" in spec,
        "spec_promotion_false": "promotion_eligible=false" in spec,
    }
    topology_ok = bool(facts["f1_unintegrated"]) ^ bool(facts["f2_promoted"])
    if facts["stage"] == "F1_UNINTEGRATED":
        stage_handoff_ok = all(historical_f1_tokens.values())
    elif facts["stage"] == "F2_PROMOTED":
        stage_handoff_ok = all(f2_handoff_tokens.values())
    else:
        stage_handoff_ok = False
    return [
        Check("claim.canonical_stage_topology_recognized", topology_ok,
              f"facts={facts}"),
        Check("claim.stage_promotion_handoff_exact", stage_handoff_ok,
              f"stage={facts['stage']} historical={historical_f1_tokens} "
              f"f2={f2_handoff_tokens}"),
        Check("claim.explicit_leaf_red_unqualified_boundary",
              all(leaf_boundary_tokens.values()),
              f"tokens={leaf_boundary_tokens}"),
    ]


def evaluate(sources: dict[str, str]) -> list[Check]:
    return structural_checks(sources) + claim_checks(sources)


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--repo-root", type=pathlib.Path, required=True)
    parser.add_argument("--json-out", type=pathlib.Path)
    args = parser.parse_args(argv)
    repo_root = args.repo_root.resolve(strict=True)
    sources = load_sources(repo_root)
    checks = evaluate(sources)
    passed = all(item.passed for item in checks)
    payload = {
        "schema": "v8r-dual-mem-bridge-check/v1",
        "ok": passed,
        "candidate_claim": (
            "dual_bridge_cache_hit_leaf_verified" if passed else "none"
        ),
        "candidate_only_until_execution_gate": True,
        "architecture": {
            "DI-5": "RED", "OOO-3": "RED", "overall": "RED",
            "ppa": "UNQUALIFIED",
        },
        "canonical_stage": canonical_stage_facts(sources)["stage"],
        "checks": [asdict(item) for item in checks],
    }
    rendered = json.dumps(payload, indent=2, sort_keys=True) + "\n"
    if args.json_out:
        args.json_out.parent.mkdir(parents=True, exist_ok=True)
        args.json_out.write_text(rendered, encoding="utf-8")
    sys.stdout.write(rendered)
    return 0 if passed else 1


if __name__ == "__main__":
    raise SystemExit(main())
