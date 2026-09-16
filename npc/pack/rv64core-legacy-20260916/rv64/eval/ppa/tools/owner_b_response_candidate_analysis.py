#!/usr/bin/env python3
"""重建并复核当前 RV64 AXI B 返回路径与可回退候选边界。"""

from __future__ import annotations

import argparse
from decimal import Decimal
import pathlib
import re
import sys
from typing import Any

TOOLS_DIR = pathlib.Path(__file__).resolve().parent
if str(TOOLS_DIR) not in sys.path:
    sys.path.insert(0, str(TOOLS_DIR))

import architecture_hard_gates as architecture  # noqa: E402
import owner_b_latency_sensitivity as sensitivity  # noqa: E402
import owner_timing_workload_ab as evidence  # noqa: E402


REPO_ROOT = pathlib.Path(__file__).resolve().parents[5]
SCHEMA = "npc-rv64-owner-b-response-candidate-analysis-v2"
STATUS = "CURRENT_PATH_MAPPED_NEXT_CANDIDATE_DEFINED"
NEXT_ACTION = "qualify.current-reference-ppa"
SELECTED_SLICE = "analyze.owner-b-response-latency-candidate"
IMPLEMENTED_CANDIDATE = "adapter-final-b-fall-through-v1"
NEXT_CANDIDATE = "adapter-input-aw-w-fall-through-v1"

SOURCE_PATHS = (
    "npc/rv64/vsrc/memory/OooMemAxiBridge.v",
    "npc/rv64/vsrc/memory/OooDualMemBridgeWrapper.v",
    "npc/rv64/vsrc/memory/OooDualMemAxiArbiter.v",
    "npc/rv64/vsrc/memory/OooLsuAxiLaneAdapter.v",
    "npc/rv64/vsrc/core/NpcCoreTop.v",
    "npc/rv64/vsrc/core/OooCoreTopGlue.v",
    "npc/rv64/vsrc/bus/NpcAxiBus.v",
    "npc/rv64/vsrc/bus/AxiCrossbar.v",
    "npc/rv64/vsrc/sim/AxiDpiSlave.sv",
    "npc/rv64/eval/ppa/instrumentation/NpcOooOwnerTimingProbe.sv",
)
PRIOR_STABLE_PATHS = frozenset((
    "npc/rv64/vsrc/memory/OooMemAxiBridge.v",
    "npc/rv64/vsrc/memory/OooDualMemBridgeWrapper.v",
    "npc/rv64/vsrc/memory/OooDualMemAxiArbiter.v",
    "npc/rv64/vsrc/core/NpcCoreTop.v",
    "npc/rv64/vsrc/bus/NpcAxiBus.v",
    "npc/rv64/vsrc/bus/AxiCrossbar.v",
    "npc/rv64/vsrc/sim/AxiDpiSlave.sv",
))


class EvidenceError(ValueError):
    """输入证据或当前 RTL 不满足 B 返回路径分析合同。"""


def require(condition: bool, message: str) -> None:
    if not condition:
        raise EvidenceError(message)


def load_json(path: pathlib.Path) -> dict[str, Any]:
    try:
        value = evidence.load_json(path)
    except (evidence.EvidenceError, OSError) as error:
        raise EvidenceError(str(error)) from error
    require(isinstance(value, dict), "JSON root must be an object")
    return value


def resolve_file(raw: str | pathlib.Path) -> pathlib.Path:
    try:
        return evidence.resolve_file(raw)
    except (evidence.EvidenceError, OSError) as error:
        raise EvidenceError(str(error)) from error


def file_ref(path: pathlib.Path) -> dict[str, Any]:
    try:
        return evidence.file_ref(path)
    except (evidence.EvidenceError, OSError) as error:
        raise EvidenceError(str(error)) from error


def verify_ref(value: Any, label: str) -> pathlib.Path:
    try:
        return evidence.verify_ref(value, label)
    except (evidence.EvidenceError, OSError) as error:
        raise EvidenceError(str(error)) from error


