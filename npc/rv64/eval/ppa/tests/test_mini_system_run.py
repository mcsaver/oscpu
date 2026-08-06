from __future__ import annotations

import importlib.util
import pathlib
import re
import sys
import tempfile
import unittest


ROOT = pathlib.Path(__file__).resolve().parents[5]
TOOL_PATH = ROOT / "npc/rv64/eval/ppa/tools/mini_system_run.py"
SPEC = importlib.util.spec_from_file_location("mini_system_run_under_test", TOOL_PATH)
assert SPEC and SPEC.loader
TOOL = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = TOOL
SPEC.loader.exec_module(TOOL)


def binding_text(case_name: str = "all") -> str:
    digest = "a" * 64
    values = {
        "schema": "npc-rv64-l2-mini-system-run-binding-v1",
        "rtl_design_id": "sha256:" + "b" * 64,
        "production_rtl_file_count": "146",
        "simulator_sha256": digest,
        "simulator_source_sha256": digest,
        "layer_source_sha256": digest,
        "payload_elf_sha256": digest,
        "payload_bin_sha256": digest,
        "effective_dtb_sha256": digest,
        "opensbi_fw_sha256": digest,
        "payload_load_addr": "0x80400000",
        "effective_dtb_addr": "0x82300000",
        "opensbi_fw_jump_fdt_addr": "0x82300000",
        "effective_dtb_syscon": "1",
        "l2_case": case_name,
        "max_cycles": "1000000",
        "OOO_ASSERT": "1",
        "OOO_CSR_QUEUE_HEAD": "1",
        "OOO_TERMINAL_HOLDER_ASSERT": "1",
        "ubuntu2204_full_simulation": "not_launched",
    }
    return "\n".join(f"{key}={value}" for key, value in values.items()) + "\n"


def console_text(case_name: str = "all") -> str:
    lines = ["OpenSBI v1.8"]
    lines.extend(TOOL.phases_for_case(case_name))
    lines.extend(
        (
            "syscon-reset: poweroff requested value=0x00005555 "
            "pc=0x0000000080000100 cycle=850000 commit=290000",
            "HIT GOOD TRAP at pc = 0x80000100",
            "exit via system-reset, code=0, cycles=900000, commits=300000",
            "total guest instructions = 300000",
            "total guest cycles = 900000",
        )
    )
    return "\n".join(lines) + "\n"


def npc_text(case_name: str = "all") -> str:
    stream = ("boot\n" + "\n".join(TOOL.phases_for_case(case_name)) + "\n").encode(
        "ascii"
    )
    def marker_observation(marker: str) -> tuple[int, int]:
        end = stream.index(marker.encode("ascii")) + len(marker) - 1
        return (end + 1) * 1000, (end + 1) * 100

    def midpoint(left: tuple[int, int], right: tuple[int, int]) -> tuple[int, int]:
        return (left[0] + right[0]) // 2, (left[1] + right[1]) // 2

    lines = [
        f"[uart-trace] tx={index} cycle={index * 1000} commit={index * 100} "
        f"data=0x{byte:02x} char='.'"
        for index, byte in enumerate(stream, start=1)
    ]
    lines.extend(f"[guest] {marker}" for marker in TOOL.phases_for_case(case_name))
    selector = TOOL.CASE_SELECTORS[case_name]
    selector_time = midpoint(
        marker_observation("__RV64_L2_CASE_SELECT__"),
        marker_observation(TOOL.CASE_MARKERS[case_name]),
    )
    lines.append(
        f"[uart-rx] pop=1 cycle={selector_time[0]} commit={selector_time[1]} "
        f"data=0x{selector:02x} char='.'"
    )
    if case_name in ("interrupt", "all"):
        irq_time = midpoint(
            marker_observation("__RV64_L2_MMIO_PASS__"),
            marker_observation("__RV64_L2_PLIC_UART_IRQ_PASS__"),
        )
        lines.append(
            f"[irq-trace] event=1 cycle={irq_time[0]} commit={irq_time[1]} "
            "uart_irq=1 plic_irq=1"
        )
    return "\n".join(lines) + "\n"


