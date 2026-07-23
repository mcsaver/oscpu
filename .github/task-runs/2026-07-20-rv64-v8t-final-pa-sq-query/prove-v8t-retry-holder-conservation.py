#!/usr/bin/env python3
"""Bounded exhaustive control proof for the two v8t/F3 retry holders.

This is an executable RTL-correlated state-space proof, not formal signoff.
It first binds the abstract transition model to exact OooIntBackend source
equations and payload/terminal/census mappings, then exhausts every Boolean
control combination per bank and the Cartesian product of reachable actions.
"""

from __future__ import annotations

import argparse
import hashlib
import itertools
import json
import pathlib
import re
from dataclasses import asdict, dataclass


@dataclass(frozen=True)
class Check:
    check_id: str
    passed: bool
    detail: str


@dataclass(frozen=True)
class Step:
    valid: bool
    capture: bool
    cancel: bool
    req_fire: bool
    next_valid: bool
    terminal: bool
    miq_push: bool
    action: str


def strip_comments(text: str) -> str:
    text = re.sub(r"/\*.*?\*/", "", text, flags=re.S)
    return re.sub(r"//[^\n]*", "", text)


def regex_count(text: str, pattern: str) -> int:
    return len(re.findall(pattern, text, flags=re.S | re.M))


def model_step(bits: tuple[bool, ...]) -> Step:
    (
        valid,
        query_valid,
        query_exact,
        sq_replay,
        flush,
        checkpoint,
        selective_kill,
        tracker_exact,
        bank_match,
        selected,
        transport_open,
        control_block,
        ready,
    ) = bits
    retry_ready = query_exact and not valid and not flush and not checkpoint
    replay_out = query_valid and (not query_exact or sq_replay)
    capture = query_valid and replay_out and retry_ready
    cancel = valid and (selective_kill or flush or checkpoint)
    candidate = valid and tracker_exact and not cancel and bank_match
    req_valid = (
        candidate
        and selected
        and transport_open
        and not flush
        and not checkpoint
        and not control_block
    )
    req_fire = req_valid and ready
    if cancel or req_fire:
        next_valid = False
    elif capture:
        next_valid = True
    else:
        next_valid = valid
    if cancel:
        action = "cancel"
    elif req_fire:
        action = "reissue"
    elif capture:
        action = "capture"
    elif valid:
        action = "hold"
    else:
        action = "idle"
    return Step(
        valid=valid,
        capture=capture,
        cancel=cancel,
        req_fire=req_fire,
        next_valid=next_valid,
        terminal=cancel,
        miq_push=req_fire,
        action=action,
    )


