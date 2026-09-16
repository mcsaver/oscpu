#!/usr/bin/env python3

from __future__ import annotations

import copy
import hashlib
import importlib.util
import json
import pathlib
import sys
import tempfile
import unittest


ROOT = pathlib.Path(__file__).resolve().parents[5]
TOOL_PATH = (
    ROOT / "npc/rv64/eval/ppa/tools/historical_defect_backfill.py"
)
LEDGER_PATH = (
    ROOT / "npc/rv64/design/arch/historical-defect-backfill-ledger.json"
)
SCHEMA_PATH = (
    ROOT / "npc/rv64/eval/ppa/schemas/"
    "historical-defect-backfill-ledger-v1.schema.json"
)


def load_tool():
    spec = importlib.util.spec_from_file_location(
        "historical_defect_backfill_tested",
        TOOL_PATH,
    )
    assert spec is not None and spec.loader is not None
    module = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    return module


def sha256_bytes(value: bytes) -> str:
    return hashlib.sha256(value).hexdigest()


class HistoricalDefectBackfillTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.tool = load_tool()
        cls.live_ledger = json.loads(LEDGER_PATH.read_text(encoding="utf-8"))
        cls.live_schema = json.loads(SCHEMA_PATH.read_text(encoding="utf-8"))

    def make_workspace(
        self,
        temp: pathlib.Path,
        transform=None,
    ) -> tuple[pathlib.Path, dict]:
        ledger = copy.deepcopy(self.live_ledger)
        if transform is not None:
            transform(ledger)

        schema_path = temp / self.tool.SCHEMA_PATH
        schema_path.parent.mkdir(parents=True, exist_ok=True)
        schema_path.write_text(
            json.dumps(self.live_schema, indent=2) + "\n",
            encoding="utf-8",
        )

        for entry in ledger["entries"]:
            for owner in entry["owner_paths"]:
                owner_path = temp / owner
                owner_path.parent.mkdir(parents=True, exist_ok=True)
                owner_path.touch(exist_ok=True)

        for entry in ledger["entries"]:
            for field in ("source_artifacts", "current_evidence"):
                for artifact in entry[field]:
                    artifact_path = temp / artifact["path"]
                    artifact_path.parent.mkdir(parents=True, exist_ok=True)
                    content = (artifact["path"] + "\n").encode("utf-8")
                    artifact_path.write_bytes(content)
                    artifact["sha256"] = sha256_bytes(content)

        ledger_path = temp / self.tool.LEDGER_PATH
        ledger_path.parent.mkdir(parents=True, exist_ok=True)
        ledger_path.write_text(
            json.dumps(ledger, indent=2) + "\n",
            encoding="utf-8",
        )
        return ledger_path, ledger

    def test_live_ledger_closes_the_terminal_duplicate_at_vd4(self) -> None:
        result = self.tool.audit(
            ROOT,
            expected_design_id=self.live_ledger["design_id"],
        )
        self.assertTrue(result["valid"], result["errors"])
        self.assertEqual(result["status"], "PASS")
        self.assertEqual(result["selected_id"], "NONE")
        self.assertEqual(result["counts"]["depths"]["VD1"], 0)
        self.assertEqual(result["counts"]["depths"]["VD3"], 3)
        self.assertEqual(result["counts"]["depths"]["VD4"], 3)
        self.assertEqual(result["current_receipt_status"], "PASS")

    def test_wrong_selected_entry_fails_closed(self) -> None:
        def transform(ledger):
            for entry in ledger["entries"]:
                if entry["id"] == (
                    "HIST-V9P-TERMINAL-COLLECTOR-INGRESS-DUP"
                ):
                    entry["status"] = "QUEUED"
            ledger["entries"][0]["validation_depth"] = "VD1"
            ledger["entries"][0]["status"] = "QUEUED"
            ledger["entries"][1]["validation_depth"] = "VD1"
            ledger["entries"][1]["status"] = "SELECTED"
            ledger["selected_id"] = ledger["entries"][1]["id"]

        with tempfile.TemporaryDirectory() as directory:
            root = pathlib.Path(directory)
            _, ledger = self.make_workspace(root, transform)
            result = self.tool.audit(
                root,
                expected_design_id=ledger["design_id"],
                require_current_receipt=False,
            )
        self.assertFalse(result["valid"])
        self.assertTrue(
            any("highest-priority" in error for error in result["errors"])
        )

    def test_artifact_hash_drift_fails_closed(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = pathlib.Path(directory)
            _, ledger = self.make_workspace(root)
            artifact = ledger["entries"][0]["source_artifacts"][0]
            (root / artifact["path"]).write_text("drift\n", encoding="utf-8")
            result = self.tool.audit(
                root,
                expected_design_id=ledger["design_id"],
                require_current_receipt=False,
            )
        self.assertFalse(result["valid"])
        self.assertTrue(
            any("hash drifted" in error for error in result["errors"])
        )

    def test_zero_vd0_vd1_allows_no_selected_entry(self) -> None:
        def transform(ledger):
            for entry in ledger["entries"]:
                if entry["validation_depth"] in {"VD0", "VD1"}:
                    entry["validation_depth"] = "VD2"
                    entry["status"] = "BACKFILLED"
            ledger["selected_id"] = "NONE"

        with tempfile.TemporaryDirectory() as directory:
            root = pathlib.Path(directory)
            _, ledger = self.make_workspace(root, transform)
            result = self.tool.audit(
                root,
                expected_design_id=ledger["design_id"],
                require_current_receipt=False,
            )
        self.assertTrue(result["valid"], result["errors"])
        self.assertEqual(result["status"], "PASS")
        self.assertEqual(result["blocking_ids"], [])

    def test_missing_known_defect_cannot_disable_the_inventory_gate(self) -> None:
        def transform(ledger):
            ledger["entries"] = [
                entry
                for entry in ledger["entries"]
                if entry["id"] != (
                    "HIST-V9P-TERMINAL-COLLECTOR-INGRESS-DUP"
                )
            ]
            ledger["selected_id"] = "NONE"

        with tempfile.TemporaryDirectory() as directory:
            root = pathlib.Path(directory)
            _, ledger = self.make_workspace(root, transform)
            result = self.tool.audit(
                root,
                expected_design_id=ledger["design_id"],
                require_current_receipt=False,
            )
        self.assertFalse(result["valid"])
        self.assertTrue(
            any("ledger inventory drifted" in error
                for error in result["errors"])
        )

    def test_cleared_inventory_is_fully_supported_by_current_receipt(self) -> None:
        def transform(ledger):
            for entry in ledger["entries"]:
                if entry["validation_depth"] in {"VD0", "VD1"}:
                    entry["validation_depth"] = "VD2"
                    entry["status"] = "BACKFILLED"
            ledger["selected_id"] = "NONE"

        with tempfile.TemporaryDirectory() as directory:
            root = pathlib.Path(directory)
            _, ledger = self.make_workspace(root, transform)
            result = self.tool.audit(
                root,
                expected_design_id=ledger["design_id"],
                require_current_receipt=False,
            )
        self.assertTrue(result["valid"], result["errors"])
        self.assertEqual(result["status"], "PASS")
        self.assertEqual(
            self.tool.CURRENT_RECEIPT_IDS,
            self.tool.KNOWN_LEDGER_IDS,
        )


if __name__ == "__main__":
    unittest.main()
