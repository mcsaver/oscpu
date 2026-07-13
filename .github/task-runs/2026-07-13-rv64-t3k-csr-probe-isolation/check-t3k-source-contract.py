#!/usr/bin/env python3
"""Fail-closed source gate for the T3K CSR legality probe isolation."""

from __future__ import annotations

import argparse
from collections import Counter
from pathlib import Path
import re
import sys

from t3k_csr_contract import (
    ContractError,
    T3KSource,
    associative_terms,
    compact,
    exact_call,
    identifiers,
    require,
    source_paths,
    unwrap,
)


MARKER = "[T3K-SOURCE-CONTRACT]"
RAW_PREDICATE = "csr_access_illegal_raw"
STATE_ARGS = (
    "priv_mode_q",
    "csr_mstatus_q",
    "csr_mcounteren_q",
    "csr_scounteren_q",
)
ACCESS_ARGS = ("csr_addr_i", "csr_funct3_i", "csr_rs1_idx_i", *STATE_ARGS)
PROBE_ARGS = (
    "csr_probe_addr_i",
    "csr_probe_funct3_i",
    "csr_probe_rs1_idx_i",
    *STATE_ARGS,
)
PROBE_FIELDS = ("valid", "addr", "funct3", "rs1_idx")


def require_exact_and_call(
    expression: str,
    valid_name: str,
    expected_args: tuple[str, ...],
    code: str,
) -> None:
    terms = associative_terms(expression, "&&")
    require(len(terms) == 2, code, f"expected valid && raw predicate, got {compact(expression)}")
    valid_terms = [term for term in terms if compact(term) == valid_name]
    calls = [exact_call(term, RAW_PREDICATE) for term in terms]
    calls = [call for call in calls if call is not None]
    require(len(valid_terms) == 1 and len(calls) == 1, code, f"invalid gated call shape: {compact(expression)}")
    require(
        tuple(compact(item) for item in calls[0]) == expected_args,
        code,
        f"raw predicate arguments differ: actual={calls[0]} expected={expected_args}",
    )


def validate_mux(source: T3KSource) -> dict[str, object]:
    mux = source.mux
    for field in PROBE_FIELDS:
        mux.require_port("output", f"csr_probe_{field}_o")

    head1_terms = Counter(compact(item) for item in associative_terms(mux.assignment("head1_csr_probe_o"), "&&"))
    expected_head1 = Counter(
        {
            "dispatch_valid_i": 1,
            "!dispatch0_system_i": 1,
            "dispatch1_barrier_i": 1,
            "head1_csr_raw_i": 1,
        }
    )
    require(
        head1_terms == expected_head1,
        "E_MUX_HEAD1_PROBE",
        f"head1 probe premise differs: actual={dict(head1_terms)} expected={dict(expected_head1)}",
    )

    valid_terms = Counter(compact(item) for item in associative_terms(mux.assignment("csr_probe_valid_o"), "||"))
    expected_valid = Counter({"head0_csr_raw_i": 1, "head1_csr_probe_o": 1})
    require(
        valid_terms == expected_valid,
        "E_MUX_PROBE_VALID",
        f"probe valid must be the two head candidates only: {dict(valid_terms)}",
    )

    addr_expression = compact(mux.assignment("csr_probe_addr_o"))
    addr_match = re.fullmatch(r"([A-Za-z_][A-Za-z0-9_$]*)\[31:20\]", addr_expression)
    require(addr_match is not None, "E_MUX_PROBE_PAYLOAD", f"probe addr is not an instruction slice: {addr_expression}")
    instruction = addr_match.group(1)
    require(
        compact(mux.assignment("csr_probe_funct3_o")) == f"{instruction}[14:12]" and
        compact(mux.assignment("csr_probe_rs1_idx_o")) == f"{instruction}[19:15]",
        "E_MUX_PROBE_PAYLOAD",
        "probe addr/funct3/rs1_idx do not share one selected instruction",
    )
    require(
        compact(mux.assignment(instruction)) == "head1_csr_probe_o?head_inst1_i:head_inst0_i",
        "E_MUX_PROBE_PRIORITY",
        f"probe instruction must select head1 probe before head0, got {compact(mux.assignment(instruction))}",
    )

    closure = mux.dependency_closure(f"csr_probe_{field}_o" for field in PROBE_FIELDS)
    forbidden = {
        name for name in closure
        if name.startswith("core_commit0_")
        or name.startswith("pending_system_")
        or name.startswith("csr_access_")
        or name in {"debug_gprs_i", "stop_pending_i", "drain_complete_i"}
    }
    require(
        not forbidden,
        "E_MUX_PROBE_NOT_HEAD_ONLY",
        f"commit/pending/access dependency leaked into probe cone: {sorted(forbidden)}",
    )
    required_leaves = {"head_inst0_i", "head_inst1_i", "head0_csr_raw_i", "head1_csr_raw_i"}
    require(
        required_leaves <= closure,
        "E_MUX_PROBE_PROVENANCE",
        f"probe cone lacks head provenance leaves: {sorted(required_leaves - closure)}",
    )
    return {"probe_instruction": instruction, "probe_cone_nodes": len(closure)}


