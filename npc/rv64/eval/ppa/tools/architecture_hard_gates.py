#!/usr/bin/env python3
"""Fail-closed executable architecture gates for the RV64 OoO core."""

from __future__ import annotations

import argparse
import dataclasses
import datetime
import hashlib
import json
import math
import pathlib
import re
import sys
from typing import Any


RESULT_SCHEMA = "npc-rv64-architecture-hard-gates-result-v2"
EVIDENCE_SCHEMA = "npc-rv64-architecture-directed-suite-v2"
CONTRACT_REL = "npc/rv64/design/arch/rv64-architecture-ppa-contract.md"
GATE_IDS = (
    "DI-1", "DI-2", "DI-3", "DI-4", "DI-5",
    "OOO-1", "OOO-2", "OOO-3", "OOO-4",
)
EVIDENCE_TEST = {
    "DI-1": "frontend_ii1",
    "DI-2": "width_continuity",
    "DI-3": "pair_matrix",
    "DI-4": "no_static_lane_semantics",
    "DI-5": "dual_memory_issue",
    "OOO-1": "true_ooo_long_latency",
    "OOO-2": "selective_scheduling",
    "OOO-3": "memory_ordering",
    "OOO-4": "speculation_recovery",
}
PAIR_MATRIX = (
    "alu_alu", "alu_branch", "branch_alu", "alu_jal", "jal_alu",
    "alu_jalr", "jalr_alu", "alu_load", "load_alu", "alu_store",
    "store_alu", "load_load", "load_store", "store_load", "store_store",
)
WIDTH_BOUNDARIES = (
    "fetch", "decode", "rename", "dispatch", "issue", "execute", "retire",
)


@dataclasses.dataclass(frozen=True)
class Check:
    check_id: str
    passed: bool
    detail: str

    def json(self) -> dict[str, Any]:
        return {
            "check_id": self.check_id,
            "status": "GREEN" if self.passed else "RED",
            "detail": self.detail,
        }


def repo_root(start: pathlib.Path) -> pathlib.Path:
    for path in (start, *start.parents):
        if (path / ".git").exists():
            return path.resolve()
    raise ValueError("cannot locate repository root")


def digest(path: pathlib.Path) -> str:
    value = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            value.update(chunk)
    return value.hexdigest()


def canonical_digest(value: Any) -> str:
    raw = json.dumps(
        value, allow_nan=False, ensure_ascii=False,
        separators=(",", ":"), sort_keys=True).encode("utf-8")
    return hashlib.sha256(raw).hexdigest()


def is_sha256(value: Any) -> bool:
    return (
        isinstance(value, str) and len(value) == 64
        and all(char in "0123456789abcdef" for char in value)
    )


def nonnegative_int(value: Any) -> bool:
    return isinstance(value, int) and not isinstance(value, bool) and value >= 0


def number(value: Any) -> bool:
    return (
        isinstance(value, (int, float)) and not isinstance(value, bool)
        and math.isfinite(value)
    )


def strip_comments(text: str) -> str:
    return re.sub(r"/\*.*?\*/|//[^\n]*", "", text, flags=re.DOTALL)


def match(text: str, pattern: str) -> bool:
    return re.search(pattern, text, flags=re.DOTALL | re.MULTILINE) is not None


def rtl_binding(root: pathlib.Path) -> tuple[str, dict[str, str]]:
    suffixes = {".v", ".sv", ".vh", ".svh", ".mk"}
    files = sorted(
        path for path in (root / "npc/rv64/vsrc").rglob("*")
        if path.is_file() and path.suffix.lower() in suffixes)
    if not files:
        raise ValueError("RTL source set is empty")
    entries = {
        path.relative_to(root).as_posix(): digest(path) for path in files
    }
    return canonical_digest(entries), entries


