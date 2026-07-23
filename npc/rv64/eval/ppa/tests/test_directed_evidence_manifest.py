#!/usr/bin/env python3
"""Self-tests for atomic, non-destructive directed-evidence publication."""

from __future__ import annotations

import importlib.util
import json
import pathlib
import tempfile
import unittest


TOOL = pathlib.Path(__file__).resolve().parents[1] / "tools" / (
    "directed_evidence_manifest.py")
SPEC = importlib.util.spec_from_file_location(
    "directed_evidence_manifest", TOOL)
assert SPEC is not None and SPEC.loader is not None
manifest_tool = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(manifest_tool)


class ManifestMergeTests(unittest.TestCase):
    def test_matching_siblings_survive_merge(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            path = pathlib.Path(temporary) / "architecture-current.json"
            original = {
                "design_id": "sha256:" + ("a" * 64),
                "generated_at_utc": "old",
                "schema": "schema-v2",
                "tests": {
                    "selective_scheduling": {"status": "PASS"},
                    "sibling_probe": {"status": "PASS"},
                },
            }
            path.write_text(json.dumps(original), encoding="utf-8")
            merged = manifest_tool.merge_directed_record(
                path,
                schema="schema-v2",
                design_id="sha256:" + ("a" * 64),
                generated_at_utc="new",
                test_id="true_ooo_long_latency",
                record={"status": "PASS"},
            )
            self.assertEqual(
                set(merged["tests"]),
                {
                    "selective_scheduling",
                    "sibling_probe",
                    "true_ooo_long_latency",
                },
            )
            self.assertEqual(json.loads(path.read_text()), merged)

    def test_injected_failure_preserves_parseable_old_file(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            path = pathlib.Path(temporary) / "architecture-current.json"
            original = {
                "design_id": "sha256:" + ("b" * 64),
                "generated_at_utc": "old",
                "schema": "schema-v2",
                "tests": {"selective_scheduling": {"status": "PASS"}},
            }
            original_text = json.dumps(original, sort_keys=True)
            path.write_text(original_text, encoding="utf-8")
            with self.assertRaisesRegex(RuntimeError, "injected failure"):
                manifest_tool.merge_directed_record(
                    path,
                    schema="schema-v2",
                    design_id="sha256:" + ("b" * 64),
                    generated_at_utc="new",
                    test_id="true_ooo_long_latency",
                    record={"status": "PASS"},
                    fault_before_replace=True,
                )
            self.assertEqual(path.read_text(encoding="utf-8"), original_text)
            self.assertEqual(json.loads(path.read_text()), original)
            self.assertFalse(path.with_suffix(".json.tmp").exists())

    def test_stale_design_records_are_not_carried_forward(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            path = pathlib.Path(temporary) / "architecture-current.json"
            path.write_text(json.dumps({
                "design_id": "sha256:" + ("c" * 64),
                "generated_at_utc": "old",
                "schema": "schema-v2",
                "tests": {"stale": {"status": "PASS"}},
            }), encoding="utf-8")
            merged = manifest_tool.merge_directed_record(
                path,
                schema="schema-v2",
                design_id="sha256:" + ("d" * 64),
                generated_at_utc="new",
                test_id="fresh",
                record={"status": "PASS"},
            )
            self.assertEqual(set(merged["tests"]), {"fresh"})


if __name__ == "__main__":
    unittest.main()
