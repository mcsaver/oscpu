#!/usr/bin/env python3
"""Focused checks for compacted RV64 functional archive rehydration."""

from __future__ import annotations

import importlib.util
import pathlib
import tempfile
import unittest


TOOL_PATH = pathlib.Path(__file__).resolve().parents[1] / "tools" / (
    "functional_archive_rehydrate.py")
SPEC = importlib.util.spec_from_file_location(
    "test_functional_archive_rehydrate_tool", TOOL_PATH)
assert SPEC is not None and SPEC.loader is not None
TOOL = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(TOOL)
ROOT = TOOL_PATH.parents[5]
FUNCTIONAL = ROOT / (
    ".github/task-runs/"
    "2026-08-02-rv64-v14e-p1-remaining-current-rebind-v1/"
    "evidence/f0-run-2/functional"
)


class FunctionalArchiveRehydrateTests(unittest.TestCase):
    def test_v14e_compaction_chain_and_inventory_are_exact(self) -> None:
        aggregate, pre, post = TOOL.validate_compaction_chain(
            root=ROOT,
            aggregate_path=FUNCTIONAL / "functional-aggregate.json",
            descriptor_path=FUNCTIONAL / "functional-run-descriptor.json",
            pre_path=FUNCTIONAL / "pre-compaction-artifacts.json",
            post_path=FUNCTIONAL / "post-compaction.json",
        )
        self.assertEqual(
            aggregate["design_id"],
            "sha256:093c2380b997029944aa4462015d83711d7c5f1d52b15b4803c4515a581a7488",
        )
        self.assertEqual(len(list(TOOL.iter_program_records(aggregate))), 240)
        self.assertEqual(pre["removed_counts"]["program_images"], 240)
        self.assertFalse(post["standalone_binary_replay_available"])
        self.assertTrue(post["rebuild_binding_available"])

    def test_receipt_size_metadata_cannot_hide_identity_drift(self) -> None:
        base = {
            "kind": "simulator_binary", "path": "frozen/NpcSimTop",
            "sha256": "1" * 64,
        }
        with_size = {**base, "size_bytes": 123}
        self.assertEqual(TOOL.record_identity(base), TOOL.record_identity(with_size))
        changed = {**with_size, "sha256": "2" * 64}
        self.assertNotEqual(TOOL.record_identity(base), TOOL.record_identity(changed))

    def test_exact_copy_rejects_wrong_source_hash(self) -> None:
        with tempfile.TemporaryDirectory(
            prefix=".rv64-functional-rehydrate-test-", dir=ROOT,
        ) as raw:
            directory = pathlib.Path(raw)
            source = directory / "source.bin"
            destination = directory / "restored.bin"
            source.write_bytes(b"rtl-functional-input")
            with self.assertRaisesRegex(TOOL.RehydrateError, "source hash mismatch"):
                TOOL.link_or_copy_exact(
                    root=ROOT,
                    source=source,
                    destination=destination,
                    expected_sha256="0" * 64,
                )
            self.assertFalse(destination.exists())


if __name__ == "__main__":
    unittest.main()
