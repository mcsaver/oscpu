#!/usr/bin/env python3
"""Finite-domain proof over the T3J premises extracted from current RTL."""

from __future__ import annotations

import argparse
import itertools
from pathlib import Path
import sys
from typing import Mapping

from t3j_verilog_contract import (
    ContractError,
    Expr,
    T3JSource,
    expr_canonical,
    parse_expr,
    require,
    source_paths,
    substitute,
    verilog_int,
)


MARKER = "[T3J-WINDOW-DOMAIN-PROOF]"


def repeated_substitute(expression: Expr, replacements: Mapping[str, Expr]) -> Expr:
    current = expression
    for _iteration in range(16):
        updated = substitute(current, replacements)
        if updated == current:
            return current
        current = updated
    raise ContractError("E_PROOF_ALIAS_DEPTH", "signal substitution did not converge")


def numeric_value(expression: Expr, state: int, localparams: Mapping[str, int]) -> int | None:
    if expression.op == "const":
        return verilog_int(str(expression.args[0]))
    if expression.op == "id":
        name = str(expression.args[0])
        if name == "state_q":
            return state
        return localparams.get(name)
    return None


def comparison_is_numeric(expression: Expr, localparams: Mapping[str, int]) -> bool:
    if expression.op not in ("eq", "ne"):
        return False
    return all(
        item.op == "const" or (item.op == "id" and str(item.args[0]) in ({"state_q"} | set(localparams)))
        for item in expression.args
    )


def atom_key(expression: Expr) -> str:
    return f"cmp:{expr_canonical(expression)}"


def collect_atoms(expression: Expr, localparams: Mapping[str, int]) -> set[str]:
    if expression.op == "id":
        name = str(expression.args[0])
        if name == "state_q" or name in localparams:
            return set()
        return {f"id:{name}"}
    if expression.op == "const":
        return set()
    if expression.op in ("eq", "ne") and not comparison_is_numeric(expression, localparams):
        return {atom_key(expression)}
    result: set[str] = set()
    for item in expression.args:
        result |= collect_atoms(item, localparams)
    return result


def evaluate(expression: Expr, state: int, atoms: Mapping[str, bool], localparams: Mapping[str, int]) -> bool | int:
    if expression.op == "id":
        name = str(expression.args[0])
        if name == "state_q":
            return state
        if name in localparams:
            return localparams[name]
        return atoms[f"id:{name}"]
    if expression.op == "const":
        return verilog_int(str(expression.args[0]))
    if expression.op == "not":
        return not bool(evaluate(expression.args[0], state, atoms, localparams))
    if expression.op == "and":
        return bool(evaluate(expression.args[0], state, atoms, localparams)) and bool(
            evaluate(expression.args[1], state, atoms, localparams)
        )
    if expression.op == "or":
        return bool(evaluate(expression.args[0], state, atoms, localparams)) or bool(
            evaluate(expression.args[1], state, atoms, localparams)
        )
    if expression.op in ("eq", "ne"):
        if comparison_is_numeric(expression, localparams):
            left = numeric_value(expression.args[0], state, localparams)
            right = numeric_value(expression.args[1], state, localparams)
            require(left is not None and right is not None, "E_PROOF_NUMERIC", "numeric comparison failed to resolve")
            equal = left == right
        else:
            equal = atoms[atom_key(expression)]
        return equal if expression.op == "eq" else not equal
    raise ContractError("E_PROOF_OPERATOR", f"unsupported AST operator {expression.op}")


def state_label(state: int, localparams: Mapping[str, int]) -> str:
    names = sorted(name for name, value in localparams.items() if value == state and name.startswith("S_"))
    return f"{state}({','.join(names) if names else 'ILLEGAL'})"


def valuations(expressions: tuple[Expr, ...], state_width: int, localparams: Mapping[str, int]):
    atoms = sorted(set().union(*(collect_atoms(expression, localparams) for expression in expressions)))
    require(len(atoms) <= 14, "E_PROOF_ATOM_BOUND", f"finite proof expanded to {len(atoms)} atoms")
    for state in range(1 << state_width):
        for bits in itertools.product((False, True), repeat=len(atoms)):
            yield state, dict(zip(atoms, bits)), atoms


