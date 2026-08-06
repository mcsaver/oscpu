#!/usr/bin/env python3
"""Focused tests for current-design DI-5 evidence parsing and replay."""

from __future__ import annotations

import hashlib
import importlib.util
import pathlib
import sys
import tempfile
import unittest


TOOLS = pathlib.Path(__file__).resolve().parents[1] / "tools"
sys.path.insert(0, str(TOOLS))
SPEC = importlib.util.spec_from_file_location(
    "dual_memory_issue_evidence_under_test",
    TOOLS / "dual_memory_issue_evidence.py",
)
assert SPEC is not None and SPEC.loader is not None
evidence = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(evidence)
ROOT = TOOLS.parents[4]
MUTATOR_SPEC = importlib.util.spec_from_file_location(
    "mutate_v8u_f4_under_test",
    ROOT / ".github/task-runs/2026-07-20-rv64-v8u-dual-memory-"
    "sustained-issue/mutate-v8u-f4.py",
)
assert MUTATOR_SPEC is not None and MUTATOR_SPEC.loader is not None
mutator = importlib.util.module_from_spec(MUTATOR_SPEC)
sys.modules[MUTATOR_SPEC.name] = mutator
MUTATOR_SPEC.loader.exec_module(mutator)


def digest_bytes(value: bytes) -> str:
    return hashlib.sha256(value).hexdigest()


def steady_system_log() -> str:
    lines = []
    for cycle in range(64):
        lines.extend([
            f"[V8U-DI5-CYCLE] index={cycle} agu=11 translation=11 "
            "query=11 cache=11 completion=11",
            f"[V8U-DI5-PIPE] index={cycle} fetch=1/1 dispatch=11/1 "
            "iq=00 res=11 capture=11 consume=11 turnover=1",
            f"[V8U-DI5-GRANT] index={cycle} candidate=11 selected=11 "
            "bank=10 slot=11 bridge_ready=11 grant=11 miq_count=2,2 "
            "bridge_load=11/11",
        ])
    lines.extend([
        "[V8U-DI5-METRIC] trace_cycles=64 memory_issue_ipc_milli=2000 "
        "dual_issue_cycles=64 agu_accepts=64,64 "
        "translation_accepts=64,64 physical_lsq_queries=64,64 "
        "cache_admissions=64,64 completions=64,64",
        "[RESULT] PASS",
    ])
    return "\n".join(lines) + "\n"


