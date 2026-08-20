from __future__ import annotations

import json
import copy
import tempfile
import unittest
from pathlib import Path

from npc.rv64.eval.ppa.tools import architecture_registry as registry
from npc.rv64.eval.ppa.tools import traceable_mapped_sta as mapped_sta


class ArchitectureRegistryTests(unittest.TestCase):
    def setUp(self) -> None:
        self.catalog = registry.load_json(registry.CATALOG_PATH)

    def test_catalog_contract_and_single_entry_are_explicit(self) -> None:
        self.assertEqual([], registry.validate_catalog(self.catalog))
        self.assertEqual(
            "npc/rv64/ARCHITECTURE.md",
            self.catalog["single_entry"],
        )
        self.assertEqual({"bpu", "fp"}, set(self.catalog["capabilities"]))
        self.assertEqual(
            registry.EXPECTED_LIVE_DESIGN_ID,
            self.catalog["run_parameter_contract"]["expected_rtl_design_id"],
        )
        self.assertEqual(
            registry.EXPECTED_BPU_PHYSICAL_EXPERIMENT_STATE,
            self.catalog["bpu_physical_experiment_state"],
        )
        paths = sorted(
            path.relative_to(registry.REPO_ROOT).as_posix()
            for path in (registry.REPO_ROOT / "npc/rv64/vsrc").rglob("*")
            if path.is_file() and path.suffix.lower() in registry.SOURCE_SUFFIXES
        )
        self.assertEqual(
            registry.canonical_sha256(paths),
            self.catalog["scope"]["inventory_review"]["path_set_sha256"],
        )

    def test_rendered_single_entry_has_no_trailing_whitespace(self) -> None:
        snapshot = registry.build_snapshot(self.catalog)
        self.assertEqual([], snapshot["errors"])
        rendered = registry.render_markdown(snapshot, self.catalog)
        trailing = [
            line_number
            for line_number, line in enumerate(rendered.splitlines(), 1)
            if line.endswith((" ", "\t"))
        ]
        self.assertEqual([], trailing)

    def test_owner_and_role_resolution_do_not_use_filename_count_routing(self) -> None:
        errors: list[str] = []
        self.assertEqual(
            "rv64-bpu",
            registry.owner_for(
                "npc/rv64/vsrc/frontend/OooBranchDirectionPredictor.v",
                self.catalog,
                errors,
            ),
        )
        self.assertEqual(
            "rv64-bpu",
            registry.owner_for(
                "npc/rv64/vsrc/frontend/OooBranchLocalPht.v",
                self.catalog,
                errors,
            ),
        )
        self.assertEqual(
            "rv64-fp",
            registry.owner_for(
                "npc/rv64/vsrc/execute/OooFpArithGate.v",
                self.catalog,
                errors,
            ),
        )
        for child in (
            "OooFpAddSubPipe.v",
            "OooFpMulProductPipe.v",
            "OooFpMulNormRoundPipe.v",
            "OooFpFmaAlignAddPipe.v",
            "OooFpFmaNormRoundPipe.v",
        ):
            self.assertEqual(
                "rv64-fp",
                registry.owner_for(
                    f"npc/rv64/vsrc/execute/{child}", self.catalog, errors
                ),
            )
        lists = {
            "core": {"npc/rv64/vsrc/memory/OooMmuEpochOwner.v"},
            "header": set(),
            "sim": set(),
        }
        self.assertEqual(
            "catalog_only",
            registry.role_for(
                "npc/rv64/vsrc/memory/OooMmuEpochOwner.v",
                lists,
                self.catalog,
            ),
        )
        self.assertEqual(
            "unclassified",
            registry.role_for(
                "npc/rv64/vsrc/debug/NewUnreviewedChecker.sv",
                lists,
                self.catalog,
            ),
        )
        self.assertEqual([], errors)

    def test_non_product_and_development_sources_require_explicit_intent(self) -> None:
        lists = {
            "core": {"npc/rv64/vsrc/control/NewProduct.v"},
            "header": set(),
            "sim": {"npc/rv64/vsrc/sim/NewModel.sv"},
        }
        development_errors = registry.file_registration_errors(
            "npc/rv64/vsrc/control/NewProduct.v",
            role="product",
            lifecycle="development",
            lists=lists,
            catalog=self.catalog,
        )
        self.assertTrue(
            any("explicit role acknowledgement" in error for error in development_errors),
            development_errors,
        )
        self.assertEqual(
            "unclassified",
            registry.role_for(
                "npc/rv64/vsrc/sim/NewModel.sv",
                lists,
                self.catalog,
            ),
        )
        self.assertEqual(
            "unclassified",
            registry.role_for(
                "npc/rv64/vsrc/debug/NewChecker.sv",
                lists,
                self.catalog,
            ),
        )
        missing_intent = copy.deepcopy(self.catalog)
        del missing_intent["file_overrides"][
            "npc/rv64/vsrc/sim/AxiDpiSlave.sv"
        ]["intent"]
        errors = registry.validate_catalog(missing_intent)
        self.assertTrue(any("lacks explicit" in error for error in errors), errors)
        missing_scope = copy.deepcopy(self.catalog)
        del missing_scope["file_overrides"][
            "npc/rv64/vsrc/debug/OooRedirectMuxChecker.sv"
        ]["configuration_scope"]
        errors = registry.validate_catalog(missing_scope)
        self.assertTrue(any("lacks explicit" in error for error in errors), errors)

    def test_inventory_acknowledgement_mutation_fails_closed(self) -> None:
        paths = sorted(
            path.relative_to(registry.REPO_ROOT).as_posix()
            for path in (registry.REPO_ROOT / "npc/rv64/vsrc").rglob("*")
            if path.is_file() and path.suffix.lower() in registry.SOURCE_SUFFIXES
        )
        catalog = copy.deepcopy(self.catalog)
        catalog["scope"]["inventory_review"]["path_set_sha256"] = "0" * 64
        errors = registry.inventory_review_errors(catalog, paths)
        self.assertTrue(any("without architecture review" in error for error in errors))

    def test_catalog_only_must_remain_compiled(self) -> None:
        path = "npc/rv64/vsrc/memory/OooMmuEpochOwner.v"
        errors = registry.file_registration_errors(
            path,
            role="catalog_only",
            lifecycle="committed",
            lists={"core": set(), "header": set(), "sim": set()},
            catalog=self.catalog,
        )
        self.assertTrue(any("absent from compiled catalog" in error for error in errors))
        status, reachability_errors = registry.file_reachability_status(
            path,
            role="catalog_only",
            modules=["OooMmuEpochOwner"],
            reachable_modules={"OooMmuEpochOwner"},
            elaboration_status="PASS",
        )
        self.assertEqual("FAIL_UNEXPECTED", status)
        self.assertTrue(
            any("catalog_only source became reachable" in error for error in reachability_errors)
        )

    def test_catalog_forbids_manual_mapped_design_identity(self) -> None:
        catalog = copy.deepcopy(self.catalog)
        catalog["evidence"]["mapped_design_id"] = "sha256:" + "0" * 64
        errors = registry.validate_catalog(catalog)
        self.assertTrue(any("manual mapped_design_id" in error for error in errors), errors)

    def test_placeholder_blackbox_cannot_claim_physical_closure(self) -> None:
        catalog = copy.deepcopy(self.catalog)
        boundary = catalog["physical_boundaries"]["OooFpArithGate"]
        boundary["closure_state"] = "PASS"
        errors = registry.validate_catalog(catalog)
        self.assertTrue(
            any("cannot close" in error for error in errors),
            errors,
        )

    def test_elaboration_walk_keeps_instance_identity(self) -> None:
        graph = {
            "modules": {
                "NpcTop": {
                    "cells": {
                        "u_core": {"type": "Core"},
                    }
                },
                "Core": {
                    "cells": {
                        "u_bpu": {"type": "OooBranchDirectionPredictor"},
                    }
                },
                "OooBranchDirectionPredictor": {"cells": {}},
            }
        }
        rows = registry.reachable_instances(graph, "NpcTop")
        self.assertEqual(
            [
                ("NpcTop", "NpcTop"),
                ("Core", "NpcTop.u_core"),
                (
                    "OooBranchDirectionPredictor",
                    "NpcTop.u_core.u_bpu",
                ),
            ],
            [(row["module"], row["path"]) for row in rows],
        )

    def test_dynamic_evidence_is_bound_to_live_design(self) -> None:
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            (root / "evidence").mkdir()
            result = root / "evidence/result.json"
            result.write_text(
                json.dumps(
                    {
                        "status": "PASS",
                        "design_id": "sha256:live",
                        "tests": {
                            "inventory": ["tb_ooo_fp_arith_gate"],
                        },
                    }
                ),
                encoding="utf-8",
            )
            capability = {
                "dynamic_evidence": [
                    {
                        "kind": "module_test",
                        "module": "OooFpArithGate",
                        "result": "evidence/result.json",
                    }
                ]
            }
            current = registry.dynamic_capability(
                capability,
                root=root,
                live_design_id="sha256:live",
            )
            stale = registry.dynamic_capability(
                capability,
                root=root,
                live_design_id="sha256:other",
            )
            self.assertEqual("OBSERVED_CLASS_INTERNAL_EDGE_GAP", current["status"])
            self.assertEqual("GAP", stale["status"])

    def test_fp_module_observation_uses_current_input_bound_receipt_only(self) -> None:
        result_relative = (
            ".github/task-runs/2026-08-09-rv64-bpu-inline-ppa-d3f3-a1/"
            "evidence/fp-arith-functional-evidence-closure-v1/module-result.json"
        )
        fp_evidence = self.catalog["capabilities"]["fp"]["dynamic_evidence"]
        self.assertEqual(result_relative, fp_evidence[0]["result"])
        self.assertEqual(result_relative, self.catalog["evidence"]["module_result"])

        result_path = registry.REPO_ROOT / result_relative
        result = registry.load_json(result_path)
        self.assertEqual("PASS", result["status"])
        self.assertEqual(registry.EXPECTED_LIVE_DESIGN_ID, result["design_id"])
        self.assertEqual(
            ["tb_ooo_fp_arith_gate"], result["tests"]["inventory"]
        )
        self.assertEqual(
            registry.sha256_file(
                registry.REPO_ROOT / result["focused"]["raw_log"]["path"]
            ),
            result["focused"]["raw_log"]["sha256"],
        )
        self.assertEqual(
            registry.sha256_file(
                registry.REPO_ROOT / result["mutations"]["evidence_path"]
            ),
            result["mutations"]["evidence_sha256"],
        )
        self.assertEqual(
            registry.sha256_file(
                registry.REPO_ROOT / result["functional_input_manifest"]["path"]
            ),
            result["functional_input_manifest"]["sha256"],
        )

        dynamic = registry.dynamic_capability(
            self.catalog["capabilities"]["fp"],
            root=registry.REPO_ROOT,
            live_design_id=registry.EXPECTED_LIVE_DESIGN_ID,
        )
        self.assertEqual("GAP", dynamic["status"])
        self.assertEqual("PASS", dynamic["observations"][0]["status"])
        self.assertEqual("GAP", dynamic["observations"][1]["status"])

        snapshot = registry.build_snapshot(self.catalog)
        self.assertEqual([], snapshot["errors"])
        files = {row["path"]: row for row in snapshot["files"]}
        self.assertEqual(
            "FOCUSED_PASS",
            files["npc/rv64/vsrc/execute/OooFpArithGate.v"]["dynamic"],
        )
        other_product_dynamic = {
            row["dynamic"]
            for row in snapshot["files"]
            if row["role"] == "product"
            and row["path"] != "npc/rv64/vsrc/execute/OooFpArithGate.v"
        }
        self.assertEqual({"SYSTEM_BOUND_NO_NODE_COUNTER"}, other_product_dynamic)

        configuration = self.catalog["physical_configurations"][
            registry.FP_ARITH_PRODUCTION_CHILDREN_INLINE_CONFIGURATION
        ]
        self.assertEqual("development", configuration["source_lifecycle"])
        self.assertEqual("UNMEASURED", configuration["measurement_status"])
        self.assertEqual("GAP", configuration["physical_status"])
        self.assertFalse(configuration["canonical"])
        self.assertFalse(configuration["champion"])

    def test_mapped_runner_consumes_registry_projection(self) -> None:
        runner = (
            registry.REPO_ROOT
            / "npc/rv64/eval/ppa/run-traceable-mapped-current.sh"
        ).read_text(encoding="utf-8")
        sta_tcl = (
            registry.REPO_ROOT
            / "npc/rv64/eval/ppa/opensta-traceable-mapped-current.tcl"
        ).read_text(encoding="utf-8")
        sta_parser = (
            registry.REPO_ROOT
            / "npc/rv64/eval/ppa/tools/traceable_mapped_sta.py"
        ).read_text(encoding="utf-8")
        self.assertIn("emit mapped-blackbox-modules", runner)
        self.assertIn("emit mapped-artifact-profile", runner)
        self.assertIn("emit inline-modules", runner)
        self.assertIn("emit macro-lib-files", runner)
        self.assertIn("emit run-parameters", runner)
        self.assertIn("stamp-mapped-summary", runner)
        parent = registry.mapped_projection(
            self.catalog, registry.FOUR_PLACEHOLDER_CONFIGURATION
        )
        child = registry.mapped_projection(
            self.catalog, registry.BPU_INLINE_CONFIGURATION
        )
        banked = registry.mapped_projection(
            self.catalog,
            registry.BPU_LOCAL_PHT_BANKED_CHILD_INLINE_CONFIGURATION,
        )
        flat_read = registry.mapped_projection(
            self.catalog,
            registry.BPU_LOCAL_PHT_WRITE_BANKED_FLAT_READ_VIEW_INLINE_CONFIGURATION,
        )
        fp_arith = registry.mapped_projection(
            self.catalog,
            registry.FP_ARITH_PRODUCTION_CHILDREN_INLINE_CONFIGURATION,
        )
        self.assertEqual(
            [
                "Sram4096x199",
                "Sram4096x113",
                "OooFpArithGate",
                "OooBranchDirectionPredictor",
            ],
            parent["blackbox_modules"],
        )
        self.assertEqual([], parent["inline_modules"])
        self.assertEqual("none", parent["mapped_artifact_profile"])
        self.assertEqual(
            ["Sram4096x199", "Sram4096x113", "OooFpArithGate"],
            child["blackbox_modules"],
        )
        self.assertEqual(
            ["OooBranchDirectionPredictor"], child["inline_modules"]
        )
        self.assertEqual("none", child["mapped_artifact_profile"])
        self.assertEqual(
            registry.FOUR_PLACEHOLDER_CONFIGURATION,
            child["comparison_parent"],
        )
        self.assertNotIn(
            "OooBranchDirectionPredictor.lib",
            " ".join(row["path"] for row in child["macro_lib_files"]),
        )
        self.assertEqual(
            ["Sram4096x199", "Sram4096x113", "OooFpArithGate"],
            banked["blackbox_modules"],
        )
        self.assertEqual(
            registry.EXPECTED_BANKED_CHILD_INLINE_MODULES,
            banked["inline_modules"],
        )
        self.assertEqual(
            registry.MAPPED_ARTIFACT_PROFILE_BPU_LOCAL_PHT,
            banked["mapped_artifact_profile"],
        )
        self.assertEqual([], parent["keep_hierarchy_additions"])
        self.assertEqual([], child["keep_hierarchy_additions"])
        self.assertEqual(
            registry.EXPECTED_BANKED_CHILD_KEEP_HIERARCHY_ADDITIONS,
            banked["keep_hierarchy_additions"],
        )
        self.assertEqual(
            self.catalog["run_parameter_contract"]["keep_hierarchy_modules"]
            + registry.EXPECTED_BANKED_CHILD_KEEP_HIERARCHY_ADDITIONS,
            banked["keep_hierarchy_modules"],
        )
        self.assertEqual(
            registry.BPU_INLINE_CONFIGURATION,
            banked["comparison_parent"],
        )
        self.assertEqual("engineering_proxy_archive", banked["archive_class"])
        self.assertFalse(banked["canonical"])
        self.assertFalse(banked["champion"])
        self.assertEqual(
            registry.BPU_LOCAL_PHT_BANKED_CHILD_INLINE_CONFIGURATION,
            flat_read["comparison_parent"],
        )
        self.assertEqual(
            registry.EXPECTED_BANKED_CHILD_INLINE_MODULES,
            flat_read["inline_modules"],
        )
        self.assertEqual(
            registry.MAPPED_ARTIFACT_PROFILE_BPU_LOCAL_PHT,
            flat_read["mapped_artifact_profile"],
        )
        self.assertEqual(
            registry.EXPECTED_BANKED_CHILD_KEEP_HIERARCHY_ADDITIONS,
            flat_read["keep_hierarchy_additions"],
        )
        self.assertEqual(
            "engineering_proxy_negative_result_archive",
            flat_read["archive_class"],
        )
        self.assertFalse(flat_read["canonical"])
        self.assertFalse(flat_read["champion"])
        self.assertEqual(
            ["Sram4096x199", "Sram4096x113", "OooBranchDirectionPredictor"],
            fp_arith["blackbox_modules"],
        )
        self.assertEqual(
            registry.EXPECTED_FP_ARITH_INLINE_MODULES,
            fp_arith["inline_modules"],
        )
        self.assertEqual(
            registry.MAPPED_ARTIFACT_PROFILE_FP_ARITH_CHILDREN,
            fp_arith["mapped_artifact_profile"],
        )
        self.assertEqual(
            registry.EXPECTED_FP_ARITH_KEEP_HIERARCHY_ADDITIONS,
            fp_arith["keep_hierarchy_additions"],
        )
        self.assertEqual("development", fp_arith["source_lifecycle"])
        self.assertEqual("UNMEASURED", fp_arith["measurement_status"])
        self.assertEqual("GAP", fp_arith["physical_status"])
        self.assertFalse(fp_arith["canonical"])
        self.assertFalse(fp_arith["champion"])
        self.assertNotIn(
            "OooFpArithGate.lib",
            " ".join(row["path"] for row in fp_arith["macro_lib_files"]),
        )
        self.assertEqual([], registry.mapped_runner_contract_errors(runner))
        self.assertEqual(
            [], registry.mapped_sta_tool_contract_errors(sta_tcl, sta_parser)
        )
        for marker in (
            "write_bpu_negative_slack_inventory $bpu_negative_slack_path",
            "write_bpu_update_fanout_inventory $bpu_update_fanout_path",
            "opensta-bpu-negative-slack.tsv",
            "opensta-bpu-update-fanout.tsv",
        ):
            self.assertIn(marker, sta_tcl)
        self.assertLess(
            sta_tcl.index(
                "write_bpu_negative_slack_inventory $bpu_negative_slack_path"
            ),
            sta_tcl.index("write_note $complete_path"),
        )
        for marker in (
            '"bpu_negative_slack_inventory": parse_bpu_negative_slack_inventory(',
            '"bpu_update_fanout_inventory": parse_bpu_update_fanout_inventory(',
            '"bpu_negative_slack": out_dir / BPU_NEGATIVE_SLACK_FILENAME',
            '"bpu_update_fanout": out_dir / BPU_UPDATE_FANOUT_FILENAME',
        ):
            self.assertIn(marker, sta_parser)
        for marker in (
            'bpu_negative_slack_artifact="${evidence_dir}/opensta-bpu-negative-slack.tsv"',
            'bpu_update_fanout_artifact="${evidence_dir}/opensta-bpu-update-fanout.tsv"',
            '-s "${bpu_negative_slack_artifact}"',
            '-s "${bpu_update_fanout_artifact}"',
            '"${sta_tcl}" "${trace_checker}" "${architecture_registry}" "${runner_path}"',
        ):
            self.assertIn(marker, runner)
        for marker in (
            "--physical-configuration)",
            "--expected-rtl-design-id)",
            "emit expected-rtl-design-id",
            "emit live-rtl-design-id",
            "emit mapped-artifact-profile",
            "emit inline-modules",
            "emit keep-hierarchy-modules",
            "emit run-parameters",
            "binding_rc=1",
            '"${binding_rc}" -eq 0',
            '--physical-configuration "${physical_configuration}"',
            '--expected-rtl-design-id "${expected_rtl_design_id}"',
            '--parameters "${parameters}"',
            '--sta-input-manifest "${input_manifest}"',
            '--synth-stat "${evidence_dir}/synth_stat.txt"',
            '--blackbox-modules "${blackbox_modules}"',
            '--inline-modules "${inline_modules}"',
            '--macro-lib-files "${macro_lib_rel[*]}"',
            'V15P_STA_EXPECTED_MACRO_LIB_COUNT="${#macro_libs[@]}"',
            '--expected-macro-lib-count "${#macro_libs[@]}"',
            '--expected-unknown-macro-modules "${blackbox_modules}"',
            '--mapped-artifact-profile "${mapped_artifact_profile}"',
            'runner_path="$(realpath -e -- "${BASH_SOURCE[0]}")"',
            '! -path "${repo_root}/npc/rv64/vsrc/filelist.mk"',
            '"${architecture_registry}" "${runner_path}"',
        ):
            mutated = runner.replace(marker, "MUTATED")
            self.assertTrue(
                registry.mapped_runner_contract_errors(mutated),
                marker,
            )
        for source_name, source, marker in (
            (
                "tcl",
                sta_tcl,
                'if {$macro_count != $expected_macro_count}',
            ),
            (
                "parser",
                sta_parser,
                '"macro_lib_count": str(args.expected_macro_lib_count)',
            ),
        ):
            mutated = source.replace(marker, "MUTATED")
            errors = registry.mapped_sta_tool_contract_errors(
                mutated if source_name == "tcl" else sta_tcl,
                mutated if source_name == "parser" else sta_parser,
            )
            self.assertTrue(errors, source_name)

    def test_mapped_sta_area_parser_accepts_projected_three_macro_set(self) -> None:
        text = "\n".join(
            (
                "=== design hierarchy ===",
                "    100005 top NpcTop",
                "    100005 mapped cells",
                "         1 - Sram4096x199",
                "         2 - Sram4096x113",
                "         1 - OooFpArithGate",
                "         3 mapped submodules",
                "Area for cell type \\Sram4096x199 is unknown!",
                "Area for cell type \\Sram4096x113 is unknown!",
                "Area for cell type \\OooFpArithGate is unknown!",
                "Chip area for top module '\\NpcTop': 200000.00",
                "  of which used for sequential elements: 100000.00 (50.00%)",
                "",
            )
        )
        with tempfile.TemporaryDirectory() as temporary:
            synth_stat = Path(temporary) / "synth_stat.txt"
            synth_stat.write_text(text, encoding="utf-8")
            expected = {
                "Sram4096x199",
                "Sram4096x113",
                "OooFpArithGate",
            }
            area = mapped_sta.parse_area(synth_stat, expected)
            self.assertEqual(
                {
                    "OooFpArithGate": 1,
                    "Sram4096x113": 2,
                    "Sram4096x199": 1,
                },
                area["unknown_macro_instances"],
            )
            with self.assertRaises(mapped_sta.EvidenceError):
                mapped_sta.parse_area(
                    synth_stat, expected | {"OooBranchDirectionPredictor"}
                )

    def test_physical_configuration_ids_and_delta_fail_closed(self) -> None:
        for configuration_id in ("", "mapped-5ns-unknown-v1"):
            with self.assertRaises(registry.RegistryError):
                registry.mapped_projection(self.catalog, configuration_id)

        wrong_delta = copy.deepcopy(self.catalog)
        wrong_delta["physical_configurations"][
            registry.BPU_INLINE_CONFIGURATION
        ]["boundary_modes"]["OooFpArithGate"] = registry.INLINE_MODE
        errors = registry.validate_catalog(wrong_delta)
        self.assertTrue(any("unauthorized" in error for error in errors), errors)

        bpu_blackbox = copy.deepcopy(self.catalog)
        bpu_blackbox["physical_configurations"][
            registry.BPU_INLINE_CONFIGURATION
        ]["boundary_modes"]["OooBranchDirectionPredictor"] = (
            registry.PLACEHOLDER_MODE
        )
        errors = registry.validate_catalog(bpu_blackbox)
        self.assertTrue(any("unauthorized" in error for error in errors), errors)

        missing_sram = copy.deepcopy(self.catalog)
        del missing_sram["physical_configurations"][
            registry.BPU_INLINE_CONFIGURATION
        ]["boundary_modes"]["Sram4096x199"]
        errors = registry.validate_catalog(missing_sram)
        self.assertTrue(any("boundary key set" in error for error in errors), errors)

        missing_fp_census = copy.deepcopy(self.catalog)
        del missing_fp_census["physical_configurations"][
            registry.BPU_INLINE_CONFIGURATION
        ]["expected_unknown_macro_instances"]["OooFpArithGate"]
        errors = registry.validate_catalog(missing_fp_census)
        self.assertTrue(any("macro census" in error for error in errors), errors)

        promoted_archive = copy.deepcopy(self.catalog)
        promoted_archive["physical_configurations"][
            registry.BPU_LOCAL_PHT_BANKED_CHILD_INLINE_CONFIGURATION
        ]["champion"] = True
        errors = registry.validate_catalog(promoted_archive)
        self.assertTrue(any("non-champion" in error for error in errors), errors)

        hidden_child = copy.deepcopy(self.catalog)
        hidden_child["physical_configurations"][
            registry.BPU_LOCAL_PHT_BANKED_CHILD_INLINE_CONFIGURATION
        ]["inline_modules"] = ["OooBranchDirectionPredictor"]
        errors = registry.validate_catalog(hidden_child)
        self.assertTrue(any("inline module set" in error for error in errors), errors)

        missing_keep_hierarchy = copy.deepcopy(self.catalog)
        del missing_keep_hierarchy["physical_configurations"][
            registry.BPU_LOCAL_PHT_BANKED_CHILD_INLINE_CONFIGURATION
        ]["keep_hierarchy_additions"]
        errors = registry.validate_catalog(missing_keep_hierarchy)
        self.assertTrue(any("invalid key set" in error for error in errors), errors)

        drifted_keep_hierarchy = copy.deepcopy(self.catalog)
        drifted_keep_hierarchy["physical_configurations"][
            registry.BPU_LOCAL_PHT_WRITE_BANKED_FLAT_READ_VIEW_INLINE_CONFIGURATION
        ]["keep_hierarchy_additions"] = ["OooBranchDirectionPredictor"]
        errors = registry.validate_catalog(drifted_keep_hierarchy)
        self.assertTrue(
            any("keep-hierarchy additions" in error for error in errors), errors
        )

        share_enabled = copy.deepcopy(self.catalog)
        share_enabled["run_parameter_contract"]["synthesis"]["share"] = 1
        errors = registry.validate_catalog(share_enabled)
        self.assertTrue(any("run_parameter_contract drifted" in error for error in errors))
        with self.assertRaises(registry.RegistryError):
            registry.mapped_projection(
                share_enabled,
                registry.BPU_LOCAL_PHT_WRITE_BANKED_FLAT_READ_VIEW_INLINE_CONFIGURATION,
            )

        measured_without_receipt = copy.deepcopy(self.catalog)
        measured_without_receipt["bpu_physical_experiment_state"][
            "measurement_status"
        ] = "PASS"
        errors = registry.validate_catalog(measured_without_receipt)
        self.assertTrue(
            any("measurement_status" in error for error in errors), errors
        )

        promoted_candidate = copy.deepcopy(self.catalog)
        promoted_candidate["physical_configurations"][
            registry.BPU_LOCAL_PHT_WRITE_BANKED_FLAT_READ_VIEW_INLINE_CONFIGURATION
        ]["canonical"] = True
        errors = registry.validate_catalog(promoted_candidate)
        self.assertTrue(any("non-canonical" in error for error in errors), errors)

        measured_fp_without_receipt = copy.deepcopy(self.catalog)
        measured_fp_without_receipt["physical_configurations"][
            registry.FP_ARITH_PRODUCTION_CHILDREN_INLINE_CONFIGURATION
        ]["measurement_status"] = "PASS"
        errors = registry.validate_catalog(measured_fp_without_receipt)
        self.assertTrue(any("measurement_status" in error for error in errors), errors)

        fp_child_hidden = copy.deepcopy(self.catalog)
        fp_child_hidden["physical_configurations"][
            registry.FP_ARITH_PRODUCTION_CHILDREN_INLINE_CONFIGURATION
        ]["inline_modules"] = ["OooFpArithGate"]
        errors = registry.validate_catalog(fp_child_hidden)
        self.assertTrue(any("inline module set" in error for error in errors), errors)

        fp_wrapper_blackboxed = copy.deepcopy(self.catalog)
        fp_wrapper_blackboxed["physical_configurations"][
            registry.FP_ARITH_PRODUCTION_CHILDREN_INLINE_CONFIGURATION
        ]["boundary_modes"]["OooFpArithGate"] = registry.PLACEHOLDER_MODE
        errors = registry.validate_catalog(fp_wrapper_blackboxed)
        self.assertTrue(any("unauthorized" in error for error in errors), errors)

        drifted_profile = copy.deepcopy(self.catalog)
        drifted_profile["physical_configurations"][
            registry.FP_ARITH_PRODUCTION_CHILDREN_INLINE_CONFIGURATION
        ]["mapped_artifact_profile"] = registry.MAPPED_ARTIFACT_PROFILE_BPU_LOCAL_PHT
        errors = registry.validate_catalog(drifted_profile)
        self.assertTrue(
            any("mapped artifact profile" in error for error in errors), errors
        )

        rewritten_frozen_receipt = copy.deepcopy(self.catalog)
        rewritten_frozen_receipt["bpu_physical_experiment_state"][
            "frozen_predecessor"
        ]["mapped_execution_receipt"] = "GAP"
        errors = registry.validate_catalog(rewritten_frozen_receipt)
        self.assertTrue(
            any("mapped_execution_receipt" in error for error in errors), errors
        )

        schema = registry.load_json(registry.SCHEMA_PATH)
        schema_properties = schema["properties"]
        banked_schema = schema_properties["physical_configurations"]["properties"][
            registry.BPU_LOCAL_PHT_BANKED_CHILD_INLINE_CONFIGURATION
        ]
        self.assertIn("keep_hierarchy_additions", banked_schema["required"])
        self.assertEqual(
            registry.EXPECTED_BANKED_CHILD_KEEP_HIERARCHY_ADDITIONS,
            banked_schema["properties"]["keep_hierarchy_additions"]["const"],
        )
        self.assertEqual(
            registry.EXPECTED_LIVE_DESIGN_ID,
            schema_properties["run_parameter_contract"]["properties"][
                "expected_rtl_design_id"
            ]["const"],
        )
        flat_read_schema = schema_properties["physical_configurations"]["properties"][
            registry.BPU_LOCAL_PHT_WRITE_BANKED_FLAT_READ_VIEW_INLINE_CONFIGURATION
        ]
        self.assertEqual(
            "engineering_proxy_negative_result_archive",
            flat_read_schema["properties"]["archive_class"]["const"],
        )
        self.assertEqual(
            registry.EXPECTED_LIVE_DESIGN_ID,
            schema_properties["bpu_physical_experiment_state"]["properties"][
                "live_rtl_design_id"
            ]["const"],
        )
        fp_schema = schema_properties["physical_configurations"]["properties"][
            registry.FP_ARITH_PRODUCTION_CHILDREN_INLINE_CONFIGURATION
        ]
        self.assertEqual(
            registry.EXPECTED_FP_ARITH_INLINE_MODULES,
            fp_schema["properties"]["inline_modules"]["const"],
        )
        self.assertEqual(
            registry.MAPPED_ARTIFACT_PROFILE_FP_ARITH_CHILDREN,
            fp_schema["properties"]["mapped_artifact_profile"]["const"],
        )
        self.assertEqual(
            "UNMEASURED",
            fp_schema["properties"]["measurement_status"]["const"],
        )
        self.assertEqual(
            "GAP", fp_schema["properties"]["physical_status"]["const"]
        )
        self.assertFalse(fp_schema["properties"]["canonical"]["const"])
        self.assertFalse(fp_schema["properties"]["champion"]["const"])

        ooc_schema = schema_properties["physical_configurations"]["properties"][
            registry.FP_ARITH_PRODUCTION_CHILDREN_OOC_BOUNDARY_CONFIGURATION
        ]
        self.assertEqual(
            registry.OOC_STA_ABSTRACTION,
            ooc_schema["properties"]["abstraction_kind"]["const"],
        )
        self.assertEqual(
            registry.MAPPED_ARTIFACT_PROFILE_FP_ARITH_OOC_COMPOSITE,
            ooc_schema["properties"]["mapped_artifact_profile"]["const"],
        )

    def test_fp_ooc_composite_projection_and_tool_contract_fail_closed(self) -> None:
        projection = registry.mapped_projection(
            self.catalog,
            registry.FP_ARITH_PRODUCTION_CHILDREN_OOC_BOUNDARY_CONFIGURATION,
        )
        self.assertEqual(
            ["OooFpArithGate"], projection["implementation_classes"]["inline_rtl"]
        )
        self.assertEqual(
            registry.EXPECTED_FP_OOC_MACRO_MODULES,
            projection["implementation_classes"]["known_ooc_macro"],
        )
        self.assertEqual(
            registry.EXPECTED_FP_OOC_UNKNOWN_PLACEHOLDERS,
            projection["implementation_classes"]["unknown_placeholder"],
        )
        self.assertEqual(
            registry.EXPECTED_FP_OOC_MACRO_MODULES,
            projection["known_ooc_macro_modules"],
        )
        self.assertEqual(
            [
                *projection["blackbox_modules"],
                *registry.EXPECTED_FP_OOC_MACRO_MODULES,
            ],
            projection["top_blackbox_modules"],
        )
        parameters = registry.run_parameter_values(
            self.catalog,
            registry.FP_ARITH_PRODUCTION_CHILDREN_OOC_BOUNDARY_CONFIGURATION,
            expected_rtl_design_id=registry.EXPECTED_LIVE_DESIGN_ID,
            result_root=str(
                registry.REPO_ROOT
                / ".github/runtime-artifacts/fp-ooc-composite/unit"
            ),
        )
        self.assertEqual(
            " ".join(registry.EXPECTED_FP_OOC_MACRO_MODULES),
            parameters["known_ooc_macro_modules"],
        )
        self.assertEqual(
            registry.OOC_STA_ABSTRACTION, parameters["ooc_abstraction_kind"]
        )
        self.assertEqual(
            "bound_stdlib_whitelist_no_dollar_generic",
            projection["ooc_model_contract"]["mapped_leaf_policy"],
        )
        self.assertEqual(
            "complete_ports_leaf_cells_instances",
            projection["ooc_model_contract"]["retained_netlist_manifest"],
        )
        self.assertEqual(
            {
                "path_object": "PathEnd_points_Path_arrival",
                "unit_domain": "OpenSTA_PropertyValue_UI_nanoseconds",
                "input_to_register_d": (
                    "endpoint_arrival_ns-minus-first_arrival_ns_with_zero_input_seed"
                ),
                "register_q_to_output": (
                    "endpoint_cumulative_arrival_ns_from_zero_rising_ideal_clock"
                ),
                "clock_origin_ns": 0.0,
                "clock_source_latency_ns": 0.0,
                "clock_network_latency_ns": 0.0,
                "clock_insertion_ns": 0.0,
                "clock_propagation": "ideal_unpropagated",
                "path_end_validation": (
                    "constrained_min_max_check_role_startpoint_endpoint_points_first_last"
                ),
            },
            projection["ooc_model_contract"]["path_measurement_basis"],
        )
        for module, contract in projection["child_contracts"].items():
            exact = contract["top_boundary_contract"]
            self.assertEqual(
                f"u_fp_arith/{contract['top_instance']}",
                exact["source_instance_path"],
                module,
            )
        final_endpoint = projection["child_contracts"][
            "OooFpFmaNormRoundPipe"
        ]["top_boundary_contract"]["endpoint"]
        self.assertEqual(
            {
                "kind": "backend_completion_register_d",
                "object_class": "REGISTER_D",
                "instance_path": registry.FP_OOC_BACKEND_COMPLETION_INSTANCE_PATH,
                "register_families": registry.FP_OOC_BACKEND_COMPLETION_REGISTER_FAMILIES,
            },
            final_endpoint,
        )

        # Freeze the live NpcTop instance chain and the value/fflags capture
        # edge.  This is deliberately source based: no guessed top port or
        # loose u_fp_arith wildcard may substitute for the completion FIFO D.
        rtl_chain = (
            ("npc/rv64/vsrc/core/NpcTop.v", "NpcCoreTop u_core"),
            ("npc/rv64/vsrc/core/NpcCoreTop.v", "u_ooo_core ("),
            ("npc/rv64/vsrc/core/OooCoreTopGlue.v", "u_execute_backend ("),
            ("npc/rv64/vsrc/execute/OooExecuteBackend.v", "u_core_slice ("),
            ("npc/rv64/vsrc/execute/OooAluCoreSlice.v", "u_decode_backend ("),
            ("npc/rv64/vsrc/decode/OooAluDecodeBackend.v", "u_int_backend ("),
            ("npc/rv64/vsrc/execute/OooIntBackend.v", "u_fp_backend ("),
        )
        for relative, marker in rtl_chain:
            text = (registry.REPO_ROOT / relative).read_text(encoding="utf-8")
            self.assertIn(marker, text, relative)
        fp_backend = (registry.REPO_ROOT / "npc/rv64/vsrc/execute/OooFpBackend.v").read_text(
            encoding="utf-8"
        )
        for marker in (
            ".out_value_o(arith_out_value_w)",
            ".out_fflags_o(arith_out_fflags_w)",
            "arith_out_valid_w ? arith_out_value_w",
            "arith_out_valid_w ? arith_out_fflags_w",
            "df_value_q[df_tail_q] <= done_in_value_w",
            "df_fflags_q[df_tail_q] <= done_in_fflags_w",
        ):
            self.assertIn(marker, fp_backend)

        for label, endpoint in (
            (
                "legacy-top-port",
                {
                    "kind": "top_port",
                    "object_class": "PORT",
                    "port_families": {"out_fflags_o": 5, "out_value_o": 64},
                },
            ),
            (
                "near-name",
                {
                    **copy.deepcopy(final_endpoint),
                    "register_families": {"df_fflags_q": 40, "df_value_qq": 512},
                },
            ),
            (
                "wrong-hierarchy",
                {
                    **copy.deepcopy(final_endpoint),
                    "instance_path": final_endpoint["instance_path"].replace(
                        "/u_fp_backend", "/u_fake_fp_backend"
                    ),
                },
            ),
        ):
            damaged = copy.deepcopy(self.catalog)
            damaged["physical_configurations"][
                registry.FP_ARITH_PRODUCTION_CHILDREN_OOC_BOUNDARY_CONFIGURATION
            ]["child_contracts"]["OooFpFmaNormRoundPipe"][
                "top_boundary_contract"
            ]["endpoint"] = endpoint
            errors = registry.validate_catalog(damaged)
            with self.subTest(label=label):
                self.assertTrue(
                    any("child timing contracts drifted" in error for error in errors),
                    errors,
                )
        profile_sha, profile_errors = registry.mapped_profile_evidence_state(
            {}, expected_profile=registry.MAPPED_ARTIFACT_PROFILE_FP_ARITH_OOC_COMPOSITE
        )
        self.assertIsNone(profile_sha)
        self.assertTrue(
            any("generic mapped-summary stamping is forbidden" in error
                for error in profile_errors),
            profile_errors,
        )

        paths = {
            "runner": registry.REPO_ROOT / "npc/rv64/eval/ppa/run-fp-ooc-composite-current.sh",
            "child_yosys": registry.REPO_ROOT / "npc/rv64/eval/ppa/yosys-fp-ooc-child.tcl",
            "child_sta": registry.REPO_ROOT / "npc/rv64/eval/ppa/opensta-fp-ooc-child.tcl",
            "top_sta": registry.REPO_ROOT / "npc/rv64/eval/ppa/opensta-fp-ooc-top.tcl",
            "parser": registry.REPO_ROOT / "npc/rv64/eval/ppa/tools/fp_ooc_composite.py",
            "schema": registry.REPO_ROOT / "npc/rv64/eval/ppa/schemas/fp-ooc-composite-v1.schema.json",
        }
        source = {key: path.read_text(encoding="utf-8") for key, path in paths.items()}
        self.assertEqual(
            [],
            registry.fp_ooc_composite_tool_contract_errors(
                source["runner"], source["child_yosys"], source["child_sta"],
                source["top_sta"], source["parser"], source["schema"],
            ),
        )
        damaged = source["runner"].replace(
            "emit known-ooc-macro-modules", "emit mapped-blackbox-modules", 1
        )
        errors = registry.fp_ooc_composite_tool_contract_errors(
            damaged, source["child_yosys"], source["child_sta"],
            source["top_sta"], source["parser"], source["schema"],
        )
        self.assertTrue(any("known-macro projection" in error for error in errors), errors)
        for source_name, marker, expected_label in (
            ("child_sta", "register_q_pins", "real Q launch collection"),
            (
                "child_sta", "-endpoint_path_count $endpoint_path_count",
                "explicit endpoint path cap",
            ),
            (
                "child_sta",
                "proc validate_path_end {path_end label expected_min_max expected_roles from_names to_names}",
                "PathEnd points validator",
            ),
            ("child_sta", "get_property $path_end points", "PathEnd points property"),
            ("child_sta", "get_property $first_point arrival", "first Path UI-ns arrival"),
            ("child_sta", "get_property $last_point arrival", "endpoint Path UI-ns arrival"),
            ("child_sta", "$path_end min_max", "PathEnd min/max object method"),
            ("child_sta", "$path_end check_role", "PathEnd check-role object method"),
            ("child_sta", "is not a constrained PathEnd", "constrained PathEnd gate"),
            (
                "child_sta",
                "input Path arrival seed is not explicit zero UI-ns",
                "zero input arrival seed gate",
            ),
            (
                "child_sta", "return $endpoint_arrival_ns",
                "cumulative clock-to-Q endpoint arrival",
            ),
            (
                "child_sta",
                "set path_startpoint [dict get $observation startpoint]",
                "per-query PathEnd startpoint materialization",
            ),
            (
                "child_sta",
                "set path_endpoint [dict get $observation endpoint]",
                "per-query PathEnd endpoint materialization",
            ),
            (
                "child_sta", "set selected_startpoint $path_startpoint",
                "ordinary selected startpoint state",
            ),
            (
                "child_sta", "set selected_endpoint $path_endpoint",
                "ordinary selected endpoint state",
            ),
            (
                "child_sta",
                "-waveform [list $fp_ooc_clock_origin_ns [expr {$period_ns / 2.0}]]",
                "explicit zero rising clock waveform",
            ),
            (
                "child_sta",
                "set_clock_latency -source $fp_ooc_clock_source_latency_ns",
                "zero source clock latency",
            ),
            (
                "child_sta",
                "set_clock_latency $fp_ooc_clock_network_latency_ns",
                "zero network clock latency",
            ),
            (
                "child_sta", "set fp_ooc_clock_propagated 0",
                "unpropagated clock basis",
            ),
            (
                "child_sta",
                "set bracket_pattern [format {^%s\\[([0-9]+)\\]$} $family]",
                "brace-quoted bracket port-family pattern",
            ),
            (
                "child_sta",
                "set splitnets_pattern [format {^%s__v([0-9]+)$} $family]",
                "brace-quoted splitnets port-family pattern",
            ),
            (
                "child_sta",
                "set underscore_pattern [format {^%s_([0-9]+)_$} $family]",
                "brace-quoted underscore port-family pattern",
            ),
            (
                "child_sta",
                "regexp {^(?:0|[1-9][0-9]*)$} $index_text",
                "canonical decimal port index gate",
            ),
            (
                "child_sta",
                '$selected_style ne "" && $selected_style ne $style',
                "single indexed-style gate",
            ),
            (
                "child_sta",
                "dict exists $indexed_ports $index",
                "unique port index gate",
            ),
            (
                "child_sta",
                "for {set index 0} {$index < $width} {incr index}",
                "continuous port index coverage",
            ),
            (
                "child_sta",
                "get_property $port direction] ne $direction",
                "exact port direction gate",
            ),
            (
                "child_sta",
                '$width == 1 && $selected_style ne "scalar"',
                "width-one exact scalar gate",
            ),
            ("top_sta", "actual_pin_crosscheck", "actual pin object intersection"),
            ("top_sta", "$exact_name ne $full", "actual pin full-name equality"),
            ("top_sta", "actual_parent_cell_crosscheck", "actual parent cell intersection"),
            ("top_sta", "exact_backend_completion_register_d_objects",
             "backend completion register-D collection"),
            ("parser", "validate_netlist_manifest", "retained complete manifest validator"),
            ("parser", "canonicalize_retained_ports",
             "Registry-driven post-split port canonicalizer"),
            ("parser", '"raw_ports"', "retained raw split-port manifest"),
            ("parser", '"raw_to_canonical"',
             "auditable raw-to-canonical port map"),
            ("parser", '"port_manifest"',
             "child result port-manifest binding"),
            ("parser", "expected_netlist_sha256",
             "manifest-to-netlist digest binding"),
            ("parser", "expected_netlist_size_bytes",
             "manifest-to-netlist size binding"),
            ("parser", "_parse_port_object_family",
             "strict port-family parser"),
            ("parser", "_validate_port_object_family_names",
             "strict port-family coverage validator"),
            (
                "parser",
                '("underscore", rf"{re.escape(family)}_([0-9]+)_")',
                "underscore mapped-port style",
            ),
            (
                "parser",
                're.fullmatch(r"(?:0|[1-9][0-9]*)", index_text)',
                "canonical mapped-port decimal index",
            ),
            (
                "parser", "set(indices) == set(range(width))",
                "continuous mapped-port index coverage",
            ),
            (
                "parser", "candidate = name",
                "direct PORT full-object parser",
            ),
            (
                "parser", 'require("/" not in name,',
                "hierarchical PORT owner rejection",
            ),
            ("parser", "backend_completion_register_d",
             "backend completion endpoint projection"),
            (
                "parser",
                '"path_measurement_basis": projection()["ooc_model_contract"]',
                "Registry path-measurement basis binding",
            ),
            ("schema", '"portManifestSummary"',
             "post-split port-manifest schema"),
            ("schema", '"port_manifest"',
             "post-split port-manifest field"),
        ):
            changed = dict(source)
            changed[source_name] = changed[source_name].replace(marker, "")
            errors = registry.fp_ooc_composite_tool_contract_errors(
                changed["runner"], changed["child_yosys"], changed["child_sta"],
                changed["top_sta"], changed["parser"], changed["schema"],
            )
            with self.subTest(source=source_name):
                self.assertTrue(any(expected_label in error for error in errors), errors)
        owner_dropping_parser = source["parser"].replace(
            "candidate = name", 'candidate = name.rsplit("/", 1)[-1]', 1
        )
        errors = registry.fp_ooc_composite_tool_contract_errors(
            source["runner"], source["child_yosys"], source["child_sta"],
            source["top_sta"], owner_dropping_parser, source["schema"],
        )
        self.assertTrue(
            any("discards hierarchical PORT ownership" in error
                for error in errors),
            errors,
        )
        for forbidden, expected_label in (
            ("sta::time_sta_ui", "secondary UI-time conversion"),
            ("data_arrival_time", "PathEnd data-arrival offset"),
            ("set bogus [expr {$period_ns - $slack_ns}]",
             "period/slack pseudo path-delay derivation"),
            ("set bogus [expr {$required - $slack_ns}]",
             "required/slack pseudo path-delay derivation"),
            ("get_property $path_end path_delay",
             "PathEnd pseudo delay/arrival property"),
            ("$path_end arrival", "raw SWIG Path arrival"),
            ("-group_count 100000", "deprecated path-group query"),
            ("-group_path_count 100000", "unbounded 100000 path group"),
            ("set selected_path $path", "cross-query selected PathEnd retention"),
            ("set selected_points $points", "cross-query selected Path points retention"),
        ):
            damaged_child = source["child_sta"] + "\n" + forbidden
            errors = registry.fp_ooc_composite_tool_contract_errors(
                source["runner"], source["child_yosys"], damaged_child,
                source["top_sta"], source["parser"], source["schema"],
            )
            with self.subTest(forbidden_measurement=forbidden):
                self.assertTrue(
                    any(expected_label in error for error in errors), errors
                )
        safe_regexp = "[regexp $bracket_pattern $name -> index_text]"
        self.assertEqual(1, source["child_sta"].count(safe_regexp))
        double_quoted = source["child_sta"].replace(
            safe_regexp,
            '[regexp "^${family}[0-9]+$" $name -> index_text]',
            1,
        )
        errors = registry.fp_ooc_composite_tool_contract_errors(
            source["runner"], source["child_yosys"], double_quoted,
            source["top_sta"], source["parser"], source["schema"],
        )
        self.assertTrue(
            any("double-quoted regexp command substitution" in error
                for error in errors),
            errors,
        )
        proc_start = source["child_sta"].index(
            "proc exact_port_family {family width direction}"
        )
        proc_end = source["child_sta"].index("\nproc register_d_pins", proc_start)
        cardinality_only = '''proc exact_port_family {family width direction} {
  set result {}
  foreach port [get_ports *] {
    if {[string match "${family}*" [get_full_name $port]] &&
        [get_property $port direction] eq $direction} {
      lappend result $port
    }
  }
  if {[collection_count $result] != $width} { error "cardinality mismatch" }
  return $result
}
'''
        cardinality_only_source = (
            source["child_sta"][:proc_start]
            + cardinality_only
            + source["child_sta"][proc_end + 1:]
        )
        errors = registry.fp_ooc_composite_tool_contract_errors(
            source["runner"], source["child_yosys"], cardinality_only_source,
            source["top_sta"], source["parser"], source["schema"],
        )
        self.assertTrue(
            any("continuous port index coverage" in error for error in errors),
            errors,
        )
        for marker, expected_label in (
            ('endpoint_kind eq "top_port"', "legacy top-port endpoint dispatch"),
            ("proc exact_top_port_objects", "legacy top-port object collector"),
            ("proc actual_port_crosscheck", "legacy top-port crosscheck"),
        ):
            errors = registry.fp_ooc_composite_tool_contract_errors(
                source["runner"], source["child_yosys"], source["child_sta"],
                source["top_sta"] + "\n" + marker, source["parser"],
                source["schema"],
            )
            with self.subTest(forbidden_top_marker=marker):
                self.assertTrue(
                    any(expected_label in error for error in errors), errors
                )

    def test_fp_ooc_child_source_domains_and_runner_fail_closed(self) -> None:
        configuration_id = (
            registry.FP_ARITH_PRODUCTION_CHILDREN_OOC_BOUNDARY_CONFIGURATION
        )
        projection = registry.mapped_projection(self.catalog, configuration_id)
        filelist = "npc/rv64/vsrc/filelist.mk"
        for module, contract in projection["child_contracts"].items():
            closure = contract["source_closure"]
            compile_sources = contract["compile_sources"]
            expected_compile = [
                path for path in closure if Path(path).suffix in {".v", ".sv"}
            ]
            self.assertEqual(expected_compile, compile_sources, module)
            self.assertIn(contract["rtl"], compile_sources, module)
            self.assertIn(filelist, closure, module)
            self.assertNotIn(filelist, compile_sources, module)

        schema = registry.load_json(registry.SCHEMA_PATH)
        child_schema = schema["$defs"]["fpOocChildContract"]
        self.assertIn("compile_sources", child_schema["required"])
        compile_schema = child_schema["properties"]["compile_sources"]
        self.assertEqual(1, compile_schema["minItems"])
        self.assertTrue(compile_schema["uniqueItems"])
        self.assertEqual(
            "^npc/rv64/vsrc/.+\\.(v|sv)$",
            compile_schema["items"]["pattern"],
        )

        module = "OooFpAddSubPipe"
        base_contract = self.catalog["physical_configurations"][configuration_id][
            "child_contracts"
        ][module]
        mutations: list[tuple[str, dict[str, object], str]] = []
        missing = copy.deepcopy(self.catalog)
        del missing["physical_configurations"][configuration_id]["child_contracts"][
            module
        ]["compile_sources"]
        mutations.append(("missing-field", missing, "compile_sources must be non-empty"))
        non_verilog = copy.deepcopy(self.catalog)
        non_verilog["physical_configurations"][configuration_id]["child_contracts"][
            module
        ]["compile_sources"].append(filelist)
        mutations.append(("non-verilog", non_verilog, "non-Verilog"))
        not_subset = copy.deepcopy(self.catalog)
        not_subset["physical_configurations"][configuration_id]["child_contracts"][
            module
        ]["compile_sources"][1] = "npc/rv64/vsrc/execute/OooFpArithGate.v"
        mutations.append(("not-closure-subset", not_subset, "not a source_closure subset"))
        outside = copy.deepcopy(self.catalog)
        outside["physical_configurations"][configuration_id]["child_contracts"][
            module
        ]["compile_sources"][0] = "npc/rv64/eval/ppa/FakeChild.v"
        mutations.append(("outside-vsrc", outside, "out-of-domain"))
        missing_rtl = copy.deepcopy(self.catalog)
        missing_rtl["physical_configurations"][configuration_id]["child_contracts"][
            module
        ]["compile_sources"].remove(base_contract["rtl"])
        mutations.append(("missing-child-rtl", missing_rtl, "lacks child RTL"))
        for label, damaged, expected in mutations:
            with self.subTest(catalog_mutation=label):
                errors = registry.validate_catalog(damaged)
                self.assertTrue(any(expected in error for error in errors), errors)

        paths = {
            "runner": registry.REPO_ROOT / "npc/rv64/eval/ppa/run-fp-ooc-composite-current.sh",
            "child_yosys": registry.REPO_ROOT / "npc/rv64/eval/ppa/yosys-fp-ooc-child.tcl",
            "child_sta": registry.REPO_ROOT / "npc/rv64/eval/ppa/opensta-fp-ooc-child.tcl",
            "top_sta": registry.REPO_ROOT / "npc/rv64/eval/ppa/opensta-fp-ooc-top.tcl",
            "parser": registry.REPO_ROOT / "npc/rv64/eval/ppa/tools/fp_ooc_composite.py",
            "schema": registry.REPO_ROOT / "npc/rv64/eval/ppa/schemas/fp-ooc-composite-v1.schema.json",
        }
        source = {key: path.read_text(encoding="utf-8") for key, path in paths.items()}

        def errors_for(*, runner: str | None = None,
                       parser: str | None = None) -> list[str]:
            return registry.fp_ooc_composite_tool_contract_errors(
                runner if runner is not None else source["runner"],
                source["child_yosys"], source["child_sta"], source["top_sta"],
                parser if parser is not None else source["parser"], source["schema"],
            )

        self.assertEqual([], errors_for())
        compile_input = '"${child_compile_sources[*]}" "${child_netlist}"'
        closure_input = '"${child_source_closure[*]}" "${child_netlist}"'
        reused_closure = source["runner"].replace(
            compile_input, closure_input, 1
        )
        self.assertTrue(
            any("sends identity source_closure" in error
                for error in errors_for(runner=reused_closure))
        )
        compile_manifest_line = (
            '  sha256sum "${child_compile_sources[@]}" '
            '>"${child_dir}/compile-sources.sha256" || fail 1\n'
        )
        self.assertEqual(1, source["runner"].count(compile_manifest_line))
        missing_manifest = source["runner"].replace(compile_manifest_line, "", 1)
        self.assertTrue(
            any("compile-source manifest" in error
                for error in errors_for(runner=missing_manifest))
        )
        missing_emit = source["parser"].replace(
            "command_emit_child_compile_sources", ""
        )
        self.assertTrue(
            any("compile-source command" in error
                for error in errors_for(parser=missing_emit))
        )

    def test_fp_ooc_runner_pythonpath_and_failure_status_fail_closed(self) -> None:
        paths = {
            "runner": registry.REPO_ROOT / "npc/rv64/eval/ppa/run-fp-ooc-composite-current.sh",
            "child_yosys": registry.REPO_ROOT / "npc/rv64/eval/ppa/yosys-fp-ooc-child.tcl",
            "child_sta": registry.REPO_ROOT / "npc/rv64/eval/ppa/opensta-fp-ooc-child.tcl",
            "top_sta": registry.REPO_ROOT / "npc/rv64/eval/ppa/opensta-fp-ooc-top.tcl",
            "parser": registry.REPO_ROOT / "npc/rv64/eval/ppa/tools/fp_ooc_composite.py",
            "schema": registry.REPO_ROOT / "npc/rv64/eval/ppa/schemas/fp-ooc-composite-v1.schema.json",
        }
        source = {key: path.read_text(encoding="utf-8") for key, path in paths.items()}

        def errors_for(runner: str) -> list[str]:
            return registry.fp_ooc_composite_tool_contract_errors(
                runner, source["child_yosys"], source["child_sta"],
                source["top_sta"], source["parser"], source["schema"],
            )

        self.assertEqual([], errors_for(source["runner"]))
        binding = (
            'export PYTHONPATH="${repo_root}"\n'
            "readonly PYTHONPATH\n"
        )
        self.assertEqual(1, source["runner"].count(binding))
        moved_after_identity = source["runner"].replace(binding, "", 1)
        identity_end = (
            '  --output "${evidence_dir}/run-identity.json" || fail 2\n'
        )
        self.assertEqual(1, moved_after_identity.count(identity_end))
        moved_after_identity = moved_after_identity.replace(
            identity_end, identity_end + binding, 1
        )
        mutations = (
            (
                "deleted-binding",
                source["runner"].replace(binding, "", 1),
                "deterministic repository PYTHONPATH binding",
            ),
            (
                "wrong-root",
                source["runner"].replace(
                    'export PYTHONPATH="${repo_root}"',
                    'export PYTHONPATH="${repo_root}/npc"', 1,
                ),
                "deterministic repository PYTHONPATH binding",
            ),
            (
                "external-inheritance",
                source["runner"].replace(
                    'export PYTHONPATH="${repo_root}"',
                    'export PYTHONPATH="${PYTHONPATH}:${repo_root}"', 1,
                ),
                "deterministic repository PYTHONPATH binding",
            ),
            (
                "binding-after-first-composite",
                moved_after_identity,
                "does not precede all Python tool calls",
            ),
            (
                "deleted-stage-freeze",
                source["runner"].replace(
                    '  local failure_stage="${stage}"\n', "", 1
                ),
                "failure stage freeze",
            ),
            (
                "deleted-stage-restore",
                source["runner"].replace(
                    '    stage="${failure_stage}"\n', "", 1
                ),
                "failure stage restoration",
            ),
            (
                "deleted-cleanup-status",
                source["runner"].replace(
                    "    printf 'CLEANUP_RC=%s\\n' \"${cleanup_rc}\"\n",
                    "", 1,
                ),
                "cleanup return-code status field",
            ),
            (
                "exit-trap-overwrite",
                source["runner"].replace(
                    '    stage="${failure_stage}"', "    stage=exit-trap", 1
                ),
                "overwrites the real failure stage",
            ),
            (
                "deleted-signal-stage",
                source["runner"].replace(
                    '  stage="signal-${signal_name}"\n', "", 1
                ),
                "signal-stage cleanup ordering",
            ),
        )
        for label, damaged, expected in mutations:
            with self.subTest(label=label):
                errors = errors_for(damaged)
                self.assertTrue(any(expected in error for error in errors), errors)

    def test_fp_ooc_runner_child_result_dir_and_cleanup_fail_closed(self) -> None:
        paths = {
            "runner": registry.REPO_ROOT / "npc/rv64/eval/ppa/run-fp-ooc-composite-current.sh",
            "child_yosys": registry.REPO_ROOT / "npc/rv64/eval/ppa/yosys-fp-ooc-child.tcl",
            "child_sta": registry.REPO_ROOT / "npc/rv64/eval/ppa/opensta-fp-ooc-child.tcl",
            "top_sta": registry.REPO_ROOT / "npc/rv64/eval/ppa/opensta-fp-ooc-top.tcl",
            "parser": registry.REPO_ROOT / "npc/rv64/eval/ppa/tools/fp_ooc_composite.py",
            "schema": registry.REPO_ROOT / "npc/rv64/eval/ppa/schemas/fp-ooc-composite-v1.schema.json",
        }
        source = {key: path.read_text(encoding="utf-8") for key, path in paths.items()}

        def errors_for(runner: str) -> list[str]:
            return registry.fp_ooc_composite_tool_contract_errors(
                runner, source["child_yosys"], source["child_sta"],
                source["top_sta"], source["parser"], source["schema"],
            )

        runner = source["runner"]
        self.assertEqual([], errors_for(runner))
        create_line = (
            '  mkdir -p -- "${child_dir}" "${child_runtime}" '
            '"${child_result_dir}" || fail 1\n'
        )
        parent_rmdir = '  rmdir -- "${resolved_parent}"\n'
        self.assertEqual(1, runner.count(create_line))
        self.assertEqual(1, runner.count(parent_rmdir))

        late_create = runner.replace(create_line, "", 1)
        synthesis_end = (
            '    "${repo_root}/npc/rv64/vsrc ${repo_root}/npc/rv64/vsrc/include" "" \\\n'
            '    || fail $?\n'
        )
        self.assertEqual(1, late_create.count(synthesis_end))
        late_create = late_create.replace(
            synthesis_end, synthesis_end + create_line, 1
        )
        success_only_cleanup = runner.replace(parent_rmdir, "", 1)
        success_cleanup_anchor = (
            '[[ "${cleanup_rc}" -eq 0 ]] || fail "${cleanup_rc}"\n'
        )
        self.assertEqual(1, success_only_cleanup.count(success_cleanup_anchor))
        success_only_cleanup = success_only_cleanup.replace(
            success_cleanup_anchor,
            success_cleanup_anchor + 'rmdir -- "${resolved_parent}"\n',
            1,
        )
        mutations = (
            (
                "missing-child-result-dir-create",
                runner.replace(create_line, "", 1),
                "child result directory",
            ),
            (
                "wrong-child-result-dir-level",
                runner.replace(
                    create_line,
                    '  mkdir -p -- "${child_dir}" "${child_runtime}" || fail 1\n',
                    1,
                ),
                "child result directory",
            ),
            (
                "late-child-result-dir-create",
                late_create,
                "child result directory ordering",
            ),
            (
                "missing-parent-rmdir",
                runner.replace(parent_rmdir, "", 1),
                "runtime-parent",
            ),
            (
                "success-only-parent-rmdir",
                success_only_cleanup,
                "cleanup is not validate-random-delete-random",
            ),
            (
                "swallowed-nonempty-parent",
                runner.replace(
                    parent_rmdir,
                    '  rmdir -- "${resolved_parent}" || true\n',
                    1,
                ),
                "cleanup is not validate-random-delete-random",
            ),
        )
        for label, damaged, expected in mutations:
            with self.subTest(label=label):
                errors = errors_for(damaged)
                self.assertTrue(any(expected in error for error in errors), errors)

    def test_failed_f5f2_attempt_and_closed_bpu_sweep_fail_closed(self) -> None:
        promoted_failed_attempt = copy.deepcopy(self.catalog)
        promoted_failed_attempt["bpu_physical_experiment_state"][
            "failed_attempt"
        ]["result"] = "PASS"
        errors = registry.validate_catalog(promoted_failed_attempt)
        self.assertTrue(
            any("failed_attempt.result" in error for error in errors), errors
        )

        promoted_execution_receipt = copy.deepcopy(self.catalog)
        promoted_execution_receipt["bpu_physical_experiment_state"][
            "mapped_execution_receipt"
        ] = "PASS"
        errors = registry.validate_catalog(promoted_execution_receipt)
        self.assertTrue(
            any("mapped_execution_receipt" in error for error in errors), errors
        )

        raw_as_failed_summary = copy.deepcopy(self.catalog)
        raw_as_failed_summary["bpu_physical_experiment_state"][
            "failed_attempt"
        ]["summary"] = registry.FAILED_F5F2_RAW_DIAGNOSTIC
        errors = registry.validate_catalog(raw_as_failed_summary)
        self.assertTrue(
            any("failed_attempt.summary" in error for error in errors), errors
        )

        raw_as_bound_summary = copy.deepcopy(self.catalog)
        raw_as_bound_summary["evidence"][
            "mapped_summary"
        ] = registry.FAILED_F5F2_RAW_DIAGNOSTIC
        errors = registry.validate_catalog(raw_as_bound_summary)
        self.assertTrue(
            any("latest successful bound B279 summary" in error for error in errors),
            errors,
        )

        cleared_stop_condition = copy.deepcopy(self.catalog)
        cleared_stop_condition["bpu_physical_experiment_state"][
            "stop_condition"
        ] = "CLEARED"
        errors = registry.validate_catalog(cleared_stop_condition)
        self.assertTrue(any("stop_condition" in error for error in errors), errors)

        continued_traceable_run = copy.deepcopy(self.catalog)
        continued_traceable_run["bpu_physical_experiment_state"][
            "next_action"
        ] = "RUN_TRACEABLE_MAPPED_CURRENT_ONCE"
        errors = registry.validate_catalog(continued_traceable_run)
        self.assertTrue(any("next_action" in error for error in errors), errors)

        changed_latest_attempt = copy.deepcopy(self.catalog)
        changed_latest_attempt["evidence"][
            "latest_mapped_attempt"
        ] = registry.FROZEN_B279_MAPPED_SUMMARY
        errors = registry.validate_catalog(changed_latest_attempt)
        self.assertTrue(
            any("latest_mapped_attempt" in error for error in errors), errors
        )

        schema = registry.load_json(registry.SCHEMA_PATH)
        state_schema = schema["properties"]["bpu_physical_experiment_state"]
        state_properties = state_schema["properties"]
        self.assertEqual(
            "FAILED_INCOMPLETE",
            state_properties["measurement_status"]["const"],
        )
        self.assertEqual("FAIL", state_properties["mapped_execution_receipt"]["const"])
        self.assertEqual("TRIGGERED", state_properties["stop_condition"]["const"])
        self.assertEqual(
            "STOP_BPU_PIVOT_FP", state_properties["next_action"]["const"]
        )
        self.assertEqual(
            "BPU_CLOSED_FOR_SWEEP", state_properties["sweep_status"]["const"]
        )
        failed_properties = state_properties["failed_attempt"]["properties"]
        self.assertIsNone(failed_properties["summary"]["const"])
        self.assertIsNone(
            failed_properties["architecture_registry_binding"]["const"]
        )
        self.assertFalse(failed_properties["qualified_measurement"]["const"])
        evidence_properties = schema["properties"]["evidence"]["properties"]
        self.assertEqual(
            registry.FROZEN_B279_MAPPED_SUMMARY,
            evidence_properties["mapped_summary"]["const"],
        )
        self.assertEqual(
            registry.FAILED_F5F2_STATUS,
            evidence_properties["latest_mapped_attempt"]["const"],
        )

    def test_architecture_policy_hash_excludes_evidence_pointer(self) -> None:
        changed_pointer = copy.deepcopy(self.catalog)
        changed_pointer["evidence"]["mapped_summary"] = (
            ".github/task-runs/new-run/evidence/new-summary.json"
        )
        self.assertNotEqual(
            registry.canonical_sha256(self.catalog),
            registry.canonical_sha256(changed_pointer),
        )
        self.assertEqual(
            registry.architecture_policy_sha256(self.catalog),
            registry.architecture_policy_sha256(changed_pointer),
        )

    def test_run_parameter_artifact_rejects_configuration_drift(self) -> None:
        result_root = (
            registry.REPO_ROOT
            / ".github/runtime-artifacts/test-architecture-registry/run/sta"
        )
        text = registry.render_run_parameters(
            self.catalog,
            registry.BPU_LOCAL_PHT_WRITE_BANKED_FLAT_READ_VIEW_INLINE_CONFIGURATION,
            expected_rtl_design_id=registry.EXPECTED_LIVE_DESIGN_ID,
            result_root=str(result_root),
        )
        expected_keep_hierarchy = " ".join(
            self.catalog["run_parameter_contract"]["keep_hierarchy_modules"]
            + registry.EXPECTED_BANKED_CHILD_KEEP_HIERARCHY_ADDITIONS
        )
        self.assertIn(
            f"keep_hierarchy_modules={expected_keep_hierarchy}\n",
            text,
        )
        self.assertIn(
            "mapped_artifact_profile=bpu-local-pht-v1\n",
            text,
        )
        with tempfile.TemporaryDirectory() as temp:
            parameters = Path(temp) / "parameters.txt"
            parameters.write_text(text, encoding="utf-8")
            self.assertEqual(
                [],
                registry.run_parameter_artifact_errors(
                    self.catalog,
                    registry.BPU_LOCAL_PHT_WRITE_BANKED_FLAT_READ_VIEW_INLINE_CONFIGURATION,
                    expected_rtl_design_id=registry.EXPECTED_LIVE_DESIGN_ID,
                    parameters_path=parameters,
                ),
            )
            parameters.write_text(
                text.replace("period_ns=5.0", "period_ns=4.0"),
                encoding="utf-8",
            )
            errors = registry.run_parameter_artifact_errors(
                self.catalog,
                registry.BPU_LOCAL_PHT_WRITE_BANKED_FLAT_READ_VIEW_INLINE_CONFIGURATION,
                expected_rtl_design_id=registry.EXPECTED_LIVE_DESIGN_ID,
                parameters_path=parameters,
            )
            self.assertTrue(any("period_ns" in error for error in errors), errors)

            parameters.write_text(
                text.replace(
                    "mapped_artifact_profile=bpu-local-pht-v1",
                    "mapped_artifact_profile=none",
                ),
                encoding="utf-8",
            )
            errors = registry.run_parameter_artifact_errors(
                self.catalog,
                registry.BPU_LOCAL_PHT_WRITE_BANKED_FLAT_READ_VIEW_INLINE_CONFIGURATION,
                expected_rtl_design_id=registry.EXPECTED_LIVE_DESIGN_ID,
                parameters_path=parameters,
            )
            self.assertTrue(
                any("mapped_artifact_profile" in error for error in errors), errors
            )

            changed_policy = copy.deepcopy(self.catalog)
            changed_policy["owners"]["rv64-bpu"]["responsibility"] += " drift"
            policy_errors = registry.run_parameter_artifact_errors(
                changed_policy,
                registry.BPU_LOCAL_PHT_WRITE_BANKED_FLAT_READ_VIEW_INLINE_CONFIGURATION,
                expected_rtl_design_id=registry.EXPECTED_LIVE_DESIGN_ID,
                parameters_path=parameters,
            )
            self.assertTrue(
                any("architecture_policy_sha256" in error for error in policy_errors),
                policy_errors,
            )

        with self.assertRaises(registry.RegistryError):
            registry.require_expected_rtl_design_id(
                self.catalog,
                expected="sha256:" + "0" * 64,
                actual=registry.EXPECTED_LIVE_DESIGN_ID,
            )

    def test_raw_synth_stat_macro_census_is_independent(self) -> None:
        with tempfile.TemporaryDirectory() as temp:
            synth_stat = Path(temp) / "synth_stat.txt"
            synth_stat.write_text(
                "old section\n=== design hierarchy ===\n"
                "  1  -  Sram4096x199\n"
                "  2  -  Sram4096x113\n"
                "  1  -  OooFpArithGate\n"
                "  10  10.0  OTHER\n",
                encoding="utf-8",
            )
            census, errors = registry.synth_stat_unknown_macro_instances(
                synth_stat,
                boundary_modules=set(self.catalog["physical_boundaries"]),
            )
            self.assertEqual([], errors)
            self.assertEqual(
                self.catalog["physical_configurations"][
                    registry.BPU_INLINE_CONFIGURATION
                ]["expected_unknown_macro_instances"],
                census,
            )

    def test_mapped_binding_rejects_missing_identity_and_projection_drift(self) -> None:
        sources = {"npc/rv64/vsrc/core/NpcTop.v": "a" * 64}
        configuration_id = registry.BPU_INLINE_CONFIGURATION
        configuration = self.catalog["physical_configurations"][configuration_id]
        projection = registry.mapped_projection(self.catalog, configuration_id)
        summary = {
            "status": "PASS",
            "mapped_artifact_profile": projection["mapped_artifact_profile"],
            "actual_synthesis_source_sha256": sources,
            "synthesis": {
                "area": {
                    "unknown_macro_instances": projection[
                        "expected_unknown_macro_instances"
                    ]
                }
            },
            "architecture_registry_binding": {
                "schema": registry.MAPPED_BINDING_SCHEMA,
                "design_id": "sha256:live",
                "synthesis_sources_sha256": registry.canonical_sha256(sources),
                "source_manifest_sha256": "c" * 64,
                "production_manifest_before_sha256": "d" * 64,
                "production_manifest_after_sha256": "d" * 64,
                "architecture_policy_sha256": "e" * 64,
                "physical_configuration_id": configuration_id,
                "physical_configuration_sha256": (
                    registry.physical_configuration_sha256(
                        configuration_id, configuration
                    )
                ),
                "mapped_projection": projection,
                "mapped_projection_sha256": registry.canonical_sha256(projection),
                "mapped_artifact_profile": projection["mapped_artifact_profile"],
                "mapped_profile_evidence_sha256": "7" * 64,
                "run_parameter_contract_sha256": "f" * 64,
                "parameters_sha256": "1" * 64,
                "sta_input_manifest_sha256": "2" * 64,
                "evidence_artifacts_sha256": "3" * 64,
            },
        }
        common = {
            "live_design_id": "sha256:live",
            "current_sources": sources,
            "policy_sha256": "e" * 64,
            "physical_configuration_id": configuration_id,
            "physical_configuration_digest": (
                registry.physical_configuration_sha256(
                    configuration_id, configuration
                )
            ),
            "projection": projection,
            "mapped_artifact_profile": projection["mapped_artifact_profile"],
            "mapped_profile_evidence_sha256": "7" * 64,
            "source_manifest_sha256": "c" * 64,
            "production_manifest_before_sha256": "d" * 64,
            "production_manifest_after_sha256": "d" * 64,
            "run_parameter_contract_sha256": "f" * 64,
            "parameters_sha256": "1" * 64,
            "sta_input_manifest_sha256": "2" * 64,
            "evidence_artifacts_sha256": "3" * 64,
        }
        self.assertEqual([], registry.mapped_binding_errors(summary, **common))
        missing_identity = copy.deepcopy(summary)
        del missing_identity["architecture_registry_binding"]["design_id"]
        self.assertTrue(registry.mapped_binding_errors(missing_identity, **common))
        stale_projection = copy.deepcopy(summary)
        stale_projection["architecture_registry_binding"][
            "mapped_projection_sha256"
        ] = "f" * 64
        errors = registry.mapped_binding_errors(stale_projection, **common)
        self.assertTrue(any("projection hash" in error for error in errors), errors)
        stale_configuration = copy.deepcopy(summary)
        stale_configuration["architecture_registry_binding"][
            "physical_configuration_sha256"
        ] = "8" * 64
        errors = registry.mapped_binding_errors(stale_configuration, **common)
        self.assertTrue(any("configuration hash" in error for error in errors), errors)
        stale_profile = copy.deepcopy(summary)
        stale_profile["architecture_registry_binding"][
            "mapped_artifact_profile"
        ] = registry.MAPPED_ARTIFACT_PROFILE_BPU_LOCAL_PHT
        errors = registry.mapped_binding_errors(stale_profile, **common)
        self.assertTrue(any("artifact profile" in error for error in errors), errors)
        stale_profile_evidence = copy.deepcopy(summary)
        stale_profile_evidence["architecture_registry_binding"][
            "mapped_profile_evidence_sha256"
        ] = "6" * 64
        errors = registry.mapped_binding_errors(stale_profile_evidence, **common)
        self.assertTrue(any("profile evidence" in error for error in errors), errors)
        bpu_residual = copy.deepcopy(summary)
        residual_projection = bpu_residual["architecture_registry_binding"][
            "mapped_projection"
        ]
        residual_projection["blackbox_modules"].append(
            "OooBranchDirectionPredictor"
        )
        residual_projection["inline_modules"] = []
        residual_projection["macro_lib_files"].append(
            {
                "path": self.catalog["physical_boundaries"][
                    "OooBranchDirectionPredictor"
                ]["liberty"],
                "sha256": "9" * 64,
            }
        )
        bpu_residual["architecture_registry_binding"][
            "mapped_projection_sha256"
        ] = registry.canonical_sha256(residual_projection)
        errors = registry.mapped_binding_errors(bpu_residual, **common)
        self.assertTrue(
            any("blackbox/inline/Liberty" in error for error in errors), errors
        )
        stale_sources = copy.deepcopy(summary)
        stale_sources["actual_synthesis_source_sha256"] = {
            "npc/rv64/vsrc/core/NpcTop.v": "f" * 64
        }
        errors = registry.mapped_binding_errors(stale_sources, **common)
        self.assertTrue(any("source set is stale" in error for error in errors), errors)
        stale_parameters = copy.deepcopy(summary)
        stale_parameters["architecture_registry_binding"]["parameters_sha256"] = (
            "4" * 64
        )
        errors = registry.mapped_binding_errors(stale_parameters, **common)
        self.assertTrue(any("parameters artifact" in error for error in errors), errors)
        stale_sta_manifest = copy.deepcopy(summary)
        stale_sta_manifest["architecture_registry_binding"][
            "sta_input_manifest_sha256"
        ] = "5" * 64
        errors = registry.mapped_binding_errors(stale_sta_manifest, **common)
        self.assertTrue(any("STA input manifest" in error for error in errors), errors)
        stale_artifacts = copy.deepcopy(summary)
        stale_artifacts["architecture_registry_binding"][
            "evidence_artifacts_sha256"
        ] = "6" * 64
        errors = registry.mapped_binding_errors(stale_artifacts, **common)
        self.assertTrue(any("evidence artifact" in error for error in errors), errors)
        stale_census = copy.deepcopy(summary)
        stale_census["synthesis"]["area"]["unknown_macro_instances"][
            "OooBranchDirectionPredictor"
        ] = 1
        errors = registry.mapped_binding_errors(stale_census, **common)
        self.assertTrue(any("macro census" in error for error in errors), errors)

    def test_production_manifest_is_rechecked_against_current_inputs(self) -> None:
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            production_input = root / "config"
            production_input.write_text("before\n", encoding="utf-8")
            manifest = root / "production.sha256"
            manifest.write_text(
                f"{registry.sha256_file(production_input)}  {production_input}\n",
                encoding="utf-8",
            )
            self.assertEqual([], registry.verify_sha256_manifest(manifest)["errors"])
            production_input.write_text("after\n", encoding="utf-8")
            errors = registry.verify_sha256_manifest(manifest)["errors"]
            self.assertTrue(any("production input drifted" in error for error in errors))

    def test_production_manifest_rejects_duplicate_and_noncanonical_records(
        self,
    ) -> None:
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            production_input = root / "config"
            production_input.write_text("stable\n", encoding="utf-8")
            record = (
                f"{registry.sha256_file(production_input)}  {production_input}\n"
            )

            duplicate_manifest = root / "duplicate.sha256"
            duplicate_manifest.write_text(record + record, encoding="utf-8")
            duplicate_errors = registry.verify_sha256_manifest(
                duplicate_manifest
            )["errors"]
            self.assertTrue(
                any("duplicates input" in error for error in duplicate_errors),
                duplicate_errors,
            )

            relative_manifest = root / "relative.sha256"
            relative_manifest.write_text(
                f"{registry.sha256_file(production_input)}  config\n",
                encoding="utf-8",
            )
            relative_errors = registry.verify_sha256_manifest(relative_manifest)[
                "errors"
            ]
            self.assertTrue(
                any("non-canonical" in error for error in relative_errors),
                relative_errors,
            )

    def test_fp_ooc_constant_output_bit_model_contract_fail_closed(self) -> None:
        projection = registry.mapped_projection(
            self.catalog,
            registry.FP_ARITH_PRODUCTION_CHILDREN_OOC_BOUNDARY_CONFIGURATION,
        )
        model = projection["ooc_model_contract"]
        self.assertEqual(
            "retained_unique_driver_plus_bound_stdlib_output_pin_function",
            model["output_bit_classification_source"],
        )
        self.assertEqual(
            ["DYNAMIC", "CONSTANT_0", "CONSTANT_1"],
            model["output_bit_classes"],
        )
        self.assertEqual(
            "real_register_q_path_required",
            model["dynamic_output_path_policy"],
        )
        self.assertEqual(
            "zero_register_q_paths_required",
            model["constant_output_path_policy"],
        )
        self.assertEqual(
            "forbidden", model["constant_inference_from_missing_path"]
        )
        self.assertEqual(
            "none_or_isolated_tied_off_true_without_ordinary_timing",
            model["literal_output_timing_group_policy"],
        )
        self.assertEqual(
            "nested_literal_and_top_propagated_constant_no_sdc_seed_"
            "dynamic_reg_clk_to_q",
            model["focused_generated_macro_oracle"],
        )
        self.assertEqual(
            "dynamic_state_function_rising_edge_xor_literal_constant_function",
            model["liberty_output_member_policy"],
        )
        self.assertEqual(
            "derived_from_dynamic_bits_only",
            model["family_timing_summary_policy"],
        )
        self.assertEqual(
            {
                "register_d_endpoints": 608,
                "nonclock_input_bits": 134,
                "output_bits": 138,
                "dynamic_output_bits": 136,
                "find_calls": 273,
                "path_end_limit": 2364,
                "validation_limit": 2364,
            },
            model["child_query_budget"]["current_addsub"],
        )
        paths = {
            "runner": registry.REPO_ROOT / "npc/rv64/eval/ppa/run-fp-ooc-composite-current.sh",
            "child_yosys": registry.REPO_ROOT / "npc/rv64/eval/ppa/yosys-fp-ooc-child.tcl",
            "child_sta": registry.REPO_ROOT / "npc/rv64/eval/ppa/opensta-fp-ooc-child.tcl",
            "top_sta": registry.REPO_ROOT / "npc/rv64/eval/ppa/opensta-fp-ooc-top.tcl",
            "parser": registry.REPO_ROOT / "npc/rv64/eval/ppa/tools/fp_ooc_composite.py",
            "schema": registry.REPO_ROOT / "npc/rv64/eval/ppa/schemas/fp-ooc-composite-v1.schema.json",
        }
        sources = {
            name: path.read_text(encoding="utf-8") for name, path in paths.items()
        }

        def errors(overrides: dict[str, str] | None = None) -> list[str]:
            selected = dict(sources)
            selected.update(overrides or {})
            return registry.fp_ooc_composite_tool_contract_errors(
                selected["runner"], selected["child_yosys"],
                selected["child_sta"], selected["top_sta"],
                selected["parser"], selected["schema"],
            )

        self.assertEqual([], errors())
        mutations = {
            "runner-driver-contract": (
                "runner", 'stage="child-${module}-output-bit-driver-contract"'
            ),
            "child-constant-zero-path": (
                "child_sta",
                "structurally constant output has a register-Q timing path",
            ),
            "child-dynamic-real-path": (
                "child_sta", "dynamic output has no real register-Q timing path"
            ),
            "child-budget-wrapper": (
                "child_sta", "proc budgeted_find_timing_paths"
            ),
            "child-output-bulk": (
                "child_sta", "proc collect_output_timing_bulk"
            ),
            "runner-query-progress": (
                "runner", 'query_progress_path="${child_dir}/child-query-progress-${analysis}.tsv"'
            ),
            "parser-query-progress": (
                "parser", "def parse_query_progress("
            ),
            "schema-query-budget": (
                "schema", '"queryBudget"'
            ),
            "top-constant-nonoverride": (
                "top_sta", "never receive a synthetic top-level timing"
            ),
            "parser-structural-oracle": (
                "parser", "build_output_bit_driver_contract"
            ),
            "parser-structured-literal-timing": (
                "parser", "_validate_literal_output_timing_groups"
            ),
            "parser-whitespace-invariant-groups": (
                "parser", "_extract_liberty_group_blocks"
            ),
            "parser-isolated-tied-off-policy": (
                "parser", "literal stdlib output timing must be an isolated"
            ),
            "parser-tied-off-si-allowlist": (
                "parser",
                "literal stdlib tied_off group carries unsupported or ordinary semantics",
            ),
            "parser-bitwise-liberty": (
                "parser", 'pin ({name}[{index}])'
            ),
            "parser-complete-bit-partition": (
                "parser", "validate_output_bit_driver_partition"
            ),
            "parser-dynamic-state-function": (
                "parser", "_dynamic_state_name"
            ),
            "parser-mixed-bus-inheritance": (
                "parser", "carries inherited behavior"
            ),
            "schema-bit-inventory": (
                "schema", '"outputBitTimingRecord"'
            ),
            "schema-driver-contract": (
                "schema", '"outputBitDriverContract"'
            ),
        }
        for label, (source_name, marker) in mutations.items():
            self.assertIn(marker, sources[source_name], label)
            damaged = sources[source_name].replace(marker, "")
            with self.subTest(label=label):
                self.assertTrue(errors({source_name: damaged}))

    def test_fp_ooc_tcl_row_projection_contract_fail_closed(self) -> None:
        configuration_id = (
            registry.FP_ARITH_PRODUCTION_CHILDREN_OOC_BOUNDARY_CONFIGURATION
        )
        projection = registry.mapped_projection(self.catalog, configuration_id)
        expected = {
            "encoding": "outer_list_of_brace_quoted_row_lists",
            "atom_policy": "nonempty_ascii_safe_no_brace_or_backslash",
            "child_output_bit_driver": {
                "fields": [
                    "family", "index", "opensta_object_name", "classification",
                    "constant_value", "driver_binding_sha256",
                ],
                "row_count": "sum_registered_output_widths",
            },
            "top_boundary": {
                "fields": [
                    "path_class", "source_instance_path", "source_object_class",
                    "source_port_family_widths", "endpoint_kind",
                    "endpoint_instance_path", "endpoint_object_class",
                    "endpoint_family_widths",
                ],
                "row_count": 5,
            },
        }
        self.assertEqual(
            expected,
            projection["ooc_model_contract"]["tcl_row_projection_contract"],
        )
        schema = registry.load_json(registry.SCHEMA_PATH)
        schema_contract = schema["properties"]["physical_configurations"][
            "properties"
        ][configuration_id]["properties"]["ooc_model_contract"]["const"]
        self.assertEqual(
            expected, schema_contract["tcl_row_projection_contract"]
        )
        sources = {
            "parser": (
                registry.REPO_ROOT
                / "npc/rv64/eval/ppa/tools/fp_ooc_composite.py"
            ).read_text(encoding="utf-8"),
            "child": (
                registry.REPO_ROOT
                / "npc/rv64/eval/ppa/opensta-fp-ooc-child.tcl"
            ).read_text(encoding="utf-8"),
            "top": (
                registry.REPO_ROOT
                / "npc/rv64/eval/ppa/opensta-fp-ooc-top.tcl"
            ).read_text(encoding="utf-8"),
        }
        for source, marker in (
            ("parser", "def render_tcl_row_table("),
            ("parser", "def validate_tcl_row_table("),
            ("parser", "TCL_SAFE_ATOM_RE"),
            (
                "child",
                "[llength $::fp_ooc_output_bit_driver_contract] != $expected",
            ),
            ("child", "if {[llength $row] != 6}"),
            ("top", "[llength $fp_ooc_boundary_contract] != 5"),
            ("top", "if {[llength $contract] != 8}"),
        ):
            with self.subTest(source=source, marker=marker):
                self.assertIn(marker, sources[source])

        for label, path, value in (
            (
                "child-field-count",
                ("child_output_bit_driver", "fields"),
                expected["child_output_bit_driver"]["fields"][:-1],
            ),
            ("top-row-count", ("top_boundary", "row_count"), 4),
            ("unsafe-atom-policy", ("atom_policy",), "brace_escape_allowed"),
        ):
            damaged = copy.deepcopy(self.catalog)
            target = damaged["physical_configurations"][configuration_id][
                "ooc_model_contract"
            ]["tcl_row_projection_contract"]
            for key in path[:-1]:
                target = target[key]
            target[path[-1]] = value
            with self.subTest(mutation=label):
                errors = registry.validate_catalog(damaged)
                self.assertTrue(
                    any("OOC model contract drifted" in error for error in errors),
                    errors,
                )

    def test_runner_arguments_must_equal_catalog_projection(self) -> None:
        projection = {
            "mapped_artifact_profile": "none",
            "blackbox_modules": ["Macro"],
            "inline_modules": ["Inline"],
            "macro_lib_files": [{"path": "macro.lib", "sha256": "a" * 64}],
        }
        self.assertEqual(
            [],
            registry.projection_argument_errors(
                projection,
                mapped_artifact_profile="none",
                blackbox_modules=["Macro"],
                inline_modules=["Inline"],
                macro_lib_files=["macro.lib"],
            ),
        )
        errors = registry.projection_argument_errors(
            projection,
            mapped_artifact_profile="fp-arith-children-v1",
            blackbox_modules=["Other"],
            inline_modules=["OtherInline"],
            macro_lib_files=["other.lib"],
        )
        self.assertEqual(4, len(errors))


if __name__ == "__main__":
    unittest.main()
