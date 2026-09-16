#!/usr/bin/env python3

from __future__ import annotations

import json
import hashlib
import pathlib
import re
import shutil
import subprocess
import sys
import tempfile
import unittest

import jsonschema


ROOT = pathlib.Path(__file__).resolve().parents[5]
TOOL = ROOT / "npc/rv64/eval/ppa/tools/performance_baseline_current.py"
FIXTURES = ROOT / "npc/rv64/eval/ppa/tests/fixtures"
ARCH_STABLE = ROOT / "npc/rv64/eval/ppa/evidence/arch-stable-current.json"
CONTRACT = ROOT / "npc/rv64/design/arch/performance-measurement-contract-v1.json"
BASELINE_CONTRACT_TEMPLATE = (
    ROOT / "npc/rv64/design/arch/performance-baseline-contract-v2.json")
AMENDMENT = ROOT / (
    "npc/rv64/design/arch/performance-boundary-qualification-amendment-v1.json")
COUNTER = ROOT / "npc/rv64/design/arch/performance-counter-schema-v4.json"
POLICY = ROOT / "npc/rv64/eval/ppa/policies/proxy-200mhz-v1.json"
SIMULATOR = ROOT / (
    ".github/task-runs/2026-08-08-rv64-v15x-trap-c0-dispatch-closure-f72e-l1-a1/"
    "evidence/functional/frozen/NpcSimTop"
)
CONFIG = ROOT / "npc/rv64/.config"
COREMARK_IMAGE = ROOT / (
    ".github/task-runs/2026-08-08-rv64-v15x-trap-c0-dispatch-closure-f72e-l1-a1/"
    "evidence/functional/images/benchmarks/coremark.bin"
)
DHRYSTONE_IMAGE = ROOT / (
    ".github/task-runs/2026-08-08-rv64-v15x-trap-c0-dispatch-closure-f72e-l1-a1/"
    "evidence/functional/images/benchmarks/dhrystone.bin"
)
A2_SOURCE_MANIFEST = ROOT / (
    ".github/task-runs/2026-08-04-rv64-v14n-performance-baseline-current-v2/"
    "evidence/performance-baseline-current/run-manifest.json"
)
CURRENT_INDEPENDENT_REVIEW = ROOT / (
    "npc/rv64/eval/ppa/evidence/"
    "performance-baseline-independent-review-current.json"
)
HISTORICAL_INDEPENDENT_REVIEW = ROOT / (
    ".github/task-runs/2026-08-04-rv64-v14n-"
    "performance-baseline-composite-replay-v1/evidence/composite-replay/"
    "independent-review-receipt.json"
)
RESULT_SCHEMA_V2 = ROOT / (
    "npc/rv64/eval/ppa/schemas/performance-baseline-current-v2.schema.json")
RESULT_SCHEMA_V3 = ROOT / (
    "npc/rv64/eval/ppa/schemas/performance-baseline-current-v3.schema.json")
REVIEW_SCHEMA_V1 = ROOT / (
    "npc/rv64/eval/ppa/schemas/"
    "performance-baseline-independent-review-v1.schema.json")
REVIEW_SCHEMA_V2 = ROOT / (
    "npc/rv64/eval/ppa/schemas/"
    "performance-baseline-independent-review-v2.schema.json")
CURRENT_RESULT = ROOT / "npc/rv64/eval/ppa/evidence/performance-baseline-current.json"


