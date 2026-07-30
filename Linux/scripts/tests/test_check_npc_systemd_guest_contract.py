#!/usr/bin/env python3

from __future__ import annotations

import importlib.util
import os
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path
from types import ModuleType


SCRIPT_DIR = Path(__file__).resolve().parent
GUEST_CHECKER = SCRIPT_DIR.parent / "check-npc-systemd-guest.sh"
TRANSACTION_PARSER = SCRIPT_DIR.parent / "npc_systemd_transaction_evidence.py"


def load_transaction_parser() -> ModuleType:
    spec = importlib.util.spec_from_file_location(
        "npc_systemd_transaction_evidence_contract",
        TRANSACTION_PARSER,
    )
    if spec is None or spec.loader is None:
        raise AssertionError("cannot load transaction parser")
    module = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    return module


TRANSACTION = load_transaction_parser()


def transaction_lines() -> list[str]:
    lines: list[str] = []
    for stage in TRANSACTION.V2_SPECS:
        lines.append(stage.begin)
        lines.extend(f"{prefix}fixture" for prefix in stage.ancillary_prefixes)
        lines.extend(
            f"{stage.pass_prefix}{label}" for label in stage.expected_labels
        )
        lines.append(f"{stage.done_stem} rc=0")
    return lines


def complete_console() -> list[str]:
    return [
        "OpenSBI v1.3",
        "Platform Reboot Device     : syscon-reboot",
        "Platform Shutdown Device   : syscon-poweroff",
        "SBI SRST extension detected",
        "[uart-rx] loaded bytes=0 file_bytes=0 text_bytes=0",
        *transaction_lines(),
        "__NPC_SYSTEMD_POWEROFF_BEGIN__",
        "reboot: Power down",
        "syscon-reset: poweroff requested value=0x00005555 pc=0x00000000800237ae",
        "HIT GOOD TRAP",
        "exit via system-reset, code=0, cycles=5071521696, commits=1223536213",
    ]


