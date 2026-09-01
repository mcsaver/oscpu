#!/usr/bin/env python3
"""Pure-integer IEEE raw-bit oracle for ordered SUM_ROWS."""

from __future__ import annotations

import argparse
import hashlib
import json
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Callable, Dict, Iterable, List, Mapping, Sequence, Tuple


FLAG_NV = 0x10
FLAG_DZ = 0x08
FLAG_OF = 0x04
FLAG_UF = 0x02
FLAG_NX = 0x01
F32_CANONICAL_NAN = 0x7FC00000
F64_CANONICAL_NAN = 0x7FF8000000000000
ROW_LENGTH = 128
SCHEMA = "ordered-sum-rows-v1-integer-dyadic"


class OracleError(RuntimeError):
    pass


@dataclass(frozen=True)
class Decoded:
    kind: str
    sign: int
    magnitude: int
    exponent: int
    signaling: bool


@dataclass(frozen=True)
class Candidate:
    identifier: str
    fill: int
    runs: Tuple[Tuple[int, int, int], ...]
    overrides: Tuple[Tuple[int, int], ...]
    expected_result: int
    expected_flags: int


def width_mask(exp_width: int, frac_width: int) -> int:
    return (1 << (1 + exp_width + frac_width)) - 1


def canonical_nan(exp_width: int, frac_width: int) -> int:
    exp_all = (1 << exp_width) - 1
    return (exp_all << frac_width) | (1 << (frac_width - 1))


def decode_bits(raw: int, exp_width: int, frac_width: int) -> Decoded:
    total_width = 1 + exp_width + frac_width
    if raw < 0 or raw > width_mask(exp_width, frac_width):
        raise OracleError(f"raw value exceeds {total_width} bits: {raw}")
    sign = (raw >> (exp_width + frac_width)) & 1
    exp_field = (raw >> frac_width) & ((1 << exp_width) - 1)
    fraction = raw & ((1 << frac_width) - 1)
    exp_all = (1 << exp_width) - 1
    bias = (1 << (exp_width - 1)) - 1
    if exp_field == exp_all:
        if fraction == 0:
            return Decoded("inf", sign, 0, 0, False)
        quiet = (fraction >> (frac_width - 1)) & 1
        return Decoded("nan", sign, 0, 0, quiet == 0)
    if exp_field == 0:
        if fraction == 0:
            return Decoded("zero", sign, 0, 0, False)
        exponent = 1 - bias - frac_width
        return Decoded("finite", sign, fraction, exponent, False)
    magnitude = (1 << frac_width) | fraction
    exponent = exp_field - bias - frac_width
    return Decoded("finite", sign, magnitude, exponent, False)


def round_shift_rne(value: int, shift: int) -> Tuple[int, bool]:
    if value < 0:
        raise OracleError("round_shift_rne requires a non-negative integer")
    if shift <= 0:
        return value << (-shift), False
    quotient = value >> shift
    remainder = value - (quotient << shift)
    if remainder == 0:
        return quotient, False
    half = 1 << (shift - 1)
    if remainder > half or (remainder == half and (quotient & 1)):
        quotient += 1
    return quotient, True


def pack_dyadic(
    sign: int,
    magnitude: int,
    exponent: int,
    exp_width: int,
    frac_width: int,
) -> Tuple[int, int]:
    if sign not in (0, 1) or magnitude < 0:
        raise OracleError("invalid dyadic sign or magnitude")
    sign_shift = exp_width + frac_width
    sign_bits = sign << sign_shift
    if magnitude == 0:
        return sign_bits, 0

    precision = frac_width + 1
    bias = (1 << (exp_width - 1)) - 1
    minimum_normal_exp = 1 - bias
    maximum_normal_exp = bias
    leading_exp = magnitude.bit_length() - 1 + exponent

    if leading_exp < minimum_normal_exp:
        minimum_subnormal_exp = minimum_normal_exp - frac_width
        scale = exponent - minimum_subnormal_exp
        if scale >= 0:
            fraction = magnitude << scale
            inexact = False
        else:
            fraction, inexact = round_shift_rne(magnitude, -scale)
        if fraction >= (1 << frac_width):
            raw = sign_bits | (1 << frac_width)
            return raw, FLAG_NX if inexact else 0
        raw = sign_bits | fraction
        flags = FLAG_NX if inexact else 0
        if inexact:
            flags |= FLAG_UF
        return raw, flags

    shift = magnitude.bit_length() - precision
    significand, inexact = round_shift_rne(magnitude, shift)
    if significand == (1 << precision):
        significand >>= 1
        leading_exp += 1
    if leading_exp > maximum_normal_exp:
        exp_all = (1 << exp_width) - 1
        return sign_bits | (exp_all << frac_width), FLAG_OF | FLAG_NX
    exp_field = leading_exp + bias
    fraction = significand - (1 << frac_width)
    raw = sign_bits | (exp_field << frac_width) | fraction
    return raw, FLAG_NX if inexact else 0


