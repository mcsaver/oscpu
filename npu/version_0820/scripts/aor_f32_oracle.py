#!/usr/bin/env python3
# SPDX-License-Identifier: MIT
#
# Derived from ARM-software/optimized-routines, commit
# 67126040cf80f956676fbf473c2d9bebdb475283.  This source-replay oracle is a
# project-local, integer-only transcription of the fixed expf/logf operation
# graph; it is not a host-libm reference.

from __future__ import annotations

import argparse
import ast
import hashlib
import json
import os
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Iterable, Sequence


PROFILE = "AOR_AARCH64_FMA_RNE_V1"
SOURCE_COMMIT = "67126040cf80f956676fbf473c2d9bebdb475283"
MANIFEST_SCHEMA = "aor-f32-exp-log-manifest-v1"
VECTOR_SCHEMA = "aor-f32-vector-set-v1"
MUTATION_SCHEMA = "aor-f32-mutation-audit-v1"
EVIDENCE_SCHEMA = "aor-f32-oracle-evidence-v2"
EXPECTED_MANIFEST_SHA256 = "4d7b403b5f835adfc4465f920a9322ddf71b7568aaf0f1790c84e0b81371f004"
EXPECTED_OLD_IDENTITY = {
    "manifest_canonical_sha256": "4d7b403b5f835adfc4465f920a9322ddf71b7568aaf0f1790c84e0b81371f004",
    "generator_sha256": "8d7653c724614e70dc617d745bfd240b01179d4a9925a92c5377c95457a9062b",
    "vectors_sha256": "ef3e7e9c847d88231e06af6e5047a08dd9ecfc963a0ddc5b671f7244d7a98c9e",
    "mutation_audit_sha256": "3164d812410065b380862cb036cd494baa033a86e6526eda41e667e971315ead",
}
PASS_MARKER = "[AOR-F32-ORACLE][PASS]"
EVIDENCE_PASS_MARKER = "[AOR-F32-EVIDENCE][PASS]"

SCRIPT_PATH = Path(__file__).resolve()
REPO_ROOT = SCRIPT_PATH.parent.parent
DEFAULT_MANIFEST = REPO_ROOT.joinpath("tests", "vectors", "aor_f32_manifest.json")
TMP_BUILD = REPO_ROOT.joinpath("tmp", "build", "aor-f32-oracle")

FLAG_ORDER = ("NV", "DZ", "OF", "UF", "NX")
U32_MASK = (1 << 32) - 1
U64_MASK = (1 << 64) - 1

PRODUCTION_IMPORT_ALLOWLIST = frozenset(
    {
        ("from", "__future__", "annotations", None),
        ("import", "argparse", None, None),
        ("import", "ast", None, None),
        ("import", "hashlib", None, None),
        ("import", "json", None, None),
        ("import", "os", None, None),
        ("import", "sys", None, None),
        ("from", "dataclasses", "dataclass", None),
        ("from", "pathlib", "Path", None),
        ("from", "typing", "Any", None),
        ("from", "typing", "Iterable", None),
        ("from", "typing", "Sequence", None),
    }
)


class OracleError(RuntimeError):
    """A fail-closed oracle error with a stable machine-readable code."""

    def __init__(self, code: str, message: str, flags: Sequence[str] = ()) -> None:
        super().__init__(message)
        self.code = code
        self.flags = ordered_flags(flags)


class ManifestError(OracleError):
    pass


class NanEvidenceError(OracleError):
    pass


@dataclass(frozen=True)
class BinaryFormat:
    total_bits: int
    exponent_bits: int
    fraction_bits: int
    precision: int
    minimum_exponent: int
    maximum_exponent: int
    bias: int


F32 = BinaryFormat(32, 8, 23, 24, -126, 127, 127)
F64 = BinaryFormat(64, 11, 52, 53, -1022, 1023, 1023)


@dataclass(frozen=True)
class Decoded:
    kind: str
    sign: int
    magnitude: int
    exponent: int
    fraction: int
    quiet: bool


@dataclass(frozen=True)
class Dyadic:
    sign: int
    magnitude: int
    exponent: int


@dataclass(frozen=True)
class RawResult:
    raw: int
    flags: tuple[str, ...]


@dataclass(frozen=True)
class IntegralResult:
    raw: int
    discarded: bool


@dataclass(frozen=True)
class IntegerResult:
    value: int
    flags: tuple[str, ...]
    discarded: bool


@dataclass(frozen=True)
class AorResult:
    raw: int
    api_flags: tuple[str, ...]
    trace: tuple[dict[str, Any], ...]


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


def u32(value: int) -> int:
    return value & U32_MASK


def u64(value: int) -> int:
    return value & U64_MASK


def asr32(value: int, amount: int) -> int:
    word = u32(value)
    signed = word - (1 << 32) if word & (1 << 31) else word
    return signed >> amount


def raw_text(raw: int, bits: int) -> str:
    if bits == 32:
        return "0x" + format(u32(raw), "08x")
    if bits == 64:
        return "0x" + format(u64(raw), "016x")
    raise OracleError("RAW_WIDTH", "unsupported raw width")


def parse_raw(text: str, bits: int) -> int:
    width = bits // 4
    if not isinstance(text, str):
        raise OracleError("RAW_TYPE", "raw value is not a string")
    if len(text) != width + 2 or not text.startswith("0x"):
        raise OracleError("RAW_SYNTAX", "raw value has the wrong width or prefix")
    digits = text[2:]
    if digits != digits.lower() or any(ch not in "0123456789abcdef" for ch in digits):
        raise OracleError("RAW_SYNTAX", "raw value must use lowercase hexadecimal")
    return int(digits, 16)


def decode(raw: int, spec: BinaryFormat) -> Decoded:
    raw &= (1 << spec.total_bits) - 1
    sign = (raw >> (spec.total_bits - 1)) & 1
    exponent_mask = (1 << spec.exponent_bits) - 1
    exponent_field = (raw >> spec.fraction_bits) & exponent_mask
    fraction = raw & ((1 << spec.fraction_bits) - 1)
    if exponent_field == exponent_mask:
        if fraction == 0:
            return Decoded("infinity", sign, 0, 0, fraction, False)
        quiet = bool(fraction & (1 << (spec.fraction_bits - 1)))
        return Decoded("nan", sign, 0, 0, fraction, quiet)
    if exponent_field == 0:
        if fraction == 0:
            return Decoded("zero", sign, 0, spec.minimum_exponent - spec.fraction_bits, 0, False)
        return Decoded(
            "finite",
            sign,
            fraction,
            spec.minimum_exponent - spec.fraction_bits,
            fraction,
            False,
        )
    return Decoded(
        "finite",
        sign,
        (1 << spec.fraction_bits) | fraction,
        exponent_field - spec.bias - spec.fraction_bits,
        fraction,
        False,
    )


def decode_f32(raw: int) -> Decoded:
    return decode(u32(raw), F32)


def decode_f64(raw: int) -> Decoded:
    return decode(u64(raw), F64)


def normalize_dyadic(sign: int, magnitude: int, exponent: int) -> Dyadic:
    if sign not in (0, 1) or magnitude < 0:
        raise OracleError("DYADIC_DOMAIN", "invalid dyadic sign or magnitude")
    if magnitude == 0:
        return Dyadic(sign, 0, 0)
    trailing = (magnitude & -magnitude).bit_length() - 1
    return Dyadic(sign, magnitude >> trailing, exponent + trailing)


def _round_right_rne(magnitude: int, amount: int) -> tuple[int, bool]:
    if amount <= 0:
        return magnitude << (-amount), False
    retained = magnitude >> amount
    remainder = magnitude & ((1 << amount) - 1)
    half = 1 << (amount - 1)
    increment = remainder > half or (remainder == half and bool(retained & 1))
    return retained + int(increment), remainder != 0


def _round_precision_unbounded_rne(magnitude: int, exponent: int, precision: int) -> tuple[int, int, bool]:
    """Round to precision with RN-even while intentionally ignoring the exponent range."""

    if magnitude <= 0 or precision <= 0:
        raise OracleError("PACK_DOMAIN", "unbounded precision rounding requires positive integers")
    grid = exponent + magnitude.bit_length() - precision
    rounded, inexact = _round_right_rne(magnitude, grid - exponent)
    if rounded == 0:
        raise OracleError("PACK_INTERNAL", "unbounded precision rounding produced zero")
    return rounded, grid, inexact


def pack_dyadic(sign: int, magnitude: int, exponent: int, spec: BinaryFormat) -> RawResult:
    """Round |magnitude|*2**exponent once with RN-even and tininess-after."""

    if sign not in (0, 1) or magnitude < 0:
        raise OracleError("PACK_DOMAIN", "invalid dyadic sign or magnitude")
    sign_word = sign << (spec.total_bits - 1)
    if magnitude == 0:
        return RawResult(sign_word, ())

    # IEEE tininess-after 先在目标 precision、暂时无界 exponent 下舍入；这个结果可能
    # 仍然 tiny，即使有限 exponent/subnormal 编码阶段最终进位到 minimum normal。
    precision_rounded, precision_grid, _ = _round_precision_unbounded_rne(
        magnitude,
        exponent,
        spec.precision,
    )
    precision_floor_log = precision_rounded.bit_length() - 1 + precision_grid
    tiny_after = precision_floor_log < spec.minimum_exponent

    # 最终编码始终直接从 exact dyadic 舍入到有限格式网格，不能对上面的暂时结果二次舍入。
    length = magnitude.bit_length()
    minimum_grid = spec.minimum_exponent - (spec.precision - 1)
    grid = max(exponent + length - spec.precision, minimum_grid)
    rounded, inexact = _round_right_rne(magnitude, grid - exponent)
    inexact_flags: tuple[str, ...] = ("UF", "NX") if inexact and tiny_after else (("NX",) if inexact else ())
    if rounded == 0:
        return RawResult(sign_word, inexact_flags)

    floor_log = rounded.bit_length() - 1 + grid
    if floor_log > spec.maximum_exponent:
        return RawResult(sign_word | (((1 << spec.exponent_bits) - 1) << spec.fraction_bits), ("OF", "NX"))

    if floor_log >= spec.minimum_exponent:
        alignment = spec.precision - rounded.bit_length()
        if alignment >= 0:
            significand = rounded << alignment
        else:
            discarded_mask = (1 << (-alignment)) - 1
            if rounded & discarded_mask:
                raise OracleError("PACK_INTERNAL", "rounded significand is not exactly alignable")
            significand = rounded >> (-alignment)
        exponent_field = floor_log + spec.bias
        fraction = significand - (1 << (spec.precision - 1))
        raw = sign_word | (exponent_field << spec.fraction_bits) | fraction
        return RawResult(raw, inexact_flags)

    if grid != minimum_grid or rounded >= (1 << (spec.precision - 1)):
        raise OracleError("PACK_INTERNAL", "subnormal encoding invariant failed")
    return RawResult(sign_word | rounded, inexact_flags)


def pack_f32(sign: int, magnitude: int, exponent: int) -> RawResult:
    return pack_dyadic(sign, magnitude, exponent, F32)


def pack_f64(sign: int, magnitude: int, exponent: int) -> RawResult:
    return pack_dyadic(sign, magnitude, exponent, F64)


def _require_finite(value: Decoded, operation: str) -> None:
    if value.kind not in ("zero", "finite"):
        raise OracleError("NONFINITE_OPERAND", operation + " requires finite operands")


def f32_to_f64_exact(raw: int) -> RawResult:
    value = decode_f32(raw)
    _require_finite(value, "f32_to_f64_exact")
    result = pack_f64(value.sign, value.magnitude, value.exponent)
    if result.flags:
        raise OracleError("EXACT_CONVERSION", "f32 to f64 conversion was unexpectedly inexact")
    return result


def f64_to_f32(raw: int) -> RawResult:
    value = decode_f64(raw)
    _require_finite(value, "f64_to_f32")
    return pack_f32(value.sign, value.magnitude, value.exponent)


def _finite_terms(values: Sequence[Decoded]) -> tuple[int, int]:
    nonzero = [value for value in values if value.magnitude != 0]
    if not nonzero:
        return 0, 0
    common_exponent = min(value.exponent for value in nonzero)
    total = 0
    for value in nonzero:
        term = value.magnitude << (value.exponent - common_exponent)
        total += -term if value.sign else term
    return total, common_exponent


def f64_add(a_raw: int, b_raw: int) -> RawResult:
    a = decode_f64(a_raw)
    b = decode_f64(b_raw)
    _require_finite(a, "f64_add")
    _require_finite(b, "f64_add")
    total, exponent = _finite_terms((a, b))
    if total == 0:
        zero_sign = (a.sign & b.sign) if a.magnitude == 0 and b.magnitude == 0 else 0
        return pack_f64(zero_sign, 0, 0)
    return pack_f64(int(total < 0), abs(total), exponent)


def f64_sub(a_raw: int, b_raw: int) -> RawResult:
    return f64_add(a_raw, u64(b_raw) ^ (1 << 63))


def f64_mul(a_raw: int, b_raw: int) -> RawResult:
    a = decode_f64(a_raw)
    b = decode_f64(b_raw)
    _require_finite(a, "f64_mul")
    _require_finite(b, "f64_mul")
    return pack_f64(a.sign ^ b.sign, a.magnitude * b.magnitude, a.exponent + b.exponent)


def f64_fma(a_raw: int, b_raw: int, c_raw: int) -> RawResult:
    a = decode_f64(a_raw)
    b = decode_f64(b_raw)
    c = decode_f64(c_raw)
    _require_finite(a, "f64_fma")
    _require_finite(b, "f64_fma")
    _require_finite(c, "f64_fma")
    product_sign = a.sign ^ b.sign
    product_magnitude = a.magnitude * b.magnitude
    product_exponent = a.exponent + b.exponent
    product = Decoded("finite", product_sign, product_magnitude, product_exponent, 0, False)
    total, exponent = _finite_terms((product, c))
    if total == 0:
        if product_magnitude == 0 and c.magnitude == 0:
            zero_sign = product_sign & c.sign
        else:
            zero_sign = 0
        return pack_f64(zero_sign, 0, 0)
    return pack_f64(int(total < 0), abs(total), exponent)


