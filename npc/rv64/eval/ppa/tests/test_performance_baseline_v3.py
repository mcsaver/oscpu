#!/usr/bin/env python3

from __future__ import annotations

import hashlib
import json
import pathlib
import re
import shutil
import subprocess
import sys
import tempfile
import unittest
from collections.abc import Callable

import jsonschema


ROOT = pathlib.Path(__file__).resolve().parents[5]
TOOL = ROOT / "npc/rv64/eval/ppa/tools/performance_baseline_current.py"
RUNNER = ROOT / "npc/rv64/eval/ppa/run-performance-baseline-current.sh"
FIXTURES = ROOT / "npc/rv64/eval/ppa/tests/fixtures"
ARCH_STABLE = ROOT / "npc/rv64/eval/ppa/evidence/arch-stable-current.json"
BASELINE = ROOT / "npc/rv64/design/arch/performance-baseline-contract-v3.json"
MEASUREMENT = ROOT / "npc/rv64/design/arch/performance-measurement-contract-v2.json"
COUNTER = ROOT / "npc/rv64/design/arch/performance-counter-schema-v4.json"
AMENDMENT = ROOT / (
    "npc/rv64/design/arch/performance-boundary-qualification-amendment-v2.json")
MATRIX = ROOT / "npc/rv64/design/arch/performance-workload-matrix-v1.json"
POLICY = ROOT / "npc/rv64/eval/ppa/policies/performance-baseline-f7-v1.json"
RESULT_SCHEMA = ROOT / (
    "npc/rv64/eval/ppa/schemas/performance-baseline-current-v3.schema.json")
SIMULATOR = ROOT / (
    ".github/task-runs/2026-08-07-rv64-v15p-control-loop-current-f7a/"
    "evidence/functional/frozen/NpcSimTop")
CONFIG = ROOT / "npc/rv64/.config"
COREMARK_IMAGE = ROOT / (
    ".github/task-runs/2026-08-07-rv64-v15p-control-loop-current-f7a/"
    "evidence/functional/images/benchmarks/coremark.bin")
DHRYSTONE_IMAGE = ROOT / (
    ".github/task-runs/2026-08-07-rv64-v15p-control-loop-current-f7a/"
    "evidence/functional/images/benchmarks/dhrystone.bin")