def convert_bits(
    raw: int,
    in_exp_width: int,
    in_frac_width: int,
    out_exp_width: int,
    out_frac_width: int,
) -> Tuple[int, int]:
    decoded = decode_bits(raw, in_exp_width, in_frac_width)
    out_sign_shift = out_exp_width + out_frac_width
    if decoded.kind == "nan":
        flags = FLAG_NV if decoded.signaling else 0
        return canonical_nan(out_exp_width, out_frac_width), flags
    if decoded.kind == "inf":
        exp_all = (1 << out_exp_width) - 1
        return ((decoded.sign << out_sign_shift)
                | (exp_all << out_frac_width)), 0
    if decoded.kind == "zero":
        return decoded.sign << out_sign_shift, 0
    return pack_dyadic(
        decoded.sign,
        decoded.magnitude,
        decoded.exponent,
        out_exp_width,
        out_frac_width,
    )


def add_bits(raw_a: int, raw_b: int, exp_width: int, frac_width: int) -> Tuple[int, int]:
    a = decode_bits(raw_a, exp_width, frac_width)
    b = decode_bits(raw_b, exp_width, frac_width)
    sign_shift = exp_width + frac_width
    if a.kind == "nan" or b.kind == "nan":
        invalid = ((a.kind == "nan" and a.signaling)
                   or (b.kind == "nan" and b.signaling))
        return canonical_nan(exp_width, frac_width), FLAG_NV if invalid else 0
    if a.kind == "inf" and b.kind == "inf":
        if a.sign != b.sign:
            return canonical_nan(exp_width, frac_width), FLAG_NV
        exp_all = (1 << exp_width) - 1
        return (a.sign << sign_shift) | (exp_all << frac_width), 0
    if a.kind == "inf" or b.kind == "inf":
        selected = a if a.kind == "inf" else b
        exp_all = (1 << exp_width) - 1
        return (selected.sign << sign_shift) | (exp_all << frac_width), 0
    if a.kind == "zero" and b.kind == "zero":
        zero_sign = a.sign if a.sign == b.sign else 0
        return zero_sign << sign_shift, 0

    finite_terms: List[Tuple[int, int]] = []
    for value in (a, b):
        if value.kind == "finite":
            signed_magnitude = -value.magnitude if value.sign else value.magnitude
            finite_terms.append((signed_magnitude, value.exponent))
    if not finite_terms:
        return 0, 0
    common_exp = min(term[1] for term in finite_terms)
    exact_sum = 0
    for signed_magnitude, term_exp in finite_terms:
        exact_sum += signed_magnitude << (term_exp - common_exp)
    if exact_sum == 0:
        return 0, 0
    sign = 1 if exact_sum < 0 else 0
    magnitude = -exact_sum if exact_sum < 0 else exact_sum
    return pack_dyadic(sign, magnitude, common_exp, exp_width, frac_width)


def widen_f32(raw: int) -> Tuple[int, int]:
    return convert_bits(raw, 8, 23, 11, 52)


def add_f64(raw_a: int, raw_b: int) -> Tuple[int, int]:
    return add_bits(raw_a, raw_b, 11, 52)


def narrow_f64(raw: int) -> Tuple[int, int]:
    return convert_bits(raw, 11, 52, 8, 23)


def expand_candidate(candidate: Candidate) -> List[int]:
    row = [candidate.fill] * ROW_LENGTH
    for first, last_exclusive, value in candidate.runs:
        if first < 0 or last_exclusive > ROW_LENGTH or first >= last_exclusive:
            raise OracleError(f"invalid run in {candidate.identifier}")
        for index in range(first, last_exclusive):
            row[index] = value
    for index, value in candidate.overrides:
        if index < 0 or index >= ROW_LENGTH:
            raise OracleError(f"invalid override in {candidate.identifier}")
        row[index] = value
    return row