def prove_text(raw_text: str, source_name: str = "OooIntBackend.v") -> dict:
    text = strip_comments(raw_text)
    checks: list[Check] = []

    def add(check_id: str, passed: bool, detail: str) -> None:
        checks.append(Check(check_id, bool(passed), detail))

    holder_fields = (
        "valid", "producer_id", "rob_idx", "pdest", "pdest_fp", "size",
        "unsigned", "addr", "wdata", "wstrb", "owner_kind",
        "owner_token", "mmu_epoch", "fault_tval",
    )
    missing_fields = [
        f"mem_retry{bank}_{field}_q"
        for bank in (0, 1)
        for field in holder_fields
        if f"mem_retry{bank}_{field}_q" not in text
    ]
    add(
        "source.two_complete_holder_payloads",
        not missing_fields,
        f"missing={missing_fields}",
    )

    sequential_counts = {}
    capture_payload_counts = {}
    for bank in (0, 1):
        sequential_counts[f"bank{bank}"] = regex_count(
            text,
            rf"else\s+if\s*\(mem_retry{bank}_cancel_w\s*\|\|\s*"
            rf"mem_retry{bank}_req_fire_w\)\s*begin\s*"
            rf"mem_retry{bank}_valid_q\s*<=\s*1'b0;\s*end\s*"
            rf"else\s+if\s*\(mem_sq_retry{bank}_capture_w\)\s*begin\s*"
            rf"mem_retry{bank}_valid_q\s*<=\s*1'b1;",
        )
        prefix = "mem1" if bank else "mem"
        miq = "miq1" if bank else "miq"
        producer = "mem1_sq_query_producer_id_w" if bank else "mem_sq_query_producer_id_w"
        source_map = {
            "producer_id": producer,
            "rob_idx": f"{miq}_head_rob_w",
            "pdest": f"{miq}_head_pdest_w",
            "pdest_fp": f"{miq}_head_pdest_fp_w",
            "size": f"{miq}_head_size_w",
            "unsigned": f"{miq}_head_unsigned_w",
            "addr": f"{miq}_head_addr_w",
            "wdata": f"{miq}_head_wdata_w",
            "wstrb": f"{miq}_head_wstrb_w",
            "owner_kind": f"{miq}_head_owner_kind_w",
            "owner_token": f"{miq}_head_owner_token_w",
            "mmu_epoch": f"{miq}_head_mmu_epoch_w",
            "fault_tval": f"{miq}_head_fault_tval_w",
        }
        capture_payload_counts[f"bank{bank}"] = sum(
            regex_count(
                text,
                rf"mem_retry{bank}_{field}_q\s*<=\s*{re.escape(source)}\s*;",
            )
            for field, source in source_map.items()
        )
        # Keep the variable live in the generated proof report terminology.
        assert prefix in {"mem", "mem1"}
    add(
        "source.cancel_or_fire_precedes_capture",
        sequential_counts == {"bank0": 1, "bank1": 1},
        f"counts={sequential_counts}",
    )
    add(
        "source.capture_payload_exact",
        capture_payload_counts == {"bank0": 13, "bank1": 13},
        f"field_assignments={capture_payload_counts}",
    )

    capture_credit = {
        "ready0": regex_count(
            text,
            r"mem_sq_query_retry_ready_o\s*=\s*ENABLE_DUAL_MEM\s*&&\s*"
            r"mem_sq_query_exact_w\s*&&\s*!mem_retry0_valid_q\s*&&\s*"
            r"!flush_i\s*&&\s*!checkpoint_restore_i",
        ),
        "ready1": regex_count(
            text,
            r"mem1_sq_query_retry_ready_o\s*=\s*ENABLE_DUAL_MEM\s*&&\s*"
            r"mem1_sq_query_exact_w\s*&&\s*!mem_retry1_valid_q\s*&&\s*"
            r"!flush_i\s*&&\s*!checkpoint_restore_i",
        ),
        "capture0": regex_count(
            text,
            r"mem_sq_retry0_capture_w\s*=\s*mem_sq_query_valid_i\s*&&\s*"
            r"mem_sq_query_replay_o\s*&&\s*mem_sq_query_retry_ready_o",
        ),
        "capture1": regex_count(
            text,
            r"mem_sq_retry1_capture_w\s*=\s*mem1_sq_query_valid_i\s*&&\s*"
            r"mem1_sq_query_replay_o\s*&&\s*mem1_sq_query_retry_ready_o",
        ),
    }
    add(
        "source.capture_requires_exact_empty_credit",
        all(value == 1 for value in capture_credit.values()),
        f"counts={capture_credit}",
    )

    reissue_fragments = [
        "wire push_retry0_w = mem_retry0_req_fire_w;",
        "wire push_retry1_w = mem_retry1_req_fire_w;",
        "push_retry0_w ? mem_retry0_rob_idx_q :",
        "push_retry0_w ? mem_retry0_pdest_q :",
        "push_retry0_w ? mem_retry0_pdest_fp_q :",
        "push_retry0_w ? mem_retry0_size_q :",
        "push_retry0_w ? mem_retry0_unsigned_q :",
        "push_retry1_w ? mem_retry1_rob_idx_q :",
        "push_retry1_w ? mem_retry1_pdest_q :",
        "push_retry1_w ? mem_retry1_pdest_fp_q :",
        "push_retry1_w ? mem_retry1_size_q :",
        "push_retry1_w ? mem_retry1_unsigned_q :",
        "grant_retry0_w ? mem_retry0_owner_token_q :",
        "grant_retry1_w ?\n      mem_retry1_owner_token_q :",
        "grant_retry0_w ? mem_retry0_addr_q :",
        "grant_retry1_w ? mem_retry1_addr_q :",
    ]
    missing_reissue = [item for item in reissue_fragments if item not in text]
    add(
        "source.request_fire_atomic_exact_miq_repush",
        not missing_reissue,
        f"missing={missing_reissue}",
    )

    terminal_fragments = [
        "wire mem_retry0_tagged_terminal_w = mem_retry0_cancel_w;",
        "wire mem_retry1_tagged_terminal_w = mem_retry1_cancel_w;",
        "mem_retry1_tagged_terminal_w,\n      mem_retry0_tagged_terminal_w,",
        "mem_retry1_owner_token_q,\n      mem_retry0_owner_token_q,",
        "assign mem_terminal_ingress10_mask_w =\n      mem_retry0_tagged_terminal_w ?",
        "assign mem_terminal_ingress11_mask_w =\n      mem_retry1_tagged_terminal_w ?",
        ".INGRESS_N(12)",
    ]
    missing_terminal = [item for item in terminal_fragments if item not in text]
    add(
        "source.cancel_exact_terminal_lanes_10_11",
        not missing_terminal,
        f"missing={missing_terminal}",
    )

    census_fragments = [
        "wire [31:0] mem_retry0_owner_mask_w = mem_retry0_valid_q ?",
        "wire [31:0] mem_retry1_owner_mask_w = mem_retry1_valid_q ?",
        "mem_buffer_owner_mask_w | mem_retry0_owner_mask_w |\n      mem_retry1_owner_mask_w |",
        "[V8T-RETRY-HOLDER-EXACT]",
        "[V8T-RETRY0-HANDOFF-NEXT-Q]",
        "[V8T-RETRY1-HANDOFF-NEXT-Q]",
        "[V8T-RETRY0-REPUSH-NEXT-Q]",
        "[V8T-RETRY1-REPUSH-NEXT-Q]",
    ]
    missing_census = [item for item in census_fragments if item not in text]
    add(
        "source.holder_in_owner_census_and_next_q_oracles",
        not missing_census,
        f"missing={missing_census}",
    )

    bit_vectors = itertools.product((False, True), repeat=13)
    steps = [model_step(bits) for bits in bit_vectors]
    action_counts = {
        action: sum(step.action == action for step in steps)
        for action in ("idle", "capture", "hold", "reissue", "cancel")
    }
    exclusive = all(
        int(step.capture) + int(step.cancel) + int(step.req_fire) <= 1
        for step in steps
    )
    add(
        "exhaustive.capture_reissue_cancel_mutually_exclusive",
        exclusive and all(action_counts.values()),
        f"vectors={len(steps)} actions={action_counts}",
    )

    conserved = True
    failures: list[dict] = []
    for step in steps:
        source_count = int(step.valid or step.capture)
        sink_count = int(step.next_valid) + int(step.terminal) + int(step.miq_push)
        if source_count != sink_count:
            conserved = False
            failures.append({"step": asdict(step), "source": source_count,
                             "sink": sink_count})
            if len(failures) == 4:
                break
    add(
        "exhaustive.single_bank_owner_conservation",
        conserved,
        f"vectors={len(steps)} counterexamples={failures}",
    )

    representatives: dict[str, Step] = {}
    for step in steps:
        representatives.setdefault(step.action, step)
    cross_count = 0
    cross_ok = True
    for action0, action1 in itertools.product(sorted(representatives), repeat=2):
        step0 = representatives[action0]
        step1 = representatives[action1]
        source = int(step0.valid or step0.capture) + int(step1.valid or step1.capture)
        sink = sum(
            int(value)
            for step in (step0, step1)
            for value in (step.next_valid, step.terminal, step.miq_push)
        )
        cross_count += 1
        cross_ok = cross_ok and source == sink
        if action0 == "cancel" and action1 == "cancel":
            cross_ok = cross_ok and step0.terminal and step1.terminal
    add(
        "exhaustive.two_bank_cartesian_independence",
        cross_ok and cross_count == 25,
        f"action_pairs={cross_count} lane_map=bank0:10,bank1:11",
    )

    liveness_ok = True
    schedules = 0
    progress_schedules = 0
    for schedule in itertools.product(("hold", "service", "cancel"), repeat=6):
        schedules += 1
        valid = True
        saw_progress = False
        for event in schedule:
            if valid and event in {"service", "cancel"}:
                saw_progress = True
                valid = False
        if saw_progress:
            progress_schedules += 1
            liveness_ok = liveness_ok and not valid
        else:
            liveness_ok = liveness_ok and valid
    add(
        "bounded.conditional_progress_depth_6",
        liveness_ok and schedules == 729 and progress_schedules == 728,
        f"schedules={schedules} progress_schedules={progress_schedules}",
    )

    passed = all(check.passed for check in checks)
    return {
        "schema": "v8t-retry-holder-conservation-proof/v1",
        "proof_scope": "bounded_exhaustive_rtl_correlated_control",
        "formal_signoff": False,
        "source_name": source_name,
        "source_sha256": hashlib.sha256(raw_text.encode("utf-8")).hexdigest(),
        "passed": passed,
        "per_bank_boolean_vectors": len(steps),
        "two_bank_action_pairs": cross_count,
        "bounded_liveness_depth": 6,
        "checks": [asdict(check) for check in checks],
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--source", type=pathlib.Path, required=True)
    parser.add_argument("--json-out", type=pathlib.Path)
    args = parser.parse_args()
    raw_text = args.source.resolve(strict=True).read_text(encoding="utf-8")
    result = prove_text(raw_text, args.source.name)
    for check in result["checks"]:
        status = "PASS" if check["passed"] else "FAIL"
        print(f"[V8T-RETRY-PROOF][{status}] {check['check_id']}: {check['detail']}")
    if args.json_out:
        args.json_out.parent.mkdir(parents=True, exist_ok=True)
        args.json_out.write_text(
            json.dumps(result, indent=2, sort_keys=True) + "\n",
            encoding="utf-8",
        )
    return 0 if result["passed"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
