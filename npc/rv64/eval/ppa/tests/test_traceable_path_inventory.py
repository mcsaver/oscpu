#!/usr/bin/env python3

from __future__ import annotations

import importlib.util
import pathlib
import tempfile
import unittest


ROOT = pathlib.Path(__file__).resolve().parents[5]
TOOL = ROOT / "npc/rv64/eval/ppa/tools/traceable_path_inventory.py"
SPEC = importlib.util.spec_from_file_location("traceable_path_inventory", TOOL)
assert SPEC is not None and SPEC.loader is not None
MODULE = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(MODULE)


def path_block(index: int, endpoint_suffix: str) -> str:
    return "\n".join(
        (
            f"Startpoint: u_core_source_{index}_DFFQX1H7L_D",
            "            (rising edge-triggered flip-flop clocked by core_clock)",
            f"Endpoint: u_core_sink_{index}_DFFQX1H7L_{endpoint_suffix}",
            "          (rising edge-triggered flip-flop clocked by core_clock)",
            "Path Group: core_clock",
            "Path Type: max",
            "",
        )
    )


class TraceablePathInventoryTests(unittest.TestCase):
    def setUp(self) -> None:
        runtime = ROOT / ".github/runtime-artifacts/tests"
        runtime.mkdir(parents=True, exist_ok=True)
        self.temporary = tempfile.TemporaryDirectory(
            prefix="traceable-path-inventory-", dir=runtime
        )
        self.work = pathlib.Path(self.temporary.name)

    def tearDown(self) -> None:
        self.temporary.cleanup()

    def write_report(self, text: str) -> pathlib.Path:
        path = self.work / "top40.rpt"
        path.write_text(text, encoding="utf-8")
        return path

    def test_public_d_q_and_ck_named_registers_are_accepted(self) -> None:
        suffixes = ("D", "Q", "Q_1", "CK")
        report = self.write_report(
            "".join(path_block(index, suffixes[index % len(suffixes)]) for index in range(40))
        )
        result = MODULE.inspect_report(report)
        self.assertEqual(result["status"], "PASS")
        self.assertEqual(result["public_flat_endpoints"], 40)
        self.assertEqual(result["clocked_register_descriptions"], 80)

    def test_opaque_endpoint_is_rejected(self) -> None:
        text = "".join(path_block(index, "Q") for index in range(40))
        text = text.replace(
            "Endpoint: u_core_sink_0_DFFQX1H7L_Q",
            "Endpoint: _12345_DFFQX1H7L_Q",
            1,
        )
        result = MODULE.inspect_report(self.write_report(text))
        self.assertEqual(result["status"], "FAIL")
        self.assertEqual(result["opaque_endpoints"], 1)
        self.assertEqual(result["public_flat_endpoints"], 39)

    def test_missing_clocked_register_description_is_rejected(self) -> None:
        text = "".join(path_block(index, "Q") for index in range(40))
        text = text.replace(
            "          (rising edge-triggered flip-flop clocked by core_clock)",
            "          (unconstrained endpoint)",
            1,
        )
        with self.assertRaisesRegex(MODULE.TraceabilityError, "lacks"):
            MODULE.inspect_report(self.write_report(text))

    def test_path_count_mismatch_is_rejected(self) -> None:
        result = MODULE.inspect_report(self.write_report(path_block(0, "D")))
        self.assertEqual(result["status"], "FAIL")
        self.assertIn("startpoints=1 expected=40", result["errors"])


if __name__ == "__main__":
    unittest.main()