def ordered_sum_row(inputs: Sequence[int]) -> Mapping[str, object]:
    if len(inputs) != ROW_LENGTH:
        raise OracleError(f"row length {len(inputs)} is not {ROW_LENGTH}")
    accumulator = 0
    sticky_flags = 0
    trace_lines: List[str] = []
    for index, raw in enumerate(inputs):
        if raw < 0 or raw > 0xFFFFFFFF:
            raise OracleError(f"row element {index} is not F32 raw bits")
        widened, widen_flags = widen_f32(raw)
        accumulator_before = accumulator
        accumulator, add_flags = add_f64(accumulator, widened)
        sticky_flags |= widen_flags | add_flags
        trace_lines.append(
            f"{index:03d}:{raw:08x}:{widened:016x}:{widen_flags:02x}:"
            f"{accumulator_before:016x}:{accumulator:016x}:{add_flags:02x}"
        )
    result, narrow_flags = narrow_f64(accumulator)
    sticky_flags |= narrow_flags
    trace_lines.append(
        f"narrow:{accumulator:016x}:{result:08x}:{narrow_flags:02x}:"
        f"sticky:{sticky_flags:02x}"
    )
    trace_bytes = "\n".join(trace_lines).encode("ascii")
    return {
        "result": result,
        "flags": sticky_flags,
        "trace_sha256": hashlib.sha256(trace_bytes).hexdigest(),
        "add_count": ROW_LENGTH,
        "consumed": ROW_LENGTH,
    }


def candidate(
    identifier: str,
    expected_result: int,
    expected_flags: int,
    overrides: Iterable[Tuple[int, int]] = (),
    fill: int = 0,
    runs: Iterable[Tuple[int, int, int]] = (),
) -> Candidate:
    return Candidate(
        identifier,
        fill,
        tuple(runs),
        tuple(overrides),
        expected_result,
        expected_flags,
    )