class PerformanceBaselineCurrentTests(unittest.TestCase):
    def setUp(self) -> None:
        runtime = ROOT / ".github/runtime-artifacts/tests"
        runtime.mkdir(parents=True, exist_ok=True)
        self.temporary = tempfile.TemporaryDirectory(
            prefix="performance-baseline-", dir=runtime)
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
        self.stats_off_simulator.write_bytes(b"\x7fELFstats-off-fixture\n")
        self.stats_off_simulator.chmod(0o755)
        self.manifest = self.work / "manifest.json"
        self.result = self.work / "result.json"
        self.precheck = self.work / "precheck.json"
        self.a1_status = self.work / "a1-original.status"
        self.a2_status = self.work / "a2-original.status"
        self.a2_command_status = self.work / "a2-command-status.txt"
        self.source_manifest = self.work / "a2-source-manifest.json"
        self.baseline_contract = self.work / "performance-baseline-contract-v2.json"
        self.postflight = self.work / "postflight-arch-stable.log"
        original_failure = (
            "FAIL rc=1 stage=evidence-complete evidence_complete=0 cleanup_rc=0\n")
        self.a1_status.write_text(original_failure, encoding="utf-8")
        self.a2_status.write_text(original_failure, encoding="utf-8")
        self.a2_command_status.write_text(
            "preflight_rc=0\n"
            "stats_on_rc=0\n"
            "stats_off_build_rc=0\n"
            "stats_off_rc=0\n"
            "manifest_rc=0\n"
            "audit_rc=1\n"
            "postflight_rc=1\n"
            "verify_rc=1\n"
            "cleanup_rc=0\n"
            "stats_off_build_bytes_deleted=230259728\n",
            encoding="utf-8",
        )
        self.postflight.write_text(
            "[ARCH-STABLE] status=ARCH_STABLE ppa=UNQUALIFIED "
            "promotion_eligible=false blockers=0\n",
            encoding="utf-8",
        )

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

    def copy_runs(self, source: pathlib.Path, stem: str) -> list[pathlib.Path]:
        paths = []
        for index in range(1, 4):
            destination = self.work / f"{stem}-rep{index}.log"
            shutil.copyfile(source, destination)
            paths.append(destination)
        return paths

    def make_stats_off(self, source: pathlib.Path, name: str) -> pathlib.Path:
        text = source.read_text(encoding="utf-8")
        self.assertIn("available=1", text)
        rewritten = []
        for line in text.splitlines(keepends=True):
            if "COUNTERS_FINAL" in line:
                def replace_counter(match):
                    key, value = match.group(1), match.group(2)
                    if key in {"complete", "available", "conservation"}:
                        return f"{key}=0"
                    if (key.startswith("cycle_") or key.startswith("slot_")
                            or key in {"slot_capacity", "retired_slots", "unused_slots"}):
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
            cwd=ROOT,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            check=False,
        )

    def prepare_source_execution(self, coremark: list[pathlib.Path]) -> None:
        arch_stable = json.loads(ARCH_STABLE.read_text(encoding="utf-8"))
        design_id = arch_stable["design_id"]
        source = {
            "schema": "npc-rv64-performance-baseline-run-manifest-v1",
            "design_id": design_id,
            "arch_stable_result": self.artifact_record(ARCH_STABLE),
            "measurement_contract": self.artifact_record(CONTRACT),
            "counter_schema": self.artifact_record(COUNTER),
            "policy": self.artifact_record(POLICY),
            "simulator": self.artifact_record(SIMULATOR),
            "config": self.artifact_record(CONFIG),
            "workloads": {
                "coremark": {
                    "image": self.artifact_record(COREMARK_IMAGE),
                    "logs": [self.artifact_record(path) for path in coremark],
                },
                "dhrystone_10000": {
                    "image": self.artifact_record(DHRYSTONE_IMAGE),
                    "logs": [self.artifact_record(path) for path in self.dhrystone_logs],
                },
            },
            "instrumentation_noninterference": {
                "mode": "CONFIG_NPC_OOO_STATS=n",
                "stats_off_simulator": self.artifact_record(
                    self.stats_off_simulator),
                "logs": {
                    "coremark": self.artifact_record(self.coremark_off),
                    "dhrystone_10000": self.artifact_record(self.dhrystone_off),
                },
            },
        }
        self.source_manifest.write_text(
            json.dumps(source, indent=2, sort_keys=True) + "\n", encoding="utf-8")
        baseline = json.loads(
            BASELINE_CONTRACT_TEMPLATE.read_text(encoding="utf-8"))
        candidate_path = ROOT / arch_stable["candidate"]["path"]
        baseline["current_arch_stable_binding"] = {
            "design_id": design_id,
            "result": self.artifact_record(ARCH_STABLE),
            "candidate": self.artifact_record(candidate_path),
            "simulator_sha256": self.artifact_record(SIMULATOR)["sha256"],
            "config_sha256": self.artifact_record(CONFIG)["sha256"],
        }
        baseline["measurement_contract"] = self.artifact_record(CONTRACT)
        baseline["counter_schema"] = self.artifact_record(COUNTER)
        baseline["boundary_qualification_amendment"] = self.artifact_record(
            AMENDMENT)
        baseline["policy"] = self.artifact_record(POLICY)
        baseline["historical_execution_source"].update({
            "a1_original_status": self.artifact_record(self.a1_status),
            "a2_original_status": self.artifact_record(self.a2_status),
            "a2_command_status": self.artifact_record(self.a2_command_status),
            "a2_manifest": self.artifact_record(self.source_manifest),
        })
        self.baseline_contract.write_text(
            json.dumps(baseline, indent=2, sort_keys=True) + "\n", encoding="utf-8")

    def write_manifest(
        self, *, duplicate_coremark: bool = False, bind_postflight: bool = True,
    ) -> None:
        coremark = self.coremark_logs
        if duplicate_coremark:
            coremark = [self.coremark_logs[0]] * 3
        self.prepare_source_execution(coremark)
        command = [
            "manifest",
            "--output", self.relative(self.manifest),
            "--arch-stable-result", self.relative(ARCH_STABLE),
            "--baseline-contract", self.relative(self.baseline_contract),
            "--measurement-contract", self.relative(CONTRACT),
            "--counter-schema", self.relative(COUNTER),
            "--boundary-qualification-amendment", self.relative(AMENDMENT),
            "--policy", self.relative(POLICY),
            "--simulator", self.relative(SIMULATOR),
            "--config", self.relative(CONFIG),
            "--coremark-image", self.relative(COREMARK_IMAGE),
            "--dhrystone-image", self.relative(DHRYSTONE_IMAGE),
            "--stats-off-simulator", self.relative(self.stats_off_simulator),
            "--coremark-stats-off-log", self.relative(self.coremark_off),
            "--dhrystone-stats-off-log", self.relative(self.dhrystone_off),
            "--source-a1-status", self.relative(self.a1_status),
            "--source-a2-status", self.relative(self.a2_status),
            "--source-a2-command-status", self.relative(self.a2_command_status),
            "--source-a2-manifest", self.relative(self.source_manifest),
        ]
        for path in coremark:
            command.extend(("--coremark-log", self.relative(path)))
        for path in self.dhrystone_logs:
            command.extend(("--dhrystone-log", self.relative(path)))
        completed = self.run_tool(*command)
        self.assertEqual(completed.returncode, 0, completed.stdout)
        if bind_postflight:
            completed = self.run_tool(
                "bind-postflight",
                "--manifest", self.relative(self.manifest),
                "--postflight-log", self.relative(self.postflight),
                "--output", self.relative(self.manifest),
            )
            self.assertEqual(completed.returncode, 0, completed.stdout)

    def build(self) -> subprocess.CompletedProcess[str]:
        return self.run_tool(
            "build",
            "--manifest", self.relative(self.manifest),
            "--output", self.relative(self.result),
            "--require-baseline",
        )

    def set_dhrystone_endpoint_mismatch(
        self, path: pathlib.Path, *, conserve: bool,
    ) -> None:
        text = path.read_text(encoding="utf-8")
        text = text.replace(
            "BOUNDARY kind=start pc=0x0000000080000334 cycle=10 "
            "retired_before=20 lane=0",
            "BOUNDARY kind=start pc=0x0000000080000334 cycle=10 "
            "retired_before=20 lane=1",
        ).replace(
            "start_lane=0 end_lane=0 phase_aligned=1",
            "start_lane=1 end_lane=0 phase_aligned=0",
        )
        if conserve:
            text = text.replace(
                "slot_capacity=200 retired_slots=100 unused_slots=100 "
                "slot_rob_empty=20",
                "slot_capacity=199 retired_slots=100 unused_slots=99 "
                "slot_rob_empty=19",
            )
        path.write_text(text, encoding="utf-8")

    def test_build_and_verify_current_baseline(self) -> None:
        self.write_manifest()
        built = self.build()
        self.assertEqual(built.returncode, 0, built.stdout)
        verified = self.run_tool(
            "verify", "--input", self.relative(self.result),
            "--require-baseline")
        self.assertEqual(verified.returncode, 0, verified.stdout)
        value = json.loads(self.result.read_text(encoding="utf-8"))
        self.assertEqual(value["status"], "PERF_BASELINE")
        self.assertEqual(value["ppa"], "UNQUALIFIED")
        self.assertFalse(value["promotion_eligible"])
        self.assertTrue(value["instrumentation_noninterference"]["status"] == "PASS")

    def test_historical_a2_cannot_rebind_to_current_arch_stable(self) -> None:
        replayed = self.run_tool(
            "replay-manifest",
            "--source-manifest", self.relative(A2_SOURCE_MANIFEST),
            "--baseline-contract", self.relative(BASELINE_CONTRACT_TEMPLATE),
            "--boundary-qualification-amendment", self.relative(AMENDMENT),
            "--output", self.relative(self.manifest),
        )
        self.assertEqual(replayed.returncode, 0, replayed.stdout)
        prechecked = self.run_tool(
            "precheck",
            "--manifest", self.relative(self.manifest),
            "--output", self.relative(self.precheck),
        )
        self.assertNotEqual(prechecked.returncode, 0)
        self.assertIn("ARCH_STABLE result size mismatch", prechecked.stdout)

    def test_legacy_a2_manifest_is_historical_not_current(self) -> None:
        completed = self.run_tool(
            "build",
            "--manifest", self.relative(A2_SOURCE_MANIFEST),
            "--output", self.relative(self.result),
            "--require-baseline",
        )
        self.assertNotEqual(completed.returncode, 0)
        self.assertIn("ARCH_STABLE result size mismatch", completed.stdout)

    def test_historical_review_cannot_publish_as_current(self) -> None:
        published = self.run_tool(
            "publish",
            "--review", self.relative(HISTORICAL_INDEPENDENT_REVIEW),
            "--output", self.relative(self.result),
        )
        self.assertNotEqual(published.returncode, 0)
        self.assertIn("ARCH_STABLE result size mismatch", published.stdout)

    def test_publish_rejects_nonapproval(self) -> None:
        review = json.loads(
            HISTORICAL_INDEPENDENT_REVIEW.read_text(encoding="utf-8"))
        review["decision"] = "REJECT_PERF_BASELINE"
        rejected = self.work / "rejected-review.json"
        rejected.write_text(json.dumps(review), encoding="utf-8")
        published = self.run_tool(
            "publish",
            "--review", self.relative(rejected),
            "--output", self.relative(self.result),
        )
        self.assertNotEqual(published.returncode, 0)
        self.assertIn("independent review decision mismatch", published.stdout)

    def test_current_result_and_review_match_json_schemas(self) -> None:
        current_result = json.loads(CURRENT_RESULT.read_text(encoding="utf-8"))
        current_review = json.loads(
            CURRENT_INDEPENDENT_REVIEW.read_text(encoding="utf-8"))
        result_schema_path = {
            "npc-rv64-performance-baseline-current-v2": RESULT_SCHEMA_V2,
            "npc-rv64-performance-baseline-current-v3": RESULT_SCHEMA_V3,
        }[current_result["schema"]]
        review_schema_path = {
            "npc-rv64-performance-baseline-independent-review-v1": (
                REVIEW_SCHEMA_V1),
            "npc-rv64-performance-baseline-independent-review-v2": (
                REVIEW_SCHEMA_V2),
        }[current_review["schema"]]
        result_schema = json.loads(
            result_schema_path.read_text(encoding="utf-8"))
        review_schema = json.loads(
            review_schema_path.read_text(encoding="utf-8"))
        jsonschema.Draft202012Validator.check_schema(result_schema)
        jsonschema.Draft202012Validator.check_schema(review_schema)
        jsonschema.validate(current_result, result_schema)
        jsonschema.validate(current_review, review_schema)

    def test_reused_raw_log_path_is_rejected(self) -> None:
        self.write_manifest(duplicate_coremark=True)
        completed = self.build()
        self.assertNotEqual(completed.returncode, 0)
        self.assertIn("raw log path is reused", completed.stdout)

    def test_tampered_log_after_manifest_is_rejected(self) -> None:
        self.write_manifest()
        self.coremark_logs[1].write_text(
            self.coremark_logs[1].read_text(encoding="utf-8").replace(
                "cycle_useful=60", "cycle_useful=61", 1),
            encoding="utf-8",
        )
        completed = self.build()
        self.assertNotEqual(completed.returncode, 0)
        self.assertIn("sha256 mismatch", completed.stdout)

    def test_non_bit_exact_counter_is_rejected(self) -> None:
        self.coremark_logs[1].write_text(
            self.coremark_logs[1].read_text(encoding="utf-8").replace(
                "cycle_useful=60 cycle_rob_empty=10",
                "cycle_useful=59 cycle_rob_empty=11", 1),
            encoding="utf-8",
        )
        self.write_manifest()
        completed = self.build()
        self.assertNotEqual(completed.returncode, 0)
        self.assertIn("repetition counters are not bit-exact", completed.stdout)

    def test_stats_off_available_one_is_rejected(self) -> None:
        shutil.copyfile(FIXTURES / "coremark-valid.log", self.coremark_off)
        self.write_manifest()
        completed = self.build()
        self.assertNotEqual(completed.returncode, 0)
        self.assertIn("counter availability mismatch", completed.stdout)

    def test_stats_on_off_cycle_mismatch_is_rejected(self) -> None:
        text = self.coremark_off.read_text(encoding="utf-8")
        self.coremark_off.write_text(
            text.replace("kind=end pc=0x00000000800017b0 cycle=110",
                         "kind=end pc=0x00000000800017b0 cycle=111")
                .replace("end_cycle=110", "end_cycle=111")
                .replace("cycles=100", "cycles=101"),
            encoding="utf-8",
        )
        self.write_manifest()
        completed = self.build()
        self.assertNotEqual(completed.returncode, 0)
        self.assertIn("stats on/off cycle mismatch", completed.stdout)

    def test_stats_off_boundary_final_mismatch_is_rejected(self) -> None:
        text = self.coremark_off.read_text(encoding="utf-8")
        self.coremark_off.write_text(
            text.replace("kind=end pc=0x00000000800017b0 cycle=110",
                         "kind=end pc=0x00000000800017b0 cycle=111"),
            encoding="utf-8",
        )
        self.write_manifest()
        completed = self.build()
        self.assertNotEqual(completed.returncode, 0)
        self.assertIn("stats-off region cycle delta mismatch", completed.stdout)

    def test_stats_off_simulator_must_differ(self) -> None:
        self.stats_off_simulator = SIMULATOR
        self.write_manifest()
        completed = self.build()
        self.assertNotEqual(completed.returncode, 0)
        self.assertIn("must differ", completed.stdout)

    def test_precheck_cannot_publish_without_postflight(self) -> None:
        self.write_manifest(bind_postflight=False)
        prechecked = self.run_tool(
            "precheck",
            "--manifest", self.relative(self.manifest),
            "--output", self.relative(self.precheck),
        )
        self.assertEqual(prechecked.returncode, 0, prechecked.stdout)
        value = json.loads(self.precheck.read_text(encoding="utf-8"))
        self.assertEqual(value["status"], "PERF_BASELINE_PRECHECK")
        self.assertTrue(value["blockers"])
        built = self.build()
        self.assertNotEqual(built.returncode, 0)
        self.assertIn("postflight ARCH_STABLE verify log artifact", built.stdout)

    def test_bad_postflight_marker_is_rejected(self) -> None:
        self.postflight.write_text(
            "[ARCH-STABLE] status=ARCH_STABLE ppa=UNQUALIFIED "
            "promotion_eligible=false blockers=1\n",
            encoding="utf-8",
        )
        self.write_manifest()
        completed = self.build()
        self.assertNotEqual(completed.returncode, 0)
        self.assertIn("postflight ARCH_STABLE PASS marker mismatch", completed.stdout)

    def test_original_fail_status_rewrite_is_rejected(self) -> None:
        self.a2_status.write_text(
            "PASS rc=0 stage=evidence-complete evidence_complete=1 cleanup_rc=0\n",
            encoding="utf-8",
        )
        self.write_manifest()
        completed = self.build()
        self.assertNotEqual(completed.returncode, 0)
        self.assertIn("A2 original FAIL status changed", completed.stdout)

    def test_dhrystone_endpoint_correction_is_accepted(self) -> None:
        for path in self.dhrystone_logs:
            self.set_dhrystone_endpoint_mismatch(path, conserve=True)
        self.write_manifest()
        completed = self.build()
        self.assertEqual(completed.returncode, 0, completed.stdout)
        value = json.loads(self.result.read_text(encoding="utf-8"))
        dhrystone = value["benchmarks"]["dhrystone_10000"]
        self.assertEqual(dhrystone["retire_slots"]["capacity"], 199)
        self.assertTrue(dhrystone["bit_exact"])

    def test_dhrystone_bad_endpoint_capacity_is_rejected(self) -> None:
        for path in self.dhrystone_logs:
            self.set_dhrystone_endpoint_mismatch(path, conserve=False)
        self.write_manifest()
        completed = self.build()
        self.assertNotEqual(completed.returncode, 0)
        self.assertIn("endpoint-corrected slot capacity mismatch", completed.stdout)


if __name__ == "__main__":
    unittest.main()
