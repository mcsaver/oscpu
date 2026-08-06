#!/usr/bin/env python3

from __future__ import annotations

import json
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path


SCRIPT_DIR = Path(__file__).resolve().parent
PARSER = SCRIPT_DIR.parent / "npc_systemd_transaction_evidence.py"
FIXTURES = SCRIPT_DIR / "fixtures"

PREFLIGHT = (
    "os-release-ubuntu-2204",
    "bin-sh",
    "bin-bash",
    "systemd-binary",
    "systemd-autocheck-script",
    "systemd-wrapper-preflight",
)
AUTOCHECK = (
    "uname-riscv64",
    "os-release-ubuntu-2204",
    "root-context",
    "bin-sh",
    "bin-bash",
    "systemd-state",
)
STRICT = (
    "uname-riscv64",
    "os-release-ubuntu-2204",
    "root-shell",
    "bin-sh",
    "bin-bash",
    "systemd-state",
    "block-vda",
    "virtio-blk-driver",
    "root-on-vda",
    "root-ext4",
    "root-rw",
    "rootfs-write-sync-readback",
    "virtio-device-name",
    "virtio-irq-before-parse",
    "virtio-blk-direct-read",
    "virtio-irq-growth",
    "dmesg-no-critical",
)


def ancillary(stage: str, legacy: bool) -> list[str]:
    if stage == "preflight":
        prefix = "__NPC_CHECK" if legacy else "__NPC_PREFLIGHT"
        return [f"{prefix}_SYSTEMD_STATE__:wrapper-pre-systemd"]
    if stage == "autocheck":
        prefix = "__NPC_CHECK" if legacy else "__NPC_AUTOCHECK"
        return [
            f"{prefix}_UNAME__:riscv64",
            f"{prefix}_SYSTEMD_STATE__:pid1-systemd",
        ]
    return [
        "__NPC_CHECK_UNAME__:riscv64",
        "__NPC_CHECK_SYSTEMD_STATE__:pid1-systemd",
        "__NPC_CHECK_VDA_DRIVER__:virtio_blk",
        "__NPC_CHECK_ROOT_SOURCE__:/dev/root:254:0:254:0",
        "__NPC_CHECK_ROOT_MOUNT__:ext4:rw,relatime",
        "__NPC_CHECK_VIRTIO_IRQ_OWNER__:virtio0",
        "__NPC_CHECK_VIRTIO_IRQ__:10->11",
    ]


def make_stage(stage: str, legacy: bool = False) -> list[str]:
    labels = {
        "preflight": PREFLIGHT,
        "autocheck": AUTOCHECK,
        "strict": STRICT,
    }[stage]
    if legacy:
        begin = "__NPC_SYSTEMD_CHECK_BEGIN__"
        pass_prefix = "__NPC_CHECK_PASS__:"
        done = {
            "preflight": "__NPC_SYSTEMD_CHECK_DONE__ rc=0",
            "autocheck": "__NPC_SYSTEMD_AUTOCHECK_DONE__ rc=0",
            "strict": "__NPC_SYSTEMD_UART_CHECK_DONE__ rc=0",
        }[stage]
    else:
        begin = f"__NPC_SYSTEMD_{stage.upper()}_BEGIN__"
        pass_prefix = (
            "__NPC_CHECK_PASS__:"
            if stage == "strict"
            else f"__NPC_{stage.upper()}_PASS__:"
        )
        done = f"__NPC_SYSTEMD_{stage.upper()}_DONE__ rc=0"
    return [
        begin,
        *ancillary(stage, legacy),
        *(f"{pass_prefix}{label}" for label in labels),
        done,
    ]


def complete_console(legacy: bool = False) -> list[str]:
    return [
        "OpenSBI v1.3",
        *make_stage("preflight", legacy),
        "__NPC_CONSOLE_SHELL_READY__",
        *make_stage("autocheck", legacy),
        *make_stage("strict", legacy),
        "__NPC_SYSTEMD_POWEROFF_BEGIN__",
    ]


