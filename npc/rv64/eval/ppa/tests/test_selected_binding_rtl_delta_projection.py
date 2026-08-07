#!/usr/bin/env python3
"""Directed fail-closed tests for the V14R RTL-delta projection receipt."""

from __future__ import annotations

import importlib.util
import json
import os
import pathlib
import shutil
import subprocess
import sys
import tempfile
import unittest


ROOT = pathlib.Path(__file__).resolve().parents[5]
TOOL = ROOT / "npc/rv64/eval/ppa/tools/selected_binding_rtl_delta_projection.py"
PRIOR_RECEIPT = ROOT / (
    ".github/task-runs/2026-08-06-rv64-v15h-architecture-debt-current-f7a/"
    "evidence/selected-binding-rtl-delta-projection/receipt.json"
)


def load_tool():
    spec = importlib.util.spec_from_file_location("rtl_delta_projection", TOOL)
    assert spec and spec.loader
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


MODULE = load_tool()


class SelectedBindingRtlDeltaProjectionTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.temp = tempfile.TemporaryDirectory(prefix="rv64-rtl-delta-test-")
        cls.base = pathlib.Path(cls.temp.name)
        cls.captured = cls.base / "captured.json"
        cls.capture = subprocess.run(
            [
                sys.executable,
                str(TOOL),
                "rebind",
                "--root",
                str(ROOT),
                "--input",
                str(PRIOR_RECEIPT),
                "--output",
                str(cls.captured),
            ],
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            check=False,
        )
        if cls.capture.returncode != 0:
            raise AssertionError(
                f"rebind rc={cls.capture.returncode}\n"
                f"stdout={cls.capture.stdout}\nstderr={cls.capture.stderr}"
            )
        cls.master = cls.base / "master"
        for relative in (
            *MODULE.RTL_PATHS,
            *MODULE.CONSUMER_PATHS,
            MODULE.CENSUS,
            MODULE.COVERAGE,
            MODULE.POLICY,
        ):
            destination = cls.master / relative
            destination.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(ROOT / relative, destination)
        evidence_destination = cls.master / MODULE.EVIDENCE
        evidence_destination.parent.mkdir(parents=True, exist_ok=True)
        shutil.copytree(ROOT / MODULE.EVIDENCE, evidence_destination)
        shutil.copy2(cls.captured, cls.master / "receipt.json")

    @classmethod
    def tearDownClass(cls) -> None:
        cls.temp.cleanup()

    def setUp(self) -> None:
        self.fixture = self.base / self._testMethodName
        shutil.copytree(self.master, self.fixture)

    def verify(self, *, no_path: bool = False) -> subprocess.CompletedProcess[str]:
        env = os.environ.copy()
        if no_path:
            env["PATH"] = ""
        return subprocess.run(
            [
                sys.executable,
                str(TOOL),
                "verify",
                "--root",
                str(self.fixture),
                "--receipt",
                str(self.fixture / "receipt.json"),
            ],
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            env=env,
            check=False,
        )

    def rebind(self) -> subprocess.CompletedProcess[str]:
        return subprocess.run(
            [
                sys.executable,
                str(TOOL),
                "rebind",
                "--root",
                str(self.fixture),
                "--input",
                str(self.fixture / "receipt.json"),
                "--output",
                str(self.fixture / "rebound.json"),
            ],
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            check=False,
        )

    def rewrite_receipt(self, mutate) -> None:
        path = self.fixture / "receipt.json"
        value = json.loads(path.read_text(encoding="utf-8"))
        mutate(value)
        path.write_text(json.dumps(value, indent=2, sort_keys=True) + "\n", encoding="utf-8")

    def test_current_v14r_rebind_and_git_free_verify_pass(self) -> None:
        self.assertIn("PASS mode=rebind", self.capture.stdout)
        receipt = json.loads(self.captured.read_text(encoding="utf-8"))
        self.assertRegex(
            receipt["current_design_id"], r"^sha256:[0-9a-f]{64}$"
        )
        self.assertFalse((self.fixture / ".git").exists())
        completed = self.verify(no_path=True)
        self.assertEqual(completed.returncode, 0, completed.stderr)
        self.assertIn("PASS mode=verify", completed.stdout)

    def test_current_rtl_byte_mutation_returns_nonzero(self) -> None:
        path = self.fixture / MODULE.RTL_PATHS[1]
        path.write_bytes(path.read_bytes() + b"\n")
        completed = self.verify()
        self.assertNotEqual(completed.returncode, 0)
        self.assertIn("current RTL hash drift", completed.stderr)

    def test_current_testbench_byte_mutation_returns_nonzero(self) -> None:
        path = self.fixture / MODULE.CONSUMER_PATHS[0]
        path.write_bytes(path.read_bytes() + b"\n")
        completed = self.verify()
        self.assertNotEqual(completed.returncode, 0)
        self.assertIn("current RTL hash drift", completed.stderr)

    def test_testbench_delta_cannot_rewrite_old_lines(self) -> None:
        def mutate(value):
            edit = value["consumer_delta"][0]["edits"][0]
            edit["tag"] = "replace"
            value["consumer_delta_sha256"] = MODULE.digest(
                value["consumer_delta"]
            )

        self.rewrite_receipt(mutate)
        completed = self.verify()
        self.assertNotEqual(completed.returncode, 0)
        self.assertIn("changed existing lines", completed.stderr)

    def test_current_design_identity_mutation_returns_nonzero(self) -> None:
        def mutate(value):
            value["current_design_id"] = "sha256:" + "0" * 64

        self.rewrite_receipt(mutate)
        completed = self.verify()
        self.assertNotEqual(completed.returncode, 0)
        self.assertIn("current design identity drift", completed.stderr)

    def test_unrelated_whole_design_identity_can_rebind_without_git(self) -> None:
        census_path = self.fixture / MODULE.CENSUS
        census = json.loads(census_path.read_text(encoding="utf-8"))
        census["design_id"] = "sha256:" + "1" * 64
        census_path.write_text(
            json.dumps(census, indent=2, sort_keys=True) + "\n",
            encoding="utf-8",
        )
        completed = self.rebind()
        self.assertEqual(completed.returncode, 0, completed.stderr)
        self.assertIn("PASS mode=rebind", completed.stdout)
        shutil.copy2(self.fixture / "rebound.json", self.fixture / "receipt.json")
        verified = self.verify(no_path=True)
        self.assertEqual(verified.returncode, 0, verified.stderr)

    def test_reversible_edit_mutation_returns_nonzero(self) -> None:
        def mutate(value):
            edit = next(
                item
                for record in value["rtl_delta"]
                for item in record["edits"]
                if item["baseline_b64"] != item["current_b64"]
            )
            edit["baseline_b64"] = edit["current_b64"]
            edit["baseline_chunk_sha256"] = edit["current_chunk_sha256"]
            value["rtl_delta_sha256"] = MODULE.digest(value["rtl_delta"])

        self.rewrite_receipt(mutate)
        completed = self.verify()
        self.assertNotEqual(completed.returncode, 0)
        self.assertIn("baseline hash mismatch", completed.stderr)

    def test_preexisting_holder_write_fingerprint_mutation_returns_nonzero(self) -> None:
        def mutate(value):
            holder = value["holder_write_projection"]
            fingerprint = holder["pre_existing_state_writes"][0]["fingerprint"]
            fingerprint["writes"].append("synthetic_q <= 1'b1;")
            fingerprint["count"] = len(fingerprint["writes"])
            fingerprint["sha256"] = MODULE.digest(fingerprint["writes"])
            unsigned = {key: item for key, item in holder.items() if key != "projection_sha256"}
            holder["projection_sha256"] = MODULE.digest(unsigned)

        self.rewrite_receipt(mutate)
        completed = self.verify()
        self.assertNotEqual(completed.returncode, 0)
        self.assertIn("holder write projection drift", completed.stderr)

    def test_v14r_artifact_hash_mutation_returns_nonzero(self) -> None:
        path = self.fixture / MODULE.EVIDENCE / next(iter(MODULE.POSITIVE_LOGS))
        path.write_bytes(path.read_bytes() + b"\n[V14R-ARTIFACT-MUTATION]\n")
        completed = self.verify()
        self.assertNotEqual(completed.returncode, 0)
        self.assertIn("V14R evidence projection drift", completed.stderr)


if __name__ == "__main__":
    unittest.main(verbosity=2)