def f64_round_integral_rmm(raw: int) -> IntegralResult:
    value = decode_f64(raw)
    _require_finite(value, "f64_round_integral_rmm")
    if value.magnitude == 0:
        return IntegralResult(u64(raw), False)
    if value.exponent >= 0:
        integer_magnitude = value.magnitude << value.exponent
        discarded = False
    else:
        amount = -value.exponent
        integer_magnitude = value.magnitude >> amount
        remainder = value.magnitude & ((1 << amount) - 1)
        discarded = remainder != 0
        if remainder and (remainder << 1) >= (1 << amount):
            integer_magnitude += 1
    packed = pack_f64(value.sign, integer_magnitude, 0)
    if packed.flags:
        raise OracleError("INTEGRAL_PACK", "rounded integral result was unexpectedly inexact")
    return IntegralResult(packed.raw, discarded)


def f64_to_i32_rmm(raw: int, expose_inexact: bool = False) -> IntegerResult:
    value = decode_f64(raw)
    if value.kind not in ("zero", "finite"):
        return IntegerResult(-(1 << 31), ("NV",), False)
    rounded = f64_round_integral_rmm(raw)
    integral = decode_f64(rounded.raw)
    magnitude = integral.magnitude << integral.exponent if integral.exponent >= 0 else integral.magnitude >> (-integral.exponent)
    signed = -magnitude if integral.sign else magnitude
    if signed < -(1 << 31) or signed > (1 << 31) - 1:
        return IntegerResult(-(1 << 31), ("NV",), rounded.discarded)
    flags = ("NX",) if expose_inexact and rounded.discarded else ()
    return IntegerResult(signed, flags, rounded.discarded)


def i32_to_f64(value: int) -> RawResult:
    if value < -(1 << 31) or value > (1 << 31) - 1:
        raise OracleError("I32_RANGE", "integer input is outside signed 32-bit range")
    result = pack_f64(int(value < 0), abs(value), 0)
    if result.flags:
        raise OracleError("I32_EXACT", "i32 to f64 conversion was unexpectedly inexact")
    return result


def compare_finite(a: Decoded, b: Decoded) -> int:
    _require_finite(a, "compare_finite")
    _require_finite(b, "compare_finite")
    total, _ = _finite_terms((a, Decoded(b.kind, 1 - b.sign, b.magnitude, b.exponent, b.fraction, b.quiet)))
    return (total > 0) - (total < 0)


def check_integer_only_source(source: str, filename: str = "<source>", require_complete_imports: bool = False) -> None:
    """Reject syntax that can introduce host real/complex arithmetic or dynamic code."""

    if type(source) is not str or type(filename) is not str or type(require_complete_imports) is not bool:
        raise OracleError("INTEGER_ONLY_CHECKER_INPUT", "checker arguments have invalid types")
    try:
        tree = ast.parse(source, filename=filename)
    except SyntaxError as error:
        raise OracleError("INTEGER_ONLY_SYNTAX", "source does not parse") from error

    seen_imports: set[tuple[str, str, str | None, str | None]] = set()
    forbidden_names = {
        "float",
        "complex",
        "__import__",
        "eval",
        "exec",
        "compile",
        "getattr",
        "setattr",
        "vars",
        "globals",
        "locals",
        "__builtins__",
    }
    forbidden_literal_type_names = {"float", "complex"}
    controlled_json_keywords = {
        "object_pairs_hook": "_duplicate_checked_object",
        "parse_float": "_reject_json_real",
        "parse_constant": "_reject_json_constant",
    }
    parents = {child: parent for parent in ast.walk(tree) for child in ast.iter_child_nodes(parent)}

    for node in ast.walk(tree):
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
        elif isinstance(node, ast.Name) and node.id in forbidden_names:
            raise OracleError("INTEGER_ONLY_NAME", "forbidden runtime name: " + node.id)
        elif isinstance(node, ast.Attribute):
            if node.attr in forbidden_names:
                raise OracleError("INTEGER_ONLY_ATTRIBUTE", "forbidden runtime attribute: " + node.attr)
            if (
                node.attr == "loads"
                and isinstance(node.value, ast.Name)
                and node.value.id == "json"
            ):
                parent = parents.get(node)
                if not isinstance(parent, ast.Call) or parent.func is not node:
                    raise OracleError("INTEGER_ONLY_JSON", "json.loads cannot be captured or aliased")
        elif isinstance(node, ast.Constant) and type(node.value).__name__ in forbidden_literal_type_names:
            raise OracleError("INTEGER_ONLY_LITERAL", "host real or complex literal is forbidden")
        elif isinstance(node, (ast.Div, ast.Pow)):
            raise OracleError("INTEGER_ONLY_OPERATOR", "true division and exponentiation are forbidden")
        elif isinstance(node, ast.Call):
            is_json_loads = (
                isinstance(node.func, ast.Attribute)
                and node.func.attr == "loads"
                and isinstance(node.func.value, ast.Name)
                and node.func.value.id == "json"
            )
            if isinstance(node.func, ast.Attribute) and node.func.attr == "loads" and not is_json_loads:
                raise OracleError("INTEGER_ONLY_JSON", "only controlled json.loads is allowed")
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


def _require_integer_json_tree(value: Any) -> None:
    if value is None or isinstance(value, (str, int, bool)):
        return
    if isinstance(value, (list, tuple)):
        for item in value:
            _require_integer_json_tree(item)
        return
    if isinstance(value, dict):
        for key, item in value.items():
            if not isinstance(key, str):
                raise OracleError("JSON_KEY_TYPE", "canonical JSON keys must be strings")
            _require_integer_json_tree(item)
        return
    raise OracleError("JSON_VALUE_TYPE", "canonical JSON accepts only null, bool, integer, string, array and object")


def canonical_bytes(value: Any) -> bytes:
    _require_integer_json_tree(value)
    return json.dumps(value, sort_keys=True, separators=(",", ":"), ensure_ascii=True).encode("utf-8")


