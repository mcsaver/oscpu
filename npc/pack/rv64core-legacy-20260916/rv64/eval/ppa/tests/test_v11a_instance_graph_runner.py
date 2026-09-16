#!/usr/bin/env python3
"""Fail-closed publication tests for the V11A instance-graph runner."""

from __future__ import annotations

import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import textwrap
import unittest


REPO_ROOT = Path(__file__).resolve().parents[5]
RUN_ID = "2026-07-29-rv64-v11a-producer-holder-instance-graph"
RUNNER = REPO_ROOT / f".github/task-runs/{RUN_ID}/run-instance-graph.sh"
STATUS_HELPER = REPO_ROOT / "scripts/task-run-status.sh"

RUNNER_SOURCE_PATHS = (
    "npc/rv64/Makefile",
    "npc/rv64/configs/product-rtl-defaults.mk",
    "npc/rv64/design/arch/producer-holder-census.json",
    "npc/rv64/eval/ppa/tools/arch_stable_freeze.py",
    "npc/rv64/eval/ppa/tools/producer_holder_census.py",
    "npc/rv64/eval/ppa/tools/producer_holder_instance_graph.py",
    "npc/rv64/eval/ppa/tests/test_arch_stable_freeze.py",
    "npc/rv64/eval/ppa/tests/test_producer_holder_census.py",
    "npc/rv64/eval/ppa/tests/test_producer_holder_instance_graph.py",
    "npc/rv64/eval/ppa/tests/test_v11a_instance_graph_runner.py",
    "scripts/tests/test-task-run-status.sh",
)

CANONICAL_EVIDENCE = {
    "holder-instance-graph.json": (
        b'{"design_id":"sha256:'
        b'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",'
        b'"fixture":"result"}\n'
    ),
    "yosys-instance-graph-receipt.json": b'{"fixture":"receipt"}\n',
    "yosys-instance-graph.full.json.gz": b"fixture-full-gzip\n",
    "yosys-instance-graph.ys": b"# fixture yosys script\n",
    "yosys-instance-graph.log": b"fixture yosys log\n",
}

FAKE_PYTHON = r"""#!/usr/bin/env bash
set -euo pipefail

if [[ "${1:-}" == "-m" ]]; then
  exit "${V11A_FAKE_UNIT_RC:-0}"
fi

tool="${1:-}"
shift || true
repo_root=$(CDPATH= cd -- "$(dirname -- "$tool")/../../../../.." && pwd)
evidence_dir="$repo_root/.github/task-runs/2026-07-29-rv64-v11a-producer-holder-instance-graph/evidence"

if [[ "$tool" == */producer_holder_instance_graph.py ]]; then
  mode="frozen"
  json_out=""
  receipt_out=""
  full_out=""
  script_out=""
  log_out=""
  while [[ "$#" -gt 0 ]]; do
    case "$1" in
      --elaborate)
        mode="elaborate"
        shift
        ;;
      --json-out)
        json_out="$2"
        shift 2
        ;;
      --receipt-out)
        receipt_out="$2"
        shift 2
        ;;
      --full-json-out)
        full_out="$2"
        shift 2
        ;;
      --script-out)
        script_out="$2"
        shift 2
        ;;
      --log-out)
        log_out="$2"
        shift 2
        ;;
      --timeout-seconds)
        shift 2
        ;;
      *)
        shift
        ;;
    esac
  done
  if [[ "$mode" == "elaborate" ]]; then
    cp "$evidence_dir/holder-instance-graph.json" "$json_out"
    cp "$evidence_dir/yosys-instance-graph-receipt.json" "$receipt_out"
    cp "$evidence_dir/yosys-instance-graph.full.json.gz" "$full_out"
    cp "$evidence_dir/yosys-instance-graph.ys" "$script_out"
    cp "$evidence_dir/yosys-instance-graph.log" "$log_out"
    if [[ "${V11A_FAKE_FULL_JSON_MISMATCH:-0}" == "1" ]]; then
      printf '%s\n' "full-json-drift" >> "$full_out"
    fi
  fi
  printf '%s\n' "[fixture-instance-graph] PASS"
  exit 0
fi

if [[ "$tool" == */producer_holder_census.py ]]; then
  if [[ "${V11A_FAKE_SOURCE_DRIFT:-0}" == "1" ]]; then
    printf '%s\n' "# injected source drift" >> "$repo_root/npc/rv64/Makefile"
  fi
  printf '%s\n' "[fixture-census] PASS"
  exit 0
fi

printf '%s\n' "unexpected fixture python invocation: $tool $*" >&2
exit 97
"""

FAKE_RM = r"""#!/usr/bin/env bash
set -euo pipefail

if [[ "${V11A_FAKE_CLEANUP_SIGNAL:-0}" == "1" &&
      "$*" == *"/rv64-holder-instance-graph."* ]]; then
  /bin/rm "$@"
  kill -TERM "$PPID"
  exit 0
fi
exec /bin/rm "$@"
"""


