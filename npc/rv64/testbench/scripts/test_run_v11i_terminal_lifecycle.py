from __future__ import annotations

import unittest
from pathlib import Path

from run_v11i_terminal_lifecycle import (
    ABA_FAIL,
    ABA_OBSERVATION_FAIL,
    HOLDER_ASSERT,
    FOCUSED_DEFINE,
    STALE_ACTIVE,
    TB_PASS,
    TESTBENCH_OBSERVATION,
    WRAP_PASS,
    Profile,
    build_mutant,
    evaluate_profile,
)


REPO_ROOT = Path(__file__).resolve().parents[4]
BACKEND = REPO_ROOT / "npc" / "rv64" / "vsrc" / "execute" / "OooIntBackend.v"


class V11ITerminalLifecycleRunnerTest(unittest.TestCase):
    def evaluate(
        self,
        profile: Profile,
        log: str,
        *,
        compile_rc: int = 0,
        sim_rc: int | None = 0,
        artifact_exists: bool = True,
    ) -> bool:
        passed, _ = evaluate_profile(
            profile,
            compile_rc=compile_rc,
            sim_rc=sim_rc,
            log_text=log,
            artifact_exists=artifact_exists,
        )
        return passed

    def test_production_requires_exact_wrap_and_tb_pass(self) -> None:
        profile = Profile(
            "production-assert",
            assertions=True,
            stale_tuple_variant=False,
        )
        log = (
            f"{WRAP_PASS} owners=33 PASS\n"
            f"{TB_PASS}\n"
        )
        self.assertTrue(self.evaluate(profile, log))
        self.assertFalse(self.evaluate(profile, f"{TB_PASS}\n"))
        self.assertFalse(
            self.evaluate(profile, log + "[V11I-QUIET][FAIL] duplicate\n")
        )
        self.assertFalse(self.evaluate(profile, log, sim_rc=1))

    def test_assert_profile_requires_holder_next_rejection(self) -> None:
        profile = Profile(
            "stale-tuple-assert",
            assertions=True,
            stale_tuple_variant=True,
        )
        log = f"{STALE_ACTIVE} token=0\n{HOLDER_ASSERT} token=0\n"
        self.assertTrue(self.evaluate(profile, log, sim_rc=1))
        self.assertFalse(
            self.evaluate(profile, f"{STALE_ACTIVE} token=0\n", sim_rc=1)
        )
        self.assertFalse(self.evaluate(profile, log, sim_rc=0))
        self.assertFalse(
            self.evaluate(profile, log, sim_rc=1, artifact_exists=False)
        )

    def test_release_profile_requires_independent_aba_observation(self) -> None:
        profile = Profile(
            "stale-tuple-release",
            assertions=False,
            stale_tuple_variant=True,
        )
        log = f"{STALE_ACTIVE} token=0\n{ABA_FAIL} token=0\n"
        self.assertTrue(self.evaluate(profile, log, sim_rc=1))
        self.assertFalse(
            self.evaluate(
                profile,
                log + f"{ABA_OBSERVATION_FAIL} early sample\n",
                sim_rc=1,
            )
        )
        self.assertFalse(
            self.evaluate(
                profile,
                log + f"{HOLDER_ASSERT} unexpected\n",
                sim_rc=1,
            )
        )

    def test_mutant_is_compile_source_copy_with_exact_receipts(self) -> None:
        production = BACKEND.read_text(encoding="utf-8")
        mutated, receipts = build_mutant(production)

        self.assertEqual(5, len(receipts))
        self.assertTrue(all(item["anchor_count"] == 1 for item in receipts))
        self.assertIn("v11i_stale_tuple_wait_q", mutated)
        self.assertIn("v11i_lane0_terminal_token_w", mutated)
        self.assertNotEqual(production, mutated)
        self.assertNotIn("v11i_stale_tuple_wait_q", production)

    def test_mutation_generation_fails_closed_on_missing_anchor(self) -> None:
        with self.assertRaisesRegex(ValueError, "expected one RTL anchor"):
            build_mutant("module empty; endmodule\n")

    def test_contract_binds_compile_define_and_lane0_response(self) -> None:
        self.assertEqual(
            "-DV11I_TERMINAL_LIFECYCLE_FOCUSED",
            FOCUSED_DEFINE,
        )
        self.assertIn("lane0 response-terminal", TESTBENCH_OBSERVATION)
        self.assertNotIn("lane6", TESTBENCH_OBSERVATION)
        self.assertNotIn("+V11I_TERMINAL_LIFECYCLE_ONLY", TESTBENCH_OBSERVATION)


if __name__ == "__main__":
    unittest.main()