def sha256_bytes(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def generator_sha256() -> str:
    return sha256_bytes(SCRIPT_PATH.read_bytes())


def load_manifest(path: Path) -> dict[str, Any]:
    try:
        text = path.read_text(encoding="utf-8")
    except (OSError, UnicodeError) as error:
        raise ManifestError("MANIFEST_READ", str(error)) from error
    try:
        value = json.loads(
            text,
            object_pairs_hook=_duplicate_checked_object,
            parse_float=_reject_json_real,
            parse_constant=_reject_json_constant,
        )
    except ManifestError:
        raise
    except (json.JSONDecodeError, UnicodeError) as error:
        raise ManifestError("MANIFEST_JSON", str(error)) from error
    if type(value) is not dict:
        raise ManifestError("MANIFEST_ROOT", "manifest root must be an object")
    validate_manifest(value)
    return value


def _schema_object(value: Any, path: str, keys: Iterable[str]) -> dict[str, Any]:
    if type(value) is not dict:
        raise ManifestError("SCHEMA_OBJECT", path + " must be an object")
    expected = set(keys)
    if set(value) != expected:
        raise ManifestError("SCHEMA_KEYS", path + " has missing or unknown fields")
    return value


def _schema_array(value: Any, path: str, length: int | None = None) -> list[Any]:
    if type(value) is not list:
        raise ManifestError("SCHEMA_ARRAY", path + " must be an array")
    if length is not None and len(value) != length:
        raise ManifestError("SCHEMA_ARRAY_LENGTH", path + " has the wrong length")
    return value


def _schema_string(value: Any, path: str) -> str:
    if type(value) is not str:
        raise ManifestError("SCHEMA_STRING", path + " must be a string")
    return value


def _schema_int(value: Any, path: str) -> int:
    if type(value) is not int:
        raise ManifestError("SCHEMA_INTEGER", path + " must be an integer and not a boolean")
    return value


def _schema_null(value: Any, path: str) -> None:
    if value is not None:
        raise ManifestError("SCHEMA_NULL", path + " must be null")


def _schema_string_array(value: Any, path: str, length: int | None = None) -> list[str]:
    array = _schema_array(value, path, length)
    result: list[str] = []
    for index, item in enumerate(array):
        result.append(_schema_string(item, path + "[" + str(index) + "]"))
    return result


def _schema_flags(value: Any, path: str) -> list[str]:
    flags = _schema_string_array(value, path)
    try:
        canonical = list(ordered_flags(flags))
    except OracleError as error:
        raise ManifestError("SCHEMA_FLAGS", path + " contains an unknown flag") from error
    if flags != canonical:
        raise ManifestError("SCHEMA_FLAGS", path + " flags are duplicated or out of order")
    return flags


def _schema_scalar_object(
    value: Any,
    path: str,
    string_fields: Iterable[str] = (),
    int_fields: Iterable[str] = (),
    null_fields: Iterable[str] = (),
) -> dict[str, Any]:
    strings = tuple(string_fields)
    integers = tuple(int_fields)
    nulls = tuple(null_fields)
    obj = _schema_object(value, path, (*strings, *integers, *nulls))
    for key in strings:
        _schema_string(obj[key], path + "." + key)
    for key in integers:
        _schema_int(obj[key], path + "." + key)
    for key in nulls:
        _schema_null(obj[key], path + "." + key)
    return obj


def _schema_raw_object(value: Any, path: str, fields: Iterable[str], bits: int) -> dict[str, Any]:
    names = tuple(fields)
    obj = _schema_object(value, path, names)
    for key in names:
        parse_raw(_schema_string(obj[key], path + "." + key), bits)
    return obj


def _validate_manifest_schema(manifest: Any) -> dict[str, Any]:
    root_keys = (
        "schema",
        "status",
        "profile",
        "source",
        "build_profile",
        "fp_profile",
        "flags_profile",
        "nan_target_evidence",
        "raw_syntax",
        "exp32",
        "log32",
        "special_results",
        "nan_policy",
        "mutation_audit",
    )
    root = _schema_object(manifest, "$", root_keys)
    for key in ("schema", "status", "profile"):
        _schema_string(root[key], "$." + key)

    source = _schema_object(root["source"], "$.source", ("project", "commit", "license_choice", "files"))
    for key in ("project", "commit", "license_choice"):
        _schema_string(source[key], "$.source." + key)
    _schema_string_array(source["files"], "$.source.files", 4)

    build = _schema_object(root["build_profile"], "$.build_profile", ("target", "language", "flags", "macros"))
    _schema_string(build["target"], "$.build_profile.target")
    _schema_string(build["language"], "$.build_profile.language")
    _schema_string_array(build["flags"], "$.build_profile.flags", 5)
    _schema_scalar_object(
        build["macros"],
        "$.build_profile.macros",
        int_fields=(
            "WANT_ROUNDING",
            "WANT_ERRNO",
            "WANT_ERRNO_UFLOW",
            "HAVE_FAST_ROUND",
            "HAVE_FAST_LROUND",
            "HAVE_FAST_FMA",
            "TOINT_INTRINSICS",
            "EXP2F_TABLE_BITS",
            "EXP2F_POLY_ORDER",
            "LOGF_TABLE_BITS",
            "LOGF_POLY_ORDER",
        ),
    )
    _schema_scalar_object(
        root["fp_profile"],
        "$.fp_profile",
        string_fields=("arithmetic_rounding", "integer_rounding", "tininess_detection"),
        int_fields=("flush_to_zero", "default_nan", "trapping"),
    )
    _schema_scalar_object(
        root["flags_profile"],
        "$.flags_profile",
        string_fields=("revision",),
        int_fields=(
            "accumulate_f64_add_mul_fma",
            "suppress_f64_to_i32_conversion_inexact",
            "require_exact_f32_to_f64",
            "require_exact_i32_to_f64",
            "accumulate_final_f64_to_f32",
        ),
    )
    _schema_scalar_object(
        root["nan_target_evidence"],
        "$.nan_target_evidence",
        null_fields=("compiler_version", "isa_revision", "fpcr_raw", "disassembly_sha256", "probe_sha256"),
    )
    _schema_scalar_object(root["raw_syntax"], "$.raw_syntax", string_fields=("f32_regex", "f64_regex"))

    exp = _schema_object(
        root["exp32"],
        "$.exp32",
        (
            "dag_revision",
            "table_bits",
            "table_length",
            "table_index",
            "scale_expression",
            "table_exponent_shift",
            "table_raw64",
            "used_raw64",
            "unused_raw64",
            "threshold_raw32",
            "bit_constants",
            "helper_raw32",
            "dag",
        ),
    )
    for key in ("dag_revision", "table_index", "scale_expression"):
        _schema_string(exp[key], "$.exp32." + key)
    for key in ("table_bits", "table_length", "table_exponent_shift"):
        _schema_int(exp[key], "$.exp32." + key)
    for index, raw in enumerate(_schema_string_array(exp["table_raw64"], "$.exp32.table_raw64", 32)):
        parse_raw(raw, 64)
    _schema_raw_object(exp["used_raw64"], "$.exp32.used_raw64", ("invln2_scaled", "C0", "C1", "C2", "one"), 64)
    _schema_raw_object(
        exp["unused_raw64"],
        "$.exp32.unused_raw64",
        ("shift_scaled", "unscaled_C0", "unscaled_C1", "unscaled_C2", "shift"),
        64,
    )
    _schema_raw_object(
        exp["threshold_raw32"],
        "$.exp32.threshold_raw32",
        ("special_gate_88", "overflow_strict_gt", "underflow_to_zero_strict_lt", "inactive_errno"),
        32,
    )
    exp_bits = _schema_object(
        exp["bit_constants"],
        "$.exp32.bit_constants",
        ("positive_infinity", "negative_infinity", "top12_shift", "abstop_mask", "infinity_top12"),
    )
    for key in ("positive_infinity", "negative_infinity", "abstop_mask", "infinity_top12"):
        parse_raw(_schema_string(exp_bits[key], "$.exp32.bit_constants." + key), 32)
    _schema_int(exp_bits["top12_shift"], "$.exp32.bit_constants.top12_shift")
    _schema_raw_object(exp["helper_raw32"], "$.exp32.helper_raw32", ("underflow_factor", "overflow_factor"), 32)
    _schema_string_array(exp["dag"], "$.exp32.dag", 14)

    log = _schema_object(
        root["log32"],
        "$.log32",
        ("dag_revision", "table_bits", "table_length", "off_raw32", "table_raw64", "used_raw64", "unused_raw64", "bit_constants", "dag"),
    )
    _schema_string(log["dag_revision"], "$.log32.dag_revision")
    _schema_int(log["table_bits"], "$.log32.table_bits")
    _schema_int(log["table_length"], "$.log32.table_length")
    parse_raw(_schema_string(log["off_raw32"], "$.log32.off_raw32"), 32)
    log_table = _schema_array(log["table_raw64"], "$.log32.table_raw64", 16)
    for index, row_value in enumerate(log_table):
        row = _schema_array(row_value, "$.log32.table_raw64[" + str(index) + "]", 2)
        for column, raw_value in enumerate(row):
            parse_raw(_schema_string(raw_value, "$.log32.table_raw64[" + str(index) + "][" + str(column) + "]"), 64)
    _schema_raw_object(log["used_raw64"], "$.log32.used_raw64", ("ln2", "A0", "A1", "A2", "one", "negative_one"), 64)
    _schema_raw_object(log["unused_raw64"], "$.log32.unused_raw64", ("invln10",), 64)
    log_bits = _schema_object(
        log["bit_constants"],
        "$.log32.bit_constants",
        (
            "positive_zero",
            "negative_zero",
            "positive_one",
            "positive_infinity",
            "minimum_normal",
            "normal_span",
            "sign",
            "twice_nan_cutoff",
            "exponent_clear",
            "index_shift",
            "exponent_shift",
            "subnormal_scale",
            "subnormal_exponent_adjust",
        ),
    )
    for key in (
        "positive_zero",
        "negative_zero",
        "positive_one",
        "positive_infinity",
        "minimum_normal",
        "normal_span",
        "sign",
        "twice_nan_cutoff",
        "exponent_clear",
        "subnormal_scale",
        "subnormal_exponent_adjust",
    ):
        parse_raw(_schema_string(log_bits[key], "$.log32.bit_constants." + key), 32)
    for key in ("index_shift", "exponent_shift"):
        _schema_int(log_bits[key], "$.log32.bit_constants." + key)
    _schema_string_array(log["dag"], "$.log32.dag", 17)

    specials = _schema_object(root["special_results"], "$.special_results", ("exp32", "log32"))
    special_names = {
        "exp32": ("negative_infinity", "positive_infinity", "finite_overflow", "finite_underflow_to_zero"),
        "log32": ("positive_one", "positive_zero", "negative_zero", "positive_infinity"),
    }
    for operation, names in special_names.items():
        operation_object = _schema_object(specials[operation], "$.special_results." + operation, names)
        for name in names:
            result = _schema_object(operation_object[name], "$.special_results." + operation + "." + name, ("result_raw32", "flags"))
            parse_raw(_schema_string(result["result_raw32"], "$.special_results." + operation + "." + name + ".result_raw32"), 32)
            _schema_flags(result["flags"], "$.special_results." + operation + "." + name + ".flags")

    nan_policy = _schema_object(
        root["nan_policy"],
        "$.nan_policy",
        ("concrete_result_raw32", "quiet_nan_api_flags", "signaling_nan_api_flags", "negative_log_api_flags"),
    )
    _schema_string(nan_policy["concrete_result_raw32"], "$.nan_policy.concrete_result_raw32")
    for key in ("quiet_nan_api_flags", "signaling_nan_api_flags", "negative_log_api_flags"):
        _schema_flags(nan_policy[key], "$.nan_policy." + key)

    mutation = _schema_object(
        root["mutation_audit"],
        "$.mutation_audit",
        ("schema", "search_order", "difference_fields", "exp_domain", "log_domain", "outcomes", "witness_count", "gap_count"),
    )
    _schema_string(mutation["schema"], "$.mutation_audit.schema")
    _schema_string(mutation["search_order"], "$.mutation_audit.search_order")
    _schema_string_array(mutation["difference_fields"], "$.mutation_audit.difference_fields", 4)
    exp_domain = _schema_object(
        mutation["exp_domain"],
        "$.mutation_audit.exp_domain",
        ("anchors_raw32", "include_sign_bit_twin", "inclusive_radius_raw", "ordering", "filter", "raw_candidate_union_count"),
    )
    for index, raw in enumerate(_schema_string_array(exp_domain["anchors_raw32"], "$.mutation_audit.exp_domain.anchors_raw32", 9)):
        parse_raw(raw, 32)
    for key in ("include_sign_bit_twin", "inclusive_radius_raw", "raw_candidate_union_count"):
        _schema_int(exp_domain[key], "$.mutation_audit.exp_domain." + key)
    for key in ("ordering", "filter"):
        _schema_string(exp_domain[key], "$.mutation_audit.exp_domain." + key)
    log_domain = _schema_object(
        mutation["log_domain"],
        "$.mutation_audit.log_domain",
        (
            "table_base_expression",
            "table_base_inclusive_radius_raw",
            "positive_subnormal_seeds_raw32",
            "subnormal_inclusive_radius_raw",
            "ordering",
            "filter",
            "overlap_policy",
        ),
    )
    for key in ("table_base_expression", "ordering", "filter", "overlap_policy"):
        _schema_string(log_domain[key], "$.mutation_audit.log_domain." + key)
    for key in ("table_base_inclusive_radius_raw", "subnormal_inclusive_radius_raw"):
        _schema_int(log_domain[key], "$.mutation_audit.log_domain." + key)
    for raw in _schema_string_array(log_domain["positive_subnormal_seeds_raw32"], "$.mutation_audit.log_domain.positive_subnormal_seeds_raw32", 6):
        parse_raw(raw, 32)

    outcomes = _schema_array(mutation["outcomes"], "$.mutation_audit.outcomes", 7)
    expected_ids = ("M09", "M10", "M11", "M12", "M23", "M24", "M26")
    for index, outcome_value in enumerate(outcomes):
        path = "$.mutation_audit.outcomes[" + str(index) + "]"
        has_witness = expected_ids[index] != "M11"
        keys = ("mutation", "definition", "status", "candidates_examined", "witness") if has_witness else (
            "mutation",
            "definition",
            "status",
            "candidates_examined",
        )
        outcome = _schema_object(outcome_value, path, keys)
        for key in ("mutation", "definition", "status"):
            _schema_string(outcome[key], path + "." + key)
        _schema_int(outcome["candidates_examined"], path + ".candidates_examined")
        if has_witness:
            witness_keys = (
                "input_raw32",
                "comparison_stage",
                "strict_intermediate_raw64",
                "mutant_intermediate_raw64",
                "strict_intermediate_flags",
                "mutant_intermediate_flags",
                "strict_final_raw32",
                "mutant_final_raw32",
                "strict_api_flags",
                "mutant_api_flags",
                "difference_fields",
            )
            if expected_ids[index] in ("M23", "M24", "M26"):
                witness_keys = ("domain_id", *witness_keys)
            witness = _schema_object(outcome["witness"], path + ".witness", witness_keys)
            for key in ("input_raw32", "strict_final_raw32", "mutant_final_raw32"):
                parse_raw(_schema_string(witness[key], path + ".witness." + key), 32)
            for key in ("strict_intermediate_raw64", "mutant_intermediate_raw64"):
                parse_raw(_schema_string(witness[key], path + ".witness." + key), 64)
            _schema_string(witness["comparison_stage"], path + ".witness.comparison_stage")
            if "domain_id" in witness:
                _schema_string(witness["domain_id"], path + ".witness.domain_id")
            for key in ("strict_intermediate_flags", "mutant_intermediate_flags", "strict_api_flags", "mutant_api_flags"):
                _schema_flags(witness[key], path + ".witness." + key)
            _schema_string_array(witness["difference_fields"], path + ".witness.difference_fields")
    _schema_int(mutation["witness_count"], "$.mutation_audit.witness_count")
    _schema_int(mutation["gap_count"], "$.mutation_audit.gap_count")
    return root


def validate_manifest(manifest: dict[str, Any]) -> str:
    manifest = _validate_manifest_schema(manifest)
    if manifest.get("schema") != MANIFEST_SCHEMA:
        raise ManifestError("MANIFEST_SCHEMA", "unexpected manifest schema")
    if manifest.get("profile") != PROFILE:
        raise ManifestError("MANIFEST_PROFILE", "unexpected arithmetic profile")
    source = manifest.get("source")
    if not isinstance(source, dict) or source.get("commit") != SOURCE_COMMIT:
        raise ManifestError("MANIFEST_COMMIT", "unexpected optimized-routines commit")
    if manifest.get("status") != "DRAFT_BLOCKED_ON_NAN_CODEGEN_EVIDENCE":
        raise ManifestError("MANIFEST_STATUS", "NaN target evidence gate must remain blocked")
    evidence = manifest["nan_target_evidence"]
    if not evidence or not all(value is None for value in evidence.values()):
        raise ManifestError("MANIFEST_NAN_EVIDENCE", "unverified NaN evidence must remain null")
    fp_profile = manifest.get("fp_profile")
    required_fp = {
        "arithmetic_rounding": "RNE",
        "integer_rounding": "RMM_TIES_AWAY",
        "tininess_detection": "AFTER_ROUNDING",
        "flush_to_zero": 0,
        "default_nan": 0,
        "trapping": 0,
    }
    if fp_profile != required_fp:
        raise ManifestError("MANIFEST_FP_PROFILE", "arithmetic profile changed")
    required_flags = {
        "revision": "AOR_STEP_STICKY_V1",
        "accumulate_f64_add_mul_fma": 1,
        "suppress_f64_to_i32_conversion_inexact": 1,
        "require_exact_f32_to_f64": 1,
        "require_exact_i32_to_f64": 1,
        "accumulate_final_f64_to_f32": 1,
    }
    if manifest.get("flags_profile") != required_flags:
        raise ManifestError("MANIFEST_FLAGS_PROFILE", "sticky exception profile changed")
    exp = manifest.get("exp32")
    log = manifest.get("log32")
    if exp.get("dag_revision") != "AOR_SCALAR_EXPF_FMA_RNE_V1":
        raise ManifestError("MANIFEST_EXP_DAG", "EXP DAG revision changed")
    if log.get("dag_revision") != "AOR_SCALAR_LOGF_FMA_RNE_V1":
        raise ManifestError("MANIFEST_LOG_DAG", "LOG DAG revision changed")
    if len(exp.get("table_raw64", ())) != 32 or len(log.get("table_raw64", ())) != 16:
        raise ManifestError("MANIFEST_TABLE_LENGTH", "table length changed")
    mutation_audit = manifest.get("mutation_audit")
    if mutation_audit.get("schema") != MUTATION_SCHEMA:
        raise ManifestError("MANIFEST_MUTATION_SCHEMA", "mutation audit schema changed")
    if mutation_audit.get("witness_count") != 6 or mutation_audit.get("gap_count") != 1:
        raise ManifestError("MANIFEST_MUTATION_COUNTS", "mutation witness or GAP count changed")
    outcomes = mutation_audit.get("outcomes")
    if [entry.get("mutation") for entry in outcomes] != [
        "M09",
        "M10",
        "M11",
        "M12",
        "M23",
        "M24",
        "M26",
    ]:
        raise ManifestError("MANIFEST_MUTATION_ORDER", "mutation audit order changed")
    digest = sha256_bytes(canonical_bytes(manifest))
    if digest != EXPECTED_MANIFEST_SHA256:
        raise ManifestError("MANIFEST_CONTENT_SHA", "manifest content does not match the frozen profile")
    return digest


class TraceBuilder:
    def __init__(self) -> None:
        self.records: list[dict[str, Any]] = []

    def add(
        self,
        step: str,
        raw: int | None = None,
        bits: int | None = None,
        step_flags: Iterable[str] = (),
        **details: Any,
    ) -> None:
        record: dict[str, Any] = {"step": step, "step_flags": list(ordered_flags(step_flags))}
        if raw is not None:
            if bits is None:
                raise OracleError("TRACE_WIDTH", "trace raw value lacks a width")
            record["raw"] = raw_text(raw, bits)
        for key in sorted(details):
            record[key] = details[key]
        self.records.append(record)


def _nan_rejection(operation: str, raw: int, value: Decoded) -> NanEvidenceError:
    flags = () if value.quiet else ("NV",)
    return NanEvidenceError(
        "NAN_RAW_EVIDENCE_REQUIRED",
        operation + " target NaN raw is unavailable for " + raw_text(raw, 32),
        flags,
    )


class AorOracle:
    def __init__(self, manifest: dict[str, Any]) -> None:
        self.manifest_sha256 = validate_manifest(manifest)
        self.manifest = manifest
        self.exp = manifest["exp32"]
        self.log = manifest["log32"]

    def _exp64(self, name: str) -> int:
        return parse_raw(self.exp["used_raw64"][name], 64)

    def _log64(self, name: str) -> int:
        return parse_raw(self.log["used_raw64"][name], 64)

    def exp32(self, input_raw: int) -> AorResult:
        ix = u32(input_raw)
        value = decode_f32(ix)
        trace = TraceBuilder()
        trace.add("classify", ix, 32, kind=value.kind, sign=value.sign)
        if value.kind == "nan":
            raise _nan_rejection("exp32", ix, value)
        if value.kind == "infinity":
            if value.sign:
                trace.add("negative_infinity", 0, 32)
                return AorResult(0, (), tuple(trace.records))
            trace.add("positive_infinity", 0x7F800000, 32)
            return AorResult(0x7F800000, (), tuple(trace.records))

        gate = parse_raw(self.exp["threshold_raw32"]["special_gate_88"], 32)
        overflow_threshold = parse_raw(self.exp["threshold_raw32"]["overflow_strict_gt"], 32)
        underflow_threshold = parse_raw(self.exp["threshold_raw32"]["underflow_to_zero_strict_lt"], 32)
        abstop = (ix >> 20) & 0x7FF
        gate_top = (gate >> 20) & 0x7FF
        if abstop >= gate_top:
            if compare_finite(value, decode_f32(overflow_threshold)) > 0:
                trace.add("finite_overflow_helper", 0x7F800000, 32, ("OF", "NX"))
                return AorResult(0x7F800000, ("OF", "NX"), tuple(trace.records))
            if compare_finite(value, decode_f32(underflow_threshold)) < 0:
                trace.add("finite_underflow_helper", 0, 32, ("UF", "NX"))
                return AorResult(0, ("UF", "NX"), tuple(trace.records))

        accumulated: tuple[str, ...] = ()
        xd = f32_to_f64_exact(ix)
        trace.add("xd", xd.raw, 64, xd.flags)
        z = f64_mul(self._exp64("invln2_scaled"), xd.raw)
        accumulated = merge_flags(accumulated, z.flags)
        trace.add("z", z.raw, 64, z.flags)
        kd = f64_round_integral_rmm(z.raw)
        trace.add("kd", kd.raw, 64, (), discarded=kd.discarded)
        k_result = f64_to_i32_rmm(z.raw)
        if "NV" in k_result.flags:
            raise OracleError("EXP_K_RANGE", "EXP range reduction integer is outside i32")
        trace.add(
            "k",
            step_flags=k_result.flags,
            value=k_result.value,
            discarded=k_result.discarded,
            source="z",
            source_raw=raw_text(z.raw, 64),
        )
        r = f64_sub(z.raw, kd.raw)
        accumulated = merge_flags(accumulated, r.flags)
        trace.add("r", r.raw, 64, r.flags)

        index = u64(k_result.value) & 31
        shift_term = u64(u64(k_result.value) << int(self.exp["table_exponent_shift"]))
        table_raw = parse_raw(self.exp["table_raw64"][index], 64)
        scale_raw = u64(table_raw + shift_term)
        scale_value = decode_f64(scale_raw)
        if scale_value.kind not in ("zero", "finite"):
            raise OracleError("EXP_SCALE_NONFINITE", "EXP scale construction produced a non-finite operand")
        trace.add("scale", scale_raw, 64, (), index=index, shift_term=raw_text(shift_term, 64))

        p01 = f64_fma(self._exp64("C0"), r.raw, self._exp64("C1"))
        accumulated = merge_flags(accumulated, p01.flags)
        trace.add("p01", p01.raw, 64, p01.flags)
        r2 = f64_mul(r.raw, r.raw)
        accumulated = merge_flags(accumulated, r2.flags)
        trace.add("r2", r2.raw, 64, r2.flags)
        p2 = f64_fma(self._exp64("C2"), r.raw, self._exp64("one"))
        accumulated = merge_flags(accumulated, p2.flags)
        trace.add("p2", p2.raw, 64, p2.flags)
        p = f64_fma(p01.raw, r2.raw, p2.raw)
        accumulated = merge_flags(accumulated, p.flags)
        trace.add("p", p.raw, 64, p.flags)
        y = f64_mul(p.raw, scale_raw)
        accumulated = merge_flags(accumulated, y.flags)
        trace.add("y", y.raw, 64, y.flags)
        output = f64_to_f32(y.raw)
        accumulated = merge_flags(accumulated, output.flags)
        trace.add("out", output.raw, 32, output.flags)
        return AorResult(output.raw, accumulated, tuple(trace.records))

    def log32(self, input_raw: int) -> AorResult:
        ix = u32(input_raw)
        value = decode_f32(ix)
        trace = TraceBuilder()
        trace.add("classify", ix, 32, kind=value.kind, sign=value.sign)
        if ix == 0x3F800000:
            trace.add("positive_one", 0, 32)
            return AorResult(0, (), tuple(trace.records))

        if u32(ix - 0x00800000) >= 0x7F000000:
            if u32(ix * 2) == 0:
                trace.add("divide_by_zero_helper", 0xFF800000, 32, ("DZ",))
                return AorResult(0xFF800000, ("DZ",), tuple(trace.records))
            if ix == 0x7F800000:
                trace.add("positive_infinity", 0x7F800000, 32)
                return AorResult(0x7F800000, (), tuple(trace.records))
            if value.kind == "nan":
                raise _nan_rejection("log32", ix, value)
            if value.sign:
                raise NanEvidenceError(
                    "NAN_RAW_EVIDENCE_REQUIRED",
                    "log32 negative-domain target NaN raw is unavailable for " + raw_text(ix, 32),
                    ("NV",),
                )
            if value.kind != "finite" or value.magnitude == 0:
                raise OracleError("LOG_CLASSIFY", "unexpected LOG special classification")

            magnitude = value.fraction
            leading = magnitude.bit_length() - 1
            scaled_exponent = leading + 1
            scaled_fraction = (magnitude << (23 - leading)) & 0x7FFFFF
            scaled_raw = (scaled_exponent << 23) | scaled_fraction
            ix = u32(scaled_raw - (23 << 23))
            trace.add(
                "subnormal_normalize",
                ix,
                32,
                (),
                leading_one=leading,
                scaled_raw=raw_text(scaled_raw, 32),
            )

        tmp = u32(ix - parse_raw(self.log["off_raw32"], 32))
        index = (tmp >> 19) & 15
        k = asr32(tmp, 23)
        exponent_clear = parse_raw(self.log["bit_constants"]["exponent_clear"], 32)
        iz = u32(ix - (tmp & exponent_clear))
        trace.add("range_reduce_bits", iz, 32, (), index=index, k=k, tmp=raw_text(tmp, 32))

        accumulated: tuple[str, ...] = ()
        z = f32_to_f64_exact(iz)
        trace.add("z", z.raw, 64, z.flags)
        invc = parse_raw(self.log["table_raw64"][index][0], 64)
        logc = parse_raw(self.log["table_raw64"][index][1], 64)
        r = f64_fma(z.raw, invc, self._log64("negative_one"))
        accumulated = merge_flags(accumulated, r.flags)
        trace.add("r", r.raw, 64, r.flags)
        k64 = i32_to_f64(k)
        trace.add("k64", k64.raw, 64, k64.flags)
        y0 = f64_fma(k64.raw, self._log64("ln2"), logc)
        accumulated = merge_flags(accumulated, y0.flags)
        trace.add("y0", y0.raw, 64, y0.flags)
        r2 = f64_mul(r.raw, r.raw)
        accumulated = merge_flags(accumulated, r2.flags)
        trace.add("r2", r2.raw, 64, r2.flags)
        q0 = f64_fma(self._log64("A1"), r.raw, self._log64("A2"))
        accumulated = merge_flags(accumulated, q0.flags)
        trace.add("q0", q0.raw, 64, q0.flags)
        q1 = f64_fma(self._log64("A0"), r2.raw, q0.raw)
        accumulated = merge_flags(accumulated, q1.flags)
        trace.add("q1", q1.raw, 64, q1.flags)
        tail = f64_add(y0.raw, r.raw)
        accumulated = merge_flags(accumulated, tail.flags)
        trace.add("tail", tail.raw, 64, tail.flags)
        y = f64_fma(q1.raw, r2.raw, tail.raw)
        accumulated = merge_flags(accumulated, y.flags)
        trace.add("y", y.raw, 64, y.flags)
        output = f64_to_f32(y.raw)
        accumulated = merge_flags(accumulated, output.flags)
        trace.add("out", output.raw, 32, output.flags)
        return AorResult(output.raw, accumulated, tuple(trace.records))

    def exp_input_for_k(self, k: int) -> int:
        """Construct a deterministic F32 recipe near k*ln(2)/32 without host arithmetic."""

        k64 = i32_to_f64(k)
        product = f64_mul(k64.raw, self._log64("ln2"))
        value = decode_f64(product.raw)
        scaled = pack_f64(value.sign, value.magnitude, value.exponent - 5)
        result = f64_to_f32(scaled.raw)
        actual = self.exp32(result.raw)
        index_steps = [entry for entry in actual.trace if entry["step"] == "scale"]
        if len(index_steps) != 1 or index_steps[0]["index"] != (u64(k) & 31):
            raise OracleError("EXP_K_RECIPE", "constructed EXP input did not select requested table index")
        return result.raw

    @staticmethod
    def _entry(result: AorResult, step: str) -> dict[str, Any]:
        matches = [entry for entry in result.trace if entry["step"] == step]
        if len(matches) != 1:
            raise OracleError("MUTATION_TRACE", "strict trace does not contain exactly one " + step)
        return matches[0]

    @staticmethod
    def _raw_from_entry(result: AorResult, step: str, bits: int) -> int:
        entry = AorOracle._entry(result, step)
        return parse_raw(entry["raw"], bits)

    @staticmethod
    def _flags_before(result: AorResult, stop_step: str) -> tuple[str, ...]:
        accumulated: tuple[str, ...] = ()
        for entry in result.trace:
            if entry["step"] == stop_step:
                break
            accumulated = merge_flags(accumulated, entry["step_flags"])
        return accumulated

    @staticmethod
    def _mutation_record(
        mutation: str,
        input_raw: int,
        stage: str,
        strict_stage_raw: int,
        strict_stage_flags: Iterable[str],
        mutant_stage_raw: int,
        mutant_stage_flags: Iterable[str],
        strict_result: AorResult,
        mutant_final: RawResult,
        mutant_api_flags: Iterable[str],
    ) -> dict[str, Any]:
        strict_stage_flag_list = list(ordered_flags(strict_stage_flags))
        mutant_stage_flag_list = list(ordered_flags(mutant_stage_flags))
        mutant_api_flag_list = list(ordered_flags(mutant_api_flags))
        differences: list[str] = []
        if strict_stage_raw != mutant_stage_raw:
            differences.append("intermediate_raw64")
        if strict_stage_flag_list != mutant_stage_flag_list:
            differences.append("intermediate_flags")
        if strict_result.raw != mutant_final.raw:
            differences.append("final_raw32")
        if list(strict_result.api_flags) != mutant_api_flag_list:
            differences.append("api_flags")
        return {
            "mutation": mutation,
            "input_raw32": raw_text(input_raw, 32),
            "comparison_stage": stage,
            "strict_intermediate_raw64": raw_text(strict_stage_raw, 64),
            "mutant_intermediate_raw64": raw_text(mutant_stage_raw, 64),
            "strict_intermediate_flags": strict_stage_flag_list,
            "mutant_intermediate_flags": mutant_stage_flag_list,
            "strict_final_raw32": raw_text(strict_result.raw, 32),
            "mutant_final_raw32": raw_text(mutant_final.raw, 32),
            "strict_api_flags": list(strict_result.api_flags),
            "mutant_api_flags": mutant_api_flag_list,
            "difference_fields": differences,
        }

    def exp_mutation_probe(self, input_raw: int, mutation: str) -> dict[str, Any] | None:
        if mutation not in ("M09", "M10", "M11", "M12"):
            raise OracleError("MUTATION_ID", "unsupported EXP mutation")
        strict = self.exp32(input_raw)
        steps = {entry["step"] for entry in strict.trace}
        if "scale" not in steps:
            return None
        r = self._raw_from_entry(strict, "r", 64)
        scale = self._raw_from_entry(strict, "scale", 64)
        c0 = self._exp64("C0")
        c1 = self._exp64("C1")
        c2 = self._exp64("C2")
        one = self._exp64("one")

        if mutation == "M09":
            strict_stage = self._entry(strict, "p01")
            prefix = self._flags_before(strict, "p01")
            split_mul = f64_mul(c0, r)
            mutant_stage = f64_add(split_mul.raw, c1)
            stage_flags = merge_flags(split_mul.flags, mutant_stage.flags)
            accumulated = merge_flags(prefix, stage_flags)
            r2 = f64_mul(r, r)
            p2 = f64_fma(c2, r, one)
            p = f64_fma(mutant_stage.raw, r2.raw, p2.raw)
            accumulated = merge_flags(accumulated, r2.flags, p2.flags, p.flags)
            stage_name = "p01"
        elif mutation == "M10":
            strict_stage = self._entry(strict, "p2")
            prefix = self._flags_before(strict, "p2")
            p01 = RawResult(self._raw_from_entry(strict, "p01", 64), tuple(self._entry(strict, "p01")["step_flags"]))
            r2 = RawResult(self._raw_from_entry(strict, "r2", 64), tuple(self._entry(strict, "r2")["step_flags"]))
            split_mul = f64_mul(c2, r)
            mutant_stage = f64_add(split_mul.raw, one)
            stage_flags = merge_flags(split_mul.flags, mutant_stage.flags)
            p = f64_fma(p01.raw, r2.raw, mutant_stage.raw)
            accumulated = merge_flags(prefix, stage_flags, p.flags)
            stage_name = "p2"
        elif mutation == "M11":
            strict_stage = self._entry(strict, "p")
            prefix = self._flags_before(strict, "p")
            p01 = self._raw_from_entry(strict, "p01", 64)
            r2 = self._raw_from_entry(strict, "r2", 64)
            p2 = self._raw_from_entry(strict, "p2", 64)
            split_mul = f64_mul(p01, r2)
            mutant_stage = f64_add(split_mul.raw, p2)
            stage_flags = merge_flags(split_mul.flags, mutant_stage.flags)
            p = mutant_stage
            accumulated = merge_flags(prefix, stage_flags)
            stage_name = "p"
        else:
            strict_stage = self._entry(strict, "p")
            prefix = self._flags_before(strict, "p01")
            h1 = f64_fma(c0, r, c1)
            h2 = f64_fma(h1.raw, r, c2)
            mutant_stage = f64_fma(h2.raw, r, one)
            stage_flags = merge_flags(h1.flags, h2.flags, mutant_stage.flags)
            p = mutant_stage
            accumulated = merge_flags(prefix, stage_flags)
            stage_name = "p"

        y = f64_mul(p.raw, scale)
        output = f64_to_f32(y.raw)
        accumulated = merge_flags(accumulated, y.flags, output.flags)
        record = self._mutation_record(
            mutation,
            input_raw,
            stage_name,
            parse_raw(strict_stage["raw"], 64),
            strict_stage["step_flags"],
            mutant_stage.raw,
            stage_flags,
            strict,
            output,
            accumulated,
        )
        return record if record["difference_fields"] else None

    def log_mutation_probe(self, input_raw: int, mutation: str) -> dict[str, Any] | None:
        if mutation not in ("M23", "M24", "M26"):
            raise OracleError("MUTATION_ID", "unsupported LOG mutation")
        strict = self.log32(input_raw)
        steps = {entry["step"] for entry in strict.trace}
        if "range_reduce_bits" not in steps:
            return None
        bits = self._entry(strict, "range_reduce_bits")
        index = int(bits["index"])
        z = self._raw_from_entry(strict, "z", 64)
        r_strict = self._raw_from_entry(strict, "r", 64)
        k64 = self._raw_from_entry(strict, "k64", 64)
        invc = parse_raw(self.log["table_raw64"][index][0], 64)
        logc = parse_raw(self.log["table_raw64"][index][1], 64)

        if mutation == "M23":
            strict_stage = self._entry(strict, "r")
            prefix = self._flags_before(strict, "r")
            split_mul = f64_mul(z, invc)
            mutant_stage = f64_add(split_mul.raw, self._log64("negative_one"))
            stage_flags = merge_flags(split_mul.flags, mutant_stage.flags)
            accumulated = merge_flags(prefix, stage_flags)
            r = mutant_stage.raw
            y0 = f64_fma(k64, self._log64("ln2"), logc)
            r2 = f64_mul(r, r)
            q0 = f64_fma(self._log64("A1"), r, self._log64("A2"))
            q1 = f64_fma(self._log64("A0"), r2.raw, q0.raw)
            tail = f64_add(y0.raw, r)
            y = f64_fma(q1.raw, r2.raw, tail.raw)
            accumulated = merge_flags(accumulated, y0.flags, r2.flags, q0.flags, q1.flags, tail.flags, y.flags)
            stage_name = "r"
        elif mutation == "M24":
            strict_stage = self._entry(strict, "y0")
            prefix = self._flags_before(strict, "y0")
            split_mul = f64_mul(k64, self._log64("ln2"))
            mutant_stage = f64_add(split_mul.raw, logc)
            stage_flags = merge_flags(split_mul.flags, mutant_stage.flags)
            accumulated = merge_flags(prefix, stage_flags)
            r = r_strict
            r2 = f64_mul(r, r)
            q0 = f64_fma(self._log64("A1"), r, self._log64("A2"))
            q1 = f64_fma(self._log64("A0"), r2.raw, q0.raw)
            tail = f64_add(mutant_stage.raw, r)
            y = f64_fma(q1.raw, r2.raw, tail.raw)
            accumulated = merge_flags(accumulated, r2.flags, q0.flags, q1.flags, tail.flags, y.flags)
            stage_name = "y0"
        else:
            strict_stage = self._entry(strict, "y")
            prefix = self._flags_before(strict, "tail")
            y0 = self._raw_from_entry(strict, "y0", 64)
            r2 = self._raw_from_entry(strict, "r2", 64)
            q1 = self._raw_from_entry(strict, "q1", 64)
            u = f64_fma(q1, r2, y0)
            mutant_stage = f64_add(u.raw, r_strict)
            stage_flags = merge_flags(u.flags, mutant_stage.flags)
            y = mutant_stage
            accumulated = merge_flags(prefix, stage_flags)
            stage_name = "y"

        output = f64_to_f32(y.raw)
        accumulated = merge_flags(accumulated, output.flags)
        record = self._mutation_record(
            mutation,
            input_raw,
            stage_name,
            parse_raw(strict_stage["raw"], 64),
            strict_stage["step_flags"],
            mutant_stage.raw,
            stage_flags,
            strict,
            output,
            accumulated,
        )
        return record if record["difference_fields"] else None


def trace_sha256(trace: Sequence[dict[str, Any]]) -> str:
    return sha256_bytes(canonical_bytes(list(trace)))


EXP_MUTATION_DEFINITIONS = {
    "M09": "p01: FMA(C0,r,C1) -> ADD(MUL(C0,r),C1)",
    "M10": "p2: FMA(C2,r,ONE) -> ADD(MUL(C2,r),ONE)",
    "M11": "p: FMA(p01,r2,p2) -> ADD(MUL(p01,r2),p2)",
    "M12": "polynomial: strict parallel tree -> Horner FMA(FMA(FMA(C0,r,C1),r,C2),r,ONE)",
}

LOG_MUTATION_DEFINITIONS = {
    "M23": "r: FMA(z,invc,NEG_ONE) -> ADD(MUL(z,invc),NEG_ONE)",
    "M24": "y0: FMA(k64,LN2,logc) -> ADD(MUL(k64,LN2),logc)",
    "M26": "tail/final: FMA(q1,r2,ADD(y0,r)) -> ADD(FMA(q1,r2,y0),r)",
}

EXP_SEARCH_ANCHORS = (
    0x00800000,
    0x3A800000,
    0x3E800000,
    0x3F000000,
    0x3F800000,
    0x40000000,
    0x41000000,
    0x42B00000,
    0x42B17217,
)
LOG_SUBNORMAL_SEEDS = (0x00000001, 0x00000002, 0x00000003, 0x003FFFFF, 0x00400000, 0x007FFFFF)


def _exp_search_candidates() -> list[int]:
    candidates: set[int] = set()
    for anchor in EXP_SEARCH_ANCHORS:
        for center in (anchor, anchor ^ 0x80000000):
            lower = max(0, center - 2048)
            upper = min(U32_MASK, center + 2048)
            candidates.update(range(lower, upper + 1))
    return sorted(candidates)


def _log_search_domains() -> list[tuple[str, list[int]]]:
    domains: list[tuple[str, list[int]]] = []
    for index in range(16):
        base = u32(0x3F330000 + (index << 19))
        lower = max(1, base - 2048)
        upper = min(0x7F7FFFFF, base + 2048)
        domains.append(("table-base-" + format(index, "02d"), list(range(lower, upper + 1))))
    for seed_index, seed in enumerate(LOG_SUBNORMAL_SEEDS):
        lower = max(1, seed - 64)
        upper = min(0x007FFFFF, seed + 64)
        domains.append(("subnormal-seed-" + format(seed_index, "02d"), list(range(lower, upper + 1))))
    return domains


def audit_mutations(oracle: AorOracle) -> dict[str, Any]:
    exp_candidates = _exp_search_candidates()
    log_domains = _log_search_domains()
    results: list[dict[str, Any]] = []

    for mutation, definition in EXP_MUTATION_DEFINITIONS.items():
        examined = 0
        witness: dict[str, Any] | None = None
        for raw in exp_candidates:
            value = decode_f32(raw)
            if value.kind not in ("zero", "finite"):
                continue
            strict = oracle.exp32(raw)
            if "scale" not in {entry["step"] for entry in strict.trace}:
                continue
            examined += 1
            witness = oracle.exp_mutation_probe(raw, mutation)
            if witness is not None:
                break
        entry: dict[str, Any] = {
            "mutation": mutation,
            "operation": "exp32",
            "definition": definition,
            "status": "WITNESS" if witness is not None else "GAP_NO_WITNESS_IN_BOUNDED_DOMAIN",
            "candidates_examined": examined,
        }
        if witness is not None:
            entry["witness"] = witness
        results.append(entry)

    for mutation, definition in LOG_MUTATION_DEFINITIONS.items():
        examined = 0
        witness = None
        witness_domain: str | None = None
        for domain_id, candidates in log_domains:
            for raw in candidates:
                value = decode_f32(raw)
                if value.kind != "finite" or value.sign or value.magnitude == 0:
                    continue
                examined += 1
                witness = oracle.log_mutation_probe(raw, mutation)
                if witness is not None:
                    witness_domain = domain_id
                    break
            if witness is not None:
                break
        entry = {
            "mutation": mutation,
            "operation": "log32",
            "definition": definition,
            "status": "WITNESS" if witness is not None else "GAP_NO_WITNESS_IN_BOUNDED_DOMAIN",
            "candidates_examined": examined,
        }
        if witness is not None:
            witness["domain_id"] = witness_domain
            entry["witness"] = witness
        results.append(entry)

    witness_count = sum(1 for entry in results if entry["status"] == "WITNESS")
    gap_count = len(results) - witness_count
    audit = {
        "schema": MUTATION_SCHEMA,
        "profile": PROFILE,
        "flags_profile": "AOR_STEP_STICKY_V1",
        "manifest_sha256": oracle.manifest_sha256,
        "generator_sha256": generator_sha256(),
        "search_order": "first difference in the frozen stable domain order",
        "exp_domain": {
            "anchors_raw32": [raw_text(raw, 32) for raw in EXP_SEARCH_ANCHORS],
            "include_sign_bit_twin": 1,
            "inclusive_radius_raw": 2048,
            "ordering": "raw32 ascending after union and deduplication",
            "filter": "finite and normal-DAG path only",
            "raw_candidate_union_count": len(exp_candidates),
        },
        "log_domain": {
            "table_base_expression": "u32(0x3f330000+(index<<19)), index=0..15",
            "table_base_inclusive_radius_raw": 2048,
            "positive_subnormal_seeds_raw32": [raw_text(raw, 32) for raw in LOG_SUBNORMAL_SEEDS],
            "subnormal_inclusive_radius_raw": 64,
            "ordering": "domain_id order shown by table index then seed index, raw32 ascending within each domain",
            "filter": "positive finite nonzero",
            "overlap_policy": "retain candidates in each distinct domain_id",
        },
        "mutations": results,
        "witness_count": witness_count,
        "gap_count": gap_count,
    }
    expected = oracle.manifest["mutation_audit"]
    for key in ("schema", "search_order", "exp_domain", "log_domain", "witness_count", "gap_count"):
        if audit[key] != expected[key]:
            raise OracleError("MUTATION_MANIFEST_MISMATCH", "mutation audit mismatch: " + key)
    expected_outcomes = {entry["mutation"]: entry for entry in expected["outcomes"]}
    for actual in results:
        frozen = expected_outcomes.get(actual["mutation"])
        if frozen is None:
            raise OracleError("MUTATION_MANIFEST_MISMATCH", "missing frozen mutation outcome")
        for key in ("definition", "status", "candidates_examined"):
            if actual[key] != frozen[key]:
                raise OracleError("MUTATION_MANIFEST_MISMATCH", actual["mutation"] + " mismatch: " + key)
        if actual["status"] == "WITNESS":
            for key, value in frozen["witness"].items():
                if actual["witness"].get(key) != value:
                    raise OracleError("MUTATION_MANIFEST_MISMATCH", actual["mutation"] + " witness mismatch: " + key)
    return audit


def emit_mutation_audit(output: Path, oracle: AorOracle) -> tuple[int, int, str]:
    output = output.resolve()
    if not _path_inside_repo(output):
        raise OracleError("OUTPUT_SCOPE", "mutation audit output must stay inside the project directory")
    audit = audit_mutations(oracle)
    payload = canonical_bytes(audit) + b"\n"
    TMP_BUILD.mkdir(parents=True, exist_ok=True)
    output.parent.mkdir(parents=True, exist_ok=True)
    temporary = TMP_BUILD.joinpath("audit-" + output.name + ".tmp")
    temporary.write_bytes(payload)
    os.replace(temporary, output)
    return int(audit["witness_count"]), int(audit["gap_count"]), sha256_bytes(payload)


def _qualified_case_recipes(oracle: AorOracle) -> list[dict[str, Any]]:
    recipes: list[dict[str, Any]] = []

    def add(case_id: str, operation: str, raw: int, recipe: str) -> None:
        recipes.append(
            {
                "case_id": case_id,
                "op": operation,
                "input_raw": raw_text(raw, 32),
                "recipe": recipe,
            }
        )

    add("exp-pos-zero", "exp32", 0x00000000, "fixed non-NaN special")
    add("exp-neg-zero", "exp32", 0x80000000, "fixed signed-zero input")
    add("exp-pos-inf", "exp32", 0x7F800000, "fixed non-NaN special")
    add("exp-neg-inf", "exp32", 0xFF800000, "fixed non-NaN special")
    add("exp-pos-min-subnormal", "exp32", 0x00000001, "fixed smallest positive input")
    add("exp-neg-min-subnormal", "exp32", 0x80000001, "fixed smallest negative input")
    for name, raw in (
        ("gate-below", 0x42AFFFFF),
        ("gate-equal", 0x42B00000),
        ("overflow-below", 0x42B17216),
        ("overflow-equal", 0x42B17217),
        ("overflow-above", 0x42B17218),
        ("underflow-above", 0xC2CFF1B3),
        ("underflow-equal", 0xC2CFF1B4),
        ("underflow-below", 0xC2CFF1B5),
    ):
        add("exp-" + name, "exp32", raw, "frozen threshold or adjacent raw")
    for k in (-33, -32, -1, 0, 31, 32, 33):
        add("exp-k-boundary-" + str(k).replace("-", "m"), "exp32", oracle.exp_input_for_k(k), "integer recipe k*ln2/32")
    for k in range(32):
        add("exp-table-index-" + format(k, "02d"), "exp32", oracle.exp_input_for_k(k), "integer recipe selecting table index")

    add("log-pos-one", "log32", 0x3F800000, "fixed non-NaN special")
    add("log-pos-zero", "log32", 0x00000000, "fixed non-NaN special")
    add("log-neg-zero", "log32", 0x80000000, "fixed non-NaN special")
    add("log-pos-inf", "log32", 0x7F800000, "fixed non-NaN special")
    add("log-one-below", "log32", 0x3F7FFFFF, "positive-one adjacent raw")
    add("log-one-above", "log32", 0x3F800001, "positive-one adjacent raw")
    add("log-min-subnormal", "log32", 0x00000001, "minimum positive subnormal")
    add("log-max-subnormal", "log32", 0x007FFFFF, "maximum positive subnormal")
    add("log-min-normal", "log32", 0x00800000, "minimum positive normal")
    add("log-max-finite", "log32", 0x7F7FFFFF, "maximum positive finite")
    off = 0x3F330000
    for index in range(16):
        add("log-table-index-" + format(index, "02d"), "log32", u32(off + (index << 19)), "OFF plus index field")
    for leading in range(23):
        add("log-subnormal-leading-" + format(leading, "02d"), "log32", 1 << leading, "positive subnormal with fixed leading-one position")

    for case_id, operation, raw, flags in (
        ("reject-exp-qnan", "exp32", 0x7FC00001, ()),
        ("reject-exp-snan", "exp32", 0x7F800001, ("NV",)),
        ("reject-log-qnan", "log32", 0x7FC00001, ()),
        ("reject-log-snan", "log32", 0x7F800001, ("NV",)),
        ("reject-log-negative-one", "log32", 0xBF800000, ("NV",)),
        ("reject-log-negative-infinity", "log32", 0xFF800000, ("NV",)),
    ):
        recipes.append(
            {
                "case_id": case_id,
                "op": operation,
                "input_raw": raw_text(raw, 32),
                "recipe": "target NaN raw blocked until compiler/ISA/FPCR evidence exists",
                "expected_error": "NAN_RAW_EVIDENCE_REQUIRED",
                "expected_flags": list(flags),
            }
        )
    return recipes


def _require_full_special_evidence(manifest: dict[str, Any]) -> None:
    evidence = manifest["nan_target_evidence"]
    if type(evidence) is not dict:
        raise ManifestError("SCHEMA_OBJECT", "$.nan_target_evidence must be an object")
    if all(value is None for value in evidence.values()):
        raise NanEvidenceError(
            "NAN_RAW_EVIDENCE_REQUIRED",
            "full-special vectors require compiler, ISA, FPCR, disassembly and probe evidence",
        )


def build_vector_records(oracle: AorOracle, vector_profile: str) -> list[dict[str, Any]]:
    if vector_profile == "full-special":
        _require_full_special_evidence(oracle.manifest)
    if vector_profile != "qualified":
        raise OracleError("VECTOR_PROFILE", "unsupported vector profile")
    generator_digest = generator_sha256()
    bindings = {
        "manifest_sha256": oracle.manifest_sha256,
        "generator_sha256": generator_digest,
        "profile": PROFILE,
        "source_commit": SOURCE_COMMIT,
    }
    records: list[dict[str, Any]] = []
    for recipe in _qualified_case_recipes(oracle):
        record = {"kind": "case", **bindings, **recipe}
        operation = recipe["op"]
        raw = parse_raw(recipe["input_raw"], 32)
        if "expected_error" in recipe:
            try:
                oracle.exp32(raw) if operation == "exp32" else oracle.log32(raw)
            except OracleError as error:
                if error.code != recipe["expected_error"] or list(error.flags) != recipe["expected_flags"]:
                    raise OracleError("REJECTION_MISMATCH", "blocked vector produced the wrong error") from error
            else:
                raise OracleError("REJECTION_MISSING", "blocked vector unexpectedly produced a raw result")
        else:
            result = oracle.exp32(raw) if operation == "exp32" else oracle.log32(raw)
            record["expected_raw"] = raw_text(result.raw, 32)
            record["expected_flags"] = list(result.api_flags)
            record["trace_sha256"] = trace_sha256(result.trace)
        records.append(record)
    return records


def _path_inside_repo(path: Path) -> bool:
    try:
        path.resolve().relative_to(REPO_ROOT)
    except ValueError:
        return False
    return True


def emit_vectors(output: Path, oracle: AorOracle, vector_profile: str) -> tuple[int, str]:
    output = output.resolve()
    if not _path_inside_repo(output):
        raise OracleError("OUTPUT_SCOPE", "vector output must stay inside the project directory")
    records = build_vector_records(oracle, vector_profile)
    payload = _vector_payload(oracle, records, vector_profile)
    TMP_BUILD.mkdir(parents=True, exist_ok=True)
    output.parent.mkdir(parents=True, exist_ok=True)
    temporary = TMP_BUILD.joinpath("emit-" + output.name + ".tmp")
    temporary.write_bytes(payload)
    os.replace(temporary, output)
    return len(records), sha256_bytes(payload)


def _vector_metadata(oracle: AorOracle, records: Sequence[dict[str, Any]], vector_profile: str) -> dict[str, Any]:
    return {
        "kind": "metadata",
        "schema": VECTOR_SCHEMA,
        "vector_profile": vector_profile,
        "vector_count": len(records),
        "manifest_sha256": oracle.manifest_sha256,
        "generator_sha256": generator_sha256(),
        "profile": PROFILE,
        "source_commit": SOURCE_COMMIT,
    }


def _vector_payload(oracle: AorOracle, records: Sequence[dict[str, Any]], vector_profile: str) -> bytes:
    metadata = _vector_metadata(oracle, records, vector_profile)
    return b"\n".join(canonical_bytes(record) for record in [metadata, *records]) + b"\n"


def _load_jsonl(path: Path) -> tuple[list[dict[str, Any]], bytes]:
    try:
        payload = path.read_bytes()
        text = payload.decode("utf-8")
    except (OSError, UnicodeError) as error:
        raise OracleError("VECTOR_READ", str(error)) from error
    lines = text.splitlines()
    records: list[dict[str, Any]] = []
    for line_number, line in enumerate(lines, 1):
        if not line:
            raise OracleError("VECTOR_EMPTY_LINE", "empty JSONL line at " + str(line_number))
        try:
            record = json.loads(
                line,
                object_pairs_hook=_duplicate_checked_object,
                parse_float=_reject_json_real,
                parse_constant=_reject_json_constant,
            )
        except OracleError:
            raise
        except (json.JSONDecodeError, UnicodeError) as error:
            raise OracleError("VECTOR_JSON", str(error)) from error
        if type(record) is not dict or canonical_bytes(record).decode("utf-8") != line:
            raise OracleError("VECTOR_CANONICAL", "JSONL record is not canonical at line " + str(line_number))
        records.append(record)
    return records, payload


def _validate_vector_records_schema(records: Any) -> list[dict[str, Any]]:
    array = _schema_array(records, "$vectors")
    if len(array) != 109:
        raise OracleError("VECTOR_EXACT_COUNT", "vector file must contain one metadata record and exactly 108 cases")
    metadata = _schema_object(
        array[0],
        "$vectors[0]",
        ("kind", "schema", "vector_profile", "vector_count", "manifest_sha256", "generator_sha256", "profile", "source_commit"),
    )
    for key in ("kind", "schema", "vector_profile", "manifest_sha256", "generator_sha256", "profile", "source_commit"):
        _schema_string(metadata[key], "$vectors[0]." + key)
    _schema_int(metadata["vector_count"], "$vectors[0].vector_count")
    if metadata["vector_count"] != 108:
        raise OracleError("VECTOR_EXACT_COUNT", "metadata vector_count must be integer 108")

    binding_fields = ("manifest_sha256", "generator_sha256", "profile", "source_commit")
    common_fields = ("kind", *binding_fields, "case_id", "op", "input_raw", "recipe", "expected_flags")
    normal_keys = set((*common_fields, "expected_raw", "trace_sha256"))
    rejection_keys = set((*common_fields, "expected_error"))
    validated: list[dict[str, Any]] = [metadata]
    for index, value in enumerate(array[1:], 1):
        path = "$vectors[" + str(index) + "]"
        record = _schema_object(value, path, value.keys() if type(value) is dict else ())
        keys = set(record)
        if keys != normal_keys and keys != rejection_keys:
            raise OracleError("VECTOR_FIELDS", path + " has missing or unknown fields")
        for key in ("kind", *binding_fields, "case_id", "op", "input_raw", "recipe"):
            _schema_string(record[key], path + "." + key)
        parse_raw(record["input_raw"], 32)
        _schema_flags(record["expected_flags"], path + ".expected_flags")
        if keys == normal_keys:
            parse_raw(_schema_string(record["expected_raw"], path + ".expected_raw"), 32)
            _schema_string(record["trace_sha256"], path + ".trace_sha256")
        else:
            _schema_string(record["expected_error"], path + ".expected_error")
        validated.append(record)
    return validated


def verify_vectors(path: Path, oracle: AorOracle) -> tuple[int, str]:
    records, payload = _load_jsonl(path)
    _validate_vector_records_schema(records)
    expected_records = build_vector_records(oracle, "qualified")
    if len(expected_records) != 108:
        raise OracleError("VECTOR_GENERATOR_COUNT", "qualified generator did not produce exactly 108 cases")
    expected_payload = _vector_payload(oracle, expected_records, "qualified")
    if payload != expected_payload:
        raise OracleError(
            "VECTOR_PAYLOAD_MISMATCH",
            "vector bytes differ from the exact canonical 108-case membership, order, fields, recipes or final newline",
        )
    return 108, sha256_bytes(payload)


def _strict_json_file(path: Path, read_code: str, json_code: str) -> tuple[dict[str, Any], bytes]:
    try:
        payload = path.read_bytes()
        text = payload.decode("utf-8")
    except (OSError, UnicodeError) as error:
        raise OracleError(read_code, str(error)) from error
    try:
        value = json.loads(
            text,
            object_pairs_hook=_duplicate_checked_object,
            parse_float=_reject_json_real,
            parse_constant=_reject_json_constant,
        )
    except OracleError:
        raise
    except (json.JSONDecodeError, UnicodeError) as error:
        raise OracleError(json_code, str(error)) from error
    if type(value) is not dict:
        raise OracleError(json_code, "JSON root must be an object")
    return value, payload


def _schema_sha256(value: Any, path: str, allow_null: bool = False) -> str | None:
    if allow_null and value is None:
        return None
    digest = _schema_string(value, path)
    if len(digest) != 64 or digest != digest.lower() or any(character not in "0123456789abcdef" for character in digest):
        raise OracleError("EVIDENCE_SHA_SYNTAX", path + " is not a lowercase SHA256")
    return digest


def _evidence_project_path(text: Any, path: str) -> Path:
    relative = _schema_string(text, path)
    candidate = REPO_ROOT.joinpath(relative).resolve()
    if not _path_inside_repo(candidate):
        raise OracleError("EVIDENCE_PATH_SCOPE", path + " leaves the project directory")
    return candidate


def _validate_mutation_audit_file(audit: Any, manifest: dict[str, Any], expected_generator: str) -> None:
    obj = _schema_object(
        audit,
        "$mutation_audit",
        (
            "schema",
            "profile",
            "flags_profile",
            "manifest_sha256",
            "generator_sha256",
            "search_order",
            "exp_domain",
            "log_domain",
            "mutations",
            "witness_count",
            "gap_count",
        ),
    )
    for key in ("schema", "profile", "flags_profile", "manifest_sha256", "generator_sha256", "search_order"):
        _schema_string(obj[key], "$mutation_audit." + key)
    _schema_int(obj["witness_count"], "$mutation_audit.witness_count")
    _schema_int(obj["gap_count"], "$mutation_audit.gap_count")
    mutations = _schema_array(obj["mutations"], "$mutation_audit.mutations", 7)
    frozen_audit = manifest["mutation_audit"]
    if obj["schema"] != MUTATION_SCHEMA or obj["profile"] != PROFILE or obj["flags_profile"] != "AOR_STEP_STICKY_V1":
        raise OracleError("EVIDENCE_MUTATION_PROFILE", "mutation audit profile changed")
    if obj["manifest_sha256"] != validate_manifest(manifest) or obj["generator_sha256"] != expected_generator:
        raise OracleError("EVIDENCE_MUTATION_BINDING", "mutation audit identity binding changed")
    if obj["witness_count"] != 6 or obj["gap_count"] != 1:
        raise OracleError("EVIDENCE_MUTATION_COUNTS", "mutation witness or GAP count changed")
    if obj["search_order"] != frozen_audit["search_order"]:
        raise OracleError("EVIDENCE_MUTATION_SEARCH_ORDER", "mutation search order changed")

    exp_domain = _schema_object(
        obj["exp_domain"],
        "$mutation_audit.exp_domain",
        ("anchors_raw32", "include_sign_bit_twin", "inclusive_radius_raw", "ordering", "filter", "raw_candidate_union_count"),
    )
    for raw in _schema_string_array(exp_domain["anchors_raw32"], "$mutation_audit.exp_domain.anchors_raw32", 9):
        parse_raw(raw, 32)
    for key in ("include_sign_bit_twin", "inclusive_radius_raw", "raw_candidate_union_count"):
        _schema_int(exp_domain[key], "$mutation_audit.exp_domain." + key)
    for key in ("ordering", "filter"):
        _schema_string(exp_domain[key], "$mutation_audit.exp_domain." + key)
    if exp_domain != frozen_audit["exp_domain"]:
        raise OracleError("EVIDENCE_MUTATION_EXP_DOMAIN", "EXP mutation domain changed")

    log_domain = _schema_object(
        obj["log_domain"],
        "$mutation_audit.log_domain",
        (
            "table_base_expression",
            "table_base_inclusive_radius_raw",
            "positive_subnormal_seeds_raw32",
            "subnormal_inclusive_radius_raw",
            "ordering",
            "filter",
            "overlap_policy",
        ),
    )
    for key in ("table_base_expression", "ordering", "filter", "overlap_policy"):
        _schema_string(log_domain[key], "$mutation_audit.log_domain." + key)
    for key in ("table_base_inclusive_radius_raw", "subnormal_inclusive_radius_raw"):
        _schema_int(log_domain[key], "$mutation_audit.log_domain." + key)
    for raw in _schema_string_array(log_domain["positive_subnormal_seeds_raw32"], "$mutation_audit.log_domain.positive_subnormal_seeds_raw32", 6):
        parse_raw(raw, 32)
    if log_domain != frozen_audit["log_domain"]:
        raise OracleError("EVIDENCE_MUTATION_LOG_DOMAIN", "LOG mutation domain changed")

    frozen_outcomes = frozen_audit["outcomes"]
    for index, mutation_value in enumerate(mutations):
        path = "$mutation_audit.mutations[" + str(index) + "]"
        frozen = frozen_outcomes[index]
        mutation = _schema_object(
            mutation_value,
            path,
            ("mutation", "operation", "definition", "status", "candidates_examined", "witness")
            if frozen["status"] == "WITNESS"
            else ("mutation", "operation", "definition", "status", "candidates_examined"),
        )
        for key in ("mutation", "operation", "definition", "status"):
            _schema_string(mutation[key], path + "." + key)
        _schema_int(mutation["candidates_examined"], path + ".candidates_examined")
        for key in ("mutation", "definition", "status", "candidates_examined"):
            if mutation[key] != frozen[key]:
                raise OracleError("EVIDENCE_MUTATION_OUTCOME", path + " differs from manifest: " + key)
        expected_operation = "exp32" if index < 4 else "log32"
        if mutation["operation"] != expected_operation:
            raise OracleError("EVIDENCE_MUTATION_OPERATION", path + " operation changed")
        if frozen["status"] == "WITNESS":
            witness = _schema_object(
                mutation["witness"],
                path + ".witness",
                ("mutation", *frozen["witness"].keys()),
            )
            _schema_string(witness["mutation"], path + ".witness.mutation")
            for key in ("input_raw32", "strict_final_raw32", "mutant_final_raw32"):
                parse_raw(_schema_string(witness[key], path + ".witness." + key), 32)
            for key in ("strict_intermediate_raw64", "mutant_intermediate_raw64"):
                parse_raw(_schema_string(witness[key], path + ".witness." + key), 64)
            _schema_string(witness["comparison_stage"], path + ".witness.comparison_stage")
            if "domain_id" in witness:
                _schema_string(witness["domain_id"], path + ".witness.domain_id")
            for key in ("strict_intermediate_flags", "mutant_intermediate_flags", "strict_api_flags", "mutant_api_flags"):
                _schema_flags(witness[key], path + ".witness." + key)
            _schema_string_array(witness["difference_fields"], path + ".witness.difference_fields")
            expected_witness = {"mutation": frozen["mutation"], **frozen["witness"]}
            if witness != expected_witness:
                raise OracleError("EVIDENCE_MUTATION_WITNESS", path + " witness differs from manifest")


def _validate_evidence_schema(evidence: Any, bootstrap_self_log: bool) -> dict[str, Any]:
    root = _schema_object(
        evidence,
        "$evidence",
        (
            "schema",
            "profile",
            "flags_profile",
            "source_commit",
            "identity",
            "artifacts",
            "commands",
            "semantic_bindings",
            "return_code_semantics",
            "upstream_file_sha256",
            "self_verification",
        ),
    )
    for key in ("schema", "profile", "flags_profile", "source_commit", "return_code_semantics"):
        _schema_string(root[key], "$evidence." + key)
    if root["schema"] != EVIDENCE_SCHEMA or root["profile"] != PROFILE or root["flags_profile"] != "AOR_STEP_STICKY_V1":
        raise OracleError("EVIDENCE_PROFILE", "evidence schema or profile changed")
    if root["source_commit"] != SOURCE_COMMIT:
        raise OracleError("EVIDENCE_SOURCE_COMMIT", "evidence source commit changed")
    if root["return_code_semantics"] != "external exec observation; terminal PASS record and log hash are independently verified, but parent wait status is not derivable from log bytes":
        raise OracleError("EVIDENCE_RC_SEMANTICS", "return-code semantics are not explicit")

    identity = _schema_object(root["identity"], "$evidence.identity", ("old", "new"))
    identity_keys = ("manifest_canonical_sha256", "generator_sha256", "vectors_sha256", "mutation_audit_sha256")
    for generation in ("old", "new"):
        item = _schema_object(identity[generation], "$evidence.identity." + generation, identity_keys)
        for key in identity_keys:
            _schema_sha256(item[key], "$evidence.identity." + generation + "." + key)
    if identity["old"] != EXPECTED_OLD_IDENTITY:
        raise OracleError("EVIDENCE_OLD_IDENTITY", "old semantic identity changed")

    artifacts = _schema_array(root["artifacts"], "$evidence.artifacts", 6)
    expected_artifacts = (
        ("generator", "scripts/aor_f32_oracle.py"),
        ("test_source", "tests/test_aor_f32_oracle.py"),
        ("manifest_file", "tests/vectors/aor_f32_manifest.json"),
        ("vectors", "tests/vectors/aor_f32_vectors.jsonl"),
        ("contract", "docs/AOR_F32_ORACLE_CONTRACT.md"),
        ("mutation_audit", "tmp/logs/aor-f32-oracle/final-mutation-audit.json"),
    )
    for index, artifact_value in enumerate(artifacts):
        path = "$evidence.artifacts[" + str(index) + "]"
        artifact = _schema_object(artifact_value, path, ("id", "path", "sha256"))
        _schema_string(artifact["id"], path + ".id")
        _schema_string(artifact["path"], path + ".path")
        _schema_sha256(artifact["sha256"], path + ".sha256")
        expected_id, expected_path = expected_artifacts[index]
        if artifact["id"] != expected_id or artifact["path"] != expected_path:
            raise OracleError("EVIDENCE_ARTIFACT_ORDER", "artifact membership, order or path changed")

    commands = _schema_array(root["commands"], "$evidence.commands", 7)
    expected_commands = (
        (
            "validate-manifest",
            "env PYTHONPYCACHEPREFIX=tmp/build/aor-f32-oracle/pycache timeout 30s python3 scripts/aor_f32_oracle.py validate-manifest",
            "tmp/logs/aor-f32-oracle/final-validate-manifest.log",
            PASS_MARKER,
            "validate-manifest",
        ),
        (
            "self-test",
            "env PYTHONPYCACHEPREFIX=tmp/build/aor-f32-oracle/pycache timeout 30s python3 scripts/aor_f32_oracle.py self-test",
            "tmp/logs/aor-f32-oracle/final-self-test.log",
            PASS_MARKER,
            "self-test",
        ),
        (
            "audit-mutations",
            "env PYTHONPYCACHEPREFIX=tmp/build/aor-f32-oracle/pycache timeout 120s python3 scripts/aor_f32_oracle.py audit-mutations --output tmp/logs/aor-f32-oracle/final-mutation-audit.json",
            "tmp/logs/aor-f32-oracle/final-mutation-audit.log",
            PASS_MARKER,
            "audit-mutations",
        ),
        (
            "emit-vectors",
            "env PYTHONPYCACHEPREFIX=tmp/build/aor-f32-oracle/pycache timeout 45s python3 scripts/aor_f32_oracle.py emit-vectors --output tests/vectors/aor_f32_vectors.jsonl",
            "tmp/logs/aor-f32-oracle/final-emit-vectors.log",
            PASS_MARKER,
            "emit-vectors",
        ),
        (
            "verify-vectors",
            "env PYTHONPYCACHEPREFIX=tmp/build/aor-f32-oracle/pycache timeout 45s python3 scripts/aor_f32_oracle.py verify-vectors --input tests/vectors/aor_f32_vectors.jsonl",
            "tmp/logs/aor-f32-oracle/final-verify-vectors.log",
            PASS_MARKER,
            "verify-vectors",
        ),
        (
            "unit-test",
            "env PYTHONPYCACHEPREFIX=tmp/build/aor-f32-oracle/pycache timeout 90s python3 tests/test_aor_f32_oracle.py",
            "tmp/logs/aor-f32-oracle/final-unit-test.log",
            "[AOR-F32-TEST][PASS]",
            "unit-test",
        ),
        (
            "verify-evidence",
            "env PYTHONPYCACHEPREFIX=tmp/build/aor-f32-oracle/pycache timeout 120s python3 scripts/aor_f32_oracle.py verify-evidence --evidence tmp/logs/aor-f32-oracle/final-evidence.json",
            "tmp/logs/aor-f32-oracle/final-verify-evidence.log",
            EVIDENCE_PASS_MARKER,
            "verify-evidence",
        ),
    )
    for index, command_value in enumerate(commands):
        path = "$evidence.commands[" + str(index) + "]"
        command = _schema_object(
            command_value,
            path,
            (
                "id",
                "command",
                "log",
                "sha256",
                "expected_marker",
                "marker_command",
                "observed_exec_return_code",
                "observed_exec_return_code_authority",
            ),
        )
        for key in ("id", "command", "log", "expected_marker", "marker_command", "observed_exec_return_code_authority"):
            _schema_string(command[key], path + "." + key)
        allow_null = bootstrap_self_log and command["id"] == "verify-evidence"
        _schema_sha256(command["sha256"], path + ".sha256", allow_null=allow_null)
        _schema_int(command["observed_exec_return_code"], path + ".observed_exec_return_code")
        expected_id, expected_command, expected_log, expected_marker, expected_marker_command = expected_commands[index]
        if (
            command["id"] != expected_id
            or command["command"] != expected_command
            or command["log"] != expected_log
            or command["expected_marker"] != expected_marker
            or command["marker_command"] != expected_marker_command
        ):
            raise OracleError("EVIDENCE_COMMAND_ORDER", "command membership, order, path or marker contract changed")
        if command["observed_exec_return_code"] != 0:
            raise OracleError("EVIDENCE_OBSERVED_RC", "an externally observed command return code is nonzero")
        if command["observed_exec_return_code_authority"] != "external Codex exec result; recorded observation, not independently derivable from this log":
            raise OracleError("EVIDENCE_OBSERVED_RC_AUTHORITY", "return-code authority field changed")

    bindings = _schema_scalar_object(
        root["semantic_bindings"],
        "$evidence.semantic_bindings",
        string_fields=("manifest_canonical_sha256", "generator_sha256", "vectors_sha256", "mutation_audit_sha256"),
        int_fields=("qualified_vectors", "internal_self_test_cases", "unittest_methods", "mutation_witnesses", "mutation_gaps"),
    )
    for key in ("manifest_canonical_sha256", "generator_sha256", "vectors_sha256", "mutation_audit_sha256"):
        _schema_sha256(bindings[key], "$evidence.semantic_bindings." + key)
    if (
        bindings["qualified_vectors"] != 108
        or bindings["internal_self_test_cases"] != 15
        or bindings["unittest_methods"] != 28
        or bindings["mutation_witnesses"] != 6
        or bindings["mutation_gaps"] != 1
    ):
        raise OracleError("EVIDENCE_SEMANTIC_COUNTS", "evidence semantic counts changed")

    upstream = _schema_object(root["upstream_file_sha256"], "$evidence.upstream_file_sha256", ("status", "files"))
    _schema_string(upstream["status"], "$evidence.upstream_file_sha256.status")
    if upstream["status"] != "GAP_SOURCE_FILES_NOT_VENDORED_NO_LOCAL_CONTENT_SHA256":
        raise OracleError("EVIDENCE_UPSTREAM_GAP", "upstream SHA GAP status changed")
    upstream_files = _schema_array(upstream["files"], "$evidence.upstream_file_sha256.files", 6)
    expected_upstream = ("math/expf.c", "math/exp2f_data.c", "math/logf.c", "math/logf_data.c", "math/math_config.h", "math/math_errf.c")
    for index, file_value in enumerate(upstream_files):
        path = "$evidence.upstream_file_sha256.files[" + str(index) + "]"
        item = _schema_object(file_value, path, ("path", "sha256"))
        _schema_string(item["path"], path + ".path")
        _schema_null(item["sha256"], path + ".sha256")
        if item["path"] != expected_upstream[index]:
            raise OracleError("EVIDENCE_UPSTREAM_ORDER", "upstream GAP file membership or order changed")

    self_verification = _schema_scalar_object(
        root["self_verification"],
        "$evidence.self_verification",
        string_fields=("command_id", "bootstrap_semantics"),
        int_fields=("normal_verification_required",),
    )
    if self_verification["command_id"] != "verify-evidence" or self_verification["normal_verification_required"] != 1:
        raise OracleError("EVIDENCE_SELF_VERIFY", "self-verification contract changed")
    if self_verification["bootstrap_semantics"] != "verify-evidence log SHA may be null only during bootstrap; the final receipt binds that log SHA and must pass without --bootstrap-self-log":
        raise OracleError("EVIDENCE_SELF_VERIFY", "self-verification bootstrap semantics changed")
    return root


def _validate_log_marker(marker: Any, command: dict[str, Any], bindings: dict[str, Any]) -> None:
    command_id = command["id"]
    if command_id == "validate-manifest":
        obj = _schema_object(marker, "$log_marker", ("command", "manifest_sha256", "marker"))
    elif command_id == "self-test":
        obj = _schema_object(marker, "$log_marker", ("cases", "command", "generator_sha256", "manifest_sha256", "marker"))
        if _schema_int(obj["cases"], "$log_marker.cases") != bindings["internal_self_test_cases"]:
            raise OracleError("EVIDENCE_LOG_COUNT", "self-test case count changed")
    elif command_id == "audit-mutations":
        obj = _schema_object(
            marker,
            "$log_marker",
            ("audit_sha256", "command", "gap_count", "generator_sha256", "manifest_sha256", "marker", "witness_count"),
        )
        _schema_sha256(obj["audit_sha256"], "$log_marker.audit_sha256")
        if obj["audit_sha256"] != bindings["mutation_audit_sha256"]:
            raise OracleError("EVIDENCE_LOG_SHA_BINDING", "mutation marker SHA changed")
        if _schema_int(obj["witness_count"], "$log_marker.witness_count") != bindings["mutation_witnesses"]:
            raise OracleError("EVIDENCE_LOG_COUNT", "mutation witness count changed")
        if _schema_int(obj["gap_count"], "$log_marker.gap_count") != bindings["mutation_gaps"]:
            raise OracleError("EVIDENCE_LOG_COUNT", "mutation GAP count changed")
    elif command_id in ("emit-vectors", "verify-vectors"):
        obj = _schema_object(
            marker,
            "$log_marker",
            ("command", "generator_sha256", "manifest_sha256", "marker", "vector_count", "vector_sha256"),
        )
        _schema_sha256(obj["vector_sha256"], "$log_marker.vector_sha256")
        if obj["vector_sha256"] != bindings["vectors_sha256"]:
            raise OracleError("EVIDENCE_LOG_SHA_BINDING", command_id + " vector SHA changed")
        if _schema_int(obj["vector_count"], "$log_marker.vector_count") != bindings["qualified_vectors"]:
            raise OracleError("EVIDENCE_LOG_COUNT", command_id + " vector count changed")
    elif command_id == "unit-test":
        obj = _schema_object(marker, "$log_marker", ("command", "marker", "tests"))
        if _schema_int(obj["tests"], "$log_marker.tests") != bindings["unittest_methods"]:
            raise OracleError("EVIDENCE_LOG_COUNT", "unit-test method count changed")
    elif command_id == "verify-evidence":
        obj = _schema_object(marker, "$log_marker", ("artifact_count", "command", "command_count", "marker", "schema"))
        if _schema_int(obj["artifact_count"], "$log_marker.artifact_count") != 6:
            raise OracleError("EVIDENCE_LOG_COUNT", "evidence artifact count changed")
        if _schema_int(obj["command_count"], "$log_marker.command_count") != 7:
            raise OracleError("EVIDENCE_LOG_COUNT", "evidence command count changed")
        if _schema_string(obj["schema"], "$log_marker.schema") != EVIDENCE_SCHEMA:
            raise OracleError("EVIDENCE_LOG_SCHEMA", "evidence marker schema changed")
    else:
        raise OracleError("EVIDENCE_LOG_COMMAND", "unknown evidence command")

    if _schema_string(obj["marker"], "$log_marker.marker") != command["expected_marker"]:
        raise OracleError("EVIDENCE_LOG_MARKER", command_id + " marker changed")
    if _schema_string(obj["command"], "$log_marker.command") != command["marker_command"]:
        raise OracleError("EVIDENCE_LOG_COMMAND", command_id + " marker command changed")
    if command_id not in ("unit-test", "verify-evidence"):
        if _schema_sha256(obj["manifest_sha256"], "$log_marker.manifest_sha256") != bindings["manifest_canonical_sha256"]:
            raise OracleError("EVIDENCE_LOG_SHA_BINDING", command_id + " manifest SHA changed")
    if command_id in ("self-test", "audit-mutations", "emit-vectors", "verify-vectors"):
        if _schema_sha256(obj["generator_sha256"], "$log_marker.generator_sha256") != bindings["generator_sha256"]:
            raise OracleError("EVIDENCE_LOG_SHA_BINDING", command_id + " generator SHA changed")


def _verify_log_record(command: dict[str, Any], bindings: dict[str, Any], bootstrap_self_log: bool) -> None:
    if bootstrap_self_log and command["id"] == "verify-evidence" and command["sha256"] is None:
        return
    log_path = _evidence_project_path(command["log"], "$evidence.commands." + command["id"] + ".log")
    try:
        payload = log_path.read_bytes()
        text = payload.decode("utf-8")
    except (OSError, UnicodeError) as error:
        raise OracleError("EVIDENCE_LOG_READ", command["id"] + ": " + str(error)) from error
    if sha256_bytes(payload) != command["sha256"]:
        raise OracleError("EVIDENCE_LOG_SHA", command["id"] + " log SHA mismatch")
    if "Traceback (most recent call last)" in text or "[AOR-F32-ORACLE][FAIL]" in text:
        raise OracleError("EVIDENCE_LOG_FAILURE", command["id"] + " log contains a failure or traceback")
    marker_lines = [line for line in text.splitlines() if command["expected_marker"] in line]
    if len(marker_lines) != 1:
        raise OracleError("EVIDENCE_LOG_MARKER_COUNT", command["id"] + " log must contain exactly one terminal marker")
    try:
        marker = json.loads(
            marker_lines[0],
            object_pairs_hook=_duplicate_checked_object,
            parse_float=_reject_json_real,
            parse_constant=_reject_json_constant,
        )
    except OracleError:
        raise
    except (json.JSONDecodeError, UnicodeError) as error:
        raise OracleError("EVIDENCE_LOG_MARKER_JSON", command["id"] + " marker is not strict JSON") from error
    _validate_log_marker(marker, command, bindings)


def verify_evidence(path: Path, bootstrap_self_log: bool = False) -> tuple[int, int]:
    evidence, _ = _strict_json_file(path, "EVIDENCE_READ", "EVIDENCE_JSON")
    evidence = _validate_evidence_schema(evidence, bootstrap_self_log)
    artifacts = evidence["artifacts"]
    artifact_by_id = {artifact["id"]: artifact for artifact in artifacts}
    for artifact in artifacts:
        artifact_path = _evidence_project_path(artifact["path"], "$evidence.artifacts." + artifact["id"] + ".path")
        try:
            digest = sha256_bytes(artifact_path.read_bytes())
        except OSError as error:
            raise OracleError("EVIDENCE_ARTIFACT_READ", artifact["id"] + ": " + str(error)) from error
        if digest != artifact["sha256"]:
            raise OracleError("EVIDENCE_ARTIFACT_SHA", artifact["id"] + " SHA mismatch")

    manifest_path = _evidence_project_path(artifact_by_id["manifest_file"]["path"], "$evidence.artifacts.manifest_file.path")
    manifest = load_manifest(manifest_path)
    oracle = AorOracle(manifest)
    bindings = evidence["semantic_bindings"]
    if oracle.manifest_sha256 != bindings["manifest_canonical_sha256"]:
        raise OracleError("EVIDENCE_MANIFEST_CANONICAL_SHA", "manifest canonical SHA mismatch")
    if generator_sha256() != bindings["generator_sha256"]:
        raise OracleError("EVIDENCE_GENERATOR_SHA", "generator semantic SHA mismatch")
    vector_path = _evidence_project_path(artifact_by_id["vectors"]["path"], "$evidence.artifacts.vectors.path")
    vector_count, vector_digest = verify_vectors(vector_path, oracle)
    if vector_count != bindings["qualified_vectors"] or vector_digest != bindings["vectors_sha256"]:
        raise OracleError("EVIDENCE_VECTOR_BINDING", "vector semantic binding mismatch")
    audit_path = _evidence_project_path(artifact_by_id["mutation_audit"]["path"], "$evidence.artifacts.mutation_audit.path")
    audit, audit_payload = _strict_json_file(audit_path, "EVIDENCE_MUTATION_READ", "EVIDENCE_MUTATION_JSON")
    if audit_payload != canonical_bytes(audit) + b"\n":
        raise OracleError("EVIDENCE_MUTATION_CANONICAL", "mutation audit is not canonical JSON")
    if sha256_bytes(audit_payload) != bindings["mutation_audit_sha256"]:
        raise OracleError("EVIDENCE_MUTATION_SHA", "mutation audit semantic SHA mismatch")
    _validate_mutation_audit_file(audit, manifest, bindings["generator_sha256"])
    if evidence["identity"]["new"] != {
        "manifest_canonical_sha256": bindings["manifest_canonical_sha256"],
        "generator_sha256": bindings["generator_sha256"],
        "vectors_sha256": bindings["vectors_sha256"],
        "mutation_audit_sha256": bindings["mutation_audit_sha256"],
    }:
        raise OracleError("EVIDENCE_NEW_IDENTITY", "new identity does not match semantic bindings")
    for command in evidence["commands"]:
        _verify_log_record(command, bindings, bootstrap_self_log)
    return len(artifacts), len(evidence["commands"])


def run_internal_self_test(oracle: AorOracle) -> int:
    cases = 0
    obvious = (
        (oracle.exp32, 0x00000000, 0x3F800000, ()),
        (oracle.exp32, 0x80000000, 0x3F800000, ()),
        (oracle.exp32, 0xFF800000, 0x00000000, ()),
        (oracle.exp32, 0x7F800000, 0x7F800000, ()),
        (oracle.exp32, 0x00000001, 0x3F800000, ("NX",)),
        (oracle.exp32, 0x80000001, 0x3F800000, ("NX",)),
        (oracle.log32, 0x3F800000, 0x00000000, ()),
        (oracle.log32, 0x00000000, 0xFF800000, ("DZ",)),
        (oracle.log32, 0x80000000, 0xFF800000, ("DZ",)),
        (oracle.log32, 0x7F800000, 0x7F800000, ()),
    )
    for operation, input_raw, expected_raw, expected_flags in obvious:
        result = operation(input_raw)
        if result.raw != expected_raw or result.api_flags != expected_flags:
            raise OracleError("SELF_TEST_OBVIOUS", "obvious fixed raw case failed")
        cases += 1
    fused = f64_fma(0x3FF0000002000000, 0x3FEFFFFFFC000000, 0xBFF0000000000000)
    separate_product = f64_mul(0x3FF0000002000000, 0x3FEFFFFFFC000000)
    separate = f64_add(separate_product.raw, 0xBFF0000000000000)
    if fused.raw != 0xBC90000000000000 or separate.raw != 0x0000000000000000:
        raise OracleError("SELF_TEST_FMA", "fused/non-fused discriminator failed")
    cases += 1
    if u32(-1) != 0xFFFFFFFF or u64(-1) != 0xFFFFFFFFFFFFFFFF or asr32(0xFF800000, 23) != -1:
        raise OracleError("SELF_TEST_MODULO", "fixed-width integer semantics failed")
    cases += 1
    source = SCRIPT_PATH.read_text(encoding="utf-8")
    check_integer_only_source(source, filename=str(SCRIPT_PATH), require_complete_imports=True)
    cases += 1
    reduction = oracle.exp32(0x3F800000)
    kd_entry = AorOracle._entry(reduction, "kd")
    k_entry = AorOracle._entry(reduction, "k")
    z_entry = AorOracle._entry(reduction, "z")
    if not kd_entry["discarded"] or not k_entry["discarded"] or k_entry["source"] != "z" or k_entry["source_raw"] != z_entry["raw"]:
        raise OracleError("SELF_TEST_EXP_CONVERSION_SOURCE", "EXP integer conversion did not consume fractional z")
    cases += 1
    negative_tiny = oracle.exp32(0x80000001)
    tiny_kd = AorOracle._entry(negative_tiny, "kd")
    tiny_k = AorOracle._entry(negative_tiny, "k")
    if tiny_kd["raw"] != "0x8000000000000000" or tiny_k["value"] != 0 or not tiny_k["discarded"]:
        raise OracleError("SELF_TEST_EXP_NEGATIVE_ZERO", "EXP round-integral lost negative zero or conversion provenance")
    cases += 1
    return cases


def _status_payload(**values: Any) -> str:
    return canonical_bytes({"marker": PASS_MARKER, **values}).decode("utf-8")


def _build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Integer-only AOR EXP32/LOG32 source-replay oracle")
    subparsers = parser.add_subparsers(dest="command", required=True)
    validate = subparsers.add_parser("validate-manifest")
    validate.add_argument("--manifest", type=Path, default=DEFAULT_MANIFEST)
    self_test = subparsers.add_parser("self-test")
    self_test.add_argument("--manifest", type=Path, default=DEFAULT_MANIFEST)
    emit = subparsers.add_parser("emit-vectors")
    emit.add_argument("--manifest", type=Path, default=DEFAULT_MANIFEST)
    emit.add_argument("--output", type=Path, required=True)
    emit.add_argument("--vector-profile", choices=("qualified", "full-special"), default="qualified")
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
    parser = _build_parser()
    arguments = parser.parse_args(argv)
    try:
        if arguments.command == "verify-evidence":
            artifact_count, command_count = verify_evidence(arguments.evidence.resolve(), arguments.bootstrap_self_log)
            print(
                canonical_bytes(
                    {
                        "artifact_count": artifact_count,
                        "command": arguments.command,
                        "command_count": command_count,
                        "marker": EVIDENCE_PASS_MARKER,
                        "schema": EVIDENCE_SCHEMA,
                    }
                ).decode("utf-8")
            )
            return 0
        manifest = load_manifest(arguments.manifest.resolve())
        oracle = AorOracle(manifest)
        if arguments.command == "validate-manifest":
            print(_status_payload(command=arguments.command, manifest_sha256=oracle.manifest_sha256))
        elif arguments.command == "self-test":
            cases = run_internal_self_test(oracle)
            print(
                _status_payload(
                    command=arguments.command,
                    cases=cases,
                    manifest_sha256=oracle.manifest_sha256,
                    generator_sha256=generator_sha256(),
                )
            )
        elif arguments.command == "emit-vectors":
            count, digest = emit_vectors(arguments.output, oracle, arguments.vector_profile)
            print(
                _status_payload(
                    command=arguments.command,
                    vector_count=count,
                    vector_sha256=digest,
                    manifest_sha256=oracle.manifest_sha256,
                    generator_sha256=generator_sha256(),
                )
            )
        elif arguments.command == "verify-vectors":
            count, digest = verify_vectors(arguments.input.resolve(), oracle)
            print(
                _status_payload(
                    command=arguments.command,
                    vector_count=count,
                    vector_sha256=digest,
                    manifest_sha256=oracle.manifest_sha256,
                    generator_sha256=generator_sha256(),
                )
            )
        elif arguments.command == "audit-mutations":
            witness_count, gap_count, digest = emit_mutation_audit(arguments.output, oracle)
            print(
                _status_payload(
                    command=arguments.command,
                    witness_count=witness_count,
                    gap_count=gap_count,
                    audit_sha256=digest,
                    manifest_sha256=oracle.manifest_sha256,
                    generator_sha256=generator_sha256(),
                )
            )
        else:
            raise OracleError("COMMAND", "unreachable command")
    except OracleError as error:
        payload = {
            "marker": "[AOR-F32-ORACLE][FAIL]",
            "code": error.code,
            "message": str(error),
            "flags": list(error.flags),
        }
        print(canonical_bytes(payload).decode("utf-8"), file=sys.stderr)
        return 2
    except Exception as error:
        payload = {
            "marker": "[AOR-F32-ORACLE][FAIL]",
            "code": "UNEXPECTED_INTERNAL_ERROR",
            "message": type(error).__name__,
            "flags": [],
        }
        print(canonical_bytes(payload).decode("utf-8"), file=sys.stderr)
        return 2
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