def live_sources(root: pathlib.Path) -> dict[str, str]:
    names = (
        "scheduling/OooIntIssueQueue.v",
        "execute/OooIntBackend.v",
        "memory/OooMemAxiBridge.v",
        "memory/OooMemInflightQueue.v",
        "memory/OooStoreQueue.v",
        "memory/OooLoadQueue.v",
        "cache/OooDataWordCache.v",
    )
    result: dict[str, str] = {}
    for name in names:
        path = root / "npc/rv64/vsrc" / name
        if path.is_file():
            result[name] = strip_comments(path.read_text(encoding="utf-8"))
    return result


def di4_checks(src: dict[str, str]) -> list[Check]:
    iq = src.get("scheduling/OooIntIssueQueue.v", "")
    backend = src.get("execute/OooIntBackend.v", "")
    issue = iq + "\n" + backend
    capability_predicate = match(
        issue,
        r"\b(?:ctrl_is_lane[01]_simple_alu|is_lane[01]_simple_alu_ctrl|"
        r"(?:lane|terminal|issue)[01]_(?:is_)?simple_alu_capable|"
        r"(?:simple_alu|alu)_capability_predicate)"
        r"(?:_[A-Za-z0-9]+)?\b")
    entry_capability = match(
        issue,
        r"\b(?:entry_capability|capability_q|entry_fu_mask|fu_mask_q)"
        r"(?:_[A-Za-z0-9]+)?\b")
    dynamic_steering = match(
        issue,
        r"\b(?:issue_pair_swapped(?:_[A-Za-z0-9]+)?|"
        r"pair_swap(?:ped)?(?:_[A-Za-z0-9]+)?|"
        r"promote_to_lane0(?:_[A-Za-z0-9]+)?|"
        r"[A-Za-z0-9_]*promotion[A-Za-z0-9_]*)\b")
    return [
        Check(
            "source.capability_predicate_has_entry_metadata",
            not capability_predicate or entry_capability,
            "a simple/ALU capability restriction is tracked per entry"),
        Check(
            "source.capability_predicate_has_dynamic_steering",
            not capability_predicate or dynamic_steering,
            "a restricted asymmetric terminal has explicit swap or promotion"),
    ]


def second_memory_terminal_live(backend: str) -> bool:
    valid_tie = match(
        backend,
        r"\b(?:wire\s+)?issue1_mem_req_valid_w\s*=\s*1'b0\s*;")
    addr_tie = match(
        backend,
        r"\b(?:assign\s+)?issue1_mem_addr_w\s*=\s*"
        r"\{[^;]*1'b0[^;]*\}\s*;")
    return not valid_tie and not addr_tie


def di5_checks(src: dict[str, str]) -> list[Check]:
    backend = src.get("execute/OooIntBackend.v", "")
    bridge = src.get("memory/OooMemAxiBridge.v", "")
    miq = src.get("memory/OooMemInflightQueue.v", "")
    sq = src.get("memory/OooStoreQueue.v", "")
    cache = src.get("cache/OooDataWordCache.v", "")
    live_second = second_memory_terminal_live(backend)
    two_agu = (
        match(backend, r"\bLSU\s+(?:#\s*\(.*?\)\s*)?u_issue0_lsu\b")
        and match(backend,
                  r"\bLSU\s+(?:#\s*\(.*?\)\s*)?u_issue1_lsu\b"))
    translation = all(
        token in bridge for token in (
            "mem0_req_valid_i", "mem0_req_ready_o",
            "mem1_req_valid_i", "mem1_req_ready_o"))
    physical = (
        match(sq, r"\boutput\b[^;]*(?:snoop|query)[^;]*paddr[^;]*;")
        and match(backend, r"\bissue0_[A-Za-z0-9_]*paddr\w*\b")
        and match(backend, r"\bissue1_[A-Za-z0-9_]*paddr\w*\b"))
    cache_faces = (
        all(match(cache + bridge,
                  rf"\b(?:req|mem){lane}_\w*(?:valid|admit)\w*\b")
            for lane in (0, 1))
        or (match(cache + bridge, r"\bu_dcache(?:_bank)?0\b")
            and match(cache + bridge, r"\bu_dcache(?:_bank)?1\b")))
    completion = all(
        token in bridge for token in (
            "mem0_rsp_valid_o", "mem0_rsp_ready_i",
            "mem1_rsp_valid_o", "mem1_rsp_ready_i"))
    credit = (
        all(token in miq for token in ("push0_valid_i", "push1_valid_i"))
        or all(match(backend, rf"\bmem_(?:issue)?{lane}_\w*credit\w*\b")
               for lane in (0, 1))
        or (match(backend, r"\bOooMemInflightQueue\b.*?\bu_miq0\b")
            and match(backend, r"\bOooMemInflightQueue\b.*?\bu_miq1\b")))
    facts = (
        ("source.two_live_memory_issue_terminals", live_second,
         "both issue terminals carry nonconstant memory requests"),
        ("source.two_agu", two_agu, "two distinct issue AGUs exist"),
        ("source.two_translation_admissions", translation,
         "mem0/mem1 translation valid-ready faces exist"),
        ("source.two_physical_lsq_queries", physical,
         "both terminals query physical LSQ/SQ addresses"),
        ("source.two_cache_admissions", cache_faces,
         "two cache admissions or two named banks exist"),
        ("source.two_completions", completion,
         "mem0/mem1 response valid-ready faces exist"),
        ("source.two_memory_credits", credit,
         "two memory issue credits or queue pushes exist"),
    )
    return [Check(*fact) for fact in facts]