def parse_key_values(path: pathlib.Path) -> dict[str, str]:
    values: dict[str, str] = {}
    for raw in path.read_text(encoding="utf-8", errors="strict").splitlines():
        if "=" not in raw or raw.startswith("The "):
            continue
        key, value = raw.split("=", 1)
        if re.fullmatch(r"[A-Z0-9_]+", key):
            require(key not in values, f"duplicate key in {evidence.rel(path)}: {key}")
            values[key] = value.strip()
    return values


def require_once(text: str, pattern: str, label: str) -> None:
    count = len(re.findall(pattern, text, flags=re.MULTILINE | re.DOTALL))
    require(count == 1, f"{label} marker count is {count}, expected 1")


def analyze_source_texts(texts: dict[str, str]) -> dict[str, Any]:
    missing = [path for path in SOURCE_PATHS if path not in texts]
    require(not missing, f"source text inventory is incomplete: {missing}")

    bridge = texts["npc/rv64/vsrc/memory/OooMemAxiBridge.v"]
    adapter = texts["npc/rv64/vsrc/memory/OooLsuAxiLaneAdapter.v"]
    crossbar = texts["npc/rv64/vsrc/bus/AxiCrossbar.v"]
    slave = texts["npc/rv64/vsrc/sim/AxiDpiSlave.sv"]

    # 这些结构约束把 4-cycle 观测绑定到真实 VALID/READY owner，而不是注释。
    require_once(
        bridge,
        r"assign\s+data_store_b_response_fusion_w\s*=\s*\n?\s*"
        r"data_store_b_terminal_w\s*&&\s*fsm_normal_w\s*;",
        "bridge final-B response fusion",
    )
    require_once(
        bridge,
        r"assign\s+lsu_axi_bready_o\s*=\s*\n?\s*"
        r"\(state_q\s*==\s*S_WRITE_RESP\)\s*\|\|\s*"
        r"\(state_q\s*==\s*S_AD_UPDATE\)\s*;",
        "bridge state-only BREADY",
    )
    require_once(
        adapter,
        r"wire\s+final_b_fallthrough_w\s*=.*?"
        r"\(state_q\s*==\s*S_W_RESP\).*?d_axi_bvalid_i.*?"
        r"!split_write_more_beats_w\s*;",
        "adapter final-B fall-through",
    )
    require_once(
        adapter,
        r"assign\s+u_axi_bvalid_o\s*=\s*\(state_q\s*==\s*S_B_RESP\)\s*\|\|\s*"
        r"\n?\s*final_b_fallthrough_w\s*;",
        "adapter upstream BVALID mux",
    )
    require_once(
        adapter,
        r"assign\s+d_axi_bready_o\s*=\s*\(state_q\s*==\s*S_W_RESP\)\s*;",
        "adapter state-only downstream BREADY",
    )
    require_once(
        adapter,
        r"state_q\s*<=\s*u_axi_bready_i\s*\?\s*S_IDLE\s*:\s*S_B_RESP\s*;",
        "adapter registered backpressure fallback",
    )
    require_once(
        crossbar,
        r"if\s*\(wr_active_q\[s\]\s*&&\s*wr_aw_sent_q\[s\]\s*&&\s*"
        r"wr_w_sent_q\[s\]\)\s*begin\s*\n\s*owner\s*=.*?\n\s*"
        r"m_bvalid_r\[owner\]\s*=\s*s_bvalid_i\[s\]",
        "crossbar exact write-owner B route",
    )
    require_once(
        slave,
        r"wire\s+write_complete_w\s*=\s*!s_axi_bvalid_o\s*&&.*?"
        r"\(aw_valid_q\s*\|\|\s*aw_fire_w\).*?"
        r"\(w_valid_q\s*\|\|\s*w_fire_w\)\s*;",
        "target registered write completion",
    )
    require_once(
        slave,
        r"if\s*\(write_complete_w\)\s*begin.*?"
        r"s_axi_bvalid_o\s*<=\s*1'b1\s*;",
        "target registered BVALID",
    )

    return {
        "bridge_final_b_response_fusion": True,
        "bridge_bready_state_only": True,
        "adapter_final_b_fallthrough": True,
        "adapter_nonfinal_split_b_internal": True,
        "adapter_bready_state_only": True,
        "adapter_registered_backpressure_fallback": True,
        "crossbar_exact_write_owner_b_route": True,
        "target_bvalid_registered_after_complete_aw_w": True,
    }


