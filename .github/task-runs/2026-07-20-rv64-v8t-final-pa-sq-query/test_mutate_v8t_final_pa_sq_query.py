#!/usr/bin/env python3
"""Anchor/activation unit tests for the v8t/F3 semantic mutator."""

from __future__ import annotations

import importlib.util
import pathlib
import sys
import unittest


HERE = pathlib.Path(__file__).resolve().parent
REPO = HERE.parents[2]
SPEC = importlib.util.spec_from_file_location(
    "mutate_v8t", HERE / "mutate-v8t-final-pa-sq-query.py"
)
assert SPEC and SPEC.loader
MUTATOR = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = MUTATOR
SPEC.loader.exec_module(MUTATOR)

SOURCE_PATHS = {
    "OooStoreQueue.v": REPO / "npc/rv64/vsrc/memory/OooStoreQueue.v",
    "OooMemAxiBridge.v": REPO / "npc/rv64/vsrc/memory/OooMemAxiBridge.v",
    "OooIntBackend.v": REPO / "npc/rv64/vsrc/execute/OooIntBackend.v",
}


class MutatorTests(unittest.TestCase):
    def test_all_mutations_have_exact_live_anchors(self) -> None:
        self.assertGreaterEqual(len(MUTATOR.MUTATIONS), 20)
        for name, mutation in MUTATOR.MUTATIONS.items():
            with self.subTest(name=name):
                text = SOURCE_PATHS[mutation.source_name].read_text(
                    encoding="utf-8"
                )
                mutated = text
                for old, new, expected_count in mutation.replacements:
                    self.assertEqual(mutated.count(old), expected_count)
                    mutated = mutated.replace(old, new)
                    self.assertEqual(mutated.count(old), 0)
                    self.assertIn(new, mutated)
                self.assertNotEqual(mutated, text)

    def test_mutations_are_bounded_to_known_rtl_sources(self) -> None:
        self.assertEqual(
            {item.source_name for item in MUTATOR.MUTATIONS.values()},
            set(SOURCE_PATHS),
        )


if __name__ == "__main__":
    unittest.main()
