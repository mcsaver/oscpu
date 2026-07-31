#!/usr/bin/env python3
"""Positive and fail-closed tests for holder instance-graph evidence."""

from __future__ import annotations

import json
import os
import sys
import tempfile
import unittest
from pathlib import Path
from unittest import mock


TEST_DIR = Path(__file__).resolve().parent
RV64_DIR = TEST_DIR.parents[2]
TOOLS_DIR = RV64_DIR / "eval/ppa/tools"
sys.path.insert(0, str(TOOLS_DIR))

import producer_holder_instance_graph as graph  # noqa: E402


class ProducerHolderInstanceGraphTests(unittest.TestCase):
    def setUp(self) -> None:
        self.temp = tempfile.TemporaryDirectory(
            prefix="producer-holder-instance-graph-"
        )
        self.repo = Path(self.temp.name) / "repo"
        self.manifest = (
            self.repo / "npc/rv64/design/arch/producer-holder-census.json"
        )
        self.yosys_json = self.repo / "evidence/yosys.json"
        self.result_path = (
            self.repo / graph.CANONICAL_EVIDENCE_PATHS["result"]
        )
        self.receipt_path = (
            self.repo / graph.CANONICAL_EVIDENCE_PATHS["receipt"]
        )
        self.full_path = self.repo / graph.CANONICAL_EVIDENCE_PATHS["full"]
        self.script_path = (
            self.repo / graph.CANONICAL_EVIDENCE_PATHS["script"]
        )
        self.log_path = self.repo / graph.CANONICAL_EVIDENCE_PATHS["log"]
        self._write(
            "npc/rv64/vsrc/core/NpcTop.v",
            "module NpcTop; Core u_core(); endmodule\n",
        )
        self._write(
            "npc/rv64/vsrc/core/Core.v",
            "module Core; HolderA u_a(); HolderB u_b0(); "
            "HolderB u_b1(); endmodule\n",
        )
        self._write(
            "npc/rv64/vsrc/holder/HolderA.v",
            "module HolderA; endmodule\n",
        )
        self._write(
            "npc/rv64/vsrc/holder/HolderB.v",
            "module HolderB; endmodule\n",
        )
        self._write(
            graph.CONFIG_PATH,
            "NPC_PRODUCT_RTL_CONFIG_SCHEMA := "
            "npc-rv64-product-rtl-config-v1\n"
            "OOO_CSR_QUEUE_HEAD ?= 1\n"
            "OOO_TERMINAL_HOLDER_ASSERT ?= 1\n",
        )
        self._write(
            graph.MAKEFILE_PATH,
            "print-synth-rtl:\n"
            "\t@printf '%s\\n' "
            "$(CURDIR)/vsrc/core/NpcTop.v "
            "$(CURDIR)/vsrc/core/Core.v "
            "$(CURDIR)/vsrc/holder/HolderA.v "
            "$(CURDIR)/vsrc/holder/HolderB.v\n",
        )
        self.fake_yosys = self._write(
            "oss-cad-suite/bin/yosys",
            "#!/bin/sh\nprintf '%s\\n' 'Yosys fixture 1.0'\n",
        )
        self.fake_yosys.chmod(0o755)
        source_sha, _ = graph.rtl_binding(self.repo)
        self.manifest_value = {
            "schema_version": "rv64-producer-holder-census-v1",
            "design_id": f"sha256:{source_sha}",
            "direct_full_p_fields": [
                {"module": "HolderA"},
                {"module": "HolderB"},
            ],
            "combinational_full_p_regs": [],
            "generation_authorities": [],
            "token_q_fields": [],
            "packed_full_p_stages": [],
            "token_set_holders": [],
            "elaborated_instance_graph": {
                "schema_version": graph.SCHEMA,
                "top_module": graph.TOP_MODULE,
                "product_config": graph.config_binding(self.repo),
                "instances": [
                    {
                        "module": "HolderA",
                        "path": "NpcTop.u_core.u_a",
                    },
                    {
                        "module": "HolderB",
                        "path": "NpcTop.u_core.u_b0",
                    },
                    {
                        "module": "HolderB",
                        "path": "NpcTop.u_core.u_b1",
                    },
                ],
                "evidence": {
                    "result": {
                        "kind": graph.EVIDENCE_KINDS["result"],
                        "path": graph.CANONICAL_EVIDENCE_PATHS["result"],
                        "sha256": "0" * 64,
                    },
                    "receipt": {
                        "kind": graph.EVIDENCE_KINDS["receipt"],
                        "path": graph.CANONICAL_EVIDENCE_PATHS["receipt"],
                        "sha256": "0" * 64,
                    },
                    "full": {
                        "kind": graph.EVIDENCE_KINDS["full"],
                        "path": graph.CANONICAL_EVIDENCE_PATHS["full"],
                        "sha256": "0" * 64,
                    },
                    "script": {
                        "kind": graph.EVIDENCE_KINDS["script"],
                        "path": graph.CANONICAL_EVIDENCE_PATHS["script"],
                        "sha256": "0" * 64,
                    },
                    "log": {
                        "kind": graph.EVIDENCE_KINDS["log"],
                        "path": graph.CANONICAL_EVIDENCE_PATHS["log"],
                        "sha256": "0" * 64,
                    },
                },
            },
        }
        self._write_json(self.manifest, self.manifest_value)
        self._write_json(
            self.yosys_json,
            {
                "modules": {
                    "NpcTop": {
                        "cells": {
                            "u_core": {"type": "Core"},
                        },
                    },
                    "Core": {
                        "cells": {
                            "u_a": {
                                "type": "$paramod$1234567890\\HolderA",
                            },
                            "u_b0": {
                                "type": "$paramod\\HolderB\\DEPTH=s32'1",
                            },
                            "u_b1": {
                                "type": "$paramod\\HolderB\\DEPTH=s32'1",
                            },
                        },
                    },
                    "$paramod$1234567890\\HolderA": {"cells": {}},
                    "$paramod\\HolderB\\DEPTH=s32'1": {"cells": {}},
                },
            },
        )

    def tearDown(self) -> None:
        self.temp.cleanup()

    def _write(self, relative: str, text: str) -> Path:
        path = self.repo / relative
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(text, encoding="utf-8")
        return path

    @staticmethod
    def _write_json(path: Path, value: dict) -> None:
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(
            json.dumps(value, ensure_ascii=False, indent=2, sort_keys=True)
            + "\n",
            encoding="utf-8",
        )

    def provenance(
        self,
    ) -> tuple[dict, list[dict[str, str]], bytes, bytes]:
        source_records = graph.synth_source_records(self.repo)
        script = graph.canonical_yosys_script(source_records).encode("utf-8")
        log = b"fixture elaboration log\n"
        version_output = b"Yosys fixture 1.0\n"
        metadata = {
            "name": "yosys",
            "path": self.fake_yosys.relative_to(self.repo).as_posix(),
            "version": "Yosys fixture 1.0",
            "version_output_sha256": graph.sha256_bytes(version_output),
            "executable_sha256": graph.sha256_file(self.fake_yosys),
            "source_count": len(source_records),
        }
        return metadata, source_records, script, log

    def elaborate_audit(self) -> dict:
        self._write_json(self.manifest, self.manifest_value)
        metadata, source_records, script, log = self.provenance()
        full_yosys_json = graph.canonicalize_full_yosys_json(
            self.yosys_json.read_bytes()
        )
        return graph.audit_elaborated(
            self.repo,
            self.manifest,
            self.yosys_json,
            elaborator=metadata,
            elaboration_sources=source_records,
            elaborator_full_json_sha256=graph.sha256_bytes(
                full_yosys_json
            ),
            elaborator_script_sha256=graph.sha256_bytes(script),
            elaborator_log_sha256=graph.sha256_bytes(log),
        )

    def freeze_baseline(self) -> dict:
        result = self.elaborate_audit()
        self.assertEqual(result["status"], "PASS", result["errors"])
        _, _, script, log = self.provenance()
        full_yosys_json = graph.canonicalize_full_yosys_json(
            self.yosys_json.read_bytes()
        )
        receipt = graph.build_receipt(result, full_yosys_json)
        self._write_json(self.result_path, result)
        self._write_json(self.receipt_path, receipt)
        self.full_path.write_bytes(
            graph.deterministic_gzip(full_yosys_json)
        )
        self.script_path.write_bytes(script)
        self.log_path.write_bytes(log)
        evidence = self.manifest_value["elaborated_instance_graph"]["evidence"]
        paths = {
            "result": self.result_path,
            "receipt": self.receipt_path,
            "full": self.full_path,
            "script": self.script_path,
            "log": self.log_path,
        }
        for role, path in paths.items():
            evidence[role]["sha256"] = graph.sha256_file(path)
        self._write_json(self.manifest, self.manifest_value)
        return result

    def test_parameterized_module_name_decode(self) -> None:
        self.assertEqual(
            graph.original_module_name("$paramod$0123\\HolderA"),
            "HolderA",
        )
        self.assertEqual(
            graph.original_module_name("$paramod\\HolderB\\DEPTH=s32'1"),
            "HolderB",
        )

    def test_full_json_normalizes_only_process_local_yosys_key_tokens(
        self,
    ) -> None:
        first = {
            "cells": {
                "$display$0x1111:7067$5": {"type": "$print"},
            },
            "netnames": {
                "$display$0x1111:7067$5_EN": {"bits": [1]},
            },
        }
        second = {
            "cells": {
                "$display$0xabcdef:7067$5": {"type": "$print"},
            },
            "netnames": {
                "$display$0xabcdef:7067$5_EN": {"bits": [1]},
            },
        }
        first_bytes = json.dumps(first).encode("utf-8")
        second_bytes = json.dumps(second).encode("utf-8")
        self.assertEqual(
            graph.canonicalize_full_yosys_json(first_bytes),
            graph.canonicalize_full_yosys_json(second_bytes),
        )

    def test_full_json_key_normalization_collision_fails_closed(
        self,
    ) -> None:
        value = {
            "$display$0x1111:7067$5": {},
            "$display$0x2222:7067$5": {},
        }
        with self.assertRaisesRegex(ValueError, "collision"):
            graph.canonicalize_full_yosys_json(
                json.dumps(value).encode("utf-8")
            )

    def test_source_list_is_stable_under_parent_make_directory_tracing(
        self,
    ) -> None:
        with mock.patch.dict(os.environ, {"MAKEFLAGS": "w"}, clear=False):
            records = graph.synth_source_records(self.repo)
        self.assertEqual(len(records), 4)
        self.assertEqual(
            [row["path"] for row in records],
            [
                "npc/rv64/vsrc/core/NpcTop.v",
                "npc/rv64/vsrc/core/Core.v",
                "npc/rv64/vsrc/holder/HolderA.v",
                "npc/rv64/vsrc/holder/HolderB.v",
            ],
        )

    def test_baseline_binds_all_duplicate_instances(self) -> None:
        result = self.elaborate_audit()
        self.assertEqual(result["status"], "PASS", result["errors"])
        self.assertEqual(result["counts"]["holder_modules"], 2)
        self.assertEqual(result["counts"]["holder_instances"], 3)
        self.assertEqual(result["counts"]["duplicate_holder_modules"], 1)
        self.assertEqual(result["instance_counts"], {
            "HolderA": 1,
            "HolderB": 2,
        })

    def test_added_live_duplicate_instance_fails_closed(self) -> None:
        self.manifest_value["elaborated_instance_graph"]["instances"].pop()
        result = self.elaborate_audit()
        self.assertEqual(result["status"], "FAIL")
        self.assertIn(
            "undeclared live holder instance: "
            "HolderB::NpcTop.u_core.u_b1",
            result["errors"],
        )

    def test_stale_declared_instance_fails_closed(self) -> None:
        self.manifest_value["elaborated_instance_graph"]["instances"].append({
            "module": "HolderA",
            "path": "NpcTop.u_core.u_missing",
        })
        result = self.elaborate_audit()
        self.assertEqual(result["status"], "FAIL")
        self.assertIn(
            "stale/nonexistent holder instance: "
            "HolderA::NpcTop.u_core.u_missing",
            result["errors"],
        )

    def test_holder_module_without_declaration_fails_closed(self) -> None:
        rows = self.manifest_value["elaborated_instance_graph"]["instances"]
        self.manifest_value["elaborated_instance_graph"]["instances"] = [
            row for row in rows if row["module"] != "HolderA"
        ]
        result = self.elaborate_audit()
        self.assertEqual(result["status"], "FAIL")
        self.assertIn(
            "census holder module lacks declared instance: HolderA",
            result["errors"],
        )

    def test_frozen_baseline_recomputes_bindings(self) -> None:
        self.freeze_baseline()
        result = graph.audit_frozen(self.repo, self.manifest)
        self.assertEqual(result["status"], "PASS", result["errors"])
        self.assertEqual(result["counts"]["holder_instances"], 3)

    def test_frozen_source_drift_fails_closed(self) -> None:
        self.freeze_baseline()
        self._write(
            "npc/rv64/vsrc/holder/HolderA.v",
            "module HolderA; wire drift; endmodule\n",
        )
        result = graph.audit_frozen(self.repo, self.manifest)
        self.assertEqual(result["status"], "FAIL")
        self.assertTrue(any(
            "source" in error or "design_id" in error
            for error in result["errors"]
        ))

    def test_frozen_product_config_drift_fails_closed(self) -> None:
        self.freeze_baseline()
        self._write(
            graph.CONFIG_PATH,
            "NPC_PRODUCT_RTL_CONFIG_SCHEMA := "
            "npc-rv64-product-rtl-config-v1\n"
            "OOO_CSR_QUEUE_HEAD ?= 0\n"
            "OOO_TERMINAL_HOLDER_ASSERT ?= 1\n",
        )
        result = graph.audit_frozen(self.repo, self.manifest)
        self.assertEqual(result["status"], "FAIL")
        self.assertTrue(any(
            "product config" in error for error in result["errors"]
        ))

    def test_frozen_makefile_non_elaboration_edit_remains_bound(self) -> None:
        self.freeze_baseline()
        makefile = self.repo / graph.MAKEFILE_PATH
        self._write(
            graph.MAKEFILE_PATH,
            makefile.read_text(encoding="utf-8")
            + "# semantic-evidence pointer only\n",
        )
        result = graph.audit_frozen(self.repo, self.manifest)
        self.assertEqual(result["status"], "PASS", result["errors"])

    def test_frozen_makefile_source_list_drift_fails_closed(self) -> None:
        self.freeze_baseline()
        self._write(
            graph.MAKEFILE_PATH,
            "print-synth-rtl:\n"
            "\t@printf '%s\\n' "
            "$(CURDIR)/vsrc/core/NpcTop.v "
            "$(CURDIR)/vsrc/core/Core.v "
            "$(CURDIR)/vsrc/holder/HolderA.v\n",
        )
        result = graph.audit_frozen(self.repo, self.manifest)
        self.assertEqual(result["status"], "FAIL")
        self.assertTrue(any(
            "source list" in error for error in result["errors"]
        ))

    def test_frozen_graph_payload_edit_fails_closed(self) -> None:
        result = self.freeze_baseline()
        result["graph"]["reachable_instances"].pop()
        self._write_json(self.result_path, result)
        evidence = self.manifest_value["elaborated_instance_graph"]["evidence"]
        evidence["result"]["sha256"] = graph.sha256_file(self.result_path)
        self._write_json(self.manifest, self.manifest_value)
        frozen = graph.audit_frozen(self.repo, self.manifest)
        self.assertEqual(frozen["status"], "FAIL")
        self.assertIn(
            "frozen reachable graph sha256 mismatch",
            frozen["errors"],
        )

    def test_null_elaborator_fails_closed(self) -> None:
        self._write_json(self.manifest, self.manifest_value)
        _, source_records, script, log = self.provenance()
        result = graph.audit_elaborated(
            self.repo,
            self.manifest,
            self.yosys_json,
            elaborator=None,
            elaboration_sources=source_records,
            elaborator_full_json_sha256=graph.sha256_bytes(
                graph.canonicalize_full_yosys_json(
                    self.yosys_json.read_bytes()
                )
            ),
            elaborator_script_sha256=graph.sha256_bytes(script),
            elaborator_log_sha256=graph.sha256_bytes(log),
        )
        self.assertEqual(result["status"], "FAIL")
        self.assertTrue(any(
            "bindings.elaborator" in error for error in result["errors"]
        ))

    def test_synchronized_result_and_declaration_delete_is_rejected_by_receipt(
        self,
    ) -> None:
        result = self.freeze_baseline()
        rows = self.manifest_value["elaborated_instance_graph"]["instances"]
        self.manifest_value["elaborated_instance_graph"]["instances"] = [
            row for row in rows
            if row["path"] != "NpcTop.u_core.u_b1"
        ]
        result["graph"]["reachable_instances"] = [
            row for row in result["graph"]["reachable_instances"]
            if row["path"] != "NpcTop.u_core.u_b1"
        ]
        result["graph"]["holder_instances"] = [
            row for row in result["graph"]["holder_instances"]
            if row["path"] != "NpcTop.u_core.u_b1"
        ]
        result["graph"]["sha256"] = graph.canonical_sha256(
            result["graph"]["reachable_instances"]
        )
        result["counts"]["holder_instances"] = 2
        result["counts"]["reachable_module_instances"] = 3
        result["counts"]["duplicate_holder_modules"] = 0
        result["instance_counts"]["HolderB"] = 1
        declaration = self.manifest_value["elaborated_instance_graph"]
        declaration_payload = {
            key: declaration[key]
            for key in (
                "schema_version", "top_module", "product_config", "instances"
            )
        }
        result["bindings"]["instance_declaration_sha256"] = (
            graph.canonical_sha256(declaration_payload)
        )
        self._write_json(self.result_path, result)
        evidence = declaration["evidence"]
        evidence["result"]["sha256"] = graph.sha256_file(self.result_path)
        self._write_json(self.manifest, self.manifest_value)

        frozen = graph.audit_frozen(self.repo, self.manifest)
        self.assertEqual(frozen["status"], "FAIL")
        self.assertIn(
            "frozen Yosys receipt reachable graph differs from result",
            frozen["errors"],
        )

    def test_synchronized_result_receipt_and_declaration_delete_is_rejected_by_full_json(
        self,
    ) -> None:
        result = self.freeze_baseline()
        receipt = graph.load_json(self.receipt_path)
        declaration = self.manifest_value["elaborated_instance_graph"]
        declaration["instances"] = [
            row for row in declaration["instances"]
            if row["path"] != "NpcTop.u_core.u_b1"
        ]
        for container, key in (
            (result["graph"], "reachable_instances"),
            (result["graph"], "holder_instances"),
            (receipt, "reachable_instances"),
        ):
            container[key] = [
                row for row in container[key]
                if row["path"] != "NpcTop.u_core.u_b1"
            ]
        result["graph"]["sha256"] = graph.canonical_sha256(
            result["graph"]["reachable_instances"]
        )
        result["counts"].update({
            "holder_instances": 2,
            "reachable_module_instances": 3,
            "duplicate_holder_modules": 0,
        })
        result["instance_counts"]["HolderB"] = 1
        declaration_payload = {
            key: declaration[key]
            for key in (
                "schema_version", "top_module", "product_config", "instances"
            )
        }
        result["bindings"]["instance_declaration_sha256"] = (
            graph.canonical_sha256(declaration_payload)
        )
        receipt["reachable_graph_sha256"] = graph.canonical_sha256(
            receipt["reachable_instances"]
        )
        self._write_json(self.result_path, result)
        self._write_json(self.receipt_path, receipt)
        evidence = declaration["evidence"]
        evidence["result"]["sha256"] = graph.sha256_file(self.result_path)
        evidence["receipt"]["sha256"] = graph.sha256_file(
            self.receipt_path
        )
        self._write_json(self.manifest, self.manifest_value)

        frozen = graph.audit_frozen(self.repo, self.manifest)
        self.assertEqual(frozen["status"], "FAIL")
        self.assertIn(
            "frozen result reachable graph differs from full Yosys JSON",
            frozen["errors"],
        )
        self.assertIn(
            "frozen Yosys receipt reachable graph differs from full JSON",
            frozen["errors"],
        )

    def test_same_bytes_at_noncanonical_evidence_path_fail_closed(
        self,
    ) -> None:
        self.freeze_baseline()
        copied = self.repo / "evidence/copied-result.json"
        copied.parent.mkdir(parents=True, exist_ok=True)
        copied.write_bytes(self.result_path.read_bytes())
        evidence = self.manifest_value["elaborated_instance_graph"]["evidence"]
        evidence["result"]["path"] = "evidence/copied-result.json"
        evidence["result"]["sha256"] = graph.sha256_file(copied)
        self._write_json(self.manifest, self.manifest_value)

        frozen = graph.audit_frozen(self.repo, self.manifest)
        self.assertEqual(frozen["status"], "FAIL")
        self.assertTrue(any(
            "evidence.result.path must equal" in error
            for error in frozen["errors"]
        ))

    def test_synchronized_script_hash_edit_still_fails_canonical_rebuild(
        self,
    ) -> None:
        result = self.freeze_baseline()
        receipt = graph.load_json(self.receipt_path)
        self.script_path.write_text(
            self.script_path.read_text(encoding="utf-8")
            + "# synchronized drift\n",
            encoding="utf-8",
        )
        drift_sha = graph.sha256_file(self.script_path)
        result["bindings"]["elaborator_script_sha256"] = drift_sha
        receipt["script_sha256"] = drift_sha
        self._write_json(self.result_path, result)
        self._write_json(self.receipt_path, receipt)
        evidence = self.manifest_value["elaborated_instance_graph"]["evidence"]
        evidence["result"]["sha256"] = graph.sha256_file(self.result_path)
        evidence["receipt"]["sha256"] = graph.sha256_file(self.receipt_path)
        evidence["script"]["sha256"] = drift_sha
        self._write_json(self.manifest, self.manifest_value)

        frozen = graph.audit_frozen(self.repo, self.manifest)
        self.assertEqual(frozen["status"], "FAIL")
        self.assertIn(
            "frozen Yosys script differs from canonical live source closure",
            frozen["errors"],
        )


if __name__ == "__main__":
    unittest.main(verbosity=2)
