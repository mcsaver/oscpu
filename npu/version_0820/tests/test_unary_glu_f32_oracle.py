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


sys.dont_write_bytecode = True
REPO_ROOT = Path(__file__).resolve().parent.parent
SCRIPTS = REPO_ROOT.joinpath("scripts")
if str(SCRIPTS) not in sys.path:
    sys.path.insert(0, str(SCRIPTS))

SCRIPT = SCRIPTS.joinpath("unary_glu_f32_oracle.py")
MANIFEST = REPO_ROOT.joinpath("tests", "vectors", "unary_glu_f32_manifest.json")
VECTORS = REPO_ROOT.joinpath("tests", "vectors", "unary_glu_f32_vectors.jsonl")
TMP_BUILD = REPO_ROOT.joinpath("tmp", "build", "unary-glu-f32-oracle")
EVIDENCE = REPO_ROOT.joinpath("tmp", "logs", "unary-glu-f32-oracle", "final-evidence.json")

MODULE_SPEC = importlib.util.spec_from_file_location("unary_glu_f32_oracle", SCRIPT)
if MODULE_SPEC is None or MODULE_SPEC.loader is None:
    raise RuntimeError("cannot load unary/GLU oracle module")
oracle_module = importlib.util.module_from_spec(MODULE_SPEC)
sys.modules[MODULE_SPEC.name] = oracle_module
MODULE_SPEC.loader.exec_module(oracle_module)
# The unit entrypoint executes the same immutable-on-disk production gate before
# any test can replace module attributes or monkeypatch a checker function.
oracle_module.enforce_production_source_gate()


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


def strict_object(text: str) -> dict[str, object]:
    value = json.loads(
        text,
        object_pairs_hook=oracle_module._duplicate_checked_object,
        parse_float=oracle_module._reject_json_real,
        parse_constant=oracle_module._reject_json_constant,
    )
    if type(value) is not dict:
        raise AssertionError("strict JSON value is not an object")
    return value


def write_jsonl(path: Path, records: list[dict[str, object]], final_newline: bool = True) -> None:
    payload = b"\n".join(oracle_module.canonical_bytes(record) for record in records)
    if final_newline:
        payload += b"\n"
    path.write_bytes(payload)


class PrimitiveTests(unittest.TestCase):
    def test_add_operational_boundaries(self) -> None:
        cases = (
            (0x00000000, 0x80000000, 0x00000000, ()),
            (0x80000000, 0x80000000, 0x80000000, ()),
            (0x3F800000, 0xBF800000, 0x00000000, ()),
            (0x3F800000, 0x33800000, 0x3F800000, ("NX",)),
            (0x3F800001, 0x33800000, 0x3F800002, ("NX",)),
            (0x7F7FFFFF, 0x7F7FFFFF, 0x7F800000, ("OF", "NX")),
            (0x7F800000, 0xFF800000, 0x7FC00000, ("NV",)),
            (0x7FC12345, 0x3F800000, 0x7FC00000, ()),
            (0x7F800001, 0x3F800000, 0x7FC00000, ("NV",)),
        )
        for lhs, rhs, raw, flags in cases:
            self.assertEqual(oracle_module.f32_add(lhs, rhs), oracle_module.aor.RawResult(raw, flags))

    def test_mul_tininess_after_and_specials(self) -> None:
        cases = (
            (0x00800000, 0x3F7FFFFE, 0x007FFFFF, ()),
            (0x00800000, 0x3F7FFFFF, 0x00800000, ("UF", "NX")),
            (0x80800000, 0x3F7FFFFF, 0x80800000, ("UF", "NX")),
            (0x00000001, 0x3F000000, 0x00000000, ("UF", "NX")),
            (0x7F7FFFFF, 0x40000000, 0x7F800000, ("OF", "NX")),
            (0x00000000, 0x7F800000, 0x7FC00000, ("NV",)),
            (0x80000000, 0x7F800000, 0x7FC00000, ("NV",)),
            (0x7F800000, 0xFF800000, 0xFF800000, ()),
        )
        for lhs, rhs, raw, flags in cases:
            self.assertEqual(oracle_module.f32_mul(lhs, rhs), oracle_module.aor.RawResult(raw, flags))

    def test_div_operational_boundaries_and_specials(self) -> None:
        cases = (
            (0x7F800000, 0x00000000, 0x7F800000, ()),
            (0xFF800000, 0x00000000, 0xFF800000, ()),
            (0x3F800000, 0x00000000, 0x7F800000, ("DZ",)),
            (0xBF800000, 0x00000000, 0xFF800000, ("DZ",)),
            (0x00000000, 0x00000000, 0x7FC00000, ("NV",)),
            (0x7F800000, 0x7F800000, 0x7FC00000, ("NV",)),
            (0x00800000, 0x3F800001, 0x007FFFFF, ("UF", "NX")),
            (0x00800000, 0x3F7FFFFF, 0x00800001, ("NX",)),
            (0x3F800000, 0x40400000, 0x3EAAAAAB, ("NX",)),
        )
        for lhs, rhs, raw, flags in cases:
            self.assertEqual(oracle_module.f32_div(lhs, rhs), oracle_module.aor.RawResult(raw, flags))

    def test_rational_pack_roundtrip_for_finite_raws(self) -> None:
        raws = (
            0x00000001,
            0x007FFFFF,
            0x00800000,
            0x3F800000,
            0xBF800000,
            0x7F7FFFFF,
            0xFF7FFFFF,
        )
        for raw in raws:
            decoded = oracle_module.aor.decode_f32(raw)
            packed = oracle_module.pack_f32_rational(
                decoded.sign,
                decoded.magnitude,
                1,
                decoded.exponent,
            )
            self.assertEqual(packed, oracle_module.aor.RawResult(raw, ()))

    def test_primitive_commutative_operand_order(self) -> None:
        add_ab = oracle_module.f32_add(0x3F800001, 0x33800000)
        add_ba = oracle_module.f32_add(0x33800000, 0x3F800001)
        mul_ab = oracle_module.f32_mul(0x00800000, 0x3F7FFFFF)
        mul_ba = oracle_module.f32_mul(0x3F7FFFFF, 0x00800000)
        self.assertEqual(add_ab, add_ba)
        self.assertEqual(mul_ab, mul_ba)


class DagTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.manifest = oracle_module.load_manifest(MANIFEST)
        cls.oracle = oracle_module.TensorUnaryGluOracle(cls.manifest)

    def test_exact_child_opcode_and_materialization_order(self) -> None:
        cases = (
            ("SIGMOID", 0x3F800000, None, ("AOR_EXP32", "FP32_ADD_RNE", "FP32_DIV_RNE"), ("e", "d", "y")),
            ("SOFTPLUS", 0x3F800000, None, ("AOR_EXP32", "FP32_ADD_RNE", "AOR_LOG32"), ("e", "d", "y")),
            ("SILU", 0x3F800000, None, ("AOR_EXP32", "FP32_ADD_RNE", "FP32_DIV_RNE"), ("e", "d", "y")),
            ("SWIGLU", 0x3F800000, 0x40000000, ("AOR_EXP32", "FP32_ADD_RNE", "FP32_DIV_RNE", "FP32_MUL_RNE"), ("e", "d", "s", "y")),
        )
        for operation, src0, src1, opcodes, names in cases:
            result = self.oracle.evaluate(operation, src0, src1)
            self.assertEqual(result.status, "OK")
            self.assertEqual(result.commit_count, 1)
            self.assertEqual(tuple(child["opcode"] for child in result.children), opcodes)
            self.assertEqual(tuple(child["materialized"] for child in result.children), names)
            self.assertEqual(tuple(child["child_index"] for child in result.children), tuple(range(len(opcodes))))

    def test_negative_100_internal_infinity_is_legal(self) -> None:
        sigmoid = self.oracle.evaluate("SIGMOID", 0xC2C80000)
        silu = self.oracle.evaluate("SILU", 0xC2C80000)
        self.assertEqual((sigmoid.raw, sigmoid.flags), (0x00000000, ("OF", "NX")))
        self.assertEqual((silu.raw, silu.flags), (0x80000000, ("OF", "NX")))
        for result in (sigmoid, silu):
            self.assertEqual(result.status, "OK")
            self.assertEqual(result.commit_count, 1)
            self.assertEqual(len(result.children), 3)
            self.assertEqual(result.children[0]["result_raw32"], "0x7f800000")
            self.assertEqual(result.children[0]["flags"], ["OF", "NX"])

    def test_softplus_strict_twenty_threshold(self) -> None:
        below = self.oracle.evaluate("SOFTPLUS", 0x419FFFFF)
        equal = self.oracle.evaluate("SOFTPLUS", 0x41A00000)
        above = self.oracle.evaluate("SOFTPLUS", 0x41A00001)
        negative = self.oracle.evaluate("SOFTPLUS", 0xC1A00000)
        self.assertEqual(tuple(len(item.children) for item in (below, equal, above, negative)), (3, 3, 0, 3))
        self.assertEqual(above.raw, 0x41A00001)
        self.assertEqual(above.flags, ())
        self.assertEqual(above.commit_count, 1)

    def test_minimum_subnormal_and_sticky_flags(self) -> None:
        for operation in ("SIGMOID", "SOFTPLUS", "SILU"):
            for raw in (0x00000001, 0x80000001):
                result = self.oracle.evaluate(operation, raw)
                sticky: set[str] = set()
                for child in result.children:
                    sticky.update(child["flags"])
                self.assertEqual(tuple(name for name in oracle_module.FLAG_ORDER if name in sticky), result.flags)
                self.assertIn("NX", result.flags)

    def test_swiglu_signed_zero_and_source_roles(self) -> None:
        positive = self.oracle.evaluate("SWIGLU", 0x00000000, 0x3F800000)
        negative = self.oracle.evaluate("SWIGLU", 0x80000000, 0x3F800000)
        gate_negative = self.oracle.evaluate("SWIGLU", 0x00000000, 0xBF800000)
        role_a = self.oracle.evaluate("SWIGLU", 0x3F800000, 0x40000000)
        role_b = self.oracle.evaluate("SWIGLU", 0x40000000, 0x3F800000)
        self.assertEqual((positive.raw, negative.raw, gate_negative.raw), (0x00000000, 0x80000000, 0x80000000))
        self.assertNotEqual(role_a.raw, role_b.raw)
        self.assertEqual(role_a.children[2]["operands_raw32"][0], "0x3f800000")
        self.assertEqual(role_a.children[3]["operands_raw32"][1], "0x40000000")

    def test_external_nonfinite_preflight_zero_child_zero_commit(self) -> None:
        specials = (0x7F800000, 0xFF800000, 0x7FC12345, 0x7F800001)
        for operation in oracle_module.OPERATIONS:
            for raw in specials:
                result = self.oracle.evaluate(operation, raw, 0x3F800000 if operation == "SWIGLU" else None)
                self.assertEqual((result.status, result.raw, result.flags, len(result.children), result.commit_count), ("UNSUPPORTED", 0, (), 0, 0))
                self.assertEqual(result.reason, "NONFINITE_SRC0")
        for raw in specials:
            result = self.oracle.evaluate("SWIGLU", 0x3F800000, raw)
            self.assertEqual((result.status, result.raw, result.flags, len(result.children), result.commit_count), ("UNSUPPORTED", 0, (), 0, 0))
            self.assertEqual(result.reason, "NONFINITE_SRC1")

    def test_finite_swiglu_overflow_is_success(self) -> None:
        positive = self.oracle.evaluate("SWIGLU", 0x7F7FFFFF, 0x40000000)
        negative = self.oracle.evaluate("SWIGLU", 0x7F7FFFFF, 0xC0000000)
        self.assertEqual((positive.status, positive.raw, positive.commit_count), ("OK", 0x7F800000, 1))
        self.assertEqual((negative.status, negative.raw, negative.commit_count), ("OK", 0xFF800000, 1))
        self.assertIn("OF", positive.flags)
        self.assertIn("OF", negative.flags)


class MutationTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        manifest = oracle_module.load_manifest(MANIFEST)
        cls.oracle = oracle_module.TensorUnaryGluOracle(manifest)
        cls.audit = oracle_module.audit_mutations(cls.oracle)
        cls.outcomes = {item["mutation_id"]: item for item in cls.audit["outcomes"]}

    def test_bounded_search_records_all_three_outcomes(self) -> None:
        self.assertEqual(list(self.outcomes), ["SILU_RECIPROCAL_MUL", "SWIGLU_NUMERATOR_FIRST", "SWIGLU_ROLE_SWAP"])
        self.assertGreater(self.audit["search_domain_unique_finite_candidates"], 0)
        self.assertEqual(self.audit["witness_count"] + self.audit["gap_count"], 3)
        self.assertEqual(self.audit["search_domain_unique_finite_candidates"], 69652)
        self.assertEqual(self.audit["search_domain_swiglu_pair_count"], 696520)
        self.assertEqual(self.audit["search_domain_role_pair_count"], 4)
        for outcome in self.audit["outcomes"]:
            self.assertGreater(outcome["candidates_examined"], 0)
            self.assertEqual(outcome["eligible_candidates"], outcome["candidates_examined"])
            self.assertIn(outcome["status"], ("WITNESS", "GAP_NO_WITNESS_IN_BOUNDED_DOMAIN"))

    def test_witnesses_replay_exact_raw(self) -> None:
        silu = self.outcomes["SILU_RECIPROCAL_MUL"]
        swiglu = self.outcomes["SWIGLU_NUMERATOR_FIRST"]
        role = self.outcomes["SWIGLU_ROLE_SWAP"]
        if silu["status"] == "WITNESS":
            witness = silu["witness"]
            observed = oracle_module.silu_reciprocal_mutation_probe(self.oracle, oracle_module.parse_raw32(witness["input_raw32"]))
            self.assertEqual(observed, witness)
            self.assertIn("final_raw32", witness["difference_fields"])
            self.assertEqual((witness["strict_child_count"], witness["mutant_child_count"]), (3, 4))
            self.assertEqual(witness["mutant_child_opcodes"][-2:], ["FP32_DIV_RNE", "FP32_MUL_RNE"])
        if swiglu["status"] == "WITNESS":
            witness = swiglu["witness"]
            observed = oracle_module.swiglu_numerator_first_mutation_probe(
                self.oracle,
                oracle_module.parse_raw32(witness["src0_raw32"]),
                oracle_module.parse_raw32(witness["src1_raw32"]),
            )
            self.assertEqual(observed, witness)
            self.assertIn("final_raw32", witness["difference_fields"])
            self.assertEqual((witness["strict_child_count"], witness["mutant_child_count"]), (4, 4))
            self.assertEqual(witness["strict_child_opcodes"][-2:], ["FP32_DIV_RNE", "FP32_MUL_RNE"])
            self.assertEqual(witness["mutant_child_opcodes"][-2:], ["FP32_MUL_RNE", "FP32_DIV_RNE"])
        self.assertEqual(role["status"], "WITNESS")
        witness = role["witness"]
        observed = oracle_module.swiglu_role_swap_mutation_probe(
            self.oracle,
            oracle_module.parse_raw32(witness["src0_raw32"]),
            oracle_module.parse_raw32(witness["src1_raw32"]),
        )
        self.assertEqual(observed, witness)
        self.assertEqual((witness["src0_role"], witness["src1_role"]), ("NONLINEAR_GATE", "LINEAR_UP"))