CANDIDATES: Tuple[Candidate, ...] = (
    candidate("Z0", 0x00000000, 0x00),
    candidate("Z1", 0x00000000, 0x00, fill=0x80000000),
    candidate("Z2", 0x00000000, 0x00, ((0, 0x80000000),)),
    candidate("Z3", 0x00000000, 0x00, ((127, 0x80000000),)),
    candidate("C0", 0x3F800000, 0x00, ((0, 0x3F800000),)),
    candidate("C1", 0x3F800000, 0x00, ((127, 0x3F800000),)),
    candidate("C2", 0x00000000, 0x00,
              ((0, 0xBF800000), (127, 0x3F800000))),
    candidate("C3", 0x00000000, 0x00,
              ((0, 0x3F800000), (127, 0xBF800000))),
    candidate("S0", 0x00000001, 0x00, ((0, 0x00000001),)),
    candidate("S1", 0x80000001, 0x00, ((0, 0x80000001),)),
    candidate("S2", 0x00000080, 0x00, fill=0x00000001),
    candidate("S3", 0x0000007F, 0x00, runs=((0, 127, 0x00000001),)),
    candidate("S4", 0x00800000, 0x00, ((0, 0x00800000),)),
    candidate("S5", 0x007FFFFF, 0x00,
              ((0, 0x00800000), (1, 0x80000001))),
    candidate("S6", 0x00800000, 0x00,
              ((0, 0x007FFFFF), (1, 0x00000001))),
    candidate("S7", 0x00000000, 0x00,
              ((0, 0x00000001), (1, 0x80000001))),
    candidate("S8", 0x00000001, 0x00,
              ((0, 0x00800000), (1, 0x807FFFFF))),
    candidate("S9", 0x00FFFFFE, 0x00,
              ((0, 0x007FFFFF), (1, 0x007FFFFF))),
    candidate("F0", 0x4B800001, 0x00,
              ((0, 0x4B800000), (1, 0x3F800000), (2, 0x3F800000))),
    candidate("F1", 0x3F800000, 0x00,
              ((0, 0x4B800000), (1, 0x3F800000), (2, 0xCB800000))),
    candidate("F2", 0xCB800001, 0x00,
              ((0, 0xCB800000), (1, 0xBF800000), (2, 0xBF800000))),
    candidate("F3", 0x3F800001, 0x00,
              ((0, 0x3F800000), (1, 0x33800000), (2, 0x33800000))),
    candidate("T0", 0x3F800000, 0x01,
              ((0, 0x3F800000), (1, 0x33800000))),
    candidate("T1", 0x3F800002, 0x01,
              ((0, 0x3F800000), (1, 0x34400000))),
    candidate("T2", 0x4B800000, 0x01,
              ((0, 0x4B800000), (1, 0x3F800000))),
    candidate("T3", 0x4B800002, 0x01,
              ((0, 0x4B800000), (1, 0x40400000))),
    candidate("T4", 0xCB800000, 0x01,
              ((0, 0xCB800000), (1, 0xBF800000))),
    candidate("T5", 0xCB800002, 0x01,
              ((0, 0xCB800000), (1, 0xC0400000))),
    candidate("D0", 0x00000000, 0x01,
              ((0, 0x71800000), (1, 0x3F800000), (2, 0xF1800000))),
    candidate("D1", 0x3F800000, 0x00,
              ((0, 0x71800000), (1, 0xF1800000), (2, 0x3F800000))),
    candidate("D2", 0x3F800000, 0x01,
              ((0, 0x71800000), (1, 0x3F800000),
               (2, 0xF1800000), (3, 0x3F800000))),
    candidate("D3", 0x00000000, 0x01,
              ((0, 0x71800000), (1, 0x57000000), (2, 0xF1800000))),
    candidate("D4", 0x58000000, 0x01,
              ((0, 0x71800000), (1, 0x57800000),
               (2, 0x57000000), (3, 0xF1800000))),
    candidate("D5", 0x00000000, 0x01,
              ((0, 0x71800000), (1, 0x56FFFFFF), (2, 0xF1800000))),
    candidate("D6", 0x57800000, 0x01,
              ((0, 0x71800000), (1, 0x57000001), (2, 0xF1800000))),
    candidate("D7", 0x00000000, 0x01,
              ((0, 0xF1800000), (1, 0xD7000000), (2, 0x71800000))),
    candidate("D8", 0xD8000000, 0x01,
              ((0, 0xF1800000), (1, 0xD7800000),
               (2, 0xD7000000), (3, 0x71800000))),
    candidate("D9", 0x00000000, 0x01,
              ((0, 0x71800000), (1, 0x57000000),
               (2, 0x57000000), (3, 0xF1800000))),
    candidate("O0", 0x7F7FFFFF, 0x00, ((0, 0x7F7FFFFF),)),
    candidate("O1", 0x7F7FFFFF, 0x01,
              ((0, 0x7F7FFFFF), (1, 0x72FFFFFF))),
    candidate("O2", 0x7F800000, 0x05,
              ((0, 0x7F7FFFFF), (1, 0x73000000))),
    candidate("O3", 0x7F800000, 0x05,
              ((0, 0x7F7FFFFF), (1, 0x73000001))),
    candidate("O4", 0x7F800000, 0x05,
              ((0, 0x7F7FFFFF), (1, 0x7F7FFFFF))),
    candidate("O5", 0xFF7FFFFF, 0x01,
              ((0, 0xFF7FFFFF), (1, 0xF2FFFFFF))),
    candidate("O6", 0xFF800000, 0x05,
              ((0, 0xFF7FFFFF), (1, 0xF3000000))),
    candidate("O7", 0x7F7FFFFF, 0x00,
              ((0, 0x7F7FFFFF), (1, 0x73000000), (2, 0xF3000000))),
    candidate("O8", 0x7F7FFFFF, 0x00,
              ((0, 0x7F7FFFFF), (1, 0x7F7FFFFF), (2, 0xFF7FFFFF))),
    candidate("I0", 0x7F800000, 0x00, ((0, 0x7F800000),)),
    candidate("I1", 0xFF800000, 0x00, ((0, 0xFF800000),)),
    candidate("I2", 0x7FC00000, 0x10,
              ((0, 0x7F800000), (1, 0xFF800000))),
    candidate("I3", 0x7F800000, 0x00,
              ((0, 0x7F800000), (1, 0x7F800000))),
    candidate("N0", 0x7FC00000, 0x00, ((0, 0x7FC12345),)),
    candidate("N1", 0x7FC00000, 0x00, ((0, 0xFFC12345),)),
    candidate("N2", 0x7FC00000, 0x10, ((0, 0x7F800001),)),
    candidate("N3", 0x7FC00000, 0x10, ((0, 0xFF800001),)),
    candidate("N4", 0x7FC00000, 0x10,
              ((0, 0x7FC12345), (127, 0x7F800001))),
    candidate("N5", 0x7FC00000, 0x10,
              ((0, 0x7F800000), (127, 0xFF800000))),
    candidate("N6", 0x7FC00000, 0x10,
              ((0, 0x7F800000), (127, 0x7F800001))),
    candidate("N7", 0x7FC00000, 0x11,
              ((0, 0x71800000), (1, 0x3F800000), (127, 0x7F800001))),
    # 合同显式要求的第二个 tree/reorder discriminator。
    candidate("D10", 0x57000000, 0x01,
              ((0, 0x71800000), (1, 0x57000000),
               (2, 0xF1800000), (3, 0x57000000))),
)


