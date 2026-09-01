#!/usr/bin/env python3
# SPDX-License-Identifier: MIT
"""Pure-integer raw-bit oracle for Tensor NPU Unary/GLU F32 operations.

This module composes the frozen AOR EXP32/LOG32 source-replay oracle with
independent IEEE-754 binary32 add, multiply, and divide primitives.  It never
asks the host floating-point environment to evaluate an expected result.
"""

from __future__ import annotations

import argparse
import ast
import hashlib
import json
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Iterable, Sequence


sys.dont_write_bytecode = True

import aor_f32_oracle as aor


PROFILE = "TENSOR_NPU_UNARY_GLU_F32_RNE_V1"
MANIFEST_SCHEMA = "unary-glu-f32-manifest-v1"
VECTOR_SCHEMA = "unary-glu-f32-vector-set-v1"
MUTATION_SCHEMA = "unary-glu-f32-mutation-audit-v1"
EVIDENCE_SCHEMA = "unary-glu-f32-oracle-evidence-v2"
FLAGS_PROFILE = "IEEE754_F32_RNE_TININESS_AFTER_STICKY_V1"

AOR_PROFILE = "AOR_AARCH64_FMA_RNE_V1"
AOR_GENERATOR_SHA256 = "d18d79a44940d2e7ce915b64bc6cf65383f2307d9d16ec792d6e4077c2d59e95"
AOR_MANIFEST_CANONICAL_SHA256 = "4d7b403b5f835adfc4465f920a9322ddf71b7568aaf0f1790c84e0b81371f004"
AOR_VECTORS_SHA256 = "e635c1ce963bb814f746dc828d715bd6cc39841f11ed8551aa7b15f128fcaa41"
EXPECTED_MANIFEST_SHA256 = "fd31c9dae64f8fbb0f946ff57177cfb944ae8e41ffae19304d25d06c5de5d370"

PASS_MARKER = "[UNARY-GLU-F32-ORACLE][PASS]"
FAIL_MARKER = "[UNARY-GLU-F32-ORACLE][FAIL]"
TEST_PASS_MARKER = "[UNARY-GLU-F32-TEST][PASS]"
EVIDENCE_PASS_MARKER = "[UNARY-GLU-F32-EVIDENCE][PASS]"

SCRIPT_PATH = Path(__file__).resolve()
REPO_ROOT = SCRIPT_PATH.parent.parent
DEFAULT_MANIFEST = REPO_ROOT.joinpath("tests", "vectors", "unary_glu_f32_manifest.json")
DEFAULT_VECTORS = REPO_ROOT.joinpath("tests", "vectors", "unary_glu_f32_vectors.jsonl")
AOR_MANIFEST_PATH = REPO_ROOT.joinpath("tests", "vectors", "aor_f32_manifest.json")
AOR_VECTORS_PATH = REPO_ROOT.joinpath("tests", "vectors", "aor_f32_vectors.jsonl")
TMP_BUILD = REPO_ROOT.joinpath("tmp", "build", "unary-glu-f32-oracle")
TMP_LOGS = REPO_ROOT.joinpath("tmp", "logs", "unary-glu-f32-oracle")

ONE_RAW32 = 0x3F800000
TWENTY_RAW32 = 0x41A00000
POSITIVE_INFINITY_RAW32 = 0x7F800000
CANONICAL_INTERNAL_NAN_RAW32 = 0x7FC00000
SIGN_MASK32 = 1 << 31
FLAG_ORDER = ("NV", "DZ", "OF", "UF", "NX")
OPERATIONS = ("SIGMOID", "SOFTPLUS", "SILU", "SWIGLU")
VECTOR_OPERATIONS = (*OPERATIONS, "MUL32_RNE")

PRODUCTION_IMPORT_ALLOWLIST = frozenset(
    {
        ("from", "__future__", "annotations", None),
        ("import", "argparse", None, None),
        ("import", "ast", None, None),
        ("import", "hashlib", None, None),
        ("import", "json", None, None),
        ("import", "sys", None, None),
        ("from", "dataclasses", "dataclass", None),
        ("from", "pathlib", "Path", None),
        ("from", "typing", "Any", None),
        ("from", "typing", "Iterable", None),
        ("from", "typing", "Sequence", None),
        ("import", "aor_f32_oracle", None, "aor"),
    }
)

# The production gate is a closed capability policy.  Syntax, import identity,
# call origin, module attributes, and object attributes are all positive
# allowlists; adding a new capability requires an explicit reviewed edit here.
AST_NODE_CAPABILITIES = frozenset(
    {
        "Add",
        "And",
        "AnnAssign",
        "Assign",
        "Attribute",
        "AugAssign",
        "BinOp",
        "BitAnd",
        "BitOr",
        "BitXor",
        "BoolOp",
        "Break",
        "Call",
        "ClassDef",
        "Compare",
        "Constant",
        "Continue",
        "Dict",
        "DictComp",
        "Eq",
        "ExceptHandler",
        "Expr",
        "For",
        "FunctionDef",
        "GeneratorExp",
        "Gt",
        "GtE",
        "If",
        "IfExp",
        "Import",
        "ImportFrom",
        "In",
        "Is",
        "IsNot",
        "LShift",
        "List",
        "ListComp",
        "Load",
        "Lt",
        "LtE",
        "Module",
        "Mult",
        "Name",
        "Not",
        "NotEq",
        "NotIn",
        "Or",
        "Pass",
        "RShift",
        "Raise",
        "Return",
        "Set",
        "Slice",
        "Starred",
        "Store",
        "Sub",
        "Subscript",
        "Try",
        "Tuple",
        "USub",
        "UnaryOp",
        "While",
        "alias",
        "arg",
        "arguments",
        "comprehension",
        "keyword",
    }
)

NAME_CALL_CAPABILITIES = frozenset(
    {
        "Path",
        "SystemExit",
        "abs",
        "any",
        "bool",
        "dataclass",
        "divmod",
        "enumerate",
        "frozenset",
        "int",
        "isinstance",
        "len",
        "list",
        "max",
        "min",
        "print",
        "range",
        "set",
        "sorted",
        "str",
        "sum",
        "super",
        "tuple",
        "type",
    }
)

MODULE_ATTRIBUTE_CAPABILITIES = {
    "aor": frozenset(
        {
            "AorOracle",
            "AorResult",
            "Decoded",
            "F32",
            "OracleError",
            "RawResult",
            "canonical_bytes",
            "compare_finite",
            "decode_f32",
            "generator_sha256",
            "load_manifest",
            "pack_f32",
            "parse_raw",
            "raw_text",
            "u32",
            "validate_manifest",
        }
    ),
    "argparse": frozenset({"ArgumentParser"}),
    "ast": frozenset(
        {
            "AST",
            "AnnAssign",
            "AsyncFunctionDef",
            "Attribute",
            "BinOp",
            "Call",
            "ClassDef",
            "Constant",
            "ExceptHandler",
            "FunctionDef",
            "Import",
            "ImportFrom",
            "Name",
            "Subscript",
            "Tuple",
            "arg",
            "iter_child_nodes",
            "parse",
            "walk",
        }
    ),
    "hashlib": frozenset({"sha256"}),
    "json": frozenset({"JSONDecodeError", "loads"}),
    "sys": frozenset({"dont_write_bytecode", "stderr"}),
}

MODULE_CALL_CAPABILITIES = {
    "aor": frozenset(
        {
            "AorOracle",
            "RawResult",
            "canonical_bytes",
            "compare_finite",
            "decode_f32",
            "generator_sha256",
            "load_manifest",
            "pack_f32",
            "parse_raw",
            "raw_text",
            "u32",
            "validate_manifest",
        }
    ),
    "argparse": frozenset({"ArgumentParser"}),
    "ast": frozenset({"iter_child_nodes", "parse", "walk"}),
    "hashlib": frozenset({"sha256"}),
    "json": frozenset({"loads"}),
    "sys": frozenset(),
}

OBJECT_ATTRIBUTE_CAPABILITIES = frozenset(
    {
        "_append_aor_child",
        "_append_primitive_child",
        "_complete",
        "_unsupported",
        "add",
        "add_argument",
        "add_parser",
        "add_subparsers",
        "aor",
        "api_flags",
        "append",
        "annotation",
        "arg",
        "args",
        "asname",
        "attr",
        "bases",
        "bias",
        "bit_length",
        "bootstrap_self_log",
        "canonical_bytes",
        "children",
        "code",
        "command",
        "commit_count",
        "count",
        "decode",
        "decorator_list",
        "difference",
        "encode",
        "endswith",
        "evaluate",
        "evidence",
        "exp32",
        "exponent",
        "flags",
        "fraction_bits",
        "func",
        "get",
        "hexdigest",
        "id",
        "input",
        "items",
        "join",
        "joinpath",
        "keywords",
        "kind",
        "level",
        "log32",
        "lower",
        "magnitude",
        "manifest",
        "manifest_sha256",
        "maximum_exponent",
        "minimum_exponent",
        "mkdir",
        "module",
        "name",
        "names",
        "output",
        "parent",
        "parse_args",
        "precision",
        "quiet",
        "raw",
        "read_bytes",
        "read_text",
        "reason",
        "relative_to",
        "resolve",
        "returns",
        "sign",
        "splitlines",
        "startswith",
        "status",
        "trace",
        "type",
        "update",
        "value",
        "write_bytes",
    }
)

OBJECT_CALL_CAPABILITIES = frozenset(
    {
        "_append_aor_child",
        "_append_primitive_child",
        "_complete",
        "_unsupported",
        "add",
        "add_argument",
        "add_parser",
        "add_subparsers",
        "append",
        "bit_length",
        "count",
        "decode",
        "difference",
        "encode",
        "endswith",
        "evaluate",
        "exp32",
        "get",
        "hexdigest",
        "items",
        "join",
        "joinpath",
        "log32",
        "lower",
        "mkdir",
        "parse_args",
        "read_bytes",
        "read_text",
        "relative_to",
        "resolve",
        "splitlines",
        "startswith",
        "update",
        "write_bytes",
    }
)


class OracleError(RuntimeError):
    """Fail-closed error with a stable code and IEEE flag payload."""

    def __init__(self, code: str, message: str, flags: Sequence[str] = ()) -> None:
        super().__init__(message)
        self.code = code
        self.flags = ordered_flags(flags)


class ManifestError(OracleError):
    pass


@dataclass(frozen=True)
class UnaryResult:
    status: str
    raw: int
    flags: tuple[str, ...]
    children: tuple[dict[str, Any], ...]
    commit_count: int
    reason: str | None


def ordered_flags(flags: Iterable[str]) -> tuple[str, ...]:
    selected = set(flags)
    unknown = selected.difference(FLAG_ORDER)
    if unknown:
        raise OracleError("UNKNOWN_FLAG", "unknown exception flag: " + ",".join(sorted(unknown)))
    return tuple(name for name in FLAG_ORDER if name in selected)


def merge_flags(*groups: Iterable[str]) -> tuple[str, ...]:
    merged: set[str] = set()
    for group in groups:
        merged.update(group)
    return ordered_flags(merged)


def raw_text(raw: int) -> str:
    return aor.raw_text(aor.u32(raw), 32)


def parse_raw32(text: str) -> int:
    try:
        return aor.parse_raw(text, 32)
    except aor.OracleError as error:
        raise OracleError(error.code, str(error), error.flags) from error


def canonical_bytes(value: Any) -> bytes:
    try:
        return aor.canonical_bytes(value)
    except aor.OracleError as error:
        raise OracleError(error.code, str(error), error.flags) from error