def verify_sensitivity(path: pathlib.Path) -> dict[str, Any]:
    value = load_json(path)
    try:
        rebuilt = sensitivity.rebuild_receipt(value)
    except (sensitivity.EvidenceError, OSError, KeyError, TypeError) as error:
        raise EvidenceError(f"sensitivity receipt cannot be rebuilt: {error}") from error
    require(value == rebuilt, "sensitivity receipt differs from rebuilt evidence")
    require(value.get("status") == "H1_B_RESPONSE_LATENCY_SENSITIVE",
            "sensitivity receipt did not select H1")
    for workload in ("coremark", "dhrystone_10000"):
        mean = (value.get("workloads", {}).get(workload, {})
                .get("delay_points", {}).get("0", {})
                .get("write_response", {}).get("mean_completed_cycles"))
        require(mean == "4.000000000000",
                f"current {workload} B-response latency is not four cycles")
    return value


def verify_selector(path: pathlib.Path, design_id: str) -> dict[str, Any]:
    require(
        evidence.rel(path) !=
        "npc/rv64/eval/ppa/evidence/optimization-slice-current.json",
        "selector input must be an immutable versioned snapshot",
    )
    value = load_json(path)
    require(value.get("schema") == "npc-rv64-optimization-slice-decision-v1",
            "selector schema mismatch")
    require(value.get("decision") == "SELECT", "selector decision is not SELECT")
    require(value.get("live_design_id") == design_id, "selector design-id drift")
    require(value.get("selected_slice", {}).get("id") == SELECTED_SLICE,
            "selector does not authorize B-response candidate analysis")
    return value


def verify_prior_analysis(path: pathlib.Path) -> dict[str, Any]:
    value = load_json(path)
    require(value.get("schema") == "npc-rv64-owner-b-response-candidate-analysis-v1",
            "prior analysis schema mismatch")
    require(value.get("status") == "CANDIDATE_DEFINED",
            "prior analysis did not define a candidate")
    candidate = value.get("candidate", {})
    require(candidate.get("id") == IMPLEMENTED_CANDIDATE,
            "prior analysis candidate mismatch")
    require(candidate.get("baseline_aw_w_to_store_terminal_cycles") == 5 and
            candidate.get("expected_aw_w_to_store_terminal_cycles") == 4,
            "prior candidate cycle contract mismatch")
    return value


def verify_independent_review(
        path: pathlib.Path,
        contract_path: pathlib.Path,
        design_id: str,
        prior_design_id: str,
        adapter_sha256: str,
) -> dict[str, dict[str, Any]]:
    text = path.read_text(encoding="utf-8", errors="strict")
    contract_reference = file_ref(contract_path)
    require_once(
        text,
        re.escape(
            f"- Contract SHA-256: `{contract_reference['sha256']}`"
        ),
        "independent-review contract binding",
    )
    require_once(
        text,
        re.escape(
            "[V15W-OWNER-B-PATH-CURRENT-REVIEW][GAP_CANDIDATE_ONLY] "
            f"design_id={design_id} prior_design_id={prior_design_id} "
            "current_cycles=4 candidate_cycles=3 "
            f"candidate={NEXT_CANDIDATE} adapter_sha256={adapter_sha256}"
        ),
        "independent-review candidate marker",
    )
    require("- Production RTL change authorized: `false`" in text,
            "independent review does not deny production RTL authorization")
    require("- PPA: `UNQUALIFIED`" in text,
            "independent review does not preserve PPA qualification boundary")
    require("- Promotion eligible: `false`" in text,
            "independent review does not deny promotion")
    return {
        "review": file_ref(path),
        "contract": contract_reference,
    }


