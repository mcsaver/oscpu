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
HISTORICAL_BACKEND = (
    ROOT
    / ".github/task-runs/2026-07-23-rv64-v9p-serialize-current-design/"
      "rtl-verification/v9p-replay-capacity-evidence/"
      "fence-open-mutation/OooIntBackend.v"
).read_text(encoding="utf-8")


class TerminalCollectorLaneContractTests(unittest.TestCase):
    def test_current_lane_and_free_pair_contract_passes(self) -> None:
        result = LANES.audit_text(BACKEND, COLLECTOR)
        self.assertEqual(len(result["lanes"]), 12)
        self.assertEqual(len(result["tracker_free_lanes"]), 2)
        self.assertFalse(result["raw_ingress_is_transfer_authority"])
        self.assertFalse(result["duplicate_ingress_is_merged"])
        matrix = result["source_pair_matrix"]
        self.assertEqual(len(matrix["pairs"]), 66)
        self.assertEqual(matrix["source_guarded_or_asserted_pairs"], 66)
        self.assertEqual(matrix["collector_only_pairs"], 0)
        self.assertEqual(matrix["collector_only_pair_ids"], [])
        self.assertEqual(matrix["precollector_pair_status"], "CLOSED")
        self.assertEqual(matrix["guard_counts"]["response-credit"], 21)
        self.assertEqual(
            matrix["guard_counts"]["amo-transient-holder-assertion"], 3
        )

    def test_historical_snapshot_keeps_unknown_pair_boundary(self) -> None:
        matrix = LANES.build_pair_matrix(HISTORICAL_BACKEND)
        self.assertEqual(len(matrix["pairs"]), 66)
        self.assertEqual(matrix["source_guarded_or_asserted_pairs"], 27)
        self.assertEqual(matrix["collector_only_pairs"], 39)
        self.assertFalse(
            matrix["source_guard_presence"]["bridge-holder-assertion"]
        )

    def test_source_pair_assertion_removal_is_rejected(self) -> None:
        mutant = BACKEND.replace(
            "[V9Q-TRANSIENT-BRIDGE-DISJOINT]",
            "[V9Q-TRANSIENT-BRIDGE-REMOVED]",
            1,
        )
        self.assertNotEqual(mutant, BACKEND)
        with self.assertRaisesRegex(
            LANES.ContractError, "transient-bridge-assertion"
        ):
            LANES.audit_text(mutant, COLLECTOR)

    def test_amo_transient_holder_assertion_removal_is_rejected(self) -> None:
        mutant = BACKEND.replace(
            "[V14U-AMO-TRANSIENT-HOLDER-DISJOINT]",
            "[V14U-AMO-TRANSIENT-HOLDER-REMOVED]",
            1,
        )
        self.assertNotEqual(mutant, BACKEND)
        with self.assertRaisesRegex(
            LANES.ContractError, "amo-transient-holder-assertion"
        ):
            LANES.audit_text(mutant, COLLECTOR)

    def test_amo_transient_holder_operand_omission_is_rejected(self) -> None:
        mutant = BACKEND.replace(
            "      (mem_issue_res_owner_mask_w | "
            "mem_issue1_res_owner_mask_w |\n"
            "       mem_buffer_owner_mask_w);",
            "      (mem_issue_res_owner_mask_w | "
            "mem_issue1_res_owner_mask_w);",
            1,
        )
        self.assertNotEqual(mutant, BACKEND)
        with self.assertRaisesRegex(
            LANES.ContractError, "amo-transient-holder-assertion"
        ):
            LANES.audit_text(mutant, COLLECTOR)

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

    def test_scalar_birth_inhibit_removal_is_rejected(self) -> None:
        mutant = BACKEND.replace(
            "      !v15r_mem_birth_any_w &&\n",
            "",
            1,
        )
        self.assertNotEqual(mutant, BACKEND)
        with self.assertRaisesRegex(
            LANES.ContractError, "reduced exact owner-terminal predicate"
        ):
            LANES.audit_text(mutant, COLLECTOR)

    def test_scalar_birth_lane_omission_is_rejected(self) -> None:
        mutant = BACKEND.replace(
            "mem_issue_res_capture_w || mem_issue1_res_capture_w",
            "mem_issue_res_capture_w || mem_issue_res_capture_w",
            1,
        )
        self.assertNotEqual(mutant, BACKEND)
        with self.assertRaisesRegex(
            LANES.ContractError, "scalar memory-birth predicate"
        ):
            LANES.audit_text(mutant, COLLECTOR)

    def test_indexed_birth_mask_in_active_holder_is_rejected(self) -> None:
        target = (
            "      mem_req_fire_owner_mask_w | mem1_req_fire_owner_mask_w;"
        )
        prefix, suffix = BACKEND.rsplit(target, 1)
        mutant = (
            prefix
            + "      v9y_mem_birth_token_mask_w |\n"
            + target
            + suffix
        )
        self.assertNotEqual(mutant, BACKEND)
        with self.assertRaisesRegex(
            LANES.ContractError, "birth mask must not feed active holder"
        ):
            LANES.audit_text(mutant, COLLECTOR)

    def test_indexed_birth_assignment_tail_is_rejected(self) -> None:
        mutant = BACKEND.replace(
            "      (v9y_pending_without_live_mask_w == 32'b0);",
            "      (v9y_pending_without_live_mask_w == 32'b0) &&\n"
            "      (v9y_mem_birth_token_mask_w == 32'b0);",
            1,
        )
        self.assertNotEqual(mutant, BACKEND)
        with self.assertRaisesRegex(
            LANES.ContractError,
            "indexed birth decode reaches production terminal cone",
        ):
            LANES.audit_text(mutant, COLLECTOR)

    def test_indexed_birth_alias_in_active_holder_is_rejected(self) -> None:
        target = "  wire [31:0] v9y_active_holder_mask_w ="
        mutant = BACKEND.replace(
            target,
            "  wire [31:0] v15r_birth_alias_w = "
            "v9y_mem_birth_token_mask_w;\n"
            + target
            + "\n      v15r_birth_alias_w |",
            1,
        )
        self.assertNotEqual(mutant, BACKEND)
        with self.assertRaisesRegex(
            LANES.ContractError,
            "indexed birth decode reaches production terminal cone",
        ):
            LANES.audit_text(mutant, COLLECTOR)

    def test_indexed_birth_in_intermediate_mask_is_rejected(self) -> None:
        mutant = BACKEND.replace(
            "  wire [31:0] v9y_unterminalized_holder_mask_w =\n"
            "      v9y_active_holder_mask_w & ~v9y_terminal_transfer_mask_w;",
            "  wire [31:0] v9y_unterminalized_holder_mask_w =\n"
            "      (v9y_active_holder_mask_w | v9y_mem_birth_token_mask_w) &\n"
            "      ~v9y_terminal_transfer_mask_w;",
            1,
        )
        self.assertNotEqual(mutant, BACKEND)
        with self.assertRaisesRegex(
            LANES.ContractError,
            "indexed birth decode reaches production terminal cone",
        ):
            LANES.audit_text(mutant, COLLECTOR)

    def test_renamed_indexed_birth_decode_is_rejected(self) -> None:
        target = "  wire [31:0] v9y_active_holder_mask_w ="
        mutant = BACKEND.replace(
            target,
            "  wire [31:0] v15r_birth_clone_w =\n"
            "      mem_issue_res_capture_w ?\n"
            "      (32'h1 << mem_owner_alloc0_token_w) : 32'b0;\n"
            + target
            + "\n      v15r_birth_clone_w |",
            1,
        )
        self.assertNotEqual(mutant, BACKEND)
        with self.assertRaisesRegex(
            LANES.ContractError,
            "indexed birth decode reaches production terminal cone",
        ):
            LANES.audit_text(mutant, COLLECTOR)

    def test_indexed_birth_always_reg_alias_is_rejected(self) -> None:
        target = "  wire [31:0] v9y_active_holder_mask_w ="
        mutant = BACKEND.replace(
            target,
            "  reg [31:0] v15r_birth_reg_alias_r;\n"
            "  always @(*) begin\n"
            "    v15r_birth_reg_alias_r = v9y_mem_birth_token_mask_w;\n"
            "  end\n"
            + target
            + "\n      v15r_birth_reg_alias_r |",
            1,
        )
        self.assertNotEqual(mutant, BACKEND)
        with self.assertRaisesRegex(
            LANES.ContractError,
            "indexed birth decode reaches production terminal cone",
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
