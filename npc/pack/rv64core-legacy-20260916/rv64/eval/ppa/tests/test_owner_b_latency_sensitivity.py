#!/usr/bin/env python3

from __future__ import annotations

from contextlib import redirect_stderr
import io
import json
import os
import pathlib
import subprocess
import tempfile
import unittest
from unittest import mock

ROOT = pathlib.Path(__file__).resolve().parents[5]
TOOLS = ROOT / "npc/rv64/eval/ppa/tools"
REPLAY_RUNNER = ROOT / "npc/rv64/eval/ppa/replay-owner-b-latency-sensitivity.sh"
import sys

if str(TOOLS) not in sys.path:
    sys.path.insert(0, str(TOOLS))

import owner_b_latency_sensitivity as probe  # noqa: E402


class OwnerBLatencySensitivityTests(unittest.TestCase):
    def write(self, directory: pathlib.Path, name: str, text: str) -> pathlib.Path:
        path = directory / name
        path.write_text(text, encoding="utf-8")
        return path

    def test_exact_module_rename_is_accepted(self) -> None:
        with tempfile.TemporaryDirectory() as raw:
            directory = pathlib.Path(raw)
            original = self.write(
                directory, "AxiDpiSlave.sv",
                "header\nmodule AxiDpiSlave (\nports\n);\nendmodule\n")
            generated = self.write(
                directory, "AxiDpiSlaveOwnerBDelayBase.sv",
                "header\nmodule AxiDpiSlaveOwnerBDelayBase (\nports\n);\nendmodule\n")
            probe.validate_generated_base(original, generated)

    def test_non_name_source_drift_is_rejected(self) -> None:
        with tempfile.TemporaryDirectory() as raw:
            directory = pathlib.Path(raw)
            original = self.write(
                directory, "AxiDpiSlave.sv",
                "module AxiDpiSlave (\nports\n);\nendmodule\n")
            generated = self.write(
                directory, "AxiDpiSlaveOwnerBDelayBase.sv",
                "module AxiDpiSlaveOwnerBDelayBase (\nchanged\n);\nendmodule\n")
            with self.assertRaisesRegex(probe.EvidenceError, "differs beyond"):
                probe.validate_generated_base(original, generated)

    def marker_text(self, delay: int) -> str:
        return "\n".join(
            f"[OWNER-B-LATENCY-PROBE] instance=TOP.NpcSimTop.{name} "
            f"delay_cycles={delay} mode=test-only"
            for name in sorted(probe.EXPECTED_INSTANCES)) + "\n"

    def test_exact_probe_instance_set_is_accepted(self) -> None:
        with tempfile.TemporaryDirectory() as raw:
            path = self.write(pathlib.Path(raw), "run.log", self.marker_text(2))
            self.assertEqual(
                probe.parse_probe_markers(path, 2), sorted(probe.EXPECTED_INSTANCES))

    def test_probe_delay_mismatch_is_rejected(self) -> None:
        with tempfile.TemporaryDirectory() as raw:
            path = self.write(pathlib.Path(raw), "run.log", self.marker_text(0))
            with self.assertRaisesRegex(probe.EvidenceError, "delay marker mismatch"):
                probe.parse_probe_markers(path, 2)

    def test_duplicate_probe_instance_is_rejected(self) -> None:
        with tempfile.TemporaryDirectory() as raw:
            text = self.marker_text(2).replace(
                "u_sdram_slave", "u_psram_slave")
            path = self.write(pathlib.Path(raw), "run.log", text)
            with self.assertRaisesRegex(probe.EvidenceError, "instance set mismatch"):
                probe.parse_probe_markers(path, 2)

    def execution_text(self) -> str:
        return "\n".join(
            f"delay={delay} workload={workload} repetition={repetition} "
            "rc=0 assertion_markers=0"
            for delay in probe.DELAYS
            for workload in probe.WORKLOADS
            for repetition in range(1, probe.REPETITIONS + 1)) + "\n"

    def test_execution_matrix_requires_all_twelve_cases(self) -> None:
        with tempfile.TemporaryDirectory() as raw:
            path = self.write(pathlib.Path(raw), "status.txt", self.execution_text())
            self.assertEqual(probe.validate_execution_status(path)["cases"], 12)
            path.write_text("\n".join(path.read_text().splitlines()[:-1]) + "\n")
            with self.assertRaisesRegex(probe.EvidenceError, "incomplete"):
                probe.validate_execution_status(path)

    @staticmethod
    def point(delay: int, cycles: int, b_terminal: int = 10) -> dict:
        completed_cycles = b_terminal * (4 + delay)
        return {
            "delay_cycles": delay,
            "cycles": cycles,
            "retired_instructions": 100,
            "start_hits": 1,
            "end_hits": 1,
            "start_lane": 0,
            "end_lane": 0,
            "class_events": {
                "store": {"request_fire": 20, "b_terminal": b_terminal},
                "load": {"request_fire": 30, "b_terminal": 0},
            },
            "occupancy": {
                "write_inflight_0": cycles - completed_cycles,
                "write_inflight_1": completed_cycles,
                "write_inflight_2": 0,
            },
            "b_terminal": b_terminal,
            "write_response": {
                "completed": b_terminal,
                "completed_cycles": completed_cycles,
                "rob_head_cycles": completed_cycles,
                "peer_overlap_cycles": 2 * b_terminal + delay * b_terminal,
            },
        }

    def test_positive_cycle_slope_selects_h1(self) -> None:
        summary = probe.sensitivity_summary(
            self.point(0, 1000), self.point(2, 1014), "coremark")
        workloads = {
            name: {"sensitivity": summary} for name in probe.WORKLOADS}
        decision = probe.causal_decision(workloads)
        self.assertEqual(decision["causal_hypothesis"], "H1_B_RESPONSE_LATENCY")
        self.assertTrue(decision["causal_selection_authorized"])
        self.assertEqual(summary["added_b_response_cycles"], 20)

    def test_zero_cycle_slope_remains_unresolved(self) -> None:
        positive = probe.sensitivity_summary(
            self.point(0, 1000), self.point(2, 1014), "coremark")
        zero = probe.sensitivity_summary(
            self.point(0, 1000), self.point(2, 1000), "dhrystone_10000")
        decision = probe.causal_decision({
            "coremark": {"sensitivity": positive},
            "dhrystone_10000": {"sensitivity": zero},
        })
        self.assertEqual(decision["causal_hypothesis"], "UNRESOLVED")
        self.assertFalse(decision["causal_selection_authorized"])

    def test_store_request_frequency_change_is_rejected(self) -> None:
        delay0 = self.point(0, 1000)
        delay2 = self.point(2, 1014)
        delay2["class_events"]["store"]["request_fire"] += 1
        with self.assertRaisesRegex(probe.EvidenceError, "store request frequency changed"):
            probe.sensitivity_summary(delay0, delay2, "coremark")

    def test_b_transaction_frequency_change_is_rejected(self) -> None:
        delay0 = self.point(0, 1000)
        delay2 = self.point(2, 1014)
        delay2["b_terminal"] += 1
        with self.assertRaisesRegex(probe.EvidenceError, "B terminal count changed"):
            probe.sensitivity_summary(delay0, delay2, "coremark")

    def test_load_request_retiming_is_recorded_not_rejected(self) -> None:
        delay0 = self.point(0, 1000)
        delay2 = self.point(2, 1014)
        delay2["class_events"]["load"]["request_fire"] += 7
        summary = probe.sensitivity_summary(delay0, delay2, "coremark")
        self.assertEqual(summary["request_fire_delta_by_class"]["load"], 7)
        self.assertTrue(summary["b_transaction_frequency_unchanged"])

    def test_wrong_response_slope_is_rejected(self) -> None:
        delay0 = self.point(0, 1000)
        delay2 = self.point(2, 1014)
        delay2["write_response"]["completed_cycles"] -= 1
        delay2["write_response"]["rob_head_cycles"] -= 1
        with self.assertRaisesRegex(probe.EvidenceError, "exactly two cycles"):
            probe.sensitivity_summary(delay0, delay2, "coremark")

    def test_assertion_marker_is_counted(self) -> None:
        with tempfile.TemporaryDirectory() as raw:
            path = self.write(
                pathlib.Path(raw), "run.log",
                "%Error: Assertion failed\n[OWNER-B-LATENCY-EARLY-VALID][FAIL]\n")
            self.assertGreaterEqual(probe.assertion_marker_count(path), 3)

    def canonical_causal_receipt(self, directory: pathlib.Path) -> pathlib.Path:
        source = ROOT / (
            ".github/task-runs/2026-08-08-rv64-v15z-arch-stable-act4-"
            "rebind-f72e-a1/evidence/mainline-rebind-f72e-v1/owner-causal/"
            "result.json"
        )
        value = json.loads(source.read_text(encoding="utf-8"))
        value["inputs"] = {
            name: probe.causal.artifact(ROOT, ROOT / reference["path"])
            for name, reference in value["inputs"].items()
        }
        path = directory / "causal.json"
        path.write_text(
            json.dumps(value, indent=2, sort_keys=True) + "\n",
            encoding="utf-8",
        )
        return path

    def test_causal_receipt_error_is_wrapped_without_attribute_error(self) -> None:
        runtime = ROOT / ".github/runtime-artifacts/tests"
        runtime.mkdir(parents=True, exist_ok=True)
        with tempfile.TemporaryDirectory(
            prefix="owner-b-causal-", dir=runtime,
        ) as raw:
            directory = pathlib.Path(raw)
            path = self.canonical_causal_receipt(directory)
            value = json.loads(path.read_text(encoding="utf-8"))
            with mock.patch.object(
                probe.causal, "build_receipt", return_value=value,
            ):
                verified = probe.verify_causal_receipt(path)
            self.assertEqual(verified["status"], "RESEARCH_REQUIRED")

            value["inputs"]["owner_timing_verifier"]["sha256"] = "0" * 64
            path.write_text(
                json.dumps(value, indent=2, sort_keys=True) + "\n",
                encoding="utf-8",
            )
            with self.assertRaisesRegex(
                probe.EvidenceError,
                "causal receipt cannot be rebuilt: causal input "
                "owner_timing_verifier sha256 mismatch",
            ):
                probe.verify_causal_receipt(path)

            args = mock.Mock()
            args.func = lambda _: probe.verify_causal_receipt(path)
            parser = mock.Mock()
            parser.parse_args.return_value = args
            stderr = io.StringIO()
            with mock.patch.object(probe, "parser", return_value=parser):
                with redirect_stderr(stderr):
                    return_code = probe.main()
            self.assertEqual(return_code, 2)
            self.assertIn(
                "[OWNER-B-LATENCY-SENSITIVITY][FAIL] causal receipt cannot "
                "be rebuilt: causal input owner_timing_verifier sha256 mismatch",
                stderr.getvalue(),
            )
            self.assertNotIn("AttributeError", stderr.getvalue())
            self.assertNotIn("Traceback", stderr.getvalue())

    def prepare_replay_fixture(
        self, directory: pathlib.Path, *, valid_binding: bool,
    ) -> pathlib.Path:
        run_dir = directory / "run"
        evidence = run_dir / "evidence/owner-b-latency-sensitivity"
        original = evidence / "checker-replay/original"
        original.mkdir(parents=True)
        self.write(
            run_dir,
            "owner-b-latency-sensitivity.status",
            (
                "FAIL rc=1 stage=receipt-build evidence_complete=0 cleanup_rc=0\n"
                if valid_binding else "RUNNING\n"
            ),
        )
        self.write(
            evidence,
            "command-status.txt",
            "\n".join((
                "preflight_rc=0", "l0_rc=0", "manifest_rc=0",
                "source_rc=0", "build_rc=0", "simulator_identity_rc=0",
                "execution_rc=0", "postflight_rc=0", "cleanup_rc=0",
                "cleanup_capture_rc=0", "receipt_rc=2", "verify_rc=1",
                "build_bytes_deleted=231088914",
            )) + "\n",
        )
        self.write(original, "owner_b_latency_sensitivity.py", "frozen\n")
        self.write(original, "run-owner-b-latency-sensitivity.sh", "frozen\n")
        return run_dir

    def write_python_stub(self, directory: pathlib.Path) -> pathlib.Path:
        stub = self.write(
            directory,
            "python3",
            """#!/usr/bin/env bash
set -uo pipefail
fail_stage=${OWNER_B_REPLAY_TEST_FAIL_STAGE:-none}
case " $* " in
  *" -m unittest "*)
    [[ "${fail_stage}" == unit-tests ]] && exit 41
    exit 0
    ;;
  *" build "*)
    [[ "${fail_stage}" == build ]] && exit 42
    output=
    while [[ $# -gt 0 ]]; do
      if [[ "$1" == --output ]]; then
        output=$2
        break
      fi
      shift
    done
    [[ -n "${output}" ]] || exit 44
    printf '%s\\n' '{"stub":true}' >"${output}"
    exit 0
    ;;
  *" verify "*)
    [[ "${fail_stage}" == verify ]] && exit 43
    exit 0
    ;;
esac
exit 45
""",
        )
        stub.chmod(0o755)
        return stub

    def test_replay_runner_fails_closed_at_each_required_stage(self) -> None:
        task_runs = ROOT / ".github/task-runs"
        with tempfile.TemporaryDirectory(
            prefix="owner-b-replay-negative-", dir=task_runs,
        ) as raw:
            root = pathlib.Path(raw)
            stub_dir = root / "bin"
            stub_dir.mkdir()
            self.write_python_stub(stub_dir)
            for stage, expected_rc, expected_stage in (
                ("binding", 1, "original-failure-binding"),
                ("unit-tests", 41, "checker-negative-tests"),
                ("build", 42, "checker-replay-build"),
                ("verify", 43, "checker-replay-verify"),
            ):
                with self.subTest(stage=stage):
                    case_dir = root / stage
                    case_dir.mkdir()
                    run_dir = self.prepare_replay_fixture(
                        case_dir, valid_binding=stage != "binding")
                    environment = os.environ.copy()
                    environment["PATH"] = (
                        f"{stub_dir}:{environment.get('PATH', '')}")
                    environment["OWNER_B_REPLAY_TEST_FAIL_STAGE"] = stage
                    completed = subprocess.run(
                        ["bash", str(REPLAY_RUNNER), "--run-dir", str(run_dir)],
                        cwd=ROOT,
                        env=environment,
                        text=True,
                        stdout=subprocess.PIPE,
                        stderr=subprocess.STDOUT,
                        check=False,
                    )
                    self.assertEqual(completed.returncode, expected_rc, completed.stdout)
                    status = (
                        run_dir / "evidence/owner-b-latency-sensitivity/"
                        "checker-replay-v2/checker-replay.status"
                    ).read_text(encoding="utf-8").strip()
                    self.assertEqual(
                        status,
                        f"FAIL rc={expected_rc} stage={expected_stage} "
                        "evidence_complete=0 cleanup_rc=0",
                    )

    def test_replay_runner_marks_pass_only_after_all_required_stages(self) -> None:
        task_runs = ROOT / ".github/task-runs"
        with tempfile.TemporaryDirectory(
            prefix="owner-b-replay-positive-", dir=task_runs,
        ) as raw:
            root = pathlib.Path(raw)
            stub_dir = root / "bin"
            stub_dir.mkdir()
            self.write_python_stub(stub_dir)
            run_dir = self.prepare_replay_fixture(root, valid_binding=True)
            environment = os.environ.copy()
            environment["PATH"] = f"{stub_dir}:{environment.get('PATH', '')}"
            completed = subprocess.run(
                ["bash", str(REPLAY_RUNNER), "--run-dir", str(run_dir)],
                cwd=ROOT,
                env=environment,
                text=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                check=False,
            )
            self.assertEqual(completed.returncode, 0, completed.stdout)
            status = (
                run_dir / "evidence/owner-b-latency-sensitivity/"
                "checker-replay-v2/checker-replay.status"
            ).read_text(encoding="utf-8").strip()
            self.assertEqual(status, "PASS")


if __name__ == "__main__":
    unittest.main()