def validate_candidates() -> None:
    identifiers = set()
    failures = []
    for item in CANDIDATES:
        if item.identifier in identifiers:
            raise OracleError(f"duplicate candidate id {item.identifier}")
        identifiers.add(item.identifier)
        actual = ordered_sum_row(expand_candidate(item))
        result = int(actual["result"])
        flags = int(actual["flags"])
        if result != item.expected_result or flags != item.expected_flags:
            failures.append(
                f"{item.identifier}:actual={result:08x}/{flags:02x}:"
                f"expected={item.expected_result:08x}/{item.expected_flags:02x}"
            )
    if failures:
        raise OracleError("candidate mismatch " + ";".join(failures))


def mutation_x0_seed(inputs: Sequence[int]) -> Tuple[int, int]:
    widened, flags = widen_f32(inputs[0])
    accumulator = widened
    for raw in inputs[1:]:
        widened, widen_flags = widen_f32(raw)
        accumulator, add_flags = add_f64(accumulator, widened)
        flags |= widen_flags | add_flags
    result, narrow_flags = narrow_f64(accumulator)
    return result, flags | narrow_flags


def mutation_f32_accumulator(inputs: Sequence[int]) -> Tuple[int, int]:
    accumulator = 0
    flags = 0
    for raw in inputs:
        accumulator, add_flags = add_bits(accumulator, raw, 8, 23)
        flags |= add_flags
    return accumulator, flags


def mutation_intermediate_narrow(inputs: Sequence[int]) -> Tuple[int, int]:
    accumulator = 0
    flags = 0
    for index, raw in enumerate(inputs):
        widened, widen_flags = widen_f32(raw)
        accumulator, add_flags = add_f64(accumulator, widened)
        flags |= widen_flags | add_flags
        if index == 63:
            narrowed, narrow_flags = narrow_f64(accumulator)
            accumulator, rewiden_flags = widen_f32(narrowed)
            flags |= narrow_flags | rewiden_flags
    result, final_flags = narrow_f64(accumulator)
    return result, flags | final_flags


def mutation_127_add(inputs: Sequence[int]) -> Tuple[int, int]:
    # Distinct from x0_seed: keep the required +0 seed, execute only indices
    # 0..126, and omit the final input entirely.  C1/N4 are last-index killers;
    # Z1 remains an independent signed-zero killer for x0_seed.
    accumulator = 0
    flags = 0
    for raw in inputs[:-1]:
        widened, widen_flags = widen_f32(raw)
        accumulator, add_flags = add_f64(accumulator, widened)
        flags |= widen_flags | add_flags
    result, narrow_flags = narrow_f64(accumulator)
    return result, flags | narrow_flags


def mutation_early_nan(inputs: Sequence[int]) -> Tuple[int, int]:
    accumulator = 0
    flags = 0
    for raw in inputs:
        widened, widen_flags = widen_f32(raw)
        accumulator, add_flags = add_f64(accumulator, widened)
        flags |= widen_flags | add_flags
        if decode_bits(raw, 8, 23).kind == "nan":
            break
    result, narrow_flags = narrow_f64(accumulator)
    return result, flags | narrow_flags