class ManifestVectorCliTests(unittest.TestCase):
    def assert_stable_failure(self, completed: subprocess.CompletedProcess[str]) -> dict[str, object]:
        self.assertEqual(completed.returncode, 2, msg=completed.stdout + completed.stderr)
        self.assertEqual(completed.stdout, "")
        self.assertNotIn("Traceback", completed.stderr)
        lines = completed.stderr.splitlines()
        self.assertEqual(len(lines), 1, msg=completed.stderr)
        value = strict_object(lines[0])
        self.assertEqual(set(value), {"code", "flags", "marker", "message"})
        self.assertEqual(value["marker"], oracle_module.FAIL_MARKER)
        self.assertIs(type(value["code"]), str)
        self.assertIs(type(value["flags"]), list)
        self.assertIs(type(value["message"]), str)
        return value

    def test_manifest_identity_and_integer_json_tree(self) -> None:
        manifest = oracle_module.load_manifest(MANIFEST)
        self.assertEqual(oracle_module.validate_manifest(manifest), oracle_module.EXPECTED_MANIFEST_SHA256)
        pending: list[object] = [manifest]
        forbidden_type_name = "fl" + "oat"
        while pending:
            value = pending.pop()
            self.assertNotEqual(type(value).__name__, forbidden_type_name)
            if type(value) is dict:
                pending.extend(value.values())
            elif type(value) is list:
                pending.extend(value)

    def test_manifest_mutations_fail_closed(self) -> None:
        original = oracle_module.load_manifest(MANIFEST)
        mutations: list[dict[str, object]] = []
        for path, value in (
            (("profile",), "WRONG"),
            (("constants_raw32", "one"), "0x3f800001"),
            (("flags_profile", "tininess"), "WRONG"),
            (("operations", "SILU", "dag"), ["changed"]),
            (("aor_binding", "generator_sha256"), "0" * 64),
        ):
            item = copy.deepcopy(original)
            cursor: dict[str, object] = item
            for key in path[:-1]:
                next_value = cursor[key]
                self.assertIs(type(next_value), dict)
                cursor = next_value
            cursor[path[-1]] = value
            mutations.append(item)
        for mutation in mutations:
            with self.assertRaises(oracle_module.ManifestError):
                oracle_module.validate_manifest(mutation)

    def test_json_duplicate_real_and_invalid_utf8_are_stable_failures(self) -> None:
        TMP_BUILD.mkdir(parents=True, exist_ok=True)
        cases = (
            ("duplicate.json", b'{"schema":"a","schema":"b"}\n'),
            ("real.json", b'{"schema":"a","value":1.25}\n'),
            ("utf8.json", b"\xff\xfe"),
            ("root.json", b"[]\n"),
        )
        for name, payload in cases:
            path = TMP_BUILD.joinpath(name)
            path.write_bytes(payload)
            result = run_cli(["validate-manifest", "--manifest", str(path)])
            self.assert_stable_failure(result)

    def test_integer_only_ast_and_import_gate(self) -> None:
        oracle_module.check_integer_only_source(
            SCRIPT.read_text(encoding="utf-8"),
            filename=str(SCRIPT),
            require_complete_imports=True,
        )
        rejected = (
            "value = total / abs(total)\n",
            "value = 2 ** 7\n",
            "import math\n",
            "import aor_f32_oracle\n",
            "import aor_f32_oracle as other\n",
            "from aor_f32_oracle import pack_f32\n",
            "from builtins import float as host_real\n",
            "import builtins\nvalue = builtins.float(1)\n",
            "value = float(1)\n",
            "value = complex(1)\n",
            "value = __import__('math')\n",
            "value = eval('1')\n",
            "exec('value=1')\n",
            "value = compile('1','x','eval')\n",
            "value = 1+2j\n",
            "import json\nvalue=json.loads('1.25')\n",
            "import json\nloads=json.loads\nvalue=loads('1.25')\n",
            "import json\nnamespace=json\nvalue=namespace.loads('1.25')\n",
            "import json\nnamespace=json.__dict__\nvalue=namespace['loads']('1.25')\n",
            "import json\nname='loads'\nvalue=json.__dict__[name]('1.25')\n",
            "import sys\nname='builtins'\nnamespace=sys.modules[name].__dict__\nvalue=namespace['float'](1)\n",
            "import json\nvalue=getattr(json,'loads')('1.25')\n",
            "import json\nvalue=vars(json)['loads']('1.25')\n",
            "value=globals()['float'](1)\n",
            "value=locals()['complex'](1)\n",
            "value=().__class__.__base__.__subclasses__()\n",
            "name='float'\nvalue=__builtins__[name](1)\n",
            "def float(value):\n    return value\nvalue=float(1)\n",
            "def complex(value):\n    return value\nvalue=complex(1)\n",
        )
        for source in rejected:
            with self.assertRaises(oracle_module.OracleError, msg=source):
                oracle_module.check_integer_only_source(source)
        oracle_module.check_integer_only_source(
            "import json\nvalue=json.loads(text,object_pairs_hook=_duplicate_checked_object,parse_float=_reject_json_real,parse_constant=_reject_json_constant)\n"
        )

    def test_emit_reproducible_and_checked_in_vectors(self) -> None:
        TMP_BUILD.mkdir(parents=True, exist_ok=True)
        first = TMP_BUILD.joinpath("vectors-first.jsonl")
        second = TMP_BUILD.joinpath("vectors-second.jsonl")
        a = run_cli(["emit-vectors", "--output", str(first)], timeout_seconds=45)
        b = run_cli(["emit-vectors", "--output", str(second)], timeout_seconds=45)
        self.assertEqual((a.returncode, b.returncode), (0, 0), msg=a.stderr + b.stderr)
        self.assertEqual(first.read_bytes(), second.read_bytes())
        manifest = oracle_module.load_manifest(MANIFEST)
        oracle = oracle_module.TensorUnaryGluOracle(manifest)
        count, digest = oracle_module.verify_vectors(first, oracle)
        self.assertEqual(count, len(oracle_module._qualified_recipes()))
        self.assertEqual(len(digest), 64)
        checked_count, checked_digest = oracle_module.verify_vectors(VECTORS, oracle)
        self.assertEqual((checked_count, checked_digest), (count, digest))

    def test_vector_required_membership_and_trace_fields(self) -> None:
        manifest = oracle_module.load_manifest(MANIFEST)
        records = oracle_module.build_vector_records(oracle_module.TensorUnaryGluOracle(manifest))
        cases = {record["case_id"]: record for record in records[1:]}
        required = {
            "sigmoid-negative-100-internal-inf",
            "silu-negative-100-internal-inf",
            "softplus-below-twenty",
            "softplus-equal-twenty",
            "softplus-above-twenty",
            "softplus-negative-twenty",
            "mutation-silu-reciprocal-mul-first-witness",
            "mutation-swiglu-numerator-first-witness",
            "primitive-mul-minnormal-roundup-tiny-positive",
            "primitive-mul-minnormal-roundup-tiny-negative",
            "swiglu-finite-overflow-positive",
            "reject-sigmoid-src0-positive-infinity",
            "reject-swiglu-src1-signaling-nan",
        }
        self.assertTrue(required.issubset(cases))
        self.assertEqual(cases["softplus-equal-twenty"]["child_count"], 3)
        self.assertEqual(cases["softplus-above-twenty"]["child_count"], 0)
        overflow = cases["swiglu-finite-overflow-positive"]
        self.assertEqual(overflow["expected_error"], 0)
        self.assertEqual(
            [child["opcode"] for child in overflow["children"]],
            ["AOR_EXP32", "FP32_ADD_RNE", "FP32_DIV_RNE", "FP32_MUL_RNE"],
        )
        self.assertEqual(overflow["expected_raw32"], "0x7f800000")
        self.assertTrue({"OF", "NX"}.issubset(overflow["sticky_flags"]))
        rejected = cases["reject-sigmoid-src0-positive-infinity"]
        self.assertEqual((rejected["expected_raw32"], rejected["child_count"], rejected["commit_count"]), ("0x00000000", 0, 0))
        for case in cases.values():
            self.assertEqual(case["child_count"], len(case["children"]))
            for index, child in enumerate(case["children"]):
                self.assertEqual(child["child_index"], index)
                self.assertIn("result_raw32", child)
                self.assertIn("flags", child)

    def test_vector_exact_payload_mutations_fail(self) -> None:
        manifest = oracle_module.load_manifest(MANIFEST)
        oracle = oracle_module.TensorUnaryGluOracle(manifest)
        records, _ = oracle_module._load_jsonl(VECTORS)
        mutations: list[tuple[str, list[dict[str, object]], bool]] = []

        changed_recipe = copy.deepcopy(records)
        changed_recipe[1]["recipe"] = "changed"
        mutations.append(("vector-changed-recipe.jsonl", changed_recipe, True))

        replaced = copy.deepcopy(records)
        required_index = next(index for index, record in enumerate(replaced) if record.get("case_id") == "silu-negative-100-internal-inf")
        replaced[required_index] = copy.deepcopy(replaced[1])
        replaced[required_index]["case_id"] = "replacement"
        mutations.append(("vector-replaced.jsonl", replaced, True))

        unknown = copy.deepcopy(records)
        unknown[1]["unknown"] = "forbidden"
        mutations.append(("vector-unknown.jsonl", unknown, True))

        reordered = copy.deepcopy(records)
        reordered[1], reordered[2] = reordered[2], reordered[1]
        mutations.append(("vector-reordered.jsonl", reordered, True))

        deleted = copy.deepcopy(records)
        del deleted[1]
        deleted[0]["vector_count"] = len(deleted) - 1
        mutations.append(("vector-deleted.jsonl", deleted, True))

        boolean_count = copy.deepcopy(records)
        boolean_count[0]["vector_count"] = True
        mutations.append(("vector-bool.jsonl", boolean_count, True))

        mutations.append(("vector-no-newline.jsonl", copy.deepcopy(records), False))
        for name, values, final_newline in mutations:
            path = TMP_BUILD.joinpath(name)
            write_jsonl(path, values, final_newline)
            with self.assertRaises(oracle_module.OracleError, msg=name):
                oracle_module.verify_vectors(path, oracle)

    def test_malformed_jsonl_returns_one_machine_failure(self) -> None:
        cases = (
            ("vectors-invalid-utf8.jsonl", b"\xff\xfe"),
            ("vectors-invalid-json.jsonl", b"{\n"),
            ("vectors-real.jsonl", b'{"value":1.25}\n'),
            ("vectors-root.jsonl", b"[]\n"),
        )
        for name, payload in cases:
            path = TMP_BUILD.joinpath(name)
            path.write_bytes(payload)
            completed = run_cli(["verify-vectors", "--input", str(path)])
            self.assert_stable_failure(completed)

    def test_evidence_receipt_when_present(self) -> None:
        if not EVIDENCE.exists():
            self.fail("final evidence receipt is required for the fixed unit run")
        evidence, _ = oracle_module._read_strict_object(EVIDENCE, "EVIDENCE_TEST")
        command_records = evidence.get("commands")
        self.assertIs(type(command_records), list)
        bootstrap = any(
            type(record) is dict
            and record.get("id") in ("unit-test", "verify-evidence")
            and record.get("sha256") is None
            for record in command_records
        )
        artifacts, commands = oracle_module.verify_evidence(EVIDENCE, bootstrap_self_log=bootstrap)
        self.assertEqual(artifacts, len(oracle_module.FINAL_ARTIFACT_PATHS))
        self.assertEqual(commands, len(oracle_module.FINAL_COMMAND_SPECS))

        facts = oracle_module.collect_evidence_facts()
        expected = oracle_module.expected_log_payload("unit-test", facts)
        payload_mutations: list[dict[str, object]] = []
        for field, value in (
            ("generator_sha256", "0" * 64),
            ("tests", 22),
            ("marker", oracle_module.PASS_MARKER),
        ):
            changed = copy.deepcopy(expected)
            changed[field] = value
            payload_mutations.append(changed)
        extra = copy.deepcopy(expected)
        extra["unknown"] = "forbidden"
        payload_mutations.append(extra)
        payload_mutations.append(
            {
                "command": "unit-test",
                "marker": oracle_module.TEST_PASS_MARKER,
                "tests": 23,
            }
        )
        payload_mutations.append(oracle_module.expected_log_payload("validate-manifest", facts))
        for changed in payload_mutations:
            changed_bytes = oracle_module.canonical_bytes(changed) + b"\n"
            changed_sha = oracle_module.sha256_bytes(changed_bytes)
            with self.assertRaises(oracle_module.OracleError):
                oracle_module._verify_log_payload_bytes("unit-test", changed_bytes, changed_sha, expected)
        expected_bytes = oracle_module.canonical_bytes(expected) + b"\n"
        with self.assertRaises(oracle_module.OracleError):
            oracle_module._verify_log_payload_bytes(
                "unit-test",
                expected_bytes[:-1],
                oracle_module.sha256_bytes(expected_bytes[:-1]),
                expected,
            )

        unit_index = next(
            index for index, record in enumerate(command_records) if type(record) is dict and record.get("id") == "unit-test"
        )
        for field, value in (
            ("command", "timeout 1s python3 tests/test_unary_glu_f32_oracle.py"),
            ("observed_exec_return_code", True),
            ("observed_exec_return_code_authority", "claimed"),
        ):
            changed_command = copy.deepcopy(command_records[unit_index])
            changed_command[field] = value
            with self.assertRaises(oracle_module.OracleError):
                oracle_module._verify_log_record(
                    changed_command,
                    oracle_module.FINAL_COMMAND_SPECS[unit_index],
                    expected,
                    bootstrap,
                )


if __name__ == "__main__":
    suite = unittest.defaultTestLoader.loadTestsFromModule(sys.modules[__name__])
    result = unittest.TestResult()
    suite.run(result)
    if result.wasSuccessful() and len(result.skipped) == 0:
        facts = oracle_module.collect_evidence_facts()
        payload = oracle_module.expected_log_payload("unit-test", facts)
        if result.testsRun != payload["tests"]:
            raise RuntimeError("executed unittest count differs from the production-derived count")
        print(oracle_module.canonical_bytes(payload).decode("utf-8"))
        raise SystemExit(0)
    first_problem = "NO_DETAIL"
    problems = list(result.failures) + list(result.errors)
    if problems:
        first_problem = problems[0][0].id()
    print(
        json.dumps(
            {
                "command": "unit-test",
                "errors": len(result.errors),
                "failures": len(result.failures),
                "first_problem": first_problem,
                "marker": "[UNARY-GLU-F32-TEST][FAIL]",
                "skipped": len(result.skipped),
                "tests": result.testsRun,
            },
            sort_keys=True,
            separators=(",", ":"),
        ),
        file=sys.stderr,
    )
    raise SystemExit(1)