def validate_csr(source: T3KSource) -> dict[str, object]:
    csr = source.csr
    for field in PROBE_FIELDS:
        csr.require_port("input", f"csr_probe_{field}_i")

    functions = csr.functions(RAW_PREDICATE)
    require(
        len(functions) == 1,
        "E_CSR_RAW_PREDICATE_COUNT",
        f"{RAW_PREDICATE} definition count={len(functions)}, wanted 1",
    )
    function = functions[0]
    function_inputs = re.findall(
        r"\binput\s+(?:wire\s+)?(?:\[[^;\]]+\]\s*)?([A-Za-z_][A-Za-z0-9_$]*)\s*;",
        function,
    )
    expected_inputs = (
        "csr_addr",
        "csr_funct3",
        "csr_rs1_idx",
        "priv_mode",
        "csr_mstatus",
        "csr_mcounteren",
        "csr_scounteren",
    )
    require(
        tuple(function_inputs) == expected_inputs,
        "E_CSR_RAW_PREDICATE_INPUTS",
        f"raw predicate inputs differ: actual={function_inputs} expected={expected_inputs}",
    )
    result_assignments = re.findall(rf"\b{RAW_PREDICATE}\s*=", function)
    require(
        len(result_assignments) == 1,
        "E_CSR_RAW_PREDICATE_RESULT",
        f"raw predicate result assignment count={len(result_assignments)}, wanted 1",
    )
    function_ids = identifiers(function)
    for required_name in (*expected_inputs, "csr_addr_known", "csr_addr_writable", "csr_write_intent", "csr_counter_bit"):
        require(
            required_name in function_ids,
            "E_CSR_RAW_PREDICATE_COVERAGE",
            f"raw predicate omits required legality premise/helper {required_name}",
        )
    leaked_channels = {
        name for name in function_ids
        if name.startswith("csr_probe_") or name in {"csr_addr_i", "csr_funct3_i", "csr_rs1_idx_i", "csr_valid_i"}
    }
    require(
        not leaked_channels,
        "E_CSR_RAW_PREDICATE_CHANNEL_LEAK",
        f"raw predicate directly captures a caller channel: {sorted(leaked_channels)}",
    )

    raw_call_count = len(re.findall(rf"\b{RAW_PREDICATE}\s*\(", csr.source))
    require(
        raw_call_count == 2,
        "E_CSR_RAW_PREDICATE_CALL_COUNT",
        f"raw predicate call count={raw_call_count}, wanted exactly main+probe=2",
    )
    require_exact_and_call(
        csr.assignment("csr_access_illegal_w"),
        "csr_valid_i",
        ACCESS_ARGS,
        "E_CSR_ACCESS_CALL",
    )
    public_probe_expression = csr.assignment("csr_illegal_o")
    if compact(public_probe_expression) == "csr_probe_illegal_w":
        probe_call_expression = csr.assignment("csr_probe_illegal_w")
    else:
        probe_call_expression = public_probe_expression
    require_exact_and_call(
        probe_call_expression,
        "csr_probe_valid_i",
        PROBE_ARGS,
        "E_CSR_PROBE_CALL",
    )

    obsolete = {
        name for name in (
            "csr_known_r",
            "csr_writable_r",
            "csr_priv_ok_w",
            "csr_satp_tvm_illegal_w",
            "csr_counter_m_allowed_w",
            "csr_counter_s_allowed_w",
            "csr_counter_allowed_w",
        )
        if re.search(rf"\b{re.escape(name)}\b", csr.source)
    }
    require(
        not obsolete,
        "E_CSR_DUPLICATE_LEGALITY_CONE",
        f"legacy single-port legality cone remains: {sorted(obsolete)}",
    )

    commit_guard = re.search(
        r"\bif\s*\(\s*csr_commit_i\s*&&\s*csr_valid_i\s*&&\s*"
        r"~csr_access_illegal_w\s*&&\s*csr_need_write_w\s*\)",
        csr.source,
    )
    require(
        commit_guard is not None,
        "E_CSR_SIDE_EFFECT_GUARD",
        "architectural CSR write must be guarded by internal csr_access_illegal_w",
    )
    require(
        len(re.findall(r"\bcsr_illegal_o\b", csr.source)) == 2,
        "E_CSR_PUBLIC_PROBE_CONSUMER",
        "public probe legality must occur only in its port declaration and assignment",
    )
    require(
        csr.raw.count("[CSR-LEGAL-VIEW-EQUIV]") == 1,
        "E_CSR_EQUIV_ASSERT_MARKER",
        "main/probe equivalence assertion marker must appear exactly once",
    )
    return {"raw_calls": raw_call_count, "raw_inputs": len(function_inputs)}


