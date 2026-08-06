from __future__ import annotations

import importlib.util
import json
import pathlib
import sys
import tempfile
import unittest


ROOT = pathlib.Path(__file__).resolve().parents[5]
TOOL_PATH = ROOT / "npc/rv64/eval/ppa/tools/system_recertification_run.py"
RUNNER_PATH = ROOT / "npc/rv64/eval/ppa/run-system-recertification-current.sh"
POLICY_PATH = (
    ROOT / "npc/rv64/design/arch/system-recertification-run-policy-v1.json"
)
SPEC = importlib.util.spec_from_file_location(
    "system_recertification_run_under_test", TOOL_PATH
)
assert SPEC and SPEC.loader
TOOL = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = TOOL
SPEC.loader.exec_module(TOOL)


def execution_text() -> str:
    return "\n".join(
        (
            "HIT GOOD TRAP at pc = 0x00000000800237ae",
            "exit via system-reset, code=0, cycles=5071521696, commits=1223536213",
            "total guest instructions = 1223536213",
            "total guest cycles = 5071521696",
            "CPI (cycles/instruction) = 4.145",
        )
    )


def terminal_text() -> str:
    return "\n".join(
        (
            "__NPC_SYSTEMD_STRICT_DONE__ rc=0",
            "__NPC_SYSTEMD_POWEROFF_BEGIN__",
            "reboot: Power down",
            "syscon-reset: poweroff requested value=0x00005555",
            "exit via system-reset, code=0",
            "HIT GOOD TRAP",
            "total guest instructions = 1",
            "total guest cycles = 2",
        )
    )


def transaction() -> dict:
    counts = {"preflight": 6, "autocheck": 6, "strict": 17}
    return {
        "status": "PASS",
        "stages": [
            {
                "name": name,
                "status": "PASS",
                "done_rc": 0,
                "errors": [],
                "fail_markers": [],
                "pass_observation_count": count,
                "expected_pass_labels": [f"{name}-{index}" for index in range(count)],
            }
            for name, count in counts.items()
        ],
    }


