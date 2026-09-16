from __future__ import annotations

import importlib.util
import pathlib
import re
import sys
import tempfile
import unittest


ROOT = pathlib.Path(__file__).resolve().parents[5]
TOOL_PATH = ROOT / "npc/rv64/eval/ppa/tools/lightweight_linux_run.py"
SPEC = importlib.util.spec_from_file_location("lightweight_linux_run_under_test", TOOL_PATH)
assert SPEC and SPEC.loader
TOOL = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = TOOL
SPEC.loader.exec_module(TOOL)


def binding_text(case_name: str = "all") -> str:
    digest = "a" * 64
    values = {
        "schema": "npc-rv64-l3-lightweight-linux-run-binding-v1",
        "rtl_design_id": "sha256:" + "b" * 64,
        "production_rtl_file_count": "146",
        "simulator_sha256": digest,
        "simulator_source_sha256": digest,
        "layer_source_sha256": digest,
        "linux_image_sha256": digest,
        "initramfs_sha256": digest,
        "guest_dtb_sha256": digest,
        "opensbi_platform_dtb_sha256": digest,
        "opensbi_fw_sha256": digest,
        "kernel_effective_config_sha256": digest,
        "pid1_sha256": digest,
        "effective_dtb_sha256": digest,
        "effective_dtb_shared": "1",
        "effective_dtb_rdinit": "1",
        "effective_dtb_initrd": "1",
        "linux_syscon_poweroff_driver": "0",
        "linux_guest_dtb_syscon": "1",
        "opensbi_platform_dtb_syscon": "1",
        "opensbi_fw_jump_fdt_addr": "0x82300000",
        "linux_load_addr": "0x80400000",
        "linux_guest_dtb_addr": "0x82300000",
        "initramfs_addr": "0x84000000",
        "OOO_ASSERT": "1",
        "OOO_CSR_QUEUE_HEAD": "1",
        "OOO_TERMINAL_HOLDER_ASSERT": "1",
        "linux_version": "6.6.0",
        "ubuntu2204_full_simulation": "not_launched",
        "max_cycles": "1000000",
        "uart_rx_cycle_gap": "20000",
        "l3_case": case_name,
    }
    return "\n".join(f"{key}={value}" for key, value in values.items()) + "\n"


