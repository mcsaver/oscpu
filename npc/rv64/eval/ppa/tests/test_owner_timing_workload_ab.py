#!/usr/bin/env python3

from __future__ import annotations

import copy
import importlib.util
import json
import pathlib
import tempfile
import unittest


ROOT = pathlib.Path(__file__).resolve().parents[5]
TOOL = ROOT / "npc/rv64/eval/ppa/tools/owner_timing_workload_ab.py"
BASELINE = ROOT / "npc/rv64/eval/ppa/evidence/performance-baseline-current.json"
ARCH_STABLE = ROOT / "npc/rv64/eval/ppa/evidence/arch-stable-current.json"
CONTRACT = ROOT / (
    "npc/rv64/eval/ppa/instrumentation/owner-timing-contract-v1.json")
PROFILE = ROOT / (
    "npc/rv64/eval/ppa/instrumentation/owner-timing-validation-profile-v1.json")
RUNNER = ROOT / "npc/rv64/eval/ppa/run-owner-timing-workload-ab.sh"
CHECKER = ROOT / (
    "npc/rv64/eval/ppa/instrumentation/check-owner-timing.sh")
SPEC = importlib.util.spec_from_file_location("owner_timing_workload_ab", TOOL)
assert SPEC is not None and SPEC.loader is not None
MODULE = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(MODULE)


def common_lines(workload: str, start_hits: int = 1) -> list[str]:
    marker = "CoreMark PASS" if workload == "coremark" else "Dhrystone PASS"
    return [
        marker,
        "HIT GOOD TRAP",
        "FINAL schema=npc-rv64-region-final-v1 "
        "counter_scope=pc_bounded_region_v1 complete=1 termination_rc=0 "
        f"start_seen=1 end_seen=1 start_hits={start_hits} end_hits=1 "
        "start_cycle=10 end_cycle=14 cycles=4 start_retired=3 "
        "end_retired=8 retired=5",
        "COUNTERS_FINAL schema=npc-rv64-performance-counter-v4 "
        "complete=1 available=1 overflow=0 invalid_events=0 "
        "start_lane=0 end_lane=0 cycles=4 retired_slots=5 "
        "slot_capacity=8 conservation=1",
    ]


def owner_lines(start_hits: int = 1) -> list[str]:
    invalid_fields = " ".join(
        f"invalid_{reason}=0" for reason in MODULE.INVALID_REASONS
    )
    lines = [
        "OWNER_TIMING_FINAL schema=npc-rv64-owner-timing-v1 "
        "complete=1 available=1 overflow=0 invalid_events=0 "
        f"{invalid_fields} invalid_conservation=1 "
        f"start_seen=1 end_seen=1 start_hits={start_hits} end_hits=1 "
        "start_lane=0 end_lane=0 cycles=4 state_conservation=1 "
        "interval_conservation=1 candidate_authorized=0 "
        "promotion_eligible=0 ppa=UNQUALIFIED",
        "OWNER_TIMING_OCCUPANCY write_inflight_0=4 "
        "write_inflight_1=0 write_inflight_2=0 conservation=1",
    ]
    states = " ".join(f"s{index}={4 if index == 0 else 0}" for index in range(16))
    for bridge in range(2):
        lines.append(f"OWNER_TIMING_STATE bridge={bridge} {states}")
    for bridge in range(2):
        for operation in MODULE.CLASSES:
            lines.append(
                f"OWNER_TIMING_EVENT bridge={bridge} class={operation} "
                "request_fire=0 b_terminal=0"
            )
    for bridge in range(2):
        for stage in MODULE.STAGES:
            for operation in MODULE.CLASSES:
                lines.append(
                    f"OWNER_TIMING_STAGE bridge={bridge} stage={stage} "
                    f"class={operation} eligible_started=0 completed=0 "
                    "right_censored=0 cancelled=0 left_censored=0 "
                    "left_completed=0 left_right_censored=0 "
                    "observed_cycles=0 completed_cycles=0 rob_head_cycles=0 "
                    "peer_overlap_cycles=0 bins=0/0/0/0/0/0/0/0/0"
                )
    return lines