class GuestNaturalTerminalContractTest(unittest.TestCase):
    def run_checker(
        self,
        lines: list[str],
        *,
        simulator_rc: int = 0,
        max_cycles: int = 6_000_000_000,
        npc_log_kind: str = "file",
        assertion_query_error: bool = False,
    ) -> subprocess.CompletedProcess[str]:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            log_dir = root / "logs"
            fake_sim = root / "fake-npc-sim.py"
            fake_sim.write_text(
                "#!/usr/bin/env python3\n"
                "import os\n"
                "from pathlib import Path\n"
                "npc_log = Path(os.environ['NPC_TEST_NPC_LOG'])\n"
                "if os.environ.get('NPC_TEST_NPC_LOG_KIND') == 'directory':\n"
                "    npc_log.mkdir(parents=True, exist_ok=True)\n"
                "else:\n"
                "    npc_log.parent.mkdir(parents=True, exist_ok=True)\n"
                "    npc_log.write_text('rv64 npc log fixture\\n', encoding='utf-8')\n"
                "print(os.environ['NPC_TEST_CONSOLE'])\n"
                "raise SystemExit(int(os.environ.get('NPC_TEST_SIM_RC', '0')))\n",
                encoding="utf-8",
            )
            fake_sim.chmod(0o755)
            artifacts = {}
            for name in ("Image", "fw_jump.bin", "run.dtb", "rootfs.ext4"):
                path = root / name
                path.write_bytes(b"rv64-contract-fixture\n")
                artifacts[name] = path
            env = os.environ.copy()
            if assertion_query_error:
                fake_bin = root / "fake-bin"
                fake_bin.mkdir()
                fake_grep = fake_bin / "grep"
                fake_grep.write_text(
                    "#!/usr/bin/env bash\n"
                    "for arg in \"$@\"; do\n"
                    "  case \"$arg\" in\n"
                    "    *S2-G1-TCOLL-INGRESS-DUP*) exit 2 ;;\n"
                    "  esac\n"
                    "done\n"
                    "exec /usr/bin/grep \"$@\"\n",
                    encoding="utf-8",
                )
                fake_grep.chmod(0o755)
                env["PATH"] = f"{fake_bin}:{env['PATH']}"
            env.update(
                {
                    "NPC_TEST_CONSOLE": "\n".join(lines),
                    "NPC_TEST_SIM_RC": str(simulator_rc),
                    "NPC_TEST_NPC_LOG": str(log_dir / "npc.log"),
                    "NPC_TEST_NPC_LOG_KIND": npc_log_kind,
                    "NPC_SYSTEMD_GUEST_COMMAND_MODE": "systemd-strict",
                    "NPC_SYSTEMD_STRICT_CHECK": "1",
                    "NPC_SYSTEMD_GUEST_POWEROFF": "1",
                    "NPC_SYSTEMD_REQUIRE_PROMPT": "0",
                    "NPC_SYSTEMD_HOST_TIMEOUT": "5",
                    "NPC_SYSTEMD_CHECK_MAX_CYCLES": str(max_cycles),
                    "NPC_SYSTEMD_TRANSACTION_PARSER": str(TRANSACTION_PARSER),
                    "LOG_DIR": str(log_dir),
                    "CONSOLE_LOG": str(log_dir / "console.log"),
                    "NPC_LOG": str(log_dir / "npc.log"),
                    "NPC_SIM": str(fake_sim),
                    "LINUX_IMAGE": str(artifacts["Image"]),
                    "RUN_FW": str(artifacts["fw_jump.bin"]),
                    "RUN_DTB": str(artifacts["run.dtb"]),
                    "RUN_ROOTFS": str(artifacts["rootfs.ext4"]),
                    "NEXT_ADDR": "0x80200000",
                    "DTB_ADDR": "0x82200000",
                }
            )
            return subprocess.run(
                ["bash", str(GUEST_CHECKER)],
                text=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                env=env,
                check=False,
            )

    def test_actual_terminal_chain_passes_without_system_power_off_text(self) -> None:
        result = self.run_checker(complete_console())
        self.assertEqual(result.returncode, 0, result.stdout)
        self.assertNotIn("System Power Off", "\n".join(complete_console()))
        self.assertIn("PASS strict guest + natural poweroff", result.stdout)

    def test_systemd_power_off_text_cannot_replace_kernel_terminal(self) -> None:
        lines = [
            "System Power Off" if line == "reboot: Power down" else line
            for line in complete_console()
        ]
        result = self.run_checker(lines)
        self.assertEqual(result.returncode, 1, result.stdout)
        self.assertIn(
            "missing natural-poweroff evidence: kernel power down",
            result.stdout,
        )

    def test_missing_raw_syscon_terminal_fails(self) -> None:
        lines = [
            line
            for line in complete_console()
            if not line.startswith("syscon-reset: poweroff requested")
        ]
        result = self.run_checker(lines)
        self.assertEqual(result.returncode, 1, result.stdout)
        self.assertIn(
            "missing natural-poweroff evidence: RTL syscon terminal",
            result.stdout,
        )

    def test_each_raw_terminal_event_duplicate_fails(self) -> None:
        markers = (
            "__NPC_SYSTEMD_STRICT_DONE__ rc=0",
            "__NPC_SYSTEMD_POWEROFF_BEGIN__",
            "reboot: Power down",
            "syscon-reset: poweroff requested value=0x00005555",
            "HIT GOOD TRAP",
            "exit via system-reset, code=0",
        )
        for marker in markers:
            with self.subTest(marker=marker):
                lines = complete_console()
                duplicate = next(line for line in lines if marker in line)
                lines.insert(lines.index(duplicate) + 1, duplicate)
                result = self.run_checker(lines)
                self.assertEqual(result.returncode, 1, result.stdout)
                if marker == "__NPC_SYSTEMD_STRICT_DONE__ rc=0":
                    self.assertIn(
                        "bounded systemd transaction evidence is RED",
                        result.stdout,
                    )
                else:
                    self.assertIn(
                        "natural-poweroff event count mismatch",
                        result.stdout,
                    )

    def test_each_raw_terminal_event_same_line_duplicate_fails(self) -> None:
        markers = (
            "__NPC_SYSTEMD_STRICT_DONE__ rc=0",
            "__NPC_SYSTEMD_POWEROFF_BEGIN__",
            "reboot: Power down",
            "syscon-reset: poweroff requested value=0x00005555",
            "HIT GOOD TRAP",
            "exit via system-reset, code=0",
        )
        for marker in markers:
            with self.subTest(marker=marker):
                lines = complete_console()
                index = next(
                    index for index, line in enumerate(lines) if marker in line
                )
                lines[index] = f"{lines[index]} {lines[index]}"
                result = self.run_checker(lines)
                self.assertEqual(result.returncode, 1, result.stdout)
                if marker == "__NPC_SYSTEMD_STRICT_DONE__ rc=0":
                    self.assertTrue(
                        "bounded systemd transaction evidence is RED"
                        in result.stdout
                        or "natural-poweroff event count mismatch"
                        in result.stdout,
                        result.stdout,
                    )
                else:
                    self.assertIn(
                        "natural-poweroff event count mismatch",
                        result.stdout,
                    )

    def test_each_adjacent_terminal_order_swap_fails(self) -> None:
        ordered_markers = (
            "__NPC_SYSTEMD_STRICT_DONE__ rc=0",
            "__NPC_SYSTEMD_POWEROFF_BEGIN__",
            "reboot: Power down",
            "syscon-reset: poweroff requested value=0x00005555",
            "HIT GOOD TRAP",
            "exit via system-reset, code=0",
        )
        for left, right in zip(ordered_markers, ordered_markers[1:]):
            with self.subTest(left=left, right=right):
                lines = complete_console()
                left_index = next(
                    index for index, line in enumerate(lines) if left in line
                )
                right_index = next(
                    index for index, line in enumerate(lines) if right in line
                )
                lines[left_index], lines[right_index] = (
                    lines[right_index],
                    lines[left_index],
                )
                result = self.run_checker(lines)
                self.assertEqual(result.returncode, 1, result.stdout)
                self.assertIn(
                    "natural-poweroff event order mismatch",
                    result.stdout,
                )

    def test_host_timeout_return_code_is_preserved_as_hardware_gap(self) -> None:
        result = self.run_checker(complete_console(), simulator_rc=124)
        self.assertEqual(result.returncode, 124, result.stdout)
        self.assertIn("RV64 host wall-clock budget expired", result.stdout)

    def test_each_rtl_assertion_precedes_host_timeout_classification(self) -> None:
        for marker in (
            "[V9R-SQ-RETRY-C0-HANDOFF]",
            "[V9R-MEM-SQ-RETRY-C0-HANDOFF]",
        ):
            with self.subTest(marker=marker):
                result = self.run_checker(
                    [*complete_console(), marker],
                    simulator_rc=124,
                )
                self.assertEqual(result.returncode, 1, result.stdout)
                self.assertNotIn("host wall-clock budget expired", result.stdout)

    def test_each_rtl_assertion_fails_even_after_clean_simulator_exit(self) -> None:
        for marker in (
            "[V9R-SQ-RETRY-C0-HANDOFF]",
            "[V9R-MEM-SQ-RETRY-C0-HANDOFF]",
        ):
            with self.subTest(marker=marker):
                result = self.run_checker([*complete_console(), marker])
                self.assertEqual(result.returncode, 1, result.stdout)
                self.assertIn(
                    "RTL assertion marker was observed",
                    result.stdout,
                )
                self.assertNotIn(
                    "PASS strict guest + natural poweroff",
                    result.stdout,
                )

    def test_exact_cycle_budget_abort_is_hardware_gap(self) -> None:
        max_cycles = 6_000_000_000
        lines = [
            *transaction_lines(),
            "npc: ABORT at pc = 0x0000000080001234",
            f"cycles={max_cycles}, commits=123456, core-state=0x00000001",
        ]
        result = self.run_checker(
            lines,
            simulator_rc=1,
            max_cycles=max_cycles,
        )
        self.assertEqual(result.returncode, 124, result.stdout)
        self.assertIn("RV64 simulation cycle budget exhausted", result.stdout)

    def test_each_rtl_assertion_precedes_cycle_budget_classification(self) -> None:
        max_cycles = 6_000_000_000
        for marker in (
            "[V9R-SQ-RETRY-C0-HANDOFF]",
            "[V9R-MEM-SQ-RETRY-C0-HANDOFF]",
        ):
            with self.subTest(marker=marker):
                lines = [
                    *transaction_lines(),
                    marker,
                    "npc: ABORT at pc = 0x0000000080001234",
                    f"cycles={max_cycles}, commits=123456, core-state=0x00000001",
                ]
                result = self.run_checker(
                    lines,
                    simulator_rc=1,
                    max_cycles=max_cycles,
                )
                self.assertEqual(result.returncode, 1, result.stdout)
                self.assertNotIn(
                    "simulation cycle budget exhausted",
                    result.stdout,
                )

    def test_non_regular_npc_log_fails_closed(self) -> None:
        result = self.run_checker(
            complete_console(),
            npc_log_kind="directory",
        )
        self.assertEqual(result.returncode, 1, result.stdout)
        self.assertIn(
            "NPC log is not a readable regular file",
            result.stdout,
        )

    def test_assertion_query_io_error_fails_closed(self) -> None:
        result = self.run_checker(
            complete_console(),
            simulator_rc=124,
            assertion_query_error=True,
        )
        self.assertEqual(result.returncode, 1, result.stdout)
        self.assertIn(
            "RTL assertion evidence query failed (rc=2)",
            result.stdout,
        )
        self.assertNotIn("host wall-clock budget expired", result.stdout)


if __name__ == "__main__":
    unittest.main()