def ooo2_checks(src: dict[str, str]) -> list[Check]:
    iq = src.get("scheduling/OooIntIssueQueue.v", "")
    backend = src.get("execute/OooIntBackend.v", "")
    older_block = match(
        iq, r"entry_mem_order_block_r\s*=\s*(?:(?!;).)*older_valid_seen_r")
    freeze = match(
        backend, r"assign\s+iq_issue0_ready_w\s*=\s*(?:(?!;).)*"
        r"mem_issue_res_valid_q\s*\?\s*1'b0")
    return [
        Check("source.no_arbitrary_older_valid_block", not older_block,
              "memory scheduling ignores unrelated older-valid uops"),
        Check("source.no_single_reservation_global_freeze", not freeze,
              "one memory reservation cannot freeze all raw issue"),
    ]


def ooo3_checks(src: dict[str, str]) -> list[Check]:
    lq = src.get("memory/OooLoadQueue.v", "")
    sq = src.get("memory/OooStoreQueue.v", "")
    depth = (
        match(lq, r"parameter\s+(?:integer\s+)?ENTRY_(?:N|COUNT)\s*=\s*[4-9]")
        or match(lq, r"parameter\s+(?:integer\s+)?ENTRY_(?:N|COUNT)\s*=\s*[1-9][0-9]+")
        or match(lq, r"parameter\s+ENTRY_COUNT_W\s*=\s*[2-9]"))
    return [
        Check("source.load_queue_at_least_four",
              "module OooLoadQueue" in lq and depth,
              "a real load queue has at least four entries"),
        Check("source.sq_physical_disambiguation",
              match(sq, r"\boutput\b[^;]*(?:snoop|query)[^;]*paddr[^;]*;"),
              "SQ exposes physical-address ordering queries"),
    ]


def source_checks(src: dict[str, str]) -> dict[str, list[Check]]:
    lane = di4_checks(src)
    memory = di5_checks(src)
    return {
        "DI-1": [],
        "DI-2": [],
        "DI-3": [
            Check("source.pairing_not_static_lane",
                  all(item.passed for item in lane),
                  "pair formation is not limited by lane role"),
            Check("source.memory_pairs_two_terminals", memory[0].passed,
                  "LL/LS/SL/SS reach two live memory terminals"),
        ],
        "DI-4": lane,
        "DI-5": memory,
        "OOO-1": [],
        "OOO-2": ooo2_checks(src),
        "OOO-3": ooo3_checks(src),
        "OOO-4": [],
    }