def sha256_bytes(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def generator_sha256() -> str:
    try:
        return sha256_bytes(SCRIPT_PATH.read_bytes())
    except OSError as error:
        raise OracleError("GENERATOR_READ", str(error)) from error


def _nan_flags(*values: aor.Decoded) -> tuple[str, ...]:
    return ("NV",) if any(value.kind == "nan" and not value.quiet for value in values) else ()


def _internal_nan(*values: aor.Decoded) -> aor.RawResult:
    return aor.RawResult(CANONICAL_INTERNAL_NAN_RAW32, _nan_flags(*values))


def _infinity(sign: int, flags: Iterable[str] = ()) -> aor.RawResult:
    return aor.RawResult((sign << 31) | POSITIVE_INFINITY_RAW32, ordered_flags(flags))


def _zero(sign: int) -> aor.RawResult:
    return aor.RawResult(sign << 31, ())


def _require_raw_int(value: Any, name: str) -> int:
    if type(value) is not int:
        raise OracleError("RAW_TYPE", name + " must be an integer and not a boolean")
    return aor.u32(value)


def f32_add(lhs_raw: int, rhs_raw: int) -> aor.RawResult:
    """IEEE binary32 addition, RN-even, implemented with exact signed dyadics."""

    lhs_word = _require_raw_int(lhs_raw, "lhs_raw")
    rhs_word = _require_raw_int(rhs_raw, "rhs_raw")
    lhs = aor.decode_f32(lhs_word)
    rhs = aor.decode_f32(rhs_word)
    if lhs.kind == "nan" or rhs.kind == "nan":
        return _internal_nan(lhs, rhs)
    if lhs.kind == "infinity" and rhs.kind == "infinity":
        if lhs.sign != rhs.sign:
            return aor.RawResult(CANONICAL_INTERNAL_NAN_RAW32, ("NV",))
        return _infinity(lhs.sign)
    if lhs.kind == "infinity":
        return _infinity(lhs.sign)
    if rhs.kind == "infinity":
        return _infinity(rhs.sign)
    if lhs.magnitude == 0 and rhs.magnitude == 0:
        return _zero(lhs.sign & rhs.sign)
    nonzero = [value for value in (lhs, rhs) if value.magnitude != 0]
    common_exponent = min(value.exponent for value in nonzero)
    total = 0
    for value in nonzero:
        term = value.magnitude << (value.exponent - common_exponent)
        total += -term if value.sign else term
    if total == 0:
        return _zero(0)
    return aor.pack_f32(int(total < 0), abs(total), common_exponent)


def f32_mul(lhs_raw: int, rhs_raw: int) -> aor.RawResult:
    """IEEE binary32 multiplication, RN-even, from one exact dyadic product."""

    lhs_word = _require_raw_int(lhs_raw, "lhs_raw")
    rhs_word = _require_raw_int(rhs_raw, "rhs_raw")
    lhs = aor.decode_f32(lhs_word)
    rhs = aor.decode_f32(rhs_word)
    if lhs.kind == "nan" or rhs.kind == "nan":
        return _internal_nan(lhs, rhs)
    sign = lhs.sign ^ rhs.sign
    if (lhs.kind == "infinity" and rhs.kind == "zero") or (
        rhs.kind == "infinity" and lhs.kind == "zero"
    ):
        return aor.RawResult(CANONICAL_INTERNAL_NAN_RAW32, ("NV",))
    if lhs.kind == "infinity" or rhs.kind == "infinity":
        return _infinity(sign)
    if lhs.magnitude == 0 or rhs.magnitude == 0:
        return _zero(sign)
    return aor.pack_f32(
        sign,
        lhs.magnitude * rhs.magnitude,
        lhs.exponent + rhs.exponent,
    )


def _ratio_at_least_power(numerator: int, denominator: int, exponent: int, power: int) -> bool:
    shift = exponent - power
    if shift >= 0:
        return (numerator << shift) >= denominator
    return numerator >= (denominator << (-shift))


def _rational_floor_log(numerator: int, denominator: int, exponent: int) -> int:
    if numerator <= 0 or denominator <= 0:
        raise OracleError("RATIONAL_DOMAIN", "floor-log requires positive numerator and denominator")
    candidate = numerator.bit_length() - denominator.bit_length() + exponent
    if not _ratio_at_least_power(numerator, denominator, exponent, candidate):
        candidate -= 1
    return candidate


def _round_rational_at_grid(
    numerator: int,
    denominator: int,
    exponent: int,
    grid: int,
) -> tuple[int, bool]:
    shift = exponent - grid
    if shift >= 0:
        dividend = numerator << shift
        divisor = denominator
    else:
        dividend = numerator
        divisor = denominator << (-shift)
    retained, remainder = divmod(dividend, divisor)
    doubled = remainder << 1
    increment = doubled > divisor or (doubled == divisor and bool(retained & 1))
    return retained + int(increment), remainder != 0


def pack_f32_rational(
    sign: int,
    numerator: int,
    denominator: int,
    exponent: int,
) -> aor.RawResult:
    """Round ``numerator/denominator * 2^exponent`` once to binary32.

    Tininess-after uses two independent integer rounding decisions.  First the
    exact rational is rounded to 24-bit precision with an unbounded exponent;
    only that temporary result decides whether it remains tiny.  The final raw
    encoding is then rounded directly from the exact rational to the normal or
    subnormal binary32 grid.  The temporary result is never rounded again.
    """

    if sign not in (0, 1) or numerator < 0 or denominator <= 0:
        raise OracleError("RATIONAL_DOMAIN", "invalid rational pack operand")
    if numerator == 0:
        return _zero(sign)

    floor_log = _rational_floor_log(numerator, denominator, exponent)
    precision_grid = floor_log - (aor.F32.precision - 1)
    precision_rounded, _ = _round_rational_at_grid(
        numerator,
        denominator,
        exponent,
        precision_grid,
    )
    if precision_rounded == 0:
        raise OracleError("RATIONAL_INTERNAL", "unbounded precision rounding produced zero")
    precision_floor_log = precision_rounded.bit_length() - 1 + precision_grid
    tiny_after = precision_floor_log < aor.F32.minimum_exponent

    minimum_grid = aor.F32.minimum_exponent - (aor.F32.precision - 1)
    final_grid = max(floor_log - (aor.F32.precision - 1), minimum_grid)
    rounded, inexact = _round_rational_at_grid(
        numerator,
        denominator,
        exponent,
        final_grid,
    )
    inexact_flags: tuple[str, ...]
    if inexact and tiny_after:
        inexact_flags = ("UF", "NX")
    elif inexact:
        inexact_flags = ("NX",)
    else:
        inexact_flags = ()
    sign_word = sign << 31
    if rounded == 0:
        return aor.RawResult(sign_word, inexact_flags)

    result_floor_log = rounded.bit_length() - 1 + final_grid
    if result_floor_log > aor.F32.maximum_exponent:
        return _infinity(sign, ("OF", "NX"))
    if result_floor_log >= aor.F32.minimum_exponent:
        alignment = aor.F32.precision - rounded.bit_length()
        if alignment >= 0:
            significand = rounded << alignment
        else:
            discarded_mask = (1 << (-alignment)) - 1
            if rounded & discarded_mask:
                raise OracleError("RATIONAL_INTERNAL", "normal result is not exactly alignable")
            significand = rounded >> (-alignment)
        exponent_field = result_floor_log + aor.F32.bias
        fraction = significand - (1 << (aor.F32.precision - 1))
        return aor.RawResult(sign_word | (exponent_field << aor.F32.fraction_bits) | fraction, inexact_flags)

    if final_grid != minimum_grid or rounded >= (1 << (aor.F32.precision - 1)):
        raise OracleError("RATIONAL_INTERNAL", "subnormal encoding invariant failed")
    return aor.RawResult(sign_word | rounded, inexact_flags)


def f32_div(lhs_raw: int, rhs_raw: int) -> aor.RawResult:
    """IEEE binary32 division, RN-even, using exact integer rational rounding."""

    lhs_word = _require_raw_int(lhs_raw, "lhs_raw")
    rhs_word = _require_raw_int(rhs_raw, "rhs_raw")
    lhs = aor.decode_f32(lhs_word)
    rhs = aor.decode_f32(rhs_word)
    if lhs.kind == "nan" or rhs.kind == "nan":
        return _internal_nan(lhs, rhs)
    sign = lhs.sign ^ rhs.sign
    if lhs.kind == "infinity" and rhs.kind == "infinity":
        return aor.RawResult(CANONICAL_INTERNAL_NAN_RAW32, ("NV",))
    if lhs.kind == "zero" and rhs.kind == "zero":
        return aor.RawResult(CANONICAL_INTERNAL_NAN_RAW32, ("NV",))
    if lhs.kind == "infinity":
        return _infinity(sign)
    if rhs.kind == "infinity":
        return _zero(sign)
    if rhs.kind == "zero":
        return _infinity(sign, ("DZ",))
    if lhs.kind == "zero":
        return _zero(sign)
    return pack_f32_rational(
        sign,
        lhs.magnitude,
        rhs.magnitude,
        lhs.exponent - rhs.exponent,
    )


def _trace_hash(trace: Sequence[dict[str, Any]]) -> str:
    return sha256_bytes(canonical_bytes(list(trace)))


def _child_record(
    index: int,
    opcode: str,
    materialized: str,
    operands: Sequence[int],
    result: aor.RawResult,
    detail_trace: Sequence[dict[str, Any]] | None = None,
) -> dict[str, Any]:
    return {
        "child_index": index,
        "detail_trace_sha256": None if detail_trace is None else _trace_hash(detail_trace),
        "flags": list(ordered_flags(result.flags)),
        "materialized": materialized,
        "opcode": opcode,
        "operands_raw32": [raw_text(raw) for raw in operands],
        "result_raw32": raw_text(result.raw),
    }


class TensorUnaryGluOracle:
    def __init__(self, manifest: dict[str, Any]) -> None:
        self.manifest_sha256 = validate_manifest(manifest)
        try:
            aor_manifest = aor.load_manifest(AOR_MANIFEST_PATH)
            self.aor = aor.AorOracle(aor_manifest)
        except aor.OracleError as error:
            raise OracleError("AOR_BINDING", str(error), error.flags) from error

    @staticmethod
    def _unsupported(reason: str) -> UnaryResult:
        return UnaryResult("UNSUPPORTED", 0, (), (), 0, reason)

    @staticmethod
    def _append_aor_child(
        children: list[dict[str, Any]],
        opcode: str,
        materialized: str,
        operand: int,
        result: aor.AorResult,
    ) -> None:
        children.append(
            _child_record(
                len(children),
                opcode,
                materialized,
                (operand,),
                aor.RawResult(result.raw, result.api_flags),
                result.trace,
            )
        )

    @staticmethod
    def _append_primitive_child(
        children: list[dict[str, Any]],
        opcode: str,
        materialized: str,
        lhs: int,
        rhs: int,
        result: aor.RawResult,
    ) -> None:
        children.append(
            _child_record(
                len(children),
                opcode,
                materialized,
                (lhs, rhs),
                result,
            )
        )

    @staticmethod
    def _complete(raw: int, children: list[dict[str, Any]]) -> UnaryResult:
        sticky: tuple[str, ...] = ()
        for child in children:
            sticky = merge_flags(sticky, child["flags"])
        return UnaryResult("OK", aor.u32(raw), sticky, tuple(children), 1, None)

    def evaluate(self, operation: str, src0_raw: int, src1_raw: int | None = None) -> UnaryResult:
        if type(operation) is not str or operation not in OPERATIONS:
            raise OracleError("OPERATION", "unsupported operation")
        src0 = _require_raw_int(src0_raw, "src0_raw")
        src0_value = aor.decode_f32(src0)
        if src0_value.kind not in ("zero", "finite"):
            return self._unsupported("NONFINITE_SRC0")

        src1: int | None = None
        if operation == "SWIGLU":
            src1 = _require_raw_int(src1_raw, "src1_raw")
            src1_value = aor.decode_f32(src1)
            if src1_value.kind not in ("zero", "finite"):
                return self._unsupported("NONFINITE_SRC1")
        elif src1_raw is not None:
            raise OracleError("UNUSED_SRC1", operation + " does not consume src1")

        if operation == "SOFTPLUS" and aor.compare_finite(src0_value, aor.decode_f32(TWENTY_RAW32)) > 0:
            return UnaryResult("OK", src0, (), (), 1, None)

        children: list[dict[str, Any]] = []
        try:
            if operation == "SOFTPLUS":
                exp_result = self.aor.exp32(src0)
                self._append_aor_child(children, "AOR_EXP32", "e", src0, exp_result)
                add_result = f32_add(ONE_RAW32, exp_result.raw)
                self._append_primitive_child(children, "FP32_ADD_RNE", "d", ONE_RAW32, exp_result.raw, add_result)
                log_result = self.aor.log32(add_result.raw)
                self._append_aor_child(children, "AOR_LOG32", "y", add_result.raw, log_result)
                return self._complete(log_result.raw, children)

            negative_local = src0 ^ SIGN_MASK32
            exp_result = self.aor.exp32(negative_local)
            self._append_aor_child(children, "AOR_EXP32", "e", negative_local, exp_result)
            add_result = f32_add(ONE_RAW32, exp_result.raw)
            self._append_primitive_child(children, "FP32_ADD_RNE", "d", ONE_RAW32, exp_result.raw, add_result)
            if operation == "SIGMOID":
                div_result = f32_div(ONE_RAW32, add_result.raw)
                self._append_primitive_child(children, "FP32_DIV_RNE", "y", ONE_RAW32, add_result.raw, div_result)
                return self._complete(div_result.raw, children)
            if operation == "SILU":
                div_result = f32_div(src0, add_result.raw)
                self._append_primitive_child(children, "FP32_DIV_RNE", "y", src0, add_result.raw, div_result)
                return self._complete(div_result.raw, children)
            if src1 is None:
                raise OracleError("SWIGLU_SRC1", "SWIGLU src1 was not materialized")
            div_result = f32_div(src0, add_result.raw)
            self._append_primitive_child(children, "FP32_DIV_RNE", "s", src0, add_result.raw, div_result)
            mul_result = f32_mul(div_result.raw, src1)
            self._append_primitive_child(children, "FP32_MUL_RNE", "y", div_result.raw, src1, mul_result)
            return self._complete(mul_result.raw, children)
        except aor.OracleError as error:
            raise OracleError("AOR_CHILD", str(error), error.flags) from error


def _frozen_manifest() -> dict[str, Any]:
    return {
        "aor_binding": {
            "generator_sha256": AOR_GENERATOR_SHA256,
            "manifest_canonical_sha256": AOR_MANIFEST_CANONICAL_SHA256,
            "profile": AOR_PROFILE,
            "vectors_sha256": AOR_VECTORS_SHA256,
        },
        "constants_raw32": {
            "canonical_internal_nan": "0x7fc00000",
            "one": "0x3f800000",
            "positive_infinity": "0x7f800000",
            "twenty": "0x41a00000",
        },
        "external_input_profile": {
            "nonfinite_action": "UNSUPPORTED_BEFORE_CHILD_ZERO_CHILD_ZERO_COMMIT",
            "sigmoid_consumed": ["src0_finite"],
            "silu_consumed": ["src0_finite"],
            "softplus_consumed": ["src0_finite"],
            "swiglu_consumed": ["src0_finite", "src1_finite"],
        },
        "flags_profile": {
            "bit_order": ["NV", "DZ", "OF", "UF", "NX"],
            "internal_infinity": "LEGAL_IEEE_DATA",
            "revision": FLAGS_PROFILE,
            "sticky_rule": "OR_EVERY_ACTUAL_CHILD_ONLY",
            "tininess": "AFTER_ROUNDING_TWO_STAGE_PRECISION_THEN_ENCODING",
        },
        "mutation_audit": {
            "definitions": [
                {
                    "id": "SILU_RECIPROCAL_MUL",
                    "mutant": "MUL32(src0,DIV32(ONE,d))",
                    "strict": "DIV32(src0,d)",
                },
                {
                    "id": "SWIGLU_NUMERATOR_FIRST",
                    "mutant": "DIV32(MUL32(src0,src1),d)",
                    "strict": "MUL32(DIV32(src0,d),src1)",
                },
                {
                    "id": "SWIGLU_ROLE_SWAP",
                    "mutant": "SWIGLU(src1,src0)",
                    "strict": "SWIGLU(src0,src1)",
                },
            ],
            "search_domains": {
                "inclusive_radius_raw": 2048,
                "ordering": "domain_list_then_unsigned_raw_then_gate_list",
                "role_pairs_raw32": [
                    ["0x3f800000", "0x40000000"],
                    ["0xbf800000", "0x40000000"],
                    ["0x40000000", "0x3f800000"],
                    ["0x00000001", "0x3f800000"],
                ],
                "silu_anchors_raw32": [
                    "0x00000001",
                    "0x00800000",
                    "0x3a800000",
                    "0x3e800000",
                    "0x3f000000",
                    "0x3f800000",
                    "0x40000000",
                    "0x41000000",
                    "0x41a00000",
                    "0x80000001",
                    "0x80800000",
                    "0xba800000",
                    "0xbe800000",
                    "0xbf000000",
                    "0xbf800000",
                    "0xc0000000",
                    "0xc1000000",
                    "0xc1a00000",
                ],
                "swiglu_gates_raw32": [
                    "0x3f800001",
                    "0x3f000000",
                    "0x40000000",
                    "0xbf800001",
                    "0xbf000000",
                    "0xc0000000",
                    "0x00000001",
                    "0x80000001",
                    "0x7f7fffff",
                    "0xff7fffff",
                ],
            },
        },
        "operations": {
            "SIGMOID": {
                "dag": [
                    "e=AOR_EXP32(NEG_LOCAL(src0))",
                    "d=FP32_ADD_RNE(ONE,e)",
                    "y=FP32_DIV_RNE(ONE,d)",
                ],
                "fast_path": None,
            },
            "SILU": {
                "dag": [
                    "e=AOR_EXP32(NEG_LOCAL(src0))",
                    "d=FP32_ADD_RNE(ONE,e)",
                    "y=FP32_DIV_RNE(src0,d)",
                ],
                "fast_path": None,
            },
            "SOFTPLUS": {
                "dag": [
                    "e=AOR_EXP32(src0)",
                    "d=FP32_ADD_RNE(ONE,e)",
                    "y=AOR_LOG32(d)",
                ],
                "fast_path": "ordered_finite_src0_strict_gt_TWENTY_raw_bitcopy_zero_child",
            },
            "SWIGLU": {
                "dag": [
                    "e=AOR_EXP32(NEG_LOCAL(src0))",
                    "d=FP32_ADD_RNE(ONE,e)",
                    "s=FP32_DIV_RNE(src0,d)",
                    "y=FP32_MUL_RNE(s,src1)",
                ],
                "fast_path": None,
            },
        },
        "primitive_contract": {
            "add": "EXACT_SIGNED_DYADIC_SINGLE_RNE_PACK",
            "division": "EXACT_INTEGER_RATIONAL_SINGLE_RNE_PACK",
            "host_real_arithmetic": "FORBIDDEN",
            "multiply": "EXACT_DYADIC_PRODUCT_SINGLE_RNE_PACK",
            "rounding": "RNE",
            "tininess_after": "UNBOUNDED_PRECISION_ROUND_THEN_DIRECT_FINAL_ENCODING_ROUND",
        },
        "profile": PROFILE,
        "schema": MANIFEST_SCHEMA,
        "status": "QUALIFIED_FINITE_EXTERNAL_INPUTS",
    }


def _duplicate_checked_object(pairs: list[tuple[str, Any]]) -> dict[str, Any]:
    result: dict[str, Any] = {}
    for key, value in pairs:
        if key in result:
            raise ManifestError("DUPLICATE_JSON_KEY", "duplicate JSON key: " + key)
        result[key] = value
    return result


def _reject_json_real(text: str) -> Any:
    raise ManifestError("JSON_REAL_NUMBER", "JSON real number is forbidden: " + text)


def _reject_json_constant(text: str) -> Any:
    raise ManifestError("JSON_NONFINITE_NUMBER", "JSON non-finite number is forbidden: " + text)


def _strict_json_bytes(data: bytes, read_code: str, json_code: str) -> Any:
    try:
        text = data.decode("utf-8")
    except UnicodeError as error:
        raise OracleError(read_code, str(error)) from error
    try:
        return json.loads(
            text,
            object_pairs_hook=_duplicate_checked_object,
            parse_float=_reject_json_real,
            parse_constant=_reject_json_constant,
        )
    except OracleError:
        raise
    except (json.JSONDecodeError, UnicodeError) as error:
        raise OracleError(json_code, str(error)) from error


def _schema_object(value: Any, path: str, keys: Iterable[str]) -> dict[str, Any]:
    if type(value) is not dict:
        raise OracleError("SCHEMA_OBJECT", path + " must be an object")
    expected = set(keys)
    if set(value) != expected:
        raise OracleError("SCHEMA_KEYS", path + " has missing or unknown fields")
    return value


def _schema_array(value: Any, path: str, length: int | None = None) -> list[Any]:
    if type(value) is not list:
        raise OracleError("SCHEMA_ARRAY", path + " must be an array")
    if length is not None and len(value) != length:
        raise OracleError("SCHEMA_ARRAY_LENGTH", path + " has the wrong length")
    return value


def _schema_string(value: Any, path: str) -> str:
    if type(value) is not str:
        raise OracleError("SCHEMA_STRING", path + " must be a string")
    return value


def _schema_int(value: Any, path: str) -> int:
    if type(value) is not int:
        raise OracleError("SCHEMA_INTEGER", path + " must be an integer and not a boolean")
    return value


def _schema_null_or_string(value: Any, path: str) -> str | None:
    if value is None:
        return None
    return _schema_string(value, path)


def _schema_flags(value: Any, path: str) -> list[str]:
    array = _schema_array(value, path)
    flags = [_schema_string(item, path + "[" + str(index) + "]") for index, item in enumerate(array)]
    if flags != list(ordered_flags(flags)):
        raise OracleError("SCHEMA_FLAGS", path + " flags are duplicated or out of order")
    return flags


def _verify_aor_binding() -> None:
    try:
        observed_generator = aor.generator_sha256()
        aor_manifest = aor.load_manifest(AOR_MANIFEST_PATH)
        observed_manifest = aor.validate_manifest(aor_manifest)
        observed_vectors = sha256_bytes(AOR_VECTORS_PATH.read_bytes())
    except (aor.OracleError, OSError, UnicodeError) as error:
        raise OracleError("AOR_BINDING_READ", str(error)) from error
    if observed_generator != AOR_GENERATOR_SHA256:
        raise OracleError("AOR_GENERATOR_IDENTITY", "bound AOR generator SHA changed")
    if observed_manifest != AOR_MANIFEST_CANONICAL_SHA256:
        raise OracleError("AOR_MANIFEST_IDENTITY", "bound AOR manifest canonical SHA changed")
    if observed_vectors != AOR_VECTORS_SHA256:
        raise OracleError("AOR_VECTOR_IDENTITY", "bound AOR vectors SHA changed")


def validate_manifest(manifest: Any) -> str:
    if type(manifest) is not dict:
        raise ManifestError("MANIFEST_ROOT", "manifest root must be an object")
    expected = _frozen_manifest()
    if manifest != expected:
        raise ManifestError("MANIFEST_FROZEN_MISMATCH", "manifest differs from the frozen profile")
    digest = sha256_bytes(canonical_bytes(manifest))
    if digest != EXPECTED_MANIFEST_SHA256:
        raise ManifestError("MANIFEST_SHA256", "manifest canonical SHA is not the frozen identity")
    _verify_aor_binding()
    return digest


def load_manifest(path: Path) -> dict[str, Any]:
    try:
        data = path.read_bytes()
    except OSError as error:
        raise ManifestError("MANIFEST_READ", str(error)) from error
    value = _strict_json_bytes(data, "MANIFEST_UTF8", "MANIFEST_JSON")
    if type(value) is not dict:
        raise ManifestError("MANIFEST_ROOT", "manifest root must be an object")
    validate_manifest(value)
    return value


def check_integer_only_source(
    source: str,
    filename: str = "<source>",
    require_complete_imports: bool = False,
) -> None:
    """Apply a closed syntax/import/attribute/call-origin capability policy."""

    if type(source) is not str or type(filename) is not str or type(require_complete_imports) is not bool:
        raise OracleError("INTEGER_ONLY_CHECKER_INPUT", "checker arguments have invalid types")
    try:
        tree = ast.parse(source, filename=filename)
    except SyntaxError as error:
        raise OracleError("INTEGER_ONLY_SYNTAX", "source does not parse") from error
    seen_imports: set[tuple[str, str, str | None, str | None]] = set()
    controlled_json_keywords = {
        "object_pairs_hook": "_duplicate_checked_object",
        "parse_float": "_reject_json_real",
        "parse_constant": "_reject_json_constant",
    }
    parents = {child: parent for parent in ast.walk(tree) for child in ast.iter_child_nodes(parent)}

    def allowed_module_callable_reference(attribute: ast.Attribute) -> bool:
        """Permit a module callable only in an exact non-capturing type context."""

        cursor: ast.AST = attribute
        while cursor in parents:
            parent = parents[cursor]
            if isinstance(parent, ast.Call):
                if parent.func is cursor:
                    return True
                return (
                    isinstance(parent.func, ast.Name)
                    and parent.func.id == "isinstance"
                    and len(parent.args) == 2
                    and cursor is parent.args[1]
                )
            if isinstance(parent, ast.arg) and parent.annotation is cursor:
                return True
            if isinstance(parent, ast.AnnAssign) and parent.annotation is cursor:
                return True
            if isinstance(parent, ast.FunctionDef) and parent.returns is cursor:
                return True
            if isinstance(parent, ast.ExceptHandler) and parent.type is cursor:
                return True
            if isinstance(parent, (ast.Tuple, ast.Subscript, ast.BinOp)):
                cursor = parent
                continue
            return False
        return False

    defined_callables: set[str] = set()
    for definition in ast.walk(tree):
        if isinstance(definition, (ast.FunctionDef, ast.ClassDef)):
            defined_callables.add(definition.name)

    for node in ast.walk(tree):
        node_kind = type(node).__name__
        if node_kind not in AST_NODE_CAPABILITIES:
            raise OracleError("INTEGER_ONLY_SYNTAX_CAPABILITY", "syntax capability is not allowlisted: " + node_kind)
        if isinstance(node, ast.Import):
            for alias in node.names:
                identity = ("import", alias.name, None, alias.asname)
                if identity not in PRODUCTION_IMPORT_ALLOWLIST:
                    raise OracleError("INTEGER_ONLY_IMPORT", "import is outside the exact allowlist")
                seen_imports.add(identity)
        elif isinstance(node, ast.ImportFrom):
            if node.level != 0 or node.module is None:
                raise OracleError("INTEGER_ONLY_IMPORT", "relative or incomplete import is forbidden")
            for alias in node.names:
                identity = ("from", node.module, alias.name, alias.asname)
                if identity not in PRODUCTION_IMPORT_ALLOWLIST:
                    raise OracleError("INTEGER_ONLY_IMPORT", "from-import is outside the exact allowlist")
                seen_imports.add(identity)
        elif isinstance(node, ast.ClassDef):
            for base in node.bases:
                if not isinstance(base, ast.Name) or base.id not in ("OracleError", "RuntimeError"):
                    raise OracleError("INTEGER_ONLY_CLASS_BASE", "class base is outside the capability policy")
            for decorator in node.decorator_list:
                if (
                    not isinstance(decorator, ast.Call)
                    or not isinstance(decorator.func, ast.Name)
                    or decorator.func.id != "dataclass"
                ):
                    raise OracleError("INTEGER_ONLY_CLASS_DECORATOR", "class decorator is outside the capability policy")
        elif isinstance(node, ast.FunctionDef):
            for decorator in node.decorator_list:
                if not isinstance(decorator, ast.Name) or decorator.id not in ("classmethod", "staticmethod"):
                    raise OracleError("INTEGER_ONLY_FUNCTION_DECORATOR", "function decorator is outside the capability policy")
        elif isinstance(node, ast.Name):
            if node.id in ("float", "complex"):
                raise OracleError("INTEGER_ONLY_HOST_REAL_NAME", "host-real scalar name is forbidden")
            if node.id.startswith("__") and node.id not in ("__file__", "__name__"):
                raise OracleError("INTEGER_ONLY_NAME_CAPABILITY", "dunder name is outside the capability policy")
            if node.id in MODULE_ATTRIBUTE_CAPABILITIES:
                parent = parents.get(node)
                if not isinstance(parent, ast.Attribute) or parent.value is not node:
                    raise OracleError("INTEGER_ONLY_MODULE_ALIAS", "module namespace cannot be captured or aliased")
        elif isinstance(node, ast.Attribute):
            module_name = node.value.id if isinstance(node.value, ast.Name) else None
            if module_name in MODULE_ATTRIBUTE_CAPABILITIES:
                if node.attr not in MODULE_ATTRIBUTE_CAPABILITIES[module_name]:
                    raise OracleError(
                        "INTEGER_ONLY_MODULE_ATTRIBUTE",
                        "module attribute is outside the capability policy: " + module_name + "." + node.attr,
                    )
                parent = parents.get(node)
                if node.attr in MODULE_CALL_CAPABILITIES[module_name] and not allowed_module_callable_reference(node):
                    raise OracleError("INTEGER_ONLY_MODULE_CALL_ALIAS", "module callable cannot be captured or aliased")
            elif node.attr == "__init__":
                if not (
                    isinstance(node.value, ast.Call)
                    and isinstance(node.value.func, ast.Name)
                    and node.value.func.id == "super"
                ):
                    raise OracleError("INTEGER_ONLY_ATTRIBUTE_CAPABILITY", "__init__ access is not a super call")
            elif node.attr == "__name__":
                if not (
                    isinstance(node.value, ast.Call)
                    and isinstance(node.value.func, ast.Name)
                    and node.value.func.id == "type"
                ):
                    raise OracleError("INTEGER_ONLY_ATTRIBUTE_CAPABILITY", "__name__ access is not a type query")
            elif node.attr not in OBJECT_ATTRIBUTE_CAPABILITIES:
                raise OracleError(
                    "INTEGER_ONLY_ATTRIBUTE_CAPABILITY",
                    "object attribute is outside the capability policy: " + node.attr,
                )
        elif isinstance(node, ast.Constant):
            if type(node.value) not in (str, int, bool, bytes, type(None), type(Ellipsis)):
                raise OracleError(
                    "INTEGER_ONLY_LITERAL_CAPABILITY",
                    "literal type is outside the capability policy: " + type(node.value).__name__,
                )
        elif isinstance(node, ast.Call):
            if isinstance(node.func, ast.Name):
                if node.func.id not in NAME_CALL_CAPABILITIES and node.func.id not in defined_callables:
                    raise OracleError(
                        "INTEGER_ONLY_CALL_ORIGIN",
                        "name call origin is outside the capability policy: " + node.func.id,
                    )
            elif isinstance(node.func, ast.Attribute):
                call_module = node.func.value.id if isinstance(node.func.value, ast.Name) else None
                if call_module in MODULE_CALL_CAPABILITIES:
                    if node.func.attr not in MODULE_CALL_CAPABILITIES[call_module]:
                        raise OracleError("INTEGER_ONLY_CALL_ORIGIN", "module call origin is outside the capability policy")
                elif node.func.attr == "__init__":
                    if not (
                        isinstance(node.func.value, ast.Call)
                        and isinstance(node.func.value.func, ast.Name)
                        and node.func.value.func.id == "super"
                    ):
                        raise OracleError("INTEGER_ONLY_CALL_ORIGIN", "__init__ call origin is outside the capability policy")
                elif node.func.attr not in OBJECT_CALL_CAPABILITIES:
                    raise OracleError("INTEGER_ONLY_CALL_ORIGIN", "object call origin is outside the capability policy")
            else:
                raise OracleError("INTEGER_ONLY_CALL_ORIGIN", "computed call origin is outside the capability policy")

            is_json_loads = (
                isinstance(node.func, ast.Attribute)
                and node.func.attr == "loads"
                and isinstance(node.func.value, ast.Name)
                and node.func.value.id == "json"
            )
            if is_json_loads:
                if len(node.args) != 1 or any(keyword.arg is None for keyword in node.keywords):
                    raise OracleError("INTEGER_ONLY_JSON", "json.loads call shape is not controlled")
                keywords = {keyword.arg: keyword.value for keyword in node.keywords}
                if set(keywords) != set(controlled_json_keywords):
                    raise OracleError("INTEGER_ONLY_JSON", "json.loads must install all fail-closed hooks")
                for keyword, expected_name in controlled_json_keywords.items():
                    value = keywords[keyword]
                    if not isinstance(value, ast.Name) or value.id != expected_name:
                        raise OracleError("INTEGER_ONLY_JSON", "json.loads hook identity changed")

    if require_complete_imports and seen_imports != PRODUCTION_IMPORT_ALLOWLIST:
        raise OracleError("INTEGER_ONLY_IMPORT_SET", "production import set is incomplete or changed")


def enforce_production_source_gate() -> None:
    try:
        source = SCRIPT_PATH.read_text(encoding="utf-8")
    except (OSError, UnicodeError) as error:
        raise OracleError("INTEGER_ONLY_SOURCE_READ", str(error)) from error
    check_integer_only_source(source, filename=str(SCRIPT_PATH), require_complete_imports=True)


def _child_by_materialized(result: UnaryResult, name: str) -> dict[str, Any]:
    matches = [child for child in result.children if child["materialized"] == name]
    if len(matches) != 1:
        raise OracleError("MUTATION_TRACE", "strict trace does not contain exactly one " + name)
    return matches[0]


def _raw_from_child(result: UnaryResult, name: str) -> int:
    return parse_raw32(_schema_string(_child_by_materialized(result, name)["result_raw32"], name + ".raw"))


def _prefix_flags(result: UnaryResult, child_count: int) -> tuple[str, ...]:
    if child_count < 0 or child_count > len(result.children):
        raise OracleError("MUTATION_TRACE", "invalid prefix child count")
    accumulated: tuple[str, ...] = ()
    for child in result.children[:child_count]:
        accumulated = merge_flags(accumulated, child["flags"])
    return accumulated


def _mutation_differences(
    strict_raw: int,
    strict_flags: Iterable[str],
    mutant_raw: int,
    mutant_flags: Iterable[str],
) -> list[str]:
    differences: list[str] = []
    if aor.u32(strict_raw) != aor.u32(mutant_raw):
        differences.append("final_raw32")
    if list(ordered_flags(strict_flags)) != list(ordered_flags(mutant_flags)):
        differences.append("sticky_flags")
    return differences


def silu_reciprocal_mutation_probe(
    oracle: TensorUnaryGluOracle,
    input_raw: int,
) -> dict[str, Any] | None:
    strict = oracle.evaluate("SILU", input_raw)
    if strict.status != "OK" or len(strict.children) != 3:
        return None
    d_raw = _raw_from_child(strict, "d")
    reciprocal = f32_div(ONE_RAW32, d_raw)
    mutant = f32_mul(aor.u32(input_raw), reciprocal.raw)
    mutant_flags = merge_flags(_prefix_flags(strict, 2), reciprocal.flags, mutant.flags)
    differences = _mutation_differences(strict.raw, strict.flags, mutant.raw, mutant_flags)
    if not differences:
        return None
    return {
        "difference_fields": differences,
        "input_raw32": raw_text(input_raw),
        "mutation_id": "SILU_RECIPROCAL_MUL",
        "mutant_child_count": 4,
        "mutant_child_opcodes": ["AOR_EXP32", "FP32_ADD_RNE", "FP32_DIV_RNE", "FP32_MUL_RNE"],
        "mutant_final_raw32": raw_text(mutant.raw),
        "mutant_mul_flags": list(mutant.flags),
        "mutant_reciprocal_flags": list(reciprocal.flags),
        "mutant_reciprocal_raw32": raw_text(reciprocal.raw),
        "mutant_sticky_flags": list(mutant_flags),
        "strict_child_count": len(strict.children),
        "strict_child_opcodes": [child["opcode"] for child in strict.children],
        "strict_d_raw32": raw_text(d_raw),
        "strict_div_flags": list(_child_by_materialized(strict, "y")["flags"]),
        "strict_final_raw32": raw_text(strict.raw),
        "strict_sticky_flags": list(strict.flags),
    }


def swiglu_numerator_first_mutation_probe(
    oracle: TensorUnaryGluOracle,
    src0_raw: int,
    src1_raw: int,
) -> dict[str, Any] | None:
    strict = oracle.evaluate("SWIGLU", src0_raw, src1_raw)
    if strict.status != "OK" or len(strict.children) != 4:
        return None
    d_raw = _raw_from_child(strict, "d")
    s_raw = _raw_from_child(strict, "s")
    numerator = f32_mul(aor.u32(src0_raw), aor.u32(src1_raw))
    mutant = f32_div(numerator.raw, d_raw)
    mutant_flags = merge_flags(_prefix_flags(strict, 2), numerator.flags, mutant.flags)
    differences = _mutation_differences(strict.raw, strict.flags, mutant.raw, mutant_flags)
    if not differences:
        return None
    return {
        "difference_fields": differences,
        "mutation_id": "SWIGLU_NUMERATOR_FIRST",
        "mutant_child_count": 4,
        "mutant_child_opcodes": ["AOR_EXP32", "FP32_ADD_RNE", "FP32_MUL_RNE", "FP32_DIV_RNE"],
        "mutant_div_flags": list(mutant.flags),
        "mutant_final_raw32": raw_text(mutant.raw),
        "mutant_numerator_flags": list(numerator.flags),
        "mutant_numerator_raw32": raw_text(numerator.raw),
        "mutant_sticky_flags": list(mutant_flags),
        "src0_raw32": raw_text(src0_raw),
        "src1_raw32": raw_text(src1_raw),
        "strict_child_count": len(strict.children),
        "strict_child_opcodes": [child["opcode"] for child in strict.children],
        "strict_d_raw32": raw_text(d_raw),
        "strict_div_flags": list(_child_by_materialized(strict, "s")["flags"]),
        "strict_final_raw32": raw_text(strict.raw),
        "strict_mul_flags": list(_child_by_materialized(strict, "y")["flags"]),
        "strict_s_raw32": raw_text(s_raw),
        "strict_sticky_flags": list(strict.flags),
    }


def swiglu_role_swap_mutation_probe(
    oracle: TensorUnaryGluOracle,
    src0_raw: int,
    src1_raw: int,
) -> dict[str, Any] | None:
    strict = oracle.evaluate("SWIGLU", src0_raw, src1_raw)
    mutant = oracle.evaluate("SWIGLU", src1_raw, src0_raw)
    if strict.status != "OK" or mutant.status != "OK":
        return None
    differences = _mutation_differences(strict.raw, strict.flags, mutant.raw, mutant.flags)
    if not differences:
        return None
    return {
        "difference_fields": differences,
        "mutation_id": "SWIGLU_ROLE_SWAP",
        "mutant_child_count": len(mutant.children),
        "mutant_child_flags": [child["flags"] for child in mutant.children],
        "mutant_child_opcodes": [child["opcode"] for child in mutant.children],
        "mutant_child_raw32": [child["result_raw32"] for child in mutant.children],
        "mutant_final_raw32": raw_text(mutant.raw),
        "mutant_sticky_flags": list(mutant.flags),
        "src0_raw32": raw_text(src0_raw),
        "src0_role": "NONLINEAR_GATE",
        "src1_raw32": raw_text(src1_raw),
        "src1_role": "LINEAR_UP",
        "strict_child_count": len(strict.children),
        "strict_child_flags": [child["flags"] for child in strict.children],
        "strict_child_opcodes": [child["opcode"] for child in strict.children],
        "strict_child_raw32": [child["result_raw32"] for child in strict.children],
        "strict_final_raw32": raw_text(strict.raw),
        "strict_sticky_flags": list(strict.flags),
    }


def _silu_search_candidates(manifest: dict[str, Any]) -> list[int]:
    domain = manifest["mutation_audit"]["search_domains"]
    radius = _schema_int(domain["inclusive_radius_raw"], "search.radius")
    anchors = _schema_array(domain["silu_anchors_raw32"], "search.anchors")
    candidates: list[int] = []
    seen: set[int] = set()
    for anchor_text in anchors:
        anchor = parse_raw32(_schema_string(anchor_text, "search.anchor"))
        lower = max(0, anchor - radius)
        upper = min((1 << 32) - 1, anchor + radius)
        for raw in range(lower, upper + 1):
            if raw in seen:
                continue
            seen.add(raw)
            value = aor.decode_f32(raw)
            if value.kind in ("zero", "finite"):
                candidates.append(raw)
    return candidates


def audit_mutations(oracle: TensorUnaryGluOracle) -> dict[str, Any]:
    if not isinstance(oracle, TensorUnaryGluOracle):
        raise OracleError("MUTATION_INTERNAL", "mutation audit requires a TensorUnaryGluOracle")
    frozen = _frozen_manifest()
    candidates = _silu_search_candidates(frozen)
    outcomes: list[dict[str, Any]] = []

    silu_witness: dict[str, Any] | None = None
    silu_examined = 0
    silu_eligible = 0
    for raw in candidates:
        silu_examined += 1
        silu_eligible += 1
        silu_witness = silu_reciprocal_mutation_probe(oracle, raw)
        if silu_witness is not None:
            break
    outcomes.append(
        {
            "candidates_examined": silu_examined,
            "eligible_candidates": silu_eligible,
            "mutation_id": "SILU_RECIPROCAL_MUL",
            "status": "WITNESS" if silu_witness is not None else "GAP_NO_WITNESS_IN_BOUNDED_DOMAIN",
            "witness": silu_witness,
        }
    )

    gates = [
        parse_raw32(_schema_string(value, "search.gate"))
        for value in _schema_array(
            frozen["mutation_audit"]["search_domains"]["swiglu_gates_raw32"],
            "search.gates",
        )
    ]
    swiglu_witness: dict[str, Any] | None = None
    swiglu_examined = 0
    swiglu_eligible = 0
    for raw in candidates:
        if swiglu_witness is not None:
            break
        for gate in gates:
            swiglu_examined += 1
            swiglu_eligible += 1
            swiglu_witness = swiglu_numerator_first_mutation_probe(oracle, raw, gate)
            if swiglu_witness is not None:
                break
    outcomes.append(
        {
            "candidates_examined": swiglu_examined,
            "eligible_candidates": swiglu_eligible,
            "mutation_id": "SWIGLU_NUMERATOR_FIRST",
            "status": "WITNESS" if swiglu_witness is not None else "GAP_NO_WITNESS_IN_BOUNDED_DOMAIN",
            "witness": swiglu_witness,
        }
    )

    pairs = _schema_array(
        frozen["mutation_audit"]["search_domains"]["role_pairs_raw32"],
        "search.role_pairs",
    )
    role_witness: dict[str, Any] | None = None
    role_examined = 0
    role_eligible = 0
    for pair_index, pair_value in enumerate(pairs):
        pair = _schema_array(pair_value, "search.role_pairs[" + str(pair_index) + "]", 2)
        src0 = parse_raw32(_schema_string(pair[0], "search.role.src0"))
        src1 = parse_raw32(_schema_string(pair[1], "search.role.src1"))
        role_examined += 1
        role_eligible += 1
        role_witness = swiglu_role_swap_mutation_probe(oracle, src0, src1)
        if role_witness is not None:
            break
    outcomes.append(
        {
            "candidates_examined": role_examined,
            "eligible_candidates": role_eligible,
            "mutation_id": "SWIGLU_ROLE_SWAP",
            "status": "WITNESS" if role_witness is not None else "GAP_NO_WITNESS_IN_BOUNDED_DOMAIN",
            "witness": role_witness,
        }
    )

    witness_count = sum(1 for outcome in outcomes if outcome["status"] == "WITNESS")
    return {
        "gap_count": len(outcomes) - witness_count,
        "generator_sha256": generator_sha256(),
        "manifest_canonical_sha256": oracle.manifest_sha256,
        "outcomes": outcomes,
        "profile": PROFILE,
        "schema": MUTATION_SCHEMA,
        "search_domain": frozen["mutation_audit"]["search_domains"],
        "search_domain_role_pair_count": len(pairs),
        "search_domain_swiglu_pair_count": len(candidates) * len(gates),
        "search_domain_unique_finite_candidates": len(candidates),
        "witness_count": witness_count,
    }


def _qualified_recipes() -> list[dict[str, Any]]:
    recipes: list[dict[str, Any]] = []

    def add(case_id: str, operation: str, src0: int, src1: int | None, recipe: str) -> None:
        recipes.append(
            {
                "case_id": case_id,
                "operation": operation,
                "recipe": recipe,
                "src0_raw32": src0,
                "src1_raw32": src1,
            }
        )

    for operation, positive, negative in (
        ("SIGMOID", 0x3F800000, 0xBF800000),
        ("SOFTPLUS", 0x3F800000, 0xBF800000),
        ("SILU", 0x3F800000, 0xBF800000),
    ):
        prefix = operation.lower()
        add(prefix + "-ordinary-positive", operation, positive, None, "ordinary positive finite src0")
        add(prefix + "-ordinary-negative", operation, negative, None, "ordinary negative finite src0")
        add(prefix + "-positive-zero", operation, 0x00000000, None, "positive zero src0")
        add(prefix + "-negative-zero", operation, 0x80000000, None, "negative zero src0")

    add("sigmoid-negative-100-internal-inf", "SIGMOID", 0xC2C80000, None, "EXP overflows internally; final positive zero is legal")
    add("silu-negative-100-internal-inf", "SILU", 0xC2C80000, None, "EXP overflows internally; final negative zero is legal")
    add("sigmoid-positive-minsub", "SIGMOID", 0x00000001, None, "positive minimum subnormal src0")
    add("sigmoid-negative-minsub", "SIGMOID", 0x80000001, None, "negative minimum subnormal src0")
    add("softplus-positive-minsub", "SOFTPLUS", 0x00000001, None, "positive minimum subnormal src0")
    add("softplus-negative-minsub", "SOFTPLUS", 0x80000001, None, "negative minimum subnormal src0")
    add("silu-positive-minsub", "SILU", 0x00000001, None, "positive minimum subnormal src0")
    add("silu-negative-minsub", "SILU", 0x80000001, None, "negative minimum subnormal src0")
    add("mutation-silu-reciprocal-mul-first-witness", "SILU", 0x3A7FF807, None, "bounded first witness for direct DIV versus reciprocal then MUL")

    add("softplus-below-twenty", "SOFTPLUS", 0x419FFFFF, None, "strict threshold predecessor takes three-child slow path")
    add("softplus-equal-twenty", "SOFTPLUS", 0x41A00000, None, "strict equality takes three-child slow path")
    add("softplus-above-twenty", "SOFTPLUS", 0x41A00001, None, "strict successor takes zero-child raw-bitcopy path")
    add("softplus-negative-twenty", "SOFTPLUS", 0xC1A00000, None, "negative twenty takes three-child slow path")

    add("swiglu-ordinary-positive", "SWIGLU", 0x3F800000, 0x40000000, "positive src0 and positive src1")
    add("swiglu-ordinary-negative", "SWIGLU", 0xBF800000, 0x40000000, "negative src0 and positive src1")
    add("swiglu-positive-zero", "SWIGLU", 0x00000000, 0x3F800000, "positive zero src0 is materialized before multiply")
    add("swiglu-negative-zero", "SWIGLU", 0x80000000, 0x3F800000, "negative zero src0 is materialized before multiply")
    add("swiglu-zero-negative-gate", "SWIGLU", 0x00000000, 0xBF800000, "final multiply flips materialized positive zero sign")
    add("swiglu-role-a", "SWIGLU", 0x3F800000, 0x40000000, "role witness strict order src0 one src1 two")
    add("swiglu-role-b", "SWIGLU", 0x40000000, 0x3F800000, "role witness swapped external operands")
    add("swiglu-positive-minsub-src0", "SWIGLU", 0x00000001, 0x3F800000, "minimum subnormal in nonlinear src0 role")
    add("mutation-swiglu-numerator-first-witness", "SWIGLU", 0x00000001, 0x40000000, "bounded first witness for materialized DIV then MUL versus numerator-first DIV")
    add("swiglu-negative-minsub-src0", "SWIGLU", 0x80000001, 0x3F800000, "negative minimum subnormal in nonlinear src0 role")
    add("swiglu-positive-minsub-src1", "SWIGLU", 0x3F800000, 0x00000001, "minimum subnormal in linear src1 role")
    add("swiglu-finite-overflow-positive", "SWIGLU", 0x7F7FFFFF, 0x40000000, "finite inputs produce legal positive infinity with sticky flags")
    add("swiglu-finite-overflow-negative", "SWIGLU", 0x7F7FFFFF, 0xC0000000, "finite positive nonlinear input and negative linear gate produce legal negative infinity")

    specials = (
        ("positive-infinity", 0x7F800000),
        ("negative-infinity", 0xFF800000),
        ("quiet-nan", 0x7FC12345),
        ("signaling-nan", 0x7F800001),
    )
    for operation in OPERATIONS:
        for name, raw in specials:
            add(
                "reject-" + operation.lower() + "-src0-" + name,
                operation,
                raw,
                0x3F800000 if operation == "SWIGLU" else None,
                "nonfinite consumed src0 rejects before every child",
            )
    for name, raw in specials:
        add(
            "reject-swiglu-src1-" + name,
            "SWIGLU",
            0x3F800000,
            raw,
            "nonfinite consumed src1 rejects before every child",
        )
    add(
        "primitive-mul-minnormal-roundup-tiny-positive",
        "MUL32_RNE",
        0x00800000,
        0x3F7FFFFF,
        "fixed-commit fpu-sp differential: final minnormal still UF and NX",
    )
    add(
        "primitive-mul-minnormal-roundup-tiny-negative",
        "MUL32_RNE",
        0x80800000,
        0x3F7FFFFF,
        "negative mirror of fixed-commit fpu-sp tininess-after differential",
    )
    return recipes


def _vector_case(oracle: TensorUnaryGluOracle, recipe: dict[str, Any]) -> dict[str, Any]:
    operation = _schema_string(recipe["operation"], "recipe.operation")
    src0 = _schema_int(recipe["src0_raw32"], "recipe.src0")
    src1_value = recipe["src1_raw32"]
    if src1_value is not None:
        src1 = _schema_int(src1_value, "recipe.src1")
    else:
        src1 = None
    if operation == "MUL32_RNE":
        if src1 is None:
            raise OracleError("VECTOR_PRIMITIVE_OPERAND", "MUL32_RNE vector lacks rhs")
        primitive = f32_mul(src0, src1)
        child = _child_record(0, "FP32_MUL_RNE", "y", (src0, src1), primitive)
        result = UnaryResult("OK", primitive.raw, primitive.flags, (child,), 1, None)
    else:
        result = oracle.evaluate(operation, src0, src1)
    return {
        "case_id": _schema_string(recipe["case_id"], "recipe.case_id"),
        "child_count": len(result.children),
        "children": list(result.children),
        "commit_count": result.commit_count,
        "expected_error": 0 if result.status == "OK" else 1,
        "expected_raw32": raw_text(result.raw),
        "expected_status": result.status,
        "operation": operation,
        "reason": result.reason,
        "recipe": _schema_string(recipe["recipe"], "recipe.recipe"),
        "src0_raw32": raw_text(src0),
        "src1_raw32": None if src1 is None else raw_text(src1),
        "sticky_flags": list(result.flags),
    }


def build_vector_records(oracle: TensorUnaryGluOracle) -> list[dict[str, Any]]:
    cases = [_vector_case(oracle, recipe) for recipe in _qualified_recipes()]
    metadata = {
        "aor_binding": {
            "generator_sha256": AOR_GENERATOR_SHA256,
            "manifest_canonical_sha256": AOR_MANIFEST_CANONICAL_SHA256,
            "vectors_sha256": AOR_VECTORS_SHA256,
        },
        "generator_sha256": generator_sha256(),
        "manifest_canonical_sha256": oracle.manifest_sha256,
        "profile": PROFILE,
        "record_kind": "metadata",
        "schema": VECTOR_SCHEMA,
        "vector_count": len(cases),
    }
    return [metadata, *cases]


def _vector_payload(records: Sequence[dict[str, Any]]) -> bytes:
    return b"\n".join(canonical_bytes(record) for record in records) + b"\n"


def _is_owned_output(path: Path) -> bool:
    resolved = path.resolve()
    if resolved == DEFAULT_VECTORS.resolve():
        return True
    for root in (TMP_BUILD.resolve(), TMP_LOGS.resolve()):
        try:
            resolved.relative_to(root)
            return True
        except ValueError:
            pass
    return False


def _require_owned_output(path: Path) -> Path:
    resolved = path.resolve()
    if not _is_owned_output(resolved):
        raise OracleError("OUTPUT_SCOPE", "output path is outside unary-glu oracle ownership")
    return resolved


def emit_vectors(output: Path, oracle: TensorUnaryGluOracle) -> tuple[int, str]:
    target = _require_owned_output(output)
    records = build_vector_records(oracle)
    payload = _vector_payload(records)
    try:
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_bytes(payload)
    except OSError as error:
        raise OracleError("VECTOR_WRITE", str(error)) from error
    return len(records) - 1, sha256_bytes(payload)


def _load_jsonl(path: Path) -> tuple[list[dict[str, Any]], bytes]:
    try:
        data = path.read_bytes()
    except OSError as error:
        raise OracleError("VECTOR_READ", str(error)) from error
    try:
        text = data.decode("utf-8")
    except UnicodeError as error:
        raise OracleError("VECTOR_UTF8", str(error)) from error
    if not data.endswith(b"\n"):
        raise OracleError("VECTOR_FINAL_NEWLINE", "vector JSONL must end with one newline")
    lines = text.splitlines()
    if not lines or any(line == "" for line in lines):
        raise OracleError("VECTOR_LINES", "vector JSONL contains no records or a blank record")
    records: list[dict[str, Any]] = []
    for index, line in enumerate(lines):
        value = _strict_json_bytes(line.encode("utf-8"), "VECTOR_UTF8", "VECTOR_JSON")
        if type(value) is not dict:
            raise OracleError("VECTOR_ROOT", "vector line " + str(index) + " must be an object")
        records.append(value)
    return records, data


def _validate_child_schema(value: Any, path: str, expected_index: int) -> dict[str, Any]:
    child = _schema_object(
        value,
        path,
        (
            "child_index",
            "detail_trace_sha256",
            "flags",
            "materialized",
            "opcode",
            "operands_raw32",
            "result_raw32",
        ),
    )
    if _schema_int(child["child_index"], path + ".child_index") != expected_index:
        raise OracleError("VECTOR_CHILD_INDEX", path + " index is not contiguous")
    detail = _schema_null_or_string(child["detail_trace_sha256"], path + ".detail_trace_sha256")
    if detail is not None and (len(detail) != 64 or any(ch not in "0123456789abcdef" for ch in detail)):
        raise OracleError("SCHEMA_SHA256", path + ".detail_trace_sha256 is invalid")
    _schema_flags(child["flags"], path + ".flags")
    _schema_string(child["materialized"], path + ".materialized")
    _schema_string(child["opcode"], path + ".opcode")
    operands = _schema_array(child["operands_raw32"], path + ".operands_raw32")
    if len(operands) not in (1, 2):
        raise OracleError("VECTOR_OPERANDS", path + " has wrong operand count")
    for operand_index, operand in enumerate(operands):
        parse_raw32(_schema_string(operand, path + ".operands[" + str(operand_index) + "]"))
    parse_raw32(_schema_string(child["result_raw32"], path + ".result_raw32"))
    return child


def _validate_vector_schema(records: Any) -> list[dict[str, Any]]:
    array = _schema_array(records, "vectors")
    if len(array) < 2:
        raise OracleError("VECTOR_COUNT", "vector set must contain metadata and cases")
    metadata = _schema_object(
        array[0],
        "vectors[0]",
        (
            "aor_binding",
            "generator_sha256",
            "manifest_canonical_sha256",
            "profile",
            "record_kind",
            "schema",
            "vector_count",
        ),
    )
    _schema_object(
        metadata["aor_binding"],
        "vectors[0].aor_binding",
        ("generator_sha256", "manifest_canonical_sha256", "vectors_sha256"),
    )
    for key in ("generator_sha256", "manifest_canonical_sha256", "vectors_sha256"):
        _sha_text(metadata["aor_binding"][key], "vectors[0].aor_binding." + key)
    for key in ("generator_sha256", "manifest_canonical_sha256", "profile", "record_kind", "schema"):
        _schema_string(metadata[key], "vectors[0]." + key)
    _sha_text(metadata["generator_sha256"], "vectors[0].generator_sha256")
    _sha_text(metadata["manifest_canonical_sha256"], "vectors[0].manifest_canonical_sha256")
    count = _schema_int(metadata["vector_count"], "vectors[0].vector_count")
    if count != len(array) - 1:
        raise OracleError("VECTOR_COUNT", "metadata vector_count does not match records")
    seen_case_ids: set[str] = set()
    for index, value in enumerate(array[1:], start=1):
        case = _schema_object(
            value,
            "vectors[" + str(index) + "]",
            (
                "case_id",
                "child_count",
                "children",
                "commit_count",
                "expected_error",
                "expected_raw32",
                "expected_status",
                "operation",
                "reason",
                "recipe",
                "src0_raw32",
                "src1_raw32",
                "sticky_flags",
            ),
        )
        case_id = _schema_string(case["case_id"], "case.case_id")
        if case_id in seen_case_ids:
            raise OracleError("VECTOR_CASE_ID", "duplicate vector case_id")
        seen_case_ids.add(case_id)
        child_count = _schema_int(case["child_count"], "case.child_count")
        commit_count = _schema_int(case["commit_count"], "case.commit_count")
        expected_error = _schema_int(case["expected_error"], "case.expected_error")
        children = _schema_array(case["children"], "case.children")
        if child_count != len(children):
            raise OracleError("VECTOR_CHILD_COUNT", "child_count does not match children")
        for child_index, child in enumerate(children):
            _validate_child_schema(child, "case.children[" + str(child_index) + "]", child_index)
        expected_raw = _schema_string(case["expected_raw32"], "case.expected_raw32")
        parse_raw32(expected_raw)
        status = _schema_string(case["expected_status"], "case.expected_status")
        if status not in ("OK", "UNSUPPORTED"):
            raise OracleError("VECTOR_STATUS", "unknown expected_status")
        operation = _schema_string(case["operation"], "case.operation")
        if operation not in VECTOR_OPERATIONS:
            raise OracleError("VECTOR_OPERATION", "unknown operation")
        reason = _schema_null_or_string(case["reason"], "case.reason")
        _schema_string(case["recipe"], "case.recipe")
        parse_raw32(_schema_string(case["src0_raw32"], "case.src0_raw32"))
        src1 = _schema_null_or_string(case["src1_raw32"], "case.src1_raw32")
        if src1 is not None:
            parse_raw32(src1)
        _schema_flags(case["sticky_flags"], "case.sticky_flags")
        if status == "OK" and (reason is not None or commit_count != 1 or expected_error != 0):
            raise OracleError("VECTOR_STATUS_FIELDS", "OK vector fields are inconsistent")
        if status == "UNSUPPORTED" and (
            expected_raw != "0x00000000"
            or reason is None
            or child_count != 0
            or commit_count != 0
            or expected_error != 1
        ):
            raise OracleError("VECTOR_STATUS_FIELDS", "UNSUPPORTED vector fields are inconsistent")
    return array


def verify_vectors(path: Path, oracle: TensorUnaryGluOracle) -> tuple[int, str]:
    records, observed_payload = _load_jsonl(path)
    _validate_vector_schema(records)
    expected_records = build_vector_records(oracle)
    expected_payload = _vector_payload(expected_records)
    if observed_payload != expected_payload:
        raise OracleError("VECTOR_EXACT_PAYLOAD", "vector bytes differ from canonical generated payload")
    return len(records) - 1, sha256_bytes(observed_payload)


def emit_mutation_audit(output: Path, oracle: TensorUnaryGluOracle) -> tuple[int, int, str]:
    target = _require_owned_output(output)
    audit = audit_mutations(oracle)
    payload = canonical_bytes(audit) + b"\n"
    try:
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_bytes(payload)
    except OSError as error:
        raise OracleError("AUDIT_WRITE", str(error)) from error
    return _schema_int(audit["witness_count"], "audit.witness_count"), _schema_int(audit["gap_count"], "audit.gap_count"), sha256_bytes(payload)


def run_internal_self_test(oracle: TensorUnaryGluOracle) -> int:
    cases = 0
    primitive_cases = (
        ("ADD", 0x00000000, 0x80000000, 0x00000000, ()),
        ("ADD", 0x80000000, 0x80000000, 0x80000000, ()),
        ("ADD", 0x3F800000, 0xBF800000, 0x00000000, ()),
        ("ADD", 0x3F800000, 0x33800000, 0x3F800000, ("NX",)),
        ("ADD", 0x7F7FFFFF, 0x7F7FFFFF, 0x7F800000, ("OF", "NX")),
        ("ADD", 0x7F800000, 0xFF800000, 0x7FC00000, ("NV",)),
        ("ADD", 0x7FC12345, 0x3F800000, 0x7FC00000, ()),
        ("ADD", 0x7F800001, 0x3F800000, 0x7FC00000, ("NV",)),
        ("MUL", 0x00800000, 0x3F7FFFFE, 0x007FFFFF, ()),
        ("MUL", 0x00800000, 0x3F7FFFFF, 0x00800000, ("UF", "NX")),
        ("MUL", 0x80800000, 0x3F7FFFFF, 0x80800000, ("UF", "NX")),
        ("MUL", 0x00000001, 0x3F000000, 0x00000000, ("UF", "NX")),
        ("MUL", 0x00000000, 0x7F800000, 0x7FC00000, ("NV",)),
        ("MUL", 0x7F800000, 0xFF800000, 0xFF800000, ()),
        ("DIV", 0x7F800000, 0x00000000, 0x7F800000, ()),
        ("DIV", 0xFF800000, 0x00000000, 0xFF800000, ()),
        ("DIV", 0x3F800000, 0x00000000, 0x7F800000, ("DZ",)),
        ("DIV", 0x00000000, 0x00000000, 0x7FC00000, ("NV",)),
        ("DIV", 0x7F800000, 0x7F800000, 0x7FC00000, ("NV",)),
        ("DIV", 0x00800000, 0x3F800001, 0x007FFFFF, ("UF", "NX")),
        ("DIV", 0x00800000, 0x3F7FFFFF, 0x00800001, ("NX",)),
        ("DIV", 0x3F800000, 0x40400000, 0x3EAAAAAB, ("NX",)),
    )
    for operation, lhs, rhs, expected_raw, expected_flags in primitive_cases:
        if operation == "ADD":
            result = f32_add(lhs, rhs)
        elif operation == "MUL":
            result = f32_mul(lhs, rhs)
        else:
            result = f32_div(lhs, rhs)
        if (result.raw, result.flags) != (expected_raw, expected_flags):
            raise OracleError(
                "SELF_TEST_PRIMITIVE",
                raw_text(lhs) + "," + raw_text(rhs) + " produced " + raw_text(result.raw),
                result.flags,
            )
        cases += 1

    sigmoid_negative_100 = oracle.evaluate("SIGMOID", 0xC2C80000)
    if (
        sigmoid_negative_100.raw != 0x00000000
        or sigmoid_negative_100.flags != ("OF", "NX")
        or len(sigmoid_negative_100.children) != 3
        or sigmoid_negative_100.children[0]["result_raw32"] != "0x7f800000"
    ):
        raise OracleError("SELF_TEST_SIGMOID_INTERNAL_INF", "SIGMOID -100 contract failed")
    cases += 1
    silu_negative_100 = oracle.evaluate("SILU", 0xC2C80000)
    if (
        silu_negative_100.raw != 0x80000000
        or silu_negative_100.flags != ("OF", "NX")
        or len(silu_negative_100.children) != 3
        or silu_negative_100.children[0]["result_raw32"] != "0x7f800000"
    ):
        raise OracleError("SELF_TEST_SILU_INTERNAL_INF", "SILU -100 contract failed")
    cases += 1
    equal_twenty = oracle.evaluate("SOFTPLUS", 0x41A00000)
    above_twenty = oracle.evaluate("SOFTPLUS", 0x41A00001)
    if len(equal_twenty.children) != 3 or len(above_twenty.children) != 0 or above_twenty.raw != 0x41A00001:
        raise OracleError("SELF_TEST_SOFTPLUS_THRESHOLD", "SOFTPLUS strict threshold failed")
    cases += 1
    unsupported = oracle.evaluate("SIGMOID", 0x7FC12345)
    if (
        unsupported.status != "UNSUPPORTED"
        or unsupported.raw != 0
        or unsupported.flags
        or unsupported.children
        or unsupported.commit_count != 0
    ):
        raise OracleError("SELF_TEST_PREFLIGHT", "external nonfinite preflight failed")
    cases += 1
    overflow = oracle.evaluate("SWIGLU", 0x7F7FFFFF, 0x40000000)
    if overflow.status != "OK" or overflow.raw != 0x7F800000 or "OF" not in overflow.flags or len(overflow.children) != 4:
        raise OracleError("SELF_TEST_SWIGLU_OVERFLOW", "finite SWIGLU overflow contract failed")
    cases += 1
    enforce_production_source_gate()
    cases += 1
    return cases


FINAL_ARTIFACT_PATHS = {
    "contract": "docs/UNARY_GLU_F32_ORACLE_CONTRACT.md",
    "generator": "scripts/unary_glu_f32_oracle.py",
    "manifest_file": "tests/vectors/unary_glu_f32_manifest.json",
    "mutation_audit": "tmp/logs/unary-glu-f32-oracle/final-mutation-audit.json",
    "test_source": "tests/test_unary_glu_f32_oracle.py",
    "vectors": "tests/vectors/unary_glu_f32_vectors.jsonl",
}

FINAL_COMMAND_SPECS = (
    {
        "command": "env PYTHONPYCACHEPREFIX=tmp/build/unary-glu-f32-oracle/pycache timeout 30s python3 scripts/unary_glu_f32_oracle.py validate-manifest",
        "expected_marker": PASS_MARKER,
        "id": "validate-manifest",
        "log": "tmp/logs/unary-glu-f32-oracle/final-validate-manifest.log",
        "marker_command": "validate-manifest",
    },
    {
        "command": "env PYTHONPYCACHEPREFIX=tmp/build/unary-glu-f32-oracle/pycache timeout 30s python3 scripts/unary_glu_f32_oracle.py self-test",
        "expected_marker": PASS_MARKER,
        "id": "self-test",
        "log": "tmp/logs/unary-glu-f32-oracle/final-self-test.log",
        "marker_command": "self-test",
    },
    {
        "command": "env PYTHONPYCACHEPREFIX=tmp/build/unary-glu-f32-oracle/pycache timeout 120s python3 scripts/unary_glu_f32_oracle.py audit-mutations --output tmp/logs/unary-glu-f32-oracle/final-mutation-audit.json",
        "expected_marker": PASS_MARKER,
        "id": "audit-mutations",
        "log": "tmp/logs/unary-glu-f32-oracle/final-mutation-audit.log",
        "marker_command": "audit-mutations",
    },
    {
        "command": "env PYTHONPYCACHEPREFIX=tmp/build/unary-glu-f32-oracle/pycache timeout 45s python3 scripts/unary_glu_f32_oracle.py emit-vectors --output tests/vectors/unary_glu_f32_vectors.jsonl",
        "expected_marker": PASS_MARKER,
        "id": "emit-vectors",
        "log": "tmp/logs/unary-glu-f32-oracle/final-emit-vectors.log",
        "marker_command": "emit-vectors",
    },
    {
        "command": "env PYTHONPYCACHEPREFIX=tmp/build/unary-glu-f32-oracle/pycache timeout 45s python3 scripts/unary_glu_f32_oracle.py verify-vectors --input tests/vectors/unary_glu_f32_vectors.jsonl",
        "expected_marker": PASS_MARKER,
        "id": "verify-vectors",
        "log": "tmp/logs/unary-glu-f32-oracle/final-verify-vectors.log",
        "marker_command": "verify-vectors",
    },
    {
        "command": "env PYTHONPYCACHEPREFIX=tmp/build/unary-glu-f32-oracle/pycache timeout 90s python3 tests/test_unary_glu_f32_oracle.py",
        "expected_marker": TEST_PASS_MARKER,
        "id": "unit-test",
        "log": "tmp/logs/unary-glu-f32-oracle/final-unit-test.log",
        "marker_command": "unit-test",
    },
    {
        "command": "env PYTHONPYCACHEPREFIX=tmp/build/unary-glu-f32-oracle/pycache timeout 120s python3 scripts/unary_glu_f32_oracle.py verify-evidence --evidence tmp/logs/unary-glu-f32-oracle/final-evidence.json",
        "expected_marker": EVIDENCE_PASS_MARKER,
        "id": "verify-evidence",
        "log": "tmp/logs/unary-glu-f32-oracle/final-verify-evidence.log",
        "marker_command": "verify-evidence",
    },
)


def _project_path(text: Any, path: str) -> Path:
    relative = _schema_string(text, path)
    if relative.startswith("/") or "\\" in relative or relative.startswith("../") or "/../" in relative:
        raise OracleError("EVIDENCE_PATH", path + " is not a safe project-relative path")
    resolved = REPO_ROOT.joinpath(relative).resolve()
    try:
        resolved.relative_to(REPO_ROOT.resolve())
    except ValueError as error:
        raise OracleError("EVIDENCE_PATH", path + " escapes the repository") from error
    return resolved


def _sha_text(value: Any, path: str, allow_null: bool = False) -> str | None:
    if value is None and allow_null:
        return None
    text = _schema_string(value, path)
    if len(text) != 64 or any(ch not in "0123456789abcdef" for ch in text):
        raise OracleError("SCHEMA_SHA256", path + " is not a lowercase SHA-256")
    return text


def _read_strict_object(path: Path, prefix: str) -> tuple[dict[str, Any], bytes]:
    try:
        data = path.read_bytes()
    except OSError as error:
        raise OracleError(prefix + "_READ", str(error)) from error
    value = _strict_json_bytes(data, prefix + "_UTF8", prefix + "_JSON")
    if type(value) is not dict:
        raise OracleError(prefix + "_ROOT", prefix + " root must be an object")
    return value, data


def _test_method_count() -> int:
    path = REPO_ROOT.joinpath(FINAL_ARTIFACT_PATHS["test_source"])
    try:
        source = path.read_text(encoding="utf-8")
    except (OSError, UnicodeError) as error:
        raise OracleError("TEST_SOURCE_READ", str(error)) from error
    try:
        tree = ast.parse(source, filename=str(path))
    except SyntaxError as error:
        raise OracleError("TEST_SOURCE_SYNTAX", "test source does not parse") from error
    return sum(
        1
        for node in ast.walk(tree)
        if isinstance(node, (ast.FunctionDef, ast.AsyncFunctionDef)) and node.name.startswith("test_")
    )


def _manifest_file_sha256(path: Path = DEFAULT_MANIFEST) -> str:
    try:
        return sha256_bytes(path.read_bytes())
    except OSError as error:
        raise OracleError("MANIFEST_FILE_READ", str(error)) from error


def _evidence_facts(
    oracle: TensorUnaryGluOracle,
    vector_count: int,
    vector_sha256: str,
    mutation_sha256: str,
    mutation_witnesses: int,
    mutation_gaps: int,
    internal_self_test_cases: int,
    unittest_methods: int,
) -> dict[str, Any]:
    return {
        "artifact_count": len(FINAL_ARTIFACT_PATHS),
        "command_count": len(FINAL_COMMAND_SPECS),
        "generator_sha256": generator_sha256(),
        "internal_self_test_cases": internal_self_test_cases,
        "manifest_canonical_sha256": oracle.manifest_sha256,
        "manifest_file_sha256": _manifest_file_sha256(),
        "mutation_audit_sha256": mutation_sha256,
        "mutation_gaps": mutation_gaps,
        "mutation_witnesses": mutation_witnesses,
        "qualified_vectors": vector_count,
        "unittest_methods": unittest_methods,
        "vectors_sha256": vector_sha256,
    }


def collect_evidence_facts() -> dict[str, Any]:
    """Recompute all semantic and file identities used by command receipts."""

    enforce_production_source_gate()
    manifest = load_manifest(DEFAULT_MANIFEST)
    oracle = TensorUnaryGluOracle(manifest)
    vector_count, vector_sha = verify_vectors(DEFAULT_VECTORS, oracle)
    mutation_path = REPO_ROOT.joinpath(FINAL_ARTIFACT_PATHS["mutation_audit"])
    _, mutation_bytes = _read_strict_object(mutation_path, "MUTATION_AUDIT")
    expected_mutation = audit_mutations(oracle)
    if mutation_bytes != canonical_bytes(expected_mutation) + b"\n":
        raise OracleError("EVIDENCE_MUTATION_PAYLOAD", "mutation audit is not the exact regenerated payload")
    return _evidence_facts(
        oracle,
        vector_count,
        vector_sha,
        sha256_bytes(mutation_bytes),
        _schema_int(expected_mutation["witness_count"], "mutation.witness_count"),
        _schema_int(expected_mutation["gap_count"], "mutation.gap_count"),
        run_internal_self_test(oracle),
        _test_method_count(),
    )


def expected_log_payload(command_id: str, facts: dict[str, Any]) -> dict[str, Any]:
    """Derive the one allowed canonical PASS object for a final command log."""

    if type(command_id) is not str or type(facts) is not dict:
        raise OracleError("EVIDENCE_LOG_EXPECTED_INPUT", "expected log arguments have invalid types")
    common = {
        "command": command_id,
        "generator_sha256": _sha_text(facts["generator_sha256"], "facts.generator_sha256"),
        "manifest_canonical_sha256": _sha_text(
            facts["manifest_canonical_sha256"],
            "facts.manifest_canonical_sha256",
        ),
        "manifest_file_sha256": _sha_text(facts["manifest_file_sha256"], "facts.manifest_file_sha256"),
        "marker": PASS_MARKER,
        "profile": PROFILE,
    }
    if command_id == "validate-manifest":
        return common
    if command_id == "self-test":
        return {**common, "cases": _schema_int(facts["internal_self_test_cases"], "facts.internal_self_test_cases")}
    if command_id == "audit-mutations":
        return {
            **common,
            "audit_sha256": _sha_text(facts["mutation_audit_sha256"], "facts.mutation_audit_sha256"),
            "gap_count": _schema_int(facts["mutation_gaps"], "facts.mutation_gaps"),
            "witness_count": _schema_int(facts["mutation_witnesses"], "facts.mutation_witnesses"),
        }
    if command_id in ("emit-vectors", "verify-vectors"):
        return {
            **common,
            "vector_count": _schema_int(facts["qualified_vectors"], "facts.qualified_vectors"),
            "vector_sha256": _sha_text(facts["vectors_sha256"], "facts.vectors_sha256"),
        }
    full = {
        **common,
        "audit_sha256": _sha_text(facts["mutation_audit_sha256"], "facts.mutation_audit_sha256"),
        "gap_count": _schema_int(facts["mutation_gaps"], "facts.mutation_gaps"),
        "self_test_cases": _schema_int(facts["internal_self_test_cases"], "facts.internal_self_test_cases"),
        "vector_count": _schema_int(facts["qualified_vectors"], "facts.qualified_vectors"),
        "vector_sha256": _sha_text(facts["vectors_sha256"], "facts.vectors_sha256"),
        "witness_count": _schema_int(facts["mutation_witnesses"], "facts.mutation_witnesses"),
    }
    if command_id == "unit-test":
        return {
            **full,
            "errors": 0,
            "failures": 0,
            "marker": TEST_PASS_MARKER,
            "skipped": 0,
            "tests": _schema_int(facts["unittest_methods"], "facts.unittest_methods"),
        }
    if command_id == "verify-evidence":
        return {
            **full,
            "artifact_count": _schema_int(facts["artifact_count"], "facts.artifact_count"),
            "command_count": _schema_int(facts["command_count"], "facts.command_count"),
            "marker": EVIDENCE_PASS_MARKER,
            "schema": EVIDENCE_SCHEMA,
            "unittest_methods": _schema_int(facts["unittest_methods"], "facts.unittest_methods"),
        }
    raise OracleError("EVIDENCE_COMMAND_ID", "unknown command marker schema")


def _verify_log_payload_bytes(
    command_id: str,
    data: bytes,
    expected_sha256: str,
    expected_payload: dict[str, Any],
) -> None:
    """Verify both the receipt SHA and the entire canonical command-log byte stream."""

    if sha256_bytes(data) != expected_sha256:
        raise OracleError("EVIDENCE_LOG_SHA256", command_id + " log SHA changed")
    expected_bytes = canonical_bytes(expected_payload) + b"\n"
    if data != expected_bytes:
        raise OracleError("EVIDENCE_LOG_EXACT_PAYLOAD", command_id + " log is not the current exact PASS payload")


def _verify_log_record(
    command: dict[str, Any],
    spec: dict[str, str],
    expected_payload: dict[str, Any],
    bootstrap_self_log: bool,
) -> None:
    command_id = _schema_string(command["id"], "command.id")
    if command_id != spec["id"]:
        raise OracleError("EVIDENCE_COMMAND_ID", "command order or id changed")
    for field in ("command", "expected_marker", "log", "marker_command"):
        if _schema_string(command[field], "command." + field) != spec[field]:
            raise OracleError("EVIDENCE_COMMAND_BINDING", command_id + " " + field + " changed")
    observed_rc = _schema_int(command["observed_exec_return_code"], "command.observed_exec_return_code")
    if observed_rc != 0:
        raise OracleError("EVIDENCE_COMMAND_RC", command_id + " was not externally observed as rc0")
    authority = _schema_string(
        command["observed_exec_return_code_authority"],
        "command.observed_exec_return_code_authority",
    )
    if authority != "external Codex exec result; recorded observation, not independently derivable from log bytes":
        raise OracleError("EVIDENCE_RC_AUTHORITY", command_id + " return-code authority changed")
    expected_sha = _sha_text(
        command["sha256"],
        "command.sha256",
        allow_null=bootstrap_self_log and command_id in ("unit-test", "verify-evidence"),
    )
    if bootstrap_self_log and command_id in ("unit-test", "verify-evidence") and expected_sha is None:
        return
    log_path = _project_path(command["log"], "command.log")
    try:
        data = log_path.read_bytes()
    except OSError as error:
        raise OracleError("EVIDENCE_LOG_READ", command_id + ": " + str(error)) from error
    _verify_log_payload_bytes(command_id, data, expected_sha, expected_payload)


def verify_evidence(path: Path, bootstrap_self_log: bool = False) -> tuple[int, int]:
    evidence, _ = _read_strict_object(path, "EVIDENCE")
    root = _schema_object(
        evidence,
        "evidence",
        (
            "artifacts",
            "commands",
            "first_failure",
            "identity",
            "profile",
            "return_code_semantics",
            "schema",
            "security_shadow",
            "self_verification",
            "semantic_bindings",
            "success_boundary",
        ),
    )
    if _schema_string(root["schema"], "evidence.schema") != EVIDENCE_SCHEMA:
        raise OracleError("EVIDENCE_SCHEMA", "evidence schema changed")
    if _schema_string(root["profile"], "evidence.profile") != PROFILE:
        raise OracleError("EVIDENCE_PROFILE", "evidence profile changed")
    identity = _schema_object(
        root["identity"],
        "evidence.identity",
        (
            "aor_generator_sha256",
            "aor_manifest_canonical_sha256",
            "aor_vectors_sha256",
            "generator_sha256",
            "manifest_canonical_sha256",
            "manifest_file_sha256",
            "mutation_audit_sha256",
            "vectors_sha256",
        ),
    )
    for key in identity:
        _sha_text(identity[key], "evidence.identity." + key)
    if identity["aor_generator_sha256"] != AOR_GENERATOR_SHA256:
        raise OracleError("EVIDENCE_AOR_IDENTITY", "AOR generator binding changed")
    if identity["aor_manifest_canonical_sha256"] != AOR_MANIFEST_CANONICAL_SHA256:
        raise OracleError("EVIDENCE_AOR_IDENTITY", "AOR manifest binding changed")
    if identity["aor_vectors_sha256"] != AOR_VECTORS_SHA256:
        raise OracleError("EVIDENCE_AOR_IDENTITY", "AOR vector binding changed")
    if identity["generator_sha256"] != generator_sha256():
        raise OracleError("EVIDENCE_GENERATOR_IDENTITY", "generator identity changed")

    manifest = load_manifest(DEFAULT_MANIFEST)
    oracle = TensorUnaryGluOracle(manifest)
    if identity["manifest_canonical_sha256"] != oracle.manifest_sha256:
        raise OracleError("EVIDENCE_MANIFEST_IDENTITY", "manifest identity changed")
    if identity["manifest_file_sha256"] != _manifest_file_sha256():
        raise OracleError("EVIDENCE_MANIFEST_FILE_IDENTITY", "manifest file identity changed")
    vector_count, vector_sha = verify_vectors(DEFAULT_VECTORS, oracle)
    if identity["vectors_sha256"] != vector_sha:
        raise OracleError("EVIDENCE_VECTOR_IDENTITY", "vector identity changed")

    artifacts = _schema_array(root["artifacts"], "evidence.artifacts", len(FINAL_ARTIFACT_PATHS))
    expected_ids = list(FINAL_ARTIFACT_PATHS)
    for index, value in enumerate(artifacts):
        artifact = _schema_object(value, "evidence.artifacts[" + str(index) + "]", ("id", "path", "sha256"))
        artifact_id = _schema_string(artifact["id"], "artifact.id")
        if artifact_id != expected_ids[index]:
            raise OracleError("EVIDENCE_ARTIFACT_ORDER", "artifact membership or order changed")
        if _schema_string(artifact["path"], "artifact.path") != FINAL_ARTIFACT_PATHS[artifact_id]:
            raise OracleError("EVIDENCE_ARTIFACT_PATH", artifact_id + " path changed")
        expected_sha = _sha_text(artifact["sha256"], "artifact.sha256")
        artifact_path = _project_path(artifact["path"], "artifact.path")
        try:
            observed_sha = sha256_bytes(artifact_path.read_bytes())
        except OSError as error:
            raise OracleError("EVIDENCE_ARTIFACT_READ", artifact_id + ": " + str(error)) from error
        if observed_sha != expected_sha:
            raise OracleError("EVIDENCE_ARTIFACT_SHA256", artifact_id + " SHA changed")

    mutation_path = REPO_ROOT.joinpath(FINAL_ARTIFACT_PATHS["mutation_audit"])
    mutation_value, mutation_bytes = _read_strict_object(mutation_path, "MUTATION_AUDIT")
    expected_mutation = audit_mutations(oracle)
    if mutation_bytes != canonical_bytes(expected_mutation) + b"\n":
        raise OracleError("EVIDENCE_MUTATION_PAYLOAD", "mutation audit is not the exact regenerated payload")
    mutation_sha = sha256_bytes(mutation_bytes)
    if identity["mutation_audit_sha256"] != mutation_sha:
        raise OracleError("EVIDENCE_MUTATION_IDENTITY", "mutation audit identity changed")

    bindings = _schema_object(
        root["semantic_bindings"],
        "evidence.semantic_bindings",
        (
            "internal_self_test_cases",
            "mutation_gaps",
            "mutation_witnesses",
            "qualified_vectors",
            "unittest_methods",
        ),
    )
    for key in bindings:
        _schema_int(bindings[key], "evidence.semantic_bindings." + key)
    if bindings["qualified_vectors"] != vector_count:
        raise OracleError("EVIDENCE_VECTOR_COUNT", "qualified vector count changed")
    mutation_witnesses = _schema_int(expected_mutation["witness_count"], "mutation.witness_count")
    mutation_gaps = _schema_int(expected_mutation["gap_count"], "mutation.gap_count")
    internal_self_test_cases = run_internal_self_test(oracle)
    unittest_methods = _test_method_count()
    if bindings["mutation_witnesses"] != mutation_witnesses:
        raise OracleError("EVIDENCE_MUTATION_COUNT", "mutation witness count changed")
    if bindings["mutation_gaps"] != mutation_gaps:
        raise OracleError("EVIDENCE_MUTATION_COUNT", "mutation gap count changed")
    if bindings["internal_self_test_cases"] != internal_self_test_cases:
        raise OracleError("EVIDENCE_SELF_TEST_COUNT", "internal self-test count changed")
    if bindings["unittest_methods"] != unittest_methods:
        raise OracleError("EVIDENCE_UNITTEST_COUNT", "unittest method count changed")

    facts = _evidence_facts(
        oracle,
        vector_count,
        vector_sha,
        mutation_sha,
        mutation_witnesses,
        mutation_gaps,
        internal_self_test_cases,
        unittest_methods,
    )
    commands = _schema_array(root["commands"], "evidence.commands", len(FINAL_COMMAND_SPECS))
    for index, value in enumerate(commands):
        command = _schema_object(
            value,
            "evidence.commands[" + str(index) + "]",
            (
                "command",
                "expected_marker",
                "id",
                "log",
                "marker_command",
                "observed_exec_return_code",
                "observed_exec_return_code_authority",
                "sha256",
            ),
        )
        _verify_log_record(
            command,
            FINAL_COMMAND_SPECS[index],
            expected_log_payload(FINAL_COMMAND_SPECS[index]["id"], facts),
            bootstrap_self_log,
        )

    first_failure = _schema_object(
        root["first_failure"],
        "evidence.first_failure",
        ("diagnostic", "log", "sha256", "status"),
    )
    failure_status = _schema_string(first_failure["status"], "first_failure.status")
    if failure_status == "OBSERVED":
        failure_path = _project_path(first_failure["log"], "first_failure.log")
        failure_sha = _sha_text(first_failure["sha256"], "first_failure.sha256")
        _schema_string(first_failure["diagnostic"], "first_failure.diagnostic")
        try:
            if sha256_bytes(failure_path.read_bytes()) != failure_sha:
                raise OracleError("EVIDENCE_FIRST_FAILURE_SHA", "first-failure log SHA changed")
        except OSError as error:
            raise OracleError("EVIDENCE_FIRST_FAILURE_READ", str(error)) from error
    elif failure_status == "NO_FAILURE_OBSERVED":
        if any(first_failure[key] is not None for key in ("diagnostic", "log", "sha256")):
            raise OracleError("EVIDENCE_FIRST_FAILURE", "no-failure record must use null details")
    else:
        raise OracleError("EVIDENCE_FIRST_FAILURE", "unknown first-failure status")

    security_shadow = _schema_object(
        root["security_shadow"],
        "evidence.security_shadow",
        ("diagnostic", "log", "sha256", "status"),
    )
    if _schema_string(security_shadow["status"], "security_shadow.status") != "OBSERVED_PRE_FIX":
        raise OracleError("EVIDENCE_SECURITY_SHADOW", "security shadow status changed")
    if _schema_string(security_shadow["diagnostic"], "security_shadow.diagnostic") != (
        "pre-fix checker accepted indirect JSON callable capture, dynamic builtins lookup, and reflection"
    ):
        raise OracleError("EVIDENCE_SECURITY_SHADOW", "security shadow diagnostic changed")
    security_shadow_path = _project_path(security_shadow["log"], "security_shadow.log")
    if security_shadow_path != TMP_LOGS.joinpath("p1-shadow-diagnostic.log").resolve():
        raise OracleError("EVIDENCE_SECURITY_SHADOW", "security shadow path changed")
    security_shadow_sha = _sha_text(security_shadow["sha256"], "security_shadow.sha256")
    try:
        if sha256_bytes(security_shadow_path.read_bytes()) != security_shadow_sha:
            raise OracleError("EVIDENCE_SECURITY_SHADOW_SHA", "security shadow log SHA changed")
    except OSError as error:
        raise OracleError("EVIDENCE_SECURITY_SHADOW_READ", str(error)) from error

    if _schema_string(root["return_code_semantics"], "return_code_semantics") != (
        "external exec observation; terminal PASS marker and log hash are independently verified, "
        "but parent wait status is not derivable from log bytes"
    ):
        raise OracleError("EVIDENCE_RC_SEMANTICS", "return-code semantics changed")
    success = _schema_object(
        root["success_boundary"],
        "evidence.success_boundary",
        ("qwen", "rtl", "scope", "synthesis_sta_ppa"),
    )
    if success != {
        "qwen": "NOT_RUN",
        "rtl": "NOT_RUN",
        "scope": "PURE_INTEGER_ORACLE_AND_FIXED_VECTORS_ONLY",
        "synthesis_sta_ppa": "NOT_RUN",
    }:
        raise OracleError("EVIDENCE_SUCCESS_BOUNDARY", "success boundary changed")
    self_verification = _schema_object(
        root["self_verification"],
        "evidence.self_verification",
        ("bootstrap_semantics", "command_id", "normal_verification_required"),
    )
    _schema_string(self_verification["bootstrap_semantics"], "self_verification.bootstrap_semantics")
    _schema_string(self_verification["command_id"], "self_verification.command_id")
    _schema_int(
        self_verification["normal_verification_required"],
        "self_verification.normal_verification_required",
    )
    if self_verification != {
        "bootstrap_semantics": "unit-test and verify-evidence log SHA may be null only during bootstrap; final receipt requires both bound log SHA values",
        "command_id": "verify-evidence",
        "normal_verification_required": 1,
    }:
        raise OracleError("EVIDENCE_SELF_VERIFICATION", "self-verification contract changed")
    return len(artifacts), len(commands)


def _status_payload(**values: Any) -> str:
    return canonical_bytes({"marker": PASS_MARKER, **values}).decode("utf-8")


def _build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Pure-integer Tensor NPU Unary/GLU F32 raw-bit oracle")
    subparsers = parser.add_subparsers(dest="command", required=True)
    validate = subparsers.add_parser("validate-manifest")
    validate.add_argument("--manifest", type=Path, default=DEFAULT_MANIFEST)
    self_test = subparsers.add_parser("self-test")
    self_test.add_argument("--manifest", type=Path, default=DEFAULT_MANIFEST)
    emit = subparsers.add_parser("emit-vectors")
    emit.add_argument("--manifest", type=Path, default=DEFAULT_MANIFEST)
    emit.add_argument("--output", type=Path, required=True)
    verify = subparsers.add_parser("verify-vectors")
    verify.add_argument("--manifest", type=Path, default=DEFAULT_MANIFEST)
    verify.add_argument("--input", type=Path, required=True)
    audit = subparsers.add_parser("audit-mutations")
    audit.add_argument("--manifest", type=Path, default=DEFAULT_MANIFEST)
    audit.add_argument("--output", type=Path, required=True)
    evidence = subparsers.add_parser("verify-evidence")
    evidence.add_argument("--evidence", type=Path, required=True)
    evidence.add_argument("--bootstrap-self-log", action="store_true")
    return parser


def main(argv: Sequence[str] | None = None) -> int:
    try:
        enforce_production_source_gate()
        parser = _build_parser()
        arguments = parser.parse_args(argv)
        if arguments.command == "verify-evidence":
            artifact_count, command_count = verify_evidence(
                arguments.evidence.resolve(),
                arguments.bootstrap_self_log,
            )
            facts = collect_evidence_facts()
            if facts["artifact_count"] != artifact_count or facts["command_count"] != command_count:
                raise OracleError("EVIDENCE_COUNT_RECOMPUTE", "evidence counts changed after verification")
            print(canonical_bytes(expected_log_payload("verify-evidence", facts)).decode("utf-8"))
            return 0
        manifest_path = arguments.manifest.resolve()
        manifest = load_manifest(manifest_path)
        oracle = TensorUnaryGluOracle(manifest)
        identity_fields = {
            "generator_sha256": generator_sha256(),
            "manifest_canonical_sha256": oracle.manifest_sha256,
            "manifest_file_sha256": _manifest_file_sha256(manifest_path),
            "profile": PROFILE,
        }
        if arguments.command == "validate-manifest":
            print(_status_payload(command="validate-manifest", **identity_fields))
        elif arguments.command == "self-test":
            count = run_internal_self_test(oracle)
            print(
                _status_payload(
                    cases=count,
                    command="self-test",
                    **identity_fields,
                )
            )
        elif arguments.command == "emit-vectors":
            count, digest = emit_vectors(arguments.output, oracle)
            print(
                _status_payload(
                    command="emit-vectors",
                    vector_count=count,
                    vector_sha256=digest,
                    **identity_fields,
                )
            )
        elif arguments.command == "verify-vectors":
            count, digest = verify_vectors(arguments.input.resolve(), oracle)
            print(
                _status_payload(
                    command="verify-vectors",
                    vector_count=count,
                    vector_sha256=digest,
                    **identity_fields,
                )
            )
        elif arguments.command == "audit-mutations":
            witness_count, gap_count, digest = emit_mutation_audit(arguments.output, oracle)
            print(
                _status_payload(
                    audit_sha256=digest,
                    command="audit-mutations",
                    gap_count=gap_count,
                    witness_count=witness_count,
                    **identity_fields,
                )
            )
        else:
            raise OracleError("COMMAND", "unreachable command")
    except (OracleError, aor.OracleError) as error:
        payload = {
            "code": error.code,
            "flags": list(error.flags),
            "marker": FAIL_MARKER,
            "message": str(error),
        }
        print(canonical_bytes(payload).decode("utf-8"), file=sys.stderr)
        return 2
    except Exception as error:
        payload = {
            "code": "UNEXPECTED_INTERNAL_ERROR",
            "flags": [],
            "marker": FAIL_MARKER,
            "message": type(error).__name__,
        }
        print(canonical_bytes(payload).decode("utf-8"), file=sys.stderr)
        return 2
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
