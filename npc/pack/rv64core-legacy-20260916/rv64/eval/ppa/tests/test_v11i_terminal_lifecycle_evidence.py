from __future__ import annotations

import copy
import json
import os
import sys
import tempfile
import unittest
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[5]
if str(REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(REPO_ROOT))

from npc.rv64.eval.ppa.tools.v11i_terminal_lifecycle_evidence import (  # noqa: E402
    EvidenceError,
    validate,
)


DEFAULT_SUMMARY = (
    REPO_ROOT
    / ".github"
    / "task-runs"
    / "2026-07-30-rv64-v11i-terminal-lifecycle-after-lq-clear"
    / "evidence"
    / "terminal-lifecycle-attempt-11"
    / "summary.json"
)


class V11ITerminalLifecycleEvidenceTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.summary_path = Path(
            os.environ.get("V11I_EVIDENCE_SUMMARY", DEFAULT_SUMMARY)
        ).resolve()
        if not cls.summary_path.is_file():
            raise RuntimeError(f"missing V11I evidence: {cls.summary_path}")
        cls.summary = json.loads(cls.summary_path.read_text(encoding="utf-8"))

    def validate_mutation(self, mutate, *, expected_error: str | None = None) -> None:
        value = copy.deepcopy(self.summary)
        with tempfile.TemporaryDirectory(
            prefix=".v11i-validator-test-",
            dir=self.summary_path.parent,
        ) as temporary:
            mutate(value, Path(temporary))
            path = Path(temporary) / "summary.json"
            path.write_text(
                json.dumps(value, ensure_ascii=False, indent=2, sort_keys=True)
                + "\n",
                encoding="utf-8",
            )
            if expected_error is None:
                with self.assertRaises(EvidenceError):
                    validate(REPO_ROOT, path)
            else:
                with self.assertRaisesRegex(EvidenceError, expected_error):
                    validate(REPO_ROOT, path)

    def test_current_frozen_evidence_passes(self) -> None:
        receipt = validate(REPO_ROOT, self.summary_path)
        self.assertEqual("PASS", receipt["status"])
        self.assertEqual(4, len(receipt["profiles"]))
        self.assertFalse(receipt["full_system_run_launched"])

    def test_nonzero_production_simulation_is_rejected(self) -> None:
        self.validate_mutation(
            lambda value, _: value["profiles"][0]["simulation"].update({"rc": 1})
        )

    def test_raw_log_hash_drift_is_rejected(self) -> None:
        self.validate_mutation(
            lambda value, _: value["profiles"][0]["simulation"].update(
                {"log_sha256": "0" * 64}
            )
        )

    def test_missing_mutation_receipt_is_rejected(self) -> None:
        self.validate_mutation(
            lambda value, _: value["stale_tuple_variant"]["receipts"].pop()
        )

    def test_runner_input_drift_is_rejected(self) -> None:
        def mutate(value, _):
            first = next(iter(value["runner_inputs"]["pre"]))
            value["runner_inputs"]["pre"][first] = "0" * 64
            value["runner_inputs"]["post"][first] = "0" * 64

        self.validate_mutation(mutate)

    def test_system_scope_promotion_is_rejected(self) -> None:
        self.validate_mutation(
            lambda value, _: value["scope_boundary"].update(
                {"full_system_run_launched": True}
            )
        )

    def test_lane6_contract_observation_is_rejected(self) -> None:
        self.validate_mutation(
            lambda value, _: value["contract"].update(
                {
                    "testbench_observation": (
                        "lane6 collector ingress/accept, tracker live/table, "
                        "LQ valid/terminal_seen raw Q, holder-next assertion"
                    )
                }
            )
        )

    def test_missing_focused_compile_define_is_rejected(self) -> None:
        def mutate(value, temporary):
            profile = value["profiles"][0]
            raw_evidence = profile["raw_evidence"]
            command_key = next(
                key for key in raw_evidence if key.endswith("/commands.json")
            )
            command_path = REPO_ROOT / command_key
            commands = json.loads(command_path.read_text(encoding="utf-8"))
            commands["compile"]["command"].remove(
                "-DV11I_TERMINAL_LIFECYCLE_FOCUSED"
            )
            replacement = temporary / "commands-without-focused-define" / "commands.json"
            replacement.parent.mkdir()
            replacement.write_text(
                json.dumps(commands, ensure_ascii=False, indent=2, sort_keys=True)
                + "\n",
                encoding="utf-8",
            )
            del raw_evidence[command_key]
            replacement_key = replacement.relative_to(REPO_ROOT).as_posix()
            import hashlib

            raw_evidence[replacement_key] = hashlib.sha256(
                replacement.read_bytes()
            ).hexdigest()

        self.validate_mutation(
            mutate,
            expected_error=r"production-assert: focused compile define is missing",
        )


if __name__ == "__main__":
    unittest.main()
