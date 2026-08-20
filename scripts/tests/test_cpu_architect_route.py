#!/usr/bin/env python3
"""Focused tests for the deterministic CPU Architect router."""

from __future__ import annotations

import copy
import importlib.util
import json
import subprocess
import tempfile
import unittest
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[2]
SCRIPT = REPO_ROOT / "scripts/cpu_architect_route.py"
POLICY_PATH = (
    REPO_ROOT / ".github/ai-env/contracts/cpu-architect-routing-v1.json"
)
SPEC = importlib.util.spec_from_file_location("cpu_architect_route", SCRIPT)
assert SPEC is not None and SPEC.loader is not None
ROUTER = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(ROUTER)


class CpuArchitectRouteTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.policy = ROUTER.load_json(POLICY_PATH)

    def packet(self, example_id: str) -> dict:
        for example in self.policy["examples"]:
            if example["id"] == example_id:
                return copy.deepcopy(example["packet"])
        self.fail(f"missing policy example: {example_id}")

    def test_policy_examples_are_executable_contract(self) -> None:
        ROUTER.run_self_test(self.policy)

    def test_unknown_root_cause_cannot_start_architect(self) -> None:
        packet = self.packet("owner-terminal-critical-cone")
        packet["root_cause"] = "unknown"
        result = ROUTER.classify(packet, self.policy)
        self.assertEqual(result["route"], "EXPLORER")
        self.assertIn("CAUSAL_ROOT_CAUSE_NOT_READY", result["reason_codes"])

    def test_keyword_like_tooling_task_is_non_arch(self) -> None:
        packet = self.packet("trace-parser-fix")
        result = ROUTER.classify(packet, self.policy)
        self.assertEqual(result["route"], "NON_ARCH")

    def test_fixed_cross_module_design_routes_to_worker(self) -> None:
        packet = self.packet("fixed-permit-implementation")
        result = ROUTER.classify(packet, self.policy)
        self.assertEqual(result["route"], "WORKER")

    def test_existing_candidate_routes_to_reviewer(self) -> None:
        packet = self.packet("candidate-promotion-review")
        result = ROUTER.classify(packet, self.policy)
        self.assertEqual(result["route"], "REVIEWER")
        self.assertEqual(result["verification"]["review"], "INDEPENDENT")

    def test_deterministic_high_risk_is_single_pass_with_independent_review(self) -> None:
        packet = self.packet("owner-terminal-critical-cone")
        packet["risk"] = "high"
        result = ROUTER.classify(packet, self.policy)
        self.assertEqual(result["verification"]["execution"], "SINGLE_PASS")
        self.assertEqual(result["verification"]["review"], "INDEPENDENT")

    def test_flaky_work_requires_repeat_reason(self) -> None:
        packet = self.packet("flaky-concurrent-probe")
        result = ROUTER.classify(packet, self.policy)
        self.assertEqual(
            result["verification"]["execution"], "REPEAT_WITH_REASON")
        self.assertTrue(result["verification"]["repeat_reasons"])

    def test_unknown_determinism_requires_control_not_repetition(self) -> None:
        packet = self.packet("owner-terminal-critical-cone")
        packet["determinism"] = "unknown"
        result = ROUTER.classify(packet, self.policy)
        self.assertEqual(result["verification"]["execution"], "SINGLE_PASS")
        self.assertEqual(result["verification"]["repeat_reasons"], [])

    def test_missing_authority_routes_to_clarify(self) -> None:
        packet = self.packet("open-design-without-authority")
        result = ROUTER.classify(packet, self.policy)
        self.assertEqual(result["route"], "CLARIFY")

    def test_unknown_packet_field_is_rejected(self) -> None:
        packet = self.packet("owner-terminal-critical-cone")
        packet["cpu_keyword_count"] = 99
        with self.assertRaises(ROUTER.RouteContractError):
            ROUTER.classify(packet, self.policy)

    def test_cli_classify_emits_json(self) -> None:
        packet = self.packet("owner-terminal-critical-cone")
        with tempfile.TemporaryDirectory() as tmp:
            input_path = Path(tmp) / "packet.json"
            input_path.write_text(json.dumps(packet), encoding="utf-8")
            completed = subprocess.run(
                ["python3", "-B", str(SCRIPT), "classify", "--input",
                 str(input_path)],
                cwd=REPO_ROOT,
                check=False,
                capture_output=True,
                text=True,
            )
        self.assertEqual(completed.returncode, 0, completed.stderr)
        self.assertEqual(json.loads(completed.stdout)["route"], "ARCHITECT")


if __name__ == "__main__":
    unittest.main()