def safe_artifact(root: pathlib.Path, rel: Any) -> pathlib.Path:
    if not isinstance(rel, str) or not rel or "\\" in rel:
        raise ValueError("artifact path must be workspace-relative POSIX")
    pure = pathlib.PurePosixPath(rel)
    if pure.is_absolute() or ".." in pure.parts:
        raise ValueError("artifact path escapes workspace")
    cursor = root
    for part in pure.parts:
        cursor = cursor / part
        if cursor.is_symlink():
            raise ValueError("artifact path traverses symlink")
    path = (root / pure).resolve(strict=True)
    if not path.is_relative_to(root) or not path.is_file():
        raise ValueError("artifact is not a workspace file")
    return path


def load_evidence(path: pathlib.Path | None) -> tuple[dict[str, Any], list[str]]:
    if path is None or not path.is_file():
        return {}, ["directed evidence manifest is missing"]
    try:
        value = json.loads(
            path.read_text(encoding="utf-8"),
            parse_constant=lambda item: (_ for _ in ()).throw(
                ValueError(f"non-finite constant {item}")))
    except (OSError, UnicodeDecodeError, ValueError, json.JSONDecodeError) as exc:
        return {}, [f"directed evidence cannot be parsed: {exc}"]
    return (
        (value, []) if isinstance(value, dict)
        else ({}, ["directed evidence top level is not an object"])
    )


def evidence_checks(
    root: pathlib.Path,
    evidence: dict[str, Any],
    source_sha: str,
    test_id: str,
) -> tuple[list[Check], dict[str, Any]]:
    base = [
        Check("evidence.schema", evidence.get("schema") == EVIDENCE_SCHEMA,
              f"schema is {EVIDENCE_SCHEMA}"),
        Check("evidence.design_binding",
              evidence.get("design_id") == f"sha256:{source_sha}",
              "design_id binds the complete RTL source set"),
    ]
    tests = evidence.get("tests")
    record = tests.get(test_id) if isinstance(tests, dict) else None
    if not isinstance(record, dict):
        return base + [
            Check(f"evidence.{test_id}.record", False,
                  "dedicated directed evidence is missing")
        ], {}
    checks = base + [
        Check(f"evidence.{test_id}.status", record.get("status") == "PASS",
              "status is exactly PASS"),
        Check(f"evidence.{test_id}.command",
              isinstance(record.get("command"), str)
              and bool(record.get("command").strip()),
              "exact directed-test command is recorded"),
    ]
    log_ok = False
    detail = "log/hash/marker is missing"
    log = record.get("log")
    if isinstance(log, dict) and is_sha256(log.get("sha256")):
        try:
            path = safe_artifact(root, log.get("path"))
            text = path.read_text(encoding="utf-8")
            pass_marker = f"[ARCH-GATE] {test_id} PASS"
            fail_marker = f"[ARCH-GATE] {test_id} FAIL"
            log_ok = (
                digest(path) == log["sha256"]
                and text.count(pass_marker) == 1
                and fail_marker not in text)
            detail = "log hash matches and has exactly one PASS marker"
        except (OSError, UnicodeDecodeError, ValueError) as exc:
            detail = f"invalid log: {exc}"
    checks.append(Check(f"evidence.{test_id}.log", log_ok, detail))
    metrics = record.get("metrics")
    checks.append(Check(
        f"evidence.{test_id}.metrics", isinstance(metrics, dict),
        "metrics is an object"))
    return checks, metrics if isinstance(metrics, dict) else {}


def metric(check_id: str, passed: bool, detail: str) -> Check:
    return Check(f"metric.{check_id}", passed, detail)


