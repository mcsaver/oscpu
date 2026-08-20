from __future__ import annotations

import copy
import json
import pathlib
import shutil
import tempfile
import unittest

from npc.rv64.eval.ppa.tools import act4_current as act4


CURRENT_RECEIPT = act4.ROOT / "npc/rv64/eval/ppa/evidence/act4-current.json"


class Act4CurrentTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.receipt = act4.load_json(CURRENT_RECEIPT)
        cls.snapshot = act4.load_json(
            pathlib.Path(cls.receipt["inputs"]["before"]["path"])
        )
        cls.raw_dir = act4.repo_dir(pathlib.Path(cls.receipt["source_directory"]))

    def workspace_temp(self) -> tempfile.TemporaryDirectory[str]:
        return tempfile.TemporaryDirectory(
            prefix="act4-current-test-",
            dir=act4.ROOT / ".github/task-runs",
        )

    def write_receipt_mutation(
        self, directory: pathlib.Path, value: dict
    ) -> pathlib.Path:
        path = directory / "mutated-receipt.json"
        path.write_text(json.dumps(value, sort_keys=True) + "\n", encoding="utf-8")
        return path

    def copied_case_runtime(self, directory: pathlib.Path) -> pathlib.Path:
        raw = directory / "raw"
        raw.mkdir()
        shutil.copy2(self.raw_dir / "status.txt", raw / "status.txt")
        shutil.copytree(self.raw_dir / "act4-log", raw / "act4-log")
        return raw

    def test_canonical_current_receipt_recomputes(self) -> None:
        value = act4.verify_receipt(CURRENT_RECEIPT)
        self.assertEqual(value["counts"]["passed"], 100)
        self.assertEqual(value["counts"]["rtl_assertion_failures"], 0)

    def test_inventory_binds_svnapot_capability(self) -> None:
        self.assertEqual(len(self.snapshot["elfs"]), 100)
        self.assertEqual(len(self.snapshot["excluded_elfs"]), 1)
        self.assertEqual(
            self.snapshot["excluded_elfs"][0]["case_id"],
            act4.EXPECTED_EXCLUDED_CASE,
        )
        napot_cases = {
            case["case_id"]
            for case in self.snapshot["elfs"]
            if case["suite"] == "priv/Svnapot"
        }
        self.assertEqual(len(napot_cases), 4)

    def test_unused_unknown_elf_compiler_inventory_is_non_semantic(self) -> None:
        frozen = {"make": {"sha256": "1" * 64}}
        live = {
            **frozen,
            "riscv64-unknown-elf-gcc": {"sha256": "2" * 64},
        }
        act4.validate_l1_toolchain_binding(frozen, live)
        act4.validate_l1_toolchain_binding(live, frozen)

        with self.assertRaisesRegex(act4.Act4Error, "inventory drift"):
            act4.validate_l1_toolchain_binding(
                frozen, {**frozen, "unrelated-tool": {"sha256": "3" * 64}}
            )

    def test_l1_downstream_checker_drift_does_not_require_dut_rerun(self) -> None:
        frozen = {
            "schema": "inputs-v1",
            "design_id": "sha256:" + "1" * 64,
            "required_tests": ["tb_a"],
            "official_test_ids": ["rv64ui-p-add"],
            "am_test_ids": ["dummy"],
            "groups": {
                "workflow": {
                    "npc/rv64/eval/ppa/tools/arch_stable_freeze.py": "2" * 64,
                    "npc/rv64/eval/ppa/tools/full_core_current_evidence.py": "3" * 64,
                },
                "functional_workflow": {
                    "npc/rv64/eval/ppa/tools/full_core_functional_evidence.py": "4" * 64,
                },
            },
        }
        live = copy.deepcopy(frozen)
        live["groups"]["workflow"][
            "npc/rv64/eval/ppa/tools/arch_stable_freeze.py"
        ] = "5" * 64
        live["groups"]["functional_workflow"][
            "npc/rv64/eval/ppa/tools/full_core_functional_evidence.py"
        ] = "6" * 64
        act4.validate_l1_input_binding(frozen, live)

    def test_l1_execution_runner_drift_remains_fail_closed(self) -> None:
        frozen = {
            "schema": "inputs-v1",
            "design_id": "sha256:" + "1" * 64,
            "required_tests": ["tb_a"],
            "official_test_ids": ["rv64ui-p-add"],
            "am_test_ids": ["dummy"],
            "groups": {
                "workflow": {
                    "npc/rv64/eval/ppa/tools/full_core_current_evidence.py": "2" * 64,
                },
            },
        }
        live = copy.deepcopy(frozen)
        live["groups"]["workflow"][
            "npc/rv64/eval/ppa/tools/full_core_current_evidence.py"
        ] = "3" * 64
        with self.assertRaisesRegex(act4.Act4Error, "input drift: groups"):
            act4.validate_l1_input_binding(frozen, live)

    def test_act4_checker_drift_projects_without_guest_rerun(self) -> None:
        frozen = {
            "design_id": "sha256:" + "1" * 64,
            "workflow_artifacts": {
                "checker": {"sha256": "2" * 64},
                "backend_runner": {"sha256": "3" * 64},
            },
            "elfs": [{"artifact": {"sha256": "4" * 64}}],
        }
        live = copy.deepcopy(frozen)
        live["workflow_artifacts"]["checker"]["sha256"] = "5" * 64
        self.assertEqual(
            act4.act4_execution_relevant_snapshot(frozen),
            act4.act4_execution_relevant_snapshot(live),
        )

    def test_act4_backend_runner_drift_remains_fail_closed(self) -> None:
        frozen = {
            "design_id": "sha256:" + "1" * 64,
            "workflow_artifacts": {
                "checker": {"sha256": "2" * 64},
                "backend_runner": {"sha256": "3" * 64},
            },
            "elfs": [{"artifact": {"sha256": "4" * 64}}],
        }
        live = copy.deepcopy(frozen)
        live["workflow_artifacts"]["backend_runner"]["sha256"] = "5" * 64
        self.assertNotEqual(
            act4.act4_execution_relevant_snapshot(frozen),
            act4.act4_execution_relevant_snapshot(live),
        )

    def test_missing_case_record_is_rejected(self) -> None:
        with self.workspace_temp() as raw_temp:
            directory = pathlib.Path(raw_temp)
            mutated = copy.deepcopy(self.receipt)
            mutated["cases"].pop()
            path = self.write_receipt_mutation(directory, mutated)
            with self.assertRaises(act4.Act4Error):
                act4.verify_receipt(path)

    def test_duplicate_case_record_is_rejected(self) -> None:
        with self.workspace_temp() as raw_temp:
            directory = pathlib.Path(raw_temp)
            mutated = copy.deepcopy(self.receipt)
            mutated["cases"].append(copy.deepcopy(mutated["cases"][0]))
            path = self.write_receipt_mutation(directory, mutated)
            with self.assertRaises(act4.Act4Error):
                act4.verify_receipt(path)

    def test_wrong_simulator_identity_is_rejected(self) -> None:
        with self.workspace_temp() as raw_temp:
            directory = pathlib.Path(raw_temp)
            mutated = copy.deepcopy(self.receipt)
            mutated["simulator"]["binary"]["sha256"] = "0" * 64
            path = self.write_receipt_mutation(directory, mutated)
            with self.assertRaisesRegex(act4.Act4Error, "differs from recomputed"):
                act4.verify_receipt(path)

    def test_missing_status_case_is_rejected(self) -> None:
        with self.workspace_temp() as raw_temp:
            directory = pathlib.Path(raw_temp)
            raw = directory / "raw"
            raw.mkdir()
            lines = (self.raw_dir / "status.txt").read_text(
                encoding="utf-8"
            ).splitlines()
            (raw / "status.txt").write_text(
                "\n".join(lines[1:]) + "\n", encoding="utf-8"
            )
            with self.assertRaisesRegex(act4.Act4Error, "membership"):
                act4.case_records(raw_dir=raw, snapshot=self.snapshot)

    def test_duplicate_terminal_pass_is_rejected(self) -> None:
        with self.workspace_temp() as raw_temp:
            directory = pathlib.Path(raw_temp)
            raw = self.copied_case_runtime(directory)
            first = self.snapshot["elfs"][0]["case_id"].replace("/", "__")
            with (raw / "act4-log" / f"{first}.log").open(
                "a", encoding="utf-8"
            ) as stream:
                stream.write("TOHOST PASS\n")
            with self.assertRaisesRegex(act4.Act4Error, "terminal/assertion"):
                act4.case_records(raw_dir=raw, snapshot=self.snapshot)

    def test_rtl_assertion_marker_is_rejected(self) -> None:
        with self.workspace_temp() as raw_temp:
            directory = pathlib.Path(raw_temp)
            raw = self.copied_case_runtime(directory)
            first = self.snapshot["elfs"][0]["case_id"].replace("/", "__")
            with (raw / "act4-log" / f"{first}.log").open(
                "a", encoding="utf-8"
            ) as stream:
                stream.write("[V15Z-ACT4-ASSERT-FAIL] directed mutation\n")
            with self.assertRaisesRegex(act4.Act4Error, "terminal/assertion"):
                act4.case_records(raw_dir=raw, snapshot=self.snapshot)

    def test_pre_post_input_drift_is_rejected(self) -> None:
        with self.workspace_temp() as raw_temp:
            directory = pathlib.Path(raw_temp)
            run = directory / "raw"
            run.mkdir()
            before = directory / "before.json"
            after = directory / "after.json"
            before.write_text(json.dumps(self.snapshot) + "\n", encoding="utf-8")
            mutated = copy.deepcopy(self.snapshot)
            mutated["design_id"] = "sha256:" + "0" * 64
            after.write_text(json.dumps(mutated) + "\n", encoding="utf-8")
            with self.assertRaisesRegex(act4.Act4Error, "before/after"):
                act4.build_receipt(
                    raw_dir=run,
                    before_path=before,
                    after_path=after,
                    cleanup_path=directory / "unused-cleanup.json",
                    execution_manifest_path=directory / "unused-manifest.txt",
                )

    def test_execution_manifest_is_exact_and_excludes_inapplicable_case(self) -> None:
        with self.workspace_temp() as raw_temp:
            directory = pathlib.Path(raw_temp)
            output = directory / "manifest.txt"
            act4.write_execution_manifest(
                snapshot_path=pathlib.Path(self.receipt["inputs"]["before"]["path"]),
                output_path=output,
            )
            lines = output.read_text(encoding="utf-8").splitlines()
            self.assertEqual(len(lines), 100)
            self.assertEqual(len(set(lines)), 100)
            self.assertFalse(any(act4.EXPECTED_EXCLUDED_CASE.split("/")[-1] in line for line in lines))


if __name__ == "__main__":
    unittest.main()
