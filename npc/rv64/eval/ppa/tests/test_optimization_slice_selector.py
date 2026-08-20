#!/usr/bin/env python3

from __future__ import annotations

import copy
import contextlib
import hashlib
import io
import json
import pathlib
import subprocess
import sys
import tempfile
import unittest
from unittest import mock


ROOT = pathlib.Path(__file__).resolve().parents[5]
TOOL = ROOT / "npc/rv64/eval/ppa/tools/optimization_slice_selector.py"
RUNNER = ROOT / "npc/rv64/eval/ppa/run-optimization-slice-selector.sh"
POLICY = ROOT / (
    "npc/rv64/design/arch/optimization-slice-selector-policy-v2.json")
CATALOG = ROOT / "npc/rv64/eval/ppa/optimization-slices-current.json"
OWNER_LIFETIME_CATALOG = ROOT / (
    "npc/rv64/eval/ppa/optimization-slices-owner-lifetime-v2.json")
CENSUS = ROOT / "npc/rv64/eval/ppa/evidence/cpi-bottleneck-census-current.json"
OWNER = ROOT / (
    ".github/task-runs/2026-08-08-rv64-v15z-arch-stable-act4-rebind-f72e-a1/"
    "evidence/mainline-rebind-f72e-v1/owner-timing/result.json")
CAUSAL = ROOT / (
    ".github/task-runs/2026-08-08-rv64-v15z-arch-stable-act4-rebind-f72e-a1/"
    "evidence/mainline-rebind-f72e-v1/owner-causal/result.json")
SENSITIVITY = ROOT / (
    ".github/task-runs/2026-08-08-rv64-v15z-arch-stable-act4-rebind-f72e-a1/"
    "evidence/mainline-rebind-f72e-v1/owner-b-sensitivity/result.json")
CANDIDATE_ANALYSIS = ROOT / (
    ".github/task-runs/2026-08-08-rv64-v15z-arch-stable-act4-rebind-f72e-a1/"
    "evidence/mainline-rebind-f72e-v1/owner-b-candidate/result.json")
CURRENT_REFERENCE_PPA = ROOT / (
    ".github/task-runs/2026-08-08-rv64-v15z-arch-stable-act4-rebind-f72e-a1/"
    "evidence/mainline-rebind-f72e-v1/current-reference-ppa/result.json")
CURRENT_TIMING_ANALYSIS = ROOT / (
    ".github/task-runs/2026-08-08-rv64-v15z-arch-stable-act4-rebind-f72e-a1/"
    "evidence/mainline-rebind-f72e-v1/current-timing-path-analysis/result.json")
SERIALIZED_OWNER_LIFETIME = ROOT / (
    ".github/task-runs/2026-08-08-rv64-owner-timing-causality-v1/"
    "evidence/serialized-drain-owner-lifetime/result.json")
DECISION_SCHEMA = ROOT / (
    "npc/rv64/eval/ppa/schemas/optimization-slice-decision-v1.schema.json")
CURRENT_DECISION = ROOT / (
    "npc/rv64/eval/ppa/evidence/optimization-slice-current.json")
TOOLS_DIR = TOOL.parent
if str(TOOLS_DIR) not in sys.path:
    sys.path.insert(0, str(TOOLS_DIR))

import optimization_slice_selector as selector  # noqa: E402


def sha256(path: pathlib.Path) -> str:
    value = hashlib.sha256()
    value.update(path.read_bytes())
    return value.hexdigest()


