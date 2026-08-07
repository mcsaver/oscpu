from __future__ import annotations

import copy
import importlib.util
import pathlib
import sys
import tempfile
import unittest


ROOT = pathlib.Path(__file__).resolve().parents[5]
TOOL = ROOT / "npc/rv64/eval/ppa/tools/architecture_current_delta_rebind.py"
SPEC = importlib.util.spec_from_file_location(
    "architecture_current_delta_rebind_tested", TOOL)
assert SPEC is not None and SPEC.loader is not None
rebind = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = rebind
SPEC.loader.exec_module(rebind)

SOURCE = ROOT / (
    ".github/task-runs/2026-08-06-rv64-v15j-arch-stable-current-f7a/"
    "evidence/architecture-current-final.json"
)
BASELINE_RTL = ROOT / (
    ".github/task-runs/2026-08-06-rv64-v15i-architecture-debt-current-f7a/"
    "evidence/l0-current-f7a-v15i-a3/inputs.pre.json"
)
CURRENT_RTL = ROOT / (
    ".github/task-runs/2026-08-07-rv64-v15p-control-loop-current-f7a/"
    "evidence/module/inputs.pre.json"
)
LAYERED = ROOT / "npc/rv64/eval/ppa/evidence/layered-system-signoff-current.json"
CENSUS = ROOT / "npc/rv64/design/arch/producer-holder-census.json"


class ArchitectureCurrentDeltaRebindTests(unittest.TestCase):
    def project(
        self, *, source: pathlib.Path = SOURCE,
        baseline: pathlib.Path = BASELINE_RTL,
        current: pathlib.Path = CURRENT_RTL,
    ) -> tuple[dict, dict]:
        return rebind.project_manifest(
            root=ROOT,
            source_path=source,
            baseline_rtl_path=baseline,
            current_rtl_path=current,
            layered_path=LAYERED,
            census_path=CENSUS,
        )

    def test_exact_current_delta_projects_green_nine_of_nine(self) -> None:
        manifest, context = self.project()
        self.assertEqual(
            [item["path"] for item in context["rtl_delta"]],
            [
                "npc/rv64/vsrc/control/OooPendingSystemAdmissionCancelGate.v",
                "npc/rv64/vsrc/memory/OooLsuAxiLaneAdapter.v",
            ],
        )
        result = rebind.evaluate_payload(ROOT, manifest)
        self.assertEqual(result["overall_status"], "GREEN")
        self.assertEqual(len(result["gates"]), 9)
        self.assertEqual(rebind.negative_summary(ROOT, manifest)["detected"], 4)

    def test_delta_entering_directed_rtl_source_closure_is_rejected(self) -> None:
        current_value = rebind.read_json(CURRENT_RTL)
        baseline_value = copy.deepcopy(current_value)
        path = "npc/rv64/vsrc/execute/OooIntBackend.v"
        baseline_value["groups"]["rtl"][path] = "0" * 64
        baseline_value["design_id"] = "sha256:" + rebind.arch.canonical_digest(
            baseline_value["groups"]["rtl"])
        source_value = rebind.read_json(SOURCE)
        source_value["design_id"] = baseline_value["design_id"]
        with tempfile.TemporaryDirectory(dir=ROOT) as raw:
            directory = pathlib.Path(raw)
            baseline_path = directory / "baseline.json"
            source_path = directory / "source.json"
            rebind.write_json(baseline_path, baseline_value)
            rebind.write_json(source_path, source_value)
            with self.assertRaisesRegex(
                rebind.RebindError, "directed source closure",
            ):
                self.project(source=source_path, baseline=baseline_path)

    def test_non_authorized_provenance_drift_is_rejected(self) -> None:
        source_value = rebind.read_json(SOURCE)
        files = source_value["tests"]["pair_matrix"]["provenance"]["files"]
        path = next(
            rel for rel in files
            if rel not in rebind.AUTHORIZED_PROVENANCE_DRIFT
        )
        files[path] = "0" * 64
        with tempfile.TemporaryDirectory(dir=ROOT) as raw:
            path = pathlib.Path(raw) / "source.json"
            rebind.write_json(path, source_value)
            with self.assertRaisesRegex(
                rebind.RebindError, "exceeds authorized",
            ):
                self.project(source=path)

    def test_stale_record_failure_cannot_be_hidden_by_projection(self) -> None:
        source_value = rebind.read_json(SOURCE)
        source_value["tests"]["memory_ordering"]["status"] = "FAIL"
        with tempfile.TemporaryDirectory(dir=ROOT) as raw:
            path = pathlib.Path(raw) / "source.json"
            rebind.write_json(path, source_value)
            with self.assertRaisesRegex(
                rebind.RebindError, "stale cause exceeds",
            ):
                self.project(source=path)

    def test_current_rtl_manifest_cannot_drift_from_live_design(self) -> None:
        current_value = rebind.read_json(CURRENT_RTL)
        current_value["groups"]["rtl"][
            "npc/rv64/vsrc/memory/OooLsuAxiLaneAdapter.v"
        ] = "0" * 64
        current_value["design_id"] = "sha256:" + rebind.arch.canonical_digest(
            current_value["groups"]["rtl"])
        with tempfile.TemporaryDirectory(dir=ROOT) as raw:
            path = pathlib.Path(raw) / "current.json"
            rebind.write_json(path, current_value)
            with self.assertRaisesRegex(
                rebind.RebindError, "differs from live",
            ):
                self.project(current=path)


if __name__ == "__main__":
    unittest.main()
