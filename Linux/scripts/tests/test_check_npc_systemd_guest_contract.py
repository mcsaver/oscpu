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

CONSOLE_TERMINAL_MARKERS = (
    "__NPC_SYSTEMD_STRICT_DONE__ rc=0",
    "__NPC_SYSTEMD_POWEROFF_BEGIN__",
    "reboot: Power down",
    "syscon-reset: poweroff requested value=0x00005555",
    "HIT GOOD TRAP",
    "exit via system-reset, code=0",
    "total guest instructions =",
    "total guest cycles =",
)

NPC_TERMINAL_MARKERS = {
    "poweroff-begin": "__NPC_SYSTEMD_POWEROFF_BEGIN__",
    "kernel-power-down": "reboot: Power down",
    "good-trap": "HIT GOOD TRAP",
    "system-reset": "exit via system-reset, code=0",
    "stats-instructions": "total guest instructions =",
    "stats-cycles": "total guest cycles =",
}

RTL_ASSERTION_MARKERS = (
    "[V9Q-BRIDGE-HOLDER-DISJOINT]",
    "[V9R-SQ-RETRY-C0-HANDOFF]",
    "[V9R-MEM-SQ-RETRY-C0-HANDOFF]",
    "[S2-G1-TCOLL-INGRESS-DUP]",
    "[V10D-CONTRACT-FAIL]",
    "%Error: RV64 assertion fixture",
    "Assertion failed: RV64 fixture",
    "RTL assertion: RV64 fixture",
    "[RV64_ASSERT_CONTRACT_FAIL]",
)


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
        "[   49.615057] reboot: Power down",
        "syscon-reset: poweroff requested value=0x00005555 pc=0x00000000800237ae",
        "[cpu-exec.cpp:2834 cpu_exec] npc: HIT GOOD TRAP at pc = 0x00000000800237ae",
        "[cpu-exec.cpp:2851 report_run_result] exit via system-reset, code=0, cycles=5071521696, commits=1223536213",
        "[cpu-exec.cpp:2470 statistic] total guest instructions = 1223536213",
        "[cpu-exec.cpp:2473 statistic] total guest cycles = 5071521696",
    ]


def init_line(npc_log: Path) -> str:
    return f"[log.c:145 npc_init_log] Log is written to {npc_log.resolve()}"


def npc_mirror(console_lines: list[str], npc_log: Path) -> list[str]:
    mirrored = [init_line(npc_log)]
    for line in console_lines:
        if line == "__NPC_SYSTEMD_POWEROFF_BEGIN__" or line == "[   49.615057] reboot: Power down":
            mirrored.append(f"[guest] {line}")
        elif (
            "HIT GOOD TRAP" in line
            or "exit via system-reset" in line
            or "total guest instructions" in line
            or "total guest cycles" in line
        ):
            mirrored.append(line)
    return mirrored


