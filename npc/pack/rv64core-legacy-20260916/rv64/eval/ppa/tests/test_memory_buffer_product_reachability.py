#!/usr/bin/env python3

from __future__ import annotations

import copy
import importlib.util
import pathlib
import sys
import unittest


ROOT = pathlib.Path(__file__).resolve().parents[5]
TOOL = (
    ROOT
    / "npc/rv64/eval/ppa/tools/memory_buffer_product_reachability.py"
)
SPEC = importlib.util.spec_from_file_location(
    "memory_buffer_product_reachability", TOOL
)
assert SPEC is not None and SPEC.loader is not None
MODULE = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = MODULE
SPEC.loader.exec_module(MODULE)


class MemoryBufferProductReachabilityTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.sources = {
            relative: (ROOT / relative).read_text(encoding="utf-8")
            for relative in MODULE.SOURCE_PATHS
        }

    def mutate(self, path: str, old: str, new: str) -> dict[str, str]:
        sources = dict(self.sources)
        self.assertEqual(sources[path].count(old), 1)
        sources[path] = sources[path].replace(old, new, 1)
        return sources

    def test_current_source_contract_passes(self) -> None:
        result = MODULE.audit_source_contract(self.sources)
        self.assertEqual(result["legacy_valid_set_count"], 2)
        self.assertEqual(result["exact_token_capture_count"], 2)

    def test_rejects_product_parameter_disabled(self) -> None:
        sources = self.mutate(
            "npc/rv64/vsrc/core/NpcCoreTop.v",
            ".ENABLE_DUAL_MEM(1)",
            ".ENABLE_DUAL_MEM(0)",
        )
        with self.assertRaises(MODULE.ReachabilityError):
            MODULE.audit_source_contract(sources)

    def test_rejects_broken_parameter_pass_through(self) -> None:
        sources = self.mutate(
            "npc/rv64/vsrc/execute/OooExecuteBackend.v",
            ".ENABLE_DUAL_MEM(ENABLE_DUAL_MEM)",
            ".ENABLE_DUAL_MEM(0)",
        )
        with self.assertRaises(MODULE.ReachabilityError):
            MODULE.audit_source_contract(sources)

    def test_rejects_lane0_birth_gate_inversion(self) -> None:
        sources = self.mutate(
            "npc/rv64/vsrc/execute/OooIntBackend.v",
            "assign issue0_mem_buffer_fire_w =\n"
            "      !ENABLE_DUAL_MEM &&",
            "assign issue0_mem_buffer_fire_w =\n"
            "      ENABLE_DUAL_MEM &&",
        )
        with self.assertRaises(MODULE.ReachabilityError):
            MODULE.audit_source_contract(sources)

    def test_rejects_product_request_gate_inversion(self) -> None:
        sources = self.mutate(
            "npc/rv64/vsrc/execute/OooIntBackend.v",
            "wire mem_buffer_req_valid_w =\n"
            "      !ENABLE_DUAL_MEM &&",
            "wire mem_buffer_req_valid_w =\n"
            "      ENABLE_DUAL_MEM &&",
        )
        with self.assertRaises(MODULE.ReachabilityError):
            MODULE.audit_source_contract(sources)

    def test_rejects_extra_valid_set_path(self) -> None:
        sources = self.mutate(
            "npc/rv64/vsrc/execute/OooIntBackend.v",
            "mem_store_wstrb_q <= {`STRB_W{1'b0}};\n"
            "      mem_buffer_valid_q <= 1'b0;",
            "mem_store_wstrb_q <= {`STRB_W{1'b0}};\n"
            "      mem_buffer_valid_q <= 1'b1;",
        )
        with self.assertRaises(MODULE.ReachabilityError):
            MODULE.audit_source_contract(sources)

    def test_rejects_lane1_token_truncation(self) -> None:
        sources = self.mutate(
            "npc/rv64/vsrc/execute/OooIntBackend.v",
            "mem_buffer_owner_token_q <= mem_issue1_res_owner_token_q;",
            "mem_buffer_owner_token_q <= "
            "{3'b000, mem_issue1_res_owner_token_q[1:0]};",
        )
        with self.assertRaises(MODULE.ReachabilityError):
            MODULE.audit_source_contract(sources)

    def test_elaborated_contract_requires_all_constant_zero_nets(self) -> None:
        module_type = "$paramod\\OooIntBackend\\ENABLE_DUAL_MEM=1"
        graph = {
            "modules": {
                module_type: {
                    "netnames": {
                        name: {"bits": ["0"]}
                        for name in MODULE.PRODUCT_ZERO_NETS
                    }
                }
            }
        }
        payload = b'{"modules":{}}\n'
        receipt = {
            "design_id": "sha256:" + ("a" * 64),
            "full_yosys_json_sha256": MODULE.sha256_bytes(payload),
            "reachable_instances": [
                {
                    "path": MODULE.PRODUCT_INSTANCE,
                    "module": "OooIntBackend",
                    "elaborated_type": module_type,
                }
            ],
        }
        result = MODULE.audit_elaborated_contract(
            receipt, graph, payload
        )
        self.assertEqual(
            result["constant_zero_nets"]["issue0_mem_buffer_fire_w"],
            ["0"],
        )

        mutated = copy.deepcopy(graph)
        mutated["modules"][module_type]["netnames"][
            "issue1_mem_buffer_fire_w"
        ]["bits"] = [17]
        with self.assertRaises(MODULE.ReachabilityError):
            MODULE.audit_elaborated_contract(receipt, mutated, payload)


if __name__ == "__main__":
    unittest.main()