def mutation_payload_propagation(inputs: Sequence[int]) -> Tuple[int, int]:
    correct = ordered_sum_row(inputs)
    for raw in inputs:
        decoded = decode_bits(raw, 8, 23)
        if decoded.kind == "nan":
            payload = raw & 0x007FFFFF
            payload |= 0x00400000
            result = ((decoded.sign << 31) | 0x7F800000 | payload)
            return result, int(correct["flags"])
    return int(correct["result"]), int(correct["flags"])


def mutation_ftz(inputs: Sequence[int]) -> Tuple[int, int]:
    mapped = []
    for raw in inputs:
        decoded = decode_bits(raw, 8, 23)
        if decoded.kind == "finite" and ((raw >> 23) & 0xFF) == 0:
            mapped.append(decoded.sign << 31)
        else:
            mapped.append(raw)
    result = ordered_sum_row(mapped)
    raw_result = int(result["result"])
    if ((raw_result >> 23) & 0xFF) == 0 and (raw_result & 0x7FFFFF) != 0:
        raw_result &= 0x80000000
    return raw_result, int(result["flags"])


def mutation_wrong_tininess(inputs: Sequence[int]) -> Tuple[int, int]:
    correct = ordered_sum_row(inputs)
    result = int(correct["result"])
    flags = int(correct["flags"])
    if ((result >> 23) & 0xFF) == 0 and (result & 0x7FFFFF) != 0:
        flags |= FLAG_UF
    return result, flags


def mutation_reorder(inputs: Sequence[int]) -> Tuple[int, int]:
    result = ordered_sum_row(list(reversed(inputs)))
    return int(result["result"]), int(result["flags"])


def mutation_pairwise_tree(inputs: Sequence[int]) -> Tuple[int, int]:
    flags = 0
    level = []
    for raw in inputs:
        widened, widen_flags = widen_f32(raw)
        flags |= widen_flags
        level.append(widened)
    while len(level) > 1:
        next_level = []
        index = 0
        while index < len(level):
            if index + 1 == len(level):
                next_level.append(level[index])
            else:
                value, add_flags = add_f64(level[index], level[index + 1])
                flags |= add_flags
                next_level.append(value)
            index += 2
        level = next_level
    accumulator, seed_flags = add_f64(0, level[0])
    flags |= seed_flags
    result, narrow_flags = narrow_f64(accumulator)
    return result, flags | narrow_flags


MUTATIONS: Mapping[str, Callable[[Sequence[int]], Tuple[int, int]]] = {
    "x0_seed": mutation_x0_seed,
    "f32_accumulator": mutation_f32_accumulator,
    "pairwise_tree": mutation_pairwise_tree,
    "reorder": mutation_reorder,
    "intermediate_narrow": mutation_intermediate_narrow,
    "127_add": mutation_127_add,
    "early_nan": mutation_early_nan,
    "payload_propagation": mutation_payload_propagation,
    "ftz": mutation_ftz,
    "wrong_tininess": mutation_wrong_tininess,
}


MUTATION_ONLY_ROWS: Mapping[str, Tuple[int, ...]] = {
    "M0": tuple(
        0x4B800000 if index == 0
        else 0x3F800000 if index in (1, 64, 65)
        else 0x00000000
        for index in range(ROW_LENGTH)
    ),
}


def mutation_audit_rows() -> Mapping[str, Tuple[int, ...]]:
    rows: Dict[str, Tuple[int, ...]] = {
        item.identifier: tuple(expand_candidate(item))
        for item in CANDIDATES
    }
    for identifier, row in MUTATION_ONLY_ROWS.items():
        if identifier in rows or len(row) != ROW_LENGTH:
            raise OracleError(f"invalid mutation-only row {identifier}")
        rows[identifier] = row
    return rows


def mutation_m0_outcomes() -> Mapping[str, Tuple[int, int]]:
    row = MUTATION_ONLY_ROWS["M0"]
    correct = ordered_sum_row(row)
    outcomes = {
        "production": (int(correct["result"]), int(correct["flags"])),
        "intermediate_narrow": mutation_intermediate_narrow(row),
        "f32_accumulator": mutation_f32_accumulator(row),
    }
    expected = {
        "production": (0x4B800002, FLAG_NX),
        "intermediate_narrow": (0x4B800001, FLAG_NX),
        "f32_accumulator": (0x4B800000, FLAG_NX),
    }
    if outcomes != expected:
        raise OracleError(f"M0 outcome mismatch actual={outcomes} expected={expected}")
    if len(set(outcomes.values())) != 3:
        raise OracleError("M0 does not distinguish three accumulation semantics")
    return outcomes