def source_snapshot(prior: dict[str, Any], closure: dict[str, str]) -> tuple[
        list[dict[str, Any]], dict[str, Any]]:
    prior_hashes = {
        item.get("path"): item.get("sha256")
        for item in prior.get("source_artifacts", []) if isinstance(item, dict)
    }
    texts: dict[str, str] = {}
    refs: list[dict[str, Any]] = []
    for relative in SOURCE_PATHS:
        path = resolve_file(relative)
        texts[relative] = path.read_text(encoding="utf-8", errors="strict")
        ref = file_ref(path)
        refs.append(ref)
        if relative in PRIOR_STABLE_PATHS:
            require(prior_hashes.get(relative) == ref["sha256"],
                    f"non-candidate source drifted since prior analysis: {relative}")
    adapter = next(item for item in refs if item["path"] ==
                   "npc/rv64/vsrc/memory/OooLsuAxiLaneAdapter.v")
    require(closure.get("ADAPTER_SHA256") == adapter["sha256"],
            "current adapter is not the independently reviewed V15P implementation")
    return refs, analyze_source_texts(texts)


def workload_bounds(sensitivity_value: dict[str, Any]) -> dict[str, Any]:
    result: dict[str, Any] = {}
    for workload in ("coremark", "dhrystone_10000"):
        item = sensitivity_value["workloads"][workload]["sensitivity"]
        per_delay = Decimal(item["workload_cycles_per_delay_cycle"])
        result[workload] = {
            "measured_added_delay_cycles": item["added_delay_cycles_per_b"],
            "measured_workload_cycle_delta": item["workload_cycle_delta"],
            "workload_cycles_per_one_b_delay_cycle": format(per_delay, ".12f"),
            "claim": "diagnostic_bound_not_unimplemented_core_candidate",
        }
    return result