class V11AInstanceGraphRunnerTests(unittest.TestCase):
    def setUp(self) -> None:
        self.temp = tempfile.TemporaryDirectory(
            prefix="v11a-instance-runner-test-"
        )
        self.root = Path(self.temp.name) / "repo"
        self.run_dir = self.root / f".github/task-runs/{RUN_ID}"
        self.evidence_dir = self.run_dir / "evidence"
        self.runner = self.run_dir / "run-instance-graph.sh"
        self.status = self.run_dir / "v11a-instance-graph.status"
        self.summary = self.evidence_dir / "runner-summary.log"

        self.evidence_dir.mkdir(parents=True)
        shutil.copy2(RUNNER, self.runner)
        self.runner.chmod(0o755)

        helper = self.root / "scripts/task-run-status.sh"
        helper.parent.mkdir(parents=True)
        shutil.copy2(STATUS_HELPER, helper)

        for relative in RUNNER_SOURCE_PATHS:
            target = self.root / relative
            target.parent.mkdir(parents=True, exist_ok=True)
            if not target.exists():
                target.write_text(f"# fixture: {relative}\n", encoding="utf-8")
        shutil.copy2(
            REPO_ROOT / "scripts/tests/test-task-run-status.sh",
            self.root / "scripts/tests/test-task-run-status.sh",
        )

        for name, payload in CANONICAL_EVIDENCE.items():
            (self.evidence_dir / name).write_bytes(payload)

        fake_bin = self.root / "fixture-bin"
        fake_bin.mkdir()
        fake_python = fake_bin / "python3"
        fake_python.write_text(
            textwrap.dedent(FAKE_PYTHON), encoding="utf-8"
        )
        fake_python.chmod(0o755)
        fake_rm = fake_bin / "rm"
        fake_rm.write_text(textwrap.dedent(FAKE_RM), encoding="utf-8")
        fake_rm.chmod(0o755)

        self.env = os.environ.copy()
        self.env["PATH"] = f"{fake_bin}:/usr/bin:/bin"

    def tearDown(self) -> None:
        self.temp.cleanup()

    def run_runner(
        self, *, extra_env: dict[str, str] | None = None
    ) -> subprocess.CompletedProcess[str]:
        env = self.env.copy()
        if extra_env:
            env.update(extra_env)
        return subprocess.run(
            ["/bin/bash", str(self.runner)],
            cwd=self.root,
            env=env,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            check=False,
            timeout=20,
        )

    def assert_fail_status(
        self,
        completed: subprocess.CompletedProcess[str],
        *,
        stage: str,
    ) -> None:
        self.assertNotEqual(completed.returncode, 0, completed.stdout)
        status = self.status.read_text(encoding="utf-8")
        summary = self.summary.read_text(encoding="utf-8")
        self.assertTrue(status.startswith("FAIL "), status)
        self.assertIn(f"stage={stage}", status)
        self.assertIn("evidence_complete=0", status)
        self.assertIn("[V11A-INSTANCE-GRAPH][FAIL]", summary)
        self.assertNotIn("[V11A-INSTANCE-GRAPH][PASS]", summary)

    def test_success_publishes_pass_only_after_all_five_artifacts(self) -> None:
        completed = self.run_runner()
        self.assertEqual(completed.returncode, 0, completed.stdout)
        self.assertEqual(self.status.read_text(encoding="utf-8"), "PASS\n")
        summary = self.summary.read_text(encoding="utf-8")
        self.assertIn(
            "result_receipt_full_script_log=byte-identical", summary
        )
        self.assertIn("[V11A-INSTANCE-GRAPH][PASS]", summary)

    def test_missing_status_helper_overwrites_stale_terminal_state(self) -> None:
        self.status.write_text("PASS\n", encoding="utf-8")
        self.summary.write_text(
            "[V11A-INSTANCE-GRAPH][PASS] stale\n", encoding="utf-8"
        )
        (self.root / "scripts/task-run-status.sh").unlink()
        completed = self.run_runner()
        self.assert_fail_status(completed, stage="pre-helper")

    def test_unit_failure_is_terminal_fail(self) -> None:
        completed = self.run_runner(
            extra_env={"V11A_FAKE_UNIT_RC": "7"}
        )
        self.assert_fail_status(completed, stage="instance-graph-unit")

    def test_full_yosys_mismatch_is_terminal_fail(self) -> None:
        completed = self.run_runner(
            extra_env={"V11A_FAKE_FULL_JSON_MISMATCH": "1"}
        )
        self.assert_fail_status(completed, stage="byte-identical-result")

    def test_bound_source_drift_is_terminal_fail(self) -> None:
        completed = self.run_runner(
            extra_env={"V11A_FAKE_SOURCE_DRIFT": "1"}
        )
        self.assert_fail_status(completed, stage="source-post-hash")

    def test_cleanup_signal_is_recorded_as_terminal_fail(self) -> None:
        completed = self.run_runner(
            extra_env={"V11A_FAKE_CLEANUP_SIGNAL": "1"}
        )
        self.assertEqual(completed.returncode, 143, completed.stdout)
        self.assert_fail_status(completed, stage="final-cleanup")
        self.assertIn(
            "signal=TERM", self.status.read_text(encoding="utf-8")
        )


if __name__ == "__main__":
    unittest.main()
