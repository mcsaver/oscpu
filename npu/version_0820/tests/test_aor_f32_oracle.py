#!/usr/bin/env python3

from __future__ import annotations

import copy
import importlib.util
import json
import os
import subprocess
import sys
import unittest
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parent.parent
SCRIPT = REPO_ROOT.joinpath("scripts", "aor_f32_oracle.py")
MANIFEST = REPO_ROOT.joinpath("tests", "vectors", "aor_f32_manifest.json")
VECTORS = REPO_ROOT.joinpath("tests", "vectors", "aor_f32_vectors.jsonl")
TMP_BUILD = REPO_ROOT.joinpath("tmp", "build", "aor-f32-oracle")
EVIDENCE = REPO_ROOT.joinpath("tmp", "logs", "aor-f32-oracle", "final-evidence.json")

MODULE_SPEC = importlib.util.spec_from_file_location("aor_f32_oracle", SCRIPT)
if MODULE_SPEC is None or MODULE_SPEC.loader is None:
    raise RuntimeError("cannot load oracle module")
oracle_module = importlib.util.module_from_spec(MODULE_SPEC)
sys.modules[MODULE_SPEC.name] = oracle_module
MODULE_SPEC.loader.exec_module(oracle_module)


def run_cli(arguments: list[str], timeout_seconds: int = 30) -> subprocess.CompletedProcess[str]:
    environment = dict(os.environ)
    environment["PYTHONPYCACHEPREFIX"] = str(TMP_BUILD.joinpath("pycache"))
    return subprocess.run(
        [sys.executable, str(SCRIPT), *arguments],
        cwd=REPO_ROOT,
        env=environment,
        capture_output=True,
        text=True,
        timeout=timeout_seconds,
        check=False,
    )


def parse_strict_object(text: str) -> dict[str, object]:
    value = json.loads(
        text,
        object_pairs_hook=oracle_module._duplicate_checked_object,
        parse_float=oracle_module._reject_json_real,
        parse_constant=oracle_module._reject_json_constant,
    )
    if type(value) is not dict:
        raise AssertionError("strict JSON result is not an object")
    return value


def write_canonical_jsonl(path: Path, records: list[dict[str, object]], final_newline: bool = True) -> None:
    payload = b"\n".join(oracle_module.canonical_bytes(record) for record in records)
    if final_newline:
        payload += b"\n"
    path.write_bytes(payload)