def counterexample(code: str, label: str, state: int, atoms: Mapping[str, bool], localparams: Mapping[str, int]) -> None:
    active = [name for name, value in atoms.items() if value]
    raise ContractError(
        code,
        f"{label} counterexample state={state_label(state, localparams)} true_atoms={active}",
    )


def prove(source: T3JSource) -> dict[str, int]:
    state_width = source.bridge.reg_width("state_q")
    localparams = source.bridge.numeric_localparams()
    for state in ("S_IDLE", "S_RESP", "S_LOOKUP", "S_R0"):
        require(state in localparams, "E_PROOF_STATE", f"RTL premise {state} missing")

    raw_window_connection = parse_expr(source.bridge_port("lookup_read_en_i").text)
    window, _window_location = source.resolved_bridge_port("lookup_read_en_i")
    raw_fire = parse_expr(source.bridge_assignment("fetch_req_fire_w").text)
    raw_ready = parse_expr(source.bridge_assignment("fetch_req_ready_o").text)
    raw_lookup_hit = parse_expr(source.bridge_assignment("lookup_hit_resp_w").text)
    bridge_replacements = {
        "fetch_req_fire_w": raw_fire,
        "fetch_req_ready_o": raw_ready,
        "lookup_hit_resp_w": raw_lookup_hit,
    }
    if raw_window_connection.op == "id":
        bridge_replacements[str(raw_window_connection.args[0])] = window
    window = repeated_substitute(window, bridge_replacements)
    fire = repeated_substitute(raw_fire, bridge_replacements)
    semantic = repeated_substitute(parse_expr(source.bridge_port("lookup_en_i").text), bridge_replacements)

    raw_fill_valid = parse_expr(source.bridge_assignment("fetch_cache_fill_valid_w").text)
    raw_fill_complete = parse_expr(source.bridge_assignment("fetch_cache_fill_complete_w").text)
    fill = repeated_substitute(
        raw_fill_valid,
        {"fetch_cache_fill_complete_w": raw_fill_complete},
    )
    raw_sram_write = parse_expr(source.cache_assignment("sram_we_w").text)
    sram_write = repeated_substitute(raw_sram_write, {"fill_valid_i": fill})

    case_counts: dict[str, int] = {}

    cases = 0
    for state, atoms, _atom_names in valuations((fire, window), state_width, localparams):
        cases += 1
        if bool(evaluate(fire, state, atoms, localparams)) and not bool(
            evaluate(window, state, atoms, localparams)
        ):
            counterexample("E_FIRE_REQUIRES_WINDOW", "fetch_req_fire -> physical read window", state, atoms, localparams)
    case_counts["fire_requires_window"] = cases

    cases = 0
    for state, atoms, _atom_names in valuations((semantic, fire), state_width, localparams):
        cases += 1
        if bool(evaluate(semantic, state, atoms, localparams)) != bool(
            evaluate(fire, state, atoms, localparams)
        ):
            counterexample("E_SEMANTIC_LOOKUP_EQ_FIRE", "lookup_en_i == fetch_req_fire_w", state, atoms, localparams)
    case_counts["semantic_equals_fire"] = cases

    cases = 0
    for state, atoms, _atom_names in valuations((window, sram_write), state_width, localparams):
        cases += 1
        if bool(evaluate(window, state, atoms, localparams)) and bool(
            evaluate(sram_write, state, atoms, localparams)
        ):
            counterexample("E_READ_WRITE_MUTEX", "physical read window excludes fill write", state, atoms, localparams)
    case_counts["read_write_mutex"] = cases

    case_counts["total"] = sum(case_counts.values())
    return case_counts


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
        counts = prove(T3JSource.load(bridge, cache))
    except (ContractError, OSError) as error:
        code = error.code if isinstance(error, ContractError) else "E_IO"
        print(f"{MARKER} FAIL {code}: {error}", file=sys.stderr)
        raise SystemExit(1)
    print(
        f"{MARKER} PASS RTL-premises=ready/fire/window/fill/sram_we "
        f"fire_cases={counts['fire_requires_window']} "
        f"semantic_cases={counts['semantic_equals_fire']} "
        f"mutex_cases={counts['read_write_mutex']} total_cases={counts['total']}"
    )


if __name__ == "__main__":
    main()
