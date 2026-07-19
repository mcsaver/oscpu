#!/usr/bin/env python3
"""Static/unit checks for the P0-A ABBAAB benchmark evidence runner."""

from __future__ import annotations

import copy
import importlib.util
import pathlib
import sys
import unittest


SCRIPT_PATH = pathlib.Path(__file__).resolve()
CHECKER_PATH = SCRIPT_PATH.with_name("check-r4-p0a-fixed-benchmarks.py")
SPEC = importlib.util.spec_from_file_location("p0a_benchmark_checker", CHECKER_PATH)
if SPEC is None or SPEC.loader is None:
    raise RuntimeError(f"cannot import {CHECKER_PATH}")
checker = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = checker
SPEC.loader.exec_module(checker)


class P0aBenchmarkEvidenceTests(unittest.TestCase):
    def p0a_candidate_build(self) -> tuple[pathlib.Path, pathlib.Path]:
        build = (
            checker.ROOT
            / "tmp/2026-07-15-rv64-ppa-architecture-recovery/build-r4-p0a-wb-valid"
        )
        return build / "NpcSimTop", build / "obj_dir/VNpcSimTop__verFiles.dat"

    def test_policy_and_checkpoint_contracts_are_current(self) -> None:
        policy, contracts = checker.load_policy_contract()
        self.assertEqual(
            policy["performance_evidence"]["schema"],
            "npc-rv64-performance-evidence-v3",
        )
        self.assertEqual(set(contracts), set(checker.BENCHMARKS))
        self.assertEqual(
            checker.checkpoint_counters(),
            {
                "coremark": {
                    "cycles": 4_904_511,
                    "retired_instructions": 3_183_617,
                },
                "dhrystone_10000": {
                    "cycles": 9_481_620,
                    "retired_instructions": 4_250_000,
                },
            },
        )

    def test_s0_historical_build_inputs_have_exact_sizes(self) -> None:
        root = checker.ROOT
        task = root / ".github/task-runs/2026-07-15-rv64-ppa-architecture-recovery"
        build = root / "tmp/2026-07-15-rv64-ppa-architecture-recovery/build-r4-s0-posttranslate"
        binding = task / "evidence/r4-s0-correctness-checkpoint/performance/rep01/coremark"
        value = checker.normalize_historical_inputs(
            build / "NpcSimTop",
            binding / "binding.pre.sha256",
            binding / "binding.post.sha256",
            build / "obj_dir/VNpcSimTop__verFiles.dat",
        )
        self.assertEqual(value["capture_mode"], "historical_build_attestation")
        self.assertEqual(value["rtl_count"], 117)
        self.assertEqual(len(value["inputs"]["rtl"]), 117)
        for record in checker.flattened_input_records(value["inputs"]):
            self.assertIsInstance(record["size_bytes"], int)
            self.assertGreater(record["size_bytes"], 0)

    def test_regression_verfiles_s_ledger_does_not_cover_cpp(self) -> None:
        _, verfiles = self.p0a_candidate_build()
        parsed = checker.parse_verfiles(verfiles)
        probe = checker.workspace_file(
            checker.ROOT / "npc/rv64/csrc/cpu/cpu-exec.cpp"
        )
        self.assertEqual(parsed["tokens"].count(str(probe)), 1)
        self.assertNotIn(probe, parsed["ledger"])
        with self.assertRaisesRegex(
            ValueError, "candidate Verilator ledger omits build input"
        ):
            if parsed["ledger"].get(probe) is None:
                checker.fail(f"candidate Verilator ledger omits build input: {probe}")

    def test_cpp_dependency_object_chain_is_live_bound(self) -> None:
        binary, verfiles = self.p0a_candidate_build()
        document = checker.capture_live_inputs(binary, verfiles)
        value = document["compiler_dependency_attestation"]
        checker.validate_compiler_dependency_attestation(
            value,
            checker.workspace_file(binary),
            checker.workspace_file(
                checker.ROOT / "npc/rv64/csrc/cpu/cpu-exec.cpp"
            ),
            checker.workspace_file(verfiles),
        )
        self.assertEqual(value["schema"], checker.COMPILER_ATTESTATION_SCHEMA)
        self.assertEqual(
            value["dependency_file"]["workspace_path"],
            "tmp/2026-07-15-rv64-ppa-architecture-recovery/"
            "build-r4-p0a-wb-valid/obj_dir/cpu-exec.d",
        )
        self.assertEqual(
            value["object_file"]["workspace_path"],
            "tmp/2026-07-15-rv64-ppa-architecture-recovery/"
            "build-r4-p0a-wb-valid/obj_dir/cpu-exec.o",
        )

    def parsed_fixture(self, benchmark: str) -> dict:
        fixture = (
            checker.PPA_DIR
            / "tests/fixtures"
            / ("coremark-valid.log" if benchmark == "coremark" else "dhrystone-valid.log")
        )
        return checker.parse_and_validate_log(fixture, benchmark)

    def matrix_rows(self, benchmark: str) -> list[dict]:
        parsed = self.parsed_fixture(benchmark)
        return [
            {
                "ordinal": ordinal,
                "design": design,
                "cycles": parsed["cycles"],
                "retired_instructions": parsed["retired_instructions"],
            }
            for ordinal, design in enumerate(checker.EXPECTED_SEQUENCE, start=1)
        ]

    def test_abbaab_matrix_accepts_exact_fixed_region(self) -> None:
        rows = self.matrix_rows("coremark")
        result = checker.validate_measurement_matrix(
            rows,
            "coremark",
            {"cycles": 100, "retired_instructions": 100},
            0.995,
            True,
        )
        self.assertTrue(result["candidate_cycle_exact_with_s0"])
        self.assertEqual(result["candidate_throughput_ratio"], 1.0)

    def test_wrong_order_is_rejected(self) -> None:
        rows = self.matrix_rows("coremark")
        rows[1]["design"] = "A"
        with self.assertRaisesRegex(ValueError, "ordering"):
            checker.validate_measurement_matrix(
                rows,
                "coremark",
                {"cycles": 100, "retired_instructions": 100},
                0.995,
                True,
            )

    def test_retired_drift_is_rejected(self) -> None:
        rows = self.matrix_rows("dhrystone_10000")
        for row in rows:
            if row["design"] == "B":
                row["retired_instructions"] += 1
        with self.assertRaisesRegex(ValueError, "retired counts differ"):
            checker.validate_measurement_matrix(
                rows,
                "dhrystone_10000",
                {"cycles": 100, "retired_instructions": 100},
                0.995,
                True,
            )

    def test_p0a_cycle_drift_is_rejected_even_above_perf_floor(self) -> None:
        rows = copy.deepcopy(self.matrix_rows("coremark"))
        for row in rows:
            if row["design"] == "B":
                row["cycles"] += 1
        with self.assertRaisesRegex(ValueError, "not cycle-exact"):
            checker.validate_measurement_matrix(
                rows,
                "coremark",
                {"cycles": 100, "retired_instructions": 100},
                0.98,
                True,
            )


if __name__ == "__main__":
    unittest.main(verbosity=2)