class GuestNaturalTerminalContractTest(unittest.TestCase):
    def run_checker(
        self,
        lines: list[str],
        *,
        simulator_rc: int = 0,
        simulator_delay: float = 0.0,
        host_timeout: str = "5",
        max_cycles: int = 6_000_000_000,
        npc_log_kind: str = "file",
        assertion_query_error: bool = False,
        npc_variant: str = "valid",
        parser_variant: str = "canonical",
        evidence_path_variant: str = "distinct",
    ) -> subprocess.CompletedProcess[str]:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            log_dir = root / "logs"
            npc_log_path = log_dir / "npc.log"
            console_log_path = log_dir / "console.log"
            evidence_path = log_dir / "systemd-transaction-evidence.json"
            fake_sim = root / "fake-npc-sim.py"
            fake_sim.write_text(
                "#!/usr/bin/env python3\n"
                "import os\n"
                "import time\n"
                "from pathlib import Path\n"
                "npc_log = Path(os.environ['NPC_TEST_NPC_LOG'])\n"
                "if os.environ.get('NPC_TEST_NPC_LOG_KIND') == 'directory':\n"
                "    npc_log.mkdir(parents=True, exist_ok=True)\n"
                "else:\n"
                "    npc_log.parent.mkdir(parents=True, exist_ok=True)\n"
                "    npc_log.write_text(os.environ['NPC_TEST_NPC_TEXT'], encoding='utf-8')\n"
                "print('[fake-sim] launch', flush=True)\n"
                "print(os.environ['NPC_TEST_CONSOLE'], flush=True)\n"
                "time.sleep(float(os.environ.get('NPC_TEST_SIM_DELAY', '0')))\n"
                "raise SystemExit(int(os.environ.get('NPC_TEST_SIM_RC', '0')))\n",
                encoding="utf-8",
            )
            fake_sim.chmod(0o755)
            selected_parser = TRANSACTION_PARSER
            if parser_variant == "fake-pass":
                selected_parser = root / "fake-transaction-collector.py"
                selected_parser.write_text(
                    "#!/usr/bin/env python3\n"
                    "import sys\n"
                    "from pathlib import Path\n"
                    "out = Path(sys.argv[sys.argv.index('--json-out') + 1])\n"
                    "out.parent.mkdir(parents=True, exist_ok=True)\n"
                    "out.write_text('{\\\"status\\\":\\\"PASS\\\"}\\n', encoding='utf-8')\n",
                    encoding="utf-8",
                )
                selected_parser.chmod(0o755)
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
            console_lines = [init_line(npc_log_path), *lines]
            npc_lines = npc_mirror(lines, npc_log_path)
            if npc_variant == "wrong-good-prefix":
                index = next(
                    index for index, line in enumerate(npc_lines) if "HIT GOOD TRAP" in line
                )
                npc_lines[index] = f"[guest] {npc_lines[index]}"
            elif npc_variant == "missing-init":
                npc_lines.pop(0)
            elif npc_variant == "syscon-present":
                npc_lines.insert(
                    1,
                    "syscon-reset: poweroff requested value=0x00005555 "
                    "pc=0x00000000800237ae",
                )
            elif npc_variant.startswith("duplicate-"):
                name = npc_variant.removeprefix("duplicate-")
                marker = NPC_TERMINAL_MARKERS[name]
                index = next(
                    index for index, line in enumerate(npc_lines) if marker in line
                )
                npc_lines.insert(index + 1, npc_lines[index])
            elif npc_variant.startswith("swap-"):
                pair = npc_variant.removeprefix("swap-")
                left_name, right_name = pair.split("+", maxsplit=1)
                left_marker = NPC_TERMINAL_MARKERS[left_name]
                right_marker = NPC_TERMINAL_MARKERS[right_name]
                left_index = next(
                    index for index, line in enumerate(npc_lines) if left_marker in line
                )
                right_index = next(
                    index for index, line in enumerate(npc_lines) if right_marker in line
                )
                npc_lines[left_index], npc_lines[right_index] = (
                    npc_lines[right_index],
                    npc_lines[left_index],
                )
            elif npc_variant == "wrong-good-pc":
                index = next(
                    index for index, line in enumerate(npc_lines) if "HIT GOOD TRAP" in line
                )
                npc_lines[index] = npc_lines[index].replace("800237ae", "800237af")
            elif npc_variant == "wrong-reset-cycles":
                index = next(
                    index
                    for index, line in enumerate(npc_lines)
                    if "exit via system-reset" in line
                )
                npc_lines[index] = npc_lines[index].replace("5071521696", "5071521697")
            elif npc_variant == "wrong-reset-commits":
                index = next(
                    index
                    for index, line in enumerate(npc_lines)
                    if "exit via system-reset" in line
                )
                npc_lines[index] = npc_lines[index].replace("1223536213", "1223536214")
            elif npc_variant == "wrong-init-path":
                npc_lines[0] = npc_lines[0].replace(
                    str(npc_log_path.resolve()),
                    str((log_dir / "other-npc.log").resolve()),
                )
            elif npc_variant != "valid":
                raise AssertionError(f"unsupported NPC fixture variant: {npc_variant}")
            if evidence_path_variant == "console":
                evidence_path = console_log_path
            elif evidence_path_variant == "simulator":
                evidence_path = fake_sim
            elif evidence_path_variant == "selected-parser":
                if selected_parser == TRANSACTION_PARSER:
                    raise AssertionError(
                        "selected-parser collision fixture requires parser_variant=fake-pass"
                    )
                evidence_path = selected_parser
            elif evidence_path_variant == "run-fw":
                evidence_path = artifacts["fw_jump.bin"]
            elif evidence_path_variant == "run-fw-hardlink":
                evidence_path = root / "evidence-hardlink.json"
                os.link(artifacts["fw_jump.bin"], evidence_path)
            elif evidence_path_variant != "distinct":
                raise AssertionError(
                    f"unsupported evidence path variant: {evidence_path_variant}"
                )

            env.update(
                {
                    "NPC_TEST_CONSOLE": "\n".join(console_lines),
                    "NPC_TEST_NPC_TEXT": "\n".join(npc_lines) + "\n",
                    "NPC_TEST_SIM_RC": str(simulator_rc),
                    "NPC_TEST_SIM_DELAY": str(simulator_delay),
                    "NPC_TEST_NPC_LOG": str(npc_log_path),
                    "NPC_TEST_NPC_LOG_KIND": npc_log_kind,
                    "NPC_SYSTEMD_GUEST_COMMAND_MODE": "systemd-strict",
                    "NPC_SYSTEMD_STRICT_CHECK": "1",
                    "NPC_SYSTEMD_GUEST_POWEROFF": "1",
                    "NPC_SYSTEMD_REQUIRE_PROMPT": "0",
                    "NPC_SYSTEMD_HOST_TIMEOUT": host_timeout,
                    "NPC_SYSTEMD_CHECK_MAX_CYCLES": str(max_cycles),
                    "NPC_SYSTEMD_TRANSACTION_PARSER": str(selected_parser),
                    "NPC_SYSTEMD_TRANSACTION_EVIDENCE": str(evidence_path),
                    "LOG_DIR": str(log_dir),
                    "CONSOLE_LOG": str(console_log_path),
                    "NPC_LOG": str(npc_log_path),
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
        self.assertEqual(result.stdout.count("[fake-sim] launch"), 1, result.stdout)

    def test_systemd_power_off_text_cannot_replace_kernel_terminal(self) -> None:
        lines = [
            "System Power Off" if "reboot: Power down" in line else line
            for line in complete_console()
        ]
        result = self.run_checker(lines)
        self.assertEqual(result.returncode, 1, result.stdout)
        self.assertIn(
            "console: kernel_power_down observed 0 times",
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
            "console: syscon_poweroff observed 0 times",
            result.stdout,
        )

    def test_each_raw_terminal_event_duplicate_fails(self) -> None:
        for marker in CONSOLE_TERMINAL_MARKERS:
            with self.subTest(marker=marker):
                lines = complete_console()
                duplicate = next(line for line in lines if marker in line)
                lines.insert(lines.index(duplicate) + 1, duplicate)
                result = self.run_checker(lines)
                self.assertEqual(result.returncode, 1, result.stdout)
                self.assertIn(
                    "bounded systemd transaction evidence is RED",
                    result.stdout,
                )

    def test_each_raw_terminal_event_same_line_duplicate_fails(self) -> None:
        for marker in CONSOLE_TERMINAL_MARKERS:
            with self.subTest(marker=marker):
                lines = complete_console()
                index = next(
                    index for index, line in enumerate(lines) if marker in line
                )
                lines[index] = f"{lines[index]} {lines[index]}"
                result = self.run_checker(lines)
                self.assertEqual(result.returncode, 1, result.stdout)
                self.assertIn(
                    "bounded systemd transaction evidence is RED",
                    result.stdout,
                )

    def test_each_adjacent_terminal_order_swap_fails(self) -> None:
        for left, right in zip(
            CONSOLE_TERMINAL_MARKERS, CONSOLE_TERMINAL_MARKERS[1:]
        ):
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
                if left == "__NPC_SYSTEMD_STRICT_DONE__ rc=0":
                    self.assertIn("strict done is not before poweroff begin", result.stdout)
                else:
                    self.assertIn("terminal events are not ordered", result.stdout)

    def test_npc_mirror_variants_fail_closed(self) -> None:
        for variant, expected in (
            ("wrong-good-prefix", "npc: good_trap observed 0 times"),
            ("missing-init", "npc: NPC log init line observed 0 times"),
            ("syscon-present", "npc: syscon poweroff marker observed 1 times"),
        ):
            with self.subTest(variant=variant):
                result = self.run_checker(complete_console(), npc_variant=variant)
                self.assertEqual(result.returncode, 1, result.stdout)
                self.assertIn(expected, result.stdout)

    def test_each_npc_terminal_event_duplicate_fails(self) -> None:
        for name in NPC_TERMINAL_MARKERS:
            with self.subTest(name=name):
                result = self.run_checker(
                    complete_console(),
                    npc_variant=f"duplicate-{name}",
                )
                self.assertEqual(result.returncode, 1, result.stdout)
                self.assertIn(
                    "bounded systemd transaction evidence is RED",
                    result.stdout,
                )

    def test_each_adjacent_npc_terminal_order_swap_fails(self) -> None:
        names = tuple(NPC_TERMINAL_MARKERS)
        for left, right in zip(names, names[1:]):
            with self.subTest(left=left, right=right):
                result = self.run_checker(
                    complete_console(),
                    npc_variant=f"swap-{left}+{right}",
                )
                self.assertEqual(result.returncode, 1, result.stdout)
                self.assertIn(
                    "bounded systemd transaction evidence is RED",
                    result.stdout,
                )

    def test_npc_path_pc_cycle_and_commit_mismatches_fail(self) -> None:
        for variant in (
            "wrong-init-path",
            "wrong-good-pc",
            "wrong-reset-cycles",
            "wrong-reset-commits",
        ):
            with self.subTest(variant=variant):
                result = self.run_checker(
                    complete_console(),
                    npc_variant=variant,
                )
                self.assertEqual(result.returncode, 1, result.stdout)
                self.assertIn(
                    "bounded systemd transaction evidence is RED",
                    result.stdout,
                )

    def test_canonical_verifier_cannot_be_overridden_by_fake_collector(self) -> None:
        result = self.run_checker(
            complete_console(),
            parser_variant="fake-pass",
        )
        self.assertEqual(result.returncode, 1, result.stdout)
        self.assertIn("canonical systemd transaction verification is RED", result.stdout)

    def test_output_paths_must_be_distinct_before_simulator_launch(self) -> None:
        result = self.run_checker(
            complete_console(),
            evidence_path_variant="console",
        )
        self.assertEqual(result.returncode, 1, result.stdout)
        self.assertIn(
            "console, NPC and transaction evidence outputs must use distinct paths",
            result.stdout,
        )
        self.assertNotIn("[fake-sim] launch", result.stdout)

    def test_managed_output_cannot_alias_hardware_inputs_before_preclear(self) -> None:
        cases = (
            ("simulator", "NPC_SIM_BIN input"),
            ("run-fw", "RUN_FW_FILE input"),
            ("run-fw-hardlink", "RUN_FW_FILE input"),
            ("selected-parser", "transaction parser"),
        )
        for evidence_variant, expected_input in cases:
            with self.subTest(evidence_variant=evidence_variant):
                parser_variant = (
                    "fake-pass"
                    if evidence_variant == "selected-parser"
                    else "canonical"
                )
                result = self.run_checker(
                    complete_console(),
                    evidence_path_variant=evidence_variant,
                    parser_variant=parser_variant,
                )
                self.assertEqual(result.returncode, 1, result.stdout)
                self.assertIn("transaction evidence output path aliases", result.stdout)
                self.assertIn(expected_input, result.stdout)
                self.assertNotIn("[fake-sim] launch", result.stdout)

    def test_simulator_exit_124_is_not_mislabeled_as_wall_clock_timeout(self) -> None:
        result = self.run_checker(complete_console(), simulator_rc=124)
        self.assertEqual(result.returncode, 1, result.stdout)
        self.assertIn("NPC did not exit cleanly through reset-syscon (rc=124)", result.stdout)
        self.assertNotIn("RV64 host wall-clock budget expired", result.stdout)

    def test_real_host_timeout_is_preserved_as_hardware_gap(self) -> None:
        result = self.run_checker(
            complete_console(),
            simulator_delay=1.0,
            host_timeout="0.1",
        )
        self.assertEqual(result.returncode, 124, result.stdout)
        self.assertIn("RV64 host wall-clock budget expired", result.stdout)
        self.assertEqual(result.stdout.count("[fake-sim] launch"), 1, result.stdout)

    def test_each_rtl_assertion_precedes_host_timeout_classification(self) -> None:
        for marker in RTL_ASSERTION_MARKERS:
            with self.subTest(marker=marker):
                result = self.run_checker(
                    [*complete_console(), marker],
                    simulator_delay=1.0,
                    host_timeout="0.1",
                )
                self.assertEqual(result.returncode, 1, result.stdout)
                self.assertNotIn("host wall-clock budget expired", result.stdout)

    def test_each_rtl_assertion_fails_even_after_clean_simulator_exit(self) -> None:
        for marker in RTL_ASSERTION_MARKERS:
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
        for marker in RTL_ASSERTION_MARKERS:
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