class OwnerTimingWorkloadAbTests(unittest.TestCase):
    def setUp(self) -> None:
        runtime = ROOT / ".github/runtime-artifacts/tests"
        runtime.mkdir(parents=True, exist_ok=True)
        self.temporary = tempfile.TemporaryDirectory(
            prefix="owner-timing-workload-", dir=runtime
        )
        self.work = pathlib.Path(self.temporary.name)

    def tearDown(self) -> None:
        self.temporary.cleanup()

    def write_log(self, lines: list[str], name: str = "run.log") -> pathlib.Path:
        path = self.work / name
        path.write_text("\n".join(lines) + "\n", encoding="utf-8")
        return path

    def diagnostic(self, workload: str = "coremark", start_hits: int = 1):
        path = self.write_log(
            common_lines(workload, start_hits) + owner_lines(start_hits)
        )
        return MODULE.parse_diagnostic_log(path, workload)

    def test_current_f72e_v3_baseline_binding_is_canonical(self) -> None:
        baseline, _, profile = MODULE.validate_static_inputs(
            BASELINE, CONTRACT, PROFILE)
        self.assertEqual(
            baseline["schema"], "npc-rv64-performance-baseline-current-v3")
        self.assertEqual(profile["binding"]["design_id"], baseline["design_id"])
        self.assertEqual(profile["binding"]["baseline_schema"], baseline["schema"])
        coremark = MODULE.baseline_image_path(baseline, "coremark")
        dhrystone = MODULE.baseline_image_path(baseline, "dhrystone_10000")
        expected_input_run = (
            "2026-08-08-rv64-v15x-trap-c0-dispatch-closure-f72e-l1-a1")
        self.assertIn(expected_input_run, str(coremark))
        self.assertIn(expected_input_run, str(dhrystone))
        runner = RUNNER.read_text(encoding="utf-8")
        self.assertIn("resolve-image", runner)
        self.assertNotIn(
            "2026-08-04-rv64-v14m-arch-stable-current-cohort-v1", runner)

    def test_live_arch_stable_successor_matches_frozen_baseline_identity(self) -> None:
        baseline, _, _ = MODULE.validate_static_inputs(
            BASELINE, CONTRACT, PROFILE)
        arch_stable = MODULE.validate_arch_stable_reference(
            ARCH_STABLE, baseline)
        self.assertEqual(arch_stable["design_id"], baseline["design_id"])
        self.assertEqual(arch_stable["architecture_freeze"], "ARCH_STABLE")

    def test_arch_stable_design_drift_is_rejected(self) -> None:
        baseline, _, _ = MODULE.validate_static_inputs(
            BASELINE, CONTRACT, PROFILE)
        mutated = copy.deepcopy(json.loads(ARCH_STABLE.read_text(encoding="utf-8")))
        mutated["design_id"] = "sha256:" + "0" * 64
        path = self.work / "arch-stable-design-drift.json"
        path.write_text(
            json.dumps(mutated, indent=2, sort_keys=True) + "\n",
            encoding="utf-8",
        )
        with self.assertRaisesRegex(MODULE.EvidenceError, "design-id mismatch"):
            MODULE.validate_arch_stable_reference(path, baseline)

    def test_fast_marker_case_counts_are_observed_not_duplicated(self) -> None:
        runner = RUNNER.read_text(encoding="utf-8")
        checker = CHECKER.read_text(encoding="utf-8")
        self.assertIn("unit_cases=[1-9][0-9]*", runner)
        self.assertIn("workload_cases=[1-9][0-9]*", runner)
        self.assertNotIn("workload_cases=14", runner)
        self.assertIn("workload_case_markers", checker)
        self.assertIn("unit_case_markers", checker)
        self.assertNotIn("unit_cases=12 workload_cases=", checker)
        self.assertIn("rv64-engineering-single-flight.lock", runner)
        self.assertIn("flock -n 9", runner)
        self.assertIn("run directory already exists", runner)
        self.assertIn("--arch-stable", runner)
        self.assertIn("arch_stable_baseline_identity", TOOL.read_text(encoding="utf-8"))

    def test_dhrystone_repeated_start_hits_are_legal(self) -> None:
        parsed = self.diagnostic("dhrystone_10000", start_hits=10000)
        self.assertEqual(parsed["start_hits"], 10000)
        self.assertEqual(parsed["owner_final"]["start_hits"], "10000")
        self.assertEqual(parsed["owner_line_count"], 84)

    def test_reference_log_rejects_owner_payload(self) -> None:
        path = self.write_log(common_lines("coremark") + owner_lines())
        with self.assertRaisesRegex(MODULE.EvidenceError, "unexpectedly contains"):
            MODULE.parse_reference_log(path, "coremark")

    def test_owner_invalid_event_is_rejected(self) -> None:
        lines = common_lines("coremark") + owner_lines()
        lines[4] = lines[4].replace("invalid_events=0", "invalid_events=1")
        path = self.write_log(lines)
        with self.assertRaisesRegex(MODULE.EvidenceError, "invalid_events"):
            MODULE.parse_diagnostic_log(path, "coremark")

    def test_owner_invalid_reason_conservation_is_rejected(self) -> None:
        lines = common_lines("coremark") + owner_lines()
        lines[4] = lines[4].replace(
            "invalid_admission_identity_change=0",
            "invalid_admission_identity_change=1",
        )
        path = self.write_log(lines)
        with self.assertRaisesRegex(MODULE.EvidenceError, "invalid reason total"):
            MODULE.parse_diagnostic_log(path, "coremark")

    def test_invalid_probe_preserves_failed_qualification(self) -> None:
        lines = common_lines("coremark") + owner_lines()
        lines[4] = (
            lines[4]
            .replace("complete=1", "complete=0", 1)
            .replace("invalid_events=0", "invalid_events=1", 1)
            .replace(
                "invalid_admission_identity_change=0",
                "invalid_admission_identity_change=1",
                1,
            )
        )
        path = self.write_log(lines)
        parsed = MODULE.parse_invalid_probe_log(path, "coremark")
        self.assertFalse(parsed["collector_qualified"])
        self.assertEqual(parsed["invalid_events"], 1)
        self.assertEqual(
            parsed["invalid_reason_counts"]["admission_identity_change"], 1
        )

    def test_same_design_invalid_probe_binding_is_accepted(self) -> None:
        design_id = "sha256:" + "1" * 64
        self.assertEqual(
            MODULE.bind_invalid_probe_design(design_id, design_id, False),
            design_id,
        )

    def test_cross_design_invalid_probe_requires_diagnostic_boundary(self) -> None:
        reference = "sha256:" + "1" * 64
        production = "sha256:" + "2" * 64
        with self.assertRaisesRegex(MODULE.EvidenceError, "design-id mismatch"):
            MODULE.bind_invalid_probe_design(reference, production, False)
        self.assertEqual(
            MODULE.bind_invalid_probe_design(reference, production, True),
            production,
        )

    def test_same_design_probe_rejects_reference_counter_drift(self) -> None:
        with self.assertRaisesRegex(MODULE.EvidenceError, "counter stack"):
            MODULE.enforce_invalid_probe_reference_match(True, False, False)

    def test_current_design_probe_records_reference_drift_without_promotion(self) -> None:
        MODULE.enforce_invalid_probe_reference_match(False, False, True)

    def test_missing_stage_product_row_is_rejected(self) -> None:
        lines = common_lines("coremark") + owner_lines()
        lines.pop()
        path = self.write_log(lines)
        with self.assertRaisesRegex(MODULE.EvidenceError, "do not cover"):
            MODULE.parse_diagnostic_log(path, "coremark")

    def test_duplicate_stage_product_row_is_rejected(self) -> None:
        lines = common_lines("coremark") + owner_lines()
        lines.append(lines[-1])
        path = self.write_log(lines)
        with self.assertRaisesRegex(MODULE.EvidenceError, "duplicate or invalid"):
            MODULE.parse_diagnostic_log(path, "coremark")

    def test_histogram_conservation_is_rejected(self) -> None:
        lines = common_lines("coremark") + owner_lines()
        for index, line in enumerate(lines):
            if line.startswith("OWNER_TIMING_STAGE "):
                lines[index] = line.replace(
                    "bins=0/0/0/0/0/0/0/0/0", "bins=1/0/0/0/0/0/0/0/0"
                )
                break
        path = self.write_log(lines)
        with self.assertRaisesRegex(MODULE.EvidenceError, "histogram conservation"):
            MODULE.parse_diagnostic_log(path, "coremark")

    def test_endpoint_slot_capacity_is_rejected(self) -> None:
        lines = common_lines("coremark") + owner_lines()
        lines[3] = lines[3].replace("slot_capacity=8", "slot_capacity=7")
        path = self.write_log(lines)
        with self.assertRaisesRegex(MODULE.EvidenceError, "slot capacity"):
            MODULE.parse_diagnostic_log(path, "coremark")

    def test_forbidden_marker_is_rejected(self) -> None:
        lines = common_lines("coremark") + owner_lines() + ["[CHECK-FAIL] mutation"]
        path = self.write_log(lines)
        with self.assertRaisesRegex(MODULE.EvidenceError, "forbidden marker"):
            MODULE.parse_diagnostic_log(path, "coremark")


if __name__ == "__main__":
    unittest.main()