def metric_checks(test_id: str, m: dict[str, Any]) -> list[Check]:
    if test_id == "frontend_ii1":
        window = m.get("preheated_cycles")
        packets = m.get("packets_observed")
        accepted = m.get("accepted_packets")
        produced = m.get("produced_packets")
        initiation_interval = m.get("max_initiation_interval")
        valid_window = nonnegative_int(window) and window >= 64
        return [
            metric("frontend.packets",
                   nonnegative_int(packets) and packets >= 64,
                   "at least 64 packets are observed"),
            metric("frontend.window", valid_window,
                   "the post-warmup measurement window is at least 64 cycles"),
            metric("frontend.accept_every_cycle",
                   valid_window and nonnegative_int(accepted)
                   and accepted == window,
                   "one packet is accepted on every post-warmup cycle"),
            metric("frontend.produce_every_cycle",
                   valid_window and nonnegative_int(produced)
                   and produced == window,
                   "one packet is produced on every post-warmup cycle"),
            metric("frontend.ii1",
                   number(initiation_interval)
                   and 0 < initiation_interval <= 1,
                   "maximum initiation interval is at most one cycle"),
        ]
    if test_id == "width_continuity":
        trace = m.get("trace_cycles")
        activity = m.get("boundary_activity")
        trace_ok = nonnegative_int(trace) and trace >= 64
        minimum_total = math.ceil(1.90 * trace) if trace_ok else None
        maximum_total = 2 * trace if trace_ok else None
        result = [
            metric("width.trace", trace_ok,
                   "at least 64 non-vacuum trace cycles"),
            metric("width.independent_alu_ipc",
                   number(m.get("independent_alu_ipc"))
                   and m["independent_alu_ipc"] >= 1.90,
                   "independent integer ALU IPC is at least 1.90"),
        ]
        for boundary in WIDTH_BOUNDARIES:
            record = activity.get(boundary) if isinstance(
                activity, dict) else None
            peak = record.get("peak_uops_per_cycle") if isinstance(
                record, dict) else None
            total = record.get("total_uops") if isinstance(
                record, dict) else None
            result.extend([
                metric(
                    f"width.{boundary}.peak",
                    number(peak) and peak == 2,
                    f"{boundary} demonstrates a two-uop cycle"),
                metric(
                    f"width.{boundary}.total",
                    trace_ok and nonnegative_int(total)
                    and minimum_total <= total <= maximum_total,
                    f"{boundary} sustains 1.90..2.00 uop/cycle over the trace"),
            ])
        return result
    if test_id == "pair_matrix":
        matrix = m.get("pair_matrix")
        return [
            metric(f"pair.{name}",
                   isinstance(matrix, dict) and matrix.get(name) is True,
                   f"{name} pairs in one cycle")
            for name in PAIR_MATRIX
        ]
    if test_id == "no_static_lane_semantics":
        perm = m.get("program_slot_permutation")
        result = [
            metric(f"perm.{kind}.{slot}",
                   isinstance(perm, dict)
                   and isinstance(perm.get(kind), dict)
                   and perm[kind].get(slot) is True,
                   f"{kind} from {slot} reaches a capable terminal")
            for kind in ("branch", "jal", "jalr", "load", "store", "muldiv")
            for slot in ("slot0", "slot1")
        ]
        result.append(metric(
            "perm.static_violations",
            nonnegative_int(m.get("static_lane_role_violations"))
            and m["static_lane_role_violations"] == 0,
            "no static lane-role violation"))
        return result
    if test_id == "dual_memory_issue":
        result = [
            metric("dual.trace", nonnegative_int(m.get("trace_cycles"))
                   and m["trace_cycles"] >= 64, "at least 64 steady cycles"),
            metric("dual.ipc", number(m.get("memory_issue_ipc"))
                   and m["memory_issue_ipc"] >= 1.90, "memory IPC >= 1.90"),
            metric("dual.cycles", nonnegative_int(m.get("dual_issue_cycles"))
                   and m["dual_issue_cycles"] >= 58,
                   "at least 58 dual-memory cycles"),
        ]
        for name in ("agu_accepts", "translation_accepts",
                     "physical_lsq_queries", "cache_admissions", "completions"):
            values = m.get(name)
            result.append(metric(
                f"dual.{name}",
                isinstance(values, list) and len(values) == 2
                and all(nonnegative_int(value) and value >= 58
                        for value in values),
                f"two active {name} faces"))
        return result
    if test_id == "true_ooo_long_latency":
        younger = m.get("younger_completed_before_old")
        result = [
            metric(f"long.{kind}",
                   isinstance(younger, dict)
                   and nonnegative_int(younger.get(kind))
                   and younger[kind] >= 8,
                   f"old {kind} bypassed by >=8 younger uops")
            for kind in ("load_miss", "mul", "div")
        ]
        result.extend([
            metric("long.rob", nonnegative_int(m.get("rob_peak"))
                   and m["rob_peak"] >= 9,
                   "ROB peak >=9 (one old plus eight younger)"),
            metric("long.retire", nonnegative_int(
                m.get("retire_order_violations"))
                and m["retire_order_violations"] == 0,
                "in-order retire"),
        ])
        return result
    if test_id == "selective_scheduling":
        return [
            metric("selective.dependent", m.get("blocked_dependents_only") is True,
                   "only dependent/same-resource work waits"),
            metric("selective.younger",
                   m.get("younger_independent_issued") is True,
                   "younger independent work issues"),
            metric("selective.resource",
                   m.get("different_resource_issued") is True,
                   "different resource keeps issuing"),
            metric("selective.freeze",
                   nonnegative_int(m.get("global_freeze_cycles"))
                   and m["global_freeze_cycles"] == 0,
                   "no arbitrary global freeze"),
        ]
    if test_id == "memory_ordering":
        return [
            metric("order.nonalias", m.get("nonalias_load_bypass") is True,
                   "non-alias younger load bypasses older store"),
            metric("order.alias", m.get("alias_forward_wait_replay") is True,
                   "alias forwards, waits, or replays"),
            metric("order.physical", m.get("physical_disambiguation") is True,
                   "physical byte disambiguation"),
            metric("order.stale", nonnegative_int(m.get("stale_read_count"))
                   and m["stale_read_count"] == 0, "zero stale reads"),
            metric("order.ghost", nonnegative_int(m.get("ghost_after_flush"))
                   and m["ghost_after_flush"] == 0, "zero post-flush ghosts"),
            metric("order.store_pre_auth", nonnegative_int(
                       m.get("store_side_effect_before_authorization"))
                   and m["store_side_effect_before_authorization"] == 0,
                   "zero store side effects before ROB-head authorization"),
            metric("order.store_exactly_once_fire", nonnegative_int(
                       m.get("store_authorization_fire_violations"))
                   and m["store_authorization_fire_violations"] == 0,
                   "every authorized store fires exactly once"),
            metric("order.store_b_terminal", nonnegative_int(
                       m.get("store_b_terminal_violations"))
                   and m["store_b_terminal_violations"] == 0,
                   "every fired store has exactly one aggregated B terminal"),
            metric("order.store_retire_after_b", nonnegative_int(
                       m.get("store_retire_before_b_success"))
                   and m["store_retire_before_b_success"] == 0,
                   "no successful store retires before B success"),
            metric("order.store_precise_b_error",
                   m.get("precise_b_error_trap") is True,
                   "SLVERR/DECERR produces a precise store-PC trap"),
            metric("order.store_drain_exactly_once",
                   m.get("fired_store_drain_exactly_once") is True,
                   "flush drains each already-fired store exactly once"),
        ]
    if test_id == "speculation_recovery":
        return [
            metric("recovery.multiple_controls",
                   m.get("multiple_controls_inflight") is True,
                   "multiple control-flow operations are simultaneously in flight"),
            metric("recovery.oldest_mispredict",
                   m.get("oldest_mispredict_wins") is True,
                   "the oldest mispredict determines recovery"),
            metric("recovery.selective_squash",
                   m.get("wrong_path_selective_squash") is True,
                   "only wrong-path uops and requests are squashed"),
            metric("recovery.axi_drain",
                   m.get("fired_axi_drained") is True,
                   "already-fired AXI transactions are drained"),
            metric("recovery.exactly_once_complete",
                   nonnegative_int(m.get(
                       "exactly_once_complete_violations"))
                   and m["exactly_once_complete_violations"] == 0,
                   "zero exactly-once completion violations"),
            metric("recovery.exactly_once_retire",
                   nonnegative_int(m.get(
                       "exactly_once_retire_violations"))
                   and m["exactly_once_retire_violations"] == 0,
                   "zero exactly-once retirement violations"),
            metric("recovery.ghost",
                   nonnegative_int(m.get("ghost_after_recovery"))
                   and m["ghost_after_recovery"] == 0,
                   "zero ghosts after recovery"),
        ]
    return [metric("known_test", False, "unknown evidence test")]


