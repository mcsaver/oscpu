from __future__ import annotations

import contextlib
import io
import json
import os
import pathlib
import shutil
import subprocess
import tempfile
import unittest
import uuid
from unittest import mock

from npc.rv64.eval.ppa.tools import full_core_current_evidence as module_evidence
from npc.rv64.eval.ppa.tools import full_core_functional_evidence as functional


ROOT = module_evidence.ROOT
RUNNER = ROOT / "npc/rv64/eval/ppa/run-full-core-current.sh"
POLICY = ROOT / "npc/rv64/design/arch/full-core-functional-run-policy-v1.json"


class FullCoreRunnerEntryTests(unittest.TestCase):
    def test_policy_has_immutable_fail_closed_contract(self) -> None:
        policy = json.loads(POLICY.read_text(encoding="utf-8"))
        self.assertEqual(
            policy["entrypoints"]["current"],
            "npc/rv64/eval/ppa/run-full-core-current.sh",
        )
        self.assertFalse(policy["run_directory"]["overwrite_or_reset_existing_run"])
        self.assertFalse(
            policy["configuration_control"]["workspace_default_defconfig_rewrite"]
        )
        self.assertFalse(policy["status_contract"]["exit_code_zero_alone_can_pass"])
        self.assertFalse(policy["publication"]["enabled_by_default"])
        self.assertFalse(
            policy["publication"]["execution_result_mutated_by_publication"]
        )
        self.assertIn("full-core-publication.status", policy["publication"]["status"])
        self.assertTrue(policy["publication"]["commit_marker_order"].startswith("last"))
        self.assertIn("same-run", policy["semantic_revalidation"]["source_run"])
        self.assertIn("177 test ids", policy["semantic_revalidation"]["official_membership"])
        self.assertIn("guest benchmark", policy["publication"]["downstream_f0_consumer"])
        self.assertIn("Makefile.*", policy["build_isolation"]["source_tree_observation"])
        self.assertEqual(policy["retention"]["compiled_intermediates_retained"], 0)

    def test_legacy_help_and_no_argument_do_not_enter_fixed_output_body(self) -> None:
        legacy = functional.load_legacy_runner()
        with mock.patch.object(
            legacy,
            "_retired_fixed_output_implementation",
            side_effect=AssertionError("retired body entered"),
        ), mock.patch.object(
            legacy,
            "reset_generated_dir",
            side_effect=AssertionError("historical evidence reset"),
        ), contextlib.redirect_stdout(io.StringIO()), contextlib.redirect_stderr(
            io.StringIO()
        ):
            with self.assertRaises(SystemExit) as help_exit:
                legacy.main(["--help"])
            self.assertEqual(help_exit.exception.code, 0)
            with self.assertRaises(SystemExit) as no_arg_exit:
                legacy.main([])
            self.assertEqual(no_arg_exit.exception.code, 2)

    def test_reference_and_am_build_roots_are_explicitly_isolated(self) -> None:
        legacy = functional.load_legacy_runner()
        temporary = pathlib.Path("/tmp/full-core-contract-fixture")
        command = functional.reference_build_args(legacy, temporary)
        self.assertIn(f"BUILD_DIR={temporary / 'nemu-work/build'}", command)
        self.assertFalse(any(item.startswith("WORK_DIR=") for item in command))
        self.assertNotIn("difftest-ref", command)
        makefile = (ROOT / "abstract-machine/Makefile").read_text(encoding="utf-8")
        self.assertIn("AM_BUILD_ROOT ?=", makefile)
        self.assertIn("AM_BUILD_ROOT_ABS", makefile)
        self.assertIn("lib_archive =", makefile)
        self.assertIn("archive MAKEOVERRIDES=", makefile)
        self.assertIn("AM_LIBRARY_RECURSIVE=1 NAME=$(1)", makefile)
        for library in ("am", "klib"):
            child = (ROOT / f"abstract-machine/{library}/Makefile").read_text(
                encoding="utf-8"
            )
            self.assertIn("ifeq ($(AM_LIBRARY_RECURSIVE),1)", child)
            self.assertIn("override SRCS", child)
        self.assertIn("rm -rf $(AM_BUILD_ROOT_ABS)", makefile)

    def _functional_fixture(self, output_dir: pathlib.Path) -> pathlib.Path:
        output_dir.mkdir(parents=True)
        design_id = "sha256:" + "a" * 64
        payloads = {
            "functional-aggregate.json": {"status": "PASS"},
            "functional-aggregate-result.json": {"status": "PASS"},
            "inputs.pre.json": {"binding": "same"},
            "inputs.post.json": {"binding": "same"},
        }
        for name, value in payloads.items():
            module_evidence.write_json(output_dir / name, value)
        module_result_path = output_dir.parent / "module/result.json"
        module_evidence.write_json(module_result_path, {"status": "PASS"})
        (output_dir / "functional-aggregate.log").write_text(
            "[FUNCTIONAL-AGGREGATE][PASS]\n", encoding="utf-8"
        )
        (output_dir / "frozen").mkdir()
        (output_dir / "frozen/NpcSimTop").write_bytes(b"simulator")
        (output_dir / "frozen/riscv64-nemu-interpreter-so").write_bytes(
            b"reference"
        )
        (output_dir / "frozen/npc.config").write_text(
            "CONFIG_NPC_DIFFTEST=y\n", encoding="utf-8"
        )
        result = {
            "schema": functional.SCHEMA,
            "status": "PASS",
            "design_id": design_id,
            "counts": {
                "module_passed": 1,
                "module_required": 1,
                "official_passed": 177,
                "official_required": 177,
                "am_passed": 1,
                "am_required": 1,
                "difftest_mismatches": 0,
                "evidence_mutations_compiled": 1,
                "evidence_mutations_rejected": 1,
            },
            "module_result": module_evidence.artifact(
                module_result_path, kind="module_current_result"
            ),
            "artifacts": {
                "aggregate": module_evidence.artifact(
                    output_dir / "functional-aggregate.json",
                    kind="functional_aggregate",
                ),
                "aggregate_result": module_evidence.artifact(
                    output_dir / "functional-aggregate-result.json",
                    kind="functional_aggregate_result",
                ),
                "aggregate_log": module_evidence.artifact(
                    output_dir / "functional-aggregate.log",
                    kind="functional_aggregate_log",
                ),
                "simulator": module_evidence.artifact(
                    output_dir / "frozen/NpcSimTop", kind="simulator_binary"
                ),
                "reference": module_evidence.artifact(
                    output_dir / "frozen/riscv64-nemu-interpreter-so",
                    kind="reference_model_binary",
                ),
                "configuration": module_evidence.artifact(
                    output_dir / "frozen/npc.config", kind="kconfig"
                ),
            },
            "inputs": {
                "pre": module_evidence.artifact(
                    output_dir / "inputs.pre.json", kind="functional_input_binding"
                ),
                "post": module_evidence.artifact(
                    output_dir / "inputs.post.json", kind="functional_input_binding"
                ),
                "unchanged": True,
            },
            "inputs_unchanged": True,
            "retention": {
                "module_simulation_reused": True,
                "compiled_intermediates_retained": 0,
                "frozen_simulator_retained": 1,
                "frozen_reference_retained": 1,
                "program_images_retained": 180,
            },
            "published_current": False,
        }
        result_path = output_dir / "run-result.json"
        module_evidence.write_json(result_path, result)
        module_evidence.write_status(
            output_dir,
            state="PASS",
            stage="complete",
            detail="fixture",
            design_id=design_id,
        )
        return result_path

    def test_publication_binding_commits_last_and_rejects_hash_drift(self) -> None:
        with tempfile.TemporaryDirectory(
            dir=module_evidence.TASK_RUN_ROOT,
            prefix="full-core-publication-test-",
        ) as raw:
            run_dir = pathlib.Path(raw)
            output_dir = run_dir / "evidence/functional"
            result_path = self._functional_fixture(output_dir)
            execution_status = run_dir / "full-core-current.status"
            publication_status = run_dir / "full-core-publication.status"
            execution_status.write_text("PASS\n", encoding="utf-8")
            publication_status.write_text("PASS\n", encoding="utf-8")
            canonical_dir = output_dir / "canonical"
            replacements = {
                "CANONICAL_AGGREGATE": canonical_dir / "aggregate.json",
                "CANONICAL_RESULT": canonical_dir / "result.json",
                "CANONICAL_LOG": canonical_dir / "aggregate.log",
                "CANONICAL_BINDING": canonical_dir / "binding.json",
            }
            with mock.patch.multiple(functional, **replacements):
                result = json.loads(result_path.read_text(encoding="utf-8"))
                original_result = result_path.read_bytes()
                functional.publish_current_result(
                    result_path, result, execution_status
                )
                verified = functional.verify_publication_binding(
                    result_path, result, require_publication_pass=True
                )
                self.assertEqual(verified["status"], "PASS")
                self.assertEqual(result_path.read_bytes(), original_result)
                (canonical_dir / "aggregate.json").write_text(
                    "drift\n", encoding="utf-8"
                )
                with self.assertRaisesRegex(RuntimeError, "hash drifted"):
                    functional.verify_publication_binding(
                        result_path, result, require_publication_pass=True
                    )

    def test_semantic_empty_aggregate_is_rejected(self) -> None:
        with tempfile.TemporaryDirectory(
            dir=module_evidence.TASK_RUN_ROOT,
            prefix="full-core-semantic-reject-test-",
        ) as raw:
            result_path = self._functional_fixture(
                pathlib.Path(raw) / "evidence/functional"
            )
            with mock.patch.object(
                functional,
                "validate_module_result",
                return_value=("fixture-module-command", []),
            ), self.assertRaisesRegex(RuntimeError, "aggregate schema"):
                functional.verify_functional_result(
                    result_path,
                    require_current_design=False,
                    require_canonical_current=False,
                )

    def _mutation_summary(self, legacy: object) -> tuple[dict[str, object], dict[str, int]]:
        schema_valid_ids = set(legacy.functional.SCHEMA_VALID_MUTATION_IDS)
        mutations = [
            {
                "mutation_id": mutation_id,
                "schema_valid": mutation_id in schema_valid_ids,
                "rejected": True,
                "mutant_canonical_sha256": "b" * 64,
                "reasons": ["directed fixture rejection"],
            }
            for mutation_id in legacy.functional.CANONICAL_MUTATION_IDS
        ]
        summary: dict[str, object] = {
            "schema": legacy.functional.MUTATION_SCHEMA,
            "design_id": "sha256:" + "a" * 64,
            "cohort_id": functional.COHORT_ID,
            "aggregate_schema": legacy.functional.freeze.FUNCTIONAL_SCHEMA,
            "total": len(mutations),
            "schema_valid": len(legacy.functional.SCHEMA_VALID_MUTATION_IDS),
            "schema_invalid": len(legacy.functional.SCHEMA_INVALID_MUTATION_IDS),
            "schema_valid_rejected": len(
                legacy.functional.SCHEMA_VALID_MUTATION_IDS
            ),
            "all_rejected": True,
            "mutations": mutations,
        }
        counts = {
            "evidence_mutations_compiled": len(
                legacy.functional.SCHEMA_VALID_MUTATION_IDS
            ),
            "evidence_mutations_rejected": len(
                legacy.functional.SCHEMA_VALID_MUTATION_IDS
            ),
        }
        return summary, counts

    def test_mutation_summary_requires_exact_counterexample_inventory(self) -> None:
        legacy = functional.load_legacy_runner()
        summary, counts = self._mutation_summary(legacy)
        functional.validate_mutation_summary(
            summary,
            design_id=summary["design_id"],
            counts=counts,
            legacy=legacy,
        )
        summary["mutations"][0]["mutation_id"] = "changed_terminal_observation"
        with self.assertRaisesRegex(RuntimeError, "canonical inventory drifted"):
            functional.validate_mutation_summary(
                summary,
                design_id=summary["design_id"],
                counts=counts,
                legacy=legacy,
            )

    def test_mutation_summary_requires_every_counterexample_rejected(self) -> None:
        legacy = functional.load_legacy_runner()
        summary, counts = self._mutation_summary(legacy)
        summary["mutations"][0]["rejected"] = False
        with self.assertRaisesRegex(RuntimeError, "was not rejected"):
            functional.validate_mutation_summary(
                summary,
                design_id=summary["design_id"],
                counts=counts,
                legacy=legacy,
            )

    def test_aggregate_log_rejects_rebound_semantic_drift(self) -> None:
        legacy = functional.load_legacy_runner()
        aggregate = {
            "design_id": "sha256:" + "a" * 64,
            "cohort_id": functional.COHORT_ID,
        }
        counts = {
            "module_passed": 3,
            "module_required": 3,
            "official_passed": 177,
            "official_required": 177,
            "am_passed": 61,
            "am_required": 61,
            "difftest_mismatches": 0,
            "evidence_mutations_compiled": 11,
            "evidence_mutations_rejected": 11,
        }
        checks = [{"check_id": "functional", "status": "PASS", "detail": ""}]
        with tempfile.TemporaryDirectory(
            dir=module_evidence.TASK_RUN_ROOT,
            prefix="full-core-log-semantic-test-",
        ) as raw:
            log_path = pathlib.Path(raw) / "functional-aggregate.log"
            log_path.write_text(
                legacy.functional.aggregate_log_text(aggregate, counts, checks),
                encoding="utf-8",
            )
            functional.validate_aggregate_log(
                log_path,
                aggregate=aggregate,
                counts=counts,
                checks=checks,
                legacy=legacy,
            )
            log_path.write_text(
                log_path.read_text(encoding="utf-8").replace(
                    "ppa=UNQUALIFIED", "ppa=QUALIFIED"
                ),
                encoding="utf-8",
            )
            with self.assertRaisesRegex(RuntimeError, "terminal log semantics"):
                functional.validate_aggregate_log(
                    log_path,
                    aggregate=aggregate,
                    counts=counts,
                    checks=checks,
                    legacy=legacy,
                )

    def _fake_python(self, directory: pathlib.Path) -> pathlib.Path:
        fake = directory / "python3"
        fake.write_text(
            """#!/usr/bin/env bash
set -u
args="$*"
output=""
previous=""
for argument in "$@"; do
  if [[ "${previous}" == "--output-dir" ]]; then
    output="${argument}"
    break
  fi
  previous="${argument}"
done
if [[ "${args}" == *"full_core_current_evidence.py"* ]]; then
  mkdir -p -- "${output}"
  printf '{}\\n' >"${output}/result.json"
  if [[ "${FAKE_FULL_CORE_MODE:-pass}" == "module-marker-missing" ]]; then
    exit 0
  fi
  printf '%s\\n' '[FULL-CORE-MODULE-CURRENT][PASS] design_id=fixture tests=1/1 compiled_intermediates_retained=0'
  if [[ "${FAKE_FULL_CORE_MODE:-pass}" == "module-marker-duplicate" ]]; then
    printf '%s\\n' '[FULL-CORE-MODULE-CURRENT][PASS] design_id=fixture duplicate=1'
  fi
  if [[ "${FAKE_FULL_CORE_MODE:-pass}" == "module-marker-contradictory" ]]; then
    printf '%s\\n' '[FULL-CORE-MODULE-CURRENT][FAIL] contradictory fixture'
  fi
  exit 0
fi
if [[ "${args}" == *"--publish-result"* ]]; then
  result=""
  previous=""
  for argument in "$@"; do
    if [[ "${previous}" == "--publish-result" ]]; then
      result="${argument}"
      break
    fi
    previous="${argument}"
  done
  run_dir="$(dirname "$(dirname "$(dirname "${result}")")")"
  [[ "$(cat "${run_dir}/full-core-current.status")" == "PASS" ]] || exit 90
  [[ "$(cat "${run_dir}/full-core-publication.status")" == "RUNNING" ]] || exit 91
  if [[ "${FAKE_FULL_CORE_MODE:-pass}" == "publication-fail" ]]; then
    exit 24
  fi
  if [[ "${FAKE_FULL_CORE_MODE:-pass}" == "publication-marker-missing" ]]; then
    exit 0
  fi
  printf '%s\n' '[FULL-CORE-FUNCTIONAL-PUBLISH][PASS] design_id=fixture binding_committed_last=1'
  if [[ "${FAKE_FULL_CORE_MODE:-pass}" == "publication-marker-duplicate" ]]; then
    printf '%s\n' '[FULL-CORE-FUNCTIONAL-PUBLISH][PASS] design_id=fixture duplicate=1'
  fi
  if [[ "${FAKE_FULL_CORE_MODE:-pass}" == "publication-marker-contradictory" ]]; then
    printf '%s\n' '[FULL-CORE-FUNCTIONAL-PUBLISH][FAIL] contradictory fixture'
  fi
  exit 0
fi
if [[ "${args}" == *"--verify-result"* ]]; then
  if [[ "${FAKE_FULL_CORE_MODE:-pass}" == "verify-marker-missing" ]]; then
    exit 0
  fi
  printf '%s\\n' '[FULL-CORE-FUNCTIONAL-VERIFY][PASS] design_id=fixture canonical_current_verified=False'
  if [[ "${FAKE_FULL_CORE_MODE:-pass}" == "verify-marker-duplicate" ]]; then
    printf '%s\\n' '[FULL-CORE-FUNCTIONAL-VERIFY][PASS] design_id=fixture duplicate=1'
  fi
  if [[ "${FAKE_FULL_CORE_MODE:-pass}" == "verify-marker-contradictory" ]]; then
    printf '%s\\n' '[FULL-CORE-FUNCTIONAL-VERIFY][FAIL] contradictory fixture'
  fi
  exit 0
fi
if [[ "${args}" == *"full_core_functional_evidence.py"* ]]; then
  [[ "${args}" != *"--publish-current"* ]] || exit 98
  if [[ "${FAKE_FULL_CORE_MODE:-pass}" == "functional-fail" ]]; then
    exit 23
  fi
  mkdir -p -- "${output}"
  printf '{}\\n' >"${output}/run-result.json"
  if [[ "${FAKE_FULL_CORE_MODE:-pass}" == "functional-marker-missing" ]]; then
    exit 0
  fi
  printf '%s\\n' '[FULL-CORE-FUNCTIONAL-CURRENT][PASS] design_id=fixture module=1/1 official=177/177 am=1/1 difftest_mismatches=0 compiled_intermediates_retained=0'
  if [[ "${FAKE_FULL_CORE_MODE:-pass}" == "functional-marker-duplicate" ]]; then
    printf '%s\\n' '[FULL-CORE-FUNCTIONAL-CURRENT][PASS] design_id=fixture duplicate=1'
  fi
  if [[ "${FAKE_FULL_CORE_MODE:-pass}" == "functional-marker-contradictory" ]]; then
    printf '%s\\n' '[FULL-CORE-FUNCTIONAL-CURRENT][FAIL] contradictory fixture'
  fi
  exit 0
fi
exit 99
""",
            encoding="utf-8",
        )
        fake.chmod(0o755)
        return fake

    def _wrapper_attempt(
        self, mode: str, *, publish: bool = False, run_id: str | None = None
    ) -> tuple[subprocess.CompletedProcess[str], pathlib.Path]:
        run_id = run_id or f"full-core-runner-test-{uuid.uuid4().hex}"
        run_dir = module_evidence.TASK_RUN_ROOT / run_id
        fake_bin = pathlib.Path(tempfile.mkdtemp(prefix="full-core-fake-python-"))
        fake_python = self._fake_python(fake_bin)
        runner_copy = fake_bin / "run-full-core-current.sh"
        original_runner_text = RUNNER.read_text(encoding="utf-8")
        runner_text = original_runner_text.replace(
            'repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../../../.." && pwd -P)"',
            f'repo_root="{ROOT}"',
        )
        runner_text = runner_text.replace(
            'python_bin="$(realpath -e -- /usr/bin/python3)" || exit 2',
            f'python_bin="{fake_python}"',
        )
        self.assertNotEqual(runner_text, original_runner_text)
        runner_copy.write_text(runner_text, encoding="utf-8")
        runner_copy.chmod(0o755)
        environment = os.environ.copy()
        environment["FAKE_FULL_CORE_MODE"] = mode
        try:
            command = [
                    "bash",
                    str(runner_copy),
                    "--run-dir",
                    f".github/task-runs/{run_id}",
                ]
            if publish:
                command.append("--publish-current")
            completed = subprocess.run(
                command,
                cwd=ROOT,
                env=environment,
                text=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                check=False,
            )
        finally:
            shutil.rmtree(fake_bin)
        return completed, run_dir

    def test_wrapper_success_requires_explicit_verified_completion(self) -> None:
        completed, run_dir = self._wrapper_attempt("pass")
        try:
            self.assertEqual(completed.returncode, 0, completed.stderr)
            self.assertEqual(
                (run_dir / "full-core-current.status").read_text(
                    encoding="utf-8"
                ),
                "PASS\n",
            )
            self.assertIn(
                "execution_state\tPASS",
                (run_dir / "driver-summary.tsv").read_text(encoding="utf-8"),
            )
        finally:
            shutil.rmtree(run_dir, ignore_errors=True)

    def test_wrapper_phase_failure_remains_fail_closed(self) -> None:
        completed, run_dir = self._wrapper_attempt("functional-fail")
        try:
            self.assertNotEqual(completed.returncode, 0)
            status = (run_dir / "full-core-current.status").read_text(
                encoding="utf-8"
            )
            self.assertRegex(status, r"^FAIL rc=1 stage=evidence-complete ")
            self.assertIn(
                "execution_state\tFAIL",
                (run_dir / "driver-summary.tsv").read_text(),
            )
        finally:
            shutil.rmtree(run_dir, ignore_errors=True)

    def test_wrapper_requires_explicit_functional_verify_pass_marker(self) -> None:
        completed, run_dir = self._wrapper_attempt("verify-marker-missing")
        try:
            self.assertNotEqual(completed.returncode, 0)
            status = (run_dir / "full-core-current.status").read_text(
                encoding="utf-8"
            )
            self.assertRegex(status, r"^FAIL rc=1 stage=evidence-complete ")
            summary = (run_dir / "driver-summary.tsv").read_text(encoding="utf-8")
            self.assertIn("verify_marker_rc\t1", summary)
        finally:
            shutil.rmtree(run_dir, ignore_errors=True)

    def test_wrapper_rejects_missing_duplicate_or_contradictory_stage_markers(
        self,
    ) -> None:
        modes = (
            "module-marker-missing",
            "module-marker-duplicate",
            "module-marker-contradictory",
            "functional-marker-missing",
            "functional-marker-duplicate",
            "functional-marker-contradictory",
            "verify-marker-duplicate",
            "verify-marker-contradictory",
        )
        for mode in modes:
            with self.subTest(mode=mode):
                completed, run_dir = self._wrapper_attempt(mode)
                try:
                    self.assertNotEqual(completed.returncode, 0)
                    self.assertRegex(
                        (run_dir / "full-core-current.status").read_text(
                            encoding="utf-8"
                        ),
                        r"^FAIL rc=1 stage=evidence-complete ",
                    )
                finally:
                    shutil.rmtree(run_dir, ignore_errors=True)

    def test_wrapper_publishes_only_after_execution_status_pass(self) -> None:
        completed, run_dir = self._wrapper_attempt("pass", publish=True)
        try:
            self.assertEqual(completed.returncode, 0, completed.stderr)
            self.assertEqual(
                (run_dir / "full-core-current.status").read_text(encoding="utf-8"),
                "PASS\n",
            )
            self.assertEqual(
                (run_dir / "full-core-publication.status").read_text(
                    encoding="utf-8"
                ),
                "PASS\n",
            )
            summary = (run_dir / "driver-summary.tsv").read_text(encoding="utf-8")
            self.assertIn("publication_state\tPASS", summary)
        finally:
            shutil.rmtree(run_dir, ignore_errors=True)

    def test_publication_failure_does_not_revoke_execution_pass(self) -> None:
        completed, run_dir = self._wrapper_attempt(
            "publication-fail", publish=True
        )
        try:
            self.assertNotEqual(completed.returncode, 0)
            self.assertEqual(
                (run_dir / "full-core-current.status").read_text(encoding="utf-8"),
                "PASS\n",
            )
            self.assertRegex(
                (run_dir / "full-core-publication.status").read_text(
                    encoding="utf-8"
                ),
                r"^FAIL rc=24 stage=publication-evidence-complete ",
            )
        finally:
            shutil.rmtree(run_dir, ignore_errors=True)

    def test_publication_requires_explicit_child_pass_marker(self) -> None:
        completed, run_dir = self._wrapper_attempt(
            "publication-marker-missing", publish=True
        )
        try:
            self.assertNotEqual(completed.returncode, 0)
            self.assertEqual(
                (run_dir / "full-core-current.status").read_text(encoding="utf-8"),
                "PASS\n",
            )
            self.assertRegex(
                (run_dir / "full-core-publication.status").read_text(
                    encoding="utf-8"
                ),
                r"^FAIL rc=1 stage=publication-evidence-complete ",
            )
        finally:
            shutil.rmtree(run_dir, ignore_errors=True)

    def test_publication_rejects_duplicate_or_contradictory_pass_marker(
        self,
    ) -> None:
        for mode in (
            "publication-marker-duplicate",
            "publication-marker-contradictory",
        ):
            with self.subTest(mode=mode):
                completed, run_dir = self._wrapper_attempt(mode, publish=True)
                try:
                    self.assertNotEqual(completed.returncode, 0)
                    self.assertEqual(
                        (run_dir / "full-core-current.status").read_text(
                            encoding="utf-8"
                        ),
                        "PASS\n",
                    )
                    self.assertRegex(
                        (run_dir / "full-core-publication.status").read_text(
                            encoding="utf-8"
                        ),
                        r"^FAIL rc=1 stage=publication-evidence-complete ",
                    )
                finally:
                    shutil.rmtree(run_dir, ignore_errors=True)

    def test_wrapper_refuses_to_overwrite_existing_run(self) -> None:
        run_id = f"full-core-existing-test-{uuid.uuid4().hex}"
        run_dir = module_evidence.TASK_RUN_ROOT / run_id
        run_dir.mkdir()
        sentinel = run_dir / "sentinel"
        sentinel.write_text("preserve\n", encoding="utf-8")
        try:
            completed = subprocess.run(
                [
                    "bash",
                    str(RUNNER),
                    "--run-dir",
                    f".github/task-runs/{run_id}",
                ],
                cwd=ROOT,
                text=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                check=False,
            )
            self.assertEqual(completed.returncode, 2)
            self.assertEqual(sentinel.read_text(encoding="utf-8"), "preserve\n")
            self.assertFalse((run_dir / "full-core-current.status").exists())
        finally:
            shutil.rmtree(run_dir, ignore_errors=True)

    def test_wrapper_rejects_dangling_run_dir_symlink(self) -> None:
        run_id = f"full-core-alias-test-{uuid.uuid4().hex}"
        foreign_id = f"full-core-foreign-test-{uuid.uuid4().hex}"
        alias = module_evidence.TASK_RUN_ROOT / run_id
        foreign = module_evidence.TASK_RUN_ROOT / foreign_id
        foreign.mkdir()
        target = foreign / "new-run"
        alias.symlink_to(target, target_is_directory=True)
        try:
            completed, _ = self._wrapper_attempt("pass", run_id=run_id)
            self.assertEqual(completed.returncode, 2, completed.stderr)
            self.assertFalse(target.exists())
        finally:
            if alias.is_symlink():
                alias.unlink()
            shutil.rmtree(foreign, ignore_errors=True)


if __name__ == "__main__":
    unittest.main()
