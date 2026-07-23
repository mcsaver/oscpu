#!/usr/bin/env python3
"""Fail-closed tests for local RV64 FDG-G1 evidence."""

from __future__ import annotations

import importlib.util
import json
import pathlib
import sys
import tempfile
import unittest


TOOLS = pathlib.Path(__file__).resolve().parents[1] / "tools"
REPO = TOOLS.parents[4]
sys.path.insert(0, str(TOOLS))

EVIDENCE_SPEC = importlib.util.spec_from_file_location(
    "fdg_arch_trap_evidence_under_test",
    TOOLS / "fdg_arch_trap_evidence.py",
)
assert EVIDENCE_SPEC is not None and EVIDENCE_SPEC.loader is not None
evidence = importlib.util.module_from_spec(EVIDENCE_SPEC)
sys.modules[EVIDENCE_SPEC.name] = evidence
EVIDENCE_SPEC.loader.exec_module(evidence)

FREEZE_SPEC = importlib.util.spec_from_file_location(
    "fdg_arch_stable_under_test",
    TOOLS / "arch_stable_freeze.py",
)
assert FREEZE_SPEC is not None and FREEZE_SPEC.loader is not None
freeze = importlib.util.module_from_spec(FREEZE_SPEC)
sys.modules[FREEZE_SPEC.name] = freeze
FREEZE_SPEC.loader.exec_module(freeze)

TASK = REPO / ".github/task-runs/2026-07-21-rv64-v9d-fdg-arch-trap"
FOCUSED_LOG = TASK / "evidence/module-aggregate/logs/tb_ooo_fp_legality_dispatch_path.log"
PROGRAM_LOG = TASK / "evidence/module-aggregate/logs/tb_ooo_priv_system.log"
MODULE_SUMMARY = TASK / "evidence/module-aggregate/summary.txt"
MUTATION_SUMMARY = TASK / "evidence/mutations/summary.json"
RESULT = REPO / "npc/rv64/eval/ppa/evidence/fdg-arch-trap-current.json"
RAW_LOG = REPO / "npc/rv64/eval/ppa/evidence/fdg-arch-trap.log"
RUNNER_PATH = TASK / "run-fdg-mutations.py"

RUNNER_SPEC = importlib.util.spec_from_file_location(
    "fdg_mutation_runner_under_test",
    RUNNER_PATH,
)
assert RUNNER_SPEC is not None and RUNNER_SPEC.loader is not None
runner = importlib.util.module_from_spec(RUNNER_SPEC)
sys.modules[RUNNER_SPEC.name] = runner
RUNNER_SPEC.loader.exec_module(runner)


def synthetic_focused_log(*, blocked: int = 4) -> str:
    return (
        "[FDG-G1-FOCUSED] illegal_fp_cases=4 illegal_classified=4 "
        "arch_trap=4 fp_disabled=4 "
        f"backend_blocked={blocked} legal_fp_cases=1 "
        "legal_backend_present=1 PASS\n"
        "[PASS] tb_ooo_fp_legality_dispatch_path\n"
        "[RESULT] PASS\n"
    )


def synthetic_program_log(
    *,
    core_present: int = 0,
    commit_hits: int = 1,
    csr_mepc_match: int = 1,
    csr_mtval_match: int = 1,
) -> str:
    return (
        "[FDG-G1-PROGRAM] arch_trap_capture=1 "
        "capture_pc_match=1 capture_tval_match=1 "
        "ordinary_backend_present=0 "
        f"core_backend_present={core_present} "
        f"commit_oracle_hits={commit_hits} illegal_fp_commit=0 "
        "handler=1 mret=1 cause=2 "
        f"csr_mepc_match={csr_mepc_match} "
        f"csr_mtval_match={csr_mtval_match} PASS\n"
        "[PASS] tb_ooo_priv_system\n"
        "[RESULT] PASS\n"
    )