KERNEL_POWER_DOWN = "[   49.615057] reboot: Power down"
SYSCON_POWEROFF = (
    "syscon-reset: poweroff requested value=0x00005555 "
    "pc=0x00000000800237ae"
)
GOOD_TRAP = (
    "[cpu-exec.cpp:2834 cpu_exec] npc: HIT GOOD TRAP "
    "at pc = 0x00000000800237ae"
)
SYSTEM_RESET = (
    "[cpu-exec.cpp:2851 report_run_result] exit via system-reset, "
    "code=0, cycles=5055252337, commits=1231323780"
)
STATS_INST = (
    "[cpu-exec.cpp:2470 statistic] total guest instructions = 1231323780"
)
STATS_CYCLES = "[cpu-exec.cpp:2473 statistic] total guest cycles = 5055252337"


def init_line(npc_log: Path) -> str:
    return f"[log.c:145 npc_init_log] Log is written to {npc_log.resolve()}"


def natural_pair(npc_log: Path) -> tuple[list[str], list[str]]:
    console = [
        init_line(npc_log),
        *complete_console(),
        "ordinary console line between terminal events",
        KERNEL_POWER_DOWN,
        SYSCON_POWEROFF,
        GOOD_TRAP,
        SYSTEM_RESET,
        STATS_INST,
        STATS_CYCLES,
        "ordinary statistic tail",
    ]
    npc = [
        init_line(npc_log),
        "ordinary npc line before terminal transaction",
        "[guest] __NPC_SYSTEMD_POWEROFF_BEGIN__",
        f"[guest] {KERNEL_POWER_DOWN}",
        GOOD_TRAP,
        SYSTEM_RESET,
        STATS_INST,
        STATS_CYCLES,
        "ordinary npc statistic tail",
    ]
    return console, npc


