#!/usr/bin/env python3
"""Fail-closed tests for local RV64 IFU-ACCESS-G1 evidence."""

from __future__ import annotations

import importlib.util
import json
import pathlib
import sys
import tempfile
import unittest
from unittest import mock


TOOLS = pathlib.Path(__file__).resolve().parents[1] / "tools"
REPO = TOOLS.parents[4]
sys.path.insert(0, str(TOOLS))

EVIDENCE_SPEC = importlib.util.spec_from_file_location(
    "ifu_access_evidence_under_test", TOOLS / "ifu_access_evidence.py")
assert EVIDENCE_SPEC is not None and EVIDENCE_SPEC.loader is not None
evidence = importlib.util.module_from_spec(EVIDENCE_SPEC)
sys.modules[EVIDENCE_SPEC.name] = evidence
EVIDENCE_SPEC.loader.exec_module(evidence)

FREEZE_SPEC = importlib.util.spec_from_file_location(
    "ifu_access_freeze_under_test", TOOLS / "arch_stable_freeze.py")
assert FREEZE_SPEC is not None and FREEZE_SPEC.loader is not None
freeze = importlib.util.module_from_spec(FREEZE_SPEC)
sys.modules[FREEZE_SPEC.name] = freeze
FREEZE_SPEC.loader.exec_module(freeze)

TASK = REPO / f".github/task-runs/{evidence.RUN_ID}"
FOCUSED = TASK / "evidence/focused/logs"
FOOTPRINT_LOG = FOCUSED / "tb_ooo_fetch_access_footprint.log"
ATTRS_LOG = FOCUSED / "tb_ooo_fetch_axi_access_attrs.log"
FIREWALL_LOG = FOCUSED / "tb_axi_exec_firewall.log"
LANE_LOG = FOCUSED / "tb_ooo_ifu_lane1_fault_owner.log"
DPI_LOG = TASK / "evidence/sized-dpi/run.log"
MODULE_SUMMARY = TASK / "evidence/module-aggregate/summary.txt"
VARIANT_SUMMARY = TASK / "evidence/mutations/summary.json"
RESULT = REPO / "npc/rv64/eval/ppa/evidence/ifu-access-current.json"
RAW_LOG = REPO / "npc/rv64/eval/ppa/evidence/ifu-access.log"
DISPATCH_FILE = REPO / evidence.CANONICAL_DISPATCH_FILE
RUNNER = evidence.variant_model


def write_json(path: pathlib.Path, value: dict) -> None:
    path.write_text(
        json.dumps(value, indent=2, sort_keys=True) + "\n",
        encoding="utf-8")


def ledger_entry(result_path: pathlib.Path = RESULT) -> tuple[dict, str]:
    result = json.loads(result_path.read_text(encoding="utf-8"))
    return ({
        "canonical_command": evidence.CANONICAL_COMMAND,
        "evidence": [
            {
                "kind": "ifu_access_result",
                "path": result_path.relative_to(REPO).as_posix(),
                "sha256": freeze.sha256_file(result_path),
            },
            {
                "kind": "raw_log",
                "path": RAW_LOG.relative_to(REPO).as_posix(),
                "sha256": freeze.sha256_file(RAW_LOG),
            },
        ],
    }, result["design_id"])


