from __future__ import annotations

import copy
import importlib.util
import pathlib
import sys
import tempfile
import unittest


ROOT = pathlib.Path(__file__).resolve().parents[5]
TOOL_PATH = ROOT / "npc/rv64/eval/ppa/tools/v8s_dual_memory_core_current.py"
LEGACY_TEST_PATH = (
    ROOT
    / ".github/task-runs/2026-07-20-rv64-v8s-dual-memory-core-integration"
    / "test_check_v8s_dual_memory_core.py"
)


def load_module(name: str, path: pathlib.Path):
    spec = importlib.util.spec_from_file_location(name, path)
    assert spec is not None and spec.loader is not None
    module = importlib.util.module_from_spec(spec)
    sys.modules[name] = module
    spec.loader.exec_module(module)
    return module


CURRENT = load_module("v8s_current_checker_under_test", TOOL_PATH)
CURRENT_MUTATOR = load_module(
    "v8s_current_mutator_under_test",
    ROOT / "npc/rv64/eval/ppa/tools/v8s_dual_memory_core_mutator_current.py",
)
LEGACY_TEST = load_module("v8s_legacy_checker_tests", LEGACY_TEST_PATH)
LEGACY_TEST.CHECKER = CURRENT


class CurrentHoldAwareTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.baseline = CURRENT.load_sources(ROOT)

    def check_passes(self, sources: dict[str, str]) -> bool:
        matches = [
            item
            for item in CURRENT.evaluate(sources)
            if item.check_id == "backend.dual_sq_ports_and_singleton_exclusion"
        ]
        self.assertEqual(len(matches), 1)
        return matches[0].passed

    def mutated(self, old: str, new: str) -> dict[str, str]:
        sources = copy.deepcopy(self.baseline)
        self.assertEqual(sources["backend"].count(old), 1)
        sources["backend"] = sources["backend"].replace(old, new, 1)
        return sources

    def test_current_hold_aware_baseline_passes(self) -> None:
        self.assertTrue(self.check_passes(self.baseline))

    def test_bank1_retry_cannot_bypass_effective_singleton(self) -> None:
        sources = self.mutated(
            "!mem_req_effective_singleton_w &&\n      mem_retry1_req_valid_w;",
            "mem_retry1_req_valid_w;",
        )
        self.assertFalse(self.check_passes(sources))

    def test_bank1_hold_cannot_be_ignored_by_singleton_wait(self) -> None:
        sources = self.mutated(
            "mem1_req_hold_valid_q && mem_request_transport_open_w &&",
            "1'b0 && mem_request_transport_open_w &&",
        )
        self.assertFalse(self.check_passes(sources))

    def test_effective_buffer_singleton_cannot_be_dropped(self) -> None:
        sources = self.mutated(
            "grant_buffer_w || (grant_issue0_w && issue0_is_amo_w);",
            "(grant_issue0_w && issue0_is_amo_w);",
        )
        self.assertFalse(self.check_passes(sources))


class CurrentMutatorTests(unittest.TestCase):
    def test_reconstruction_interface_preserves_all_identities(self) -> None:
        self.assertEqual(
            set(CURRENT_MUTATOR.MUTATIONS),
            set(CURRENT_MUTATOR.LEGACY.MUTATIONS),
        )
        for name, anchor in CURRENT_MUTATOR.CURRENT_MUTATIONS.items():
            self.assertEqual(CURRENT_MUTATOR.MUTATIONS[name], anchor)
        self.assertIs(
            CURRENT_MUTATOR.F3_MUTATIONS,
            CURRENT_MUTATOR.LEGACY.F3_MUTATIONS,
        )
        self.assertIs(
            CURRENT_MUTATOR.V8V_MUTATIONS,
            CURRENT_MUTATOR.LEGACY.V8V_MUTATIONS,
        )

    def test_all_eighteen_live_anchors_are_exact(self) -> None:
        backend = ROOT / "npc/rv64/vsrc/execute/OooIntBackend.v"
        control = ROOT / "npc/rv64/vsrc/control/OooCoreSliceControlGate.v"
        with tempfile.TemporaryDirectory() as raw:
            output_root = pathlib.Path(raw)
            for name in sorted(CURRENT_MUTATOR.LEGACY.MUTATIONS):
                with self.subTest(name=name):
                    source = (
                        control
                        if name == "raw_checkpoint_local_flush_bypass"
                        else backend
                    )
                    output = output_root / name / source.name
                    CURRENT_MUTATOR.mutate(name, source, output)
                    self.assertTrue(output.is_file())
                    self.assertNotEqual(
                        output.read_bytes(), source.read_bytes(), name
                    )

def load_tests(loader, tests, pattern):
    suite = unittest.TestSuite()
    suite.addTests(loader.loadTestsFromTestCase(LEGACY_TEST.CheckerTests))
    suite.addTests(loader.loadTestsFromTestCase(CurrentHoldAwareTests))
    suite.addTests(loader.loadTestsFromTestCase(CurrentMutatorTests))
    return suite


if __name__ == "__main__":
    unittest.main()
