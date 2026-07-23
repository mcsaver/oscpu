#!/usr/bin/env python3
"""Build fail-closed local RV64 MEM-ISSUE-G1 / MIQ-FLUSH-G1 evidence."""

from __future__ import annotations

import argparse
import hashlib
import importlib.util
import json
import pathlib
import re
import sys
from typing import Any, Sequence


SCHEMA = "npc-rv64-memory-issue-lifecycle-evidence-v1"
MUTATION_SCHEMA = "npc-rv64-memory-issue-lifecycle-rtl-variants-v1"
RUN_ID = "2026-07-22-rv64-v9f-memory-issue-lifecycle"
CANONICAL_COMMAND = "make -C npc/rv64 check-memory-issue-lifecycle"
REPO = pathlib.Path(__file__).resolve().parents[5]

ARCH_TOOL = pathlib.Path(__file__).with_name("architecture_hard_gates.py")
ARCH_SPEC = importlib.util.spec_from_file_location(
    "architecture_hard_gates_memory_lifecycle", ARCH_TOOL)
assert ARCH_SPEC is not None and ARCH_SPEC.loader is not None
arch = importlib.util.module_from_spec(ARCH_SPEC)
sys.modules[ARCH_SPEC.name] = arch
ARCH_SPEC.loader.exec_module(arch)

VARIANT_RUNNER = REPO / f".github/task-runs/{RUN_ID}/run-memory-lifecycle-variants.py"
VARIANT_SPEC = importlib.util.spec_from_file_location(
    "memory_lifecycle_variants", VARIANT_RUNNER)
assert VARIANT_SPEC is not None and VARIANT_SPEC.loader is not None
variant_model = importlib.util.module_from_spec(VARIANT_SPEC)
sys.modules[VARIANT_SPEC.name] = variant_model
VARIANT_SPEC.loader.exec_module(variant_model)

MEM_PHASE0_RE = re.compile(
    r"^\[MEM-ISSUE-G1-PHASE0\] pair_capture=(\d+) terminal0_local=(\d+) "
    r"terminal1_hold=(\d+) request_fire=(\d+) miq_birth=(\d+)$",
    re.MULTILINE,
)
MEM_PHASE1_RE = re.compile(
    r"^\[MEM-ISSUE-G1-PHASE1\] terminal0_empty=(\d+) "
    r"terminal1_request_fire=(\d+) terminal1_consume=(\d+) "
    r"request_mux_owner=(\d+) miq_birth=(\d+) identity_match=(\d+) "
    r"identity_fields=(\d+)$",
    re.MULTILINE,
)
MEM_POST_LAUNCH_RE = re.compile(
    r"^\[MEM-ISSUE-G1-POST-LAUNCH\] terminal_cleared=(\d+) "
    r"repeated_request_fire=(\d+) repeated_miq_birth=(\d+) "
    r"miq_resident=(\d+) quiet_cycles=(\d+)$",
    re.MULTILINE,
)
MEM_OWNER_ARBITRATION_RE = re.compile(
    r"^\[MEM-ISSUE-G1-OWNER-ARBITRATION\] other_request_fire=(\d+) "
    r"terminal1_hold=(\d+) terminal1_consume=(\d+) terminal1_birth=(\d+) "
    r"other_identity_match=(\d+) identity_fields=(\d+) "
    r"terminal1_release_fire=(\d+) PASS$",
    re.MULTILINE,
)
MEM_BACKPRESSURE_RE = re.compile(
    r"^\[MEM-ISSUE-G1-BACKPRESSURE\] valid_hold_cycles=(\d+) "
    r"request_fire_while_blocked=(\d+) terminal_consume_while_blocked=(\d+) "
    r"miq_birth_while_blocked=(\d+) release_fire=(\d+)$",
    re.MULTILINE,
)
MEM_FOCUSED_RE = re.compile(
    r"^\[MEM-ISSUE-G1-FOCUSED\] pair_capture=(\d+) terminal0_local=(\d+) "
    r"terminal1_hold=(\d+) request_fire=(\d+) terminal1_consume=(\d+) "
    r"miq_birth=(\d+) identity_match=(\d+) identity_fields=(\d+) "
    r"backpressure_hold=(\d+) owner_arbitration=(\d+) no_repeat=(\d+) "
    r"quiet_cycles=(\d+) PASS$",
    re.MULTILINE,
)
MIQ_FOCUSED_RE = re.compile(
    r"^\[MIQ-FLUSH-G1-FOCUSED\] consumed_drain_removed=(\d+) "
    r"stalled_head_no_pop_preserved=(\d+) "
    r"unconsumed_drain_preserved=(\d+) survivor_identity_match=(\d+) "
    r"wrapped_order=(\d+) PASS$",
    re.MULTILINE,
)


