#!/usr/bin/env python3
"""Fail-closed source-structure gate for the T3J fetch-cache read window."""

from __future__ import annotations

import argparse
from collections import Counter
from pathlib import Path
import sys

from t3j_verilog_contract import (
    ContractError,
    T3JSource,
    binary,
    const,
    exact_terms,
    expected_state_term,
    ident,
    normalized_commutative,
    parse_expr,
    require,
    source_paths,
    tokenize,
    unary,
)


MARKER = "[T3J-SOURCE-CONTRACT]"


def exact_counter(actual: Counter[str], expected: Counter[str], code: str, label: str) -> None:
    require(
        actual == expected,
        code,
        f"{label} differs: actual={dict(actual)} expected={dict(expected)}",
    )


def validate(source: T3JSource) -> dict[str, object]:
    # Bridge state encodings are read from RTL, not copied into the proof model.
    state_width = source.bridge.reg_width("state_q")
    state_values = source.bridge.numeric_localparams()
    required_states = ("S_IDLE", "S_RESP", "S_LOOKUP", "S_R0")
    for state in required_states:
        require(state in state_values, "E_BRIDGE_STATE", f"numeric localparam {state} missing")
        require(
            0 <= state_values[state] < (1 << state_width),
            "E_BRIDGE_STATE_RANGE",
            f"{state}={state_values[state]} does not fit state_q[{state_width - 1}:0]",
        )
    require(
        len({state_values[state] for state in required_states}) == len(required_states),
        "E_BRIDGE_STATE_ALIAS",
        f"required states alias each other: {[(state, state_values[state]) for state in required_states]}",
    )

    fire = parse_expr(source.bridge_assignment("fetch_req_fire_w").text)
    exact_counter(
        exact_terms(fire, "and"),
        Counter(
            {
                normalized_commutative(ident("fetch_req_valid_i")): 1,
                normalized_commutative(ident("fetch_req_ready_o")): 1,
            }
        ),
        "E_BRIDGE_FIRE_EXACT",
        "fetch_req_fire_w",
    )

    window, _window_location = source.resolved_bridge_port("lookup_read_en_i")
    expected_window = Counter({expected_state_term(state): 1 for state in ("S_IDLE", "S_RESP", "S_LOOKUP")})
    exact_counter(
        exact_terms(window, "or"),
        expected_window,
        "E_BRIDGE_READ_WINDOW_EXACT",
        "lookup_read_en_i physical window",
    )

    semantic_connection = parse_expr(source.bridge_port("lookup_en_i").text)
    require(
        semantic_connection == ident("fetch_req_fire_w"),
        "E_BRIDGE_SEMANTIC_LOOKUP",
        f"lookup_en_i must be the unaliased semantic fire, got {normalized_commutative(semantic_connection)}",
    )

    fill_connection = parse_expr(source.bridge_port("fill_valid_i").text)
    require(
        fill_connection == ident("fetch_cache_fill_valid_w"),
        "E_BRIDGE_FILL_CONNECTION",
        f"fill_valid_i must remain fetch_cache_fill_valid_w, got {normalized_commutative(fill_connection)}",
    )
    fill_valid = parse_expr(source.bridge_assignment("fetch_cache_fill_valid_w").text)
    require(
        fill_valid == ident("fetch_cache_fill_complete_w"),
        "E_BRIDGE_FILL_ALIAS",
        "fetch_cache_fill_valid_w must remain the exact fill-complete alias",
    )
    fill_complete = parse_expr(source.bridge_assignment("fetch_cache_fill_complete_w").text)
    fill_state_term = expected_state_term("S_R0")
    fill_terms = exact_terms(fill_complete, "and")
    require(
        fill_terms[fill_state_term] == 1,
        "E_BRIDGE_FILL_STATE_PREMISE",
        f"fill completion lacks exactly one top-level state_q==S_R0 conjunct: {dict(fill_terms)}",
    )

    ports = source.cache.ansi_ports()
    for port in ("lookup_read_en_i", "lookup_en_i", "fill_valid_i"):
        require(
            ports[("input", port)] == 1,
            "E_CACHE_PORT",
            f"OooFetchPacketCache must declare exactly one input {port}, got {ports[(('input'), port)]}",
        )

    require("en_i" in source.sram_connections, "E_CACHE_SRAM_EN_CONNECTION", "payload SRAM en_i port missing")
    sram_enable_connection = parse_expr(source.sram_connections["en_i"].text)
    require(
        sram_enable_connection == ident("sram_en_w"),
        "E_CACHE_SRAM_EN_CONNECTION",
        f"payload SRAM en_i must connect to sram_en_w, got {normalized_commutative(sram_enable_connection)}",
    )
    require("we_i" in source.sram_connections, "E_CACHE_SRAM_WE_CONNECTION", "payload SRAM we_i port missing")
    sram_write_connection = parse_expr(source.sram_connections["we_i"].text)
    require(
        sram_write_connection == ident("sram_we_w"),
        "E_CACHE_SRAM_WE_CONNECTION",
        f"payload SRAM we_i must connect to sram_we_w, got {normalized_commutative(sram_write_connection)}",
    )

    sram_enable = parse_expr(source.cache_assignment("sram_en_w").text)
    exact_counter(
        exact_terms(sram_enable, "or"),
        Counter(
            {
                normalized_commutative(ident("lookup_read_en_i")): 1,
                normalized_commutative(ident("sram_we_w")): 1,
            }
        ),
        "E_CACHE_SRAM_ENABLE_EXACT",
        "sram_en_w",
    )
    sram_write = parse_expr(source.cache_assignment("sram_we_w").text)
    exact_counter(
        exact_terms(sram_write, "and"),
        Counter(
            {
                normalized_commutative(ident("fill_valid_i")): 1,
                normalized_commutative(unary("not", ident("fill_invalidated_w"))): 1,
            }
        ),
        "E_CACHE_SRAM_WRITE_EXACT",
        "sram_we_w",
    )

    # 地址源同样属于 T3J 时序/功能合同：dummy read 只能提前打开同一个请求地址，
    # 不能偷偷改成已锁存 PC；写拍仍由 sram_we_w 唯一选择 fill index。
    lookup_index_tokens = [
        token.value for token in tokenize(source.cache_assignment("lookup_idx_w").text)
    ]
    expected_lookup_index_tokens = [
        "entry_index", "(", "lookup_pc_i", "[", "INDEX_W", ":", "1", "]", ")"
    ]
    require(
        lookup_index_tokens == expected_lookup_index_tokens,
        "E_CACHE_LOOKUP_INDEX_SOURCE",
        f"lookup_idx_w source differs: actual={lookup_index_tokens} expected={expected_lookup_index_tokens}",
    )
    sram_address_tokens = [
        token.value for token in tokenize(source.cache_assignment("sram_addr_w").text)
    ]
    expected_sram_address_tokens = [
        "{", "SRAM_ADDR_W", "{", "1'b0", "}", "}", "|", "(",
        "sram_we_w", "?", "fill_idx_w", ":", "lookup_idx_w", ")",
    ]
    require(
        sram_address_tokens == expected_sram_address_tokens,
        "E_CACHE_SRAM_ADDRESS_SOURCE",
        f"sram_addr_w mux differs: actual={sram_address_tokens} expected={expected_sram_address_tokens}",
    )
    require("addr_i" in source.sram_connections, "E_CACHE_SRAM_ADDRESS_CONNECTION", "payload SRAM addr_i port missing")
    sram_address_connection = parse_expr(source.sram_connections["addr_i"].text)
    require(
        sram_address_connection == ident("sram_addr_w"),
        "E_CACHE_SRAM_ADDRESS_CONNECTION",
        f"payload SRAM addr_i must connect to sram_addr_w, got {normalized_commutative(sram_address_connection)}",
    )

    dec_assignments = source.cache.nonblocking_assignments("dec_en_q")
    dec_rhs = Counter(normalized_commutative(parse_expr(item.text)) for _position, item in dec_assignments)
    exact_counter(
        dec_rhs,
        Counter(
            {
                normalized_commutative(const("1'b0")): 1,
                normalized_commutative(ident("lookup_en_i")): 1,
            }
        ),
        "E_CACHE_DECISION_ENABLE",
        "dec_en_q nonblocking assignments",
    )

    accept_begin, accept_end = source.cache.exact_if_begin_block(ident("lookup_en_i"))
    context_signals = ("lkp_paging_q", "lkp_priv_q", "lkp_satp_q", "lkp_pc_q", "lkp_idx_q")
    for signal in context_signals:
        assignments = source.cache.nonblocking_assignments(signal)
        require(
            len(assignments) == 1 and accept_begin <= assignments[0][0] < accept_end,
            "E_CACHE_CONTEXT_ACCEPT",
            f"{signal} must have exactly one assignment inside if (lookup_en_i)",
        )
    read_tokens_in_accept = [
        token for token in source.cache.tokens
        if accept_begin <= token.start < accept_end and token.value == "lookup_read_en_i"
    ]
    require(
        not read_tokens_in_accept,
        "E_CACHE_CONTEXT_READ_WINDOW_LEAK",
        "physical lookup_read_en_i leaked into semantic context-capture block",
    )

    for assertion_marker in ("[FPC-ACCEPT-REQUIRES-READ]", "[CONTRACT-FPC-1RW]"):
        require(
            source.cache.source.count(assertion_marker) == 1,
            "E_CACHE_ASSERT_MARKER",
            f"assertion marker {assertion_marker} count is {source.cache.source.count(assertion_marker)}, expected 1",
        )

    return {
        "state_width": state_width,
        "states": {state: state_values[state] for state in required_states},
        "window_terms": 3,
        "context_signals": len(context_signals),
    }


def parse_args() -> argparse.Namespace:
    default_root = Path(__file__).resolve().parents[3]
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("repo_root", nargs="?", type=Path, default=default_root)
    parser.add_argument("--bridge", type=Path)
    parser.add_argument("--cache", type=Path)
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    root = args.repo_root.resolve()
    default_bridge, default_cache = source_paths(root)
    bridge = (args.bridge or default_bridge).resolve()
    cache = (args.cache or default_cache).resolve()
    try:
        summary = validate(T3JSource.load(bridge, cache))
    except (ContractError, OSError) as error:
        code = error.code if isinstance(error, ContractError) else "E_IO"
        print(f"{MARKER} FAIL {code}: {error}", file=sys.stderr)
        raise SystemExit(1)
    print(
        f"{MARKER} PASS state_width={summary['state_width']} "
        f"states={summary['states']} exact_window_terms={summary['window_terms']} "
        f"semantic_context_signals={summary['context_signals']}"
    )


if __name__ == "__main__":
    main()