class DualMemoryIssueEvidenceTests(unittest.TestCase):
    def test_all_mutation_anchors_match_current_rtl_once(self) -> None:
        source_paths = {
            "OooIntBackend.v":
                ROOT / "npc/rv64/vsrc/execute/OooIntBackend.v",
            "OooMemAxiBridge.v":
                ROOT / "npc/rv64/vsrc/memory/OooMemAxiBridge.v",
            "OooIntIssueQueue.v":
                ROOT / "npc/rv64/vsrc/scheduling/OooIntIssueQueue.v",
        }
        for name, mutation in mutator.MUTATIONS.items():
            text = source_paths[mutation.source_name].read_text(
                encoding="utf-8")
            self.assertEqual(
                text.count(mutation.old),
                mutation.expected_count,
                name,
            )

    def test_exact_steady_system_trace_passes(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            path = pathlib.Path(temporary) / "system.log"
            path.write_text(steady_system_log(), encoding="utf-8")
            metrics = evidence.read_system(path)
            self.assertEqual(metrics["memory_issue_ipc"], 2.0)
            self.assertEqual(metrics["completions"], [64, 64])

    def test_single_inactive_completion_face_is_rejected(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            path = pathlib.Path(temporary) / "system.log"
            text = steady_system_log().replace(
                "index=37 agu=11 translation=11 query=11 cache=11 "
                "completion=11",
                "index=37 agu=11 translation=11 query=11 cache=11 "
                "completion=10",
            )
            path.write_text(text, encoding="utf-8")
            with self.assertRaisesRegex(ValueError, "steady-state face"):
                evidence.read_system(path)

    def test_mutation_aggregate_rejects_successful_semantic_variant(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = pathlib.Path(temporary)
            result = root / "result.log"
            summary = root / "summary.tsv"
            baseline = root / "baseline.log"
            result.write_text(
                "[V8U-F4-MUTATION][PASS] compile_success=7 "
                "dynamic_rejections=7 feedback_scc_recreated=1 "
                "baseline_unoptflat=0\n",
                encoding="utf-8",
            )
            baseline.write_text(
                "[V8U-F4-CONE][PASS] baseline NpcCoreTop has no UNOPTFLAT\n",
                encoding="utf-8",
            )
            rows = []
            for name in evidence.arch.DUAL_MEMORY_MUTATION_NAMES:
                role = (
                    "backend" if name.startswith("backend_")
                    else "bridge" if name.startswith("bridge_")
                    else "iq"
                )
                cone = (
                    "unoptflat_recreated"
                    if name == "backend_next_requires_response_fire"
                    else "not_required"
                )
                rows.append(
                    f"{name}|{role}|compile_success|target_rejected|{cone}|"
                    f"{'a' * 64}|{'b' * 64}|1"
                )
            summary.write_text("\n".join(rows) + "\n", encoding="utf-8")
            parsed = evidence.read_mutations(result, summary, baseline)
            self.assertEqual(set(parsed), set(evidence.MUTATIONS))

            summary.write_text(
                ("\n".join(rows) + "\n").replace("|1\n", "|0\n", 1),
                encoding="utf-8",
            )
            with self.assertRaisesRegex(ValueError, "returned success"):
                evidence.read_mutations(result, summary, baseline)

    def test_frozen_replay_allows_only_enumerated_non_rtl_drift(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = pathlib.Path(temporary).resolve()
            checker = root / "npc/rv64/eval/ppa/tools/architecture_hard_gates.py"
            makefile = root / "npc/rv64/Makefile"
            rtl = root / "npc/rv64/vsrc/memory/OooMemAxiBridge.v"
            checker.parent.mkdir(parents=True)
            makefile.parent.mkdir(parents=True, exist_ok=True)
            rtl.parent.mkdir(parents=True)
            checker.write_text("old checker\n", encoding="utf-8")
            makefile.write_text("old orchestration\n", encoding="utf-8")
            rtl.write_text("stable rtl\n", encoding="utf-8")
            manifest = root / "sources.sha256"
            manifest.write_text(
                f"{digest_bytes(checker.read_bytes())}  {checker}\n"
                f"{digest_bytes(makefile.read_bytes())}  {makefile}\n"
                f"{digest_bytes(rtl.read_bytes())}  {rtl}\n",
                encoding="utf-8",
            )
            checker.write_text("new checker\n", encoding="utf-8")
            makefile.write_text("new orchestration\n", encoding="utf-8")
            allowed = {
                "npc/rv64/Makefile",
                "npc/rv64/eval/ppa/tools/architecture_hard_gates.py",
            }
            entries, drift = evidence.read_frozen_source_manifest(
                root,
                manifest,
                allowed,
            )
            self.assertEqual(len(entries), 3)
            self.assertEqual(
                drift,
                allowed,
            )

            rtl.write_text("drifted rtl\n", encoding="utf-8")
            with self.assertRaisesRegex(ValueError, "non-authorized F2"):
                evidence.read_frozen_source_manifest(
                    root,
                    manifest,
                    allowed,
                )

    def test_task_run_path_is_bounded(self) -> None:
        valid = evidence.task_run_evidence_rel(
            "2026-08-02-rv64-v13y-di5-current-rebind-v1", "di5-current")
        self.assertEqual(
            valid.as_posix(),
            ".github/task-runs/2026-08-02-rv64-v13y-di5-current-rebind-v1/"
            "evidence/di5-current",
        )
        with self.assertRaisesRegex(ValueError, "malformed"):
            evidence.task_run_evidence_rel("../escape", "di5-current")


if __name__ == "__main__":
    unittest.main()