class SystemRecertificationRunnerTests(unittest.TestCase):
    def test_policy_keeps_state_vector_and_promotion_boundary_separate(self) -> None:
        policy = TOOL.require_policy(ROOT)
        self.assertEqual(policy["required_states"]["execution_state"], "PASS")
        self.assertEqual(
            policy["promotion_boundary"]["system_transaction"],
            "PASS_CURRENT_IDENTITY",
        )
        self.assertEqual(policy["promotion_boundary"]["architecture"], "NOT_IMPLIED")
        self.assertEqual(policy["promotion_boundary"]["ppa"], "NOT_IMPLIED")
        self.assertEqual(
            policy["promotion_boundary"]["default_system_signoff"],
            "NOT_REQUIRED_BY_THIS_OPTIONAL_RUN",
        )
        self.assertEqual(
            policy["launch_authorization"]["mode"],
            "explicit-user-request-only",
        )
        self.assertFalse(policy["launch_authorization"]["automatic_launch"])
        self.assertFalse(
            policy["launch_authorization"]["default_promotion_gate"]
        )
        self.assertIn("NpcSimTop executable", policy["retention"]["remove"])
        self.assertIn("driver, console and NPC execution logs", policy["retention"]["keep"])

    def test_policy_json_is_canonical_object_without_duplicate_keys(self) -> None:
        policy = TOOL.load_json(POLICY_PATH)
        self.assertEqual(policy["schema"], TOOL.POLICY_SCHEMA)
        self.assertEqual(json.loads(POLICY_PATH.read_text(encoding="utf-8")), policy)

    def test_execution_parser_binds_reset_statistics_and_pc(self) -> None:
        parsed = TOOL.parse_execution(execution_text())
        self.assertEqual(parsed["commits"], 1_223_536_213)
        self.assertEqual(parsed["cycles"], 5_071_521_696)
        self.assertEqual(parsed["final_pc"], "0x00000000800237ae")
        self.assertEqual(parsed["system_reset_code"], 0)

    def test_execution_parser_rejects_duplicate_terminal_result(self) -> None:
        with self.assertRaises(TOOL.RecertificationRunError):
            TOOL.parse_execution(execution_text() + "\n" + execution_text())

    def test_terminal_contract_accepts_exact_once(self) -> None:
        counts = TOOL.exact_terminal_counts(terminal_text())
        self.assertEqual(set(counts), set(TOOL.TERMINAL_MARKERS))
        self.assertTrue(all(value == 1 for value in counts.values()))

    def test_terminal_contract_rejects_duplicate_good_trap(self) -> None:
        with self.assertRaises(TOOL.RecertificationRunError):
            TOOL.exact_terminal_counts(terminal_text() + "\nHIT GOOD TRAP")

    def test_transaction_contract_rejects_missing_strict_observation(self) -> None:
        candidate = transaction()
        candidate["stages"][-1]["pass_observation_count"] = 16
        with self.assertRaises(TOOL.RecertificationRunError):
            TOOL.validate_transaction(candidate)

    def test_transaction_contract_accepts_exact_stage_inventory(self) -> None:
        self.assertEqual(
            TOOL.validate_transaction(transaction()),
            {"preflight": 6, "autocheck": 6, "strict": 17},
        )

    @unittest.skipUnless(hasattr(pathlib.Path, "symlink_to"), "symlink unavailable")
    def test_lexical_input_rejects_symlink_before_resolution(self) -> None:
        with tempfile.TemporaryDirectory() as raw:
            root = pathlib.Path(raw)
            (root / "real.txt").write_text("rtl\n", encoding="utf-8")
            (root / "alias.txt").symlink_to(root / "real.txt")
            with self.assertRaises(TOOL.RecertificationRunError):
                TOOL.lexical_regular_file(root, pathlib.PurePosixPath("alias.txt"))

    def test_runner_uses_isolated_config_and_fail_closed_status(self) -> None:
        text = RUNNER_PATH.read_text(encoding="utf-8")
        self.assertIn("scripts/task-run-status.sh", text)
        self.assertIn("rv64-engineering-single-flight.lock", text)
        self.assertIn("npc-source-sandbox", text)
        self.assertIn("task_run_status_mark_evidence_complete", text)
        self.assertNotIn("make -C \"${repo_root}/npc/rv64\" default_defconfig", text)
        self.assertNotIn("ubuntu-rootfs-systemd-strict-image", text)
        self.assertNotIn("2026-08-02-rv64-v14e", text)
        self.assertIn("--user-authorized-full-ubuntu", text)
        self.assertIn("Ubuntu 22.04 execution requires", text)

    def test_input_contract_lists_current_v14u_rtl_and_runtime_artifacts(self) -> None:
        self.assertIn(pathlib.PurePosixPath("npc/rv64/vsrc"), TOOL.INPUT_TREES)
        self.assertIn(
            pathlib.PurePosixPath("nemu/build/riscv64-nemu-interpreter-so"),
            TOOL.INPUT_FILES,
        )

    def test_source_sandbox_requires_exact_copied_closure(self) -> None:
        with tempfile.TemporaryDirectory() as raw:
            root = pathlib.Path(raw)
            sandbox = root / "sandbox"
            (sandbox / "vsrc").mkdir(parents=True)
            (sandbox / "Makefile").write_text("all:\n\t@true\n", encoding="utf-8")
            (sandbox / "vsrc/top.v").write_text("module top; endmodule\n", encoding="utf-8")
            snapshot_path = root / "snapshot.json"
            snapshot = {
                "schema": TOOL.INPUT_SCHEMA,
                "files": {
                    "npc/rv64/Makefile": {
                        "sha256": TOOL.sha256_file(sandbox / "Makefile"),
                        "size_bytes": (sandbox / "Makefile").stat().st_size,
                    },
                    "npc/rv64/vsrc/top.v": {
                        "sha256": TOOL.sha256_file(sandbox / "vsrc/top.v"),
                        "size_bytes": (sandbox / "vsrc/top.v").stat().st_size,
                    },
                },
            }
            snapshot_path.write_text(json.dumps(snapshot), encoding="utf-8")
            self.assertEqual(
                TOOL.verify_source_sandbox(root, snapshot_path, sandbox),
                {"expected_files": 2, "observed_files": 2},
            )
            (sandbox / "vsrc/extra.v").write_text(
                "module extra; endmodule\n", encoding="utf-8"
            )
            with self.assertRaises(TOOL.RecertificationRunError):
                TOOL.verify_source_sandbox(root, snapshot_path, sandbox)
        self.assertIn(
            pathlib.PurePosixPath(
                "Linux/env/platforms/npc/images/ubuntu2204/"
                "ubuntu-22.04-riscv64-strict.ext4"
            ),
            TOOL.INPUT_FILES,
        )


if __name__ == "__main__":
    unittest.main()
