from __future__ import annotations

import copy
import importlib.util
import pathlib
import sys
import tempfile
import unittest


ROOT = pathlib.Path(__file__).resolve().parents[5]
TOOL = ROOT / "npc/rv64/eval/ppa/tools/architecture_current_aggregate.py"
SPEC = importlib.util.spec_from_file_location("architecture_current_aggregate", TOOL)
assert SPEC is not None and SPEC.loader is not None
aggregate = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = aggregate
SPEC.loader.exec_module(aggregate)


class ArchitectureCurrentAggregateTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        source_sha, _ = aggregate.arch.rtl_binding(ROOT)
        cls.design_id = f"sha256:{source_sha}"

    def write_manifest(
        self, root: pathlib.Path, name: str, tests: set[str], *, design_id: str | None = None,
    ) -> pathlib.Path:
        path = root / f"{name}.json"
        aggregate.atomic_json(path, {
            "design_id": design_id or self.design_id,
            "generated_at_utc": "2026-08-06T00:00:00+00:00",
            "schema": aggregate.arch.EVIDENCE_SCHEMA,
            "tests": {test: {"status": "PASS"} for test in sorted(tests)},
        })
        return path

    def complete_inputs(self, root: pathlib.Path) -> list[pathlib.Path]:
        return [
            self.write_manifest(root, f"input-{index}", {test})
            for index, test in enumerate(sorted(aggregate.EXPECTED_TESTS))
        ]

    def test_complete_disjoint_inventory_passes(self) -> None:
        with tempfile.TemporaryDirectory(dir=ROOT) as raw:
            inputs = self.complete_inputs(pathlib.Path(raw))
            manifest, receipts = aggregate.collect(ROOT, inputs)
            self.assertEqual(set(manifest["tests"]), aggregate.EXPECTED_TESTS)
            self.assertEqual(len(receipts), len(aggregate.EXPECTED_TESTS))

    def test_missing_record_is_rejected(self) -> None:
        with tempfile.TemporaryDirectory(dir=ROOT) as raw:
            inputs = self.complete_inputs(pathlib.Path(raw))[:-1]
            with self.assertRaisesRegex(ValueError, "inventory is incomplete"):
                aggregate.collect(ROOT, inputs)

    def test_duplicate_record_is_rejected(self) -> None:
        with tempfile.TemporaryDirectory(dir=ROOT) as raw:
            root = pathlib.Path(raw)
            inputs = self.complete_inputs(root)
            value = aggregate.parse_json(inputs[0])
            duplicate = self.write_manifest(
                root, "duplicate", set(value["tests"])
            )
            with self.assertRaisesRegex(ValueError, "duplicate test records"):
                aggregate.collect(ROOT, [*inputs, duplicate])

    def test_design_drift_is_rejected(self) -> None:
        with tempfile.TemporaryDirectory(dir=ROOT) as raw:
            root = pathlib.Path(raw)
            inputs = self.complete_inputs(root)
            stale = aggregate.parse_json(inputs[0])
            stale["design_id"] = "sha256:" + "0" * 64
            aggregate.atomic_json(inputs[0], stale)
            with self.assertRaisesRegex(ValueError, "design-id mismatch"):
                aggregate.collect(ROOT, inputs)

    def test_unknown_record_is_rejected(self) -> None:
        with tempfile.TemporaryDirectory(dir=ROOT) as raw:
            root = pathlib.Path(raw)
            inputs = self.complete_inputs(root)
            unknown = self.write_manifest(root, "unknown", {"invented_gate"})
            with self.assertRaisesRegex(ValueError, "unknown test records"):
                aggregate.collect(ROOT, [*inputs, unknown])


if __name__ == "__main__":
    unittest.main()
