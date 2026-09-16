#!/usr/bin/env python3
"""Negative/self-tests for the executable architecture gates."""

from __future__ import annotations

import importlib.util
import pathlib
import sys
import tempfile
import unittest


TOOL = pathlib.Path(__file__).resolve().parents[1] / "tools" / (
    "architecture_hard_gates.py")
SPEC = importlib.util.spec_from_file_location("architecture_hard_gates", TOOL)
assert SPEC is not None and SPEC.loader is not None
arch = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = arch
SPEC.loader.exec_module(arch)


def dual_sources() -> dict[str, str]:
    return {
        "scheduling/OooIntIssueQueue.v": "module IQ; endmodule\n",
        "execute/OooIntBackend.v": """
            wire issue0_mem_req_valid_w = issue0_valid_w;
            wire issue1_mem_req_valid_w =
                mem_issue1_res_valid_q && issue1_valid_w;
            wire [63:0] issue0_mem_paddr_w;
            wire [63:0] issue1_mem_paddr_w;
            wire mem_issue0_credit_w;
            wire mem_issue1_credit_w;
            LSU u_issue0_lsu();
            LSU u_issue1_lsu();
        """,
        "memory/OooMemAxiBridge.v": """
            module Bridge(
              input mem0_req_valid_i, output mem0_req_ready_o,
              input mem1_req_valid_i, output mem1_req_ready_o,
              output mem0_rsp_valid_o, input mem0_rsp_ready_i,
              output mem1_rsp_valid_o, input mem1_rsp_ready_i);
              wire req0_lookup_valid_w;
              wire req1_lookup_valid_w;
            endmodule
        """,
        "memory/OooMemInflightQueue.v":
            "module MIQ(input push0_valid_i, input push1_valid_i); endmodule\n",
        "memory/OooStoreQueue.v":
            "module SQ(output [127:0] snoop_paddr_o); endmodule\n",
        "cache/OooDataWordCache.v":
            "module DC(input req0_lookup_valid_i,"
            " input req1_lookup_valid_i); endmodule\n",
        "memory/OooLoadQueue.v":
            "module OooLoadQueue #(parameter ENTRY_N = 4)(); endmodule\n",
    }


def width_metrics() -> dict[str, object]:
    return {
        "trace_cycles": 64,
        "independent_alu_ipc": 1.90,
        "boundary_activity": {
            boundary: {
                "peak_uops_per_cycle": 2,
                "total_uops": 122,
            }
            for boundary in arch.WIDTH_BOUNDARIES
        },
    }


def pair_metrics() -> dict[str, object]:
    return {
        "pair_matrix": {name: True for name in arch.PAIR_MATRIX},
        "same_cycle_pair_fires": 15,
        "same_cycle_memory_pair_fires": 4,
        "distinct_nonzero_generation_memory_pids": 8,
        "dual_reservation_observations": 4,
        "distinct_owner_token_pairs": 4,
        "captured_agu_matches": 8,
        "store_store_exact_owner_binds": 2,
        "special_memory_exclusions": 10,
        "atomic_scarcity_zero_births": 1,
        "collector_ingress_peak": 12,
        "collector_exact_drains": 12,
        "raw_fallthrough_violations": 0,
        "bank1_age_bypass_violations": 0,
        "owner_ghosts_after_cancel": 0,
    }


def selective_sources() -> dict[str, str]:
    return {
        "scheduling/OooIntIssueQueue.v": """
            OooIntIssueSelect8 u_select(
              .universal_owner_present_i(universal_owner_present_i));
            assign issue1_valid_o = issue1_found_w &&
                                    !recover_active_i && !kill_valid_i;
        """,
        "scheduling/OooIntIssueSelect8.v": """
            wire [7:0] issue1_onehot_w = owner_memory_pair_peek_w ?
                pair_peek_onehot_w : universal_owner_present_i ?
                first_alu_onehot_w : partner_onehot_w;
            assign issue1_found_o = universal_owner_present_i ?
                (!owner_memory_pair_peek_w && first_alu_valid_w) :
                partner_valid_w;
        """,
        "rename_allocate/OooDispatchBackend.v": """
            OooIntIssueQueue u_iq(
              .universal_owner_present_i(universal_owner_present_i));
        """,
        "execute/OooIntBackend.v": """
            OooDispatchBackend u_dispatch(
              .universal_owner_present_i(mem_issue_res_valid_q ||
                                         mem_issue1_res_valid_q));
            assign iq_issue0_ready_w = mem_issue_res_valid_q ?
                1'b0 : resource_ready_w;
            assign issue1_ready_w = !flush_i && !checkpoint_restore_hold_w &&
                                    !issue_block_w;
            assign issue1_fire_w = issue1_valid_w && issue1_ready_w;
        """,
    }


