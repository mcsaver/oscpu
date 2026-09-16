#!/usr/bin/env python3

from __future__ import annotations

import unittest
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[4]
SIM_TOP = REPO_ROOT / "npc/rv64/vsrc/sim/NpcSimTop.sv"
CPU_EXEC = REPO_ROOT / "npc/rv64/csrc/cpu/cpu-exec.cpp"


def diagnostic_decision(
    flags: int,
    *,
    sv39_lower_user_pc: bool,
    dynamic_user_pc: bool,
) -> tuple[bool, bool]:
    debug_valid = bool((flags >> 63) & 1)
    priv = (flags >> 27) & 0x3
    sv39 = bool((flags >> 29) & 1)
    user_context = (
        debug_valid and sv39 and sv39_lower_user_pc
    ) or dynamic_user_pc
    progress_eligible = user_context and (
        (debug_valid and priv == 0) or dynamic_user_pc
    )
    return user_context, progress_eligible


class DebugOooFlagsContractTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.sim_top = SIM_TOP.read_text(encoding="utf-8")
        cls.cpu_exec = CPU_EXEC.read_text(encoding="utf-8")

    def test_enabled_payload_sets_only_the_new_valid_msb(self) -> None:
        self.assertIn(
            "assign debug_ooo_flags_o = {\n"
            "    1'b1,\n"
            "    17'd0,",
            self.sim_top,
        )
        self.assertIn("assign debug_ooo_flags_o = 64'd0;", self.sim_top)
        self.assertIn(
            "configuration-valid, not a per-cycle transaction-valid signal",
            self.sim_top,
        )
        self.assertNotIn(
            "assign debug_ooo_flags_o = {\n    18'd0,",
            self.sim_top,
        )

    def test_host_decoder_gates_privilege_interpretation_with_valid(self) -> None:
        for token in (
            "bool debug_valid = ((flags >> 63) & 0x1u) != 0;",
            "(debug_valid && sv39 && user_pc) || dynamic_user_pc",
            "((debug_valid && priv == 0) || dynamic_user_pc)",
            '" debug_valid=%u priv=%llu sv39=%u"',
            '"ooo flags=0x%016llx valid=%llu',
            "payload/configuration validity, not transaction validity",
        ):
            with self.subTest(token=token):
                self.assertIn(token, self.cpu_exec)

    def test_user_trace_is_observational_only(self) -> None:
        start = self.cpu_exec.index("static void maybe_log_user_trace(")
        end = self.cpu_exec.index(
            "\nstatic void maybe_log_ecall_trap(",
            start,
        )
        body = self.cpu_exec[start:end]
        for forbidden in (
            "npc_state(",
            "report_exit(",
            "report_trap(",
            "finish_exec(",
            "g_stop_requested",
            "halt_ret",
        ):
            with self.subTest(forbidden=forbidden):
                self.assertNotIn(forbidden, body)
        self.assertIn('LogBothTag("user_progress"', body)
        self.assertIn('LogBothTag("user_ecall"', body)

    def test_disabled_payload_cannot_claim_sv39_or_privilege(self) -> None:
        user_context, progress = diagnostic_decision(
            0,
            sv39_lower_user_pc=True,
            dynamic_user_pc=False,
        )
        self.assertFalse(user_context)
        self.assertFalse(progress)

    def test_dynamic_user_pc_remains_observable_with_invalid_payload(self) -> None:
        user_context, progress = diagnostic_decision(
            0,
            sv39_lower_user_pc=True,
            dynamic_user_pc=True,
        )
        self.assertTrue(user_context)
        self.assertTrue(progress)

    def test_valid_u_mode_sv39_payload_remains_observable(self) -> None:
        flags = (1 << 63) | (1 << 29)
        user_context, progress = diagnostic_decision(
            flags,
            sv39_lower_user_pc=True,
            dynamic_user_pc=False,
        )
        self.assertTrue(user_context)
        self.assertTrue(progress)

    def test_clearing_valid_is_a_negative_mutation(self) -> None:
        valid_flags = (1 << 63) | (1 << 29)
        mutated_flags = valid_flags & ~(1 << 63)
        self.assertEqual(
            diagnostic_decision(
                valid_flags,
                sv39_lower_user_pc=True,
                dynamic_user_pc=False,
            ),
            (True, True),
        )
        self.assertEqual(
            diagnostic_decision(
                mutated_flags,
                sv39_lower_user_pc=True,
                dynamic_user_pc=False,
            ),
            (False, False),
        )


if __name__ == "__main__":
    unittest.main()
