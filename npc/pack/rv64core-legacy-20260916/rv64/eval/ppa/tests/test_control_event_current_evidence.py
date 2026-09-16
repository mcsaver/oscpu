#!/usr/bin/env python3
"""Tests for compact current V9O CONTROL-EVENT evidence."""

from __future__ import annotations

import importlib.util
import json
import pathlib
import unittest


TOOL = pathlib.Path(__file__).resolve().parents[1] / "tools/control_event_current_evidence.py"
SPEC = importlib.util.spec_from_file_location("control_event_current_evidence", TOOL)
assert SPEC is not None and SPEC.loader is not None
evidence = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(evidence)
ROOT = pathlib.Path(__file__).resolve().parents[5]


class PureContractTests(unittest.TestCase):
    def test_dispatch_rejects_dynamic_syntax(self) -> None:
        text = (ROOT / evidence.DISPATCH_FILE).read_text(encoding="utf-8")
        evidence.validate_dispatch_text(text)
        for mutation in (
            text + "include ../../Makefile\n",
            text.replace("bash ../../", "$(SHELL) ../../", 1),
            text.replace(evidence.CANONICAL_TARGET, "wrong-target", 1),
        ):
            with self.assertRaises(ValueError):
                evidence.validate_dispatch_text(mutation)

    def test_mutation_patches_are_nonempty_and_source_changing(self) -> None:
        runner = evidence.mutation_runner(ROOT)
        for spec in runner.MUTATIONS:
            with self.subTest(name=spec.name):
                patch, before, after = evidence.mutation_patch(ROOT, spec)
                self.assertTrue(patch.startswith(b"--- "))
                self.assertNotEqual(before, after)


class CurrentEvidenceTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.path = ROOT / evidence.RESULT_PATH
        if not cls.path.is_file():
            raise unittest.SkipTest("current V9O CONTROL-EVENT result not built")
        cls.payload = json.loads(cls.path.read_text(encoding="utf-8"))

    def test_current_payload_is_valid(self) -> None:
        self.assertEqual(
            evidence.validate_payload(
                ROOT, self.payload, self.payload["design_id"]
            ),
            [],
        )

    def test_false_green_shapes_are_rejected(self) -> None:
        cases: list[tuple[str, dict]] = []
        missing_focus = json.loads(json.dumps(self.payload))
        missing_focus["focused"]["passed"] = 9
        cases.append(("focused test missing", missing_focus))
        escaped = json.loads(json.dumps(self.payload))
        escaped["rtl_mutations"]["rejected"] = 10
        cases.append(("mutation escaped", escaped))
        promoted = json.loads(json.dumps(self.payload))
        promoted["claim_boundary"]["promotion_eligible"] = True
        cases.append(("local result promoted", promoted))
        duplicated = json.loads(json.dumps(self.payload))
        duplicated["retention"]["duplicated_module_aggregate"] = True
        cases.append(("duplicated aggregate restored", duplicated))
        stale = json.loads(json.dumps(self.payload))
        stale["source_binding"]["sha256"] = "0" * 64
        cases.append(("source binding stale", stale))
        for label, candidate in cases:
            with self.subTest(label=label):
                self.assertTrue(evidence.validate_payload(
                    ROOT, candidate, self.payload["design_id"]
                ))

    def test_no_compiled_image_is_retained(self) -> None:
        self.assertEqual(
            list((ROOT / f".github/task-runs/{evidence.RUN_ID}").rglob("*.vvp")),
            [],
        )


if __name__ == "__main__":
    unittest.main()