class OptimizationSliceSelectorTests(unittest.TestCase):
    def setUp(self) -> None:
        runtime = ROOT / ".github/runtime-artifacts/tests"
        runtime.mkdir(parents=True, exist_ok=True)
        self.temporary = tempfile.TemporaryDirectory(
            prefix="optimization-selector-", dir=runtime)
        self.work = pathlib.Path(self.temporary.name)
        self.policy = json.loads(POLICY.read_text(encoding="utf-8"))
        self.catalog = json.loads(CATALOG.read_text(encoding="utf-8"))
        self.policy_path = self.work / "policy.json"
        self.catalog_path = self.work / "catalog.json"
        self.result_path = self.work / "decision.json"
        self.write_json(self.policy_path, self.policy)
        self.write_json(self.catalog_path, self.catalog)
        frozen = json.loads(CENSUS.read_text(encoding="utf-8"))
        raw_design_id = frozen["design_id"].removeprefix("sha256:")
        _, rtl_entries = selector.architecture.rtl_binding(ROOT)
        self.rtl_binding_patch = mock.patch.object(
            selector.architecture,
            "rtl_binding",
            return_value=(raw_design_id, rtl_entries),
        )
        self.rtl_binding_patch.start()
        self.production_manifest_patch = mock.patch.object(
            selector.owner_timing,
            "validate_manifest",
            side_effect=self.frozen_manifest_ref,
        )
        self.production_manifest_patch.start()
        self.synthesis_source_patch = mock.patch.object(
            selector.current_reference,
            "verify_source_map",
            side_effect=self.frozen_synthesis_source_map,
        )
        self.synthesis_source_patch.start()

    def tearDown(self) -> None:
        self.synthesis_source_patch.stop()
        self.production_manifest_patch.stop()
        self.rtl_binding_patch.stop()
        self.temporary.cleanup()

    @staticmethod
    def frozen_manifest_ref(path: pathlib.Path) -> dict[str, object]:
        lines = path.read_text(encoding="utf-8").splitlines()
        return {
            **selector.owner_timing.file_ref(path),
            "file_count": len(lines),
            "aggregate_sha256": selector.owner_timing.sha256(path),
        }

    @staticmethod
    def frozen_synthesis_source_map(
        value: object, label: str,
    ) -> dict[str, str]:
        selector.current_reference.require(
            isinstance(value, dict) and len(value) >= 120,
            f"{label} synthesis source map is incomplete",
        )
        selector.current_reference.require(
            value.get(selector.current_reference.ADAPTER_PATH)
            == selector.current_reference.EXPECTED_ADAPTER_SHA256,
            f"{label} adapter SHA-256 mismatch",
        )
        selector.current_reference.require(
            all(isinstance(path, str) and isinstance(digest, str)
                for path, digest in value.items()),
            f"{label} synthesis source entry is invalid",
        )
        return dict(sorted(value.items()))

    @staticmethod
    def write_json(path: pathlib.Path, value: object) -> None:
        path.write_text(
            json.dumps(value, indent=2, sort_keys=True, ensure_ascii=False) + "\n",
            encoding="utf-8",
        )

    @staticmethod
    def relative(path: pathlib.Path) -> str:
        return path.resolve().relative_to(ROOT).as_posix()

    def run_tool(self, *arguments: str) -> subprocess.CompletedProcess[str]:
        output = io.StringIO()
        with contextlib.redirect_stdout(output), contextlib.redirect_stderr(output):
            try:
                returncode = selector.main(list(arguments))
            except SystemExit as exc:
                returncode = int(exc.code)
        return subprocess.CompletedProcess(
            args=[sys.executable, "-B", str(TOOL), *arguments],
            returncode=returncode,
            stdout=output.getvalue(),
            stderr=None,
        )

    def run_live_tool(self, *arguments: str) -> subprocess.CompletedProcess[str]:
        return subprocess.run(
            [sys.executable, "-B", str(TOOL), *arguments],
            cwd=ROOT,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            check=False,
        )

    def build(
        self, *, report_only: bool = False,
        research: pathlib.Path | None = None,
    ) -> subprocess.CompletedProcess[str]:
        arguments = [
            "build",
            "--policy", self.relative(self.policy_path),
            "--catalog", self.relative(self.catalog_path),
            "--output", self.relative(self.result_path),
        ]
        if research is not None:
            arguments.extend(["--research-state", self.relative(research)])
        if report_only:
            arguments.append("--report-only")
        return self.run_tool(*arguments)

    def result(self) -> dict[str, object]:
        return json.loads(self.result_path.read_text(encoding="utf-8"))

    def bind_authority(self, name: str, value: dict[str, object]) -> None:
        path = self.work / f"{name}.json"
        self.write_json(path, value)
        self.policy["authorities"][name]["path"] = self.relative(path)
        self.write_json(self.policy_path, self.policy)

    def source_ref(self, path: pathlib.Path = CENSUS) -> dict[str, object]:
        return {
            "path": self.relative(path),
            "sha256": sha256(path),
            "size_bytes": path.stat().st_size,
        }

    def research_state(
        self, *, facts: dict[str, object] | None = None,
        observations: dict[str, object] | None = None,
        design_id: str | None = None,
        evidence_receipts: dict[str, object] | None = None,
    ) -> pathlib.Path:
        current = json.loads(CENSUS.read_text(encoding="utf-8"))
        path = self.work / "research.json"
        sources = [self.source_ref()]
        for reference in (evidence_receipts or {}).values():
            if reference not in sources:
                sources.append(reference)
        self.write_json(path, {
            "schema": "npc-rv64-optimization-research-state-v1",
            "design_id": design_id or current["design_id"],
            "source_artifacts": sources,
            "facts": facts or {},
            "evidence_receipts": evidence_receipts or {},
            "candidate_observations": observations or {},
        })
        return path

    def simple_candidate(
        self, candidate_id: str, *, mode: str = "information",
        metrics: dict[str, int] | None = None,
    ) -> dict[str, object]:
        candidate = copy.deepcopy(self.catalog["slices"][0])
        candidate.update({
            "id": candidate_id,
            "class": "rtl_experiment",
            "selection_mode": mode,
            "title": candidate_id,
            "prerequisites": [
                {"fact": "state_consistent", "op": "eq", "value": True},
            ],
        })
        if metrics is not None:
            candidate["selector_metrics"] = metrics
        return candidate

    @staticmethod
    def observation(
        performance: float,
        area_efficiency: float,
        slack: float = 0.12,
        *, power_qualified: bool = False,
        power_efficiency: float | None = None,
        stage: str = "intermediate_checkpoint",
    ) -> dict[str, object]:
        exact = lambda value: {  # noqa: E731
            "low": value, "nominal": value, "high": value}
        return {
            "evidence_grade": "MEASURED_SAME_DESIGN",
            "design_stage": stage,
            "uncertainty_kind": "empirical_range",
            "functional_and_architecture": True,
            "performance_ratio": exact(performance),
            "per_workload_performance_ratio": {
                "coremark": exact(performance),
                "dhrystone_10000": exact(performance),
            },
            "area_efficiency_ratio": exact(area_efficiency),
            "timing_worst_slack_ns": exact(slack),
            "power_qualified": power_qualified,
            "qualified_power_efficiency_ratio": (
                exact(power_efficiency) if power_qualified else None),
        }

    def decide_with_authority_facts(
        self, **overrides: object,
    ) -> tuple[object, ...]:
        facts: dict[str, object] = {
            "state_consistent": True,
            "hard_blockers_closed": True,
            "performance_baseline_current": True,
            "cpi_census_current": True,
            "owner_timing_measured": False,
            "causal_analysis_completed": False,
            "causal_analysis_status": "UNAVAILABLE",
            "b_latency_sensitivity_completed": False,
            "b_latency_sensitivity_status": "UNAVAILABLE",
            "b_response_candidate_analysis_completed": False,
            "b_response_candidate_analysis_status": "UNAVAILABLE",
            "ppa_reference_measurement_completed": False,
            "ppa_reference_measurement_status": "UNAVAILABLE",
            "ppa_engineering_reference_available": False,
            "ppa_timing_hard_gate": "UNKNOWN",
            "causal_selection_authorized": False,
            "causal_hypothesis": "UNRESOLVED",
            "ppa_reference_available": False,
            "ppa_qualified": False,
            "maturity": "PERF_BASELINE",
            "performance_anchor_floor_met": False,
        }
        facts.update(overrides)
        ppa_path = ROOT / self.policy["normative_inputs"]["ppa_policy"]["path"]
        ppa_policy = json.loads(ppa_path.read_text(encoding="utf-8"))
        slices = sorted(
            copy.deepcopy(self.catalog["slices"]), key=lambda item: item["id"])
        return selector.decide(
            slices, facts, self.policy, ppa_policy, {}, False, [],
        )

    def test_current_337_selects_owner_timing_causal_measurement(self) -> None:
        built = self.build()
        self.assertEqual(built.returncode, 0, built.stdout)
        value = self.result()
        self.assertEqual(value["decision"], "SELECT")
        self.assertEqual(value["next_action"], "CAUSAL_MEASUREMENT")
        self.assertEqual(
            value["selected_slice"]["id"], "measure.owner-timing-causality")
        self.assertFalse(value["state"]["performance_anchor_floor_met"])
        self.assertEqual(value["stale_refs"], [])

    def test_live_cache_is_canonical_or_explicit_stale_conflict(self) -> None:
        live_state = self.work / "live-state.json"
        built = self.run_live_tool(
            "build", "--output", self.relative(live_state), "--report-only")
        self.assertEqual(built.returncode, 0, built.stdout)
        checked = self.run_live_tool(
            "verify", "--input", self.relative(live_state), "--report-only")
        self.assertEqual(checked.returncode, 0, checked.stdout)
        stored = json.loads(CURRENT_DECISION.read_text(encoding="utf-8"))
        live = json.loads(live_state.read_text(encoding="utf-8"))
        verified = self.run_live_tool(
            "verify", "--input", self.relative(CURRENT_DECISION),
            "--report-only")
        if verified.returncode == 0:
            self.assertEqual(stored["live_design_id"], live["live_design_id"])
            return
        self.assertEqual(verified.returncode, 2, verified.stdout)
        if "decision policy sha256 mismatch" in verified.stdout:
            self.assertEqual(stored["live_design_id"], live["live_design_id"])
            return
        self.assertRegex(
            verified.stdout,
            "optimization research state design-id mismatch|"
            "stored selector decision is not canonical",
        )
        self.assertNotEqual(stored["live_design_id"], live["live_design_id"])
        self.assertEqual(live["decision"], "STATE_CONFLICT")
        self.assertEqual(live["next_action"], "STATE_RECONCILIATION")

    def test_live_verifier_rejects_fresh_state_design_id_mutation(self) -> None:
        live_state = self.work / "live-control.json"
        built = self.run_live_tool(
            "build", "--output", self.relative(live_state), "--report-only")
        self.assertEqual(built.returncode, 0, built.stdout)
        value = json.loads(live_state.read_text(encoding="utf-8"))
        value["live_design_id"] = "sha256:" + "0" * 64
        stale = self.work / "live-stale-mutant.json"
        self.write_json(stale, value)
        verified = self.run_live_tool(
            "verify", "--input", self.relative(stale), "--report-only")
        self.assertEqual(verified.returncode, 2, verified.stdout)
        self.assertIn("stored selector decision is not canonical", verified.stdout)

    def test_runner_keeps_live_validation_in_parent_shell(self) -> None:
        runner = RUNNER.read_text(encoding="utf-8")
        self.assertNotIn(
            "current_state=$(validate_current_or_stale)", runner)
        self.assertIn("    validate_current_or_stale\n", runner)
        self.assertIn('    current_state="canonical"', runner)
        self.assertIn('  current_state="stale-fail-closed"', runner)
        self.assertGreaterEqual(runner.count("return 1"), 5)

    def test_schema_and_workflow_keep_selector_role_separate(self) -> None:
        schema = json.loads(DECISION_SCHEMA.read_text(encoding="utf-8"))
        self.assertFalse(schema["additionalProperties"])
        self.assertIn("tradeoff_analysis", schema["required"])
        self.assertIn(
            "RESEARCH_REQUIRED", schema["properties"]["decision"]["enum"])
        workflow = (ROOT / (
            ".github/instructions/rv64-ppa-optimization-workflow.instructions.md"
        )).read_text(encoding="utf-8")
        blueprint = (ROOT / ".github/agentic-hardware-blueprint.md").read_text(
            encoding="utf-8")
        readme = (ROOT / "npc/rv64/eval/ppa/README.md").read_text(
            encoding="utf-8")
        self.assertIn("中型 CPI/PPA 下一切片选择器", workflow)
        self.assertIn("cpi-ppa-next-slice-selector", blueprint)
        self.assertIn("Medium next-slice selector", readme)
        for text in (workflow, blueprint, readme):
            self.assertIn("front.py", text)

        built = self.build()
        self.assertEqual(built.returncode, 0, built.stdout)
        bound = self.result()["inputs"]["decision_schema"]
        self.assertEqual(bound["path"], self.relative(DECISION_SCHEMA))
        self.assertEqual(bound["sha256"], sha256(DECISION_SCHEMA))

    def test_decision_schema_mutation_is_enforced(self) -> None:
        value = json.loads(DECISION_SCHEMA.read_text(encoding="utf-8"))
        value["required"].append("independent_review_proof")
        mutated = self.work / "mutated-decision-schema.json"
        self.write_json(mutated, value)
        with mock.patch.object(
            selector, "DEFAULT_DECISION_SCHEMA", self.relative(mutated),
        ):
            with self.assertRaisesRegex(
                selector.SelectorError, "violates schema",
            ):
                selector.build_decision(
                    ROOT, self.policy_path, self.catalog_path)

    def test_output_symlink_is_rejected_without_touching_target(self) -> None:
        target = self.work / "symlink-target.json"
        link = self.work / "decision-link.json"
        link.symlink_to(target.name)
        built = self.run_tool(
            "build",
            "--policy", self.relative(self.policy_path),
            "--catalog", self.relative(self.catalog_path),
            "--output", link.relative_to(ROOT).as_posix(),
        )
        self.assertEqual(built.returncode, 2, built.stdout)
        self.assertIn("path uses a symlink", built.stdout)
        self.assertFalse(target.exists())

    def test_external_absolute_decision_input_is_rejected(self) -> None:
        built = self.build()
        self.assertEqual(built.returncode, 0, built.stdout)
        with tempfile.TemporaryDirectory(prefix="external-selector-") as directory:
            external = pathlib.Path(directory) / "decision.json"
            external.write_bytes(self.result_path.read_bytes())
            verified = self.run_tool("verify", "--input", str(external))
        self.assertEqual(verified.returncode, 2, verified.stdout)
        self.assertIn("escapes workspace", verified.stdout)

    def test_catalog_order_does_not_change_selection(self) -> None:
        first = self.build()
        self.assertEqual(first.returncode, 0, first.stdout)
        selected = self.result()["selected_slice"]["id"]
        self.catalog["slices"].reverse()
        self.write_json(self.catalog_path, self.catalog)
        second = self.build()
        self.assertEqual(second.returncode, 0, second.stdout)
        self.assertEqual(self.result()["selected_slice"]["id"], selected)

    def test_stale_cpi_census_selects_reconciliation(self) -> None:
        value = json.loads(CENSUS.read_text(encoding="utf-8"))
        value["design_id"] = "sha256:" + "0" * 64
        self.bind_authority("cpi_census", value)
        built = self.build()
        self.assertEqual(built.returncode, 0, built.stdout)
        result = self.result()
        self.assertEqual(
            result["selected_slice"]["id"], "reconcile.current-cpi-census")
        self.assertEqual(result["next_action"], "STATE_RECONCILIATION")

    def test_required_authority_identity_conflict_fails_closed(self) -> None:
        source = ROOT / self.policy["authorities"]["architecture_debt"]["path"]
        value = json.loads(source.read_text(encoding="utf-8"))
        value["design_id"] = "sha256:" + "0" * 64
        self.bind_authority("architecture_debt", value)
        built = self.build(report_only=True)
        self.assertEqual(built.returncode, 0, built.stdout)
        result = self.result()
        self.assertEqual(result["decision"], "STATE_CONFLICT")
        self.assertIsNone(result["selected_slice"])
        self.assertIn(
            "architecture_debt:DESIGN_ID_MISMATCH",
            result["state"]["state_conflicts"],
        )

    def test_duplicate_catalog_id_is_structural_error(self) -> None:
        self.catalog["slices"].append(copy.deepcopy(self.catalog["slices"][0]))
        self.write_json(self.catalog_path, self.catalog)
        built = self.build()
        self.assertEqual(built.returncode, 2, built.stdout)
        self.assertIn("duplicate slice id", built.stdout)

    def test_duplicate_json_key_is_structural_error(self) -> None:
        self.catalog_path.write_text(
            '{"schema":"npc-rv64-optimization-slice-catalog-v1",'
            '"schema":"duplicate","catalog_id":"x","slices":[]}',
            encoding="utf-8",
        )
        built = self.build()
        self.assertEqual(built.returncode, 2, built.stdout)
        self.assertIn("duplicate JSON key", built.stdout)

    def test_no_eligible_slice_reports_hold(self) -> None:
        candidate = self.simple_candidate("never")
        candidate["prerequisites"] = [
            {"fact": "ppa_qualified", "op": "eq", "value": True},
        ]
        self.catalog["slices"] = [candidate]
        self.write_json(self.catalog_path, self.catalog)
        built = self.build(report_only=True)
        self.assertEqual(built.returncode, 0, built.stdout)
        self.assertEqual(self.result()["decision"], "NO_ELIGIBLE")
        self.assertEqual(self.result()["next_action"], "HOLD")

    def test_equal_information_front_requires_research(self) -> None:
        self.catalog["slices"] = [
            self.simple_candidate("candidate.a"),
            self.simple_candidate("candidate.b"),
        ]
        self.write_json(self.catalog_path, self.catalog)
        built = self.build(report_only=True)
        self.assertEqual(built.returncode, 0, built.stdout)
        result = self.result()
        self.assertEqual(result["decision"], "RESEARCH_REQUIRED")
        self.assertEqual(result["eligible_front"], ["candidate.a", "candidate.b"])

    def test_information_dominance_selects_unique_slice(self) -> None:
        weak = {
            "information_gain": 3, "evidence_confidence": 3,
            "reversibility": 4, "execution_cost": 3,
            "functional_risk": 2, "scope_width": 3,
        }
        strong = {
            "information_gain": 5, "evidence_confidence": 4,
            "reversibility": 5, "execution_cost": 2,
            "functional_risk": 1, "scope_width": 2,
        }
        self.catalog["slices"] = [
            self.simple_candidate("candidate.weak", metrics=weak),
            self.simple_candidate("candidate.strong", metrics=strong),
        ]
        self.write_json(self.catalog_path, self.catalog)
        built = self.build()
        self.assertEqual(built.returncode, 0, built.stdout)
        self.assertEqual(
            self.result()["selected_slice"]["id"], "candidate.strong")

    def test_authoritative_owner_receipt_state_moves_to_analysis(self) -> None:
        decision = self.decide_with_authority_facts(
            owner_timing_measured=True,
            causal_selection_authorized=False,
        )
        self.assertEqual(
            decision[4]["id"], "analyze.owner-timing-hypothesis")

    def test_research_required_causal_receipt_selects_b_latency_sensitivity(self) -> None:
        research = self.research_state(evidence_receipts={
            "owner_timing": self.source_ref(OWNER),
            "causal_analysis": self.source_ref(CAUSAL),
        })
        built = self.build(research=research)
        self.assertEqual(built.returncode, 0, built.stdout)
        result = self.result()
        self.assertEqual(result["decision"], "SELECT")
        self.assertEqual(result["next_action"], "CAUSAL_MEASUREMENT")
        self.assertEqual(
            result["selected_slice"]["id"],
            "measure.owner-b-latency-sensitivity",
        )
        self.assertTrue(result["state"]["causal_analysis_completed"])
        self.assertEqual(
            result["state"]["causal_analysis_status"], "RESEARCH_REQUIRED")
        self.assertFalse(result["state"]["causal_selection_authorized"])
        self.assertEqual(
            result["inputs"]["verification_tools"]["causal_analysis"]["path"],
            "npc/rv64/eval/ppa/tools/owner_timing_causal_analysis.py",
        )

    def test_causal_receipt_requires_bound_owner_receipt(self) -> None:
        research = self.research_state(evidence_receipts={
            "causal_analysis": self.source_ref(CAUSAL),
        })
        built = self.build(research=research)
        self.assertEqual(built.returncode, 2, built.stdout)
        self.assertIn("requires the owner timing receipt", built.stdout)

    def test_sensitivity_receipt_selects_canonical_b_path_analysis(self) -> None:
        research = self.research_state(evidence_receipts={
            "owner_timing": self.source_ref(OWNER),
            "causal_analysis": self.source_ref(CAUSAL),
            "b_latency_sensitivity": self.source_ref(SENSITIVITY),
        })
        built = self.build(research=research)
        self.assertEqual(built.returncode, 0, built.stdout)
        result = self.result()
        self.assertEqual(result["decision"], "SELECT")
        self.assertEqual(result["next_action"], "CAUSAL_MEASUREMENT")
        self.assertEqual(
            result["selected_slice"]["id"],
            "analyze.owner-b-response-latency-candidate",
        )
        self.assertTrue(result["state"]["b_latency_sensitivity_completed"])
        self.assertEqual(
            result["state"]["b_latency_sensitivity_status"],
            "H1_B_RESPONSE_LATENCY_SENSITIVE",
        )
        self.assertTrue(result["state"]["causal_selection_authorized"])
        self.assertEqual(
            result["state"]["causal_hypothesis"],
            "H1_B_RESPONSE_LATENCY",
        )
        self.assertEqual(
            result["inputs"]["verification_tools"]
            ["b_latency_sensitivity"]["path"],
            "npc/rv64/eval/ppa/tools/owner_b_latency_sensitivity.py",
        )

    def test_sensitivity_receipt_requires_bound_causal_receipt(self) -> None:
        research = self.research_state(evidence_receipts={
            "owner_timing": self.source_ref(OWNER),
            "b_latency_sensitivity": self.source_ref(SENSITIVITY),
        })
        built = self.build(research=research)
        self.assertEqual(built.returncode, 2, built.stdout)
        self.assertIn(
            "B-latency sensitivity requires owner and causal receipts",
            built.stdout,
        )

    def test_current_candidate_analysis_advances_to_ppa_reference(self) -> None:
        research = self.research_state(evidence_receipts={
            "owner_timing": self.source_ref(OWNER),
            "causal_analysis": self.source_ref(CAUSAL),
            "b_latency_sensitivity": self.source_ref(SENSITIVITY),
            "b_response_candidate_analysis": self.source_ref(CANDIDATE_ANALYSIS),
        })
        built = self.build(research=research)
        self.assertEqual(built.returncode, 0, built.stdout)
        result = self.result()
        self.assertEqual(result["decision"], "SELECT")
        self.assertEqual(result["next_action"], "PPA_QUALIFICATION")
        self.assertEqual(
            result["selected_slice"]["id"], "qualify.current-reference-ppa")
        self.assertTrue(
            result["state"]["b_response_candidate_analysis_completed"])
        self.assertEqual(
            result["inputs"]["verification_tools"]
            ["b_response_candidate_analysis"]["path"],
            "npc/rv64/eval/ppa/tools/owner_b_response_candidate_analysis.py",
        )

    def test_candidate_analysis_requires_bound_sensitivity_receipt(self) -> None:
        research = self.research_state(evidence_receipts={
            "owner_timing": self.source_ref(OWNER),
            "causal_analysis": self.source_ref(CAUSAL),
            "b_response_candidate_analysis": self.source_ref(CANDIDATE_ANALYSIS),
        })
        built = self.build(research=research)
        self.assertEqual(built.returncode, 2, built.stdout)
        self.assertIn(
            "requires owner, causal and sensitivity receipts", built.stdout)

    def test_current_reference_timing_fail_advances_to_timing_analysis(self) -> None:
        research = self.research_state(evidence_receipts={
            "owner_timing": self.source_ref(OWNER),
            "causal_analysis": self.source_ref(CAUSAL),
            "b_latency_sensitivity": self.source_ref(SENSITIVITY),
            "b_response_candidate_analysis": self.source_ref(CANDIDATE_ANALYSIS),
            "current_reference_ppa": self.source_ref(CURRENT_REFERENCE_PPA),
        })
        built = self.build(research=research)
        self.assertEqual(built.returncode, 0, built.stdout)
        result = self.result()
        self.assertEqual(result["decision"], "SELECT")
        self.assertEqual(result["next_action"], "CAUSAL_MEASUREMENT")
        self.assertEqual(
            result["selected_slice"]["id"],
            "analyze.current-timing-recovery-candidate")
        self.assertTrue(
            result["state"]["ppa_reference_measurement_completed"])
        self.assertTrue(
            result["state"]["ppa_engineering_reference_available"])
        self.assertEqual(result["state"]["ppa_timing_hard_gate"], "FAIL")
        self.assertFalse(result["state"]["ppa_reference_available"])
        self.assertEqual(
            result["inputs"]["verification_tools"]
            ["current_reference_ppa"]["path"],
            "npc/rv64/eval/ppa/tools/current_reference_ppa.py",
        )

    def test_current_reference_requires_candidate_analysis_receipt(self) -> None:
        research = self.research_state(evidence_receipts={
            "owner_timing": self.source_ref(OWNER),
            "causal_analysis": self.source_ref(CAUSAL),
            "b_latency_sensitivity": self.source_ref(SENSITIVITY),
            "current_reference_ppa": self.source_ref(CURRENT_REFERENCE_PPA),
        })
        built = self.build(research=research)
        self.assertEqual(built.returncode, 2, built.stdout)
        self.assertIn(
            "requires the B-response candidate receipt", built.stdout)

    def test_current_timing_gap_holds_without_authorized_rtl_slice(self) -> None:
        research = self.research_state(evidence_receipts={
            "owner_timing": self.source_ref(OWNER),
            "causal_analysis": self.source_ref(CAUSAL),
            "b_latency_sensitivity": self.source_ref(SENSITIVITY),
            "b_response_candidate_analysis": self.source_ref(CANDIDATE_ANALYSIS),
            "current_reference_ppa": self.source_ref(CURRENT_REFERENCE_PPA),
            "current_timing_path_analysis": self.source_ref(
                CURRENT_TIMING_ANALYSIS),
        })
        built = self.build(research=research)
        self.assertEqual(built.returncode, 1, built.stdout)
        result = self.result()
        self.assertEqual(result["decision"], "NO_ELIGIBLE")
        self.assertEqual(result["next_action"], "HOLD")
        self.assertIsNone(result["selected_slice"])
        self.assertTrue(
            result["state"]["current_timing_path_analysis_completed"])
        self.assertEqual(
            result["state"]["current_timing_candidate_id"],
            "NONE_OWNER_LIFETIME_UNPROVEN",
        )
        self.assertEqual(
            result["inputs"]["verification_tools"]
            ["current_timing_path_analysis"]["path"],
            "npc/rv64/eval/ppa/tools/current_timing_path_analysis.py",
        )

    def test_owner_lifetime_closure_selects_owner_bound_permit_experiment(self) -> None:
        self.catalog = json.loads(
            OWNER_LIFETIME_CATALOG.read_text(encoding="utf-8"))
        self.write_json(self.catalog_path, self.catalog)
        research = self.research_state(evidence_receipts={
            "owner_timing": self.source_ref(OWNER),
            "causal_analysis": self.source_ref(CAUSAL),
            "b_latency_sensitivity": self.source_ref(SENSITIVITY),
            "b_response_candidate_analysis": self.source_ref(CANDIDATE_ANALYSIS),
            "current_reference_ppa": self.source_ref(CURRENT_REFERENCE_PPA),
            "current_timing_path_analysis": self.source_ref(
                CURRENT_TIMING_ANALYSIS),
            "serialized_drain_owner_lifetime": self.source_ref(
                SERIALIZED_OWNER_LIFETIME),
        })
        built = self.build(research=research)
        self.assertEqual(built.returncode, 0, built.stdout)
        result = self.result()
        self.assertEqual(result["decision"], "SELECT")
        self.assertEqual(result["next_action"], "RTL_EXPERIMENT")
        self.assertEqual(
            result["selected_slice"]["id"],
            "experiment.serialized-owner-terminal-permit")
        self.assertTrue(
            result["state"]["serialized_drain_owner_lifetime_completed"])
        self.assertEqual(
            result["state"]["serialized_drain_candidate_id"],
            "serialized-owner-terminal-permit-v2")
        self.assertTrue(
            result["state"]["serialized_drain_experiment_authorized"])
        self.assertEqual(
            result["inputs"]["verification_tools"]
            ["serialized_drain_owner_lifetime"]["path"],
            "npc/rv64/eval/ppa/tools/"
            "serialized_drain_owner_lifetime_analysis.py",
        )

    def test_owner_lifetime_receipt_requires_timing_gap_receipt(self) -> None:
        research = self.research_state(evidence_receipts={
            "owner_timing": self.source_ref(OWNER),
            "causal_analysis": self.source_ref(CAUSAL),
            "b_latency_sensitivity": self.source_ref(SENSITIVITY),
            "b_response_candidate_analysis": self.source_ref(CANDIDATE_ANALYSIS),
            "current_reference_ppa": self.source_ref(CURRENT_REFERENCE_PPA),
            "serialized_drain_owner_lifetime": self.source_ref(
                SERIALIZED_OWNER_LIFETIME),
        })
        built = self.build(research=research)
        self.assertEqual(built.returncode, 2, built.stdout)
        self.assertIn(
            "requires current timing-path analysis", built.stdout)

    def test_tampered_current_reference_cannot_advance_selector(self) -> None:
        value = json.loads(CURRENT_REFERENCE_PPA.read_text(encoding="utf-8"))
        value["authorization"]["promotion_eligible"] = True
        receipt = self.work / "tampered-current-reference.json"
        self.write_json(receipt, value)
        research = self.research_state(evidence_receipts={
            "owner_timing": self.source_ref(OWNER),
            "causal_analysis": self.source_ref(CAUSAL),
            "b_latency_sensitivity": self.source_ref(SENSITIVITY),
            "b_response_candidate_analysis": self.source_ref(CANDIDATE_ANALYSIS),
            "current_reference_ppa": self.source_ref(receipt),
        })
        built = self.build(research=research)
        self.assertEqual(built.returncode, 2, built.stdout)
        self.assertIn(
            "current-reference PPA receipt is not canonical", built.stdout)

    def test_tampered_candidate_analysis_cannot_advance_selector(self) -> None:
        value = json.loads(CANDIDATE_ANALYSIS.read_text(encoding="utf-8"))
        value["authorization"]["new_production_rtl_change_authorized"] = True
        candidate = self.work / "tampered-candidate-analysis.json"
        self.write_json(candidate, value)
        research = self.research_state(evidence_receipts={
            "owner_timing": self.source_ref(OWNER),
            "causal_analysis": self.source_ref(CAUSAL),
            "b_latency_sensitivity": self.source_ref(SENSITIVITY),
            "b_response_candidate_analysis": self.source_ref(candidate),
        })
        built = self.build(research=research)
        self.assertEqual(built.returncode, 2, built.stdout)
        self.assertIn(
            "B-response candidate receipt is not canonical", built.stdout)

    def test_tampered_sensitivity_receipt_cannot_advance_selector(self) -> None:
        value = json.loads(SENSITIVITY.read_text(encoding="utf-8"))
        value["authorization"]["causal_selection_authorized"] = False
        sensitivity = self.work / "tampered-sensitivity.json"
        self.write_json(sensitivity, value)
        research = self.research_state(evidence_receipts={
            "owner_timing": self.source_ref(OWNER),
            "causal_analysis": self.source_ref(CAUSAL),
            "b_latency_sensitivity": self.source_ref(sensitivity),
        })
        built = self.build(research=research)
        self.assertEqual(built.returncode, 2, built.stdout)
        self.assertIn(
            "B-latency sensitivity receipt is not canonical", built.stdout)

    def test_tampered_causal_receipt_cannot_advance_selector(self) -> None:
        value = json.loads(CAUSAL.read_text(encoding="utf-8"))
        value["authorization"]["causal_selection_authorized"] = True
        causal = self.work / "tampered-causal.json"
        self.write_json(causal, value)
        research = self.research_state(evidence_receipts={
            "owner_timing": self.source_ref(OWNER),
            "causal_analysis": self.source_ref(causal),
        })
        built = self.build(research=research)
        self.assertEqual(built.returncode, 2, built.stdout)
        self.assertIn("causal analysis receipt is not canonical", built.stdout)

    def test_research_state_cannot_forge_authority_facts(self) -> None:
        research = self.research_state(facts={
            "owner_timing_measured": True,
            "causal_selection_authorized": True,
            "causal_hypothesis": "H2_WRITE_CONCURRENCY",
            "ppa_reference_available": True,
        })
        built = self.build(research=research)
        self.assertEqual(built.returncode, 2, built.stdout)
        self.assertIn(
            "research state cannot override authority facts", built.stdout)

    def test_causal_closure_precedes_rtl_with_ppa_qualification(self) -> None:
        decision = self.decide_with_authority_facts(
            owner_timing_measured=True,
            causal_selection_authorized=True,
            causal_hypothesis="H2_WRITE_CONCURRENCY",
            b_response_candidate_analysis_completed=True,
            ppa_reference_available=False,
        )
        self.assertEqual(
            decision[4]["id"],
            "qualify.current-reference-ppa",
        )

    def test_causal_and_ppa_evidence_selects_one_rtl_experiment(self) -> None:
        decision = self.decide_with_authority_facts(
            owner_timing_measured=True,
            causal_selection_authorized=True,
            causal_hypothesis="H2_WRITE_CONCURRENCY",
            ppa_reference_available=True,
        )
        self.assertEqual(
            decision[4]["id"],
            "experiment.increase-write-concurrency",
        )
        self.assertEqual(decision[1], "RTL_EXPERIMENT")

    def test_research_state_wrong_design_is_rejected(self) -> None:
        research = self.research_state(design_id="sha256:" + "0" * 64)
        built = self.build(research=research)
        self.assertEqual(built.returncode, 2, built.stdout)
        self.assertIn("research state design-id mismatch", built.stdout)

    def test_cpi_area_tradeoff_requires_research(self) -> None:
        self.catalog["slices"] = [
            self.simple_candidate("fast-large", mode="multiobjective"),
            self.simple_candidate("small-slower", mode="multiobjective"),
        ]
        self.write_json(self.catalog_path, self.catalog)
        research = self.research_state(observations={
            "fast-large": self.observation(1.05, 0.97),
            "small-slower": self.observation(1.02, 1.00),
        })
        built = self.build(report_only=True, research=research)
        self.assertEqual(built.returncode, 0, built.stdout)
        result = self.result()
        self.assertEqual(result["decision"], "RESEARCH_REQUIRED")
        self.assertFalse(result["tradeoff_analysis"]["scalarization_used"])
        self.assertEqual(
            result["tradeoff_analysis"]["timing_role"],
            "HARD_GATE_NOT_OBJECTIVE",
        )

    def test_overlapping_interval_never_becomes_epsilon_dominance(self) -> None:
        self.catalog["slices"] = [
            self.simple_candidate("wide-area-winner", mode="multiobjective"),
            self.simple_candidate("narrow-area-loser", mode="multiobjective"),
        ]
        self.write_json(self.catalog_path, self.catalog)
        left = self.observation(1.0, 1.10)
        left["performance_ratio"] = {
            "low": 0.9995, "nominal": 1.0, "high": 1.0005,
        }
        right = self.observation(1.0002, 1.00)
        right["performance_ratio"] = {
            "low": 1.0, "nominal": 1.0002, "high": 1.0004,
        }
        research = self.research_state(observations={
            "wide-area-winner": left,
            "narrow-area-loser": right,
        })
        built = self.build(report_only=True, research=research)
        self.assertEqual(built.returncode, 0, built.stdout)
        result = self.result()
        self.assertEqual(result["decision"], "RESEARCH_REQUIRED")
        self.assertEqual(
            result["eligible_front"],
            ["narrow-area-loser", "wide-area-winner"],
        )

    def test_measured_pareto_dominance_selects_unique_candidate(self) -> None:
        self.catalog["slices"] = [
            self.simple_candidate("dominant", mode="multiobjective"),
            self.simple_candidate("dominated", mode="multiobjective"),
        ]
        self.write_json(self.catalog_path, self.catalog)
        research = self.research_state(observations={
            "dominant": self.observation(1.05, 1.00),
            "dominated": self.observation(1.02, 0.98),
        })
        built = self.build(research=research)
        self.assertEqual(built.returncode, 0, built.stdout)
        self.assertEqual(self.result()["selected_slice"]["id"], "dominant")

    def test_timing_fail_cannot_be_bought_by_cpi(self) -> None:
        self.catalog["slices"] = [
            self.simple_candidate("timing-fail", mode="multiobjective"),
            self.simple_candidate("timing-pass", mode="multiobjective"),
        ]
        self.write_json(self.catalog_path, self.catalog)
        research = self.research_state(observations={
            "timing-fail": self.observation(1.20, 1.10, slack=-0.01),
            "timing-pass": self.observation(1.01, 1.00, slack=0.12),
        })
        built = self.build(research=research)
        self.assertEqual(built.returncode, 0, built.stdout)
        result = self.result()
        self.assertEqual(result["selected_slice"]["id"], "timing-pass")
        failed = next(
            item for item in result["candidate_dispositions"]
            if item["id"] == "timing-fail")
        self.assertEqual(failed["disposition"], "REJECTED_HARD_GATE")
        self.assertIn("TIMING_HARD_GATE_FAIL", failed["reasons"])

    def test_timing_interval_crossing_gate_requires_sta_refinement(self) -> None:
        self.catalog["slices"] = [
            self.simple_candidate("timing-uncertain", mode="multiobjective"),
            self.simple_candidate("timing-pass", mode="multiobjective"),
        ]
        self.write_json(self.catalog_path, self.catalog)
        uncertain = self.observation(1.20, 1.10)
        uncertain["timing_worst_slack_ns"] = {
            "low": 0.08, "nominal": 0.10, "high": 0.12,
        }
        research = self.research_state(observations={
            "timing-uncertain": uncertain,
            "timing-pass": self.observation(1.01, 1.00, slack=0.12),
        })
        built = self.build(report_only=True, research=research)
        self.assertEqual(built.returncode, 0, built.stdout)
        result = self.result()
        self.assertEqual(result["decision"], "RESEARCH_REQUIRED")
        self.assertEqual(
            result["tradeoff_analysis"]["front_status"],
            "TIMING_GATE_AMBIGUOUS",
        )
        self.assertEqual(
            result["tradeoff_analysis"]["timing_role"],
            "HARD_GATE_REQUIRES_REFINEMENT",
        )

    def test_power_qualification_mismatch_requires_research(self) -> None:
        self.catalog["slices"] = [
            self.simple_candidate("qualified", mode="multiobjective"),
            self.simple_candidate("proxy", mode="multiobjective"),
        ]
        self.write_json(self.catalog_path, self.catalog)
        research = self.research_state(observations={
            "qualified": self.observation(
                1.02, 1.00, power_qualified=True, power_efficiency=1.01),
            "proxy": self.observation(1.03, 1.01),
        })
        built = self.build(report_only=True, research=research)
        self.assertEqual(built.returncode, 0, built.stdout)
        self.assertEqual(self.result()["decision"], "RESEARCH_REQUIRED")
        self.assertEqual(
            self.result()["tradeoff_analysis"]["front_status"],
            "INCOMPARABLE_QUALIFICATION",
        )

    def test_tampered_decision_is_not_canonical(self) -> None:
        built = self.build()
        self.assertEqual(built.returncode, 0, built.stdout)
        value = self.result()
        value["next_action"] = "PPA_QUALIFICATION"
        self.write_json(self.result_path, value)
        verified = self.run_tool(
            "verify", "--input", self.relative(self.result_path))
        self.assertEqual(verified.returncode, 2, verified.stdout)
        self.assertIn("not canonical", verified.stdout)


if __name__ == "__main__":
    unittest.main()