def mutation_behavior_signatures() -> Mapping[str, Tuple[Tuple[int, int], ...]]:
    """Audit canonical60 plus explicit mutation-only discriminator behavior."""
    signatures: Dict[str, Tuple[Tuple[int, int], ...]] = {}
    owners: Dict[Tuple[Tuple[int, int], ...], str] = {}
    rows = mutation_audit_rows()
    for mutation_name, mutation in MUTATIONS.items():
        signature = tuple(mutation(row) for row in rows.values())
        prior = owners.get(signature)
        if prior is not None:
            raise OracleError(
                f"mutation behavior alias: {prior},{mutation_name}"
            )
        owners[signature] = mutation_name
        signatures[mutation_name] = signature
    return signatures


def mutation_witnesses() -> Mapping[str, str]:
    mutation_m0_outcomes()
    mutation_behavior_signatures()
    witnesses: Dict[str, str] = {}
    rows = mutation_audit_rows()
    preferred = {
        "intermediate_narrow": "M0",
        "127_add": "C1",
        "x0_seed": "Z1",
    }
    for mutation_name, mutation in MUTATIONS.items():
        ordered_identifiers = (
            [preferred[mutation_name]]
            if mutation_name in preferred
            else list(rows)
        )
        for identifier in ordered_identifiers:
            row = rows[identifier]
            correct = ordered_sum_row(row)
            mutant_result, mutant_flags = mutation(row)
            if (mutant_result != int(correct["result"])
                    or mutant_flags != int(correct["flags"])):
                witnesses[mutation_name] = identifier
                break
    missing = sorted(set(MUTATIONS) - set(witnesses))
    if missing:
        raise OracleError("mutation witness GAP: " + ",".join(missing))
    return witnesses


def vector_record(item: Candidate) -> Mapping[str, object]:
    row = expand_candidate(item)
    actual = ordered_sum_row(row)
    return {
        "schema": SCHEMA,
        "id": item.identifier,
        "fill": f"{item.fill:08x}",
        "runs": [[first, last, f"{value:08x}"]
                 for first, last, value in item.runs],
        "overrides": [[index, f"{value:08x}"]
                      for index, value in item.overrides],
        "result": f"{int(actual['result']):08x}",
        "flags": f"{int(actual['flags']):02x}",
        "trace_sha256": str(actual["trace_sha256"]),
        "elements": ROW_LENGTH,
        "add_count": int(actual["add_count"]),
        "consumed": int(actual["consumed"]),
    }


def write_vectors(path: Path) -> None:
    validate_candidates()
    records = [vector_record(item) for item in CANDIDATES]
    encoded = "".join(
        json.dumps(record, sort_keys=True, separators=(",", ":")) + "\n"
        for record in records
    )
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(encoded, encoding="utf-8", newline="\n")


def parse_hex(value: object, width: int, field: str) -> int:
    if not isinstance(value, str) or len(value) != width:
        raise OracleError(f"invalid {field}")
    try:
        parsed = int(value, 16)
    except ValueError as error:
        raise OracleError(f"invalid {field}") from error
    return parsed


def verify_vectors(path: Path) -> int:
    expected_by_id = {item.identifier: item for item in CANDIDATES}
    seen = set()
    line_count = 0
    with path.open("r", encoding="utf-8", newline="") as stream:
        for raw_line in stream:
            line_count += 1
            if not raw_line.endswith("\n"):
                raise OracleError(f"line {line_count} missing LF")
            record = json.loads(raw_line)
            if record.get("schema") != SCHEMA:
                raise OracleError(f"line {line_count} schema")
            identifier = record.get("id")
            if identifier not in expected_by_id or identifier in seen:
                raise OracleError(f"line {line_count} id")
            seen.add(identifier)
            item = expected_by_id[str(identifier)]
            canonical = vector_record(item)
            if record != canonical:
                raise OracleError(f"line {line_count} canonical mismatch id={identifier}")
            parse_hex(record["result"], 8, "result")
            parse_hex(record["flags"], 2, "flags")
    if seen != set(expected_by_id):
        missing = sorted(set(expected_by_id) - seen)
        raise OracleError("vector membership missing " + ",".join(missing))
    if line_count < 43:
        raise OracleError(f"vector count {line_count} below 43")
    return line_count


