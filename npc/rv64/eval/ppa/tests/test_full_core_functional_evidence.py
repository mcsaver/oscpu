from __future__ import annotations

import pathlib
import tempfile
import unittest

from npc.rv64.eval.ppa.tools import full_core_current_evidence as module_evidence
from npc.rv64.eval.ppa.tools import full_core_functional_evidence as functional


class FullCoreFunctionalEvidenceTests(unittest.TestCase):
    def valid_module_payload(self) -> dict[str, object]:
        return {
            "schema": module_evidence.SCHEMA,
            "status": "PASS",
            "design_id": "sha256:" + "a" * 64,
            "tests": {
                "required": 1,
                "passed": 1,
                "inventory": ["tb_example"],
                "logs": {"tb_example": {"path": "x", "sha256": "a" * 64}},
            },
            "inputs": {"unchanged": True},
        }

    def test_module_payload_contract_accepts_exact_shape(self) -> None:
        self.assertEqual(
            [], functional.module_payload_contract_errors(self.valid_module_payload())
        )

    def test_module_payload_contract_rejects_fail(self) -> None:
        value = self.valid_module_payload()
        value["status"] = "FAIL"
        self.assertIn(
            "module result is not PASS",
            functional.module_payload_contract_errors(value),
        )

    def test_module_payload_contract_rejects_inventory_drift(self) -> None:
        value = self.valid_module_payload()
        tests = value["tests"]
        assert isinstance(tests, dict)
        tests["inventory"] = ["tb_other"]
        self.assertIn(
            "module log map differs from inventory",
            functional.module_payload_contract_errors(value),
        )

    def test_repository_input_collection_excludes_generated_products(self) -> None:
        with tempfile.TemporaryDirectory(prefix="rv64-functional-inputs-") as raw:
            root = pathlib.Path(raw)
            source = root / "source"
            (source / "tests").mkdir(parents=True)
            (source / "build").mkdir()
            (source / "tests/a.c").write_text("int a;\n", encoding="utf-8")
            (source / "configure").write_text("#!/bin/sh\n", encoding="utf-8")
            (source / "Makefile").write_text("all:\n", encoding="utf-8")
            (source / "Makefile.a").write_text("generated\n", encoding="utf-8")
            (source / "build/a.o").write_bytes(b"generated")
            (source / "tests/generated-target").write_bytes(b"\x7fELFgenerated")
            (source / "tests/generated.dump").write_text(
                "generated\n", encoding="utf-8")
            observed = functional.collect_repository_files(root, [source])
            self.assertEqual(
                observed,
                ["source/Makefile", "source/configure", "source/tests/a.c"],
            )

    def test_current_functional_input_capture_is_complete(self) -> None:
        legacy = functional.load_legacy_runner()
        binding = functional.capture_functional_inputs(
            legacy, module_evidence.required_tests())
        expected_am = sorted(
            path.stem for path in (legacy.CPU_TESTS / "tests").glob("*.c"))
        self.assertTrue(expected_am)
        self.assertEqual(binding["am_test_ids"], expected_am)
        for group in (
            "functional_workflow",
            "npc_host_harness_sources",
            "official_program_sources",
            "am_program_sources",
            "benchmark_program_sources",
            "reference_model_sources",
        ):
            self.assertTrue(binding["groups"][group], group)
        self.assertIn("verilator", binding["toolchain"])

    def test_module_payload_contract_rejects_input_drift(self) -> None:
        value = self.valid_module_payload()
        inputs = value["inputs"]
        assert isinstance(inputs, dict)
        inputs["unchanged"] = False
        self.assertIn(
            "module input binding is not unchanged",
            functional.module_payload_contract_errors(value),
        )

    def test_failed_am_logs_are_retained_without_unrelated_files(self) -> None:
        with tempfile.TemporaryDirectory(prefix="rv64-am-failed-logs-") as raw:
            root = pathlib.Path(raw)
            source = root / "source"
            destination = root / "evidence" / "raw" / "am-failed"
            source.mkdir()
            (source / "pass.log").write_text("GOOD TRAP\n", encoding="utf-8")
            (source / "fail.log").write_text("BAD TRAP\n", encoding="utf-8")
            (source / "scratch.txt").write_text("temporary\n", encoding="utf-8")

            copied = functional.retain_failed_am_logs(source, destination)

            self.assertEqual(copied, ["fail.log", "pass.log"])
            self.assertEqual(
                (destination / "fail.log").read_text(encoding="utf-8"),
                "BAD TRAP\n",
            )
            self.assertEqual(
                (destination / "pass.log").read_text(encoding="utf-8"),
                "GOOD TRAP\n",
            )
            self.assertFalse((destination / "scratch.txt").exists())


if __name__ == "__main__":
    unittest.main()
