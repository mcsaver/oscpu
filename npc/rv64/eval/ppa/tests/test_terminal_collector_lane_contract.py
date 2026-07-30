from __future__ import annotations

import importlib.util
import pathlib
import sys
import unittest


ROOT = pathlib.Path(__file__).resolve().parents[5]
TOOL_PATH = (
    ROOT
    / "npc/rv64/eval/ppa/tools/terminal_collector_lane_contract.py"
)
SPEC = importlib.util.spec_from_file_location(
    "terminal_collector_lane_contract", TOOL_PATH
)
assert SPEC and SPEC.loader
LANES = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = LANES
SPEC.loader.exec_module(LANES)

BACKEND = (ROOT / LANES.BACKEND).read_text(encoding="utf-8")
COLLECTOR = (ROOT / LANES.COLLECTOR).read_text(encoding="utf-8")


class TerminalCollectorLaneContractTests(unittest.TestCase):
    def test_current_lane_and_free_pair_contract_passes(self) -> None:
        result = LANES.audit_text(BACKEND, COLLECTOR)
        self.assertEqual(len(result["lanes"]), 12)
        self.assertEqual(len(result["tracker_free_lanes"]), 2)
        self.assertFalse(result["raw_ingress_is_transfer_authority"])
        self.assertFalse(result["duplicate_ingress_is_merged"])

    def test_lane_token_swap_is_rejected(self) -> None:
        mutant = BACKEND.replace(
            "      mem1_drop0_owner_token_i,\n"
            "      mem_drop1_owner_token_i,\n"
            "      mem_drop0_owner_token_i,",
            "      mem_drop0_owner_token_i,\n"
            "      mem_drop1_owner_token_i,\n"
            "      mem1_drop0_owner_token_i,",
            1,
        )
        self.assertNotEqual(mutant, BACKEND)
        with self.assertRaisesRegex(LANES.ContractError, "lane2 token"):
            LANES.audit_text(mutant, COLLECTOR)

    def test_accept_mask_lane_omission_is_rejected(self) -> None:
        mutant = BACKEND.replace(
            "{32{mem_terminal_ingress_accept_w[7]}} &",
            "{32{mem_terminal_ingress_accept_w[6]}} &",
            1,
        )
        self.assertNotEqual(mutant, BACKEND)
        with self.assertRaisesRegex(
            LANES.ContractError, "lane7 collector acceptance"
        ):
            LANES.audit_text(mutant, COLLECTOR)

    def test_raw_ingress_transfer_authority_is_rejected(self) -> None:
        mutant = BACKEND.replace(
            "mem_terminal_accept_mask_w | sq_owner_release_effective_mask_w",
            "mem_terminal_ingress_mask_w | sq_owner_release_effective_mask_w",
            1,
        )
        self.assertNotEqual(mutant, BACKEND)
        with self.assertRaisesRegex(
            LANES.ContractError, "collector acceptance"
        ):
            LANES.audit_text(mutant, COLLECTOR)

    def test_tracker_free_lane_swap_is_rejected(self) -> None:
        mutant = BACKEND.replace(
            ".free1_token_i(mem_terminal_deq1_token_w)",
            ".free1_token_i(mem_terminal_deq0_token_w)",
            1,
        )
        self.assertNotEqual(mutant, BACKEND)
        with self.assertRaisesRegex(LANES.ContractError, "free1 token"):
            LANES.audit_text(mutant, COLLECTOR)

    def test_raw_known_assertion_removal_is_rejected(self) -> None:
        mutant = COLLECTOR.replace(
            "[V11B-TCOLL-INGRESS-TUPLE-KNOWN]",
            "[V11B-TCOLL-INGRESS-TUPLE-REMOVED]",
            1,
        )
        with self.assertRaisesRegex(
            LANES.ContractError, "assertion label is missing"
        ):
            LANES.audit_text(BACKEND, mutant)


if __name__ == "__main__":
    unittest.main()
