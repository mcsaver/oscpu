from __future__ import annotations

import copy
import importlib.util
import pathlib
import tempfile
import unittest


ROOT = pathlib.Path(__file__).resolve().parents[5]
TOOL_PATH = ROOT / "npc/rv64/eval/ppa/tools/compile_image_retirement.py"
SPEC = importlib.util.spec_from_file_location("compile_image_retirement", TOOL_PATH)
assert SPEC and SPEC.loader
RETIRE = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(RETIRE)


class CompileImageRetirementTests(unittest.TestCase):
    def setUp(self) -> None:
        self.temporary = tempfile.TemporaryDirectory()
        self.root = pathlib.Path(self.temporary.name).resolve()
        self.scope = self.root / ".github/task-runs/run-a"
        (self.scope / "profiles/a").mkdir(parents=True)
        (self.scope / "profiles/b").mkdir(parents=True)
        (self.scope / "profiles/a/test.vvp").write_bytes(b"image-a")
        (self.scope / "profiles/b/test.vvp").write_bytes(b"image-b")
        (self.scope / "profiles/a/result.log").write_text("PASS\n")

    def tearDown(self) -> None:
        self.temporary.cleanup()

    def test_preview_apply_and_verify_preserve_logs(self) -> None:
        payload = RETIRE.build_preview(self.root, self.scope)
        summary = {
            "compiled_images": [
                dict(entry) for entry in payload["entries"]
            ]
        }
        RETIRE.write_json(self.scope / "summary.json", summary)
        self.assertEqual(payload["status"], "PLANNED")
        self.assertEqual(payload["entry_count"], 2)
        manifest = self.scope / "semantic-vvp-retirement.json"
        receipt = self.scope / "compile-image-retirement-receipt.json"
        RETIRE.write_json(manifest, payload)
        result = RETIRE.apply_retirement(self.root, manifest, receipt)
        self.assertEqual(result["retired_count"], 2)
        RETIRE.verify_retirement(self.root, RETIRE.load_json(manifest))
        audit = RETIRE.build_reference_audit(
            self.root, manifest, self.scope / "reference-audit.json"
        )
        self.assertEqual(audit["status"], "PASS")
        self.assertEqual(audit["referenced_entry_count"], 2)
        self.assertTrue((self.scope / "profiles/a/result.log").is_file())
        self.assertFalse((self.scope / "profiles/a/test.vvp").exists())

    def test_scope_outside_one_task_run_is_rejected(self) -> None:
        with self.assertRaisesRegex(
            RETIRE.RetirementError, "one concrete task-run"
        ):
            RETIRE.task_run_scope(self.root, ".github/task-runs")

    def test_drifted_compile_image_is_rejected_before_delete(self) -> None:
        payload = RETIRE.build_preview(self.root, self.scope)
        manifest = self.scope / "semantic-vvp-retirement.json"
        receipt = self.scope / "compile-image-retirement-receipt.json"
        RETIRE.write_json(manifest, payload)
        (self.scope / "profiles/a/test.vvp").write_bytes(b"drift")
        with self.assertRaisesRegex(RETIRE.RetirementError, "drifted"):
            RETIRE.apply_retirement(self.root, manifest, receipt)
        self.assertTrue((self.scope / "profiles/b/test.vvp").exists())

    def test_manifest_path_edit_is_rejected(self) -> None:
        payload = RETIRE.build_preview(self.root, self.scope)
        mutated = copy.deepcopy(payload)
        mutated["entries"][0]["path"] = ".github/task-runs/run-b/test.vvp"
        with self.assertRaises(RETIRE.RetirementError):
            RETIRE.validate_manifest(self.root, mutated, require_pass=False)

    def test_reference_audit_rejects_unbound_image(self) -> None:
        payload = RETIRE.build_preview(self.root, self.scope)
        manifest = self.scope / "semantic-vvp-retirement.json"
        receipt = self.scope / "compile-image-retirement-receipt.json"
        RETIRE.write_json(
            self.scope / "summary.json",
            {"compiled_image": dict(payload["entries"][0])},
        )
        RETIRE.write_json(manifest, payload)
        RETIRE.apply_retirement(self.root, manifest, receipt)
        audit = RETIRE.build_reference_audit(
            self.root, manifest, self.scope / "reference-audit.json"
        )
        self.assertEqual(audit["status"], "GAP")
        self.assertEqual(audit["missing_reference_count"], 1)


if __name__ == "__main__":
    unittest.main()
