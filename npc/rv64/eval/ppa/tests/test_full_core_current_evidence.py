from __future__ import annotations

import pathlib
import tempfile
import unittest

from npc.rv64.eval.ppa.tools import full_core_current_evidence as evidence


class FullCoreCurrentEvidenceTests(unittest.TestCase):
    def valid_log(self) -> str:
        return "\n".join(
            (
                "[TEST] tb_example",
                "[PASS] tb_example",
                "[RTL-DESIGN-ID] sha256:" + "a" * 64,
                "[RESULT] PASS",
                "",
            )
        )

    def test_valid_module_log(self) -> None:
        self.assertEqual(
            [],
            evidence.validate_module_log(
                self.valid_log(),
                test_id="tb_example",
                design_id="sha256:" + "a" * 64,
            ),
        )

    def test_duplicate_pass_marker_is_rejected(self) -> None:
        text = self.valid_log() + "PASS tb_example\n"
        errors = evidence.validate_module_log(
            text,
            test_id="tb_example",
            design_id="sha256:" + "a" * 64,
        )
        self.assertTrue(any("native PASS" in item for item in errors))

    def test_unbracketed_native_pass_is_accepted(self) -> None:
        text = self.valid_log().replace("[PASS] tb_example", "PASS tb_example")
        self.assertEqual(
            [],
            evidence.validate_module_log(
                text,
                test_id="tb_example",
                design_id="sha256:" + "a" * 64,
            ),
        )

    def test_wrong_design_id_is_rejected(self) -> None:
        errors = evidence.validate_module_log(
            self.valid_log(),
            test_id="tb_example",
            design_id="sha256:" + "b" * 64,
        )
        self.assertTrue(any("RTL-DESIGN-ID" in item for item in errors))

    def test_fail_marker_is_rejected(self) -> None:
        errors = evidence.validate_module_log(
            self.valid_log() + "[RESULT] FAIL status=1\n",
            test_id="tb_example",
            design_id="sha256:" + "a" * 64,
        )
        self.assertIn("tb_example: contains [RESULT] FAIL", errors)

    def test_normalization_removes_repo_and_temporary_paths(self) -> None:
        with tempfile.TemporaryDirectory() as raw:
            temporary = pathlib.Path(raw)
            text = f"{evidence.ROOT}/a {temporary}/build/tb.vvp"
            normalized = evidence.normalize_text(text, temporary_root=temporary)
            self.assertEqual(
                "<REPO>/a <FULL_CORE_CURRENT_TEMP>/build/tb.vvp", normalized
            )

    def test_output_must_be_below_task_runs(self) -> None:
        with self.assertRaises((RuntimeError, ValueError)):
            evidence.safe_output_dir(pathlib.Path("npc/rv64/not-an-evidence-dir"))

    def test_missing_task_run_descendants_are_allowed(self) -> None:
        with tempfile.TemporaryDirectory(
            dir=evidence.TASK_RUN_ROOT, prefix="full-core-output-test-"
        ) as raw:
            task_dir = pathlib.Path(raw)
            output = task_dir / "evidence/module-attempt-1"
            self.assertEqual(output.resolve(strict=False), evidence.safe_output_dir(output))

    def test_current_module_input_capture_is_nonempty(self) -> None:
        tests = evidence.required_tests()
        binding = evidence.capture_inputs(tests)
        self.assertGreaterEqual(len(tests), 100)
        self.assertRegex(binding["design_id"], r"^sha256:[0-9a-f]{64}$")
        self.assertGreater(len(binding["groups"]["rtl"]), 100)
        self.assertGreater(len(binding["groups"]["test_sources"]), len(tests))


if __name__ == "__main__":
    unittest.main()
