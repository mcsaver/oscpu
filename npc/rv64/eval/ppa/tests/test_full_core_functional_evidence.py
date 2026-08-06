from __future__ import annotations

import copy
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
            "command": "run local SystemVerilog module inventory",
            "inputs": {
                "pre": {"kind": "input_binding"},
                "post": {"kind": "input_binding"},
                "unchanged": True,
            },
            "artifacts": {
                "summary": {"kind": "module_test_summary"},
                "make_log": {"kind": "module_make_log"},
            },
            "retention": {
                "compiled_images_retained": 0,
                "compiled_images_location": "task-owned temporary directory",
            },
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
        self.assertEqual(binding["schema"], functional.module_evidence.freeze.F0_FUNCTIONAL_INPUT_SCHEMA)
        self.assertEqual(len(binding["official_test_ids"]), 177)
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

    def test_current_module_input_binding_matches_exact_contract(self) -> None:
        tests = module_evidence.required_tests()
        binding = module_evidence.capture_inputs(tests)
        self.assertEqual(
            functional.module_input_binding_errors(
                binding,
                expected_design_id=binding["design_id"],
                expected_tests=tests,
            ),
            [],
        )

    def test_module_input_binding_rejects_empty_payload(self) -> None:
        errors = functional.module_input_binding_errors(
            {},
            expected_design_id="sha256:" + "a" * 64,
            expected_tests=["tb_example"],
        )
        self.assertIn("module input binding schema mismatch", errors)
        self.assertIn("module input binding group inventory mismatch", errors)

    def test_module_input_binding_rejects_design_inventory_and_group_drift(self) -> None:
        tests = module_evidence.required_tests()
        binding = module_evidence.capture_inputs(tests)
        drifted = copy.deepcopy(binding)
        drifted["design_id"] = "sha256:" + "b" * 64
        drifted["required_tests"] = list(reversed(tests))
        groups = drifted["groups"]
        assert isinstance(groups, dict)
        groups.pop("workflow")
        errors = functional.module_input_binding_errors(
            drifted,
            expected_design_id=binding["design_id"],
            expected_tests=tests,
        )
        self.assertIn("module input binding design_id mismatch", errors)
        self.assertIn("module input binding required_tests mismatch", errors)
        self.assertIn("module input binding group inventory mismatch", errors)

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

    def test_compact_copy_rejects_source_file_symlink(self) -> None:
        legacy = functional.load_legacy_runner()
        with tempfile.TemporaryDirectory(
            dir=functional.module_evidence.TASK_RUN_ROOT,
            prefix="rv64-compact-copy-",
        ) as raw:
            task_dir = pathlib.Path(raw)
            output_dir = task_dir / "evidence/functional"
            output_dir.mkdir(parents=True)
            temporary_root = task_dir / "temporary"
            temporary_root.mkdir()
            source = temporary_root / "source.log"
            source.write_text("architectural log\n", encoding="utf-8")
            alias = temporary_root / "alias.log"
            alias.symlink_to(source)
            functional.install_compact_io(legacy, output_dir, temporary_root)
            with self.assertRaisesRegex(RuntimeError, "symlink"):
                legacy.copy_regular(alias, output_dir / "raw/copied.log")

    def test_publication_rejects_parent_final_and_temporary_symlinks(self) -> None:
        with tempfile.TemporaryDirectory(
            dir=functional.module_evidence.TASK_RUN_ROOT,
            prefix="rv64-publication-alias-",
        ) as raw:
            root = pathlib.Path(raw)
            source = root / "source.json"
            source.write_text("{}\n", encoding="utf-8")

            parent_case = root / "parent-case"
            parent_case.mkdir()
            parent_foreign = root / "parent-foreign"
            parent_foreign.mkdir()
            parent_alias = parent_case / "alias"
            parent_alias.symlink_to(parent_foreign, target_is_directory=True)

            final_case = root / "final-case"
            final_case.mkdir()
            final_foreign = root / "final-foreign"
            final_foreign.mkdir()
            final_destination = final_case / "current.json"
            final_destination.symlink_to(final_foreign / "missing.json")

            temporary_case = root / "temporary-case"
            temporary_case.mkdir()
            temporary_foreign = root / "temporary-foreign"
            temporary_foreign.mkdir()
            temporary_destination = temporary_case / "current.json"
            temporary_alias = temporary_destination.with_name(
                temporary_destination.name + ".tmp-full-core-current"
            )
            temporary_alias.symlink_to(temporary_foreign / "missing.json")

            destinations = (
                parent_alias / "current.json",
                final_destination,
                temporary_destination,
            )
            for destination in destinations:
                with self.subTest(destination=destination), \
                        self.assertRaisesRegex(RuntimeError, "symlink"):
                    functional.publish_generated(source, destination)

    def test_secondary_product_snapshot_includes_result_and_generated_makefile(self) -> None:
        with tempfile.TemporaryDirectory(prefix="rv64-secondary-products-") as raw:
            root = pathlib.Path(raw)
            cpu_tests = root / "am-kernels/tests/cpu-tests"
            cpu_tests.mkdir(parents=True)
            (cpu_tests / ".result").write_text("PASS\n", encoding="utf-8")
            (cpu_tests / "Makefile.riscv64-npc").write_text(
                "generated\n", encoding="utf-8"
            )
            observed = functional.secondary_product_fingerprints(root)
            self.assertEqual(
                set(observed),
                {
                    "am-kernels/tests/cpu-tests/.result",
                    "am-kernels/tests/cpu-tests/Makefile.riscv64-npc",
                },
            )

    def test_secondary_products_must_be_absent_before_isolated_build(self) -> None:
        with tempfile.TemporaryDirectory(prefix="rv64-secondary-products-") as raw:
            root = pathlib.Path(raw)
            stale = root / "am-kernels/benchmarks/coremark/build"
            stale.mkdir(parents=True)
            (stale / "stale.o").write_bytes(b"stale")
            with self.assertRaisesRegex(RuntimeError, "pre-existing"):
                functional.require_no_secondary_products(root)


if __name__ == "__main__":
    unittest.main()