class PerformanceBaselineV3Tests(unittest.TestCase):
    def setUp(self) -> None:
        runtime = ROOT / ".github/runtime-artifacts/tests"
        runtime.mkdir(parents=True, exist_ok=True)
        self.temporary = tempfile.TemporaryDirectory(
            prefix="performance-baseline-v3-", dir=runtime)
        self.work = pathlib.Path(self.temporary.name)
        self.coremark_logs = self.copy_runs(
            FIXTURES / "coremark-valid.log", "coremark")
        self.dhrystone_logs = self.copy_runs(
            FIXTURES / "dhrystone-valid.log", "dhrystone")
        self.coremark_off = self.make_stats_off(
            FIXTURES / "coremark-valid.log", "coremark-stats-off.log")
        self.dhrystone_off = self.make_stats_off(
            FIXTURES / "dhrystone-valid.log", "dhrystone-stats-off.log")
        self.stats_off_simulator = self.work / "NpcSimTop-stats-off"
        self.stats_off_simulator.write_bytes(b"\x7fELFstats-off-v3-fixture\n")
        self.stats_off_simulator.chmod(0o755)
        self.preflight = self.work / "preflight.json"
        self.manifest = self.work / "manifest.json"
        self.result = self.work / "result.json"
        self.postflight = self.work / "postflight-arch-stable.log"
        self.postflight.write_text(
            "[ARCH-STABLE] status=ARCH_STABLE ppa=UNQUALIFIED "
            "promotion_eligible=false blockers=0\n",
            encoding="utf-8")

    def tearDown(self) -> None:
        self.temporary.cleanup()

    def relative(self, path: pathlib.Path) -> str:
        return path.resolve().relative_to(ROOT).as_posix()

    def artifact_record(self, path: pathlib.Path) -> dict[str, object]:
        payload = path.read_bytes()
        return {
            "path": self.relative(path),
            "sha256": hashlib.sha256(payload).hexdigest(),
            "size_bytes": len(payload),
        }

    def write_json(self, path: pathlib.Path, value: dict[str, object]) -> None:
        path.write_text(
            json.dumps(value, indent=2, sort_keys=True) + "\n",
            encoding="utf-8")

    def copy_runs(self, source: pathlib.Path, stem: str) -> list[pathlib.Path]:
        result = []
        for index in range(1, 4):
            destination = self.work / f"{stem}-rep{index}.log"
            shutil.copyfile(source, destination)
            result.append(destination)
        return result

    def make_stats_off(self, source: pathlib.Path, name: str) -> pathlib.Path:
        rewritten = []
        for line in source.read_text(encoding="utf-8").splitlines(keepends=True):
            if "COUNTERS_FINAL" in line:
                def replace_counter(match: re.Match[str]) -> str:
                    key, value = match.group(1), match.group(2)
                    if key in {"complete", "available", "conservation"}:
                        return f"{key}=0"
                    if (key.startswith("cycle_") or key.startswith("slot_")
                            or key in {"slot_capacity", "retired_slots",
                                       "unused_slots"}):
                        return f"{key}=0"
                    return f"{key}={value}"
                line = re.sub(
                    r"([a-zA-Z0-9_]+)=([^\s]+)", replace_counter, line)
            rewritten.append(line)
        destination = self.work / name
        destination.write_text("".join(rewritten), encoding="utf-8")
        return destination

    def run_tool(self, *arguments: str) -> subprocess.CompletedProcess[str]:
        return subprocess.run(
            [sys.executable, "-B", str(TOOL), *arguments],
            cwd=ROOT, text=True, stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT, check=False)

    def preflight_command(
        self, *, baseline: pathlib.Path = BASELINE,
        measurement: pathlib.Path = MEASUREMENT,
        amendment: pathlib.Path = AMENDMENT,
        matrix: pathlib.Path = MATRIX,
        policy: pathlib.Path = POLICY,
        simulator: pathlib.Path = SIMULATOR,
    ) -> list[str]:
        return [
            "preflight", "--output", self.relative(self.preflight),
            "--arch-stable-result", self.relative(ARCH_STABLE),
            "--baseline-contract", self.relative(baseline),
            "--measurement-contract", self.relative(measurement),
            "--counter-schema", self.relative(COUNTER),
            "--boundary-qualification-amendment", self.relative(amendment),
            "--workload-matrix", self.relative(matrix),
            "--policy", self.relative(policy),
            "--simulator", self.relative(simulator),
            "--config", self.relative(CONFIG),
            "--coremark-image", self.relative(COREMARK_IMAGE),
            "--dhrystone-image", self.relative(DHRYSTONE_IMAGE),
        ]

    def write_manifest(self, *, duplicate_coremark: bool = False) -> None:
        coremark = (
            [self.coremark_logs[0]] * 3
            if duplicate_coremark else self.coremark_logs)
        command = [
            "manifest", "--output", self.relative(self.manifest),
            "--arch-stable-result", self.relative(ARCH_STABLE),
            "--baseline-contract", self.relative(BASELINE),
            "--measurement-contract", self.relative(MEASUREMENT),
            "--counter-schema", self.relative(COUNTER),
            "--boundary-qualification-amendment", self.relative(AMENDMENT),
            "--workload-matrix", self.relative(MATRIX),
            "--policy", self.relative(POLICY),
            "--simulator", self.relative(SIMULATOR),
            "--config", self.relative(CONFIG),
            "--coremark-image", self.relative(COREMARK_IMAGE),
            "--dhrystone-image", self.relative(DHRYSTONE_IMAGE),
            "--stats-off-simulator", self.relative(self.stats_off_simulator),
            "--coremark-stats-off-log", self.relative(self.coremark_off),
            "--dhrystone-stats-off-log", self.relative(self.dhrystone_off),
        ]
        for path in coremark:
            command.extend(("--coremark-log", self.relative(path)))
        for path in self.dhrystone_logs:
            command.extend(("--dhrystone-log", self.relative(path)))
        completed = self.run_tool(*command)
        self.assertEqual(completed.returncode, 0, completed.stdout)
        completed = self.run_tool(
            "bind-postflight", "--manifest", self.relative(self.manifest),
            "--postflight-log", self.relative(self.postflight),
            "--output", self.relative(self.manifest))
        self.assertEqual(completed.returncode, 0, completed.stdout)

    def write_contract_stack(
        self, mutate_matrix: Callable[[dict[str, object]], None],
    ) -> tuple[pathlib.Path, pathlib.Path, pathlib.Path, pathlib.Path, pathlib.Path]:
        matrix_path = self.work / "matrix.json"
        measurement_path = self.work / "measurement.json"
        amendment_path = self.work / "amendment.json"
        policy_path = self.work / "policy.json"
        baseline_path = self.work / "baseline.json"

        matrix = json.loads(MATRIX.read_text(encoding="utf-8"))
        mutate_matrix(matrix)
        self.write_json(matrix_path, matrix)

        measurement = json.loads(MEASUREMENT.read_text(encoding="utf-8"))
        measurement["workload_matrix"] = self.artifact_record(matrix_path)
        self.write_json(measurement_path, measurement)

        amendment = json.loads(AMENDMENT.read_text(encoding="utf-8"))
        amendment["bound_inputs"]["measurement_contract"] = (
            self.artifact_record(measurement_path))
        self.write_json(amendment_path, amendment)

        policy = json.loads(POLICY.read_text(encoding="utf-8"))
        evidence = policy["performance_evidence"]
        evidence["measurement_contract"] = {
            **self.artifact_record(measurement_path),
            "id": measurement["performance_measurement_contract_id"],
        }
        evidence["workload_matrix"] = {
            **self.artifact_record(matrix_path),
            "id": matrix["workload_matrix_id"],
        }
        self.write_json(policy_path, policy)

        baseline = json.loads(BASELINE.read_text(encoding="utf-8"))
        baseline["measurement_contract"] = self.artifact_record(measurement_path)
        baseline["boundary_qualification_amendment"] = (
            self.artifact_record(amendment_path))
        baseline["workload_matrix"] = self.artifact_record(matrix_path)
        baseline["policy"] = self.artifact_record(policy_path)
        self.write_json(baseline_path, baseline)
        return baseline_path, measurement_path, amendment_path, matrix_path, policy_path

    def test_preflight_accepts_current_f7_identity(self) -> None:
        completed = self.run_tool(*self.preflight_command())
        self.assertEqual(completed.returncode, 0, completed.stdout)
        value = json.loads(self.preflight.read_text(encoding="utf-8"))
        self.assertEqual(value["status"], "PASS")
        self.assertEqual(value["checks"]["historical_counter_reuse"],
                         "REJECTED_BY_CONTRACT")

    def test_preflight_rejects_noncurrent_simulator_before_execution(self) -> None:
        completed = self.run_tool(*self.preflight_command(
            simulator=self.stats_off_simulator))
        self.assertNotEqual(completed.returncode, 0)
        self.assertIn("direct measurement artifact identity mismatch",
                      completed.stdout)

    def test_preflight_rejects_old_design_contract(self) -> None:
        baseline = json.loads(BASELINE.read_text(encoding="utf-8"))
        baseline["current_arch_stable_binding"]["design_id"] = (
            "sha256:" + "0" * 64)
        stale = self.work / "stale-design-baseline.json"
        self.write_json(stale, baseline)
        completed = self.run_tool(*self.preflight_command(baseline=stale))
        self.assertNotEqual(completed.returncode, 0)
        self.assertIn("current baseline contract design-id mismatch",
                      completed.stdout)

    def test_preflight_rejects_missing_workload_category(self) -> None:
        stack = self.write_contract_stack(
            lambda value: value["coverage_categories"].pop("privilege_system"))
        baseline, measurement, amendment, matrix, policy = stack
        completed = self.run_tool(*self.preflight_command(
            baseline=baseline, measurement=measurement,
            amendment=amendment, matrix=matrix, policy=policy))
        self.assertNotEqual(completed.returncode, 0)
        self.assertIn("coverage categories mismatch", completed.stdout)

    def test_direct_build_and_verify(self) -> None:
        self.write_manifest()
        built = self.run_tool(
            "build", "--manifest", self.relative(self.manifest),
            "--output", self.relative(self.result), "--require-baseline")
        self.assertEqual(built.returncode, 0, built.stdout)
        verified = self.run_tool(
            "verify", "--input", self.relative(self.result),
            "--require-baseline")
        self.assertEqual(verified.returncode, 0, verified.stdout)
        value = json.loads(self.result.read_text(encoding="utf-8"))
        schema = json.loads(RESULT_SCHEMA.read_text(encoding="utf-8"))
        jsonschema.Draft202012Validator.check_schema(schema)
        jsonschema.validate(value, schema)
        self.assertEqual(value["schema"],
                         "npc-rv64-performance-baseline-current-v3")
        self.assertEqual(value["execution_mode"],
                         "FRESH_CURRENT_DESIGN_DIRECT")
        self.assertFalse(value["claim_boundary"][
            "global_workload_representativeness"])
        self.assertEqual(value["ppa"], "UNQUALIFIED")

    def test_direct_reused_raw_log_is_rejected(self) -> None:
        self.write_manifest(duplicate_coremark=True)
        completed = self.run_tool(
            "build", "--manifest", self.relative(self.manifest),
            "--output", self.relative(self.result), "--require-baseline")
        self.assertNotEqual(completed.returncode, 0)
        self.assertIn("raw log path is reused", completed.stdout)

    def test_runner_preflights_current_identity_before_first_guest(self) -> None:
        runner = RUNNER.read_text(encoding="utf-8")
        self.assertIn("performance-baseline-contract-v3.json", runner)
        self.assertIn("performance-measurement-contract-v2.json", runner)
        self.assertIn("performance-workload-matrix-v1.json", runner)
        self.assertIn(
            "2026-08-07-rv64-v15p-control-loop-current-f7a/"
            "evidence/functional/frozen/NpcSimTop",
            runner,
        )
        self.assertNotIn(
            'stats_on_simulator="${repo_root}/.github/task-runs/'
            '2026-08-05-rv64-v15f-full-core-current-f7a6-a1/',
            runner,
        )
        self.assertNotIn("2026-08-04-rv64-v14m", runner)
        self.assertLess(
            runner.index('task_run_status_stage "preflight-exact-input-binding"'),
            runner.index('"coremark-stats-on-rep${repetition}"'))
        self.assertLess(
            runner.index('python3 -B "${tool}" preflight'),
            runner.index('"coremark-stats-on-rep${repetition}"'))


if __name__ == "__main__":
    unittest.main()