def build_receipt(
    selector_path: pathlib.Path,
    sensitivity_path: pathlib.Path,
    prior_analysis_path: pathlib.Path,
    implementation_closure_path: pathlib.Path,
    slice_disposition_path: pathlib.Path,
    performance_ab_path: pathlib.Path,
    mapped_sta_path: pathlib.Path,
    independent_review_path: pathlib.Path,
    independent_review_contract_path: pathlib.Path,
) -> dict[str, Any]:
    raw_design_id, rtl_entries = architecture.rtl_binding(REPO_ROOT)
    design_id = f"sha256:{raw_design_id}"
    selector_value = verify_selector(selector_path, design_id)
    sensitivity_value = verify_sensitivity(sensitivity_path)
    require(sensitivity_value.get("design_id") == design_id,
            "sensitivity design-id drift")
    prior = verify_prior_analysis(prior_analysis_path)
    closure = parse_key_values(implementation_closure_path)
    disposition = parse_key_values(slice_disposition_path)
    require(closure.get("RESULT") == "PASS", "implementation review closure is not PASS")
    prior_design_id = closure.get("DESIGN_ID", "")
    require(re.fullmatch(r"sha256:[0-9a-f]{64}", prior_design_id) is not None,
            "implementation closure design-id is invalid")
    require(closure.get("POSITIVE_STORE_TERMINAL_CYCLES") == "2,4,7" and
            closure.get("MUTATED_STORE_TERMINAL_CYCLES") == "3,5,8",
            "adapter absolute-latency mutation contract mismatch")
    require(disposition.get("DESIGN_ID") == prior_design_id,
            "slice disposition and implementation closure design drift")
    require(disposition.get("DEVELOPMENT_STATE") == "INTERMEDIATE_CHECKPOINT" and
            disposition.get("COMPLETE_DESIGN_PROMOTION") ==
            "REJECTED_TIMING_HARD_GATE",
            "slice disposition claim boundary mismatch")

    performance = load_json(performance_ab_path)
    require(performance.get("schema") == "npc-rv64-v15p-performance-ab-result-v1" and
            performance.get("status") == "PASS",
            "implementation performance A/B is not PASS")
    require(performance.get("mechanism") == "lsu_axi_adapter_final_b_fallthrough",
            "implementation performance mechanism mismatch")
    for workload in ("coremark", "dhrystone_10000"):
        current = sensitivity_value["workloads"][workload]["delay_points"]["0"]
        measured = performance["workloads"][workload]["candidate"]
        require(current["cycles"] == measured["cycles"] and
                current["retired_instructions"] == measured["retired_instructions"],
                f"current {workload} no longer matches the implemented candidate")

    mapped = load_json(mapped_sta_path)
    require(mapped.get("schema") == "npc-rv64-v15p-mapped-sta-ab-result-v1" and
            mapped.get("status") == "PASS",
            "mapped STA A/B evidence is not structurally PASS")
    require(mapped.get("mechanism") == "lsu_axi_adapter_final_b_fallthrough",
            "mapped STA mechanism mismatch")
    require(mapped.get("decision") == "TIMING_HARD_GATE_FAIL_REWORK_OR_ROLLBACK" and
            mapped.get("promotion_state") == "NOT_PROMOTABLE",
            "mapped STA claim boundary mismatch")

    sources, source_checks = source_snapshot(prior, closure)
    adapter_ref = next(
        item for item in sources
        if item["path"] == "npc/rv64/vsrc/memory/OooLsuAxiLaneAdapter.v"
    )
    review_refs = verify_independent_review(
        independent_review_path,
        independent_review_contract_path,
        design_id,
        prior_design_id,
        adapter_ref["sha256"],
    )
    return {
        "schema": SCHEMA,
        "status": STATUS,
        "design_id": design_id,
        "rtl_file_count": len(rtl_entries),
        "inputs": {
            "selector_decision": file_ref(selector_path),
            "b_latency_sensitivity": file_ref(sensitivity_path),
            "prior_candidate_analysis": file_ref(prior_analysis_path),
            "implementation_review_closure": file_ref(implementation_closure_path),
            "implementation_slice_disposition": file_ref(slice_disposition_path),
            "implementation_performance_ab": file_ref(performance_ab_path),
            "implementation_mapped_sta": file_ref(mapped_sta_path),
            "independent_rtl_review": review_refs["review"],
            "independent_rtl_review_contract": review_refs["contract"],
            "source_artifacts": sources,
        },
        "checks": {
            **source_checks,
            "selector_authorized_analysis":
                selector_value["selected_slice"]["id"] == SELECTED_SLICE,
            "current_owner_timing_four_cycles": True,
            "prior_candidate_is_current_rtl": True,
            "historical_implementation_design_migration_reviewed": True,
            "absolute_latency_mutation_detected": True,
            "current_workloads_match_candidate_ab": True,
            "timing_hard_gate_still_failed": True,
            "fresh_current_design_mapped_sta_available": False,
            "independent_review_current_path_pass": True,
            "independent_review_next_candidate_only": True,
        },
        "canonical_cycle_map": [
            {"edge": "E0", "elapsed_cycles": 0,
             "observation": "bridge AW/W handshake; adapter captures one logical write and enters S_W_SEND"},
            {"edge": "E1", "elapsed_cycles": 1,
             "observation": "adapter AW/W handshake at crossbar master port; crossbar captures both payloads"},
            {"edge": "E2", "elapsed_cycles": 2,
             "observation": "crossbar grants the held write and registers target ownership"},
            {"edge": "E3", "elapsed_cycles": 3,
             "observation": "target accepts AW/W and registers exact BRESP/BVALID"},
            {"edge": "E4", "elapsed_cycles": 4,
             "observation": "crossbar routes B; adapter final-B fall-through and bridge fusion create the exact store terminal"},
        ],
        "implemented_candidate": {
            "id": IMPLEMENTED_CANDIDATE,
            "state": "IMPLEMENTED_AND_CURRENT",
            "module": "OooLsuAxiLaneAdapter",
            "historical_evidence_design_id": prior_design_id,
            "current_design_id": design_id,
            "baseline_cycles": 5,
            "current_cycles": 4,
            "performance_ab_cycles_percent": {
                "coremark": disposition["COREMARK_CYCLES_PERCENT"],
                "dhrystone_10000": disposition["DHRYSTONE_10000_CYCLES_PERCENT"],
            },
        },
        "remaining_latency": {
            "cycles": 4,
            "disposition": "CANDIDATE_DEFINED_UNQUALIFIED",
            "low_risk_qualification": "GAP",
            "candidate": {
                "id": NEXT_CANDIDATE,
                "state": "CANDIDATE_ONLY",
                "module": "OooLsuAxiLaneAdapter",
                "scope": "legal_naturally_aligned_single_beat_writes",
                "current_cycles": 4,
                "ideal_no_backpressure_cycles": 3,
                "expected_cycle_delta": -1,
                "action": [
                    "present input-cycle AW and W to the downstream adapter ports without coupling upstream READY to downstream READY",
                    "enter S_W_RESP when both downstream channels accept at E0",
                    "capture the complete command and accepted-channel bit when exactly one downstream channel accepts, then finish in S_W_SEND",
                    "retain the existing path for invalid-size, sparse, misaligned and split writes",
                ],
                "required_invariants": [
                    "no upstream B response before the exact downstream final B terminal",
                    "upstream READY remains local and state-only with respect to downstream READY",
                    "AW and W payloads remain stable across independent channel backpressure",
                    "OKAY, SLVERR and DECERR are held exactly until the upstream terminal",
                    "earlier split-write errors remain sticky through the final response",
                    "escaped-write drain/drop and nokill completion remain exact across flush and selective recovery",
                ],
                "required_counterexamples": [
                    "AW-only acceptance at E0",
                    "W-only acceptance at E0",
                    "upstream response backpressure",
                    "OKAY, SLVERR and DECERR response classes",
                    "split-write sticky earlier error",
                    "flush or selective recovery at each partial-send boundary",
                    "escaped-write drain/drop and nokill completion",
                    "fresh mapped 5 ns STA of the new forward path",
                ],
                "out_of_scope": [
                    "crossbar grant fall-through",
                    "target B-generation changes",
                    "multi-owner or additional-outstanding-write changes",
                ],
            },
            "reasons": [
                "the current E0-E4 path and four-cycle workload observation are independently consistent",
                "the prior implementation evidence is migrated only by exact stable-source and adapter hashes plus current independent review",
                "the candidate removes the input capture cycle only for the narrow legal single-beat subset",
                "partial AW/W acceptance and exact response/error behavior are not yet proven",
                "fresh 5 ns mapped STA is required before production RTL implementation can be authorized",
            ],
        },
        "workload_sensitivity_bounds": workload_bounds(sensitivity_value),
        "next_action": NEXT_ACTION,
        "authorization": {
            "candidate_analysis_completed": True,
            "new_production_rtl_change_authorized": False,
            "second_core_only_candidate_defined": True,
            "ppa": "UNQUALIFIED",
            "promotion_eligible": False,
        },
        "claim_boundary": {
            "current_path_and_existing_candidate_measured": True,
            "next_candidate_is_not_implemented_or_measured": True,
            "candidate_definition_is_not_production_rtl_authorization": True,
            "diagnostic_slope_is_not_a_candidate_result": True,
            "mapped_reference_failed_5ns_hard_gate": True,
            "historical_mapped_sta_does_not_qualify_current_design": True,
            "selector_authorizes_promotion": False,
        },
    }