class NegativeTests(unittest.TestCase):
    def test_required_gate_inventory_cannot_shrink(self) -> None:
        self.assertEqual(
            arch.GATE_IDS,
            (
                "DI-1", "DI-2", "DI-3", "DI-4", "DI-5",
                "OOO-1", "OOO-2", "OOO-3", "OOO-4",
            ),
        )
        self.assertEqual(set(arch.EVIDENCE_TEST), set(arch.GATE_IDS))
        self.assertEqual(
            arch.RESULT_SCHEMA,
            "npc-rv64-architecture-hard-gates-result-v2")
        self.assertEqual(
            arch.EVIDENCE_SCHEMA,
            "npc-rv64-architecture-directed-suite-v2")
        self.assertEqual(
            arch.SELECTIVE_EVIDENCE_COMMAND,
            "make -C npc/rv64 check-selective-scheduling")
        self.assertEqual(
            arch.FRONTEND_II1_EVIDENCE_COMMAND,
            "make -C npc/rv64 check-frontend-ii1")
        self.assertEqual(
            arch.WIDTH_CONTINUITY_EVIDENCE_COMMAND,
            "make -C npc/rv64 check-width-continuity")
        self.assertEqual(
            arch.LONG_LATENCY_EVIDENCE_COMMAND,
            "make -C npc/rv64 check-true-ooo-long-latency")
        self.assertEqual(
            arch.NO_STATIC_LANE_EVIDENCE_COMMAND,
            "make -C npc/rv64 check-no-static-lane-semantics")
        self.assertEqual(
            arch.PAIR_MATRIX_EVIDENCE_COMMAND,
            "make -C npc/rv64 check-pair-matrix")
        self.assertEqual(
            arch.DUAL_MEMORY_EVIDENCE_COMMAND,
            "make -C npc/rv64 check-dual-memory-sustained-issue")
        self.assertEqual(
            arch.MEMORY_ORDERING_EVIDENCE_COMMAND,
            "make -C npc/rv64 check-memory-ordering")
        self.assertEqual(
            arch.SPECULATION_RECOVERY_EVIDENCE_COMMAND,
            "make -C npc/rv64 check-speculation-recovery")
        self.assertEqual(len(arch.PAIR_MATRIX_PROVENANCE_PATHS), 17)
        self.assertEqual(len(arch.FRONTEND_II1_SOURCE_PATHS), 29)
        self.assertEqual(len(arch.FRONTEND_II1_PROVENANCE_PATHS), 56)
        self.assertEqual(len(arch.FRONTEND_II1_TASK_RUN_SOURCE_PATHS), 27)
        self.assertEqual(len(arch.FRONTEND_II1_TASK_RUN_PROOF_ROLES), 25)
        self.assertEqual(len(arch.WIDTH_CONTINUITY_SOURCE_PATHS), 43)
        self.assertEqual(len(arch.WIDTH_CONTINUITY_PROVENANCE_PATHS), 73)
        self.assertEqual(len(arch.WIDTH_CONTINUITY_TASK_RUN_SOURCE_PATHS), 41)
        self.assertEqual(len(arch.WIDTH_CONTINUITY_TASK_RUN_PROOF_ROLES), 28)
        self.assertEqual(len(arch.SELECTIVE_PROVENANCE_PATHS), 13)
        self.assertEqual(len(arch.LONG_LATENCY_PROVENANCE_PATHS), 13)
        self.assertEqual(len(arch.NO_STATIC_LANE_PROVENANCE_PATHS), 14)
        self.assertEqual(len(arch.DUAL_MEMORY_PROVENANCE_PATHS), 18)
        self.assertEqual(len(arch.MEMORY_ORDERING_SOURCE_PATHS), 48)
        self.assertEqual(len(arch.MEMORY_ORDERING_PROVENANCE_PATHS), 63)
        self.assertEqual(len(arch.SPECULATION_RECOVERY_SOURCE_PATHS), 27)
        self.assertEqual(len(arch.SPECULATION_RECOVERY_PROVENANCE_PATHS), 52)
        self.assertEqual(
            len(arch.SPECULATION_RECOVERY_TASK_RUN_PROOF_ROLES), 22)

    def test_comment_cannot_hide_or_invent_static_lane_role(self) -> None:
        sources = dual_sources()
        sources["scheduling/OooIntIssueQueue.v"] += (
            "// ctrl_is_lane1_simple_alu is only a comment\n")
        stripped = {
            name: arch.strip_comments(text) for name, text in sources.items()
        }
        self.assertTrue(all(item.passed for item in arch.di4_checks(stripped)))
        stripped["scheduling/OooIntIssueQueue.v"] += (
            "\nfunction ctrl_is_lane1_simple_alu; endfunction\n")
        checks = {item.check_id: item for item in arch.di4_checks(stripped)}
        self.assertFalse(
            checks["source.capability_predicate_has_entry_metadata"].passed)
        self.assertFalse(
            checks["source.capability_predicate_has_dynamic_steering"].passed)

    def test_capability_metadata_and_swap_make_asymmetry_legal(self) -> None:
        sources = dual_sources()
        sources["scheduling/OooIntIssueQueue.v"] += """
            function ctrl_is_lane1_simple_alu; endfunction
            reg [1:0] entry_fu_mask_q [0:7];
            wire issue_pair_swapped_w;
        """
        self.assertTrue(all(item.passed for item in arch.di4_checks(sources)))

    def test_actual_di4_chain_cannot_pass_vacuously_or_statically(self) -> None:
        root = arch.repo_root(TOOL)
        baseline = arch.live_sources(root)
        self.assertTrue(all(item.passed for item in arch.di4_checks(baseline)))
        mutations = {
            "predicate_definition_missing": (
                "scheduling/OooIntIssueQueue.v",
                "function ctrl_is_alu_terminal_capable;",
                "function ctrl_is_alu_terminal_capable_removed;",
                "source.capability_predicate_has_entry_metadata",
            ),
            "static_entry_capability": (
                "scheduling/OooIntIssueQueue.v",
                "assign select_alu_capable_w[select_g] =\n"
                "          alu_terminal_capable_q[select_g];",
                "assign select_alu_capable_w[select_g] = (select_g == 0);",
                "source.capability_predicate_has_entry_metadata",
            ),
            "slot0_capture_missing": (
                "scheduling/OooIntIssueQueue.v",
                "ctrl_is_alu_terminal_capable(dispatch0_ctrl_i)",
                "1'b1",
                "source.capability_predicate_has_entry_metadata",
            ),
            "slot1_capture_missing": (
                "scheduling/OooIntIssueQueue.v",
                "ctrl_is_alu_terminal_capable(dispatch1_ctrl_i)",
                "1'b1",
                "source.capability_predicate_has_entry_metadata",
            ),
            "resident_capability_missing": (
                "scheduling/OooIntIssueQueue.v",
                "alu_terminal_capable_q[compact_g],",
                "1'b0,",
                "source.capability_predicate_has_entry_metadata",
            ),
            "next_unpack_missing": (
                "scheduling/OooIntIssueQueue.v",
                "alu_terminal_capable_next_r[compact_i],",
                "fixed_gpr_producer_next_r[compact_i],",
                "source.capability_predicate_has_entry_metadata",
            ),
            "q_commit_missing": (
                "scheduling/OooIntIssueQueue.v",
                "alu_terminal_capable_q[reset_i] <=\n"
                "            alu_terminal_capable_next_r[reset_i];",
                "alu_terminal_capable_q[reset_i] <= 1'b0;",
                "source.capability_predicate_has_entry_metadata",
            ),
            "dynamic_swap_missing": (
                "scheduling/OooIntIssueSelect8.v",
                "assign issue_pair_swapped_o = swap_w;",
                "assign issue_pair_swapped_o = 1'b0;",
                "source.capability_predicate_has_dynamic_steering",
            ),
        }
        for name, (path, old, new, check_id) in mutations.items():
            with self.subTest(name=name):
                sources = dict(baseline)
                self.assertEqual(sources[path].count(old), 1)
                sources[path] = sources[path].replace(old, new, 1)
                checks = {
                    item.check_id: item for item in arch.di4_checks(sources)
                }
                self.assertFalse(checks[check_id].passed)

    def test_memory_tieoff_is_di3_di5_red_but_not_di4_red(self) -> None:
        sources = dual_sources()
        self.assertTrue(all(item.passed for item in arch.di5_checks(sources)))
        sources["execute/OooIntBackend.v"] = sources[
            "execute/OooIntBackend.v"].replace(
                "wire issue1_mem_req_valid_w =\n"
                "                mem_issue1_res_valid_q && issue1_valid_w;",
                "wire issue1_mem_req_valid_w = 1'b0;")
        self.assertTrue(all(item.passed for item in arch.di4_checks(sources)))
        checks = {item.check_id: item for item in arch.di5_checks(sources)}
        self.assertFalse(
            checks["source.two_live_memory_issue_terminals"].passed)
        di3 = {
            item.check_id: item for item in arch.source_checks(sources)["DI-3"]
        }
        self.assertFalse(di3["source.memory_pairs_two_terminals"].passed)

    def test_actual_di3_chain_rejects_each_structural_cut(self) -> None:
        root = arch.repo_root(TOOL)
        baseline = arch.live_sources(root)
        self.assertTrue(all(item.passed for item in arch.di3_checks(baseline)))
        mutations = {
            "plain_slot0_capture_missing": (
                "scheduling/OooIntIssueQueue.v",
                "ctrl_is_plain_memory_terminal_capable(dispatch0_ctrl_i)",
                "1'b0",
                "source.plain_memory_capability_resident",
            ),
            "plain_slot1_capture_missing": (
                "scheduling/OooIntIssueQueue.v",
                "ctrl_is_plain_memory_terminal_capable(dispatch1_ctrl_i)",
                "1'b0",
                "source.plain_memory_capability_resident",
            ),
            "plain_fp_exclusion_missing": (
                "scheduling/OooIntIssueQueue.v",
                "!dispatch0_is_fp_i && !dispatch0_fp_pdest_i &&",
                "!dispatch0_fp_pdest_i &&",
                "source.plain_memory_capability_resident",
            ),
            "plain_resident_capability_missing": (
                "scheduling/OooIntIssueQueue.v",
                "plain_memory_terminal_capable_q[compact_g],",
                "1'b0,",
                "source.plain_memory_capability_resident",
            ),
            "plain_next_unpack_missing": (
                "scheduling/OooIntIssueQueue.v",
                "plain_memory_terminal_capable_next_r[compact_i],",
                "fixed_gpr_producer_next_r[compact_i],",
                "source.plain_memory_capability_resident",
            ),
            "plain_q_commit_missing": (
                "scheduling/OooIntIssueQueue.v",
                "plain_memory_terminal_capable_q[reset_i] <=\n"
                "            plain_memory_terminal_capable_next_r[reset_i];",
                "plain_memory_terminal_capable_q[reset_i] <= 1'b0;",
                "source.plain_memory_capability_resident",
            ),
            "selector_serialized": (
                "scheduling/OooIntIssueSelect8.v",
                "wire memory_pair_w = !universal_owner_present_i &&",
                "wire memory_pair_w = 1'b0 &&",
                "source.memory_pair_selector_atomic",
            ),
            "atomic_tracker_cut": (
                "execute/OooIntBackend.v",
                ".alloc_pair_atomic_i(1'b1)",
                ".alloc_pair_atomic_i(1'b0)",
                "source.atomic_dual_owner_birth",
            ),
            "second_agu_renamed": (
                "execute/OooIntBackend.v",
                "LSU u_issue1_lsu (",
                "LSU u_issue1_lsu_hidden (",
                "source.two_captured_data_agus",
            ),
            "bank0_age_bypass": (
                "execute/OooIntBackend.v",
                "!live_grant_retry0_w && !live_grant_issue0_w &&\n"
                "      issue1_mem_req_valid_w &&",
                "!live_grant_retry0_w &&\n"
                "      issue1_mem_req_valid_w &&",
                "source.memory_bank_age_serialized",
            ),
            "bank1_age_bypass": (
                "execute/OooIntBackend.v",
                "issue1_dual_bank1_w && !live_grant_mem1_issue0_w;",
                "issue1_dual_bank1_w;",
                "source.memory_bank_age_serialized",
            ),
            "bank0_hold_origin_cut": (
                "execute/OooIntBackend.v",
                "mem_req_hold_sel_q <= live_mem_req_sel_w;",
                "mem_req_hold_sel_q <= 6'b100000;",
                "source.memory_bank_age_serialized",
            ),
            "bank1_hold_origin_cut": (
                "execute/OooIntBackend.v",
                "mem1_req_hold_sel_q <= live_mem1_req_sel_w;",
                "mem1_req_hold_sel_q <= 3'b100;",
                "source.memory_bank_age_serialized",
            ),
            "bind1_cut": (
                "execute/OooIntBackend.v",
                ".owner_bind1_valid_i(sq_owner_bind1_valid_w)",
                ".owner_bind1_valid_i(1'b0)",
                "source.dual_store_exact_owner_bind",
            ),
            "collector_width_cut": (
                "execute/OooIntBackend.v",
                ".INGRESS_N(12)",
                ".INGRESS_N(6)",
                "source.twelve_ingress_terminal_collector",
            ),
            "collector_lane_order_cut": (
                "execute/OooIntBackend.v",
                "      mem_retry1_tagged_terminal_w,\n"
                "      mem_retry0_tagged_terminal_w,",
                "      mem_retry0_tagged_terminal_w,\n"
                "      mem_retry1_tagged_terminal_w,",
                "source.twelve_ingress_terminal_collector",
            ),
            "full_pid_cut": (
                "execute/OooIntBackend.v",
                "mem_issue1_res_producer_id_q <= issue1_producer_id_w;",
                "mem_issue1_res_producer_id_q <= {PRODUCER_ID_W{1'b0}};",
                "source.full_pid_dual_owner",
            ),
            "special_memory_misadmission": (
                "scheduling/OooIntIssueQueue.v",
                "          !ctrl[`CTRL_AMO_BIT];",
                "          1'b1;",
                "source.plain_memory_capability_resident",
            ),
        }
        for name, (path, old, new, check_id) in mutations.items():
            with self.subTest(name=name):
                sources = dict(baseline)
                self.assertEqual(sources[path].count(old), 1)
                sources[path] = sources[path].replace(old, new, 1)
                checks = {
                    item.check_id: item for item in arch.di3_checks(sources)
                }
                self.assertFalse(checks[check_id].passed)
                self.assertFalse(
                    checks["source.memory_pairs_two_terminals"].passed)

    def test_frontend_missing_one_consecutive_packet_is_red(self) -> None:
        metrics = {
            "packets_observed": 64,
            "preheated_cycles": 64,
            "accepted_packets": 64,
            "produced_packets": 64,
            "max_initiation_interval": 1,
        }
        self.assertTrue(all(item.passed for item in arch.metric_checks(
            "frontend_ii1", metrics)))
        metrics["accepted_packets"] = 63
        failures = [item.check_id for item in arch.metric_checks(
            "frontend_ii1", metrics) if not item.passed]
        self.assertEqual(failures, ["metric.frontend.accept_every_cycle"])

    def test_frontend_task_run_proofs_are_role_hash_and_log_bound(self) -> None:
        original_source_paths = arch.FRONTEND_II1_TASK_RUN_SOURCE_PATHS
        try:
            with tempfile.TemporaryDirectory() as temporary:
                root = pathlib.Path(temporary)
                source = root / "source.txt"
                source.write_text("source\n", encoding="utf-8")
                arch.FRONTEND_II1_TASK_RUN_SOURCE_PATHS = ("source.txt",)

                proof_dir = root / ".github/task-runs/test/evidence/proofs"
                proof_dir.mkdir(parents=True)
                proof_files = {}
                log_lines = ["[ARCH-GATE] frontend_ii1 PASS"]
                for role in arch.FRONTEND_II1_TASK_RUN_PROOF_ROLES:
                    path = proof_dir / f"{role}.txt"
                    path.write_text(f"{role}\n", encoding="utf-8")
                    rel = path.relative_to(root).as_posix()
                    sha = arch.digest(path)
                    proof_files[role] = {"path": rel, "sha256": sha}
                    log_lines.append(f"artifact_sha256 {rel} {sha}")
                log = root / "frontend-ii1.log"
                log.write_text("\n".join(log_lines) + "\n", encoding="utf-8")
                files = {"source.txt": arch.digest(source)}
                proof_digest_map = {
                    role: f"{item['path']}:{item['sha256']}"
                    for role, item in proof_files.items()
                }
                record = {
                    "command": arch.FRONTEND_II1_EVIDENCE_COMMAND,
                    "log": {
                        "path": "frontend-ii1.log",
                        "sha256": arch.digest(log),
                    },
                    "metrics": {},
                    "provenance": {
                        "mode": "task-run-v1",
                        "files": files,
                        "proof_files": proof_files,
                        "proof_sha256": arch.canonical_digest(
                            proof_digest_map),
                        "sha256": arch.canonical_digest(files),
                    },
                    "status": "PASS",
                }
                evidence = {
                    "schema": arch.EVIDENCE_SCHEMA,
                    "design_id": "sha256:" + ("a" * 64),
                    "tests": {"frontend_ii1": record},
                }
                checks, _ = arch.evidence_checks(
                    root, evidence, "a" * 64, "frontend_ii1")
                self.assertTrue(all(item.passed for item in checks), checks)

                first_role = arch.FRONTEND_II1_TASK_RUN_PROOF_ROLES[0]
                first_path = root / proof_files[first_role]["path"]
                first_path.write_text("stale\n", encoding="utf-8")
                checks, _ = arch.evidence_checks(
                    root, evidence, "a" * 64, "frontend_ii1")
                by_id = {item.check_id: item for item in checks}
                self.assertFalse(by_id[
                    "evidence.frontend_ii1.proof_files"].passed)

                first_path.write_text(f"{first_role}\n", encoding="utf-8")
                proof_files.pop(first_role)
                checks, _ = arch.evidence_checks(
                    root, evidence, "a" * 64, "frontend_ii1")
                by_id = {item.check_id: item for item in checks}
                self.assertFalse(by_id[
                    "evidence.frontend_ii1.proof_inventory"].passed)
        finally:
            arch.FRONTEND_II1_TASK_RUN_SOURCE_PATHS = original_source_paths

    def test_width_task_run_proofs_are_role_hash_and_log_bound(self) -> None:
        original_source_paths = arch.WIDTH_CONTINUITY_TASK_RUN_SOURCE_PATHS
        try:
            with tempfile.TemporaryDirectory() as temporary:
                root = pathlib.Path(temporary)
                source = root / "source.txt"
                source.write_text("source\n", encoding="utf-8")
                arch.WIDTH_CONTINUITY_TASK_RUN_SOURCE_PATHS = ("source.txt",)

                proof_dir = root / ".github/task-runs/test/evidence/proofs"
                proof_dir.mkdir(parents=True)
                proof_files = {}
                log_lines = ["[ARCH-GATE] width_continuity PASS"]
                for role in arch.WIDTH_CONTINUITY_TASK_RUN_PROOF_ROLES:
                    path = proof_dir / f"{role}.txt"
                    path.write_text(f"{role}\n", encoding="utf-8")
                    rel = path.relative_to(root).as_posix()
                    sha = arch.digest(path)
                    proof_files[role] = {"path": rel, "sha256": sha}
                    log_lines.append(f"artifact_sha256 {rel} {sha}")
                log = root / "width-continuity.log"
                log.write_text("\n".join(log_lines) + "\n", encoding="utf-8")
                files = {"source.txt": arch.digest(source)}
                proof_digest_map = {
                    role: f"{item['path']}:{item['sha256']}"
                    for role, item in proof_files.items()
                }
                record = {
                    "command": arch.WIDTH_CONTINUITY_EVIDENCE_COMMAND,
                    "log": {
                        "path": "width-continuity.log",
                        "sha256": arch.digest(log),
                    },
                    "metrics": {},
                    "provenance": {
                        "mode": "task-run-v1",
                        "files": files,
                        "proof_files": proof_files,
                        "proof_sha256": arch.canonical_digest(
                            proof_digest_map),
                        "sha256": arch.canonical_digest(files),
                    },
                    "status": "PASS",
                }
                evidence = {
                    "schema": arch.EVIDENCE_SCHEMA,
                    "design_id": "sha256:" + ("b" * 64),
                    "tests": {"width_continuity": record},
                }
                checks, _ = arch.evidence_checks(
                    root, evidence, "b" * 64, "width_continuity")
                self.assertTrue(all(item.passed for item in checks), checks)

                first_role = arch.WIDTH_CONTINUITY_TASK_RUN_PROOF_ROLES[0]
                first_path = root / proof_files[first_role]["path"]
                first_path.write_text("stale\n", encoding="utf-8")
                checks, _ = arch.evidence_checks(
                    root, evidence, "b" * 64, "width_continuity")
                by_id = {item.check_id: item for item in checks}
                self.assertFalse(by_id[
                    "evidence.width_continuity.proof_files"].passed)
        finally:
            arch.WIDTH_CONTINUITY_TASK_RUN_SOURCE_PATHS = original_source_paths

    def test_width_one_at_any_boundary_is_red(self) -> None:
        metrics = width_metrics()
        self.assertTrue(all(item.passed for item in arch.metric_checks(
            "width_continuity", metrics)))
        activity = metrics["boundary_activity"]
        assert isinstance(activity, dict)
        execute = activity["execute"]
        assert isinstance(execute, dict)
        execute["peak_uops_per_cycle"] = 1
        failures = [item.check_id for item in arch.metric_checks(
            "width_continuity", metrics) if not item.passed]
        self.assertEqual(failures, ["metric.width.execute.peak"])

    def test_speculation_exactly_once_violation_is_red(self) -> None:
        metrics = {
            "multiple_controls_inflight": True,
            "oldest_mispredict_wins": True,
            "wrong_path_selective_squash": True,
            "fired_axi_drained": True,
            "exactly_once_complete_violations": 0,
            "exactly_once_retire_violations": 0,
            "ghost_after_recovery": 0,
        }
        self.assertTrue(all(item.passed for item in arch.metric_checks(
            "speculation_recovery", metrics)))
        metrics["exactly_once_complete_violations"] = 1
        failures = [item.check_id for item in arch.metric_checks(
            "speculation_recovery", metrics) if not item.passed]
        self.assertEqual(
            failures, ["metric.recovery.exactly_once_complete"])

    def test_store_authorization_and_precise_b_are_hard_gates(self) -> None:
        metrics = {
            "nonalias_load_bypass": True,
            "alias_forward_wait_replay": True,
            "physical_disambiguation": True,
            "stale_read_count": 0,
            "ghost_after_flush": 0,
            "store_side_effect_before_authorization": 0,
            "store_authorization_fire_violations": 0,
            "store_b_terminal_violations": 0,
            "store_retire_before_b_success": 0,
            "precise_b_error_trap": True,
            "fired_store_drain_exactly_once": True,
        }
        self.assertTrue(all(item.passed for item in arch.metric_checks(
            "memory_ordering", metrics)))

        expected = {
            "store_side_effect_before_authorization":
                "metric.order.store_pre_auth",
            "store_authorization_fire_violations":
                "metric.order.store_exactly_once_fire",
            "store_b_terminal_violations":
                "metric.order.store_b_terminal",
            "store_retire_before_b_success":
                "metric.order.store_retire_after_b",
            "precise_b_error_trap":
                "metric.order.store_precise_b_error",
            "fired_store_drain_exactly_once":
                "metric.order.store_drain_exactly_once",
        }
        for field, check_id in expected.items():
            broken = dict(metrics)
            broken[field] = False if isinstance(metrics[field], bool) else 1
            failures = [item.check_id for item in arch.metric_checks(
                "memory_ordering", broken) if not item.passed]
            self.assertEqual(failures, [check_id])

    def test_actual_ooo3_chain_rejects_each_critical_cut(self) -> None:
        root = arch.repo_root(TOOL)
        baseline = arch.live_sources(root)
        self.assertTrue(all(item.passed for item in arch.ooo3_checks(baseline)))
        mutations = {
            "depth": (
                "memory/OooLoadQueue.v",
                "parameter integer ENTRY_N = 16",
                "parameter integer ENTRY_N = 1",
                "source.load_queue_at_least_four",
            ),
            "dispatch_credit": (
                "execute/OooIntBackend.v",
                ".lq_alloc1_ready_i(lq_alloc1_ready_w)",
                ".lq_alloc1_ready_i(1'b1)",
                "source.lq_dispatch_allocation_credits",
            ),
            "issue_authority": (
                "execute/OooIntBackend.v",
                ".issue1_open_o(lq_issue1_open_w)",
                ".issue1_open_o()",
                "source.lq_issue_launch_authority",
            ),
            "launch_identity": (
                "execute/OooIntBackend.v",
                ".launch1_producer_id_i(lq_launch1_producer_id_w)",
                ".launch1_producer_id_i(lq_launch0_producer_id_w)",
                "source.lq_issue_launch_authority",
            ),
            "second_final_pa": (
                "execute/OooIntBackend.v",
                ".query1_valid_i(ENABLE_DUAL_MEM && "
                "mem1_sq_query_pre_lq_exact_w),\n"
                "    .query1_producer_id_i(mem1_sq_query_producer_id_w),\n"
                "    .query1_paddr_i(mem1_sq_query_paddr_i)",
                ".query1_valid_i(ENABLE_DUAL_MEM && "
                "mem1_sq_query_pre_lq_exact_w),\n"
                "    .query1_producer_id_i(mem1_sq_query_producer_id_w),\n"
                "    .query1_paddr_i(mem_sq_query_paddr_i)",
                "source.lq_dual_final_pa_disposition",
            ),
            "response_gate": (
                "execute/OooIntBackend.v",
                ".response1_open_o(lq_response1_open_w)",
                ".response1_open_o()",
                "source.lq_response_completion_terminal",
            ),
            "completion_identity": (
                "execute/OooIntBackend.v",
                ".completion1_valid_i(wb1_valid_w)",
                ".completion1_valid_i(wb0_valid_w)",
                "source.lq_response_completion_terminal",
            ),
            "terminal_identity": (
                "execute/OooIntBackend.v",
                ".terminal1_valid_i(lq_terminal1_valid_w)",
                ".terminal1_valid_i(lq_terminal0_valid_w)",
                "source.lq_response_completion_terminal",
            ),
            "checkpoint_recovery": (
                "execute/OooIntBackend.v",
                ".flush_valid_i(flush_i || checkpoint_restore_apply_w ||\n"
                "                   branch_resolve_mispredict_w),\n"
                "    .flush_all_i(flush_i || checkpoint_restore_apply_w)",
                ".flush_valid_i(flush_i || branch_resolve_mispredict_w),\n"
                "    .flush_all_i(flush_i)",
                "source.lq_checkpoint_recovery",
            ),
            "checkpoint_hold_dispatch": (
                "execute/OooIntBackend.v",
                "assign dispatch0_ready_o = dispatch0_dbe_ready_w && "
                "d0_fp_ok_w &&\n"
                "                             !checkpoint_restore_hold_w &&\n"
                "                             !control_full_flush_barrier_w;",
                "assign dispatch0_ready_o = dispatch0_dbe_ready_w && "
                "d0_fp_ok_w &&\n"
                "                             !checkpoint_restore_apply_w &&\n"
                "                             !control_full_flush_barrier_w;",
                "source.checkpoint_restore_hold_admission",
            ),
            "checkpoint_irrevocable_guard": (
                "execute/OooIntBackend.v",
                "assign checkpoint_restore_apply_w =\n"
                "      (checkpoint_restore_new_req_w || "
                "checkpoint_restore_pending_q) &&\n"
                "      !checkpoint_irrevocable_write_q && "
                "sq_no_active_write_w &&\n"
                "      !drain_inflight_q;",
                "assign checkpoint_restore_apply_w =\n"
                "      (checkpoint_restore_new_req_w || "
                "checkpoint_restore_pending_q) &&\n"
                "      sq_no_active_write_w &&\n"
                "      !drain_inflight_q;",
                "source.checkpoint_irrevocable_write_drain",
            ),
            "checkpoint_commit1": (
                "execute/OooIntBackend.v",
                ".commit1_block_i(commit1_block_i || "
                "!lq_retire1_permit_w ||\n"
                "                     checkpoint_restore_hold_w),",
                ".commit1_block_i(commit1_block_i || "
                "!lq_retire1_permit_w),",
                "source.checkpoint_irrevocable_write_drain",
            ),
            "checkpoint_dispatch_owner": (
                "execute/OooIntBackend.v",
                ".head0_identity_o(head0_identity_o),\n"
                "    .rst(rst),\n"
                "    .flush_i(flush_i || checkpoint_restore_apply_w),",
                ".head0_identity_o(head0_identity_o),\n"
                "    .rst(rst),\n"
                "    .flush_i(flush_i),",
                "source.checkpoint_owner_recovery_domain",
            ),
            "checkpoint_sq_owner": (
                "execute/OooIntBackend.v",
                ".flush_valid_i(sq_flush_valid_w),\n"
                "    .flush_all_i(flush_i || checkpoint_restore_apply_w)",
                ".flush_valid_i(sq_flush_valid_w),\n"
                "    .flush_all_i(flush_i)",
                "source.checkpoint_owner_recovery_domain",
            ),
            "checkpoint_miq1_owner": (
                "execute/OooIntBackend.v",
                ") u_mem1_inflight_queue (\n"
                "    .clk(clk),\n"
                "    .rst(rst),\n"
                "    .flush_i(flush_i || checkpoint_restore_apply_w),",
                ") u_mem1_inflight_queue (\n"
                "    .clk(clk),\n"
                "    .rst(rst),\n"
                "    .flush_i(flush_i),",
                "source.checkpoint_owner_recovery_domain",
            ),
            "checkpoint_apply_broadcast": (
                "control/OooControlPlane.v",
                ".checkpoint_restore_i(core_checkpoint_restore_apply_i),",
                ".checkpoint_restore_i(core_checkpoint_restore_w),",
                "source.checkpoint_restore_apply_broadcast",
            ),
            "checkpoint_raw_local_flush_bypass": (
                "control/OooCoreSliceControlGate.v",
                "assign core_local_flush_o =\n"
                "      flush_i || core_trap_flush_i || core_serial_flush_i;",
                "assign core_local_flush_o =\n"
                "      flush_i || core_trap_flush_i || core_serial_flush_i ||\n"
                "      branch_spec_restore_i;",
                "source.checkpoint_raw_restore_fail_closed",
            ),
            "retire_permit": (
                "execute/OooIntBackend.v",
                "                    lq_retire0_permit_w),",
                "                    1'b1),",
                "source.lq_retire_authority",
            ),
            "live_mask": (
                "execute/OooIntBackend.v",
                "      lq_producer_live_mask_w |",
                "      {(1 << PRODUCER_ID_W){1'b0}} |",
                "source.lq_full_pid_live_mask",
            ),
            "dual_query_conflict": (
                "memory/OooLoadQueue.v",
                "wire query_pair_same_pid_w = query0_valid_i && query1_valid_i &&\n"
                "      (query0_producer_id_i == query1_producer_id_i);",
                "wire query_pair_same_pid_w = 1'b0;",
                "source.lq_dual_query_same_pid_fail_closed",
            ),
        }
        for name, (path, old, new, check_id) in mutations.items():
            with self.subTest(name=name):
                sources = dict(baseline)
                self.assertEqual(sources[path].count(old), 1)
                sources[path] = sources[path].replace(old, new, 1)
                checks = {
                    item.check_id: item for item in arch.ooo3_checks(sources)
                }
                self.assertFalse(checks[check_id].passed)

    def test_ooo3_command_and_provenance_replay_fail_closed(self) -> None:
        original_paths = arch.MEMORY_ORDERING_PROVENANCE_PATHS
        try:
            with tempfile.TemporaryDirectory() as temporary:
                root = pathlib.Path(temporary)
                proof = root / "proof.txt"
                log = root / "memory-ordering.log"
                proof.write_text("proof\n", encoding="utf-8")
                log.write_text(
                    "[ARCH-GATE] memory_ordering PASS\n",
                    encoding="utf-8",
                )
                arch.MEMORY_ORDERING_PROVENANCE_PATHS = ("proof.txt",)
                files = {"proof.txt": arch.digest(proof)}
                record = {
                    "command": arch.MEMORY_ORDERING_EVIDENCE_COMMAND,
                    "log": {
                        "path": "memory-ordering.log",
                        "sha256": arch.digest(log),
                    },
                    "metrics": {},
                    "provenance": {
                        "files": files,
                        "sha256": arch.canonical_digest(files),
                    },
                    "status": "PASS",
                }
                evidence = {
                    "schema": arch.EVIDENCE_SCHEMA,
                    "design_id": "sha256:" + ("d" * 64),
                    "tests": {"memory_ordering": record},
                }
                checks, _ = arch.evidence_checks(
                    root, evidence, "d" * 64, "memory_ordering")
                self.assertTrue(all(item.passed for item in checks))

                record["command"] += " EXTRA=1"
                checks, _ = arch.evidence_checks(
                    root, evidence, "d" * 64, "memory_ordering")
                by_id = {item.check_id: item for item in checks}
                self.assertFalse(by_id["evidence.memory_ordering.command"].passed)
                record["command"] = arch.MEMORY_ORDERING_EVIDENCE_COMMAND

                proof.write_text("stale\n", encoding="utf-8")
                checks, _ = arch.evidence_checks(
                    root, evidence, "d" * 64, "memory_ordering")
                by_id = {item.check_id: item for item in checks}
                self.assertFalse(by_id[
                    "evidence.memory_ordering.provenance_files"].passed)

                proof.write_text("proof\n", encoding="utf-8")
                record["provenance"]["files"] = {}
                checks, _ = arch.evidence_checks(
                    root, evidence, "d" * 64, "memory_ordering")
                by_id = {item.check_id: item for item in checks}
                self.assertFalse(by_id[
                    "evidence.memory_ordering.provenance_inventory"].passed)
        finally:
            arch.MEMORY_ORDERING_PROVENANCE_PATHS = original_paths

    def test_ooo3_task_run_proofs_are_role_and_log_bound(self) -> None:
        original_source_paths = arch.MEMORY_ORDERING_SOURCE_PATHS
        try:
            with tempfile.TemporaryDirectory() as temporary:
                root = pathlib.Path(temporary)
                source = root / "source.txt"
                source.write_text("source\n", encoding="utf-8")
                arch.MEMORY_ORDERING_SOURCE_PATHS = ("source.txt",)

                proof_dir = root / ".github/task-runs/test/evidence/proofs"
                proof_dir.mkdir(parents=True)
                proof_files = {}
                log_lines = ["[ARCH-GATE] memory_ordering PASS"]
                for role in arch.MEMORY_ORDERING_TASK_RUN_PROOF_ROLES:
                    path = proof_dir / f"{role}.txt"
                    path.write_text(f"{role}\n", encoding="utf-8")
                    rel = path.relative_to(root).as_posix()
                    sha = arch.digest(path)
                    proof_files[role] = {"path": rel, "sha256": sha}
                    log_lines.append(f"artifact_sha256 {rel} {sha}")
                log = root / "memory-ordering.log"
                log.write_text("\n".join(log_lines) + "\n", encoding="utf-8")
                files = {"source.txt": arch.digest(source)}
                proof_digest_map = {
                    role: f"{item['path']}:{item['sha256']}"
                    for role, item in proof_files.items()
                }
                record = {
                    "command": arch.MEMORY_ORDERING_EVIDENCE_COMMAND,
                    "log": {
                        "path": "memory-ordering.log",
                        "sha256": arch.digest(log),
                    },
                    "metrics": {},
                    "provenance": {
                        "mode": "task-run-v1",
                        "files": files,
                        "proof_files": proof_files,
                        "proof_sha256": arch.canonical_digest(
                            proof_digest_map),
                        "sha256": arch.canonical_digest(files),
                    },
                    "status": "PASS",
                }
                evidence = {
                    "schema": arch.EVIDENCE_SCHEMA,
                    "design_id": "sha256:" + ("d" * 64),
                    "tests": {"memory_ordering": record},
                }
                checks, _ = arch.evidence_checks(
                    root, evidence, "d" * 64, "memory_ordering")
                self.assertTrue(all(item.passed for item in checks), checks)

                first_role = arch.MEMORY_ORDERING_TASK_RUN_PROOF_ROLES[0]
                first_path = root / proof_files[first_role]["path"]
                first_path.write_text("stale\n", encoding="utf-8")
                checks, _ = arch.evidence_checks(
                    root, evidence, "d" * 64, "memory_ordering")
                by_id = {item.check_id: item for item in checks}
                self.assertFalse(by_id[
                    "evidence.memory_ordering.proof_files"].passed)

                first_path.write_text(f"{first_role}\n", encoding="utf-8")
                proof_files.pop(first_role)
                checks, _ = arch.evidence_checks(
                    root, evidence, "d" * 64, "memory_ordering")
                by_id = {item.check_id: item for item in checks}
                self.assertFalse(by_id[
                    "evidence.memory_ordering.proof_inventory"].passed)
        finally:
            arch.MEMORY_ORDERING_SOURCE_PATHS = original_source_paths

    def test_ooo4_task_run_proofs_are_role_and_log_bound(self) -> None:
        original_source_paths = arch.SPECULATION_RECOVERY_SOURCE_PATHS
        try:
            with tempfile.TemporaryDirectory() as temporary:
                root = pathlib.Path(temporary)
                source = root / "source.txt"
                source.write_text("source\n", encoding="utf-8")
                arch.SPECULATION_RECOVERY_SOURCE_PATHS = ("source.txt",)

                proof_dir = root / ".github/task-runs/test/evidence/proofs"
                proof_dir.mkdir(parents=True)
                proof_files = {}
                log_lines = ["[ARCH-GATE] speculation_recovery PASS"]
                for role in arch.SPECULATION_RECOVERY_TASK_RUN_PROOF_ROLES:
                    path = proof_dir / f"{role}.txt"
                    path.write_text(f"{role}\n", encoding="utf-8")
                    rel = path.relative_to(root).as_posix()
                    sha = arch.digest(path)
                    proof_files[role] = {"path": rel, "sha256": sha}
                    log_lines.append(f"artifact_sha256 {rel} {sha}")
                log = root / "speculation-recovery.log"
                log.write_text("\n".join(log_lines) + "\n", encoding="utf-8")
                files = {"source.txt": arch.digest(source)}
                proof_digest_map = {
                    role: f"{item['path']}:{item['sha256']}"
                    for role, item in proof_files.items()
                }
                record = {
                    "command": arch.SPECULATION_RECOVERY_EVIDENCE_COMMAND,
                    "log": {
                        "path": "speculation-recovery.log",
                        "sha256": arch.digest(log),
                    },
                    "metrics": {},
                    "provenance": {
                        "mode": "task-run-v1",
                        "files": files,
                        "proof_files": proof_files,
                        "proof_sha256": arch.canonical_digest(
                            proof_digest_map),
                        "sha256": arch.canonical_digest(files),
                    },
                    "status": "PASS",
                }
                evidence = {
                    "schema": arch.EVIDENCE_SCHEMA,
                    "design_id": "sha256:" + ("d" * 64),
                    "tests": {"speculation_recovery": record},
                }
                checks, _ = arch.evidence_checks(
                    root, evidence, "d" * 64, "speculation_recovery")
                self.assertTrue(all(item.passed for item in checks), checks)

                first_role = arch.SPECULATION_RECOVERY_TASK_RUN_PROOF_ROLES[0]
                first_path = root / proof_files[first_role]["path"]
                first_path.write_text("stale\n", encoding="utf-8")
                checks, _ = arch.evidence_checks(
                    root, evidence, "d" * 64, "speculation_recovery")
                by_id = {item.check_id: item for item in checks}
                self.assertFalse(by_id[
                    "evidence.speculation_recovery.proof_files"].passed)

                first_path.write_text(f"{first_role}\n", encoding="utf-8")
                proof_files.pop(first_role)
                checks, _ = arch.evidence_checks(
                    root, evidence, "d" * 64, "speculation_recovery")
                by_id = {item.check_id: item for item in checks}
                self.assertFalse(by_id[
                    "evidence.speculation_recovery.proof_inventory"].passed)
        finally:
            arch.SPECULATION_RECOVERY_SOURCE_PATHS = original_source_paths

    def test_ooo3_source_manifest_rejects_stale_or_missing_rtl(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = pathlib.Path(temporary).resolve()
            rtl = root / "npc/rv64/vsrc/memory/OooLoadQueue.v"
            harness = root / "npc/rv64/testbench/tests/tb_ooo_load_queue.sv"
            manifest = root / "evidence/sources.pre.sha256"
            rtl.parent.mkdir(parents=True)
            harness.parent.mkdir(parents=True)
            manifest.parent.mkdir(parents=True)
            rtl.write_text("module OooLoadQueue; endmodule\n", encoding="utf-8")
            harness.write_text("module tb; endmodule\n", encoding="utf-8")
            expected = (
                "npc/rv64/vsrc/memory/OooLoadQueue.v",
                "npc/rv64/testbench/tests/tb_ooo_load_queue.sv",
            )

            def write_manifest(include_harness: bool = True) -> None:
                paths = [rtl] + ([harness] if include_harness else [])
                manifest.write_text(
                    "".join(f"{arch.digest(path)}  {path}\n" for path in paths),
                    encoding="utf-8",
                )

            write_manifest()
            entries = arch.validate_source_manifest(root, manifest, expected)
            self.assertEqual(set(entries), set(expected))

            rtl.write_text("module stale; endmodule\n", encoding="utf-8")
            with self.assertRaisesRegex(ValueError, "hash mismatch"):
                arch.validate_source_manifest(root, manifest, expected)

            rtl.write_text("module OooLoadQueue; endmodule\n", encoding="utf-8")
            write_manifest(include_harness=False)
            with self.assertRaisesRegex(ValueError, "inventory mismatch"):
                arch.validate_source_manifest(root, manifest, expected)

    def test_missing_second_translation_and_completion_are_red(self) -> None:
        sources = dual_sources()
        sources["memory/OooMemAxiBridge.v"] = sources[
            "memory/OooMemAxiBridge.v"].replace(
                "input mem1_req_valid_i,", "").replace(
                "output mem1_rsp_valid_o,", "")
        checks = {item.check_id: item for item in arch.di5_checks(sources)}
        self.assertFalse(checks["source.two_translation_admissions"].passed)
        self.assertFalse(checks["source.two_completions"].passed)

    def test_actual_di5_chain_rejects_each_second_face_cut(self) -> None:
        root = arch.repo_root(TOOL)
        baseline = arch.live_sources(root)
        self.assertTrue(all(item.passed for item in arch.di5_checks(baseline)))
        mutations = {
            "translation": (
                "memory/OooDualMemBridgeWrapper.v",
                ".mem0_req_valid_i(lane1_req_valid_i)",
                ".mem0_req_valid_i(1'b0)",
                "source.two_translation_admissions",
            ),
            "physical_query": (
                "execute/OooIntBackend.v",
                ".query1_valid_i(ENABLE_DUAL_MEM && mem1_sq_query_exact_w),\n"
                "    .query1_producer_id_i(mem1_sq_query_producer_id_w),\n"
                "    .query1_paddr_i(mem1_sq_query_paddr_i)",
                ".query1_valid_i(ENABLE_DUAL_MEM && mem1_sq_query_exact_w),\n"
                "    .query1_producer_id_i(mem1_sq_query_producer_id_w),\n"
                "    .query1_paddr_i(mem_sq_query_paddr_i)",
                "source.two_physical_lsq_queries",
            ),
            "cache": (
                "memory/OooMemAxiBridge.v",
                ") u_dcache (",
                ") u_dcache_removed (",
                "source.two_cache_admissions",
            ),
            "completion": (
                "memory/OooDualMemBridgeWrapper.v",
                ".mem0_rsp_valid_o(lane1_rsp_valid_w)",
                ".mem0_rsp_valid_o()",
                "source.two_completions",
            ),
            "credit": (
                "execute/OooIntBackend.v",
                ".push_valid_i(miq1_push_valid_w)",
                ".push_valid_i(miq_push_valid_w)",
                "source.two_memory_credits",
            ),
        }
        for name, (path, old, new, check_id) in mutations.items():
            with self.subTest(name=name):
                sources = dict(baseline)
                self.assertEqual(sources[path].count(old), 1)
                sources[path] = sources[path].replace(old, new, 1)
                checks = {
                    item.check_id: item for item in arch.di5_checks(sources)
                }
                self.assertFalse(checks[check_id].passed)

    def test_arbitrary_older_valid_and_reservation_freeze_are_red(self) -> None:
        sources = dual_sources()
        sources["scheduling/OooIntIssueQueue.v"] += (
            "always @(*) entry_mem_order_block_r = "
            "is_mem && older_valid_seen_r;\n")
        sources["execute/OooIntBackend.v"] += (
            "assign iq_issue0_ready_w = mem_issue_res_valid_q "
            "? 1'b0 : resource_ready_w;\n")
        checks = {item.check_id: item for item in arch.ooo2_checks(sources)}
        self.assertFalse(
            checks["source.no_arbitrary_older_valid_block"].passed)
        self.assertFalse(
            checks["source.no_single_reservation_global_freeze"].passed)

    def test_universal_local_stop_with_complete_alu_path_is_green(self) -> None:
        checks = arch.ooo2_checks(selective_sources())
        self.assertTrue(all(item.passed for item in checks))

    def test_each_universal_owner_path_cut_is_red(self) -> None:
        mutations = {
            "backend_binding": (
                "universal_owner_present_i(mem_issue_res_valid_q ||\n"
                "                                         mem_issue1_res_valid_q)",
                "universal_owner_present_i(1'b0)",
                "execute/OooIntBackend.v",
                "source.reservation_owner_backend_binding",
            ),
            "dispatch_forwarding": (
                "universal_owner_present_i(universal_owner_present_i)",
                "universal_owner_present_i(1'b0)",
                "rename_allocate/OooDispatchBackend.v",
                "source.reservation_owner_forwarding",
            ),
            "selector_steering": (
                "first_alu_onehot_w : partner_onehot_w",
                "8'b0 : partner_onehot_w",
                "scheduling/OooIntIssueSelect8.v",
                "source.reservation_owner_alu_steering",
            ),
            "iq_issue1_mask": (
                "!recover_active_i && !kill_valid_i",
                "!universal_owner_present_i && !recover_active_i && "
                "!kill_valid_i",
                "scheduling/OooIntIssueQueue.v",
                "source.reservation_owner_issue1_valid_independent",
            ),
            "backend_issue1_mask": (
                "!issue_block_w;",
                "!issue_block_w && !mem_issue_res_valid_q;",
                "execute/OooIntBackend.v",
                "source.reservation_owner_issue1_ready_independent",
            ),
        }
        for name, (old, new, path, check_id) in mutations.items():
            with self.subTest(name=name):
                sources = selective_sources()
                self.assertEqual(sources[path].count(old), 1)
                sources[path] = sources[path].replace(old, new, 1)
                checks = {
                    item.check_id: item for item in arch.ooo2_checks(sources)
                }
                self.assertFalse(checks[check_id].passed)
                self.assertFalse(
                    checks["source.no_single_reservation_global_freeze"].passed)

    def test_universal_owner_requires_exact_two_bank_or(self) -> None:
        for name, replacement in {
            "bank0_only": "mem_issue_res_valid_q",
            "bank1_only": "mem_issue1_res_valid_q",
            "and": "mem_issue_res_valid_q && mem_issue1_res_valid_q",
            "constant": "1'b1",
            "raw_ready": "mem_req_ready_i",
        }.items():
            with self.subTest(name=name):
                sources = selective_sources()
                old = (
                    "mem_issue_res_valid_q ||\n"
                    "                                         "
                    "mem_issue1_res_valid_q"
                )
                self.assertEqual(
                    sources["execute/OooIntBackend.v"].count(old), 1)
                sources["execute/OooIntBackend.v"] = sources[
                    "execute/OooIntBackend.v"].replace(old, replacement, 1)
                checks = {
                    item.check_id: item for item in arch.ooo2_checks(sources)
                }
                self.assertFalse(
                    checks["source.reservation_owner_backend_binding"].passed)
                self.assertFalse(
                    checks["source.no_single_reservation_global_freeze"].passed)

    def test_pair_matrix_cannot_omit_store_store(self) -> None:
        metrics = pair_metrics()
        self.assertTrue(all(item.passed for item in arch.metric_checks(
            "pair_matrix", metrics)))
        matrix = metrics["pair_matrix"]
        assert isinstance(matrix, dict)
        del matrix["store_store"]
        failures = [item.check_id for item in arch.metric_checks(
            "pair_matrix", metrics) if not item.passed]
        self.assertEqual(
            failures,
            ["metric.pair.store_store", "metric.pair.exact_key_set"])

    def test_pair_matrix_rejects_extra_key_and_borrowed_counts(self) -> None:
        metrics = pair_metrics()
        matrix = metrics["pair_matrix"]
        assert isinstance(matrix, dict)
        matrix["label_only_fake"] = True
        metrics["same_cycle_memory_pair_fires"] = 3
        failures = [item.check_id for item in arch.metric_checks(
            "pair_matrix", metrics) if not item.passed]
        self.assertEqual(failures, [
            "metric.pair.exact_key_set",
            "metric.pair.same_cycle_memory_pair_fires",
        ])

    def test_program_slot_permutation_cannot_omit_one_slot(self) -> None:
        metrics = {
            "program_slot_permutation": {
                kind: {"slot0": True, "slot1": True}
                for kind in ("branch", "jal", "jalr", "load", "store", "muldiv")
            },
            "static_lane_role_violations": 0,
            "same_cycle_pair_fires": 12,
            "exact_full_pid_matches": 24,
        }
        self.assertTrue(all(item.passed for item in arch.metric_checks(
            "no_static_lane_semantics", metrics)))
        metrics["program_slot_permutation"]["load"]["slot1"] = False
        failures = [item.check_id for item in arch.metric_checks(
            "no_static_lane_semantics", metrics) if not item.passed]
        self.assertEqual(failures, ["metric.perm.load.slot1"])

    def test_di4_quantitative_metrics_cannot_be_borrowed(self) -> None:
        metrics = {
            "program_slot_permutation": {
                kind: {"slot0": True, "slot1": True}
                for kind in ("branch", "jal", "jalr", "load", "store", "muldiv")
            },
            "static_lane_role_violations": 0,
            "same_cycle_pair_fires": 12,
            "exact_full_pid_matches": 24,
        }
        self.assertTrue(all(item.passed for item in arch.metric_checks(
            "no_static_lane_semantics", metrics)))
        for field, check_id in (
            ("same_cycle_pair_fires", "metric.perm.same_cycle_pair_fires"),
            ("exact_full_pid_matches", "metric.perm.exact_full_pid_matches"),
        ):
            broken = dict(metrics)
            broken[field] -= 1
            failures = [item.check_id for item in arch.metric_checks(
                "no_static_lane_semantics", broken) if not item.passed]
            self.assertEqual(failures, [check_id])

    def test_di4_command_and_provenance_replay_fail_closed(self) -> None:
        with tempfile.TemporaryDirectory() as temp:
            root = pathlib.Path(temp)
            files: dict[str, str] = {}
            for index, rel in enumerate(arch.NO_STATIC_LANE_PROVENANCE_PATHS):
                path = root / rel
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_text(f"proof artifact {index}\n", encoding="utf-8")
                files[rel] = arch.digest(path)
            log = root / "npc/rv64/eval/ppa/evidence/no-static-lane.log"
            log.parent.mkdir(parents=True, exist_ok=True)
            log.write_text(
                "[ARCH-GATE] no_static_lane_semantics PASS run_id=test\n",
                encoding="utf-8")
            record = {
                "status": "PASS",
                "command": arch.NO_STATIC_LANE_EVIDENCE_COMMAND,
                "log": {
                    "path": log.relative_to(root).as_posix(),
                    "sha256": arch.digest(log),
                },
                "provenance": {
                    "files": files,
                    "sha256": arch.canonical_digest(files),
                },
                "metrics": {},
            }
            evidence = {
                "schema": arch.EVIDENCE_SCHEMA,
                "design_id": f"sha256:{'a' * 64}",
                "tests": {"no_static_lane_semantics": record},
            }
            checks, _ = arch.evidence_checks(
                root, evidence, "a" * 64, "no_static_lane_semantics")
            self.assertTrue(all(item.passed for item in checks))

            record["command"] += " EXTRA=1"
            checks, _ = arch.evidence_checks(
                root, evidence, "a" * 64, "no_static_lane_semantics")
            failed = {item.check_id for item in checks if not item.passed}
            self.assertIn(
                "evidence.no_static_lane_semantics.command", failed)
            record["command"] = arch.NO_STATIC_LANE_EVIDENCE_COMMAND

            stale = root / arch.NO_STATIC_LANE_PROVENANCE_PATHS[-1]
            stale.write_text("stale replay\n", encoding="utf-8")
            checks, _ = arch.evidence_checks(
                root, evidence, "a" * 64, "no_static_lane_semantics")
            failed = {item.check_id for item in checks if not item.passed}
            self.assertIn(
                "evidence.no_static_lane_semantics.provenance_files", failed)

    def test_inactive_second_memory_face_is_red(self) -> None:
        metrics = {
            "trace_cycles": 64,
            "memory_issue_ipc": 1.90,
            "dual_issue_cycles": 58,
            "agu_accepts": [64, 58],
            "translation_accepts": [64, 58],
            "physical_lsq_queries": [64, 58],
            "cache_admissions": [64, 58],
            "completions": [64, 58],
        }
        self.assertTrue(all(item.passed for item in arch.metric_checks(
            "dual_memory_issue", metrics)))
        metrics["translation_accepts"] = [122, 0]
        failures = [item.check_id for item in arch.metric_checks(
            "dual_memory_issue", metrics) if not item.passed]
        self.assertEqual(
            failures, ["metric.dual.translation_accepts"])

    def test_di5_command_and_provenance_replay_fail_closed(self) -> None:
        original_paths = arch.DUAL_MEMORY_PROVENANCE_PATHS
        try:
            with tempfile.TemporaryDirectory() as temporary:
                root = pathlib.Path(temporary)
                proof = root / "proof.txt"
                log = root / "dual-memory.log"
                proof.write_text("proof\n", encoding="utf-8")
                log.write_text(
                    "[ARCH-GATE] dual_memory_issue PASS\n",
                    encoding="utf-8",
                )
                arch.DUAL_MEMORY_PROVENANCE_PATHS = ("proof.txt",)
                files = {"proof.txt": arch.digest(proof)}
                record = {
                    "command": arch.DUAL_MEMORY_EVIDENCE_COMMAND,
                    "log": {
                        "path": "dual-memory.log",
                        "sha256": arch.digest(log),
                    },
                    "metrics": {},
                    "provenance": {
                        "files": files,
                        "sha256": arch.canonical_digest(files),
                    },
                    "status": "PASS",
                }
                evidence = {
                    "schema": arch.EVIDENCE_SCHEMA,
                    "design_id": "sha256:" + ("f" * 64),
                    "tests": {"dual_memory_issue": record},
                }
                checks, _ = arch.evidence_checks(
                    root, evidence, "f" * 64, "dual_memory_issue")
                self.assertTrue(all(item.passed for item in checks))

                record["command"] += " EXTRA=1"
                checks, _ = arch.evidence_checks(
                    root, evidence, "f" * 64, "dual_memory_issue")
                by_id = {item.check_id: item for item in checks}
                self.assertFalse(by_id[
                    "evidence.dual_memory_issue.command"].passed)
                record["command"] = arch.DUAL_MEMORY_EVIDENCE_COMMAND

                proof.write_text("stale\n", encoding="utf-8")
                checks, _ = arch.evidence_checks(
                    root, evidence, "f" * 64, "dual_memory_issue")
                by_id = {item.check_id: item for item in checks}
                self.assertFalse(by_id[
                    "evidence.dual_memory_issue.provenance_files"].passed)
        finally:
            arch.DUAL_MEMORY_PROVENANCE_PATHS = original_paths

    def test_di5_task_run_proofs_are_role_and_log_bound(self) -> None:
        original_source_paths = arch.DUAL_MEMORY_SOURCE_PATHS
        try:
            with tempfile.TemporaryDirectory() as temporary:
                root = pathlib.Path(temporary)
                source = root / "source.txt"
                source.write_text("source\n", encoding="utf-8")
                arch.DUAL_MEMORY_SOURCE_PATHS = ("source.txt",)

                proof_dir = root / ".github/task-runs/test/evidence/proofs"
                proof_dir.mkdir(parents=True)
                proof_files = {}
                log_lines = ["[ARCH-GATE] dual_memory_issue PASS"]
                for role in arch.DUAL_MEMORY_TASK_RUN_PROOF_ROLES:
                    path = proof_dir / f"{role}.txt"
                    path.write_text(f"{role}\n", encoding="utf-8")
                    rel = path.relative_to(root).as_posix()
                    sha = arch.digest(path)
                    proof_files[role] = {"path": rel, "sha256": sha}
                    log_lines.append(f"artifact_sha256 {rel} {sha}")
                log = root / "dual-memory.log"
                log.write_text("\n".join(log_lines) + "\n", encoding="utf-8")
                files = {"source.txt": arch.digest(source)}
                proof_digest_map = {
                    role: f"{item['path']}:{item['sha256']}"
                    for role, item in proof_files.items()
                }
                record = {
                    "command": arch.DUAL_MEMORY_EVIDENCE_COMMAND,
                    "log": {
                        "path": "dual-memory.log",
                        "sha256": arch.digest(log),
                    },
                    "metrics": {},
                    "provenance": {
                        "mode": "task-run-v1",
                        "files": files,
                        "proof_files": proof_files,
                        "proof_sha256": arch.canonical_digest(
                            proof_digest_map),
                        "sha256": arch.canonical_digest(files),
                    },
                    "status": "PASS",
                }
                evidence = {
                    "schema": arch.EVIDENCE_SCHEMA,
                    "design_id": "sha256:" + ("e" * 64),
                    "tests": {"dual_memory_issue": record},
                }
                checks, _ = arch.evidence_checks(
                    root, evidence, "e" * 64, "dual_memory_issue")
                self.assertTrue(all(item.passed for item in checks), checks)

                first_role = arch.DUAL_MEMORY_TASK_RUN_PROOF_ROLES[0]
                first_path = root / proof_files[first_role]["path"]
                first_path.write_text("stale\n", encoding="utf-8")
                checks, _ = arch.evidence_checks(
                    root, evidence, "e" * 64, "dual_memory_issue")
                by_id = {item.check_id: item for item in checks}
                self.assertFalse(by_id[
                    "evidence.dual_memory_issue.proof_files"].passed)

                first_path.write_text(f"{first_role}\n", encoding="utf-8")
                proof_files.pop(first_role)
                checks, _ = arch.evidence_checks(
                    root, evidence, "e" * 64, "dual_memory_issue")
                by_id = {item.check_id: item for item in checks}
                self.assertFalse(by_id[
                    "evidence.dual_memory_issue.proof_inventory"].passed)
        finally:
            arch.DUAL_MEMORY_SOURCE_PATHS = original_source_paths

    def test_long_latency_requires_old_plus_eight_younger_in_rob(self) -> None:
        metrics = {
            "younger_completed_before_old": {
                "load_miss": 8,
                "mul": 8,
                "div": 8,
            },
            "younger_issue_accepted_under_owner": {
                "load_miss": 8,
                "mul": 8,
                "div": 8,
            },
            "dual_issue_cycles_under_owner": {
                "load_miss": 4,
                "mul": 4,
                "div": 4,
            },
            "owner_live_younger_completions": {
                "load_miss": 8,
                "mul": 8,
                "div": 8,
            },
            "rob_peak": 9,
            "rob_valid_entries_peak": 9,
            "retire_order_violations": 0,
        }
        self.assertTrue(all(item.passed for item in arch.metric_checks(
            "true_ooo_long_latency", metrics)))
        metrics["rob_peak"] = 8
        failures = [item.check_id for item in arch.metric_checks(
            "true_ooo_long_latency", metrics) if not item.passed]
        self.assertEqual(failures, ["metric.long.rob"])

    def test_long_latency_evidence_binds_exact_command_and_inventory(
            self) -> None:
        original_paths = arch.LONG_LATENCY_PROVENANCE_PATHS
        try:
            with tempfile.TemporaryDirectory() as temporary:
                root = pathlib.Path(temporary)
                proof = root / "proof.txt"
                log = root / "long.log"
                proof.write_text("proof\n", encoding="utf-8")
                log.write_text(
                    "[ARCH-GATE] true_ooo_long_latency PASS\n",
                    encoding="utf-8",
                )
                arch.LONG_LATENCY_PROVENANCE_PATHS = ("proof.txt",)
                files = {"proof.txt": arch.digest(proof)}
                record = {
                    "command": arch.LONG_LATENCY_EVIDENCE_COMMAND,
                    "log": {
                        "path": "long.log",
                        "sha256": arch.digest(log),
                    },
                    "metrics": {},
                    "provenance": {
                        "files": files,
                        "sha256": arch.canonical_digest(files),
                    },
                    "status": "PASS",
                }
                evidence = {
                    "schema": arch.EVIDENCE_SCHEMA,
                    "design_id": "sha256:" + ("e" * 64),
                    "tests": {"true_ooo_long_latency": record},
                }
                checks, _ = arch.evidence_checks(
                    root, evidence, "e" * 64, "true_ooo_long_latency")
                self.assertTrue(all(item.passed for item in checks))

                record["command"] = "make fake-long-proof"
                checks, _ = arch.evidence_checks(
                    root, evidence, "e" * 64, "true_ooo_long_latency")
                by_id = {item.check_id: item for item in checks}
                self.assertFalse(by_id[
                    "evidence.true_ooo_long_latency.command"].passed)
                record["command"] = arch.LONG_LATENCY_EVIDENCE_COMMAND

                proof.write_text("tampered\n", encoding="utf-8")
                checks, _ = arch.evidence_checks(
                    root, evidence, "e" * 64, "true_ooo_long_latency")
                by_id = {item.check_id: item for item in checks}
                self.assertFalse(by_id[
                    "evidence.true_ooo_long_latency.provenance_files"].passed)
        finally:
            arch.LONG_LATENCY_PROVENANCE_PATHS = original_paths

    def test_ooo1_task_run_proofs_are_role_and_log_bound(self) -> None:
        original_source_paths = arch.LONG_LATENCY_SOURCE_PATHS
        try:
            with tempfile.TemporaryDirectory() as temporary:
                root = pathlib.Path(temporary)
                source = root / "source.txt"
                source.write_text("source\n", encoding="utf-8")
                arch.LONG_LATENCY_SOURCE_PATHS = ("source.txt",)

                proof_dir = root / ".github/task-runs/test/evidence/proofs"
                proof_dir.mkdir(parents=True)
                proof_files = {}
                log_lines = [
                    "[ARCH-GATE] true_ooo_long_latency PASS",
                ]
                for role in arch.LONG_LATENCY_TASK_RUN_PROOF_ROLES:
                    path = proof_dir / f"{role}.txt"
                    path.write_text(f"{role}\n", encoding="utf-8")
                    rel = path.relative_to(root).as_posix()
                    sha = arch.digest(path)
                    proof_files[role] = {"path": rel, "sha256": sha}
                    log_lines.append(f"artifact_sha256 {rel} {sha}")
                log = root / "true-ooo-long-latency.log"
                log.write_text("\n".join(log_lines) + "\n", encoding="utf-8")
                files = {"source.txt": arch.digest(source)}
                proof_digest_map = {
                    role: f"{item['path']}:{item['sha256']}"
                    for role, item in proof_files.items()
                }
                record = {
                    "command": arch.LONG_LATENCY_EVIDENCE_COMMAND,
                    "log": {
                        "path": "true-ooo-long-latency.log",
                        "sha256": arch.digest(log),
                    },
                    "metrics": {},
                    "provenance": {
                        "mode": "task-run-v1",
                        "files": files,
                        "proof_files": proof_files,
                        "proof_sha256": arch.canonical_digest(
                            proof_digest_map),
                        "sha256": arch.canonical_digest(files),
                    },
                    "status": "PASS",
                }
                evidence = {
                    "schema": arch.EVIDENCE_SCHEMA,
                    "design_id": "sha256:" + ("d" * 64),
                    "tests": {"true_ooo_long_latency": record},
                }
                checks, _ = arch.evidence_checks(
                    root, evidence, "d" * 64, "true_ooo_long_latency")
                self.assertTrue(all(item.passed for item in checks), checks)

                first_role = arch.LONG_LATENCY_TASK_RUN_PROOF_ROLES[0]
                first_path = root / proof_files[first_role]["path"]
                first_path.write_text("stale\n", encoding="utf-8")
                checks, _ = arch.evidence_checks(
                    root, evidence, "d" * 64, "true_ooo_long_latency")
                by_id = {item.check_id: item for item in checks}
                self.assertFalse(by_id[
                    "evidence.true_ooo_long_latency.proof_files"].passed)

                first_path.write_text(f"{first_role}\n", encoding="utf-8")
                proof_files.pop(first_role)
                checks, _ = arch.evidence_checks(
                    root, evidence, "d" * 64, "true_ooo_long_latency")
                by_id = {item.check_id: item for item in checks}
                self.assertFalse(by_id[
                    "evidence.true_ooo_long_latency.proof_inventory"].passed)
        finally:
            arch.LONG_LATENCY_SOURCE_PATHS = original_source_paths

    def test_ooo1_negative_fatal_is_expected_but_pass_or_drift_is_rejected(
            self) -> None:
        tool_dir = TOOL.parent
        builder_path = tool_dir / "true_ooo_long_latency_evidence.py"
        module_name = "true_ooo_long_latency_evidence_test"
        sys.path.insert(0, tool_dir.as_posix())
        try:
            spec = importlib.util.spec_from_file_location(
                module_name, builder_path)
            assert spec is not None and spec.loader is not None
            builder = importlib.util.module_from_spec(spec)
            sys.modules[module_name] = builder
            spec.loader.exec_module(builder)
        finally:
            sys.path.remove(tool_dir.as_posix())

        with tempfile.TemporaryDirectory() as temporary:
            root = pathlib.Path(temporary)
            source = root / "npc/rv64/vsrc/execute/OooIntBackend.v"
            source.parent.mkdir(parents=True)
            source.write_text("module OooIntBackend; endmodule\n", encoding="utf-8")
            source_sha = builder.arch.digest(source)
            mutator_log = root / "mutator.log"
            mutator_log.write_text(
                "[V8N-MUTATION-HASH] name=serial_issue1 "
                f"source_sha256={source_sha} mutant_sha256={'1' * 64} "
                f"image_sha256={'2' * 64}\n",
                encoding="utf-8",
            )
            simulation_log = root / "simulation.log"
            simulation_text = (
                "[V8N-ACTIVATION] scenario=load_miss owner_pid=16\n"
                "[CHECK-FAIL] v8n load four dual-issue accept cycles\n"
                "FATAL: common/tb_common.svh:35\n"
                "[RESULT] FAIL status=1\n"
            )
            simulation_log.write_text(simulation_text, encoding="utf-8")

            builder.validate_mutation_proof(
                root, "serial_issue1", mutator_log, simulation_log)

            simulation_log.write_text(
                simulation_text.replace(
                    "[RESULT] FAIL status=1", "[RESULT] PASS"),
                encoding="utf-8",
            )
            with self.assertRaisesRegex(ValueError, "clean rejection"):
                builder.validate_mutation_proof(
                    root, "serial_issue1", mutator_log, simulation_log)

            simulation_log.write_text(simulation_text, encoding="utf-8")
            source.write_text("module changed; endmodule\n", encoding="utf-8")
            with self.assertRaisesRegex(ValueError, "source/hash binding"):
                builder.validate_mutation_proof(
                    root, "serial_issue1", mutator_log, simulation_log)

    def test_missing_evidence_is_red(self) -> None:
        checks, metrics = arch.evidence_checks(
            pathlib.Path.cwd(), {}, "0" * 64, "pair_matrix")
        self.assertEqual(metrics, {})
        self.assertTrue(checks)
        self.assertTrue(all(not item.passed for item in checks))

    def test_selective_evidence_binds_exact_proof_inventory(self) -> None:
        original_paths = arch.SELECTIVE_PROVENANCE_PATHS
        try:
            with tempfile.TemporaryDirectory() as temporary:
                root = pathlib.Path(temporary)
                proof = root / "proof.txt"
                log = root / "selective.log"
                proof.write_text("proof\n", encoding="utf-8")
                log.write_text(
                    "[ARCH-GATE] selective_scheduling PASS\n",
                    encoding="utf-8",
                )
                arch.SELECTIVE_PROVENANCE_PATHS = ("proof.txt",)
                files = {"proof.txt": arch.digest(proof)}
                evidence = {
                    "schema": arch.EVIDENCE_SCHEMA,
                    "design_id": "sha256:" + ("a" * 64),
                    "tests": {
                        "selective_scheduling": {
                            "command": arch.SELECTIVE_EVIDENCE_COMMAND,
                            "log": {
                                "path": "selective.log",
                                "sha256": arch.digest(log),
                            },
                            "metrics": {},
                            "provenance": {
                                "files": files,
                                "sha256": arch.canonical_digest(files),
                            },
                            "status": "PASS",
                        }
                    },
                }
                checks, _ = arch.evidence_checks(
                    root, evidence, "a" * 64, "selective_scheduling")
                self.assertTrue(all(item.passed for item in checks))

                proof.write_text("changed\n", encoding="utf-8")
                checks, _ = arch.evidence_checks(
                    root, evidence, "a" * 64, "selective_scheduling")
                by_id = {item.check_id: item for item in checks}
                self.assertFalse(by_id[
                    "evidence.selective_scheduling.provenance_files"].passed)
                self.assertFalse(by_id[
                    "evidence.selective_scheduling.provenance_digest"].passed)
        finally:
            arch.SELECTIVE_PROVENANCE_PATHS = original_paths


if __name__ == "__main__":
    unittest.main()
