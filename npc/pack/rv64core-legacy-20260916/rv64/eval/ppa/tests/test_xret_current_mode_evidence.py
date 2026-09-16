#!/usr/bin/env python3
"""Fail-closed tests for local RV64 XRET-G1 evidence."""

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
    "xret_current_mode_evidence_under_test",
    TOOLS / "xret_current_mode_evidence.py",
)
assert EVIDENCE_SPEC is not None and EVIDENCE_SPEC.loader is not None
evidence = importlib.util.module_from_spec(EVIDENCE_SPEC)
sys.modules[EVIDENCE_SPEC.name] = evidence
EVIDENCE_SPEC.loader.exec_module(evidence)

FREEZE_SPEC = importlib.util.spec_from_file_location(
    "xret_arch_stable_under_test",
    TOOLS / "arch_stable_freeze.py",
)
assert FREEZE_SPEC is not None and FREEZE_SPEC.loader is not None
freeze = importlib.util.module_from_spec(FREEZE_SPEC)
sys.modules[FREEZE_SPEC.name] = freeze
FREEZE_SPEC.loader.exec_module(freeze)

TASK = REPO / ".github/task-runs/2026-07-21-rv64-v9e-xret-current-design"
FOCUSED_LOG = TASK / "evidence/module-aggregate/logs/tb_ooo_fetch_head_classify_gate.log"
PROGRAM_LOG = TASK / "evidence/module-aggregate/logs/tb_ooo_priv_system.log"
MODULE_SUMMARY = TASK / "evidence/module-aggregate/summary.txt"
MUTATION_SUMMARY = TASK / "evidence/mutations/summary.json"
RESULT = REPO / "npc/rv64/eval/ppa/evidence/xret-current-mode-current.json"
RAW_LOG = REPO / "npc/rv64/eval/ppa/evidence/xret-current-mode.log"
RUNNER_PATH = TASK / "run-xret-mutations.py"

RUNNER_SPEC = importlib.util.spec_from_file_location(
    "xret_mutation_runner_under_test", RUNNER_PATH)
assert RUNNER_SPEC is not None and RUNNER_SPEC.loader is not None
runner = importlib.util.module_from_spec(RUNNER_SPEC)
sys.modules[RUNNER_SPEC.name] = runner
RUNNER_SPEC.loader.exec_module(runner)


def synthetic_focused_log(*, arch_traps: int = 4) -> str:
    return (
        "[XRET-G1-FOCUSED] cases=7 legal=3 illegal=4 "
        "raw_preserved=7 legal_system=3 "
        f"illegal_arch_trap={arch_traps} PASS\n"
        "[PASS] tb_ooo_fetch_head_classify_gate\n"
        "[RESULT] PASS\n"
    )


def synthetic_program_log(
    *,
    mret_request: int = 0,
    sret_older: int = 1,
) -> str:
    return (
        "[XRET-G1-PROGRAM-LEGAL-MRET] csr_request=1 commit=1 "
        "return=1 backend_drained=1 PASS\n"
        "[XRET-G1-PROGRAM-LEGAL-SRET] csr_request=1 commit=1 "
        "return=1 backend_drained=1 PASS\n"
        "[XRET-G1-PROGRAM-ILLEGAL-MRET] arch_trap_capture=1 "
        "capture_pc_match=1 capture_tval_match=1 request_oracle_hits=1 "
        f"csr_request={mret_request} commit_oracle_hits=1 commit=0 "
        "handler=1 cause=2 csr_mepc_match=1 csr_mtval_match=1 return=1 "
        "backend_drained=1 PASS\n"
        "[XRET-G1-PROGRAM-ILLEGAL-SRET] arch_trap_capture=1 "
        "capture_pc_match=1 capture_tval_match=1 request_oracle_hits=1 "
        "csr_request=0 commit_oracle_hits=1 commit=0 handler=1 cause=2 "
        "csr_mepc_match=1 csr_mtval_match=1 "
        f"older_lane0={sret_older} return=1 backend_drained=1 PASS\n"
        "[PASS] tb_ooo_priv_system\n"
        "[RESULT] PASS\n"
    )


def write_json(path: pathlib.Path, value: dict) -> None:
    path.write_text(
        json.dumps(value, indent=2, sort_keys=True) + "\n",
        encoding="utf-8")


