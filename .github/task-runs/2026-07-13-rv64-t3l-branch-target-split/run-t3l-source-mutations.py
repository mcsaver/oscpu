#!/usr/bin/env python3

from __future__ import annotations

from pathlib import Path

from t3l_branch_target_contract import (
    MASK52,
    ContractError,
    load_live,
    reference_target,
    validate_sources,
)


def replace_exact(text: str, old: str, new: str, name: str) -> str:
    count = text.count(old)
    if count != 1:
        raise SystemExit(f"mutation setup {name}: expected one source token, got {count}")
    return text.replace(old, new, 1)


def expect_source_red(base: dict[str, str], name: str, key: str, old: str, new: str) -> None:
    mutated = dict(base)
    mutated[key] = replace_exact(mutated[key], old, new, name)
    try:
        validate_sources(mutated)
    except ContractError as exc:
        print(f"[T3L-MUTATION-{name}] PASS gate=source code={exc.code}")
        return
    raise SystemExit(f"[T3L-MUTATION-{name}] FALSE-GREEN")


def semantic_model(pc: int, bimm: int, kind: str) -> int:
    pc &= (1 << 64) - 1
    bimm &= 0x1FFF
    low_sum = (pc & 0xFFF) + (bimm & 0xFFF)
    carry = low_sum >> 12
    sign = (bimm >> 12) & 1
    if kind == "DROP_SIGN":
        delta = carry
    elif kind == "ADD_SIGN":
        delta = carry + sign
    elif kind == "DROP_CARRY":
        delta = -sign
    elif kind == "BIT11_SIGN":
        delta = carry - ((bimm >> 11) & 1)
    elif kind == "UNSIGNED13":
        return (pc + bimm) & ((1 << 64) - 1)
    else:
        raise AssertionError(kind)
    high = ((pc >> 12) + delta) & MASK52
    return (high << 12) | (low_sum & 0xFFF)


def expect_semantic_red(name: str, probes: tuple[tuple[int, int], ...]) -> None:
    for pc, bimm in probes:
        if semantic_model(pc, bimm, name) != reference_target(pc, bimm):
            print(f"[T3L-MUTATION-{name}] PASS gate=domain pc={pc:#x} bimm={bimm:#x}")
            return
    raise SystemExit(f"[T3L-MUTATION-{name}] FALSE-GREEN")


def main() -> int:
    root = Path.cwd()
    base = load_live(root)
    validate_sources(base)
    expect_source_red(
        base, "DECODER_WIDE", "decoder", "output [12:0] dec0_bimm_o",
        "output [`XLEN-1:0] dec0_bimm_o",
    )
    expect_source_red(
        base, "FRONTEND_WIDE", "frontend", "wire [12:0] fetch_dec0_bimm_w;",
        "wire [`XLEN-1:0] fetch_dec0_bimm_w;",
    )
    expect_source_red(
        base, "STATIC_BIT11", "frontend",
        ".lookup0_static_taken_i(fetch_dec0_bimm_w[12])",
        ".lookup0_static_taken_i(fetch_dec0_bimm_w[11])",
    )
    expect_source_red(
        base, "LANE1_STATIC_CROSS", "frontend",
        ".lookup1_static_taken_i(fetch_dec1_bimm_w[12])",
        ".lookup1_static_taken_i(fetch_dec0_bimm_w[12])",
    )
    expect_source_red(
        base, "LANE1_TARGET_CROSS", "frontend",
        ".bimm_i(fetch_dec1_bimm_w)", ".bimm_i(fetch_dec0_bimm_w)",
    )
    expect_source_red(
        base, "TARGET_ADD_SIGN", "target",
        "{{(`XLEN-13){1'b0}}, bimm_i[12]};",
        "-{{(`XLEN-13){1'b0}}, bimm_i[12]};",
    )
    expect_source_red(
        base, "TARGET_DROP_CARRY", "target",
        "+\n      {{(`XLEN-13){1'b0}}, low_sum_w[12]} -",
        "+\n      {{(`XLEN-13){1'b0}}, 1'b0} -",
    )

    probes = ((0, 0x1FFE), (2, 0x1FFE), (0xFFE, 0x2), (0, 0x1000), (0, 0x800))
    for name in ("DROP_SIGN", "ADD_SIGN", "DROP_CARRY", "BIT11_SIGN", "UNSIGNED13"):
        expect_semantic_red(name, probes)
    print("[T3L-SOURCE-MUTATIONS] PASS source_cases=7 semantic_cases=5")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
