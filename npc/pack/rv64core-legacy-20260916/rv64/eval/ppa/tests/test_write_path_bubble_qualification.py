#!/usr/bin/env python3

from __future__ import annotations

import importlib.util
import pathlib
import tempfile
import unittest


ROOT = pathlib.Path(__file__).resolve().parents[5]
TOOL = ROOT / "npc/rv64/eval/ppa/tools/write_path_bubble_qualification.py"
SPEC = importlib.util.spec_from_file_location("write_path_bubble", TOOL)
assert SPEC and SPEC.loader
MODULE = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(MODULE)


def valid_fields() -> dict[str, int | str]:
    fields: dict[str, int | str] = {
        "schema": MODULE.SCHEMA,
        "complete": 1,
        "available": 1,
        "overflow": 0,
        "invalid": 0,
        "cycles": 100,
        "arb_events": 10,
        "arb_source11": 7,
        "arb_source10": 1,
        "arb_source01": 2,
        "arb_source00": 0,
        "arb_ready11": 8,
        "arb_ready10": 1,
        "arb_ready01": 1,
        "arb_ready00": 0,
        "arb_lane0": 6,
        "arb_lane1": 4,
        "arb_contention": 2,
        "arb_strict": 6,
        "xbar_grant_cycles": 12,
        "xbar_grants": 12,
        "xbar_ready11": 10,
        "xbar_ready10": 1,
        "xbar_ready01": 1,
        "xbar_ready00": 0,
        "xbar_master0": 1,
        "xbar_master1": 11,
        "xbar_grant_bvalid": 0,
        "xbar_head0_wr_rsp": 5,
        "xbar_head1_wr_rsp": 4,
        "xbar_head_any_wr_rsp": 8,
        "xbar_strict": 10,
        "live_pairs": 11,
        "live_master0": 1,
        "live_master1": 10,
        "live_target_inactive": 11,
        "live_target_active": 0,
        "live_older_holder": 0,
        "live_same_target_conflict": 0,
        "live_narrow_eligible": 11,
        "arb_conservation": 1,
        "xbar_ready_conservation": 1,
        "xbar_master_conservation": 1,
        "xbar_target_conservation": 1,
        "live_conservation": 1,
    }
    for index in range(16):
        fields[f"xbar_target{index}"] = 12 if index == 3 else 0
    return fields


def marker(fields: dict[str, int | str] | None = None) -> str:
    values = valid_fields() if fields is None else fields
    return "WRITE_PATH_BUBBLE_FINAL " + " ".join(
        f"{key}={value}" for key, value in values.items())


def full_log() -> str:
    return "\n".join([
        "Difftest: ON",
        "npc GOOD TRAP at pc",
        marker(),
        ("FINAL schema=npc-rv64-region-final-v1 complete=1 "
         "termination_rc=0 cycles=100 retired=50"),
        ("COUNTERS_FINAL schema=npc-rv64-performance-counter-v4 "
         "complete=1 available=1 overflow=0 invalid_events=0 cycles=100 "
         "retired_slots=50 conservation=1"),
    ])


class WritePathBubbleQualificationTest(unittest.TestCase):
    def test_valid_marker(self) -> None:
        parsed = MODULE.parse_marker_text(marker())
        self.assertEqual(parsed["xbar_grants"], 12)
        self.assertEqual(parsed["arb_strict"], 6)

    def test_duplicate_marker_rejected(self) -> None:
        with self.assertRaisesRegex(MODULE.EvidenceError, "exactly one"):
            MODULE.parse_marker_text(marker() + "\n" + marker())

    def test_truncated_marker_rejected(self) -> None:
        fields = valid_fields()
        del fields["xbar_ready00"]
        with self.assertRaisesRegex(MODULE.EvidenceError, "field mismatch"):
            MODULE.parse_marker_text(marker(fields))

    def test_extra_field_rejected(self) -> None:
        fields = valid_fields()
        fields["invented"] = 1
        with self.assertRaisesRegex(MODULE.EvidenceError, "field mismatch"):
            MODULE.parse_marker_text(marker(fields))

    def test_malformed_integer_rejected(self) -> None:
        fields = valid_fields()
        fields["xbar_grants"] = "12x"
        with self.assertRaisesRegex(MODULE.EvidenceError, "unsigned integer"):
            MODULE.parse_marker_text(marker(fields))

    def test_duplicate_field_rejected(self) -> None:
        with self.assertRaisesRegex(MODULE.EvidenceError, "duplicate field"):
            MODULE.parse_marker_text(marker() + " xbar_grants=12")

    def test_invalid_probe_rejected(self) -> None:
        fields = valid_fields()
        fields["invalid"] = 1
        with self.assertRaisesRegex(MODULE.EvidenceError, "probe invalid"):
            MODULE.parse_marker_text(marker(fields))

    def test_nonconserving_ready_matrix_rejected(self) -> None:
        fields = valid_fields()
        fields["xbar_ready11"] = 9
        with self.assertRaisesRegex(MODULE.EvidenceError, "ready-matrix"):
            MODULE.parse_marker_text(marker(fields))

    def test_false_conservation_flag_rejected(self) -> None:
        fields = valid_fields()
        fields["arb_conservation"] = 0
        with self.assertRaisesRegex(MODULE.EvidenceError, "arb_conservation"):
            MODULE.parse_marker_text(marker(fields))

    def test_full_log_receipt(self) -> None:
        receipt = MODULE.build_receipt(full_log(), "unit", 100, 50)
        self.assertEqual(receipt["status"], "WRITE_PATH_BUBBLE_QUALIFIED")
        self.assertEqual(receipt["region"]["retired"], 50)

    def test_full_log_wrong_roi_rejected(self) -> None:
        with self.assertRaisesRegex(MODULE.EvidenceError, "region cycles"):
            MODULE.build_receipt(full_log(), "unit", 101, 50)

    def test_cli_writes_canonical_json(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = pathlib.Path(directory)
            log = root / "input.log"
            output = root / "result.json"
            log.write_text(full_log() + "\n", encoding="utf-8")
            rc = MODULE.main([
                "parse", "--log", str(log), "--workload", "unit",
                "--expected-cycles", "100", "--expected-retired", "50",
                "--output", str(output),
            ])
            self.assertEqual(rc, 0)
            text = output.read_text(encoding="utf-8")
            self.assertTrue(text.endswith("\n"))
            self.assertIn('"schema": "npc-rv64-write-path-bubble-qualification-v1"',
                          text)


if __name__ == "__main__":
    unittest.main()