def require_connection(connections: dict[str, str], port: str, signal: str, code: str, owner: str) -> None:
    actual = connections.get(port)
    require(actual is not None, code, f"{owner} lacks named connection .{port}")
    require(compact(actual) == signal, code, f"{owner}.{port} got {compact(actual)}, expected {signal}")


def validate_wiring(source: T3KSource) -> dict[str, int]:
    mux_connections = source.control.instance_connections("OooCsrAccessRequestMux")
    control_connections = source.glue.instance_connections("OooControlPlane")
    glue_connections = source.top.instance_connections("OooCoreTopGlue")
    csr_connections = source.top.instance_connections("CsrFile")

    for field in PROBE_FIELDS:
        boundary = f"csr_probe_{field}_w"
        mux_port = f"csr_probe_{field}_o"
        csr_port = f"csr_probe_{field}_i"
        top_wire = f"ooo_csr_probe_{field}_w"
        source.control.require_port("output", boundary)
        source.glue.require_port("output", boundary)
        require_connection(mux_connections, mux_port, boundary, "E_WIRE_MUX_CONTROL", "OooControlPlane/mux")
        require_connection(control_connections, boundary, boundary, "E_WIRE_CONTROL_GLUE", "OooCoreTopGlue/control")
        require_connection(glue_connections, boundary, top_wire, "E_WIRE_GLUE_TOP", "NpcCoreTop/glue")
        require_connection(csr_connections, csr_port, top_wire, "E_WIRE_TOP_CSR", "NpcCoreTop/CsrFile")

    probe_top_wires = {f"ooo_csr_probe_{field}_w" for field in PROBE_FIELDS}
    for field in PROBE_FIELDS:
        expression_ids = identifiers(csr_connections[f"csr_probe_{field}_i"])
        require(
            expression_ids == {f"ooo_csr_probe_{field}_w"},
            "E_WIRE_PROBE_CROSS_FIELD",
            f"CsrFile probe {field} is cross-wired: {sorted(expression_ids)}",
        )
    require(
        set().union(*(identifiers(csr_connections[f"csr_probe_{field}_i"]) for field in PROBE_FIELDS)) == probe_top_wires,
        "E_WIRE_PROBE_BIJECTION",
        "CsrFile probe connections are not a one-to-one four-field mapping",
    )
    return {"boundaries": 4, "named_connections": 16}


def validate(source: T3KSource) -> dict[str, object]:
    mux = validate_mux(source)
    csr = validate_csr(source)
    wiring = validate_wiring(source)
    return {**mux, **csr, **wiring}


def parse_args() -> argparse.Namespace:
    default_root = Path(__file__).resolve().parents[3]
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("repo_root", nargs="?", type=Path, default=default_root)
    parser.add_argument("--mux", type=Path)
    parser.add_argument("--control", type=Path)
    parser.add_argument("--glue", type=Path)
    parser.add_argument("--top", type=Path)
    parser.add_argument("--csr", type=Path)
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    root = args.repo_root.resolve()
    defaults = source_paths(root)
    paths = tuple(
        (override or default).resolve()
        for override, default in zip(
            (args.mux, args.control, args.glue, args.top, args.csr),
            defaults,
        )
    )
    try:
        summary = validate(T3KSource.load(*paths))
    except (ContractError, OSError, UnicodeError) as error:
        code = error.code if isinstance(error, ContractError) else "E_IO"
        print(f"{MARKER} FAIL {code}: {error}", file=sys.stderr)
        raise SystemExit(1)
    print(
        f"{MARKER} PASS raw_predicate={RAW_PREDICATE} "
        f"definitions=1 calls={summary['raw_calls']} inputs={summary['raw_inputs']} "
        f"probe_cone_nodes={summary['probe_cone_nodes']} "
        f"boundaries={summary['boundaries']} named_connections={summary['named_connections']}"
    )


if __name__ == "__main__":
    main()
