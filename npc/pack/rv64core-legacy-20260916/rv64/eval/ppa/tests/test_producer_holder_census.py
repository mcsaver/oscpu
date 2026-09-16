#!/usr/bin/env python3
"""Mutation-oriented self-tests for producer_holder_census.py."""

from __future__ import annotations

import json
import shutil
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch
from pathlib import Path


TEST_DIR = Path(__file__).resolve().parent
RV64_DIR = TEST_DIR.parents[2]
REPO_ROOT = RV64_DIR.parents[1]
TOOLS_DIR = RV64_DIR / "eval/ppa/tools"
MANIFEST = RV64_DIR / "design/arch/producer-holder-census.json"
sys.path.insert(0, str(TOOLS_DIR))

import producer_holder_census as census  # noqa: E402


class ProducerHolderCensusTests(unittest.TestCase):
    def setUp(self) -> None:
        self.temp = tempfile.TemporaryDirectory(prefix="producer-census-")
        self.repo = Path(self.temp.name) / "repo"
        self.source = self.repo / "npc/rv64/vsrc"
        self.manifest = (
            self.repo / "npc/rv64/design/arch/producer-holder-census.json"
        )
        nemu_kconfig = self.repo / "nemu/Kconfig"
        nemu_kconfig.parent.mkdir(parents=True, exist_ok=True)
        nemu_kconfig.write_text("# census fixture\n", encoding="utf-8")
        self.source.parent.mkdir(parents=True, exist_ok=True)
        shutil.copytree(RV64_DIR / "vsrc", self.source)
        (self.repo / "npc/rv64/csrc").mkdir(parents=True, exist_ok=True)
        self.manifest.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(MANIFEST, self.manifest)
        for relative in (
            "Makefile",
            "npc/rv64/configs/product-rtl-defaults.mk",
            "npc/rv64/Makefile",
            "npc/rv64/scripts/config.mk",
        ):
            source = REPO_ROOT / relative
            target = self.repo / relative
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(source, target)
        self.manifest_value = json.loads(
            self.manifest.read_text(encoding="utf-8")
        )
        self.instance_graph_fixture = {
            "status": "PASS",
            "design_id": self.manifest_value["design_id"],
            "counts": {
                "holder_modules": 15,
                "holder_instances": 17,
                "duplicate_holder_modules": 2,
                "reachable_module_instances": 194,
            },
            "graph_sha256": "fixture-census-unit-graph",
            "errors": [],
        }

    def copy_instance_evidence(self) -> None:
        evidence_bundle = self.manifest_value[
            "elaborated_instance_graph"
        ]["evidence"]
        for entry in evidence_bundle.values():
            evidence_relative = entry["path"]
            evidence_source = REPO_ROOT / evidence_relative
            evidence_target = self.repo / evidence_relative
            evidence_target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(evidence_source, evidence_target)

    def tearDown(self) -> None:
        self.temp.cleanup()

    def audit(
        self, *, full_instance_graph: bool = False
    ) -> dict[str, object]:
        if full_instance_graph:
            self.copy_instance_evidence()
            return census.audit(self.repo, self.manifest, self.source)
        with patch.object(
            census.instance_graph,
            "audit_frozen",
            return_value=self.instance_graph_fixture,
        ):
            return census.audit(self.repo, self.manifest, self.source)

    def mutate_before_endmodule(self, relative: str, payload: str) -> None:
        path = self.source / relative
        text = path.read_text(encoding="utf-8")
        marker = text.rfind("endmodule")
        self.assertGreaterEqual(marker, 0)
        path.write_text(text[:marker] + payload + text[marker:], encoding="utf-8")

    def mutate_manifest(self, callback) -> None:
        data = json.loads(self.manifest.read_text(encoding="utf-8"))
        callback(data)
        self.manifest.write_text(
            json.dumps(data, ensure_ascii=False, indent=2) + "\n",
            encoding="utf-8",
        )

    def test_baseline_is_field_and_instance_complete_and_hash_bound(self) -> None:
        result = self.audit(full_instance_graph=True)
        self.assertEqual(result["status"], "PASS", result["errors"])
        self.assertEqual(
            result["counts"],
            {
                "direct_full_p_fields": 20,
                "combinational_full_p_regs": 1,
                "generation_authorities": 1,
                "token_q_fields": 17,
                "packed_full_p_stages": 5,
            },
        )
        self.assertEqual(len(result["hashes"]["manifest_sha256"]), 64)
        self.assertEqual(len(result["hashes"]["checker_sha256"]), 64)
        self.assertEqual(len(result["hashes"]["source_set_sha256"]), 64)
        self.assertEqual(result["instance_graph"]["status"], "PASS")
        self.assertEqual(
            result["instance_graph"]["counts"]["holder_instances"], 17
        )

    def test_integer_iq_packed_compaction_anchor_is_sensitive(self) -> None:
        path = self.source / "scheduling/OooIntIssueQueue.v"
        text = path.read_text(encoding="utf-8")
        anchor = "producer_id_q[compact_g],"
        self.assertEqual(text.count(anchor), 1)
        path.write_text(
            text.replace(anchor, "{PRODUCER_ID_W{1'b0}},", 1),
            encoding="utf-8",
        )

        result = self.audit()
        self.assertEqual(result["status"], "FAIL")
        self.assertIn(
            "combinational_full_p_regs[0] coverage anchor missing: "
            "integer-iq-next-producer",
            result["errors"],
        )

    def test_checker_loads_by_file_path_without_external_pythonpath(
        self,
    ) -> None:
        checker = TOOLS_DIR / "producer_holder_census.py"
        code = (
            "import importlib.util,sys;"
            f"p={str(checker)!r};"
            "s=importlib.util.spec_from_file_location('isolated_census',p);"
            "m=importlib.util.module_from_spec(s);"
            "sys.modules[s.name]=m;"
            "s.loader.exec_module(m);"
            "print(m.SCHEMA)"
        )
        completed = subprocess.run(
            [sys.executable, "-c", code],
            cwd=self.temp.name,
            env={"PATH": str(Path(sys.executable).parent)},
            check=False,
            capture_output=True,
            text=True,
        )
        self.assertEqual(
            completed.returncode,
            0,
            completed.stderr + completed.stdout,
        )
        self.assertEqual(
            completed.stdout.strip(),
            "rv64-producer-holder-census-v1",
        )

    def test_load_queue_is_a_retire_resident_direct_holder(self) -> None:
        data = json.loads(self.manifest.read_text(encoding="utf-8"))
        direct = {row["id"]: row for row in data["direct_full_p_fields"]}
        load_queue = direct["load-queue-producers"]
        self.assertEqual(load_queue["classification"], "DIRECT_HOLDER")
        self.assertEqual(load_queue["module"], "OooLoadQueue")
        self.assertEqual(load_queue["symbol"], "producer_id_q")
        self.assertIn("producer_live_mask_o", load_queue["coverage_anchor"])

    def test_retry_holders_are_explicit_tracker_bound_census_rows(self) -> None:
        data = json.loads(self.manifest.read_text(encoding="utf-8"))
        direct = {row["id"]: row for row in data["direct_full_p_fields"]}
        tokens = {row["id"]: row for row in data["token_q_fields"]}
        for bank in (0, 1):
            producer = direct[f"memory-retry{bank}-producer-cache"]
            token = tokens[f"memory-retry{bank}-token"]
            self.assertEqual(
                producer["classification"], "REDUNDANT_IDENTITY_CACHE"
            )
            self.assertIn(
                f"mem_retry{bank}_tracker_exact_w",
                producer["coverage_anchor"],
            )
            self.assertEqual(token["classification"], "INDIRECT_HOLDER")
            self.assertIn(
                f"mem_retry{bank}_owner_mask_w", token["coverage_anchor"]
            )

    def test_v9r_retry_c0_handoff_anchors_fail_closed(self) -> None:
        cases = (
            (
                "execute/OooIntBackend.v",
                "      !flush_i && !checkpoint_restore_hold_w &&\n"
                "      !control_full_flush_barrier_w;",
                "      !flush_i && !checkpoint_restore_hold_w;",
                "v9r-backend-retry0-c0-gate",
            ),
            (
                "execute/OooIntBackend.v",
                "      !flush_i && !checkpoint_restore_hold_w &&\n"
                "      !control_full_flush_barrier_w;",
                "      !flush_i && !checkpoint_restore_hold_w;",
                "v9r-backend-retry1-c0-gate",
            ),
            (
                "execute/OooIntBackend.v",
                "      if (control_full_flush_barrier_w &&\n"
                "          (mem_sq_query_retry_ready_o ||",
                "      if (1'b0 &&\n"
                "          (mem_sq_query_retry_ready_o ||",
                "v9r-backend-retry-c0-assert",
            ),
            (
                "memory/OooMemAxiBridge.v",
                "      mem0_sq_query_retry_ready_i && "
                "!control_full_flush_barrier_i;",
                "      mem0_sq_query_retry_ready_i;",
                "v9r-bridge-retry-fire-c0-gate",
            ),
            (
                "memory/OooMemAxiBridge.v",
                "      if (control_full_flush_barrier_i && "
                "sq_query_retry_fire_w) begin",
                "      if (1'b0 && sq_query_retry_fire_w) begin",
                "v9r-bridge-retry-fire-c0-assert",
            ),
        )
        occurrence = {
            "v9r-backend-retry0-c0-gate": 0,
            "v9r-backend-retry1-c0-gate": 1,
        }
        for relative, old, new, anchor_id in cases:
            with self.subTest(anchor=anchor_id):
                path = self.source / relative
                original = path.read_text(encoding="utf-8")
                if anchor_id in occurrence:
                    parts = original.split(old)
                    self.assertEqual(len(parts), 3)
                    index = occurrence[anchor_id]
                    mutated = old.join(parts[: index + 1]) + new + old.join(
                        parts[index + 1 :]
                    )
                else:
                    self.assertEqual(original.count(old), 1)
                    mutated = original.replace(old, new, 1)
                path.write_text(mutated, encoding="utf-8")
                result = self.audit()
                self.assertIn(
                    f"required anchor missing: {anchor_id}",
                    result["errors"],
                )
                path.write_text(original, encoding="utf-8")

    def test_irrevocable_write_lease_is_a_direct_birth_fence_holder(self) -> None:
        data = json.loads(self.manifest.read_text(encoding="utf-8"))
        direct = {row["id"]: row for row in data["direct_full_p_fields"]}
        lease = direct["checkpoint-irrevocable-write-producer"]
        self.assertEqual(lease["classification"], "DIRECT_HOLDER")
        self.assertEqual(
            lease["symbol"], "checkpoint_irrevocable_write_pid_q"
        )
        self.assertIn(
            "checkpoint_irrevocable_write_live_mask_w",
            lease["coverage_anchor"],
        )

    def test_cut_irrevocable_write_birth_fence_union_fails_closed(self) -> None:
        path = self.source / "execute/OooIntBackend.v"
        text = path.read_text(encoding="utf-8")
        old = (
            "      branch_producer_live_mask_w |\n"
            "      checkpoint_irrevocable_write_live_mask_w;"
        )
        self.assertEqual(text.count(old), 1)
        path.write_text(
            text.replace(old, "      branch_producer_live_mask_w;", 1),
            encoding="utf-8",
        )
        result = self.audit()
        self.assertEqual(result["status"], "FAIL")
        self.assertIn(
            "required anchor missing: intbackend-transient-union",
            result["errors"],
        )

    def test_assertion_only_shadows_are_not_production_holders(self) -> None:
        result = self.audit()
        discovered = {tuple(row) for row in result["discovered"]["direct_full_p_fields"]}
        self.assertNotIn(
            (
                "npc/rv64/vsrc/execute/OooIntBackend.v",
                "OooIntBackend",
                "v8l_mem_capture_producer_q",
            ),
            discovered,
        )
        self.assertNotIn(
            (
                "npc/rv64/vsrc/execute/OooMulDivUnit.v",
                "OooMulDivUnit",
                "md_req_producer_id_q",
            ),
            discovered,
        )

    def test_new_full_p_q_field_fails_closed(self) -> None:
        self.mutate_before_endmodule(
            "execute/OooClmulUnit.v",
            "\n  reg [PRODUCER_ID_W-1:0] surprise_producer_q;\n",
        )
        result = self.audit()
        self.assertEqual(result["status"], "FAIL")
        self.assertTrue(any("unclassified full-P Q field" in error
                            for error in result["errors"]))

    def test_new_full_p_non_q_reg_fails_closed(self) -> None:
        self.mutate_before_endmodule(
            "execute/OooClmulUnit.v",
            "\n  reg [PRODUCER_ID_W-1:0] surprise_owner_reg;\n",
        )
        result = self.audit()
        self.assertEqual(result["status"], "FAIL")
        self.assertTrue(any(
            "unclassified combinational full-P register exemption" in error
            for error in result["errors"]
        ))

    def test_new_packed_stage_fails_closed(self) -> None:
        self.mutate_before_endmodule(
            "execute/OooClmulUnit.v",
            """
  localparam V8L_SURPRISE_W = PRODUCER_ID_W + 1;
  wire v8l_surprise_ready_w;
  wire v8l_surprise_valid_w;
  wire [V8L_SURPRISE_W-1:0] v8l_surprise_payload_w;
  PipeStageReg #(.WIDTH(V8L_SURPRISE_W)) u_v8l_surprise_stage (
    .clk(clk), .rst(rst), .flush_i(1'b0), .kill_i(1'b0),
    .up_valid_i(1'b0), .up_ready_o(v8l_surprise_ready_w),
    .up_payload_i({V8L_SURPRISE_W{1'b0}}),
    .down_valid_o(v8l_surprise_valid_w), .down_ready_i(1'b1),
    .down_payload_o(v8l_surprise_payload_w));
""",
        )
        result = self.audit()
        self.assertEqual(result["status"], "FAIL")
        self.assertTrue(any("unclassified ProducerId-bearing PipeStageReg" in error
                            for error in result["errors"]))

    def test_new_owner_token_q_field_fails_closed(self) -> None:
        self.mutate_before_endmodule(
            "memory/OooMemInflightQueue.v",
            "\n  reg [OWNER_TOKEN_W-1:0] surprise_owner_token_q;\n",
        )
        result = self.audit()
        self.assertEqual(result["status"], "FAIL")
        self.assertTrue(any("unclassified owner-token Q field" in error
                            for error in result["errors"]))

    def test_cut_intiq_union_anchor_fails_closed(self) -> None:
        path = self.source / "rename_allocate/OooDispatchBackend.v"
        text = path.read_text(encoding="utf-8")
        old = "producer_live_mask_i | int_iq_producer_live_mask_w"
        self.assertIn(old, text)
        path.write_text(text.replace(old, "producer_live_mask_i", 1),
                        encoding="utf-8")
        result = self.audit()
        self.assertEqual(result["status"], "FAIL")
        self.assertIn("required anchor missing: dispatch-complete-union",
                      result["errors"])

    def test_raw_index_guard_is_rejected(self) -> None:
        path = self.source / "rename_allocate/OooDispatchBackend.v"
        text = path.read_text(encoding="utf-8")
        old = "complete_producer_live_mask_w[\n                                 rob_dispatch0_producer_id_w]"
        new = "complete_producer_live_mask_w[\n                                 rob_dispatch0_producer_id_w[ROB_INDEX_W-1:0]]"
        self.assertIn(old, text)
        path.write_text(text.replace(old, new, 1), encoding="utf-8")
        result = self.audit()
        self.assertEqual(result["status"], "FAIL")
        self.assertTrue(any("dispatch-lane0-raw-index-guard" in error
                            for error in result["errors"]))

    def test_manifest_cannot_self_promote_or_weaken_dynamic_contract(self) -> None:
        def mutate(data: dict[str, object]) -> None:
            data["status_ledger"]["global_no_live_reuse"] = "GREEN"
            data["dynamic_evidence_contract"][
                "compile_success_mutations_required"
            ] = False

        self.mutate_manifest(mutate)
        result = self.audit()
        self.assertEqual(result["status"], "FAIL")
        self.assertTrue(any("overclaim/drift" in error for error in result["errors"]))
        self.assertTrue(any("dynamic_evidence_contract" in error
                            for error in result["errors"]))


if __name__ == "__main__":
    unittest.main(verbosity=2)