def evaluate(root: pathlib.Path, evidence_path: pathlib.Path | None) -> dict[str, Any]:
    contract_path = root / CONTRACT_REL
    contract = contract_path.read_text(encoding="utf-8")
    source_sha, source_files = rtl_binding(root)
    src_checks = source_checks(live_sources(root))
    evidence, evidence_errors = load_evidence(evidence_path)
    gates: dict[str, Any] = {}
    for gate_id in GATE_IDS:
        test_id = EVIDENCE_TEST[gate_id]
        checks = [
            Check("contract.clause", f"**{gate_id} " in contract,
                  f"normative {gate_id} clause exists"),
            *src_checks[gate_id],
        ]
        evidence_part, metrics = evidence_checks(
            root, evidence, source_sha, test_id)
        checks.extend(evidence_part)
        checks.extend(metric_checks(test_id, metrics))
        passed = not evidence_errors and all(item.passed for item in checks)
        gates[gate_id] = {
            "status": "GREEN" if passed else "RED",
            "evidence_test": test_id,
            "checks": [item.json() for item in checks],
        }
    green = all(value["status"] == "GREEN" for value in gates.values())
    return {
        "schema": RESULT_SCHEMA,
        "generated_at_utc": datetime.datetime.now(
            datetime.timezone.utc).isoformat(),
        "overall_status": "GREEN" if green else "RED",
        "exit_code": 0 if green else 1,
        "contract": {"path": CONTRACT_REL, "sha256": digest(contract_path)},
        "rtl_source_set": {
            "design_id": f"sha256:{source_sha}",
            "sha256": source_sha,
            "file_count": len(source_files),
            "files": source_files,
        },
        "evidence_manifest": str(evidence_path) if evidence_path else None,
        "evidence_errors": evidence_errors,
        "gates": gates,
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--repo-root", type=pathlib.Path)
    parser.add_argument("--evidence-manifest", type=pathlib.Path)
    parser.add_argument("--output", required=True, type=pathlib.Path)
    args = parser.parse_args()
    try:
        root = args.repo_root.resolve() if args.repo_root else repo_root(
            pathlib.Path(__file__).resolve())
        evidence = args.evidence_manifest.resolve(
        ) if args.evidence_manifest else None
        result = evaluate(root, evidence)
        output = args.output.resolve()
        output.parent.mkdir(parents=True, exist_ok=True)
        temporary = output.with_suffix(output.suffix + ".tmp")
        temporary.write_text(
            json.dumps(result, indent=2, ensure_ascii=False, sort_keys=True)
            + "\n", encoding="utf-8")
        temporary.replace(output)
    except (OSError, UnicodeDecodeError, ValueError) as exc:
        print(f"ARCHITECTURE HARD GATE ERROR: {exc}", file=sys.stderr)
        return 2
    for gate_id in GATE_IDS:
        gate = result["gates"][gate_id]
        red = sum(check["status"] == "RED" for check in gate["checks"])
        print(f"{gate_id}: {gate['status']} ({red} red checks)")
    print(f"OVERALL: {result['overall_status']}")
    print(f"RESULT: {output}")
    return int(result["exit_code"])


if __name__ == "__main__":
    raise SystemExit(main())
