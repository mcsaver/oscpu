#!/usr/bin/env python3
"""V12C pending-SYSTEM 当前设计矩阵 runner 的定向单测。"""

from __future__ import annotations

import importlib.util
import sys
import tempfile
import unittest
from pathlib import Path


RUNNER = Path(__file__).with_name("run_v12c_serialize_system_current.py")
sys.path.insert(0, str(RUNNER.parent))
SPEC = importlib.util.spec_from_file_location("v12c_serialize_system_runner", RUNNER)
assert SPEC is not None and SPEC.loader is not None
MODULE = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = MODULE
SPEC.loader.exec_module(MODULE)


def priv_positive_log() -> str:
    return "\n".join(
        (
            "[V10B-SYSTEM-MIXED] C1=clear C2=no-repeat PASS",
            "[V10B-SATP-MMU] C1=clear C2=no-repeat PASS",
            "[V10B-FENCE-POST-FIRE] C1-owner-stop-clear=1 C2-repeat=0 PASS",
            "[V10G-PRODUCT-QH-SATP] C1_apply=1 C2_quiet=1 PASS",
            "[PASS] tb_ooo_priv_system",
            "[RESULT] PASS",
            "",
        )
    )


class MarkerTests(unittest.TestCase):
    def test_priv_system_positive_contract(self) -> None:
        markers = MODULE.validate_positive_markers(
            priv_positive_log(), "tb_ooo_priv_system"
        )
        self.assertEqual(len(markers), 5)

    def test_priv_system_missing_c2_marker_is_rejected(self) -> None:
        with self.assertRaises(MODULE.common.EvidenceError):
            MODULE.validate_positive_markers(
                priv_positive_log().replace("[V10B-FENCE-POST-FIRE]", "[DRIFT]"),
                "tb_ooo_priv_system",
            )

    def test_csr_mux_positive_contract(self) -> None:
        markers = MODULE.validate_positive_markers(
            "PASS tb_ooo_csr_access_request_mux\n[RESULT] PASS\n",
            "tb_ooo_csr_access_request_mux",
        )
        self.assertEqual(markers, {"PASS tb_ooo_csr_access_request_mux": 1})

    def test_positive_check_fail_is_rejected(self) -> None:
        with self.assertRaises(MODULE.common.EvidenceError):
            MODULE.validate_positive_markers(
                priv_positive_log() + "[CHECK-FAIL] repeated terminal\n",
                "tb_ooo_priv_system",
            )

    def test_all_mutation_rejection_markers_are_bound(self) -> None:
        for mutation in MODULE.MUTATIONS:
            with self.subTest(mutation=mutation.name):
                counts = MODULE.validate_negative_markers(
                    f"{mutation.rejection_marker}\n[RESULT] FAIL status=1\n",
                    mutation,
                )
                self.assertEqual(counts, {mutation.rejection_marker: 1})

    def test_negative_without_bound_marker_is_rejected(self) -> None:
        with self.assertRaises(MODULE.common.EvidenceError):
            MODULE.validate_negative_markers(
                "[CHECK-FAIL] unrelated\n[RESULT] FAIL\n",
                MODULE.MUTATIONS[0],
            )


class MutationTests(unittest.TestCase):
    def setUp(self) -> None:
        self.root = RUNNER.parents[4]

    def test_all_mutation_anchors_materialize_unique_rtl(self) -> None:
        with tempfile.TemporaryDirectory(dir=self.root) as directory:
            output = Path(directory)
            for mutation in MODULE.MUTATIONS:
                with self.subTest(mutation=mutation.name):
                    target, record = MODULE.materialize_mutation(
                        self.root, output, mutation
                    )
                    source = self.root / MODULE.VSRCDIR_REL / mutation.module
                    self.assertNotEqual(
                        MODULE.common.sha256_file(target),
                        MODULE.common.sha256_file(source),
                    )
                    self.assertEqual(record["name"], mutation.name)

    def test_product_queue_head_default_is_current(self) -> None:
        product = MODULE.common.validate_product_configuration(self.root)
        self.assertEqual(product["OOO_CSR_QUEUE_HEAD"], 1)
        self.assertFalse(product["command_line_override"])

    def test_failed_run_cleanup_preserves_logs_and_status(self) -> None:
        with tempfile.TemporaryDirectory(dir=self.root) as directory:
            output = Path(directory)
            mutation = output / "generated/mutations/example/OooExample.v"
            vvp = output / "profiles/assert/build/test.vvp"
            dependency = output / "profiles/assert/dependencies/test.argv"
            log = output / "profiles/assert/logs/test.log"
            status = output / "status.json"
            for path in (mutation, vvp, dependency, log, status):
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_text("evidence\n", encoding="utf-8")
            result = MODULE.cleanup_failed_run(output)
            self.assertEqual(result["removed"], 3)
            self.assertFalse(mutation.exists())
            self.assertFalse(vvp.exists())
            self.assertFalse(dependency.exists())
            self.assertTrue(log.exists())
            self.assertTrue(status.exists())


if __name__ == "__main__":
    unittest.main()
