#!/usr/bin/env python3
"""Directed tests for the integer-dyadic ordered SUM_ROWS oracle."""

from __future__ import annotations

import ast
import importlib.util
import sys
import unittest
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[3]
SCRIPT_PATH = REPO_ROOT / "npu/version_0820/scripts/ordered_sum_rows_oracle.py"
VECTOR_PATH = REPO_ROOT / "npu/version_0820/tests/vectors/ordered_sum_rows_vectors.jsonl"
SPEC = importlib.util.spec_from_file_location("ordered_sum_rows_oracle", SCRIPT_PATH)
if SPEC is None or SPEC.loader is None:
    raise RuntimeError("cannot load ordered_sum_rows_oracle")
ORACLE = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = ORACLE
SPEC.loader.exec_module(ORACLE)


class OrderedSumRowsOracleTest(unittest.TestCase):
    def test_candidate_membership_and_no_shell_subset(self) -> None:
        identifiers = [item.identifier for item in ORACLE.CANDIDATES]
        self.assertEqual(len(identifiers), 60)
        self.assertEqual(len(set(identifiers)), 60)
        self.assertEqual(identifiers[-1], "D10")
        self.assertEqual(len(identifiers[:-1]), 59)

    def test_all_candidates_match_independent_expected_fields(self) -> None:
        ORACLE.validate_candidates()
        for item in ORACLE.CANDIDATES:
            actual = ORACLE.ordered_sum_row(ORACLE.expand_candidate(item))
            self.assertEqual(actual["result"], item.expected_result, item.identifier)
            self.assertEqual(actual["flags"], item.expected_flags, item.identifier)
            self.assertEqual(actual["add_count"], 128, item.identifier)
            self.assertEqual(actual["consumed"], 128, item.identifier)
            self.assertEqual(len(actual["trace_sha256"]), 64, item.identifier)

    def test_rne_integer_shift(self) -> None:
        self.assertEqual(ORACLE.round_shift_rne(0b100, 1), (0b10, False))
        self.assertEqual(ORACLE.round_shift_rne(0b101, 1), (0b10, True))
        self.assertEqual(ORACLE.round_shift_rne(0b111, 1), (0b100, True))
        self.assertEqual(ORACLE.round_shift_rne(3, -2), (12, False))

    def test_special_and_tininess_anchors(self) -> None:
        self.assertEqual(
            ORACLE.widen_f32(0x7F800001),
            (ORACLE.F64_CANONICAL_NAN, ORACLE.FLAG_NV),
        )
        self.assertEqual(
            ORACLE.add_f64(0x7FF0000000000000, 0xFFF0000000000000),
            (ORACLE.F64_CANONICAL_NAN, ORACLE.FLAG_NV),
        )
        self.assertEqual(
            ORACLE.narrow_f64(0x36A0000000000000),
            (0x00000001, 0),
        )
        self.assertEqual(
            ORACLE.narrow_f64(0x0000000000000001),
            (0x00000000, ORACLE.FLAG_UF | ORACLE.FLAG_NX),
        )

    def test_fixed_profile_flags_have_no_dz_or_true_uf(self) -> None:
        for item in ORACLE.CANDIDATES:
            actual = ORACLE.ordered_sum_row(ORACLE.expand_candidate(item))
            flags = int(actual["flags"])
            self.assertEqual(flags & ORACLE.FLAG_DZ, 0, item.identifier)
            self.assertEqual(flags & ORACLE.FLAG_UF, 0, item.identifier)

    def test_all_mutations_have_machine_selected_witness(self) -> None:
        witnesses = ORACLE.mutation_witnesses()
        rows = ORACLE.mutation_audit_rows()
        self.assertEqual(set(witnesses), set(ORACLE.MUTATIONS))
        self.assertEqual(len(witnesses), 10)
        for mutation_name, identifier in witnesses.items():
            row = rows[identifier]
            correct = ORACLE.ordered_sum_row(row)
            mutant_result, mutant_flags = ORACLE.MUTATIONS[mutation_name](row)
            self.assertNotEqual(
                (mutant_result, mutant_flags),
                (correct["result"], correct["flags"]),
                mutation_name,
            )

    def test_all_mutation_labels_have_distinct_full_vector_behavior(self) -> None:
        signatures = ORACLE.mutation_behavior_signatures()
        self.assertEqual(len(signatures), 10)
        self.assertEqual(len(set(signatures.values())), 10)
        witnesses = ORACLE.mutation_witnesses()
        # The formerly aliased labels now fail for independent structural
        # reasons: signed-zero seeding versus omission of the last element.
        self.assertEqual(witnesses["x0_seed"], "Z1")
        self.assertEqual(witnesses["127_add"], "C1")
        self.assertEqual(witnesses["intermediate_narrow"], "M0")
        self.assertNotEqual(signatures["x0_seed"], signatures["127_add"])
        self.assertNotEqual(
            signatures["intermediate_narrow"],
            signatures["f32_accumulator"],
        )

    def test_m0_is_synthetic_and_three_way_discriminating(self) -> None:
        self.assertEqual(set(ORACLE.MUTATION_ONLY_ROWS), {"M0"})
        self.assertNotIn("M0", {item.identifier for item in ORACLE.CANDIDATES})
        self.assertEqual(len(ORACLE.mutation_audit_rows()), 61)
        outcomes = ORACLE.mutation_m0_outcomes()
        self.assertEqual(outcomes["production"], (0x4B800002, ORACLE.FLAG_NX))
        self.assertEqual(
            outcomes["intermediate_narrow"],
            (0x4B800001, ORACLE.FLAG_NX),
        )
        self.assertEqual(
            outcomes["f32_accumulator"],
            (0x4B800000, ORACLE.FLAG_NX),
        )
        self.assertEqual(len(set(outcomes.values())), 3)

    def test_checked_in_vectors_are_canonical(self) -> None:
        self.assertTrue(VECTOR_PATH.is_file())
        self.assertEqual(ORACLE.verify_vectors(VECTOR_PATH), 60)

    def test_source_uses_only_integer_arithmetic_nodes(self) -> None:
        parsed = ast.parse(SCRIPT_PATH.read_text(encoding="utf-8"))
        forbidden_imports = {"math", "decimal", "fractions", "numpy", "ctypes", "struct"}
        for node in ast.walk(parsed):
            if isinstance(node, ast.BinOp):
                self.assertNotIsInstance(node.op, ast.Div)
            if isinstance(node, ast.Import):
                for alias in node.names:
                    self.assertNotIn(alias.name.split(".")[0], forbidden_imports)
            if isinstance(node, ast.ImportFrom):
                self.assertNotIn((node.module or "").split(".")[0], forbidden_imports)
            if isinstance(node, ast.Call) and isinstance(node.func, ast.Name):
                self.assertNotEqual(node.func.id, "float")


if __name__ == "__main__":
    unittest.main()
