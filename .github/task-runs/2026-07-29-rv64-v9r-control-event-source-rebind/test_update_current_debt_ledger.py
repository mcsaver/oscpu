#!/usr/bin/env python3
from __future__ import annotations

import importlib.util
import pathlib
import subprocess
import sys
import unittest
from types import SimpleNamespace
from unittest import mock


ROOT = pathlib.Path(__file__).resolve().parents[3]
UPDATER = (
    ROOT
    / ".github/task-runs/2026-07-22-rv64-v9l-functional-aggregate-current-design"
    / "update-current-debt-ledger.py"
)
SPEC = importlib.util.spec_from_file_location(
    "testable_v9l_debt_updater", UPDATER
)
assert SPEC and SPEC.loader
MODULE = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = MODULE
SPEC.loader.exec_module(MODULE)


class SerializeVerifierDispatchTests(unittest.TestCase):
    def exact_entry(self) -> dict[str, object]:
        return {
            "id": "SERIALIZE-G1",
            "canonical_command": MODULE.SERIALIZE_COMMAND,
            "evidence": [
                dict(item) for item in MODULE.SERIALIZE_EXPECTED_EVIDENCE
            ],
        }

    @mock.patch.object(MODULE.subprocess, "run")
    def test_accepts_only_zero_rc_exact_pass_marker(
        self, run: mock.Mock
    ) -> None:
        run.return_value = SimpleNamespace(
            returncode=0,
            stdout=(
                "[SERIALIZE-G1-VERIFY] design_id=sha256:"
                + "0" * 64
                + " review=APPROVED PASS\n"
            ),
            stderr="",
        )
        MODULE.verify_serialize_entry(self.exact_entry())
        run.assert_called_once_with(
            ["python3", str(MODULE.SERIALIZE_VERIFY)],
            cwd=MODULE.ROOT,
            text=True,
            capture_output=True,
            check=False,
        )

    @mock.patch.object(MODULE.subprocess, "run")
    def test_rejects_command_substitution(self, run: mock.Mock) -> None:
        entry = self.exact_entry()
        entry["canonical_command"] += " --skip-review"
        with self.assertRaisesRegex(RuntimeError, "command is not exact"):
            MODULE.verify_serialize_entry(entry)
        run.assert_not_called()

    @mock.patch.object(MODULE.subprocess, "run")
    def test_rejects_nonzero_verifier(self, run: mock.Mock) -> None:
        run.return_value = SimpleNamespace(
            returncode=1,
            stdout="",
            stderr="review tuple drifted",
        )
        with self.assertRaisesRegex(RuntimeError, "canonical verifier failed"):
            MODULE.verify_serialize_entry(self.exact_entry())

    @mock.patch.object(MODULE.subprocess, "run")
    def test_rejects_missing_terminal_pass_marker(
        self, run: mock.Mock
    ) -> None:
        run.return_value = SimpleNamespace(
            returncode=0,
            stdout="[SERIALIZE-G1-VERIFY] review=APPROVED\n",
            stderr="",
        )
        with self.assertRaisesRegex(RuntimeError, "exact PASS marker"):
            MODULE.verify_serialize_entry(self.exact_entry())

    @mock.patch.object(MODULE.subprocess, "run")
    def test_rejects_missing_tuple_member(self, run: mock.Mock) -> None:
        entry = self.exact_entry()
        entry["evidence"] = entry["evidence"][:-1]
        with self.assertRaisesRegex(RuntimeError, "tuple is not exact"):
            MODULE.verify_serialize_entry(entry)
        run.assert_not_called()

    @mock.patch.object(MODULE.subprocess, "run")
    def test_rejects_extra_tuple_member(self, run: mock.Mock) -> None:
        entry = self.exact_entry()
        entry["evidence"].append(dict(MODULE.SERIALIZE_EXPECTED_EVIDENCE[0]))
        with self.assertRaisesRegex(RuntimeError, "tuple is not exact"):
            MODULE.verify_serialize_entry(entry)
        run.assert_not_called()

    @mock.patch.object(MODULE.subprocess, "run")
    def test_rejects_remapped_tuple_member(self, run: mock.Mock) -> None:
        entry = self.exact_entry()
        entry["evidence"][0] = {
            **entry["evidence"][0],
            "path": entry["evidence"][1]["path"],
        }
        with self.assertRaisesRegex(RuntimeError, "tuple is not exact"):
            MODULE.verify_serialize_entry(entry)
        run.assert_not_called()


if __name__ == "__main__":
    unittest.main()