def rebuild_receipt(value: dict[str, Any]) -> dict[str, Any]:
    require(value.get("schema") == SCHEMA, "candidate analysis schema mismatch")
    inputs = value.get("inputs", {})
    names = (
        "selector_decision", "b_latency_sensitivity", "prior_candidate_analysis",
        "implementation_review_closure", "implementation_slice_disposition",
        "implementation_performance_ab", "implementation_mapped_sta",
        "independent_rtl_review", "independent_rtl_review_contract",
    )
    paths = [verify_ref(inputs.get(name), name) for name in names]
    source_refs = inputs.get("source_artifacts", [])
    require(isinstance(source_refs, list) and len(source_refs) == len(SOURCE_PATHS),
            "candidate analysis source inventory mismatch")
    for item in source_refs:
        verify_ref(item, "candidate analysis source")
    return build_receipt(*paths)


def command_build(args: argparse.Namespace) -> int:
    value = build_receipt(
        resolve_file(args.selector),
        resolve_file(args.sensitivity),
        resolve_file(args.prior_analysis),
        resolve_file(args.implementation_closure),
        resolve_file(args.slice_disposition),
        resolve_file(args.performance_ab),
        resolve_file(args.mapped_sta),
        resolve_file(args.independent_review),
        resolve_file(args.independent_review_contract),
    )
    output = pathlib.Path(args.output)
    if not output.is_absolute():
        output = REPO_ROOT / output
    try:
        evidence.atomic_write_json(output, value)
    except (evidence.EvidenceError, OSError) as error:
        raise EvidenceError(str(error)) from error
    print(
        "[OWNER-B-RESPONSE-CANDIDATE-ANALYSIS][PASS] "
        f"status={value['status']} current_cycles=4 "
        f"second_candidate={NEXT_CANDIDATE} candidate_state=CANDIDATE_ONLY "
        f"next={value['next_action']}")
    return 0