def self_test() -> None:
    anchors = (
        (widen_f32(0x00000001), (0x36A0000000000000, 0x00)),
        (widen_f32(0x7F800001), (F64_CANONICAL_NAN, FLAG_NV)),
        (add_f64(0x3FF0000000000000, 0x3CA0000000000000),
         (0x3FF0000000000000, FLAG_NX)),
        (add_f64(0x7FF0000000000000, 0xFFF0000000000000),
         (F64_CANONICAL_NAN, FLAG_NV)),
        (narrow_f64(0x36A0000000000000), (0x00000001, 0x00)),
        (narrow_f64(0x0000000000000001), (0x00000000, FLAG_UF | FLAG_NX)),
        (narrow_f64(0x7FF0000000000001), (F32_CANONICAL_NAN, FLAG_NV)),
    )
    for actual, expected in anchors:
        if actual != expected:
            raise OracleError(f"self-test anchor actual={actual} expected={expected}")
    validate_candidates()


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser()
    subparsers = parser.add_subparsers(dest="command", required=True)
    subparsers.add_parser("validate")
    subparsers.add_parser("self-test")
    subparsers.add_parser("mutation-audit")
    generate = subparsers.add_parser("generate")
    generate.add_argument("--output", required=True, type=Path)
    verify = subparsers.add_parser("verify")
    verify.add_argument("--vectors", required=True, type=Path)
    trace = subparsers.add_parser("trace")
    trace.add_argument("--id", required=True)
    return parser


def main(argv: Sequence[str] | None = None) -> int:
    args = build_parser().parse_args(argv)
    try:
        if args.command == "validate":
            validate_candidates()
            print(f"[NPU-ORDERED-SUM-ROWS-ORACLE][VALIDATE][PASS] rows={len(CANDIDATES)} source=no-shell-candidates+contract-D10")
        elif args.command == "self-test":
            self_test()
            print(f"[NPU-ORDERED-SUM-ROWS-ORACLE][SELFTEST][PASS] anchors=7 rows={len(CANDIDATES)} integer_only=1")
        elif args.command == "mutation-audit":
            witnesses = mutation_witnesses()
            m0 = mutation_m0_outcomes()
            encoded = ",".join(f"{name}:{witnesses[name]}" for name in sorted(witnesses))
            print(
                "[NPU-ORDERED-SUM-ROWS-ORACLE][M0][PASS] "
                f"production={m0['production'][0]:08x}/{m0['production'][1]:02x} "
                f"checkpoint={m0['intermediate_narrow'][0]:08x}/{m0['intermediate_narrow'][1]:02x} "
                f"f32_accumulator={m0['f32_accumulator'][0]:08x}/{m0['f32_accumulator'][1]:02x} "
                "synthetic_only=1"
            )
            print(
                "[NPU-ORDERED-SUM-ROWS-ORACLE][MUTATION][PASS] "
                f"mutations={len(witnesses)} "
                f"distinct={len(mutation_behavior_signatures())} "
                f"signature_rows={len(mutation_audit_rows())} witnesses={encoded}"
            )
        elif args.command == "generate":
            write_vectors(args.output)
            print(f"[NPU-ORDERED-SUM-ROWS-ORACLE][GENERATE][PASS] rows={len(CANDIDATES)} output={args.output}")
        elif args.command == "verify":
            rows = verify_vectors(args.vectors)
            print(f"[NPU-ORDERED-SUM-ROWS-ORACLE][VERIFY][PASS] rows={rows} vectors={args.vectors}")
        elif args.command == "trace":
            selected = [item for item in CANDIDATES if item.identifier == args.id]
            if len(selected) != 1:
                raise OracleError(f"unknown id {args.id}")
            print(json.dumps(vector_record(selected[0]), sort_keys=True,
                             separators=(",", ":")))
        else:
            raise OracleError("unreachable command")
    except (OracleError, OSError, json.JSONDecodeError) as error:
        print(f"[NPU-ORDERED-SUM-ROWS-ORACLE][{args.command.upper()}][FAIL] {error}",
              file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