def ledger_entry(result_path: pathlib.Path = RESULT) -> tuple[dict, str]:
    result = json.loads(result_path.read_text(encoding="utf-8"))
    return ({
        "canonical_command": evidence.CANONICAL_COMMAND,
        "evidence": [
            {
                "kind": "xret_current_mode_result",
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


class XretCurrentModeEvidenceTests(unittest.TestCase):
    def test_normalizer_replaces_only_exact_transient_root(self) -> None:
        temp = pathlib.Path("/tmp/xret-example-random")
        original = (
            f"[COMPILE] -o {temp}/build/test.vvp "
            f"{temp}/OooFetchHeadClassifyGate.v\n"
            "/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/core/CsrFile.v\n"
        )
        normalized = runner.normalize_transient_paths(original, temp)
        self.assertNotIn(str(temp), normalized)
        self.assertEqual(normalized.count(runner.TRANSIENT_DIR_TOKEN), 2)
        self.assertIn(
            "/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/core/CsrFile.v",
            normalized)

    def test_exact_focused_and_program_markers_are_accepted(self) -> None:
        with tempfile.TemporaryDirectory() as temp_name:
            temp = pathlib.Path(temp_name)
            focused = temp / "focused.log"
            program = temp / "program.log"
            focused.write_text(synthetic_focused_log(), encoding="utf-8")
            program.write_text(synthetic_program_log(), encoding="utf-8")
            self.assertEqual(evidence.parse_focused_log(focused)["cases"], 7)
            parsed = evidence.parse_program_log(program)
            self.assertEqual(parsed["illegal_mret"]["csr_request"], 0)
            self.assertEqual(parsed["illegal_sret"]["older_lane0"], 1)

    def test_focused_or_program_semantic_cut_is_rejected(self) -> None:
        with tempfile.TemporaryDirectory() as temp_name:
            temp = pathlib.Path(temp_name)
            focused = temp / "focused.log"
            program = temp / "program.log"
            focused.write_text(
                synthetic_focused_log(arch_traps=3), encoding="utf-8")
            with self.assertRaisesRegex(ValueError, "event inventory"):
                evidence.parse_focused_log(focused)
            program.write_text(
                synthetic_program_log(mret_request=1), encoding="utf-8")
            with self.assertRaisesRegex(ValueError, "event inventory"):
                evidence.parse_program_log(program)

    def test_lane1_older_retirement_cut_is_rejected(self) -> None:
        with tempfile.TemporaryDirectory() as temp_name:
            program = pathlib.Path(temp_name) / "program.log"
            program.write_text(
                synthetic_program_log(sret_older=0), encoding="utf-8")
            with self.assertRaisesRegex(ValueError, "event inventory"):
                evidence.parse_program_log(program)

    def test_live_variants_reconstruct_and_reject(self) -> None:
        audit = evidence.validate_mutations(REPO, MUTATION_SUMMARY)
        self.assertEqual(audit["compile_success"], 8)
        self.assertEqual(audit["dynamic_rejected"], 8)
        self.assertEqual(audit["oracle_probes_compile_success"], 2)
        self.assertEqual(audit["oracle_probes_dynamic_rejected"], 2)

    def test_live_variant_logs_have_no_random_temp_suffix(self) -> None:
        value = json.loads(MUTATION_SUMMARY.read_text(encoding="utf-8"))
        for row in value["results"] + value["oracle_probes"]:
            log = REPO / row["log"]["path"]
            text = log.read_text(encoding="utf-8")
            self.assertNotIn("/tmp/xret-", text, log)
            self.assertIn(runner.TRANSIENT_DIR_TOKEN, text, log)

    def test_live_module_aggregate_is_exact_and_deterministic(self) -> None:
        aggregate = evidence.parse_module_aggregate(REPO, MODULE_SUMMARY)
        self.assertEqual(aggregate["required"], len(aggregate["tests"]))
        self.assertEqual(aggregate["passed"], aggregate["required"])
        for record in aggregate["tests"].values():
            text = (REPO / record["path"]).read_text(encoding="utf-8")
            self.assertNotIn("/tmp/rv64-xret-v9e.", text)
            self.assertIn(runner.TRANSIENT_DIR_TOKEN, text)

    def test_variant_aggregate_cut_is_rejected(self) -> None:
        value = json.loads(MUTATION_SUMMARY.read_text(encoding="utf-8"))
        value["dynamic_rejected"] = 7
        with tempfile.TemporaryDirectory() as temp_name:
            path = pathlib.Path(temp_name) / "summary.json"
            write_json(path, value)
            with self.assertRaisesRegex(ValueError, "aggregate is incomplete"):
                evidence.validate_mutations(REPO, path)

    def test_arch_stable_validator_accepts_live_evidence(self) -> None:
        entry, design_id = ledger_entry()
        self.assertEqual(freeze.validate_xret_debt(REPO, entry, design_id), [])

    def test_arch_stable_validator_rejects_illegal_request_cut(self) -> None:
        value = json.loads(RESULT.read_text(encoding="utf-8"))
        value["metrics"]["program"]["illegal_mret"]["csr_request"] = 1
        with tempfile.TemporaryDirectory(
            dir=REPO / ".github/task-runs", prefix=".xret-validator-",
        ) as temp_name:
            path = pathlib.Path(temp_name) / "result.json"
            write_json(path, value)
            entry, design_id = ledger_entry(path)
            errors = freeze.validate_xret_debt(REPO, entry, design_id)
        self.assertTrue(any("metrics" in error for error in errors), errors)


if __name__ == "__main__":
    unittest.main()