class TransactionEvidenceTest(unittest.TestCase):
    def run_parser(
        self,
        lines: list[str],
        *,
        protocol: str = "auto",
        crlf: bool = False,
    ) -> tuple[subprocess.CompletedProcess[str], dict[str, object]]:
        with tempfile.TemporaryDirectory() as tmp:
            tmp_path = Path(tmp)
            console = tmp_path / "console.log"
            evidence = tmp_path / "evidence.json"
            separator = "\r\n" if crlf else "\n"
            console.write_bytes((separator.join(lines) + separator).encode("utf-8"))
            proc = subprocess.run(
                [
                    sys.executable,
                    str(PARSER),
                    "--console",
                    str(console),
                    "--protocol",
                    protocol,
                    "--json-out",
                    str(evidence),
                ],
                check=False,
                text=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
            )
            return proc, json.loads(evidence.read_text(encoding="utf-8"))

    def assert_pass(self, lines: list[str], **kwargs: object) -> dict[str, object]:
        proc, payload = self.run_parser(lines, **kwargs)
        self.assertEqual(proc.returncode, 0, proc.stderr)
        self.assertEqual(payload["status"], "PASS")
        self.assertEqual(
            [stage["pass_observation_count"] for stage in payload["stages"]],
            [6, 6, 17],
        )
        return payload

    def assert_red(
        self, lines: list[str], expected_error: str, **kwargs: object
    ) -> dict[str, object]:
        proc, payload = self.run_parser(lines, **kwargs)
        self.assertNotEqual(proc.returncode, 0)
        self.assertEqual(payload["status"], "FAIL")
        self.assertIn(expected_error, "\n".join(payload["errors"]))
        return payload

    def write_natural_pair(
        self,
        tmp_path: Path,
        *,
        console_lines: list[str] | None = None,
        npc_lines: list[str] | None = None,
        console_raw: bytes | None = None,
        npc_raw: bytes | None = None,
    ) -> tuple[Path, Path, Path]:
        console = tmp_path / "console.log"
        npc_log = tmp_path / "npc.log"
        evidence = tmp_path / "evidence.json"
        default_console, default_npc = natural_pair(npc_log)
        if console_raw is None:
            selected = default_console if console_lines is None else console_lines
            console_raw = ("\n".join(selected) + "\n").encode("utf-8")
        if npc_raw is None:
            selected = default_npc if npc_lines is None else npc_lines
            npc_raw = ("\n".join(selected) + "\n").encode("utf-8")
        console.write_bytes(console_raw)
        npc_log.write_bytes(npc_raw)
        return console, npc_log, evidence

    def natural_command(
        self,
        mode: str,
        console: Path,
        npc_log: Path,
        evidence: Path,
        *,
        require_pass: bool = False,
        producer_closed: bool = False,
    ) -> list[str]:
        command = [
            sys.executable,
            str(PARSER),
            mode,
            "--console",
            str(console),
            "--npc-log",
            str(npc_log),
            "--protocol",
            "strict-v2",
            "--terminal-contract",
            "natural-poweroff",
        ]
        if producer_closed:
            command.append("--producer-closed")
        if mode == "collect":
            command.extend(("--json-out", str(evidence)))
        else:
            command.extend(("--evidence", str(evidence)))
            if require_pass:
                command.extend(("--require-status", "PASS"))
        return command

    def run_natural(
        self,
        console: Path,
        npc_log: Path,
        evidence: Path,
        *,
        mode: str = "collect",
        require_pass: bool = False,
        producer_closed: bool = False,
    ) -> subprocess.CompletedProcess[str]:
        return subprocess.run(
            self.natural_command(
                mode,
                console,
                npc_log,
                evidence,
                require_pass=require_pass,
                producer_closed=producer_closed,
            ),
            check=False,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
        )

    def test_strict_v2_pass(self) -> None:
        payload = self.assert_pass(complete_console())
        self.assertEqual(payload["protocol"], "strict-v2")

    def test_legacy_v1_pass(self) -> None:
        payload = self.assert_pass(complete_console(legacy=True))
        self.assertEqual(payload["protocol"], "legacy-v1")

    def test_ansi_and_crlf_are_normalized_before_exact_match(self) -> None:
        lines = complete_console()
        lines[1] = f"\x1b[1;34m{lines[1]}\x1b[0m"
        self.assert_pass(lines, crlf=True)

    def test_legacy_stage_cannot_borrow_earlier_pass(self) -> None:
        lines = complete_console(legacy=True)
        strict_begin = len(make_stage("preflight", True)) + len(
            make_stage("autocheck", True)
        ) + 2
        strict_bin_sh = lines.index(
            "__NPC_CHECK_PASS__:bin-sh", strict_begin
        )
        del lines[strict_bin_sh]
        self.assert_red(lines, "strict: missing PASS label bin-sh")

    def test_duplicate_strict_pass_is_not_deduplicated(self) -> None:
        lines = complete_console()
        marker = "__NPC_CHECK_PASS__:virtio-irq-growth"
        lines.insert(lines.index(marker), marker)
        payload = self.assert_red(
            lines, "strict: PASS label virtio-irq-growth observed 2 times"
        )
        strict = payload["stages"][2]
        self.assertEqual(strict["observed_pass_counts"]["virtio-irq-growth"], 2)

    def test_embedded_literal_is_not_a_marker(self) -> None:
        lines = complete_console()
        marker = "__NPC_CHECK_PASS__:dmesg-no-critical"
        lines[lines.index(marker)] = f"driver argument contains {marker}"
        self.assert_red(lines, "strict: missing PASS label dmesg-no-critical")

    def test_duplicate_begin_is_red(self) -> None:
        lines = complete_console()
        lines.insert(2, "__NPC_SYSTEMD_PREFLIGHT_BEGIN__")
        self.assert_red(lines, "preflight: begin marker observed 2 times")

    def test_duplicate_done_is_red(self) -> None:
        lines = complete_console()
        marker = "__NPC_SYSTEMD_AUTOCHECK_DONE__ rc=0"
        lines.insert(lines.index(marker), marker)
        self.assert_red(lines, "autocheck: done marker observed 2 times")

    def test_fail_marker_is_red(self) -> None:
        lines = complete_console()
        done = lines.index("__NPC_SYSTEMD_STRICT_DONE__ rc=0")
        lines.insert(done, "__NPC_CHECK_FAIL__:dmesg-no-critical")
        self.assert_red(lines, "strict: 1 FAIL marker(s)")

    def test_mixed_protocol_is_red(self) -> None:
        lines = complete_console()
        lines.insert(1, "__NPC_SYSTEMD_CHECK_BEGIN__")
        self.assert_red(lines, "strict-v2 console contains legacy-v1")

    def test_v9s_rerun4_incomplete_replay_is_16_of_17_red(self) -> None:
        fixture = (FIXTURES / "v9s-rerun4-incomplete.console").read_text(
            encoding="utf-8"
        ).splitlines()
        payload = self.assert_red(
            fixture, "strict: done marker observed 0 times"
        )
        strict = payload["stages"][2]
        self.assertEqual(strict["pass_observation_count"], 16)
        self.assertEqual(strict["observed_pass_counts"]["virtio-irq-growth"], 1)
        self.assertNotIn("dmesg-no-critical", strict["observed_pass_counts"])

    def test_natural_poweroff_collect_verify_and_require_pass(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            console, npc_log, evidence = self.write_natural_pair(Path(tmp))
            collect = self.run_natural(console, npc_log, evidence)
            self.assertEqual(collect.returncode, 0, collect.stderr)
            payload = json.loads(evidence.read_text(encoding="utf-8"))
            self.assertEqual(payload["schema"], "npc-rv64-systemd-transaction-evidence/v2")
            self.assertEqual(payload["status"], "PASS")
            self.assertEqual(payload["stage_status"], "PASS")
            self.assertEqual(payload["terminal"]["status"], "PASS")
            self.assertEqual(payload["snapshot"]["rounds"], 3)
            self.assertTrue(payload["snapshot"]["stable"])
            self.assertFalse(payload["snapshot"]["producer_closed_proof"])
            self.assertEqual(payload["terminal"]["console"]["pc"], "0x00000000800237ae")
            self.assertEqual(payload["terminal"]["console"]["cycles"], 5055252337)
            self.assertEqual(payload["terminal"]["console"]["commits"], 1231323780)

            verify = self.run_natural(
                console, npc_log, evidence, mode="verify"
            )
            self.assertEqual(verify.returncode, 0, verify.stderr)
            require = self.run_natural(
                console,
                npc_log,
                evidence,
                mode="verify",
                require_pass=True,
            )
            self.assertEqual(require.returncode, 0, require.stderr)

    def test_semantic_fail_receipt_verifies_but_require_pass_rejects(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            tmp_path = Path(tmp)
            npc_log = tmp_path / "npc.log"
            console_lines, npc_lines = natural_pair(npc_log)
            console_lines.insert(console_lines.index(GOOD_TRAP), GOOD_TRAP)
            console, npc_log, evidence = self.write_natural_pair(
                tmp_path,
                console_lines=console_lines,
                npc_lines=npc_lines,
            )
            collect = self.run_natural(console, npc_log, evidence)
            self.assertEqual(collect.returncode, 1, collect.stderr)
            payload = json.loads(evidence.read_text(encoding="utf-8"))
            self.assertEqual(payload["status"], "FAIL")
            self.assertIn(
                "console: good_trap observed 2 times",
                "\n".join(payload["errors"]),
            )
            verify = self.run_natural(console, npc_log, evidence, mode="verify")
            self.assertEqual(verify.returncode, 0, verify.stderr)
            require = self.run_natural(
                console,
                npc_log,
                evidence,
                mode="verify",
                require_pass=True,
            )
            self.assertEqual(require.returncode, 1)

    def test_invalid_console_formats_are_invalid_evidence(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            base = Path(tmp)
            probe_npc = base / "probe" / "npc.log"
            console_lines, _ = natural_pair(probe_npc)
            valid = ("\n".join(console_lines) + "\n").encode("utf-8")
            cases = {
                "invalid-utf8": valid + b"\xff\n",
                "bom": b"\xef\xbb\xbf" + valid,
                "nul": valid[:-1] + b"\x00\n",
                "tab": valid[:-1] + b"\t\n",
                "bare-cr": valid.replace(b"\n", b"\r", 1),
                "triple-cr": valid.replace(b"\n", b"\r\r\r\n", 1),
                "unsupported-escape": valid[:-1] + b"\x1b[2J\n",
                "missing-final-lf": valid[:-1],
            }
            for name, raw in cases.items():
                with self.subTest(name=name):
                    case = base / name
                    case.mkdir()
                    console, npc_log, evidence = self.write_natural_pair(case)
                    # Recreate the init line with this case's actual NPC path before
                    # injecting the format fault.
                    lines, npc_lines = natural_pair(npc_log)
                    case_valid = ("\n".join(lines) + "\n").encode("utf-8")
                    raw = raw.replace(
                        str(probe_npc.resolve()).encode("utf-8"),
                        str(npc_log.resolve()).encode("utf-8"),
                    )
                    if name == "invalid-utf8":
                        raw = case_valid + b"\xff\n"
                    console.write_bytes(raw)
                    npc_log.write_bytes(("\n".join(npc_lines) + "\n").encode("utf-8"))
                    proc = self.run_natural(console, npc_log, evidence)
                    self.assertEqual(proc.returncode, 2, proc.stderr)
                    payload = json.loads(evidence.read_text(encoding="utf-8"))
                    self.assertEqual(payload["status"], "INVALID_EVIDENCE")
                    self.assertEqual(payload["stage_status"], "NOT_EVALUATED")
                    self.assertEqual(payload["terminal"]["status"], "NOT_EVALUATED")

    def test_crcrlf_and_bounded_sgr_are_accepted(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            tmp_path = Path(tmp)
            npc_log = tmp_path / "npc.log"
            console_lines, npc_lines = natural_pair(npc_log)
            console_lines[0] = f"\x1b[1;34m{console_lines[0]}\x1b[0m"
            npc_lines[0] = f"\x1b[1;34m{npc_lines[0]}\x1b[0m"
            console_raw = ("\r\r\n".join(console_lines) + "\r\r\n").encode("utf-8")
            npc_raw = ("\r\r\n".join(npc_lines) + "\r\r\n").encode("utf-8")
            console, npc_log, evidence = self.write_natural_pair(
                tmp_path, console_raw=console_raw, npc_raw=npc_raw
            )
            proc = self.run_natural(console, npc_log, evidence)
            self.assertEqual(proc.returncode, 0, proc.stderr)
            payload = json.loads(evidence.read_text(encoding="utf-8"))
            self.assertGreater(payload["sources"]["console"]["sgr_sequences_stripped"], 0)
            self.assertGreater(payload["sources"]["console"]["newline_counts"]["CRCRLF"], 0)

    def test_terminal_negative_matrix(self) -> None:
        mutations = {
            "duplicate-begin": (
                lambda console, npc: console.insert(
                    console.index("__NPC_SYSTEMD_POWEROFF_BEGIN__"),
                    "__NPC_SYSTEMD_POWEROFF_BEGIN__",
                ),
                "console: poweroff_begin observed 2 times",
            ),
            "swapped-syscon-good": (
                lambda console, npc: console.__setitem__(
                    slice(console.index(SYSCON_POWEROFF), console.index(GOOD_TRAP) + 1),
                    [GOOD_TRAP, SYSCON_POWEROFF],
                ),
                "console: terminal events are not ordered",
            ),
            "pc-mismatch": (
                lambda console, npc: console.__setitem__(
                    console.index(GOOD_TRAP),
                    GOOD_TRAP.replace("800237ae", "800237af"),
                ),
                "syscon PC",
            ),
            "count-mismatch": (
                lambda console, npc: console.__setitem__(
                    console.index(STATS_INST),
                    STATS_INST.replace("1231323780", "1231323781"),
                ),
                "reset commits",
            ),
            "npc-wrong-prefix": (
                lambda console, npc: npc.__setitem__(
                    npc.index(GOOD_TRAP), f"[guest] {GOOD_TRAP}"
                ),
                "npc: good_trap observed 0 times",
            ),
            "npc-syscon": (
                lambda console, npc: npc.insert(npc.index(GOOD_TRAP), SYSCON_POWEROFF),
                "npc: syscon poweroff marker observed 1 times",
            ),
            "missing-init": (
                lambda console, npc: console.pop(0),
                "console: NPC log init line observed 0 times",
            ),
            "bad-trap": (
                lambda console, npc: console.append(
                    "[cpu-exec.cpp:2834 cpu_exec] npc: HIT BAD TRAP "
                    "at pc = 0x00000000800237ae"
                ),
                "malformed or reserved terminal marker",
            ),
            "zero-cycles": (
                lambda console, npc: (
                    console.__setitem__(
                        console.index(SYSTEM_RESET),
                        SYSTEM_RESET.replace("cycles=5055252337", "cycles=0"),
                    ),
                    console.__setitem__(
                        console.index(STATS_CYCLES),
                        STATS_CYCLES.replace("5055252337", "0"),
                    ),
                ),
                "outside nonzero u64 range",
            ),
        }
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            for name, (mutate, expected) in mutations.items():
                with self.subTest(name=name):
                    case = root / name
                    case.mkdir()
                    npc_log = case / "npc.log"
                    console_lines, npc_lines = natural_pair(npc_log)
                    mutate(console_lines, npc_lines)
                    console, npc_log, evidence = self.write_natural_pair(
                        case,
                        console_lines=console_lines,
                        npc_lines=npc_lines,
                    )
                    proc = self.run_natural(console, npc_log, evidence)
                    self.assertEqual(proc.returncode, 1, proc.stderr)
                    payload = json.loads(evidence.read_text(encoding="utf-8"))
                    self.assertEqual(payload["status"], "FAIL")
                    self.assertIn(expected, "\n".join(payload["errors"]))

    def test_producer_closed_proof_is_explicit_and_verifier_bound(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            console, npc_log, evidence = self.write_natural_pair(Path(tmp))
            collect = self.run_natural(
                console,
                npc_log,
                evidence,
                producer_closed=True,
            )
            self.assertEqual(collect.returncode, 0, collect.stderr)
            payload = json.loads(evidence.read_text(encoding="utf-8"))
            self.assertIs(payload["snapshot"]["producer_closed_proof"], True)

            missing_binding = self.run_natural(
                console,
                npc_log,
                evidence,
                mode="verify",
            )
            self.assertEqual(missing_binding.returncode, 3, missing_binding.stderr)

            bound = self.run_natural(
                console,
                npc_log,
                evidence,
                mode="verify",
                producer_closed=True,
            )
            self.assertEqual(bound.returncode, 0, bound.stderr)

    def test_invalid_npc_preserves_stage_and_skips_terminal(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            tmp_path = Path(tmp)
            console, npc_log, evidence = self.write_natural_pair(tmp_path)
            npc_log.write_bytes(npc_log.read_bytes()[:-1] + b"\x00\n")
            proc = self.run_natural(console, npc_log, evidence)
            self.assertEqual(proc.returncode, 2, proc.stderr)
            payload = json.loads(evidence.read_text(encoding="utf-8"))
            self.assertEqual(payload["status"], "INVALID_EVIDENCE")
            self.assertEqual(payload["stage_status"], "PASS")
            self.assertEqual(payload["terminal"]["status"], "NOT_EVALUATED")

    def test_canonical_json_tamper_unknown_and_duplicate_are_rejected(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            console, npc_log, evidence = self.write_natural_pair(Path(tmp))
            collect = self.run_natural(console, npc_log, evidence)
            self.assertEqual(collect.returncode, 0, collect.stderr)
            original = evidence.read_bytes()

            payload = json.loads(original.decode("utf-8"))
            payload["unknown"] = True
            evidence.write_text(
                json.dumps(payload, sort_keys=True, separators=(",", ":")) + "\n",
                encoding="utf-8",
            )
            unknown = self.run_natural(console, npc_log, evidence, mode="verify")
            self.assertEqual(unknown.returncode, 3)

            evidence.write_bytes(original.replace(b"{", b'{"schema":"duplicate",', 1))
            duplicate = self.run_natural(console, npc_log, evidence, mode="verify")
            self.assertEqual(duplicate.returncode, 3)

            payload = json.loads(original.decode("utf-8"))
            evidence.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
            whitespace = self.run_natural(console, npc_log, evidence, mode="verify")
            self.assertEqual(whitespace.returncode, 3)

    def test_stale_output_is_replaced_by_invalid_receipt(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            tmp_path = Path(tmp)
            console, npc_log, evidence = self.write_natural_pair(tmp_path)
            evidence.write_text("stale\n", encoding="utf-8")
            console.unlink()
            proc = self.run_natural(console, npc_log, evidence)
            self.assertEqual(proc.returncode, 2, proc.stderr)
            self.assertNotEqual(evidence.read_text(encoding="utf-8"), "stale\n")
            payload = json.loads(evidence.read_text(encoding="utf-8"))
            self.assertEqual(payload["status"], "INVALID_EVIDENCE")

    def test_output_path_collision_is_usage_error(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            console, npc_log, _ = self.write_natural_pair(Path(tmp))
            proc = self.run_natural(console, npc_log, console)
            self.assertEqual(proc.returncode, 64)


if __name__ == "__main__":
    unittest.main()