def sha256_bytes(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def sha256_file(path: pathlib.Path) -> str:
    return sha256_bytes(path.read_bytes())


def safe_file(root: pathlib.Path, path: pathlib.Path) -> pathlib.Path:
    resolved = path.resolve(strict=True)
    if not resolved.is_relative_to(root):
        raise ValueError(f"artifact escapes repository: {resolved}")
    if path.is_symlink() or not resolved.is_file():
        raise ValueError(f"artifact is not a regular non-symlink file: {path}")
    return resolved


def artifact(root: pathlib.Path, path: pathlib.Path, kind: str) -> dict[str, str]:
    resolved = safe_file(root, path)
    return {
        "kind": kind,
        "path": resolved.relative_to(root).as_posix(),
        "sha256": sha256_file(resolved),
    }


def require_pass_log(text: str, test_name: str, label: str) -> None:
    accepted = {f"[PASS] {test_name}", f"PASS {test_name}"}
    if len([line for line in text.splitlines() if line in accepted]) != 1:
        raise ValueError(f"{label}: expected one exact test PASS line")
    if text.count("[RESULT] PASS") != 1:
        raise ValueError(f"{label}: expected one exact marker [RESULT] PASS")
    for marker in ("[RESULT] FAIL", "[CHECK-FAIL]", "FATAL:", "ERROR:"):
        if marker in text:
            raise ValueError(f"{label}: unexpected failure marker {marker}")


def parse_one_marker(
    regex: re.Pattern[str],
    text: str,
    names: tuple[str, ...],
    expected: dict[str, int],
    label: str,
) -> dict[str, int]:
    matches = list(regex.finditer(text))
    if len(matches) != 1:
        raise ValueError(f"{label}: expected one exact semantic marker")
    metrics = dict(zip(
        names, (int(value) for value in matches[0].groups()), strict=True))
    if metrics != expected:
        raise ValueError(f"{label}: event inventory drifted: {metrics}")
    return metrics


def parse_mem_focused_log(path: pathlib.Path) -> dict[str, dict[str, int]]:
    text = path.read_text(encoding="utf-8")
    require_pass_log(text, "tb_ooo_int_backend", "MEM focused log")
    return {
        "phase0": parse_one_marker(
            MEM_PHASE0_RE, text,
            ("pair_capture", "terminal0_local", "terminal1_hold",
             "request_fire", "miq_birth"),
            {"pair_capture": 2, "terminal0_local": 1,
             "terminal1_hold": 1, "request_fire": 0, "miq_birth": 0},
            "MEM phase0"),
        "phase1": parse_one_marker(
            MEM_PHASE1_RE, text,
            ("terminal0_empty", "terminal1_request_fire",
             "terminal1_consume", "request_mux_owner", "miq_birth",
             "identity_match", "identity_fields"),
            {"terminal0_empty": 1, "terminal1_request_fire": 1,
             "terminal1_consume": 1, "request_mux_owner": 1,
             "miq_birth": 1, "identity_match": 1,
             "identity_fields": 15},
            "MEM phase1"),
        "post_launch": parse_one_marker(
            MEM_POST_LAUNCH_RE, text,
            ("terminal_cleared", "repeated_request_fire",
             "repeated_miq_birth", "miq_resident", "quiet_cycles"),
            {"terminal_cleared": 1, "repeated_request_fire": 0,
             "repeated_miq_birth": 0, "miq_resident": 1,
             "quiet_cycles": 3},
            "MEM post launch"),
        "owner_arbitration": parse_one_marker(
            MEM_OWNER_ARBITRATION_RE, text,
            ("other_request_fire", "terminal1_hold", "terminal1_consume",
             "terminal1_birth", "other_identity_match", "identity_fields",
             "terminal1_release_fire"),
            {"other_request_fire": 1, "terminal1_hold": 1,
             "terminal1_consume": 0, "terminal1_birth": 0,
             "other_identity_match": 1, "identity_fields": 5,
             "terminal1_release_fire": 1},
            "MEM owner arbitration"),
        "backpressure": parse_one_marker(
            MEM_BACKPRESSURE_RE, text,
            ("valid_hold_cycles", "request_fire_while_blocked",
             "terminal_consume_while_blocked", "miq_birth_while_blocked",
             "release_fire"),
            {"valid_hold_cycles": 2, "request_fire_while_blocked": 0,
             "terminal_consume_while_blocked": 0,
             "miq_birth_while_blocked": 0, "release_fire": 1},
            "MEM backpressure"),
        "summary": parse_one_marker(
            MEM_FOCUSED_RE, text,
            ("pair_capture", "terminal0_local", "terminal1_hold",
             "request_fire", "terminal1_consume", "miq_birth",
             "identity_match", "identity_fields", "backpressure_hold",
             "owner_arbitration", "no_repeat", "quiet_cycles"),
            {"pair_capture": 2, "terminal0_local": 1,
             "terminal1_hold": 1, "request_fire": 1,
             "terminal1_consume": 1, "miq_birth": 1,
             "identity_match": 1, "identity_fields": 15,
             "backpressure_hold": 2, "owner_arbitration": 1,
             "no_repeat": 1, "quiet_cycles": 3},
            "MEM summary"),
    }


def parse_miq_focused_log(path: pathlib.Path) -> dict[str, int]:
    text = path.read_text(encoding="utf-8")
    require_pass_log(text, "tb_ooo_mem_inflight_queue", "MIQ focused log")
    return parse_one_marker(
        MIQ_FOCUSED_RE, text,
        ("consumed_drain_removed", "stalled_head_no_pop_preserved",
         "unconsumed_drain_preserved", "survivor_identity_match",
         "wrapped_order"),
        {"consumed_drain_removed": 1, "stalled_head_no_pop_preserved": 1,
         "unconsumed_drain_preserved": 1,
         "survivor_identity_match": 1, "wrapped_order": 1},
        "MIQ focused log")


def required_module_tests(makefile: pathlib.Path) -> list[str]:
    tests: list[str] = []
    collecting = False
    for line in makefile.read_text(encoding="utf-8").splitlines():
        stripped = line.strip()
        if not collecting:
            if not stripped.startswith("TESTS :="):
                continue
            collecting = True
            stripped = stripped.removeprefix("TESTS :=").strip()
        continued = stripped.endswith("\\")
        payload = stripped[:-1].strip() if continued else stripped
        if payload:
            tests.extend(payload.split())
        if not continued:
            break
    if not tests or len(tests) != len(set(tests)):
        raise ValueError("module TESTS inventory is empty or duplicated")
    if any(not re.fullmatch(r"tb_[a-z0-9_]+", name) for name in tests):
        raise ValueError("module TESTS inventory contains a malformed name")
    return tests


def parse_module_aggregate(
    root: pathlib.Path,
    summary: pathlib.Path,
) -> dict[str, Any]:
    tests = required_module_tests(root / "npc/rv64/testbench/Makefile")
    text = summary.read_text(encoding="utf-8")
    count = len(tests)
    markers = (
        "# NPC single module testbench summary",
        f"- total: {count}", f"- passed: {count}", "- failed: 0",
    )
    if any(text.count(marker) != 1 for marker in markers):
        raise ValueError("module aggregate summary counts are incomplete")
    log_dir = summary.parent / "logs"
    actual_logs = {path.stem for path in log_dir.glob("*.log") if path.is_file()}
    if actual_logs != set(tests):
        raise ValueError("module aggregate log inventory is not exact")
    records: dict[str, dict[str, str]] = {}
    summary_lines = text.splitlines()
    for test_name in tests:
        if summary_lines.count(f"- PASS {test_name}") != 1:
            raise ValueError(f"module aggregate summary missing {test_name}")
        log_path = safe_file(root, log_dir / f"{test_name}.log")
        require_pass_log(
            log_path.read_text(encoding="utf-8"), test_name,
            f"module aggregate {test_name}")
        records[test_name] = {
            "path": log_path.relative_to(root).as_posix(),
            "sha256": sha256_file(log_path),
        }
    return {
        "required": count,
        "passed": count,
        "failed": 0,
        "tests": records,
    }


def reconstruct_variant(root: pathlib.Path, spec: Any) -> tuple[str, str]:
    source = safe_file(root, root / spec.source_rel)
    text = source.read_text(encoding="utf-8")
    if text.count(spec.old) != 1 or spec.old == spec.new:
        raise ValueError(f"{spec.name}: live RTL variant anchor is not unique")
    return text, text.replace(spec.old, spec.new, 1)


def validate_variants(root: pathlib.Path, path: pathlib.Path) -> dict[str, Any]:
    payload = json.loads(path.read_text(encoding="utf-8"))
    specs = {spec.name: spec for spec in variant_model.VARIANTS}
    rows = payload.get("results")
    if not isinstance(rows, list):
        raise ValueError("RTL verification-variant result list is missing")
    by_name = {
        row.get("name"): row for row in rows
        if isinstance(row, dict) and isinstance(row.get("name"), str)
    }
    expected_by_debt = {
        debt_id: sum(spec.debt_id == debt_id for spec in specs.values())
        for debt_id in sorted({spec.debt_id for spec in specs.values()})
    }
    aggregate_ok = (
        payload.get("schema") == MUTATION_SCHEMA
        and payload.get("suite_run_id") == RUN_ID
        and payload.get("required") == len(specs)
        and payload.get("compile_success") == len(specs)
        and payload.get("dynamic_rejected") == len(specs)
        and payload.get("source_unchanged") is True
        and payload.get("source_sha256_before")
        == payload.get("source_sha256_after")
        and set(by_name) == set(specs)
        and set(payload.get("by_debt", {})) == set(expected_by_debt)
    )
    if not aggregate_ok:
        raise ValueError("RTL verification-variant aggregate is incomplete")
    verified: list[dict[str, Any]] = []
    source_before: dict[str, str] = {}
    for name, spec in specs.items():
        row = by_name[name]
        original, variant = reconstruct_variant(root, spec)
        expected_original_sha = sha256_bytes(original.encode("utf-8"))
        expected_variant_sha = sha256_bytes(variant.encode("utf-8"))
        log = row.get("log")
        log_path = safe_file(root, root / log.get("path", "")) \
            if isinstance(log, dict) else None
        log_ok = (
            log_path is not None
            and set(log) == {"path", "sha256"}
            and log.get("sha256") == sha256_file(log_path)
        )
        log_text = log_path.read_text(encoding="utf-8") if log_path else ""
        fixed_ok = (
            row.get("debt_id") == spec.debt_id
            and row.get("purpose") == spec.purpose
            and row.get("source") == spec.source_rel
            and row.get("make_variable") == spec.make_variable
            and row.get("test_name") == spec.test_name
            and row.get("ivflags") == spec.ivflags
            and row.get("expected_marker") == spec.expected_marker
            and row.get("original_sha256") == expected_original_sha
            and row.get("variant_sha256") == expected_variant_sha
            and row.get("compile_success") is True
            and row.get("marker_observed") is True
            and row.get("dynamic_rejected") is True
            and isinstance(row.get("make_returncode"), int)
            and row.get("make_returncode") != 0
            and log_ok
            and variant_model.TRANSIENT_DIR_TOKEN in log_text
            and "/tmp/rv64-v9f-" not in log_text
            and spec.expected_marker in log_text
            and "[RESULT] FAIL status=" in log_text
            and "[RESULT] PASS" not in log_text
        )
        if not fixed_ok:
            raise ValueError(f"{name}: RTL verification variant is stale")
        source_before[spec.source_rel] = expected_original_sha
        verified.append(dict(row))
    if payload.get("source_sha256_before") != source_before:
        raise ValueError("RTL verification-variant source binding is stale")
    for debt_id, count in expected_by_debt.items():
        row = payload["by_debt"].get(debt_id)
        if row != {
            "required": count,
            "compile_success": count,
            "dynamic_rejected": count,
        }:
            raise ValueError(f"{debt_id}: variant aggregate drifted")
    return {
        "schema": MUTATION_SCHEMA,
        "required": len(specs),
        "compile_success": len(specs),
        "dynamic_rejected": len(specs),
        "by_debt": payload["by_debt"],
        "source_unchanged": True,
        "results": sorted(verified, key=lambda item: item["name"]),
    }


def validate_drain_birth_topology(root: pathlib.Path) -> dict[str, bool]:
    """Check request-owner and DRAIN handshakes independently of the TB."""

    backend = safe_file(
        root, root / "npc/rv64/vsrc/execute/OooIntBackend.v"
    ).read_text(encoding="utf-8")
    store_queue = safe_file(
        root, root / "npc/rv64/vsrc/memory/OooStoreQueue.v"
    ).read_text(encoding="utf-8")
    miq = safe_file(
        root, root / "npc/rv64/vsrc/memory/OooMemInflightQueue.v"
    ).read_text(encoding="utf-8")
    int_tb = safe_file(
        root, root / "npc/rv64/testbench/tests/tb_ooo_int_backend.sv"
    ).read_text(encoding="utf-8")
    backend_anchors = (
        "  wire sq_drain_req_fire_w = grant_sq_w && mem_req_ready_i;",
        "  wire push_drain_w = sq_drain_req_fire_w;",
        "  assign miq_push_valid_w = mem_req_fire_any_w;",
        (
            "  wire sq_drain_launch_authorized_w = "
            "sq_drain_tracker_exact_w &&\n"
            "      (sq_drain_tracker_producer_id_w == "
            "sq_drain_producer_id_w) &&\n"
            "      (sq_drain_producer_id_w == rob_head_producer_id_w) &&\n"
            "      rob_head_launch_open_w;"
        ),
        "  wire grant_sq_w =\n"
        "      mem_request_transport_open_w && sq_drain_req_valid_w;",
        (
            "  assign issue1_mem_request_fire_w =\n"
            "      (grant_issue1_w && mem_req_ready_i) ||\n"
            "      (grant_mem1_issue1_w && mem1_req_ready_i);"
        ),
        "  wire mem_req_fire_any_w = mem_req_valid_o && mem_req_ready_i;",
        "  wire mem1_req_fire_any_w = mem1_req_valid_o && mem1_req_ready_i;",
    )
    sq_anchors = (
        (
            "  assign req_valid_o =\n"
            "      head_valid_w && owner_valid_q[head_q] && "
            "filled_q[head_q] &&\n"
            "      !request_sent_q[head_q] &&\n"
            "      attr_valid_q[head_q] && !terminal_q[head_q] && "
            "rob_head_valid_i &&\n"
            "      rob_head_launch_open_i &&\n"
            "      (producer_id_q[head_q] == rob_head_producer_id_i) &&\n"
            "      (rob_idx_q[head_q] == rob_head_idx_i);"
        ),
        "[T4N-SQ-REQ-FIRE] physical request fire without eligible head",
        "[S1-TYPED-SQ-DRAIN-ECHO] drain changed head PA/class provenance",
    )
    if any(backend.count(anchor) != 1 for anchor in backend_anchors):
        raise ValueError("DRAIN backend birth topology anchor drifted")
    if any(store_queue.count(anchor) != 1 for anchor in sq_anchors):
        raise ValueError("DRAIN SQ authorization topology anchor drifted")
    miq_anchors = (
        (
            "  wire pop_fire_w = pop_valid_i && head_valid_o && "
            "pop_owner_match_o;"
        ),
        "  wire flush_pop_drain_w = pop_fire_w && "
        "(kind_q[head_q] == KIND_DRAIN);",
        "[MIQ-OWNER-MISMATCH] rsp owner does not match FIFO head",
    )
    if any(miq.count(anchor) != 1 for anchor in miq_anchors):
        raise ValueError("MIQ exact-owner pop-fire topology anchor drifted")
    if re.search(r"\bpop_ready", miq):
        raise ValueError("MIQ unexpectedly gained an independent pop-ready port")
    focused_single_port = (
        "`else\n  localparam TB_ENABLE_DUAL_MEM = 0;\n`endif" in int_tb
        and ".ENABLE_DUAL_MEM(TB_ENABLE_DUAL_MEM)" in int_tb
        and "`elsif V9F_MEMORY_ISSUE_LIFECYCLE_FOCUSED" in int_tb
    )
    if not focused_single_port:
        raise ValueError("V9F focused single-memory-port binding drifted")
    if backend.count("MIQ_KIND_DRAIN") < 1:
        raise ValueError("DRAIN kind is absent from the MIQ push mux")
    return {
        "miq_birth_uses_request_fire": True,
        "drain_birth_uses_sq_request_fire": True,
        "sq_request_requires_exact_rob_head_launch_open": True,
        "sq_request_identity_echo_is_asserted": True,
        "drain_is_transport_irrevocable_not_assumed_retired": True,
        "focused_configuration_is_single_memory_port": True,
        "issue1_request_fire_uses_its_own_grant_and_selected_port_ready": True,
        "bank0_global_fire_has_no_independent_accept_condition": True,
        "miq_pop_fire_requires_valid_head_and_exact_owner_match": True,
        "miq_has_no_independent_pop_ready_port": True,
        "miq_pop_valid_owner_mismatch_is_asserted_illegal": True,
    }


SOURCE_BINDING_PATHS = (
    "npc/rv64/vsrc/execute/OooIntBackend.v",
    "npc/rv64/vsrc/memory/OooMemInflightQueue.v",
    "npc/rv64/vsrc/memory/OooStoreQueue.v",
    "npc/rv64/testbench/tests/tb_ooo_int_backend.sv",
    "npc/rv64/testbench/tests/tb_ooo_mem_inflight_queue.sv",
    "npc/rv64/testbench/Makefile",
    "npc/rv64/testbench/scripts/check_tb_result.py",
    "npc/rv64/Makefile",
    f".github/task-runs/{RUN_ID}/contract.md",
    f".github/task-runs/{RUN_ID}/rtl-derivation.md",
    f".github/task-runs/{RUN_ID}/run-focused.sh",
    f".github/task-runs/{RUN_ID}/run-memory-lifecycle-variants.py",
    "npc/rv64/eval/ppa/tools/memory_issue_lifecycle_evidence.py",
    "npc/rv64/eval/ppa/tools/arch_stable_freeze.py",
    "npc/rv64/eval/ppa/tests/test_memory_issue_lifecycle_evidence.py",
)


def build(
    *,
    root: pathlib.Path,
    mem_log: pathlib.Path,
    miq_log: pathlib.Path,
    module_summary: pathlib.Path,
    mutation_summary: pathlib.Path,
) -> dict[str, Any]:
    mem_metrics = parse_mem_focused_log(mem_log)
    miq_metrics = parse_miq_focused_log(miq_log)
    module = parse_module_aggregate(root, module_summary)
    variants = validate_variants(root, mutation_summary)
    drain_topology = validate_drain_birth_topology(root)
    rtl_sha, rtl_files = arch.rtl_binding(root)
    source_bindings = {
        rel: sha256_file(safe_file(root, root / rel))
        for rel in SOURCE_BINDING_PATHS
    }
    return {
        "schema": SCHEMA,
        "suite_run_id": RUN_ID,
        "status": "PASS",
        "design_id": f"sha256:{rtl_sha}",
        "canonical_command": CANONICAL_COMMAND,
        "scope": (
            "local RV64 OooIntBackend single-port memory reservation terminal "
            "launch and OooMemInflightQueue same-cycle DRAIN response/flush"),
        "metrics": {
            "mem_issue": mem_metrics,
            "miq_flush": miq_metrics,
        },
        "invariants": {
            "memory_pair_capture_is_atomic": True,
            "terminal1_has_no_edge_old_terminal0_lookthrough": True,
            "terminal_consume_request_fire_and_miq_birth_agree": True,
            "terminal_consume_and_miq_identity_are_request_owner_qualified": True,
            "request_owner_identity_is_preserved": True,
            "backpressure_holds_terminal_without_miq_birth": True,
            "post_launch_quiet_window_has_no_repeated_request_or_birth": True,
            "flush_subtracts_exact_fired_drain_head": True,
            "flush_preserves_valid_drain_head_without_pop_fire": True,
            "flush_preserves_unconsumed_drain_identity": True,
            "flush_compaction_preserves_fifo_order": True,
        },
        "focused_tests": {
            "mem_issue_lifecycle": {
                "status": "PASS", "log_sha256": sha256_file(mem_log)},
            "miq_flush_lifecycle": {
                "status": "PASS", "log_sha256": sha256_file(miq_log)},
        },
        "module_aggregate": module,
        "variant_audit": variants,
        "static_audit": drain_topology,
        "provenance": {
            "rtl_sha256": rtl_sha,
            "files": rtl_files,
            "source_bindings": source_bindings,
        },
        "artifacts": [
            artifact(root, mem_log, "mem_issue_focused_log"),
            artifact(root, miq_log, "miq_flush_focused_log"),
            artifact(root, module_summary, "module_aggregate_summary"),
            artifact(root, mutation_summary, "rtl_variant_summary"),
        ],
        "claim": {
            "architecture_debts": {
                "MEM-ISSUE-G1": "CLOSED_ELIGIBLE",
                "MIQ-FLUSH-G1": "CLOSED_ELIGIBLE",
            },
            "ppa": "UNQUALIFIED",
            "promotion_eligible": False,
        },
    }


def raw_summary(result: dict[str, Any]) -> str:
    mem = result["metrics"]["mem_issue"]
    miq = result["metrics"]["miq_flush"]
    variants = result["variant_audit"]
    module = result["module_aggregate"]
    return "\n".join((
        f"schema={result['schema']}",
        f"design_id={result['design_id']}",
        f"canonical_command={result['canonical_command']}",
        f"mem_pair_capture={mem['summary']['pair_capture']}",
        f"mem_terminal0_local={mem['summary']['terminal0_local']}",
        f"mem_terminal1_hold={mem['summary']['terminal1_hold']}",
        f"mem_request_fire={mem['summary']['request_fire']}",
        f"mem_terminal1_consume={mem['summary']['terminal1_consume']}",
        f"mem_miq_birth={mem['summary']['miq_birth']}",
        f"mem_identity_match={mem['summary']['identity_match']}",
        f"mem_identity_fields={mem['summary']['identity_fields']}",
        f"mem_backpressure_hold={mem['summary']['backpressure_hold']}",
        f"mem_owner_arbitration={mem['summary']['owner_arbitration']}",
        f"mem_no_repeat={mem['summary']['no_repeat']}",
        f"mem_quiet_cycles={mem['summary']['quiet_cycles']}",
        f"miq_consumed_drain_removed={miq['consumed_drain_removed']}",
        "miq_stalled_head_no_pop_preserved="
        f"{miq['stalled_head_no_pop_preserved']}",
        f"miq_unconsumed_drain_preserved={miq['unconsumed_drain_preserved']}",
        f"miq_survivor_identity_match={miq['survivor_identity_match']}",
        f"miq_wrapped_order={miq['wrapped_order']}",
        f"compile_success_rtl_variants={variants['compile_success']}",
        f"dynamic_rejected_rtl_variants={variants['dynamic_rejected']}",
        "mem_issue_variants="
        f"{variants['by_debt']['MEM-ISSUE-G1']['dynamic_rejected']}/"
        f"{variants['by_debt']['MEM-ISSUE-G1']['required']}",
        "miq_flush_variants="
        f"{variants['by_debt']['MIQ-FLUSH-G1']['dynamic_rejected']}/"
        f"{variants['by_debt']['MIQ-FLUSH-G1']['required']}",
        f"module_aggregate={module['passed']}/{module['required']}",
        "ppa=UNQUALIFIED",
        "promotion_eligible=false",
        "[MEM-ISSUE-G1-GATE] PASS",
        "[MIQ-FLUSH-G1-GATE] PASS",
        "",
    ))


def main(argv: Sequence[str] | None = None) -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", type=pathlib.Path, required=True)
    parser.add_argument("--mem-log", type=pathlib.Path, required=True)
    parser.add_argument("--miq-log", type=pathlib.Path, required=True)
    parser.add_argument("--module-summary", type=pathlib.Path, required=True)
    parser.add_argument("--mutation-summary", type=pathlib.Path, required=True)
    parser.add_argument("--output", type=pathlib.Path, required=True)
    parser.add_argument("--raw-log", type=pathlib.Path, required=True)
    args = parser.parse_args(argv)
    root = args.root.resolve(strict=True)
    output = args.output.resolve()
    raw_log = args.raw_log.resolve()
    for path in (output, raw_log):
        if not path.is_relative_to(root):
            parser.error(f"output escapes repository: {path}")
        path.parent.mkdir(parents=True, exist_ok=True)
    result = build(
        root=root,
        mem_log=safe_file(root, args.mem_log),
        miq_log=safe_file(root, args.miq_log),
        module_summary=safe_file(root, args.module_summary),
        mutation_summary=safe_file(root, args.mutation_summary),
    )
    output.write_text(
        json.dumps(result, indent=2, sort_keys=True) + "\n",
        encoding="utf-8")
    raw_log.write_text(raw_summary(result), encoding="utf-8")
    print(
        f"[MEMORY-LIFECYCLE-EVIDENCE] design_id={result['design_id']} "
        f"focused=2/2 variants={result['variant_audit']['dynamic_rejected']}/"
        f"{result['variant_audit']['required']} status=PASS")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
