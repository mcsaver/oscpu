#!/usr/bin/env python3
"""Focused tests for live-source OOO-3 mutation reconstruction."""

from __future__ import annotations

import hashlib
import importlib.util
import pathlib
import sys
import unittest


TOOLS = pathlib.Path(__file__).resolve().parents[1] / "tools"
sys.path.insert(0, str(TOOLS))
SPEC = importlib.util.spec_from_file_location(
    "memory_ordering_evidence_under_test",
    TOOLS / "memory_ordering_evidence.py",
)
assert SPEC is not None and SPEC.loader is not None
evidence = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(evidence)


class MutationReconstructionTests(unittest.TestCase):
    def test_reconstructs_real_owner_token_cut(self) -> None:
        source = "a, mem1_drop0_owner_token_i, b"
        old = "mem1_drop0_owner_token_i"
        new = "mem_drop0_owner_token_i"
        expected = hashlib.sha256(
            source.replace(old, new, 1).encode("utf-8")
        ).hexdigest()
        self.assertEqual(
            evidence.reconstruct_mutation_sha256(
                "duplicate_bridge_drop_token", source, [(old, new)]),
            expected,
        )

    def test_rejects_byte_identical_cut(self) -> None:
        with self.assertRaisesRegex(ValueError, "byte-identical no-op"):
            evidence.reconstruct_mutation_sha256(
                "no_op", "wire x = y;", [("wire x = y;", "wire x = y;")]
            )

    def test_rejects_missing_anchor(self) -> None:
        with self.assertRaisesRegex(ValueError, "0 live anchors"):
            evidence.reconstruct_mutation_sha256(
                "missing", "wire x = y;", [("wire z = y;", "wire z = q;")]
            )

    def test_rejects_ambiguous_anchor_set(self) -> None:
        with self.assertRaisesRegex(ValueError, "2 live anchors"):
            evidence.reconstruct_mutation_sha256(
                "ambiguous",
                "wire x = y; wire z = q;",
                [("wire x = y;", "wire x = q;"),
                 ("wire z = q;", "wire z = y;")],
            )


if __name__ == "__main__":
    unittest.main()