class PrimitiveTests(unittest.TestCase):
    def test_dyadic_normalization(self) -> None:
        self.assertEqual(oracle_module.normalize_dyadic(0, 0, -999), oracle_module.Dyadic(0, 0, 0))
        self.assertEqual(oracle_module.normalize_dyadic(1, 0, 77), oracle_module.Dyadic(1, 0, 0))
        self.assertEqual(oracle_module.normalize_dyadic(0, 0x1800, -20), oracle_module.Dyadic(0, 3, -9))
        self.assertEqual(oracle_module.normalize_dyadic(1, 7, -149), oracle_module.Dyadic(1, 7, -149))

    def test_decode_pack_roundtrip(self) -> None:
        f32_raws = (
            0x00000000,
            0x80000000,
            0x00000001,
            0x007FFFFF,
            0x00800000,
            0x3F800000,
            0xBF800000,
            0x7F7FFFFF,
            0xFF7FFFFF,
        )
        for raw in f32_raws:
            decoded = oracle_module.decode_f32(raw)
            packed = oracle_module.pack_f32(decoded.sign, decoded.magnitude, decoded.exponent)
            self.assertEqual(packed.raw, raw)
            self.assertEqual(packed.flags, ())
        f64_raws = (
            0x0000000000000000,
            0x8000000000000000,
            0x0000000000000001,
            0x000FFFFFFFFFFFFF,
            0x0010000000000000,
            0x3FF0000000000000,
            0xBFF0000000000000,
            0x7FEFFFFFFFFFFFFF,
        )
        for raw in f64_raws:
            decoded = oracle_module.decode_f64(raw)
            packed = oracle_module.pack_f64(decoded.sign, decoded.magnitude, decoded.exponent)
            self.assertEqual(packed.raw, raw)
            self.assertEqual(packed.flags, ())

    def test_rne_retained_even_odd_and_carry(self) -> None:
        even = oracle_module.pack_f64(0, (1 << 53) + 1, -53)
        odd = oracle_module.pack_f64(0, (1 << 53) + 3, -53)
        carry = oracle_module.pack_f64(0, (1 << 54) - 1, -53)
        self.assertEqual((even.raw, even.flags), (0x3FF0000000000000, ("NX",)))
        self.assertEqual((odd.raw, odd.flags), (0x3FF0000000000002, ("NX",)))
        self.assertEqual((carry.raw, carry.flags), (0x4000000000000000, ("NX",)))

    def test_subnormal_normal_overflow_and_tininess_after(self) -> None:
        exact_min_sub = oracle_module.pack_f32(0, 1, -149)
        half_min_sub = oracle_module.pack_f32(0, 1, -150)
        above_half_min_sub = oracle_module.pack_f32(0, 3, -151)
        max_sub = oracle_module.pack_f32(0, (1 << 23) - 1, -149)
        min_normal = oracle_module.pack_f32(0, 1 << 23, -149)
        tie_to_min_normal = oracle_module.pack_f32(0, (1 << 24) - 1, -150)
        overflow_tie = oracle_module.pack_f32(0, (1 << 25) - 1, 103)
        self.assertEqual((exact_min_sub.raw, exact_min_sub.flags), (0x00000001, ()))
        self.assertEqual((half_min_sub.raw, half_min_sub.flags), (0x00000000, ("UF", "NX")))
        self.assertEqual((above_half_min_sub.raw, above_half_min_sub.flags), (0x00000001, ("UF", "NX")))
        self.assertEqual((max_sub.raw, max_sub.flags), (0x007FFFFF, ()))
        self.assertEqual((min_normal.raw, min_normal.flags), (0x00800000, ()))
        self.assertEqual((tie_to_min_normal.raw, tie_to_min_normal.flags), (0x00800000, ("UF", "NX")))
        self.assertEqual((overflow_tie.raw, overflow_tie.flags), (0x7F800000, ("OF", "NX")))

    def test_add_half_ulp_variants(self) -> None:
        half_ulp = 0x3CA0000000000000
        three_quarters_ulp = 0x3CA8000000000000
        even = oracle_module.f64_add(0x3FF0000000000000, half_ulp)
        odd = oracle_module.f64_add(0x3FF0000000000001, half_ulp)
        above = oracle_module.f64_add(0x3FF0000000000000, three_quarters_ulp)
        self.assertEqual((even.raw, even.flags), (0x3FF0000000000000, ("NX",)))
        self.assertEqual((odd.raw, odd.flags), (0x3FF0000000000002, ("NX",)))
        self.assertEqual((above.raw, above.flags), (0x3FF0000000000001, ("NX",)))

    def test_mul_normal_to_subnormal_boundary(self) -> None:
        exact = oracle_module.f64_mul(0x0010000000000000, 0x3FE0000000000000)
        under = oracle_module.f64_mul(0x0000000000000001, 0x3FE0000000000000)
        self.assertEqual((exact.raw, exact.flags), (0x0008000000000000, ()))
        self.assertEqual((under.raw, under.flags), (0x0000000000000000, ("UF", "NX")))

    def test_fused_nonfused_discriminator(self) -> None:
        a = 0x3FF0000002000000
        b = 0x3FEFFFFFFC000000
        c = 0xBFF0000000000000
        fused = oracle_module.f64_fma(a, b, c)
        rounded_product = oracle_module.f64_mul(a, b)
        nonfused = oracle_module.f64_add(rounded_product.raw, c)
        self.assertEqual(fused.raw, 0xBC90000000000000)
        self.assertEqual(nonfused.raw, 0x0000000000000000)

    def test_f64_to_f32_boundary_rules(self) -> None:
        exact_max_sub64 = oracle_module.pack_f64(0, (1 << 23) - 1, -149)
        tie_min_normal64 = oracle_module.pack_f64(0, (1 << 24) - 1, -150)
        half_min_sub64 = oracle_module.pack_f64(0, 1, -150)
        self.assertEqual(oracle_module.f64_to_f32(exact_max_sub64.raw), oracle_module.RawResult(0x007FFFFF, ()))
        self.assertEqual(
            oracle_module.f64_to_f32(tie_min_normal64.raw),
            oracle_module.RawResult(0x00800000, ("UF", "NX")),
        )
        self.assertEqual(oracle_module.f64_to_f32(half_min_sub64.raw), oracle_module.RawResult(0x00000000, ("UF", "NX")))

    def test_f64_to_f32_softfloat_tininess_after_boundary(self) -> None:
        cases = (
            (0x380FFFFFDFFFFFFF, 0x007FFFFF, ("UF", "NX"), 0xFFFFFF, True),
            (0x380FFFFFE0000000, 0x00800000, ("UF", "NX"), 0xFFFFFF, False),
            (0x380FFFFFE0000001, 0x00800000, ("UF", "NX"), 0xFFFFFF, True),
            (0x380FFFFFE1000000, 0x00800000, ("UF", "NX"), 0xFFFFFF, True),
            (0x380FFFFFEFFFFFFF, 0x00800000, ("UF", "NX"), 0xFFFFFF, True),
            (0x380FFFFFF0000000, 0x00800000, ("NX",), 0x1000000, True),
            (0x380FFFFFF0000001, 0x00800000, ("NX",), 0x1000000, True),
        )
        for raw, expected_raw, expected_flags, precision_rounded, precision_inexact in cases:
            decoded = oracle_module.decode_f64(raw)
            temporary, grid, temporary_inexact = oracle_module._round_precision_unbounded_rne(
                decoded.magnitude,
                decoded.exponent,
                oracle_module.F32.precision,
            )
            self.assertEqual((temporary, grid, temporary_inexact), (precision_rounded, -150, precision_inexact))
            for sign in (0, 1):
                signed_input = raw | (sign << 63)
                signed_output = expected_raw | (sign << 31)
                self.assertEqual(
                    oracle_module.f64_to_f32(signed_input),
                    oracle_module.RawResult(signed_output, expected_flags),
                )

    def test_rmm_ties_integer_edges_and_negative_zero(self) -> None:
        cases = (
            (0x3FE0000000000000, 0x3FF0000000000000, 1),
            (0xBFE0000000000000, 0xBFF0000000000000, -1),
            (0x3FF8000000000000, 0x4000000000000000, 2),
            (0xBFF8000000000000, 0xC000000000000000, -2),
            (0x4004000000000000, 0x4008000000000000, 3),
            (0xC004000000000000, 0xC008000000000000, -3),
        )
        for raw, rounded_raw, integer in cases:
            rounded = oracle_module.f64_round_integral_rmm(raw)
            converted = oracle_module.f64_to_i32_rmm(raw)
            self.assertEqual((rounded.raw, rounded.discarded), (rounded_raw, True))
            self.assertEqual((converted.value, converted.flags, converted.discarded), (integer, (), True))
            self.assertEqual(oracle_module.f64_to_i32_rmm(raw, expose_inexact=True).flags, ("NX",))
        self.assertEqual(oracle_module.f64_round_integral_rmm(0x8000000000000000).raw, 0x8000000000000000)
        for integer in (-(1 << 31), -1, 0, 1, (1 << 31) - 1):
            raw = oracle_module.i32_to_f64(integer).raw
            result = oracle_module.f64_to_i32_rmm(raw)
            self.assertEqual((result.value, result.flags), (integer, ()))
        positive_oob = oracle_module.pack_f64(0, (1 << 32) - 1, -1)
        negative_oob = oracle_module.pack_f64(1, (1 << 32) + 1, -1)
        self.assertEqual(oracle_module.f64_to_i32_rmm(positive_oob.raw).flags, ("NV",))
        self.assertEqual(oracle_module.f64_to_i32_rmm(negative_oob.raw).flags, ("NV",))

    def test_u32_u64_modulo_and_asr(self) -> None:
        self.assertEqual(oracle_module.u32(-1), 0xFFFFFFFF)
        self.assertEqual(oracle_module.u32(0x100000001), 1)
        self.assertEqual(oracle_module.u64(-1), 0xFFFFFFFFFFFFFFFF)
        self.assertEqual(oracle_module.u64((1 << 64) + 7), 7)
        self.assertEqual(oracle_module.asr32(0xFF800000, 23), -1)
        self.assertEqual(oracle_module.asr32(0x80000000, 31), -1)


class DagTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.manifest = oracle_module.load_manifest(MANIFEST)
        cls.oracle = oracle_module.AorOracle(cls.manifest)

    def test_fixed_obvious_results(self) -> None:
        cases = (
            (self.oracle.exp32, 0x00000000, 0x3F800000, ()),
            (self.oracle.exp32, 0x80000000, 0x3F800000, ()),
            (self.oracle.exp32, 0x00000001, 0x3F800000, ("NX",)),
            (self.oracle.exp32, 0x80000001, 0x3F800000, ("NX",)),
            (self.oracle.exp32, 0xFF800000, 0x00000000, ()),
            (self.oracle.exp32, 0x7F800000, 0x7F800000, ()),
            (self.oracle.log32, 0x3F800000, 0x00000000, ()),
            (self.oracle.log32, 0x00000000, 0xFF800000, ("DZ",)),
            (self.oracle.log32, 0x80000000, 0xFF800000, ("DZ",)),
            (self.oracle.log32, 0x7F800000, 0x7F800000, ()),
        )
        for operation, input_raw, expected_raw, expected_flags in cases:
            result = operation(input_raw)
            self.assertEqual((result.raw, result.api_flags), (expected_raw, expected_flags))

    def test_exp_threshold_strictness(self) -> None:
        overflow_equal = self.oracle.exp32(0x42B17217)
        overflow_above = self.oracle.exp32(0x42B17218)
        underflow_equal = self.oracle.exp32(0xC2CFF1B4)
        underflow_below = self.oracle.exp32(0xC2CFF1B5)
        self.assertNotIn("finite_overflow_helper", [entry["step"] for entry in overflow_equal.trace])
        self.assertEqual((overflow_above.raw, overflow_above.api_flags), (0x7F800000, ("OF", "NX")))
        self.assertIn("finite_overflow_helper", [entry["step"] for entry in overflow_above.trace])
        self.assertNotIn("finite_underflow_helper", [entry["step"] for entry in underflow_equal.trace])
        self.assertEqual((underflow_below.raw, underflow_below.api_flags), (0x00000000, ("UF", "NX")))
        self.assertIn("finite_underflow_helper", [entry["step"] for entry in underflow_below.trace])
        self.assertNotIn("finite_overflow_helper", [entry["step"] for entry in self.oracle.exp32(0x42AFFFFF).trace])
        self.assertNotIn("finite_overflow_helper", [entry["step"] for entry in self.oracle.exp32(0x42B00000).trace])

    def test_exp_table_indices_and_modulo_boundaries(self) -> None:
        observed: set[int] = set()
        for k in range(32):
            raw = self.oracle.exp_input_for_k(k)
            result = self.oracle.exp32(raw)
            scale = [entry for entry in result.trace if entry["step"] == "scale"]
            self.assertEqual(len(scale), 1)
            observed.add(scale[0]["index"])
        self.assertEqual(observed, set(range(32)))
        for k in (-33, -32, -1, 0, 31, 32, 33):
            raw = self.oracle.exp_input_for_k(k)
            result = self.oracle.exp32(raw)
            scale = [entry for entry in result.trace if entry["step"] == "scale"][0]
            self.assertEqual(scale["index"], oracle_module.u64(k) & 31)

    def test_log_table_indices_and_subnormal_normalization(self) -> None:
        observed: set[int] = set()
        for index in range(16):
            raw = oracle_module.u32(0x3F330000 + (index << 19))
            result = self.oracle.log32(raw)
            bits = [entry for entry in result.trace if entry["step"] == "range_reduce_bits"]
            self.assertEqual(len(bits), 1)
            observed.add(bits[0]["index"])
        self.assertEqual(observed, set(range(16)))
        leading_positions: set[int] = set()
        for leading in range(23):
            result = self.oracle.log32(1 << leading)
            normalized = [entry for entry in result.trace if entry["step"] == "subnormal_normalize"]
            self.assertEqual(len(normalized), 1)
            leading_positions.add(normalized[0]["leading_one"])
        self.assertEqual(leading_positions, set(range(23)))

    def test_nan_and_negative_domain_fail_closed(self) -> None:
        cases = (
            (self.oracle.exp32, 0x7FC00001, ()),
            (self.oracle.exp32, 0x7F800001, ("NV",)),
            (self.oracle.log32, 0x7FC00001, ()),
            (self.oracle.log32, 0x7F800001, ("NV",)),
            (self.oracle.log32, 0xBF800000, ("NV",)),
            (self.oracle.log32, 0xFF800000, ("NV",)),
        )
        for operation, raw, flags in cases:
            with self.assertRaises(oracle_module.NanEvidenceError) as caught:
                operation(raw)
            self.assertEqual(caught.exception.code, "NAN_RAW_EVIDENCE_REQUIRED")
            self.assertEqual(caught.exception.flags, flags)

    def test_trace_order_and_sticky_flags(self) -> None:
        exp_result = self.oracle.exp32(0x3F800000)
        exp_steps = [entry["step"] for entry in exp_result.trace]
        self.assertEqual(exp_steps, ["classify", "xd", "z", "kd", "k", "r", "scale", "p01", "r2", "p2", "p", "y", "out"])
        z_entry = [entry for entry in exp_result.trace if entry["step"] == "z"][0]
        kd_entry = [entry for entry in exp_result.trace if entry["step"] == "kd"][0]
        k_entry = [entry for entry in exp_result.trace if entry["step"] == "k"][0]
        self.assertTrue(kd_entry["discarded"])
        self.assertTrue(k_entry["discarded"])
        self.assertEqual(k_entry["source"], "z")
        self.assertEqual(k_entry["source_raw"], z_entry["raw"])
        self.assertFalse(oracle_module.f64_to_i32_rmm(oracle_module.parse_raw(kd_entry["raw"], 64)).discarded)
        negative_tiny = self.oracle.exp32(0x80000001)
        negative_kd = [entry for entry in negative_tiny.trace if entry["step"] == "kd"][0]
        negative_k = [entry for entry in negative_tiny.trace if entry["step"] == "k"][0]
        self.assertEqual(negative_kd["raw"], "0x8000000000000000")
        self.assertTrue(negative_k["discarded"])
        self.assertEqual(negative_k["value"], 0)
        sticky = set()
        for entry in exp_result.trace:
            sticky.update(entry["step_flags"])
        self.assertEqual(set(exp_result.api_flags), sticky)
        log_result = self.oracle.log32(0x3F000000)
        log_steps = [entry["step"] for entry in log_result.trace]
        self.assertEqual(log_steps, ["classify", "range_reduce_bits", "z", "r", "k64", "y0", "r2", "q0", "q1", "tail", "y", "out"])


class MutationTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.manifest = oracle_module.load_manifest(MANIFEST)
        cls.oracle = oracle_module.AorOracle(cls.manifest)
        cls.outcomes = {entry["mutation"]: entry for entry in cls.manifest["mutation_audit"]["outcomes"]}

    def test_fixed_first_witnesses(self) -> None:
        for mutation in ("M09", "M10", "M12", "M23", "M24", "M26"):
            expected = self.outcomes[mutation]
            self.assertEqual(expected["status"], "WITNESS")
            input_raw = oracle_module.parse_raw(expected["witness"]["input_raw32"], 32)
            if mutation in oracle_module.LOG_MUTATION_DEFINITIONS:
                observed = self.oracle.log_mutation_probe(input_raw, mutation)
            else:
                observed = self.oracle.exp_mutation_probe(input_raw, mutation)
            self.assertIsNotNone(observed)
            assert observed is not None
            for key in (
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
            ):
                self.assertEqual(observed[key], expected["witness"][key], msg=mutation + ":" + key)

    def test_m11_gap_is_bounded_not_equivalence(self) -> None:
        gap = self.outcomes["M11"]
        self.assertEqual(gap["status"], "GAP_NO_WITNESS_IN_BOUNDED_DOMAIN")
        self.assertEqual(gap["candidates_examined"], 71698)
        domain = self.manifest["mutation_audit"]["exp_domain"]
        self.assertEqual(domain["raw_candidate_union_count"], 73746)
        self.assertEqual(len(oracle_module._exp_search_candidates()), 73746)
        self.assertEqual(self.manifest["mutation_audit"]["witness_count"], 6)
        self.assertEqual(self.manifest["mutation_audit"]["gap_count"], 1)

    def test_mutation_definition_and_domain_binding(self) -> None:
        self.assertEqual(list(oracle_module.EXP_MUTATION_DEFINITIONS), ["M09", "M10", "M11", "M12"])
        self.assertEqual(list(oracle_module.LOG_MUTATION_DEFINITIONS), ["M23", "M24", "M26"])
        log_domain = self.manifest["mutation_audit"]["log_domain"]
        self.assertEqual(log_domain["table_base_inclusive_radius_raw"], 2048)
        self.assertEqual(log_domain["subnormal_inclusive_radius_raw"], 64)
        self.assertEqual(len(log_domain["positive_subnormal_seeds_raw32"]), 6)