def write_json(path: pathlib.Path, value: dict) -> None:
    path.write_text(
        json.dumps(value, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )


def ledger_entry(result_path: pathlib.Path = RESULT) -> tuple[dict, str]:
    result = json.loads(result_path.read_text(encoding="utf-8"))
    return ({
        "canonical_command": evidence.CANONICAL_COMMAND,
        "evidence": [
            {
                "kind": "fdg_arch_trap_result",
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


class FdgArchTrapEvidenceTests(unittest.TestCase):
    def test_mutation_logs_normalize_only_transient_compile_directory(self) -> None:
        temp = pathlib.Path("/tmp/fdg-example-random")
        original = (
            f"[COMPILE] -o {temp}/build/test.vvp "
            f"{temp}/OooFrontendDispatchGate.v\n"
            "/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/DecodeUnit.v\n"
        )
        normalized = runner.normalize_transient_paths(original, temp)
        self.assertNotIn(str(temp), normalized)
        self.assertEqual(normalized.count(runner.TRANSIENT_DIR_TOKEN), 2)
        self.assertIn(
            "/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/DecodeUnit.v",
            normalized,
        )

    def test_live_mutation_logs_have_no_random_temp_suffix(self) -> None:
        value = json.loads(MUTATION_SUMMARY.read_text(encoding="utf-8"))
        rows = value["results"] + value["oracle_probes"]
        for row in rows:
            log = REPO / row["log"]["path"]
            text = log.read_text(encoding="utf-8")
            self.assertNotIn("/tmp/fdg-", text, log)
            self.assertIn(runner.TRANSIENT_DIR_TOKEN, text, log)

    def test_live_module_logs_have_no_random_temp_suffix(self) -> None:
        tests = evidence.required_module_tests(
            REPO / "npc/rv64/testbench/Makefile")
        log_dir = MODULE_SUMMARY.parent / "logs"
        for test_name in tests:
            log = log_dir / f"{test_name}.log"
            text = log.read_text(encoding="utf-8")
            self.assertNotIn("/tmp/rv64-fdg-v9d.", text, log)
            self.assertIn(runner.TRANSIENT_DIR_TOKEN, text, log)

    def test_exact_focused_and_program_markers_are_accepted(self) -> None:
        with tempfile.TemporaryDirectory() as temp_name:
            temp = pathlib.Path(temp_name)
            focused = temp / "focused.log"
            program = temp / "program.log"
            focused.write_text(synthetic_focused_log(), encoding="utf-8")
            program.write_text(synthetic_program_log(), encoding="utf-8")
            self.assertEqual(evidence.parse_focused_log(focused)["backend_blocked"], 4)
            self.assertEqual(evidence.parse_program_log(program)["arch_trap_capture"], 1)

    def test_focused_or_program_semantic_cut_is_rejected(self) -> None:
        with tempfile.TemporaryDirectory() as temp_name:
            temp = pathlib.Path(temp_name)
            focused = temp / "focused.log"
            program = temp / "program.log"
            focused.write_text(synthetic_focused_log(blocked=3), encoding="utf-8")
            with self.assertRaisesRegex(ValueError, "matrix inventory"):
                evidence.parse_focused_log(focused)
            program.write_text(synthetic_program_log(core_present=1), encoding="utf-8")
            with self.assertRaisesRegex(ValueError, "event inventory"):
                evidence.parse_program_log(program)

    def test_live_variants_reconstruct_and_reject(self) -> None:
        audit = evidence.validate_mutations(REPO, MUTATION_SUMMARY)
        self.assertEqual(audit["compile_success"], 6)
        self.assertEqual(audit["dynamic_rejected"], 6)
        self.assertEqual(audit["oracle_probes_compile_success"], 1)
        self.assertEqual(audit["oracle_probes_dynamic_rejected"], 1)

    def test_live_module_aggregate_is_exact(self) -> None:
        aggregate = evidence.parse_module_aggregate(REPO, MODULE_SUMMARY)
        self.assertEqual(aggregate["required"], 109)
        self.assertEqual(aggregate["passed"], 109)
        self.assertEqual(aggregate["failed"], 0)

    def test_variant_aggregate_cut_is_rejected(self) -> None:
        value = json.loads(MUTATION_SUMMARY.read_text(encoding="utf-8"))
        value["dynamic_rejected"] = 5
        with tempfile.TemporaryDirectory() as temp_name:
            path = pathlib.Path(temp_name) / "summary.json"
            write_json(path, value)
            with self.assertRaisesRegex(ValueError, "aggregate is incomplete"):
                evidence.validate_mutations(REPO, path)

    def test_oracle_probe_aggregate_cut_is_rejected(self) -> None:
        value = json.loads(MUTATION_SUMMARY.read_text(encoding="utf-8"))
        value["oracle_probes_dynamic_rejected"] = 0
        with tempfile.TemporaryDirectory() as temp_name:
            path = pathlib.Path(temp_name) / "summary.json"
            write_json(path, value)
            with self.assertRaisesRegex(ValueError, "aggregate is incomplete"):
                evidence.validate_mutations(REPO, path)

    def test_program_metadata_or_commit_oracle_cut_is_rejected(self) -> None:
        with tempfile.TemporaryDirectory() as temp_name:
            temp = pathlib.Path(temp_name)
            commit = temp / "commit.log"
            mepc = temp / "mepc.log"
            mtval = temp / "mtval.log"
            commit.write_text(
                synthetic_program_log(commit_hits=0), encoding="utf-8")
            mepc.write_text(
                synthetic_program_log(csr_mepc_match=0), encoding="utf-8")
            mtval.write_text(
                synthetic_program_log(csr_mtval_match=0), encoding="utf-8")
            for path in (commit, mepc, mtval):
                with self.assertRaisesRegex(ValueError, "event inventory"):
                    evidence.parse_program_log(path)

    def test_arch_stable_validator_accepts_live_evidence(self) -> None:
        entry, design_id = ledger_entry()
        self.assertEqual(freeze.validate_fdg_debt(REPO, entry, design_id), [])

    def test_arch_stable_validator_rejects_program_cut(self) -> None:
        value = json.loads(RESULT.read_text(encoding="utf-8"))
        value["metrics"]["program"]["core_backend_present"] = 1
        temp_parent = REPO / ".github/task-runs"
        with tempfile.TemporaryDirectory(
            dir=temp_parent, prefix=".fdg-validator-program-",
        ) as temp_name:
            path = pathlib.Path(temp_name) / "result.json"
            write_json(path, value)
            entry, design_id = ledger_entry(path)
            errors = freeze.validate_fdg_debt(REPO, entry, design_id)
        self.assertTrue(any("metrics" in error for error in errors), errors)


if __name__ == "__main__":
    unittest.main()
