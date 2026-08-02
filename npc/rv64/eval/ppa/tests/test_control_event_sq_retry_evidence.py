#!/usr/bin/env python3
"""Tests for compact CONTROL-EVENT/V9R current evidence."""

from __future__ import annotations

import importlib.util
import json
import pathlib
import tempfile
import unittest
from unittest import mock


TOOL = pathlib.Path(__file__).resolve().parents[1] / "tools/control_event_sq_retry_evidence.py"
SPEC = importlib.util.spec_from_file_location("control_event_sq_retry_evidence", TOOL)
assert SPEC is not None and SPEC.loader is not None
evidence = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(evidence)
ROOT = evidence.find_repo_root(TOOL)


class PureContractTests(unittest.TestCase):
    def test_canonical_dispatch_is_literal_and_exact(self) -> None:
        text = (ROOT / evidence.DISPATCH_FILE).read_text(encoding="utf-8")
        evidence.validate_dispatch_text(text)
        for mutation in (
            text + "include ../../Makefile\n",
            text.replace("bash ../../", "$(SHELL) ../../"),
            text.replace(evidence.CANONICAL_TARGET, "wrong-target", 1),
        ):
            with self.assertRaises(ValueError):
                evidence.validate_dispatch_text(mutation)

    def test_all_five_mutations_are_current_and_non_noop(self) -> None:
        self.assertEqual(len(evidence.VARIANTS), 5)
        for case_id, spec in evidence.VARIANTS.items():
            with self.subTest(case_id=case_id):
                mutated, receipt = evidence.mutated_bytes(ROOT, case_id)
                production = (ROOT / spec["production_source"]).read_bytes()
                self.assertNotEqual(mutated, production)
                self.assertEqual(receipt["anchor_count"], 1)
                self.assertNotEqual(
                    receipt["production_sha256"], receipt["variant_sha256"]
                )
                self.assertTrue(
                    evidence.mutation_patch_bytes(ROOT, case_id).startswith(
                        b"--- "
                    )
                )

    def test_byte_identical_mutation_is_rejected(self) -> None:
        case_id = "backend-bank0-ready-open"
        original = dict(evidence.VARIANTS[case_id])
        broken = dict(original)
        broken["new"] = broken["old"]
        with mock.patch.dict(evidence.VARIANTS, {case_id: broken}):
            with self.assertRaises(ValueError):
                evidence.mutated_bytes(ROOT, case_id)

    def test_compile_output_must_be_transient(self) -> None:
        source = ROOT / "npc/rv64/testbench/tests/tb_ooo_mem_axi_bridge.sv"
        with tempfile.TemporaryDirectory() as directory:
            log = pathlib.Path(directory) / "compile.log"
            log.write_text(
                "[COMPILE] iverilog -o "
                f"{ROOT}/npc/rv64/testbench/build/retained.vvp {source}\n",
                encoding="utf-8",
            )
            with self.assertRaises(ValueError):
                evidence.compile_sources(ROOT, log)


class CurrentEvidenceTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.path = ROOT / evidence.RESULT_PATH
        if not cls.path.is_file():
            raise unittest.SkipTest("current CONTROL-EVENT/V9R result not built")
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

        missing_trap = json.loads(json.dumps(self.payload))
        missing_trap["positive"]["natural_trap_head_cases"] = 0
        cases.append(("missing natural trap", missing_trap))

        missing_resident_holder = json.loads(json.dumps(self.payload))
        missing_resident_holder["positive"]["resident_holder_banks"] = 0
        cases.append(("missing resident-holder C0 pause", missing_resident_holder))

        escaped_variant = json.loads(json.dumps(self.payload))
        escaped_variant["compile_success_rtl_variants"][0]["result"] = "PASS"
        cases.append(("escaped compile-success variant", escaped_variant))

        promoted = json.loads(json.dumps(self.payload))
        promoted["promotion_eligible"] = True
        promoted["ppa_status"] = "qualified"
        cases.append(("local evidence promoted", promoted))

        persistent_image = json.loads(json.dumps(self.payload))
        persistent_image["retention"]["compiled_images_retained"] = 1
        cases.append(("compiled image retained", persistent_image))

        stale_binding = json.loads(json.dumps(self.payload))
        stale_binding["source_binding"]["sha256"] = "0" * 64
        cases.append(("source binding drift", stale_binding))

        for label, candidate in cases:
            with self.subTest(label=label):
                self.assertTrue(
                    evidence.validate_payload(
                        ROOT, candidate, self.payload["design_id"]
                    )
                )

    def test_task_run_retains_no_compiled_image(self) -> None:
        self.assertEqual(
            list((ROOT / evidence.EVIDENCE_ROOT).rglob("*.vvp")),
            [],
        )
        for case_id, spec in evidence.VARIANTS.items():
            self.assertFalse(
                (ROOT / evidence.EVIDENCE_ROOT / case_id /
                 spec["mutated_name"]).exists()
            )
            self.assertTrue(
                (ROOT / evidence.EVIDENCE_ROOT / "patches" /
                 f"{case_id}.patch").is_file()
            )


if __name__ == "__main__":
    unittest.main()