def command_verify(args: argparse.Namespace) -> int:
    path = resolve_file(args.input)
    value = load_json(path)
    rebuilt = rebuild_receipt(value)
    require(value == rebuilt, "candidate analysis differs from rebuilt evidence")
    print(
        "[OWNER-B-RESPONSE-CANDIDATE-ANALYSIS-VERIFY][PASS] "
        f"status={value['status']} current_cycles=4 "
        f"second_candidate={NEXT_CANDIDATE} candidate_state=CANDIDATE_ONLY "
        f"next={value['next_action']}")
    return 0


def parser() -> argparse.ArgumentParser:
    root = argparse.ArgumentParser()
    sub = root.add_subparsers(dest="command", required=True)
    build = sub.add_parser("build")
    build.add_argument("--selector", required=True)
    build.add_argument("--sensitivity", required=True)
    build.add_argument("--prior-analysis", required=True)
    build.add_argument("--implementation-closure", required=True)
    build.add_argument("--slice-disposition", required=True)
    build.add_argument("--performance-ab", required=True)
    build.add_argument("--mapped-sta", required=True)
    build.add_argument("--independent-review", required=True)
    build.add_argument("--independent-review-contract", required=True)
    build.add_argument("--output", required=True)
    build.set_defaults(func=command_build)
    verify = sub.add_parser("verify")
    verify.add_argument("--input", required=True)
    verify.set_defaults(func=command_verify)
    return root


def main() -> int:
    args = parser().parse_args()
    try:
        return args.func(args)
    except (EvidenceError, OSError, KeyError, TypeError, ValueError) as error:
        print(f"[OWNER-B-RESPONSE-CANDIDATE-ANALYSIS][FAIL] {error}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
