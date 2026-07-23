#!/usr/bin/env python3
from __future__ import annotations

import importlib.util
import pathlib
import sys
import tempfile
import unittest


HERE = pathlib.Path(__file__).resolve().parent
ROOT = HERE.parents[2]
TOOL = HERE / "check-v8q-dual-mem-fabric.py"
RTL = ROOT / "npc/rv64/vsrc/memory/OooDualMemAxiArbiter.v"

SPEC = importlib.util.spec_from_file_location("v8q_checker", TOOL)
assert SPEC is not None and SPEC.loader is not None
checker = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = checker
SPEC.loader.exec_module(checker)


class CheckerFailClosedTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.source = RTL.read_text(encoding="utf-8")

    def assert_source_rejected(self, text: str, check_id: str) -> None:
        checks = {item.check_id: item for item in checker.structural_checks(text)}
        self.assertIn(check_id, checks)
        self.assertFalse(checks[check_id].passed)

    def test_current_source_passes_every_structural_check(self) -> None:
        checks = checker.structural_checks(self.source)
        self.assertTrue(checks)
        self.assertTrue(all(item.passed for item in checks), checks)

    def test_empty_source_fails(self) -> None:
        self.assert_source_rejected("", "source.one_nonempty_module")

    def test_comment_only_module_name_fails(self) -> None:
        self.assert_source_rejected(
            "// module OooDualMemAxiArbiter (\n", "source.one_nonempty_module"
        )

    def test_missing_state_fails(self) -> None:
        mutated = self.source.replace(
            "localparam [2:0] S_WRITE_RESP = 3'd4;",
            "localparam [2:0] S_WRITE_DONE = 3'd4;",
            1,
        )
        self.assert_source_rejected(mutated, "source.state.s_write_resp")

    def test_tied_off_seen_fails(self) -> None:
        mutated = self.source.replace(
            "wire aw_seen_next_w = aw_seen_q || aw_fire_w;",
            "wire aw_seen_next_w = 1'b0;",
            1,
        )
        self.assert_source_rejected(mutated, "source.aw_seen_aggregation")

    def test_duplicate_module_fails(self) -> None:
        duplicated = self.source + "\nmodule OooDualMemAxiArbiter (); endmodule\n"
        self.assert_source_rejected(duplicated, "source.one_nonempty_module")

    def test_comment_only_assertion_marker_fails(self) -> None:
        mutated = self.source.replace(
            "[ARB-IDLE-QUIET]", "[ARB-IDLE-MISSING]", 1
        ) + "\n// [ARB-IDLE-QUIET]\n"
        self.assert_source_rejected(mutated, "source.assertion_marker_set")

    def test_rr_update_on_capture_fails(self) -> None:
        mutated = self.source.replace(
            "owner_q <= capture_owner_w;\n            is_write_q <= capture_write_w;",
            "owner_q <= capture_owner_w;\n            is_write_q <= capture_write_w;\n"
            "            rr_q <= ~capture_owner_w;",
            1,
        )
        self.assert_source_rejected(
            mutated, "source.rr_only_reset_and_terminals"
        )

    def test_response_broadcast_fails_isolation_shape(self) -> None:
        mutated = self.source.replace(
            "lane1_axi_rvalid_o = d_axi_rvalid_i;",
            "lane1_axi_rvalid_o = d_axi_rvalid_i;\n"
            "            lane0_axi_rvalid_o = d_axi_rvalid_i;",
            1,
        )
        self.assert_source_rejected(mutated, "source.nonowner_exact_isolation")

    def test_canonical_instance_detection_ignores_comments(self) -> None:
        with tempfile.TemporaryDirectory() as temp:
            root = pathlib.Path(temp)
            target = root / "OooDualMemAxiArbiter.v"
            target.write_text(self.source, encoding="utf-8")
            (root / "CommentOnly.v").write_text(
                "// OooDualMemAxiArbiter u_fake ( .clk(clk) );\n",
                encoding="utf-8",
            )
            self.assertEqual(checker.canonical_instantiations(root, target), [])
            (root / "Live.v").write_text(
                "module Live; OooDualMemAxiArbiter u_live ( .clk(clk) ); endmodule\n",
                encoding="utf-8",
            )
            self.assertEqual(
                checker.canonical_instantiations(root, target), ["Live.v:u_live"]
            )

    def test_exact_f1_leaf_wrapper_instance_is_allowed(self) -> None:
        checks = {
            item.check_id: item
            for item in checker.claim_checks(
                "dual_axi_miss_fabric_leaf_verified DI-5 RED OOO-3 "
                "overall architecture PPA promotion",
                ["memory/OooDualMemBridgeWrapper.v:u_miss_arbiter"],
            )
        }
        self.assertTrue(checks["claim.no_canonical_core_integration"].passed)

    def test_core_instance_is_rejected(self) -> None:
        checks = {
            item.check_id: item
            for item in checker.claim_checks(
                "dual_axi_miss_fabric_leaf_verified DI-5 RED OOO-3 "
                "overall architecture PPA promotion",
                ["core/NpcCoreTop.v:u_miss_arbiter"],
            )
        }
        self.assertFalse(checks["claim.no_canonical_core_integration"].passed)


if __name__ == "__main__":
    unittest.main()