def console_text(case_name: str = "all") -> str:
    lines = ["OpenSBI v1.8", "SBI SRST extension detected", "printk: debug:"]
    lines.extend(
        (
            "[    0.123456] reboot: Power down",
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
    phase_markers = TOOL.phase_markers_for_case(case_name)
    stream = (
        "boot\n"
        + "\n".join(phase_markers)
        + "\n[    0.123456] reboot: Power down\n"
    ).encode("ascii")

    def marker_observation(marker: str) -> tuple[int, int]:
        end = stream.index(marker.encode("ascii")) + len(marker) - 1
        return (end + 1) * 1000, (end + 1) * 100

    def midpoint(left: tuple[int, int], right: tuple[int, int]) -> tuple[int, int]:
        return (left[0] + right[0]) // 2, (left[1] + right[1]) // 2

    lines = [
        "[dpi.c:156 uart-rx] loaded bytes=1 "
        "wait='__RV64_L3_CASE_SELECT__'",
        "[dpi.c:402 uart-rx] waiting for guest output "
        "pattern='__RV64_L3_CASE_SELECT__'",
        *[f"[guest] {marker}" for marker in phase_markers],
    ]
    for index, byte in enumerate(stream, start=1):
        lines.append(
            f"[uart-trace] tx={index} cycle={index * 1000} commit={index * 100} "
            f"data=0x{byte:02x} char='.'"
        )
    selector = TOOL.CASE_SELECTORS[case_name]
    selector_time = midpoint(
        marker_observation("__RV64_L3_CASE_SELECT__"),
        marker_observation(TOOL.CASE_MARKERS[case_name]),
    )
    lines.append(
        f"[uart-rx] pop=1 cycle={selector_time[0]} commit={selector_time[1]} "
        f"data=0x{selector:02x} char='.'"
    )
    if case_name in ("interrupt", "all"):
        first_rx = midpoint(
            marker_observation("__RV64_L3_UART_ARM_1__"),
            marker_observation("__RV64_L3_UART_RX_1=0x41__"),
        )
        second_rx = midpoint(
            marker_observation("__RV64_L3_UART_ARM_2__"),
            marker_observation("__RV64_L3_UART_RX_2=0x42__"),
        )
        first_irq = midpoint(
            first_rx, marker_observation("__RV64_L3_UART_RX_1=0x41__")
        )
        second_irq = midpoint(
            second_rx, marker_observation("__RV64_L3_UART_RX_2=0x42__")
        )
        lines.extend(
            (
                f"[uart-rx] pop=2 cycle={first_rx[0]} commit={first_rx[1]} "
                "data=0x41 char='A'",
                f"[irq-trace] event=1 cycle={first_irq[0]} commit={first_irq[1]} "
                "uart_irq=1 plic_irq=1",
                f"[uart-rx] pop=3 cycle={second_rx[0]} commit={second_rx[1]} "
                "data=0x42 char='B'",
                f"[irq-trace] event=2 cycle={second_irq[0]} commit={second_irq[1]} "
                "uart_irq=1 plic_irq=1",
            )
        )
    lines.extend(
        (
            "[guest] [    0.123456] reboot: Power down",
            "npc: HIT GOOD TRAP at pc = 0x80000100",
        )
    )
    return "\n".join(lines) + "\n"


class LightweightLinuxRunTests(unittest.TestCase):
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

    def test_positive_accepts_printk_debug_and_exact_transaction(self) -> None:
        result = self.run_candidate()
        self.assertEqual(result["status"], "PASS")
        self.assertEqual(result["commits"], 300000)
        self.assertEqual(
            [item["data"] for item in result["uart_rx"]], [0x78, 0x41, 0x42]
        )
        self.assertEqual(result["signoff_scope"], "full-l3")

    def test_each_directed_case_has_exact_reduced_scope(self) -> None:
        for case_name in TOOL.CASE_SELECTORS:
            with self.subTest(case_name=case_name):
                result = self.run_candidate(case_name=case_name)
                expected = "full-l3" if case_name == "all" else "directed-case"
                self.assertEqual(result["signoff_scope"], expected)

    def test_real_bug_marker_is_rejected(self) -> None:
        with self.assertRaises(TOOL.LightweightLinuxError):
            self.run_candidate(console=console_text() + "kernel BUG: real failure\n")

    def test_duplicate_pass_is_rejected(self) -> None:
        with self.assertRaises(TOOL.LightweightLinuxError):
            self.run_candidate(npc=npc_text() + "[guest] __RV64_L3_LIGHTWEIGHT_PASS__\n")

    def test_duplicate_terminal_is_rejected(self) -> None:
        with self.assertRaises(TOOL.LightweightLinuxError):
            self.run_candidate(console=console_text() + "HIT GOOD TRAP\n")

    def test_missing_guest_kernel_power_down_is_rejected(self) -> None:
        with self.assertRaises(TOOL.LightweightLinuxError):
            self.run_candidate(
                npc=npc_text().replace("reboot: Power down", "reboot: halted")
            )

    def test_wrong_second_uart_payload_is_rejected(self) -> None:
        with self.assertRaises(TOOL.LightweightLinuxError):
            self.run_candidate(npc=npc_text().replace("data=0x42", "data=0x43"))

    def test_uart_rx_before_arm_is_rejected(self) -> None:
        damaged = re.sub(
            r"\[uart-rx\] pop=2 cycle=\d+ commit=\d+",
            "[uart-rx] pop=2 cycle=1 commit=1",
            npc_text(),
            count=1,
        )
        with self.assertRaises(TOOL.LightweightLinuxError):
            self.run_candidate(npc=damaged)

    def test_missing_uart_to_plic_assertion_is_rejected(self) -> None:
        with self.assertRaises(TOOL.LightweightLinuxError):
            self.run_candidate(npc=npc_text().replace("plic_irq=1", "plic_irq=0"))

    def test_missing_linux_version_binding_is_rejected(self) -> None:
        damaged = binding_text().replace("linux_version=6.6.0\n", "")
        with self.assertRaises(TOOL.LightweightLinuxError):
            self.run_candidate(binding=damaged)

    def test_ubuntu_launch_binding_drift_is_rejected(self) -> None:
        damaged = binding_text().replace(
            "ubuntu2204_full_simulation=not_launched",
            "ubuntu2204_full_simulation=launched",
        )
        with self.assertRaises(TOOL.LightweightLinuxError):
            self.run_candidate(binding=damaged)

    def test_syscon_without_cycle_commit_is_rejected(self) -> None:
        damaged = console_text().replace(" cycle=850000 commit=290000", "")
        with self.assertRaises(TOOL.LightweightLinuxError):
            self.run_candidate(console=damaged)

    def test_missing_tx_phase_is_rejected(self) -> None:
        phase_markers = TOOL.phase_markers_for_case("all")
        marker = phase_markers[5].encode("ascii")
        stream = ("boot\n" + "\n".join(phase_markers) + "\n").encode("ascii")
        damaged = stream.replace(marker, b"_" * len(marker))
        original = npc_text()
        trace_lines = [
            line for line in original.splitlines() if "[uart-trace]" not in line
        ]
        trace_lines.extend(
            f"[uart-trace] tx={index} cycle={index * 1000} commit={index * 100} "
            f"data=0x{byte:02x} char='.'"
            for index, byte in enumerate(damaged, start=1)
        )
        with self.assertRaises(TOOL.LightweightLinuxError):
            self.run_candidate(npc="\n".join(trace_lines) + "\n")

    def test_unselected_phase_is_rejected(self) -> None:
        with self.assertRaises(TOOL.LightweightLinuxError):
            self.run_candidate(
                case_name="boot",
                npc=npc_text("boot") + "[guest] __RV64_L3_ATOMIC_PASS__\n",
            )

    def test_split_effective_dtb_is_rejected(self) -> None:
        damaged = binding_text().replace(
            "opensbi_platform_dtb_sha256=" + "a" * 64,
            "opensbi_platform_dtb_sha256=" + "c" * 64,
        )
        with self.assertRaises(TOOL.LightweightLinuxError):
            self.run_candidate(binding=damaged)


if __name__ == "__main__":
    unittest.main()