class IfuAccessEvidenceTests(unittest.TestCase):
    def test_live_focused_logs_are_exact(self) -> None:
        self.assertEqual(
            evidence.parse_footprint_log(FOOTPRINT_LOG),
            evidence.FOOTPRINT_METRICS)
        self.assertEqual(evidence.parse_attrs_log(ATTRS_LOG), evidence.ATTR_METRICS)
        self.assertEqual(
            evidence.parse_firewall_log(FIREWALL_LOG), evidence.FIREWALL_METRICS)
        self.assertEqual(evidence.parse_lane_log(LANE_LOG), evidence.LANE_METRICS)
        self.assertEqual(evidence.parse_dpi_log(DPI_LOG), evidence.DPI_METRICS)

    def test_footprint_summary_cut_is_rejected(self) -> None:
        text = FOOTPRINT_LOG.read_text(encoding="utf-8").replace(
            "[ACCESS-G1-MATRIX] footprint=4",
            "[ACCESS-G1-MATRIX] footprint=3",
            1,
        )
        with tempfile.TemporaryDirectory() as temp_name:
            path = pathlib.Path(temp_name) / "footprint.log"
            path.write_text(text, encoding="utf-8")
            with self.assertRaisesRegex(ValueError, "semantic inventory"):
                evidence.parse_footprint_log(path)

    def test_lane_owner_map_cut_is_rejected(self) -> None:
        text = LANE_LOG.read_text(encoding="utf-8").replace(
            "[ACCESS-G1-OWNER-MAP] rows=12 lane0=6 lane1=6",
            "[ACCESS-G1-OWNER-MAP] rows=11 lane0=6 lane1=5",
            1,
        )
        with tempfile.TemporaryDirectory() as temp_name:
            path = pathlib.Path(temp_name) / "lane.log"
            path.write_text(text, encoding="utf-8")
            with self.assertRaisesRegex(ValueError, "owner aggregate"):
                evidence.parse_lane_log(path)

    def test_dpi_guard_width_cut_is_rejected(self) -> None:
        text = DPI_LOG.read_text(encoding="utf-8").replace(
            "tail_addr=0x000000008000000e bytes=2",
            "tail_addr=0x000000008000000e bytes=8",
            1,
        )
        with tempfile.TemporaryDirectory() as temp_name:
            path = pathlib.Path(temp_name) / "dpi.log"
            path.write_text(text, encoding="utf-8")
            with self.assertRaisesRegex(ValueError, "guard-page"):
                evidence.parse_dpi_log(path)

    def test_normalizer_replaces_exact_transient_root(self) -> None:
        with tempfile.TemporaryDirectory(
            prefix="rv64-ifu-access-v9i.", dir="/tmp",
        ) as temp_name:
            transient = pathlib.Path(temp_name)
            raw = f"[COMPILE] {transient}/build/test.vvp\n"
            normalized = RUNNER.normalize_transient_paths(raw, transient)
            self.assertNotIn(str(transient), normalized)
            self.assertEqual(normalized.count(RUNNER.TRANSIENT_DIR_TOKEN), 1)

    def test_live_variants_reconstruct_and_reject(self) -> None:
        audit = evidence.validate_variants(REPO, VARIANT_SUMMARY)
        self.assertEqual(audit["required"], 19)
        self.assertEqual(audit["compile_success"], 19)
        self.assertEqual(audit["dynamic_rejected"], 19)
        self.assertEqual(
            sum(row["required"] for row in audit["by_source"].values()), 19)

    def test_live_module_aggregate_is_exact(self) -> None:
        aggregate = evidence.parse_module_aggregate(REPO, MODULE_SUMMARY)
        self.assertEqual(aggregate["required"], len(aggregate["tests"]))
        self.assertEqual(aggregate["passed"], aggregate["required"])

    def test_live_static_contract_is_bound(self) -> None:
        audit = evidence.validate_static_contract(REPO)
        self.assertTrue(audit["bridge_exact_exec_pmp_halfword"])
        self.assertTrue(audit["lane_owner_composition_matrix"])

    def test_canonical_make_dispatch_is_target_scoped(self) -> None:
        text = DISPATCH_FILE.read_text(encoding="utf-8")
        evidence.validate_canonical_make_dispatch(text)
        evidence.validate_canonical_make_dispatch(
            text + "\n.PHONY: unrelated-target\nunrelated-target:\n\t@true\n")
        with self.assertRaisesRegex(ValueError, "canonical Make dispatch"):
            evidence.validate_canonical_make_dispatch(
                text.replace(
                    evidence.CANONICAL_DISPATCH_BLOCK,
                    evidence.CANONICAL_DISPATCH_BLOCK.replace(
                        "run-focused.sh", "wrong-runner.sh"),
                    1,
                )
            )
        with self.assertRaisesRegex(ValueError, "canonical Make dispatch"):
            evidence.validate_canonical_make_dispatch(
                text
                + f"\n{evidence.CANONICAL_TARGET}:\n"
                + "\t@bash wrong-runner.sh\n"
            )

    def test_effective_make_dispatch_rejects_included_override(self) -> None:
        with tempfile.TemporaryDirectory() as temp_name:
            temp = pathlib.Path(temp_name)
            dispatch = pathlib.Path("ifu-evidence.mk")
            expected = f"bash ../../{evidence.CANONICAL_RUNNER}"
            (temp / dispatch).write_text(
                evidence.CANONICAL_DISPATCH_BLOCK + "\n",
                encoding="utf-8",
            )
            evidence.validate_effective_make_dispatch(
                temp, dispatch, evidence.CANONICAL_TARGET, expected)
            marker = temp / "runner-started.marker"
            (temp / "override.mk").write_text(
                f"$(file >{marker},unexpected)\n"
                f"{evidence.CANONICAL_TARGET}:\n"
                "\t@bash wrong-runner.sh\n",
                encoding="utf-8",
            )
            with (temp / dispatch).open("a", encoding="utf-8") as stream:
                stream.write("include override.mk\n")
            with self.assertRaisesRegex(ValueError, "restricted Make dispatch"):
                evidence.validate_effective_make_dispatch(
                    temp, dispatch, evidence.CANONICAL_TARGET, expected)
            self.assertFalse(marker.exists())

    def test_parse_time_make_constructs_are_rejected_without_execution(self) -> None:
        text = DISPATCH_FILE.read_text(encoding="utf-8")
        with tempfile.TemporaryDirectory() as temp_name:
            marker = pathlib.Path(temp_name) / "runner-started.marker"
            mutations = (
                text + f"\n$(shell touch {marker})\n",
                text + "\n$(eval check-ifu-access: ; @false)\n",
                text
                + "\nifeq ($(findstring n,$(MAKEFLAGS)),n)\n"
                + "dry-run-only:\n\t@true\nendif\n",
            )
            for mutation in mutations:
                with self.subTest(mutation=mutation.rsplit("\n", 2)[0][-48:]):
                    with self.assertRaisesRegex(
                        ValueError, "restricted Make dispatch",
                    ):
                        evidence.validate_canonical_make_dispatch(mutation)
                    self.assertFalse(marker.exists())

    def test_make_environment_injection_is_removed(self) -> None:
        with tempfile.TemporaryDirectory() as temp_name:
            temp = pathlib.Path(temp_name)
            dispatch = pathlib.Path("ifu-evidence.mk")
            expected = f"bash ../../{evidence.CANONICAL_RUNNER}"
            (temp / dispatch).write_text(
                evidence.CANONICAL_DISPATCH_BLOCK + "\n",
                encoding="utf-8",
            )
            marker = temp / "injected.marker"
            injected = temp / "injected.mk"
            injected.write_text(
                f"$(file >{marker},unexpected)\n", encoding="utf-8")
            with mock.patch.dict(evidence.os.environ, {
                "MAKEFILES": str(injected),
                "GNUMAKEFLAGS": f"-f {injected}",
                "MAKEFLAGS": "--eval=forced:=1",
                "MFLAGS": "-n",
                "MAKELEVEL": "9",
            }):
                evidence.validate_effective_make_dispatch(
                    temp, dispatch, evidence.CANONICAL_TARGET, expected)
            self.assertFalse(marker.exists())

    def test_arch_stable_validator_accepts_live_evidence(self) -> None:
        entry, design_id = ledger_entry()
        self.assertEqual(
            freeze.validate_ifu_access_debt(REPO, entry, design_id), [])

    def test_arch_stable_validator_rejects_owner_row_cut(self) -> None:
        value = json.loads(RESULT.read_text(encoding="utf-8"))
        value["metrics"]["lane_owner"]["owner_map_rows"] = 11
        with tempfile.TemporaryDirectory(
            dir=REPO / ".github/task-runs", prefix=".ifu-access-validator-",
        ) as temp_name:
            path = pathlib.Path(temp_name) / "result.json"
            write_json(path, value)
            entry, design_id = ledger_entry(path)
            errors = freeze.validate_ifu_access_debt(REPO, entry, design_id)
        self.assertTrue(any("metrics" in error for error in errors), errors)


if __name__ == "__main__":
    unittest.main()