class ManifestAndCliTests(unittest.TestCase):
    def assert_stable_cli_failure(self, completed: subprocess.CompletedProcess[str]) -> dict[str, object]:
        self.assertEqual(completed.returncode, 2, msg=completed.stdout + completed.stderr)
        self.assertEqual(completed.stdout, "")
        self.assertNotIn("Traceback", completed.stderr)
        lines = completed.stderr.splitlines()
        self.assertEqual(len(lines), 1, msg=completed.stderr)
        payload = parse_strict_object(lines[0])
        self.assertEqual(set(payload), {"marker", "code", "message", "flags"})
        self.assertEqual(payload["marker"], "[AOR-F32-ORACLE][FAIL]")
        self.assertIs(type(payload["code"]), str)
        self.assertIs(type(payload["message"]), str)
        self.assertIs(type(payload["flags"]), list)
        return payload

    def test_manifest_hash_and_no_json_real_numbers(self) -> None:
        manifest = oracle_module.load_manifest(MANIFEST)
        self.assertEqual(oracle_module.validate_manifest(manifest), oracle_module.EXPECTED_MANIFEST_SHA256)
        pending = [manifest]
        forbidden_type_name = "fl" + "oat"
        while pending:
            value = pending.pop()
            self.assertNotEqual(type(value).__name__, forbidden_type_name)
            if isinstance(value, dict):
                pending.extend(value.values())
            elif isinstance(value, list):
                pending.extend(value)

    def test_manifest_mutations_fail_closed(self) -> None:
        original = oracle_module.load_manifest(MANIFEST)
        mutations = []
        item = copy.deepcopy(original)
        item["profile"] = "WRONG"
        mutations.append(item)
        item = copy.deepcopy(original)
        item["source"]["commit"] = "0" * 40
        mutations.append(item)
        item = copy.deepcopy(original)
        item["exp32"]["table_raw64"][0] = "0x3ff0000000000001"
        mutations.append(item)
        item = copy.deepcopy(original)
        item["log32"]["dag"][0] = "changed"
        mutations.append(item)
        item = copy.deepcopy(original)
        item["nan_target_evidence"]["fpcr_raw"] = "0x0000000000000000"
        mutations.append(item)
        item = copy.deepcopy(original)
        item["flags_profile"]["revision"] = "WRONG"
        mutations.append(item)
        item = copy.deepcopy(original)
        item["mutation_audit"]["outcomes"][2]["status"] = "WITNESS"
        mutations.append(item)
        for mutation in mutations:
            with self.assertRaises(oracle_module.ManifestError):
                oracle_module.validate_manifest(mutation)

    def test_duplicate_key_and_json_real_number_rejected(self) -> None:
        TMP_BUILD.mkdir(parents=True, exist_ok=True)
        duplicate = TMP_BUILD.joinpath("manifest-duplicate.json")
        real_number = TMP_BUILD.joinpath("manifest-real-number.json")
        duplicate.write_text('{"schema":"a","schema":"b"}\n', encoding="utf-8")
        real_number.write_text('{"schema":"a","value":1.25}\n', encoding="utf-8")
        with self.assertRaises(oracle_module.ManifestError) as duplicate_error:
            oracle_module.load_manifest(duplicate)
        with self.assertRaises(oracle_module.ManifestError) as real_error:
            oracle_module.load_manifest(real_number)
        self.assertEqual(duplicate_error.exception.code, "DUPLICATE_JSON_KEY")
        self.assertEqual(real_error.exception.code, "JSON_REAL_NUMBER")

    def test_ast_and_import_gate(self) -> None:
        oracle_module.check_integer_only_source(
            SCRIPT.read_text(encoding="utf-8"),
            filename=str(SCRIPT),
            require_complete_imports=True,
        )
        rejected = (
            "value = total / abs(total)\n",
            "value = 2 ** 7\n",
            "import math\n",
            "import json as j\n",
            "from builtins import float as f\nvalue = f(1)\n",
            "import builtins\nvalue = builtins.float(1)\n",
            "import builtins\nvalue = builtins.complex(1)\n",
            "value = float(1)\n",
            "value = complex(1)\n",
            "value = __import__('math')\n",
            "value = eval('1')\n",
            "exec('value=1')\n",
            "value = compile('1', 'x', 'eval')\n",
            "value = 1+2j\n",
            "import json\nvalue = json.loads('1.25')\n",
            "import json\nloads = json.loads\nvalue = loads('1.25')\n",
            "import builtins\nvalue = getattr(builtins, 'float')\n",
        )
        for source in rejected:
            with self.assertRaises(oracle_module.OracleError, msg=source):
                oracle_module.check_integer_only_source(source)
        accepted = (
            "value = total // abs(total)\n",
            "import json\nvalue = json.loads(text, object_pairs_hook=_duplicate_checked_object, parse_float=_reject_json_real, parse_constant=_reject_json_constant)\n",
        )
        for source in accepted:
            oracle_module.check_integer_only_source(source)

    def test_emit_is_reproducible_and_full_special_rejects(self) -> None:
        TMP_BUILD.mkdir(parents=True, exist_ok=True)
        output_a = TMP_BUILD.joinpath("repro-a.jsonl")
        output_b = TMP_BUILD.joinpath("repro-b.jsonl")
        base = ["emit-vectors", "--manifest", str(MANIFEST), "--output"]
        first = run_cli(base + [str(output_a)])
        second = run_cli(base + [str(output_b)])
        self.assertEqual((first.returncode, second.returncode), (0, 0), msg=first.stderr + second.stderr)
        self.assertEqual(output_a.read_bytes(), output_b.read_bytes())
        self.assertNotIn(str(TMP_BUILD).encode("utf-8"), output_a.read_bytes())
        manifest = oracle_module.load_manifest(MANIFEST)
        count, digest = oracle_module.verify_vectors(output_a, oracle_module.AorOracle(manifest))
        self.assertEqual(count, 108)
        self.assertEqual(len(digest), 64)
        blocked = run_cli(base + [str(TMP_BUILD.joinpath("must-not-exist.jsonl")), "--vector-profile", "full-special"])
        self.assertEqual(blocked.returncode, 2)
        self.assertIn("NAN_RAW_EVIDENCE_REQUIRED", blocked.stderr)

    def test_vector_verifier_binds_exact_payload(self) -> None:
        manifest = oracle_module.load_manifest(MANIFEST)
        oracle = oracle_module.AorOracle(manifest)
        original, _ = oracle_module._load_jsonl(VECTORS)
        mutations: list[tuple[str, list[dict[str, object]], bool]] = []

        changed_recipe = copy.deepcopy(original)
        changed_recipe[1]["recipe"] = "tampered recipe"
        mutations.append(("vector-changed-recipe.jsonl", changed_recipe, True))

        replaced_case = copy.deepcopy(original)
        target_index = next(index for index, record in enumerate(replaced_case) if record.get("case_id") == "reject-exp-snan")
        replacement = copy.deepcopy(replaced_case[1])
        replacement["case_id"] = "replacement-for-required-rejection"
        replaced_case[target_index] = replacement
        mutations.append(("vector-replaced-required-case.jsonl", replaced_case, True))

        unknown_field = copy.deepcopy(original)
        unknown_field[1]["unknown"] = "forbidden"
        mutations.append(("vector-unknown-field.jsonl", unknown_field, True))

        reordered = copy.deepcopy(original)
        reordered[1], reordered[2] = reordered[2], reordered[1]
        mutations.append(("vector-reordered.jsonl", reordered, True))

        deleted = copy.deepcopy(original)
        del deleted[1]
        deleted[0]["vector_count"] = 107
        mutations.append(("vector-deleted-case.jsonl", deleted, True))

        boolean_count = copy.deepcopy(original)
        boolean_count[0]["vector_count"] = True
        mutations.append(("vector-boolean-count.jsonl", boolean_count, True))

        missing_newline = copy.deepcopy(original)
        mutations.append(("vector-missing-final-newline.jsonl", missing_newline, False))

        for filename, records, final_newline in mutations:
            path = TMP_BUILD.joinpath(filename)
            write_canonical_jsonl(path, records, final_newline=final_newline)
            with self.assertRaises(oracle_module.OracleError, msg=filename):
                oracle_module.verify_vectors(path, oracle)

    def test_malformed_inputs_return_one_fail_json(self) -> None:
        TMP_BUILD.mkdir(parents=True, exist_ok=True)
        original = oracle_module.load_manifest(MANIFEST)
        manifest_cases: list[tuple[str, bytes]] = []

        table_not_array = copy.deepcopy(original)
        table_not_array["exp32"]["table_raw64"] = 7
        manifest_cases.append(("bad-table-not-array.json", json.dumps(table_not_array, sort_keys=True).encode("utf-8")))

        row_wrong = copy.deepcopy(original)
        row_wrong["log32"]["table_raw64"][0] = ["0x3ff661ec79f8f3be"]
        manifest_cases.append(("bad-log-row.json", json.dumps(row_wrong, sort_keys=True).encode("utf-8")))

        outcome_not_object = copy.deepcopy(original)
        outcome_not_object["mutation_audit"]["outcomes"][0] = 9
        manifest_cases.append(("bad-outcome-not-object.json", json.dumps(outcome_not_object, sort_keys=True).encode("utf-8")))

        boolean_integer = copy.deepcopy(original)
        boolean_integer["exp32"]["table_bits"] = True
        manifest_cases.append(("bad-boolean-integer.json", json.dumps(boolean_integer, sort_keys=True).encode("utf-8")))
        manifest_cases.append(("bad-json-real.json", b'{"schema":1.25}\n'))
        manifest_cases.append(("bad-utf8-manifest.json", b"\xff\xfe"))

        for filename, payload in manifest_cases:
            path = TMP_BUILD.joinpath(filename)
            path.write_bytes(payload)
            result = run_cli(["validate-manifest", "--manifest", str(path)])
            self.assert_stable_cli_failure(result)

        vector_cases = (
            ("bad-utf8-vectors.jsonl", b"\xff\xfe"),
            ("bad-json-vectors.jsonl", b"{\n"),
            ("bad-root-vectors.jsonl", b"[]\n"),
        )
        for filename, payload in vector_cases:
            path = TMP_BUILD.joinpath(filename)
            path.write_bytes(payload)
            result = run_cli(["verify-vectors", "--manifest", str(MANIFEST), "--input", str(path)])
            self.assert_stable_cli_failure(result)

    def test_checked_in_vectors_verify(self) -> None:
        manifest = oracle_module.load_manifest(MANIFEST)
        count, digest = oracle_module.verify_vectors(VECTORS, oracle_module.AorOracle(manifest))
        self.assertEqual(count, 108)
        self.assertEqual(len(digest), 64)


if __name__ == "__main__":
    suite = unittest.defaultTestLoader.loadTestsFromModule(sys.modules[__name__])
    result = unittest.TextTestRunner(verbosity=2).run(suite)
    if result.wasSuccessful():
        print(
            json.dumps(
                {
                    "command": "unit-test",
                    "marker": "[AOR-F32-TEST][PASS]",
                    "tests": result.testsRun,
                },
                sort_keys=True,
                separators=(",", ":"),
            )
        )
        raise SystemExit(0)
    raise SystemExit(1)