class MiniSystemRunTests(unittest.TestCase):
    def run_candidate(
        self,
        case_name: str = "all",
        console: str | None = None,
        npc: str | None = None,
        binding: str | None = None,
    ):
        with tempfile.TemporaryDirectory() as raw:
            root = pathlib.Path(raw)
            console_path = root / "console.log"
            npc_path = root / "npc.log"
            binding_path = root / "binding.txt"
            console_path.write_text(
                console if console is not None else console_text(case_name)
            )
            npc_path.write_text(npc if npc is not None else npc_text(case_name))
            binding_path.write_text(
                binding if binding is not None else binding_text(case_name)
            )
            return TOOL.parse_execution(console_path, npc_path, binding_path)

    def test_all_case_supports_full_l2_claim(self) -> None:
        result = self.run_candidate()
        self.assertEqual(result["status"], "PASS")
        self.assertEqual(result["signoff_scope"], "full-l2")
        self.assertEqual(result["selector_rx"]["data"], 0x78)

    def test_all_seven_cases_have_exact_scope(self) -> None:
        for case_name in TOOL.CASE_SELECTORS:
            with self.subTest(case_name=case_name):
                result = self.run_candidate(case_name=case_name)
                expected = "full-l2" if case_name == "all" else "directed-case"
                self.assertEqual(result["signoff_scope"], expected)

    def test_payload_fail_marker_is_rejected(self) -> None:
        with self.assertRaises(TOOL.MiniSystemError):
            self.run_candidate(console=console_text() + "__RV64_L2_FAIL__\n")

    def test_duplicate_terminal_is_rejected(self) -> None:
        with self.assertRaises(TOOL.MiniSystemError):
            self.run_candidate(console=console_text() + "HIT GOOD TRAP\n")

    def test_missing_phase_is_rejected(self) -> None:
        marker = "__RV64_L2_TIMER_IRQ_PASS__"
        with self.assertRaises(TOOL.MiniSystemError):
            self.run_candidate(npc=npc_text().replace(marker, "_" * len(marker)))

    def test_unselected_phase_is_rejected(self) -> None:
        with self.assertRaises(TOOL.MiniSystemError):
            self.run_candidate(
                case_name="shutdown",
                console=console_text("shutdown") + "__RV64_L2_SV39_PASS__\n",
            )

    def test_wrong_selector_is_rejected(self) -> None:
        with self.assertRaises(TOOL.MiniSystemError):
            self.run_candidate(npc=npc_text().replace("data=0x78", "data=0x70"))

    def test_selector_before_case_select_is_rejected(self) -> None:
        damaged = re.sub(
            r"\[uart-rx\] pop=1 cycle=\d+ commit=\d+",
            "[uart-rx] pop=1 cycle=1 commit=1",
            npc_text(),
            count=1,
        )
        with self.assertRaises(TOOL.MiniSystemError):
            self.run_candidate(npc=damaged)

    def test_missing_uart_to_plic_assertion_is_rejected(self) -> None:
        with self.assertRaises(TOOL.MiniSystemError):
            self.run_candidate(npc=npc_text().replace("plic_irq=1", "plic_irq=0"))

    def test_reordered_terminal_transaction_is_rejected(self) -> None:
        damaged = console_text().replace(
            "syscon-reset: poweroff requested value=0x00005555 "
            "pc=0x0000000080000100 cycle=850000 commit=290000\n"
            "HIT GOOD TRAP at pc = 0x80000100",
            "HIT GOOD TRAP at pc = 0x80000100\n"
            "syscon-reset: poweroff requested value=0x00005555 "
            "pc=0x0000000080000100 cycle=850000 commit=290000",
        )
        with self.assertRaises(TOOL.MiniSystemError):
            self.run_candidate(console=damaged)

    def test_syscon_without_cycle_commit_is_rejected(self) -> None:
        damaged = console_text().replace(" cycle=850000 commit=290000", "")
        with self.assertRaises(TOOL.MiniSystemError):
            self.run_candidate(console=damaged)

    def test_rtl_assertion_is_rejected(self) -> None:
        with self.assertRaises(TOOL.MiniSystemError):
            self.run_candidate(npc=npc_text() + "[V15-L2-ASSERT-FAIL]\n")


if __name__ == "__main__":
    unittest.main()
